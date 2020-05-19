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


  ; Hello, world!
  mov word [0xb8000], 0x0248  ; H
  mov word [0xb8002], 0x0265  ; e
  mov word [0xb8004], 0x026c  ; l
  mov word [0xb8006], 0x026c  ; l
  mov word [0xb8008], 0x026f  ; o
  mov word [0xb800a], 0x022c  ; ,
  mov word [0xb800c], 0x0220  ;
  mov word [0xb800e], 0x4277  ; w
  mov word [0xb8010], 0x026f  ; o
  mov word [0xb8012], 0x0272  ; r
  mov word [0xb8014], 0x026c  ; l
  mov word [0xb8016], 0x0264  ; d
  mov word [0xb8018], 0x0221  ; !
  hlt

section .bss
align 4096

p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
