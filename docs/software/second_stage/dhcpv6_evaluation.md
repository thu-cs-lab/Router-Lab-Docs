## 网络拓扑


在 TANLabs 提交后，会在实验室的实验网络下进行真机评测。你的软件会运行在树莓派上，和平台提供的机器组成如下的拓扑：

![Topology](img/topology_dhcpv6.png)

这一阶段，PC1 和 R2 由 TANLabs 自动配置和提供，你代码所运行在的树莓派处于 R1 的位置。

初始状态下，PC1 没有 IPv6 地址，也没有路由。在 R2 上配置了初始的 IPv6 地址 `fd00::3:2/112` 和如下的路由：

```text
fd00::1:0/112 via fd00::3:1 dev r2r1
fd00::3:0/112 dev r2r1 scope link
```

R1 负责为 PC1 分配动态的 IP 地址 `fd00::1:2/112`。

## 检查内容

评测时 TANLabs 将会自动逐项检查下列内容：

1. 配置网络拓扑，在 R1 上运行定义了 `ROUTER_R1` 的 DHCPv6 服务器程序。
2. （35% 分数）测试 ICMPv6 Router Solicitation 处理：在 PC1 上运行 `rdisc6 pc1r1`，可以获取正确的信息。
3. （45% 分数）测试 DHCPv6 获取 IP 地址：在 PC1 上运行 `dhcpcd -6 -1 -B -C resolv.conf -d pc1r1`，能否成功获取动态 IPv6 地址。
4. （10% 分数）测试 ping：在 PC1 上运行 `ping fd00::3:2`，能否联通。
5. （10% 分数）测试转发性能：在 R2 上运行 `iperf3 -s`，在 PC1 上运行 `iperf3 -c fd00::3:2 -O 5 -P 10`，按照 Bitrate 给出分数，测试转发的效率。

代码量：实现 ICMPv6 处理约 70 行，实现 DHCPv6 协议约 120 行。

设转发性能为 $s$，所有同学中转发的最高性能为 $s_{max}$，则性能分数 $S$ 为：

$$
S = S_{total} \times e^{c \times (s/s_{max}-1)}
$$

其中 $c$ 为未知常数。由于性能会计入分数，请在通过所有功能测试后，检查一下是否删除了不必要的影响性能的调试代码。

??? warning "容易出错的地方"

??? example "可供参考的例子"

??? tip "在线评测的原理"