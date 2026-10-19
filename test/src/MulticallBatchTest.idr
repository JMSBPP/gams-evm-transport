module MulticallBatchTest

import MulticallBatch

||| Empty batch has no calls.
export
testEmpty : Bool
testEmpty = null (calls emptyBatch)

||| Append preserves index order (first appended = index 0).
export
testAppendOrder : Bool
testAppendOrder =
  let b0 = emptyBatch
      b1 = appendCall b0 (MkCall "0x1" "0xaa")
      b2 = appendCall b1 (MkCall "0x2" "0xbb")
  in toSoladyBytes b2 == ["0xaa", "0xbb"]
     && toMulticall3Calls b2 == [("0x1", "0xaa"), ("0x2", "0xbb")]
