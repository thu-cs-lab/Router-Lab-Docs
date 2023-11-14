## 网络拓扑

在 TANLabs 提交后，会在实验室的实验网络下进行真机评测。你的软件会运行在树莓派上，和平台提供的机器组成如下的拓扑：

![Topology](img/topology_ripng.png)

这一阶段，PC1、R1、R3、PC2 都由 TANLabs 自动配置和提供，两台路由器上均运行 BIRD（BIRD Internet Routing Daemon）作为标准的路由软件实现。运行着你的代码的树莓派处于 R2 的位置。其中 R2 实际用到的只有两个口，剩余两个口按顺序配置为 `fd00::8:1/112` 和 `fd00::9:1/112`（见 `Router-Lab/Homework/ospf/main.cpp` 代码中 ROUTER_R2 部分）。初始情况下，R1 和 R3 先不启动 OSPF 协议处理程序，这些机器的系统路由表如下：

```text
PC1:
default via fd00::1:1 dev pc1r1
fd00::1:0/112 dev pc1r1 scope link
R1:
fd00::1:0/112 dev r1pc1 scope link
fd00::3:0/112 dev r1r2 scope link
R3:
fd00::4:0/112 dev r3r2 scope link
fd00::5:0/112 dev r3pc2 scope link
PC2:
default via fd00::5:2 dev pc2r3
fd00::5:0/112 dev pc2r3 scope link
```

上面的每个网口名称格式都是两个机器拼接而成，如 `pc1r1` 代表 pc1 上通往 r1 的网口。此时，接上你的树莓派，按照图示连接两侧的 R1 和 R3 后，从 PC1 到 PC2 是不通的。接着，在 R1 和 R3 上都开启 OSPF 协议处理程序 BIRD，R1 会在 Intra-Area-Prefix-LSA 中宣告 `fd00::1:0/112` 和 `fd00::3:0/112` 的路由，R3 会在 Intra-Area-Prefix-LSA 中宣告 `fd00::4:0/112` 和 `fd00::5:0/112` 的路由。一段时间后它们的路由表（即直连路由 + OSPF 收到的路由）应该变成这样：

```text
R1:
fd00::1:0/112 dev r1pc1 scope link
fd00::3:0/112 dev r1r2 scope link
fd00::4:0/112 via fd00::3:2 dev r1r2
fd00::5:0/112 via fd00::3:2 dev r1r2
fd00::8:0/112 via fd00::3:2 dev r1r2
fd00::9:0/112 via fd00::3:2 dev r1r2
R3:
fd00::1:0/112 via fd00::4:1 dev r3r2
fd00::3:0/112 via fd00::4:1 dev r3r2
fd00::4:0/112 dev r3r2 scope link
fd00::5:0/112 dev r3pc2 scope link
fd00::8:0/112 via fd00::4:1 dev r3r2
fd00::9:0/112 via fd00::4:1 dev r3r2
```

在 Linux 中，上面的 `via fd00:3:2` 和 `via fd00::4:1` 在实际情况下会变成对应的 fe80 开头的 Link Local 地址。

在代码中，已经为大家设置好了一些常量，根据 ROUTER_R{1,2,3} 宏的不同定义取不同的值。在 `Homework/ospf` 目录下可以看到名为 `r1` `r2` `r3` 的目录，每个目录下都有 Makefile，分别编译出不同宏定义下的路由器。

## 检查内容

评测时 TANLabs 将会自动逐项检查下列内容：

1. 配置网络拓扑，在 R1 和 R3 上运行 BIRD，在 R2 上运行定义了 `ROUTER_R2` 的 OSPF 路由器程序。
2. 等待 OSPF 协议运行一段时间，30 秒后正式开始评测。
3. （20% 分数）测试 R1 和 R3 上的 OSPF 邻居关系：在 R1 和 R3 上运行 `birdc show ospf neighbor` 查看 OSPF 邻居信息。期望输出：R2 对应的 State 为 `Full/PtP`。
4. （15% 分数）测试转发 ICMPv6：在 PC1 上 `ping fd00::5:1` 若干次，在 PC2 上 `ping fd00::1:2` 若干次，测试 ICMP 连通性。期望输出：丢包率不是 100%。
5. （15% 分数）测试转发 TCP：在 PC1 和 PC2 上各监听 80 端口（`sudo nc -6 -l -p 80`），各自通过 nc 访问对方（`nc $remote_ip 80`），测试 TCP 连通性。期望输出：打印了通过 TCP 传输的数据。
6. （40% 分数）判断路由表正误：导出 R1 和 R3 上的系统路由表（运行 `ip -6 route`），和答案进行比对。期望输出：打印出正确的路由表。
7. （10% 分数）测试转发性能：在 PC2 上运行 `iperf3 -s`，在 PC1 上运行 `iperf3 -c fd00::5:1 -O 5 -P 10`，按照 Bitrate 给出分数，测试转发的吞吐率。期望输出：输出了 iperf3 测速结果。

代码量：更新 checksum 小作业的实现约 5 行，处理 OSPF Hello 报文约 10 行，计算路由表约 110 行。

在过程中，如果路由器程序崩溃退出，后续的测试项目都会失败。在实验平台上，可以看到功能和性能的原始评测结果，不公布最终折算成绩。需要注意的是，GNU netcat 不支持 IPv6，请使用 netcat-openbsd。

设转发性能为 $s$，所有同学中转发的最高吞吐率为 $s_{max}$，则性能分数 $S$ 为：

$$
S = S_{total} \times e^{c \times (s/s_{max}-1)}
$$

其中 $c$ 为未知常数。由于性能会计入分数，请在通过所有功能测试后，检查一下是否删除了不必要的影响性能的调试代码。

??? question "为何不在 R2 上配置 IP 地址：fd00::3:2 和 fd00::4:1"

    1. Linux 有自己的网络栈，如果配置了这两个地址，Linux 的网络栈也会进行处理，如 ICMP 响应和（可以开启的）转发功能
    2. 实验中你编写的路由器会运行在 R2 上，它会进行 ND 报文处理（HAL 代码内实现）和 IP 分组转发（你的代码实现），实际上做的和 Linux 网络栈的部分功能是一致的
    3. 为了保证确实是你编写的路由器在工作而不是 Linux 网络栈在工作，所以不在 R2 上配置这两个 IP 地址
    4. 作为保险，HAL 在 Linux 下会关闭对应 interface 的 IPv6 功能。

??? warning "容易出错的地方"

    TODO: 待补充

??? example "可供参考的例子"

    我们提供了 [`ospf-r1.pcap`](static/ospf-r1.pcap) 和 [`ospf-r3.pcap`](static/ospf-r3.pcap) （可点击文件名下载）这两个文件，分别是在 R1 的 r1r2 接口和 R3 的 r3r2 接口的抓包结果，模拟了实验的过程：
    
    1. 开启 R1 R3 上的 BIRD，然后在 R2 上运行的路由器实现
    2. 等待一段时间后，运行 `test4.sh`，测试 PC1 和 PC2 间的 ping 连通性，每个方向 ping 4 次
    
    下面按包序号解释 `ospf-r1.pcap` 的抓包结果：

    ```
    No.1:       R1 从 r1r2 接口向 AllSPFRouters 组播地址，即 ff02::5 发送 OSPF Hello。
    No.2~No.3:  MLD（Multicast Listener Discovery）协议相关报文，用于加入组播组，本实验中不用关心。
    No.4:       R2 路由器启动了，于是开始发送 OSPF Hello 报文。R1 第一次收到 R2 发来的 OSPF Hello，
                R1 开始维护关于 R2 的邻居状态。
    No.5:       R1 在间隔 5 秒后再一次发送 OSPF Hello 报文，在其中包含了 R2 的 Router ID。
    No.6:       R2 第一次收到 R1 的 OSPF Hello (No.5)，开始维护关于 R1 的邻居状态，初始为 Init，
                实验框架在此时会立即触发各个接口发送一次 Hello。
    No.7:       R1 收到 R2 的 Hello，发现其中包含了自己的 Router ID，于是将 R2 的邻居状态设为 ExStart，
                并开始发送 DD 报文。然而由于此时 R2 中 R1 的邻居状态仍为 Init，并且实验框架为了测试对
                OSPF Hello 报文的处理是否正确，并未实现 Init 直接到 ExStart 的状态转换，故该包被丢弃。
    No.8:       R2 在第一次收到 R3 的 OSPF Hello 报文，立即触发各个接口发送一次 Hello，故 R1 也会收到一次。
    No.9:       R1 重传 DD 报文。
    No.10:      R1 间隔 5 秒后，再一次发送 OSPF Hello 报文。
    No.11:      R2 收到 R1 的 OSPF Hello 报文，将 R1 的邻居状态设为 ExStart，开始发送 DD 报文。
    No.12:      R1 收到 R2 的 DD 报文，由于 R2 的 Router ID 比自己大，于是将自己设为 Follower（Slave），
                邻居状态变为 Exchange，使用 R2 的 DD Sequence Number 回复 R2 的 DD 报文，
                其中 Init 位和 Leader（Master）位置为 0，同时携带自己的 LSA Header。
    No.13:      R2 收到 R1 的 DD 报文，将自己设为 Leader（Master），邻居状态变为 Exchange，将自己的
                DD Sequence Number 加一，Leader（Master）位置为 1，同时携带自己的 LSA Header 发送。
    No.14:      R1 收到 R2 的 DD 报文，发现 More 位为 0，于是使用收到 DD 报文的 DD Sequence Number
                回复 R2 的 DD 报文（因为 R1 是 Slave），邻居状态变为 Loading。
    No.15:      R1 发送 LS Request，请求自己没有的两个 R2 的 LSA。
    No.16:      由于 R1 收到过 R2 发来的报文，故邻居缓存中有 R2 地址对应的 MAC 地址，此处是 R1
                正在维护邻居缓存有效性，进行 NUD 检测。
    No.17:      R2 收到 R1 的 DD 报文（No.14），发现 More bit 为 0，于是邻居状态变为 Loading。
    No.18:      R2 发送 LS Update 回复 No.15 的 LS Request。
    No.19:      R2 发送 LS Update 回复 No.15 的 LS Request。由于实验框架一个 LS Update 只回复一个 LSA，
                故有 No.18 和 No.19 两个包。R1 在收到这两个报文后，便完成了所有 LSA 的请求，
                维护的 R2 邻居状态变为 Full。
    No.20:      R2 对 No.16 NUD 检测的回复。
    No.21:      R1 发送 LS Update 回复 No.17 的 LS Request。R2 收到此报文后，便完成了所有 LSA 的请求，
                维护的 R1 邻居状态变为 Full。
    No.22:      R2 维护的 R1 邻居状态变为 Full 后，自身的 Router LSA 中添加了到 R1 的连接信息，
                需要向各个邻居洪泛这个 LSA 的更新。在向 R1 发送更新时，实验框架发出 NS 请求，但丢弃了该包。
    No.23:      R1 回复 NA。
    No.24:      R2 收到 R1 的 LS Update（No.21），回复 LS Acknowledge。
    No.25:      R2 在间隔 5 秒后，再一次发送 OSPF Hello 报文。
    No.26:      R1 收到 R2 的 LS Update（No.18，No.19），回复 LS Acknowledge。BIRD 实现了延迟发送
                LS Acknowledge（详见 RFC2328 Section 13.5），故间隔了一段时间才回复。
    No.27:      R2 重传之前丢弃的 LS Update（No.22）。实验框架中 LS Update 重传和 OSPF Hello 共用计时器，
                故和 No.25 一起发送。
    No.28:      R1 维护的 R2 邻居状态变为 Full 后，自身的 Router LSA 中添加了到 R2 的连接信息，
                向各个邻居洪泛这个 LSA 的更新，此处的延迟发送与 BIRD 的实现相关。
    No.29:      R2 收到 R1 的 LS Update（No.28），回复 LS Acknowledge。
    No.30:      R1 收到 R2 的 LS Update（No.27），回复 LS Acknowledge。
    No.31:      R1 在间隔 5 秒后，再一次发送 OSPF Hello 报文。
    No.32:      R1 维护邻居缓存，进行 NUD 检测。
    No.33:      R2 回复 No.32 的 NUD 检测。
    No.34:      R2 在间隔 5 秒后，再一次发送 OSPF Hello 报文。
    No.35:      R2 收到 R3 的 Router LSA，洪泛 LS Update 给 R1。
    No.36:      R2 维护的 R3 邻居状态变为 Full 后，自身的 Router LSA 中添加了到 R3 的连接信息，
                向各个邻居洪泛这个 LSA 的更新。
    No.37:      R2 收到 R3 的 Intra-Area-Prefix LSA，洪泛 LS Update 给 R1。
    No.38:      R1 收到 R2 的 LS Update（No.35，No.36，No.37），回复 LS Acknowledge。此处为延迟发送。
    No.39:      R2 向 R1 洪泛 R3 的 Router LSA 更新，这说明 R3 维护的 R2 邻居状态已变为 Full，
                并且已经向 R2 洪泛了更新。
    No.40:      R1 收到 R2 的 LS Update（No.39），回复 LS Acknowledge。
    No.41~NO.45: R1 和 R2 继续每隔 5 秒发送 OSPF Hello 报文，维持邻居状态。
    No.46:      PC1 向 PC2 发送 ICMPv6 Echo Request，R1 收到后根据目标 IPv6 地址查询路由表，
                得知下一跳为 R2，于是转发给 R2。
    No.47:      R1 收到了 R2 转发来的 ICMPv6 Echo Reply，之后将根据目标 IPv6 地址查询路由表，
                并得知匹配 r1pc1 接口的直连路由，然后转发给 PC1。
    No.48:      R2 间隔 5 秒后，再一次发送 OSPF Hello 报文。
    No.49~No.54: PC1 ping PC2 的剩余三个来回。
    No.55~No.64: PC2 ping PC1 的四个来回。
    ```

??? question "实现的路由表需要支持容纳多大的规模？"

    你可以从第二、三阶段的评测流程中判断至少需要多大的规模。

??? question "如何提升转发性能？"

    你可以按照代码的框架进行分析，在测试转发性能的时候，代码中哪些部分的执行次数最多，然后估计哪些部分的占用时间最长，然后针对这部分进行优化。

!!! tips "这个实验是怎么设计出来的？"

    第二阶段实验首先是确定了一个网络拓扑，其次才是在网络中测试路由器的功能。如果只有两个路由器，一个运行标准实现，一个运行同学的实现，那就无法判断同学实现的路由器是否正确地把学习到的路由再发送出去，因此最少需要三个路由器。此外，为了模拟终端用户，也是在 R1 和 R3 的两侧分别设置了两个客户端 PC1 和 PC2，它们对网络中的路由器如何配置是不关心的，它们只知道默认路由，并且可以通过默认路由来访问对方，这也模拟了最常见的网络访问形式。因此，网络拓扑设计成了 PC1-R1-R2-R3-PC2 这样的形式。实际上可以设计更复杂的网络拓扑，但是为了减少同学们理解的负担，就简化成一条线的形式。
    
    对于如何测试路由器的功能，也是采用了网络中常见的手段：ping、traceroute、iperf 等等。ping 就是考察了路由表的正确性和转发功能；traceroute 在实验中通过设置不同 Hop Limit 来实现，考察了当 Hop Limit 降为 0 时的处理（本实验中不涉及）；iperf 则是让同学对网络性能有一个概念，并且知道代码中哪些部分对性能影响大，哪些部分影响不大。
    
    这一阶段还希望大家理解和掌握网络模拟和调试的一些方法和工具：Wireshark 和 netns。首先是希望同学掌握网络中的调试方法，之后在遇到网络不通的时候，不再是毫无方向地尝试各种方法，而是按照一定的思路，查看网络各处的状态，排除出问题所在。其次是希望同学接触一些比较先进的网络技术，比如 netns，可以在 Linux 环境中模拟各种各样的网络，也可以让大家了解常见的容器技术是如何实现网络隔离的。如果同学对具体原理不感兴趣，也可以直接用提供好的脚本来搭建基于 netns 的网络环境。
