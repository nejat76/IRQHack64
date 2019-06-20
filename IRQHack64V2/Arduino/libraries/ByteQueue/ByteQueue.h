#ifndef _BYTE_QUEUE_
#define _BYTE_QUEUE_

#include <Arduino.h>

#define QUEUE_MAX_SIZE 63

class ByteQueue{
    private:
        uint8_t item[QUEUE_MAX_SIZE];
        volatile int8_t head;
        volatile int8_t tail;
    public:
        ByteQueue();
		void Reset();
        void Enqueue(uint8_t);
        uint8_t Dequeue();
        int8_t Size();
        bool IsEmpty();
		bool IsAvailable();
        bool IsFull();
};

#endif 