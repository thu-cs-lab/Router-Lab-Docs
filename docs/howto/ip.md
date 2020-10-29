# `ip` 命令的使用

在本文中几次提到了 `ip` 命令的使用，它的全名为 iproute2，是当前管理 Linux 操作系统网络最常用的命令之一。需要注意的是，涉及到更改的命令都需要 root 权限，所以需要在命令前加一个 `sudo 命令` （注意空格）表示用 root 权限运行。

以下是一些网络上的 ip 命令的使用帮助：

[How To Use IPRoute2 Tools to Manage Network Configuration on a Linux VPS](https://www.digitalocean.com/community/tutorials/how-to-use-iproute2-tools-to-manage-network-configuration-on-a-linux-vps)

[IPROUTE2 Utility Suite Howto](http://www.policyrouting.com/iproute2.doc.html)

## `ip a` 子命令

第一个比较重要的子命令是 `ip a`，它是 `ip addr` 的简写，意思是列出所有网口信息和地址信息，如：

```text
2: enp14s0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 12:34:56:78:9a:bc brd ff:ff:ff:ff:ff:ff
```

代表有一个名为 `enp14s0` 的网口，状态为 `DOWN` 表示没有启用，反之 `UP` 表示已经启用，下面则是它的 MAC 地址，其他部分可以忽略。

每个网口可以有自己的 IP 地址，如：

```text
2: enp14s0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state UP group default qlen 1000
    link/ether 12:34:56:78:9a:bc brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.4/26 brd 1.2.3.127 scope global dynamic enp14s0
       valid_lft 233sec preferred_lft 233sec
    inet6 2402:f000::233/128 scope global dynamic noprefixroute
       valid_lft 23333sec preferred_lft 23333sec
```

这代表它有一个 IPv4 地址 1.2.3.4 和一个 IPv6 地址 2404:f000::233，其表示方法为 CIDR，即地址和前缀长度。

如果要给网口配置一个 IP 地址，命令为 `ip addr add $addr/$prefix_len dev $interface` 其中 $addr $prefix_len $interface 是需要你填入的，比如对于上面这个例子，可能之前执行过 `ip addr add 1.2.3.4/26 dev enp14s0` 。删除只要把 add 换成 del 即可。

需要注意的是，在运行你实现的路由器的时候，请不要在相关的网口上配置 IP 地址，因为 HAL 绕过了 Linux 网络栈，如果你配置了 IP 地址，在 Linux 和路由器的双重作用下可能有意外的效果。

## `ip l` 子命令

第二个重要的子命令是 `ip l`，是 `ip link` 的简写，一般直接使用 `ip link set $interface up` 和 `ip link set $interface down` 来让一个 `DOWN` 的网口变成 `UP`，也可以反过来让一个 `UP` 的网口变成 `DOWN`。注意，在一些情况下（例如网线没插等等），它可能会失败。

此外，还可以用 `ip l set $interface netns $netns_name` 来把一个网口挪到目的的 netns 中。通畅情况下，我们都是先创建好 interface，再用这种方法把它移动到特定的 netns 中。

另外，在创建 veth 的时候，使用的命令是 `ip link add $name1 type veth peer name $name2`，它会创建一对 interface，分别叫做 $name1 和 $name2，所有从 $name1 发出的流量都可以在 $name2 收到，反之亦然。可以理解成一根虚拟的网线，两端分别是 $name1 和 $name2。

## `ip r` 子命令

第三个重要的子命令是 `ip r`，是 `ip route` 的简写，它会显示 Linux 系统中的路由表：

```text
default via 1.2.3.1 dev enp14s0 proto static
1.2.3.0/26 dev enp14s0 proto kernel scope link src 1.2.3.4
```

我们也在上文中数次用了类似的语法表示一个路由表。每一项的格式如下：

```text
ip/prefix dev interface scope link 是一条直连路由，表示在这个子网中，所有的 IP 地址都通过 interface 直连可达
ip/prefix via another_ip dev interface 表示去往目标子网的 IP 分组，下一跳 IP 地址都是 another_ip ，通过 interface 出去
default via another_ip dev interface 这里 default 代表 0.0.0.0/0 ，其实是上一种格式
```

至于一些额外的类似 `proto static` `proto kernel` `src 1.2.3.4` 的内容可以直接忽略。

如果要修改的话，可以用 `ip route add` 接上你要添加的表项，相应地 `ip route del` 就是删除。例如，如果要删掉上面的默认路由，可以用 `ip route del default via 1.2.3.1 dev enp14s0` 实现。此外，值得注意的是，网络一般是双向的，在某台主机上添加去往另一个主机或子网的路由后，需要在目标主机或目标子网的路由器上添加回到这台主机的路由。此时，网络才能进行双向通信。

## `ip netns` 子命令

这个子命令用于进行 netns 相关的操作。首先是 `ip netns add $name`，就是创建 netns，删掉的话，只要 `ip netns delete $name` 即可。如果要列出所有的 netns，运行 `ip netns list`。如果要知道当前运行在哪个 netns 中，运行 `ip netns identify` 命令。

另外，很重要的一个功能是 `ip netns exec $name [command] ...`，它会在指定的 netns 中运行命令。如果你想在 netns 中打开一个 shell，可以执行 `ip netns exec $name bash`（或者把 bash 替换为你喜欢的 shell 程序，比如 fish）。进去以后，你再运行 `ip a` 等命令的时候，看到的就是 $name netns 里面的网络了。这对调试 netns 很有好处。
