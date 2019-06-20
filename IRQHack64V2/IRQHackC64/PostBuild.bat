64tass -c -b Menus\WarningMenu\Warning.s -o build\Warning.bin  --labels build\symbol\Warning.s.txt
copy /b build\IrqLoaderMenu.obj + build\Warning.bin build\warning.prg
del build\Warning.bin

..\tools\bin2Ardh build\warning.prg build\defaultmenu.h data_len cartridgeData
..\tools\bin2Ardh build\LoaderStub.65s.bin build\LoaderStub.h stub_len stubData
copy avrincludehead.txt+build\defaultmenu.h build\head.tmp
copy build\head.tmp + build\LoaderStub.h build\final.tmp

copy build\final.tmp+avrincludefoot.txt  build\FlashLib.h
copy build\FlashLib.h ..\Arduino\IRQHack64\FlashLib.h




..\tools\CreateEpromLoader build\IRQLoader.65s.bin build\IRQLoaderRom.bin 171 166 103 141 121 151 146 161 156 195 176 255