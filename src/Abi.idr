||| Minimal ABI word helpers (HEVM-shaped: left-pad int-likes to 32 bytes).
||| Selectors / regen: `cast sig "setTick(uint256)"` etc.
module Abi

import Data.List
import Data.Nat
import Data.String

||| Hex digit 0..15 → lowercase char.
hexDigit : Int -> Char
hexDigit n =
  if n < 10 then chr (n + cast {to=Int} (ord '0'))
  else chr (n - 10 + cast {to=Int} (ord 'a'))

||| Non-negative Integer → lowercase hex (no `0x`, no pad; `0` → `"0"`).
export
toHex : Integer -> String
toHex n =
  if n <= 0 then "0"
  else pack (reverse (go n))
  where
    go : Integer -> List Char
    go 0 = []
    go x =
      let d = cast {to=Int} (x `mod` 16)
      in hexDigit d :: go (x `div` 16)

||| Left-pad with `'0'` to exactly `n` characters (truncate from left if longer).
export
padLeft : Nat -> String -> String
padLeft n s =
  let len = length s
  in if len >= n
       then pack (drop (minus len n) (unpack s))
       else pack (replicate (minus n len) '0' ++ unpack s)

||| Strip optional `0x` / `0X` prefix.
export
strip0x : String -> String
strip0x s =
  case unpack s of
    '0' :: 'x' :: rest => pack rest
    '0' :: 'X' :: rest => pack rest
    _ => s

||| \(2^{256}\) for two's-complement wrap of signed Integers into uint256.
uint256Modulus : Integer
uint256Modulus =
  0x10000000000000000000000000000000000000000000000000000000000000000

||| ABI word: 32-byte hex (64 chars), no `0x`.
||| Negatives use two's-complement wrap: \(n \bmod 2^{256}\) (Solidity `uint256(int256(n))`).
export
encodeUint256Word : Integer -> String
encodeUint256Word n =
  let wrapped =
        if n >= 0 then n
        else
          let r = n `mod` uint256Modulus
          in if r < 0 then r + uint256Modulus else r
  in padLeft 64 (toHex wrapped)

||| ABI-encode a uint256 for calldata (word only, no selector).
export
encodeUint256 : Integer -> String
encodeUint256 = encodeUint256Word

||| Address → 32-byte left-padded word (no `0x`). Accepts `0x…` or bare hex.
export
encodeAddressWord : String -> String
encodeAddressWord addr =
  let h = strip0x addr
      h40 = if length h > 40 then pack (drop (minus (length h) 40) (unpack h)) else h
  in padLeft 64 h40

||| Pad hex payload to a multiple of 64 chars (32-byte words).
export
padToWordBoundary : String -> String
padToWordBoundary h =
  let len = length h
      rem = len `mod` 64
  in if rem == 0 then h
     else h ++ pack (replicate (minus 64 rem) '0')

||| Encode a dynamic `bytes` value (length word + data, 32-byte padded). Input may be `0x…`.
export
encodeBytes : String -> String
encodeBytes raw =
  let h = strip0x raw
      byteLen = cast {to=Integer} (length h `div` 2)
  in encodeUint256Word byteLen ++ padToWordBoundary h

||| Static-head array of words (address[] / uint256[]): length + elements.
export
encodeWordArray : List String -> String
encodeWordArray words =
  encodeUint256Word (cast {to=Integer} (length words)) ++ fastConcat words

||| `bytes[]`: length, then a dynamic-tuple of blobs (offsets relative to the
||| start of that tuple — i.e. the first offset word — matching Solidity/cast).
export
encodeBytesArray : List String -> String
encodeBytesArray blobs =
  let n = length blobs
      -- offsets counted from the start of the offset table (after length)
      headSize = n * 32
      encodedBlobs = map encodeBytes blobs
      offsets = offsetWords headSize encodedBlobs
  in encodeUint256Word (cast {to=Integer} n)
     ++ fastConcat offsets
     ++ fastConcat encodedBlobs
  where
    offsetWords : Nat -> List String -> List String
    offsetWords _ [] = []
    offsetWords off (blob :: rest) =
      encodeUint256Word (cast {to=Integer} off)
        :: offsetWords (off + (length blob `div` 2)) rest
