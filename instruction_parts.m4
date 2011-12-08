# Copyright (c) 2011 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

  # Relative jumps and calls.
  rel8 = any rel8_operand;
  rel16 = any{2} rel16_operand;
  rel32 = any{4} rel32_operand;

  # Displacements.
  disp8		= any disp8_operand;
  disp32	= any{4} disp32_operand;
  disp64	= any{8} disp64_operand;

  # Immediates.
  imm2 = chartest(｢(c & 0x0c) == 0x00｣) imm2_operand;
  imm8 = any imm8_operand;
  imm16 = any{2} imm16_operand;
  imm32 = any{4} imm32_operand;
  imm64 = any{8} imm64_operand;
  imm8n2 = any imm8_second_operand;
  imm16n2 = any{2} imm16_second_operand;
  imm32n2 = any{4} imm32_second_operand;
  imm64n2 = any{8} imm64_second_operand;

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
  # Used for segment operations: there only 6 segment registers.
  opcode_s = chartest(｢(c & 0x38) < 0x30｣);
  # This is used to move operand name detection after first byte of ModRM.
  opcode_m = any;
  opcode_r = any;

  # Prefixes.
  data16 = 0x66 data16_prefix;
  branch = 0x2e branch_not_taken | 0x3e branch_taken;
  condrep = 0xf2 repnz_prefix | 0xf3 repz_prefix;
  lock = 0xf0 lock_prefix;
  rep = 0xf3 rep_prefix;
  repnz = 0xf2 repnz_prefix;
  repz = 0xf3 repz_prefix;

  # REX prefixes.
  action rex_pfx {
    rex_prefix = *p;
  }
  define(｢rex_pfx｣, ｢@rex｢_｣pfx｣)
  REX_NONE = 0x40 rex_pfx;
  REX_W    = chartest(｢(c & 0xf7) == 0x40｣) rex_pfx;
  REX_R    = chartest(｢(c & 0xfb) == 0x40｣) rex_pfx;
  REX_X    = chartest(｢(c & 0xfd) == 0x40｣) rex_pfx;
  REX_B    = chartest(｢(c & 0xfe) == 0x40｣) rex_pfx;
  REX_WR   = chartest(｢(c & 0xf3) == 0x40｣) rex_pfx;
  REX_WX   = chartest(｢(c & 0xf5) == 0x40｣) rex_pfx;
  REX_WB   = chartest(｢(c & 0xf6) == 0x40｣) rex_pfx;
  REX_RX   = chartest(｢(c & 0xf9) == 0x40｣) rex_pfx;
  REX_RB   = chartest(｢(c & 0xfa) == 0x40｣) rex_pfx;
  REX_XB   = chartest(｢(c & 0xfc) == 0x40｣) rex_pfx;
  REX_WRX  = chartest(｢(c & 0xf1) == 0x40｣) rex_pfx;
  REX_WRB  = chartest(｢(c & 0xf2) == 0x40｣) rex_pfx;
  REX_WXB  = chartest(｢(c & 0xf4) == 0x40｣) rex_pfx;
  REX_RXB  = chartest(｢(c & 0xf8) == 0x40｣) rex_pfx;
  REX_WRXB = chartest(｢(c & 0xf0) == 0x40｣) rex_pfx;

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
  REXW_R   = chartest(｢(c & 0xfb) == 0x48｣) rex_pfx;
  REXW_X   = chartest(｢(c & 0xfd) == 0x48｣) rex_pfx;
  REXW_B   = chartest(｢(c & 0xfe) == 0x48｣) rex_pfx;
  REXW_RX  = chartest(｢(c & 0xf9) == 0x48｣) rex_pfx;
  REXW_RB  = chartest(｢(c & 0xfa) == 0x48｣) rex_pfx;
  REXW_XB  = chartest(｢(c & 0xfc) == 0x48｣) rex_pfx;
  REXW_RXB = chartest(｢(c & 0xf8) == 0x48｣) rex_pfx;

  # VEX/XOP prefix.
  action vex_pfx {
    vex_prefix = *p;
  }
  define(｢vex_pfx｣, ｢@vex｢_｣pfx｣)
  # VEX/XOP prefix2.
  action vex_pfx2 {
    vex_prefix2 = *p;
  }
  define(｢vex_pfx2｣, ｢@vex｢_｣pfx2｣)
  # VEX/XOP short prefix
  action vex_pfx_short {
    /* This emulates two prefixes case. */
    vex_prefix = (p[0] & 0x80) | 0x61;
    vex_prefix2 = p[0] & 0x7f;
  }
  define(｢vex_pfx_short｣, ｢@vex｢_｣pfx｢_｣short｣)

  define(｢vex_map｣, ｢VEX_$1 = chartest(｢(c & $2) == $2｣) vex_pfx｣)
  vex_map(NONE, 0xe0);
  vex_map(R, 0x60);
  vex_map(X, 0xa0);
  vex_map(B, 0xc0);
  vex_map(RX, 0x20);
  vex_map(RB, 0x40);
  vex_map(XB, 0x80);
  vex_map(RXB, 0x00);
  popdef(｢vex_map｣)

  define(｢vex_map｣, ｢VEX_map$1 = chartest(｢(c & 0x1f) == $2｣)｣)
  vex_map(｢01｣, 1);
  vex_map(｢02｣, 2);
  vex_map(｢03｣, 3);
  vex_map(｢08｣, 8);
  vex_map(｢09｣, 9);
  vex_map(｢0A｣, 10);
  vex_map(｢00001｣, 1);
  vex_map(｢00010｣, 2);
  vex_map(｢00011｣, 3);
  vex_map(｢01000｣, 8);
  vex_map(｢01001｣, 9);
  vex_map(｢01010｣, 10);
  popdef(｢vex_map｣)
