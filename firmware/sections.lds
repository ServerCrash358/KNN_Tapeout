ENTRY(_start)

MEMORY {
  mem : ORIGIN = 0x00000000, LENGTH = 4096K
}

SECTIONS
{
  .text : {
    *(.text*)
    _etext = .;
  } > mem

  . = ALIGN(4);

  .data : {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > mem
  
  . = ALIGN(4);

  .others : {
    *(*)
  } > mem

  . = ALIGN(4);
  _end = .;
}

/* Symbol definitions outside of SECTIONS block */
PROVIDE(_stack_top = ORIGIN(mem) + LENGTH(mem));
PROVIDE(_data_load_start = _data_start);


