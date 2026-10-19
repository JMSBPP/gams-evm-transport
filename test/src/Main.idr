module Main

import System
import MulticallBatchTest

main : IO ()
main = do
  False <- pure (not testEmpty)
    | True => do putStrLn "testEmpty failed"; exitFailure
  False <- pure (not testAppendOrder)
    | True => do putStrLn "testAppendOrder failed"; exitFailure
  putStrLn "Test successful!"
