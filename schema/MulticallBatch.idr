module Main

namespace Main
    namespace Calls
        public export
        record CallsItem where
            constructor MkCallsItem
            target : String
            data_ : String

public export
record Main where
    constructor MkMain
    calls : List Main.Main.Calls.CallsItem
