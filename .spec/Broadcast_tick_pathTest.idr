||| Behavioral: tiny GDX → broadcast_tick_path exits 0 only when Anvil apply succeeds.
|||
||| $$
||| \mathrm{broadcast\_tick\_path}() = 0
||| \;\Leftrightarrow\;
||| \mathrm{applyOnChain}(A, B) = \mathrm{Success}(h)
||| $$
||| with $B$ built from a nonempty GDX param unload; JSON alone is not Success.
||| stdout includes the tx hash $h$.
module Broadcast_tick_pathTest

import System

import Broadcast_tick_path

||| Drive broadcast_tick_path; process exit code is the assertion.
main : IO ()
main = broadcast_tick_path
