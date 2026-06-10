  ram_start equ 0x0
  ram_end equ 0x0
  virtual_address equ 0x0
  physical_address equ 0x0
  voffset equ (virtual_address - physical_address)
  string equ ram_start+0
.org 0x0
start:
  li $s0, _constant_pool + voffset  ; $s0 points to constant numbers
  li $s1, ram_start       ; $s1 points to statics
  li $sp, ram_end+1
  ;; Set up heap and static initializers
  li $gp, ram_start+4
  ; static init
  li $t8, _string + voffset
  li $t9, string
  sw $t8, ($t9)

main:
  ; main(local_count=1, max_stack=1, param_count=1)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -8
  ; invoke_static_method() name=isNotNull params=0 is_void=0
  addiu $sp, $sp, -8
  sw $ra, 4($sp)
  sw $fp, 0($sp)
  jal isNotNull
  nop ; Delay slot
  lw $ra, 4($sp)
  lw $fp, 0($sp)
  addiu $sp, $sp, 8
  move $t0, $v0
  ; pop()
  addiu $sp, $sp, 8
  jr $ra
  nop ; Delay slot

isNotNull:
  ; isNotNull(local_count=0, max_stack=1, param_count=0)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -4
  ; get_static(string, 0)
  lw $t0, 0($s1)
  ; ternary 0 (0) ? 0 : 1
  ; true condition is in delay slot
  move $t8, $0
  beq $t0, $t8, ternary_0
  move $t0, $0
  lw $t0, 0x0000($s0)
ternary_0:
isNotNull_11:
  move $v0, $t0
  addiu $sp, $sp, 4
  jr $ra
  nop ; Delay slot

.align 32
  dc32 5
_string:
  db "hello"
.align 16

.align 32
_constant_pool:
  dc32 0x0001


