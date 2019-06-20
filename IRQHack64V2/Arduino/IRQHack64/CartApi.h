#ifndef _CARTAPI_H
#define _CARTAPI_H
#include <Arduino.h>
#include <SdFat.h>
#include "DirFunction.h"
#include "CartInterface.h"

#define WRITE_BUFFER_SIZE 32
#define SOURCE_SIZE 32
//#define FILENAME_SIZE 32
#define NOT_INITIALIZED 0x01
#define FILE_NOT_FOUND 0x02
#define FILE_CANNOT_BE_OPENED 0x03
#define FILE_IS_NOT_OPENED 0x04
#define FILE_WRITE_HAS_FAILED 0x05
#define WRITE_NOT_COMPLETE 0x06
#define FILE_DELETION_FAILED 0x07
#define CANT_SEEK 0x08
#define INVALID_ARGUMENT 0x09
#define NOT_IMPLEMENTED 0x0A
#define DIR_NOT_FOUND 0x0B
#define DIR_DELETION_FAILED 0x0C
#define DIR_ALREADY_EXISTS 0x0D
#define DIR_CREATION_FAILED 0x0E
#define FILE_INFO_FAILED 0x0F
#define INVALID_SOURCE_TYPE 0x10
#define INVALID_CONTENT 0x11

#define SUCCESSFUL 0x80


#define COMMAND_READ_FILE  78
#define COMMAND_OPEN_FILE  2
#define COMMAND_CLOSE_FILE  3
#define COMMAND_WRITE_FILE  4
#define COMMAND_DELETE_FILE  5
#define COMMAND_SEEK_FILE  6
#define COMMAND_LONG_SEEK_FILE  7
#define COMMAND_GET_INFO_FOR_FILE  8

#define COMMAND_READ_DIR  10
#define COMMAND_CHANGE_DIR  11
#define COMMAND_DELETE_DIR  12
#define COMMAND_CREATE_DIR  13

#define COMMAND_READ_EEPROM  15
#define COMMAND_SEEK_EEPROM  16
#define COMMAND_WRITE_EEPROM  17

#define COMMAND_SET_PORT  20
#define COMMAND_SET_IO  21

#define COMMAND_SET_SOURCE  22

#define COMMAND_INVOKE_WITH_NAME  23
#define COMMAND_INVOKE_WITH_INDEX  24

#define COMMAND_STREAM  25

#define COMMAND_NI_STREAM  26

#define COMMAND_END_TALKING  30
#define COMMAND_EXIT_TO_MENU  31

#define SEEK_FROM_BEGINNING 0
#define SEEK_FROM_CURRENT 1
#define SEEK_FROM_END 2

#define PILOT_DESC_1 73
#define PILOT_DESC_2 82
#define PILOT_DESC_3 81

#define MAX_ARGUMENTS_LENGTH 40

#define SOURCE_TYPE_SD 1
#define SOURCE_TYPE_HTTP 2
#define SOURCE_TYPE_FTP 3


//#define STREAMING_BUFFER_SIZE 64
#define STREAMING_BUFFER_SIZE 128

//Size of each buffer used in double buffering
#define DOUBLE_BUFFER_SIZE 64

//Size of the non interrupted buffer, should be multiple of 8
#define NON_INTERRUPTED_BUFFER_SIZE 400
//#define NON_INTERRUPTED_BUFFER_SIZE 200


class CartApi {

 protected:
   File   workingFile;   
   //uint8_t TalkStatus = 0;
   //uint8_t Arguments[80];
   uint8_t Arguments[34];
   //int startIndex;
   int eepromIndex; 
   //uint8_t fileBuffer[BUFFER_SIZE];     
   //char currentFileName[FILENAME_SIZE];
     
   int16_t GetCommand();
   int16_t GetByte();
   int16_t AwaitByte(int16_t maxTryCount);
   void GetArgumentsDynamic(int16_t argumentsLength);
   void GetArgumentsStatic(int16_t argumentsLength); 
   void HandleReadFile();   
   void HandleOpenFile();   
   void HandleCloseFile();
   void HandleWriteFile();
   void HandleDeleteFile();
   void HandleSeekFile();
   void HandleLongSeekFile();
   void HandleGetInfoForFile();
   void HandleReadDirectory();
   void HandleChangeDirectory();
   void HandleDeleteDirectory();
   void HandleCreateDirectory();   
   void HandleReadEeprom();
   void HandleSeekEeprom();
   void HandleWriteEeprom();
   void IncrementEepromAddress();
   void HandleValueResponse(uint8_t value);
   void HandleSetPort();   
   void HandleSetIO();   
   void HandleEndTalking();
   void HandleSetSource();
   void HandleInvokeWithName();
   void HandleInvokeWithIndex();
   void HandleStream();   
   //void HandleExitToMenu();
   static void DoStreaming1();
   static void DoStreaming2();
   static void DoubleBufferedStreaming();   
   void HandleNonInterruptedStream();
   static void SingleBufferedStreaming();
  
 public : 
  void SendHeader(unsigned char startLow, unsigned char startHigh, unsigned char transferPages, long dataLength, unsigned char type, unsigned char transferMode); 
  void Init();
  int16_t IsStartTalking();
  void HandleApi();  
  void SendLoaderStub();  
  void TransferMenu();
  void ResetNoCartridge();  
  void UpdateFile();
  //void SendTestProgramToSecondaryLoader();
  void SendStubLoader(); 
  void ReceiveFile();
  void TransferGame(char * selectedFileName);
  void TransferGame(StringPrint selectedFile);
  void InvokeSelected(int selected, unsigned int args);
  /*
  void TransferDirectory(int startIndex);
  void TransferDirectoryNext();
  void TransferDirectoryPrevious();
  void TransferDirectoryCurrent();
  */
};

#endif

