||| Opaque external service: Consumed only after MulticallBatch is fully built from GDX.
module PublishGdx

import Data.List
import Data.String
import System
import System.File

import GdxCsv
import MulticallBatch

jsonEscape : String -> String
jsonEscape = pack . concatMap escChar . unpack
  where
    escChar : Char -> List Char
    escChar '"' = ['\\', '"']
    escChar '\\' = ['\\', '\\']
    escChar c = [c]

callToJson : Call -> String
callToJson (MkCall t d) =
  "{\"target\":\"" ++ jsonEscape t ++ "\",\"data\":\"" ++ jsonEscape d ++ "\"}"

||| Serialize MulticallBatch for web3 / file handoff.
export
batchToJson : MulticallBatch -> String
batchToJson (MkMulticallBatch cs) =
  "{\"calls\":[" ++ fastConcat (intersperse "," (map callToJson cs)) ++ "]}"

||| Consumed (exit 0) only after GDX → CSV → MulticallBatch is complete.
export
publishGdx : IO ()
publishGdx = do
  Right raw <- readFile "build/.gdx-publish-path"
    | Left _ => exitFailure
  let path = trim raw
  False <- pure (path == "")
    | True => exitFailure
  True <- exists path
    | False => exitFailure
  Right batch <- gdxToMulticallBatch path
    | Left _ => exitFailure
  let False = null (calls batch)
    | True => exitFailure
  Right _ <- writeFile "build/multicall-batch.json" (batchToJson batch)
    | Left _ => exitFailure
  exitSuccess

main : IO ()
main = publishGdx
