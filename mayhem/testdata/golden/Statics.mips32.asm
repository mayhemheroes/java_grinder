  ram_start equ 0x0
  ram_end equ 0x0
  virtual_address equ 0x0
  physical_address equ 0x0
  voffset equ (virtual_address - physical_address)
  integer equ ram_start+0
  short_integer equ ram_start+4
  byte_integer equ ram_start+8
  byte_integer_neg equ ram_start+12
.org 0x0
start:
  li $s0, _constant_pool + voffset  ; $s0 points to constant numbers
  li $s1, ram_start       ; $s1 points to statics
  li $sp, ram_end+1
  ;; Set up heap and static initializers
  li $gp, ram_start+16
  li $t8, 0x0032
  sw $t8, 0x0000($s1) ; static integer
  li $t8, 0x0019
  sw $t8, 0x0004($s1) ; static short_integer
  li $t8, 0x0001
  sw $t8, 0x0008($s1) ; static byte_integer
  li $t8, 0xffffffce
  sw $t8, 0x000c($s1) ; static byte_integer_neg

main:
  ; main(local_count=1, max_stack=1, param_count=1)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -8
  ; push_int(20)
  lw $t0, 0x0000($s0)
  ; put_static(short_integer, 1)
  sw $t0, 4($s1)
  ; invoke_static_method() name=get_number params=0 is_void=0
  addiu $sp, $sp, -8
  sw $ra, 4($sp)
  sw $fp, 0($sp)
  jal get_number
  nop ; Delay slot
  lw $ra, 4($sp)
  lw $fp, 0($sp)
  addiu $sp, $sp, 8
  move $t0, $v0
  ; pop()
  addiu $sp, $sp, 8
  jr $ra
  nop ; Delay slot

get_number:
  ; get_number(local_count=0, max_stack=2, param_count=0)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -4
  ; push_ref(integer)
  li $t8, integer
  lw $t0, ($t8)
  ; push_ref(short_integer)
  li $t8, short_integer
  lw $t1, ($t8)
  add $t0, $t0, $t1
  ; push_ref(byte_integer)
  li $t8, byte_integer
  lw $t1, ($t8)
  add $t0, $t0, $t1
  ; push_ref(byte_integer_neg)
  li $t8, byte_integer_neg
  lw $t1, ($t8)
  add $t0, $t0, $t1
  move $v0, $t0
  addiu $sp, $sp, 4
  jr $ra
  nop ; Delay slot

.align 32
_constant_pool:
  dc32 0x0014


