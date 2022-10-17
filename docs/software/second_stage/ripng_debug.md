## 本地测试

在编写 RIPng 协议的路由器的时候，可以在本机搭建一个虚拟的和评测一样的网络拓扑，这样就可以在虚拟网络中按照评测流程一步一步进行，同时观察程序的行为，可以大大地加快代码的调试。

本地测试主要分为两个部分：首先，搭建网络拓扑，将网络中各个设备连接好；其次，在各个设备上，运行相应的软件（比如 R2 运行自己编写的路由器，R1 和 R3 运行标准的路由器实现），并配置好网络（比如 IPv6 地址，路由等等）。

网络拓扑的具体过程见[附录中的拓扑搭建文档](../../appendix/topology.md)。

### 快捷脚本

实验仓库中，在 `Setup/ripng` 目录下提供了 netns 配置脚本，BIRD 配置以及评测脚本，你可以参考里面的内容进行配置。

### 软件配置

你实现的路由器实际上包括两部分功能：IPv6 分组转发和路由协议。在第二阶段中，自己写的路由器运行在 R2 上，而 R1 和 R3 都需要运行标准的路由器。那么，在 Linux 环境中，为了实现路由器的功能，需要下面两个部分：分组转发和路由协议。

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

为了实现路由协议，需要运行 BIRD。下面提供一个 BIRD（BIRD Internet Routing Daemon，安装方法 `apt install bird`）的参考配置，以 Debian 为例，如下修改文件 `/etc/bird.conf` 即可。

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
        update time 5; # 5 秒一次更新，方便调试
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
        update time 5; # 5 秒一次更新，方便调试
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
