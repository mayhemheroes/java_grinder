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
  ; main(local_count=1, max_stack=1, param_count=1)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -8
  ; invoke_static_method() name=loop_down params=0 is_void=0
  addiu $sp, $sp, -8
  sw $ra, 4($sp)
  sw $fp, 0($sp)
  jal loop_down
  nop ; Delay slot
  lw $ra, 4($sp)
  lw $fp, 0($sp)
  addiu $sp, $sp, 8
  move $t0, $v0
  ; pop()
  addiu $sp, $sp, 8
  jr $ra
  nop ; Delay slot

loop_up:
  ; loop_up(local_count=2, max_stack=2, param_count=0)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -12
  ; push_int(0)
  move $t0, $0
  sw $t0, 0($fp) ; local_0
  ; push_int(0)
  move $t0, $0
  sw $t0, -4($fp) ; local_1
loop_up_4:
  lw $t0, -4($fp) ; local_1
  ; push_int(640)
  lw $t1, 0x0000($s0)
  ; jump_cond_integer(loop_up_20, 5, 4)
  subu $t0, $t0, $t1
  bgez $t0, loop_up_20
  nop
  ; inc_integer(local_0,1)
  lw $t8, 0($fp)
  addiu $t8, $t8, 1
  sw $t8, 0($fp)
  ; inc_integer(local_1,1)
  lw $t8, -4($fp)
  addiu $t8, $t8, 1
  sw $t8, -4($fp)
  b loop_up_4
  nop ; Delay slot
loop_up_20:
  lw $t0, 0($fp) ; local_0
  move $v0, $t0
  addiu $sp, $sp, 12
  jr $ra
  nop ; Delay slot

loop_down:
  ; loop_down(local_count=2, max_stack=1, param_count=0)
  addiu $fp, $sp, -4
  addiu $sp, $sp, -12
  ; push_int(0)
  move $t0, $0
  sw $t0, 0($fp) ; local_0
  ; push_int(640)
  lw $t0, 0x0000($s0)
  sw $t0, -4($fp) ; local_1
loop_down_6:
  lw $t0, -4($fp) ; local_1
  ; jump_cond(loop_down_19, 3, 4)
  blez $t0, loop_down_19
  nop
  ; inc_integer(local_0,1)
  lw $t8, 0($fp)
  addiu $t8, $t8, 1
  sw $t8, 0($fp)
  ; inc_integer(local_1,-1)
  lw $t8, -4($fp)
  addiu $t8, $t8, -1
  sw $t8, -4($fp)
  b loop_down_6
  nop ; Delay slot
loop_down_19:
  lw $t0, 0($fp) ; local_0
  move $v0, $t0
  addiu $sp, $sp, 12
  jr $ra
  nop ; Delay slot

.align 32
_constant_pool:
  dc32 0x0280


