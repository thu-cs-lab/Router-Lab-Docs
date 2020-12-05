# 课程要求

对于参与联合实验的同学，请参考联合实验的课程要求。

课程实验分为如下两个部分：编程作业和真机评测。

编程作业：校历第 5 周-第 9 周周日（11 月 15 日）22:00:00

真机评测（单人）：校历第 10 周-第 13 周周日（12 月 13 日）22:00:00

真机评测（组队）：校历第 13 周-第 15 周周日（12 月 27 日）22:00:00

以上截止时间都以东八区（UTC+8）为准。在截止时间之前，你需要提交代码、完成评测并且标记最终提交。如果不标记最终提交，则以截止时间前最后一次评测结果为准。补交的惩罚措施尚未确定。

## 编程作业

目前，一共包括四个编程实验如下：

- `checksum`：计算 IP Checksum
- `forwarding`：进行转发的 IP 头更新
- `lookup`：路由表的查询
- `protocol`：RIP 协议的处理

你需要在 [TanLabs](https://lab.cs.tsinghua.edu.cn/tan/) 上登录，并且在网站上创建属于你的作业 GitLab 仓库。你需要使用 Git 往你的作业仓库中提交的你的代码，然后在 TanLabs 查看评测结果。评测的流程和要求详见 TanLabs 网站上的说明。

编程作业占实验的 40% 分数。参加联合实验的同学也需要完成编程实验（得到这一部分满分）。每个实验占四分之一的编程作业分数，每个实验的所有数据点均分 10% 的分数。你需要标注一次提交作为最终提交来计算最终成绩，这一部分的分数可以在 TanLabs 上看到。

## 真机评测

第二部分，你需要基于编程作业的代码，修改 `Homework/router/main.cpp`，实现一个完整的路由器功能。和编程作业一样，你也需要把代码提交到 GitLab 上，然后在 TanLabs 上进行远程的树莓派的评测，分为个人和组队两种评测方法，详见 TanLabs 网站上的说明。

对于路由器功能和评测的要求，详见 “验收要求” 文档。

真机评测占实验的 60% 分数。个人评测和组队评测各占 *真机评测* 分数的一半。需要在 TanLabs 上标记你的最终评测，每次评测会显示各项评测的原始结果，不提供分数。

## 路由器功能实现的要求

必须实现的有：

1. 转发功能，支持直连路由和间接路由，包括查表，TTL 减一，Checksum 更新并转到正确的 interface 出去。
2. 周期性地向所有端口发送 RIP Response （**周期为 5s**，而不是 [RFC 2453 Section 3.8 Timers](https://tools.ietf.org/html/rfc2453#section-3.8) 要求的 30s），目标地址为 RIP 的组播地址。
3. 对收到的 RIP Request 生成 RIP Response 进行回复，目标地址为 RIP Request 的源地址。
4. 实现水平分割（split horizon）和毒性反转（reverse poisoning），处理 RIP 中 `metric=16` 的情况。
5. 收到 RIP Response 时，对路由表进行维护，注意 RIP 中 `nexthop=0` 的含义，见 [RFC 2453 Section 4.4 Next Hop](https://tools.ietf.org/html/rfc2453#section-4.4)。
6. 对 ICMP Echo Request 进行 ICMP Echo Reply 的回复，见 [RFC 792 Echo or Echo Reply Message](https://tools.ietf.org/html/rfc792)。
7. 在查不到路由表的时候，回复 ICMP Destination Unreachable (network unreachable)，见 [RFC792 Destination Unreachable Message](https://tools.ietf.org/html/rfc792)。
8. 在 TTL 减为 0 时，回复 ICMP Time Exceeded (time to live exceeded in transit)，见 [RFC792 Time Exceeded Message](https://tools.ietf.org/html/rfc792)。
9. 在发送的 RIP Response 出现不止 25 条 Entry 时拆分。

可选实现的有（不加分，但对调试有帮助）：

1. 定期或者在更新的时候向 stdout/stderr 打印最新的 RIP 路由表。
2. 在路由表出现更新的时候立即发送 RIP Response（完整或者增量），目标地址为 RIP 的组播地址，可以加快路由表的收敛速度。
3. 路由的失效（Invalid）和删除（Flush）计时器。
4. 程序启动时向所有 interface 发送 RIP Request，目标地址为 RIP 的组播地址。

不需要实现的有：

1. ARP 的处理。
2. IGMP 的处理。
3. interface 状态的跟踪（UP/DOWN 切换）。
