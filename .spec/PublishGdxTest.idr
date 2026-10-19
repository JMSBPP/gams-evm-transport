||| Behavioral: tiny GDX → publishGdx exits 0 only when Anvil apply succeeds.
|||
||| $$
||| \mathrm{publishGdx}() = 0
||| \;\Leftrightarrow\;
||| \mathrm{applyOnChain}(A, B) = \mathrm{Success}
||| $$
||| with $B$ built from a nonempty GDX param unload; JSON alone is not Success.
module PublishGdxTest

import System

import PublishGdx

||| Drive publishGdx; process exit code is the assertion.
main : IO ()
main = publishGdx
