.data
ADDR_DSPL: .word 0x10008000
colors: .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xf28c28, 0xff00ff, 0xffffff   # red, green, blue, yellow, orange, magenta, white

######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################
.text
lw $s0, ADDR_DSPL       # $s0 = base address for display
la $s1, colors          # $s1 = address for the first color

# initialize the drawing of white game area rectangle
addi $a0, $zero, 1          # set the X coordinate
addi $a1, $zero, 1          # set the Y coordinate
addi $a2, $zero, 8          # set the width of the rectangle (6 + 2)
addi $a3, $zero, 16         # set the height of the rectangle (14 + 2)
lw $t9, 24($s1)             # loads white from colors
jal rect_draw               # calls rectangle drawing function.

# initialize the drawing of white game area rectangle
addi $a0, $zero, 2          # set the X coordinate
addi $a1, $zero, 2          # set the Y coordinate
addi $a2, $zero, 6          # set the width of the rectangle (6)
addi $a3, $zero, 14         # set the height of the rectangle (14)
add $t9, $zero, $zero       # set the colour of the rectangle to be black
jal rect_draw               # calls rectangle drawing function.

jal rand_column
li $v0, 10                  # terminate the program gracefully (number correspods to the type of syscall)
syscall

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
addi $t4, $t2, 384           # calculate the postion of the last pixel in the column
rand_column_loop:
jal rand_color              # call rand_color to get a random color in $v0
beq $t4, $t2, rand_column_loop_end # check if the current position is the end of the column, if so branch out of the loop
sw $v0, 0($t2)              # draw pixel of color $v0 to location $t2
addi $t2, $t2, 128          # Move to the next pixel in the column
j rand_column_loop          # Jump to the start of the loop
rand_column_loop_end:
lw $ra, 0($sp)              # pop $ra off the stack
addi $sp, $sp, 4          # move stack pointer back to the top of the stack
jr $ra
# draw the pixel
# move to the next row
# randomly generate an integer for one of the six colors
# draw the pixel
# move to the next row
# randomly generate an integer for one of the six colors
# draw the pixel

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