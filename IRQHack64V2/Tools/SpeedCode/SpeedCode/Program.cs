using System;
using System.IO;
using System.Text;

namespace SpeedCode
{
    class Program
    {
        static void Main(string[] args)
        {
            string template = args[0];
            string outputFile = args[1];
            string scParameter = args[2];

            string templateContent = File.ReadAllText(template);

            string outputContent = "";
            switch(scParameter)
            {
                case "IRQ":
                    outputContent = BuildIRQCode(templateContent);
                    break;
                case "NMI":
                    outputContent = BuildNMICode(templateContent);
                    break;
            }

            File.WriteAllText(outputFile, outputContent);

        }


        /*
MRH_{0}      	
	LDA {1}				; 2
	STA ACTUAL_LOW		; 3
	LDA {2}				; 4		
	STA ACTUAL_HIGH	 	; 3
	LDA {3}				; 2			
	STA $D012			; 4
	
	LDA {4}				; 2
	STA IRQ6502			; 4
	LDA {5}				; 2
	STA IRQ6502+1		; 4
	LDY #$00			; 2			
	ASL $D019			; 6
	RTI					; 6	

    */
        static byte[] rasterLine =
        {
            121, 129, 137, 145, 153, 161, 169, 177, 185, 193, 201, 209, 217, 225, 233
        };

        static byte[] low =
        {
            0x90,0xA0,0xB0,0xC0,0xD0,0xE0,0xF0,0x00,0x10,0x20,0xD0,0xE0,0xF0,0x00,0x10,0x20,0x30,0x40,0x50,0x60,0x10,0x20,0x30,0x40,0x50,0x60,0x70,0x80,0x90,0xA0,0x50,0x60,0x70,0x80,0x90,0xA0,0xB0,0xC0,0xD0,0xE0,0x90,0xA0,0xB0,0xC0,0xD0,0xE0,0xF0,0x00,0x10,0x20,0xD0,0xE0,0xF0,0x00,0x10,0x20,0x30,0x40,0x50,0x60
        };

        static byte[] high =
        {
            0xAB,0xAB,0xAB,0xAB,0xAB,0xAB,0xAB,0xAC,0xAC,0xAC,0xAC,0xAC,0xAC,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAE,0xAE,0xAE,0xAE,0xAE,0xAE,0xAE,0xAE,0xAE,0xAE,0xAF,0xAF,0xAF,0xAF,0xAF,0xAF,0xAF,0xAF,0xAF,0xAF,0xB0,0xB0,0xB0,0xB0,0xB0,0xB0,0xB0,0xB1,0xB1,0xB1,0xB1,0xB1,0xB1,0xB2,0xB2,0xB2,0xB2,0xB2,0xB2,0xB2
        };

        private static string BuildIRQCode(string template)
        {
            StringBuilder sb = new StringBuilder();

            int x = 0;

            while (x<900) {

                byte lowAddress = low[x % 60];
                byte highAddress = high[x % 60];
                int currentVector = x == 899 ? 0 : x + 1;
                string current = String.Format(template, x.ToString().PadLeft(3, '0'),
                                                            "#$" + Convert.ToString(lowAddress, 16),
                                                            "#$" + Convert.ToString(highAddress, 16),
                                                            "#$" + Convert.ToString(rasterLine[(x+1) % 15], 16),
                                                            "#<MRH_"  + (currentVector).ToString().PadLeft(3, '0'),
                                                            "#>MRH_" + (currentVector).ToString().PadLeft(3, '0')
                                                            );

                x++;
                sb.Append(current + "\r\n\r\n");

            }



            return sb.ToString();
        }


        private static string BuildNMICode(string template)
        {
            StringBuilder sb = new StringBuilder();

            int v = 0xA000;
            int x = 0;

            while (x < 50)
            {

                int currentVector = x == 49 ? 0 : x + 1;
                string current = String.Format(template, x.ToString().PadLeft(3, '0'),
                                                            "$" + Convert.ToString(v, 16),
                                                            "$" + Convert.ToString(v + 1, 16),
                                                            "$" + Convert.ToString(v + 2, 16),
                                                            "$" + Convert.ToString(v + 3, 16),
                                                            "$" + Convert.ToString(v + 4, 16),
                                                            "$" + Convert.ToString(v + 5, 16),
                                                            "$" + Convert.ToString(v + 6, 16),
                                                            "$" + Convert.ToString(v + 7, 16)//,
                                                            //(currentVector).ToString().PadLeft(3, '0'),
                                                            //(currentVector).ToString().PadLeft(3, '0')
                                                            );

                x++;
                v = v + 8;
                sb.Append(current + "\r\n\r\n");

            }



            return sb.ToString();
        }
    }
}
