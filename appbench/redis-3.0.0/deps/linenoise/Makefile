STD=
WARN= -Wall
OPT= -Os 

R_CFLAGS= $(STD) $(WARN) $(OPT) $(DEBUG) $(CFLAGS) -fPIC
R_LDFLAGS= $(LDFLAGS) -lhoard -fPIC
DEBUG= -g -fPIC

R_CC=$(CC) $(R_CFLAGS)
R_LD=$(CC) $(R_LDFLAGS)

linenoise.o: linenoise.h linenoise.c

linenoise_example: linenoise.o example.o
	$(R_LD) -fPIC -o $@ $^

.c.o:
	$(R_CC) -fPIC -c $<

clean:
	rm -f linenoise_example *.o
