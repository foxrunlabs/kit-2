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
# File Name : Makefile
# Project   : Kit-2 8-bit Computer
# Author    : Ryan Clarke
# E-mail    : kj6msg@icloud.com
#-------------------------------------------------------------------------------
# Purpose   : Makefile for the entire Kit-2 project.
#===============================================================================


GREEN   = \033[0;32m
NOCOLOR = \033[0m

PREFIX  = .
BIOSBIN := $(PREFIX)/kitbios/bin/kitbios.bin
BIOSINC := $(PREFIX)/kitpic.X/src/kitbios.inc

BIN2INC = $(PREFIX)/bin2inc/bin/bin2inc
MAKE    = make

.PHONY: all
all : bios pic

.PHONY: bios
bios :
	@echo "[${GREEN}Building KitBIOS${NOCOLOR}]"
	$(MAKE) -C kitbios

.PHONY: pic
pic :
	@echo "[${GREEN}Building KitPIC${NOCOLOR}]"
	$(MAKE) -C kitpic.X

.PHONY: sim
sim :
	@echo "[${GREEN}Building KitBIOS (py65mon version)${NOCOLOR}]"
	$(MAKE) -C kitbios $@

.PHONY: clean
clean :
	@echo "[${GREEN}Cleaning KitBIOS${NOCOLOR}]"
	$(MAKE) -C kitbios $@
	@echo "[${GREEN}Cleaning KitPIC${NOCOLOR}]"
	$(MAKE) -C kitpic.X $@
