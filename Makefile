# Variables to override
#
# CC            C compiler
# CROSSCOMPILE  crosscompiler prefix, if any
# CFLAGS        compiler flags for compiling all C files
# LDFLAGS       linker flags for linking all binaries

# Initialize some variables if not set
LDFLAGS ?=
CFLAGS ?= -O2 -Wall
CC ?= $(CROSSCOMPILE)-gcc

# Check that we're on a supported build platform
ifeq ($(CROSSCOMPILE),)
# Not crosscompiling, so check that we're on Linux.
ifneq ($(shell uname -s),Linux)
$(warning dht only works on Linux on a Raspberry Pi. Crosscompilation)
$(warning is supported by defining at least $$CROSSCOMPILE. See Makefile for)
$(warning details. If using Nerves, this should be done automatically.)
$(warning .)
$(warning Skipping C compilation unless targets explicitly passed to make.)
DEFAULT_TARGETS = priv
endif
endif
DEFAULT_TARGETS ?= priv priv/dht


SRC=$(wildcard src/*.c)
OBJ=$(SRC:.c=.o)

.PHONY: all clean

all: $(DEFAULT_TARGETS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

priv:
	mkdir -p priv

priv/dht: $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f priv/dht $(OBJ)
