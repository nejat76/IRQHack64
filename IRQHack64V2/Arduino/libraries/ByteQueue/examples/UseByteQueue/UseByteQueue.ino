#include <ByteQueue.h>

ByteQueue queue;

void setup()
{
}

void loop()
{
	queue.Enqueue(100);
	queue.Dequeue();
}