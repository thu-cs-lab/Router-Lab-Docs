## OSPF 路由器

一个 OSPF 协议的路由器需要支持如下的功能：

1. 发现邻居 OSPF 路由器，保持 Link State Database 同步
2. 根据 Link State Database，通过 Dijkstra 最短路算法计算路由表
3. 按照动态计算得到的路由表，进行 IPv6 分组的转发

## 协议理解

TODO

关于 Hello Protocol 的更多说明请参见 [RFC 2328: OSPF Version 2](static/rfc2328.html)，实验者可以重点关注第 7、7.1、8、8.1、8.2、9（Hello Timer）、9.5 以及 10.5 小节。

关于 LSA 格式的更多说明请参见 [RFC 2328: OSPF Version 2](static/rfc2328.html)，实验者可以重点关注第 12、12.1、12.1.1、12.1.3、12.1.4、12.1.5、12.1.6 以及 12.1.7 小节。

关于路由表计算的更多说明请参见 [RFC 2328: OSPF Version 2](static/rfc2328.html)，实验者可以重点关注第 11、16、16.1、16.1.1 以及 16.8 小节。

## 工作流程

可以回答以上几个问题以后，结合仓库中 `Homework/ospf/main.cpp` 尝试理解下面的路由的工作流程：

1. 初始化路由表，加入直连路由；
2. 进入路由器主循环；
3. 如果距离上一次发送已经超过了 5 秒，就发送 OSPF Hello 到所有的接口；
4. 接收 IPv6 分组，如果没有收到就跳到第 2 步；
5. 检查 IPv6 分组的完整性和正确性；
6. 判断 IPv6 分组目标是否是路由器：如果是，则进入 OSPF 协议处理；如果否，则要转发；
7. 如果是 OSPF 报文，根据 OSPF 报文类型进行处理：
    1. 如果是 OSPF Hello，判断是否是不认识的 OSPF 路由器，如果是，加入到邻居状态表中
    2. 如果是 OSPF Database Description，和邻居进行 Link State Database 的状态同步，把自己的 LSA Header 发送给对方，同时记录对方发送的 LSA Header；同步完成后，发送 OSPF LS Request 获取对方的完整 LSA
    3. 如果是 OSPF LS Update，更新自己的 Link State Database，更新状态，不再重传对应的 OSPF LS Request 报文（若有），并根据需要回复 OSPF LS Acknowledgement
    4. 如果是 OSPF LS Request，用 OSPF LS Update 回复自己 Link State Database 中对应的 LSA
    5. 如果是 OSPF LS Acknowledgement，更新状态，不再重传对应的 OSPF LS Update 报文
8. 如果这个 IPv6 分组要转发，判断 Hop Limit，如果小于或等于 1，就丢弃；
9. 如果 Hop Limit 正常，查询路由表，如果找到了，就转发给下一跳，转发时从 ND 表中获取下一跳 MAC 地址；如果找不到匹配的路由表表项，则丢弃；
10. 跳到第 2 步，进入下一次循环处理。

TODO: 流程图

## 功能要求

由于 OSPF 协议完整实现比较复杂，你只需要实现其中的一部分。必须实现的有：

1. 更新 checksum 小作业的实现，加入对 OSPF 报文校验和计算的支持
2. 构造 OSPF Hello 报文并发送；接收来自邻居的 OSPF Hello 报文，并更新状态
3. 根据 Link State Database，执行 Dijkstra 算法，计算路由表

其余功能已经由代码框架提供。

!!! attention "HONOR CODE"

    在 `ospf` 目录中，有一个 `HONOR-CODE.md` 文件，你需要在这个文件中以 Markdown 格式记录你完成这个作业时参考网上的文章或者代码、与同学的交流情况。