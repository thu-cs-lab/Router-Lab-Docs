## 本地测试

在编写 RIPng 协议的路由器的时候，我们可以在本机搭建一个虚拟的和评测一样的网络拓扑，这样就可以在虚拟网络中按照评测流程一步一步进行，同时观察程序的行为，可以大大地加快代码的调试。

本地测试主要分为两个部分：首先，搭建网络拓扑，将网络中各个设备连接好；其次，在各个设备上，运行相应的软件（比如 R2 运行自己编写的路由器，R1 R3 运行标准的路由器实现），并配置好网络（比如 IP 地址，路由等等）。具体过程见下。

### 拓扑搭建

为了方便路由器的调试，我们给大家提供树莓派，用来自己搭建网络拓扑，在上面运行自己的程序并且调试。自己测试的时候，有两种办法：

1. netns 或虚拟机：可以在一个设备里模拟完整的网络拓扑，好处是只需要一个设备，坏处是配置起来比较麻烦，而且有一些细节上和实际设备不一样，特别是 ethtool 相关的一些设置。
2. 多设备联调：可以找你的队友或者舍友一起合作搭建一个由树莓派和笔记本连起来的调试网络。

#### 虚拟组网

为了方便测试，你可以在一台计算机上模拟评测环境的网络拓扑，并相应在模拟出的五台 “主机” 中运行不同的程序（如 BIRD / 你实现的路由器软件 / ping 等客户端工具）。这对于你的调试将有很大的帮助。我们建议你采用下列的两种方式：

1. 使用虚拟机安装多个不同的操作系统，并将它们的网络按照需要的拓扑连接。这一方法思路简单，并且可以做到与真实多机环境完全相同，但可能消耗较多的资源。
2. 使用 Linux 提供的 network namespace 功能，在同一个系统上创建多个相互隔离的网络环境，并使用 veth （每对 veth 有两个接口，可以处在不同的 namespace 中，可以理解为一条虚拟的网线）将它们恰当地连接起来。这一方法资源占用少，但是对 Linux 使用经验和网络配置知识有较高的需求。如果你使用的操作系统不是 Linux，可以开一个 Linux 虚拟机进行这些操作。

##### netns 使用方法

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

上面的 all 可以替换为 interface 的名字。在用这种方法的时候需要小心 Linux 自带的转发和你编写的转发的冲突，在 R2 上不要用 `ip a` 命令配置 IP 地址，也不要打开 Linux 自带的转发功能。

想知道当前在哪个 netns 的话，可以执行 `ip netns identify` 命令。可以参考 FAQ 里面的方法把 netns 加入到 shell 的 prompt 中，这样会方便自己的调试。

!!! attention "netns 环境和真实环境的不同"

    由于 netns 是 Linux 里面隔离网络的一种技术，它会默认开启一些优化，比如跳过 checksum 的计算等等。所以，如果在里面直接运行你编写的路由器，很可能会把 checksum 错误的包转发出去，然后 Linux 在校验 checksum 的时候发现它是错的，而且是软件发出来的，它会选择丢弃，可能出现 TCP 连接失败的问题，详见 FAQ 中的相关讨论。

有兴趣的同学也可以尝试一下 [mininet](https://github.com/mininet/mininet) 工具来搭建基于 netns 的虚拟网络。

#### 树莓派组网

树莓派的 USB 网卡按照插拔的顺序，会在 `eth1-4` 开始分配，在实验的拓扑里，我们建议大家改成 `本机设备对端设备` 的名字格式，可以通过 `ip link set $old_name name $new_name` 修改名字，这样方便记忆和配置。每次插拔可能都需要重新修改，可以通过常见的工具来判断是否连接到了正确的设备上。

在 `Setup/rpi` 目录下存放了可供参考的在树莓派的 R1 和 R3 上配置的脚本，还有恢复它的改动的脚本，注意它采用了树莓派中管理网络的 dhcpcd 进行地址的配置，所以可能不适用于树莓派以外的环境。 如果运行过配置脚本，如果要恢复环境，运行恢复脚本 `Setup/restore.sh` 即可，也可以手动删除 `/etc/dhcpcd.conf` 最后的几行内容然后用 `sudo systemctl restart dhcpcd` 来重启 dhcpcd。简单起见，它采用了 netns 来模拟 PC1 和 PC2，这样只需要两个树莓派就可以进行调试。

### 软件配置

我们实现的路由器实际上包括两部分功能：IPv6 分组转发和路由协议。在第二阶段中，自己写的路由器运行在 R2 上，而 R1 R3 都需要运行标准的路由器。那么，在 Linux 环境中，为了实现路由器的功能，需要下面两个部分：分组转发和路由协议。

#### 分组转发

为了打开 Linux 的转发功能（例如 R1 和 R3），需要用 root 身份运行下面的命令（重启后失效）：

```shell
# enable forwarding for all interfaces
echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
```

如果你在 netns 中用 Linux 自带的功能做转发需要运行如下命令：

```shell
# enable forwarding for all interfaces in netns R1
ip netns exec R1 sh -c "echo 1 > /proc/sys/net/ipv4/conf/all/forwarding"
```

#### 路由协议

为了实现路由协议，需要运行 BIRD。我们提供一个 BIRD（BIRD Internet Routing Daemon，安装方法 `apt install bird`）的参考配置，以 Debian 为例，如下修改文件 `/etc/bird.conf` 即可。

需要注意的是，BIRD v1.6 中，为了 IPv6 版本的 BIRD 叫做 `bird6`，而 IPv4 版本的 BIRD 叫做 `bird`；在 BIRD v2.0 中，两个版本合并了，因此都是 `bird`。

##### BIRD v2.0 配置

[BIRD v2.0 官方配置文档](https://bird.network.cz/?get_doc&f=bird.html&v=20)

```conf
# log "bird.log" all; # 可以将 log 输出到文件中
# debug protocols all; # 如果要更详细的信息，可以打开这个

router id 网口IP地址; # 随便写一个，保证唯一性即可

protocol device {
}

protocol kernel {
    # 表示 BIRD 会把系统的路由表通过 RIP 发出去，也会把收到的 RIP 信息写入系统路由表
    # 你可以用 `ip route` 命令查看系统的路由表
    # 退出 BIRD 后从系统中删除路由
    persist no;
    # 从系统学习路由
    learn;
    ipv6 {
        # 导出路由到系统，可以用 `ip r` 看到
        # 也可以用 `export none` 表示不导出，用 birdc show route 查看路由
        export all;
    };
}

protocol static {
    ipv6 { };
    route a:b:c:d::/64 via "网口名称"; # 可以手动添加一个静态路由方便调试，只有在这个网口存在并且为 UP 时才生效
}

protocol direct {
    ipv6;
    # 把网口上的直连路由导入到路由协议中
    interface "网口名称";
}


protocol rip ng {
    ipv6 {
        import all;
        export all;
    };
    debug all;
    interface "网口名称" { # 网口名称必须存在，否则 BIRD 会直接退出
        update time 5; # 5秒一次更新，方便调试
    };
}
```

##### BIRD v1.6 配置

[BIRD v1.6 官方配置文档](https://bird.network.cz/?get_doc&f=bird.html&v=16)

```conf
# log "bird.log" all; # 可以将 log 输出到文件中
# debug protocols all; # 如果要更详细的信息，可以打开这个

router id 网口IP地址; # 随便写一个，保证唯一性即可

protocol device {
}

protocol kernel {
    # 表示 BIRD 会把系统的路由表通过 RIP 发出去，也会把收到的 RIP 信息写入系统路由表
    # 你可以用 `ip route` 命令查看系统的路由表
    # 退出 BIRD 后从系统中删除路由
    persist off;
    # 从系统学习路由
    learn;
    # 导出路由到系统，可以用 `ip r` 看到
    # 也可以用 `export none` 表示不导出，用 birdc show route 查看路由
    export all;
}

protocol static {
    route a:b:c:d::/64 via "网口名称"; # 可以手动添加一个静态路由方便调试，只有在这个网口存在并且为 UP 时才生效
}

protocol direct {
    # 把网口上的直连路由导入到路由协议中
    interface "网口名称";
}

protocol rip {
    import all;
    export all;
    debug all;
    interface "网口名称" { # 网口名称必须存在，否则 BIRD 会直接退出
        update time 5; # 5秒一次更新，方便调试
    };
}
```

</details>

##### 配置使用

这里的网口名字对应你连接到路由器的网口，也要配置一个固定的 IP 地址，需要和路由器对应网口的 IP 在同一个网段内。配置固定 IP 地址的命令格式为 `ip a add IP地址/前缀长度 dev 网口名称`，你可以用 `ip a` 命令看到所有网口的信息。

以下以 BIRD v1.6 为例：启动服务（如 `systemctl start bird6`）后，你就可以开始抓包，同时查看 bird 打出的信息（`journalctl -f -u bird6`），这对调试你的路由器实现很有帮助。

你也可以直接运行 BIRD（`bird6 -c /etc/bird.conf`），可在命令选项中加上 `-d` 把程序放到前台，方便直接退出进程。若想同时开多个 BIRD，则需要给每个进程指定单独的 PID 文件和 socket，如 `bird6 -d -c bird1.conf -P bird1.pid -s bird1.socket` 。

在安装 BIRD（`sudo apt install bird`）之后，它默认是已经启动并且开机自启动。如果要启动 BIRD，运行 `sudo systemctl start bird6`；停止 BIRD： `sudo systemctl stop bird6`；重启 BIRD：`sudo systemctl restart bird6`；打开开机自启动：`sudo systemctl enable bird6`；关闭开机自启动：`sudo systemctl disable bird6`。

配合 BIRD 使用的还有它的客户端程序 `birdc6`，它可以连接到 BIRD 服务并且控制它的行为。默认情况下 birdc 会连接系统服务（systemctl 启动）的 BIRD，如果启动 BIRD 时采用了 `-s` 参数，那么 birdc 也要指定同样的 socket 路径。

对于一条静态路由（如 `route a:b:c:d::/64 via "abcd"`），它只有在 `abcd` 处于 UP 状态时才会生效，如果你只是想让 BIRD 向外宣告这一条路由，可以用 `lo`（本地环回）代替 `abcd` 并且运行 `ip l set lo up`。你可以用 `birdc6 show route` 来确认这件事情。

### 快捷脚本

实验仓库中，在 `Setup/netns` 目录下提供了在 netns 环境下的 BIRD 配置，你可以参考里面的进行配置。

你还可以在作业仓库的 `Setup/netns` 目录下找到通过 netns 模拟评测环境的脚本（个人评测 `setup-netns.sh`，组队评测 `setup-netns-group.sh`），你需要先尝试阅读并理解里面的脚本代码， **在理解脚本代码** 后再执行并在里面运行自己的程序。

!!! tips "第二阶段实验是怎么设计出来的？"

    第二阶段实验首先是确定了一个网络拓扑，其次才是在网络中测试路由器的功能。如果只有两个路由器，一个运行标准实现，一个运行同学的实现，那就无法判断同学实现的路由器是否正确地把学习到的路由再发送出去，因此最少需要三个路由器。此外，为了模拟终端用户，也是在 R1 R3 的两侧分别设置了两个客户端 PC1 和 PC2，它们对网络中的路由器如何配置是不关心的，它们只知道默认路由，并且可以通过默认路由来访问对方，这也模拟了我们最常见的网络访问形式。因此，网络拓扑设计成了 PC1-R1-R2-R3-PC2 这样的形式。实际上可以设计更复杂的网络拓扑，但是为了减少同学们理解的负担，就简化成一条线的形式。

    对于如何测试路由器的功能，也是采用了网络中常见的手段：ping，traceroute，iperf 等等。ping 就是考察了路由表的正确性和转发功能；traceroute 在实验中通过设置不同 hlim 来实现，考察了当 hlim 降为 0 时的处理；iperf 则是让同学对网络性能有一个概念，并且知道代码中哪些部分对性能影响大，哪些部分影响不大。

    这一阶段还希望大家理解和掌握网络模拟和调试的一些方法和工具：wireshark 和 netns。首先是希望同学掌握网络中的调试方法，之后在遇到网络不通的时候，不再是毫无方向地尝试各种方法，而是按照一定的思路，查看网络各处的状态，排除出问题所在。其次是希望同学接触一些比较先进的网络技术，比如 netns，可以在 linux 环境中模拟各种各样的网络，也可以让大家了解常见的容器技术是如何实现网络隔离的。如果同学不感兴趣具体原理，也可以直接用提供好的脚本来搭建基于 netns 的网络环境。