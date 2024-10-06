module ex(
    //from id_ex
    input wire [`RegBus]        op1_i,
    input wire [`RegBus]        op2_i,
    input wire [`RegBus]        op1_jump_i,
    input wire [`RegBus]        op2_jump_i,
    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,
    input wire [`RegBus]        reg1_rdata_i,
    input wire [`RegBus]        reg2_rdata_i,
    input wire [`RegBus]        csr_rdata_i,
    //from / to mem ,这里考虑cache设计？halt？
    // write back regs
    // to regs
    output reg[`RegBus] reg_wdata_o,       // 写寄存器数据
    output reg reg_we_o,                   // 是否要写通用寄存器
    output reg[`RegAddrBus] reg_waddr_o,   // 写通用寄存器地址
    // to csr reg
    output reg[`RegBus] csr_wdata_o,        // 写CSR寄存器数据
    output reg csr_we_o,                   // 是否要写CSR寄存器
    output reg[`MemAddrBus] csr_waddr_o,   // 写CSR寄存器地址
    // to ctrl
    output reg jump_flag_o,                // 是否跳转标志
    output reg[`InstAddrBus] jump_addr_o,  // 跳转目的地址
    output reg [`InstBus] inst_o,
    output reg [`InstAddrBus] inst_addr_o,

    output reg hold_flag_o,
    // to mem
    output  reg  [`CacheAddrBus]    o_p_addr,                //cpu->cache addr
    output  reg  [`CacheByteBus]    o_p_byte_en,             //写稀疏掩码
    output  reg  [`CacheDataBus]    o_p_writedata,           //写数据
    output  reg                     o_p_read,                //读使能
    output  reg                     o_p_write,               //写使能
   
    output  reg  [`RegAddrBus]      reg_wait_wb 
);
/************************TASK***********************************/
task set_reg(
    input [`RegAddrBus]reg_waddr ,
    input [`RegBus]reg_wdata ,
    input reg_we    ,
    input [`MemAddrBus]csr_waddr ,
    input [`RegBus]csr_wdata ,
    input csr_we    ,
    input [`InstAddrBus]jump_addr,
    input jump_flag 
);
    reg_wdata_o = reg_wdata;
    reg_we_o    = reg_we   ;
    reg_waddr_o = reg_waddr;
    csr_wdata_o = csr_wdata;
    csr_we_o    = csr_we   ;
    csr_waddr_o = csr_waddr;
    jump_flag_o = jump_flag;
    jump_addr_o = jump_addr;
endtask
task set_mem(
    input [`CacheAddrBus]mem_waddr ,
    input [`CacheDataBus]mem_wdata ,
    input [`CacheByteBus]mem_mask  ,
    input                read_en   ,
    input                write_en   
);
    o_p_addr      = mem_waddr;
    o_p_byte_en   = mem_mask ;
    o_p_writedata = mem_wdata;
    o_p_read      = read_en  ;      
    o_p_write     = write_en ;     
endtask
/**************************COMB LOGIC****************************************/
wire [`RegBus] op1_add_reg1 = op1_i + reg1_rdata_i;
wire [`RegBus] op1_xor_reg1 = op1_i ^ reg1_rdata_i;
wire [`RegBus] op1_or_reg1  =  op1_i | reg1_rdata_i;
wire [`RegBus] op1_and_reg1 =  op1_i & reg1_rdata_i;
wire [`RegBus] op1_ge_reg1  = (op1_i >= reg1_rdata_i) ? 32'd1:32'd0;
wire [`RegBus] op1_geu_reg1 = ($signed(op1_i) >= $signed(reg1_rdata_i)) ? 32'd1:32'd0;
wire [`RegBus] op1_lt_reg1  = (op1_i < reg1_rdata_i) ? 32'd1:32'd0;
wire [`RegBus] op1_ltu_reg1 = ($signed(op1_i) < $signed(reg1_rdata_i)) ? 32'd1:32'd0;

wire [`RegBus] reg1_sll_op1 = reg1_rdata_i << op1_i[4:0];
wire [`RegBus] reg1_srl_op1 = reg1_rdata_i >> op1_i[4:0];
wire [`RegBus] reg1_add_reg2= reg1_rdata_i + reg2_rdata_i;
wire [`RegBus] reg1_or_reg2 = reg1_rdata_i | reg2_rdata_i;
wire [`RegBus] reg1_and_reg2= reg1_rdata_i & reg2_rdata_i;
wire [`RegBus] reg1_xor_reg2= reg1_rdata_i & reg2_rdata_i;
wire [`RegBus] reg1_sll_reg2= reg1_rdata_i << reg2_rdata_i[24:20];
wire [`RegBus] reg1_srl_reg2= reg1_rdata_i >> reg2_rdata_i[24:20];

wire [`RegBus] jump1_add_jump2 = op1_jump_i + op2_jump_i;
wire reg1_eq_reg2 = reg1_rdata_i == reg2_rdata_i;
wire reg1_ge_reg2 = reg1_rdata_i >= reg2_rdata_i;
wire reg1_geu_reg2 = ($signed(reg1_rdata_i) >= $signed(reg2_rdata_i));
wire [4:0] uimm = inst_i[19:15];
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
wire [2:0]U_rd = inst_i[11:7];
wire [19:0]U_imm = inst_i[31:12];
// J类型 无条件跳转 opcode += imm
wire [2:0]J_funct3 = inst_i[14:12];
wire [4:0] J_rd = inst_i[11:7];
wire [19:0]J_imm = {inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21]};

wire [`MemAddrBus] mem_base   = reg1_rdata_i;
wire [`MemAddrBus] mem_bias   = op1_i;
wire [`MemBus]     mem_wdata  = reg2_rdata_i;
wire [`MemAddrBus] addr       = mem_base + mem_bias;
wire [`CacheAddrBus] mem_addr = {2'b00,addr[22:0]};
wire [`CacheDataBus] writedata = mem_wdata;

always@(*) begin
    inst_o  =   inst_i;
    inst_addr_o = inst_addr_i;
end

always@(*) begin
    case(opcode)
        `INST_TYPE_I    :begin
            case(I_funct3)
                `INST_ADDI :begin
                    set_reg(op2_i[4:0],op1_add_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_SLTI :begin
                    set_reg(op2_i[4:0],op1_lt_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_SLTIU:begin
                    set_reg(op2_i[4:0],op1_ltu_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_XORI :begin
                    set_reg(op2_i[4:0],op1_xor_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_ORI  :begin
                    set_reg(op2_i[4:0],op1_or_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_ANDI :begin
                    set_reg(op2_i[4:0],op1_and_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_SLLI :begin
                    set_reg(op2_i[4:0],reg1_sll_op1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_SRLI :begin
                    set_reg(op2_i[4:0],reg1_srl_op1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                default:begin
                    //DO NOTHING
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
            endcase
        end
        `INST_TYPE_B    :begin
            case(B_funct3)
                `INST_BEQ :begin
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            jump1_add_jump2,reg1_eq_reg2);
                end
                `INST_BNE :begin
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            jump1_add_jump2,~reg1_eq_reg2);
                end
                `INST_BLT :begin
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            jump1_add_jump2,~reg1_ge_reg2);
                end
                `INST_BGE :begin
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            jump1_add_jump2,reg1_ge_reg2);
                end
                `INST_BLTU:begin
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            jump1_add_jump2,~reg1_geu_reg2);
                end
                `INST_BGEU:begin
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            jump1_add_jump2,reg1_geu_reg2);
                end
                default:begin
                    //DO NOTHING
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
            endcase
        end
        `INST_TYPE_R_M  :begin
            case(R_funct7)
                7'b000_0000:begin
                    case(R_funct3)
                        `INST_ADD_SUB:begin
                            set_reg(op1_i[4:0],reg1_add_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_SLL    :begin
                            set_reg(op1_i[4:0],reg1_sll_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_SLT    :begin
                            set_reg(op1_i[4:0],~reg1_ge_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_SLTU   :begin
                            set_reg(op1_i[4:0],~reg1_geu_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_XOR    :begin
                            set_reg(op1_i[4:0],reg1_xor_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_SRL    :begin
                            set_reg(op1_i[4:0],reg1_srl_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_OR     :begin
                            set_reg(op1_i[4:0],reg1_or_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_AND    :begin
                            set_reg(op1_i[4:0],reg1_and_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        default:begin
                            //DO NOTHING
                            set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                    endcase
                end
                default:begin
                    //DO NOTHING
                end
            endcase
        end
        `INST_TYPE_CSR   :begin //CSR寄存器这些我认为不应该属于常规六种 IRSJBU
            case(I_funct3)
                `INST_CSRRW :begin
                    //读csr到reg，写reg到csr
                    set_reg(op1_i[4:0],csr_rdata_i,`WriteEnable,
                            op2_i,reg1_rdata_i,`WriteEnable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_CSRRS :begin
                    set_reg(op1_i[4:0],csr_rdata_i,`WriteEnable,
                            op2_i,reg1_rdata_i|csr_rdata_i,`WriteEnable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_CSRRC :begin
                    set_reg(op1_i[4:0],csr_rdata_i,`WriteEnable,
                            op2_i,(~reg1_rdata_i)&csr_rdata_i,`WriteEnable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_CSRRWI:begin
                    set_reg(op1_i[4:0],csr_rdata_i,`WriteEnable,
                            op2_i,{27'h0,uimm},`WriteEnable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_CSRRSI:begin
                    set_reg(op1_i[4:0],csr_rdata_i,`WriteEnable,
                            op2_i,(~{27'h0,uimm})|csr_rdata_i,`WriteEnable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_CSRRCI:begin
                    set_reg(op1_i[4:0],csr_rdata_i,`WriteEnable,
                            op2_i,(~{27'h0,uimm})&csr_rdata_i,`WriteEnable,
                            `ZeroWord,`JumpDisable);
                end
                default:begin
                    //DO NOTHING
                    set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
            endcase
        end
        `INST_JAL,
        `INST_JALR:begin
            set_reg(op1_i[4:0],inst_addr_i+op2_i,`WriteDisable,
                    `ZeroReg,`ZeroWord,`WriteDisable,
                    op1_jump_i+op2_jump_i,`JumpEnable);
        end
        `INST_LUI:begin
            set_reg(op1_i[4:0],op2_i,`WriteEnable,
                    `ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroWord,`JumpDisable);
        end
        `INST_AUIPC :begin
            set_reg(op1_i[4:0],op2_i+inst_addr_i,`WriteEnable,
                    `ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroWord,`JumpDisable);
        end
        `INST_NOP_OP:
        begin
            //DO NOTHING
            set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroWord,`JumpDisable);
        end
        `INST_FENCE:
        begin
            //DO NOTHING
            set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroReg,`ZeroWord,`WriteDisable,
                    op1_jump_i+op2_jump_i,`JumpEnable);
        end
        default:begin
            //DO NOTHING
            set_reg(`ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroReg,`ZeroWord,`WriteDisable,
                    `ZeroWord,`JumpDisable);
        end
    endcase
end
always@(*) begin
    case(opcode)
        `INST_TYPE_L    :begin
            hold_flag_o = `Hold_Enable;
        end
        default: begin
            hold_flag_o = `Hold_Disbale;
        end
    endcase
end

always@(*) begin
    case(opcode)
    `INST_TYPE_S    :begin
        reg_wait_wb = `ZeroReg;
        case(funct3)
            `INST_SB:begin
                set_mem(mem_addr,writedata,mem_addr[0+:2],`ReadDisable,`WriteEnable);
            end
            `INST_SH:begin
                set_mem(mem_addr,writedata,{mem_addr[1],1'b0},`ReadDisable,`WriteEnable);
            end
            `INST_SW:begin
                set_mem(mem_addr,writedata,2'b11,`ReadDisable,`WriteEnable);
            end
            default:begin
                set_mem(25'd0,`ZeroWord,2'b00,`ReadDisable,`WriteDisable);
            end
        endcase
    end
    `INST_TYPE_L    :begin
        reg_wait_wb = I_rd;
        case(funct3)
            `INST_LB :begin
                set_mem(mem_addr,25'd0,2'b00,`ReadEnable,`WriteDisable);
            end
            `INST_LH :begin
                set_mem(mem_addr,25'd0,2'b00,`ReadEnable,`WriteDisable);
            end
            `INST_LW :begin
                set_mem(mem_addr,25'd0,2'b00,`ReadEnable,`WriteDisable);
            end
            `INST_LBU:begin
                set_mem(mem_addr,25'd0,2'b00,`ReadEnable,`WriteDisable);
            end
            `INST_LHU:begin
                set_mem(mem_addr,25'd0,2'b00,`ReadEnable,`WriteDisable);
            end
            default:begin
                set_mem(25'd0,`ZeroWord,2'b00,`ReadDisable,`WriteDisable);
            end
        endcase
    end
    default: begin
        reg_wait_wb = `ZeroReg;
        set_mem(25'd0,`ZeroWord,2'b00,`ReadDisable,`WriteDisable);
    end
    endcase
end

endmodule