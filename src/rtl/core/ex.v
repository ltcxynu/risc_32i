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
    output  reg  [`CacheAddrBus]    o_p_addr,                //cpu->cache waddr
    output  reg  [`CacheByteBus]    o_p_byte_en,             //写稀疏掩码
    output  reg  [`CacheDataBus]    o_p_writedata,           //写数据
    output  reg                     o_p_read,                //读使能
    output  reg                     o_p_write,               //写使能
   
    output  reg  [`RegAddrBus]      reg_wait_wb,
    output  reg  [1:0]              mask_wait_wb,
    output  reg  [2:0]              ifunct3_wait_wb,
    output  reg                     flush_ex
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

wire [`RegBus] reg1_sll_op1 = reg1_rdata_i << op1_i[4:0];
wire [`RegBus] reg1_srl_op1 = reg1_rdata_i >> op1_i[4:0];
wire [`RegBus] reg1_add_reg2= reg1_rdata_i + reg2_rdata_i;
wire [`RegBus] reg1_sub_reg2= reg1_rdata_i - reg2_rdata_i;
wire [`RegBus] reg1_or_reg2 = reg1_rdata_i | reg2_rdata_i;
wire [`RegBus] reg1_and_reg2= reg1_rdata_i & reg2_rdata_i;
wire [`RegBus] reg1_xor_reg2= reg1_rdata_i ^ reg2_rdata_i;
wire [`RegBus] reg1_sll_reg2= reg1_rdata_i << reg2_rdata_i[4:0];
wire [`RegBus] reg1_srl_reg2= reg1_rdata_i >> reg2_rdata_i[4:0];

wire [`RegBus] data_mask    = {32{reg1_rdata_i[31]}} >> reg2_rdata_i[4:0];
wire [`RegBus] data_mask_op    = {32{reg1_rdata_i[31]}} >> op1_i[4:0];
wire [`RegBus] reg1_sra_reg2= reg1_rdata_i[31] ? (reg1_rdata_i >> reg2_rdata_i[4:0])|~data_mask : (reg1_rdata_i >> reg2_rdata_i[4:0]);
wire [`RegBus] reg1_sra_op1= reg1_rdata_i[31] ? (reg1_rdata_i >> op1_i[4:0])|~data_mask_op : (reg1_rdata_i >> op1_i[4:0]);


wire [`RegBus] jump1_add_jump2 = op1_jump_i + op2_jump_i;
wire reg1_eq_reg2  = reg1_rdata_i == reg2_rdata_i;
wire reg1_geu_reg2 = reg1_rdata_i >= reg2_rdata_i;
wire reg1_ge_reg2  = ($signed(reg1_rdata_i) >= $signed(reg2_rdata_i));
wire reg1_geu_op1 = ( reg1_rdata_i >= op1_i);
wire reg1_ge_op1  = ($signed(reg1_rdata_i) >= $signed(op1_i));

wire [7:0]  opcode  = inst_i[6:0];
wire [4:0]  rd      = inst_i[11:7];
wire [2:0]  funct3  = inst_i[14:12];
wire [11:0] I_imm   = inst_i[31:20];
wire [4:0]  uimm    = inst_i[19:15];
wire [6:0]  funct7  = inst_i[31:25];



wire [`MemAddrBus]      mem_base   = reg1_rdata_i;
wire [`MemAddrBus]      mem_bias   = op1_i;
wire [`MemBus]          mem_wdata  = reg2_rdata_i;
wire [`MemAddrBus]      waddr      = mem_base + mem_bias;
wire [`CacheAddrBus]    mem_addr   = {4'b0000,waddr[22:2]};
reg  [`CacheDataBus]    byte_data,half_data;
reg [3:0] byte_mask,half_mask;
always@(*) begin
    inst_o      = inst_i;
    inst_addr_o = inst_addr_i;
end

always@(*) begin
    case(opcode)
        `INST_TYPE_I    :begin
            case(funct3)
                `INST_ADDI :begin
                    set_reg(op2_i[4:0],op1_add_reg1,`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_SLTI :begin
                    set_reg(op2_i[4:0],{31'd0,~reg1_ge_op1},`WriteEnable,
                            `ZeroReg,`ZeroWord,`WriteDisable,
                            `ZeroWord,`JumpDisable);
                end
                `INST_SLTIU:begin
                    set_reg(op2_i[4:0],{31'd0,~reg1_geu_op1},`WriteEnable,
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
                    case(I_imm[11:5])
                    7'b000_0000:
                        set_reg(op2_i[4:0],reg1_srl_op1,`WriteEnable,
                                `ZeroReg,`ZeroWord,`WriteDisable,
                                `ZeroWord,`JumpDisable);
                    7'b010_0000:
                        set_reg(op2_i[4:0],reg1_sra_op1,`WriteEnable,
                                `ZeroReg,`ZeroWord,`WriteDisable,
                                `ZeroWord,`JumpDisable);
                    endcase
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
            case(funct3)
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
            case(funct7)
                7'b000_0000:begin
                    case(funct3)
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
                            set_reg(op1_i[4:0],{31'd0,~reg1_ge_reg2},`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_SLTU   :begin
                            set_reg(op1_i[4:0],{31'd0,~reg1_geu_reg2},`WriteEnable,
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
                7'b010_0000:begin
                    case(funct3)
                        `INST_ADD_SUB:begin
                            set_reg(op1_i[4:0],reg1_sub_reg2,`WriteEnable,
                                    `ZeroReg,`ZeroWord,`WriteDisable,
                                    `ZeroWord,`JumpDisable);
                        end
                        `INST_SRL    :begin
                            set_reg(op1_i[4:0],reg1_sra_reg2,`WriteEnable,
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
            case(funct3)
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
            set_reg(op1_i[4:0],inst_addr_i+op2_i,`WriteEnable,
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
            //DO NOTHING ? 实际上还是要做一些事情的，包括：1，flush Dcache. 2，flush Icache. 3. Jump next addr.
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
            hold_flag_o = `HoldEnable;
        end
        default: begin
            hold_flag_o = `HoldDisable;
        end
    endcase
end
always@(*) begin
    case(waddr[1:0])
    2'b00:begin 
        byte_mask = 4'b0001; 
        half_mask = 4'b0011;
        byte_data = {24'b0,mem_wdata[7:0]};
        half_data = {12'b0,mem_wdata[15:0]};
    end
    2'b01:begin 
        byte_mask = 4'b0010; 
        half_mask = 4'b1100;
        byte_data = {16'b0,mem_wdata[7:0],8'b0};
        half_data = {mem_wdata[15:0],16'b0};
    end
    2'b10:begin 
        byte_mask = 4'b0100; 
        half_mask = 4'b1100;
        byte_data = {8'b0,mem_wdata[7:0],16'b0};
        half_data = {mem_wdata[15:0],16'b0};
    end
    2'b11:begin 
        byte_mask = 4'b1000; 
        half_mask = 4'b1100;
        byte_data = {mem_wdata[7:0],24'b0};
        half_data = {mem_wdata[15:0],16'b0};
    end
    endcase
end
always@(*) begin
    case(opcode)
    `INST_TYPE_S    :begin
        reg_wait_wb     = `ZeroReg;
        mask_wait_wb    = 2'b00;
        ifunct3_wait_wb = 3'b000;
        case(funct3)
            `INST_SB:begin
                set_mem(mem_addr,byte_data,byte_mask,`ReadDisable,`WriteEnable);
            end
            `INST_SH:begin
                set_mem(mem_addr,half_data,half_mask,`ReadDisable,`WriteEnable);
            end
            `INST_SW:begin
                set_mem(mem_addr,mem_wdata,4'b1111,`ReadDisable,`WriteEnable);
            end
            default:begin
                set_mem(25'd0,`ZeroWord,4'b00,`ReadDisable,`WriteDisable);
            end
        endcase
    end
    `INST_TYPE_L    :begin
        reg_wait_wb = rd;
        mask_wait_wb    = waddr[1:0];
        ifunct3_wait_wb = funct3;
        set_mem(mem_addr,`ZeroWord,4'b00,`ReadEnable,`WriteDisable);
    end
    default: begin
        reg_wait_wb = `ZeroReg;
        set_mem(25'd0,`ZeroWord,2'b00,`ReadDisable,`WriteDisable);
    end
    endcase
end
always @(*) begin
    case(opcode)
    `INST_FENCE: begin
        flush_ex = 1;
    end
    default: begin
        flush_ex = 0;
    end
    endcase
end
endmodule