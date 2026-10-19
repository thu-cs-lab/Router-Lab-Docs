# Lab 2：IPv4 单跳处理

在本节实验中，实验者需要补全 Tofino P4 程序，实现 IPv4 最长前缀匹配、Ethernet header 改写、TTL 递减、TTL 过期丢弃以及 IPv4 header checksum 更新。

## 实验目标

* 使用 LPM 表根据 IPv4 destination address 选择出口端口；
* 在转发时修改 Ethernet source/destination MAC；
* 将 IPv4 TTL 减 1，并丢弃 TTL 小于等于 1 的报文；
* 使用 TNA `Checksum` extern 重新计算 IPv4 header checksum。

## 实验环境

![Lab 2 实验拓扑](img/tofino_dual_host_topology.svg)

| 主机 | IPv4 地址 | MAC 地址 | Device port |
|---|---|---|---:|
| Host A | `192.168.1.2/24` | `02:00:00:00:00:01` | `132` |
| Host B | `192.168.2.2/24` | `02:00:00:00:00:02` | `133` |

控制面向 IPv4 LPM 表写入以下规则：

| Prefix | 处理动作 |
|---|---|
| `10.0.0.0/8` | 转发至 device port `133` |
| `10.1.0.0/16` | 丢弃 |
| Default | 丢弃 |

目的地址 `10.1.2.3` 同时匹配 `/8` 和 `/16`。LPM 表应选择长度更大的 `/16` 表项，因此该报文最终被丢弃。

## 数据平面处理流程

IPv4 报文进入 ingress pipeline 后，按照以下顺序处理：

1. 检查 IPv4 header 是否有效；
2. 检查 TTL 是否允许继续转发；
3. 使用 destination address 查询 LPM 表；
4. 设置 egress port，并改写 Ethernet header；
5. 将 TTL 减 1；
6. 在 ingress deparser 中重新计算 IPv4 header checksum。

TTL 小于等于 1 的报文直接丢弃。本实验不生成 ICMP Time Exceeded。

## 实验步骤

### 1. 实现 LPM 转发

在 `switch/ipv4_action.p4` 中补全 IPv4 LPM 表和转发动作。命中转发表项时，数据平面需要设置 egress port，并将 Ethernet source/destination MAC 改写为控制面指定的值。

可以先只下发 `10.0.0.0/8` 表项，观察发往 `10.1.2.3` 的报文被转发；再加入 `10.1.0.0/16` drop 表项，确认相同目的地址改为命中 `/16` 并被丢弃。

### 2. 实现 TTL 处理

转发动作中使用以下语句递减 TTL：

```p4
hdr.ipv4.ttl = hdr.ipv4.ttl - 8w1;
```

执行 LPM 查询前，应先判断 TTL。TTL 大于 1 时继续处理，TTL 小于等于 1 时设置 drop 标志。

### 3. 更新 IPv4 Checksum

TTL 位于 IPv4 header 中，修改 TTL 后原有 header checksum 不再有效。数据平面需要设置 checksum 更新标志，并在 ingress deparser 中调用 TNA `Checksum` extern，按照 IPv4 header 的字段顺序计算新的 checksum。

为了观察错误现象，可以暂时关闭 checksum 更新：

```p4
ig_md.update_ipv4_checksum = 1w0;
```

此时报文的 TTL 仍会变为 63，但 Host B 的验证脚本或 `tcpdump` 会将 IPv4 checksum 标记为错误。恢复 checksum 更新后，应得到正确的校验结果。

### 4. 编译与运行

完成前面的 P4 修改后，在 Tofino 交换机上进入 `p4-ipv4-action` 目录：

```bash
make
./contrl
```

控制面完成端口开启和 LPM 表项下发后，应输出：

```text
[LPM] prefix=10.0.0.0/8 action=FORWARD egress=133
[LPM] prefix=10.1.0.0/16 action=DROP
[CONTROL] status=READY
```

修改 P4 程序后，先按 `Ctrl-C` 停止当前控制面，再重新运行 `make` 和 `./contrl`。

### 5. 配置实验主机

在 Host A 上运行：

```bash
ip link set eth0 down
ip link set eth0 address 02:00:00:00:00:01
ip link set eth0 up
ip addr replace 192.168.1.2/24 dev eth0
ip route replace default via 192.168.1.1 dev eth0
ip -br link show dev eth0
```

在 Host B 上运行：

```bash
ip link set eth0 down
ip link set eth0 address 02:00:00:00:00:02
ip link set eth0 up
ip addr replace 192.168.2.2/24 dev eth0
ip route replace default via 192.168.2.1 dev eth0
ip -br link show dev eth0
```

两个接口都应显示 `UP` 和 `LOWER_UP`。MAC 地址需要与控制面表项和测试脚本中的配置保持一致。

## 实验验证

先在 Host B 运行接收脚本：

```bash
python3 scripts/verify_packets.py
```

再在 Host A 发送四个测试报文：

```bash
python3 scripts/send_tests.py
```

测试脚本使用以下测试用例：

| Case | Destination | TTL | 预期结果 |
|---|---|---:|---|
| `route-8` | `10.2.3.4` | 64 | Host B 收到，TTL 为 63，checksum 正确 |
| `drop-16` | `10.1.2.3` | 64 | 命中 `/16`，丢弃 |
| `drop-miss` | `172.16.0.1` | 64 | LPM miss，丢弃 |
| `drop-ttl` | `10.2.3.4` | 1 | TTL 过期，丢弃 |

正确实现后，Host B 输出如下：

```text
received case=route-8 dst=10.2.3.4 ttl=63 checksum=correct ...
PASS: LPM, TTL, checksum, and drop behavior are correct
```

也可以在 Host B 使用 `tcpdump` 检查收到的 Ethernet 和 IPv4 header：

```bash
tcpdump -ni eth0 -e -vvv -XX 'ip and udp dst port 9000'
```
