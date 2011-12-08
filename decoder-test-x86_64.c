/*
 * Copyright (c) 2011 The Native Client Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include <assert.h>
#include <elf.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "decoder-x86_64.h"

#undef TRUE
#define TRUE    1

#undef FALSE
#define FALSE   0

typedef Elf64_Ehdr Elf_Ehdr;
typedef Elf64_Shdr Elf_Shdr;

static void CheckBounds(unsigned char *data, size_t data_size,
			void *ptr, size_t inside_size) {
  assert(data <= (unsigned char *) ptr);
  assert((unsigned char *) ptr + inside_size <= data + data_size);
}

void ReadFile(const char *filename, uint8_t **result, size_t *result_size) {
  FILE *fp;
  uint8_t *data;
  size_t file_size;
  size_t got;

  fp = fopen(filename, "rb");
  if (fp == NULL) {
    fprintf(stderr, "Failed to open input file: %s\n", filename);
    exit(1);
  }
  /* Find the file size. */
  fseek(fp, 0, SEEK_END);
  file_size = ftell(fp);
  data = malloc(file_size);
  if (data == NULL) {
    fprintf(stderr, "Unable to create memory image of input file: %s\n",
	    filename);
    exit(1);
  }
  fseek(fp, 0, SEEK_SET);
  got = fread(data, 1, file_size, fp);
  if (got != file_size) {
    fprintf(stderr, "Unable to read data from input file: %s\n",
	    filename);
    exit(1);
  }
  fclose(fp);

  *result = data;
  *result_size = file_size;
}

struct DecodeState {
  const uint8_t *fwait; /* Set to true if fwait is detetected. */
  const uint8_t *offset;
};

void ProcessInstruction(const uint8_t *begin, const uint8_t *end,
			struct instruction *instruction, void *userdata) {
  const uint8_t *p;
  char delimeter = ' ';
  int print_rip = FALSE;
  int rex_bits = 0;
  int maybe_rex_bits = 0;
  int show_name_suffix = FALSE;
#define print_name(x) (printf((x)), shown_name += strlen((x)))
  int shown_name = 0;
  int i, operand_type;

  /* “fwait” is nasty: any number of them will be included in other X87
     instructions ("fclex", "finit", “fstcw”, “fstsw”, “fsave” have two
     names, other instructions are unchanged) - but if after them we see
     regular instruction then we must print all them.  This convoluted
     logic is not needed when we  don't print anything so decoder does
     not include it.  */
  if ((end == begin + 1) && (begin[0] == 0x9b)) {
    if (!(((struct DecodeState *)userdata)->fwait)) {
      ((struct DecodeState *)userdata)->fwait = begin;
    }
    return;
  } else if (((struct DecodeState *)userdata)->fwait) {
    if ((begin[0] < 0xd8) || (begin[0] > 0xdf)) {
      while ((((struct DecodeState *)userdata)->fwait) < begin) {
	printf("%8x:\t                   \tfwait\n",
	  (((struct DecodeState *)userdata)->fwait++) -
				     (((struct DecodeState *)userdata)->offset));
      }
    } else {
      begin = ((struct DecodeState *)userdata)->fwait;
    }
    ((struct DecodeState *)userdata)->fwait = FALSE;
  }
  printf("%8x:\t", begin - (((struct DecodeState *)userdata)->offset));
  for (p = begin; p < begin + 7; p++) {
    if (p >= end) {
      printf("   ");
    } else {
      printf("%02x ", *p);
    }
  }
  printf("\t");
  if (instruction->operands_count > 0) {
    show_name_suffix = TRUE;
    for (i=instruction->operands_count-1;i>=0;i--) {
      if (instruction->operands[i].name == JMP_TO) {
        /* Most control flow instructions never use suffixes, but “call” and
           “jmp” do... unless byte offset is used.  */
	if ((!strcmp(instruction->name, "call")) ||
	    (!strcmp(instruction->name, "jmp"))) {
	  switch (instruction->operands[i].type) {
	    case OperandSize8bit: show_name_suffix = FALSE; break;
	    case OperandSize16bit: show_name_suffix = 'w'; break;
	    case OperandSize32bit: show_name_suffix = 'q'; break;
	    default: assert(FALSE);
	  }
	} else {
	  show_name_suffix = FALSE;
	}
      } else if ((instruction->operands[i].name == REG_IMM) ||
		 (instruction->operands[i].name == REG_IMM2) ||
		 (instruction->operands[i].name == REG_RM) ||
		 (instruction->operands[i].name == REG_PORT_DX) ||
		 (instruction->operands[i].name == REG_ES_RDI) ||
		 (instruction->operands[i].name == REG_DS_RSI)) {
	if (show_name_suffix) {
	  switch (instruction->operands[i].type) {
	    case OperandSize8bit: show_name_suffix = 'b'; break;
	    case OperandSize16bit: show_name_suffix = 'w'; break;
	    case OperandSize32bit: show_name_suffix = 'l'; break;
	    case OperandSize64bit: show_name_suffix = 'q'; break;
	    case OperandFloatSize32bit: show_name_suffix = 's'; break;
	    case OperandFloatSize64bit: show_name_suffix = 'l'; break;
	    case OperandFloatSize80bit:show_name_suffix = 't'; break;
	    case OperandX87Size32bit: show_name_suffix = 'l'; break;
	    case OperandX87Size64bit: show_name_suffix = 'L'; break;
	    case OperandX87Size16bit:
	    case OperandX87BCD:
	    case OperandX87ENV:
	    case OperandX87STATE:
	    case OperandX87MMXXMMSTATE:
	    case OperandSize128bit:
	    case OperandFarPtr: 
	    case OperandSelector: show_name_suffix = FALSE; break;
	    default: assert(FALSE);
	  }
	}
      } else {
	/* First argument of “rcl”/“rcr”/“rol”/“ror”/“sar/”“shl”/“shr”
	   can not be used to determine size of command.  */
	if (((i != 1) || (strcmp(instruction->name, "rcl") &&
			  strcmp(instruction->name, "rcr") &&
			  strcmp(instruction->name, "rol") &&
			  strcmp(instruction->name, "ror") &&
			  strcmp(instruction->name, "sal") &&
			  strcmp(instruction->name, "sar") &&
			  strcmp(instruction->name, "shl") &&
			  strcmp(instruction->name, "shr"))) &&
	/* Second argument of “crc32” can not be used to determine size of
	   command.  */
	    ((i != 0) || strcmp(instruction->name, "crc32"))) {
	  show_name_suffix = FALSE;
	}
	/* First argument of “crc32” can be used for that but objdump uses
	   suffix anyway. */
	if ((i == 1) && (!strcmp(instruction->name, "crc32"))) {
	  switch (instruction->operands[i].type) {
	    case OperandSize8bit: show_name_suffix = 'b'; break;
	    case OperandSize16bit: show_name_suffix = 'w'; break;
	    case OperandSize32bit: show_name_suffix = 'l'; break;
	    case OperandSize64bit: show_name_suffix = 'q'; break;
	    default: assert(FALSE);
	  }
	}
      }
      if ((instruction->operands[i].name >= REG_R8) &&
	  (instruction->operands[i].name <= REG_R15)) {
	rex_bits++;
	/* HACK: objdump mistakenly allows “lock” with “mov %crX,%rXX” only in
	   32bit mode.  It's perfectly valid in 64bit mode, too, so instead of
	   changing the decoder we fix it here.  */
	if (instruction->operands[i].type == OperandControlRegister) {
	  if ((*begin == 0xf0) && !(instruction->prefix.lock)) {
	    print_name("lock ");
	    instruction->operands[i].name -= 8;
	  }
	}
      } else if (instruction->operands[i].name == REG_RM) {
	if ((instruction->rm.base >= REG_R8) &&
	    (instruction->rm.base <= REG_R15)) {
	  rex_bits++;
	} else if ((instruction->rm.base == REG_NONE) ||
		   (instruction->rm.base == REG_RIP)) {
	  maybe_rex_bits++;
	}
	if ((instruction->rm.index >= REG_R8) &&
	    (instruction->rm.index <= REG_R15)) {
	  rex_bits++;
	}
      }
    }
  }
  if (instruction->prefix.lock) {
    print_name("lock ");
  }
  if (instruction->prefix.repnz) {
    print_name("repnz ");
  }
  if (instruction->prefix.repz) {
    /* This prefix is “rep” for “ins”, “movs”, and “outs”, “repz” otherwise.  */
    if ((!strcmp(instruction->name, "ins")) ||
	(!strcmp(instruction->name, "movs")) ||
	(!strcmp(instruction->name, "outs"))) {
      print_name("rep ");
    } else {
      print_name("repz ");
    }
  }
  if (instruction->prefix.rex == 0x40) {
    /* First argument of “crc32”/“rcl”/“rcr”/“rol”/“ror”/“sar”/“shl”/“shr”
       confuses objdump: it does not show it in this case.  */
    if (show_name_suffix &&
	((strcmp(instruction->name, "crc32") &&
	  strcmp(instruction->name, "rcl") &&
	  strcmp(instruction->name, "rcr") &&
	  strcmp(instruction->name, "rol") &&
	  strcmp(instruction->name, "ror") &&
	  strcmp(instruction->name, "sal") &&
	  strcmp(instruction->name, "sar") &&
	  strcmp(instruction->name, "shl") &&
	  strcmp(instruction->name, "shr")) ||
	 (instruction->operands[1].name > REG_R15))) {
      print_name("rex ");
    }
  }
  if ((instruction->prefix.rex & 0x08) == 0x08) {
    /* rex.W is ignored by “in”/“out”, and “pop”/“push” commands.  */
    if ((!strcmp(instruction->name, "in")) ||
	(!strcmp(instruction->name, "ins")) ||
	(!strcmp(instruction->name, "out")) ||
	(!strcmp(instruction->name, "outs")) ||
	(!strcmp(instruction->name, "pop")) ||
	(!strcmp(instruction->name, "push"))) {
      rex_bits = -1;
    }
  }
  if (show_name_suffix == 'b') {
    /* “cflush", “int”, “invlpg”, “prefetch*”, and “setcc” never use suffix. */
    if ((!strcmp(instruction->name, "clflush")) ||
	(!strcmp(instruction->name, "int")) ||
	(!strcmp(instruction->name, "invlpg")) ||
	(!strcmp(instruction->name, "prefetch")) ||
	(!strcmp(instruction->name, "prefetchnta")) ||
	(!strcmp(instruction->name, "prefetcht0")) ||
	(!strcmp(instruction->name, "prefetcht1")) ||
	(!strcmp(instruction->name, "prefetcht2")) ||
	(!strcmp(instruction->name, "prefetchw")) ||
	(!strcmp(instruction->name, "seta")) ||
	(!strcmp(instruction->name, "setae")) ||
	(!strcmp(instruction->name, "setbe")) ||
	(!strcmp(instruction->name, "setb")) ||
	(!strcmp(instruction->name, "sete")) ||
	(!strcmp(instruction->name, "setg")) ||
	(!strcmp(instruction->name, "setge")) ||
	(!strcmp(instruction->name, "setle")) ||
	(!strcmp(instruction->name, "setl")) ||
	(!strcmp(instruction->name, "setne")) ||
	(!strcmp(instruction->name, "setno")) ||
	(!strcmp(instruction->name, "setnp")) ||
	(!strcmp(instruction->name, "setns")) ||
	(!strcmp(instruction->name, "seto")) ||
	(!strcmp(instruction->name, "setp")) ||
	(!strcmp(instruction->name, "sets"))) {
      show_name_suffix = FALSE;
    /* Instruction enter accepts two immediates: word and byte. But
       objdump always uses suffix “q”. This is supremely strange, but
       we want to match objdump exactly, so... here goes.  */
    } else if (!strcmp(instruction->name, "enter")) {
      show_name_suffix = 'q';
    }
  }
  if ((show_name_suffix == 'b') || (show_name_suffix == 'l')) {
    /* objdump always shows “6a 01” as “pushq $1”, “66 68 01 00” as
       “pushw $1” yet “68 01 00 00 00” as "pushq $1" again.  This makes no
       sense whatsoever so we'll just hack around here to make sure we
       produce objdump-compatible output.  */
    if (!strcmp(instruction->name, "push")) {
      show_name_suffix = 'q';
    }
  }
  if (show_name_suffix == 'w') {
    /* “lldt”, “[ls]msw”, “lret”, “ltr”, and “ver[rw]” newer use suffixes at
       all.  */
    if ((!strcmp(instruction->name, "lldt")) ||
	(!strcmp(instruction->name, "lmsw")) ||
	(!strcmp(instruction->name, "lret")) ||
	(!strcmp(instruction->name, "ltr")) ||
	(!strcmp(instruction->name, "smsw")) ||
	(!strcmp(instruction->name, "verr")) ||
	(!strcmp(instruction->name, "verw"))) {
       show_name_suffix = FALSE;
    /* “callw”/“jmpw” already includes suffix in the nanme.  */
    } else if ((!strcmp(instruction->name, "callw")) ||
	       (!strcmp(instruction->name, "jmpw"))) {
      show_name_suffix = FALSE;
    /* “ret” always uses suffix “q” no matter what.  */
    } else if (!strcmp(instruction->name, "ret")) {
      show_name_suffix = 'q';
    }
  }
  if ((show_name_suffix == 'w') || (show_name_suffix == 'l')) {
    /* “sldt” and “str” newer uses suffixes at all.  */
    if ((!strcmp(instruction->name, "sldt")) ||
	(!strcmp(instruction->name, "str"))) {
       show_name_suffix = FALSE;
    }
  }
  if (show_name_suffix == 'l') {
    /* “popl” does not exist, only “popq” do.  */
    if (!strcmp(instruction->name, "pop")) {
       show_name_suffix = 'q';
    }
  }
  if (show_name_suffix == 'q') {
    /* “callq”,“cmpxchg8b”/“jmpq” already include suffix in the nanme.  */
    if ((!strcmp(instruction->name, "callq")) ||
	(!strcmp(instruction->name, "cmpxchg8b")) ||
	(!strcmp(instruction->name, "jmpq"))) {
       show_name_suffix = FALSE;
    }
  }
  i = (instruction->prefix.rex & 0x01) +
      ((instruction->prefix.rex & 0x02) >> 1) +
      ((instruction->prefix.rex & 0x04) >> 2);
  if (!((i == rex_bits) ||
	(maybe_rex_bits &&
	 (instruction->prefix.rex & 0x01) && (i == rex_bits + 1)))) {
    print_name("rex.");
    if (instruction->prefix.rex & 0x08) {
      print_name("W");
    }
    if (instruction->prefix.rex & 0x04) {
      print_name("R");
    }
    if (instruction->prefix.rex & 0x02) {
      print_name("X");
    }
    if (instruction->prefix.rex & 0x01) {
      print_name("B");
    }
    print_name(" ");
  }
  printf("%s", instruction->name);
  shown_name += strlen(instruction->name);
  if (show_name_suffix) {
    if (show_name_suffix == 'L') {
      print_name("ll");
    } else {
      printf("%c", show_name_suffix);
      shown_name++;
    }
  }
  if (!strcmp(instruction->name, "mov")) {
    if ((instruction->operands[1].name == REG_IMM) &&
       (instruction->operands[1].type == OperandSize64bit)) {
      print_name("abs");
    }
  }
#undef print_name
  if ((strcmp(instruction->name, "nop") || instruction->operands_count != 0) &&
      strcmp(instruction->name, "fwait") &&
      strcmp(instruction->name, "popq   %fs") &&
      strcmp(instruction->name, "popq   %gs") &&
      strcmp(instruction->name, "pushq  %fs") &&
      strcmp(instruction->name, "pushq  %gs")) {
    while (shown_name < 6) {
      printf(" ");
      shown_name++;
    }
    if (instruction->operands_count == 0) {
      printf(" ");
    }
  }
  for (i=instruction->operands_count-1;i>=0;i--) {
    printf("%c", delimeter);
    if ((!strcmp(instruction->name, "callw")) ||
	(!strcmp(instruction->name, "callq")) ||
	(!strcmp(instruction->name, "jmpw")) ||
	(!strcmp(instruction->name, "jmpq")) ||
	(!strcmp(instruction->name, "ljmpw")) ||
	(!strcmp(instruction->name, "ljmpq")) ||
	(!strcmp(instruction->name, "lcallw")) ||
	(!strcmp(instruction->name, "lcallq"))) {
      printf("*");
    }
    /* Dirty hack: both AMD manual and Intel manual agree that mov from general
       purpose register to segment register has signature “mov Ew Sw”, but
       objdump insist on 32bit.  This is clearly error in objdump so we fix it
       here and not in decoder.  */
    if (((begin[0] == 0x8e) || 
	 ((begin[0] >= 0x40) && (begin[0] <= 0x4f) && (begin[1] == 0x8e))) &&
	(instruction->operands[i].type == OperandSize16bit)) {
      operand_type = OperandSize32bit;
    } else {
      operand_type = instruction->operands[i].type;
    }
    switch (instruction->operands[i].name) {
      case REG_RAX: switch (operand_type) {
	case OperandSize8bit: printf("%%al"); break;
	case OperandSize16bit: printf("%%ax"); break;
	case OperandSize32bit: printf("%%eax"); break;
	case OperandSize64bit: printf("%%rax"); break;
	case OperandST: printf("%%st(0)"); break;
	case OperandMMX: printf("%%mm0"); break;
	case OperandXMM: printf("%%xmm0"); break;
	case OperandSegmentRegister: printf("%%es"); break;
	case OperandControlRegister: printf("%%cr0"); break;
	case OperandDebugRegister: printf("%%db0"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RCX: switch (operand_type) {
	case OperandSize8bit: printf("%%cl"); break;
	case OperandSize16bit: printf("%%cx"); break;
	case OperandSize32bit: printf("%%ecx"); break;
	case OperandSize64bit: printf("%%rcx"); break;
	case OperandST: printf("%%st(1)"); break;
	case OperandMMX: printf("%%mm1"); break;
	case OperandXMM: printf("%%xmm1"); break;
	case OperandSegmentRegister: printf("%%cs"); break;
	case OperandControlRegister: printf("%%cr1"); break;
	case OperandDebugRegister: printf("%%db1"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RDX: switch (operand_type) {
	case OperandSize8bit: printf("%%dl"); break;
	case OperandSize16bit: printf("%%dx"); break;
	case OperandSize32bit: printf("%%edx"); break;
	case OperandSize64bit: printf("%%rdx"); break;
	case OperandST: printf("%%st(2)"); break;
	case OperandMMX: printf("%%mm2"); break;
	case OperandXMM: printf("%%xmm2"); break;
	case OperandSegmentRegister: printf("%%ss"); break;
	case OperandControlRegister: printf("%%cr2"); break;
	case OperandDebugRegister: printf("%%db2"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RBX: switch (operand_type) {
	case OperandSize8bit: printf("%%bl"); break;
	case OperandSize16bit: printf("%%bx"); break;
	case OperandSize32bit: printf("%%ebx"); break;
	case OperandSize64bit: printf("%%rbx"); break;
	case OperandST: printf("%%st(3)"); break;
	case OperandMMX: printf("%%mm3"); break;
	case OperandXMM: printf("%%xmm3"); break;
	case OperandSegmentRegister: printf("%%ds"); break;
	case OperandControlRegister: printf("%%cr3"); break;
	case OperandDebugRegister: printf("%%db3"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RSP: switch (operand_type) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%spl");
	  else
	    printf("%%ah");
	  break;
	case OperandSize16bit: printf("%%sp"); break;
	case OperandSize32bit: printf("%%esp"); break;
	case OperandSize64bit: printf("%%rsp"); break;
	case OperandST: printf("%%st(4)"); break;
	case OperandMMX: printf("%%mm4"); break;
	case OperandXMM: printf("%%xmm4"); break;
	case OperandSegmentRegister: printf("%%fs"); break;
	case OperandControlRegister: printf("%%cr4"); break;
	case OperandDebugRegister: printf("%%db4"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RBP: switch (operand_type) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%bpl");
	  else
	    printf("%%ch");
	  break;
	case OperandSize16bit: printf("%%bp"); break;
	case OperandSize32bit: printf("%%ebp"); break;
	case OperandSize64bit: printf("%%rbp"); break;
	case OperandST: printf("%%st(5)"); break;
	case OperandMMX: printf("%%mm5"); break;
	case OperandXMM: printf("%%xmm5"); break;
	case OperandSegmentRegister: printf("%%gs"); break;
	case OperandControlRegister: printf("%%cr5"); break;
	case OperandDebugRegister: printf("%%db5"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RSI: switch (operand_type) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%sil");
	  else
	    printf("%%dh");
	  break;
	case OperandSize16bit: printf("%%si"); break;
	case OperandSize32bit: printf("%%esi"); break;
	case OperandSize64bit: printf("%%rsi"); break;
	case OperandST: printf("%%st(6)"); break;
	case OperandMMX: printf("%%mm6"); break;
	case OperandXMM: printf("%%xmm6"); break;
	case OperandControlRegister: printf("%%cr6"); break;
	case OperandDebugRegister: printf("%%db6"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RDI: switch (operand_type) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%dil");
	  else
	    printf("%%bh");
	  break;
	case OperandSize16bit: printf("%%di"); break;
	case OperandSize32bit: printf("%%edi"); break;
	case OperandSize64bit: printf("%%rdi"); break;
	case OperandST: printf("%%st(7)"); break;
	case OperandMMX: printf("%%mm7"); break;
	case OperandXMM: printf("%%xmm7"); break;
	case OperandControlRegister: printf("%%cr7"); break;
	case OperandDebugRegister: printf("%%db7"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R8: switch (operand_type) {
	case OperandSize8bit: printf("%%r8b"); break;
	case OperandSize16bit: printf("%%r8w"); break;
	case OperandSize32bit: printf("%%r8d"); break;
	case OperandSize64bit: printf("%%r8"); break;
	case OperandXMM: printf("%%xmm8"); break;
	case OperandControlRegister: printf("%%cr8"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R9: switch (operand_type) {
	case OperandSize8bit: printf("%%r9b"); break;
	case OperandSize16bit: printf("%%r9w"); break;
	case OperandSize32bit: printf("%%r9d"); break;
	case OperandSize64bit: printf("%%r9"); break;
	case OperandControlRegister: printf("%%cr9"); break;
	case OperandXMM: printf("%%xmm9"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R10: switch (operand_type) {
	case OperandSize8bit: printf("%%r10b"); break;
	case OperandSize16bit: printf("%%r10w"); break;
	case OperandSize32bit: printf("%%r10d"); break;
	case OperandSize64bit: printf("%%r10"); break;
	case OperandControlRegister: printf("%%cr10"); break;
	case OperandXMM: printf("%%xmm10"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R11: switch (operand_type) {
	case OperandSize8bit: printf("%%r11b"); break;
	case OperandSize16bit: printf("%%r11w"); break;
	case OperandSize32bit: printf("%%r11d"); break;
	case OperandSize64bit: printf("%%r11"); break;
	case OperandXMM: printf("%%xmm11"); break;
	case OperandControlRegister: printf("%%cr11"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R12: switch (operand_type) {
	case OperandSize8bit: printf("%%r12b"); break;
	case OperandSize16bit: printf("%%r12w"); break;
	case OperandSize32bit: printf("%%r12d"); break;
	case OperandSize64bit: printf("%%r12"); break;
	case OperandXMM: printf("%%xmm12"); break;
	case OperandControlRegister: printf("%%cr12"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R13: switch (operand_type) {
	case OperandSize8bit: printf("%%r13b"); break;
	case OperandSize16bit: printf("%%r13w"); break;
	case OperandSize32bit: printf("%%r13d"); break;
	case OperandSize64bit: printf("%%r13"); break;
	case OperandXMM: printf("%%xmm13"); break;
	case OperandControlRegister: printf("%%cr13"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R14: switch (operand_type) {
	case OperandSize8bit: printf("%%r14b"); break;
	case OperandSize16bit: printf("%%r14w"); break;
	case OperandSize32bit: printf("%%r14d"); break;
	case OperandSize64bit: printf("%%r14"); break;
	case OperandXMM: printf("%%xmm14"); break;
	case OperandControlRegister: printf("%%cr14"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R15: switch (operand_type) {
	case OperandSize8bit: printf("%%r15b"); break;
	case OperandSize16bit: printf("%%r15w"); break;
	case OperandSize32bit: printf("%%r15d"); break;
	case OperandSize64bit: printf("%%r15"); break;
	case OperandXMM: printf("%%xmm15"); break;
	case OperandControlRegister: printf("%%cr15"); break;
	default: assert(FALSE);
      }
      break;
      case REG_ST:
        assert(operand_type == OperandST);
        printf("%%st");
        break;
      case REG_RM: {
	if (instruction->rm.offset) {
	  printf("0x%llx",instruction->rm.offset);
	}
	if ((instruction->rm.base != REG_NONE) ||
	    (instruction->rm.index != REG_RIZ) ||
	    (instruction->rm.scale != 0)) {
	  printf("(");
	}
	switch (instruction->rm.base) {
	  case REG_RAX: printf("%%rax"); break;
	  case REG_RCX: printf("%%rcx"); break;
	  case REG_RDX: printf("%%rdx"); break;
	  case REG_RBX: printf("%%rbx"); break;
	  case REG_RSP: printf("%%rsp"); break;
	  case REG_RBP: printf("%%rbp"); break;
	  case REG_RSI: printf("%%rsi"); break;
	  case REG_RDI: printf("%%rdi"); break;
	  case REG_R8: printf("%%r8"); break;
	  case REG_R9: printf("%%r9"); break;
	  case REG_R10: printf("%%r10"); break;
	  case REG_R11: printf("%%r11"); break;
	  case REG_R12: printf("%%r12"); break;
	  case REG_R13: printf("%%r13"); break;
	  case REG_R14: printf("%%r14"); break;
	  case REG_R15: printf("%%r15"); break;
	  case REG_RIP: printf("%%rip"); print_rip = TRUE; break;
	  case REG_NONE: break;
	  default: assert(FALSE);
	}
	switch (instruction->rm.index) {
	  case REG_RAX: printf(",%%rax,%d",1<<instruction->rm.scale); break;
	  case REG_RCX: printf(",%%rcx,%d",1<<instruction->rm.scale); break;
	  case REG_RDX: printf(",%%rdx,%d",1<<instruction->rm.scale); break;
	  case REG_RBX: printf(",%%rbx,%d",1<<instruction->rm.scale); break;
	  case REG_RSP: printf(",%%rsp,%d",1<<instruction->rm.scale); break;
	  case REG_RBP: printf(",%%rbp,%d",1<<instruction->rm.scale); break;
	  case REG_RSI: printf(",%%rsi,%d",1<<instruction->rm.scale); break;
	  case REG_RDI: printf(",%%rdi,%d",1<<instruction->rm.scale); break;
	  case REG_R8: printf(",%%r8,%d",1<<instruction->rm.scale); break;
	  case REG_R9: printf(",%%r9,%d",1<<instruction->rm.scale); break;
	  case REG_R10: printf(",%%r10,%d",1<<instruction->rm.scale); break;
	  case REG_R11: printf(",%%r11,%d",1<<instruction->rm.scale); break;
	  case REG_R12: printf(",%%r12,%d",1<<instruction->rm.scale); break;
	  case REG_R13: printf(",%%r13,%d",1<<instruction->rm.scale); break;
	  case REG_R14: printf(",%%r14,%d",1<<instruction->rm.scale); break;
	  case REG_R15: printf(",%%r15,%d",1<<instruction->rm.scale); break;
	  case REG_RIZ: if (((instruction->rm.base != REG_NONE) &&
			     (instruction->rm.base != REG_RSP) &&
			     (instruction->rm.base != REG_R12)) ||
			    (instruction->rm.scale != 0))
	      printf(",%%riz,%d",1<<instruction->rm.scale);
	    break;
	  case REG_NONE: break;
	  default: assert(FALSE);
	}
	if ((instruction->rm.base != REG_NONE) ||
	    (instruction->rm.index != REG_RIZ) ||
	    (instruction->rm.scale != 0)) {
	  printf(")");
	}
      }
      break;
      case REG_IMM: {
	printf("$0x%llx",instruction->imm[0]);
	break;
      }
      case REG_IMM2: {
	printf("$0x%llx",instruction->imm[1]);
	break;
      }
      case REG_PORT_DX: printf("(%%dx)"); break;
      case REG_DS_RBX: printf("%%ds:(%%rbx)"); break;
      case REG_ES_RDI: printf("%%es:(%%rdi)"); break;
      case REG_DS_RSI: printf("%%ds:(%%rsi)"); break;
      case JMP_TO: if (instruction->operands[0].type == OperandSize16bit)
	  printf("0x%x", (end + instruction->rm.offset -
			   (((struct DecodeState *)userdata)->offset)) & 0xffff);
	else
	  printf("0x%x", end + instruction->rm.offset -
				     (((struct DecodeState *)userdata)->offset));
	break;
      default: assert(FALSE);
    }
    delimeter = ',';
  }
  if (print_rip) {
    printf("        # 0x%8x", end + instruction->rm.offset -
				     (((struct DecodeState *)userdata)->offset));
  }
  printf("\n");
  begin += 7;
  while (begin < end) {
    printf("%8x:\t", begin - (((struct DecodeState *)userdata)->offset));
    for (p = begin; p < begin + 7; p++) {
      if (p >= end) {
	printf("\n");
	return;
      } else {
	printf("%02x ", *p);
      }
    }
    begin += 6;
  }
}

void ProcessError (const uint8_t *ptr, void *userdata) {
  printf("rejected at %x (byte 0x%02x)\n", ptr - (uint8_t *)userdata, *ptr);
}

int DecodeFile(const char *filename, int repeat_count) {
  size_t data_size;
  uint8_t *data;
  ReadFile(filename, &data, &data_size);

  int count;
  for (count = 0; count < repeat_count; count++) {
    Elf_Ehdr *header;
    int index;

    header = (Elf_Ehdr *) data;
    CheckBounds(data, data_size, header, sizeof(*header));
    assert(memcmp(header->e_ident, ELFMAG, strlen(ELFMAG)) == 0);

    for (index = 0; index < header->e_shnum; index++) {
      Elf_Shdr *section = (Elf_Shdr *) (data + header->e_shoff +
					header->e_shentsize * index);
      CheckBounds(data, data_size, section, sizeof(*section));

      if ((section->sh_flags & SHF_EXECINSTR) != 0) {
	struct DecodeState state;
	state.fwait = FALSE;
	state.offset = data + section->sh_offset - section->sh_addr;
	CheckBounds(data, data_size,
		    data + section->sh_offset, section->sh_size);
	int rc = DecodeChunk(section->sh_addr,
			     data + section->sh_offset, section->sh_size,
			     ProcessInstruction, ProcessError, &state);
	if (rc != 0) {
	  return rc;
	} else if (state.fwait) {
	  while (state.fwait < data + section->sh_offset + section->sh_size) {
	    printf("%8x:\t                   \tfwait\n",
						   state.fwait++ - state.offset);
	  }
	}
      }
    }
  }
  return 0;
}

int main(int argc, char **argv) {
  int index, initial_index = 1, repeat_count = 1;
  if (argc == 1) {
    printf("%s: no input files\n", argv[0]);
  }
  if (!strcmp(argv[1],"--repeat"))
    repeat_count = atoi(argv[2]),
    initial_index += 2;
  for (index = initial_index; index < argc; index++) {
    const char *filename = argv[index];
    int rc = DecodeFile(filename, repeat_count);
    if (rc != 0) {
      printf("file '%s' can not be fully decoded\n", filename);
      return 1;
    }
  }
  return 0;
}
