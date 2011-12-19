OUT = out
OUT_DIRS = $(OUT)/build \
	   $(OUT)/tarballs \
	   $(OUT)/timestamps \
	   $(OUT)/test

CC = gcc
M4 = m4
CFLAGS = -Wall -Werror -O3 -m32 -g
LDFLAGS = -m32 -g
INST_DEFS = general-purpose-instructions.def \
	    system-instructions.def \
	    x86-64-instructions.def \
	    x87-instructions.def \
	    mmx-instructions.def \
	    xmm-instructions.def

$(OUT_DIRS):
	install -m 755 -d $@

all: decoder-test-x86_64 validator-test-x86_64
decoder-test-x86_64: decoder-x86_64.o decoder-test-x86_64.o
validator-test-x86_64: validator-x86_64.o validator-test-x86_64.o
.INTERMEDIATE: decoder-x86_64.rl
decoder-x86_64.rl: decoder-x86_64.m4 $(INST_DEFS) \
  common.m4 common_decoding.m4 instruction_parts.m4 instructions.m4
.INTERMEDIATE: one-instruction.rl
one-instruction.rl: one-instruction.m4 $(INST_DEFS) \
  common.m4 common_decoding.m4 instruction_parts.m4 instructions.m4

%.rl: %.m4
	$(M4) < $< > $@

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

$(BINUTILS_TARBALL):
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
	rm -rf $(OUT)/build $(OUT)/timestamps $(OUT)/test

.PHONY: check
check: $(BINUTILS_STAMP) one-instruction.xml decoder-test-x86_64 | $(OUT)/test
	python dfa_possibilities.py one-instruction.xml > $(OUT)/test/list.s
	$(GAS) --64 $(OUT)/test/list.s -o $(OUT)/test/list.o
	$(OBJDUMP) -d $(OUT)/test/list.o > $(OUT)/test/objdump.txt
	./decoder-test-x86_64 $(OUT)/test/list.o > $(OUT)/test/decoder.txt
	diff -uNr $(OUT)/test/objdump.txt $(OUT)/test/decoder.txt
