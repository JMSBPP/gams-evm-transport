module PublishGdx

import Data.String
import System
import System.File

||| Opaque-service stub: Consumed (exit 0) when the path sidecar points at an existing GDX file.
export
publishGdx : IO ()
publishGdx = do
  Right raw <- readFile "build/.gdx-publish-path"
    | Left _ => exitFailure
  let path = trim raw
  False <- pure (path == "")
    | True => exitFailure
  True <- exists path
    | False => exitFailure
  exitSuccess

main : IO ()
main = publishGdx
