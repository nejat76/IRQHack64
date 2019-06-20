64tass -c -b "PrgPlugin.s" -o ..\..\build\plugins\PrgPlugin.bin --labels ..\..\build\symbol\prgplugin.txt -L ..\..\build\listing\prgpluginLST.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
GOTO END

:ERRORFINISH
PAUSE
:END