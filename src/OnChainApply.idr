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

||| Outcome of one on-chain apply attempt. Success carries the tx hash.
||| types.toml: OnChainApply.ApplyResult
public export
data ApplyResult : Type where
  Success : (txHash : String) -> ApplyResult
  Failure : (reason : String) -> ApplyResult

||| Construct Addresses (named algebra helper).
export
mkAddresses : String -> String -> String -> String -> Addresses
mkAddresses rpcUrl tick multicaller from =
  MkAddresses rpcUrl tick multicaller from

export
success : String -> ApplyResult
success = Success

export
failure : String -> ApplyResult
failure = Failure

zeroAddr : String
zeroAddr = "0x0000000000000000000000000000000000000000"

isHexChar : Char -> Bool
isHexChar c =
  isDigit c
  || (c >= 'a' && c <= 'f')
  || (c >= 'A' && c <= 'F')

||| True iff `0x` + 64 hex digits (32-byte tx hash).
isTxHash : String -> Bool
isTxHash s =
  let cs = unpack s
  in length cs == 66
     && isPrefixOf ['0', 'x'] cs
     && all isHexChar (drop 2 cs)

||| Extract JSON-RPC `"result":"<hash>"` from an `eth_sendTransaction` body.
parseRpcTxHash : String -> Maybe String
parseRpcTxHash res =
  go (unpack res)
  where
    marker : List Char
    marker = unpack "\"result\":\""

    takeUntilQuote : List Char -> Maybe String
    takeUntilQuote xs =
      let (hashChars, rem) = break (== '"') xs
          s = pack hashChars
      in case rem of
           '"' :: _ => if isTxHash s then Just s else Nothing
           _ => Nothing

    go : List Char -> Maybe String
    go [] = Nothing
    go xs@(_ :: rest) =
      if isPrefixOf marker xs
        then takeUntilQuote (drop (length marker) xs)
        else go rest

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
  if not (rpcOk res)
    then pure (Failure ("RPC error: " ++ res))
    else case parseRpcTxHash res of
      Just h => pure (Success h)
      Nothing => pure (Failure ("missing tx hash in RPC result: " ++ res))
