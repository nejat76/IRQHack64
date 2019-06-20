64tass -c -b PatternMatchTest.s -o ..\..\build\PatternMatchTest.bin --labels ..\..\build\PatternMatchTest.txt -L ..\..\build\PatternMatchTestLst.txt
copy /b ..\..\build\IrqLoaderMenu.obj + ..\..\build\PatternMatchTest.bin ..\..\build\PatternMatchTest.prg

PAUSE