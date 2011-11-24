  # Displacements.
  disp8		= any disp8_operand;
  disp32	= any{4} disp32_operand;

  # Immediates.
  imm8 = any imm8_operand;
  imm16 = any{2} imm16_operand;
  imm32 = any{4} imm32_operand;
  imm64 = any{8} imm64_operand;

  # Different types of operands.
  operand_sib_nodisp = chartest(｢(c & 0xC0) == 0    && (c & 0x07) == 0x04｣) .
    (chartest(｢(c & 0x07) != 0x05｣) modrm_parse_sib);
  operand_sib_disp8  = chartest(｢(c & 0xC0) == 0x40 && (c & 0x07) == 0x04｣) .
    (any modrm_parse_sib) . disp8;
  operand_sib_disp32 =
    ((chartest(｢(c & 0xC0) == 0    && (c & 0x07) == 0x04｣) .
      (chartest(｢(c & 0x07) == 0x05｣) modrm_pure_index)) |
     (chartest(｢(c & 0xC0) == 0x80 && (c & 0x07) == 0x04｣) .
      (any modrm_parse_sib))) . disp32;
  operand_disp8  = chartest(｢(c & 0xC0) == 0x40 && (c & 0x07) != 0x04｣)
    modrm_base_disp . disp8;
  operand_disp32 = chartest(｢(c & 0xC0) == 0x80 && (c & 0x07) != 0x04｣)
     modrm_base_disp . disp32;
  # It's pure disp32 in IA32 case, but offset(%rip) in x86-64 case.
  operand_rip = chartest(｢(c & 0xC0) == 0   && (c & 0x07) == 0x05｣)
   modrm_rip . disp32;
  single_register_memory = chartest(｢(c & 0xC0) == 0
    && (c & 0x07) != 0x04 && (c & 0x07) != 0x05｣) modrm_only_base;
  modrm_memory = (operand_rip | operand_sib_nodisp | operand_sib_disp8 |
		  operand_sib_disp32 | operand_disp8 | operand_disp32 |
		  single_register_memory) check_access;
  modrm_registers = chartest(｢(c & 0xC0) == 0xC0｣);

  # Operations selected using opcode in ModR/M.
  opcode_0 = chartest(｢(c & 0x38) == 0x00｣);
  opcode_1 = chartest(｢(c & 0x38) == 0x08｣);
  opcode_2 = chartest(｢(c & 0x38) == 0x10｣);
  opcode_3 = chartest(｢(c & 0x38) == 0x18｣);
  opcode_4 = chartest(｢(c & 0x38) == 0x20｣);
  opcode_5 = chartest(｢(c & 0x38) == 0x28｣);
  opcode_6 = chartest(｢(c & 0x38) == 0x30｣);
  opcode_7 = chartest(｢(c & 0x38) == 0x38｣);

  # Prefixes.
  data16 = 0x66 data16_prefix;
  branch = 0x2e branch_not_taken | 0x3e branch_taken;
  condrep = 0xf2 repe_prefix | 0xf3 repne_prefix;
  lock = 0xf0 lock_prefix;
  rep = 0xf3 rep_prefix;

  # REX prefixes.
  action rex_pfx {
    rex_prefix = *p;
  }
  define(｢rex_pfx｣, ｢@rex｢_｣pfx｣)
  REX_NONE = 0x40 rex_pfx;
  REX_W    = (0x40 | 0x48) rex_pfx;
  REX_R    = (0x40 | 0x44) rex_pfx;
  REX_X    = (0x40 | 0x42) rex_pfx;
  REX_B    = (0x40 | 0x41) rex_pfx;
  REX_WR   = (0x40 | 0x44 | 0x48 | 0x4C) rex_pfx;
  REX_WX   = (0x40 | 0x42 | 0x48 | 0x4A) rex_pfx;
  REX_WB   = (0x40 | 0x41 | 0x48 | 0x49) rex_pfx;
  REX_RX   = (0x40 | 0x42 | 0x44 | 0x46) rex_pfx;
  REX_RB   = (0x40 | 0x41 | 0x44 | 0x45) rex_pfx;
  REX_XB   = (0x40 | 0x41 | 0x42 | 0x43) rex_pfx;
  REX_WRX  = (0x40 | 0x42 | 0x44 | 0x46 | 0x48 | 0x4A | 0x4C | 0x4E) rex_pfx;
  REX_WRB  = (0x40 | 0x41 | 0x44 | 0x45 | 0x48 | 0x49 | 0x4C | 0x4D) rex_pfx;
  REX_WXB  = (0x40 | 0x41 | 0x42 | 0x43 | 0x48 | 0x49 | 0x4A | 0x4B) rex_pfx;
  REX_RXB  = (0x40 | 0x41 | 0x42 | 0x43 | 0x44 | 0x45 | 0x46 | 0x47) rex_pfx;
  REX_WRXB = (0x40 | 0x41 | 0x42 | 0x43 | 0x44 | 0x45 | 0x46 | 0x47 |
	      0x48 | 0x49 | 0x4a | 0x4b | 0x4c | 0x4d | 0x4e | 0x4f) rex_pfx;
  rex_w    = REX_W    - REX_NONE;
  rex_r    = REX_R    - REX_NONE;
  rex_x    = REX_X    - REX_NONE;
  rex_b    = REX_B    - REX_NONE;
  rex_wr   = REX_WR   - REX_NONE;
  rex_wx   = REX_WX   - REX_NONE;
  rex_wb   = REX_WB   - REX_NONE;
  rex_rx   = REX_RX   - REX_NONE;
  rex_rb   = REX_RB   - REX_NONE;
  rex_xb   = REX_XB   - REX_NONE;
  rex_wrx  = REX_WRX  - REX_NONE;
  rex_wrb  = REX_WRB  - REX_NONE;
  rex_wxb  = REX_WXB  - REX_NONE;
  rex_rxb  = REX_RXB  - REX_NONE;
  rex_wrxb = REX_WRXB - REX_NONE;
  REXW_NONE= 0x48 rex_pfx;
  REXW_R   = (0x48 | 0x4C) rex_pfx;
  REXW_X   = (0x48 | 0x4A) rex_pfx;
  REXW_B   = (0x48 | 0x49) rex_pfx;
  REXW_RX  = (0x48 | 0x4A | 0x4C | 0x4E) rex_pfx;
  REXW_RB  = (0x48 | 0x49 | 0x4C | 0x4D) rex_pfx;
  REXW_XB  = (0x48 | 0x49 | 0x4A | 0x4B) rex_pfx;
  REXW_RXB = (0x48 | 0x49 | 0x4a | 0x4b | 0x4c | 0x4d | 0x4e | 0x4f) rex_pfx;
