// Exhaustive ALU test: every op, every pair of operands, both carry-in values,
// checked against an integer reference model.
module tb_alu;
  import cpu_pkg::*;

  alu_op_e op;
  data_t   a, b, result;
  logic    carry_in;
  flags_t  flags;

  alu dut (.*);

  int errors = 0;

  function automatic void check(alu_op_e o, int ia, int ib, int ic, data_t r, flags_t f);
    int     sa, sb, sr, full, amt, exp_r;
    logic   exp_c, exp_v;

    sa    = ia >= 128 ? ia - 256 : ia;
    sb    = ib >= 128 ? ib - 256 : ib;
    amt   = ib % 8;
    exp_c = ic[0];
    exp_v = 1'b0;

    case (o)
      ALU_ADD, ALU_ADC: begin
        full  = ia + ib + (o == ALU_ADC ? ic : 0);
        exp_r = full % 256;
        exp_c = full > 255;
        sr    = sa + sb + (o == ALU_ADC ? ic : 0);
        exp_v = sr > 127 || sr < -128;
      end
      ALU_SUB, ALU_SBC: begin
        full  = ia - ib - (o == ALU_SBC ? ic : 0);
        exp_r = (full + 512) % 256;
        exp_c = full < 0;
        sr    = sa - sb - (o == ALU_SBC ? ic : 0);
        exp_v = sr > 127 || sr < -128;
      end
      ALU_AND: exp_r = ia & ib;
      ALU_OR:  exp_r = ia | ib;
      ALU_XOR: exp_r = ia ^ ib;
      ALU_NOT: exp_r = 255 - ia;
      ALU_SHL: exp_r = (ia * (1 << amt)) % 256;
      ALU_SHR: exp_r = ia / (1 << amt);
      ALU_ASR: exp_r = ((sa >>> amt) + 256) % 256;
      ALU_ROL: exp_r = ((ia * (1 << amt)) % 256) | (ia / (1 << (8 - amt)) % 256);
      ALU_ROR: exp_r = (ia / (1 << amt)) | ((ia * (1 << (8 - amt))) % 256);
      default: exp_r = 0;
    endcase

    if (r !== data_t'(exp_r) || f.c !== exp_c || f.v !== exp_v ||
        f.z !== (exp_r == 0) || f.n !== (exp_r >= 128)) begin
      if (errors < 10)
        $display("FAIL %s a=%02h b=%02h c=%0d: got r=%02h f=%b, want r=%02h vnzc=%b%b%b%b",
                 o.name(), ia, ib, ic, r, f, exp_r[7:0], exp_v, exp_r >= 128, exp_r == 0, exp_c);
      errors++;
    end
  endfunction

  initial begin
    for (int o = 0; o <= int'(ALU_ROR); o++)
      for (int ia = 0; ia < 256; ia++)
        for (int ib = 0; ib < 256; ib++)
          for (int ic = 0; ic < 2; ic++) begin
            op       = alu_op_e'(o);
            a        = data_t'(ia);
            b        = data_t'(ib);
            carry_in = ic[0];
            #1;
            check(op, ia, ib, ic, result, flags);
          end

    if (errors != 0) $fatal(1, "tb_alu: %0d errors", errors);
    $display("tb_alu: PASS");
    $finish;
  end
endmodule
