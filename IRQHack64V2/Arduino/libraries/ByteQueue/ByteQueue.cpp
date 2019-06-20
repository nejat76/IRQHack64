#include <Arduino.h>
#include <stdlib.h> 
#include "ByteQueue.h"

ByteQueue::ByteQueue(){
	Reset();
}

 void ByteQueue::Reset(){
	head = 0;
    tail = 0;
 }
 
void ByteQueue::Enqueue(uint8_t data){
    item[tail] = data;
    tail = (tail+1)%QUEUE_MAX_SIZE;
}
 
 
uint8_t ByteQueue::Dequeue(){
    uint8_t temp;
    temp = item[head];
    head = (head+1)%QUEUE_MAX_SIZE;
    return temp;
}
 
 
int8_t ByteQueue::Size(){
    return (tail - head);
}
 
 
bool ByteQueue::IsEmpty(){
    if(abs(head == tail)){
        return true;
    }else{
        return false;
    }
}

bool ByteQueue::IsAvailable(){
	return !IsEmpty();
}
 
bool ByteQueue::IsFull(){
    if(head==(tail+1)%QUEUE_MAX_SIZE){
        return true;
    }else{
        return false;
    }
}