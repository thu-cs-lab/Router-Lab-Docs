# 第二阶段：邻居发现协议与邻居缓存

## IPv6 地址分类

为了方便实验者阅读理解邻居发现协议（ND），本节首先对 IPv6 的地址分类进行一些介绍。

IPv6 地址有三种类型，分别为单播地址、任播地址以及组播地址：

* 单播（unicast）地址标记了一个单独的接口。发送给单播地址的 IP 分组将被发送到该地址标记的接口。
* 任播（anycast）地址标记了一组接口。发送给任播地址的 IP 分组将被发送到该地址标记的接口中的 **任意一个** （路由算法通常会选择最近的那个）。
* 组播（multicast）地址标记了一组接口。发送给组播地址的 IP 分组将被发送到该地址标记的 **所有** 接口。

值得注意的是，IPv6 中没有广播地址，组播覆盖了广播的功能。

进一步，根据地址作用的范围，又可以作更细致的划分：

* 未指定地址（Unspecified Address）
    * `::`
* 回环地址（Loopback Address）
    * `::1`
    * 配置在用于向主机自身发送 IP 分组的虚拟接口上
* 全球单播地址（Global Unicast Addresses，GUA）
    * 地址范围较广（目前集中在 `2000::/3`，但 RFC 并没有规定一个范围），全球唯一，全网可达
    * 例：`2a0e:aa06:497::1`
* 链路本地地址（Link-Local IPv6 Unicast Addresses）
    * `fe80::/64`，同链路唯一，同链路可达
    * 可由 MAC 地址生成（可以参见编程作业 `eui64`）
    * 例：`fe80::5657:44ff:fe32:5f30`（由 `54:57:44:32:5f:30` 生成）
* 子网路由器任播地址（Subnet-Router Anycast Address）
    * 接口号为全零的地址，在本实验中不要使用
* Unique Local Addresses，ULA
    * `fc00::/7`，“内网地址”，本实验不涉及
    * 可参考 [RFC 4193: Unique Local IPv6 Unicast Addresses](https://datatracker.ietf.org/doc/html/rfc4193)
* 组播地址（Multicast Addresses）
    * `ff00::/8`，有多种作用范围，作用范围可小至单个接口（Interface-Local），也可大至全球范围（Global）
    * 分为永久分配和非永久分配两类
    * Solicited-Node Multicast Address 是一类重要的组播地址
        * 用于在发送组播 Neighbor Solicitation 时作为目的地址（Destination Address）
        * 根据 ND 报文的目标 IP 地址（Target Address）生成
        * 例：`ff02::1:ff32:5f30`（由 `fe80::5657:44ff:fe32:5f30` 生成）

关于 IPv6 地址架构的更多说明请参见 [RFC 4291: IP Version 6 Addressing Architecture](https://datatracker.ietf.org/doc/html/rfc4291)，实验者可以重点关注第 2.5.4、2.5.6、2.7.1（Solicited-Node Address）以及 2.8 小节。

## 路由器地址配置

路由器需要配置合适的地址才能正常工作。每个接口的地址都需要单独进行配置，为了能够动态修改，配置信息应保存在寄存器中，而不是硬编码在逻辑中。通常情况下，路由器会通过软件配置地址（参见“软硬件接口”一节）。在本实验中，在 CPU 实现完成之前，可以考虑实现为通过拨码开关和按钮进行配置。

一般而言，数据链路层（MAC 层）和网络层（IP 层）都需要配置相应的地址。

在数据链路层，每个接口需要配置一个全班 **唯一** 的 **单播** MAC 地址。请实验者注意不要将 MAC 地址错误地配置为组播地址（一个 MAC 地址为组播地址当且仅当其首个字节最低有效位为 1）。

在网络层，每个接口需要至少配置一个同链路唯一的链路本地地址，一种直接的方法是由 MAC 地址生成。此外，每个接口还可以配置若干全球单播地址，方便管理员远程访问该路由器。但需要注意的是，若某个链路或接口损坏，则相应接口上的全球单播地址就不能使用了。因此，如果实验者实现了 Loopback 接口，也可以在 Loopback 接口上配置全球单播地址，通过合适的路由，只要有任一链路有效，该地址总能访问到该路由器。如果配置了全球单播地址，请实验者注意不同接口上的 IP 地址应当在不同的子网。

在实践中，在网络层配置好 IP 地址后，网络节点还需要进行重复地址检测并加入相应组播组。在本实验中，这一过程可以省略。

## 邻居发现协议处理

路由器工作在网络层（三层，采用 IP 协议），之下的数据链路层（二层，本实验基于以太网）为网络层提供 **服务**。网络层使用 IP 地址标识不同的网络节点，而数据链路层则使用 MAC 地址（链路层地址）进行以太网帧的转发。因此，网络节点在发送和转发 IP 分组时，仅根据目的 IP 地址确定下一跳 IP 地址是不够的。为了能够将 IP 分组通过以太网发送至下一跳节点，网络节点还需要知道下一跳的 MAC 地址。邻居发现协议能够实现 IP 地址到 MAC 地址的转换这一地址解析（Address Resolution）过程。

事实上，本实验中，实验者可以把 ND 协议处理实现在硬件中，也可以实现在软件中。本实验建议 ND 协议采用硬件实现，其优点为方便调试，不需要等到 CPU 及软件实现完毕后再进行调试；但是，如果软件需要访问邻居缓存（事实上，在本实验中一般不需要），则需要额外的工作。

总体而言，实验者至少需要实现 ND 报文的以下处理，以便与其他网络节点互联互通：

* 组播 Neighbor Solicitation 发送：已知下一跳的 IP 地址，但需要查询其 MAC 地址。
* 组播 Neighbor Solicitation 接收与处理：其他节点需要查询当前节点的 MAC 地址；或者其他节点正在针对该 IP 地址进行重复地址检测（Duplicate Address Detection，DAD），此时 ND 报文的源地址为未指定地址。其中，实验者可以不实现对于后一种情况的处理，但是需要正确地丢弃这样的报文。
* 单播 Neighbor Solicitation 接收与处理：其他节点正在针对该 IP 地址进行邻居不可达检测（Neighbor Unreachability Detection，NUD）。顺便指出，本实验中，实验者可以不实现单播 Neighbor Solicitation 的发送，即可以不主动进行 NUD，但是需要响应 NUD。
* 单播 Neighbor Advertisement 发送：上述源地址不为未指定地址的 Neighbor Solicitation 触发的 Neighbor Advertisement。
* 单播 Neighbor Advertisement 接收与处理：当前节点发出的组播 Neighbor Solicitation 得到了响应。
* 组播 Neighbor Advertisement 发送：上述源地址为未指定地址的 Neighbor Solicitation 触发的 Neighbor Advertisement，实验者可以不实现对于这种情况的处理。
* 组播 Neighbor Advertisement 接收与处理：其他节点为了响应源地址为未指定地址的 Neighbor Solicitation 而发出的 Neighbor Advertisement，由于其为组播，被当前节点接收。实验者需要正确地丢弃这样的报文。

特别地，实验者可以不实现邻居缓存表项的状态维护（Neighbor Cache Entry States）。此外，实验者可以不实现对于任播地址，包括子网路由器任播地址的 Neighbor Solicitation 的接收与处理。

邻居发现协议的更多细节请参见 [RFC 4861: Neighbor Discovery for IP version 6 (IPv6)](https://datatracker.ietf.org/doc/html/rfc4861)，实验者可以重点关注第 4.3、4.4、4.6.1、7.1、7.2.2、7.2.3、7.2.4 以及 7.2.5 小节。

基于以太网传送 IPv6 分组（包括 ND 报文）时，源和目的 MAC 地址的填写请参见 [RFC 2464: Transmission of IPv6 Packets over Ethernet Networks](https://datatracker.ietf.org/doc/html/rfc2464)，实验者可以重点关注第 3、6、7 小节。

### ND 报文接收

与 Loopback 不同，在本节中，实验者需要对收到的以太网帧进行解析，判断其 EtherType。如果该帧是一个合法的 ND 报文，则实验者需要提取出发送者的 MAC 地址以及 IP 地址，然后更新或插入到邻居缓存中。此处的更新是指，当邻居缓存中存在对应 IP 地址的条目时，更新其 MAC 地址，当不存在时，不进行其他操作；插入是指，当邻居缓存中存在对应 IP 地址的条目时，更新其 MAC 地址，当不存在时，插入该 IP 地址和 MAC 地址的对应关系。当处理完成后，实验者即可将此 ND 报文丢弃。实现完成后，实验者可以通过仿真来进行测试，然后使用 ILA 在实验板上进行观察。

实验者可以在与实验路由器相连的主机上使用 `sudo ndisc6 <目标地址> <网络接口>` 命令来发送 Neighbor Solicitation，以便调试。除 ILA 外，实验者也可以尝试把信号接到 LED 上进行观察。请注意，如果信号变化的频率过快，会导致 LED 闪烁过快，人眼是难以观察的。

!!! question "思考"

    1. 以太网帧的 EtherType 在哪个位置？IPv6 协议对应的 EtherType 是多少？
    2. IPv6 分组头部的 next header 在哪个位置？ND 协议对应的 next header 是多少？
    3. 如何判断一个 ND 报文是否合法？
    4. 操作系统一般会在什么情况下发送 ND 报文到路由器？
    5. 如何向操作系统添加一条指向实验路由器的路由表项？
    6. 何时 **更新** 邻居缓存表项？何时 **插入** 邻居缓存表项？

### Neighbor Advertisement 发送

实验者首先需要对接收到的 Neighbor Solicitation 进行判断。若其请求的目标 IP 地址为当前实验路由器对应接口上的 IP 地址，则实验路由器需要构造一个 Neighbor Advertisement 并发送至相同接口。

如果实现正确，实验者就可以通过 `ndisc6` 得到稳定的低延迟的回复了。

!!! question "思考"

    1. 在构造 Neighbor Advertisement 时，以太网帧头部、IPv6 分组头部、ND 报文的各个字段以及选项（如源 MAC 地址等）应当如何填写？

## 邻居缓存设计与实现

邻居缓存负责缓存 IP 地址与 MAC 地址的对应关系。与转发表不同，邻居缓存的匹配算法采用精确匹配，因此较为简单。根据本实验的实际情况，邻居缓存所需支持的容量无需太大，十余条即可。实现邻居缓存时，实验者可以采用 CAM（Content-Addressable Memory）、蛮力查找或散列表等数据结构，同时可以加入过期自动删除的功能。其中，实验者也可以不实现过期自动删除的功能。

实验者需要为邻居缓存设计好接口，写好 testbench，并进行充分测试。

!!! question "思考"

    1. 如何实现过期自动删除的功能？
    2. IP 地址会有局部性吗？
    3. 如何处理邻居缓存满的情况？
