module ifu2idu(
    input  logic                       i_sys_clk,
    input  logic                       i_sys_rst_n,
    input  logic                       i_sys_pc_en,

    output logic                       o_i2i_st_en,

    input  logic                       i_ifu_valid,
    output logic                       o_i2i_ready,
    input  logic                       i_idu_ready,
    output logic                       o_i2i_valid,

    input  logic [`ADDR_WIDTH - 1 : 0] i_ifu_pc,
    output logic [`ADDR_WIDTH - 1 : 0] o_i2i_pc
);

    logic r_i2i_st_en;

    always_ff @(posedge i_sys_clk) begin
        if (!i_sys_rst_n) begin
            r_i2i_st_en <= 1'b0;
        end
        else if (i_ifu_valid && o_i2i_ready) begin
            r_i2i_st_en <= 1'b1;
        end
        else if (i_sys_pc_en) begin
            r_i2i_st_en <= 1'b0;
        end
        else begin
            r_i2i_st_en <= r_i2i_st_en;
        end
    end

    assign o_i2i_st_en = r_i2i_st_en;

    assign o_i2i_ready = 1'b1;
    assign o_i2i_valid = 1'b1;

    logic [`ADDR_WIDTH - 1 : 0] r_i2i_pc;

    always_ff @(i_sys_clk) begin
        if (!i_sys_rst_n) begin
            r_i2i_pc <= `ADDR_ZERO;
        end
        else if (i_ifu_valid && o_i2i_ready) begin
            r_i2i_pc <= i_ifu_pc;
        end
        else begin
            r_i2i_pc <= r_i2i_pc;
        end
    end

    assign o_i2i_pc = r_i2i_pc;

endmodule
