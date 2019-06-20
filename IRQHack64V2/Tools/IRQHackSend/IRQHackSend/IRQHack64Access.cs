using System;
using System.Threading;
using System.IO.Ports;
using System.Text;
using System.IO;
using System.Collections.Generic;

namespace IRQHackSend
{
    public class IRQHack64Access
    {
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

        private SerialPort port;

        public IRQHack64Access(string comPort)
        {
            port = SetSerialPort(comPort);
        }


        static string CleanPort(SerialPort port)
        {
            StringBuilder sb = new StringBuilder();
           
            while (port.BytesToRead > 0)
            {
                int character = port.ReadChar();
                sb.Append((char)character);
            }

            return sb.ToString();
        }

        public string Init()
        {
            port.Open();
            string initString = CleanPort(port);
            Thread.Sleep(100); //Wait arduino to come alive.
            port.Write(new char[] { '7' }, 0, 1); 
            Thread.Sleep(300); //Wait arduino to come alive.
            string finishingString = CleanPort(port);
            return initString + finishingString;
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


        public byte OpenFile(string fileName, byte flags)
        {
            byte[] fileNameBytes = Encoding.ASCII.GetBytes(fileName);

            port.Write(new byte[] { (byte)Commands.COMMAND_OPEN_FILE }, 0, 1);
            port.Write(new byte[] { flags }, 0, 1);
            port.Write(new byte[] { (byte)(fileNameBytes.Length + 1) }, 0, 1);
            port.Write(fileNameBytes, 0, fileNameBytes.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte WriteEeprom(byte value)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_WRITE_EEPROM }, 0, 1);
            port.Write(new byte[] { value }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte SeekEeprom(ushort address)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_SEEK_EEPROM }, 0, 1);
            port.Write(new byte[] { (byte)(address >> 8) }, 0, 1);
            port.Write(new byte[] { (byte)(address & 0xFF) }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte ReadEeprom()
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_READ_EEPROM }, 0, 1);
            byte value;

            HandleValueResponse(port, out value);
            return value;
        }

        public byte DeleteDirectory(string dirName)
        {
            byte[] fileName = Encoding.ASCII.GetBytes(dirName);
            port.Write(new byte[] { (byte)Commands.COMMAND_DELETE_DIR }, 0, 1);
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte CreateDirectory(string dirName)
        {
            byte[] fileName = Encoding.ASCII.GetBytes(dirName);
            port.Write(new byte[] { (byte)Commands.COMMAND_CREATE_DIR }, 0, 1);
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte ChangeDirectory(string dirName)
        {
            byte[] fileName = Encoding.ASCII.GetBytes(dirName);
            port.Write(new byte[] { (byte)Commands.COMMAND_CHANGE_DIR }, 0, 1); //Change directory
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileName.Length + 1) }, 0, 1);
            port.Write(fileName, 0, fileName.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            return (byte)port.ReadByte();
        }

        public List<string> ReadDirectory(byte numberOfEntries, byte dataLength, out byte returnValue)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_READ_DIR }, 0, 1);
            port.Write(new byte[] { numberOfEntries }, 0, 1);
            port.Write(new byte[] { dataLength }, 0, 1);
            bool isSuccessful = HandleResponse(port, out returnValue);
            Thread.Sleep(100);
            if (isSuccessful)
            {
                int actualLength = dataLength * 256;
                byte[] received = new byte[actualLength + 2];

                port.Read(received, 0, actualLength + 2);

                List<string> names = GetNames(received);
                return names;
            }
            return null;
        }

        public byte LongSeekFile(byte seekDirection, uint seekLength)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_LONG_SEEK_FILE }, 0, 1);
            port.Write(new byte[] { seekDirection }, 0, 1);
            port.Write(new byte[] { (byte)(seekLength & 255) }, 0, 1);
            port.Write(new byte[] { (byte)((seekLength >> 8) & 255) }, 0, 1);
            port.Write(new byte[] { (byte)((seekLength >> 16) & 255) }, 0, 1);
            port.Write(new byte[] { (byte)((seekLength >> 24) & 255) }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte SeekFile(byte seekDirection,  ushort seekLength)
        { 
            port.Write(new byte[] { (byte)Commands.COMMAND_SEEK_FILE }, 0, 1);
            port.Write(new byte[] { seekDirection }, 0, 1);
            port.Write(new byte[] { (byte)(seekLength & 255) }, 0, 1);
            port.Write(new byte[] { (byte)(seekLength >> 8) }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte DeleteFile(string fileName)
        {
            byte[] fileNameBytes = Encoding.ASCII.GetBytes(fileName);
            port.Write(new byte[] { (byte)Commands.COMMAND_DELETE_FILE }, 0, 1);
            port.Write(new byte[] { 0 }, 0, 1); //Reserved flags
            port.Write(new byte[] { (byte)(fileNameBytes.Length + 1) }, 0, 1);
            port.Write(fileNameBytes, 0, fileNameBytes.Length);
            port.Write(new byte[] { 0 }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte WriteFile(byte[] buffer)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_WRITE_FILE }, 0, 1);
            Thread.Sleep(50);
            port.Write(buffer, 0, 32);

            return (byte)port.ReadByte();
        }

        public byte CloseFile()
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_CLOSE_FILE }, 0, 1);

            return (byte)port.ReadByte();
        }

        public byte[] ReadFile(byte blocksToRead, out byte returnValue)
        {

            port.Write(new byte[] { (byte)Commands.COMMAND_READ_FILE }, 0, 1);
            Thread.Sleep(10);
            port.Write(new byte[] { blocksToRead }, 0, 1);
            bool isSuccessful = HandleResponse(port, out returnValue);
            Thread.Sleep(50);
            if (isSuccessful)
            {
                return GetByteStream(blocksToRead * 256);
            } else
            {
                return null;
            }
        }

        public byte[] GetInfoForFile(out byte returnValue)
        {
            port.Write(new byte[] { (byte)Commands.COMMAND_GET_INFO_FOR_FILE }, 0, 1);
            Thread.Sleep(10);
            bool isSuccessful = HandleResponse(port, out returnValue );
            Thread.Sleep(50);
            if (isSuccessful)
            {
                return GetByteStream(256);
            } else
            {
                return null;
            }
        }


        private byte[] GetByteStream(int totalLength)
        {
            int count = totalLength / 16;
            byte[] buffer = new byte[16];
            byte[] read = new byte[totalLength];

            for (int i = 0; i < count; i++)
            {
                port.Read(buffer, 0, 16);
                Array.Copy(buffer, 0, read, i * 16, 16);
            }

            return read;
        }

        private static List<string> GetNames(byte[] received)
        {
            List<string> names = new List<string>();
            StringBuilder sb = new StringBuilder();
            bool stringStarted = false;

            for (int i = 2; i < received.Length; i++)
            {
                if (received[i] != 0)
                {
                    if (sb.Length == 0) { stringStarted = true; }
                    sb.Append((char)received[i]);
                }
                else
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

        static bool HandleValueResponse(SerialPort port, out byte value)
        {
            value = 0;
            int response = port.ReadByte();
            if ((response & 0x80) > 0)
            {
                int extraResponse = port.ReadByte();

                value = (byte)((extraResponse << 1) | (response & 0x01));
                return true;
            }
            else
            {
                value = (byte)response;
                return false;
            }
        }

        bool HandleResponse(SerialPort port, out byte value)
        {
            value = (byte)port.ReadByte();
            if ((value & 0x80) > 0)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        static void HandleInvalidParameter(string parameterName)
        {
            throw new Exception(String.Format("Invalid parameter : {0}", parameterName));
        }



    }
}
