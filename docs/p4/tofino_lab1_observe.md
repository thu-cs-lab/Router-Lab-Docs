# Lab 1：黑盒观察与调试

在本节实验中，实验者将运行一个已经编译好的 Tofino 程序，通过主机抓包、CPU 接口抓包、交换机端口计数器和控制面日志观察数据包的处理结果。

本实验不需要修改 P4 程序。实验者需要分别构造 ARP 和 UDP 报文，并根据观测结果判断报文被交换机回复或上传至控制面的条件。

## 实验目标

* 运行已经编译好的 Tofino 程序并检查端口状态；
* 使用 `tcpdump` 对比 ARP Request 与交换机生成的 ARP Reply；
* 构造 UDP 探测报文，并结合 CPU 接口抓包和控制面日志定位触发 CPU upload 的端口。

## 实验环境

本实验只使用 Host A。Tofino 的 `9/0` 端口配置为网关 `192.168.1.1`。

![Lab 1 实验拓扑](img/tofino_lab1_topology.svg)

| 组件 | 配置 |
|---|---|
| Host A | `192.168.1.2/24` |
| 网关 | `192.168.1.1` |
| Front-panel port | `9/0` |
| Device port | `132` |
| CPU port | `64` |

## 实验步骤

### 1. 运行交换机程序

登录 Tofino 交换机，进入课程提供的 `p4-blackbox-observe` 目录，运行控制面程序：

```bash
./contrl
```

控制面程序加载名为 `observe` 的 P4 pipeline、开启 `9/0`、下发表项，并将 CPU upload 事件写入 `observe.log`。终端出现以下输出后开始测试：

```text
[CONTROL] status=READY
```

### 2. 配置实验主机

在 Host A 上配置接口地址和默认路由：

```bash
ip link set eth0 up
ip addr replace 192.168.1.2/24 dev eth0
ip route replace default via 192.168.1.1 dev eth0
ip -br addr show dev eth0
ip route
```

接口应显示 `UP` 和 `LOWER_UP`。如果显示 `LOWERLAYERDOWN`，应先检查端口容器是否正确连接到 Tofino `9/0`，此时继续发送报文不会得到有效的实验结果。

### 3. 观察 ARP 报文

在 Host A 启动抓包：

```bash
tcpdump -ni eth0 -Q inout -e -vvv -XX arp
```

打开另一个终端，清空邻居缓存并查询网关地址：

```bash
ip neigh flush all
arping -c 3 -I eth0 192.168.1.1
```

抓包中应同时出现 ARP Request 和 ARP Reply。比较两个报文的以下字段：

| 字段 | ARP Request | ARP Reply |
|---|---|---|
| Ethernet source/destination MAC | Host A / broadcast | 网关 / Host A |
| ARP opcode | request | reply |
| ARP sender IP | `192.168.1.2` | `192.168.1.1` |
| ARP target IP | `192.168.1.1` | `192.168.1.2` |

随后查询另一个地址：

```bash
ip neigh flush all
arping -c 3 -I eth0 192.168.1.254
```

对比两次 `arping` 和抓包结果，确认交换机只对配置在端口上的网关地址生成 ARP Reply。

### 4. 观察 CPU Upload

在 Tofino 交换机上分别观察 CPU 接口和控制面日志，其中 `<cpu-interface>` 替换为实验环境中的 CPU Linux 接口名：

```bash
tcpdump -ni <cpu-interface> -e -vvv -XX 'ether proto 0x0866'
tail -f observe.log
```

在 Host A 上自行编写 Python 程序，向 `192.168.1.1` 的 UDP destination port `10000` 至 `10031` 依次发送探测报文。程序应绑定 `eth0` 和源地址 `192.168.1.2`，并在 payload 中记录当前探测的端口号，便于对照抓包与控制面日志。

运行程序时观察 `observe.log` 和 CPU 接口抓包，找出触发 CPU upload 的 destination port。命中后，控制面会输出类似以下内容：

```text
[UPLOAD] ingress=132 proto=UDP ...
```

CPU 接口收到的 upload 报文使用 EtherType `0x0866`。将日志中的 source port、destination port 和 UDP length 与 Host A 发送的报文进行比较。

## 实验验证

完成实验后，应能够观察到以下两种报文路径：

| 输入报文 | 处理结果 |
|---|---|
| 查询 `192.168.1.1` 的 ARP Request | 交换机生成 ARP Reply 并返回 Host A |
| 命中特定 destination port 的 UDP | 转换为 EtherType `0x0866` 的报文并上传 CPU |

停止实验时，在运行 `contrl` 的终端按 `Ctrl-C`，并删除旧日志后再开始下一轮测试：

```bash
rm -f observe.log
```
