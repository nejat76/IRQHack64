#include "IrqHack64.h"
#include "CartInterface.h"
#include "CartApi.h"
#include <Arduino.h>
#include <EEPROM.h>
#include <SPI.h>
#include <SdFat.h>
#include <SdFatUtil.h>


SdFat sd;
DirFunction dirFunc;
CartApi cartApi;
CartInterface cartInterface;

const unsigned char stateNone = 0;
const unsigned char statePressed = 1;
const unsigned char stateReleased = 2;


const unsigned char stateBoot = 0;
const unsigned char stateMenu = 1;
const unsigned char stateGame = 2;

/*
volatile unsigned char transferMode = 2;
*/

unsigned char  state = stateNone;
uint16_t pressTime = 0;

//unsigned char cartridgeState = stateBoot;

const unsigned char chipSelect = 10;

void ShowMem() {
#ifdef DEBUG  
  Serial.print(F("Free RAM: "));
  Serial.println(FreeRam());    
#endif  
}

#ifdef DEBUG 
void printOptions(void) {
  Serial.println(F("---- IrqHack64 by I.R.on----"));
  Serial.println(F("1. Receive program"));          
  Serial.println(F("2. Load menu"));      
  Serial.println(F("3. Reset C64"));  
  Serial.println(F("4. Reset C64 - Cart disabled"));          
  Serial.println(F("5. Update File "));            
  Serial.println(F("6. Serial Terminal"));     
  Serial.println();
  Serial.println();
  
  ShowMem();
}
#endif

void setup() {
  cartInterface.Init();  
  Serial.begin(57600);
  
  #ifdef NOOUT
  if (!sd.begin(chipSelect, SPI_FULL_SPEED)) {  
      sd.initErrorHalt();
  }    
  #else
  if (!sd.begin(chipSelect, SPI_FULL_SPEED)) {  
      Serial.println(F("Can't initialize!"));
      sd.initErrorHalt();
  } else {    
      uint32_t cardSize  = sd.card()->cardSize();
      if (cardSize == 0) {
        Serial.println(F("cardSize failed"));
        return;
      }
      
      Serial.println(F("\nCard type: "));
      switch (sd.card()->type()) {
      case SD_CARD_TYPE_SD1:
        Serial.println(F("SD1"));
        break;
    
      case SD_CARD_TYPE_SD2:
        Serial.println(F("SD2"));
        break;
    
      case SD_CARD_TYPE_SDHC:
        if (cardSize < 70000000) {
          Serial.println(F("SDHC"));
        } else {
          Serial.println(F("SDXC"));
        }
        break;
      default:
      Serial.println(F("Unknown\n"));
      }                  
  }
  #endif
  
  #ifdef DEBUG
  printOptions();
  #endif
  

//  dirFunc.ReInit();
//  dirFunc.Prepare();
  cartApi.Init();
}


void SerialTestTerminal() {
  Serial.println(F("Test terminal started!"));
  while(1) {
    cartApi.HandleApi();  
  }  
}

void loop() {
  cartApi.HandleApi();
  
  if (!digitalRead(SEL) && state == stateNone) {
    state = statePressed;
    pressTime = millis()/100;
  }

  uint16_t elapsed;
  if (digitalRead(SEL) && state == statePressed) {
    state = stateReleased;          
    elapsed = millis()/100 - pressTime;
    if (elapsed >5) {
      cartApi.ResetNoCartridge();
      //cartridgeState = stateBoot;      
    } else {
      cartApi.TransferMenu();
      //cartridgeState = stateMenu;
    }
  }
  
  if (state == stateReleased) {
    if ( (millis()/100 - pressTime)>15) {
      state = stateNone;
      elapsed = 0;
      pressTime = 0;
    }
  }
    
  while (Serial.available() > 0) {
      char data=(char)Serial.read();
      switch(data) {
          case '1' : cartApi.ReceiveFile(); break;
          case '2' : cartApi.TransferMenu(); break;                                    
          case '3' : cartInterface.ResetC64(); break;
          case '4' : cartApi.ResetNoCartridge(); break;
          case '5' : cartApi.UpdateFile(); break;            
          case '6' : SerialTestTerminal(); break;       
      }
  } 
}

