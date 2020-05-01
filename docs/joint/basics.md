# 第一阶段：学习 AXI-Stream 协议、 RGMII 接口和基本的网络知识

## 学习 AXI-Stream 协议

在本次实验中，我们已经把以太网 MAC 配置好，以太网帧的内容会通过 AXI-Stream 协议与其余逻辑进行交互。通过在 Vivado 中运行 testbench，可以找到接受到的以太网帧对应在 AXI-Stream 上的波形，把它和 testbench 中编写的以太网帧进行比较。

!!! question

    1. AXI-Stream 什么情况下传输一拍的数据（Data Beat）？
    2. 握手是通过哪些信号完成的，握手的信号之间有什么依赖关系？
    3. AXI-Stream 的 tuser 信号在这里可能代表什么意义？

## 学习 RGMII 接口

实际在 FPGA 芯片 和以太网 PHY 芯片之间通信的是 RGMII 接口，请观察仿真中 RGMII 的波形，和上面 AXI-Stream 的进行比较，应该可以找到一些相同点和不同点。

!!! question

    1. RGMII 的频率是多少，数据和时钟是什么关系？
    2. RGMII 和 AXI-Stream 的数据上长度和内容差异在哪里？
    3. RGMII 中的 RX_CTL 信号代表什么意义？

## 学习基础的网络知识

了解 IP 和 ARP 协议的基本功能和转发的概念，理解 KSZ8795 的 VLAN 配置，然后自己用 Linux 系统搭建一个网络，用 Linux 自带的转发功能，学会用 tcpdump 和 Wireshark 进行抓包分析。

了解转发的概念以后，可以基于 HAL 编写一个固定转发方式的路由器，比如只有 A B C三个结点，B 只处理 A 发给 C 和 C 发给 A的，检验 ping 是否成功。

阅读 testbench 中提供的样例以太网帧，估计一下路由器应该做出如何的反应。

!!! question

    1. VLAN 是做什么的，为什么需要 VLAN？
    2. KSZ8795 作用是什么？
    3. 需要转发 ARP 吗？
    4. 什么样的 IP 需要转发，转发的依据是什么？
    5. 转发 IP 的时候需要修改哪些字段？
    6. 如何知道转发后新的 VLAN Tag 和目标 MAC 地址？

## 尝试在仿真中实现 Loopback

Loopback 就是环回的意思，在 testbench 中，仿真代码会向 RGMII 不断发以太网帧，你要做的就是原样地发回去。你需要理解 AXI-Stream 接口的使用方式，主要是信号的握手和数据的传输过程。建议用一个单独的时钟域编写你的环回逻辑，通过一个异步 FIFO 把 MAC 的 125M 和单独的时钟隔开，这样你的逻辑有更多的时序自由度。

如果 Loopback 实现正确，你应该可以在仿真中看到 TX 的 RGMII 上有波形，并且它的内容和 RX 的内容是一样的。进一步，你可以尝试修改测试的以太网帧的内容，让它接受到不同长度的内容，并观察在 FCS 正确与错误时的表现。遇到问题时，可以在仿真中看 IP 的 Statistics Vector，然后查询文档。

如果在实现上遇到了困难，可以打开 IP 的 Example Design，里面有一个 Loopback 的实现，但比较复杂，不容易理解。并且，可以结合 RGMII 协议尝试理解一下 testbench 的实现方式，在后续编写各个模块的过程中也需要编写大量的测试。

!!! question

    1. IP 在校验 FCS 之后做了哪些事情，在 TX 的时候又对 FCS 做了什么？
    2. 样例工程中对 IP 进行了哪些配置？
    3. 如何处理 AXI-Stream 在 TX 时候 tready 不连续为高的情况？
    4. testbench 为了生成一个 RGMII 信号，做了哪些事情？

## 尝试在板子上实现 Loopback

基于上一步的成果，编写一段小的逻辑，实现目的 MAC 地址和源 MAC 地址的翻转，然后先在仿真中测试通过。仿真没问题后，再把代码生成 bitstream 到板子上，生成过程中一定注意 Critical Warning 和 Timing failed 信息，必须要重视并且进行修复，这一点是贯穿整个实验的，需要牢记。完成后把设备连到网口上，用 Wireshark 抓包，然后观察，如果出现一个包出现两次，只有 MAC 地址交换了的情况，说明实现正确，并且能正常运行。

如果在板子上工作不正常，请了解 ILA 的使用方式，从 AXI-Stream 的 RX 开始检查是否收到正确的以太网帧，然后按照数据流的顺序一路查到 AXI-Stream 的 TX。这个过程可能会很麻烦，但一定要耐心学会硬件调试的方法，如果有 Critical Warning 必须要注意，并且仿真中不应该出现带 X 和 Z 的有用的信号。

!!! question

    1. Vivado 提供的不同仿真模式有什么区别？
    2. 如何查看 Timing 信息？
    3. 如果出现 WNS 为负数，应该做哪些事情？
    4. 仿真中的 X 和 Z 都是代码中怎么写出来的？
