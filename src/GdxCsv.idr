||| GDX → gdxdump CSV interchange (locked after spike for Multicall indexing).
module GdxCsv

import Data.List
import Data.List1
import Data.String
import System
import System.File

import MulticallBatch

public export
data GdxSymbolKind = GdxSet | GdxParam

public export
record GdxSymbol where
  constructor MkGdxSymbol
  name : String
  kind : GdxSymbolKind

public export
data GdxElement
  = SetElem String String                 -- symbol, element
  | ParamElem String (List String) String -- symbol, keys, value

||| Default smoke / placeholder target for encoded calls.
export
defaultTarget : String
defaultTarget = "0x0000000000000000000000000000000000000001"

hexDigit : Int -> Char
hexDigit n =
  if n < 10 then chr (n + cast {to=Int} (ord '0'))
  else chr (n - 10 + cast {to=Int} (ord 'a'))

byteHex : Char -> String
byteHex c =
  let n = cast {to=Int} (ord c)
  in pack [hexDigit (n `div` 16), hexDigit (n `mod` 16)]

||| Trivial calldata encoding: 0x + hex of UTF-8 payload (smoke-grade).
export
encodeData : String -> String
encodeData s = "0x" ++ concatMap byteHex (unpack s)

runDump : String -> IO (Either String String)
runDump cmd = do
  let outFile = "build/.gdxdump-out.txt"
  ignore $ system "mkdir -p build"
  code <- system (cmd ++ " > " ++ outFile ++ " 2>/dev/null")
  if code /= 0
    then pure (Left ("gdxdump failed: " ++ cmd))
    else do
      Right body <- readFile outFile
        | Left err => pure (Left (show err))
      pure (Right body)

||| Parse `gdxdump … Symbols` table into symbol list (skip header).
export
parseSymbols : String -> List GdxSymbol
parseSymbols body =
  mapMaybe parseLine (drop 1 (lines body))
  where
    parseLine : String -> Maybe GdxSymbol
    parseLine line =
      case words line of
        (_ :: name :: _ :: ty :: _) =>
          case ty of
            "Set" => Just (MkGdxSymbol name GdxSet)
            "Par" => Just (MkGdxSymbol name GdxParam)
            _ => Nothing
        _ => Nothing

stripQuotes : String -> String
stripQuotes s =
  let chars = unpack s
      chars' = case chars of
        '"' :: rest => rest
        xs => xs
      chars'' = case reverse chars' of
        '"' :: rest => reverse rest
        xs => chars'
  in pack chars''

||| Parse set CSV (header + one column of elements).
export
parseSetCsv : String -> String -> List GdxElement
parseSetCsv sym body =
  map (\e => SetElem sym (stripQuotes e))
      (filter (/= "") (map trim (drop 1 (lines body))))

||| Parse parameter CSV: key columns…, Val
export
parseParamCsv : String -> String -> List GdxElement
parseParamCsv sym body =
  case lines body of
    [] => []
    (_ :: rows) => mapMaybe parseRow rows
  where
    parseRow : String -> Maybe GdxElement
    parseRow row =
      let parts = map (stripQuotes . trim) (forget (split (== ',') row))
      in case reverse parts of
           [] => Nothing
           (val :: keysRev) => Just (ParamElem sym (reverse keysRev) val)

||| Dump one symbol as CSV text.
export
gdxdumpCsv : String -> String -> IO (Either String String)
gdxdumpCsv gdxPath symb =
  runDump ("gdxdump " ++ gdxPath ++ " symb=" ++ symb ++ " format=csv")

||| List symbols in a GDX.
export
gdxSymbols : String -> IO (Either String (List GdxSymbol))
gdxSymbols gdxPath = do
  Right body <- runDump ("gdxdump " ++ gdxPath ++ " Symbols")
    | Left e => pure (Left e)
  pure (Right (parseSymbols body))

||| All elements in symbol-table order, each symbol’s rows in CSV index order.
export
gdxElements : String -> IO (Either String (List GdxElement))
gdxElements gdxPath = do
  Right syms <- gdxSymbols gdxPath
    | Left e => pure (Left e)
  go syms []
  where
    go : List GdxSymbol -> List GdxElement -> IO (Either String (List GdxElement))
    go [] acc = pure (Right acc)
    go (MkGdxSymbol n k :: rest) acc = do
      Right csv <- gdxdumpCsv gdxPath n
        | Left e => pure (Left e)
      let elems = case k of
            GdxSet => parseSetCsv n csv
            GdxParam => parseParamCsv n csv
      go rest (acc ++ elems)

elementPayload : GdxElement -> String
elementPayload (SetElem sym e) = "set|" ++ sym ++ "|" ++ e
elementPayload (ParamElem sym keys val) =
  "par|" ++ sym ++ "|" ++ fastConcat (intersperse "," keys) ++ "|" ++ val

||| Encode one GDX element as a Multicall Call (smoke encoding).
export
elementToCall : GdxElement -> Call
elementToCall el =
  MkCall defaultTarget (encodeData (elementPayload el))

||| Build MulticallBatch by appending calls for elements index 0..n-1.
export
elementsToBatch : List GdxElement -> MulticallBatch
elementsToBatch = foldl (\b, el => appendCall b (elementToCall el)) emptyBatch

||| GDX path → MulticallBatch (full consume job for publish).
export
gdxToMulticallBatch : String -> IO (Either String MulticallBatch)
gdxToMulticallBatch gdxPath = do
  Right elems <- gdxElements gdxPath
    | Left e => pure (Left e)
  pure (Right (elementsToBatch elems))
