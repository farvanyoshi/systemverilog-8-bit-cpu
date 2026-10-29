// Tests the data stack pointer and the return-address stack.
module tb_stacks;
  import cpu_pkg::*;

  logic  clk, clear;
  logic  inc, dec;
  data_t sp, sp_dec;
  logic  push, pop;
  pc_t   push_addr, top;

  data_stack dstack (.clk, .clear, .inc, .dec, .sp, .sp_dec);
  ret_stack  rstack (.clk, .clear, .push, .pop, .push_addr, .top);

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  int errors = 0;

  task automatic tick();
    @(posedge clk);
    #1;
    {inc, dec, push, pop} = '0;
  endtask

  task automatic check(string what, int got, int want);
    if (got != want) begin
      $display("FAIL %s = %h, want %h", what, got, want);
      errors++;
    end
  endtask

  initial begin
    {inc, dec, push, pop} = '0;
    push_addr = '0;
    clear     = 1'b1;
    tick();
    clear = 1'b0;

    // Data stack: first push targets 0xFF and the pointer follows it.
    check("sp", sp, 'h00);
    check("sp_dec", sp_dec, 'hFF);
    dec = 1'b1;
    tick();
    check("sp after push", sp, 'hFF);
    dec = 1'b1;
    tick();
    check("sp after 2 pushes", sp, 'hFE);
    inc = 1'b1;
    tick();
    inc = 1'b1;
    tick();
    check("sp after 2 pops", sp, 'h00);

    // Return stack: LIFO order, nesting.
    for (int i = 1; i <= 5; i++) begin
      push      = 1'b1;
      push_addr = pc_t'(i * 100);
      tick();
      check("ras top after push", top, i * 100);
    end
    for (int i = 5; i >= 1; i--) begin
      check("ras top before pop", top, i * 100);
      pop = 1'b1;
      tick();
    end

    // Clear empties the return stack.
    push      = 1'b1;
    push_addr = 11'h55;
    tick();
    clear = 1'b1;
    tick();
    clear     = 1'b0;
    push      = 1'b1;
    push_addr = 11'h66;
    tick();
    pop = 1'b1;
    tick();
    push      = 1'b1;
    push_addr = 11'h77;
    tick();
    check("ras top after clear", top, 'h77);
    check("sp after clear", sp, 'h00);

    if (errors != 0) $fatal(1, "tb_stacks: %0d errors", errors);
    $display("tb_stacks: PASS");
    $finish;
  end
endmodule
