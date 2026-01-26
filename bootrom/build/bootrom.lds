ENTRY(_start)
MEMORY {
  bootrom : ORIGIN = 0x00000000, LENGTH = 16384
}
SECTIONS
{
  .text : {
    *(.text*)
    _etext = .;
  } > bootrom
  . = ALIGN(4);
  .data : {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > bootrom
  . = ALIGN(4);
  .rodata : {
    *(.rodata*)
  } > bootrom
  . = ALIGN(4);
  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > bootrom
  . = ALIGN(4);
  _end = .;
}
PROVIDE(_stack_top = ORIGIN(bootrom) + LENGTH(bootrom));
PROVIDE(_data_load_start = _data_start);
