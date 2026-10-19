||| Anvil smoke: Multicaller.aggregate with ≥2 setTick datas targeting Tick.
||| Env: ANVIL_RPC_URL, TICK_ADDRESS, MULTICALLER_ADDRESS; optional ANVIL_FROM.
module AnvilTickSmoke

import Data.List
import Data.String
import System

import AbiMethod
import AnvilRpc

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

main : IO ()
main = do
  url <- do
    Just u <- getEnv "ANVIL_RPC_URL"
      | Nothing => pure defaultRpcUrl
    let u' = trim u
    pure (if u' == "" then defaultRpcUrl else u')
  tick <- requireEnv "TICK_ADDRESS"
  multicaller <- requireEnv "MULTICALLER_ADDRESS"
  from <- do
    Just f <- getEnv "ANVIL_FROM"
      | Nothing =>
          -- Anvil default first unlocked account
          pure "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    let f' = trim f
    pure (if f' == "" then "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" else f')
  let datas = [abiMethodSetTick 1, abiMethodSetTick 2]
      targets = [tick, tick]
      values = [0, 0]
      calldata = abiMethodAggregate targets datas values
                   "0x0000000000000000000000000000000000000000"
  Right res <- ethSendTransaction url from multicaller calldata
    | Left err => do
        putStrLn err
        exitFailure
  True <- pure (rpcOk res)
    | False => do
        putStrLn ("RPC error: " ++ res)
        exitFailure
  putStrLn "anvil-tick-smoke ok"
  exitSuccess
