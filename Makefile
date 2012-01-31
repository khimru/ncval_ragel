# Copyright (c) 2012 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

OUT = out
OUT_DIRS = $(OUT)/build \
	   $(OUT)/tarballs \
	   $(OUT)/timestamps \
	   $(OUT)/test

PYTHON2X=/usr/bin/python2.6
CC = gcc -std=gnu99 -Wdeclaration-after-statement -Wall -pedantic -Wextra \
     -Wno-long-long -Wswitch-enum -Wsign-compare -Wno-variadic-macros -Werror -O3 \
     -finline-limit=10000 -m32
CXX = g++ -std=c++0x -O3 -finline-limit=10000 -m32
CFLAGS = -g
CXXFLAGS = -g
LDFLAGS = -g
INST_DEFS = general-purpose-instructions.def \
	    system-instructions.def \
	    x86-64-instructions.def \
	    x87-instructions.def \
	    mmx-instructions.def \
	    xmm-instructions.def

FAST_TMP_FOR_TEST=/dev/shm

$(OUT_DIRS):
	install -m 755 -d $@

all: decoder-test-x86_64 validator-test-x86_64
.INTERMEDIATE: decoder-test-x86_64.o decoder-x86_64.o
decoder-test-x86_64: decoder-x86_64.o decoder-test-x86_64.o
.INTERMEDIATE: validator-test-x86_64.o validator-x86_64.o
validator-test-x86_64: validator-x86_64.o validator-test-x86_64.o
.INTERMEDIATE: gen-decoder decoder-x86_64.c validator-x86_64.c
decoder-x86_64.c: decoder-x86_64-instruction-consts.c
decoder-x86_64.c: decoder-x86_64-instruction.rl
.INTERMEDIATE: decoder-x86_64-instruction.rl decoder-x86_64-instruction-consts.c
decoder-x86_64-instruction-consts.c decoder-x86_64-instruction.rl: \
							gen-decoder $(INST_DEFS)
	./gen-decoder -o decoder-x86_64-instruction.rl $(INST_DEFS) \
	  -d check_access,opcode,parse_operands_states,mark_data_fields
validator-x86_64.c: validator-x86_64-instruction-consts.c
validator-x86_64.c: validator-x86_64-instruction.rl
.INTERMEDIATE: validator-x86_64-instruction.rl
.INTERMEDIATE: validator-x86_64-instruction-consts.c
validator-x86_64-instruction-consts.c validator-x86_64-instruction.rl: \
							gen-decoder $(INST_DEFS)
	./gen-decoder -o validator-x86_64-instruction.rl $(INST_DEFS) \
	  -d opcode,instruction_name,mark_data_fields,rel_operand_action
one-instruction.rl: one-valid-instruction-consts.c
one-instruction.rl: one-valid-instruction.rl
.INTERMEDIATE: one-valid-instruction.rl one-valid-instruction-consts.c
one-valid-instruction-consts.c one-valid-instruction.rl: \
							gen-decoder $(INST_DEFS)
	./gen-decoder -o one-valid-instruction.rl $(INST_DEFS) \
	  -d check_access,rex_prefix,vex_prefix,opcode,parse_operands \
	  -d parse_operands_states
.INTERMEDIATE: one-instruction.dot one-instruction.xml

%.c: %.rl
	ragel -G2 $<

%.dot: %.rl
	ragel -V $< > $@

%.xml: %.rl
	ragel -x $< > $@

# To test the decoder compare its output with output from objdump.  This
# allows to match instruction opcode, length and operands.
#
# Disassemblers in different versions of binutils produce slightly different
# output.  Do not take binutils as installed on the system, instead download and
# build it.
#
# Original source is located here:
# BINUTILS_URL_BASE = http://ftp.gnu.org/gnu/binutils
BINUTILS_URL_BASE = http://commondatastorage.googleapis.com/nativeclient-mirror/toolchain/binutils
BINUTILS_VER = binutils-2.22
BINUTILS_TARBALL = $(OUT)/tarballs/$(BINUTILS_VER).tar.bz2
BINUTILS_BUILD_DIR = $(OUT)/build/build-$(BINUTILS_VER)
BINUTILS_STAMP = $(OUT)/timestamps/binutils
OBJDUMP = $(BINUTILS_BUILD_DIR)/binutils/objdump
GAS = $(BINUTILS_BUILD_DIR)/gas/as-new

$(BINUTILS_TARBALL): | $(OUT_DIRS)
	rm -f $(BINUTILS_TARBALL)
	cd $(OUT)/tarballs && wget $(BINUTILS_URL_BASE)/$(BINUTILS_VER).tar.bz2

$(BINUTILS_STAMP): $(BINUTILS_TARBALL) | $(OUT_DIRS)
	rm -rf $(OUT)/build/$(BINUTILS_VER)
	cd $(OUT)/build && tar jxf ../tarballs/$(BINUTILS_VER).tar.bz2
	rm -rf $(BINUTILS_BUILD_DIR)
	mkdir -p $(BINUTILS_BUILD_DIR)
	cd $(BINUTILS_BUILD_DIR) && \
	  ../$(BINUTILS_VER)/configure
	$(MAKE) -C $(BINUTILS_BUILD_DIR)
	touch $@

.PHONY: binutils
binutils: $(BINUTILS_STAMP)

.PHONY: clean
clean:
	rm -rf "$(OUT)"/build "$(OUT)"/timestamps "$(OUT)"/test \
	    "$(FAST_TMP_FOR_TEST)"/_test_dfa_insts*

.PHONY: clean-tests
clean-tests:
	rm -rf "$(OUT)"/test "$(FAST_TMP_FOR_TEST)"/_test_dfa_insts*

.PHONY: check
check: $(BINUTILS_STAMP) one-instruction.xml decoder-test-x86_64 | $(OUT)/test
	python dfa_possibilities.py one-instruction.xml > $(OUT)/test/list.s
	$(GAS) --64 $(OUT)/test/list.s -o $(OUT)/test/list.o
	$(OBJDUMP) -d $(OUT)/test/list.o > $(OUT)/test/objdump.txt
	./decoder-test-x86_64 $(OUT)/test/list.o > $(OUT)/test/decoder.txt
	diff -uNr $(OUT)/test/objdump.txt $(OUT)/test/decoder.txt

.PHONY: check-n
check-n: $(BINUTILS_STAMP) one-instruction.dot decoder-test-x86_64 | $(OUT)/test
	$(PYTHON2X) parse_dfa.py <one-instruction.dot \
	    > "$(OUT)/test/test_dfa_transitions.c"
	$(CC) $(CFLAGS) -c test_dfa.c -o "$(OUT)/test/test_dfa.o"
	$(CC) $(CFLAGS) -O0 -I. -c "$(OUT)/test/test_dfa_transitions.c" -o \
	    "$(OUT)/test/test_dfa_transitions.o"
	$(CC) $(LDFLAGS) "$(OUT)/test/test_dfa.o" "$(OUT)/test/test_dfa_transitions.o" \
	    -o $(OUT)/test/test_dfa
	$(PYTHON2X) run_objdump_test.py \
	  --gas="$(GAS)" \
	  --objdump="$(OBJDUMP)" \
	  --decoder=./decoder-test-x86_64 \
	  --tester=./decoder_test_one_file.sh \
	  --nthreads=`cat /proc/cpuinfo | grep processor | wc -l` -- \
	  "$(OUT)/test/test_dfa" "$(FAST_TMP_FOR_TEST)"
