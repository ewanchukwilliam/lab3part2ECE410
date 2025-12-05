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

        -- Load first number from memory
        -- lw x1, 100(x0)    -- x1 = 10 (first number)
        0 => x"83", 1 => x"20", 2 => x"40", 3 => x"06",

        -- Load second number from memory
        -- lw x2, 104(x0)    -- x2 = 20 (second number)
        4 => x"03", 5 => x"21", 6 => x"80", 7 => x"06",

        -- Add the two numbers
        -- add x3, x1, x2    -- x3 = 10 + 20 = 30
        8 => x"B3", 9 => x"81", 10 => x"20", 11 => x"00",

        -- Divide by 2 (shift right by 1)
        -- srai x4, x3, 1    -- x4 = 30 >> 1 = 15 (average)
        12 => x"13", 13 => x"D2", 14 => x"11", 15 => x"40",

        -- Store result to memory
        -- sw x4, 108(x0)    -- Store average (15) to address 108
        16 => x"23", 17 => x"26", 18 => x"C0", 19 => x"06",

        -- Halt execution
        -- halt
        20 => x"FF", 21 => x"FF", 22 => x"FF", 23 => x"FF",

        -- DATA SECTION
        100 => x"0A", 101 => x"00", 102 => x"00", 103 => x"00",  -- 10 (first number)
        104 => x"14", 105 => x"00", 106 => x"00", 107 => x"00",  -- 20 (second number)
        -- 108 will contain result: 15 (0x0F) after program runs

        OTHERS => (OTHERS => '0')
    );

    SIGNAL addr_int : INTEGER := 0;

BEGIN
    addr_int <= to_integer(unsigned(address(9 DOWNTO 0))); -- Address conversion fits 1 KB

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
