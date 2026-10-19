module Main

import System
import MulticallBatchTest
import AbiTest

main : IO ()
main = do
  False <- pure (not testEmpty)
    | True => do putStrLn "testEmpty failed"; exitFailure
  False <- pure (not testAppendOrder)
    | True => do putStrLn "testAppendOrder failed"; exitFailure
  False <- pure (not testSetTick1)
    | True => do putStrLn "testSetTick1 failed"; exitFailure
  False <- pure (not testSetTick3)
    | True => do putStrLn "testSetTick3 failed"; exitFailure
  False <- pure (not testSetTickNeg1440)
    | True => do putStrLn "testSetTickNeg1440 failed"; exitFailure
  False <- pure (not testParseDecimalNeg1440)
    | True => do putStrLn "testParseDecimalNeg1440 failed"; exitFailure
  False <- pure (not testParseDecimalPos)
    | True => do putStrLn "testParseDecimalPos failed"; exitFailure
  False <- pure (not testParseDecimalRejectsBareMinus)
    | True => do putStrLn "testParseDecimalRejectsBareMinus failed"; exitFailure
  False <- pure (not testReadTickSel)
    | True => do putStrLn "testReadTickSel failed"; exitFailure
  False <- pure (not testAggregateOne)
    | True => do putStrLn "testAggregateOne failed"; exitFailure
  False <- pure (not testParamToSetTick3)
    | True => do putStrLn "testParamToSetTick3 failed"; exitFailure
  False <- pure (not testParamToSetTickNeg1440)
    | True => do putStrLn "testParamToSetTickNeg1440 failed"; exitFailure
  False <- pure (not testNegValInBatch)
    | True => do putStrLn "testNegValInBatch failed"; exitFailure
  False <- pure (not testSetSkipped)
    | True => do putStrLn "testSetSkipped failed"; exitFailure
  putStrLn "Test successful!"
