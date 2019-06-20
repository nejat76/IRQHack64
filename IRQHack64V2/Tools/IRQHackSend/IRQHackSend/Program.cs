using System;
using System.Threading;
using System.IO.Ports;
using System.Text;
using System.IO;
using System.Collections.Generic;

namespace IRQHackSend
{
	//TODO : Refactor code to use IRQHack64Access class
    class Program
    {
		const string COMMAND_READ_FILE = "ReadFile"; 
		const string COMMAND_OPEN_FILE = "OpenFile"; 
		const string COMMAND_CLOSE_FILE = "CloseFile";
		const string COMMAND_WRITE_FILE = "WriteFile";
		const string COMMAND_DELETE_FILE = "DeleteFile";
		const string COMMAND_SEEK_FILE = "SeekFile";
		const string COMMAND_LONG_SEEK_FILE = "LongSeekFile";
        const string COMMAND_GET_INFO_FOR_FILE = "GetInfoForFile";
        const string COMMAND_READ_DIR = "ReadDir";
		const string COMMAND_CHANGE_DIR = "ChangeDir";
		const string COMMAND_DELETE_DIR = "DeleteDir";
        const string COMMAND_CREATE_DIR = "CreateDir";
        const string COMMAND_READ_EEPROM = "ReadEeprom";
		const string COMMAND_SEEK_EEPROM = "SeekEeprom";
		const string COMMAND_WRITE_EEPROM = "WriteEeprom";

        enum Commands : byte
        {
            COMMAND_READ_FILE = 1,
            COMMAND_OPEN_FILE = 2,
            COMMAND_CLOSE_FILE = 3,
            COMMAND_WRITE_FILE = 4,
            COMMAND_DELETE_FILE = 5,
            COMMAND_SEEK_FILE = 6,
            COMMAND_LONG_SEEK_FILE = 7,
            COMMAND_GET_INFO_FOR_FILE = 8,

            COMMAND_READ_DIR = 10,
            COMMAND_CHANGE_DIR = 11,
            COMMAND_DELETE_DIR = 12,
            COMMAND_CREATE_DIR = 13,

            COMMAND_READ_EEPROM = 15,
            COMMAND_SEEK_EEPROM = 16,
            COMMAND_WRITE_EEPROM = 17
        };

        static void Receive(SerialPort port)
        {
            Console.Out.WriteLine();
            Console.Out.Write(">>> Transmission from micro start");
            Console.Out.WriteLine();
            while (port.BytesToRead>0)
            {
                int character = port.ReadChar();
                Console.Out.Write((char)character);
            }
            Console.Out.WriteLine();
            Console.Out.Write("<<< Transmission from micro ends");
            Console.Out.WriteLine();
        }


        static void SendFile(string prgFile, string comPort)
		{
			SerialPort port = SetSerialPort(comPort);

			try
			{
				port.Open();
			}
			catch (Exception ex)
			{
				Console.Out.WriteLine("Port open failed!");
				throw ex;
			}

			byte[] fileContents;

			try
			{
				fileContents = File.ReadAllBytes(prgFile);
			}
			catch (Exception ex)
			{
				Console.Out.WriteLine("Failed reading file!");
				throw ex;
			}

			Receive(port);

			if (fileContents.Length > 65535) throw new Exception("File is too long!");

			Console.Out.WriteLine(String.Format("{0} is opened", comPort));
			Console.Out.WriteLine("Waiting arduino to initialize");
			Thread.Sleep(100); //Wait arduino to come alive.
			port.Write(new char[] { '1' }, 0, 1); //Send 1 byte command '1'
			Console.Out.WriteLine("Send ReceiveFile command");
			//Wait as much as 2 seconds for the c64 to reset and the circuit to receive what we are
			//sending


			Receive(port);

			Console.Out.WriteLine("Waiting for C64 to reset");
			Thread.Sleep(300);

			//Send length of prg file
			byte low = (byte)(fileContents.Length % 256);
			byte high = (byte)(fileContents.Length / 256);

			port.Write(new byte[] { low, high }, 0, 2);

			for (int i = 0; i < 2; i++)
			{
				port.Write(new byte[] { fileContents[i] }, 0, 1);
				//if (i % 32 == 0)
				//{
				//    Thread.Sleep(1);
				//}

			}

			for (int i = 2; i < fileContents.Length; i++)
			{
				port.Write(new byte[] { fileContents[i] }, 0, 1);
				//if (i%32 == 0)
				//{
				//    Thread.Sleep(10);
				//}

			}

			Receive(port);
			Thread.Sleep(100);
			Receive(port);
			Thread.Sleep(10000);
			port.Close();

			Console.ReadLine();
		}

		static SerialPort SetSerialPort(string comPort)
		{
			SerialPort port = new SerialPort();
			port.BaudRate = 57600;
			port.DataBits = 8;
			port.StopBits = StopBits.One;
			port.RtsEnable = false;
			port.Parity = Parity.None;
			port.PortName = comPort;
			return port;
		}

		static void OpenMenu(string comPort)
        {
            SerialPort port = new SerialPort();
            port.BaudRate = 57600;
            port.DataBits = 8;
            port.StopBits = StopBits.One;
            port.RtsEnable = false;
            port.Parity = Parity.None;
            port.PortName = comPort;

            try
            {
                port.Open();
            }
            catch (Exception ex)
            {
                Console.Out.WriteLine("Port open failed!");
                throw ex;
            }

            Receive(port);

            Console.Out.WriteLine(String.Format("{0} is opened", comPort));

            port.Write(new char[] { '2' }, 0, 1); //Send 1 byte command '1'
            Console.Out.WriteLine("Send OpenMenu command");
  
            Receive(port);

            port.Close();

            Console.ReadLine();
        }

        static void Main(string[] args)
        {
			//WriteFile("irqhack64.prg", "COM3");
			//return;
			string option = args[0];

			if (option == "L")
			{
				string prgFile = args[1];
				string comPort = args[2];

				SendFile(prgFile, comPort);
			}
			else if (option == "W")
			{
				string prgFile = args[1];
				string comPort = args[2];

				WriteFile(prgFile, comPort);
			} 
			else if (option == "C")
			{
				string comPort = args[1];
				TestConsole(comPort);
			} else if (option == "WW")
            {
                string prgFile = args[1];
                string comPort = args[2];

                WriteFileNew(prgFile, comPort);
            }
            //OpenMenu(comPort);
        }

		static void TestConsole(string comPort)
		{
			SerialPort port = SetSerialPort(comPort);

			try
			{
				port.Open();
			}
			catch (Exception ex)
			{
				Console.Out.WriteLine("Port open failed!");
				throw ex;
			}

			Receive(port);

			Console.Out.WriteLine(String.Format("{0} is opened", comPort));
			Console.Out.WriteLine("Waiting arduino to initialize");
			Thread.Sleep(100); //Wait arduino to come alive.
			port.Write(new char[] { '7' }, 0, 1); //Send 1 byte command '1'
			Console.Out.WriteLine("Send SerialTestTerminal command");
            Thread.Sleep(300); //Wait arduino to come alive.
            Receive(port);
            //byte[] initialize = new byte[] {73, 82, 81};
            //port.Write(initialize, 0, 3);
            while (true)
			{
				string command = Console.ReadLine();
				if (command == "X")
				{
					port.Close();
					return;
				}

				HandleCommand(command, port);
			}
		}

		static void HandleCommand(string commandWithArguments, SerialPort port)
		{			
			string[] commandArgs = commandWithArguments.Split(' ');
			if (commandArgs.Length > 0)
			{
				string command = commandArgs[0];

				switch (command)
				{
					case COMMAND_READ_FILE: HandleReadFile(port, commandArgs); break;
					case COMMAND_OPEN_FILE: HandleOpenFile(port, commandArgs); break;
					case COMMAND_CLOSE_FILE: HandleCloseFile(port); break;
					case COMMAND_WRITE_FILE: HandleWriteFile(port, commandArgs); break;
					case COMMAND_DELETE_FILE: HandleDeleteFile(port, commandArgs[1]); break;
					case COMMAND_SEEK_FILE: HandleSeekFile(port, commandArgs); break;
					case COMMAND_LONG_SEEK_FILE: HandleLongSeekFile(port, commandArgs); break;
                    case COMMAND_GET_INFO_FOR_FILE: HandleGetInfoForFile(port, commandArgs); break;
                    case COMMAND_READ_DIR: HandleReadDirectory(port, commandArgs); break;
					case COMMAND_CHANGE_DIR: HandleChangeDirectory(port, commandArgs[1]); break;
					case COMMAND_DELETE_DIR: HandleDeleteDirectory(port, commandArgs[1]); break;
                    case COMMAND_CREATE_DIR: HandleCreateDirectory(port, commandArgs[1]); break;
                    case COMMAND_READ_EEPROM: HandleReadEeprom(port, commandArgs); break;
					case COMMAND_SEEK_EEPROM: HandleSeekEeprom(port, commandArgs); break;
					case COMMAND_WRITE_EEPROM: HandleWriteEeprom(port, commandArgs); break;
				}

			}

		}

        static bool HandleValueResponse(SerialPort port, out byte value)
        {
            value = 0;
            int response = port.ReadByte();
            if ((response & 0x80) > 0)
            {
                Console.Out.WriteLine("Success");
                int extraResponse = port.ReadByte();

                value = (byte)((extraResponse << 1) | (response & 0x01));
                return true;
            }
            else
            {
                Console.Out.WriteLine(String.Format("Failed : {0}", response.ToString("X")));
                return false;
            }
        }

        static bool HandleResponse(SerialPort port)
		{
			//while (port.BytesToRead == 0) {}
			int response = port.ReadByte();
			if ((response & 0x80)>0)
			{
				Console.Out.WriteLine("Success");
				return true;
			}
			else {
				Console.Out.WriteLine(String.Format("Failed : {0}", response.ToString("X")));
				return false;
			}
		}

		static void HandleInvalidParameter(string parameterName)
		{
			Console.Out.WriteLine(String.Format("Invalid parameter : {0}", parameterName));
		}

		static void HandleWriteEeprom(SerialPort port, string[] commandArgs)
		{
            byte value;
            if (byte.TryParse(commandArgs[1], out value))
            {
                port.Write(new byte[] { (byte)Commands.COMMAND_WRITE_EEPROM }, 0, 1); 
                port.Write(new byte[] { value }, 0, 1);

                HandleResponse(port);
            } else
            {
                HandleInvalidParameter("Value");
                return;
            }
        }

		static void HandleSeekEeprom(SerialPort port, string[] commandArgs)
		{
            ushort address = 0;

            if (ushort.TryParse(commandArgs[1], out address) && address<1024)
            {
                port.Write(new byte[] { (byte) Commands.COMMAND_SEEK_EEPROM }, 0, 1); 
                port.Write(new byte[] { (byte) (address>>8) }, 0, 1); 
                port.Write(new byte[] { (byte) (address & 0xFF) }, 0, 1);

                HandleResponse(port);
            } else
            {
                HandleInvalidParameter("Address");
                return;
            }

        }

		static void HandleReadEeprom(SerialPort port, string[] commandArgs)
		{
            port.Write(new byte[] { (byte) Commands.COMMAND_READ_EEPROM }, 0, 1); 
            byte value;

            HandleValueResponse(port, out value);
            Console.Out.WriteLine(value);
        }

		static void HandleDeleteDirectory(SerialPort port, string v)
		{
            byte[] fileName = Encoding.ASCII.GetBytes(v);
            port.Write(new byte[] { (byte) Commands.COMMAND_DELETE_DIR }, 0, 1);
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            HandleResponse(port);
        }

        private static void HandleCreateDirectory(SerialPort port, string v)
        {
            byte[] fileName = Encoding.ASCII.GetBytes(v);
            port.Write(new byte[] { (byte) Commands.COMMAND_CREATE_DIR }, 0, 1);
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            HandleResponse(port);
        }

        static void HandleChangeDirectory(SerialPort port, string v)
		{
            byte[] fileName = Encoding.ASCII.GetBytes(v);
            port.Write(new byte[] { (byte) Commands.COMMAND_CHANGE_DIR }, 0, 1); //Change directory
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            HandleResponse(port);
        }

		static void HandleReadDirectory(SerialPort port, string[] commandArgs)
		{
            byte numberOfEntries;
            byte dataLength;
            if (commandArgs.Length < 2 || !byte.TryParse(commandArgs[1], out numberOfEntries))
            {
                HandleInvalidParameter("NumberOfEntries");
                return;
            }

            if (commandArgs.Length < 3 || !byte.TryParse(commandArgs[2], out dataLength))
            {
                HandleInvalidParameter("DataLength");
                return;
            }

            port.Write(new byte[] { (byte) Commands.COMMAND_READ_DIR }, 0, 1); 
            port.Write(new byte[] { numberOfEntries }, 0, 1);
            port.Write(new byte[] { dataLength }, 0, 1);
            bool isSuccessful = HandleResponse(port);
            Thread.Sleep(100);
            if (isSuccessful)
            {
                int actualLength = dataLength * 256;
                byte[] received = new byte[actualLength + 2];

                port.Read(received, 0, actualLength + 2);

                Console.Out.WriteLine("Current Items Count : " + received[0]);
                Console.Out.WriteLine("Total Items Count : " + received[1]);
                List<string> names = GetNames(received);
                for (int i = 0;i<names.Count;i++)
                {
                    Console.Out.WriteLine(names[i]);
                }
            }

            Thread.Sleep(100);
            Receive(port);

        }

        private static List<string> GetNames(byte[] received)
        {
            List<string> names = new List<string>();
            StringBuilder sb = new StringBuilder();
            bool stringStarted = false;

            for (int i = 2;i<received.Length;i++)
            {
                if (received[i]!=0)
                {
                    if (sb.Length == 0) { stringStarted = true; }
                    sb.Append((char)received[i]);
                } else
                {
                    if (stringStarted)
                    {
                        names.Add(sb.ToString());
                        sb.Clear();
                        stringStarted = false;
                    } 
                }
            }

            return names;
        }

        static void HandleLongSeekFile(SerialPort port, string[] commandArgs)
		{
            byte seekDirection;
            uint seekLength;

            if (byte.TryParse(commandArgs[1], out seekDirection))
            {
                if ((uint.TryParse(commandArgs[2], out seekLength)))
                {
                    port.Write(new byte[] { (byte) Commands.COMMAND_LONG_SEEK_FILE }, 0, 1); 
                    port.Write(new byte[] { seekDirection }, 0, 1);
                    port.Write(new byte[] { (byte)(seekLength & 255) }, 0, 1);
                    port.Write(new byte[] { (byte)((seekLength >> 8) & 255) }, 0, 1);
                    port.Write(new byte[] { (byte)((seekLength >> 16) & 255) }, 0, 1);
                    port.Write(new byte[] { (byte)((seekLength >> 24) & 255) }, 0, 1);

                    HandleResponse(port);
                }
                else
                {
                    HandleInvalidParameter("SeekLength");
                }
            }
            else
            {
                HandleInvalidParameter("SeekDirection");
            }
        }

		static void HandleSeekFile(SerialPort port, string[] commandArgs)
		{
            byte seekDirection;
            ushort seekLength;

            if (byte.TryParse(commandArgs[1], out seekDirection))
            {
                if ((ushort.TryParse(commandArgs[2], out seekLength))) {
                    port.Write(new byte[] { (byte) Commands.COMMAND_SEEK_FILE }, 0, 1); 
                    port.Write(new byte[] { seekDirection }, 0, 1);
                    port.Write(new byte[] { (byte)(seekLength & 255) }, 0, 1);
                    port.Write(new byte[] { (byte)(seekLength >>8) }, 0, 1);

                    HandleResponse(port);
                } else
                {
                    HandleInvalidParameter("SeekLength");
                }
            } else
            {
                HandleInvalidParameter("SeekDirection");
            }
        }

		static void HandleDeleteFile(SerialPort port, string v)
		{
            byte[] fileName = Encoding.ASCII.GetBytes(v);
            port.Write(new byte[] { (byte) Commands.COMMAND_DELETE_FILE }, 0, 1);
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            HandleResponse(port);
        }

		static void HandleWriteFile(SerialPort port, string[] commandArgs)
		{
            byte[] buffer = new byte[32];
            for (int i=0;i<32;i++)
            {
                if (!byte.TryParse(commandArgs[i+1], out buffer[i]))
                {
                    HandleInvalidParameter("BytesToWrite");
                    return;
                }
            }

            port.Write(new byte[] { (byte) Commands.COMMAND_WRITE_FILE }, 0, 1);
            Thread.Sleep(50);
            port.Write(buffer, 0, 32);

            HandleResponse(port);
        }

		static void HandleCloseFile(SerialPort port)
		{
            port.Write(new byte[] { (byte) Commands.COMMAND_CLOSE_FILE }, 0, 1); 

            HandleResponse(port);
        }

		static void HandleReadFile(SerialPort port, string[] commandArgs)
		{
			byte blocksToRead;
			if (byte.TryParse(commandArgs[1], out blocksToRead)) {
                port.Write(new byte[] { (byte) Commands.COMMAND_READ_FILE }, 0, 1); 
                Thread.Sleep(10);
                port.Write(new byte[] { blocksToRead }, 0, 1); 
                bool isSuccessful = HandleResponse(port);
                Thread.Sleep(50);
                if (isSuccessful)
                {
                    HandleByteStreamResponse(port, blocksToRead * 256);
                }
            }
			else {
				HandleInvalidParameter("DataLength");
			}
		}

        static void HandleGetInfoForFile(SerialPort port, string[] commandArgs)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_GET_INFO_FOR_FILE }, 0, 1);
            Thread.Sleep(10);
            bool isSuccessful = HandleResponse(port);
            Thread.Sleep(50);
            if (isSuccessful)
            {
                HandleByteStreamResponse(port, 256);
            }
        }

        static void DumpBuffer(byte[] buffer)
		{
			for (int i = 0; i < 16; i++)
			{
				Console.Out.Write(String.Format("{0:X2}", buffer[i]) + " ");
			}
			Console.Out.WriteLine();
		}

		static void HandleByteStreamResponse(SerialPort port, int v)
		{
			int count = v / 16;
			byte[] buffer = new byte[16];

			for (int i = 0; i < count; i++)
			{
				port.Read(buffer, 0, 16);
				DumpBuffer(buffer);
			}
		}

		static void HandleOpenFile(SerialPort port, string[] commandArgs)
		{
            string v = commandArgs[1];
            byte flags;
            byte[] fileName = Encoding.ASCII.GetBytes(v);

            if (commandArgs.Length<3 || !byte.TryParse(commandArgs[2], out flags))
            {
                HandleInvalidParameter("Flags");
                return;
            }
            port.Write(new byte[] { (byte) Commands.COMMAND_OPEN_FILE }, 0, 1);
            port.Write(new byte[] { flags }, 0, 1);
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

			HandleResponse(port);

		}

		static void WriteFile(string prgFile, string comPort)
		{
			SerialPort port = SetSerialPort(comPort);
			
			try
			{
				port.Open();
			}
			catch (Exception ex)
			{
				Console.Out.WriteLine("Port open failed!");
				throw ex;
			}

			byte[] fileContents;

			try
			{
				fileContents = File.ReadAllBytes(prgFile);
			}
			catch (Exception ex)
			{
				Console.Out.WriteLine("Failed reading file!");
				throw ex;
			}

			Receive(port);

			if (fileContents.Length > 65535) throw new Exception("File is too long!");

			Console.Out.WriteLine(String.Format("{0} is opened", comPort));
			Console.Out.WriteLine("Waiting arduino to initialize");
			Thread.Sleep(100); //Wait arduino to come alive.
			port.Write(new char[] { '5' }, 0, 1); //Send 1 byte command '1'
			Console.Out.WriteLine("Send UpdateFile command");

			Receive(port);

			Console.Out.WriteLine("Waiting for micro");
			Thread.Sleep(300);

			byte[] asciiBytes = Encoding.ASCII.GetBytes(prgFile);

			for (int i = 0; i < asciiBytes.Length; i++)
			{
				port.Write(new byte[] { asciiBytes[i] }, 0, 1);
			}

			port.Write(new byte[] { 0 }, 0, 1);

			Thread.Sleep(300);

			//Send length of prg file
			byte low = (byte)(fileContents.Length % 256);
			byte high = (byte)(fileContents.Length / 256);

			port.Write(new byte[] { low, high }, 0, 2);


			for (int i = 0; i < fileContents.Length; i++)
			{
				port.Write(new byte[] { fileContents[i] }, 0, 1);
				if (i%32 == 0)
				{
				    Thread.Sleep(10);
				}
			}

			Thread.Sleep(50);
			Receive(port);
			Thread.Sleep(100);
			Receive(port);
			port.Close();

			Console.ReadLine();

		}

        static void WriteFileNew(string prgFile, string comPort)
        {
            IRQHack64Access access = new IRQHack64Access(comPort);
            const int WriteBufferLength = 32;

            //byte[] fileContents = File.ReadAllBytes(@"C:\Users\nejat\Documents\Sources\IRQHack64V2\IRQHackC64\Menus\Demo\demo.prg");
			byte[] fileContents = File.ReadAllBytes(prgFile);
            byte[] writeBuffer = new byte[WriteBufferLength];

            if (fileContents.Length > 65535) throw new Exception("File is too long!");


            int count = fileContents.Length / WriteBufferLength;
            int pad = fileContents.Length % WriteBufferLength;

            string initResponse = access.Init();
            Console.Out.WriteLine(initResponse);

            access.DeleteFile("demo.prg");
            Thread.Sleep(500);
            byte response = access.OpenFile("demo.prg", 66);

            if ((response & 0x80)>0)
            {
                for (int i = 0; i < count;i++)
                {
                    Array.Copy(fileContents, i * WriteBufferLength, writeBuffer, 0, WriteBufferLength);
                    response = access.WriteFile(writeBuffer);

                    if ((response & 0x80) == 0)
                    {
                        Console.Out.WriteLine(String.Format("Writing failed at {0}, Error : {1}, closing file", i, response));
                        response = access.CloseFile();
                        if ((response & 0x80) == 0)
                        {
                            Console.Out.WriteLine(String.Format("Closing failed! Error : {0}", response));
                            return;
                        }

                        return;
                    }else
                    {
                        Console.Out.WriteLine("Written, at : " + i * 32);
                    }
                }

                access.CloseFile();
                //if (pad > 0)
                //{
                //    uint padPosition = Convert.ToUInt32(fileContents.Length - pad);

                //    Array.Copy(fileContents, padPosition, writeBuffer, 0, pad);
                //    response = access.LongSeekFile(0, padPosition);
                //    if ((response & 0x80) == 0)
                //    {
                //        Console.Out.WriteLine(String.Format("Seeking failed! Error : {0}", response));
                //        return;
                //    }
                //    response = access.WriteFile(writeBuffer);
                //    if ((response & 0x80) == 0)
                //    {
                //        Console.Out.WriteLine(String.Format("Final write failed! Error : {0}", response));
                //        return;
                //    }

                //}


            } else
            {
                Console.Out.WriteLine(String.Format("Can't open file! : {0}", response));
            }

            Console.Out.WriteLine("Finished writing");

            Console.ReadLine();


        }

    }
}
