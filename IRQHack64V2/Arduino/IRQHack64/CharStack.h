#ifndef _CHARSTACK_H
#define _CHARSTACK_H

//#define STACK_SIZE 100
#define STACK_SIZE 50
#define STACK_TOP (STACK_SIZE-1)

class CharStack {	
 public: 
	void Push(char);
        char Pop();
        char Current();
        void ReInit();
        //char charBuffer[STACK_SIZE]; // buffer to hold 6 folder names with max length 32 at least
 	      //int top = STACK_TOP;    
 
 protected:
     
	
};


class StringStack : public CharStack {
 protected:

 public: 
        //int itemCount = 0;
        //int itemArray[10] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }; 
        void ReInit(void);
	void PushString(char *);
        char * PopString();
        char * CurrentString(); 
        char * LookAt(int);
        int GetCount();   
        
};

#endif _CHARSTACK_H
