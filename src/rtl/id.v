`include "bus_defines.v"
`include "rv32i_defines.v"

module id(
    input wire rst,

    //from if_id
    input wire [`InstBus]      inst_i,
    input wire [`InstAddrBus]  inst_addr_i,
    //form regs
    input wire [`RegBus]        reg1_rdata_i,
    input wire [`RegBus]        reg2_rdata_i,
    //from csr reg
    input wire [`RegBus]        csr_rdata_i,
    //form ex
    input wire                  ex_jump_flag_i,
    //to regs
    output reg [`RegAddrBus]    reg1_raddr_o,
    output reg [`RegAddrBus]    reg2_raddr_o,

    //to csr reg
    output reg[`MemAddrBus]     csr_raddr_o,
    //to ex
    output reg[`MemAddrBus]     op1_o,//
    output reg[`MemAddrBus]     op2_o,
    output reg[`MemAddrBus]     op1_jump_o,
    output reg[`MemAddrBus]     op2_jump_o,
    output reg[`InstBus]        inst_o,
    output reg[`InstAddrBus]    inst_addr_o,     
    output reg [`RegBus]        reg1_rdata_o,
    output reg [`RegBus]        reg2_rdata_o,
    output reg                  reg_we_o,
    output reg [`RegAddrBus]    reg_waddr_o,
    output reg                  csr_we_o,
    output reg [`RegBus]        csr_rdata_o,
    output reg [`MemAddrBus]    csr_waddr_o 
    
);
//mask
wire [6:0] opcode = inst_i[6:0];
wire [4:0] rd     = inst_i[11:7];
wire [2:0] funct3 = inst_i[14:12];
wire [4:0] rs1    = inst_i[19:15];
wire [4:0] rs2    = inst_i[24:20];
wire [6:0] funct7 = inst_i[31:25];

always @(*) begin
    op1_o           =   `ZeroWord;
    op2_o           =   `ZeroWord;
    op1_jump_o      =   `ZeroWord;
    op2_jump_o      =   `ZeroWord;
    inst_o          =   inst_i;
    inst_addr_o     =   inst_addr_i;
    reg1_rdata_o    =   reg1_rdata_i;
    reg2_rdata_o    =   reg2_rdata_i;
    csr_we_o        =   `WriteDisable;
    csr_rdata_o     =   csr_rdata_i;
    csr_waddr_o     =   `ZeroWord;
    csr_raddr_o     =   `ZeroWord;

//按opcode进行分类
    case(opcode)
        `INST_TYPE_I: //rd = rs1 ？imm; imm:31:20 
        begin
            case(funct3)
                `INST_ADDI ,
                `INST_SLTI ,
                `INST_SLTIU,
                `INST_XORI ,
                `INST_ORI  ,
                `INST_ANDI ,
                `INST_SLLI ,
                `INST_SRLI  : 
                begin
                    reg_we_o = `WriteEnable;
                    reg_waddr_o = rd;
                    reg1_raddr_o = rs1;
                    reg2_raddr_o = `ZeroReg;
                    op1_o = reg1_rdata_i;
                    op2_o = {{20{inst_i[31]}},inst_i[31:20]};//拓展符号位！
                end
                default:
                begin
                    reg_we_o = `WriteDisable;
                    reg_waddr_o = `ZeroReg;
                    reg1_raddr_o = `ZeroReg;
                    reg2_raddr_o = `ZeroReg;
                end
            endcase
        end
        `INST_TYPE_B:
        begin
            case(funct3)
                `INST_BEQ ,//if(rs1 ?? rs2) PC +=imm
                `INST_BNE ,
                `INST_BLT ,
                `INST_BGE ,
                `INST_BLTU,
                `INST_BGEU:
                begin
                    reg_we_o = `WriteEnable;
                    reg_waddr_o = rd;
                    reg1_raddr_o = rs1;
                    reg2_raddr_o = rs2;
                    op1_o = reg1_rdata_i;
                    op2_o = reg2_rdata_i;                 
                    op1_jump_o = inst_addr_i;
                    op2_jump_o = {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
                end
            default:
            begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
            end

            endcase
        end
        `INST_TYPE_L:
        begin
            case(funct3)//LX : rd = M[rs1+imm][0:x]
                `INST_LB ,
                `INST_LH ,
                `INST_LW ,
                `INST_LBU,
                `INST_LHU:
                begin
                    reg_we_o = `WriteEnable;
                    reg_waddr_o = rd;
                    reg1_raddr_o = rs1;
                    reg2_raddr_o = `ZeroReg;
                    op1_o = reg1_rdata_i;
                    op2_o = {{20{inst_i[31]}},inst_i[31:20]};//拓展符号位！                    
                end
                default:
                begin
                    reg_we_o = `WriteDisable;
                    reg_waddr_o = `ZeroReg;
                    reg1_raddr_o = `ZeroReg;
                    reg2_raddr_o = `ZeroReg;
                end

            endcase
        end
        `INST_TYPE_R_M://注意，M是 rv32M拓展
        begin
            if(funct7 == 7'b0000_000 || funct7 == 7'b0100_000)
            begin
                case(funct3)
                    `INST_ADD_SUB,//rd = rs1 ? rs2
                    `INST_SLL,
                    `INST_SLT,
                    `INST_SLTU,
                    `INST_XOR,
                    `INST_SLL,
                    `INST_OR,
                    `INST_AND:
                    begin
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        op1_o = reg1_rdata_i;
                        op2_o = reg2_rdata_i;     
                    end
                    default:
                    begin
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                    end
                endcase
            end
            else if(funct7 == 7'b0000_001) 
            begin
            //RV32M基础拓展
            //TODO
            end
        end
        `INST_TYPE_S:
        begin
            case(funct3)
                `INST_SB,//M[rs1+imm][0:x]=rs2[0:x] x=7,15,31
                `INST_SH,
                `INST_SW:
                begin
                    reg_we_o = `WriteDisable;
                    reg_waddr_o = `ZeroReg;
                    reg1_raddr_o = `ZeroReg;
                    // reg1_raddr_o = rs1;//这里其实没读reg1吧？rs1+imm其实是拼起来的立即数值，那传这个干吗？
                    reg2_raddr_o = rs2;
                    op1_o = reg1_rdata_i;
                    op2_o = {{20{inst_i[31]}},inst_i[31:25],inst_i[19:15]};//拓展符号位！ 
                end
            endcase
        end
        `INST_CSR   :
        begin
            reg_we_o = `WriteDisable;
            reg_waddr_o = `ZeroReg;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg;
            csr_raddr_o = {{20{1'b0}},inst_i[31:20]};    
            csr_waddr_o = {{20{1'b0}},inst_i[31:20]};    

            case(funct3)
                `INST_CSRRW ,//这些属于杂项，因此并没有一个特殊表达式
                `INST_CSRRS ,
                `INST_CSRRC :
                begin
                    reg_we_o = `WriteEnable;
                    reg_waddr_o = rd;
                    reg1_raddr_o = rs1;
                    reg2_raddr_o = `ZeroReg;
                    csr_we_o = `WriteEnable;
                end
                `INST_CSRRWI,
                `INST_CSRRSI,
                `INST_CSRRCI:
                begin
                    reg_we_o = `WriteEnable;
                    reg_waddr_o = rd;
                    reg1_raddr_o = `ZeroReg;
                    reg2_raddr_o = `ZeroReg;
                    csr_we_o = `WriteEnable;
                end
                default:
                begin
                    reg_we_o = `WriteDisable;
                    reg_waddr_o = `ZeroReg;
                    reg1_raddr_o = `ZeroReg;
                    reg2_raddr_o = `ZeroReg;
                    csr_we_o = `WriteDisable;                    
                end
            endcase
        end
        
        `INST_JAL   :
        begin
            reg_we_o = `WriteEnable;
            reg_waddr_o = rd;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg;
            op1_o = inst_addr_i;
            op2_o = 32'h4;                 
            op1_jump_o = inst_addr_i;
            op2_jump_o = {{12{inst_i[31]}},inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};
        end
        `INST_JALR  :
        begin
            reg_we_o = `WriteEnable;
            reg_waddr_o = rd;
            reg1_raddr_o = rs1;
            reg2_raddr_o = `ZeroReg;
            op1_o = inst_addr_i;
            op2_o = 32'h4;                 
            op1_jump_o = reg1_rdata_i;
            op2_jump_o = {{20{inst_i[31]}},inst_i[31:20]};
        end
        `INST_LUI   :
        begin
            reg_we_o = `WriteEnable;
            reg_waddr_o = rd;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg;
            op1_o = {inst_i[31:12],{12{1'b0}}};
            op2_o = `ZeroWord;                 
        end
        `INST_AUIPC :
        begin
            reg_we_o = `WriteEnable;
            reg_waddr_o = rd;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg;
            op1_o = inst_addr_i;
            op2_o = {inst_i[31:12],{12{1'b0}}};                 
        end
        `INST_NOP_OP:
        begin //本质就是啥也不干
            reg_we_o = `WriteDisable;
            reg_waddr_o = `ZeroReg;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg;       
        end
        `INST_FENCE :
        begin //在书里写了和nop一样，但是看起来要动 指令指针？
            reg_we_o = `WriteDisable;
            reg_waddr_o = `ZeroReg;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg; 
            op1_jump_o = inst_addr_i;
            op2_jump_o = 32'h4;
        end
        
        default:
        begin
            reg_we_o = `WriteDisable;
            reg_waddr_o = `ZeroReg;
            reg1_raddr_o = `ZeroReg;
            reg2_raddr_o = `ZeroReg;       
        end
    endcase

    

end
endmodule