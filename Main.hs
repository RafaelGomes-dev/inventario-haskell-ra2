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

main :: IO ()
main = do
  tempo <- getCurrentTime

  let item1 = Item "001" "Teclado" 10 "Perifericos"
  let inv0 = Map.empty

  case addItem tempo item1 inv0 of
    Left erro ->
      putStrLn ("Erro ao adicionar: " ++ erro)

    Right (inv1, log1) -> do
      putStrLn "Item adicionado com sucesso."
      print inv1
      print log1

      case removeItem tempo "001" 3 inv1 of
        Left erro ->
          putStrLn ("Erro ao remover: " ++ erro)

        Right (inv2, log2) -> do
          putStrLn "Item removido com sucesso."
          print inv2
          print log2