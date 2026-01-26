ENTRY(_start)
MEMORY {
  ram : ORIGIN = 0x00004000, LENGTH = 16384
}
SECTIONS
{
  .text : {
    *(.text*)
    _etext = .;
  } > ram
  . = ALIGN(4);
  .data : {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > ram
  . = ALIGN(4);
  .rodata : {
    *(.rodata*)
  } > ram
  . = ALIGN(4);
  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > ram
  . = ALIGN(4);
  _end = .;
}
PROVIDE(_stack_top = ORIGIN(ram) + LENGTH(ram));
PROVIDE(_data_load_start = _data_start);
