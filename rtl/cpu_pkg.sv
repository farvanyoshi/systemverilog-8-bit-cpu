// Shared types and constants for the 8-bit CPU. See docs/ISA.md.
package cpu_pkg;

  localparam int XLEN = 8;   // data width
  localparam int ILEN = 16;  // instruction width
  localparam int PCW  = 11;  // program counter width

  typedef logic [XLEN-1:0] data_t;
  typedef logic [ILEN-1:0] instr_t;
  typedef logic [PCW-1:0]  pc_t;
  typedef logic [2:0]      reg_idx_t;

  typedef enum logic [4:0] {
    OP_ADD   = 5'b00000,
    OP_ADC   = 5'b00001,
    OP_SUB   = 5'b00010,
    OP_SBC   = 5'b00011,
    OP_AND   = 5'b00100,
    OP_OR    = 5'b00101,
    OP_XOR   = 5'b00110,
    OP_NOT   = 5'b00111,
    OP_SHL   = 5'b01000,
    OP_SHR   = 5'b01001,
    OP_ASR   = 5'b01010,
    OP_ROL   = 5'b01011,
    OP_ROR   = 5'b01100,
    OP_ADDI  = 5'b01101,
    OP_SUBI  = 5'b01110,
    OP_LDI   = 5'b01111,
    OP_LDA   = 5'b10000,
    OP_SDA   = 5'b10001,
    OP_LIA   = 5'b10010,
    OP_SIA   = 5'b10011,
    OP_BRZ   = 5'b10100,
    OP_BRN   = 5'b10101,
    OP_BRV   = 5'b10110,
    OP_ACALL = 5'b10111,
    OP_JMP   = 5'b11000,
    OP_RCALL = 5'b11001,
    OP_PUSH  = 5'b11010,
    OP_POP   = 5'b11011,
    OP_RET   = 5'b11100,
    OP_NOP   = 5'b11101,
    OP_RESET = 5'b11110,
    OP_HALT  = 5'b11111
  } opcode_e;

  // Inserted behind a taken branch, and loaded into the IR on reset.
  localparam instr_t NOP_INSTR = {OP_NOP, 11'b0};

  typedef enum logic [3:0] {
    ALU_ADD,
    ALU_ADC,
    ALU_SUB,
    ALU_SBC,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_NOT,
    ALU_SHL,
    ALU_SHR,
    ALU_ASR,
    ALU_ROL,
    ALU_ROR
  } alu_op_e;

  typedef struct packed {
    logic v;
    logic n;
    logic z;
    logic c;
  } flags_t;

  // Register write-back source.
  typedef enum logic [1:0] {
    WB_ALU,
    WB_IMM,
    WB_MEM
  } wb_sel_e;

  // Data memory address source.
  typedef enum logic [1:0] {
    ADDR_DIRECT,   // imm8
    ADDR_INDEXED,  // rs1 + imm5
    ADDR_SP,       // sp (POP)
    ADDR_SP_DEC    // sp - 1 (PUSH)
  } addr_sel_e;

  // Next-PC source when the instruction redirects.
  typedef enum logic [1:0] {
    PC_SEQ,  // no redirect
    PC_REL,  // here + sext(rel11)
    PC_ABS,  // imm11
    PC_RET   // top of return stack
  } pc_sel_e;

  // Condition tested by a PC_REL redirect.
  typedef enum logic [1:0] {
    COND_ALWAYS,
    COND_Z,
    COND_N,
    COND_V
  } cond_e;

  typedef struct packed {
    logic      reg_we;
    wb_sel_e   wb_sel;
    logic      ra_is_rd;    // read port A addresses rd instead of rs1
    logic      rb_is_rd;    // read port B addresses rd instead of rs2
    alu_op_e   alu_op;
    logic      alu_b_imm;   // ALU operand B is imm8 instead of port B
    logic      flags_we;
    logic      mem_we;
    addr_sel_e addr_sel;
    logic      sp_inc;
    logic      sp_dec;
    pc_sel_e   pc_sel;
    cond_e     cond;
    logic      ras_push;
    logic      ras_pop;
    logic      soft_reset;
    logic      halt;
  } ctrl_t;

endpackage
