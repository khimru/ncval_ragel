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
    ｢instruction_select(possible_command_modes(shift(split_argument($1))),
		       possible_rex_rxb_bits(shift(split_argument($1))), $@)｣)｣)
  define(｢possible_command_modes｣, ｢ifelse($1, , ｢none｣,
    ｢return_operand_modes(_possible_command_modes($@))｣)｣)
  define(｢_possible_command_modes｣,｢ifelse($#, 0, ｢unknown｣,
    $#, 1, ｢｢ifelse(substr($1, 0, 1), ｢M｣, ｢memonly｣, substr($1, 0, 1), ｢R｣, ｢regonly｣)｢｣possible_command_mode_｣substr($1, 1, 1)(substr($1, 0, 1))｣,
    ｢check_prefixes_compatibility(｢ifelse(substr($1, 0, 1), ｢M｣, ｢memonly｣, substr($1, 0, 1), ｢R｣, ｢regonly｣)｢｣possible_command_mode_｣substr($1, 1, 1)(
    substr($1, 0, 1)), _possible_command_modes(shift($@)))｣)｣)
  # Operand sizes mostly follow AMD manual.
  # ｢unknown｣ means ther operands will determine.
  define(｢possible_command_mode_1｣,｢unknown｣)
  define(｢possible_command_mode_b｣,｢unknown｣)
  define(｢possible_command_mode_d｣,｢unknown｣)
  define(｢possible_command_mode_p｣,｢unknown｣)
  define(｢possible_command_mode_q｣,｢unknown｣)
  define(｢possible_command_mode_r｣,｢unknown｣)
  define(｢possible_command_mode_s｣,｢unknown｣)
  define(｢possible_command_mode_v｣,｢data16rexw｣)
  define(｢possible_command_mode_w｣,｢unknown｣)
  define(｢possible_command_mode_z｣,｢data16rexw｣)
  # ｢size8｣ is special "prefix" not included in AMD manual:  w bit in opcode
  # switches between 8bit and 16/32/64 bit versions.  M is just an address in
  # memory: it means register-only encodings are invalid, but other operands
  # decide everything else.
  define(｢possible_command_mode_｣, ｢size8data16rexw｣)
  define(｢return_operand_modes｣, ｢ifelse(
    ｢$#｣, 0, ｢none｣,
    ｢$#｣, 1,
    ｢ifelse(
      $1, ｢unknown｣, ｢none｣,
      $1, ｢none｣, ｢none｣,
      $1, ｢memonlyunknown｣, ｢memonlynone｣,
      $1, ｢memonlynone｣, ｢memonlynone｣,
      $1, ｢regonlyunknown｣, ｢regonlynone｣,
      $1, ｢regonlynone｣, ｢regonlynone｣,
      $1, ｢size8data16rexw｣, ｢size8data16rexw｣,
      $1, ｢data16｣, ｢data16｣,
      $1, ｢data16rexw｣, ｢data16rexw｣,
      $1, ｢rexw｣, ｢rexw｣,
      $1, ｢memonlysize8data16rexw｣, ｢memonlysize8data16rexw｣,
      $1, ｢memonlydata16｣, ｢memonlydata16｣,
      $1, ｢memonlydata16rexw｣, ｢memonlydata16rexw｣,
      $1, ｢memonlyrexw｣, ｢memonlyrexw｣,
      $1, ｢regonlysize8data16rexw｣, ｢regonlysize8data16rexw｣,
      $1, ｢regonlydata16｣, ｢regonlydata16｣,
      $1, ｢regonlydata16rexw｣, ｢regonlydata16rexw｣,
      $1, ｢regonlyrexw｣, ｢regonlyrexw｣,
      ｢fatal_error(｢Incorrect operand mode:｣ $1)｣)｣,
    ｢$#｣, 2, ｢ifelse(
      $1, ｢unknown｣, ｢return_operand_modes(｢$2｣)｣,
      $2, ｢unknown｣, ｢return_operand_modes(｢$1｣)｣,
      $1, $2, ｢return_operand_modes(｢$1｣)｣,
      $1, ｢memonly｣, ｢return_operand_modes(｢memonly｣$2)｣,
      $2, ｢memonly｣, ｢return_operand_modes(｢memonly｣$1)｣,
      $1, ｢regonly｣, ｢return_operand_modes(｢regonly｣$2)｣,
      $2, ｢regonly｣, ｢return_operand_modes(｢regonly｣$1)｣,
      ｢fatal_error(｢Incorrect operand modes｣ $1 ｢and｣ $2)｣)｣,
    ｢return_operand_modes(｢$1｣, return_operand_modes(shift($@)))｣)｣)
  define(｢check_prefixes_compatibility｣, ｢ifelse(
    ｢unknown｣, $1, ｢$2｣,
    ｢unknown｣, $2, ｢$1｣,
    $1, $2, ｢$2｣,
    $1, ｢memonly｣$2, $1,
    $2, ｢memonly｣$1, $2,
    $1, ｢regonly｣$2, $1,
    $2, ｢regonly｣$1, $2,
    $1, ｢memonly｣, ｢memonly｣$2,
    $2, ｢memonly｣, ｢memonly｣$1,
    $1, ｢regonly｣, ｢regonly｣$2,
    $2, ｢regonly｣, ｢regonly｣$1,
    ｢fatal_error(｢Incompatible prefixes｣ $1 ｢and｣ $2)｣)｣)
  define(｢possible_rex_rxb_bits｣, ｢check_rex_rxb_bits(｢ifelse(｢$1｣, , ,
    ｢ifelse(
      unquote(｢possible_rex_rxb_bits_｣substr(｢$1｣, 0, 1)(substr(｢$1｣, 1, 1))),
      ｢possible_rex_rxb_bits_｣substr(｢$1｣, 0, 1)(substr(｢$1｣, 1, 1)),
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
  define(｢possible_rex_rxb_bits_G｣, ｢r｣)
  define(｢possible_rex_rxb_bits_E｣, ｢xb｣)
  define(｢possible_rex_rxb_bits_I｣, )
  define(｢possible_rex_rxb_bits_J｣, )
  define(｢possible_rex_rxb_bits_M｣, ｢xb｣)
  define(｢possible_rex_rxb_bits_O｣, )
  define(｢possible_rex_rxb_bits_R｣, ｢b｣)
  define(｢possible_rex_rxb_bits_S｣, )
  define(｢possible_rex_rxb_bits_X｣, )
  define(｢possible_rex_rxb_bits_Y｣, )
  define(｢check_rex_rxb_bits｣, ｢ifelse($1, , ,
    $1, ｢b｣, ｢b｣,
    $1, ｢r｣, ｢r｣,
    $1, ｢rxb｣, ｢rxb｣,
    $1, ｢xb｣, ｢xb｣,
    $1, ｢xbr｣, ｢rxb｣,
    ｢fatal_error(｢Incorrect rex type:｣ $1)｣)｣)
  # Note: we don't support "{mem,reg}only" and "lock" simultaneously.  IA32 and
  # x86-64 never use them together.  "{mem,reg}only" without lock are "sgdt",
  # "lea", etc while "lock" can only be ever used with the follwing instructions:
  # adc, add, and, btc, btr, bts, cmpxchg, cmpxchg8b, chmpxchg16b, dec, inc, neg,
  # not, or, sbb, sub, xadd, xchg, and xor.  ALL these instructions are NOT in
  # the "{mem,reg}only" group initially but become "memonly" when combined with
  # "lock" prefix.
  define(｢instruction_select｣, ｢ifelse(
    substr(｢$4｣, 0, 5), ｢0x66 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0x66 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢data16 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0x66 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢0xf2 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0xf2 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢repnz ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0xf2 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢0xf3 ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0xf3 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    substr(｢$4｣, 0, 5), ｢repz ｣,
      ｢instruction_select(｢$1｣, ｢$2｣, ｢$3｣, trim(substr(｢$4｣, 5)), ｢0xf3 $5｣,
					shift(shift(shift(shift(shift($@))))))｣,
    ｢$1｣, ｢size8data16rexw｣,
      ｢instruction_select(｢size8｣, shift($@))｣  ｢instruction_select(
	   ｢data16rexw｣, $2, $3, setwflag($4), shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢data16rexw｣,
      ｢instruction_select(｢data16｣, shift($@))｣  ｢instruction_select(
		   ｢none｣, shift($@))｣  ｢instruction_select(｢rexw｣, shift($@))｣,
    ｢$1｣, ｢size8｣,
      ｢ifelse(index(｢$5｣, ｢lock｣), -1, 
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢size8｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢size8｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣one_required_prefix(｢lock｣,
	  optional_prefixes(｢$5｣)) REX_prefix_q(｢$2｣)instruction_body(
	  ｢memonlysize8｣, shift(shift($@)))｣)｣,
    ｢$1｣, ｢data16｣,
      ｢ifelse(index(｢$5｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣one_required_prefix(｢data16｣,
	  optional_prefixes(｢$5｣)) rex_prefix_q(｢$2｣)instruction_body(｢data16｣,
	  shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣one_required_prefix(｢data16｣,
	  optional_prefixes(｢$5｣)) rex_prefix_q(｢$2｣)instruction_body(｢data16｣,
	  shift(shift($@)))instruction_separator｢｣｢(｣two_required_prefixes(
	  ｢data16｣, ｢lock｣, optional_prefixes(｢$4｣)) rex_prefix_q(
	  ｢$2｣)instruction_body(｢memonlydata16｣, shift(shift($@)))｣)｣,
    ｢$1｣, ｢rexw｣, 
      ｢ifelse(index(｢$5｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢rexw｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢rexw｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣one_required_prefix(｢lock｣,
	  optional_prefixes(｢$5｣)) REXW_prefix(｢$2｣)instruction_body(
	  ｢memonlyrexw｣, shift(shift($@)))｣)｣,
    ｢$1｣, ｢none｣,
      ｢ifelse(index(｢$5｣, ｢lock｣), -1,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢none｣, shift(shift($@)))｣,
	｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	  ｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢none｣, shift(shift(
	  $@)))instruction_separator｢｣｢(｣one_required_prefix(｢lock｣,
	  optional_prefixes(｢$5｣)) rex_prefix_q(｢$2｣)instruction_body(
	  ｢memonlynone｣, shift(shift($@)))｣)｣,
    ｢$1｣, ｢memonlysize8data16rexw｣,
      ｢instruction_select(｢memonlysize8｣, shift($@))｣  ｢instruction_select(
	｢memonlydata16rexw｣, $2, $3, setwflag($4),
					       shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢memonlydata16rexw｣,
      ｢instruction_select(｢memonlydata16｣, shift($@))｣  ｢instruction_select(
	｢memonlynone｣, shift($@))｣  ｢instruction_select(｢memonlyrexw｣,
								    shift($@))｣,
    ｢$1｣, ｢memonlysize8｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢memonlysize8｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢memonlydata16｣,
      ｢instruction_separator｢｣｢(｣one_required_prefix(｢data16｣,
	optional_prefixes(｢$5｣)) rex_prefix_q(｢$2｣)instruction_body(
					    ｢memonlydata16｣, shift(shift($@)))｣,
    ｢$1｣, ｢memonlyrexw｣, 
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢memonlyrexw｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢memonlynone｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢memonlynone｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢regonlysize8data16rexw｣,
      ｢instruction_select(｢regonlysize8｣, shift($@))｣  ｢instruction_select(
	｢regonlydata16rexw｣, $2, $3, setwflag($4),
					       shift(shift(shift(shift($@)))))｣,
    ｢$1｣, ｢regonlydata16rexw｣,
      ｢instruction_select(｢regonlydata16｣, shift($@))｣  ｢instruction_select(
	｢regonlynone｣, shift($@))｣  ｢instruction_select(｢regonlyrexw｣,
								    shift($@))｣,
    ｢$1｣, ｢regonlysize8｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REX_prefix_q(｢$2｣)instruction_body(｢regonlysize8｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢regonlydata16｣,
      ｢instruction_separator｢｣｢(｣one_required_prefix(｢data16｣,
	optional_prefixes(｢$5｣)) rex_prefix_q(｢$2｣)instruction_body(
					    ｢regonlydata16｣, shift(shift($@)))｣,
    ｢$1｣, ｢regonlyrexw｣, 
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) REXW_prefix(｢$2｣)instruction_body(｢regonlyrexw｣,
							     shift(shift($@)))｣,
    ｢$1｣, ｢regonlynone｣,
      ｢instruction_separator｢｣｢(｣possible_optional_prefixes(
	｢$5｣) rex_prefix_q(｢$2｣)instruction_body(｢regonlynone｣,
							     shift(shift($@)))｣,
    ｢fatal_error(｢Incorrect operand mode:｣ $1)｣)｣)
  define(｢possible_optional_prefixes｣, ｢ifelse(
    substr(｢$1｣, 0, 5), ｢0x66 ｣,
		       ｢one_required_prefix(｢data16｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 5), ｢0xf2 ｣,
			｢one_required_prefix(｢repnz｣, optional_prefixes(｢$1｣))｣,
    substr(｢$1｣, 0, 5), ｢0xf3 ｣,
			 ｢one_required_prefix(｢repz｣, optional_prefixes(｢$1｣))｣,
    possible_prefixes(optional_prefixes(｢$1｣)), , ,
    ｢possible_prefixes(optional_prefixes(｢$1｣))?｣)｣)
  define(｢optional_prefixes｣, ｢_optional_prefixes(split_argument($1))｣)
  define(｢_optional_prefixes｣, ｢ifelse(｢$#｣, 0, , ｢$#｣｢$1｣, 1, ,
    ｢$1｣, ｢condrep｣, ｢condrep, ｣,
    ｢$1｣, ｢rep｣, ｢rep, ｣)ifelse(eval(｢$#>1｣), 1,
    ｢_optional_prefixes(shift($@))｣)｣)
  define(｢rex_prefix_q｣, ｢ifelse($1, , , ｢｢rex_$1?｣ ｣)｣)
  define(｢REX_prefix_q｣, ｢ifelse($1, , , ｢｢REX_｣translit($1, ｢a-z｣, ｢A-Z｣)? ｣)｣)
  define(｢REXW_prefix｣,
	     ｢ifelse($1, , ｢REXW_NONE ｣, ｢｢REXW_｣translit($1, ｢a-z｣, ｢A-Z｣) ｣)｣)
  define(｢instruction_separator｣, ｢_instruction_separator｢｣popdef(
    ｢_instruction_separator｣)｢｣pushdef(｢_instruction_separator｣, ｢ |
    ｣)｣)
  define(｢_instruction_separator｣, )
  define(｢setwflag｣, ｢_setwflag(split_argument(｢$1｣))｣)
  define(｢_setwflag｣, ｢ifelse(
    ｢$2｣, , format(｢0x%02x｣, eval(｢$1 + 1｣)),
    index(｢$2｣, ｢/｣), -1, ｢$1 _setwflag(shift($@))｣,
    ｢format(｢0x%02x｣, eval(｢$1 + 1｣)) $2｣)｣)
  define(｢instruction_body｣, ｢opcode_nomodrm(｢$1｣, ｢$3｣,
    split_argument(｢$2｣))｢｣instruction_modrm_arguments(
    $@)｢｣instruction_immediate_arguments(｢$1｣, shift(split_argument(｢$2｣))))｣)
  define(｢opcode_nomodrm｣, ｢ifelse(regexp(｢$2｣, ｢\(.*\)/[0-7s]\(.*\)｣, ｢\1\2｣), ,
    ｢__opcode_nomodrm(｢$1｣, _opcode_nomodrm(shift($@)), shift(shift($@)))｣,
    ｢___opcode_nomodrm(｢$1｣, regexp($2, ｢\(.*\)/[0-7s]\(.*\)｣, ｢\1\2｣),
							   shift(shift($@)))｣)｣)
  define(｢_opcode_nomodrm｣, ｢ifelse(｢$3｣, , ｢$1｣,
    ｢ifelse(substr(｢$3｣, 0, 1), ｢r｣, regopcode(｢$1｣),
    ｢_opcode_nomodrm(｢$1｣, ｢$2｣, shift(shift(shift($@))))｣)｣)｣)
  define(｢__opcode_nomodrm｣,
    ｢begin_opcode((trim(｢$2｣))) end_opcode(｢$3｣) instruction_name(
    ｢$3｣)｢｣instruction_arguments_number(shift(shift(shift(
    $@))))｢｣instruction_arguments_sizes(｢$1｣, shift(shift(shift(
    $@))))｢｣instruction_implied_arguments(｢$1｣, shift(shift(shift($@))))｣)
  define(｢___opcode_nomodrm｣, ｢begin_opcode((trim(｢$2｣)))｣)
  define(｢regopcode｣, ｢_regopcode(split_argument(｢$1｣))｣)
  define(｢_regopcode｣, ｢ifelse($#, 1,
    ｢chartest(｢(｢c｣ != 0x90) && ((｢c｣ & 0xf8) == ｢$1｣)｣)｣,
    ｢$1 _regopcode(shift($@))｣)｣)
  define(｢instruction_arguments_number｣,
    ｢ifelse(｢$1｣, , ｢ operands_count_is_0｣, ｢ operands_count_is_$#｣)｣)
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
	      unquote(｢instruction_argument_size_$1_｣substr($2, 1, 1)),
	      ｢instruction_argument_size_$1_｣substr($2, 1, 1),
	      ｢ifelse(
		unquote(｢instruction_argument_size_｣substr($2, 1, 1)),
		｢instruction_argument_size_｣substr($2, 1, 1),
		｢fatal_error(｢Can not determine argument size:｣ $1 $2)｣,
		｢instruction_argument_size_｣substr($2, 1, 1))｣,
	      ｢instruction_argument_size_$1_｣substr($2, 1, 1))｣,
	    instruction_argument_size_$1_$2)｣))｣)｣)
  define(｢instruction_argument_size_data16｣, ｢16bit｣)
  define(｢instruction_argument_size_none｣, ｢32bit｣)
  define(｢instruction_argument_size_size8｣, ｢8bit｣)
  define(｢instruction_argument_size_rexw｣, ｢64bit｣)
  define(｢instruction_argument_size_rexw_I｣, ｢32bit｣)
  define(｢instruction_argument_size_b｣, ｢8bit｣)
  define(｢instruction_argument_size_d｣, ｢32bit｣)
  define(｢instruction_argument_size_q｣, ｢64bit｣)
  define(｢instruction_argument_size_p｣, ｢farptr｣)
  define(｢instruction_argument_size_r｣, ｢64bit｣)
  define(｢instruction_argument_size_s｣, ｢selector｣)
  define(｢instruction_argument_size_data16_v｣, ｢16bit｣)
  define(｢instruction_argument_size_none_v｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_v｣, ｢64bit｣)
  define(｢instruction_argument_size_data16_Sw｣, ｢segreg｣)
  define(｢instruction_argument_size_none_Sw｣, ｢segreg｣)
  define(｢instruction_argument_size_rexw_Sw｣, ｢segreg｣)
  define(｢instruction_argument_size_w｣, ｢16bit｣)
  define(｢instruction_argument_size_data16_z｣, ｢16bit｣)
  define(｢instruction_argument_size_none_z｣, ｢32bit｣)
  define(｢instruction_argument_size_rexw_z｣, ｢32bit｣)
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
      substr(｢$2｣, 0, 1), ｢O｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_absolute_disp｣,
      substr(｢$2｣, 0, 1), ｢R｣, ,
      substr(｢$2｣, 0, 1), ｢S｣, ,
      substr(｢$2｣, 0, 1), ｢X｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_ds_rsi｣,
      substr(｢$2｣, 0, 1), ｢Y｣, ｢ ｣｢operand｣decr(decr(｢$#｣))｢_es_rdi｣,
      ｢fatal_error(｢Can not determine argument type:｣ $2)｣)｣)
  define(｢instruction_modrm_arguments｣, ｢ifelse(index(｢$2｣, ｢ E｣), -1,
    ｢ifelse(index(｢$2｣, ｢ G｣), -1,
      ｢ifelse(index(｢$2｣, ｢ M｣), -1,
	｢ifelse(index(｢$2｣, ｢ R｣), -1,
	  ｢ifelse(index(｢$2｣, ｢ S｣), -1, ,
	    ｢ _instruction_modrm_arguments($@)｣)｣,
	  ｢ _instruction_modrm_arguments($@)｣)｣,
	｢ _instruction_modrm_arguments($@)｣)｣,
      ｢ _instruction_modrm_arguments($@)｣)｣,
    ｢ _instruction_modrm_arguments($@)｣)｣)
  define(｢_instruction_modrm_arguments｣, ｢ifelse(index(｢$3｣, ｢/｣), -1, ,
    ｢regexp(｢$3｣, ｢/\([0-7s]\)｣,
    ｢(( opcode_\1 end_opcode(split_argument(
      ｢$2｣))) instruction_name(split_argument(
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
  define(｢register_instruction_modrm_arguments｣,
    ｢modrm_registers _register_instruction_modrm_arguments($@)｣)
  define(｢_register_instruction_modrm_arguments｣, ｢ifelse(eval(｢$#>1｣), 1,
    ｢_register_instruction_modrm_arguments(shift($@)) ｣)｢｣ifelse(
      substr(｢$1｣, 0, 1), ｢E｣, ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, 0, 1), ｢G｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢M｣, ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, 0, 1), ｢R｣, ｢operand｣decr(｢$#｣)｢_from_modrm_rm｣,
      substr(｢$1｣, 0, 1), ｢S｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,)｣)
  define(｢memory_instruction_modrm_arguments｣,
    ｢(modrm_memory & (any _memory_instruction_modrm_arguments($@) any*))｣)
  define(｢_memory_instruction_modrm_arguments｣, ｢ifelse(eval(｢$#>1｣), 1,
    ｢_memory_instruction_modrm_arguments(shift($@)) ｣)｢｣ifelse(
      substr(｢$1｣, 0, 1), ｢E｣, ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, 0, 1), ｢G｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,
      substr(｢$1｣, 0, 1), ｢M｣, ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, 0, 1), ｢R｣, ｢operand｣decr(｢$#｣)｢_rm｣,
      substr(｢$1｣, 0, 1), ｢S｣, ｢operand｣decr(｢$#｣)｢_from_modrm_reg｣,)｣)
  define(｢instruction_immediate_arguments｣, ｢ifelse(
      substr(｢$1｣, 0, 7), ｢memonly｣,
		  ｢instruction_immediate_arguments(substr(｢$1｣, 7), shift($@))｣,
      substr(｢$1｣, 0, 7), ｢regonly｣,
		  ｢instruction_immediate_arguments(substr(｢$1｣, 7), shift($@))｣,
      ｢ ifelse(substr(｢$2｣, 0, 1), ｢i｣, ｢ifelse(len(｢$2｣), 1,
	  ｢ifelse(instruction_immediate_arguments_$1,
	    ｢instruction_immediate_arguments_$1｣,
	    ｢fatal_error(｢Can not determine immediate size:｣ $1)｣,
	    instruction_immediate_arguments_$1｢｢n2｣｣)｣,
	  ｢ifelse(
	    unquote(｢instruction_immediate_arguments_$1_｣substr($2, 1, 1)),
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1, 1),
	    ｢ifelse(
	      unquote(｢instruction_immediate_arguments_｣substr($2, 1, 1)),
	      ｢instruction_immediate_arguments_｣substr($2, 1, 1),
	      ｢fatal_error(｢Can not determine immediate size:｣ $1 $2)｣,
	      ｢instruction_immediate_arguments_｣substr($2, 1, 1)｢｢n2｣｣)｣,
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1, 1)｢｢n2｣｣)｣)｣,
	substr(｢$2｣, 0, 1), ｢I｣, ｢ifelse(len(｢$2｣), 1,
	  ｢ifelse(instruction_immediate_arguments_$1,
	    ｢instruction_immediate_arguments_$1｣,
	    ｢fatal_error(｢Can not determine immediate size:｣ $1)｣,
	    instruction_immediate_arguments_$1)｣,
	  ｢ifelse(
	    unquote(｢instruction_immediate_arguments_$1_｣substr($2, 1, 1)),
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1, 1),
	    ｢ifelse(
	      unquote(｢instruction_immediate_arguments_｣substr($2, 1, 1)),
	      ｢instruction_immediate_arguments_｣substr($2, 1, 1),
	      ｢fatal_error(｢Can not determine immediate size:｣ $1 $2)｣,
	      ｢instruction_immediate_arguments_｣substr($2, 1, 1))｣,
	    ｢instruction_immediate_arguments_$1_｣substr($2, 1, 1))｣)｣,
	substr(｢$2｣, 0, 1), ｢J｣, ｢ifelse(len(｢$2｣), 1,
	  ｢ifelse(
	    instruction_jump_arguments_$1,
	    ｢instruction_jump_arguments_$1｣,
	    ｢fatal_error(｢Can not determine jump size:｣ $1)｣,
	    instruction_jump_arguments_$1)｣,
	  ｢ifelse(
	    unquote(｢instruction_jump_arguments_$1_｣substr($2, 1, 1)),
	    ｢instruction_jump_arguments_$1_｣substr($2, 1, 1),
	    ｢ifelse(
	      unquote(｢instruction_jump_arguments_｣substr($2, 1, 1)),
	      ｢instruction_jump_arguments_｣substr($2, 1, 1),
	      ｢fatal_error(｢Can not determine jump size:｣ $1 $2)｣,
	      ｢instruction_jump_arguments_｣substr($2, 1, 1))｣,
	    ｢instruction_jump_arguments_$1_｣substr($2, 1, 1))｣)｣,
	substr(｢$2｣, 0, 1), ｢O｣, ｢disp64｣) ifelse(eval(｢$#>2｣), 1, ｢instruction_immediate_arguments(
	  ｢$1｣, shift(shift($@)))｣)｣)｣)
  define(｢instruction_immediate_arguments_size8｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_data16｣, ｢imm16｣)
  define(｢instruction_immediate_arguments_none｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_rexw｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_size8_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_data16_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_none_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_rexw_b｣, ｢imm8｣)
  define(｢instruction_immediate_arguments_data16_v｣, ｢imm16｣)
  define(｢instruction_immediate_arguments_none_v｣, ｢imm32｣)
  define(｢instruction_immediate_arguments_rexw_v｣, ｢imm64｣)
  define(｢instruction_immediate_arguments_none_w｣, ｢imm16｣)
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
