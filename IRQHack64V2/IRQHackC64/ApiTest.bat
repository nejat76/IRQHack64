E:
cd E:\Code\IRQHack64V2\IRQHackC64
Call PreBuild.BAT

petcat -w2 <Menus\I_R_on\IrqLoaderMenu.bas >build\IrqLoaderMenu.obj

64tass -c -b Menus\ApiTest\ApiTest.s -o build\ApiTest.s.bin --labels build\ApiTest.txt -L build\ApiTestLst.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERRORFINISH
copy /b build\IrqLoaderMenu.obj + build\ApiTest.s.bin build\demo.prg
copy build\demo.prg Menus\ApiTest\

..\Tools\IRQHackSend build\demo.prg COM10

:ERRORFINISH
PAUSE