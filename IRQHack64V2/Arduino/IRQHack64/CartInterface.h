#ifndef _CARTINTERFACE_

#define _CARTINTERFACE_
#include "Arduino.h"
#include "HardwareSerial.h"
#include "IRQHack64.h"
#include <ByteQueue.h>
#include <SPI.h>

#define PORT_MANIPULATION
#define OPENCOLLECTORSTYLE

#define IRQ 2 
#define EXROM 3
#define NMI 8
#define RESET 9
#define SEL 18

#define PRE_WAIT 3
#define INITIAL_WAIT 17
#define INTER_WAIT 11
#define FINAL_WAIT 23
#define SINGLE_WAIT 35


/* Signaling/SM definitions */
#define ONE 1
#define ZERO 0
#define BIT_WAITING  0
#define BIT_STARTED 1
#define BIT_ZERO_END 2
#define BIT_ONE_END 3

#define IDENTIFIER_1 0x64
#define IDENTIFIER_2 0x46
#define IDENTIFIER_3 0x17

#define IDLE 0
#define IDENTIFIER_1_OK 1
#define IDENTIFIER_2_OK 2
#define IDENTIFIER_3_OK 3
#define GOT_COMMAND_BYTE 4
#define IN_TRANSMISSION 5

/* Signaling/SM definitions */



class CartInterface {

 protected:
  //static ByteQueue readQueue;
  unsigned int transferIndex;
  unsigned int blockIndex;
  //unsigned char transferBufferIndex;
  //static const unsigned char bytesPerNMI = 1;   

 
  void SetAddressPinsOutput();
  void IOSetup();
 private : 
  static void ReceiveInterrupt();
  
 public :
  static const uint8_t TransferMode = 0;
  void Init();  
  void SetPage(unsigned char value);   
  uint8_t ReadIO();
  void SetIO(unsigned char value);    
  unsigned int GetTransferIndex();
  unsigned int GetBlockIndex();
  void ResetC64();
  void TransmitByteSlow(unsigned char val);
  void TransmitByteBlockEnd(unsigned char val) ;
  void ResetIndex();
  void EnableCartridge();
  void DisableCartridge();
  void ResetLow();
  void ResetHigh();
  void NmiLow();
  void NmiHigh();  
  void TransmitByteFast(unsigned char val);
  void StreamByteSlow(unsigned char value);
  void TransmitByteFastStd(unsigned char val);
  void StreamByte(unsigned char value);
  void InitTransfer();
  void EndTransfer();
  void HandleReceive();
  void ResetReceive();
  void ResetReceiveNoStateChange();
  void StartListening();
  void EndListening();

  void SoftStartListening();
  void SoftEndListening();
 
  uint16_t Read();  
  uint8_t ReceiveHandler();    
};

#endif

