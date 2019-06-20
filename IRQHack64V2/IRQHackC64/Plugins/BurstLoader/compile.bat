64tass -c -b BurstLoader.s -o ..\..\build\plugins\cvidplugin.bin --labels ..\..\build\symbol\BurstLoader.txt -L ..\..\build\listing\BurstLoaderLST.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
copy /b ..\..\build\IrqLoaderMenu.obj + ..\..\build\plugins\cvidplugin.bin ..\..\build\plugins\cvidplugin.prg
del ..\..\build\plugins\cvidplugin.bin
GOTO END

:ERRORFINISH
PAUSE
:END
