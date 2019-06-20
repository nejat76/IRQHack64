Call PreBuild.BAT

cd Menus\I_R_on
64tass -c -b --long-branch IrqLoaderMenuNew.s -o ..\..\build\IrqLoaderMenuNew.bin --labels ..\..\build\symbol\IrqLoaderMenuNew.txt -L ..\..\build\listing\IrqLoaderMenuNewLst.txt
cd ..
cd ..
petcat -w2 <Menus\I_R_on\IrqLoaderMenu.bas >build\IrqLoaderMenu.obj
copy /b build\IrqLoaderMenu.obj + build\IrqLoaderMenuNew.bin build\irqhack64.prg
del build\IrqLoaderMenuNew.bin

64tass -c -b Menus\KeyBooter\KeyBooter.s -o build\KeyBooter.s.bin --labels build\symbol\KeyBooter.txt -L build\listing\KeyBooterLst.txt
copy /b build\IrqLoaderMenu.obj + build\KeyBooter.s.bin build\keybooter.prg
del build\KeyBooter.s.bin


Call PostBuild.BAT


CD plugins\BurstLoader
CALL compile.bat

CD ..\..\

CD plugins\KoalaDisplayer
CALL compile.bat

CD ..\..\

CD plugins\PetsciiDisplayer
CALL compile.bat

CD ..\..\

CD plugins\PrgPlugin
CALL compile.bat

CD ..\..\

CD plugins\WavPlayer
CALL compile.bat

CD ..\..\

del build\defaultmenu.h
del build\IrqLoaderMenu.obj
del build\final.tmp
del build\LoaderStub.h
del build\head.tmp
del build\Flashlib.h
del build\IRQLoader.65s.bin
del build\LoaderStub.65s.bin
del build\Warning.prg


REM ..\Tools\IRQHackSend build\irqhack64.prg COM10

PAUSE