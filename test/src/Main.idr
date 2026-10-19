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
  False <- pure (not testReadTickSel)
    | True => do putStrLn "testReadTickSel failed"; exitFailure
  False <- pure (not testAggregateOne)
    | True => do putStrLn "testAggregateOne failed"; exitFailure
  False <- pure (not testParamToSetTick3)
    | True => do putStrLn "testParamToSetTick3 failed"; exitFailure
  False <- pure (not testSetSkipped)
    | True => do putStrLn "testSetSkipped failed"; exitFailure
  putStrLn "Test successful!"
