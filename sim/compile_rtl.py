import sys
import filecmp
import subprocess
import sys
import os


# 主函数
def main():
    rtl_dir = sys.argv[1]

    if rtl_dir != r'..':
        tb_file = r'/src/rtl/coretb/quick_sim_core.sv'
    else:
        tb_file = r'/src/rtl/coretb/quick_sim_core.sv'

    # iverilog程序
    iverilog_cmd = ['iverilog']
    iverilog_cmd += ['-g2005-sv']
    # 顶层模块
    #iverilog_cmd += ['-s', r'tinyriscv_soc_tb']
    # 编译生成文件
    iverilog_cmd += ['-o', r'out.vvp']
    # 头文件(defines.v)路径
    iverilog_cmd += ['-I', rtl_dir + r'/src/rtl/core']
    # 宏定义，仿真输出文件
    iverilog_cmd += ['-D', r'OUTPUT="signature.output"']
    # testbench文件
    iverilog_cmd.append(rtl_dir + tb_file)
    # ../rtl/utils
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/utils/gen_dff.v')
    # # ../rtl/core
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/clint.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/csr_reg.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/ctrl.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/ex.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/id_ex.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/id.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/if_id.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/pc.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/regs.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/rv32i_defines.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/rv32i.v')
    # iverilog_cmd.append(rtl_dir + r'/src/rtl/core/wb.v')

    # 编译
    process = subprocess.Popen(iverilog_cmd)
    process.wait(timeout=5)

if __name__ == '__main__':
    sys.exit(main())
