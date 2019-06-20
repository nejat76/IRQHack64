64tass -c -b Loader\LoaderStub.65s -o build\LoaderStub.65s.bin --labels build\symbol\LoaderStub.65s.txt
64tass -c -b Loader\IRQLoader.65s -o build\IRQLoader.65s.bin --labels build\symbol\IRQLoader.txt

petcat -w2 <Menus\I_R_on\IrqLoaderMenu.bas >build\IrqLoaderMenu.obj