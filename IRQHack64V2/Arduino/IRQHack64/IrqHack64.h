#ifndef _IRQHACK64_
#include <avr/pgmspace.h>


#define _IRQHACK64_

#define TYPE_MENU 0
#define TYPE_STANDARD_PRG 1
#define TYPE_CARTRIDGE 2
#define TYPE_BOOTER 3
#define TYPE_PRG_TRANSMISSION 4

#define CALLER_HANDLES_DIRECTORIES

#define DEBUG

//#define NOOUT
#define USERAMLAUNCHER
//#define PATCHPROCESSORPORTACCESS

//#define TEST_TERMINAL_MODE


#endif
