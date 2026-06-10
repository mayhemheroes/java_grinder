  ram_start equ 0x0
  ram_end equ 0x0
  virtual_address equ 0x0
  physical_address equ 0x0
  voffset equ (virtual_address - physical_address)
.org 0x0
start:
  li $s0, _constant_pool + voffset  ; $s0 points to constant numbers
  li $s1, ram_start       ; $s1 points to statics
  li $sp, ram_end+1
  ;; Set up heap and static initializers
  li $gp, ram_start+0

main:
  ; main(local_count=1, max_stack=2, param_count=1)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -8
  ; push_int(3)
  lw $t0, 0x0000($s0)
  ; push_int(2)
  lw $t1, 0x0004($s0)
  ; invoke_static_method() name=addIs5_II params=2 is_void=0
  addiu $sp, $sp, -8
  sw $ra, 4($sp)
  sw $fp, 0($sp)
  sw $t0, -4($sp)
  sw $t1, -8($sp)
  jal addIs5_II
  nop ; Delay slot
  lw $ra, 4($sp)
  lw $fp, 0($sp)
  addiu $sp, $sp, 8
  move $t0, $v0
  ; pop()
  addiu $sp, $sp, 8
  jr $ra
  nop ; Delay slot

addIs5_II:
  ; addIs5_II(local_count=2, max_stack=2, param_count=2)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -12
  lw $t0, 0($fp) ; local_0
  lw $t1, -4($fp) ; local_1
  add $t0, $t0, $t1
  ; ternary 1 (5) ? 0 : 1
  ; true condition is in delay slot
  lw $t8, 0x0008($s0)
  bne $t0, $t8, ternary_0
  move $t0, $0
  lw $t0, 0x000c($s0)
ternary_0:
addIs5_II_12:
  move $v0, $t0
  addiu $sp, $sp, 12
  jr $ra
  nop ; Delay slot

.align 32
_constant_pool:
  dc32 0x0003, 0x0002, 0x0005, 0x0001


