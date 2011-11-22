CC = gcc
M4 = m4
CFLAGS = -Wall -Werror -O3 -m32 -g
LDFLAGS = -m32 -g
INST_DEFS = general-purpose-instructions.def x86-64-instructions.def

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
