||| Web3 Multicall-ready batch.
||| Mirrors schema/MulticallBatch.json (regenerate via `just gdx-schema`).
||| Shape: ordered list of {target, data} for Multicall3 / Solady multicall(bytes[]).
module MulticallBatch

||| One call entry for a web3 Multicall API.
public export
record Call where
  constructor MkCall
  target : String
  data_ : String

||| Ordered multicall batch (index 0 first).
public export
record MulticallBatch where
  constructor MkMulticallBatch
  calls : List Call

export
emptyBatch : MulticallBatch
emptyBatch = MkMulticallBatch []

||| Append one call (preserves order: earlier appends stay earlier).
export
appendCall : MulticallBatch -> Call -> MulticallBatch
appendCall (MkMulticallBatch cs) c = MkMulticallBatch (cs ++ [c])

||| Solady Multicallable view: list of call data blobs.
export
toSoladyBytes : MulticallBatch -> List String
toSoladyBytes (MkMulticallBatch cs) = map data_ cs

||| Multicall3-style view: (target, data) pairs.
export
toMulticall3Calls : MulticallBatch -> List (String, String)
toMulticall3Calls (MkMulticallBatch cs) = map (\c => (c.target, c.data_)) cs
