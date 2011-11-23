%%{
  machine one_instruction_x86_64;
  alphtype unsigned char;

  include(common.m4)

  # We don't need to fully parse instructions here
  define(｢begin_opcode｣, ｢$1｣)
  define(｢check_access｣, )
  define(｢end_opcode｣, )
  define(｢modrm_base_disp｣, )
  define(｢modrm_only_base｣, )
  define(｢modrm_parse_sib｣, )
  define(｢modrm_pure_index｣, )
  define(｢modrm_rip｣, )
  define(｢data16_prefix｣, )
  define(｢lock_prefix｣, )
  define(｢operand0_8bit｣, )
  define(｢operand0_16bit｣, )
  define(｢operand0_32bit｣, )
  define(｢operand0_64bit｣, )
  define(｢operand0_accumulator｣, )
  define(｢operand0_from_modrm_reg｣, )
  define(｢operand0_from_modrm_rm｣, )
  define(｢operand0_from_opcode｣, )
  define(｢operand0_immediate｣, )
  define(｢operand0_rm｣, )
  define(｢operand1_8bit｣, )
  define(｢operand1_16bit｣, )
  define(｢operand1_32bit｣, )
  define(｢operand1_64bit｣, )
  define(｢operand1_from_modrm_reg｣, )
  define(｢operand1_from_modrm_rm｣, )
  define(｢operand1_immediate｣, )
  define(｢operand1_rm｣, )
  define(｢operand2_8bit｣, )
  define(｢operand2_16bit｣, )
  define(｢operand2_32bit｣, )
  define(｢operand2_64bit｣, )
  define(｢operand2_immediate｣, )
  define(｢operands_count_is_0｣, )
  define(｢operands_count_is_1｣, )
  define(｢operands_count_is_2｣, )
  define(｢operands_count_is_3｣, )
  define(｢operands_count_is_4｣, )
  define(｢operands_count_is_5｣, )

  # But we need to know where DISP and IMM fields can be found
  action disp8_operand_begin { }
  action disp8_operand_end { }
  define(｢disp8_operand｣, ｢｢>disp8_operand_begin @disp8_operand_end｣｣)
  action disp32_operand_begin { }
  action disp32_operand_end { }
  define(｢disp32_operand｣, ｢｢>disp32_operand_begin @disp32_operand_end｣｣)
  action imm8_operand_begin { }
  action imm8_operand_end { }
  define(｢imm8_operand｣, ｢｢>imm8_operand_begin @imm8_operand_end｣｣)
  action imm16_operand_begin { }
  action imm16_operand_end { }
  define(｢imm16_operand｣, ｢｢>imm16_operand_begin @imm16_operand_end｣｣)
  action imm32_operand_begin { }
  action imm32_operand_end { }
  define(｢imm32_operand｣, ｢｢>imm32_operand_begin @imm32_operand_end｣｣)
  action imm64_operand_begin { }
  action imm64_operand_end { }
  define(｢imm64_operand｣, ｢｢>imm8_operand_begin @imm64_operand_end｣｣)

  include(｢instruction_parts.m4｣)

  define(｢_instruction_name_action｣, ｢action instruction_｢｣$1 { }｣)

  include(｢instructions.m4｣)

  main := valid_instruction;

}%%
