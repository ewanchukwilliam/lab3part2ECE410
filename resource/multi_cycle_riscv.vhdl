------------------------------------------------------------------------
-- University  : University of Alberta
-- Course      : ECE 410
-- Project     : Lab 3
-- File        : multi_cycle_riscv.vhdl
-- Authors     : Antonio Alejandro Andara Lara
-- Date        : 23-Oct-2025
------------------------------------------------------------------------
-- Description  : Top-level RISC-V CPU combining multi-cycle datapath and control logic.
--                Executes basic load, store, and arithmetic instructions.
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY multi_cycle_riscv IS
    PORT (
        clock  : IN STD_LOGIC;
        reset  : IN STD_LOGIC;
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        ------------------------------------------------------------------------
        -- DEBUG SECTION: Signals for simulation visibility
        ------------------------------------------------------------------------
        debug_pc          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_instruction : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_alu_result  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_op_code     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        debug_funct3      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        debug_funct7_bit5 : OUT STD_LOGIC;
        debug_zero_flag   : OUT STD_LOGIC;
        debug_pc_write    : OUT STD_LOGIC;
        debug_ir_write    : OUT STD_LOGIC;
        debug_mem_write   : OUT STD_LOGIC;
        debug_reg_write   : OUT STD_LOGIC;
        debug_adr_src     : OUT STD_LOGIC;
        debug_result_src  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        debug_alu_src_a   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        debug_alu_src_b   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        debug_alu_ctrl    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        debug_imm_sel     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE structural OF multi_cycle_riscv IS
    SIGNAL zero_flag   : STD_LOGIC := '0';
    SIGNAL adr_src     : STD_LOGIC;
    SIGNAL pc_write    : STD_LOGIC;
    SIGNAL ir_write    : STD_LOGIC;
    SIGNAL mem_write   : STD_LOGIC;
    SIGNAL reg_write   : STD_LOGIC;
    SIGNAL funct7_bit5 : STD_LOGIC;
    SIGNAL output_en   : STD_LOGIC;
    SIGNAL result_src  : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL alu_src_a   : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL alu_src_b   : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL funct3      : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL imm_sel     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_ctrl    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL op_code     : STD_LOGIC_VECTOR(6 DOWNTO 0);

    ------------------------------------------------------------------------
    -- DEBUG SECTION: Additional signals from datapath for visibility
    ------------------------------------------------------------------------
    SIGNAL debug_pc_internal          : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL debug_instruction_internal : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL debug_alu_result_internal  : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    datapath : ENTITY work.multi_cycle_datapath(structural)
        PORT MAP(
            clock       => clock,
            adr_src     => adr_src,
            pc_write    => pc_write,
            ir_write    => ir_write,
            mem_write   => mem_write,
            reg_write   => reg_write,
            output_en   => output_en,
            result_src  => result_src,
            imm_sel     => imm_sel,
            alu_src_a   => alu_src_a,
            alu_src_b   => alu_src_b,
            alu_ctrl    => alu_ctrl,
            op_code     => op_code,
            funct3      => funct3,
            funct7_bit5 => funct7_bit5,
            zero_flag   => zero_flag,
            dp_out      => result,

            -- DEBUG SECTION
            debug_pc          => debug_pc_internal,
            debug_instruction => debug_instruction_internal,
            debug_alu_result  => debug_alu_result_internal
        );

    control_unit : ENTITY work.multi_cycle_controller(behavioral)
        PORT MAP(
            clock       => clock,
            reset       => reset,
            op_code     => op_code,
            funct3      => funct3,
            funct7_bit5 => funct7_bit5,
            zero_flag   => zero_flag,
            output_en   => output_en,
            adr_src     => adr_src,
            pc_write    => pc_write,
            ir_write    => ir_write,
            mem_write   => mem_write,
            reg_write   => reg_write,
            result_src  => result_src,
            imm_sel     => imm_sel,
            alu_src_a   => alu_src_a,
            alu_src_b   => alu_src_b,
            alu_ctrl    => alu_ctrl
        );

    ------------------------------------------------------------------------
    -- DEBUG SECTION: Assign debug outputs
    ------------------------------------------------------------------------
    -- Datapath signals
    debug_pc          <= debug_pc_internal;
    debug_instruction <= debug_instruction_internal;
    debug_alu_result  <= debug_alu_result_internal;

    -- Controller signals
    debug_op_code     <= op_code;
    debug_funct3      <= funct3;
    debug_funct7_bit5 <= funct7_bit5;
    debug_zero_flag   <= zero_flag;
    debug_pc_write    <= pc_write;
    debug_ir_write    <= ir_write;
    debug_mem_write   <= mem_write;
    debug_reg_write   <= reg_write;
    debug_adr_src     <= adr_src;
    debug_result_src  <= result_src;
    debug_alu_src_a   <= alu_src_a;
    debug_alu_src_b   <= alu_src_b;
    debug_alu_ctrl    <= alu_ctrl;
    debug_imm_sel     <= imm_sel;

END structural;
