||| Opaque external service: Consumed only after on-chain apply Success.
|||
||| Algebra (carriers):
||| $$
||| \mathrm{GdxPath},\ \mathrm{MulticallBatch},\ \mathrm{Addresses},\ \mathrm{Success}
||| $$
|||
||| Operation:
||| $$
||| \mathrm{broadcast\_tick\_path} : \mathrm{IO}\,()
||| $$
||| GDX path $\to$ batch $\to$ write JSON $\to$ $\mathrm{applyOnChain}$ $\to$ exit $0$ iff Success.
|||
||| Laws:
||| 1. Exit $0 \Leftrightarrow$ $\mathrm{applyOnChain}$ returned Success.
||| 2. Empty batch $\Rightarrow$ nonzero.
||| 3. Apply Failure $\Rightarrow$ nonzero (fail closed).
||| 4. JSON still written before apply when batch builds.
|||
||| Invalid: missing GDX path; dump/empty batch; bad Addresses; apply Failure.
module Broadcast_tick_path

import Data.List
import Data.String
import System
import System.File

import AnvilRpc
import GdxCsv
import MulticallBatch
import OnChainApply

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

requireEnv : String -> IO (Maybe String)
requireEnv name = do
  Just v <- getEnv name
    | Nothing => pure Nothing
  let v' = trim v
  pure (if v' == "" then Nothing else Just v')

||| Env Addresses for apply (AddressBootstrap deferred).
resolveAddresses : IO (Maybe Addresses)
resolveAddresses = do
  url <- do
    Just u <- getEnv "ANVIL_RPC_URL"
      | Nothing => pure defaultRpcUrl
    let u' = trim u
    pure (if u' == "" then defaultRpcUrl else u')
  Just tick <- requireEnv "TICK_ADDRESS"
    | Nothing => pure Nothing
  Just multicaller <- requireEnv "MULTICALLER_ADDRESS"
    | Nothing => pure Nothing
  from <- do
    Just f <- getEnv "ANVIL_FROM"
      | Nothing =>
          pure "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    let f' = trim f
    pure (if f' == "" then "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" else f')
  pure (Just (mkAddresses url tick multicaller from))

||| Consumed (exit 0) only after GDX → batch → JSON → applyOnChain Success.
||| types.toml: Broadcast_tick_path.broadcast_tick_path
export
broadcast_tick_path : IO ()
broadcast_tick_path = do
  Right raw <- readFile "build/.gdx-publish-path"
    | Left _ => do
        putStrLn "broadcast_tick_path failed: missing GDX path file"
        exitFailure
  let path = trim raw
  False <- pure (path == "")
    | True => do
        putStrLn "broadcast_tick_path failed: empty GDX path"
        exitFailure
  True <- exists path
    | False => do
        putStrLn ("broadcast_tick_path failed: GDX not found: " ++ path)
        exitFailure
  Right batch <- gdxToMulticallBatch path
    | Left err => do
        putStrLn ("broadcast_tick_path failed: " ++ err)
        exitFailure
  let False = null (calls batch)
    | True => do
        putStrLn "broadcast_tick_path failed: empty batch"
        exitFailure
  Right _ <- writeFile "build/multicall-batch.json" (batchToJson batch)
    | Left err => do
        putStrLn ("broadcast_tick_path failed: " ++ show err)
        exitFailure
  Just addrs <- resolveAddresses
    | Nothing => do
        putStrLn "broadcast_tick_path failed: missing TICK_ADDRESS / MULTICALLER_ADDRESS"
        exitFailure
  result <- applyOnChain addrs batch
  let n = length (calls batch)
  case result of
    Success txHash => do
      putStrLn ("broadcast_tick_path ok " ++ txHash ++ " calls=" ++ show n)
      exitSuccess
    Failure reason => do
      putStrLn ("broadcast_tick_path failed: " ++ reason)
      exitFailure

main : IO ()
main = broadcast_tick_path
