#include "defines.h"
#include "elf.h"
#include "lib.h"

struct elf_header {
  struct {
    unsigned char magic[4];
    unsigned char class;
    unsigned char format;
    unsigned char version;
    unsigned char abi;
    unsigned char abi_version;
    unsigned char reserve[7];
  } id;
  short type;
  short arch;
  long version;
  long entry_point;
  long program_header_offset;
  long section_header_offset;
  long flags;
  short header_size;
  short program_header_size;
  short program_header_num;
  short section_header_size;
  short section_header_num;
  short section_name_index;
};

struct elf_program_header {
  long type;
  long offset;
  long virtual_addr;
  long physical_addr;
  long file_size;
  long memory_size;
  long flags;
  long align;
};

/* ELF�إå��Υ����å� */
static int elf_check(struct elf_header *header)
{
  if (memcmp(header->id.magic, "\x7f" "ELF", 4))
    return -1;

  if (header->id.class   != 1) return -1; /* ELF32 */
  if (header->id.format  != 2) return -1; /* Big endian */
  if (header->id.version != 1) return -1; /* version 1 */
  if (header->type       != 2) return -1; /* Executable file */
  if (header->version    != 1) return -1; /* version 1 */

  /* SiperH */
  if ((header->arch != 42)) return -1;

  return 0;
}

/* ��������ñ�̤ǤΥ��� */
static int elf_load_program(struct elf_header *header)
{
  int i;
  struct elf_program_header *phdr;

  for (i = 0; i < header->program_header_num; i++) {
    /* �ץ���ࡦ�إå������ */
    phdr = (struct elf_program_header *)
      ((char *)header + header->program_header_offset +
       header->program_header_size * i);

    if (phdr->type != 1) /* ���ɲ�ǽ�ʥ������Ȥ��� */
      continue;

    memcpy((char *)phdr->physical_addr, (char *)header + phdr->offset,
	   phdr->file_size);
    memset((char *)phdr->physical_addr + phdr->file_size, 0,
	   phdr->memory_size - phdr->file_size);
  }

  return 0;
}

char *elf_load(char *buf)
{
  struct elf_header *header = (struct elf_header *)buf;

  if (elf_check(header) < 0) /* ELF�إå��Υ����å� */
    return NULL;

  if (elf_load_program(header) < 0) /* ��������ñ�̤ǤΥ��� */
    return NULL;

  return (char *)header->entry_point;
}
