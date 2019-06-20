64tass -c -b BurstLoaderTest.s -o ..\..\build\BurstLoaderTest.bin --labels ..\..\build\symbol\BurstLoaderTest.txt -L ..\..\build\listing\BurstLoaderTestLST.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
copy /b ..\..\build\IrqLoaderMenu.obj + ..\..\build\BurstLoaderTest.bin ..\..\build\burstloadert.prg
GOTO END

:ERRORFINISH
PAUSE
:END
PAUSE