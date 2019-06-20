64tass -c -b "PetsciiDisplayer.s" -o ..\..\build\plugins\petgplugin.bin --labels ..\..\build\symbol\petgplugin.txt -L ..\..\build\listing\petgpluginLST.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
GOTO END

:ERRORFINISH
PAUSE
:END