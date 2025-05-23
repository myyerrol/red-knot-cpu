module idu(
    input  logic                       i_sys_ready,
    output logic                       o_sys_valid,

    input  logic [`INST_WIDTH - 1 : 0] i_ram_inst,

    output logic [`ARGS_WIDTH - 1 : 0] o_idu_ctr_alu_type,
    output logic [`ARGS_WIDTH - 1 : 0] o_idu_ctr_alu_rs1,
    output logic [`ARGS_WIDTH - 1 : 0] o_idu_ctr_alu_rs2,
    output logic [`ARGS_WIDTH - 1 : 0] o_idu_ctr_jmp_type,
    output logic                       o_idu_ctr_ram_wr_en,
    output logic [`ARGS_WIDTH - 1 : 0] o_idu_ctr_ram_byt,
    output logic                       o_idu_ctr_reg_wr_en,
    output logic [`ARGS_WIDTH - 1 : 0] o_idu_ctr_reg_wr_src,

    input  logic [`DATA_WIDTH - 1 : 0] i_gpr_rs1_data,
    input  logic [`DATA_WIDTH - 1 : 0] i_gpr_rs2_data,
    output logic [`GPRS_WIDTH - 1 : 0] o_idu_gpr_rs1_id,
    output logic [`GPRS_WIDTH - 1 : 0] o_idu_gpr_rs2_id,
    output logic [`GPRS_WIDTH - 1 : 0] o_idu_gpr_rd_id,

    input  logic [`ADDR_WIDTH - 1 : 0] i_ifu_pc,
    output logic [`DATA_WIDTH - 1 : 0] o_idu_rs1_data,
    output logic [`DATA_WIDTH - 1 : 0] o_idu_rs2_data,

    output logic [`DATA_WIDTH - 1 : 0] o_idu_jmp_or_reg_data,
    output logic                       o_idu_end_flag
);

    assign o_sys_valid = 1'b1;

    logic [              6 : 0] w_inst_opcode;
    logic [              2 : 0] w_inst_funct3;
    logic [              6 : 0] w_inst_funct7;
    logic [`GPRS_WIDTH - 1 : 0] w_inst_rs1_id;
    logic [`GPRS_WIDTH - 1 : 0] w_inst_rs2_id;
    logic [`GPRS_WIDTH - 1 : 0] w_inst_rd_id;
    logic [`DATA_WIDTH - 1 : 0] w_inst_imm;

    assign w_inst_opcode = i_ram_inst[ 6 :  0];
    assign w_inst_funct3 = i_ram_inst[14 : 12];
    assign w_inst_funct7 = i_ram_inst[31 : 25];
    assign w_inst_rs1_id = i_ram_inst[19 : 15];
    assign w_inst_rs2_id = i_ram_inst[24 : 20];
    assign w_inst_rd_id  = i_ram_inst[11 :  7];

    imm u_imm(
        .i_imm_inst  (i_ram_inst   ),
        .i_imm_opcode(w_inst_opcode),
        .o_imm_data  (w_inst_imm   )
    );

    logic [`ARGS_WIDTH - 1 : 0] w_ctr_alu_type;
    logic [`ARGS_WIDTH - 1 : 0] w_ctr_alu_rs1;
    logic [`ARGS_WIDTH - 1 : 0] w_ctr_alu_rs2;
    logic [`ARGS_WIDTH - 1 : 0] w_ctr_jmp_type;
    logic                       w_ctr_ram_wr_en;
    logic [`ARGS_WIDTH - 1 : 0] w_ctr_ram_byt;
    logic                       w_ctr_reg_wr_en;
    logic [`ARGS_WIDTH - 1 : 0] w_ctr_reg_wr_src;

    always_comb begin
        case (w_inst_opcode)
            // LUI
            7'b0110111: begin
                w_ctr_alu_type   = `ALU_TYPE_ADD;
                w_ctr_alu_rs1    = `ALU_RS1_X;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_U;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_ALU;
            end
            // AUIPC
            7'b0010111: begin
                w_ctr_alu_type   = `ALU_TYPE_ADD;
                w_ctr_alu_rs1    = `ALU_RS1_PC;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_U;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_ALU;
            end
            // JAL
            7'b1101111: begin
                w_ctr_alu_type   = `ALU_TYPE_ADD;
                w_ctr_alu_rs1    = `ALU_RS1_PC;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_J;
                w_ctr_jmp_type   = `JMP_J;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_PC;
            end
            // JALR
            7'b1100111: begin
                w_ctr_alu_type   = `ALU_TYPE_JALR;
                w_ctr_alu_rs1    = `ALU_RS1_GPR;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_I;
                w_ctr_jmp_type   = `JMP_J;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_PC;
            end
            // BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                w_ctr_alu_type   = (w_inst_funct3 === 3'b000) ? `ALU_TYPE_BEQ  :
                                   (w_inst_funct3 === 3'b001) ? `ALU_TYPE_BNE  :
                                   (w_inst_funct3 === 3'b100) ? `ALU_TYPE_BLT  :
                                   (w_inst_funct3 === 3'b101) ? `ALU_TYPE_BGE  :
                                   (w_inst_funct3 === 3'b110) ? `ALU_TYPE_BLTU :
                                   (w_inst_funct3 === 3'b111) ? `ALU_TYPE_BGEU :
                                                                `ALU_TYPE_X;
                w_ctr_alu_rs1    = `ALU_RS1_GPR;
                w_ctr_alu_rs2    = `ALU_RS2_GPR;
                w_ctr_jmp_type   = `JMP_B;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b0;
                w_ctr_reg_wr_src = `REG_WR_SRC_X;
            end
            // LB, LH, LW, LBU, LHU
            7'b0000011: begin
                w_ctr_alu_type   = `ALU_TYPE_ADD;
                w_ctr_alu_rs1    = `ALU_RS1_GPR;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_I;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = (w_inst_funct3 === 3'b000) ? `RAM_BYT_1_S :
                                   (w_inst_funct3 === 3'b001) ? `RAM_BYT_2_S :
                                   (w_inst_funct3 === 3'b010) ? `RAM_BYT_4_S :
                                   (w_inst_funct3 === 3'b100) ? `RAM_BYT_1_U :
                                   (w_inst_funct3 === 3'b101) ? `RAM_BYT_2_U :
                                                                `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_MEM;
            end
            // SB, SH, SW
            7'b0100011: begin
                w_ctr_alu_type   = `ALU_TYPE_ADD;
                w_ctr_alu_rs1    = `ALU_RS1_GPR;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_S;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b1;
                w_ctr_ram_byt    = (w_inst_funct3 === 3'b000) ? `RAM_BYT_1_U :
                                   (w_inst_funct3 === 3'b001) ? `RAM_BYT_2_U :
                                   (w_inst_funct3 === 3'b010) ? `RAM_BYT_4_U :
                                                                `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b0;
                w_ctr_reg_wr_src = `REG_WR_SRC_X;
            end
            // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            7'b0010011: begin
                w_ctr_alu_type   = (w_inst_funct3 === 3'b000    ) ? `ALU_TYPE_ADD  :
                                   (w_inst_funct3 === 3'b010    ) ? `ALU_TYPE_SLT  :
                                   (w_inst_funct3 === 3'b011    ) ? `ALU_TYPE_SLTU :
                                   (w_inst_funct3 === 3'b100    ) ? `ALU_TYPE_XOR  :
                                   (w_inst_funct3 === 3'b110    ) ? `ALU_TYPE_OR   :
                                   (w_inst_funct3 === 3'b111    ) ? `ALU_TYPE_AND  :
                                   (w_inst_funct3 === 3'b001    ) ? `ALU_TYPE_SLL  :
                                   (w_inst_funct3 === 3'b101    ) ?
                                  ((w_inst_funct7 === 7'b0000000) ? `ALU_TYPE_SRL  :
                                                                    `ALU_TYPE_SRA) :
                                                                    `ALU_TYPE_X;
                w_ctr_alu_rs1    = `ALU_RS1_GPR;
                w_ctr_alu_rs2    = `ALU_RS2_IMM_I;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_ALU;
            end
            // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            7'b0110011: begin
                w_ctr_alu_type   = (w_inst_funct3 === 3'b000    ) ?
                                  ((w_inst_funct7 === 7'b0000000) ? `ALU_TYPE_ADD  :
                                                                    `ALU_TYPE_SUB) :
                                   (w_inst_funct3 === 3'b001    ) ? `ALU_TYPE_SLL  :
                                   (w_inst_funct3 === 3'b010    ) ? `ALU_TYPE_SLT  :
                                   (w_inst_funct3 === 3'b011    ) ? `ALU_TYPE_SLTU :
                                   (w_inst_funct3 === 3'b100    ) ? `ALU_TYPE_XOR  :
                                   (w_inst_funct3 === 3'b101    ) ?
                                  ((w_inst_funct7 === 7'b0000000) ? `ALU_TYPE_SRL  :
                                                                    `ALU_TYPE_SRA) :
                                   (w_inst_funct3 === 3'b110    ) ? `ALU_TYPE_OR   :
                                   (w_inst_funct3 === 3'b111    ) ? `ALU_TYPE_AND  :
                                                                    `ALU_TYPE_X;
                w_ctr_alu_rs1    = `ALU_RS1_GPR;
                w_ctr_alu_rs2    = `ALU_RS2_GPR;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b1;
                w_ctr_reg_wr_src = `REG_WR_SRC_ALU;
            end
            default: begin
                w_ctr_alu_type   = `ALU_TYPE_X;
                w_ctr_alu_rs1    = `ALU_RS1_X;
                w_ctr_alu_rs2    = `ALU_RS2_X;
                w_ctr_jmp_type   = `JMP_X;
                w_ctr_ram_wr_en  = 1'b0;
                w_ctr_ram_byt    = `RAM_BYT_X;
                w_ctr_reg_wr_en  = 1'b0;
                w_ctr_reg_wr_src = `REG_WR_SRC_X;
            end
        endcase
    end

    assign o_idu_ctr_alu_type   = (o_sys_valid && i_sys_ready) ? w_ctr_alu_type   : `ALU_TYPE_X;
    assign o_idu_ctr_alu_rs1    = (o_sys_valid && i_sys_ready) ? w_ctr_alu_rs1    : `ALU_RS1_X;
    assign o_idu_ctr_alu_rs2    = (o_sys_valid && i_sys_ready) ? w_ctr_alu_rs2    : `ALU_RS2_X;
    assign o_idu_ctr_jmp_type   = (o_sys_valid && i_sys_ready) ? w_ctr_jmp_type   : `JMP_X;
    assign o_idu_ctr_ram_wr_en  = (o_sys_valid && i_sys_ready) ? w_ctr_ram_wr_en  : 1'b0;
    assign o_idu_ctr_ram_byt    = (o_sys_valid && i_sys_ready) ? w_ctr_ram_byt    : `RAM_BYT_X;
    assign o_idu_ctr_reg_wr_en  = (o_sys_valid && i_sys_ready) ? w_ctr_reg_wr_en  : 1'b0;
    assign o_idu_ctr_reg_wr_src = (o_sys_valid && i_sys_ready) ? w_ctr_reg_wr_src : `REG_WR_SRC_X;

    assign o_idu_gpr_rs1_id = (o_sys_valid && i_sys_ready) ? w_inst_rs1_id : 5'h0;
    assign o_idu_gpr_rs2_id = (o_sys_valid && i_sys_ready) ? w_inst_rs2_id : 5'h0;
    assign o_idu_gpr_rd_id  = (o_sys_valid && i_sys_ready) ? w_inst_rd_id  : 5'h0;

    always_comb begin
        if (o_sys_valid && i_sys_ready) begin
            o_idu_rs1_data = (w_ctr_alu_rs1 === `ALU_RS1_GPR) ? i_gpr_rs1_data :
                             (w_ctr_alu_rs1 === `ALU_RS1_PC ) ? i_ifu_pc       :
                                                               `DATA_ZERO;
            o_idu_rs2_data = (w_ctr_alu_rs2 === `ALU_RS2_GPR  ) ? i_gpr_rs2_data :
                             (w_ctr_alu_rs2 === `ALU_RS2_IMM_I) ? w_inst_imm     :
                             (w_ctr_alu_rs2 === `ALU_RS2_IMM_S) ? w_inst_imm     :
                             (w_ctr_alu_rs2 === `ALU_RS2_IMM_B) ? w_inst_imm     :
                             (w_ctr_alu_rs2 === `ALU_RS2_IMM_U) ? w_inst_imm     :
                             (w_ctr_alu_rs2 === `ALU_RS2_IMM_J) ? w_inst_imm     :
                                                                 `DATA_ZERO;
        end
        else begin
            o_idu_rs1_data = `DATA_ZERO;
            o_idu_rs2_data = `DATA_ZERO;
        end
    end

    assign o_idu_jmp_or_reg_data = (o_sys_valid && i_sys_ready) ?
                                  ((w_ctr_jmp_type === `JMP_B ) ? w_inst_imm      :
                                                                  i_gpr_rs2_data) : `DATA_ZERO;
    assign o_idu_end_flag  = (w_inst_opcode == 7'b1110011 &&
                              i_ram_inst[31 : 20] == 12'h0001) ? 1'b1 : 1'b0;

endmodule
