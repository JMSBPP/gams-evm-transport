||| Opaque external service: Consumed only after on-chain apply Success.
|||
||| Algebra (carriers):
||| $$
||| \mathrm{GdxPath},\ \mathrm{MulticallBatch},\ \mathrm{Addresses},\ \mathrm{Success}
||| $$
|||
||| Operation:
||| $$
||| \mathrm{publishGdx} : \mathrm{IO}\,()
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
module PublishGdx

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
||| types.toml: PublishGdx.publishGdx
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
  Just addrs <- resolveAddresses
    | Nothing => exitFailure
  result <- applyOnChain addrs batch
  case result of
    Success => exitSuccess
    Failure _ => exitFailure

main : IO ()
main = publishGdx
