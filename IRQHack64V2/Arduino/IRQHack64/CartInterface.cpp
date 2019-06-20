#include <Arduino.h>
#include <ByteQueue.h>
#include "CartInterface.h"
#include "IrqHack64.h"

volatile ByteQueue readQueue;
volatile uint8_t bitState = BIT_STARTED;
volatile int receiveState = IDLE;

volatile uint8_t currentByte = 0;
volatile uint8_t bitMask = 1;
volatile unsigned long lastInterruptTime = 0;
volatile unsigned long timeDifference = 0;
volatile unsigned long interruptTime = 0;
//volatile uint8_t toggle = 1;

static void CartInterface::ReceiveInterrupt() {
  
    lastInterruptTime = interruptTime;
    interruptTime = micros();
    timeDifference = interruptTime - lastInterruptTime;

    switch(bitState) {
    case BIT_STARTED :
      if (timeDifference<350 || timeDifference>1000) {
        bitState = BIT_STARTED;
        currentByte = 0;
        bitMask = 1;
      } else {
        if (timeDifference<450) {
          bitState = BIT_ZERO_END;
        } else if (timeDifference>700) {
          bitState = BIT_ONE_END;
        } else {
          bitState = BIT_STARTED;
          currentByte = 0;
          bitMask = 1;          
        }     
      }
    break;
    case BIT_ZERO_END :
      bitState = BIT_STARTED;
      return;
    break;
    case BIT_ONE_END :
      bitState = BIT_STARTED;
      return;
    break;
  }

  if (receiveState == IN_TRANSMISSION) {
    if (bitState > BIT_STARTED) {
      if (bitState == BIT_ONE_END) {
        currentByte = currentByte | bitMask;      
      }  
    
      bitMask<<=1;
      
      if (bitMask == 0) {      
        if (!readQueue.IsFull()) {
          readQueue.Enqueue(currentByte);
        }                  
        
        bitMask = 1;
        currentByte = 0;      
      }      
    }
  }
  
}

uint8_t CartInterface::ReceiveHandler() {
    if (receiveState == IN_TRANSMISSION) {
        return receiveState;
    }
    //Serial.println(timeDifference);
    if (bitState < BIT_ZERO_END) {
      return receiveState;
    }
    
       
    // A bit transfer has been finished
        
    if (bitState == BIT_ONE_END) {
      currentByte = currentByte | bitMask;      
    }    
  
    bitMask<<=1;
    
    if (bitMask == 0) {
      switch(receiveState) {
        case IDLE : 
        if (currentByte == IDENTIFIER_1) {
          receiveState = IDENTIFIER_1_OK;
          //Serial.println(F("1"));
        }
        break;
        
        case IDENTIFIER_1_OK : 
        if (currentByte == IDENTIFIER_2) {
          receiveState = IDENTIFIER_2_OK;
          //Serial.println(F("2"));
        }
        break;

        case IDENTIFIER_2_OK :
        if (currentByte == IDENTIFIER_3) {
          receiveState = IDENTIFIER_3_OK;
          //Serial.println(F("3"));
        }
        break;
        
        case IDENTIFIER_3_OK :                    
          if (!readQueue.IsFull()) {
            readQueue.Enqueue(currentByte);
          }          
          receiveState = IN_TRANSMISSION;      
          EnableCartridge(); 
          //Serial.println(F("Q"));
        break;         

        case IN_TRANSMISSION : break;     
          if (!readQueue.IsFull()) {
            readQueue.Enqueue(currentByte);
            //Serial.println(currentByte);
          }          
      }
      
      bitMask = 1;
      currentByte = 0;      
    }

    // Wait until next bit is transferred or whole process is restarted.
    while(bitState >= BIT_ZERO_END) {
      if (receiveState == IN_TRANSMISSION) break;
    }

    return receiveState;
}

void CartInterface::SetAddressPinsOutput() {
  #ifdef __AVR__
    #ifdef PORT_MANIPULATION  
    DDRD = DDRD | B11110000; // Set Pin 4..7 as outputs. A12, A13, A14, A15
    DDRC = DDRC | B00001111; // Set Analog pin 0..3 as outputs A8, A9, A10, A11
    #else
    for (int i=0;i<8;i++) {
      pinMode(addressPins[i], OUTPUT);
    }  
    #endif
  #endif
}


uint16_t CartInterface::Read() {
  if (readQueue.IsAvailable()) {
    uint8_t val = readQueue.Dequeue();
    uint16_t intVal = val;
    return val;    
  } else {      
      return -1;
  }
}

void CartInterface::IOSetup() {  
  pinMode(IRQ, INPUT);    
  pinMode(EXROM, OUTPUT);    
  digitalWrite(EXROM, HIGH);    
  pinMode(SEL, INPUT);  
  digitalWrite(SEL, HIGH); //Activate internal pullup    
  #ifdef OPENCOLLECTORSTYLE      
    ResetHigh();        
    NmiHigh();
  #else  
    pinMode(RESET, OUTPUT);
    digitalWrite(RESET, HIGH);
    
    pinMode(NMI, OUTPUT);
    digitalWrite(NMI, HIGH);                
  #endif  

}


void CartInterface::ResetReceive() {
  bitState = BIT_STARTED;
  receiveState = IDLE;
  bitMask = 1;  
  //Discard any received items that are not consumed.
  readQueue.Reset(); 
}

void CartInterface::ResetReceiveNoStateChange() {
  bitState = BIT_STARTED;
  bitMask = 1;  
  //Discard any received items that are not consumed.
  readQueue.Reset(); 
}

void CartInterface::StartListening() {
  ResetReceive();
  attachInterrupt(digitalPinToInterrupt(IRQ), CartInterface::ReceiveInterrupt, FALLING);      
}

void CartInterface::EndListening() {
  detachInterrupt(digitalPinToInterrupt(IRQ));
  ResetReceive();
  DisableCartridge();
}

void CartInterface::SoftStartListening() {
  ResetReceiveNoStateChange();
  attachInterrupt(digitalPinToInterrupt(IRQ), CartInterface::ReceiveInterrupt, FALLING);      
}

void CartInterface::SoftEndListening() {
  detachInterrupt(digitalPinToInterrupt(IRQ));
  ResetReceiveNoStateChange();
}


void CartInterface::Init() {
  IOSetup();
  SetAddressPinsOutput();  
  StartListening(); 
}


unsigned int CartInterface::GetTransferIndex() {
  return transferIndex;
}

unsigned int CartInterface::GetBlockIndex() {
  return blockIndex;
}


void CartInterface::SetPage(unsigned char value) {  
  #ifdef PORT_MANIPULATION
  PORTD = (PIND & 0x0F) | (value & 0xF0);
  PORTC = (PINC & 0xF0) | (value & 0x0F);
  #else
  unsigned char mask = 1;
  for (int i=0;i<8;i++) {
    digitalWrite(addressPins[i], value & mask);
    mask = mask<<1;
  }    
  #endif   
}

void CartInterface::ResetC64() {
  //Serial.println(F("Resetting"));
  ResetLow();
  delayMicroseconds(1000);  
  ResetHigh();
  //Serial.println(F("Reset"));  
}

void CartInterface::TransmitByteSlow(unsigned char val) {
  SetPage(val);
  NmiLow();
  delayMicroseconds(10); //Wait for interrupt to trigger
  NmiHigh();    
  delayMicroseconds(75);  //Wait for interrupt to finish it's job 
}

void CartInterface::TransmitByteBlockEnd(unsigned char val) {
  SetPage(val);
  NmiLow();
  delayMicroseconds(6); //Wait for interrupt to trigger
  NmiHigh(); 
  delayMicroseconds(100);  //Wait for interrupt to finish it's job
}

void CartInterface::ResetIndex() {
  transferIndex = 0;
  blockIndex = 0;
  //transferBufferIndex=0;
}

void CartInterface::EnableCartridge() {  
  #ifdef DEBUG
  Serial.println("AVR Enabling Cartridge");
  #endif  
  PORTD &= ~_BV (PD3);
}



void CartInterface::DisableCartridge() {  
  PORTD |= _BV (PD3);
}

void CartInterface::ResetLow() {
  #ifdef OPENCOLLECTORSTYLE
   PORTB &= ~_BV(PB1); // turn off internal resistor 
   DDRB |= _BV(PB1); // set to output       
  #else
    PORTB &= ~_BV (PB1);
  #endif  
}

void CartInterface::ResetHigh() {
  #ifdef OPENCOLLECTORSTYLE
    DDRB &= ~_BV(PB1); //switch to input while port is low. 
    PORTB |= _BV(PB1); //turn on internal resistor to Vcc 
  #else
    PORTB |= _BV (PB1);
  #endif 
}

void CartInterface::NmiLow() {
  #ifdef OPENCOLLECTORSTYLE
   PORTB &= ~_BV(PB0); // turn off internal resistor 
   DDRB |= _BV(PB0); // set to output       
  #else
    PORTB &= ~_BV (PB0);
  #endif
}

void CartInterface::NmiHigh() {
  #ifdef OPENCOLLECTORSTYLE
    DDRB &= ~_BV(PB0); //switch to input while port is low. 
    PORTB |= _BV(PB0); //turn on internal resistor to Vcc 
  #else      
    PORTB |= _BV (PB0);
  #endif
}

void CartInterface::TransmitByteFast(unsigned char val) 
{ 
   SetPage(val);
   if (transferIndex==255) {
      NmiLow();      
      delayMicroseconds(7); //Wait for interrupt to trigger
      NmiHigh();      
      delayMicroseconds(80);  //Wait for interrupt to finish it's job
      transferIndex = 0;
      blockIndex++;
   } else {    
      NmiLow();     
      delayMicroseconds(6); //Wait for interrupt to trigger    
      NmiHigh();
      delayMicroseconds(31);  //Wait for interrupt to finish it's job     
      transferIndex++;
   }      
}


void CartInterface::TransmitByteFastStd(unsigned char val) 
{ 
   SetPage(val);
   if (transferIndex==255) {
      NmiLow();      
      delayMicroseconds(7); //Wait for interrupt to trigger
      NmiHigh();      
      delayMicroseconds(80);  //Wait for interrupt to finish it's job
      transferIndex = 0;
      blockIndex++;
   } else {    
      NmiLow();     
      delayMicroseconds(7); //Wait for interrupt to trigger    
      NmiHigh();
      delayMicroseconds(40);  //Wait for interrupt to finish it's job     
      transferIndex++;
   }      
}

void CartInterface::StreamByte(unsigned char value) 
{ 
    SetPage(value);

    NmiLow();      
    delayMicroseconds(5); //Wait for interrupt to trigger
    NmiHigh();      
    
    delayMicroseconds(1);        
}

void CartInterface::InitTransfer()  {
  /* Cart software waits for data while page is negative */
  SetPage(0x80);    
  /* Enable cartridge so on restart rom code is executed */    
  EnableCartridge();
  /* Reset C64 */        
  ResetC64();   
}



