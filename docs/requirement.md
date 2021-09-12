# 课程要求

对于秋季学期参与联合实验的同学，请参考联合实验的课程要求。

课程实验分为如下两个部分：编程作业和真机评测。

编程作业：校历第 1 周-第 9 周周日（2021 年 11 月 14 日）22:00:00

真机评测（单人）：校历第 10 周-第 12 周周日（2021 年 12 月 5 日）22:00:00

真机评测（组队）：校历第 13 周-第 14 周周日（2021 年 12 月 19 日）22:00:00

以上截止时间都以东八区（UTC+8）为准。在截止时间之前，你需要提交代码、完成评测并且标记最终提交。如果不标记最终提交，则以截止时间前最后一次评测结果为准。补交的惩罚措施尚未确定。

## 编程作业

目前，一共包括四个编程实验如下：

- `eui64`：基于 EUI64 构造 IPv6 Link Local 地址
- `internet-checksum`：进行 UDP 和 ICMPv6 的校验和检验和计算
- `lookup`：路由表的查询
- `protocol`：RIPng 协议的处理

你需要在 [TanLabs](https://lab.cs.tsinghua.edu.cn/tan/) 上登录，并且在网站上创建属于你的作业 GitLab 仓库。你需要使用 Git 往你的作业仓库中提交的你的代码，然后在 TanLabs 查看评测结果。评测的流程和要求详见 TanLabs 网站上的说明。

编程作业占实验的 20% 分数。参加联合实验的同学也需要完成编程实验（得到这一部分满分）。每个实验占四分之一的编程作业分数，每个实验的所有数据点均分分数。你需要标注一次提交作为最终提交来计算最终成绩，这一部分的分数可以在 TanLabs 上看到。

## 真机评测

第二部分，你需要基于编程作业的代码，修改 `Homework/router/main.cpp`，实现一个完整的路由器功能。和编程作业一样，你也需要把代码提交到 GitLab 上，然后在 TanLabs 上进行远程的树莓派的评测，分为个人和组队两种评测方法，详见 TanLabs 网站上的说明。

对于路由器功能和评测的要求，详见 “验收要求” 文档。

真机评测占实验的 80% 分数。个人评测和组队评测各占 *真机评测* 分数的一半（即各占 40%）。你需要在 TanLabs 上标记你的最终评测，每次评测会显示各项评测的原始结果，但不提供分数。

## 路由器功能实现的要求

必须实现的有：

1. 转发功能，支持直连路由和间接路由，包括 Hop Limit 减一，查表并向正确的 interface 发送出去。
2. 周期性地向所有端口发送 RIPng Response（**周期为 5s**，而不是 [RFC 2080 Section 2.3 Timers](https://www.rfc-editor.org/rfc/rfc2080.html#section-2.3) 要求的 30s），目标地址为 RIPng 的组播地址。
3. 对收到的 RIPng Request 生成 RIPng Response 进行回复，目标地址为 RIPng Request 的源地址。
4. 实现水平分割（split horizon）和毒性反转（reverse poisoning）。
5. 收到 RIPng Response 时，对路由表进行维护，处理 RIPng 中 `metric=16` 的情况。
6. 对 ICMPv6 Echo Request 进行 ICMPv6 Echo Reply 的回复，见 [RFC 4443 Echo Reply Message](https://datatracker.ietf.org/doc/html/rfc4443#section-4.2)。
7. 在接受到 IPv6 packet，按照目的地址在路由表中查找不到路由的时候，回复 ICMPv6 Destination Unreachable (No route to destination)，见 [RFC 4443 Section 3.1 Destination Unreachable Message](https://datatracker.ietf.org/doc/html/rfc4443#section-3.1)。
8. 在 Hop Limit 减为 0 时，回复 ICMPv6 Time Exceeded (Hop limit exceeded in transit)，见 [RFC 4443 Section 3.3 Time Exceeded Message](https://datatracker.ietf.org/doc/html/rfc4443#section-3.3)。
9. 在发送的 RIPng Response 大小超过 MTU 时进行拆分。

可选实现的有（不加分，但对调试有帮助）：

1. 定期或者在更新的时候向 stdout/stderr 打印最新的 RIP 路由表。
2. 在路由表出现更新的时候立即发送 RIPng Response（完整或者增量），可以加快路由表的收敛速度。
3. 路由的超时（Timeout）和垃圾回收（Garbage Collection）定时器。
4. 程序启动时向所有 interface 发送 RIPng Request。

不需要实现的有：

1. NDP 的处理，已经在 HAL 中实现。
2. interface 状态的跟踪（UP/DOWN 切换）。
