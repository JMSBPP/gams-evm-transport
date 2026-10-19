$onText
==========================================================================
------------------> GdxWriter < ----------------------------------------
  Execution-time GDX unload helpers (not compile-time $gdx*).
==========================================================================
$offText

$if set gdxWriterIncluded $goto gdx_writer_done
$set gdxWriterIncluded

* Usage: gdxWrite('build/foo.gdx') sym1, sym2, … ;
* Expands to: execute_unload 'build/foo.gdx', sym1, sym2, … ;
$macro gdxWrite(path) execute_unload path,

$label gdx_writer_done
