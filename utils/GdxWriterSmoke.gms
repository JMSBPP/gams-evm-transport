$title GdxWriterSmoke
$include GdxWriter.gms

Set DemoSet / a, b /;
Parameter DemoParam(DemoSet);
DemoParam('a') = 1;
DemoParam('b') = 2;

gdxWrite('build/gdx_writer_smoke.gdx') DemoSet, DemoParam;
