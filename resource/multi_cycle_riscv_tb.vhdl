------------------------------------------------------------------------
-- University  : University of Alberta
-- Course      : ECE 410
-- Project     : Lab 3
-- File        : multi_cycle_riscv_tb.vhdl
-- Authors     : Antonio Alejandro Andara Lara
-- Date        : 23-Oct-2025
------------------------------------------------------------------------
-- Description  : Testbench for the multi cycle RISC-V CPU core
--                Program is preloaded in the combined memory module
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY multi_cycle_riscv_tb IS
END ENTITY;

ARCHITECTURE tb OF multi_cycle_riscv_tb IS

    SIGNAL clock  : STD_LOGIC                     := '0';
    SIGNAL reset  : STD_LOGIC                     := '0';
    SIGNAL result : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    ------------------------------------------------------------------------
    -- DEBUG SECTION: Signals for monitoring internal CPU state
    ------------------------------------------------------------------------
    SIGNAL debug_pc          : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL debug_instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL debug_alu_result  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL debug_op_code     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL debug_funct3      : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL debug_funct7_bit5 : STD_LOGIC;
    SIGNAL debug_zero_flag   : STD_LOGIC;
    SIGNAL debug_pc_write    : STD_LOGIC;
    SIGNAL debug_ir_write    : STD_LOGIC;
    SIGNAL debug_mem_write   : STD_LOGIC;
    SIGNAL debug_reg_write   : STD_LOGIC;
    SIGNAL debug_adr_src     : STD_LOGIC;
    SIGNAL debug_result_src  : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL debug_alu_src_a   : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL debug_alu_src_b   : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL debug_alu_ctrl    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL debug_imm_sel     : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

    DUT : ENTITY work.multi_cycle_riscv(structural)
        PORT MAP(
            clock  => clock,
            reset  => reset,
            result => result,

            -- DEBUG SECTION
            debug_pc          => debug_pc,
            debug_instruction => debug_instruction,
            debug_alu_result  => debug_alu_result,
            debug_op_code     => debug_op_code,
            debug_funct3      => debug_funct3,
            debug_funct7_bit5 => debug_funct7_bit5,
            debug_zero_flag   => debug_zero_flag,
            debug_pc_write    => debug_pc_write,
            debug_ir_write    => debug_ir_write,
            debug_mem_write   => debug_mem_write,
            debug_reg_write   => debug_reg_write,
            debug_adr_src     => debug_adr_src,
            debug_result_src  => debug_result_src,
            debug_alu_src_a   => debug_alu_src_a,
            debug_alu_src_b   => debug_alu_src_b,
            debug_alu_ctrl    => debug_alu_ctrl,
            debug_imm_sel     => debug_imm_sel
        );

    PROCESS IS BEGIN
        reset <= '1';
        WAIT FOR 1 ns;
        reset <= '0';
        WAIT FOR 1 ns;
        FOR i IN 0 TO 40 LOOP
            clock <= '1';
            WAIT FOR 2 ns;
            clock <= '0';
            WAIT FOR 2 ns;
        END LOOP;
        WAIT;
    END PROCESS;

END ARCHITECTURE;
