`include "bus_defines.v"
`include "rv32i_defines.v"

module ex(
    input wire                  clk,
    input wire                  rst,
    //from id_ex
    input reg[`MemAddrBus]      op1_i,//
    input reg[`MemAddrBus]      op2_i,
    input reg[`MemAddrBus]      op1_jump_i,
    input reg[`MemAddrBus]      op2_jump_i,
    input reg[`InstBus]         inst_i,
    input reg[`InstAddrBus]     inst_addr_i,     
    input reg [`RegBus]         reg1_rdata_i,
    input reg [`RegBus]         reg2_rdata_i,
    input reg                   reg_we_i,
    input reg [`RegAddrBus]     reg_waddr_i,
    input reg                   csr_we_i,
    input reg [`RegBus]         csr_rdata_i,
    input reg [`MemAddrBus]     csr_waddr_i,
    // from/to mem
    input wire[`MemBus]         mem_rdata_i,
    output reg [`MemBus]        mem_wdata_o,
    output reg [`MemAddrBus]    mem_raddr_o,        
    output reg [`MemAddrBus]    mem_waddr_o,        
    output wire                 mem_we_o,
    output wire                 mem_req_o,
    //to regs
    output wire[`RegBus]        reg_wdata_o,
    output wire                 reg_we_o,
    output wire[`RegAddrBus]    reg_waddr_o,
    //to csr regs
    output wire[`RegBus]        csr_wdata_o,
    output wire                 csr_we_o,
    output wire[`MemAddrBus]    csr_waddr_o,
    //to ctrl
    output wire                 hold_flag_o,
    output wire                 jump_flag_o,
    output wire[`InstAddrBus]   jump_addr_o
);
/*-----------------------------wire-------------------------------------*/
wire [6:0] opcode = inst_i[6:0];
wire [4:0] rd     = inst_i[11:7];
wire [2:0] funct3 = inst_i[14:12];
wire [4:0] uimm    = inst_i[19:15];
wire [6:0] funct7 = inst_i[31:25];
wire [`RegBus]      op1_add_op2_res;
wire [`RegBus]      op1_sub_op2_res;
wire [`RegBus]      op1_ge_op2_signed;
wire [`RegBus]      op1_ge_op2_unsigned;
wire [`RegBus]      op1_or_op2_res;
wire [`RegBus]      op1_xor_op2_res;
wire [`RegBus]      op1_and_op2_res;
wire [`RegBus]      reg1_slli_imm_res;
wire [`RegBus]      reg1_srli_imm_res;
wire [`RegBus]      reg1_sll_reg2_res;
wire [`RegBus]      reg1_srl_reg2_res;
wire [`RegBus]      shift_mask;
wire                op1_eq_op2_res;
wire [`RegBus]      op1_jump_and_op2_jump_res;
wire [1:0]          mem_w_mask;
wire [1:0]          mem_r_mask;

/*-----------------------------reg--------------------------------------*/
reg                 reg_we;
reg [`RegAddrBus]   reg_waddr;
reg mem_req;
reg                 hold_flag;
reg                 jump_flag;
reg [`InstAddrBus]  jump_addr;
reg                 mem_we;
reg [`RegBus]       reg_wdata;
/*----------------------------assign------------------------------------*/
assign op1_add_op2_res      = op1_i + op2_i;
assign op1_sub_op2_res      = op1_i - op2_i;
assign op1_ge_op2_signed    = $signed(op1_i) >= signed(op2_i);
assign op1_ge_op2_unsigned  = op1_i >= op2_i;
assign op1_or_op2_res       = op1_i | op2_i;
assign op1_xor_op2_res      = op1_i ^ op2_i;
assign op1_and_op2_res      = op1_i & op2_i;
assign reg1_slli_imm_res    = reg1_rdata_i << inst_i[24:20];
assign reg1_sll_reg2_res    = reg1_rdata_i << reg2_rdata_i[4:0];
assign shift_mask           = 32'hffff_ffff >> inst_i[24:20];
assign shift_mask_reg2      = 32'hffff_ffff >> reg2_rdata_i[4:0];
assign reg1_srli_imm_res    = (reg1_rdata_i[31] == 1'b1) ? (reg1_rdata_i >> inst_i[24:20])|(~shift_mask) : reg1_rdata_i >> inst_i[24:20];
assign reg1_srl_reg2_res    = (reg1_rdata_i[31] == 1'b1) ? (reg1_rdata_i >> reg2_rdata_i[4:0])|(~shift_mask) : reg1_rdata_i >> reg2_rdata_i[4:0];
assign op1_eq_op2_res       = op1_i == op2_i;
assign op1_jump_and_op2_jump_res = op1_jump_i+op2_jump_i;
assign mem_w_mask           = op1_and_op2_res&2'b11;
assign mem_r_mask           = op1_and_op2_res&2'b11;

/*----------------------------暂不处理输出中断等逻辑------------------------------------*/


always @(*) begin
    reg_we = reg_we_i;
    reg_waddr = reg_waddr_i;
    mem_req = `RIB_NREQ;
    csr_wdata_o = `ZeroWord;
//按opcode进行分类
    case(opcode)
        `INST_TYPE_I: //立即数型 imm
        begin
            case(funct3)//rd = rs1 ？imm; imm:31:20 
                `INST_ADDI :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = op1_add_op2_res;//加立即数比较简单，不需要访问内存，直接把译码后的op1+op2即可。
                end
                `INST_SLTI :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = {32{~op1_ge_op2_signed}} & 32'h1;
                end
                `INST_SLTIU:begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = {32{~op1_ge_op2_unsigned}} & 32'h1;
                end
                `INST_XORI :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = op1_xor_op2_res;
                end
                `INST_ORI  :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = op1_or_op2_res;
                end
                `INST_ANDI :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = op1_and_op2_res;
                end
                `INST_SLLI :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = reg1_slli_imm_res;
                end
                `INST_SRLI :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = reg1_srli_imm_res;
                end
                default :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_B://分支跳转 branch
        begin
            case(funct3)//if(rs1 ?? rs2) PC +=imm
                `INST_BEQ :begin
                    jump_flag = op1_eq_op2_res;
                    hold_flag = `HoldDisable;
                    jump_addr = op1_eq_op2_res ? op1_jump_and_op2_jump_res : 32'h0;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;
                end
                `INST_BNE :begin
                    jump_flag = ~op1_eq_op2_res;
                    hold_flag = `HoldDisable;
                    jump_addr = ~op1_eq_op2_res ? op1_jump_and_op2_jump_res : 32'h0;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;                    
                end
                `INST_BLT :begin
                    jump_flag = ~op1_ge_op2_signed;
                    hold_flag = `HoldDisable;
                    jump_addr = ~op1_ge_op2_signed ? op1_jump_and_op2_jump_res : 32'h0;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;                          
                end
                `INST_BGE :begin
                    jump_flag = op1_ge_op2_signed;
                    hold_flag = `HoldDisable;
                    jump_addr = op1_ge_op2_signed ? op1_jump_and_op2_jump_res : 32'h0;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;                       
                end
                `INST_BLTU:begin
                    jump_flag = ~op1_ge_op2_unsigned;
                    hold_flag = `HoldDisable;
                    jump_addr = ~op1_ge_op2_unsigned ? op1_jump_and_op2_jump_res : 32'h0;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;                          
                end
                `INST_BGEU:begin
                    jump_flag = op1_ge_op2_unsigned;
                    hold_flag = `HoldDisable;
                    jump_addr = op1_ge_op2_unsigned ? op1_jump_and_op2_jump_res : 32'h0;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;                          
                end
                default   :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    reg_wdata   = `ZeroWord;                         
                end
            endcase
        end
        `INST_TYPE_L://加载 load
        begin
            case(funct3)//LX : rd = M[rs1+imm][0:x]
                `INST_LB :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = op1_add_op2_res;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    mem_req     = `RIB_REQ;
                    case (mem_r_mask)
                        2'b00:begin
                            reg_wdata = {24{{mem_rdata_i[7]}},{mem_rdata_i[7:0]}};
                        end 
                        2'b01:begin
                            reg_wdata = {24{{mem_rdata_i[15]}},{mem_rdata_i[15:8]}};
                        end 
                        2'b10:begin
                            reg_wdata = {24{{mem_rdata_i[23]}},{mem_rdata_i[23:16]}};
                            
                        end 
                        default:begin
                            reg_wdata = {24{{mem_rdata_i[31]}},{mem_rdata_i[31:24]}};
                        end 
                    endcase                    
                end
                `INST_LH :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = op1_add_op2_res;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    mem_req     = `RIB_REQ;
                    case (mem_r_mask)
                        2'b00:begin
                            reg_wdata = {12{{mem_rdata_i[15]}},{mem_rdata_i[15:0]}};
                        end 
                        default:begin
                            reg_wdata = {12{{mem_rdata_i[31]}},{mem_rdata_i[31:16]}};
                        end 
                    endcase                        
                end
                `INST_LW :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = op1_add_op2_res;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    mem_req     = `RIB_REQ;
                    reg_wdata   = mem_rdata_i;   
                end
                `INST_LBU:begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = op1_add_op2_res;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    mem_req     = `RIB_REQ;
                    case (mem_r_mask)
                        2'b00:begin
                            reg_wdata = {24{1'b0},{mem_rdata_i[7:0]}};
                        end 
                        2'b01:begin
                            reg_wdata = {24{1'b0},{mem_rdata_i[15:8]}};
                        end 
                        2'b10:begin
                            reg_wdata = {24{1'b0},{mem_rdata_i[23:16]}};
                            
                        end 
                        default:begin
                            reg_wdata = {24{1'b0},{mem_rdata_i[31:24]}};
                        end 
                    endcase      
                end
                `INST_LHU:begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = op1_add_op2_res;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    mem_req     = `RIB_REQ;
                    case (mem_r_mask)
                        2'b00:begin
                            reg_wdata = {12{1'b0},{mem_rdata_i[15:0]}};
                        end 
                        default:begin
                            reg_wdata = {12{1'b0},{mem_rdata_i[31:16]}};
                        end 
                    endcase    
                end
                default: begin 
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_we      = `WriteDisable;
                    mem_req     = `RIB_NREQ;
                    reg_wdata   = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_R_M://计算 注意，M是 rv32M拓展
        begin
            if(funct7 == 7'b0000_000 || funct7 == 7'b0100_000)
            begin
                case(funct3)//rd = rs1 ? rs2
                    `INST_ADD_SUB   :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        case(funct7)
                        7'b000_0000:begin
                            reg_wdata = op1_add_op2_res;
                        end
                        7'b010_0000:begin
                            reg_wdata = op1_sub_op2_res;
                        end
                        default:begin
                            reg_wdata = `ZeroWord;
                        end
                        endcase
                    end
                    `INST_SLL       :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = reg1_sll_reg2_res;                        
                    end
                    `INST_SLT       :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = {32{~op1_ge_op2_signed}} & 32'h1;
                    end
                    `INST_SLTU      :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = {32{~op1_ge_op2_unsigned}} & 32'h1;
                    end
                    `INST_XOR       :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = op1_xor_op2_res;
                    end
                    `INST_SRL       :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = reg1_srl_reg2_res;                        
                    end
                    `INST_OR        :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = op1_or_op2_res;                        
                    end
                    `INST_AND       :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = op1_and_op2_res;
                    end
                    default         :begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_we      = `WriteDisable;
                        reg_wdata   = `ZeroWord;                        
                    end
                endcase
            end
            else if(funct7 == 7'b0000_001) 
            begin
            //RV32M基础拓展
            //TODO
            end
        end
        `INST_TYPE_S://存储 save
        begin
            case(funct3)//M[rs1+imm][0:x]=rs2[0:x] x=7,15,31
                `INST_SB:begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = op1_add_op2_res;
                    mem_raddr_o = `ZeroWord;
                    mem_we      = `WriteEnable;
                    reg_wdata   = `ZeroWord;     
                    mem_req     = `RIB_REQ;                   
                    case(mem_w_mask)
                        2'b00:begin
                            mem_wdata_o = {mem_rdata_i[31:8],reg2_rdata_i[7:0]};
                        end
                        2'b01:begin
                            mem_wdata_o = {mem_rdata_i[31:16],reg2_rdata_i[15:8],mem_rdata_i[7:0]};
                        end
                        2'b10:begin
                            mem_wdata_o = {mem_rdata_i[31:8],reg2_rdata_i[23:16],mem_rdata_i[15:0]};
                        end
                        default:begin
                            mem_wdata_o = {reg2_rdata_i[31:24],mem_rdata_i[23:0]};
                        end                                               
                    endcase
                end
                `INST_SH:begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = op1_add_op2_res;
                    mem_raddr_o = `ZeroWord;
                    mem_we      = `WriteEnable;
                    reg_wdata   = `ZeroWord;     
                    mem_req     = `RIB_REQ;                   
                    case(mem_w_mask)
                        2'b00:begin
                            mem_wdata_o = {mem_rdata_i[31:16],reg2_rdata_i[15:0]};
                        end
                        default:begin
                            mem_wdata_o = {reg2_rdata_i[31:16],mem_rdata_i[15:0]};
                        end                                               
                    endcase                    
                end
                `INST_SW:begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = op1_add_op2_res;
                    mem_raddr_o = `ZeroWord;
                    mem_we      = `WriteEnable;
                    reg_wdata   = `ZeroWord;     
                    mem_req     = `RIB_REQ;
                    mem_wdata_o = reg2_rdata_i;
                end
                default :begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_we      = `WriteEnable;
                    reg_wdata   = `ZeroWord;     
                    mem_req     = `RIB_NREQ;
                    mem_wdata_o = `ZeroWord;
                end
            endcase
        end
        `INST_CSR   :
        begin
            jump_flag = `JumpDisable;
            hold_flag = `HoldDisable;
            jump_addr = `ZeroWord;
            mem_waddr_o = `ZeroWord;
            mem_raddr_o = `ZeroWord;
            mem_we      = `WriteDisable;     
            mem_wdata_o = `ZeroWord;  
            case(funct3)//这些属于杂项，因此并没有一个特殊表达式
                `INST_CSRRW :begin //csr 寄存器 r & w
                    reg_wdata = csr_rdata_i;
                    csr_wdata_o = reg1_rdata_i;
                end
                `INST_CSRRS :begin
                    reg_wdata = csr_rdata_i;
                    csr_wdata_o = csr_rdata_i | reg1_rdata_i;
                    
                end
                `INST_CSRRC :begin
                    reg_wdata = csr_rdata_i;
                    csr_wdata_o = csr_rdata_i & ~reg1_rdata_i;
                end
                `INST_CSRRWI:begin
                    reg_wdata = csr_rdata_i;
                    csr_wdata_o = {27'h0, rs1};
                end
                `INST_CSRRSI:begin
                    reg_wdata = csr_rdata_i;
                    csr_wdata_o = csr_rdata_i | {27'h0, rs1};
                end
                `INST_CSRRCI:begin
                    reg_wdata = csr_rdata_i;
                    csr_wdata_o = csr_rdata_i & ~{27'h0, rs1};
                end
                default     :begin
                    reg_wdata = `ZeroWord;
                    csr_wdata_o = `ZeroWord;
                end
            endcase
        end
        
        `INST_JAL   :
        `INST_JALR  :
        `INST_LUI   :
        `INST_AUIPC :
        `INST_NOP_OP:
        `INST_FENCE :
        default:
    endcase

    

end
endmodule