||| ABI method encoders for Tick + Vectorized Multicaller.
||| Regen selectors: `cast sig "setTick(uint256)"`, `cast sig "readTick()"`,
||| `cast sig "aggregate(address[],bytes[],uint256[],address)"`.
module AbiMethod

import Data.List
import Data.String

import Abi

||| `setTick(uint256)` — `cast sig`
export
selSetTick : String
selSetTick = "fb972e51"

||| `readTick()` — `cast sig`
export
selReadTick : String
selReadTick = "23f6079d"

||| Multicaller `aggregate(address[],bytes[],uint256[],address)` — `cast sig`
export
selAggregate : String
selAggregate = "991f255f"

||| Full calldata for `setTick(uint256)`.
export
abiMethodSetTick : Integer -> String
abiMethodSetTick n = "0x" ++ selSetTick ++ encodeUint256Word n

||| Full calldata for `readTick()`.
export
abiMethodReadTick : String
abiMethodReadTick = "0x" ++ selReadTick

||| Multicaller `aggregate(targets, data, values, refundTo)`.
||| Tick demo: repeat the same Tick address in `targets`; `data` are Idris-encoded blobs.
export
abiMethodAggregate : List String -> List String -> List Integer -> String -> String
abiMethodAggregate targets datas values refundTo =
  let offsetTargets : Integer = 128  -- 4 head words * 32
      targetsBody = encodeWordArray (map encodeAddressWord targets)
      dataBody = encodeBytesArray datas
      valuesBody = encodeWordArray (map encodeUint256Word values)
      offsetData = offsetTargets + hexByteLen targetsBody
      offsetValues = offsetData + hexByteLen dataBody
      head =
        encodeUint256Word offsetTargets
        ++ encodeUint256Word offsetData
        ++ encodeUint256Word offsetValues
        ++ encodeAddressWord refundTo
  in "0x" ++ selAggregate ++ head ++ targetsBody ++ dataBody ++ valuesBody
  where
    hexByteLen : String -> Integer
    hexByteLen s = cast {to=Integer} (length s) `div` 2
