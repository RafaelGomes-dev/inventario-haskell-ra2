module Main where

import qualified Data.map as Map
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

data Acaolog = Add | Remove | Update | QueryFail
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

main :: IO ()
main = do
  let it = Item "001" "Teclado" 10 "Perifericos"
  putStrLn ("Serializacao OK? " ++ show (read (show it) == it))
