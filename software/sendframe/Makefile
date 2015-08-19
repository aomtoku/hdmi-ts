#Makefile for FrameSend send.c

CC = gcc
CFLAGS = -O -Wall -g
OBJS = main.o
INCLUDES = -I/usr/local/include
TARGET = sendframe
SRC = main.c send.h

all:	$(TARGET)

$(TARGET): $(OBJS)
	$(CC)  -o $@ $(OBJS)

clean:
	-rm -f $(TARGET) $(OBJS) 

.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) -c $<
