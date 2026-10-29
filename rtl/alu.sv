// Combinational ALU. Produces the result and the full set of flags the
// instruction would write; ops that leave C unchanged pass carry_in through.
module alu
  import cpu_pkg::*;
(
  input  alu_op_e op,
  input  data_t   a,
  input  data_t   b,
  input  logic    carry_in,
  output data_t   result,
  output flags_t  flags
);

  logic [XLEN:0]     wide;  // result with carry/borrow in the top bit
  logic [2*XLEN-1:0] rot;
  logic [2:0]        amt;
  logic              is_add, is_sub;

  assign amt = b[2:0];

  always_comb begin
    wide   = '0;
    rot    = '0;
    is_add = 1'b0;
    is_sub = 1'b0;

    unique case (op)
      ALU_ADD: begin wide = {1'b0, a} + {1'b0, b};                         is_add = 1'b1; end
      ALU_ADC: begin wide = {1'b0, a} + {1'b0, b} + {{XLEN{1'b0}}, carry_in}; is_add = 1'b1; end
      ALU_SUB: begin wide = {1'b0, a} - {1'b0, b};                         is_sub = 1'b1; end
      ALU_SBC: begin wide = {1'b0, a} - {1'b0, b} - {{XLEN{1'b0}}, carry_in}; is_sub = 1'b1; end
      ALU_AND: wide[XLEN-1:0] = a & b;
      ALU_OR:  wide[XLEN-1:0] = a | b;
      ALU_XOR: wide[XLEN-1:0] = a ^ b;
      ALU_NOT: wide[XLEN-1:0] = ~a;
      ALU_SHL: wide[XLEN-1:0] = a << amt;
      ALU_SHR: wide[XLEN-1:0] = a >> amt;
      ALU_ASR: wide[XLEN-1:0] = $signed(a) >>> amt;
      ALU_ROL: begin rot = {a, a} << amt; wide[XLEN-1:0] = rot[2*XLEN-1:XLEN]; end
      ALU_ROR: begin rot = {a, a} >> amt; wide[XLEN-1:0] = rot[XLEN-1:0];      end
      default: wide = '0;
    endcase
  end

  assign result  = wide[XLEN-1:0];
  assign flags.z = (result == '0);
  assign flags.n = result[XLEN-1];
  assign flags.c = (is_add || is_sub) ? wide[XLEN] : carry_in;
  assign flags.v = is_add ? (a[XLEN-1] == b[XLEN-1]) && (result[XLEN-1] != a[XLEN-1]) :
                   is_sub ? (a[XLEN-1] != b[XLEN-1]) && (result[XLEN-1] != a[XLEN-1]) :
                            1'b0;

endmodule
