 /*
  *      This program is free software; you can redistribute it and/or
  *      modify it under the terms of the GNU General Public License
  *      as published by the Free Software Foundation; either version
  *      2 of the License, or (at your option) any later version.
  *
  *  Copyright 1999-2005 Michael Klein <michael(dot)klein(at)puffin(dot)lb(dot)shuttle(dot)de>
  *  Copyright 2001-2005 Spiro Trikaliotis
  *
  *  Parts are Copyright
  *      Jouko Valta <jopi(at)stekt(dot)oulu(dot)fi>
  *      Andreas Boose <boose(at)linux(dot)rz(dot)fh-hannover(dot)de>
 */
 
 
 /*-------------------------------------------------------------------*/
 /*--------- ASCII <-> PETSCII CONVERSION FUNCTIONS ------------------*/
 /*
  * 
  *  These functions are taken from VICE's charset.c,
  *  Copyright
  *      Jouko Valta <jopi(at)stekt(dot)oulu(dot)fi>
  *      Andreas Boose <boose(at)linux(dot)rz(dot)fh-hannover(dot)de>
  *
  *  You can get VICE from http://www.viceteam.org/
  */
 
//
// char 
// cbm_ascii2petscii_c(char Character)
// {
//     if ((Character >= 0x5b) && (Character <= 0x7e))
//     {
//         return Character ^ 0x20;
//     }
//     else if ((Character >= 'A') && (Character <= 'Z'))          /* C0 - DF */
//     {
//         return Character | 0x80;
//     }
//     return Character;
// }
// 

