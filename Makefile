# Variables to override
#
# CC            C compiler
# CROSSCOMPILE  crosscompiler prefix, if any
# CFLAGS        compiler flags for compiling all C files
# LDFLAGS       linker flags for linking all binaries

# Initialize some variables if not set
LDFLAGS ?=
CC ?= $(CROSSCOMPILE)-gcc

CFLAGS := $(CFLAGS) -std=gnu99 -O2 -Wall

# Check that we're on a supported build platform
ifeq ($(CROSSCOMPILE),)
    # Not crosscompiling, so check that we're on Linux.
    ifneq ($(shell uname -s),Linux)
        $(warning dht only works on Linux on a Raspberry Pi. Crosscompilation)
        $(warning is supported by defining at least $$CROSSCOMPILE and $$MIX_TARGET.)
        $(warning See Makefile for details. If using Nerves, this should be done automatically.)
        $(warning )
        $(warning Skipping C compilation unless targets explicitly passed to make.)
        DEFAULT_TARGETS = priv
    endif
endif
DEFAULT_TARGETS ?= priv priv/dht

ifeq ($(TRAVIS),true)
    $(warning TRAVIS build)
    DEFAULT_TARGETS = priv
endif

# Raspberry Platform
CFLAGS := $(CFLAGS) -D$(MIX_TARGET)
ifeq ($(MIX_TARGET),rpi)
    SRC = $(wildcard src/*.c src/rpi/*.c)
endif
ifeq ($(MIX_TARGET),rpi0)
    SRC = $(wildcard src/*.c src/rpi0/*.c)
endif
ifeq ($(MIX_TARGET),rpi2)
    SRC = $(wildcard src/*.c src/rpi2/*.c)
endif
ifeq ($(MIX_TARGET),rpi3)
    SRC = $(wildcard src/*.c src/rpi3/*.c)
endif
ifeq ($(MIX_TARGET),rpi4)
    SRC = $(wildcard src/*.c src/rpi4/*.c)
endif
SRC ?=

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
