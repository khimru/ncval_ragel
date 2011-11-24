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

void ProcessInstruction(uint8_t *begin, uint8_t *end,
			struct instruction *instruction, void *userdata) {
  uint8_t *p;
  char delimeter = ' ';
  int print_rip = FALSE;
  int rex_bits = 0;
  int maybe_rex_bits = 0;
  int show_name_suffix = FALSE;
#define print_name(x) (printf((x)), shown_name += strlen((x)))
  int shown_name = 0;
  int i;

  printf("%8x:\t", begin - (uint8_t *)userdata);
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
      if ((instruction->operands[i].name == REG_IMM) ||
	  (instruction->operands[i].name == REG_RM) ||
	  (instruction->operands[i].name == REG_PORT_DX) ||
	  (instruction->operands[i].name == REG_ES_RDI) ||
	  (instruction->operands[i].name == REG_DS_RSI)) {
	if (show_name_suffix) {
	  switch (instruction->operands[i].size) {
	    case OperandSize8bit: show_name_suffix = 'b'; break;
	    case OperandSize16bit: show_name_suffix = 'w'; break;
	    case OperandSize32bit: show_name_suffix = 'l'; break;
	    case OperandSize64bit: show_name_suffix = 'q'; break;
	    default: assert(FALSE);
	  }
	}
      } else {
	show_name_suffix = FALSE;
      }
      if ((instruction->operands[i].name >= REG_R8) &&
	  (instruction->operands[i].name <= REG_R15)) {
	rex_bits++;
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
  if (instruction->prefix.rep) {
    print_name("rep ");
  }
  if (instruction->prefix.repe) {
    print_name("repe ");
  }
  if (instruction->prefix.repne) {
    print_name("repne ");
  }
  if ((!strcmp(instruction->name, "ins")) ||
      (!strcmp(instruction->name, "outs"))) {
    /* rex.W is ignored by in/out commands.  */
    if (instruction->prefix.rex == 0x48) {
      print_name("rex.W ");
    }
  } else if (!strcmp(instruction->name, "push")) {
    /* objdump always shows "6a 01" as "pushq $1", "66 68 01 00" as
       "pushw $1" yet "68 01 00" as "pushq $1" again.  This makes no
       sense whatsoever so we'll just hack around here to make sure
       we produce objdump-compatible output.  */
    if ((show_name_suffix == 'b') || (show_name_suffix == 'l')) {
      show_name_suffix = 'q';
    }
    /* rex.W is ignored by push command.  */
    if (instruction->prefix.rex == 0x48) {
      print_name("rex.W ");
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
#undef print_name
  printf("%s", instruction->name);
  shown_name += strlen(instruction->name);
  if (show_name_suffix) {
    printf("%c", show_name_suffix);
    shown_name++;
  }
  while (shown_name < 6) {
    printf(" ");
    shown_name++;
  }
  for (i=instruction->operands_count-1;i>=0;i--) {
    printf("%c", delimeter);
    switch (instruction->operands[i].name) {
      case REG_RAX: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%al"); break;
	case OperandSize16bit: printf("%%ax"); break;
	case OperandSize32bit: printf("%%eax"); break;
	case OperandSize64bit: printf("%%rax"); break;
	case OperandSizeST: printf("%%st(0)"); break;
	case OperandSizeXMM: printf("%%xmm0"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RCX: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%cl"); break;
	case OperandSize16bit: printf("%%cx"); break;
	case OperandSize32bit: printf("%%ecx"); break;
	case OperandSize64bit: printf("%%rcx"); break;
	case OperandSizeST: printf("%%st(1)"); break;
	case OperandSizeXMM: printf("%%xmm1"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RDX: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%dl"); break;
	case OperandSize16bit: printf("%%dx"); break;
	case OperandSize32bit: printf("%%edx"); break;
	case OperandSize64bit: printf("%%rdx"); break;
	case OperandSizeST: printf("%%st(2)"); break;
	case OperandSizeXMM: printf("%%xmm2"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RBX: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%bl"); break;
	case OperandSize16bit: printf("%%bx"); break;
	case OperandSize32bit: printf("%%ebx"); break;
	case OperandSize64bit: printf("%%rbx"); break;
	case OperandSizeST: printf("%%st(3)"); break;
	case OperandSizeXMM: printf("%%xmm3"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RSP: switch (instruction->operands[i].size) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%spl");
	  else
	    printf("%%ah");
	  break;
	case OperandSize16bit: printf("%%sp"); break;
	case OperandSize32bit: printf("%%esp"); break;
	case OperandSize64bit: printf("%%rsp"); break;
	case OperandSizeST: printf("%%st(4)"); break;
	case OperandSizeXMM: printf("%%xmm4"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RBP: switch (instruction->operands[i].size) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%bpl");
	  else
	    printf("%%ch");
	  break;
	case OperandSize16bit: printf("%%bp"); break;
	case OperandSize32bit: printf("%%ebp"); break;
	case OperandSize64bit: printf("%%rbp"); break;
	case OperandSizeST: printf("%%st(5)"); break;
	case OperandSizeXMM: printf("%%xmm5"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RSI: switch (instruction->operands[i].size) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%sil");
	  else
	    printf("%%dh");
	  break;
	case OperandSize16bit: printf("%%si"); break;
	case OperandSize32bit: printf("%%esi"); break;
	case OperandSize64bit: printf("%%rsi"); break;
	case OperandSizeST: printf("%%st(6)"); break;
	case OperandSizeXMM: printf("%%xmm6"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RDI: switch (instruction->operands[i].size) {
	case OperandSize8bit: if (instruction->prefix.rex)
	    printf("%%dil");
	  else
	    printf("%%bh");
	  break;
	case OperandSize16bit: printf("%%di"); break;
	case OperandSize32bit: printf("%%edi"); break;
	case OperandSize64bit: printf("%%rdi"); break;
	case OperandSizeST: printf("%%st(7)"); break;
	case OperandSizeXMM: printf("%%xmm7"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R8: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r8b"); break;
	case OperandSize16bit: printf("%%r8w"); break;
	case OperandSize32bit: printf("%%r8d"); break;
	case OperandSize64bit: printf("%%r8"); break;
	case OperandSizeXMM: printf("%%xmm8"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R9: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r9b"); break;
	case OperandSize16bit: printf("%%r9w"); break;
	case OperandSize32bit: printf("%%r9d"); break;
	case OperandSize64bit: printf("%%r9"); break;
	case OperandSizeXMM: printf("%%xmm9"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R10: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r10b"); break;
	case OperandSize16bit: printf("%%r10w"); break;
	case OperandSize32bit: printf("%%r10d"); break;
	case OperandSize64bit: printf("%%r10"); break;
	case OperandSizeXMM: printf("%%xmm10"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R11: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r11b"); break;
	case OperandSize16bit: printf("%%r11w"); break;
	case OperandSize32bit: printf("%%r11d"); break;
	case OperandSize64bit: printf("%%r11"); break;
	case OperandSizeXMM: printf("%%xmm11"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R12: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r12b"); break;
	case OperandSize16bit: printf("%%r12w"); break;
	case OperandSize32bit: printf("%%r12d"); break;
	case OperandSize64bit: printf("%%r12"); break;
	case OperandSizeXMM: printf("%%xmm12"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R13: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r13b"); break;
	case OperandSize16bit: printf("%%r13w"); break;
	case OperandSize32bit: printf("%%r13d"); break;
	case OperandSize64bit: printf("%%r13"); break;
	case OperandSizeXMM: printf("%%xmm13"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R14: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r14b"); break;
	case OperandSize16bit: printf("%%r14w"); break;
	case OperandSize32bit: printf("%%r14d"); break;
	case OperandSize64bit: printf("%%r14"); break;
	case OperandSizeXMM: printf("%%xmm14"); break;
	default: assert(FALSE);
      }
      break;
      case REG_R15: switch (instruction->operands[i].size) {
	case OperandSize8bit: printf("%%r15b"); break;
	case OperandSize16bit: printf("%%r15w"); break;
	case OperandSize32bit: printf("%%r15d"); break;
	case OperandSize64bit: printf("%%r15"); break;
	case OperandSizeXMM: printf("%%xmm15"); break;
	default: assert(FALSE);
      }
      break;
      case REG_RM: {
	if (instruction->rm.offset) {
	  printf("0x%x",instruction->rm.offset);
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
	printf("$0x%llx",instruction->imm);
	break;
      }
      case REG_PORT_DX: printf("(%%dx)"); break;
      case REG_ES_RDI: printf("%%es:(%%rdi)"); break;
      case REG_DS_RSI: printf("%%ds:(%%rsi)"); break;
      default: assert(FALSE);
    }
    delimeter = ',';
  }
  if (print_rip) {
    printf("        # 0x%8x",
			    end + instruction->rm.offset - (uint8_t *)userdata);
  }
  printf("\n");
  begin += 7;
  while (begin < end) {
    printf("%8x:\t", begin - (uint8_t *)userdata);
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

void ProcessError (uint8_t *ptr, void *userdata) {
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
	CheckBounds(data, data_size,
		    data + section->sh_offset, section->sh_size);
	int rc = DecodeChunk(section->sh_addr,
			     data + section->sh_offset, section->sh_size,
			     ProcessInstruction, ProcessError,
			     data + section->sh_offset - section->sh_addr);
	if (rc != 0) {
	  return rc;
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
