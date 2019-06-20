#ifndef _DIR_FUNCTION_H
#define _DIR_FUNCTION_H

#include <SdFat.h>
#include <SdFatUtil.h>


#include "StringPrint.h"
#include "CharStack.h"

class DirFunction  {

 protected:
   //SdFile   file;   

 public:
   uint8_t PathDepth = 0;
   static const unsigned int NMax = 20;
   StringStack stack;
   
   unsigned int count;
   unsigned int currentIndex;
   unsigned int selected;

 
 
    void SetSd(SdFat* sdFat);
    void ReInit(void);
    void ToRoot();
    void GoBack();
    void Rewind();
    void Prepare();
    void ChangeDirectory(char * directory);
    void SetSelected(unsigned int );
    unsigned int GetSelected(void);    
    //void InitSerialize();
    //unsigned char Serialize();
    //unsigned char  Deserialize(unsigned char p);    
    unsigned int GetCount();
    //void ChangeToSavedDirectory();
    int Iterate();
    StringPrint CurrentFileName;  
    int  IsDirectory;
    int IsFinished;
    int IsHidden;
    int InSubDir;
	
};
#endif _DIR_FUNCTION_H
