||| Behavioral: nonempty setTick MulticallBatch applied on Anvil yields Success.
|||
||| $$
||| |B.\mathrm{calls}| \ge 1
||| \;\land\;
||| B_i.\mathrm{data} = \mathrm{setTick}(v_i)
||| \;\land\;
||| \mathrm{Anvil\ up}
||| \;\Rightarrow\;
||| \mathrm{applyOnChain}(A, B) = \mathrm{Success}
||| $$
module OnChainApplyTest

import Data.List
import Data.String
import System

import AbiMethod
import AnvilRpc
import MulticallBatch
import OnChainApply

requireEnv : String -> IO String
requireEnv name = do
  Just v <- getEnv name
    | Nothing => do
        putStrLn ("missing env " ++ name)
        exitFailure
  let v' = trim v
  False <- pure (v' == "")
    | True => do
        putStrLn ("empty env " ++ name)
        exitFailure
  pure v'

||| Nonempty setTick batch → one aggregate Success on live Anvil.
main : IO ()
main = do
  url <- do
    Just u <- getEnv "ANVIL_RPC_URL"
      | Nothing => pure defaultRpcUrl
    let u' = trim u
    pure (if u' == "" then defaultRpcUrl else u')
  tick <- requireEnv "APP_ADDRESS"
  multicaller <- requireEnv "MULTICALLER_ADDRESS"
  from <- do
    Just f <- getEnv "ANVIL_FROM"
      | Nothing =>
          pure "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    let f' = trim f
    pure (if f' == "" then "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" else f')
  let addrs = mkAddresses url tick multicaller from
      batch =
        MkMulticallBatch
          [ MkCall tick (abiMethodSetTick 1)
          , MkCall tick (abiMethodSetTick 2)
          ]
  result <- applyOnChain addrs batch
  case result of
    Success txHash =>
      if isPrefixOf (unpack "0x") (unpack txHash) && length txHash == 66
        then do
          putStrLn ("onchain-apply nonempty setTick → Success " ++ txHash)
          exitSuccess
        else do
          putStrLn ("expected 0x tx hash, got: " ++ txHash)
          exitFailure
    Failure reason => do
      putStrLn ("expected Success, got Failure: " ++ reason)
      exitFailure
