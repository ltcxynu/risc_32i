risc-v 32i设计
============================================================
本项目是笔者从经典的 liangkangnan 的tinyrisc-v开始，在master分支学习搭建r-v。在pipe5分支搭建了带cache的版本。

可以使用下指令得到liangkangnan的源码

`git clone https://gitee.com/liangkangnan/tinyriscv.git`

其中cache设计使用了airin717的4way-4word设计。
`https://github.com/airin711/Verilog-caches.git`

在跟着原设计敲了一遍后，发现没有cache设计，并且对rom/ram的访问也过于理想，于是考虑加上cache。
由于添加了cache，访存和写回的环节必须要添加流水线。
因此在源码的基础上重新设计了大多数模块。
整体结构的设计尽可能保持不变，但区分开 <指令译码> 和 <执行> 阶段的任务，原设计在译码时就准备好了写地址/使能，只在执行阶段做了数据计算这项任务。
本设计只在 <指令译码> 时预读取寄存器。针对外部存储的访问，放在执行阶段，执行Load指令会暂停流水线，直到load完成，store指令则发起往cache的请求后不等待写完成。

<div align=center>
<img src="https://github.com/ltcxynu/risc_32i/pic/rv32i.png" width="180" height="105">

</div>
解决GTKwave字体大小的方法
gtkwave *.vcd --rcvar 'fontname_signals Monospace 20' --rcvar 'fontname_waves Monospace 18'