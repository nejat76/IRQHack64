64tass -c -b "PrgPluginStub.s" -o PrgPluginStub.bin --labels prgpluginstub.txt -L prgpluginstubLST.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
copy PrgPluginStub.bin E:\Code\ninjatracker\
GOTO END

:ERRORFINISH
PAUSE
:END