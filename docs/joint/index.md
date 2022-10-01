# 计网联合实验总述

## 实验目标

本实验为《计算机组成原理》与《计算机网络原理》联合硬件路由器实验，简称“计网联合实验”，或“联合实验”。实验目标为基于 ThinRouter 硬件平台设计并实现一台硬件路由器。

具体而言，实验者需要在 FPGA 上实现一个 CPU（《计算机组成原理》实验要求）及一个硬件转发引擎（《计算机网络原理》实验要求）：

* 绝大多数 IP 分组通过转发引擎高效转发（数据平面）
* 运行在 CPU 上的软件处理 RIP 路由协议（控制平面）
* 软件对转发引擎进行管理和配置（路由管理）

## 实验框架

ThinRouter 的样例工程在 [https://git.tsinghua.edu.cn/tanlabs-public/tanlabs](https://git.tsinghua.edu.cn/tanlabs-public/tanlabs) （[GitHub 镜像](https://github.com/thu-cs-lab/tanlabs)），克隆后就可以得到一个样例工程，这是实验者可以使用的实验框架，部分实验逻辑和引脚约束已经提供好。实验者可以阅读实验框架中的注释来获得更多信息。此外，实验者也可以不使用提供的实验框架，从零开始设计与实现。

如果实验框架原始代码有更新（届时助教会通过多种渠道通知），实验者可以按照如下命令合并这些更新：

```shell
> git remote add upstream git@git.tsinghua.edu.cn:tanlabs-public/tanlabs.git
> git fetch upstream
> git merge upstream/master
```

或者，更简单地，按照如下命令来合并：

```shell
> git pull git@git.tsinghua.edu.cn:tanlabs-public/tanlabs.git master
```

## 与软件实验的区别

* 硬件转发 IP 分组，性能更高
* 熟悉 FPGA 如何处理 IP 分组，解决实际问题
* 进一步锻炼系统能力
* 获得不一样的人生体验
* 可能获得更有竞争力的成绩

## 本文档用词

本文档后续将会频繁出现“实验者需要”及“实验者可以”等文字，其中的“需要”及“可以”含义如下：

* “需要”是指实验者为了完成实验必须要完成的任务，与 [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) 中 `MUST` 含义类似。
* “可以”是指本文档建议实验者在进行实验时完成的任务，其可能对实验会有帮助，但实验者可以完成也可以不完成，与 RFC 2119 中 `SHOULD` 含义类似。
