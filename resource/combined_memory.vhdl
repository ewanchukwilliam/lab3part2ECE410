------------------------------------------------------------------------
-- University  : University of Alberta
-- Course      : ECE 410
-- Project     : Lab 3
-- File        : data_memory.vhdl
-- Authors     : Antonio Alejandro Andara Lara
-- Date        : 23-Oct-2025
------------------------------------------------------------------------
-- Description  : 1 KB data memory with 32-bit read/write interface.
--                Supports synchronous writes and asynchronous reads.
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY combined_mem IS
    PORT (
        clock      : IN STD_LOGIC;
        write_en   : IN STD_LOGIC;
        address    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        data       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF combined_mem IS

    -- Byte-addressable RAM
    TYPE memory_data IS ARRAY (0 TO 1023) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL RAM : memory_data := (
        -- Program: Average of Two Numbers Calculator
        -- Calculates (num1 + num2) / 2 and stores result

        -- LOAD DATA: Load simple values from memory
        -- lw x1, 100(x0)    -- Load 10 into x1
        0 => x"83", 1 => x"20", 2 => x"40", 3 => x"06",
        -- lw x2, 104(x0)    -- Load 20 into x2
        4 => x"03", 5 => x"21", 6 => x"80", 7 => x"06",

        -- ARITHMETIC OPERATIONS
        -- add x3, x1, x2    -- x3 = 10 + 20 = 30
        8 => x"B3", 9 => x"81", 10 => x"20", 11 => x"00",

        -- SHIFT OPERATIONS (divide by 2)
        -- srai x4, x3, 1    -- x4 = 30 >> 1 = 15 (average)
        12 => x"13", 13 => x"D2", 14 => x"11", 15 => x"40",

        -- VERIFICATION: Check if result is correct
        -- addi x5, x0, 15    -- x5 = 15 (expected value)
        16 => x"93", 17 => x"02", 18 => x"F0", 19 => x"00",
        -- beq x4, x5, 12     -- If x4 == 15, branch to success (skip fail case)
        20 => x"63", 21 => x"0C", 22 => x"52", 23 => x"00",

        -- FAIL case: x4 != 15
        -- addi x5, x0, -1    -- x5 = -1 (error indicator)
        24 => x"93", 25 => x"02", 26 => x"F0", 27 => x"FF",
        -- beq x0, x0, 8      -- Unconditional branch, skip success case
        28 => x"63", 29 => x"08", 30 => x"00", 31 => x"00",

        -- SUCCESS case: x4 == 15
        -- addi x5, x0, 1     -- x5 = 1 (success indicator)
        32 => x"93", 33 => x"02", 34 => x"10", 35 => x"00",

        -- STORE OPERATIONS
        -- sw x4, 108(x0)     -- Store result (15) to memory address 108
        36 => x"23", 37 => x"26", 38 => x"40", 39 => x"06",
        -- sw x5, 112(x0)     -- Store verification flag to address 112
        40 => x"23", 41 => x"28", 42 => x"50", 43 => x"06",

        -- HALT
        44 => x"FF", 45 => x"FF", 46 => x"FF", 47 => x"FF",

        -- DATA SECTION
        100 => x"0A", 101 => x"00", 102 => x"00", 103 => x"00",  -- 10
        104 => x"14", 105 => x"00", 106 => x"00", 107 => x"00",  -- 20

        OTHERS => (OTHERS => '0')
    );

    SIGNAL addr_int : INTEGER := 0;

BEGIN
    -- Limit address to prevent out-of-bounds access when reading 4 bytes
    addr_int <= to_integer(unsigned(address(9 DOWNTO 0))) WHEN unsigned(address(9 DOWNTO 0)) <= 1020
                ELSE 0;

    PROCESS (clock)
    BEGIN
        IF rising_edge(clock) AND write_en = '1' THEN
            RAM(addr_int)     <= write_data(7 DOWNTO 0);
            RAM(addr_int + 1) <= write_data(15 DOWNTO 8);
            RAM(addr_int + 2) <= write_data(23 DOWNTO 16);
            RAM(addr_int + 3) <= write_data(31 DOWNTO 24);
        END IF;
    END PROCESS;

    -- read 4 consecutive bytes form one 32-bit word
    data <= RAM(addr_int + 3) &
        RAM(addr_int + 2) &
        RAM(addr_int + 1) &
        RAM(addr_int);

END ARCHITECTURE rtl;
