#include <SdFat.h>
#include <SdFatUtil.h>
#include "IRQHack64.h"
#include "Arduino.h"
#include "DirFunction.h"
#include "CharStack.h"
#include <avr/eeprom.h>

extern SdFat  sd;

void DirFunction::ReInit() {
  ToRoot();
  stack.ReInit();
}

void DirFunction::GoBack() {
#ifndef  CALLER_HANDLES_DIRECTORIES  
  count = 0;
  currentIndex = 0;
  IsFinished = 0;
  IsDirectory = 0;
  InSubDir = 0;

  if (!sd.chdir()) {    
    #ifdef DEBUG
    Serial.println("chdir(\) failed");
    #endif
    sd.errorHalt();
  }

  if (stack.GetCount()>0) {
    stack.PopString();
    for (int i = 0;i<stack.GetCount();i++) {
      sd.chdir(stack.LookAt(i));
    }
  }   
#else
  count = 0;
  currentIndex = 0;
  IsFinished = 0;
  IsDirectory = 0;

  sd.chdir(); //We are going to root... C64 will handle going 1 directory back.
  InSubDir = 0;
  PathDepth = 0;  

#endif
}


void DirFunction::ToRoot() {
  count = 0;
  currentIndex = 0;
  IsFinished = 0;
  IsDirectory = 0;
  InSubDir = 0;
  PathDepth = 0;

  if (!sd.chdir()) {    
    #ifdef DEBUG    
    Serial.println("chdir(\) failed");
    #endif
    sd.errorHalt();
  } 
}

void DirFunction::Prepare() {
  SdFile   file;  
  count = 0;
  currentIndex = 0;
  
  SdBaseFile* dirFile = (SdBaseFile*) sd.vwd();
  dirFile->rewind();

  #ifndef  CALLER_HANDLES_DIRECTORIES
  if (stack.GetCount()>0) count++;
  #else 
  if (InSubDir == 1) count++;
  #endif
  
  //Count files
  while (file.openNext(dirFile, O_READ)) {  
    if (!file.isHidden()) {   
      //file.printName(&Serial); 
      count++;
      //Serial.println(); 
    } 
    file.close(); 
  }   

  
  dirFile->rewind();
  #ifdef DEBUG    
  Serial.print(F("File count :  ")); Serial.println(count);
  #endif
}

void DirFunction::ChangeDirectory(char * directory) {
  #ifndef  CALLER_HANDLES_DIRECTORIES  
    ToRoot();  
    
    for (int i = 0;i<stack.GetCount();i++) {
      bool dirChangeStatus = sd.chdir(stack.LookAt(i));
      #ifdef DEBUG
      if (!dirChangeStatus) {
        Serial.print(F("From stack chdir(")); Serial.print(stack.LookAt(i)); Serial.println(F(") failed"));      
      } else {
        Serial.print(F("From stack Entered ")); Serial.println(stack.LookAt(i)); 
      }
      #endif
    }
    
    InSubDir = 1;  
    if (sd.chdir(directory)) {
      stack.PushString(directory);  
    } else {
      #ifdef DEBUG
      Serial.print("chdir("); Serial.print(directory); Serial.println(") failed");      
      #endif
    }
  #else
    sd.chdir(directory);
    InSubDir = 1;
    PathDepth++;
  #endif
}

int DirFunction::Iterate() {
  SdFile   file;  
  //Serial.print(F("Current Index : "));Serial.println(currentIndex);
  SdBaseFile* dirFile = (SdBaseFile*) sd.vwd();  

  CurrentFileName.ResetIndex();  
  if (InSubDir==1 && currentIndex == 0) {
    CurrentFileName.Copy("..");
    IsDirectory = 1;
    IsHidden = 0;
    currentIndex++;
    return 1;
  }
  
  if (currentIndex<count) {      
    if (file.openNext(dirFile, O_READ)) {        
      if (!file.isHidden()) {  
        file.printName(&CurrentFileName); 
        //Serial.println(CurrentFileName.value);
        currentIndex++;
        IsDirectory = file.isSubDir();
        IsHidden = 0;
        file.close();         
        return 1;
      }  else {
        IsHidden = 1;
        IsDirectory = file.isSubDir();
        file.close();         
        return 1;
      }      
    } else {
      IsFinished = 1;
      #ifdef DEBUG
      Serial.println(F("OpenNext failed! Finished"));
      #endif
      return 0;
    }
  } else {
    IsFinished = 1;
    #ifdef DEBUG
    Serial.println(F("Finished"));
    #endif
    return 0;
  }
  
  return 0;
}

unsigned int  DirFunction::GetCount() {
  return count;
}

void DirFunction::Rewind() {
  SdBaseFile* dirFile = (SdBaseFile*) sd.vwd(); 
  dirFile->rewind();
  currentIndex = 0;  
  IsDirectory = 0;
  IsHidden = 0;
  IsFinished = 0;
}

void DirFunction::SetSelected(unsigned int selectedIndex) {
  selected = selectedIndex;
}

unsigned int DirFunction::GetSelected(void) {
  return selected;  
}  

/*
static unsigned char serialization = 0;

void DirFunction::InitSerialize()  {
  serialization = 0;
}

unsigned char DirFunction::Serialize() {
  if(serialization == 0) {
    serialization++;    
     return 8 + STACK_SIZE + 10*2;
  } else if(serialization == 1) {
    serialization++;    
    return stack.top&0xFF;
  } else if(serialization == 2) {
    serialization++;    
    return stack.top>>8;
  } else if(serialization == 3) {
    serialization++;    
    return selected&0xFF;
  } else if(serialization == 4) {
    serialization++;    
    return selected>>8;
  } else if(serialization == 5) {
    serialization++;    
    return stack.itemCount&0xFF;
  } else if(serialization == 6) {
    serialization++;    
    return stack.itemCount>>8;
  } else if(serialization == 7) {
    serialization++;    
    return count&0xFF;
  } else if(serialization == 8) {
    serialization++;    
    return count>>8;
  }
  
  else if(serialization >8 && serialization<29) {
    serialization++;    
    unsigned int item = stack.itemArray[(serialization-9)/2];
    if (serialization %2) {
       return ((unsigned int)item)>>8; //high
    } else {
     return item & 0xFF; //low      
    }
  } else if(serialization >28) {
    serialization++;    
    return stack.charBuffer[serialization-29];
  }   
}

unsigned char  DirFunction::Deserialize(unsigned char p) {
  if(serialization == 0) {
    serialization++;    
    return 8 + STACK_SIZE + 10*2;
  } else if(serialization == 1) {
    serialization++;    
    stack.top = p;    
  } else if(serialization == 2) {
    serialization++;    
    stack.top = stack.top | ((unsigned int)p<<8);
  } else if(serialization == 3) {
    serialization++;    
    selected = p;
  } else if(serialization == 4) {
    serialization++;    
    selected = selected | ((unsigned int)p<<8);
  } else if(serialization == 5) {
    serialization++;    
    stack.itemCount = p;
  } else if(serialization == 6) {
    serialization++;    
    stack.itemCount = stack.itemCount | ((unsigned int)p<<8);
  } else if(serialization == 7) {
    serialization++;    
    count = p;
  } else if(serialization == 8) {
    serialization++;    
    count = count | ((unsigned int)p<<8);
  }    
  else if(serialization >8 && serialization<29) {
    serialization++;    

    if (serialization %2) {
       stack.itemArray[(serialization-9)/2]=stack.itemArray[(serialization-9)/2] | (((unsigned int)p)<<8);      
    } else {
       stack.itemArray[(serialization-9)/2]=p;
    }
  }  
  else if(serialization > 28) {
    serialization++;    
    stack.charBuffer[serialization-29] = p;
  } 
 
 return 0; 
}

void DirFunction::ChangeToSavedDirectory() {
 for (int i = 0;i<stack.GetCount();i++) {
    bool dirChangeStatus = sd.chdir(stack.LookAt(i));
    #ifdef DEBUG
    if (!sd.chdir(stack.LookAt(i))) {
      Serial.print(F("From stack chdir(")); Serial.print(stack.LookAt(i)); Serial.println(F(") failed"));      
    } else {
      Serial.print(F("From stack Entered ")); Serial.println(stack.LookAt(i)); 
    }
    #endif
  }  
}

*/
