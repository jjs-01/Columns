.data
ADDR_DSPL: .word 0x10008000
colors: .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xf28c28, 0xff00ff, 0xffffff   # red, green, blue, yellow, orange, magenta, white
keyboardaddress: .word 0xffff0000
game_board: .space 360
# time count to count every game_loop up to a certain gravity time, number of blocks placed placements, difficulty (0 = easy, 1 = medium, 3 = hard)
game_info: .word 0, 0, 0


##############################################################################
# Julia Sinclair 1011047564 and Mei Walters 1011183167
##############################################################################
######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8g
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################
.text
lw $s0, ADDR_DSPL           # $s0 = base address for display
la $s1, colors              # $s1 = address for the first color
lw $s2, keyboardaddress     # $s2 = address for the keyboard
la $s3, game_board          # $s3 = address for game_board
la $s5, game_info           # $s5 = info for the game (which fields represent which above)

# initialize the drawing of white game area rectangle
addi $a0, $zero, 1          # set the X coordinate
addi $a1, $zero, 1          # set the Y coordinate
addi $a2, $zero, 8          # set the width of the rectangle (6 + 2)
addi $a3, $zero, 17         # set the height of the rectangle (15 + 2)
lw $t9, 24($s1)             # loads white from colors
jal rect_draw               # calls rectangle drawing function.

# initialize the drawing of black game area rectangle
addi $a0, $zero, 2          # set the X coordinate
addi $a1, $zero, 2          # set the Y coordinate
addi $a2, $zero, 6          # set the width of the rectangle (6)
addi $a3, $zero, 15         # set the height of the rectangle (15)
add $t9, $zero, $zero       # set the colour of the rectangle to be black
jal rect_draw               # calls rectangle drawing function.

# initialize the drawing of the column
draw_col:
jal rand_column
li $s4, 56           # $s4 = offset for the bottom of the column being moved on game_board

game_loop:
lw $s2, keyboardaddress 
lw $t8, 0($s2)              # load first word from keyboard

bne $t8, 1, redraw  # if first word 1 key is not pressed
j keyboard_input

collision_detection:
addi $a0, $s4, -48            # make the argument for $a0 point to top of column just placed
jal three_in_row
jal three_in_col
jal three_in_diagonal

addi $a0, $a0, 24          # make the argument for $a0 point to middle of column just placed
jal three_in_row
jal three_in_col
jal three_in_diagonal

addi $a0, $a0, 24          # make the argument for $a0 point to bottom  of column just placed
jal three_in_row
jal three_in_col
jal three_in_diagonal

j final_state               # if it reaches here, all of the collisions should be sorted out

check_collisions:
jal redraw_game_board
li $v0, 32          # pauses to look more natural when deleting the next rows
li $a0, 250
syscall

li $t2, 0        # make t2 the pixel we want to look at
li $t9, 360
check_collisions_loop:
beq $t2, $t9, final_state       # at end of array, therefore no more collisions, draw a new column

addi $a0, $t2, 0          # make the argument for $a0 point to the pixel focused on
jal three_in_row          # check for any new collisions
jal three_in_col
jal three_in_diagonal

addi $t2, $t2, 4
j check_collisions_loop

final_state:
addi $t2, $s3, 0
addi $t3, $s3, 24

check_top_row:
addi $t2, $t2, 4
beq $t2, $t3, draw_col_at_top
lw $t9, 0($t2)
bne $t9, $zero, respond_to_Q        # if the row is not black, then the game is lost
j check_top_row

draw_col_at_top:
jal rand_column
li $s4, 56
sw $zero, 0($s5)        # resets clock tick 

redraw:
# checks whether to add gravity
lw $t1, 0($s5)
addi $t1, $t1, 1
sw $t1, 0($s5)        # save incremented value
li $t2, 64
divu $t1, $t2
mfhi $t6
bne $t6, $zero, refresh_board
sw $zero, 0($s5)        # resets clock tick 
jal gravity_to_column

refresh_board:
jal redraw_game_board

sleep:
li $v0, 32
li $a0, 16
syscall

j game_loop

##############################################################################
# Code for responding to keyboard input
##############################################################################
keyboard_input:
lw $a0, 4 ($s2) # Load second word from keyboard
beq $a0, 0x71, respond_to_Q # check if the key q was pressed
beq $a0, 0x61, respond_to_A # check if the key a was pressed
beq $a0, 0x73, respond_to_S # check if the key s was pressed
beq $a0, 0x64, respond_to_D # check if the key d was pressed
beq $a0, 0x77, respond_to_W # check if the key w was pressed

jr $ra

##############################################################################
# Code for responding to key press Q
##############################################################################
respond_to_Q:
li $v0, 10                  # terminate the program gracefully
syscall

##############################################################################
# Code for responding to key press A
##############################################################################
respond_to_A:
li $t6, 24                      # load $t6 to be 24
divu $s4, $t6                   # divide the offset by 24
mfhi $t6                        # store remainder in $t6

beq $t6, $zero, END_A           # if remainder is zero, end of column, don't move

addi $t6, $s4, -4           # load into $t6 the value one left of s4
add $t6, $s3, $t6           # get the value of s3 at t6
lw $t6, 0($t6)              # load colour at t6 into t6

bne $t6, $zero, END_A       # if colour isn't black, stop moving

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, -4          # set the amount to move the column by (4 left)
addi $a1, $s4, 0
jal redraw_column

addi $s4, $s4, -4          # increment to right

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

END_A: 
j redraw

##############################################################################
# Code for responding to key press S
##############################################################################
respond_to_S:
add $t6, $s3, $s4           # t6 is the address of bottom of col
addi $t6, $t6, 24           # value one row below t6
lw $t6, 0($t6)              # load colour at t6 into t6

MOVE_COL_DOWN_ENTIRELY:
addi $t0, $s4, -332         # trying to determine if the value is at the final column
bgtz $t0, END_S
bne $t6, $zero, END_S       # move until the next colour is not black (i.e. edge or another placed column)

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, 24         # set the amount to move the column by (down 1 row)
addi $a1, $s4, 0
jal redraw_column

addi $s4, $s4, 24           # increment to next column value
add $t6, $s3, $s4           # t6 is the address of bottom of next col
addi $t6, $t6, 24           # t6 is the address of bottom of next col
lw $t6, 0($t6)              # load colour at t6 into t6

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

jal redraw_game_board
li $v0, 32                  # dropping animation
li $a0, 8          
syscall

j MOVE_COL_DOWN_ENTIRELY

END_S:
j collision_detection


##############################################################################
# Code for responding to key press D
##############################################################################
respond_to_D:
li $t6, 24                      # load $t6 to be 24
addi $t4, $s4, -20              # subtract 20 from offset (to help check if right end of row)
divu $t4, $t6                   # divide the offset by 24
mfhi $t6                        # store remainder in $t6

beq $t6, $zero, END_A           # if remainder is zero, end of column, don't move

addi $t6, $s4, 4            # load into $t6 the value one right of s4
add $t6, $s3, $t6           # get the value of s3 at t6
lw $t6, 0($t6)              # load colour at t6 into t6

bne $t6, $zero, END_D       # move until the next colour is not black (i.e. edge or another placed column)

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, 4          # set the amount to move the column by (4 right)
addi $a1, $s4, 0
jal redraw_column

addi $s4, $s4, 4          # increment right

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

END_D:
j redraw

##############################################################################
# Code for responding to key press W
##############################################################################
respond_to_W:

add $t6, $s3, $s4      # make $t6 point to the address of bottom of row

lw $t9, 0($t6)          # get colour from bottom of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
addi $t6, $t6, -24     # go to next row in column 

lw $t9, 0($t6)          # get colour from middle of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
addi $t6, $t6, -24     # go to next row in column 

lw $t9, 0($t6)          # get colour from top of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour

# shift the colours
addi $t6, $t6, 48          # go to bottom column

lw $t9, 0($sp)              # pop top colour off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($t6)              # draws top colour at bottom column
addi $t6, $t6, -48         # go to top column

lw $t9, 0($sp)              # pop middle colour off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($t6)              # draws middle colour at top column
addi $t6, $t6, 24          # go to middle column

lw $t9, 0($sp)              # pop bottom colour off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($t6)              # draws bottom colour at middle column

addi $t6, $t6, 24          # go to bottom column
j redraw

##############################################################################
# Code for random color column
##############################################################################
# $s0 = location of the top-left corner of the bitmap
# $s1 = address of the first color
# $t2 = the current location to draw the random color pixel

rand_column:
addi $sp, $sp, -4           # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)              # push $ra to the stack for nested function
addi $t2, $s3, 8            # add the offset from game_board (for row 0, column 3 in the board) to $t2
addi $t4, $s3, 80           # calculate the postion of the last pixel in the column 
rand_column_loop:
jal rand_color              # call rand_color to get a random color in $v0
beq $t4, $t2, rand_column_loop_end # check if the current position is the end of the column, if so branch out of the loop
sw $v0, 0($t2)              # draw pixel of color $v0 to location $t2
addi $t2, $t2, 24           # Move to the next pixel in the column
j rand_column_loop          # Jump to the start of the loop
rand_column_loop_end:
lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
jr $ra

##############################################################################
# Code selecting a random color
##############################################################################
# $s0 = location of the top-left corner of the bitmap
# $s1 = address of the first color

rand_color:
# randomly generate an integer for one of the six colors
li $v0, 42
li $a0, 0                   # random integer gets stored in $a0
li $a1, 6                   # 0 to 6 exclusive
syscall                     # random integer stored in $a0

sll $t3, $a0, 2             # multiply index by 4 (word size)
add $t3, $t3, $s1           # color address = address of first color + offset
lw $v0, 0($t3)              # load color into return value $v0
jr $ra

##############################################################################
# Code for moving the column down by one
##############################################################################
# $s4 = offset of the bottom of the column

gravity_to_column:
add $t0, $s4, $s3      # get the pixel value of the colour
add $t0, $t0, 24      # get the pixel value of the colour
lw $t9, 0($t0)         # put colour of t0 into t9
bne $t9, $zero, check_collisions

addi $t0, $s4, -356         # trying to determine if the value is at the final column
bgtz $t0, draw_col_at_top

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store return

addi $a0, $zero, 24         # set the amount to move the column by (down 1 row)
addi $a1, $s4, 0
jal redraw_column

addi $s4, $s4, 24           # move s4 down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
jr $ra

##############################################################################
# Code for getting the colours from the current column and adding colours to stack
##############################################################################
# $t4 = colour of bottom pixel
# $t5 = colour of middle pixel
# $t7 = colour of top pixel
# $t9 = colour of current popped off pixel
# $a0 = new location to draw column at
# $a1 = offset location of bottom pixel of column

redraw_column:
add $a1, $s3, $a1       # make a1 point to the address of location of the bottom in the game_board array
lw $t4, 0($a1)          # get colour from bottom of col, store in t4
sw $zero, 0($a1)        # paint pixel black
addi $a1, $a1, -24     # go to next row in column 

lw $t5, 0($a1)          # get colour from middle of col, store in t5
sw $zero, 0($a1)        # paint pixel black
addi $a1, $a1, -24      # go to next row in column 

lw $t7, 0($a1)          # get colour from top of col, store in t7
sw $zero, 0($a1)        # paint pixel black

add $a1, $a1, $a0         # moves pixel by specified amount

# draw at new $s4 location
sw $t7, 0($a1)              # draws column pixel to the changed position
addi $a1, $a1, 24           # go to next column

sw $t5, 0($a1)              # draws column pixel to the left position
addi $a1, $a1, 24           # go to next column

sw $t4, 0($a1)              # draws column pixel to the left position

jr $ra 


##############################################################################
# Code for checking 3 in a row from pixel
##############################################################################
# $a0 = offset of the pixel we start from
# $t0 = location of the pixel we start from
# $t1 = location of one in the row
# $t3 = location of two in the row
# $t4 = colour of one in the row
# $t5 = colour of two in the row
# $t7 = colour at a0
# $t8 = checking value

three_in_row:
# store return to stack
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store return

add $t0, $s3, $a0       # get to the location of the pixel we start from
lw $t7, 0($t0)          # get colour of bottom of row

beq $t7, $zero, return_checking_row      # if t7 is black, do an early return

# two_left_order:
# check the t1, t2, a0 order
li $t8, 24
divu $a0, $t8               # see if at edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, two_right_order      # if t4 is at left end of board, go to the two right check

addi $t3, $a0, -4           # go one offset spot left
divu $t3, $t8               # see if at edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, one_left_one_right_order      # if t4 is one from left end of board, go to the one left one right check

# else:
addi $t1, $t0, -8           # go two offset spots left
lw $t4, 0($t1)               # add colour to t4

beq $t4, $zero, one_left_one_right_order      # if t4 is black, go to next case

addi $t3, $t0, -4           # go one spot left
lw $t5, 0($t3)               # add colour to t5

beq $t5, $zero, two_right_order      # if t5 is black, go to two right check

# this could possibly be the two_left order
bne $t4, $t5, one_left_one_right_order          # if t4 != t5, go to next case
bne $t7, $t4, one_left_one_right_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

one_left_one_right_order:

# check if at left end of board:
addi $t5, $a0, -20
divu $t5, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, return_checking_row      # if t4 is from left end of board, early return

divu $a0, $t8               # see if at edge of board
mfhi $t4                 # save remainder in t4
beq $t4, $zero, two_right_order      # if t4 is at left end of board, go to the one left one right check

addi $t1, $t0, -4           # go one spot left
lw $t4, 0($t1)               # add colour to t4

addi $t3, $t0, 4           # go one spot right
lw $t5, 0($t3)               # add colour to t5
beq $t5, $zero, return_checking_row      # if t5 is black, do an early return

bne $t4, $t5, two_right_order          # if t4 != t5, go to next case
bne $t7, $t4, two_right_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

two_right_order:
# check if one from left end of board:
addi $t1, $a0, 4           # go one spot left
addi $t5, $t1, -20
divu $t5, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, return_checking_row      # if t4 is one from left end of board, stop checking

addi $t5, $a0, -20
divu $t5, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, return_checking_row      # if t4 is at left end of board, stop checking

addi $t1, $t0, 4           # go one spot left
lw $t4, 0($t1)               # add colour to t4
beq $t4, $zero, return_checking_row      # if t4 is black, do an early return

addi $t3, $t0, 8           # go two spots left
lw $t5, 0($t3)           # add colour to t5
beq $t5, $zero, return_checking_row      # if t5 is black, do an early return

bne $t4, $t5, return_checking_row          # if t4 != t5, go to next case
bne $t7, $t4, return_checking_row          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

return_checking_row:
lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

jr $ra



##############################################################################
# Code for checking 3 in a col from pixel
##############################################################################
# $a0 = pixel offset we start from
# $t0 = pixel colour & address to check
# t1 = location of one in the column
# $t3 = location of two in the column
# $t4 = colour of one in the column
# $t5 = colour of two in the column
# $t7 = colour of a0
# $t8

three_in_col:
# store return to stack
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store return

add $t0, $s3, $a0       # get to the location of the pixel we start from
lw $t7, 0($t0)          # get colour of bottom of row

beq $t7, $zero, return_checking_row      # if t7 is black, do an early return

# check the t1, t2, a0 order
# two_down_order:
# check the t1, t2, a0 order
addi $t4, $a0, -356         # trying to determine if the value is at the final row
bgtz $t4, two_up_order      # if a0 bottom of board, check for two up columns

addi $t4, $a0, -332         # trying to determine if the value is at the second to final row
bgtz $t4, one_up_one_down_order      # if at second to final of board, check for one up one down columns

# else: two spots below available
addi $t1, $t0, 48           # go two spots down
lw $t4, 0($t1)               # add colour to t4
beq $t4, $zero, one_up_one_down_order      # if t4 is black, check next case

addi $t3, $t0, 24           # go one spot down
lw $t5, 0($t3)               # add colour to t5
beq $t5, $zero, two_up_order      # if t5 is black, check next case

bne $t4, $t5, one_up_one_down_order          # if t4 != t5, go to next case
bne $t7, $t4, one_up_one_down_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

one_up_one_down_order:
addi $t4, $a0, -24         # trying to determine if the value of a0 is at the top row
bltz $t4, return_checking_col      # if a0 at top of board, early return (since next case is two above)

addi $t4, $a0, -356         # trying to determine if the value is at the final row
bgtz $t4, two_up_order      # if a0 bottom of board, check for two up columns

addi $t1, $t0, -24           # go one spot up
lw $t4, 0($t1)              # add colour to t4
beq $t4, $zero, two_up_order      # if t4 is black, go next case

addi $t3, $t0, 24           # go one spot down
lw $t5, 0($t3)               # add colour to t5
beq $t5, $zero, two_up_order      # if t5 is black, go next case

bne $t4, $t5, two_up_order          # if t4 != t5, go to next case
bne $t7, $t4, two_up_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

two_up_order:
addi $t4, $a0, -24         # trying to determine if the value of a0 is at the top row
bltz $t4, return_checking_col      # if a0 at top of board, early return (since next case is two above)

addi $t4, $a0, -48         # trying to determine if the value of a0 is one below the top row
bltz $t4, return_checking_col      # if a0 at top of board, early return (since next case is two above)

addi $t1, $t0, -24           # go one spot up
lw $t4, 0($t1)               # add colour to t4
beq $t4, $zero, return_checking_col      # if t4 is black, do an early return

addi $t3, $t0, -48        # go two spots up
lw $t5, 0($t3)           # add colour to t5
beq $t5, $zero, return_checking_col      # if t5 is black, do an early return

bne $t4, $t5, return_checking_col          # if t4 != t5, go to next case
bne $t7, $t4, return_checking_col          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

return_checking_col:
lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

jr $ra




##############################################################################
# Code for checking 3 in a diagonal from pixel
##############################################################################
# $a0 = pixel we start from
# $t0 = pixel to check
# t1 = location of one in the column
# $t3 = location of two in the column
# $t4 = colour of one in the column
# $t5 = colour of two in the column
# $t7 = colour of a0
# $t8 = colour of white

three_in_diagonal:
# store return to stack
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store return

add $t0, $s3, $a0       # get to the location of the pixel we start from
lw $t7, 0($t0)          # get colour of bottom of row

beq $t7, $zero, return_checking_row      # if t7 is black, do an early return

# check the t1, t2, a0 order
# check if at left right edges, then if there's enough space at the top
li $t8, 24
divu $a0, $t8               # see if at edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, negative_two_down_order      # if t4 is at left end of board, go to the two right check

addi $t3, $a0, -4           # go one offset spot left
divu $t3, $t8               # see if at edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, negative_one_up_one_down_diagonal      # if t4 is one from left end of board, go to the one left one right check

addi $t4, $a0, -24         # trying to determine if the value of a0 is at the top row
bltz $t4, negative_two_down_order      # if a0 at top of board, next case

addi $t4, $a0, -48         # trying to determine if the value of a0 is one below the top row
bltz $t4, negative_one_up_one_down_diagonal      # if a0 at top of board, next case

# therefore t1, t3 are valid indices
addi $t1, $t0, -56           # go two spots up
lw $t4, 0($t1)               # add colour to t4

addi $t3, $t0, -28           # go one spot up
lw $t5, 0($t3)               # add colour to t5

bne $t4, $t5, negative_one_up_one_down_diagonal          # if t4 != t5, go to next case
bne $t7, $t4, negative_one_up_one_down_diagonal          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

negative_one_up_one_down_diagonal:
# check if at left right edges, then if there's enough space at the top
divu $a0, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, negative_two_down_order      # if t4 is at left end of board, go to the two right check

addi $t5, $a0, -20
divu $t5, $t8               # see if at right edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, pos_two_down_order      # if t4 is at right end of board, go to two down check

addi $t4, $a0, -24         # trying to determine if the value of a0 is at the top row
bltz $t4, negative_two_down_order      # if a0 at top of board, next case

addi $t4, $a0, -356         # trying to determine if the value is at the final row
bgtz $t4, pos_two_up_order      # if a0 bottom of board, check for two up columns

# else: valid indices
addi $t1, $t0, -28           # go one spot up
lw $t4, 0($t1)              # add colour to t4

addi $t3, $t0, 28           # go one spot down
lw $t5, 0($t3)               # add colour to t5

bne $t4, $t5, negative_two_down_order          # if t4 != t5, go to next case
bne $t7, $t4, negative_two_down_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

negative_two_down_order:
addi $t1, $a0, 4           # go one spot left
addi $t5, $t1, -20
divu $t5, $t8               # see if one from right edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, pos_up_down_order      # if t4 is one from left end of board, stop checking

addi $t5, $a0, -20
divu $t5, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, pos_two_down_order      # if t4 is at left end of board, stop checking

addi $t4, $a0, -356         # trying to determine if the value is at the final row
bgtz $t4, pos_two_up_order      # if a0 bottom of board, check for two up columns

addi $t4, $a0, -332         # trying to determine if the value is at the second to final row
bgtz $t4, pos_two_up_order      # if at second to final of board, check for one up one down columns

# now we can check valid indices
addi $t1, $t0, 28            # go one spot down
lw $t4, 0($t1)               # add colour to t4

addi $t3, $t0, 56        # go two spots down
lw $t5, 0($t3)           # add colour to t5

bne $t4, $t5, pos_two_up_order          # if t4 != t5, go to next case
bne $t7, $t4, pos_two_up_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

pos_two_up_order:
addi $t1, $a0, 4           # go one spot left
addi $t5, $t1, -20
divu $t5, $t8               # see if one from right edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, pos_up_down_order      # if t4 is one from left end of board, stop checking

addi $t5, $a0, -20
divu $t5, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, pos_two_down_order      # if t4 is at left end of board, stop checking

addi $t4, $a0, -24         # trying to determine if the value of a0 is at the top row
bltz $t4, pos_two_down_order      # if a0 at top of board, next case

addi $t4, $a0, -48         # trying to determine if the value of a0 is one below the top row
bltz $t4, pos_up_down_order      # if a0 at top of board, next case

addi $t1, $t0, -20           # go one spot up
lw $t4, 0($t1)               # add colour to t4

addi $t3, $t0, -40       # go two spots up
lw $t5, 0($t3)           # add colour to t5

bne $t4, $t5, pos_up_down_order          # if t4 != t5, go to next case
bne $t7, $t4, pos_up_down_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

pos_up_down_order:
# check if at left right edges, then if there's enough space at the top
divu $a0, $t8               # see if at left edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, return_checking_diagonal      # if t4 is at left end of board, return

addi $t5, $a0, -20
divu $t5, $t8               # see if at right edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, pos_two_down_order      # if t4 is at right end of board, go to two down check

addi $t4, $a0, -24         # trying to determine if the value of a0 is at the top row
bltz $t4, pos_two_down_order      # if a0 at top of board, next case

addi $t4, $a0, -356         # trying to determine if the value is at the final row
bgtz $t4, return_checking_diagonal      # if a0 bottom of board, early return

# else: valid indices
addi $t1, $t0, -20           # go one spot up
lw $t4, 0($t1)               # add colour to t4

addi $t3, $t0, 20        # go one spots down
lw $t5, 0($t3)           # add colour to t5

bne $t4, $t5, pos_two_down_order          # if t4 != t5, go to next case
bne $t7, $t4, pos_two_down_order          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

pos_two_down_order:
divu $a0, $t8               # see if at edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, return_checking_diagonal      # if t4 is at left end of board, go to the two right check

addi $t3, $a0, -4           # go one offset spot left
divu $t3, $t8               # see if at edge of board
mfhi $t4                    # save remainder in t4
beq $t4, $zero, return_checking_diagonal      # if t4 is one from left end of board, go to the one left one right check

addi $t4, $a0, -356         # trying to determine if the value is at the final row
bgtz $t4, return_checking_diagonal      # if a0 bottom of board, check for two up columns

addi $t4, $a0, -332         # trying to determine if the value is at the second to final row
bgtz $t4, return_checking_diagonal      # if at second to final of board, check for one up one down columns

addi $t1, $t0, 20           # go one spot up
lw $t4, 0($t1)               # add colour to t4

addi $t3, $t0, 40        # go two spots up
lw $t5, 0($t3)           # add colour to t5

bne $t4, $t5, return_checking_diagonal          # if t4 != t5, go to next case
bne $t7, $t4, return_checking_diagonal          # cond: t4 == t5, but t4 != t7, so go to next case

# paint each node black
sw $zero, 0($t0)
sw $zero, 0($t1)
sw $zero, 0($t3)

addi $a1, $t1, 0
jal move_down

addi $a1, $t3, 0
jal move_down

addi $a1, $t0, 0
jal move_down

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

j check_collisions          # check for any additional collisions created by new order on the game_board

return_checking_diagonal:
lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

jr $ra

##############################################################################
# Code for moving down a column
##############################################################################
# $a1 = position of pixel which was deleted
# $t2 = 
# $t6 =
# $t9 = colour of pixel

move_down:
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store return
sub $t2, $a1, $s3       # find offset

addi $t2, $t2, -24
bltz $t2, return_checking_row               # if t2 is in the top row, then this is not the pixel meant to move down the column

addi $t6, $a1, -24     # move to possible start of floating column with a1
lw $t9, 0($t6)          # get colour at t6
beq $t9, $zero, return_checking_col         # if the space above a1 is black, then this is not the pixel meant to move down the column

# find location of first black/white at the top of the column
find_top:
addi $t6, $t6, -24
addi $t2, $t2, -24
bltz $t2, move_down_columns      # if top row

lw $t9, 0($t6)
beq $t9, $zero, move_down_columns
j find_top

move_down_columns:
sub $t9, $a1, $s3       # find offset
addi $t9, $t9, -356     # find subtraction
bgtz $t9, return_move_down      # then we're at the end of the board, return
lw $t9, 0($a1)
bne $t9, $zero, return_move_down
addi $t2, $a1, -24         # move t2 to be the colour above empty space a1
lw $t9, 0($t2)              # store colour in t9
sw $t9, 0($a1)              # paint empty space with a1 colour

move_column_inner_loop:
sw $zero, 0($t2)            # paint empty space black
addi $t2, $t2, -24         # move t2 to be the colour above empty space
beq $t2, $t6, move_column_inner_loop_end
lw $t9, 0($t2)              # store colour in t9

addi $t2, $t2, 24         # move t2 to be the empty space
sw $t9, 0($t2)          # paint empty space with above colour

addi $t2, $t2, -24         # move t2 to next above space
j move_column_inner_loop

move_column_inner_loop_end:
addi $a1, $a1, 24
addi $t6, $t6, 24

j move_down_columns

return_move_down:
lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
jr $ra

##############################################################################
# Code for drawing the game_board
##############################################################################
# $t0 = index variable for drawing loop, the offset from start of game_board array
# $t1 = final value for the drawing loop
# $t2 = location of colour in the game_board
# $t3 = index variable for location being drawn to on the board
# $t4 = value to check to see if the location variable should go to next row
# $t9 = colour to write to board
# $s0 = address for the display
# $s3 = address for the game_board

redraw_game_board:
li $t0, 0            # make $t0 the offset from start of game_board
li $t1, 360          # make $t1 the final offset of game_board
add $t2, $s3, $t0       #address of the game_board
addi $t3, $s0, 264          # make $s2 the address of the first location in the display to write

drawing_board_loop:
li $t4, 24                      # set $t4 to 24 (may have been changed by end)
beq $t0, $t1, end_drawing_board_loop            # if we finish iterating through game_board

lw $t9, 0($t2)                 # store colour at the correct place in game_board to $t9
sw $t9, 0($t3)                  # paint colour on the board

addi $t0, $t0, 4                # increment offset from start of game_board by 4
add $t2, $s3, $t0                # increment address of game_board[offset]
addi $t3, $t3, 4                  # increment to next pixel in array

divu $t0, $t4                   # divide the offset by 24
mfhi $t4                        # store remainder in $t4
bne $t4, $zero, drawing_board_loop          # if not at edge (remainder not zero), continue loop
addi $t3, $t3, 104              # else: move display to appropriate location at the start of new loop
j drawing_board_loop


end_drawing_board_loop:
jr $ra

##############################################################################
# Code for drawing a rectangle
##############################################################################
# $s0 = location of the top-left corner of the bitmap
# $a0 = the X coordinate of the top left corner of the rectangle
# $a1 = the Y coordinate of the top left corner of the rectangle
# $a2 = the width of the rectangle
# $a3 = the height of the rectangle
# $t1 = the current index in the rectangle drawing loop

rect_draw:
add $t1, $zero, $zero       # Set a variable to count the current row in the rectangle
# start the rectangle line drawing code
rect_loop:
beq $t1, $a3, rect_loop_end # If we have drawn all the lines for this rectangle, then jump out of the loop
addi $sp, $sp, -4           # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t1, 0($sp)              # push $t1 onto the stack

addi $sp, $sp, -4           # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)              # push $ra to the stack for nested function

jal line_draw               # Call the line drawing code

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

lw $t1, 0($sp)              # pop $t1 off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

addi $t1, $t1, 1            # Increment the variable for the current row we are drawing
addi $a1, $a1, 1            # Increment the Y value to draw on the next line in the bit map
j rect_loop                 # Jump to the start of the loop
rect_loop_end:
jr $ra                      # Return to the calling program

##############################################################################
# Code for drawing a horizontal line
##############################################################################
# $s0 = location of the top-left corner of the bitmap
# $a0 = the X coordinate of the start of the line
# $a1 = the Y coordinate of the start of the line
# $a2 = the length of the line
# $t1 = the horizontal offset to add to $s0
# $t2 = the vertical offset to add to $s0
# $t3 = the current location of the pixel to draw
# $t4 = the location of the last pixel in the line
# $t9 = the colour of the line

line_draw: 
sll $t2, $a1, 7             # Calculate the vertical offset (from $s0), based on the Y input ($a1) (multiply Y input by 128)
sll $t1, $a0, 2             # Calculate the horizontal offset (from $s0), based on the X intput ($a0) (multiply X input by 4)

add $t3, $s0, $t2           # Add the vertical offset to $s0
add $t3, $t3, $t1           # Add the horizontal offset to the location calcuated above

sll $t5, $a2, 2             # Calculate the offset from $t3 for the last pixel in the line (multiple $a2 by 4)
add $t4, $t3, $t5           # Calculate the postion of the last pixel in the line
# Start of the line-drawing loop
line_loop:
beq $t3, $t4, line_loop_end # Check if the current X and Y match the end location of the line, branch out of the loop
sw $t9, 0($t3)              # Draw a single pixel at the current X and Y
addi $t3, $t3, 4            # Move to the next pixel in the row
j line_loop                 # Jump to the start of the loop
line_loop_end:
jr $ra                      # return statement (return to where you came from)