# 打开输入文件和输出文件
with open('sim/inst.data', 'r') as infile, open('src/rtl/tb/inst128.data', 'w') as outfile:
    while True:
        # 从输入文件中读取四行数据
        lines = [infile.readline().strip() for _ in range(4)]
        
        # 如果读取到的四行数据中有空行，则退出循环
        if any(line == '' for line in lines):
            break
        
        # 将四行数据拼接成一行，使用空格分隔
        concatenated_string = f"{lines[3]}{lines[2]}{lines[1]}{lines[0]}"
        
        # 将拼接后的字符串写入输出文件
        outfile.write(concatenated_string + '\n')