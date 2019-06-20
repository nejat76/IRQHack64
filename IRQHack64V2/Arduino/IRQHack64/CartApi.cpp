#include <SdFat.h>
#include <avr/eeprom.h>
#include <EEPROM.h>
#include "Arduino.h"
#include "CartApi.h"
#include "CartInterface.h"
#include "DirFunction.h"
#include "IrqHack64.h"
#include "FlashLib.h"
#include "petscii.c"
#include "FreeStack.h"

extern SdFat  sd;
extern DirFunction dirFunc;
extern CartInterface cartInterface;

//volatile static uint8_t * streamBuffer; 
volatile static uint8_t * streamBuffer1; 
volatile static uint8_t * streamBuffer2; 
//volatile static uint8_t streamBufferIndex;
volatile static uint16_t streamBufferIndex;
//volatile static uint8_t chunkLength;
//volatile static uint8_t inChunkDelay;  

void CartApi::Init() {
  eepromIndex = 0;
  /* Not talking at the moment */
  //TalkStatus = 0;  
  cartInterface.SetPage(0);  

  dirFunc.ReInit();
  dirFunc.Prepare();
}

inline void HandleResponse(unsigned char response, uint16_t waitAfterResponse) {
  #ifdef TEST_TERMINAL_MODE
  Serial.write(response);
  #else
    #ifdef DEBUG
    Serial.print(F("CMD RESULT : "));Serial.println(response);
    #endif
  cartInterface.SetPage(0);  
  cartInterface.SetPage(0);  
  cartInterface.SetPage(response);  
  #endif
  //delayMicroseconds(waitAfterResponse);  
  if (waitAfterResponse!=0) delay(waitAfterResponse);
}

/*
void CartApi::HandleReadFile() {
  Serial.println("Got HandleReadFile");
  GetArgumentsStatic(1);  
  unsigned int dataLength = Arguments[0];
  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 1);
  } else if (workingFile.isOpen()) {
    HandleResponse(SUCCESSFUL, 100);
    unsigned int totalLength = dataLength*256;
    unsigned int actualLength = 0;

    while(workingFile.available() > 0 && actualLength<totalLength) {  
      int readCount = workingFile.read(fileBuffer, BUFFER_SIZE);
  
      if (readCount > 0) {
        for (int i = 0;i<readCount;i++) {     
            cartInterface.TransmitByteFast(fileBuffer[i]);
        }        
        actualLength = actualLength + readCount;
      }

      delay(1);
    } 

    for (unsigned int i = 0;i<(totalLength - actualLength);i++) {
      cartInterface.TransmitByteFast(0);
    }
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 1);
  }
}
*/

#define BUFFER_SIZE 16
void CartApi::HandleReadFile() {
  uint8_t fileBuffer[BUFFER_SIZE];     
  #ifdef DEBUG
  Serial.println(F("Got HandleReadFile"));
  #endif
  GetArgumentsStatic(1);  
  unsigned int dataLength = Arguments[0];
  unsigned int totalLength = dataLength*256;
  unsigned int actualLength = 0;  
  int streamState;
  cartInterface.ResetIndex();
  noInterrupts();
  cartInterface.SoftEndListening();  

  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
    //HandleResponse(SUCCESSFUL, 100);
    HandleResponse(SUCCESSFUL, 1);
    delayMicroseconds(1000);
    while(workingFile.available() > 0 && actualLength<totalLength) {  
      int readCount = workingFile.read(fileBuffer, BUFFER_SIZE);
  
      if (readCount > 0) {
        for (int i = 0;i<readCount;i++) {     
            cartInterface.TransmitByteFastStd(fileBuffer[i]);
        }        
        actualLength = actualLength + readCount;
      }

      delayMicroseconds(100);
    } 
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 0);
  }
  #ifdef DEBUG
  Serial.print(F("Actual length : "));Serial.println(actualLength);
  Serial.print(F("Total length : "));Serial.println(totalLength);
  #endif
  for (unsigned int i = 0;i<(totalLength - actualLength);i++) {
    cartInterface.TransmitByteFast(0);
  }

  interrupts();
  cartInterface.SoftStartListening();
}

void CartApi::HandleOpenFile() {
  #ifdef DEBUG
  Serial.println(F("Got HandleOpenFile"));  
  #endif
  GetArgumentsDynamic(1);
  uint8_t flags = Arguments[0];
  
  #ifdef DEBUG
  Serial.print(F("Flags : "));Serial.println(flags);
  #endif DEBUG
  unsigned int fileNameLength = Arguments[1];
  char * fileName = (char *) &Arguments[2];

  #ifdef DEBUG  
  Serial.print(F("Filename : "));Serial.println(fileName);
  #endif DEBUG

  //strncpy(currentFileName, fileName, FILENAME_SIZE);
    
  workingFile = sd.open(fileName, flags);
  if (workingFile != NULL) {
    #ifdef DEBUG
    Serial.println(F("Success!"));    
    #endif DEBUG
    //HandleResponse(SUCCESSFUL, 50);
    HandleResponse(SUCCESSFUL, 1);
  } else  {
    #ifdef DEBUG      
    Serial.println(F("Fail!"));    
    #endif
    //HandleResponse(FILE_CANNOT_BE_OPENED, 50);
    HandleResponse(FILE_CANNOT_BE_OPENED, 1);
  }
}

void CartApi::HandleCloseFile() {
  #ifdef DEBUG
  Serial.println(F("Got HandleCloseFile"));    
  #endif
  GetArgumentsStatic(0);
  //HandleResponse(SUCCESSFUL, 1000);

  if (workingFile == NULL) {
      #ifdef DEBUG
      Serial.println(F("Not initialized!"));
      #endif
      //HandleResponse(NOT_INITIALIZED, 100);
      HandleResponse(NOT_INITIALIZED, 1);
  } else if (workingFile.isOpen()) {
    #ifdef DEBUG      
    Serial.println(F("Closed!"));
    #endif
    workingFile.close();
    //HandleResponse(SUCCESSFUL, 100);
    HandleResponse(SUCCESSFUL, 1);
  } else {
    //HandleResponse(FILE_IS_NOT_OPENED, 100);
    HandleResponse(FILE_IS_NOT_OPENED, 1);
  }

}



void CartApi::HandleWriteFile() {  
  #ifdef DEBUG  
  Serial.println(F("Got HandleWriteFile"));
  #endif
  GetArgumentsStatic(32);
  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
    int bytesWritten = workingFile.write(Arguments, WRITE_BUFFER_SIZE);
    if (bytesWritten == -1) {
      HandleResponse(FILE_WRITE_HAS_FAILED, 0);    
    } else if (bytesWritten<WRITE_BUFFER_SIZE) {
      HandleResponse(WRITE_NOT_COMPLETE, 0);  
    } else {
      HandleResponse(SUCCESSFUL, 0);    
    }
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 0);
  }
}

void CartApi::HandleDeleteFile() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleDeleteFile"));
  #endif    
  GetArgumentsDynamic(1);
  uint8_t flags = Arguments[0];
  unsigned int fileNameLength = Arguments[1];
  char * fileName = (char *) &Arguments[2];
  if (!sd.exists(fileName)) {
    HandleResponse(FILE_NOT_FOUND, 0);
  } else {
    if (sd.remove(fileName)) {    
      HandleResponse(SUCCESSFUL, 0);
    } else  {
      HandleResponse(FILE_DELETION_FAILED, 0);
    }
  }
}

//TODO: Signed integer support should be added
void CartApi::HandleSeekFile() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleSeekFile"));
  #endif
  GetArgumentsStatic(3);
  unsigned int seekDirection = Arguments[0];
  uint8_t low = Arguments[1];
  uint8_t high = Arguments[2];

  unsigned int seekPosition =  (high<<8) | low;
  
  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
    bool status = false;
    if (seekDirection == SEEK_FROM_BEGINNING) {
      status = workingFile.seekSet(seekPosition);
    } else if (seekDirection == SEEK_FROM_CURRENT) {
      status = workingFile.seekCur(seekPosition);
    } else if (seekDirection == SEEK_FROM_END) {
      status = workingFile.seekEnd(seekPosition);    
    }

    if (status) {
      HandleResponse(SUCCESSFUL, 1); // Other solution???
    } else {
      HandleResponse(CANT_SEEK, 1);
    }
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 1);
  }
}


void CartApi::HandleLongSeekFile() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleLongSeekFile"));
  #endif          
  GetArgumentsStatic(5);
  unsigned int seekDirection = Arguments[0];
  uint8_t low = Arguments[1];
  uint8_t high = Arguments[2];
  uint8_t upperLow = Arguments[3];
  uint8_t upperHigh = Arguments[4];

  unsigned long seekPosition = (upperHigh<<24) | (upperLow<<16) | (high<<8) | low;
  
  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
    bool status = false;
    if (seekDirection == SEEK_FROM_BEGINNING) {
      status = workingFile.seekSet(seekPosition);
    } else if (seekDirection == SEEK_FROM_CURRENT) {
      status = workingFile.seekCur(seekPosition);
    } else if (seekDirection == SEEK_FROM_END) {
      status = workingFile.seekEnd(seekPosition);    
    }

    if (status) {
      HandleResponse(SUCCESSFUL, 0);
    } else {
      HandleResponse(CANT_SEEK, 0);
    }
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 0);
  }

}


void CartApi::HandleGetInfoForFile() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleGetInfoForFile"));
  #endif            
  GetArgumentsStatic(0);
  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
    dir_t dir;
    if (workingFile.dirEntry(&dir)) {
      HandleResponse(SUCCESSFUL, 0);
      delay(1);
      uint8_t * infoBuffer = (uint8_t *) &dir;
      for (int i = 0;i<256;i++) {
        if (i<32) {
          cartInterface.TransmitByteFast(*(infoBuffer+i));
        } else {
          cartInterface.TransmitByteFast(0);
        }
      }
      
    } else {
      HandleResponse(FILE_INFO_FAILED, 0);
    }


  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 0);
  }

}

inline void CartApi::HandleReadDirectory() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleReadDirectory"));
  #endif             
  GetArgumentsStatic(3);
  uint8_t numberOfEntries = Arguments[0]; //Max number of directory entries to retrieve
  uint8_t dataLength = Arguments[1]; //Max number of pages of data to retrieve (each page is 256 byte)

  uint8_t startPage = Arguments[2]; //Starting page
 
  if (numberOfEntries == 0 || dataLength == 0) {
    HandleResponse(INVALID_ARGUMENT, 1);
  } else {
    HandleResponse(SUCCESSFUL, 1);    
    uint16_t actualTransferredBytes = 0;
    uint16_t maxBytesToTransfer = dataLength * 256;

    uint16_t itemIndex = 0;
    uint16_t startingIndex = numberOfEntries * startPage;
    
    dirFunc.Rewind();

    while (itemIndex<startingIndex && dirFunc.Iterate() && !dirFunc.IsFinished) {
      itemIndex++;      
    }


    
    uint8_t currentItemsCount = dirFunc.GetCount()>startingIndex + numberOfEntries ? numberOfEntries : dirFunc.GetCount() - startingIndex;
    //int padValue = (dirFunc.CurrentItemsCount % numberOfEntries) == 0 ? 0 : numberOfEntries - (dirFunc.CurrentItemsCount % numberOfEntries);
    uint8_t pagePadValue = (dirFunc.GetCount() % numberOfEntries) >0 ? 1 : 0;    
    uint8_t pageCount = (byte)(dirFunc.GetCount()/numberOfEntries + pagePadValue);  
  
    cartInterface.ResetIndex();
    #ifndef TEST_TERMINAL_MODE  
    noInterrupts();
    #endif
    
    cartInterface.TransmitByteFast(currentItemsCount);   
    cartInterface.TransmitByteFast(pageCount); 
  
    actualTransferredBytes = 2;
     
    uint8_t curItemIndex = 0;    
    //Send initial state of directories.
    while (curItemIndex<numberOfEntries && dirFunc.Iterate() && !dirFunc.IsFinished) {  
      if (!dirFunc.IsHidden) {  
        if (actualTransferredBytes + 32 <maxBytesToTransfer) {
          // Print the file number and name. 
          //#ifdef DEBUG         
          Serial.println(dirFunc.CurrentFileName.value);
          //#endif
          
          for (int i=0;(i<dirFunc.CurrentFileName.index) && (i<31);i++) {
//          for (int i=0;(i<dirFunc.CurrentFileName.index) && (i<20);i++) {
            //cartInterface.TransmitByteFast(cbm_ascii2petscii_c(tolower(dirFunc.CurrentFileName.value[i]))); 
            cartInterface.TransmitByteFast(tolower(dirFunc.CurrentFileName.value[i])); 
          }
          
          for (int i=dirFunc.CurrentFileName.index;i<31;i++) {
            cartInterface.TransmitByteFast(0x00);
          }

          if (dirFunc.IsDirectory) {
            cartInterface.TransmitByteFast(0x04);            
          } else {
            cartInterface.TransmitByteFast(0x00);                        
          }
                  
          actualTransferredBytes = actualTransferredBytes +32;        
          
          curItemIndex++;
        } else {
          break; 
        }
      }
    }   
  
    for (int i = 0;i<(maxBytesToTransfer - actualTransferredBytes);i++) {
      cartInterface.TransmitByteFast(0x00);    
    }

    #ifndef TEST_TERMINAL_MODE 
    interrupts();
     
    delayMicroseconds(20);
    #endif    
  }
}

void CartApi::HandleChangeDirectory() {  
  #ifdef DEBUG  
  Serial.println(F("Got HandleChangeDirectory"));
  #endif
  GetArgumentsDynamic(0);
  //uint8_t flags = Arguments[0];
  unsigned int fileNameLength = Arguments[0];
  char * fileName = (char *) &Arguments[1];
  
  #ifdef DEBUG  
  Serial.print(F("Filename : "));Serial.println(fileName);
  #endif DEBUG


  if (!strcmp(fileName, "..")) {
    dirFunc.GoBack();
  } else {
    dirFunc.ChangeDirectory(fileName);                          
  }
  
  dirFunc.Prepare();           
  HandleResponse(SUCCESSFUL, 1);  
}

void CartApi::HandleDeleteDirectory() {   
  #ifdef DEBUG  
  Serial.println(F("Got HandleDeleteDirectory"));
  #endif
  GetArgumentsDynamic(1);
  uint8_t flags = Arguments[0];
  unsigned int fileNameLength = Arguments[1];
  char * fileName = (char *) &Arguments[2];
  if (!sd.exists(fileName)) {
    HandleResponse(DIR_NOT_FOUND, 0);
  } else {
    if (sd.rmdir(fileName)) {    
      HandleResponse(SUCCESSFUL, 0);
    } else  {
      HandleResponse(DIR_DELETION_FAILED, 0);
    }
  }
}

void CartApi::HandleCreateDirectory() {  
  #ifdef DEBUG  
  Serial.println(F("Got HandleCreateDirectory"));
  #endif
  GetArgumentsDynamic(1);
  uint8_t flags = Arguments[0];
  unsigned int fileNameLength = Arguments[1];
  char * fileName = (char *) &Arguments[2];
  if (sd.exists(fileName)) {
    HandleResponse(DIR_ALREADY_EXISTS, 0);
  } else {
    if (sd.mkdir(fileName)) {    
      HandleResponse(SUCCESSFUL, 0);
    } else  {
      HandleResponse(DIR_CREATION_FAILED, 0);
    }
  }
}


void CartApi::HandleInvokeWithName() {  
  #ifdef DEBUG  
  Serial.println(F("Got HandleInvokeWithName"));
  #endif
  GetArgumentsDynamic(1);
  uint8_t flags = Arguments[0];
  unsigned int fileNameLength = Arguments[1];
  char * fileName = (char *) &Arguments[2];

  HandleResponse(SUCCESSFUL, 0);

  TransferGame(fileName);  
}

void CartApi::HandleInvokeWithIndex() {  
/* Not implemented */  
}

void CartApi::HandleValueResponse(uint8_t value) {
  //HandleResponse( (value & 1) | 0x80, 20); //Embed least significant bit of value
  HandleResponse( (value & 1) | 0x80, 1); //Embed least significant bit of value
  //HandleResponse( (value & 0xFE)>>1, 20); //Embed rest of the value
  HandleResponse( (value & 0xFE)>>1, 1); //Embed rest of the value
}

void CartApi::IncrementEepromAddress() {
    eepromIndex++;
    if (eepromIndex>1024) eepromIndex = 0;
}

void CartApi::HandleReadEeprom() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleReadEeprom"));
  #endif
  #ifndef __AVR__    
  EEPROM.begin(EEPROM_SIZE);
  #endif
  uint8_t value = EEPROM.read(eepromIndex);
  #ifndef __AVR__    
  EEPROM.end();
  #endif  
  HandleValueResponse( value );
  IncrementEepromAddress();
}

void CartApi::HandleSeekEeprom() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleSeekEeprom"));
  #endif
  GetArgumentsStatic(2);    
  uint8_t hi = Arguments[0];
  uint8_t low = Arguments[1];
  eepromIndex = (hi<<8) | low;  
  HandleResponse(SUCCESSFUL, 0);   
}

void CartApi::HandleWriteEeprom() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleWriteEeprom"));
  #endif
  #ifndef __AVR__    
  EEPROM.begin(EEPROM_SIZE);
  #endif
  GetArgumentsStatic(1);    
  uint8_t value = Arguments[0];  
  EEPROM.write(eepromIndex, value); 

  #ifndef __AVR__    
  EEPROM.end();
  #endif  
  
  IncrementEepromAddress();
  HandleResponse(SUCCESSFUL, 0); 
}

void CartApi::HandleEndTalking() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleEndTalking"));
  #endif     
  //cartInterface.EndListening();
  cartInterface.ResetReceive();
}

void CartApi::HandleSetPort() {
  #ifdef DEBUG  
  Serial.println(F("Got HandleSetPort"));
  #endif    
  GetArgumentsStatic(1);    
  uint8_t value = Arguments[0];  
  cartInterface.SetPage(value);
  HandleResponse(SUCCESSFUL, 0);   
}

void CartApi::HandleSetIO() {
}


void CartApi::HandleSetSource() {
  
}

/*
void CartApi::DoStreaming1() {
    cartInterface.SetPage(streamBuffer[streamBufferIndex]);  
    streamBufferIndex++;    
}

void CartApi::DoStreaming2() {
    cartInterface.SetPage(streamBuffer[streamBufferIndex]);
    delayMicroseconds(inChunkDelay);
    cartInterface.SetPage(streamBuffer[(STREAMING_BUFFER_SIZE/2) + streamBufferIndex]);

    //digitalWrite(13, toggle); toggle = 1-toggle;
    streamBufferIndex++;    
}

*/

volatile static uint8_t currentByte = 0;
volatile static uint8_t usedBuffer = 0;

void CartApi::DoubleBufferedStreaming() {  
    cartInterface.SetPage(currentByte);

    if (usedBuffer == 0) {
      currentByte = streamBuffer1[streamBufferIndex];
    } else if (usedBuffer == 1) {
      currentByte = streamBuffer2[streamBufferIndex];
    }
    
    streamBufferIndex++;    
    if (streamBufferIndex == DOUBLE_BUFFER_SIZE) {
      streamBufferIndex = 0;
      usedBuffer = 1-usedBuffer;
    }            
}


void CartApi::SingleBufferedStreaming() {  
    uint8_t val = streamBuffer1[streamBufferIndex];
    PORTD = (PIND & 0x0F) | (val & 0xF0);
    PORTC = (PINC & 0xF0) | (val & 0x0F);

    streamBufferIndex++;
}


void CartApi::HandleStream() {
  //uint8_t streamingBuffer[STREAMING_BUFFER_SIZE];
  uint8_t streamingBuffer1[DOUBLE_BUFFER_SIZE];
  uint8_t streamingBuffer2[DOUBLE_BUFFER_SIZE];

  #ifdef DEBUG  
  Serial.println(F("Got HandleStream"));
  #endif    
  GetArgumentsStatic(3);    
  uint8_t initialDelay = Arguments[0];  
  uint8_t countStreamedBytes = Arguments[1];  
  uint8_t delayBetweenBytes = Arguments[2];    


  if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
/*
      streamBuffer = streamingBuffer;
      chunkLength = STREAMING_BUFFER_SIZE / countStreamedBytes;
      workingFile.read(streamingBuffer, STREAMING_BUFFER_SIZE);
      TIMSK2 = 0; // Disable timer 2 interrupts
      if (chunkLength == 1) {      
        attachInterrupt(digitalPinToInterrupt(IRQ), CartApi::DoStreaming1, FALLING); 
      } else {
        attachInterrupt(digitalPinToInterrupt(IRQ), CartApi::DoStreaming2, FALLING);         
      }

      while(1) {
        if (streamBufferIndex >= countStreamedBytes) {
            workingFile.read(streamingBuffer, STREAMING_BUFFER_SIZE);
            streamBufferIndex = 0;            
        }
      }

      TIMSK2 = 0x02; // Enable timer 2 interrupts (for milliseconds and so on)
      */


      streamBuffer1 = streamingBuffer1;
      streamBuffer2 = streamingBuffer2;
      //chunkLength = STREAMING_BUFFER_SIZE / countStreamedBytes;
      workingFile.read(streamingBuffer1, DOUBLE_BUFFER_SIZE);      
      HandleResponse(SUCCESSFUL, 0);         
      TIMSK2 = 0; // Disable timer 2 interrupts
      attachInterrupt(digitalPinToInterrupt(IRQ), CartApi::DoubleBufferedStreaming, FALLING);               

     
      while(1) {
        while(usedBuffer == 0) {
          if (!digitalRead(SEL)) goto out;
        }
        workingFile.read(streamingBuffer1, DOUBLE_BUFFER_SIZE);   
        while(usedBuffer == 1) {
          if (!digitalRead(SEL)) goto out;
        }
        workingFile.read(streamingBuffer2, DOUBLE_BUFFER_SIZE);         
      }
out:      
      TIMSK2 = 0x02; // Enable timer 2 interrupts (for milliseconds and so on)      
      cartInterface.StartListening();
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 0);
  }      
}

//void CartApi::HandleNonInterruptedStream() {
//  uint8_t streamingBuffer[NON_INTERRUPTED_BUFFER_SIZE];
//  streamBuffer1 = streamingBuffer;
//
//  streamBufferIndex = 0;
//  #ifdef DEBUG  
//  Serial.println(F("Got HandleNIStream"));
//  #endif    
//  GetArgumentsStatic(1);    
//  uint8_t countOf8Bytes = Arguments[0];  
//  //uint8_t delayBetweenBytes = Arguments[1];    
//
//  if (countOf8Bytes>NON_INTERRUPTED_BUFFER_SIZE/8) {
//    HandleResponse(INVALID_ARGUMENT, 0);
//  } else if (workingFile == NULL) {
//      HandleResponse(NOT_INITIALIZED, 0);
//  } else if (workingFile.isOpen()) {
//      HandleResponse(SUCCESSFUL, 0);   
//
//      //Disable receiving interrupt but keep the state of the communication channel on.
//      cartInterface.SoftEndListening(); 
//
//      //Preload the buffer
//      workingFile.read(streamingBuffer, NON_INTERRUPTED_BUFFER_SIZE);      
//      TIMSK2 = 0; // Disable timer 2 interrupts
//      attachInterrupt(digitalPinToInterrupt(IRQ), CartApi::SingleBufferedStreaming, FALLING);               
//
//      while(1) {
//        if (streamBufferIndex == NON_INTERRUPTED_BUFFER_SIZE) {
//          if (streamBufferIndex == NON_INTERRUPTED_BUFFER_SIZE) {
//            if (streamBufferIndex == NON_INTERRUPTED_BUFFER_SIZE) {
//              Serial.println(F("Next"));
//              workingFile.read(streamingBuffer, NON_INTERRUPTED_BUFFER_SIZE);      
//              streamBufferIndex = 0;              
//            }
//          }
//        }
//      } 
//
//      TIMSK2 = 0x02; // Enable timer 2 interrupts (for milliseconds and so on)      
//  } else {
//    HandleResponse(FILE_IS_NOT_OPENED, 0);
//  }      
//}


void CartApi::HandleNonInterruptedStream() {
  uint8_t streamingBuffer[NON_INTERRUPTED_BUFFER_SIZE];
  uint16_t bufferIndex = 0;
  uint16_t bufferLength;
  
  #ifdef DEBUG  
  Serial.println(F("Got HandleNIStream"));
  #endif    
  GetArgumentsStatic(1);    
  uint8_t countOf8Bytes = Arguments[0];  
  //uint8_t delayBetweenBytes = Arguments[1];    

  if (countOf8Bytes>NON_INTERRUPTED_BUFFER_SIZE/8) {
    HandleResponse(INVALID_ARGUMENT, 0);
  } else if (workingFile == NULL) {
      HandleResponse(NOT_INITIALIZED, 0);
  } else if (workingFile.isOpen()) {
      HandleResponse(SUCCESSFUL, 0);   

      //Disable receiving interrupt but keep the state of the communication channel on.
      cartInterface.SoftEndListening(); 
      bufferLength = countOf8Bytes * 8;
           
      //Preload the buffer
      workingFile.read(streamingBuffer, bufferLength);      
      TIMSK2 = 0; // Disable timer 2 interrupts

      noInterrupts();
      uint8_t portDVal = (PIND & 0x0F);
      uint8_t portCVal = (PINC & 0xF0);
      while(1) {        
        for (bufferIndex = 0;bufferIndex<bufferLength;bufferIndex++) {
            /* Synchronization block for each 8 byte */
            while (PIND & 0x04); // Wait till C64 requests a stream                                     
            while ((PIND & 0x04)==0);  // Wait till captured low signal changes back to high
            /* Synchronization block for each 8 byte */
            //cartInterface.SetPage(streamingBuffer[bufferIndex]);
            uint8_t val = streamingBuffer[bufferIndex];
            PORTD = portDVal | (val & 0xF0);
            PORTC = portCVal | (val & 0x0F);            
        }   
                    
        //Serial.println(F("Next frame")); 
        workingFile.read(streamingBuffer, bufferLength);      
      } 


      interrupts();
      TIMSK2 = 0x02; // Enable timer 2 interrupts (for milliseconds and so on)      
  } else {
    HandleResponse(FILE_IS_NOT_OPENED, 0);
  }      
}



/*
void CartApi::HandleExitToMenu() {
  HandleResponse(SUCCESSFUL, 0);     
  #ifdef DEBUG  
  Serial.println(F("Exiting to menu"));
  #endif     
  cartInterface.EndListening();
  TransferMenu();
}
*/


/*
int16_t CartApi::AwaitByte(int16_t maxTryCount) {
  int16_t value = -1;
  for (uint8_t x = 0;x<2;x++) {
    for (int16_t i = 0;i<maxTryCount;i++) {
        value = cartInterface.Read();
        if (value>=0) {
          #ifdef DEBUG          
          Serial.print(F("Got byte : "));Serial.println(value);        
          #endif
          return value;        
        }
    }
  }
  
  #ifdef DEBUG          
  Serial.println(F("AW Fail"));
  #endif
  

  return value;  
}

*/

int16_t CartApi::AwaitByte(int16_t maxTryCount) {
  int16_t value = -1;
  for (uint8_t x = 0;x<100;x++) {
    for (int16_t i = 0;i<maxTryCount;i++) {
        value = cartInterface.Read();
        if (value>=0) {
          #ifdef DEBUG          
          Serial.print(F("Got byte : "));Serial.println(value);        
          #endif
          return value;        
        }
    }
  }
  
  #ifdef DEBUG          
  Serial.println(F("AW Fail"));
  #endif
  

  return value;  
}


int16_t CartApi::GetByte() {
  int16_t value = cartInterface.Read();
  #ifdef DEBUG
  if (value>=0) {
      #ifdef DEBUG          
      Serial.print(F("Got byte : "));Serial.println(value);        
      #endif
  }
  #endif
  return value;
}

// Argument length is known priorhand
void CartApi::GetArgumentsStatic(int16_t argumentsLength) {  
  for (int16_t i = 0;i<argumentsLength;) {
    int16_t value = AwaitByte(32000);
    if (value>=0) {
      Arguments[i] = value;        
      i++;
    }
  }   
}

//Only initial N argument count is known. Size of the remaining arguments is specified by length next to the known arguments.
void CartApi::GetArgumentsDynamic(int16_t argumentsLength) {  
  GetArgumentsStatic(argumentsLength);
  int16_t dynamicLength = AwaitByte(32000);
  if (dynamicLength == -1 | dynamicLength>(MAX_ARGUMENTS_LENGTH-1)) return;
  
  Arguments[argumentsLength] = dynamicLength;
  
  for (int16_t i = 1;i<=dynamicLength;i++) {
    int16_t value = AwaitByte(32000);
    if (value==-1) return;    
    Arguments[i + argumentsLength] = value;  
  }   
}


void CartApi::HandleApi() {  
  uint8_t state = cartInterface.ReceiveHandler();

  if (state == IN_TRANSMISSION) {    
      int16_t command = GetByte();
      if (command>=0) {
        cartInterface.SetPage(0);

        #ifdef DEBUG  
        //Serial.print(F("Free RAM: "));
        //Serial.println(FreeRam());    
        //Serial.print(F("FreeStack: "));Serial.println(FreeStack());
        #endif      
        
        switch(command) {
          case COMMAND_READ_FILE : HandleReadFile(); break;
          case COMMAND_OPEN_FILE : HandleOpenFile(); break;
          case COMMAND_CLOSE_FILE : HandleCloseFile(); break;
          case COMMAND_WRITE_FILE : HandleWriteFile(); break;
          case COMMAND_DELETE_FILE : HandleDeleteFile(); break;
          case COMMAND_SEEK_FILE : HandleSeekFile(); break;
          case COMMAND_LONG_SEEK_FILE : HandleLongSeekFile(); break;
          case COMMAND_GET_INFO_FOR_FILE : HandleGetInfoForFile(); break;
          case COMMAND_READ_DIR : HandleReadDirectory(); break;
          case COMMAND_CHANGE_DIR : HandleChangeDirectory(); break;
          case COMMAND_DELETE_DIR : HandleDeleteDirectory(); break;
          case COMMAND_CREATE_DIR : HandleCreateDirectory(); break;      
          case COMMAND_READ_EEPROM : HandleReadEeprom(); break;
          case COMMAND_SEEK_EEPROM : HandleSeekEeprom(); break;
          case COMMAND_WRITE_EEPROM : HandleWriteEeprom(); break;
          case COMMAND_END_TALKING : HandleEndTalking(); break;      
          case COMMAND_SET_SOURCE : HandleSetSource();break;
          case COMMAND_INVOKE_WITH_NAME : HandleInvokeWithName();break;
          case COMMAND_STREAM : HandleStream();break;          
          case COMMAND_NI_STREAM : HandleNonInterruptedStream(); break;
          case COMMAND_EXIT_TO_MENU : TransferMenu();break;            
        }

        #ifdef DEBUG  
        //Serial.println(F("Port clear!"));
        #endif
        
        cartInterface.SetPage(0);
      }
   }  
}  



#ifdef DEBUG
void TransferInfo(long transferLength, long padBytes, byte transferPages)
{
    Serial.print(F("BLK X :")); Serial.println(cartInterface.GetBlockIndex());
    Serial.print(F("XF X :")); Serial.println(cartInterface.GetTransferIndex());
    Serial.print(F("XFD LEN :")); Serial.println(cartInterface.GetBlockIndex() * 256 + cartInterface.GetTransferIndex());  
    Serial.print(F("TO XF :")); Serial.println(transferLength + padBytes);
    Serial.print(F("TO XF BLKS :")); Serial.println(transferPages);    
}
#endif 

void CartApi::SendLoaderStub() {
  #ifdef __AVR__
  for (int i = 0;i<stub_len;i++) {
    cartInterface.TransmitByteFastStd(pgm_read_byte(stubData + i));
  }
  #endif

  #ifdef ESP8266
  for (int i = 0;i<stub_len;i++) {
    cartInterface.TransmitByteFastStd(*(stubData + i));
  }
  #endif


  for (int i = stub_len;i<256;i++) {
    cartInterface.TransmitByteFastStd(0x20); //Send space character
  }

  cartInterface.ResetIndex();
}

bool StartsWith(char *str,const char *pre)
{
    size_t lenpre = strlen(pre),
           lenstr = strlen(str);
    return lenstr < lenpre ? false : strncmp(pre, str, lenpre) == 0;
}

unsigned char IsMatchLast(char * container, char * val) {
  int lastIndexContainer = strlen(container) - 1;
  int lastIndexVal = strlen(val) - 1;

  for (int i = 0; i<=lastIndexVal;i++) {
    if (container[lastIndexContainer - i] != val[lastIndexVal - i]) {
      return 0;
    }
  }

  return 1;

}


/*
byte CurrentPageIndex = 0;
byte Count = 0;
byte CurrentIndex = 0;
unsigned int CurrentItemsCount = 0; //TODO : Throw it away
unsigned int PageCount = 0; //TODO : Throw it away
*/


void CartApi::SendHeader(unsigned char startLow, unsigned char startHigh, unsigned char transferPages, long dataLength, unsigned char type, unsigned char transferMode) {
  long endAddress = (startLow + startHigh*256) + dataLength + 1;

  unsigned char endHigh = endAddress/256;
  unsigned char endLow = endAddress%256;
  
  cartInterface.TransmitByteSlow(startLow);
  cartInterface.TransmitByteSlow(startHigh);
  cartInterface.TransmitByteSlow(transferPages);
  cartInterface.TransmitByteSlow(startLow);
  cartInterface.TransmitByteSlow(startHigh);  
  cartInterface.TransmitByteSlow(endLow);
  cartInterface.TransmitByteSlow(endHigh);  
  cartInterface.TransmitByteSlow(type); 
  cartInterface.TransmitByteSlow(transferMode); //Reserved
  cartInterface.TransmitByteSlow(0); //Reserved
}

void CartApi::TransferMenu() {
  //char irqHack64[] = "irqhack64.prg";  
  static const unsigned char PROGMEM p_irqHack64[14] = {'i', 'r', 'q', 'h', 'a', 'c', 'k',  '6', '4', '.', 'p', 'r', 'g', 0};
  char irqHack64[14];

  for (uint8_t i = 0;i<14;i++) {
    irqHack64[i] = pgm_read_byte(p_irqHack64+i);
  }

  #ifdef DEBUG
  Serial.print(F("Transfer mode : "));Serial.println(cartInterface.TransferMode);
  #endif  

  cartInterface.EndListening();  
   
  dirFunc.ReInit();
  dirFunc.Prepare();
  
  unsigned char readFromFile = 0;  
  
  if (sd.exists(irqHack64)) {
    workingFile = sd.open(irqHack64);
    if (workingFile) {
      #ifdef DEBUG
        Serial.println(F("Menu from SD"));
      #endif      
      readFromFile = 1;
    } 
  }

  //int menu_data_length = (readFromFile? workingFile.size() : data_len) ;
  int menu_data_length = (readFromFile? workingFile.size() : data_len) ;
  cartInterface.EnableCartridge();
  cartInterface.ResetC64();
  
  
  delay(300);  
  

  unsigned char low;
  unsigned char high;

  if (!readFromFile) {
    low = pgm_read_byte(cartridgeData);  
    high = pgm_read_byte(cartridgeData+1);  
  } else {
    low = workingFile.read();
    high = workingFile.read();    
  }

  //long fileNamesDataLength = 16 + dirFunc.NMax * 32; // 16 byte header + 
  //long transferLength = menu_data_length + fileNamesDataLength - 2; 
  long transferLength = menu_data_length - 2; 
  long padBytes = (transferLength%256==0) ? 0 : 256 - transferLength%256; 
  byte transferPages = (byte)(transferLength/256 + (padBytes>0 ? 1 : 0));  

  //SendHeader(low, high, transferPages,menu_data_length-2, TYPE_MENU); 
  SendHeader(low, high, transferPages,transferLength, TYPE_MENU, cartInterface.TransferMode); 
  cartInterface.ResetIndex();
  
  #ifdef  USERAMLAUNCHER
  SendLoaderStub();
  #endif

  #ifdef DEBUG   
    Serial.println(F("Loading")); 
  #endif

  noInterrupts();
  if (!readFromFile) {
    for (int i=2;i<menu_data_length;i++) {
     unsigned char value = pgm_read_byte(cartridgeData+i);    
     cartInterface.TransmitByteFast(value); 
    }  
  } else {
    for (int i=2;i<menu_data_length;i++) {
     unsigned char value = workingFile.read();   
     cartInterface.TransmitByteFast(value); 
    }     
  }

/*
  unsigned char pagePadValue = (dirFunc.GetCount() % dirFunc.NMax) >0 ? 1 : 0;
  uint8_t currentItemsCount = dirFunc.GetCount()>dirFunc.NMax ? dirFunc.NMax : dirFunc.GetCount(); //TODO: Extemely rubbish... bad design...
  int padValue = (currentItemsCount % dirFunc.NMax) == 0 ? 0 : dirFunc.NMax - (currentItemsCount % dirFunc.NMax);
  PageCount = (byte)(dirFunc.GetCount()/dirFunc.NMax + pagePadValue);    
  CurrentIndex = 0;
  CurrentPageIndex = 0;
 
  

  cartInterface.TransmitByteFast(CurrentItemsCount); 
  
  cartInterface.TransmitByteFast(PageCount); 
  
  cartInterface.TransmitByteFast(CurrentPageIndex); 

  cartInterface.TransmitByteFast(cartInterface.TransferMode);   

  for (int i = 0;i<12;i++)     cartInterface.TransmitByteFast(0); //Fill reserved area
  unsigned int n = 0;
  dirFunc.Rewind();
  //Send initial state of directories.
  while (n<dirFunc.NMax && dirFunc.Iterate()) {   
    if (!dirFunc.IsHidden) {
      #ifdef DEBUG       
      Serial.println(dirFunc.CurrentFileName.value);    
      #endif
      for (int i=0;(i<dirFunc.CurrentFileName.index) && (i<32);i++) {
        cartInterface.TransmitByteFast(cbm_ascii2petscii_c(tolower(dirFunc.CurrentFileName.value[i]))); 
      }      
      
      for (int i=dirFunc.CurrentFileName.index;i<32;i++) {
        cartInterface.TransmitByteFast(0x00);
      }
  
      n++;
    }
  }    

  #ifdef DEBUG 
  Serial.print(F("ITM CNT:")); Serial.println(n);
  #endif

  for (int i = n;i<dirFunc.NMax;i++) {
    for (int j = 0;j<32;j++) {
      cartInterface.TransmitByteFast(0x00); 
    } 
  } 

*/  
  if (padBytes>0) {
    for (int i=0;i<padBytes;i++) {    
      cartInterface.TransmitByteFast(0x00); 
    }
  }
  interrupts();
//  #ifdef DEBUG 
//  Serial.print(F("CNT:"));Serial.println(dirFunc.GetCount());
//
//  Serial.print(F("PG ITEM CNT:"));Serial.println(CurrentItemsCount);
//  Serial.print(F("PG CNT:"));Serial.println(PageCount);
//  
//  TransferInfo(transferLength, padBytes, transferPages);
//  #endif

  delayMicroseconds(30);
  cartInterface.DisableCartridge();
  //delay(500);
  cartInterface.StartListening();
  #ifdef DEBUG
  Serial.println(F("Done"));
  #endif

  if (readFromFile && workingFile) workingFile.close();      
}

/*

void CartApi::TransferDirectory(int startIndex) {  
  cartInterface.EndListening();  
  cartInterface.StartListening();      
  cartInterface.EnableCartridge();

  long fileNamesDataLength = 16 + 20 * 32; // 16 byte header + 
  long transferLength = fileNamesDataLength;
  long padBytes = (transferLength%256==0) ? 0 : 256 - transferLength%256;  
  byte transferPages = (byte)(transferLength/256 + (padBytes>0 ? 1 : 0));  

  unsigned char pagePadValue = (dirFunc.GetCount() % dirFunc.NMax) >0 ? 1 : 0;
  CurrentItemsCount = dirFunc.GetCount()-startIndex>dirFunc.NMax ? dirFunc.NMax : dirFunc.GetCount()-startIndex;
  int padValue = (CurrentItemsCount % dirFunc.NMax) == 0 ? 0 : dirFunc.NMax - (CurrentItemsCount % dirFunc.NMax);
  PageCount = (byte)(dirFunc.GetCount()/dirFunc.NMax + pagePadValue);      

  cartInterface.ResetIndex();
  #ifdef DEBUG   
  Serial.println(F("XFER DIR")); 
  Serial.print(F("CNT:"));Serial.println(dirFunc.GetCount());
  Serial.print(F("PP ITEM CNT:"));Serial.println(CurrentItemsCount);
  Serial.print(F("PG CNT:"));Serial.println(PageCount);
  Serial.print(F("CP:"));Serial.println(CurrentPageIndex);  
  #endif

  noInterrupts();
  cartInterface.TransmitByteFast(CurrentItemsCount); 
  
  cartInterface.TransmitByteFast(PageCount); 
  
  cartInterface.TransmitByteFast(CurrentPageIndex); 

  cartInterface.TransmitByteFast(cartInterface.TransferMode);   

  for (int i = 0;i<12;i++)     cartInterface.TransmitByteFast(0); //Fill reserved area
  
  unsigned int n = 0;
  int itemIndex = 0;
  dirFunc.Rewind();
  //Send initial state of directories.
  while (n<255 && itemIndex<dirFunc.NMax && dirFunc.Iterate() && !dirFunc.IsFinished) {  
    if (!dirFunc.IsHidden) {  
      if (n>=CurrentIndex) {
        // Print the file number and name. 
        #ifdef DEBUG         
        Serial.println(dirFunc.CurrentFileName.value);
        #endif
        
        for (int i=0;(i<dirFunc.CurrentFileName.index) && (i<32);i++) {
          cartInterface.TransmitByteFast(cbm_ascii2petscii_c(tolower(dirFunc.CurrentFileName.value[i]))); 
          //TransmitByteFastNew(0x42);
        }
        
        for (int i=dirFunc.CurrentFileName.index;i<32;i++) {
          cartInterface.TransmitByteFast(0x00);
        }
        
        itemIndex++;
      }
      n++;
    } 
  }   

  #ifdef DEBUG   
  Serial.print(F("FL CNT:")); Serial.println(n);
  #endif
  for (int i = itemIndex;i<dirFunc.NMax;i++) {
    for (int j = 0;j<32;j++) {
      cartInterface.TransmitByteFast(0x00); 
    } 
  }  
  
  if (padBytes>0) {
    for (int i=0;i<padBytes;i++) {    
      cartInterface.TransmitByteFast(0xEA); 
    }
  }
  interrupts();
  #ifdef DEBUG   
  TransferInfo(transferLength, padBytes, transferPages);
  #endif
  
  delayMicroseconds(20);
  cartInterface.DisableCartridge();
  #ifdef DEBUG
  Serial.println(F("Done"));    
  #endif
}

void CartApi::TransferDirectoryNext() {
  if (CurrentIndex<dirFunc.GetCount()-dirFunc.NMax) {
    CurrentIndex = CurrentIndex + dirFunc.NMax;
    CurrentPageIndex++;
  }
  
  TransferDirectory(CurrentIndex);
}

void CartApi::TransferDirectoryPrevious() {
  if (CurrentIndex>=dirFunc.NMax) {
    CurrentIndex = CurrentIndex - dirFunc.NMax;
    CurrentPageIndex--;
  }
  
  TransferDirectory(CurrentIndex);  
}

void CartApi::TransferDirectoryCurrent() {
  TransferDirectory(CurrentIndex);  
}

void CartApi::InvokeSelected(int selected, unsigned int args) {
  #ifdef DEBUG   
  Serial.print(F("SEL:"));Serial.println(selected);
  #endif
  unsigned int n = 0;
  unsigned int i = 0;
  dirFunc.Rewind();
  while (n<255 && dirFunc.Iterate()) { 
    i = i + 1; 
    if (!dirFunc.IsFinished && !dirFunc.IsHidden) {  
      #ifdef DEBUG       
      //Serial.print(F("n : "));Serial.println(n);      
      //Serial.print(F("Current page index : "));Serial.println(currentIndex);
      #endif
      if (n>=CurrentIndex) {        
        if (n-CurrentIndex == selected) {
          #ifdef DEBUG 
          Serial.print(F("SEL FL:")); Serial.println(dirFunc.CurrentFileName.value);
          #endif
          if (dirFunc.IsDirectory) {
            #ifdef DEBUG 
            Serial.println(F("DIR!"));
            #endif
            if (!strcmp(dirFunc.CurrentFileName.value, "..")) {
              #ifdef DEBUG
              Serial.println(F("TO ROOT"));
              #endif
              dirFunc.GoBack();
            } else {
              dirFunc.ChangeDirectory(dirFunc.CurrentFileName.value);                          
            }
            dirFunc.Prepare();
            CurrentPageIndex = 0;            
            CurrentIndex = 0;
            TransferDirectory(CurrentIndex);
            break;             
          } else {            
            dirFunc.SetSelected(selected);
            TransferGame(dirFunc.CurrentFileName);                                
//            if (IsMatchLast(dirFunc.CurrentFileName.value, ".wav") || IsMatchLast(dirFunc.CurrentFileName.value, ".WAV")) {
//              TransferSound(dirFunc.CurrentFileName.value);
//            } else if (args==0) {
//              TransferGame(dirFunc.CurrentFileName);                    
//            } else {
//              LoadData(args);
//            }
          }
        }       
      }
      n++; 
    } 
  }   
}
*/

void CartApi::TransferGame(StringPrint selectedFile) {
  TransferGame(selectedFile.value);
}

void CartApi::TransferGame(char * selectedFileName) {
  int streamState;  
  const size_t BUF_SIZE = 16;
  uint8_t buf[BUF_SIZE];  
  cartInterface.EndListening();
  #ifdef DEBUG   
  Serial.print(F("OPENING:")); Serial.println(selectedFileName);
  #endif

  unsigned char crtFile = 0;
  unsigned char booter = 0;
  uint16_t contentLength = 0;

  workingFile = sd.open(selectedFileName);
  
  if (workingFile ) {    
    contentLength = workingFile.size();
    
   #ifdef DEBUG 
    Serial.print(contentLength); Serial.println(F(" bytes"));   
   #endif
    if (strcmp(selectedFileName, "keybooter.prg") == 0 || ( IsMatchLast(selectedFileName, ".irq") || IsMatchLast(selectedFileName, ".IRQ") ) ) {
      booter = 1;
      Serial.println(F("BOOTER!"));
    }
    if ( IsMatchLast(selectedFileName, ".crt") || IsMatchLast(selectedFileName, ".CRT") ) {
      crtFile = 1;
      Serial.print(F("CRT!"));
    }
    
    if (crtFile) workingFile.seek(80);

    long transferLength = crtFile ? contentLength - 80 : contentLength - 2;
    long padBytes = (transferLength%256==0) ? 0 : 256 - transferLength%256; 
    byte transferPages = (byte)(transferLength/256 + (padBytes>0 ? 1 : 0));
    cartInterface.ResetIndex();
    cartInterface.EnableCartridge();
    cartInterface.ResetC64();
  
    delay(200);
    //delay(500);
    
    int c = 0;
    int index = 0;
    unsigned char low;
    unsigned char high;
    unsigned char data;
    int readCount = 0;
    Serial.println(F("Loading"));
    //TODO : Put input mechanics elsewhere...
    //pressTime = millis();

    uint8_t initialBuff[2];
    if (!crtFile) {
        low = workingFile.read();
        high = workingFile.read();
    } else {
      low = 0;
      high = 0x80;
    }
    
    //noInterrupts();
    
    SendHeader(low, high, transferPages, transferLength, (crtFile ? TYPE_CARTRIDGE : (booter ? TYPE_BOOTER : TYPE_STANDARD_PRG)), cartInterface.TransferMode); 

    #ifdef  USERAMLAUNCHER
    SendLoaderStub();
    #endif

    while(workingFile.available() > 0) {      
      readCount = workingFile.read(buf, sizeof(buf));
  
      if (readCount > 0) {
        for (int i = 0;i<readCount;i++) {     
            cartInterface.TransmitByteFast(buf[i]);
        }
      }
    }        
        
    if (padBytes>0) {
      for (int i=0;i<padBytes;i++) {    
        cartInterface.TransmitByteFast(0x00); 
      }
    }   
    
    //For game mode
//    cartInterface.SetPage(0x80);    
//    delayMicroseconds(30);
//    cartInterface.DisableCartridge();

    //For special program mode
    delayMicroseconds(30);
    Init();    

    cartInterface.StartListening();
    //interrupts();
    
    #ifdef DEBUG   
      Serial.println(F("Done"));    
      TransferInfo(transferLength, padBytes, transferPages);    
    #endif    
    
    } else {
      Serial.println(F("FILENOTFOUND!"));
    }

    //if (booter)   cartApi.HandleApi();

    //SendTestProgramToSecondaryLoader();
}

void CartApi::ReceiveFile() {
  #ifdef DEBUG
  Serial.println(F("Receiving"));
  #endif
  long startTransfer = millis();
  cartInterface.EndListening();
  cartInterface.EnableCartridge();
  cartInterface.ResetC64();  
  cartInterface.ResetIndex();
  delay(200);  
  #ifdef DEBUG  
  Serial.println(F("Resetted"));  
  #endif  
  unsigned int receivedCount = 0;
  unsigned int dataLength = 0;
  unsigned char low = 0;  
  unsigned char high = 0;  
  int endCondition = 0;
  
  while (receivedCount<4) {
    //if ((millis() - startTransfer) > 10000) break;
    if (Serial.available() > 0) {
      if ((millis() - startTransfer) > 20000) break;
      unsigned char data=Serial.read();    
      if (receivedCount == 0) {
        dataLength = data;
      } else if (receivedCount == 1) {
        dataLength = data * 256 + dataLength;
      } else if (receivedCount == 2) {
        low = data;
      } else if (receivedCount == 3) {
        high = data;
      }
      receivedCount++;
    }
  }

  Serial.println(F("HEAD"));  
  
  long transferLength = dataLength - 2;
  long padBytes = (transferLength%256==0) ? 0 : 256 - transferLength%256; 
  byte transferPages = (byte)(transferLength/256 + (padBytes>0 ? 1 : 0));  

  cartInterface.ResetIndex();

  SendHeader(low, high, transferPages, transferLength, TYPE_PRG_TRANSMISSION,cartInterface.TransferMode);  //End address is not specifically correct. Should be corrected in IrqHackSend program.
  
  receivedCount = 0;

  cartInterface.ResetIndex();
  #ifdef  USERAMLAUNCHER
  SendLoaderStub();
  #endif
  
  while (receivedCount<transferLength) {
    //if ((millis() - startTransfer) > 10000) break;
    
    if (Serial.available() > 0) {    
      //if ((millis() - startTransfer) > 10000) break;     
      unsigned char data=Serial.read();    
      cartInterface.TransmitByteFast(data); 
      receivedCount++;      
    }
  }
  
  Serial.println(F("RCVD"));   
  
  if ((millis() - startTransfer) < 10000) {
    if (padBytes>0) {
      for (int i=0;i<padBytes;i++) {    
        cartInterface.TransmitByteFast(0xEA); 
      }
    }  
  }
  delayMicroseconds(20);
  cartInterface.DisableCartridge();
  Serial.println(F("OK"));    
  #ifdef DEBUG 
  Serial.print(F("DAT LEN : "));Serial.println(dataLength);
    TransferInfo(transferLength, padBytes, transferPages);    
  #endif    

  cartInterface.StartListening();
}



void CartApi::UpdateFile() {
  cartInterface.EndListening();
  const size_t BUF_SIZE = 64;
  uint8_t buf[BUF_SIZE];  
  #ifdef DEBUG
  Serial.println(F("Receiving"));
  #endif
  long startTransfer = millis();

  unsigned int receivedCount = 0;
  unsigned int dataLength = 0;

  char fileName[20];

  int readByte = -1;  
  unsigned char fileNameIndex = 0; 

  while (readByte!=0) {
      if ((millis() - startTransfer) > 20000) break;    
      if (Serial.available()>0) {
        readByte = Serial.read();
        fileName[fileNameIndex] = readByte;
        fileNameIndex++;
      }
  }

  Serial.print(F("Received filename : ")); Serial.println(fileName);
  
  while (receivedCount<2) {
    if (Serial.available() > 0) {
      if ((millis() - startTransfer) > 20000) break;
      unsigned char data=Serial.read();    
      if (receivedCount == 0) {
        dataLength = data;
      } else if (receivedCount == 1) {
        dataLength = data * 256 + dataLength;
      } 
      receivedCount++;
    }
  }

  Serial.println(F("Will read file content"));   
    sd.remove(fileName);
    File workingFile = sd.open(fileName, FILE_WRITE | O_CREAT);
    if (workingFile != NULL) {
      Serial.println(F("File open success"));

      receivedCount = 0;
      int bufferIndex = 0;
      int padSize = dataLength % BUF_SIZE;
      while (receivedCount<dataLength) {
        if ((millis() - startTransfer) > 120000) {
          Serial.println(F("Timed out"));  
          break;
        } else {        
          if (Serial.available() > 0) {    
            buf[bufferIndex] = Serial.read();    
            bufferIndex++;
            receivedCount++;      
            if (bufferIndex == BUF_SIZE) {
              workingFile.write(buf, BUF_SIZE);
              bufferIndex = 0;
            }
          }
        }
      }

      if (padSize>0) {
        workingFile.write(buf, padSize);
      }

      workingFile.close();
      
      Serial.println(F("File written!"));          
    } else  {
      Serial.println(F("File open failed"));      
    }  

    cartInterface.StartListening();    
}


void CartApi::ResetNoCartridge() {
  cartInterface.DisableCartridge();
  cartInterface.ResetC64();
}


void CartApi::SendStubLoader() {
  #ifdef DEBUG
  Serial.println(F("Loading stub"));
  #endif  

  cartInterface.InitTransfer();
  delay(500);
  
  for (int i = 0;i<stub_len;i++) {
    cartInterface.TransmitByteFast(*(stubData + i));
  }

  for (int i = stub_len;i<256;i++) {
      cartInterface.TransmitByteFast(0x20); 
  }
 
  cartInterface.EndTransfer(); 
  #ifdef DEBUG
  Serial.println(F("Done"));
  #endif  
}
/*
void CartApi::SendTestProgramToSecondaryLoader() {
  #ifdef DEBUG
  Serial.println(F("Loading secondary loader"));
  #endif  

  cartInterface.InitCustomTransfer();
  delay(500);
  
  unsigned long timeRunning = micros();
  for (int i = 0;i<test_data_len;i++) {
    cartInterface.TransmitCustomByteAsync(*(testProgram + i));
  }

  for (int i = test_data_len;i<256;i++) {
      cartInterface.TransmitByteAsync(0x20); 
  }
  unsigned long elapsed = micros() - timeRunning;
  cartInterface.EndCustomTransfer();    
  Serial.print("Done - it took "); Serial.print(elapsed); Serial.println(" microseconds");
}
*/
