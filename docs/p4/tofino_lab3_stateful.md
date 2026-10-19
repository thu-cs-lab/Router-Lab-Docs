# Lab 3：有状态流量监测

在本节实验中，实验者需要使用 Tofino Register 保存跨报文状态，根据一个流已经到达的报文数量执行正常转发、DSCP 标记或丢弃，并通过 Counter 和 Digest 观察数据平面的处理结果。

## 实验目标

* 根据 IPv4 五元组计算 Hash，将不同流映射到 Register entry；
* 使用 `RegisterAction` 原子更新报文计数；
* 根据计数结果选择不同的数据平面动作；
* 使用 Counter 统计各类处理结果；
* 使用 Digest 将阈值事件上报控制面。

## 实验环境

![Lab 3 实验拓扑](img/tofino_dual_host_topology.svg)

## 实验原理

### 无状态处理与有状态处理

在无状态处理中，交换机只根据当前报文的 header、metadata 和控制面下发的表项决定动作。相同报文在相同表项配置下会得到相同结果，先前经过的报文不会影响本次处理。

在有状态处理中，数据面还会读取并修改保存在交换机中的状态。本实验为每个 flow bucket 保存一个计数，因此同一条流的第 1 个、第 6 个和第 9 个报文可以得到不同处理结果。这个计数由报文在数据面中直接更新，不需要控制面逐包参与。

P4 通过 `extern` 使用目标架构提供的专用能力。`Hash`、`Register`、`RegisterAction`、`Counter`、`Digest` 和 `Checksum` 都是 TNA 提供的 extern；P4 程序负责指定输入字段和处理逻辑，编译器负责将它们映射到 Tofino 的硬件资源。

### IPv4 五元组

网络中的“流”通常指具有相同通信特征的一组报文。对于 IPv4 上的 TCP 或 UDP 流，通常使用以下五个字段共同标识一条流，这组字段称为 IPv4 五元组：

| 字段 | 含义 |
|---|---|
| IPv4 source address | 发送方 IP 地址 |
| IPv4 destination address | 接收方 IP 地址 |
| IP protocol | 传输层协议，如 TCP（6）或 UDP（17） |
| Transport source port | 发送方的 TCP/UDP 端口 |
| Transport destination port | 接收方的 TCP/UDP 端口 |

本实验只处理 UDP 报文，因此后两个字段分别取自 UDP source port 和 destination port。五个字段全部相同的报文属于同一条流；任意一个字段不同，就被视为另一条流。实验中的 Flow A 和 Flow B 只有 UDP source port 不同，因此是两条不同的 IPv4/UDP 流。

### 使用 Hash 选择 Register entry

P4 Register 可以看作数据平面中的数组，访问时需要提供一个整数 index。本实验声明了 1024 个 Register entry，用于保存不同流的报文计数，因此 index 的范围是 `0..1023`。

为了给每条流选择一个 entry，数据平面对 IPv4 五元组计算 32-bit CRC32 Hash，再取 Hash 结果的低 10 bit 作为 `flow_index`。10 bit 可以表示 1024 个不同的 index，因此 `flow_index` 可以直接访问 `flow_packet_count[0..1023]`。相同的 IPv4 五元组会得到相同的 Hash，从而在后续报文到达时继续访问同一个 entry。

Host A 向 `10.2.3.4:9000` 发送 IPv4/UDP 报文时，数据平面按以下过程选择 Register entry：

```text
IPv4 五元组
    -> CRC32 Hash（32 bit）
    -> 取低 10 bit 得到 flow_index
    -> 访问 flow_packet_count[flow_index]
```

CRC32 Hash 的作用只是快速选择 Register entry，不是加密或报文差错校验。由于最终只有 1024 个可选 entry，不同的 IPv4 五元组仍可能得到相同的 `flow_index`，这种情况称为 Hash collision。发生碰撞时，两条流会共享同一个 Register entry 和报文计数。因此，Register entry 只能近似对应一条流，不能替代完整的 IPv4 五元组作为流的唯一标识。

### Metadata、Register、Counter 与 Digest

这四类对象承担不同的职责：

| 对象 | 生命周期 | 本实验中的用途 |
|---|---|---|
| Metadata | 仅随当前报文经过 pipeline，处理结束后消失 | 在各处理阶段之间传递 Register index、当前计数和处理结果 |
| Register | 保存在数据平面中，后续报文可以继续读取和修改 | 保存每个 flow bucket 已到达的报文数量 |
| Counter | 保存在数据平面中，按指定 index 累加报文数和字节数 | 汇总 normal、marked 和 dropped 三类处理结果 |
| Digest | 数据面发给控制面的异步事件 | 在某条流首次达到阈值时，上报 IPv4 五元组、bucket 和计数 |

Register 与 Counter 都能跨报文保存数值，但用法不同。Register 的值会被数据面读出并参与后续决策；Counter 主要用于统计和观测。本实验使用 indirect Counter，由 P4 程序显式提供 index，而不是将 Counter 固定绑定到某一条 match-action 表项。

Digest 不会把原报文复制到 CPU，也不会等待控制面返回结果后再继续转发。它只将 `Digest.pack()` 中指定的少量字段异步上报，适合报告“计数刚刚达到 5”一类事件。控制面处理完成后需要回复 ACK，使硬件能够释放该批 Digest 使用的资源。

### 为什么使用 `RegisterAction`

Tofino pipeline 中可能同时存在多个属于同一条流的报文。一次计数更新包含“读取旧值、加一、写回新值”三个逻辑步骤。如果把读取和写入拆成彼此独立的操作，两个报文可能读到相同旧值并写回相同新值，导致少计一个报文。

`RegisterAction` 将对同一个 Register entry 的读取、计算和写回作为一次原子操作执行。这里的“原子”表示其他报文不会在本次更新中间修改该 entry，从而保证每个到达的报文只增加一次计数。

### 报文处理流程

每个符合实验条件的报文依次完成以下操作：

1. 从 IPv4 和 UDP header 中取出 IPv4 五元组并计算 Hash；
2. 使用 Hash 的低 10 bit 选择一个 Register entry；
3. 使用 `RegisterAction` 将该 entry 的计数原子加一，并把新计数写入当前报文的 metadata；
4. 根据新计数选择正常转发、DSCP 标记后转发或丢弃；
5. 根据处理结果更新对应的 Counter；
6. 如果新计数恰好为 5，额外向控制面发送一条 Digest。

### 状态处理规则

Register 完成递增后，当前报文根据新计数执行以下动作：

| 新计数 | 数据平面动作 |
|---:|---|
| `1..4` | 正常转发 |
| `5` | 正常转发，并发送一次 Digest |
| `6..8` | 将 DSCP 修改为 46，更新 IPv4 checksum 后转发 |
| `>=9` | 丢弃 |

非 UDP 报文以及 destination address 或 destination port 不符合测试条件的报文直接丢弃，不更新实验使用的 Register 和 outcome Counter。

## 实验步骤

### 1. 基于 IPv4 五元组计算 Hash

在 P4 程序中使用 TNA `Hash` extern，对 IPv4 五元组中的以下字段计算 32-bit CRC32：

```text
IPv4 source address
IPv4 destination address
IP protocol
UDP source port
UDP destination port
```

取 Hash 结果的低 10 bit 作为 Register index。Hash 计算与后续 `RegisterAction` 应在同一个 table action 中完成。计算得到的 index 写入 `ig_md.flow_index`；这是当前报文的临时 metadata，而真正跨报文保存的计数位于 `flow_packet_count[index]`。

### 2. 实现 Register 原子更新

使用 `RegisterAction` 在一次操作中读取旧值、计算新值并写回：

```text
new_count = flow_packet_count[index] + 1
flow_packet_count[index] = new_count
```

本实验使用 8-bit Register。计数达到 255 后保持饱和，避免数值回绕为 0。控制面执行 `show registers` 时会先同步硬件 Register，再显示非零 entry。

8-bit 无符号整数的最大值是 255。如果直接对 255 加一，结果会回绕为 0，使已经进入丢弃区间的流重新被当作新流处理。饱和计数会在到达最大值后保持 255，可避免这一问题。

### 3. 实现 Counter 与 Digest

使用一个 indirect Counter 的三个 index 分别记录：

| Counter index | 统计内容 |
|---:|---|
| `0` | 正常转发的报文 |
| `1` | DSCP 标记后转发的报文 |
| `2` | 因达到阈值而丢弃的报文 |

当一个流的计数第一次达到 5 时，使用 `Digest.pack()` 将 IPv4 五元组、Register index 和新计数上传控制面。条件使用 `== 5` 而不是 `>= 5`，因此每个未发生碰撞的 flow bucket 只会在越过阈值时上报一次。控制面 callback 读取 Digest 后发送 ACK。

### 4. 更新 DSCP 与 Checksum

DSCP 是 IPv4 `Differentiated Services` 字段的高 6 bit，可用于给报文标记不同的服务类别。本实验使用十进制值 46，使进入 `6..8` 计数区间的报文能够在 Host B 抓包中被清楚地区分；这个标记本身并不会自动产生队列调度或带宽保证。

DSCP 属于 IPv4 header，因此修改后需要重新计算 IPv4 header checksum。Host B 的验证脚本会同时检查 DSCP 和 checksum。

### 5. 编译与运行

完成前面的 P4 修改后，在 Tofino 交换机上进入 `p4-stateful-monitor` 目录：

```bash
make
./contrl
```

控制面程序开启 `9/0` 和 `9/1`、配置转发规则、初始化 Counter，并注册 Digest callback。出现以下提示符后即可开始测试：

```text
[CONTROL] status=READY
lab3>
```

控制器支持以下命令：

```text
show counters
show registers
clear counters
clear registers
clear all
help
quit
```

Register 会在多轮测试之间保留状态。每次重新发送测试流量前，应执行：

```text
lab3> clear all
```

### 6. 配置实验主机

在 Host A 上运行：

```bash
ip link set eth0 down
ip link set eth0 address 02:00:00:00:00:01
ip link set eth0 up
ip addr replace 192.168.1.2/24 dev eth0
```

在 Host B 上运行：

```bash
ip link set eth0 down
ip link set eth0 address 02:00:00:00:00:02
ip link set eth0 up
ip addr replace 192.168.2.2/24 dev eth0
```

使用 `ip -br link show dev eth0` 确认两端接口均为 `UP` 和 `LOWER_UP`。

## 实验验证

测试脚本发送两个 UDP source port 不同的流：

| Flow | UDP source port | 发送数量 |
|---|---:|---:|
| A | `40001` | 10 |
| B | `40002` | 3 |

先在控制器中清空状态：

```text
lab3> clear all
```

在 Host B 启动接收脚本：

```bash
python3 scripts/verify_packets.py
```

随后在 Host A 发送测试报文：

```bash
python3 scripts/send_tests.py
```

两个流未发生 Hash collision 时，Host B 应观察到：

| Flow | 正常转发 | DSCP=46 | 丢弃 | 接收总数 |
|---|---:|---:|---:|---:|
| A | 5 | 3 | 2 | 8 |
| B | 3 | 0 | 0 | 3 |

Flow A 的第 5 个报文到达时，控制面应输出一条 Digest：

```text
[DIGEST] src=192.168.1.2:40001 dst=10.2.3.4:9000 bucket=... count=5
```

测试结束后查询 Register 和 Counter：

```text
lab3> show registers
lab3> show counters
```

预期 packet counter 为：

```text
[COUNTER] normal  packets=8 bytes=...
[COUNTER] marked  packets=3 bytes=...
[COUNTER] dropped packets=2 bytes=...
```

硬件 byte counter 可能包含 Ethernet FCS，因此测试时以 packet counter 和 Host B 的接收数量为主要检查依据。
