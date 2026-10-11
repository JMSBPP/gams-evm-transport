module Ping

export
ping : IO ()
ping = putStrLn "received"
