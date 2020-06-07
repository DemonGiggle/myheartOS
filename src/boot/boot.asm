extern kmain

global start

section .text
bits 32
start:
  ; Point the first entry of level 4 table to the
  ; first entry of level 3 table
  mov eax, p3_table                 ; e.g. eax = 0x00001000
  or eax, 0b11                      ; e.g. eax = 0x00001003
  ;      0x3 is `present bit + writable bit`
  mov dword [p4_table + 0], eax     ; e.g. p4_table[0] = eax

  ; Point the first entry of level 3 table to the
  ; first entry of level 2 table
  mov eax, p2_table
  or eax, 0b11
  mov dword [p3_table + 0], eax

  ; Point each page entry in level 2 to a page
  mov ecx, 0                        ; it's a counter
.map_p2_table:
  mov eax, 0x200000                 ; 2Mb, each page size
  mul ecx                           ; eax = eax * ecx
  or eax, 0b10000011                ; set `huge page bit`, `present bit` and
            ;     `writable bit`. If no huge bit, we
            ;     only have 4kb size for a page
  mov [p2_table + ecx * 8], eax     ; each pointer in p2_table is 8 bytes

  inc ecx
  cmp ecx, 512                      ; 512 (page entries) * 8 (bytes) = 4096 bytes
            ;     so the total virtual address space is 512 * 2Mb = 1G
  jne .map_p2_table

  ; What we will do to enable paging
  ;   - tell cpu where the page table is
  ;   - enable physical address extension (PAE)
  ;   - set `long mode bit`
  ;   - enable paging

  ; Tell cpu where the page table is
  mov eax, p4_table
  mov cr3, eax                      ; move page table address to cr3 (control register)

  ; Enable PAE
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; Set long mode bit
  mov ecx, 0xC0000080
  rdmsr                             ; read the `model specific register`
  or eax, 1 << 8
  wrmsr                             ; write the `model specific register`

  ; Enable paging
  mov eax, cr0
  or eax, 1 << 31
  or eax, 1 << 16
  mov cr0, eax

  ; Setup GDT
  lgdt [gdt64.pointer]

  ; update selector
  mov ax, gdt64.data
  mov ss, ax
  mov ds, ax
  mov es, ax

  ; jump to long mode (to modify cs segment)
  jmp gdt64.code:kmain

section .bss
align 4096

p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096

section .rodata
gdt64:
  dq 0

; set the `.code` label value to the current address minus
; the address of `gdt64`
;
.code: equ $ - gdt64
  ; 44th bit: `descriptor type`, set 1 for code and data segments
  ; 47th bit: `present`, set 1 if the entry is valid
  ; 41th bit: `read/write`, if it is code segment, 1 means it's readable
  ; 43th bit: `executable`, set 1 for code segment
    ; 53th bit: `64-bit`, set 1 if it's a 64-bit GDT
  dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)

.data: equ $ - gdt64
  dq (1<<44) | (1<<47) | (1<<41)

; the pointer contains the length and the address of GDT, the
; first part is the length (2 bytes); the second one is addr (8 bytes)
;
.pointer:
  dw .pointer - gdt64 - 1 ; the length of GDT
  dq gdt64
