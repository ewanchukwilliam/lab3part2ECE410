------------------------------------------------------------------------
-- University  : University of Alberta
-- Course      : ECE 410
-- Project     : Lab 3
-- File        : multi_cycle_controller.vhdl
-- Authors     : Antonio Alejandro Andara Lara
-- Date        : 23-Oct-2025
------------------------------------------------------------------------
-- Description  : RISC-V Multi-Cycle Controller
-- Two-process FSM implementation with current_state and next_state.
-- Controls sequencing of datapath operations across FETCH, DECODE, MEMORY, etc.
-- Generates control signals for ALU, memory, register file, and immediate logic.
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY multi_cycle_controller IS
    PORT (
        clock       : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        op_code     : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        funct3      : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        funct7_bit5 : IN  STD_LOGIC;
        zero_flag   : IN  STD_LOGIC;
        output_en   : OUT STD_LOGIC;
        adr_src     : OUT STD_LOGIC;
        pc_write    : OUT STD_LOGIC;
        ir_write    : OUT STD_LOGIC;
        mem_write   : OUT STD_LOGIC;
        reg_write   : OUT STD_LOGIC;
        result_src  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        imm_sel     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_src_a   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_src_b   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        alu_ctrl    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END multi_cycle_controller;

ARCHITECTURE behavioral OF multi_cycle_controller IS

    --------------------------------------------------------------------------
    -- State and Instruction Type Definitions
    --------------------------------------------------------------------------
    TYPE instr IS (LW, SW, ADD, SUB, ADDI, BEQ, SRAI, HALT, NOP);
    TYPE instruction_type IS (U, J, I, S, B, R);
    TYPE state_type IS (
        RESET_INIT,
        FETCH,
        DECODE,
        MEM_ADR,
        MEM_READ,
        MEM_WB,
        ALU_WB,
        MEM_W,
        BRANCH,
        HALTED
    );

    SIGNAL current_state, next_state : state_type := RESET_INIT;
    SIGNAL instr_type : instruction_type;    
    SIGNAL instruction : instr;

    --------------------------------------------------------------------------
    -- Opcode definitions
    --------------------------------------------------------------------------
    CONSTANT OPCODE_LW    : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000011";
    CONSTANT OPCODE_SW    : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100011";
    CONSTANT OPCODE_ADD   : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110011";  -- R-type
    CONSTANT OPCODE_ITYPE : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010011";  -- I-type ALU (ADDI)
    CONSTANT OPCODE_BEQ   : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100011";  -- Branch
    CONSTANT OPCODE_HALT  : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111111";  -- Custom HALT

    TYPE imm_codes IS ARRAY (instruction_type) OF STD_LOGIC_VECTOR(2 DOWNTO 0);
    CONSTANT imm_code : imm_codes := (
        U => "000",
        J => "001",
        I => "010",
        S => "011",
        B => "100",
        R => "111"
    );

    --------------------------------------------------------------------------
    -- Control signals
    --------------------------------------------------------------------------
    SIGNAL adr_src_s    : STD_LOGIC;
    SIGNAL pc_write_s   : STD_LOGIC;
    SIGNAL ir_write_s   : STD_LOGIC;
    SIGNAL mem_write_s  : STD_LOGIC;
    SIGNAL reg_write_s  : STD_LOGIC;
    SIGNAL result_src_s : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL imm_sel_s    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_src_a_s  : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL alu_src_b_s  : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL alu_ctrl_s   : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL aux : STD_LOGIC_VECTOR(10 DOWNTO 0); -- added for visibility

BEGIN

    --------------------------------------------------------------------------
    -- Control signal assignments to output ports
    --------------------------------------------------------------------------
    adr_src    <= adr_src_s;
    pc_write   <= pc_write_s;
    ir_write   <= ir_write_s;
    mem_write  <= mem_write_s;
    reg_write  <= reg_write_s;
    result_src <= result_src_s;
    imm_sel    <= imm_sel_s;
    alu_src_a  <= alu_src_a_s;
    alu_src_b  <= alu_src_b_s;
    alu_ctrl   <= alu_ctrl_s;
    output_en  <= '1';

    --------------------------------------------------------------------------
    -- Instruction decoding and immediate selection
    --------------------------------------------------------------------------
    -- Instruction decoding: enhanced to distinguish SUB, BNE, ADDI
    PROCESS (op_code, funct3, funct7_bit5)
    BEGIN
        -- Default values
        instruction <= NOP;
        instr_type <= R;

        IF op_code = OPCODE_LW THEN
            instruction <= LW;
            instr_type <= I;
        ELSIF op_code = OPCODE_SW THEN
            instruction <= SW;
            instr_type <= S;
        ELSIF op_code = OPCODE_ADD THEN
            instr_type <= R;
            -- Distinguish ADD vs SUB using funct7_bit5
            IF funct3 = "000" AND funct7_bit5 = '0' THEN
                instruction <= ADD;
            ELSIF funct3 = "000" AND funct7_bit5 = '1' THEN
                instruction <= SUB;
            END IF;
        ELSIF op_code = OPCODE_ITYPE THEN
            instr_type <= I;
            IF funct3 = "000" THEN
                instruction <= ADDI;
            ELSIF funct3 = "101" AND funct7_bit5 = '1' THEN
                instruction <= SRAI;
            END IF;
        ELSIF op_code = OPCODE_BEQ THEN
            instr_type <= B;
            IF funct3 = "000" THEN
                instruction <= BEQ;
            END IF;
        ELSIF op_code = OPCODE_HALT THEN
            instruction <= HALT;
            instr_type <= R;
        ELSE
            instruction <= NOP;
            instr_type <= R;
        END IF;
    END PROCESS;

    imm_sel_s <= imm_code(instr_type);

    aux <= funct7_bit5 & funct3 & op_code;

    --------------------------------------------------------------------------
    -- Sequential process: state register update
    --------------------------------------------------------------------------
    PROCESS (clock, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= RESET_INIT;
        ELSIF rising_edge(clock) THEN
            current_state <= next_state;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------------
    -- Combinational process: next state and control signal logic
    --------------------------------------------------------------------------
    PROCESS (current_state, op_code, instruction, zero_flag)
    BEGIN
        -- Default control signal values
        -- Instruction register and program counter updates
        pc_write_s   <= '0';
        ir_write_s   <= '0';

        -- Memory and register file write controls
        mem_write_s  <= '0';
        reg_write_s  <= '0';

        -- Source selection (multiplexer controls)
        adr_src_s    <= '0';  -- 0 = PC, 1 = result mux output.
        alu_src_a_s  <= "01"; -- Select ALU operand A source (00 = PC_old, 01 = PC, 10 = rs1_reg)
        alu_src_b_s  <= "10"; -- Select ALU operand B source (00 = rs2_reg, 01 = imm_ext, 10 = 4)
        result_src_s <= "01"; -- Select result source (00 = ALU_reg, 01 = ALU_out, 10 = data_reg)

        -- ALU operation control
        alu_ctrl_s   <= "100"; -- 100 = addition

        next_state   <= current_state;  -- default

        CASE current_state IS
            WHEN RESET_INIT =>
                next_state   <= FETCH;
                ir_write_s   <= '1';
                pc_write_s   <= '1';

            WHEN FETCH =>
                next_state   <= DECODE;
                IF op_code = OPCODE_BEQ THEN
                    alu_src_a_s  <= "00";
                    alu_src_b_s  <= "01";
                END IF;

            WHEN DECODE =>
                CASE op_code IS
                    WHEN OPCODE_LW | OPCODE_SW =>
                        next_state   <= MEM_ADR;
                        alu_src_a_s  <= "10";
                        alu_src_b_s  <= "01";
                        result_src_s <= "00";

                    WHEN OPCODE_ADD =>
                        next_state   <= ALU_WB;
                        reg_write_s  <= '1';
                        -- Set ALU control based on SUB vs ADD
                        IF instruction = SUB THEN
                            alu_ctrl_s <= "101";  -- SUB
                        END IF;

                    WHEN OPCODE_ITYPE =>
                        -- I-type ALU instructions like ADDI and SRAI
                        next_state   <= ALU_WB;
                        alu_src_a_s  <= "10";  -- rs1_reg
                        alu_src_b_s  <= "01";  -- imm_ext
                        result_src_s <= "01";  -- alu_result
                        reg_write_s  <= '1';
                        -- Set ALU control based on instruction type
                        IF instruction = SRAI THEN
                            alu_ctrl_s <= "111";  -- Shift Right Arithmetic
                        ELSE
                            alu_ctrl_s <= "100";  -- ADD (for ADDI)
                        END IF;

                    WHEN OPCODE_BEQ =>
                        next_state <= BRANCH;
                        alu_src_a_s  <= "10";
                        alu_src_b_s  <= "00";
                        alu_ctrl_s   <= "101";
                        result_src_s <= "00";
                        -- BEQ branches when equal (zero_flag = 1)
                        pc_write_s <= zero_flag;

                    WHEN OPCODE_HALT =>
                        next_state <= HALTED;

                    WHEN OTHERS =>
                        NULL;
                END CASE;

            WHEN MEM_ADR =>
                result_src_s <= "00";
                adr_src_s    <= '1';

                CASE instruction IS
                    WHEN LW =>
                        next_state <= MEM_READ;    

                    WHEN SW =>
                        next_state   <= MEM_W;
                        mem_write_s  <= '1';

                    WHEN OTHERS =>
                        next_state <= FETCH;
                END CASE;

            WHEN MEM_READ =>
                next_state   <= MEM_WB;
                result_src_s <= "10";
                reg_write_s  <= '1';

            WHEN MEM_WB | ALU_WB | MEM_W | BRANCH =>
                next_state    <= FETCH;
                ir_write_s    <= '1';
                pc_write_s    <= '1';

            WHEN HALTED =>
                -- Stay in HALTED state until reset
                next_state    <= HALTED;
                pc_write_s    <= '0';
                ir_write_s    <= '0';
                mem_write_s   <= '0';
                reg_write_s   <= '0';

            WHEN OTHERS =>
                next_state <= FETCH;

        END CASE;
    END PROCESS;

END behavioral;
