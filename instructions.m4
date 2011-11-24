  define(｢instructions_defines｣, ｢_instructions_defines(patsubst(｢$*｣,｢^#[^
]*
｣, ))｣)
  define(｢_instructions_defines｣, ｢instruction_define｣｢(｣｢patsubst(｢$*｣,｢
｣, ｢)instruction_define(｣)｣｢)｣)
  define(｢instruction_define｣, ｢ifelse(｢$1｣, , ,
    ｢instruction_name_action(split_argument($1))｣)｣)
  define(｢instructions｣, ｢_instructions(patsubst(｢$*｣,｢^#[^
]*
｣, ))｣)
  define(｢_instructions｣, ｢instruction｣｢(｣｢patsubst(｢$*｣,｢
｣, ｢)｢｣instruction(｣)｣｢)｣)
  define(｢instruction_name_action｣,｢ifdef(｢instruction_$1｣,｢｣,
    ｢_instruction_name_action(｢$1｣)
  define(｢instruction_$1｣, )｣)｢｣｣)
  define(｢instruction_name｣, ｢@｢instruction_$1｣｣)
  define(｢insttype_action｣,｢ifdef(｢insttype_$1｣,｢｣,
    ｢action insttype_｢｣$1 { ｢instruction_type｣ = ｢instruction_$1｣; }
    define(｢insttype_$1｣,)｣)｢｣｣)
  define(｢insttype｣,｢@insttype｢_｣$1｣)
  define(｢instruction｣, ｢ifelse(｢$1｣, , ,
    ｢instruction_select(possible_command_modes(
    shift(split_argument($1))), $@)｣)｣)
  define(｢possible_command_modes｣,
    ｢return_operand_modes(_possible_command_modes($@))｣)
  define(｢_possible_command_modes｣,｢ifelse($#,0,｢unknown｣,
    $#,1,｢｢possible_command_mode_｣substr($1,1)｣(substr($1,0,1)),
    ｢_check_prefixes_compatibility(｢possible_command_mode_｣substr($1,1)(
    substr($1,0,1)),_possible_command_modes(shift($@)))｣)｣)
  # Operand sizes mostly follow AMD manual.
  # ｢unknown｣ means ther operands will determine.
  define(｢possible_command_mode_a｣,｢data16｣)
  define(｢possible_command_mode_b｣,｢unknown｣)
  define(｢possible_command_mode_d｣,｢unknown｣)
  define(｢possible_command_mode_q｣,｢unknown｣) # Other operands will determine
  define(｢possible_command_mode_r｣,｢rexbreg｣)
  define(｢possible_command_mode_v｣,｢data16rexw｣)
  define(｢possible_command_mode_w｣,｢unknown｣)
  define(｢possible_command_mode_z｣,｢data16rexw｣)
  # This is special prefix not included in AMD manual: w bit selects between
  # 8bit and 16/32/64 bit versions
  define(｢possible_command_mode_｣,｢size8data16rexw｣)
  define(｢return_operand_modes｣, ｢ifelse(
    ｢$#｣, ｢0｣, ｢none｣,
    ｢$#｣, ｢1｣,
    ｢ifelse(
      $1,｢unknown｣,｢none｣,
      $1,｢none｣,
      $1,｢size8data16rexw｣,｢size8data16rexw｣,
      $1,｢data16｣,｢data16｣,
      $1,｢data16rexw｣,｢data16rexw｣,
      $1,｢rexw｣,｢rexw｣,
      $1,｢rexbreg｣,｢rexbreg｣,
      ｢fatal_error(Incorrect prefix sizeA)｣)｣,
    ｢$#｣, ｢2｣, ｢ifelse(
      $1,｢unknown｣,｢return_operand_modes(｢$2｣)｣,
      $2,｢unknown｣,｢return_operand_modes(｢$1｣)｣,
      $1,$2,｢return_operand_modes(｢$1｣)｣,
      ｢fatal_error(Incorrect prefix sizeB)｣)｣,
    ｢return_operand_modes(｢$1｣, return_operand_modes(shift($@)))｣)｣)
  define(｢_check_prefixes_compatibility｣,｢ifelse(
    ｢unknown｣,$1,｢$2｣,
    ｢unknown｣,$2,｢$1｣,
    $1,$2,｢$2｣,
    ｢fatal_error(｢Incompatible prefixes $1 and $2｣)｣)｣)
  # Possible registers follow AMD manual with the following additions:
  #  a? - accumulator ("ab" means "%al", "av" means "%ax/%eax/%rax")
  #  r? - register is encoded in command (for example "push %rax..%rdi")
  #  c? - condition is encoded in command (for example Jcc)
  define(｢instruction_select｣, ｢ifelse(
    ｢$1｣, ｢size8data16rexw｣,
      ｢instruction_select(｢size8｣, shift($@))｣  ｢instruction_select(
		      ｢data16rexw｣, $2, setwflag($3), shift(shift(shift($@))))｣,
    ｢$1｣, ｢data16rexw｣,
      ｢instruction_select(｢data16｣, shift($@))｣  ｢instruction_select(
		   ｢none｣, shift($@))｣  ｢instruction_select(｢rexw｣, shift($@))｣,
    ｢$1｣, ｢rexbreg｣,
      ｢instruction_separator｢｣(rex_b? instruction_body(
      ｢none｣, $2, regopcode($3))｣,
    ｢$1｣, ｢size8｣,
      ｢ifelse(index(｢$4｣, ｢lock｣), -1, 
	｢instruction_separator｢｣｢(｣possible_prefixes(optional_prefixes(
	  ｢$4｣)) ｢REX_RXB?｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(｣possible_prefixes(optional_prefixes(
	  ｢$4｣)) ｢REX_RXB?｣ instruction_body(
	  $@)instruction_separator｢｣｢(｣one_required_prefix(｢lock｣,
	  optional_prefixes(｢$4｣)) ｢REX_RXB?｣ instruction_body(
	  lock$@)｣)｣,
    ｢$1｣, ｢data16｣,
      ｢ifelse(index(｢$4｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣one_required_prefix(｢data16｣,
	  optional_prefixes(｢$4｣)) ｢rex_rxb?｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(｣one_required_prefix(｢data16｣,
	  optional_prefixes(｢$4｣)) ｢rex_rxb?｣ instruction_body(
	  $@)instruction_separator｢｣｢(｣two_required_prefixes(｢data16｣, ｢lock｣,
	  optional_prefixes(｢$4｣)) ｢rex_rxb?｣ instruction_body(lock$@)｣)｣,
    ｢$1｣, ｢rexw｣, 
      ｢ifelse(index(｢$4｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣possible_prefixes(optional_prefixes(
	  ｢$4｣)) ｢REXW_RXB｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(｣possible_prefixes(optional_prefixes(
	  ｢$4｣)) ｢REXW_RXB｣ instruction_body(
	  $@)instruction_separator｢｣｢(｣one_required_prefix(｢lock｣,
	  optional_prefixes(｢$4｣)) ｢REXW_RXB｣ instruction_body(
	  lock$@)｣)｣,
    ｢$1｣, ｢none｣,
      ｢ifelse(index(｢$4｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣possible_prefixes(optional_prefixes(
	  ｢$4｣)) ｢rex_rxb?｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(｣possible_prefixes(optional_prefixes(
	  ｢$4｣)) ｢rex_rxb?｣ instruction_body(
	  $@)instruction_separator｢｣｢(｣one_required_prefix(｢lock｣,
	  optional_prefixes(｢$4｣)) ｢rex_rxb?｣ instruction_body(
	  lock$@)｣)｣,
    ｢fatal_error(Incorrect prefix size)｣)｣)
  define(｢optional_prefixes｣, ｢_optional_prefixes(split_argument($1))｣)
  define(｢_optional_prefixes｣, ｢ifelse(｢$#｣, ｢0｣, , ｢$#｣｢$1｣, ｢1｣, ,
    ｢$1｣, ｢condrep｣, ｢condrep, ｣,
    ｢$1｣, ｢rep｣, ｢rep, ｣)ifelse(eval(｢$#>1｣), ｢1｣,
    ｢_optional_prefixes(shift($@))｣)｣)
  define(｢instruction_separator｣, ｢_instruction_separator｢｣popdef(
    ｢_instruction_separator｣)｢｣pushdef(｢_instruction_separator｣, ｢ |
    ｣)｣)
  define(｢_instruction_separator｣, )
  define(｢setwflag｣, ｢_setwflag(split_argument($1))｣)
  define(｢_setwflag｣, ｢format(｢0x%02x｣, eval($1 + 1)) translit(
							  shift($@), ｢,｣, ｢ ｣)｣)
  define(｢regopcode｣, ｢_regopcode(split_argument($1))｣)
  define(｢_regopcode｣, ｢ifelse($#, 1, ｢chartest(｢(c & 0xf8) == $1｣)｣,
    ｢$1 _regopcode(shift($@))｣)｣)
  define(｢opcode_nomodrm｣, ｢_opcode_nomodrm(
    regexp(｢$@｣, ｢\(.*\)/[0-7]\(.*\)｣, ｢\1\2｣), $@)｣)
  define(｢_opcode_nomodrm｣, ｢ifelse(｢$1｣, , ｢begin_opcode((trim(
    ｢$2｣))) end_opcode(｢$3｣) instruction_name(｢$3｣)｣,
    ｢begin_opcode((trim(｢$1｣)))｣)｣)
  define(｢instruction_body｣, ｢opcode_nomodrm(｢$3｣,
    split_argument(｢$2｣))｢｣instruction_arguments_number(
    shift(split_argument($2)))｢｣instruction_arguments_sizes($1,
    shift(split_argument($2)))｢｣instruction_implied_arguments($1,
    shift(split_argument($2)))｢｣instruction_modrm_arguments(
    $@)｢｣instruction_immediate_arguments($1, shift(split_argument($2))))｣)
  define(｢instruction_arguments_number｣, ｢ operands_count_is_$#｣)
  define(｢instruction_arguments_sizes｣, ｢ifelse(eval(｢$#>2｣), ｢1｣,
    ｢instruction_arguments_sizes(｢$1｣, shift(shift($@)))｣) ifelse(
      substr(｢$1｣, ｢0｣, ｢4｣), ｢lock｣,
	｢instruction_arguments_sizes(substr(｢$1｣, ｢4｣), shift($@))｣,
	｢trim(｢operand｣decr(decr(｢$#｣))｢_｣ifelse(len(｢$2｣), ｢1｣,
	  ｢ifelse(instruction_argument_size_$1_$2,
	    ｢instruction_argument_size_$1_$2｣,
	    ｢ifelse(instruction_argument_size_$1,
	      ｢instruction_argument_size_$1｣,
	      ｢fatal_error(Can not determine argument size)｣,
	      instruction_argument_size_$1)｣,
	    instruction_argument_size_$1_$2)｣,
	  ｢ifelse(trim(｢instruction_argument_size_$1_｣substr($2, ｢1｣)),
	    ｢instruction_argument_size_$1_｣substr($2, ｢1｣),
	    ｢ifelse(trim(｢instruction_argument_size_｣substr($2, ｢1｣)),
	      ｢instruction_argument_size_｣substr($2, ｢1｣),
	      ｢fatal_error(Can not determine argument size)｣,
	      ｢instruction_argument_size_｣substr($2, ｢1｣))｣,
	    ｢instruction_argument_size_$1_｣substr($2, ｢1｣))｣))｣)｣)
  define(｢instruction_argument_size_data16｣, ｢16bit｣)
  define(｢instruction_argument_size_none｣, ｢32bit｣)
  define(｢instruction_argument_size_size8｣, ｢8bit｣)
  define(｢instruction_argument_size_rexw｣, ｢64bit｣)
  define(｢instruction_argument_size_rexw_I｣, ｢32bit｣)
  define(｢instruction_argument_size_b｣, ｢8bit｣)
  define(｢instruction_argument_size_d｣, ｢32bit｣)
  define(｢instruction_argument_size_q｣, ｢64bit｣)
  define(｢instruction_argument_size_r｣, ｢64bit｣)
  define(｢instruction_argument_size_data16_v｣, ｢16bit｣)
  define(｢instruction_argument_size_none_v｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_v｣, ｢64bit｣)
  define(｢instruction_argument_size_w｣, ｢16bit｣)
  define(｢instruction_argument_size_data16_z｣, ｢16bit｣)
  define(｢instruction_argument_size_none_z｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_z｣, ｢32bit｣)
  define(｢instruction_implied_arguments｣, ｢ifelse(eval(｢$#>2｣), ｢1｣,
    ｢instruction_implied_arguments(｢$1｣, shift(shift($@)))｣)｢｣ifelse(
      substr(｢$2｣, ｢0｣, ｢1｣), ｢a｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_accumulator｣,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢o｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_port_dx｣,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢r｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_from_opcode｣,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢E｣, ,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢G｣, ,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢I｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_immediate｣,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢J｣, ,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢X｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_ds_rsi｣,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢Y｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_es_rdi｣,
      ｢fatal_error(Can not determine argument type)｣)｣)
  define(｢instruction_modrm_arguments｣, ｢ifelse(index(｢$2｣, ｢ G｣), -1,
    ｢ifelse(index(｢$2｣, ｢ E｣), -1, , ｢ _instruction_modrm_arguments($@)｣)｣,
    ｢ _instruction_modrm_arguments($@)｣)｣)
  define(｢_instruction_modrm_arguments｣, ｢ifelse(index(｢$3｣, ｢/｣), -1, ,
    ｢regexp(｢$3｣, ｢/\([0-7]\)｣,
    ｢(( opcode_\1 end_opcode(split_argument(
      $2))) instruction_name(split_argument(
      $2)) & ｣)｣)｢( ｣__instruction_modrm_arguments($@)｢｣ifelse(
    index(｢$3｣, ｢/｣), -1, , ｢ )｣)｢)｣｣)
  define(｢__instruction_modrm_arguments｣, ｢ifelse(index(｢$1｣, ｢lock｣), -1,
    ｢register_instruction_modrm_arguments(shift(split_argument(
      $2))) | memory_instruction_modrm_arguments(shift(split_argument($2)))｣,
    ｢memory_instruction_modrm_arguments(shift(split_argument($2)))｣)｣)
  define(｢register_instruction_modrm_arguments｣,
    ｢modrm_registers _register_instruction_modrm_arguments($@)｣)
  define(｢_register_instruction_modrm_arguments｣, ｢ifelse(eval(｢$#>1｣), ｢1｣,
    ｢_register_instruction_modrm_arguments(shift($@)) ｣)｢｣ifelse(
      substr(｢$1｣, ｢0｣, ｢1｣), ｢E｣,
      ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, ｢0｣, ｢1｣), ｢G｣,
      ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣)｣)
  define(｢memory_instruction_modrm_arguments｣,
    ｢(modrm_memory & (any _memory_instruction_modrm_arguments($@) any*))｣)
  define(｢_memory_instruction_modrm_arguments｣, ｢ifelse(eval(｢$#>1｣), ｢1｣,
    ｢_memory_instruction_modrm_arguments(shift($@)) ｣)｢｣ifelse(
      substr(｢$1｣, ｢0｣, ｢1｣), ｢E｣,
      ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, ｢0｣, ｢1｣), ｢G｣,
      ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣)｣)
  define(｢instruction_immediate_arguments｣, ｢ifelse(eval(｢$#>2｣), ｢1｣,
    ｢instruction_immediate_arguments(｢$1｣, shift(shift($@)))｣) ifelse(
      substr(｢$1｣, ｢0｣, ｢4｣), ｢lock｣,
	｢instruction_immediate_arguments(substr(｢$1｣, ｢4｣), shift($@))｣,
      ｢ifelse(substr(｢$2｣, ｢0｣, ｢1｣), ｢I｣, ｢trim(ifelse(len(｢$2｣), ｢1｣,
	  ｢ifelse(instruction_immediate_arguments_$1,
	    ｢instruction_immediate_arguments_$1｣,
	    ｢fatal_error(Can not determine immediate size)｣,
	    instruction_immediate_arguments_$1)｣,
	  ｢ifelse(trim(｢instruction_immediate_arguments_$1_｣substr($2, ｢1｣)),
	    ｢instruction_immediate_arguments_$1_｣substr($2, ｢1｣),
	    ｢ifelse(trim(｢instruction_immediate_arguments_｣substr($2, ｢1｣)),
	      ｢instruction_immediate_arguments_｣substr($2, ｢1｣),
	      ｢fatal_error(Can not determine immediate size)｣,
	      ｢instruction_immediate_arguments_｣substr($2, ｢1｣))｣,
	    ｢instruction_immediate_arguments_$1_｣substr($2, ｢1｣))｣))｣,
	substr(｢$2｣, ｢0｣, ｢1｣), ｢J｣, ｢trim(ifelse(len(｢$2｣), ｢1｣,
	  ｢ifelse(instruction_jump_arguments_$1,
	    ｢instruction_jump_arguments_$1｣,
	    ｢fatal_error(Can not determine jump size)｣,
	    instruction_jump_arguments_$1)｣,
	  ｢ifelse(trim(｢instruction_jump_arguments_$1_｣substr($2, ｢1｣)),
	    ｢instruction_jump_arguments_$1_｣substr($2, ｢1｣),
	    ｢ifelse(trim(｢instruction_jump_arguments_｣substr($2, ｢1｣)),
	      ｢instruction_jump_arguments_｣substr($2, ｢1｣),
	      ｢fatal_error(Can not determine jump size)｣,
	      ｢instruction_jump_arguments_｣substr($2, ｢1｣))｣,
	    ｢instruction_jump_arguments_$1_｣substr($2, ｢1｣))｣))｣)｣)｣)
  define(｢instruction_immediate_arguments_data16｣, ｢imm16｣)
  define(｢instruction_immediate_arguments_none｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_size8｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_rexw｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_data16_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_none_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_rexw_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_data16_z｣, ｢imm16｣)
  define(｢instruction_immediate_arguments_none_z｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_rexw_z｣, ｢imm32｣)
  define(｢instruction_jump_arguments_none_b｣, ｢rel8｣)
  define(｢instruction_jump_arguments_data16_z｣, ｢rel16｣)
  define(｢instruction_jump_arguments_none_z｣, ｢rel32｣)
  define(｢instruction_jump_arguments_rexw_z｣, ｢rel32｣)

  instructions_defines(include(｢general-purpose-instructions.def｣))
  instructions_defines(include(｢x86-64-instructions.def｣))

  valid_instruction =
    instructions(include(｢general-purpose-instructions.def｣))
    instructions(include(｢x86-64-instructions.def｣));
