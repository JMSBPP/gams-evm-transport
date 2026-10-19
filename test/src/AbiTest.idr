module AbiTest

import AbiMethod
import GdxCsv
import MulticallBatch

||| Golden from `cast calldata "setTick(uint256)" 1`
export
goldenSetTick1 : String
goldenSetTick1 =
  "0xfb972e510000000000000000000000000000000000000000000000000000000000000001"

||| Golden from `cast calldata "setTick(uint256)" 3`
export
goldenSetTick3 : String
goldenSetTick3 =
  "0xfb972e510000000000000000000000000000000000000000000000000000000000000003"

||| Two's-complement wrap of -1440 into uint256 word (same as `uint256(int256(-1440))`).
export
goldenSetTickNeg1440 : String
goldenSetTickNeg1440 =
  "0xfb972e51fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa60"

export
testSetTick1 : Bool
testSetTick1 = abiMethodSetTick 1 == goldenSetTick1

export
testSetTick3 : Bool
testSetTick3 = abiMethodSetTick 3 == goldenSetTick3

export
testSetTickNeg1440 : Bool
testSetTickNeg1440 = abiMethodSetTick (-1440) == goldenSetTickNeg1440

export
testParseDecimalNeg1440 : Bool
testParseDecimalNeg1440 = parseDecimal "-1440" == Just (-1440)

export
testParseDecimalPos : Bool
testParseDecimalPos = parseDecimal "3" == Just 3

export
testParseDecimalRejectsBareMinus : Bool
testParseDecimalRejectsBareMinus = parseDecimal "-" == Nothing

export
testReadTickSel : Bool
testReadTickSel = abiMethodReadTick == "0x23f6079d"

||| Golden from cast aggregate with one Tick target + setTick(1).
export
goldenAggregateOne : String
goldenAggregateOne =
  "0x991f255f000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000024fb972e5100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000"

export
testAggregateOne : Bool
testAggregateOne =
  let tick = "0x0000000000000000000000000000000000000001"
      d = abiMethodSetTick 1
  in abiMethodAggregate [tick] [d] [0] "0x0000000000000000000000000000000000000000"
     == goldenAggregateOne

||| Param value `3` → golden `setTick(3)` calldata.
export
testParamToSetTick3 : Bool
testParamToSetTick3 =
  case elementToCall defaultTarget (ParamElem "p" [] "3") of
    Just (MkCall t d) => t == defaultTarget && d == goldenSetTick3
    Nothing => False

||| Param Val `-1440` → nonempty call with wrapped setTick calldata.
export
testParamToSetTickNeg1440 : Bool
testParamToSetTickNeg1440 =
  case elementToCall defaultTarget (ParamElem "pathTickVal" ["k"] "-1440") of
    Just (MkCall t d) => t == defaultTarget && d == goldenSetTickNeg1440
    Nothing => False

||| Negative Val participates in MulticallBatch (nonempty).
export
testNegValInBatch : Bool
testNegValInBatch =
  let b = elementsToBatch defaultTarget [ParamElem "p" [] "-1440"]
  in case calls b of
       [MkCall _ d] => d == goldenSetTickNeg1440
       _ => False

||| Set elements do not produce calls.
export
testSetSkipped : Bool
testSetSkipped =
  case elementToCall defaultTarget (SetElem "s" "a") of
    Nothing => True
    Just _ => False
