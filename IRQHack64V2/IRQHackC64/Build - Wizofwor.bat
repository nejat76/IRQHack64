Call PreBuild.BAT

cd Menus\wizofwor
acme -l labels.txt -r Report.txt main.asm 
cd ..
cd ..
copy /b Menus\Wizofwor\build\menu.prg build\irqhack64.prg

Call PostBuild.BAT

PAUSE