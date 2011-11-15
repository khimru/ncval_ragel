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
    ｢instruction_select(possible_operand_prefixes(
    shift(split_argument($1))), $@)｣)｣)
  define(｢possible_operand_prefixes｣,
    ｢return_operand_prefixes(_possible_operand_prefixes($@))｣)
  define(｢_possible_operand_prefixes｣,｢ifelse($#,0,｢unknown｣,
    $#,1,｢｢possible_operand_prefix_｣substr($1,1)｣(substr($1,0,1)),
    ｢_check_prefixes_compatibility(｢possible_operand_prefix_｣substr($1,1)(
    substr($1,0,1)),_possible_operand_prefixes(shift($@)))｣)｣)
  # Operand sizes mostly follow AMD manual
  define(｢possible_operand_prefix_a｣,｢data16｣)
  define(｢possible_operand_prefix_b｣,｢unknown｣) # Other operands will determine
  define(｢possible_operand_prefix_v｣,｢data16rexw｣)
  define(｢possible_operand_prefix_z｣,｢data16rexw｣)
  # This is special prefix not included in AMD manual: w bit selects between
  # 8bit and 16/32/64 bit versions
  define(｢possible_operand_prefix_｣,｢size8data16rexw｣)
  define(｢return_operand_prefixes｣,｢ifelse(
     $1,｢unknown｣,｢none｣,
     $1,｢none｣,｢none｣,
     $1,｢size8data16rexw｣,｢size8data16rexw｣,
     $1,｢data16｣,｢data16｣,
     $1,｢data16rexw｣,｢data16rexw｣,
     $1,｢rexw｣,｢rexw｣,
     ｢fatal_error(Incorrect prefix size)｣)｣)
  define(｢_check_prefixes_compatibility｣,｢ifelse(
    ｢unknown｣,$1,$2,
    $1,$2,$2,
    ｢fatal_error(Incompatible prefixes $1 and $2)｣)｣)
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
    ｢$1｣, ｢size8｣,
      ｢ifelse(index(｢$4｣, ｢lock｣), -1, 
	｢instruction_separator｢｣｢(REX_RXB?｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(REX_RXB?｣ instruction_body(
	  $@)instruction_separator｢｣｢(lock｣ ｢REX_RXB?｣ instruction_body(
	  lock$@)｣)｣,
    ｢$1｣, ｢data16｣,
      ｢ifelse(index(｢$4｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(data16｣ ｢rex_rxb?｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(data16｣ ｢rex_rxb?｣ instruction_body(
	  $@)instruction_separator｢｣｢((｣two_required_prefixes(｢data16｣,
			      ｢lock｣)｢)｣ ｢rex_rxb?｣ instruction_body(lock$@)｣)｣,
    ｢$1｣, ｢rexw｣, 
      ｢ifelse(index(｢$4｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(REXW_RXB｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(REXW_RXB｣ instruction_body(
	  $@)instruction_separator｢｣｢(lock｣ ｢REXW_RXB｣ instruction_body(
	  lock$@)｣)｣,
    ｢$1｣, ｢none｣,
      ｢ifelse(index(｢$4｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(rex_rxb?｣ instruction_body($@)｣,
	｢instruction_separator｢｣｢(rex_rxb?｣ instruction_body(
	  $@)instruction_separator｢｣｢(lock｣ ｢rex_rxb?｣ instruction_body(
	  lock$@)｣)｣,
    ｢fatal_error(Incorrect prefix size)｣)｣)
  define(｢instruction_separator｣, ｢_instruction_separator｢｣popdef(
    ｢_instruction_separator｣)｢｣pushdef(｢_instruction_separator｣, ｢ |
    ｣)｣)
  define(｢_instruction_separator｣, )
  define(｢setwflag｣, ｢_setwflag(split_argument($1))｣)
  define(｢_setwflag｣, ｢format(｢0x%02x｣, eval($1 + 1)) translit(
							  shift($@), ｢,｣, ｢ ｣)｣)
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
    ｢instruction_arguments_sizes(｢$1｣, shift(shift($@)))｣) trim(
    ｢operand｣decr(decr(｢$#｣))｢_｣ifelse(len(｢$2｣), ｢1｣,
      ｢ifelse(instruction_argument_size_$1_$2,
	｢instruction_argument_size_$1_$2｣,
	｢ifelse(instruction_argument_size_lock$1_$2,
	  ｢instruction_argument_size_lock$1_$2｣,
	  ｢ifelse(instruction_argument_size_$1,
	    ｢instruction_argument_size_$1｣,
	    ｢ifelse(instruction_argument_size_lock$1,
	      ｢instruction_argument_size_lock$1｣,
	      ｢fatal_error(Can not determine argument size)｣,
	      instruction_argument_size_lock$1)｣,
	    instruction_argument_size_$1)｣,
	  instruction_argument_size_lock$1_$2)｣,
	instruction_argument_size_$1_$2)｣,
      ｢ifelse(trim(｢instruction_argument_size_｣substr($2, ｢1｣)),
	｢instruction_argument_size_｣substr($2, ｢1｣),
	｢fatal_error(Can not determine argument size)｣,
	｢instruction_argument_size_｣substr($2, ｢1｣))｣))｣)
  define(｢instruction_argument_size_lockdata16｣, ｢16bit｣)
  define(｢instruction_argument_size_locknone｣, ｢32bit｣)
  define(｢instruction_argument_size_locksize8｣, ｢8bit｣)
  define(｢instruction_argument_size_lockrexw｣, ｢64bit｣)
  define(｢instruction_argument_size_lockrexw_I｣, ｢32bit｣)
  define(｢instruction_argument_size_a｣, ｢16bit｣)
  define(｢instruction_implied_arguments｣, ｢ifelse(eval(｢$#>2｣), ｢1｣,
    ｢instruction_implied_arguments(｢$1｣, shift(shift($@)))｣)｢｣ifelse(
      substr(｢$2｣, ｢0｣, ｢1｣), ｢a｣,
      ｢ ｣｢operand｣decr(decr(｢$#｣))｢_accumulator｣,
      substr(｢$2｣, ｢0｣, ｢1｣), ｢I｣,
      ｢ ｣｢operand｣decr(decr(｢$#｣))｢_immediate｣)｣)
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
    ｢instruction_immediate_arguments(｢$1｣, shift(shift($@)))｣) trim(
    ifelse(len(｢$2｣), ｢1｣,
      ｢ifelse(instruction_immediate_arguments_$1_$2,
	｢instruction_immediate_arguments_$1_$2｣,
	｢ifelse(instruction_immediate_arguments_lock$1_$2,
	  ｢instruction_immediate_arguments_lock$1_$2｣,
	  ｢ifelse(instruction_immediate_arguments_$1,
	    ｢instruction_immediate_arguments_$1｣,
	    ｢ifelse(instruction_immediate_arguments_lock$1,
	      ｢instruction_immediate_arguments_lock$1｣,
	      ｢fatal_error(Can not determine argument size)｣,
	      instruction_immediate_arguments_lock$1)｣,
	    instruction_immediate_arguments_$1)｣,
	  instruction_immediate_arguments_lock$1_$2)｣,
	instruction_immediate_arguments_$1_$2)｣,
      ｢ifelse(trim(｢instruction_immediate_arguments_｣substr($2, ｢1｣)),
	｢instruction_immediate_arguments_｣substr($2, ｢1｣),
	｢fatal_error(Can not determine argument size)｣,
	｢instruction_immediate_arguments_｣substr($2, ｢1｣))｣))｣)
  define(｢instruction_immediate_arguments_lockdata16｣, )
  define(｢instruction_immediate_arguments_locknone｣, )
  define(｢instruction_immediate_arguments_locksize8｣, )
  define(｢instruction_immediate_arguments_lockrexw｣, )
  define(｢instruction_immediate_arguments_lockdata16_I｣, ｢imm16｣)
  define(｢instruction_immediate_arguments_locknone_I｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_locksize8_I｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_lockrexw_I｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_a｣, ｢16bit｣)

  instructions_defines(include(｢general-purpose-instructions.def｣))

  valid_instruction =
    instructions(include(｢general-purpose-instructions.def｣));
