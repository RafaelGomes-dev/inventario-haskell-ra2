{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import qualified Data.Map as Map
import Data.Time (UTCTime, getCurrentTime)
import Data.List (isInfixOf, sortBy, maximumBy)
import Data.Ord (comparing)
import System.IO
import Control.Exception (catch, SomeException)


data Item = Item
  { itemID     :: String
  , nome       :: String
  , quantidade :: Int
  , categoria  :: String
  } deriving (Show, Read, Eq)

type Inventario = Map.Map String Item

data AcaoLog = Add | Remove | Update | QueryFail
  deriving (Show, Read, Eq)

data StatusLog = Sucesso | Falha String
  deriving (Show, Read, Eq)

data LogEntry = LogEntry
  { timestamp :: UTCTime
  , acao      :: AcaoLog
  , detalhes  :: String
  , status    :: StatusLog
  } deriving (Show, Read)

type ResultadoOperacao = (Inventario, LogEntry)

-- ============================================================
-- COLEGA A - LOGICA DE NEGOCIO PURA
-- Esta seção concentra as funções puras do sistema.
-- Nenhuma função aqui deve usar IO, ou seja:
-- nada de putStrLn, getLine, readFile, writeFile ou appendFile.
-- ============================================================

-- Cria uma entrada de log para operações que falharam.
-- O campo detalhes começa com "ID=", pois isso facilita depois
-- a análise dos logs por item.
criarLogFalha :: UTCTime -> AcaoLog -> String -> String -> LogEntry
criarLogFalha tempo acaoLog iid mensagem =
  LogEntry
    { timestamp = tempo
    , acao = acaoLog
    , detalhes = "ID=" ++ iid ++ " | " ++ mensagem
    , status = Falha mensagem
    }


-- Adiciona um novo item ao inventário.
-- Se o ID já existir, retorna Left com uma mensagem de erro.
-- Se não existir, insere o item e retorna o novo inventário com o log.
addItem :: UTCTime -> Item -> Inventario -> Either String ResultadoOperacao
addItem tempo item inv =
  case Map.lookup (itemID item) inv of
    Just _ ->
      Left "ID duplicado"

    Nothing ->
      let novoInv = Map.insert (itemID item) item inv

          descricao =
            "ID=" ++ itemID item
            ++ " | nome=" ++ nome item
            ++ " qtd=" ++ show (quantidade item)
            ++ " categoria=" ++ categoria item

          logOperacao =
            LogEntry
              { timestamp = tempo
              , acao = Add
              , detalhes = descricao
              , status = Sucesso
              }
      in Right (novoInv, logOperacao)


-- Remove uma quantidade específica de um item.
-- A função valida se a quantidade é positiva, se o item existe
-- e se há estoque suficiente.
removeItem :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao
removeItem tempo iid qtdRemover inv
  | qtdRemover <= 0 =
      Left "Quantidade invalida"

  | otherwise =
      case Map.lookup iid inv of
        Nothing ->
          Left "Item nao encontrado"

        Just itemAtual ->
          if qtdRemover > quantidade itemAtual
            then Left "Estoque insuficiente"
            else
              let novaQuantidade = quantidade itemAtual - qtdRemover

                  itemAtualizado =
                    itemAtual { quantidade = novaQuantidade }

                  novoInv =
                    Map.insert iid itemAtualizado inv

                  descricao =
                    "ID=" ++ iid
                    ++ " | removido=" ++ show qtdRemover
                    ++ " restante=" ++ show novaQuantidade

                  logOperacao =
                    LogEntry
                      { timestamp = tempo
                      , acao = Remove
                      , detalhes = descricao
                      , status = Sucesso
                      }
              in Right (novoInv, logOperacao)


-- Atualiza diretamente a quantidade de um item já existente.
-- Diferente de removeItem, aqui a quantidade não é subtraída:
-- ela é substituída pela nova quantidade informada.
updateQty :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao
updateQty tempo iid novaQtd inv
  | novaQtd < 0 =
      Left "Quantidade invalida"

  | otherwise =
      case Map.lookup iid inv of
        Nothing ->
          Left "Item nao encontrado"

        Just itemAtual ->
          let itemAtualizado =
                itemAtual { quantidade = novaQtd }

              novoInv =
                Map.insert iid itemAtualizado inv

              descricao =
                "ID=" ++ iid
                ++ " | quantidade atualizada para "
                ++ show novaQtd

              logOperacao =
                LogEntry
                  { timestamp = tempo
                  , acao = Update
                  , detalhes = descricao
                  , status = Sucesso
                  }
          in Right (novoInv, logOperacao)


-- Retorna todos os logs relacionados a um item específico.
-- Como os logs seguem o padrão "ID=<id> | ...",
-- basta procurar esse trecho dentro do campo detalhes.
historicoPorItem :: String -> [LogEntry] -> [LogEntry]
historicoPorItem iid logs =
  filter pertenceAoItem logs
  where
    pertenceAoItem logAtual =
      ("ID=" ++ iid) `isInfixOf` detalhes logAtual


-- Filtra apenas os logs que representam falhas.
logsDeErro :: [LogEntry] -> [LogEntry]
logsDeErro logs =
  filter ehErro logs
  where
    ehErro logAtual =
      case status logAtual of
        Falha _ -> True
        Sucesso -> False

-- ============================================================
-- COLEGA B - MODULO DE I/O E PERSISTENCIA
-- Toda interação com o sistema de arquivos e o terminal fica
-- aqui. O main definitivo substitui o main temporário do Aluno 1.
-- ============================================================

arqInventario :: FilePath
arqInventario = "Inventario.dat"

arqLog :: FilePath
arqLog = "Auditoria.log"

-- O `seq` força a string inteira a ser avaliada antes de retornar.
-- Sem isso, readFile é lazy e o handle fica aberto; se depois
-- tentarmos escrever no mesmo arquivo, o programa trava ou corrompe.
carregarInventario :: IO Inventario
carregarInventario =
  ( do conteudo <- readFile arqInventario
       conteudo `seq` return (read conteudo) )
  `catch` (\(_ :: SomeException) -> return Map.empty)

carregarLogs :: IO [LogEntry]
carregarLogs =
  ( do conteudo <- readFile arqLog
       let ls = filter (not . null) (lines conteudo)
       length ls `seq` return (map read ls) )
  `catch` (\(_ :: SomeException) -> return [])

salvarInventario :: Inventario -> IO ()
salvarInventario inv = writeFile arqInventario (show inv)

registrarLog :: LogEntry -> IO ()
registrarLog le = appendFile arqLog (show le ++ "\n")

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  putStrLn "=== Sistema de Inventario (RA2) ==="
  putStrLn "Comandos: add | remove | update | list | report | sair"
  inv <- carregarInventario
  loop inv

loop :: Inventario -> IO ()
loop inv = do
  putStr "\n> "
  hFlush stdout
  linha <- getLine
  let ws = words linha
  case ws of
    ("sair":_) ->
      putStrLn "Encerrando."

    ("list":_) -> do
      if Map.null inv
        then putStrLn "(inventario vazio)"
        else mapM_ (putStrLn . formatItem) (Map.elems inv)
      loop inv

    -- report carrega os logs do arquivo e exibe o relatório
    ("report":_) -> do
      logs <- carregarLogs
      gerarRelatorio logs
      loop inv

    ("add":iid:nm:qtdStr:cat:_) ->
      case readMaybeInt qtdStr of
        Nothing -> falhaParse inv
        Just q  -> do
          t <- getCurrentTime
          processarResultado inv Add iid (addItem t (Item iid nm q cat) inv)

    ("remove":iid:qtdStr:_) ->
      case readMaybeInt qtdStr of
        Nothing -> falhaParse inv
        Just q  -> do
          t <- getCurrentTime
          processarResultado inv Remove iid (removeItem t iid q inv)

    ("update":iid:qtdStr:_) ->
      case readMaybeInt qtdStr of
        Nothing -> falhaParse inv
        Just q  -> do
          t <- getCurrentTime
          processarResultado inv Update iid (updateQty t iid q inv)

    [] -> loop inv
    _  -> do
      putStrLn "Comando invalido."
      loop inv

processarResultado :: Inventario -> AcaoLog -> String
                   -> Either String ResultadoOperacao -> IO ()
processarResultado inv ac iid resultado = do
  t <- getCurrentTime
  case resultado of
    Right (novoInv, logE) -> do
      salvarInventario novoInv
      registrarLog logE
      putStrLn "OK."
      loop novoInv
    Left erro -> do
      registrarLog (criarLogFalha t ac iid erro)
      putStrLn ("ERRO: " ++ erro)
      loop inv

falhaParse :: Inventario -> IO ()
falhaParse inv = do
  putStrLn "ERRO: argumentos invalidos."
  loop inv

formatItem :: Item -> String
formatItem it =
  itemID it ++ " | " ++ nome it
  ++ " | qtd: " ++ show (quantidade it)
  ++ " | " ++ categoria it

readMaybeInt :: String -> Maybe Int
readMaybeInt s =
  case reads s of
    [(n, "")] -> Just n
    _         -> Nothing

-- Extrai o ID do campo detalhes, que sempre começa com "ID=<id> | ..."
extrairID :: LogEntry -> String
extrairID le =
  let d = detalhes le
  in if take 3 d == "ID="
       then takeWhile (/= ' ') (drop 3 d)
       else ""

-- Conta quantas vezes cada ID aparece nos logs e retorna o mais frequente.
itemMaisMovimentado :: [LogEntry] -> String
itemMaisMovimentado [] = "(sem movimentacoes)"
itemMaisMovimentado logs =
  let ids    = map extrairID logs
      grupos = Map.toList
                 (Map.fromListWith (+) [(i, 1 :: Int) | i <- ids, not (null i)])
  in if null grupos
       then "(sem movimentacoes)"
       else fst (maximumBy (comparing snd) grupos)

gerarRelatorio :: [LogEntry] -> IO ()
gerarRelatorio logs = do
  putStrLn "===== RELATORIO ====="
  putStrLn ("Total de eventos      : " ++ show (length logs))
  let erros = logsDeErro logs
  putStrLn ("Erros registrados     : " ++ show (length erros))
  mapM_ (putStrLn . ("  [ERRO] " ++) . detalhes) erros
  putStrLn ("Item mais movimentado : " ++ itemMaisMovimentado logs)