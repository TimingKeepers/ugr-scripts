CC=gcc
CFLAGS=-Wall

default: spll_reader 

spll_reader: spll_reader.o
	$(CC) $(CFLAGS) -o spll_reader spll_reader.o

spll_reader.o: spll_reader.c
	$(CC) $(CFLAGS) -c spll_reader.c

clean:
	@$(RM) spll_reader *.o
