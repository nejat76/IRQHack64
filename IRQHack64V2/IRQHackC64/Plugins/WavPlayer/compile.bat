64tass -c -b "WavPlayer.s" -o ..\..\build\plugins\wavplugin.bin --labels ..\..\build\symbol\wavplugin.txt -L ..\..\build\listing\wavpluginLST.txt

IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
GOTO END

:ERRORFINISH
PAUSE
:END