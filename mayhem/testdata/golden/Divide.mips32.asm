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
  ; push_int(27000)
  lw $t0, 0x0000($s0)
  ; push_int(400)
  lw $t1, 0x0004($s0)
  ; invoke_static_method() name=div_nums_II params=2 is_void=0
  addiu $sp, $sp, -8
  sw $ra, 4($sp)
  sw $fp, 0($sp)
  sw $t0, -4($sp)
  sw $t1, -8($sp)
  jal div_nums_II
  nop ; Delay slot
  lw $ra, 4($sp)
  lw $fp, 0($sp)
  addiu $sp, $sp, 8
  move $t0, $v0
  ; pop()
  addiu $sp, $sp, 8
  jr $ra
  nop ; Delay slot

div_nums_II:
  ; div_nums_II(local_count=2, max_stack=2, param_count=2)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -12
  lw $t0, 0($fp) ; local_0
  lw $t1, -4($fp) ; local_1
  div $t0, $t1
  nop
  nop
  mflo $t0
  move $v0, $t0
  addiu $sp, $sp, 12
  jr $ra
  nop ; Delay slot

.align 32
_constant_pool:
  dc32 0x6978, 0x0190


