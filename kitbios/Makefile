#===============================================================================
# Copyright 2020 Ryan Clarke
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#===============================================================================

#===============================================================================
# Program   : KitBIOS
# File Name : Makefile
# Project   : Kit-2 8-bit Computer
# Author    : Ryan Clarke
# E-mail    : kj6msg@icloud.com
#-------------------------------------------------------------------------------
# Purpose   : Makefile for the Kit-2 BIOS.
#===============================================================================


SHELL = /bin/sh

.SUFFIXES:
.SUFFIXES: .a65 .o

PREFIX   = .
SRCDIR   := $(PREFIX)/src
BUILDDIR := $(PREFIX)/build
BINDIR   := $(PREFIX)/bin

VPATH = $(SRCDIR):$(BUILDDIR):$(BINDIR)

SRCS := $(notdir $(wildcard */*.a65))

OBJS := $(SRCS:%.a65=%.o)
BIN   = kitbios.bin

SIMOBJS := $(OBJS:%.o=%-sim.o)
SIMBIN  := $(basename $(BIN))-sim.bin

AS      = ca65
ASFLAGS = --cpu 65C02 -l $(BUILDDIR)/$(basename $@).lst -t none

LD       = ld65
LDCONFIG = memory.conf
LDFLAGS  = -C $(LDCONFIG) -m $(BUILDDIR)/$(basename $@).map --obj-path $(BUILDDIR)

.PHONY: all
all : $(BIN)

.PHONY: sim
sim : $(SIMBIN)

$(BUILDDIR) $(BINDIR) :
	mkdir -p $@

%.o %-sim.o : %.a65 kit2.inc | $(BUILDDIR)
	$(AS) $(ASFLAGS) -o $(BUILDDIR)/$@ $<

$(BIN) $(SIMBIN) : | $(BINDIR)
	$(LD) $(LDFLAGS) -o $(BINDIR)/$@ $^

$(BIN) : $(OBJS)

$(SIMBIN) : $(SIMOBJS)
$(SIMBIN) : ASFLAGS += -D SIM

.PHONY: clean
clean :
	rm -rf $(BUILDDIR) $(BINDIR)
