||| On-chain apply: MulticallBatch → one Multicaller.aggregate tx.
|||
||| Algebra (carriers):
||| $$
||| \mathrm{Addresses},\ \mathrm{MulticallBatch},\ \mathrm{ApplyResult}
||| $$
|||
||| Operations:
||| $$
||| \mathrm{applyOnChain} : \mathrm{Addresses} \to \mathrm{MulticallBatch} \to \mathrm{IO}\,\mathrm{ApplyResult}
||| $$
|||
||| Laws:
||| 1. Empty batch $\Rightarrow$ Success (no-op).
||| 2. Total: every apply yields exactly one $\mathrm{ApplyResult}$.
||| 3. Failure $\Rightarrow$ not Consumed.
||| 4. Call order $=$ aggregate order.
|||
||| Invalid: malformed Tick/Multicaller address; bad calldata; RPC/tx revert $\Rightarrow$ Failure.
module OnChainApply

import Data.List
import Data.String

import AbiMethod
import AnvilRpc
import MulticallBatch

||| RPC + contract addresses for one apply.
||| types.toml: OnChainApply.Addresses
public export
record Addresses where
  constructor MkAddresses
  rpcUrl : String
  tick : String
  multicaller : String
  from : String

||| Outcome of one on-chain apply attempt.
||| types.toml: OnChainApply.ApplyResult
public export
data ApplyResult : Type where
  Success : ApplyResult
  Failure : (reason : String) -> ApplyResult

||| Construct Addresses (named algebra helper).
export
mkAddresses : String -> String -> String -> String -> Addresses
mkAddresses rpcUrl tick multicaller from =
  MkAddresses rpcUrl tick multicaller from

export
success : ApplyResult
success = Success

export
failure : String -> ApplyResult
failure = Failure

zeroAddr : String
zeroAddr = "0x0000000000000000000000000000000000000000"

||| Submit batch via Multicaller.aggregate; Success only after confirmed send.
||| types.toml: OnChainApply.applyOnChain
export
applyOnChain : Addresses -> MulticallBatch -> IO ApplyResult
applyOnChain addrs (MkMulticallBatch cs) = do
  let n = length cs
      targets = replicate n addrs.tick
      datas = map data_ cs
      values = replicate n 0
      calldata = abiMethodAggregate targets datas values zeroAddr
  Right res <- ethSendTransaction addrs.rpcUrl addrs.from addrs.multicaller calldata
    | Left err => pure (Failure err)
  pure (if rpcOk res then Success else Failure ("RPC error: " ++ res))
