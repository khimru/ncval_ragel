# Copyright (c) 2011 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

divert(｢-1｣)
#################################################################################
# ｢instructions_defines｣ declares actions needed by the list of instructions.
# Format of the list is described in file general-purpose-instructions.def.
# For example: ｢instructions_defines(
#		 adc Ib Ev, 0x83 /2, lock
#		 adc G E, 0x10, lock
#		 add Ib Ev, 0x83 /0, lock
#		 add E G, 0x02, lock
#	       )｣
#     becomes:
#	       action instruction_adc { instruction_name = "adc"; }
#	       action instruction_adc { instruction_name = "add"; }
#################################################################################
  define(｢instructions_defines｣, ｢_instructions_defines(patsubst(｢$*｣,｢^#[^
]*
｣, ))｣)
  define(｢_instructions_defines｣, ｢instruction_define｣｢(｣｢patsubst(｢$*｣,｢
｣, ｢)instruction_define(｣)｣｢)｣)
#################################################################################
# ｢instructions_define｣ processes one instruction.  It keeps log of instructions
# already processed by ｢instructions_define｣ and calls ｢_instruction_name_action｣
# iff instruction with the same name was not already processed.
# Note: ｢instructions.m4｣ does not define ｢_instruction_name_action｣ - you must
# declare it before including ｢instructions.m4｣.
#################################################################################
  define(｢instruction_define｣, ｢ifelse(｢$1｣, , ,
    ｢instruction_name_action(split_argument($1))｣)｣)
  define(｢instruction_name_action｣,｢ifdef(｢instruction_$1｣,｢｣,
    ｢_instruction_name_action(｢$1｣)
  define(｢instruction_$1｣, )｣)｢｣｣)
#################################################################################
# ｢instructions｣ declares ragel description the instructions in question.
# Format of the list is described in file general-purpose-instructions.def.
# See below for ｢instruction｣ descripotion for further details.
#################################################################################
  define(｢instructions｣, ｢_instructions(patsubst(｢$*｣,｢^#[^
]*
｣, ))｣)
  define(｢_instructions｣, ｢instruction｣｢(｣｢patsubst(｢$*｣,｢
｣, ｢)｢｣instruction(｣)｣｢)｣)
#################################################################################
# For example: ｢instructions(adc Ib Ev, 0x83 /2, lock)｣
#     becomes:
#	       ｢((( data16 )) rex_xb? (0x83) >begin_opcode
#		  (( opcode_2 @end_opcode) @instruction_adc @operands_count_is_2
#		  @operand0_16bit @operand1_8bit @operand1_immediate any* &
#		  ( modrm_registers @operand0_from_modrm_rm  | (modrm_memory &
#		  (any @operand0_rm  any*)) )) imm8) |
#		((( data16 lock ) | ( lock data16 )) rex_xb? (0x83) >begin_opcode
#		  (( opcode_2 @end_opcode) @instruction_adc @operands_count_is_2
#		  @operand0_16bit  @operand0_16bit @operand1_8bit
#		  @operand1_immediate any* & ( (modrm_memory & (any @operand0_rm
#		  any*)) )) imm8)   |
#		( rex_xb? (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2 @operand0_32bit
#		  @operand1_8bit @operand1_immediate any* & ( modrm_registers
#		  @operand0_from_modrm_rm  | (modrm_memory & (any @operand0_rm
#		  any*)) )) imm8) |
#		((( lock )) rex_xb? (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2  @operand0_32bit
#		  @operand0_32bit @operand1_8bit @operand1_immediate any* &
#		  ( (modrm_memory & (any @operand0_rm  any*)) )) imm8)   |
#		( REXW_XB (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2 @operand0_64bit
#		  @operand1_8bit @operand1_immediate any* & ( modrm_registers
#		  @operand0_from_modrm_rm  | (modrm_memory & (any @operand0_rm
#		  any*)) )) imm8) |
#		((( lock )) REXW_XB (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2  @operand0_64bit
#		  @operand0_64bit @operand1_8bit @operand1_immediate any* &
#		  ( (modrm_memory & (any @operand0_rm  any*)) )) imm8)｣
# Note: the very first call produces the result above subsequent calls will add
# “|” character before the description.
#################################################################################
  define(｢instruction｣, ｢ifelse(｢$1｣, , ,
    ｢instruction_select(possible_command_modes(shift(split_argument($1))),
		       possible_rex_rxb_bits(shift(split_argument($1))), $@)｣)｣)
#################################################################################
# ｢possible_command_modes｣ determines list of possible modes for the list of
# arguments.  Most arguments just return ｢nodataprefix｣ which means that command
# has only one variant.  But some combinations produce different results.
# For example: ｢possible_command_modes(G, M)｣ becomes
#	       ｢memonlysize8data16nodataprefixrexw｣
# This means: command will require modrm byte with only memory operands allowed
# (this is ｢memonly｣ part), and there are four variants of this instruction:
# ｢size8｣ (with unchanged opcode), version with ｢data16｣ prefix (｢data16｣ part,
# version with no data prefix arguments (｢nodataprefix｣ part) and version with
# ｢REXW｣ prefix (｢rexw｣ part).
#################################################################################
  define(｢possible_command_modes｣, ｢ifelse($1, , ｢nodataprefix｣,
    ｢return_operand_mode(_possible_command_modes($@))｣)｣)
  define(｢_possible_command_modes｣,｢ifelse($#, 0, ｢unknown｣,
    $#, 1, ｢｢ifelse(
      substr($1, 0, 1), ｢M｣, ｢memonly｣,
      substr($1, 0, 1), ｢R｣, ｢regonly｣)｢｣possible_command_mode_｣substr($1,
	1)(substr($1, 0, 1))｣,
    ｢check_prefixes_compatibility(｢ifelse(
      substr($1, 0, 1), ｢M｣, ｢memonly｣,
      substr($1, 0, 1), ｢R｣, ｢regonly｣)｢｣possible_command_mode_｣substr($1, 1)(
	substr($1, 0, 1)), _possible_command_modes(shift($@)))｣)｣)
#################################################################################
# ｢return_operand_mode｣ is used by ｢possible_command_modes｣.  It contains the
# list of all possible modes and converts intermediate informations (for example
# ｢memonlyunknown｣) to the final value (for example ｢memonlynodataprefix｣).
# It only processes the first argument (if any).
#################################################################################
  define(｢return_operand_mode｣, ｢ifelse(
    ｢$#｣, 0, ｢nodataprefix｣,
    ｢$#｣, 1,
    ｢ifelse(
      $1, ｢unknown｣, ｢nodataprefix｣,
      $1, ｢nodataprefix｣, ｢nodataprefix｣,
      $1, ｢memonlyunknown｣, ｢memonlynodataprefix｣,
      $1, ｢memonlynodataprefix｣, ｢memonlynodataprefix｣,
      $1, ｢regonlyunknown｣, ｢regonlynodataprefix｣,
      $1, ｢regonlynodataprefix｣, ｢regonlynodataprefix｣,
      $1, ｢size8data16nodataprefixrexw｣, ｢size8data16nodataprefixrexw｣,
      $1, ｢data16｣, ｢data16｣,
      $1, ｢data16nodataprefixrexw｣, ｢data16nodataprefixrexw｣,
      $1, ｢nodataprefixrexw｣, ｢nodataprefixrexw｣,
      $1, ｢rexw｣, ｢rexw｣,
      $1, ｢memonlysize8data16nodataprefixrexw｣,
					    ｢memonlysize8data16nodataprefixrexw｣,
      $1, ｢memonlydata16｣, ｢memonlydata16｣,
      $1, ｢memonlydata16nodataprefixrexw｣, ｢memonlydata16nodataprefixrexw｣,
      $1, ｢memonlynodataprefixrexw｣, ｢memonlynodataprefixrexw｣,
      $1, ｢memonlyrexw｣, ｢memonlyrexw｣,
      $1, ｢regonlysize8data16nodataprefixrexw｣,
					    ｢regonlysize8data16nodataprefixrexw｣,
      $1, ｢regonlydata16｣, ｢regonlydata16｣,
      $1, ｢regonlydata16nodataprefixrexw｣, ｢regonlydata16nodataprefixrexw｣,
      $1, ｢regonlynodataprefixrexw｣, ｢regonlynodataprefixrexw｣,
      $1, ｢regonlyrexw｣, ｢regonlyrexw｣,
      ｢fatal_error(｢Incorrect operand mode:｣ $1)｣)｣,
    ｢fatal_error(｢More the one mode:｣ $@)｣)｣)
#################################################################################
# ｢check_prefixes_compatibility｣ accepts the list of possible modes for the
# operands and returns combined list or aborts the M4 if they are not compatible.
#################################################################################
  define(｢check_prefixes_compatibility｣, ｢ifelse(
    $1, $2, $2,
    $1, ｢unknown｣, $2,
    $2, ｢unknown｣, $1,
    $1, ｢memonly｣$2, $1,
    $2, ｢memonly｣$1, $2,
    $1, ｢regonly｣$2, $1,
    $2, ｢regonly｣$1, $2,
    $1, ｢memonly｣, ｢memonly｣$2,
    $2, ｢memonly｣, ｢memonly｣$1,
    $1, ｢regonly｣, ｢regonly｣$2,
    $2, ｢regonly｣, ｢regonly｣$1,
    $1, ｢memonlyunknown｣, ｢memonly｣$2,
    $2, ｢memonlyunknown｣, ｢memonly｣$1,
    $1, ｢regonlyunknown｣, ｢regonly｣$2,
    $2, ｢regonlyunknown｣, ｢regonly｣$1,
    $1 $2, ｢nodataprefixrexw size8data16nodataprefixrexw｣,
						   ｢size8data16nodataprefixrexw｣,
    $2 $1, ｢nodataprefixrexw size8data16nodataprefixrexw｣,
						   ｢size8data16nodataprefixrexw｣,
    ｢fatal_error(｢Incompatible prefixes｣ $1 ｢and｣ $2)｣)｣)
#################################################################################
# ｢possible_command_mode_“second part of the operand symbol”(“first part of the
# operand symbol”)｣ returns size mode for the given operand symbol.
# Note: ｢regonly｣ and ｢memonly｣ addons are handled elsewhere to avoid logic
# duplication.
#################################################################################
  # Operand sizes mostly follow AMD manual.
  # ｢unknown｣ means ther operands will determine.
  define(｢possible_command_mode_1｣,｢unknown｣)
  define(｢possible_command_mode_b｣,｢unknown｣)
  define(｢possible_command_mode_d｣,｢unknown｣)
  define(｢possible_command_mode_o｣,｢unknown｣)
  define(｢possible_command_mode_p｣,｢unknown｣)
  define(｢possible_command_mode_q｣,｢unknown｣)
  define(｢possible_command_mode_r｣,｢unknown｣)
  define(｢possible_command_mode_s｣,｢unknown｣)
  define(｢possible_command_mode_v｣,｢data16nodataprefixrexw｣)
  define(｢possible_command_mode_w｣,｢unknown｣)
  define(｢possible_command_mode_y｣,｢nodataprefixrexw｣)
  define(｢possible_command_mode_z｣,｢data16nodataprefixrexw｣)
  # ｢size8｣ is special "prefix" not included in AMD manual:  w bit in opcode
  # switches between 8bit and 16/32/64 bit versions.  M is just an address in
  # memory: it means register-only encodings are invalid, but other operands
  # decide everything else.
  define(｢possible_command_mode_｣, ｢size8data16nodataprefixrexw｣)
#################################################################################
# ｢possible_rex_rxb_bits｣ return possible REX prefix bits for the operands.
# Note: for ModRM.rm operands we always allow both ｢X｣ and ｢B｣ bits.
#################################################################################
  define(｢possible_rex_rxb_bits｣, ｢check_rex_rxb_bits(｢ifelse(｢$1｣, , ,
    ｢ifelse(
      unquote(｢possible_rex_rxb_bits_｣substr(｢$1｣, 0, 1)(substr(｢$1｣, 1))),
      ｢possible_rex_rxb_bits_｣substr(｢$1｣, 0, 1)(substr(｢$1｣, 1)),
      ｢fatal_error(｢Can not determine rex type:｣ $1)｣,
      ｢possible_rex_rxb_bits_｣substr(｢$1｣, 0, 1)(substr(｢$1｣,
      1)))｢｣possible_rex_rxb_bits(shift($@))｣)｣)｣)
  define(｢possible_rex_rxb_bits_1｣, )
  define(｢possible_rex_rxb_bits_a｣, )
  define(｢possible_rex_rxb_bits_b｣, )
  define(｢possible_rex_rxb_bits_c｣, )
  define(｢possible_rex_rxb_bits_d｣, )
  define(｢possible_rex_rxb_bits_i｣, )
  define(｢possible_rex_rxb_bits_o｣, )
  define(｢possible_rex_rxb_bits_p｣, )
  define(｢possible_rex_rxb_bits_r｣, ｢b｣)
  define(｢possible_rex_rxb_bits_E｣, ｢xb｣)
  define(｢possible_rex_rxb_bits_G｣, ｢r｣)
  define(｢possible_rex_rxb_bits_I｣, )
  define(｢possible_rex_rxb_bits_J｣, )
  define(｢possible_rex_rxb_bits_M｣, ｢xb｣)
  define(｢possible_rex_rxb_bits_O｣, )
  define(｢possible_rex_rxb_bits_P｣, )
  define(｢possible_rex_rxb_bits_R｣, ｢b｣)
  define(｢possible_rex_rxb_bits_S｣, )
  define(｢possible_rex_rxb_bits_V｣, ｢r｣)
  define(｢possible_rex_rxb_bits_X｣, )
  define(｢possible_rex_rxb_bits_Y｣, )
  define(｢check_rex_rxb_bits｣, ｢ifelse($1, , ,
    $1, ｢b｣, ｢b｣,
    $1, ｢r｣, ｢r｣,
    $1, ｢rxb｣, ｢rxb｣,
    $1, ｢xb｣, ｢xb｣,
    $1, ｢xbr｣, ｢rxb｣,
    ｢fatal_error(｢Incorrect rex type:｣ $1)｣)｣)
#################################################################################
# ｢instruction_select｣ is the main part of the ｢instruction｣ processing.
# It receives five operands: three from command description and two obtained from
# the list of operands.
# For example: ｢instructions(adc Ib Ev, 0x83 /2, lock)｣ becomes
#	       ｢instruction_select(｢data16nodataprefixrexw｣, ｢xb｣, ｢adc Ib Ev｣,
#					    ｢0x83 /2｣, ｢lock｣) which then becomes
#	       ｢((( data16 )) rex_xb? (0x83) >begin_opcode
#		  (( opcode_2 @end_opcode) @instruction_adc @operands_count_is_2
#		  @operand0_16bit @operand1_8bit @operand1_immediate any* &
#		  ( modrm_registers @operand0_from_modrm_rm  | (modrm_memory &
#		 (any @operand0_rm  any*)) )) imm8) |
#		((( data16 lock ) | ( lock data16 )) rex_xb? (0x83) >begin_opcode
#		  (( opcode_2 @end_opcode) @instruction_adc @operands_count_is_2
#		  @operand0_16bit  @operand0_16bit @operand1_8bit
#		  @operand1_immediate any* & ( (modrm_memory & (any @operand0_rm
#		  any*)) )) imm8)   |
#		( rex_xb? (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2 @operand0_32bit
#		  @operand1_8bit @operand1_immediate any* & ( modrm_registers
#		  @operand0_from_modrm_rm  | (modrm_memory & (any @operand0_rm
#		  any*)) )) imm8) |
#		((( lock )) rex_xb? (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2  @operand0_32bit
#		  @operand0_32bit @operand1_8bit @operand1_immediate any* &
#		  ( (modrm_memory & (any @operand0_rm  any*)) )) imm8)   |
#		( REXW_XB (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2 @operand0_64bit
#		  @operand1_8bit @operand1_immediate any* & ( modrm_registers
#		  @operand0_from_modrm_rm  | (modrm_memory & (any @operand0_rm
#		 any*)) )) imm8) |
#		((( lock )) REXW_XB (0x83) >begin_opcode (( opcode_2 @end_opcode)
#		  @instruction_adc @operands_count_is_2  @operand0_64bit
#		  @operand0_64bit @operand1_8bit @operand1_immediate any* &
#		  ( (modrm_memory & (any @operand0_rm  any*)) )) imm8)｣
# Note: we don't support “{mem,reg}only” and “lock” simultaneously.  IA32 and
# x86-64 never use them together.  “{mem,reg}only” without lock are “sgdt”,
# “lea”, etc while “lock” can only be ever used with the follwing instructions:
# “adc”, “add”, “and”, “btc”, “btr”, “bts”, “cmpxchg”, “cmpxchg{8,16}b”, “dec”,
# “inc", “neg”, “not”, “or”, “sbb”, “sub”, “xadd”, “xchg”, and “xor”.
# All these instructions are not in the “{mem,reg}only” group initially but they
# become “memonly” when combined with “lock” prefix.
#################################################################################
  define(｢instruction_select｣, ｢ifelse(
    substr(｢$4｣, 0, 5), ｢0x66 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0x66 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 7), ｢data16 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 7)), ｢data16 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢0xf2 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0xf2 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 6), ｢repnz ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 6)), ｢repnz $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢0xf3 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0xf3 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢repz ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢repz $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5)｢$1｣, ｢rexw regonlynodataprefix｣,
      ｢instruction_select(｢regonlyrexw｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)),
					       shift(shift(shift(shift($@)))))｣,
    substr(｢$4｣, 0, 5)｢$1｣, ｢rexw memonlynodataprefix｣,
      ｢instruction_select(｢memonlyrexw｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)),
					       shift(shift(shift(shift($@)))))｣,
    substr(｢$4｣, 0, 5)｢$1｣, ｢rexw nodataprefix｣,
      ｢instruction_select(｢rexw｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)),
					       shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢size8data16nodataprefixrexw｣,
      ｢instruction_select(｢size8｣, shift($@))｣  ｢instruction_select(
	   ｢data16nodataprefixrexw｣, $2, $3, setwflag($4),
					       shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢data16nodataprefixrexw｣,
      ｢instruction_select(｢data16｣, shift($@))｣  ｢instruction_select(
	   ｢nodataprefix｣, shift($@))｣  ｢instruction_select(｢rexw｣, shift($@))｣,
    ｢$1｣, ｢nodataprefixrexw｣,
      ｢instruction_select(
	   ｢nodataprefix｣, shift($@))｣  ｢instruction_select(｢rexw｣, shift($@))｣,
    ｢$1｣, ｢size8｣,
      ｢ifelse(index(｢$5｣, ｢lock｣), -1, 
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢size8｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢size8｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣minimum_one_required_prefix(｢lock｣,
	  ｢$5｣) REX_prefix_q(｢$2｣)instruction_body(
	  ｢memonlysize8｣, shift(shift($@)))｣)｣,
    ｢$1｣, ｢data16｣,
      ｢ifelse(index(｢$5｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣minimum_one_required_prefix(｢data16｣,
	  ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢data16｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣minimum_one_required_prefix(｢data16｣,
	  ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢data16｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣minimum_two_required_prefixes(｢data16｣,
	  ｢lock｣, ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢memonlydata16｣,
	  shift(shift($@)))｣)｣,
    ｢$1｣, ｢rexw｣, 
      ｢ifelse(index(｢$5｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢rexw｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢rexw｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣minimum_one_required_prefix(｢lock｣,
	  ｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢memonlyrexw｣,
	  shift(shift($@)))｣)｣,
    ｢$1｣, ｢nodataprefix｣,
      ｢ifelse(index(｢$5｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(｢$5｣) rex_prefix_q(
			｢$2｣)instruction_body(｢nodataprefix｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(｢$5｣) rex_prefix_q(
	  ｢$2｣)instruction_body(｢nodataprefix｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣minimum_one_required_prefix(｢lock｣,
	  ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢memonlynodataprefix｣,
	  shift(shift($@)))｣)｣,
    ｢$1｣, ｢memonlysize8data16nodataprefixrexw｣,
      ｢instruction_select(｢memonlysize8｣, shift($@))｣  ｢instruction_select(
	｢memonlydata16nodataprefixrexw｣, $2, $3, setwflag($4),
					       shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢memonlydata16nodataprefixrexw｣,
      ｢instruction_select(｢memonlydata16｣, shift($@))｣  ｢instruction_select(
	｢memonlynodataprefix｣, shift($@))｣  ｢instruction_select(｢memonlyrexw｣,
								    shift($@))｣,
    ｢$1｣, ｢memonlynodataprefixrexw｣,
      ｢instruction_select(｢memonlynodataprefix｣, shift(
			  $@))｣  ｢instruction_select(｢memonlyrexw｣, shift($@))｣,
    ｢$1｣, ｢memonlysize8｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢memonlysize8｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢memonlydata16｣,
      ｢instruction_separator｢｣｢(｣minimum_one_required_prefix(｢data16｣,
        ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(
					    ｢memonlydata16｣, shift(shift($@)))｣,
    ｢$1｣, ｢memonlyrexw｣, 
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢memonlyrexw｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢memonlynodataprefix｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢memonlynodataprefix｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢regonlysize8data16nodataprefixrexw｣,
      ｢instruction_select(｢regonlysize8｣, shift($@))｣  ｢instruction_select(
	｢regonlydata16nodataprefixrexw｣, $2, $3, setwflag($4),
					       shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢regonlydata16nodataprefixrexw｣,
      ｢instruction_select(｢regonlydata16｣, shift($@))｣  ｢instruction_select(
	｢regonlynodataprefix｣, shift($@))｣  ｢instruction_select(｢regonlyrexw｣,
								    shift($@))｣,
    ｢$1｣, ｢regonlynodataprefixrexw｣,
      ｢instruction_select(｢regonlynodataprefix｣, shift(
			  $@))｣  ｢instruction_select(｢regonlyrexw｣, shift($@))｣,
    ｢$1｣, ｢regonlysize8｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢regonlysize8｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢regonlydata16｣,
      ｢instruction_separator｢｣｢(｣minimum_one_required_prefix(｢data16｣,
	｢$5｣) rex_prefix_q(｢$2｣)instruction_body(
					    ｢regonlydata16｣, shift(shift($@)))｣,
    ｢$1｣, ｢regonlyrexw｣, 
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢regonlyrexw｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢regonlynodataprefix｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢regonlynodataprefix｣,
							     shift(shift($@)))｣,
    ｢fatal_error(｢Incorrect operand mode:｣ $1)｣)｣)
#################################################################################
# ｢possible_optional_prefixes｣ creates list of permutations of optional prefixes.
# Note: there are some truly optional prefixes (for example ｢condrep｣ means that
# command can optionally accept “repnz” or “repz” prefixes) but first prefixes
# can be required one (it's prefix moved by ｢instruction_select｣ from opcode to
# instruction note).  If that happens then ｢possible_optional_prefixes｣ will
# always include such prefix.
# For example: ｢possible_optional_prefixes(｢rep｣)｣ becomes
#	       ｢(( rep ))?｣
# But:	       ｢possible_optional_prefixes(｢0xf2 segprefix｣)｣  becomes
#	       ｢(( 0xf2 ) |
#		 ( 0xf2 segcs|segds|seges|segfs|seggs|segss ) |
#		 ( segcs|segds|seges|segfs|seggs|segss 0xf2 ))｣
#################################################################################
  define(｢possible_optional_prefixes｣, ｢ifelse(
    substr(｢$1｣, 0, 5), ｢0x66 ｣,
			 ｢one_required_prefix(｢0x66｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 7), ｢data16 ｣,
		       ｢one_required_prefix(｢data16｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 5), ｢0xf2 ｣,
			 ｢one_required_prefix(｢0xf2｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 6), ｢repnz ｣,
			｢one_required_prefix(｢repnz｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 5), ｢0xf3 ｣,
			 ｢one_required_prefix(｢0xf3｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 5), ｢repz ｣,
			 ｢one_required_prefix(｢repz｣, optional_prefixes(｢$1｣))｣,
    possible_prefixes(optional_prefixes(｢$1｣)), , ,
    ｢possible_prefixes(optional_prefixes(｢$1｣))?｣)｣)
#################################################################################
# ｢minimum_one_required_prefix｣ is similar to ｢possible_optional_prefixes｣ but it
# accepts two argumetns: first argument is prefix which must always be present
# and second argument is like in ｢possible_optional_prefixes｣
#################################################################################
  define(｢minimum_one_required_prefix｣, ｢ifelse(
    substr(｢$2｣, 0, 5), ｢0x66 ｣,
		 ｢two_required_prefixes(｢$1｣, ｢0x66｣, optional_prefixes(｢$2｣))｣,
    substr(｢$2｣, 0, 7), ｢data16 ｣,
	       ｢two_required_prefixes(｢$1｣, ｢data16｣, optional_prefixes(｢$2｣))｣,
    substr(｢$2｣, 0, 5), ｢0xf2 ｣,
		 ｢two_required_prefixes(｢$1｣, ｢0xf2｣, optional_prefixes(｢$2｣))｣,
    substr(｢$2｣, 0, 6), ｢repnz ｣,
		｢two_required_prefixes(｢$1｣, ｢repnz｣, optional_prefixes(｢$2｣))｣,
    substr(｢$2｣, 0, 5), ｢0xf3 ｣,
		 ｢two_required_prefixes(｢$1｣, ｢0xf3｣, optional_prefixes(｢$2｣))｣,
    substr(｢$2｣, 0, 5), ｢repz ｣,
		 ｢two_required_prefixes(｢$1｣, ｢repz｣, optional_prefixes(｢$2｣))｣,
    ｢one_required_prefix(｢$1｣, optional_prefixes(｢$2｣))｣)｣)
#################################################################################
# ｢minimum_two_required_prefixes｣ is similar to ｢possible_optional_prefixes｣ but
# it accepts three argumetns: first and second arguments are prefixes which must
# always be present and third argument is like in ｢possible_optional_prefixes｣
#################################################################################
  define(｢minimum_two_required_prefixes｣, ｢ifelse(
    substr(｢$3｣, 0, 5), ｢0x66 ｣,
         ｢three_required_prefixes(｢$1｣, ｢$2｣, ｢0x66｣, optional_prefixes(｢$3｣))｣,
    substr(｢$3｣, 0, 7), ｢data16 ｣,
       ｢three_required_prefixes(｢$1｣, ｢$2｣, ｢data16｣, optional_prefixes(｢$3｣))｣,
    substr(｢$3｣, 0, 5), ｢0xf2 ｣,
	 ｢three_required_prefixes(｢$1｣, ｢$2｣, ｢0xf2｣, optional_prefixes(｢$3｣))｣,
    substr(｢$3｣, 0, 6), ｢repnz ｣,
	｢three_required_prefixes(｢$1｣, ｢$2｣, ｢repnz｣, optional_prefixes(｢$3｣))｣,
    substr(｢$3｣, 0, 5), ｢0xf3 ｣,
	 ｢three_required_prefixes(｢$1｣, ｢$2｣, ｢0xf3｣, optional_prefixes(｢$3｣))｣,
    substr(｢$3｣, 0, 5), ｢repz ｣,
	 ｢three_required_prefixes(｢$1｣, ｢$2｣, ｢repz｣, optional_prefixes(｢$3｣))｣,
    ｢two_required_prefixes(｢$1｣, ｢$2｣, optional_prefixes(｢$3｣))｣)｣)
#################################################################################
# ｢optional_prefixes｣ parses third column of instruction description (see details
# in general-purpose-instructions.def) and pulls possible optional prefixes from
# it.
# For example: ｢optional_prefixes(｢rep segprefix 3DNow｣)｣ becomes
#	       ｢rep, segcs|segds|seges|segfs|seggs|segss,｣
# Note: ｢possible_prefixes｣ ignores empty arguments so this is effectively only
# two arguments.
#################################################################################
  define(｢optional_prefixes｣, ｢_optional_prefixes(split_argument($1))｣)
  define(｢_optional_prefixes｣, ｢ifelse(｢$#｣, 0, , ｢$#｣｢$1｣, 1, ,
    ｢$1｣, ｢condrep｣, ｢condrep, ｣,
    ｢$1｣, ｢segprefix｣, ｢segcs|segds|seges|segfs|seggs|segss, ｣,
    ｢$1｣, ｢rep｣, ｢rep, ｣)ifelse(eval(｢$#>1｣), 1,
    ｢_optional_prefixes(shift($@))｣)｣)
#################################################################################
# ｢rex_prefix_q｣, ｢REX_prefix_q｣, and ｢REXW_prefix｣ create proper one of three
# possible “rex” prefixes:
#   “rex?” : optional and allows “pure rex” one (rex prefix without any bits set
#            to switch between “%{a,b,c,d}h” and “%{bpl,spl,sil,dil}”.
#   “REX?” : optional and does not allow “pure rex” (because it's pointless).
#   “REXW” : required because it should carry at least “W” bit.
# For example: ｢REX_prefix_q(｢rx｣)｣ becomes ｢REX_RX?｣.
#################################################################################
  define(｢rex_prefix_q｣, ｢ifelse($1, , , ｢｢rex_$1?｣ ｣)｣)
  define(｢REX_prefix_q｣, ｢ifelse($1, , , ｢｢REX_｣translit($1, ｢a-z｣, ｢A-Z｣)? ｣)｣)
  define(｢REXW_prefix｣,
	     ｢ifelse($1, , ｢REXW_NONE ｣, ｢｢REXW_｣translit($1, ｢a-z｣, ｢A-Z｣) ｣)｣)
#################################################################################
# ｢instruction_separator｣ becomes either ｢｣ (i.e.: nothing) if it's called for
# the first time or ｢ |  ｣ for all subsequent calls.
# Note: you can “reset” by defining “_instruction_separator” as an empty macro.
#################################################################################
  define(｢instruction_separator｣, ｢_instruction_separator｢｣popdef(
    ｢_instruction_separator｣)｢｣pushdef(｢_instruction_separator｣, ｢ |
    ｣)｣)
  define(｢_instruction_separator｣, )
#################################################################################
# ｢setwflag｣ sets the “w” (word) flag in opcode (see Intel manual for info).
# Note: don't mix “w” (word) flag in opcode and “W” (wide) flag in REX - these
# are different flags!
# For example: ｢setwflag(0x80 /0)｣ becomes ｢0x81 /0｣
#	       ｢setwflag(0x80 /0)｣ becomes ｢0x0f 0xb1｣
#################################################################################
  define(｢setwflag｣, ｢_setwflag(split_argument(｢$1｣))｣)
  define(｢_setwflag｣, ｢ifelse(
    ｢$2｣, , format(｢0x%02x｣, eval(｢$1 + 1｣)),
    index(｢$2｣, ｢/｣), -1, ｢$1 _setwflag(shift($@))｣,
    ｢format(｢0x%02x｣, eval(｢$1 + 1｣)) $2｣)｣)
#################################################################################
# ｢instruction_body｣ is simple, linear part of ｢instruction｣ processing.
# It does bulk of work, but at this stage we have selected one particular set
# of prefixes and have determined if we are processing “regonly” operands,
# “memonly” operands or both.  First argument is instruction mode, other three
# operands come unmodified from ｢instruction｣ expansion.
# For example: ｢instruction_body(｢data16｣, ｢adc Ib Ev｣, ｢0x83 /2｣, ｢lock｣)｣
#     becomes: ｢(0x83) >begin_opcode (( opcode_2 @end_opcode) @instruction_adc
#		  @operands_count_is_2 @operand0_16bit @operand1_8bit
#		  @operand1_immediate any* & ( modrm_registers
#		  @operand0_from_modrm_rm  | (modrm_memory & (any @operand0_rm
#		  any*)) )) imm8)｣
#################################################################################
  define(｢instruction_body｣, ｢opcode_nomodrm(｢$1｣, ｢$4｣, ｢$3｣,
    split_argument(｢$2｣))｢｣instruction_modrm_arguments(
    $@)｢｣instruction_immediate_arguments(｢$1｣, shift(split_argument(｢$2｣))))｣)
#################################################################################
# ｢opcode_nomodrm｣ processes mail part of instruction opcode (without “ModRM” and
# “SIB” bytes, displacement, immediates, etc).  If the instruction does not
# include “/0”, “/1”, …, “/7” “bytes” then it does most of the ｢instruction_body｣
# work, if such byte is present then it postpones bulk of work till after the
# first byte of “ModRM” is parsed.  First operand is “instruction mode”, second
# one is “additional instruction notes”, third one is “opcode” and the rest are
# instruction and it's operands.
# For example: ｢opcode_nomodrm(｢data16｣, ｢lock｣, ｢0x83 /2｣, ｢adc｣, ｢Ib｣, ｢Ev｣)｣
#     becomes: ｢(0x83) >begin_opcode｣
# Another example: ｢opcode_nomodrm(｢data16｣, ｢lock｣, ｢0x11｣, ｢adc｣, ｢G｣, ｢E｣)｣
#	  becomes: ｢(0x11) >begin_opcode @end_opcode @instruction_adc
#		     @operands_count_is_2 @operand0_16bit @operand1_16bit｣
#################################################################################
  define(｢opcode_nomodrm｣,
    ｢ifelse(regexp(｢$3｣, ｢\(.*\)/[0-7s]\(.*\)｣, ｢\1\2｣), ,
      ｢__opcode_nomodrm(｢$1｣, ｢$2｣, _opcode_nomodrm(shift(shift($@))),
						      shift(shift(shift($@))))｣,
      ｢___opcode_nomodrm(｢$1｣, ｢$4｣, regexp($3, ｢\(.*\)/[0-7s]\(.*\)｣, ｢\1\2｣),
						    shift(shift(shift($@))))｣)｣)
  define(｢_opcode_nomodrm｣, ｢ifelse(｢$3｣, , ｢$1｣,
    ｢ifelse(substr(｢$3｣, 0, 1), ｢r｣, regopcode(｢$1｣),
    ｢_opcode_nomodrm(｢$1｣, ｢$2｣, shift(shift(shift($@))))｣)｣)｣)
  define(｢__opcode_nomodrm｣,
    ｢begin_opcode((trim(｢$3｣))) end_opcode(｢$4｣) ifelse(
      substr(｢$2｣, 0, 5), ｢0x66 ｣, ｢not_data16 ｣,
      substr(｢$2｣, 0, 5), ｢0xf2 ｣, ｢not_repnz ｣,
      substr(｢$2｣, 0, 5), ｢0xf3 ｣, ｢not_repz ｣,
    )instruction_name(
    ｢$4｣)｢｣instruction_arguments_number(shift(shift(shift(shift(
    $@)))))｢｣instruction_arguments_sizes(｢$1｣, shift(shift(shift(shift(
    $@)))))｢｣instruction_implied_arguments(｢$1｣, shift(shift(shift(shift(
    $@)))))｣)
  define(｢___opcode_nomodrm｣, ｢begin_opcode((trim(｢$3｣)))｣)
#################################################################################
# ｢instruction_name｣ is inserted where we know the name of the instruction and
# are ready to insert appropriate ragel action.  It's raison d'être is to make
# this logic overridable.
# For example: ｢instruction_name(｢adc｣)｣ becomes ｢@instruction_adc｣
#################################################################################
  define(｢instruction_name｣, ｢@｢instruction_｣clean_name($1)｣)
#################################################################################
# ｢clean_name｣ is simple helper function.  It replaces symbols which can be found
# in the instruction name but not in a C identifier with “_”.  We don't use any
# mangling schemes: collisions will be found by C compiler and are pretty easy to
# fix.
# For example: ｢clean_name(｢pop %es｣)｣ becomes ｢pop__%es｣
#################################################################################
  define(｢clean_name｣, ｢translit(｢$1｣, ｢ ()[]{}%:｣, ｢_________｣)｣)
#################################################################################
# ｢regopcode｣ expands “register opcode”, i.e. opcode which encodes register in
# the bottom three bytes of opcode.
# For example: ｢regopcode(｢0x0f 0xc8｣)｣
#     becomes: ｢0x0f (0xc8|0xc9|0xca|0xcb|0xcc|0xcd|0xce|0xcf)｣
# Note: it never produces opcode ｢0x90｣.  x86-64 makes opcode ｢0x90｣ true “nop”
# while before it was really “xchg %eax,%eax” so we should not ever decode it as
# an xchg.
#################################################################################
  define(｢regopcode｣, ｢_regopcode(split_argument(｢$1｣))｣)
  define(｢_regopcode｣, ｢ifelse($#, 1,
    ｢chartest(｢(｢c｣ != 0x90) && ((｢c｣ & 0xf8) == ｢$1｣)｣)｣,
    ｢$1 __regopcode(shift($@))｣)｣)
  define(｢__regopcode｣, ｢ifelse($#, 1,
    ｢chartest(｢(｢c｣ & 0xf8) == ｢$1｣｣)｣,
    ｢$1 __regopcode(shift($@))｣)｣)
#################################################################################
# ｢instruction_arguments_number｣ is inserted where we know the number of
# arguments of the instruction and are ready to insert appropriate ragel action.
# It receives all these arguments, but usually only uses their number ($#).
# For example: ｢instruction_arguments_number(｢Ib｣, ｢Ev｣)｣
#     becomes: ｢ @operands_count_is_2｣
# Note: for zero-argument instruction it's called with one empty argument.
#################################################################################
  define(｢instruction_arguments_number｣,
    ｢ifelse(｢$1｣, , ｢ operands_count_is_0｣, ｢ operands_count_is_$#｣)｣)
#################################################################################
# ｢instruction_arguments_sizes｣ is inserted where we know all the arguments and
# are ready to insert appropriate ragel action.
# It receives “instruction mode” and all the arguments in question.
# For example: ｢instruction_arguments_sizes(｢data16｣, ｢Ib｣, ｢Ev｣)｣
#     becomes: ｢@operand0_16bit @operand1_8bit｣
#################################################################################
  define(｢instruction_arguments_sizes｣, ｢ifelse(eval(｢$#>2｣), 1,
    ｢instruction_arguments_sizes(｢$1｣, shift(shift($@)))｣) ifelse(
      ｢$2｣, , ,
      substr(｢$1｣, 0, 7), ｢memonly｣,
		      ｢instruction_arguments_sizes(substr(｢$1｣, 7), shift($@))｣,
      substr(｢$1｣, 0, 7), ｢regonly｣,
		      ｢instruction_arguments_sizes(substr(｢$1｣, 7), shift($@))｣,
	｢unquote(｢operand｣decr(decr(｢$#｣))｢_｣ifelse(len(｢$2｣), 1,
	  ｢ifelse(
	    instruction_argument_size_$1_$2,
	    ｢instruction_argument_size_$1_$2｣,
	    ｢ifelse(
	      instruction_argument_size_$1,
	      ｢instruction_argument_size_$1｣,
	      ｢fatal_error(｢Can not determine argument size:｣ $1 $2)｣,
	      instruction_argument_size_$1)｣,
	    instruction_argument_size_$1_$2)｣,
	  ｢ifelse(
	    instruction_argument_size_$1_$2,
	    ｢instruction_argument_size_$1_$2｣,
	    ｢ifelse(
	      unquote(｢instruction_argument_size_$1_｣substr($2, 1)),
	      ｢instruction_argument_size_$1_｣substr($2, 1),
	      ｢ifelse(
		unquote(｢instruction_argument_size_｣substr($2, 1)),
		｢instruction_argument_size_｣substr($2, 1),
		｢fatal_error(｢Can not determine argument size:｣ $1 $2)｣,
		｢instruction_argument_size_｣substr($2, 1))｣,
	      ｢instruction_argument_size_$1_｣substr($2, 1))｣,
	    instruction_argument_size_$1_$2)｣))｣)｣)
  define(｢instruction_argument_size_size8｣, ｢8bit｣)
  define(｢instruction_argument_size_data16｣, ｢16bit｣)
  define(｢instruction_argument_size_nodataprefix｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw｣, ｢64bit｣)
  define(｢instruction_argument_size_rexw_I｣, ｢32bit｣)
  define(｢instruction_argument_size_b｣, ｢8bit｣)
  define(｢instruction_argument_size_d｣, ｢32bit｣)
  define(｢instruction_argument_size_nodataprefix_Pq｣, ｢mmx｣)
  define(｢instruction_argument_size_rexw_Pq｣, ｢mmx｣)
  define(｢instruction_argument_size_nodataprefix_Vq｣, ｢xmm｣)
  define(｢instruction_argument_size_rexw_Vq｣, ｢xmm｣)
  define(｢instruction_argument_size_q｣, ｢64bit｣)
  define(｢instruction_argument_size_p｣, ｢farptr｣)
  define(｢instruction_argument_size_o｣, ｢128bit｣)
  define(｢instruction_argument_size_r｣, ｢64bit｣)
  define(｢instruction_argument_size_s｣, ｢selector｣)
  define(｢instruction_argument_size_data16_v｣, ｢16bit｣)
  define(｢instruction_argument_size_nodataprefix_v｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_v｣, ｢64bit｣)
  define(｢instruction_argument_size_data16_Sw｣, ｢segreg｣)
  define(｢instruction_argument_size_nodataprefix_Sw｣, ｢segreg｣)
  define(｢instruction_argument_size_rexw_Sw｣, ｢segreg｣)
  define(｢instruction_argument_size_w｣, ｢16bit｣)
  define(｢instruction_argument_size_size8_y｣, ｢32bit｣)
  define(｢instruction_argument_size_data16_y｣, ｢32bit｣)
  define(｢instruction_argument_size_nodataprefix_y｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_y｣, ｢64bit｣)
  define(｢instruction_argument_size_data16_z｣, ｢16bit｣)
  define(｢instruction_argument_size_nodataprefix_z｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_z｣, ｢32bit｣)
#################################################################################
# ｢instruction_implied_arguments｣ is inserted where we know all the arguments and
# are ready to insert appropriate ragel action.  It's used to generate “implied
# arguments”, i.e. arguments which are always affected by command but which are
# not encoded in command binary representation.
# It receives “instruction mode” and all the arguments in question.
# For example: ｢instruction_implied_arguments(｢data16｣, ｢I｣, ｢a｣)｣
#     becomes: ｢@operand0_rax @operand1_immediate｣
# Note: it does not process ｢E｣, ｢G｣, ｢J｣, ｢M｣, ｢P｣, ｢R｣, ｢V｣, and ｢S｣ arguments.
# ｢E｣, ｢G｣, ｢J｣, ｢M｣, ｢P｣, ｢R｣, ｢V｣, and ｢S｣ are “ModRM”-style arguments and thus
# are processed by ｢instruction_modrm_arguments｣ later, while ｢J｣ arguments are
# processed by ｢instruction_immediate_arguments｣ because that's where they can be
# found in the command encoding.
#################################################################################
  define(｢instruction_implied_arguments｣, ｢ifelse(eval(｢$#>2｣), 1,
    ｢instruction_implied_arguments(｢$1｣, shift(shift($@)))｣)｢｣ifelse(
      $2, , ,
      substr(｢$2｣, 0, 1), ｢1｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_one｣,
      substr(｢$2｣, 0, 1), ｢a｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_rax｣,
      substr(｢$2｣, 0, 1), ｢b｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_ds_rbx｣,
      substr(｢$2｣, 0, 1), ｢c｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_rcx｣,
      substr(｢$2｣, 0, 1), ｢d｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_rdx｣,
      substr(｢$2｣, 0, 1), ｢i｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_second_immediate｣,
      substr(｢$2｣, 0, 1), ｢o｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_port_dx｣,
      substr(｢$2｣, 0, 1), ｢r｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_from_opcode｣,
      substr(｢$2｣, 0, 1), ｢E｣, ,
      substr(｢$2｣, 0, 1), ｢G｣, ,
      substr(｢$2｣, 0, 1), ｢I｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_immediate｣,
      substr(｢$2｣, 0, 1), ｢J｣, ,
      substr(｢$2｣, 0, 1), ｢M｣, ,
      substr(｢$2｣, 0, 1), ｢P｣, ,
      substr(｢$2｣, 0, 1), ｢O｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_absolute_disp｣,
      substr(｢$2｣, 0, 1), ｢R｣, ,
      substr(｢$2｣, 0, 1), ｢V｣, ,
      substr(｢$2｣, 0, 1), ｢S｣, ,
      substr(｢$2｣, 0, 1), ｢X｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_ds_rsi｣,
      substr(｢$2｣, 0, 1), ｢Y｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_es_rdi｣,
      ｢fatal_error(｢Can not determine argument type:｣ $2)｣)｣)
#################################################################################
# ｢instruction_modrm_arguments｣ is inserted in the place where “ModRM” part of
# the instruction is expected.  If the instruction uses both “ModRM.reg” and
# “ModRM.rm” parts then here we just fill two operands, but if opcode includes
# “/0”, “/1”, …, or “/7” “byte” then we also need to determine other attributes
# of the instruction (which are usually processed by opcode_nomodrm).
# For example: ｢instruction_modrm_arguments(｢data16｣, ｢adc Ib Ev｣, ｢0x83 /2｣,
#									 ｢lock｣)｣
#     becomes: ｢ (( opcode_2 @end_opcode) @instruction_adc @operands_count_is_2
#		  @operand0_16bit @operand1_8bit @operand1_immediate any* &
#		  ( modrm_registers @operand0_from_modrm_rm  | (modrm_memory &
#		  (any @operand0_rm  any*)) ))｣
# Another example: ｢instruction_modrm_arguments(data16｣, ｢adc G E｣, ｢0x11｣
#									 ｢lock｣)｣
#	  becomes: ｢ ( modrm_registers @operand0_from_modrm_rm
#		      @operand1_from_modrm_reg | (modrm_memory &
#		      (any @operand0_rm @operand1_from_modrm_reg any*)))｣
#################################################################################
  define(｢instruction_modrm_arguments｣, ｢ifelse(index(｢$2｣, ｢ E｣), -1,
    ｢ifelse(index(｢$2｣, ｢ G｣), -1,
      ｢ifelse(index(｢$2｣, ｢ M｣), -1,
	｢ifelse(index(｢$2｣, ｢ P｣), -1,
	  ｢ifelse(index(｢$2｣, ｢ R｣), -1,
	    ｢ifelse(index(｢$2｣, ｢ S｣), -1,
	      ｢ifelse(index(｢$2｣, ｢ V｣), -1, ,
		｢ _instruction_modrm_arguments($@)｣)｣,
	      ｢ _instruction_modrm_arguments($@)｣)｣,
	    ｢ _instruction_modrm_arguments($@)｣)｣,
	  ｢ _instruction_modrm_arguments($@)｣)｣,
	｢ _instruction_modrm_arguments($@)｣)｣,
      ｢ _instruction_modrm_arguments($@)｣)｣,
    ｢ _instruction_modrm_arguments($@)｣)｣)
  define(｢_instruction_modrm_arguments｣, ｢ifelse(index(｢$3｣, ｢/｣), -1, ,
    ｢regexp(｢$3｣, ｢/\([0-7s]\)｣,
    ｢(( opcode_\1 end_opcode(split_argument(
      ｢$2｣))) ifelse(
      substr(｢$4｣, 0, 5), ｢0x66 ｣, ｢not_data16 ｣,
      substr(｢$4｣, 0, 5), ｢0xf2 ｣, ｢not_repnz ｣,
      substr(｢$4｣, 0, 5), ｢0xf3 ｣, ｢not_repz ｣,
    )instruction_name(split_argument(
      ｢$2｣))｢｣instruction_arguments_number(shift(split_argument(
      ｢$2｣)))｢｣instruction_arguments_sizes(｢$1｣, shift(split_argument(
      ｢$2｣)))｢｣instruction_implied_arguments(｢$1｣, shift(split_argument(
      ｢$2｣))) any* & ｣)｣)｢( ｣__instruction_modrm_arguments($@)｢｣ifelse(
    index(｢$3｣, ｢/｣), -1, , ｢ )｣)｢)｣｣)
  define(｢__instruction_modrm_arguments｣, ｢ifelse(
    substr(｢$1｣, 0, 7), ｢memonly｣,
		｢memory_instruction_modrm_arguments(shift(split_argument($2)))｣,
    substr(｢$1｣, 0, 7), ｢regonly｣,
	      ｢register_instruction_modrm_arguments(shift(split_argument($2)))｣,
    ｢register_instruction_modrm_arguments(shift(split_argument(
      $2))) | memory_instruction_modrm_arguments(shift(split_argument($2)))｣)｣)
#################################################################################
# ｢register_instruction_modrm_arguments｣ is used in ｢instruction_modrm_arguments｣
# in place where we've parsed the “ModRM” part of the register-to-register
# version of the instruction and need/want to pull names of registers from the
# “ModRM” byte.
# For example: ｢register_instruction_modrm_arguments(｢Ib｣, ｢Ev｣)｣
#     becomes: ｢modrm_registers @operand0_from_modrm_rm｣
# Another example: ｢register_instruction_modrm_arguments(｢G｣, ｢E｣)｣
#	  becomes: ｢modrm_registers @operand0_from_modrm_rm
#		      @operand1_from_modrm_reg｣
# Note: you can redefine ｢register_instruction_modrm_arguments｣ to unconditional
# ｢modrm_registers｣ value if you don't need to process arguments.
#################################################################################
  define(｢register_instruction_modrm_arguments｣,
    ｢modrm_registers _register_instruction_modrm_arguments($@)｣)
  define(｢_register_instruction_modrm_arguments｣, ｢ifelse(eval(｢$#>1｣), 1,
    ｢_register_instruction_modrm_arguments(shift($@)) ｣)｢｣ifelse(
      substr(｢$1｣, 0, 1), ｢E｣, ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, 0, 1), ｢G｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢M｣, ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, 0, 1), ｢P｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢R｣, ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, 0, 1), ｢S｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢V｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣)｣)
#################################################################################
# ｢memory_instruction_modrm_arguments｣ is used in ｢instruction_modrm_arguments｣
# in place where we've parsed the “ModRM” part of the register-to-memory or of
# the memory-to-register version of the instruction and need/want to pull names
# of registers from the “ModRM” byte.
# For example: ｢memory_instruction_modrm_arguments(｢Ib｣, ｢Ev｣)｣
#     becomes: ｢modrm_registers @operand0_from_modrm_rm｣
#     becomes: ｢(modrm_memory & (any @operand0_rm  any*))｣
# Another example: ｢memory_instruction_modrm_arguments(｢G｣, ｢E｣)｣
#	  becomes: ｢(modrm_memory & (any @operand0_rm @operand1_from_modrm_reg
#		     any*))｣
# Note: even if command only support memory operands we can start parsing them
# after first byte of the instruction is parsed, because another, unrelated
# instruction can share the same beginning.  Examples are x87 instructions, and
# such combinations as “sidt Ms”/“monitor”/“mwait”, etc.
# Note: you can redefine ｢memory_instruction_modrm_arguments｣ to unconditional
# ｢modrm_memory｣ value if you don't need to process arguments.
#################################################################################
  define(｢memory_instruction_modrm_arguments｣,
    ｢(modrm_memory & (any _memory_instruction_modrm_arguments($@) any*))｣)
  define(｢_memory_instruction_modrm_arguments｣, ｢ifelse(eval(｢$#>1｣), 1,
    ｢_memory_instruction_modrm_arguments(shift($@)) ｣)｢｣ifelse(
      substr(｢$1｣, 0, 1), ｢E｣, ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, 0, 1), ｢G｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢M｣, ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, 0, 1), ｢P｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢R｣, ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, 0, 1), ｢S｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢V｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣)｣)
#################################################################################
# ｢instruction_immediate_arguments｣ is placed in place where we have parsed
# everything except immedite... or offset in jmp/call... or part of the opcode
# for “3DNow!” instruction (this last part is not implemented but will also go
# here because “3DNow!” uses “immediate” byte at the end of the instructions as
# the final part of the opcode).  Here we only need to write one word (if even
# that) - but we receive all the arguments for the sake of uniformity.
# For example: ｢instruction_immediate_arguments(｢data16｣, ｢I｣, ｢a｣)｣
#     becomes: ｢imm16｣
# Another example: ｢instruction_immediate_arguments(｢rexw｣, ｢Jz｣)｣
#	  becomes: ｢rel32｣
# Last, trivial, example: ｢instruction_immediate_arguments(｢data16｣, ｢E｣, ｢G｣)｣
#		 becomes: ｢｣ (i.e.: nothing)
#################################################################################
  define(｢instruction_immediate_arguments｣, ｢ifelse(
      substr(｢$1｣, 0, 7), ｢memonly｣,
		  ｢instruction_immediate_arguments(substr(｢$1｣, 7), shift($@))｣,
      substr(｢$1｣, 0, 7), ｢regonly｣,
		  ｢instruction_immediate_arguments(substr(｢$1｣, 7), shift($@))｣,
      ｢ifelse(substr(｢$2｣, 0, 1), ｢i｣, ｢ifelse(len(｢$2｣), 1,
	  ｢ifelse(instruction_immediate_arguments_$1,
	    ｢instruction_immediate_arguments_$1｣,
	    ｢fatal_error(｢Can not determine immediate size:｣ $1)｣,
	    instruction_immediate_arguments_$1｢｢n2｣｣)｣,
	  ｢ifelse(
	    unquote(｢instruction_immediate_arguments_$1_｣substr($2, 1)),
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1),
	    ｢ifelse(
	      unquote(｢instruction_immediate_arguments_｣substr($2, 1)),
	      ｢instruction_immediate_arguments_｣substr($2, 1),
	      ｢fatal_error(｢Can not determine immediate size:｣ $1 $2)｣,
	      ｢instruction_immediate_arguments_｣substr($2, 1)｢｢n2｣｣)｣,
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1)｢｢n2｣｣)｣)｣,
	substr(｢$2｣, 0, 1), ｢I｣, ｢ifelse(len(｢$2｣), 1,
	  ｢ifelse(instruction_immediate_arguments_$1,
	    ｢instruction_immediate_arguments_$1｣,
	    ｢fatal_error(｢Can not determine immediate size:｣ $1)｣,
	    instruction_immediate_arguments_$1)｣,
	  ｢ifelse(
	    unquote(｢instruction_immediate_arguments_$1_｣substr($2, 1)),
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1),
	    ｢ifelse(
	      unquote(｢instruction_immediate_arguments_｣substr($2, 1)),
	      ｢instruction_immediate_arguments_｣substr($2, 1),
	      ｢fatal_error(｢Can not determine immediate size:｣ $1 $2)｣,
	      ｢instruction_immediate_arguments_｣substr($2, 1))｣,
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1))｣)｣,
	substr(｢$2｣, 0, 1), ｢J｣, ｢ifelse(len(｢$2｣), 1,
	  ｢ifelse(
	    instruction_jump_arguments_$1,
	    ｢instruction_jump_arguments_$1｣,
	    ｢fatal_error(｢Can not determine jump size:｣ $1)｣,
	    instruction_jump_arguments_$1)｣,
	  ｢ifelse(
	    unquote(｢instruction_jump_arguments_$1_｣substr($2, 1)),
	    ｢instruction_jump_arguments_$1_｣substr($2, 1),
	    ｢ifelse(
	      unquote(｢instruction_jump_arguments_｣substr($2, 1)),
	      ｢instruction_jump_arguments_｣substr($2, 1),
	      ｢fatal_error(｢Can not determine jump size:｣ $1 $2)｣,
	      ｢instruction_jump_arguments_｣substr($2, 1))｣,
	    ｢instruction_jump_arguments_$1_｣substr($2, 1))｣)｣,
	substr(｢$2｣, 0, 1), ｢O｣, ｢ disp64｣)｢｣ifelse(eval(｢$#>2｣), 1,
	｢instruction_immediate_arguments(｢$1｣, shift(shift($@)))｣)｣)｣)
  define(｢instruction_immediate_arguments_size8｣, ｢ imm8｣)
  define(｢instruction_immediate_arguments_data16｣, ｢ imm16｣)
  define(｢instruction_immediate_arguments_nodataprefix｣, ｢ imm32｣)
  define(｢instruction_immediate_arguments_rexw｣, ｢ imm32｣)
  define(｢instruction_immediate_arguments_size8_b｣, ｢ imm8｣)
  define(｢instruction_immediate_arguments_data16_b｣, ｢ imm8｣)
  define(｢instruction_immediate_arguments_nodataprefix_b｣, ｢ imm8｣)
  define(｢instruction_immediate_arguments_rexw_b｣, ｢ imm8｣)
  define(｢instruction_immediate_arguments_data16_v｣, ｢ imm16｣)
  define(｢instruction_immediate_arguments_nodataprefix_v｣, ｢ imm32｣)
  define(｢instruction_immediate_arguments_rexw_v｣, ｢ imm64｣)
  define(｢instruction_immediate_arguments_nodataprefix_w｣, ｢ imm16｣)
  define(｢instruction_immediate_arguments_data16_z｣, ｢ imm16｣)
  define(｢instruction_immediate_arguments_nodataprefix_z｣, ｢ imm32｣)
  define(｢instruction_immediate_arguments_rexw_z｣, ｢ imm32｣)
  define(｢instruction_jump_arguments_nodataprefix_b｣, ｢ rel8｣)
  define(｢instruction_jump_arguments_data16_z｣, ｢ rel16｣)
  define(｢instruction_jump_arguments_nodataprefix_z｣, ｢ rel32｣)
  define(｢instruction_jump_arguments_rexw_z｣, ｢ rel32｣)
#################################################################################
# Instructions parsing macrodefines are here.  Include customizations (if any).
#################################################################################
  ifelse(customize_instructions_parsing, ｢customize_instructions_parsing｣, ,
    customize_instructions_parsing);
divert｢｣dnl

  instructions_defines(include(｢general-purpose-instructions.def｣))
  instructions_defines(include(｢x86-64-instructions.def｣))
  instructions_defines(include(｢system-instructions.def｣))

  valid_instruction =
    instructions(include(｢general-purpose-instructions.def｣))
    instructions(include(｢system-instructions.def｣))
    instructions(include(｢x86-64-instructions.def｣));
