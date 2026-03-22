.data
ADDR_DSPL: .word 0x10008000
colors: .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xf28c28, 0xff00ff, 0xffffff   # red, green, blue, yellow, orange, magenta, white
keyboardaddress: .word 0xffff0000

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

# initialize the drawing of white game area rectangle
addi $a0, $zero, 1          # set the X coordinate
addi $a1, $zero, 1          # set the Y coordinate
addi $a2, $zero, 8          # set the width of the rectangle (6 + 2)
addi $a3, $zero, 17         # set the height of the rectangle (14 + 2)
lw $t9, 24($s1)             # loads white from colors
jal rect_draw               # calls rectangle drawing function.

# initialize the drawing of black game area rectangle
addi $a0, $zero, 2          # set the X coordinate
addi $a1, $zero, 2          # set the Y coordinate
addi $a2, $zero, 6          # set the width of the rectangle (6)
addi $a3, $zero, 15         # set the height of the rectangle (14)
add $t9, $zero, $zero       # set the colour of the rectangle to be black
jal rect_draw               # calls rectangle drawing function.

# initialize the drawing of the column
draw_col:
jal rand_column
addi $s4, $s0, 528          # make $t2 point to final block of the column

game_loop:
lw $t0, keyboardaddress 
lw $t8, 0($t0)              # load first word from keyboard

bne $t8, 1, no_keyboard_input  # if first word 1 key is noat pressed
jal keyboard_input

no_keyboard_input:

# increment s4
addi $t6, $s4, 128          # value one row below t6
lw $t6, 0($t6)              # load colour at t6 into t6
bne $t6, $zero, redraw

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, 128         # set the amount to move the column by (down 1 row)
jal redraw_column

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

li $v0, 32
li $a0, 1000
syscall

# TODO: redraw
redraw:
j game_loop

##############################################################################
# Code for responding to keyboard input
##############################################################################
keyboard_input:
lw $a0, 4 ($t0) # Load second word from keyboard
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
addi $t6, $s4, -4           # value one left of s4
lw $t6, 0($t6)              # load colour at t6 into t6

bne $t6, $zero, END_A       # move until the next colour is not black (i.e. edge or another placed column)

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, -4          # set the amount to move the column by (4 left)
jal redraw_column

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

END_A: 
jr $ra

##############################################################################
# Code for responding to key press S
##############################################################################
respond_to_S:
addi $t6, $s4, 128          # value one row below t6
lw $t6, 0($t6)              # load colour at t6 into t6

addi $t2, $s4, 0                # load into $t2 the initial value of the bottom of column

MOVE_COL_DOWN_ENTIRELY:
bne $t6, $zero, END_S       # move until the next colour is not black (i.e. edge or another placed column)

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, 128         # set the amount to move the column by (down 1 row)
jal redraw_column

addi $t6, $s4, 128          # increment to next column value
lw $t6, 0($t6)              # load colour at t6 into t6

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
j MOVE_COL_DOWN_ENTIRELY

END_S:
bne $t2, $s4, draw_col      # if the position of s4 has changed, no collision, draw new column
jr $ra                      # TODO: end game in this case


##############################################################################
# Code for responding to key press D
##############################################################################
respond_to_D:
addi $t6, $s4, 4           # value one right of s4
lw $t6, 0($t6)              # load colour at t6 into t6

bne $t6, $zero, END_D       # move until the next colour is not black (i.e. edge or another placed column)

addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)          # store current $ra in stack

addi $a0, $zero, 4          # set the amount to move the column by (4 right)
jal redraw_column

lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack

END_D:
jr $ra

##############################################################################
# Code for responding to key press W
##############################################################################
respond_to_W:

lw $t9, 0($s4)          # get colour from bottom of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
addi $s4, $s4, -128     # go to next row in column 

lw $t9, 0($s4)          # get colour from middle of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
addi $s4, $s4, -128     # go to next row in column 

lw $t9, 0($s4)          # get colour from top of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour

# shift the colours
addi $s4, $s4, 256          # go to bottom column

lw $t9, 0($sp)              # pop top colour off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($s4)              # draws top colour at bottom column
addi $s4, $s4, -256         # go to top column

lw $t9, 0($sp)              # pop middle colour off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($s4)              # draws middle colour at top column
addi $s4, $s4, 128          # go to middle column

lw $t9, 0($sp)              # pop bottom colour off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($s4)              # draws bottom colour at middle column

addi $s4, $s4, 128          # go to bottom column
jr $ra

##############################################################################
# Code for random color column
##############################################################################
# $s0 = location of the top-left corner of the bitmap
# $s1 = address of the first color
# $t2 = the current location to draw the random color pixel

rand_column:
addi $sp, $sp, -4           # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $ra, 0($sp)              # push $ra to the stack for nested function
addi $t2, $s0, 272          # add the horizontal - column 5 (4 x 4) and vertical - row 3 (128 x 2) offest to $s0
addi $t4, $t2, 384          # calculate the postion of the last pixel in the column
rand_column_loop:
jal rand_color              # call rand_color to get a random color in $v0
beq $t4, $t2, rand_column_loop_end # check if the current position is the end of the column, if so branch out of the loop
sw $v0, 0($t2)              # draw pixel of color $v0 to location $t2
addi $t2, $t2, 128          # Move to the next pixel in the column
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
# Code for getting the colours from the current column and adding colours to stack
##############################################################################
# $s4 = location of bottom pixel of column
# $t9 = colour of current popped off pixel
# $a0 = new location to draw column at

redraw_column:
lw $t9, 0($s4)          # get colour from bottom of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
sw $zero, 0($s4)        #paint pixel black
addi $s4, $s4, -128     # go to next row in column 

lw $t9, 0($s4)          #get colour from middle of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
sw $zero, 0($s4)        #paint pixel black
addi $s4, $s4, -128     # go to next row in column 

lw $t9, 0($s4)          #get colour from top of col, store in t9
addi $sp, $sp, -4       # move to an empty spot on the stack (decrement the stack pointer $sp by 4)
sw $t9, 0($sp)          # store colour
sw $zero, 0($s4)        #paint pixel black

add $s4, $s4, $a0         # moves pixel by specified amount

# draw at new $s4 location
lw $t9, 0($sp)              # pop $t9 off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($s4)              # draws column pixel to the left position
addi $s4, $s4, 128          # go to next column

lw $t9, 0($sp)              # pop $t9 off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($s4)              # draws column pixel to the left position
addi $s4, $s4, 128          # go to next column

lw $t9, 0($sp)              # pop $t9 off the stack
addi $sp, $sp, 4            # move stack pointer back to the top of the stack
sw $t9, 0($s4)              # draws column pixel to the left position

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