`timescale 1ns / 1ps

`include "cfg.sv"

module cpu_tb();

parameter CYCLE      = 10;
parameter DATA_WIDTH = 32;

logic                           r_clk;
logic                           r_rst_n;

always #(CYCLE / 2) r_clk = ~r_clk;

initial begin
    $readmemh("data/inst.hex", u_cpu.u_ram.r_ram);
end

initial begin
    r_clk   = 1'h0;
    r_rst_n = 1'h0;
    #(CYCLE * 1);
    r_rst_n = 1'h1;
    #(CYCLE * 100);
    $finish;
end

cpu #(
    .DATA_WIDTH(DATA_WIDTH)
) u_cpu(
    .i_sys_clk  (r_clk),
    .i_sys_rst_n(r_rst_n)
);

endmodule
