#################################################################
##                                                             ##
##    ██████╗  ██████╗  █████╗                                 ##
##    ██╔══██╗██╔═══██╗██╔══██╗                                ##
##    ██████╔╝██║   ██║███████║                                ##
##    ██╔══██╗██║   ██║██╔══██║                                ##
##    ██║  ██║╚██████╔╝██║  ██║                                ##
##    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝                                ##
##          ██╗      ██████╗  ██████╗ ██╗ ██████╗              ##
##          ██║     ██╔═══██╗██╔════╝ ██║██╔════╝              ##
##          ██║     ██║   ██║██║  ███╗██║██║                   ##
##          ██║     ██║   ██║██║   ██║██║██║                   ##
##          ███████╗╚██████╔╝╚██████╔╝██║╚██████╗              ##
##          ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝              ##
##                                                             ##
##    Main simulation makefile                                 ##
##                                                             ##
#################################################################
##                                                             ##
##     Copyright (C) 2016 ROA Logic BV                         ##
##     www.roalogic.com                                        ##
##                                                             ##
##    This source file may be used and distributed without     ##
##  restrictions, provided that this copyright statement is    ##
##  not removed from the file and that any derivative work     ##
##  contains the original copyright notice and the associated  ##
##  disclaimer.                                                ##
##                                                             ##
##    This soure file is free software; you can redistribute   ##
##  it and/or modify it under the terms of the GNU General     ##
##  Public License as published by the Free Software           ##
##  Foundation, either version 3 of the License, or (at your   ##
##  option) any later versions.                                ##
##  The current text of the License can be found at:           ##
##  http://www.gnu.org/licenses/gpl.html                       ##
##                                                             ##
##    This source file is distributed in the hope that it will ##
##  be useful, but WITHOUT ANY WARRANTY; without even the      ##
##  implied warranty of MERCHANTABILITY or FITTNESS FOR A      ##
##  PARTICULAR PURPOSE. See the GNU General Public License for ##
##  more details.                                              ##
##                                                             ##
#################################################################

all: Makefile

SIMULATORS = ncsim vcs silos icarus riviera
LINTERS    = $(addsuffix _lint, $(SIMULATORS))
SIMWAVES   = $(addsuffix _waves, $(SIMULATORS))

MS     = -s

ROOT_DIR=../../..

##########################################################################
#
# Regression variables
#
##########################################################################
#add regression variables here


##########################################################################
#
# Sources
#
##########################################################################
-include Makefile.include


##########################################################################
#
# libraries
#
##########################################################################
RTL_LIBS := $(RTLLIBS)


##########################################################################
#
# Misc Variables
#
##########################################################################
INCDIRS:=$(INCDIRS)
DEFINES:=$(DEFINES)

LOG=$(TOP).log

shell=/bin/sh


##########################################################################
#
# OVL
#
##########################################################################
ifeq ($(OVL_ASSERT),ON)
    INCDIRS +=$(STD_OVL_DIR)
    DEFINES +=OVL_ASSERT_ON
    LIB_DIR :=$(STD_OVL_DIR)
    LIB_EXT +=.vlib

    ifeq ($(OVL_INIT_MSG),ON)
        DEFINES +=OVL_INIT_MSG
    endif
endif


##########################################################################
#
# Make Targets
#
##########################################################################
.PHONY: $(SIMULATORS) $(LINTERS) $(SIMWAVES)
$(SIMULATORS): % : %/Makefile $(TB_PREREQ)
	@$(MAKE) $(MS) -C $@ sim				\
	VLOG="$(abspath $(RTL_VLOG) $(TB_VLOG))"		\
	TECHLIBS="$(TECHLIBS)"					\
	LIBDIRS="$(LIBDIRS)"					\
	LIBEXT="$(LIBEXT)"					\
	VHDL="$(abspath $(RTL_VHDL) $(TB_VHDL))"		\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	TOP=$(TB_TOP)						\
	LOG=$(LOG) PARAMS="$(PARAMS)"

$(SIMWAVES): %_waves : %/Makefile $(TB_PREREQ)
	@$(MAKE) $(MS) -C $(subst _waves,,$@) simw		\
	VLOG="$(abspath $(RTL_VLOG) $(TB_VLOG))"		\
	TECHLIBS="$(TECHLIBS)"			\
	LIBDIRS="$(LIBDIRS)"					\
	LIBEXT="$(LIBEXT)"					\
	VHDL="$(abspath $(RTL_VHDL) $(TB_VHDL))"		\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	TOP=$(TB_TOP)						\
	LOG=$(LOG) PARAMS="$(PARAMS)"

$(LINTERS): %_lint : %/Makefile $(TB_PREREQ)
	@$(MAKE) $(MS) -C $(subst _lint,,$@) lint		\
	VLOG="$(abspath $(RTL_VLOG))"				\
	VHDL="$(abspath $(RTL_VHDL))"				\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	TOP=$(RTL_TOP)


.PHONY: clean distclean mrproper
clean:
	@for f in $(wildcard *); do				\
		if test -d $$f; then $(MAKE) -C $$f clean; fi	\
	done

distclean:
	@rm -rf $(SIMULATORS) Makefile.include $(TB_PREREQ)

mrproper:
	@rm -rf *


##########################################################################
#
# Make simulation structure
#
##########################################################################
Makefile.include:
	@cp ../bin/Makefile.include .

%/Makefile:
	@mkdir -p $*
	@cp ../bin/Makefile.$* $@

$(TB_PREREQ):
	@cp ../bin/$@ $@
