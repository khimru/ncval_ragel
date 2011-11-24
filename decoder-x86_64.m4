#include <assert.h>
#include <elf.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "decoder-x86_64.h"

#undef TRUE
#define TRUE    1

#undef FALSE
#define FALSE   0

%%{
  machine decode_x86_64;
  alphtype unsigned char;

  include(common.m4)

  include(｢common_decoding.m4｣)

  include(instruction_parts.m4)

  define(｢_instruction_name_action｣,
    ｢action instruction_｢｣$1 { ｢instruction_name｣ = "$1"; }｣)

  include(instructions.m4)

  main := (valid_instruction
    >{｢
	begin = p;
	disp_type = DISPNONE;
	imm_operand = IMMNONE;
	rex_prefix = FALSE;
	data16_prefix = FALSE;
	lock_prefix = FALSE;
	rep_prefix = FALSE;
	repe_prefix = FALSE;
	repne_prefix = FALSE;
	branch_not_taken = FALSE;
	branch_taken = FALSE;
    ｣}
    @{｢
	switch (disp_type) {
	  case DISPNONE: instruction.rm.offset = 0; break;
	  case DISP8: instruction.rm.offset = *disp; break;
	  case DISP32: instruction.rm.offset = (int32_t)
	    (disp[0] + 256 * (disp[1] + 256 * (disp[2] + 256 * (disp[3]))));
	    break;
	}
	switch (imm_operand) {
	  case IMMNONE: instruction.imm = 0; break;
	  case IMM8: instruction.imm = *imm; break;
	  case IMM16: instruction.imm = (int64_t) (imm[0] + 256 * (imm[1]));
	    break;
	  case IMM32: instruction.imm = (int64_t)
	    (imm[0] + 256 * (imm[1] + 256 * (imm[2] + 256 * (imm[3]))));
	    break;
	  case IMM64: instruction.imm = (int64_t)
	    (imm[0] + 256LL * (imm[1] + 256LL * (imm[2] + 256LL * (imm[3] +
	    256 * (imm[4] + 256 * (imm[5] + 256 * (imm[6] + 256 * imm[7])))))));
	    break;
	}
	process_instruction(begin, p+1, &instruction, userdata);
    ｣})*
    $!{｢ process_error(p, userdata);
	result = 1;
	goto error_detected;
    ｣};

}%%
｢

%% write data;

#define base instruction.rm.base
#define index instruction.rm.index
#define scale instruction.rm.scale
#define rex_prefix instruction.prefix.rex
#define data16_prefix instruction.prefix.data16
#define lock_prefix instruction.prefix.lock
#define rep_prefix instruction.prefix.rep
#define repe_prefix instruction.prefix.repe
#define repne_prefix instruction.prefix.repne
#define branch_not_taken instruction.prefix.branch_not_taken
#define branch_taken instruction.prefix.branch_taken
#define operand0_size instruction.operands[0].size
#define operand1_size instruction.operands[1].size
#define operand2_size instruction.operands[2].size
#define operand0 instruction.operands[0].name
#define operand1 instruction.operands[1].name
#define operand2 instruction.operands[2].name
#define operands_count instruction.operands_count
#define instruction_name instruction.name

enum {
  REX_B = 1,
  REX_X = 2,
  REX_R = 4,
  REX_W = 8
};

enum disp_mode {
  DISPNONE,
  DISP8,
  DISP32,
};

enum imm_mode {
  IMMNONE,
  IMM8,
  IMM16,
  IMM32,
  IMM64
};

static const uint8_t index_registers[] = {
  REG_RAX, REG_RCX, REG_RDX, REG_RBX,
  REG_RIZ, REG_RBP, REG_RSI, REG_RDI,
  REG_R8,  REG_R9,  REG_R10, REG_R11,
  REG_R12, REG_R13, REG_R14, REG_R15
};

int DecodeChunk(uint32_t load_addr, uint8_t *data, size_t size,
		process_instruction_func process_instruction,
		process_error_func process_error, void *userdata) {
  uint8_t *p = data;
  uint8_t *pe = data + size;
  uint8_t *eof = pe;
  uint8_t *disp = NULL, *imm = NULL, *begin;
  uint8_t *begin_opcode, *end_opcode;
  enum disp_mode disp_type = DISPNONE;
  enum imm_mode imm_operand = IMMNONE;
  struct instruction instruction;
  int result = 0;

  int cs;

  %% write init;
  %% write exec;

error_detected:
  return result;
}

｣
