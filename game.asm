#####################################################################
#
# CSCB58 Winter 2025 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Abd-Ur-Rehman, 1009065510, rehma163, abdurrehman.abd@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# - Milestone 4
#
# Which approved features have been implemented for milestone 3?
# 1. Health bar
# 2. Win condition
# 3. Fail condition
#
# Which approved features have been implemented for milestone 4?
# 1. Moving Object
# 2. Moving Platform
# 3. Double jump
#
# Link to video demonstration for final submission:
# https://play.library.utoronto.ca/watch/23423fcb1f1ee4b34b22ec09feaac13c
#
# Are you OK with us sharing the video with people outside course staff?
# Yes
#
# Any additional information that the TA needs to know:
# - Controls: 'a' (left), 'd' (right), 'w' (jump/double jump), 'r' (restart), 'q' (quit).
# The player navigates platforms to reach the finish line, while avoiding fire and a right-moving arrow.
# Health decreases by 5% of max health (20 units) per hit. Platform 3 moves between and every 5 frames.
#
# In the begining of the video I forgot mention that the orange line at the top is the health bar! :(
#
#####################################################################

.data
    BASE_ADDRESS:   .word 0x10008000    # Base address of bitmap display
    WIDTH:          .word 64            # Width in units (64 units = 256 pixels)
    HEIGHT:         .word 64            # Height in units (64 units = 256 pixels)
    GRAY:           .word 0x00808080    # Gray color for platforms and ground
    playerX:        .word 16            # Player x-position (left-most unit, 0 to 61)
    playerY:        .word 62            # Player y-position
    playerColor:    .word 0x00FF00      # Default green color for player
    RED:            .word 0x00FF0000    # Red color for player when touching fire and arrow shaft
    bgColor:        .word 0x001C3C50    # Darker sky blue background color
    isJumping:      .word 0             # Jump flag (0 = not jumping, 1 = jumping)
    jumpCounter:    .word 0             # Tracks jump height
    doubleJumpAvailable: .word 1        # Double jump flag (1 = available, 0 = used)
    YELLOW:         .word 0x00FFFF00    # Yellow color for fire and arrowhead
    BLACK:          .word 0x00000000    # Black for finish line
    WHITE:          .word 0x00FFFFFF    # White for finish line
    health:         .word 20            # Initial health (20 units)
    maxHealth:      .word 20            # Maximum health for reference
    HEALTH_COLOR:   .word 0x00FF8C00    # Red color for health bar
    redTimer:       .word 0             # Counts frames since turning red
    isRed:          .word 0             # Flag: 0 = not red, 1 = red
    frameCounter:   .word 0             # General frame counter for timing
    displayAddress: .word 0x10008000    # Base address for display (same as BASE_ADDRESS)
    green:          .word 0x0000FF00    # Green color for text (same as playerColor)
    arrowX:         .word 0             # Arrow x-position (starting column)
    platform3X:     .word 30            # Platform 3 x-position (starts at 30)
    platform3Dir:   .word 1             # Direction: 1 = right, -1 = left
    platform3MoveCounter: .word 0       # Counter for slowing platform movement

.text
main:
    lw $t0, BASE_ADDRESS    # Load base address into $t0
    lw $t1, playerX
    lw $t2, playerColor
    lw $t3, bgColor

    # Clear screen
    li $t4, 0
    lw $t5, HEIGHT
    lw $t6, WIDTH
    mul $t5, $t5, $t6       # Total pixels = HEIGHT * WIDTH
    sll $t5, $t5, 2         # Total bytes = pixels * 4
clear_screen:
    sw $t3, 0($t0)
    addi $t0, $t0, 4
    addi $t4, $t4, 4
    blt $t4, $t5, clear_screen
    lw $t0, BASE_ADDRESS

    # Draw platforms
    li $a0, 50      # Platform 1: y=50
    li $a1, 49      # x=49
    li $a2, 15      # width=15
    jal draw_platform

    li $a0, 35      # Platform 2: y=35
    li $a1, 14      # x=14
    li $a2, 15      # width=15
    jal draw_platform

    li $a0, 20      # Platform 3: y=20
    lw $a1, platform3X  # x=platform3X (initially 30)
    li $a2, 15      # width=15
    jal draw_platform

    # Draw ground at top
    li $a0, 0       # Ground: y=0
    li $a1, 0       # x=0 (start at left edge)
    li $a2, 64      # width=64 (full width)
    jal draw_platform

    # Draw fire
    li $a0, 14      # Fire 1: x=14
    li $a1, 36      # y=36
    jal draw_fire

    li $a0, 40      # Fire 2: x=40
    li $a1, 21      # y=21
    jal draw_fire

    # Draw finish line below top platform
    li $a0, 60      # x=60
    li $a1, 51      # y=51
    jal draw_finish_line

    # Draw initial health bar
    jal draw_health_bar

    j game_loop

draw_platform:
    addi $sp, $sp, -16
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)

    lw $t0, BASE_ADDRESS
    lw $t1, GRAY
    lw $t2, HEIGHT
    sub $t2, $t2, 1
    sub $t2, $t2, $a0
    bltz $t2, skip_draw
    lw $t4, WIDTH
    mul $t2, $t2, $t4
    sll $t2, $t2, 2
    add $t2, $t2, $t0
    sll $t3, $a1, 2
    add $t3, $t2, $t3
    move $t2, $a2
    add $t5, $a1, $a2
    li $t6, 64
    bgt $t5, $t6, skip_draw
draw_platform_loop:
    li $t5, 0x10088000
    bge $t3, $t5, skip_draw
    sw $t1, 0($t3)
    addi $t3, $t3, 4
    addi $t2, $t2, -1
    bnez $t2, draw_platform_loop

skip_draw:
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_fire:
    addi $sp, $sp, -20
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)

    lw $t0, BASE_ADDRESS
    lw $t4, HEIGHT
    sub $t4, $t4, 1

    sub $t2, $t4, $a1
    lw $t6, WIDTH
    mul $t3, $t2, $t6
    sll $t3, $t3, 2
    add $t3, $t3, $t0
    sll $t2, $a0, 2
    add $t3, $t3, $t2
    lw $t1, YELLOW
    sw $t1, 0($t3)
    sw $t1, 4($t3)
    sw $t1, 8($t3)
    sw $t1, 12($t3)
    sw $t1, 16($t3)

    addi $t2, $a1, 1
    sub $t2, $t4, $t2
    mul $t3, $t2, $t6
    sll $t3, $t3, 2
    add $t3, $t3, $t0
    sll $t2, $a0, 2
    add $t3, $t3, $t2
    sw $t1, 0($t3)
    sw $t1, 8($t3)
    sw $t1, 16($t3)

    addi $t2, $a1, 2
    sub $t2, $t4, $t2
    mul $t3, $t2, $t6
    sll $t3, $t3, 2
    add $t3, $t3, $t0
    sll $t2, $a0, 2
    addi $t2, $t2, 8
    add $t3, $t3, $t2
    sw $t1, 0($t3)

    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t4, 16($sp)
    addi $sp, $sp, 20
    jr $ra

draw_finish_line:
    addi $sp, $sp, -20
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)

    lw $t0, BASE_ADDRESS
    lw $t4, HEIGHT
    sub $t4, $t4, 1         # $t4 = 63
    move $t1, $a1           # Starting y
    li $t2, 4               # 4 rows
draw_finish_y_loop:
    sub $t3, $t4, $t1       # Invert y
    lw $t6, WIDTH           # Load WIDTH (64)
    mul $t3, $t3, $t6       # Row offset
    sll $t3, $t3, 2         # Byte offset
    add $t3, $t3, $t0       # Row address
    sll $t5, $a0, 2         # x-offset
    add $t3, $t3, $t5       # Pixel address
    li $t5, 4               # 4 columns
    move $t6, $t1           # y for pattern
draw_finish_x_loop:
    andi $t7, $t6, 1        # y parity
    andi $t8, $t5, 1        # x parity
    xor $t7, $t7, $t8       # Check pattern
    beqz $t7, draw_white
    lw $t9, BLACK           # Load black color
    j draw_store
draw_white:
    lw $t9, WHITE           # Load white color
draw_store:
    sw $t9, 0($t3)          # Draw pixel
    addi $t3, $t3, 4
    addi $t5, $t5, -1
    bnez $t5, draw_finish_x_loop
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    bnez $t2, draw_finish_y_loop

    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t4, 16($sp)
    addi $sp, $sp, 20
    jr $ra

draw_health_bar:
    addi $sp, $sp, -20
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)

    lw $t0, BASE_ADDRESS
    lw $t1, HEALTH_COLOR    # Red color for health
    lw $t9, bgColor         # Background color to clear

    # Calculate starting address for y=63
    li $t3, 63              # y-position
    lw $t5, HEIGHT
    sub $t5, $t5, 1         # Invert y-coordinate
    sub $t3, $t5, $t3       # $t3 = 63 (top row)
    lw $t5, WIDTH
    mul $t3, $t3, $t5       # Row offset (63 * 64)
    sll $t3, $t3, 2         # Byte offset
    add $t3, $t3, $t0       # Base address + row offset

    # Clear the entire row (64 units)
    li $t4, 64              # Width of screen
clear_health_loop:
    beqz $t4, end_clear_health
    sw $t9, 0($t3)          # Write background color
    addi $t3, $t3, 4        # Next pixel
    addi $t4, $t4, -1       # Decrease counter
    j clear_health_loop
end_clear_health:

    # Reset address to start of row
    li $t3, 63
    lw $t5, HEIGHT
    sub $t5, $t5, 1
    sub $t3, $t5, $t3
    lw $t5, WIDTH
    mul $t3, $t3, $t5
    sll $t3, $t3, 2
    add $t3, $t3, $t0

    # Draw new health bar
    lw $t2, health          # Current health
    lw $t4, maxHealth       # Maximum health
    lw $t5, WIDTH           # Screen width (64 units)
    mul $t6, $t2, $t5       # health * WIDTH
    div $t6, $t4            # (health * WIDTH) / maxHealth
    mflo $t2                # $t2 = length of health bar in units
    
    li $t4, 0               # x-position (start at 0)
draw_health_loop:
    beqz $t2, end_health_draw   # Stop if length = 0
    sw $t1, 0($t3)              # Draw health unit
    addi $t3, $t3, 4            # Move to next pixel
    addi $t2, $t2, -1           # Decrease length counter
    j draw_health_loop
end_health_draw:
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t4, 16($sp)
    addi $sp, $sp, 20
    jr $ra

clear_platform:
    addi $sp, $sp, -16
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)

    lw $t0, BASE_ADDRESS
    lw $t1, bgColor
    lw $t2, HEIGHT
    sub $t2, $t2, 1
    sub $t2, $t2, $a0
    bltz $t2, skip_clear
    lw $t4, WIDTH
    mul $t2, $t2, $t4
    sll $t2, $t2, 2
    add $t2, $t2, $t0
    sll $t3, $a1, 2
    add $t3, $t2, $t3
    move $t2, $a2
    add $t5, $a1, $a2
    li $t6, 64
    bgt $t5, $t6, skip_clear
clear_platform_loop:
    li $t5, 0x10088000
    bge $t3, $t5, skip_clear
    sw $t1, 0($t3)
    addi $t3, $t3, 4
    addi $t2, $t2, -1
    bnez $t2, clear_platform_loop

skip_clear:
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    addi $sp, $sp, 16
    jr $ra

game_loop:
    # Save current position
    lw $t1, playerX
    lw $t5, playerY
    move $s3, $t1
    move $s4, $t5

    # Clear previous player position (3 units wide)
    mul $t9, $s4, 256       # y-offset
    add $t8, $t0, $t9       # Base + y-offset
    sll $t4, $s3, 2         # x-offset
    add $t8, $t8, $t4       # Add x-offset
    sw $t3, 0($t8)          # Clear left
    sw $t3, 4($t8)          # Clear middle
    sw $t3, 8($t8)          # Clear right

    # Clear previous arrow position
    lw $s0, arrowX
    li $t4, 18              # Row 18 (y=45, 63-45)
    addi $t5, $s0, -5       # Start five units before shaft
    addi $t6, $s0, 10       # End ten units after arrowhead
clear_arrow_top:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t3, 0($t7)          # Clear with bgColor
    addi $t5, $t5, 1
    ble $t5, $t6, clear_arrow_top
    
    li $t4, 19              # Row 19 (y=44, 63-44)
    addi $t5, $s0, -5       # Start five units before shaft
    addi $t6, $s0, 10       # End ten units after arrowhead
clear_arrow_shaft:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t3, 0($t7)          # Clear with bgColor
    addi $t5, $t5, 1
    ble $t5, $t6, clear_arrow_shaft
    
    li $t4, 20              # Row 20 (y=43, 63-43)
    addi $t5, $s0, -5       # Start five units before shaft
    addi $t6, $s0, 10       # End ten units after arrowhead
clear_arrow_bottom:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t3, 0($t7)          # Clear with bgColor
    addi $t5, $t5, 1
    ble $t5, $t6, clear_arrow_bottom

    # Clear Platform 3's previous position
    li $a0, 20
    lw $a1, platform3X
    li $a2, 15
    jal clear_platform

    # Update Platform 3's position
    lw $t9, platform3MoveCounter
    addi $t9, $t9, 1
    sw $t9, platform3MoveCounter
    li $t8, 5
    bne $t9, $t8, redraw_platforms  # Move only every 5 frames
    sw $zero, platform3MoveCounter  # Reset counter

    lw $t7, platform3X
    lw $t8, platform3Dir
    add $t7, $t7, $t8
    sw $t7, platform3X

    # Check boundaries
    li $t9, 40
    beq $t7, $t9, set_left_dir
    li $t9, 30
    beq $t7, $t9, set_right_dir
    j redraw_platforms

set_left_dir:
    li $t8, -1
    sw $t8, platform3Dir
    j redraw_platforms

set_right_dir:
    li $t8, 1
    sw $t8, platform3Dir

redraw_platforms:
    # Redraw platforms
    li $a0, 50
    li $a1, 49
    li $a2, 15
    jal draw_platform

    li $a0, 35
    li $a1, 14
    li $a2, 15
    jal draw_platform

    li $a0, 20
    lw $a1, platform3X
    li $a2, 15
    jal draw_platform

    # Redraw ground at top
    li $a0, 0       # Ground: y=0
    li $a1, 0       # x=0
    li $a2, 64      # width=64
    jal draw_platform

    # Redraw fire
    li $a0, 14
    li $a1, 36
    jal draw_fire

    li $a0, 40
    li $a1, 21
    jal draw_fire

    # Redraw finish line
    li $a0, 60
    li $a1, 51
    jal draw_finish_line

    # Redraw health bar
    jal draw_health_bar

    # Draw arrow shaft (red)
    li $t4, 19              # Row 19 (y=44)
    move $t5, $s0           # Starting column
    addi $t6, $t5, 4        # Ending column (start + 4)
arrow_shaft_loop:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    lw $t8, RED
    sw $t8, 0($t7)          # Paint red pixel
    addi $t5, $t5, 1
    ble $t5, $t6, arrow_shaft_loop
    
    # Check if arrowhead would exceed display
    move $t7, $t6           # Shaft end column
    addi $t7, $t7, 2        # Max arrowhead column
    li $t9, 63
    bgt $t7, $t9, skip_arrow_draw
    
    # Draw arrowhead (yellow)
    li $t4, 18              # Row 18 (y=45)
    move $t5, $t6           # Column at shaft end
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    lw $t8, YELLOW
    sw $t8, 0($t7)          # Yellow pixel
    
    li $t4, 19              # Row 19 (y=44)
    addi $t5, $t6, 1        # Column after shaft end
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t8, 0($t7)          # Yellow pixel
    
    addi $t5, $t6, 2        # Column two after shaft end
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t8, 0($t7)          # Yellow pixel
    
    li $t4, 20              # Row 20 (y=43)
    move $t5, $t6           # Column at shaft end
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t8, 0($t7)          # Yellow pixel

skip_arrow_draw:
    # Update arrow position
    addi $s0, $s0, 1        # Move arrow right
    li $t5, 64
    blt $s0, $t5, skip_arrow_wrap
    
    # Before wrapping, clear arrow rows around right edge
    li $t4, 18              # Row 18 (y=45)
    li $t5, 54              # Start at column 54
    li $t6, 63
clear_arrow_right_top:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t3, 0($t7)
    addi $t5, $t5, 1
    ble $t5, $t6, clear_arrow_right_top
    
    li $t4, 19              # Row 19 (y=44)
    li $t5, 54
    li $t6, 63
clear_arrow_right_shaft:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t3, 0($t7)
    addi $t5, $t5, 1
    ble $t5, $t6, clear_arrow_right_shaft
    
    li $t4, 20              # Row 20 (y=43)
    li $t5, 54
    li $t6, 63
clear_arrow_right_bottom:
    mul $t7, $t4, 64
    add $t7, $t7, $t5
    mul $t7, $t7, 4
    add $t7, $t7, $t0
    sw $t3, 0($t7)
    addi $t5, $t5, 1
    ble $t5, $t6, clear_arrow_right_bottom
    
    li $s0, 0               # Reset arrow to left edge
    sw $s0, arrowX

skip_arrow_wrap:
    sw $s0, arrowX          # Store updated arrowX

    # Keyboard input
    li $t7, 0xffff0000
    lw $t8, 0($t7)
    andi $t8, $t8, 0x1
    beq $t8, $zero, handle_movement

    lw $t9, 4($t7)
    li $s0, 113         # 'q' to quit
    beq $t9, $s0, exit

    # Restart ('r')
    li $s0, 114         # ASCII for 'r'
    bne $t9, $s0, check_a
    # Reset game state
    li $t1, 16
    sw $t1, playerX     # Reset playerX to 16
    li $t1, 62
    sw $t1, playerY     # Reset playerY to 62
    li $t1, 0x00FF00
    sw $t1, playerColor # Reset to green
    sw $zero, isJumping # Reset jumping flag
    sw $zero, jumpCounter # Reset jump counter
    li $t1, 1
    sw $t1, doubleJumpAvailable # Reset double jump
    li $t1, 20
    sw $t1, health      # Reset health to 20
    sw $zero, redTimer  # Reset red timer
    sw $zero, isRed     # Reset red flag
    sw $zero, frameCounter # Reset frame counter
    sw $zero, arrowX    # Reset arrow position
    li $t1, 30
    sw $t1, platform3X  # Reset platform3X to 30
    li $t1, 1
    sw $t1, platform3Dir # Reset direction to right
    sw $zero, platform3MoveCounter # Reset move counter
    j main              # Restart from the beginning

check_a:
    # Move left ('a')
    li $s0, 97
    bne $t9, $s0, check_d
    beq $t1, $zero, handle_movement
    sub $t1, $t1, 1
    sw $t1, playerX
    j handle_movement

check_d:
    # Move right ('d')
    li $s0, 100
    bne $t9, $s0, check_w
    li $s1, 61          # Right edge now 61 (64-3)
    beq $t1, $s1, handle_movement
    add $t1, $t1, 1
    sw $t1, playerX
    j handle_movement

check_w:
    # Jump ('w')
    li $s0, 119
    bne $t9, $s0, handle_movement
    lw $t5, playerY
    lw $t8, doubleJumpAvailable  # Load double jump flag
    
    # Check if on ground for initial jump
    li $s1, 62
    beq $t5, $s1, start_jump
    
    # Check platform under all 3 units for initial jump
    lw $t0, BASE_ADDRESS
    lw $t1, playerX
    addi $t7, $t5, 1
    mul $t9, $t7, 256
    add $t8, $t0, $t9
    sll $t4, $t1, 2
    add $t8, $t8, $t4
    lw $t9, 0($t8)      # Check left
    lw $s0, GRAY
    beq $t9, $s0, start_jump
    lw $t9, 4($t8)      # Check middle
    beq $t9, $s0, start_jump
    lw $t9, 8($t8)      # Check right
    beq $t9, $s0, start_jump
    
    # Not on ground or platform, check for double jump
    lw $t8, doubleJumpAvailable
    beqz $t8, handle_movement    # No double jump available
    # Player is airborne, allow double jump
    li $s2, 1
    sw $s2, isJumping           # Start new jump
    sw $zero, jumpCounter       # Reset jump counter
    sw $zero, doubleJumpAvailable # Consume double jump
    j handle_movement

start_jump:
    li $s2, 1
    sw $s2, isJumping
    sw $zero, jumpCounter
    li $t8, 1
    sw $t8, doubleJumpAvailable # Ensure double jump is available after ground/platform jump
    j handle_movement

handle_movement:
    lw $t5, isJumping
    lw $t6, playerY
    beqz $t5, apply_gravity

    lw $t7, jumpCounter
    li $s1, 30
    bge $t7, $s1, end_jump
    sub $t8, $t6, 1
    bltz $t8, end_jump
    move $t6, $t8
    add $t7, $t7, 1
    sw $t6, playerY
    sw $t7, jumpCounter
    j check_color

end_jump:
    sw $zero, isJumping
    j check_color

apply_gravity:
    li $s1, 62
    bge $t6, $s1, land_on_ground

    lw $t0, BASE_ADDRESS
    lw $t1, playerX
    addi $t7, $t6, 1
    mul $t9, $t7, 256
    add $t8, $t0, $t9
    sll $t4, $t1, 2
    add $t8, $t8, $t4
    
    # Check all 3 units below
    lw $t9, 0($t8)      # Left
    lw $s0, GRAY
    beq $t9, $s0, land_on_platform
    lw $t9, 4($t8)      # Middle
    beq $t9, $s0, land_on_platform
    lw $t9, 8($t8)      # Right
    beq $t9, $s0, land_on_platform

    add $t6, $t6, 1
    sw $t6, playerY
    j check_color

land_on_platform:
    sw $t6, playerY
    sw $zero, isJumping
    sw $zero, jumpCounter
    li $t8, 1
    sw $t8, doubleJumpAvailable  # Reset double jump
    j check_color

land_on_ground:
    sw $s1, playerY
    sw $zero, isJumping
    sw $zero, jumpCounter
    li $t8, 1
    sw $t8, doubleJumpAvailable  # Reset double jump
    j check_color

check_color:
    lw $t1, playerX
    lw $t5, playerY
    mul $t9, $t5, 256
    add $t6, $t0, $t9
    sll $t4, $t1, 2
    add $t6, $t6, $t4
    
    # Check all 3 units for fire (yellow)
    lw $t7, 0($t6)      # Left
    lw $s0, YELLOW
    beq $t7, $s0, set_red
    lw $t7, 4($t6)      # Middle
    beq $t7, $s0, set_red
    lw $t7, 8($t6)      # Right
    beq $t7, $s0, set_red
    
    # Check all 3 units for arrow shaft (red)
    lw $t7, 0($t6)      # Left
    lw $s0, RED
    beq $t7, $s0, set_red
    lw $t7, 4($t6)      # Middle
    beq $t7, $s0, set_red
    lw $t7, 8($t6)      # Right
    beq $t7, $s0, set_red
    
    # Check all 3 units for black (finish line)
    lw $t7, 0($t6)      # Left
    lw $s0, BLACK
    beq $t7, $s0, win_game
    lw $t7, 4($t6)      # Middle
    beq $t7, $s0, win_game
    lw $t7, 8($t6)      # Right
    beq $t7, $s0, win_game
    
    # If not touching fire, arrow, or black, reset to green
    lw $t2, playerColor # Default green
    sw $zero, isRed     # Clear red flag
    sw $zero, redTimer  # Reset timer
    j draw_player

win_game:
    jal display_you_win # Display "YOU WIN" and exit

set_red:
    lw $t2, RED
    li $t7, 1
    sw $t7, isRed       # Set red flag
    
    # Increment red timer
    lw $t7, redTimer
    addi $t7, $t7, 1
    sw $t7, redTimer
    
    # Check if 0.1 second have passed
    li $t8, 1
    blt $t7, $t8, draw_player
    
    # Reduce health by 5% of maxHealth
    lw $t7, health
    beqz $t7, game_over       # If health is already 0, display "GAME OVER"
    lw $t8, maxHealth
    li $t9, 5
    mul $t9, $t8, $t9
    div $t9, $t9, 100
    sub $t7, $t7, $t9
    bltz $t7, set_health_zero # If health would go below 0, set to 0
    sw $t7, health
    j reset_timer

set_health_zero:
    sw $zero, health
    j game_over               # Display "GAME OVER"

game_over:
    jal display_game_over     # Display "GAME OVER"

reset_timer:
    sw $zero, redTimer
    jal draw_health_bar
    j draw_player

draw_player:
    lw $t1, playerX
    lw $t5, playerY
    mul $t9, $t5, 256
    add $t6, $t0, $t9
    sll $t4, $t1, 2
    add $t6, $t6, $t4
    
    # Draw 3 units wide
    sw $t2, 0($t6)      # Left
    sw $t2, 4($t6)      # Middle
    sw $t2, 8($t6)      # Right

    # Increment frame counter
    lw $t7, frameCounter
    addi $t7, $t7, 1
    sw $t7, frameCounter

    li $v0, 32
    li $a0, 65          # 65ms delay
    syscall

    j game_loop

exit:
    li $v0, 10
    syscall
    
display_you_win:
    # Save registers we'll use
    addi $sp, $sp, -20
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)

    # Clear the entire screen with black
    lw $t0, BASE_ADDRESS      # Load base address
    lw $t1, BLACK             # Load black color (0x00000000)
    li $t2, 0                 # Counter for bytes
    lw $t3, HEIGHT            # HEIGHT = 64
    lw $t4, WIDTH             # WIDTH = 64
    mul $t3, $t3, $t4         # Total pixels = 64 * 64 = 4096
    sll $t3, $t3, 2           # Total bytes = 4096 * 4 = 16384
clear_full_screen:
    sw $t1, 0($t0)            # Write black to current pixel
    addi $t0, $t0, 4          # Move to next pixel
    addi $t2, $t2, 4          # Increment byte counter
    blt $t2, $t3, clear_full_screen

    # Reset $t0 to base address for drawing text
    lw $t0, BASE_ADDRESS
    lw $t1, green             # Load green color (0x0000FF00)

    # Calculate starting position for "Y" (row 23, column 20)
    li $t2, 23                # Row 23 for "YOU"
    li $t3, 64                # Units per row
    mul $t4, $t2, $t3         # row * 64
    addi $t4, $t4, 20         # Start at column 20
    sll $t4, $t4, 2           # Multiply by 4 (bytes per pixel)
    add $t0, $t0, $t4         # Add offset to base address
    
    # Draw "Y" (16 pixels tall, 12 pixels wide)
    sw $t1, -4($t0)           # Left diagonal
    sw $t1, 252($t0)
    sw $t1, 508($t0)
    sw $t1, 764($t0)
    sw $t1, 20($t0)           # Right diagonal
    sw $t1, 276($t0)
    sw $t1, 532($t0)
    sw $t1, 788($t0)
    sw $t1, 768($t0)          # Vertical stem
    sw $t1, 772($t0)
    sw $t1, 776($t0)
    sw $t1, 780($t0)
    sw $t1, 784($t0)
    sw $t1, 1032($t0)
    sw $t1, 1288($t0)
    sw $t1, 1544($t0)
    
    # Move to "O" position (7 units right)
    addi $t0, $t0, 28
    
    # Draw "O" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)            # Top row
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 12($t0)
    sw $t1, 16($t0)
    sw $t1, 256($t0)          # Left side
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 20($t0)           # Right side
    sw $t1, 276($t0)
    sw $t1, 532($t0)
    sw $t1, 788($t0)
    sw $t1, 1044($t0)
    sw $t1, 1300($t0)
    sw $t1, 1536($t0)         # Bottom row
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    sw $t1, 1552($t0)
    sw $t1, 1556($t0)
    
    # Move to "U" position (7 units right)
    addi $t0, $t0, 28
    
    # Draw "U" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)            # Left side
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 20($t0)           # Right side
    sw $t1, 276($t0)
    sw $t1, 532($t0)
    sw $t1, 788($t0)
    sw $t1, 1044($t0)
    sw $t1, 1300($t0)
    sw $t1, 1536($t0)         # Bottom row
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    sw $t1, 1552($t0)
    sw $t1, 1556($t0)
    
    # Reset $t0 and calculate starting position for "W" (row 35, column 20)
    lw $t0, BASE_ADDRESS      # Reload base address
    li $t2, 35                # Row 35 for "WIN"
    mul $t4, $t2, $t3         # row * 64
    addi $t4, $t4, 20         # Start at column 20
    sll $t4, $t4, 2           # Multiply by 4 (bytes per pixel)
    add $t0, $t0, $t4         # Add offset to base address
    
    # Draw "W" (16 pixels tall, 22 pixels wide)
    sw $t1, 0($t0)            # Left side of first U
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)         # Bottom row of first U
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    sw $t1, 1552($t0)
    sw $t1, 528($t0)          # Middle junction
    sw $t1, 784($t0)
    sw $t1, 1040($t0)
    sw $t1, 1296($t0)
    sw $t1, 1556($t0)         # Bottom row of second U
    sw $t1, 1560($t0)
    sw $t1, 1564($t0)
    sw $t1, 1568($t0)
    sw $t1, 32($t0)           # Right side of second U
    sw $t1, 288($t0)
    sw $t1, 544($t0)
    sw $t1, 800($t0)
    sw $t1, 1056($t0)
    sw $t1, 1312($t0)
    
    # Move to "I" position (10 units right of W's start)
    addi $t0, $t0, 40
    
    # Draw "I" (16 pixels tall, 4 pixels wide)
    sw $t1, 0($t0)            # Vertical stem
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)
    
    addi $t0, $t0, 8          # Space
    
    # Draw "N"
    sw $t1, 0($t0)            # Left Vertical stem of N
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)
    
    sw $t1, 4($t0)
    sw $t1, 264($t0)
    sw $t1, 524($t0)
    sw $t1, 784($t0)
    sw $t1, 1044($t0)
    sw $t1, 1304($t0)
    sw $t1, 1564($t0)
    
    sw $t1, 32($t0)           # Right Vertical stem of N
    sw $t1, 288($t0)
    sw $t1, 544($t0)
    sw $t1, 800($t0)
    sw $t1, 1056($t0)
    sw $t1, 1312($t0)
    sw $t1, 1568($t0)
    
    # Add delay to show the text
    li $v0, 32
    li $a0, 2000              # 2-second delay
    syscall
    
    # Restore registers
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t4, 16($sp)
    addi $sp, $sp, 20
    
    # Exit
    j exit
    
display_game_over:
    # Save registers we'll use
    addi $sp, $sp, -20
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)

    # Clear the entire screen with black
    lw $t0, BASE_ADDRESS      # Load base address
    lw $t1, BLACK             # Load black color (0x00000000)
    li $t2, 0                 # Counter for bytes
    lw $t3, HEIGHT            # HEIGHT = 64
    lw $t4, WIDTH             # WIDTH = 64
    mul $t3, $t3, $t4         # Total pixels = 64 * 64 = 4096
    sll $t3, $t3, 2           # Total bytes = 4096 * 4 = 16384
clear_full_screen_game_over:
    sw $t1, 0($t0)            # Write black to current pixel
    addi $t0, $t0, 4          # Move to next pixel
    addi $t2, $t2, 4          # Increment byte counter
    blt $t2, $t3, clear_full_screen_game_over

    # Reset $t0 to base address for drawing text
    lw $t0, BASE_ADDRESS
    lw $t1, RED               # Load red color (0x00FF0000)

    # Calculate starting position for "G" (row 20, column 18)
    li $t2, 20                # Row 20
    li $t3, 64                # Units per row
    mul $t4, $t2, $t3         # row * 64 = 20 * 64 = 1280 units
    addi $t4, $t4, 18         # Add column 18 = 1280 + 18 = 1298 units
    sll $t4, $t4, 2           # Multiply by 4 (bytes per unit) = 1298 * 4 = 5192 bytes
    add $t0, $t0, $t4         # Add offset to base address
    
    # Draw "G" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Top horizontal bar
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 12($t0)
    sw $t1, 16($t0)
    sw $t1, 256($t0)         # Left vertical side
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)        # Bottom horizontal bar
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    sw $t1, 1552($t0)
    sw $t1, 784($t0)         # Right partial vertical (hook part)
    sw $t1, 1040($t0)
    sw $t1, 1296($t0)
    sw $t1, 776($t0)         # Middle horizontal bar (hook connector)
    sw $t1, 780($t0)
    
    # Move to "A" position (6 units right of G's start)
    addi $t0, $t0, 24         # 6 units * 4 bytes = 24 bytes (column 24)
    
    # Draw "A" (16 pixels tall, 12 pixels wide)
    sw $t1, 4($t0)           # Left diagonal leg
    sw $t1, 260($t0)
    sw $t1, 516($t0)
    sw $t1, 772($t0)
    sw $t1, 1028($t0)
    sw $t1, 1284($t0)
    sw $t1, 1540($t0)
    sw $t1, 20($t0)          # Right diagonal leg
    sw $t1, 276($t0)
    sw $t1, 532($t0)
    sw $t1, 788($t0)
    sw $t1, 1044($t0)
    sw $t1, 1300($t0)
    sw $t1, 1556($t0)
    sw $t1, 528($t0)         # Middle horizontal bar
    sw $t1, 516($t0)
    sw $t1, 520($t0)
    sw $t1, 524($t0)
    sw $t1, 8($t0)           # Top horizontal bar
    sw $t1, 12($t0)
    sw $t1, 16($t0)
    
    # Move to "M" position (8 units right of A's start)
    addi $t0, $t0, 32         # 8 units * 4 bytes = 32 bytes (column 32)
    
    # Draw "M" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Left vertical leg
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)
    sw $t1, 4($t0)           # Top Bar
    sw $t1, 8($t0)
    sw $t1, 16($t0)
    sw $t1, 20($t0)
    sw $t1, 12($t0)          # Middle peak
    sw $t1, 268($t0)
    sw $t1, 524($t0)
    sw $t1, 24($t0)          # Right vertical leg
    sw $t1, 280($t0)
    sw $t1, 536($t0)
    sw $t1, 792($t0)
    sw $t1, 1048($t0)
    sw $t1, 1304($t0)
    sw $t1, 1560($t0)
    
    # Move to "E" position (9 units right of M's start)
    addi $t0, $t0, 36         # 9 units * 4 bytes = 36 bytes (column 41)
    
    # Draw "E" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Left vertical leg
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)
    sw $t1, 4($t0)           # Top horizontal bar
    sw $t1, 8($t0)
    sw $t1, 12($t0)
    sw $t1, 768($t0)         # Middle horizontal bar
    sw $t1, 772($t0)
    sw $t1, 776($t0)
    sw $t1, 1536($t0)        # Bottom horizontal bar
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    
    # Reset $t0 and calculate starting position for "O" (row 30, column 20)
    lw $t0, BASE_ADDRESS      # Reload base address
    li $t2, 30                # Row 30
    mul $t4, $t2, $t3         # row * 64 = 30 * 64 = 1920 units
    addi $t4, $t4, 20         # Add column 20 = 1920 + 20 = 1940 units
    sll $t4, $t4, 2           # Multiply by 4 = 1940 * 4 = 7760 bytes
    add $t0, $t0, $t4         # Add offset
    
    # Draw "O" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Top row
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    sw $t1, 12($t0)
    sw $t1, 16($t0)
    sw $t1, 256($t0)         # Left side
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 20($t0)          # Right side
    sw $t1, 276($t0)
    sw $t1, 532($t0)
    sw $t1, 788($t0)
    sw $t1, 1044($t0)
    sw $t1, 1300($t0)
    sw $t1, 1536($t0)        # Bottom row
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    sw $t1, 1552($t0)
    sw $t1, 1556($t0)
    
    # Move to "V" position (7 units right of O's start)
    addi $t0, $t0, 28         # Column 27
    
    # Draw "V" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Left diagonal
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1028($t0)
    sw $t1, 1284($t0)
    sw $t1, 1544($t0)
    sw $t1, 20($t0)          # Right diagonal
    sw $t1, 276($t0)
    sw $t1, 532($t0)
    sw $t1, 788($t0)
    sw $t1, 1040($t0)
    sw $t1, 1296($t0)
    sw $t1, 1548($t0)
    
    # Move to "E" position (7 units right of V's start)
    addi $t0, $t0, 28         # Column 34
    
    # Draw "E" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Left vertical leg
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)
    sw $t1, 4($t0)           # Top horizontal bar
    sw $t1, 8($t0)
    sw $t1, 12($t0)
    sw $t1, 768($t0)         # Middle horizontal bar
    sw $t1, 772($t0)
    sw $t1, 776($t0)
    sw $t1, 1536($t0)        # Bottom horizontal bar
    sw $t1, 1540($t0)
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    
    # Move to "R" position (5 units right of E's start)
    addi $t0, $t0, 20         # Column 39
    
   # Draw "R" (16 pixels tall, 12 pixels wide)
    sw $t1, 0($t0)           # Left vertical leg
    sw $t1, 256($t0)
    sw $t1, 512($t0)
    sw $t1, 768($t0)
    sw $t1, 1024($t0)
    sw $t1, 1280($t0)
    sw $t1, 1536($t0)
    sw $t1, 4($t0)           # Top horizontal bar
    sw $t1, 8($t0)
    sw $t1, 12($t0)
    sw $t1, 16($t0)
    sw $t1, 768($t0)         # Middle horizontal bar
    sw $t1, 772($t0)
    sw $t1, 776($t0)
    sw $t1, 780($t0)
    sw $t1, 784($t0)
    sw $t1, 272($t0)
    sw $t1, 528($t0)
    sw $t1, 1028($t0)        # Diagonal leg
    sw $t1, 1288($t0)
    sw $t1, 1548($t0)
    
    # Add delay to show the text
    li $v0, 32
    li $a0, 2000              # 2-second delay
    syscall
    
    # Restore registers
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t4, 16($sp)
    addi $sp, $sp, 20
    
    # Exit
    j exit