GLOBAL INICIO_PAGE_DIRECTORY
GLOBAL INICIO_PAGE_TABLE_RAM_000
GLOBAL INICIO_PAGE_TABLE_RAM_001
GLOBAL INICIO_PAGE_TABLE_RAM_002
GLOBAL INICIO_PAGE_TABLE_RAM_003
GLOBAL INICIO_PAGE_TABLE_RAM_004
GLOBAL INICIO_PAGE_TABLE_RAM_005
GLOBAL INICIO_PAGE_TABLE_RAM_006
GLOBAL INICIO_PAGE_TABLE_RAM_007
GLOBAL INICIO_PAGE_TABLE_RAM_008
GLOBAL INICIO_PAGE_TABLE_PILA
GLOBAL INICIO_PAGE_TABLE_ROM
GLOBAL SIZE_PAGINATION_STRUCTURE

section .bss
INICIO_PAGINATION_STRUCTURE:
INICIO_PAGE_DIRECTORY resb 4096
INICIO_PAGE_TABLE_RAM_000 resb 4096
INICIO_PAGE_TABLE_RAM_001 resb 4096
INICIO_PAGE_TABLE_RAM_002 resb 4096
INICIO_PAGE_TABLE_RAM_003 resb 4096
INICIO_PAGE_TABLE_RAM_004 resb 4096
INICIO_PAGE_TABLE_RAM_005 resb 4096
INICIO_PAGE_TABLE_RAM_006 resb 4096
INICIO_PAGE_TABLE_RAM_007 resb 4096
INICIO_PAGE_TABLE_RAM_008 resb 4096
INICIO_PAGE_TABLE_PILA resb 4096
INICIO_PAGE_TABLE_ROM resb 4096
