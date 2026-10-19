# Tofino 交换机使用：Simple Forward

在本节中，实验者将使用 `simple_forward` 程序熟悉 Tofino P4 程序的编译与加载过程，学习如何开启交换机端口，并通过 BF-RT 向数据平面下发表项。

`simple_forward` 根据报文的 ingress port 选择 egress port。数据平面中的转发表定义如下：

```p4
action ai_forward(portid_t egress_port) {
    ig_tm_md.ucast_egress_port = egress_port;
}

table ti_forward {
    key = {
        ig_intr_md.ingress_port: exact;
    }
    actions = {
        ai_forward;
        ai_drop;
    }
    size = 1024;
    default_action = ai_drop;
}
```

表项命中后执行 `ai_forward`，将 `ucast_egress_port` 设置为控制平面指定的端口；未命中时执行默认动作 `ai_drop`。

## 程序编译

登录 Tofino 交换机，在 `simple_forward` 目录中运行：

```bash
cd ~/simple_forward
make
```

Makefile 调用 SDE 中的 `p4_build.sh` 编译 P4 程序。编译结果位于：

```text
/root/bf-sde-9.13.0/build/p4-build/tofino/simple_forward/
```

## 程序运行

使用 `run_switchd.sh` 加载编译后的 pipeline：

```bash
/root/bf-sde-9.13.0/run_switchd.sh -p simple_forward
```

终端出现 `bfshell>` 提示符后，说明 `bf_switchd` 已完成初始化。

## 开启交换机端口

在 `bfshell` 中进入 UCLI 和 port manager：

```text
bfshell> ucli
bf-sde> xcvr_pres_ignore 9/- 1
bf-sde> xcvr_los_ignore 9/- 1
bf-sde> pm
bf-sde.pm> port-add 9/0 10G NONE
bf-sde.pm> port-add 9/1 10G NONE
bf-sde.pm> port-enb 9/0
bf-sde.pm> port-enb 9/1
bf-sde.pm> show
```

`show` 命令会显示 front-panel port 与 device port 的对应关系。本实验使用的端口如下：

| Front-panel port | Device port | 速率 |
|---|---:|---:|
| `9/0` | `132` | 10 Gbit/s |
| `9/1` | `133` | 10 Gbit/s |

开始收发报文前，应确认两个端口的 `RDY` 为 `YES`、`ADM` 为 `ENB`、`OPR` 为 `UP`。

## 查看 BF-RT 表

退出 port manager 和 UCLI，进入 `bfrt_python`：

```text
bf-sde.pm> exit
bf-sde> exit
bfshell> bfrt_python
```

使用 `bfrt.info()` 查看当前 P4 程序暴露的 BF-RT 对象：

```python
bfrt.info()
```

`simple_forward` 的转发表为：

```text
pipe.SwitchIngress.ti_forward
```

可以使用以下命令查看表结构和可调用的方法：

```python
tbl = bfrt.simple_forward.pipe.SwitchIngress.ti_forward
tbl.info()
tbl?
```

## 下发转发表项

向 `ti_forward` 添加两条表项，实现端口 `132` 和 `133` 之间的双向转发：

```python
tbl.add_with_ai_forward(ingress_port=132, egress_port=133)
tbl.add_with_ai_forward(ingress_port=133, egress_port=132)
```

使用 `dump()` 检查已写入的表项：

```python
tbl.dump()
```

下发完成后，从连接 `9/0` 的主机发送报文，报文应从 `9/1` 发出；反方向的报文应从 `9/0` 发出。可以在两端运行 `tcpdump`，并结合 port manager 中的 RX/TX 计数检查转发结果。

```bash
tcpdump -ni eth0 -e -vvv
```
