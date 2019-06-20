64tass -c -b "KoalaDisplayer.s" -o ..\..\build\plugins\koaplugin.bin --labels ..\..\build\symbol\koala.txt -L ..\..\build\listing\koalaLST.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
GOTO END

:ERRORFINISH
PAUSE
:END