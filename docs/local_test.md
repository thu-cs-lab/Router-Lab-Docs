# 本地测试方法

## 编程作业测试

在 `Homework` 目录下有四个编程作业，每个作业中有评分脚本，通过数据测试你的路由器中核心功能的实现。你需要在被标记 TODO 的函数中补全它的功能，通过测试后，就可以更容易地完成后续的路由器实现。

有这些作业，每个作业对应一个目录：

```text
eui64：生成 IPv6 Link Local 地址
internet-checksum：计算校验和
lookup：路由表查询和更新
protocol：RIPng 协议解析和封装
```

每个题目都有类似的结构（以 `internet-checksum` 为例）：

```text
data：数据所在的目录
checksum.cpp：你需要修改的地方
grade.py：一个简单的评分脚本，它会编译并运行你的代码，进行评测
main.cpp：用于评测的交互库，你不需要修改它
Makefile：用于编译并链接 HAL、交互库和你实现的代码
README.md：题目的要求
```

使用方法（在 Homework/internet-checksum 目录下执行）：

```bash
pip3 install pyshark # 仅第一次
# 修改 checksum.cpp
make # 编译，得到可以执行的 checksum
./checksum < data/checksum_input1.pcap # 你可以手动运行来看效果
make grade # 也可以运行评分脚本，实际上就是运行 python3 grade.py
```

上述命令会对每组数据运行你的程序，然后比对输出。如果输出与预期不一致，它会用 diff 工具把你的输出和答案输出的不同显示出来。

其中部分作业的输入数据的格式是 PCAP，它是一种常见的保存网络流量的格式，它可以用 Wireshark 软件打开来查看它的内容，也可以自己按照这个格式造新的数据。需要注意的是，为了区分一个以太网帧到底来自哪个虚拟的网口，我们所有的 PCAP 输入都有一个额外的 VLAN 头，VLAN 0-3 分别对应虚拟的 0-3 号网口，虽然实际情况下不应该用 VLAN 0，但简单起见就直接映射了。

!!! attention "GitLab CI 评测"

    当你用 Git 把代码提交到 GitLab 上的时候，GitLab 会按照仓库内的 `.gitlab-ci.yml` 设置的脚本进行编译和评测，它会调用上面提到的本地评测脚本。如果出现了本地评测成功，在线评测失败的情况，请先阅读 FAQ 排查常见问题，排查无果请联系助教。但请不要擅自修改 `.gitlab-ci.yml`，严禁 **攻击** 评测系统。

## 路由器测试

为了方便路由器的调试，我们给大家提供树莓派，用来自己搭建网络拓扑，在上面运行自己的程序并且调试。自己测试的时候，有两种办法：

1. netns 或虚拟机：可以在一个设备里模拟完整的网络拓扑，好处是只需要一个设备，坏处是配置起来比较麻烦，而且有一些细节上和实际设备不一样，特别是 ethtool 相关的一些设置。
2. 多设备联调：可以找你的队友或者舍友一起合作搭建一个由树莓派和笔记本连起来的调试网络。

### 虚拟组网

为了方便测试，你可以在一台计算机上模拟评测环境的网络拓扑，并相应在模拟出的五台 “主机” 中运行不同的程序（如 BIRD / 你实现的路由器软件 / ping 等客户端工具）。这对于你的调试将有很大的帮助。我们建议你采用下列的两种方式：

1. 使用虚拟机安装多个不同的操作系统，并将它们的网络按照需要的拓扑连接。这一方法思路简单，并且可以做到与真实多机环境完全相同，但可能消耗较多的资源。
2. 使用 Linux 提供的 network namespace 功能，在同一个系统上创建多个相互隔离的网络环境，并使用 veth （每对 veth 有两个接口，可以处在不同的 namespace 中，可以理解为一条虚拟的网线）将它们恰当地连接起来。这一方法资源占用少，但是对 Linux 使用经验和网络配置知识有较高的需求。如果你使用的操作系统不是 Linux，可以开一个 Linux 虚拟机进行这些操作。

#### netns 使用方法

针对 netns ，我们在下面提供了一些简单的指导：

和 network namespace 相关的操作的命令是 `ip netns`。例如我们想要创建两个 namespace 并让其能够互相通信：

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

如果你在一个 netns 中用 Linux 自带的功能做转发（例如 R1 和 R3），需要运行如下命令（root 身份，重启后失效，需要注意执行的 netns）：

```shell
# enable forwarding for all interfaces
echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
# enable forwarding for all interfaces in netns R1
ip netns exec R1 sh -c "echo 1 > /proc/sys/net/ipv4/conf/all/forwarding"
```

上面的 all 可以替换为 interface 的名字。在用这种方法的时候需要小心 Linux 自带的转发和你编写的转发的冲突，在 R2 上不要用 `ip a` 命令配置 IP 地址，也不要打开 Linux 自带的转发功能。

你可以在作业仓库的 `Setup/netns` 目录下找到模拟评测环境的脚本，你需要先尝试阅读并理解里面的脚本代码， **在理解脚本代码** 后再执行并在里面运行自己的程序。需要注意的是，这些脚本并没有配置 Linux 的转发功能，你可以按照需求自行添加。

想知道当前在哪个 netns 的话，可以执行 `ip netns identify` 命令。可以参考 FAQ 里面的方法把 netns 加入到 shell 的 prompt 中，这样会方便自己的调试。

!!! attention "netns 环境和真实环境的不同"

    由于 netns 是 Linux 里面隔离网络的一种技术，它会默认开启一些优化，比如跳过 checksum 的计算等等。所以，如果在里面直接运行你编写的路由器，很可能会把 checksum 错误的包转发出去，然后 Linux 在校验 checksum 的时候发现它是错的，而且是软件发出来的，它会选择丢弃，可能出现 TCP 连接失败的问题，详见 FAQ 中的相关讨论。

有兴趣的同学也可以尝试一下 [mininet](https://github.com/mininet/mininet) 工具来搭建基于 netns 的虚拟网络。

### 树莓派组网

树莓派的 USB 网卡按照插拔的顺序，会在 `eth1-4` 开始分配，在实验的拓扑里，我们建议大家改成 `本机设备对端设备` 的名字格式，可以通过 `ip link set $old_name name $new_name` 修改名字，这样方便记忆和配置。每次插拔可能都需要重新修改，可以通过常见的工具来判断是否连接到了正确的设备上。

在 `Setup/rpi` 目录下存放了可供参考的在树莓派的 R1 和 R3 上配置的脚本，还有恢复它的改动的脚本，注意它采用了树莓派中管理网络的 dhcpcd 进行地址的配置，所以可能不适用于树莓派以外的环境。 如果运行过配置脚本，如果要恢复环境，运行恢复脚本 `Setup/restore.sh` 即可，也可以手动删除 `/etc/dhcpcd.conf` 最后的几行内容然后用 `sudo systemctl restart dhcpcd` 来重启 dhcpcd。简单起见，它采用了 netns 来模拟 PC1 和 PC2，这样只需要两个树莓派就可以进行调试。
