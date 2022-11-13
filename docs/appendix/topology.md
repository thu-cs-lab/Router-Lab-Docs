## 拓扑搭建

为了方便路由器的调试，你可以自己搭建网络拓扑，在上面运行自己的程序并且调试。具体来说，有两种办法：

1. netns 或虚拟机：可以在一个设备里模拟完整的网络拓扑，好处是只需要一个设备，坏处是配置起来比较麻烦，而且有一些细节上和实际设备不一样，特别是 ethtool 相关的一些设置。
2. 多设备联调：可以找你的队友或者舍友一起合作搭建一个由树莓派和笔记本连起来的调试网络。

### 虚拟组网

为了方便测试，你可以在一台计算机上模拟评测环境的网络拓扑，并相应在模拟出的五台“主机”中运行不同的程序（如 BIRD / 你实现的路由器软件 / ping 等客户端工具）。这对于你的调试将有很大的帮助。建议你采用下列的两种方式：

1. 使用虚拟机安装多个不同的操作系统，并将它们的网络按照需要的拓扑连接。这一方法思路简单，并且可以做到与真实多机环境完全相同，但可能消耗较多的资源。
2. 使用 Linux 提供的 network namespace 功能，在同一个系统上创建多个相互隔离的网络环境，并使用 veth（每对 veth 有两个接口，可以处在不同的 namespace 中，可以理解为一条虚拟的网线）将它们恰当地连接起来。这一方法资源占用少，但是对 Linux 使用经验和网络配置知识有较高的需求。如果你使用的操作系统不是 Linux，可以开一个 Linux 虚拟机进行这些操作。

#### netns 使用方法

针对 netns，在下面提供了一些简单的指导：

和 network namespace 相关的操作的命令是 `ip netns`。例如想要创建两个 namespace 并让其能够互相通信：

```bash
ip netns add net0 # 创建名为 "net0" 的 namespace
ip netns add net1
ip link add veth-net0 type veth peer name veth-net1 # 创建一对相互连接的 veth pair
ip link set veth-net0 netns net0 # 将 veth 一侧加入到一个 namespace 中
ip link set veth-net1 netns net1 # 配置 veth 另一侧
ip netns exec net0 ip link set veth-net0 up
ip netns exec net0 ip addr add 10.1.1.1/24 dev veth-net0 # 给 veth 一侧配上 ip 地址
ip netns exec net1 ip link set veth-net1 up
ip netns exec net1 ip addr add 10.1.1.2/24 dev veth-net1
```

上面的命令配置了如下的虚拟网络：

![netns](img/netns.png)

配置完成后你可以运行 `ip netns exec net0 ping 10.1.1.2` 来测试在 net0 上是否能够 ping 到 net1。

你还可以运行 `ip netns exec net0 [command]` 来执行任何你想在特定 namespace 下执行的命令，也可以运行 `ip netns exec net0 bash` 打开一个网络环境为 net0 的 bash。

上面的 all 可以替换为 interface 的名字。在用这种方法的时候需要小心 Linux 自带的转发和你编写的转发的冲突，在 R2 上不要用 `ip a` 命令配置 IP 地址，也不要打开 Linux 自带的转发功能。

想知道当前在哪个 netns 的话，可以执行 `ip netns identify` 命令。可以参考 FAQ 里面的方法把 netns 加入到 shell 的 prompt 中，这样会方便自己的调试。

!!! attention "netns 环境和真实环境的不同"

    由于 netns 是 Linux 里面隔离网络的一种技术，它会默认开启一些优化，比如跳过 checksum 的计算，跳过 MAC 地址的判断等等。所以，如果在里面直接运行你编写的路由器，很可能会把 checksum 错误的 IP 分组转发出去，然后 Linux 在校验 checksum 的时候发现它是错的，而且是软件发出来的，它会选择丢弃，可能出现 TCP 连接失败的问题，详见 FAQ 中的相关讨论。

有兴趣的同学也可以尝试一下 [mininet](https://github.com/mininet/mininet) 工具来搭建基于 netns 的虚拟网络。