/*
 * Copyright (c) 2011 The Native Client Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

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
	imm2_operand = IMMNONE;
	rex_prefix = FALSE;
	data16_prefix = FALSE;
	lock_prefix = FALSE;
	repnz_prefix = FALSE;
	repz_prefix = FALSE;
	branch_not_taken = FALSE;
	branch_taken = FALSE;
    ｣}
    @{｢
	switch (disp_type) {
	  case DISPNONE: instruction.rm.offset = 0; break;
	  case DISP8: instruction.rm.offset = (int8_t) *disp; break;
	  case DISP16: instruction.rm.offset =
	    (int16_t) (disp[0] + 256 * disp[1]);
	    break;
	  case DISP32: instruction.rm.offset = (int32_t)
	    (disp[0] + 256 * (disp[1] + 256 * (disp[2] + 256 * (disp[3]))));
	    break;
	  case DISP64: instruction.rm.offset = (int64_t)
	    (disp[0] + 256LL * (disp[1] + 256LL * (disp[2] + 256LL * (disp[3] +
	    256LL * (disp[4] + 256LL * (disp[5] + 256LL * (disp[6] + 256LL *
								 disp[7])))))));
	    break;
	}
	switch (imm_operand) {
	  case IMMNONE: instruction.imm[0] = 0; break;
	  case IMM8: instruction.imm[0] = *imm; break;
	  case IMM16: instruction.imm[0] = (int64_t) (imm[0] + 256 * (imm[1]));
	    break;
	  case IMM32: instruction.imm[0] = (int64_t)
	    (imm[0] + 256 * (imm[1] + 256 * (imm[2] + 256 * (imm[3]))));
	    break;
	  case IMM64: instruction.imm[0] = (int64_t)
	    (imm[0] + 256LL * (imm[1] + 256LL * (imm[2] + 256LL * (imm[3] +
	    256LL * (imm[4] + 256LL * (imm[5] + 256LL * (imm[6] + 256LL *
								  imm[7])))))));
	    break;
	}
	switch (imm2_operand) {
	  case IMMNONE: instruction.imm[1] = 0; break;
	  case IMM8: instruction.imm[1] = *imm2; break;
	  case IMM16: instruction.imm[1] = (int64_t)
	    (imm2[0] + 256 * (imm2[1]));
	    break;
	  case IMM32: instruction.imm[1] = (int64_t)
	    (imm2[0] + 256 * (imm2[1] + 256 * (imm2[2] + 256 * (imm2[3]))));
	    break;
	  case IMM64: instruction.imm[1] = (int64_t)
	    (imm2[0] + 256LL * (imm2[1] + 256LL * (imm2[2] + 256LL * (imm2[3] +
	    256LL * (imm2[4] + 256LL * (imm2[5] + 256LL * (imm2[6] + 256LL *
								 imm2[7])))))));
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
#define repz_prefix instruction.prefix.repz
#define repnz_prefix instruction.prefix.repnz
#define branch_not_taken instruction.prefix.branch_not_taken
#define branch_taken instruction.prefix.branch_taken
#define operand0_type instruction.operands[0].type
#define operand1_type instruction.operands[1].type
#define operand2_type instruction.operands[2].type
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
  DISP16,
  DISP32,
  DISP64,
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

static const uint8_t one = 1;

int DecodeChunk(uint32_t load_addr, uint8_t *data, size_t size,
		process_instruction_func process_instruction,
		process_error_func process_error, void *userdata) {
  const uint8_t *p = data;
  const uint8_t *pe = data + size;
  const uint8_t *eof = pe;
  const uint8_t *disp = NULL;
  const uint8_t *imm = NULL;
  const uint8_t *imm2 = NULL;
  const uint8_t *begin;
  const uint8_t *begin_opcode;
  const uint8_t *end_opcode;
  enum disp_mode disp_type;
  enum imm_mode imm_operand;
  enum imm_mode imm2_operand;
  struct instruction instruction;
  int result = 0;

  int cs;

  %% write init;
  %% write exec;

error_detected:
  return result;
}

｣
