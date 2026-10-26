# Copyright 2026 Paul Maddern (paul@arcadegeek.co.uk)
TESTS = asm ctl html

MK = $(SKOOLKIT_HOME)/tools/disassembly.mk
ifeq ($(wildcard $(MK)),)
    $(error $(MK): file not found)
endif
include $(MK)
