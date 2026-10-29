// CPU core with its instruction ROM and data RAM.
module cpu_top
  import cpu_pkg::*;
#(
  parameter string ROM_FILE = ""
) (
  input  logic clk,
  input  logic rst,
  output logic halted
);

  pc_t    imem_addr;
  instr_t imem_data;
  data_t  dmem_addr, dmem_wdata, dmem_rdata;
  logic   dmem_we;

  cpu_core u_core (
    .clk,
    .rst,
    .imem_addr,
    .imem_data,
    .dmem_addr,
    .dmem_we,
    .dmem_wdata,
    .dmem_rdata,
    .halted
  );

  rom #(.INIT_FILE(ROM_FILE)) u_rom (
    .addr (imem_addr),
    .data (imem_data)
  );

  ram u_ram (
    .clk,
    .addr  (dmem_addr),
    .we    (dmem_we),
    .wdata (dmem_wdata),
    .rdata (dmem_rdata)
  );

endmodule
