# 验收流程

实验一共有三个部分的要求，第一部分是实现 `Homework` 下面的四个题目，要求在 GitLab 上提交代码；第二部分是针对个人的测试，主要测试转发和 RIP 协议的细节；第三部分是针对组队的测试。

??? tip "CIDR 表示方法"

    下面多次用到了 CIDR 的表示方法，格式是 ipv6_addr/len ，可能表示以下两种意义之一：

    1. 地址是 ipv6_addr，并且最高 len 位和 ipv6_addr 相同的 IPv6 地址都在同一个子网中，常见于对于一个网口的 IP 地址的描述。如 fd00::a:b/112表示 fd00::a:b 的地址，同一个子网的地址只有最后 16 位可以不同。
    2. 描述一个地址段，此时 ipv6_addr 除了最高 len 位都为零，表示一个 IP 地址范围，常见于路由表。如 fd00::a:b/112 表示从 fd00::a:0 到 fd00::a:ffff 的地址范围。

## 实验第一部分

实验的第一部分目前共有四道题，要求同学们独立完成，助教会对代码进行人工检查和查重。需要实现的函数功能都在函数的注释中进行了阐述，评测所采用的数据都公开。

如果出现了本地自测通过但在 GitLab CI 上测试不通过的情况，请按照如下步骤进行排查：

1. 在 GitLab CI 上，找到 homework 评测的任务，确认一下题目的 grade 和本地是否不一致
2. 检查一下代码，是否存在 **内存访问溢出**、**变量未初始化** 等常见问题。可以使用 ASan 和 UBSan 来辅助检查这些问题。
3. 检查本地的代码和 GitLab 上代码是否一致，即是否出现未提交到 GitLab 的本地代码。
4. 如果这些问题都没有，请在群里找助教，并注明是哪一个分支上哪一个提交。

同学需要在 TanLabs 上标记哪一次测评的结果作为最终的成绩。

## 实验第二部分

实验的第二部分是针对个人的测试，在 TanLabs 提交后，会在实验室的实验网络下进行真机评测。你的软件会运行在树莓派上，和我们提供的机器组成如下的拓扑：

![Topology](img/topology.png)

这一阶段，PC1、R1、R3、PC2 都由 TanLabs 自动配置和提供，两台路由器上均运行 BIRD 作为标准的路由软件实现。你代码所运行在的树莓派处于 R2 的位置。其中 R2 实际用到的只有两个口，剩余两个口按顺序配置为 `fd00::8:1/112` 和 `fd00::9:1/112` （见 `Router-Lab/Homework/router/main.cpp` 代码中 ROUTER_R2 部分）。初始情况下，R1 和 R3 先不启动 RIP 协议处理程序，这些机器的系统路由表如下：

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

上面的每个网口名称格式都是两个机器拼接而成，如 `pc1r1` 代表 pc1 上通往 r1 的网口。此时，接上你的树莓派，按照图示连接两侧的 R1 和 R3 后，从 PC1 到 PC2 是不通的。接着，在 R1 和 R3 上都开启 RIPng 协议处理程序 BIRD，它们分别会在自己的 RIP 包中宣告 `fd00::1:0/112` 和 `fd00::5:0/112` 的路由。一段时间后它们的路由表（即直连路由 + RIP 收到的路由）应该变成这样：

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
fd00::1:0/112 via fd00::4:1 dev r3r2
fd00::4:0/112 dev r3r2 scope link
fd00::5:0/112 dev r3pc2 scope link
fd00::8:0/112 via fd00::4:1 dev r3r2
fd00::9:0/112 via fd00::4:1 dev r3r2
```

在 Linux 中，上面的 `via fd00:3:2` 和 `via fd00::4:1` 在实际情况下会变成对应的 fe80 开头的 Link Local 地址。

在代码中，已经为大家设置好了一些常量，根据 ROUTER_R{1,2,3} 宏的不同定义取不同的值。

### 检查内容和方法

对于单人测试，TanLabs 将会自动逐项检查下列内容：

1. 配置网络拓扑，在 R1 和 R3 上运行 BIRD，在 R2 上运行定义了 `ROUTER_R2` 的路由器程序。
2. 等待 RIPng 协议运行一段时间，一分钟后正式开始评测。
3. 在 PC1 上 `ping fd00::5:1` 若干次，在 PC2 上 `ping fd00::1:2` 若干次，测试 ICMP 连通性。
4. 在 PC1 和 PC2 上各监听 80 端口（`sudo nc -6 -l -p 80`），各自通过 nc 访问对方（`nc $remote_ip 80`），测试 TCP 连通性。
5. 在 PC1 上 `ping fd00::5:1 -t 2`，应当出现 `Time Exceeded` 的 ICMPv6 响应，从 PC2 同样地运行 `ping fd00::1:2 -t 2`，测试 HopLimit=0 时的处理。
6. 导出 R1 和 R3 上 系统的路由表（运行 `ip -6 route`），和答案进行比对。
7. 在 PC2 上运行 `iperf3 -s`，在 PC1 上运行 `iperf3 -c fd00::5:1 -O 5 -P 10`，按照 Bitrate 给出分数，测试转发的效率。

在过程中，如果路由器程序崩溃退出，后续的测试项目都会失败。在实验平台上，可以看到功能和性能的原始评测结果，不公布最终折算成绩。需要注意的是，GNU netcat 不支持 IPv6，请使用 netcat-openbsd。

同学可以在下发的树莓派上自己搭建一个和要求一致的网络拓扑来进行测试，见 “本地测试” 文档。

??? question "为何不在 R2 上配置 IP 地址：fd00::3:2 和 fd00::4:1"

    1. Linux 有自己的网络栈，如果配置了这两个地址，Linux 的网络栈也会进行处理，如 ICMP 响应和（可以开启的）转发功能
    2. 实验中你编写的路由器会运行在 R2 上，它会进行 ICMP NDP 响应（HAL 代码内实现）和 ICMP Echo 响应（你的代码实现）和转发（你的代码实现），实际上做的和 Linux 网络栈的部分功能是一致的
    3. 为了保证确实是你编写的路由器在工作而不是 Linux 网络栈在工作，所以不在 R2 上配置这两个 IP 地址
    4. 作为保险，HAL 在 Linux 下会关闭对应 interface 的 IPv6 功能。

??? warning "容易出错的地方"

    1. Metric 计算和更新方式不正确或者不在 [1,16] 的范围内
    2. 没有正确处理 RIP Response，特别是 metric=16 的处理，参考 [RFC 2080 Section 2.4.2 Response Messages](https://www.rfc-editor.org/rfc/rfc2080.html#section-2.4.2)
    3. 转发的时候查表 not found，一般情况是路由表出错，或者是查表算法的问题
    4. 更新路由表的时候，查询应该用精确匹配，但是错误地使用了最长前缀匹配
    5. 没有对所有发出的 RIP Response 正确地实现水平分割和毒性反转
    6. 字节序不正确，可以通过 Wireshark 看出

??? example "可供参考的例子"

    我们提供了 [`host0.pcap`](static/host0.pcap) 和 [`host1.pcap`](static/host1.pcap) （可点击文件名下载）这两个文件，分别是在 R1 和 R3 抓包的结果，模拟了实验的过程：

    1. 开启 R1 R3 上的 BIRD 和 R2 上运行的路由器实现
    2. 使用 ping 进行了若干次连通性测试

    注意，这个例子中，路由器只实现了 split horizon，没有实现 reverse poisoning，你的实现不需要和它完全一样。Split horizon 的实现方法见 [RFC2452 3.4.3 Split horizon 第一段](https://tools.ietf.org/html/rfc2453#page-15)。

    举个例子，从 PC1 到 PC2 进行 ping 连通性测试的网络活动（忽略 RIP）：

    1. PC1 要 ping fd00::5:1，查询路由表得知下一跳是 fd00::1:1。
    2. 假如 PC1 还不知道 fd00::1:1 的 MAC 地址，则发送 NDP 请求（通过 pc1r1）询问 fd00::1:1 的 MAC 地址。
    3. R1 接收到 NDP 请求，回复 MAC 地址（r1pc1）给 PC1 （通过 r1pc1）。
    4. PC1 把 ICMPv6 包发给 R1 ，目标 MAC 地址为上面 NDP 请求里回复的 MAC 地址，即 R1 的 MAC 地址（r1pc1）。
    5. R1 接收到 IP 包，查询路由表得知下一跳是 fd00::3:2，假如它已经知道 fd00::3:2 的 MAC 地址。
    6. R1 把 IP 包外层的源 MAC 地址改为自己的 MAC 地址（r1r2），目的 MAC 地址改为 fd00::3:2 的 MAC 地址（R2 的 r2r1），发给 R2（通过 r1r2）。
    7. R2 接收到 IP 包，查询路由表得知下一跳是 fd00::4:2，假如它不知道 fd00::4:2 的 MAC 地址，所以丢掉这个 IP 包。
    8. R2 发送 NDP 请求（通过 r2r3）询问 fd00::4:2 的 MAC 地址。
    9. R3 接收到 NDP 请求，回复 MAC 地址（r3r2）给 R2（通过 r3r2）。
    10. PC1 继续 ping fd00::5:1，查询路由表得知下一跳是 fd00::1:1。
    11. PC1 把 ICMPv6 包发给 R1 ，目标 MAC 地址为 fd00::1:1 对应的 MAC 地址，源 MAC 地址为 fd00::1:2 对应的 MAC 地址。
    12. R1 查表后把 ICMPv6 包发给 R2，目标 MAC 地址为 fd00::3:2 对应的 MAC 地址，源 MAC 地址为 fd00::3:2 对应的 MAC 地址。
    13. R2 查表后把 ICMPv6 包发给 R3，目标 MAC 地址为 fd00::4:2 对应的 MAC 地址，源 MAC 地址为 fd00::4:1 对应的 MAC 地址。
    14. R3 查表后把 ICMPv6 包发给 PC2，目标 MAC 地址为 fd00::5:1 对应的 MAC 地址，源 MAC 地址为 fd00::5:2 对应的 MAC 地址。
    15. PC2 收到后响应，查表得知下一跳是 fd00::5:2。
    16. PC2 把 ICMPv6 包发给 R3，目标 MAC 地址为 fd00::5:2 对应的 MAC 地址，源 MAC 地址为 fd00::5:2 对应的 MAC 地址。
    17. R3 把 ICMPv6 包发给 R2，目标 MAC 地址为 fd00::4:1 对应的 MAC 地址，源 MAC 地址为 fd00::4:2 对应的 MAC 地址。
    18. R2 把 ICMPv6 包发给 R1，目标 MAC 地址为 fd00::3:1 对应的 MAC 地址，源 MAC 地址为 fd00::3:2 对应的 MAC 地址。
    19. R1 把 ICMPv6 包发给 PC1，目标 MAC 地址为 fd00::1:2 对应的 MAC 地址，源 MAC 地址为 fd00::1:1 对应的 MAC 地址。
    20. PC1 上 ping 显示成功。

??? tip "在线评测的原理"

    实验团队部署了树莓派集群，对于一次个人的真机评测，会分配三个树莓派和两个 VLAN，分别对应 PC1/R1、R2 和 R3/PC2，两个 VLAN 分别对应 R1-R2 和 R2-R3，使用 veth 连接 PC1-R1 和 R3-PC2。
    接着，在 R1 和 R3 对应的树莓派上进行各种配置，包括 netns、veth、forwarding 和 ethtool（关闭 generic-receive-offload） 的设置。在 R1 和 R3 上运行 BIRD，在 R2 上下载静态编译好的路由器程序，在容器里运行。接着，就按照上面所述的测试命令一条一条进行。

    特别地，为了安全，程序运行在单独的 chroot 和 user 中，并且限制了 capability。同时为了保证性能的稳定性，把进程绑定到了一个 CPU 核上。另外，为了提升性能，我们把 CPU Scaling Governor 设为 performance，让树莓派在不打开超频的条件下在最大主频下运行。

## 实验第三部分

第三部分是针对组队的测试，一个组一般是三个人，网络拓扑与单人测试相同，只不过此时 R1、R2、R3 都运行同学的代码。在组队完成后，队长可以在 TanLabs 上进行评测，设置 R1 R2 R3 分别对应同学的哪一个版本的代码。同样地，需要标记一次评测为全组的最终成绩。

### 测试方法

测试方法：

1. 配置网络拓扑，在 R1 R2 R3 上分别运行三位同学的程序，分别定义 `ROUTER_R{1,2,3}` 宏定义编译后的路由器程序。
2. 等待 RIP 协议运行一段时间，一分钟后进行评测。
3. 在 PC1 上 `ping 192.168.5.1` 若干次，在 PC2 上 `ping 192.168.1.2` 若干次，测试 ICMP 连通性。
4. 在 PC1 和 PC2 上各监听 80 端口，各自通过 nc 访问对方，测试 TCP 连通性。
5. 在 PC1 上 `ping 192.168.5.1 -t 1`，应当出现 `Time to live exceeded` 的响应（R1 发给 PC1），再把 TTL 改成 2 （R2 发给 PC1） 和 3（R3 发给 PC1），测试三个路由器的 TTL=0 的处理，再反过来从 PC2 上 `ping 192.168.1.2 -t 1`，也应当出现 `Time to live exceeded` 的响应（R3 发给 PC2），再把 TTL 改成 2 （R2 发给 PC2） 和 3 （R1 发给 PC2） 。
6. 在 PC1 上 `ping 192.168.233.233`，应当出现 `Destination Net Unreachable`（R1 发给 PC1），在 PC2 上 `ping 192.168.233.233` 亦然（R3 发给 PC2）。
7. 在 PC2 上运行 `iperf3 -s`，在 PC1 上运行 `iperf3 -c 192.168.5.1 -O 5 -P 10`，按照 Bitrate 给出分数，测试转发的效率。
8. 在 PC2 上运行 `iperf3 -s`，在 PC1 上运行 `iperf3 -c 192.168.5.1 -u -l 16 -t 5 -b 1G -O 5`，按照接收方实际收到的 Datagram 数量每秒（即 Total Datagram 减去 Lost，再除以时间）给出分数，测试转发的效率。
9. 小规模路由表压力测试：在 PC1 上开启 bird，配置 192.168.20.0/24 ~ 192.168.255.0/24 共两百多条新的路由，在 PC1 上配置 192.168.20.1/32 和 192.168.255.1/32 的地址，从 PC2 ping 这两个地址可以成功。
10. 中规模路由表压力测试：在上一步的基础上，在 PC1 上增加 10.0.0.0/24 ~ 10.7.255.0/24 共 2048 条新路由，在 PC1 上配置 10.1.2.3/32 和 10.8.7.6/32 的地址，从 PC2 ping 这两个地址可以成功。
11. 大规模路由表压力测试：在上一步的基础上，在 PC1 上增加 1.51.0.0/16 到 233.129.252.0/24 共 5318 条 AS4538 的新路由，在 PC1 上配置 166.111.4.100/32 和 101.6.4.100/32 的地址，从 PC2 ping 这两个地址可以成功。

在过程中，如果路由器程序崩溃退出，后续的测试项目都会失败。在实验平台上，可以看到功能和性能的原始评测结果，不公布最终成绩。

对于第 9 步到第 11 步，在实验框架最新版的 `Setup/part9to11` 目录下有对应的配置文件。为了进行第 9 步到第 11 步的评测，需要：

1. 在 PC1 上运行 BIRD，使用的配置是 `Setup/part9to11/bird1.conf`：`sudo ip netns exec PC1 bird -c bird1.conf -s bird1.ctl -d`
2. 接着，在 PC1 上把 lo 网络接口配置起来：`sudo ip netns exec PC1 ip l set lo up`
3. 配置第 9 步指定的 IP 地址：`sudo ip netns exec PC1 ip a add 192.168.20.1/32 dev pc1r1`，其他依此类推
4. 启用 part9 的配置：`sudo birdc -s bird1.ctl enable part9`
5. 此时应该可以看到 part9 的配置已经启用，可以在 PC2 上进行 ping 的测试了
6. 按照同样的方法，完成第 10 步和第 11 步的测试

PC1 和 PC2 的路由：

```text
PC1:
default via 192.168.1.1 dev pc1r1
192.168.1.0/24 dev pc1r1 scope link
PC2:
default via 192.168.5.2 dev pc2r3
192.168.5.0/24 dev pc2r3 scope link
```

初始情况下 R1 R2 R3 都只有对应的直连路由，只有在正确地运行 RIP 协议后，才能从 PC1 ping 通 PC2 。

??? warning "容易出错的地方"

    1. 自己或者队友的水平分割实现的不正确
    2. RIP 中有一些字段不符合要求
    3. USB 网卡的插入顺序不对
    4. 直连路由配置不正确
    5. PC1 和 PC2 配置不正确，ICMP 包根本没有发给 R1 和 R3
    6. Windows 默认不响应 ICMP Echo Request，[解决方法](https://kb.iu.edu/d/aopy)
    7. BIRD 配置不正确，如网卡名称和实际情况对不上

??? tip "提升转发性能的方法"

    1. 去掉转发时的调试输出
    2. 增量更新 Checksum，[参考 RFC 1624](https://tools.ietf.org/html/rfc1624)
    3. 优化路由表查询算法

??? tip "支持较大路由表的方法"

    1. 发送 RIP Response 时按照 25 条为一组进行切分
    2. 完善路由表更新算法
    3. 完善路由表查询算法
