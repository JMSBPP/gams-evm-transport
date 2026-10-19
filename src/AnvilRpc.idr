||| Minimal Anvil HTTP JSON-RPC via curl (eth_call / eth_sendTransaction).
module AnvilRpc

import Data.String
import System
import System.File

||| Default Anvil endpoint.
export
defaultRpcUrl : String
defaultRpcUrl = "http://127.0.0.1:8545"

jsonEscape : String -> String
jsonEscape = pack . concatMap esc . unpack
  where
    esc : Char -> List Char
    esc '"' = ['\\', '"']
    esc '\\' = ['\\', '\\']
    esc c = [c]

||| POST JSON-RPC body; returns raw response body or Left error.
export
rpcPost : String -> String -> IO (Either String String)
rpcPost url body = do
  ignore $ system "mkdir -p build"
  let reqFile = "build/.anvil-rpc-req.json"
      resFile = "build/.anvil-rpc-res.json"
  Right _ <- writeFile reqFile body
    | Left err => pure (Left (show err))
  let cmd =
        "curl -sS -X POST -H 'Content-Type: application/json' "
        ++ "--data @" ++ reqFile ++ " " ++ url ++ " > " ++ resFile ++ " 2>/dev/null"
  code <- system cmd
  if code /= 0
    then pure (Left ("curl RPC failed (is Anvil up at " ++ url ++ "?)"))
    else do
      Right res <- readFile resFile
        | Left err => pure (Left (show err))
      pure (Right res)

||| Fail if response contains JSON-RPC error object.
export
rpcOk : String -> Bool
rpcOk res =
  -- crude: success responses have "result"; errors have "error"
  isInfixOf "\"result\"" res && not (isInfixOf "\"error\"" res)

||| eth_call to `to` with calldata `data_` (both hex strings).
export
ethCall : String -> String -> String -> IO (Either String String)
ethCall url to data_ = do
  let body =
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\","
        ++ "\"params\":[{\"to\":\"" ++ jsonEscape to
        ++ "\",\"data\":\"" ++ jsonEscape data_ ++ "\"},\"latest\"]}"
  rpcPost url body

||| eth_sendTransaction from `from` to `to` with calldata (Anvil unlocked accounts).
export
ethSendTransaction : String -> String -> String -> String -> IO (Either String String)
ethSendTransaction url from to data_ = do
  let body =
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_sendTransaction\","
        ++ "\"params\":[{\"from\":\"" ++ jsonEscape from
        ++ "\",\"to\":\"" ++ jsonEscape to
        ++ "\",\"data\":\"" ++ jsonEscape data_ ++ "\"}]}"
  rpcPost url body
