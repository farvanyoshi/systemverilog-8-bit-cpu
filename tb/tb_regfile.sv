module tb_regfile;
  import cpu_pkg::*;

  logic     clk;
  logic     clear;
  reg_idx_t ra_addr, rb_addr, wr_addr;
  data_t    ra_data, rb_data, wr_data;
  logic     we;

  regfile dut (.*);

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  data_t model[8];
  int    errors = 0;

  task automatic write(int r, int d);
    we      = 1'b1;
    wr_addr = reg_idx_t'(r);
    wr_data = data_t'(d);
    @(posedge clk);
    #1;
    we = 1'b0;
    if (r != 0) model[r] = data_t'(d);
  endtask

  task automatic check_all();
    for (int i = 0; i < 8; i++) begin
      ra_addr = reg_idx_t'(i);
      rb_addr = reg_idx_t'(7 - i);
      #1;
      if (ra_data !== model[i] || rb_data !== model[7 - i]) begin
        $display("FAIL r%0d=%02h (want %02h), r%0d=%02h (want %02h)",
                 i, ra_data, model[i], 7 - i, rb_data, model[7 - i]);
        errors++;
      end
    end
  endtask

  initial begin
    we    = 1'b0;
    clear = 1'b1;
    @(posedge clk);
    #1;
    clear = 1'b0;
    foreach (model[i]) model[i] = '0;
    check_all();

    // Writes to r0 are ignored.
    write(0, 'hFF);
    check_all();

    for (int i = 1; i < 8; i++) write(i, 'h10 * i + i);
    check_all();

    // Overwrite and random traffic.
    for (int n = 0; n < 200; n++) write($urandom_range(0, 7), $urandom_range(0, 255));
    check_all();

    // Writes are not visible until the clock edge.
    we      = 1'b1;
    wr_addr = 3'd3;
    wr_data = ~model[3];
    ra_addr = 3'd3;
    #1;
    if (ra_data !== model[3]) begin
      $display("FAIL write visible before clock edge");
      errors++;
    end
    @(posedge clk);
    #1;
    we       = 1'b0;
    model[3] = ~model[3];
    check_all();

    clear = 1'b1;
    @(posedge clk);
    #1;
    clear = 1'b0;
    foreach (model[i]) model[i] = '0;
    check_all();

    if (errors != 0) $fatal(1, "tb_regfile: %0d errors", errors);
    $display("tb_regfile: PASS");
    $finish;
  end
endmodule
