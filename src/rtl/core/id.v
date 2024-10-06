//仅帮助传递数据，提前取数，不帮助ex提前申请数据通路，ex自己申请
//全组合逻辑，设计时虽然开了两op_o，但大部分时候不使用，不传递。因为读寄存器的数据已经传递了。

module id(
input wire                  rst,
//from if_id
input wire[`InstBus]        inst_i,
input wire[`InstAddrBus]    inst_addr_i,
//from regs
input wire[`RegBus]         reg1_rdata_i,
input wire[`RegBus]         reg2_rdata_i,
//from csr_reg
input wire[`RegBus]         csr_rdata_i,

//read regs
output reg[`RegAddrBus]     reg1_raddr_o,
output reg[`RegAddrBus]     reg2_raddr_o,
//read csr reg
output reg [`MemAddrBus]    csr_raddr_o,
//to ex
output reg [`RegBus]        op1_o,
output reg [`RegBus]        op2_o,
output reg [`RegBus]        op1_jump_o,
output reg [`RegBus]        op2_jump_o,
output reg [`InstBus]       inst_o,
output reg [`InstAddrBus]   inst_addr_o,
output reg [`RegBus]        reg1_rdata_o,
output reg [`RegBus]        reg2_rdata_o,

output reg [`RegBus]        csr_rdata_o
);
//按照不同指令类型划分 IRSBUJ
wire [7:0]opcode = inst_i[6:0];
//注释： d:direction
//      s:source
// I类型 立即数类型
wire [4:0]I_rd = inst_i[11:7];
wire [2:0]I_funct3 = inst_i[14:12];
wire [4:0]I_rs1 = inst_i[19:15];
wire [11:0]I_imm = inst_i[31:20];
// R类型 rd = rs1 ? rs2
wire [4:0]R_rd = inst_i[11:7];
wire [2:0]R_funct3 = inst_i[14:12];
wire [4:0]R_rs1 = inst_i[19:15];
wire [4:0]R_rs2 = inst_i[24:20];
wire [4:0]R_funct7 = inst_i[31:25];
// S类型 Mem[rs1+imm] = rs2
wire [2:0]S_funct3 = inst_i[14:12];
wire [4:0]S_rs1 = inst_i[19:15];
wire [4:0]S_rs2 = inst_i[24:20];
wire [11:0]S_imm = {inst_i[31:25],inst_i[11:7]};
// B类型 if(rs1?rs2) pc+=imm;
wire [2:0]B_funct3 = inst_i[14:12];
wire [4:0]B_rs1 = inst_i[19:15];
wire [4:0]B_rs2 = inst_i[24:20];
wire [11:0]B_imm = {inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8]};
// U类型 rd = {x'b,imm,x'b};//载入长立即数
wire [4:0]U_rd = inst_i[11:7];
wire [19:0]U_imm = inst_i[31:12];
// J类型 无条件跳转 opcode += imm
wire [2:0]J_funct3 = inst_i[14:12];
wire [4:0] J_rd = inst_i[11:7];
wire [19:0]J_imm = {inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21]};
//这里明确一个容易误会的地方，I是指立即数型指令，但包含立即数的指令不一定是I型，type_I也不一定包含所有I型指令，例如LB
always@(*) begin
    inst_o  =   inst_i;
    inst_addr_o = inst_addr_i;
end
always@(*) begin
    case(opcode)
        `INST_TYPE_I    :begin
            case(I_funct3)
                `INST_ADDI ,
                `INST_SLTI ,
                `INST_SLTIU,
                `INST_XORI ,
                `INST_ORI  ,
                `INST_ANDI ,
                `INST_SLLI ,
                `INST_SRLI :begin
                    //rd = rs1 ? imm
                    //向寄存器读取
                    reg1_raddr_o    = I_rs1;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = {{20{I_imm[11]}},I_imm};
                    op2_o           = I_rd;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = reg1_rdata_i;
                    reg2_rdata_o    = `ZeroWord;
                end
                default:begin
                    //DO NOTHING
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_B    :begin
            case(B_funct3)
                `INST_BEQ ,
                `INST_BNE ,
                `INST_BLT ,
                `INST_BGE ,
                `INST_BLTU,
                `INST_BGEU:begin
                    //if(rs1?rs2) pc+=imm;
                    //向寄存器读取
                    reg1_raddr_o    = B_rs1;
                    reg2_raddr_o    = B_rs2;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = inst_addr_i;
                    op2_jump_o      = {{19{B_imm[11]}},B_imm,1'b0};
                    reg1_rdata_o    = reg1_rdata_i;
                    reg2_rdata_o    = reg2_rdata_i;
                end
                default:begin
                    //DO NOTHING
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_R_M  :begin
            case(R_funct7)
                7'b000_0000:begin
                    case(R_funct3)
                        `INST_ADD_SUB,
                        `INST_SLL    ,
                        `INST_SLT    ,
                        `INST_SLTU   ,
                        `INST_XOR    ,
                        `INST_SRL    ,
                        `INST_OR     ,
                        `INST_AND    :begin
                            //rd = rs1 ? rs2;
                            //向寄存器读取
                            reg1_raddr_o    = R_rs1;
                            reg2_raddr_o    = R_rs2;
                            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                            op1_o           = R_rd;
                            op2_o           = `ZeroWord;
                            op1_jump_o      = `ZeroWord;
                            op2_jump_o      = `ZeroWord;
                            reg1_rdata_o    = reg1_rdata_i;
                            reg2_rdata_o    = reg2_rdata_i;
                        end
                        default:begin
                            //DO NOTHING
                            reg1_raddr_o    = `ZeroReg;
                            reg2_raddr_o    = `ZeroReg;
                            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                            op1_o           = `ZeroWord;
                            op2_o           = `ZeroWord;
                            op1_jump_o      = `ZeroWord;
                            op2_jump_o      = `ZeroWord;
                            reg1_rdata_o    = `ZeroWord;
                            reg2_rdata_o    = `ZeroWord;
                        end
                    endcase
                end
                default:begin
                    //DO NOTHING
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_S    :begin
            case(S_funct3)
                `INST_SB,
                `INST_SH,
                `INST_SW:begin
                    //Mem[rs1+imm] = rs2
                    reg1_raddr_o    = S_rs1;
                    reg2_raddr_o    = S_rs2;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = { {19{S_imm[11]}}, S_imm};
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = reg1_rdata_i;
                    reg2_rdata_o    = reg2_rdata_i;
                end
                default:begin
                    //DO NOTHING
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_L    :begin
            case(I_funct3)
                `INST_LB ,
                `INST_LH ,
                `INST_LW ,
                `INST_LBU,
                `INST_LHU:begin
                    //rd = Mem[rs1+imm];
                    reg1_raddr_o    = I_rs1;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = { {19{I_imm[11]}}, I_imm};
                    op2_o           = I_rd;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = reg1_rdata_i;
                    reg2_rdata_o    = `ZeroWord;
                end
                default:begin
                    //DO NOTHING
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_CSR   :begin //CSR寄存器这些我认为不应该属于常规六种 IRSJBU
            case(I_funct3)
                `INST_CSRRW ,
                `INST_CSRRS ,
                `INST_CSRRC :begin
                    reg1_raddr_o    = I_rs1;
                    reg2_raddr_o    = `ZeroReg;
                    //csr
                    csr_raddr_o     = {20'h0,I_imm}; 
                    csr_rdata_o     = csr_rdata_i;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = I_rd;
                    op2_o           = {20'h0,I_imm};
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = reg1_rdata_i;
                    reg2_rdata_o    = `ZeroWord;
                end
                `INST_CSRRWI,
                `INST_CSRRSI,
                `INST_CSRRCI:begin
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //csr
                    csr_raddr_o     = I_imm;
                    csr_rdata_o     = csr_rdata_i;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = {27'h0,I_rs1}; //zimm
                    op2_o           = I_rd;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
                default:begin
                    //DO NOTHING
                    reg1_raddr_o    = `ZeroReg;
                    reg2_raddr_o    = `ZeroReg;
                    //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
                    op1_o           = `ZeroWord;
                    op2_o           = `ZeroWord;
                    op1_jump_o      = `ZeroWord;
                    op2_jump_o      = `ZeroWord;
                    reg1_rdata_o    = `ZeroWord;
                    reg2_rdata_o    = `ZeroWord;
                end
            endcase
        end
        `INST_JAL:begin
            reg1_raddr_o    = `ZeroReg;
            reg2_raddr_o    = `ZeroReg;
            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
            op1_o           = J_rd;
            op2_o           = 32'h4;
            op1_jump_o      = inst_addr_i;
            op2_jump_o      = { {11{J_imm[19]}}, J_imm,1'b0};
            reg1_rdata_o    = `ZeroWord;
            reg2_rdata_o    = `ZeroWord;
        end
        `INST_JALR:begin
            reg1_raddr_o    = I_rs1;
            reg2_raddr_o    = `ZeroReg;
            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
            op1_o           = I_rd;
            op2_o           = 32'h4;
            op1_jump_o      = reg1_rdata_i;
            op2_jump_o      = { {11{J_imm[19]}}, J_imm,1'b0};
            reg1_rdata_o    = reg1_rdata_i;
            reg2_rdata_o    = `ZeroWord;
        end
        `INST_LUI,`INST_AUIPC :begin
            reg1_raddr_o    = `ZeroReg;
            reg2_raddr_o    = `ZeroReg;
            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
            op1_o           =  U_rd;
            op2_o           =  {U_imm,12'd0};//zimm
            op1_jump_o      = `ZeroWord;
            op2_jump_o      = `ZeroWord;
            reg1_rdata_o    = `ZeroWord;
            reg2_rdata_o    = `ZeroWord;
        end
        `INST_NOP_OP:
        begin
            //DO NOTHING
            reg1_raddr_o    = `ZeroReg;
            reg2_raddr_o    = `ZeroReg;
            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
            op1_o           = `ZeroWord;
            op2_o           = `ZeroWord;
            op1_jump_o      = `ZeroWord;
            op2_jump_o      = `ZeroWord;
            reg1_rdata_o    = `ZeroWord;
            reg2_rdata_o    = `ZeroWord;
        end
        `INST_FENCE:
        begin
            //DO NOTHING
            reg1_raddr_o    = `ZeroReg;
            reg2_raddr_o    = `ZeroReg;
            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
            op1_o           = `ZeroWord;
            op2_o           = `ZeroWord;
            op1_jump_o      = inst_addr_i;
            op2_jump_o      = 32'h4;
            reg1_rdata_o    = `ZeroWord;
            reg2_rdata_o    = `ZeroWord;
        end
        default:begin
            //DO NOTHING
            reg1_raddr_o    = `ZeroReg;
            reg2_raddr_o    = `ZeroReg;
            //向ex传递,仅传递立即数类型，不传递寄存器，寄存器读出来过pp2会到ex里。不多此一举
            op1_o           = `ZeroWord;
            op2_o           = `ZeroWord;
            op1_jump_o      = `ZeroWord;
            op2_jump_o      = `ZeroWord;
            reg1_rdata_o    = `ZeroWord;
            reg2_rdata_o    = `ZeroWord;
        end
    endcase
end
endmodule