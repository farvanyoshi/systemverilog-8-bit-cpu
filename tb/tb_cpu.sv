// Runs a program on cpu_top until HALT and checks the expectations file.
//
// Plusargs:
//   +PROG=<file.hex>    program image for $readmemh (required)
//   +EXPECT=<file.exp>  expectations; one per line:  mem <addr> <data>
//                                                     reg <n> <data>   (hex)
//   +MAX_CYCLES=<n>     give up after n cycles (default 100000)
//   +TRACE              print one line per executed instruction
//   +WAVE=<file.fst>    dump waveforms
module tb_cpu;
  import cpu_pkg::*;

  logic clk, rst, halted;

  cpu_top dut (.clk, .rst, .halted);

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  function automatic data_t reg_value(int n);
    return n == 0 ? '0 : dut.u_core.u_regfile.regs[n];
  endfunction

  task automatic trace_line(int cycle);
    $write("%6d  pc=%03h  ir=%04h  ", cycle, dut.u_core.ir_pc, dut.u_core.ir);
    for (int i = 1; i < 8; i++) $write("r%0d=%02h ", i, reg_value(i));
    $display(" sp=%02h vnzc=%04b", dut.u_core.sp, dut.u_core.flags);
  endtask

  function automatic int check_expectations(string path);
    int    fd, errors, a, d, got;
    string line, kind;

    errors = 0;
    fd = $fopen(path, "r");
    if (fd == 0) $fatal(1, "cannot open %s", path);
    while ($fgets(line, fd) != 0) begin
      if ($sscanf(line, "%s %h %h", kind, a, d) != 3) continue;
      if (kind == "mem")      got = dut.u_ram.mem[a];
      else if (kind == "reg") got = reg_value(a);
      else continue;
      if (got != d) begin
        $display("FAIL %s[%02h] = %02h, want %02h", kind, a, got, d);
        errors++;
      end
    end
    $fclose(fd);
    return errors;
  endfunction

  initial begin
    string prog, expect_path, wave;
    int    max_cycles, cycle, errors;
    bit    trace;

    if (!$value$plusargs("PROG=%s", prog)) $fatal(1, "missing +PROG=<file.hex>");
    if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 100000;
    trace = $test$plusargs("TRACE");
    if ($value$plusargs("WAVE=%s", wave)) begin
      $dumpfile(wave);
      $dumpvars(0, tb_cpu);
    end

    rst = 1'b1;
    #1 $readmemh(prog, dut.u_rom.mem);
    repeat (2) @(posedge clk);
    #1 rst = 1'b0;

    cycle = 0;
    while (!halted && cycle < max_cycles) begin
      if (trace) trace_line(cycle);
      @(posedge clk);
      #1 cycle++;
    end
    if (trace) trace_line(cycle);

    if (!halted) $fatal(1, "%s: did not halt within %0d cycles", prog, max_cycles);

    errors = 0;
    if ($value$plusargs("EXPECT=%s", expect_path)) errors = check_expectations(expect_path);

    if (errors != 0) $fatal(1, "%s: %0d errors", prog, errors);
    $display("%s: PASS (%0d cycles)", prog, cycle);
    $finish;
  end
endmodule
