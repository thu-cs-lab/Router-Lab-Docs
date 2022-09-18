## DHCPv6 路由器

一个 DHCPv6 协议的路由器需要支持如下的功能：

1. 利用 IPv6 ND 和 DHCPv6 协议给客户端分配动态的 IPv6 地址
2. 按照固定的路由表，进行 IPv6 分组的转发

## 协议理解

在这一步，你需要实现一个 DHCPv6 协议的路由器。

客户端在尝试获取 IPv6 地址的时候，首先会通过 IPv6 ND（Neighbor Discovery）协议发送 RS（Router Solicitation）去寻找路由器，路由器向客户端发送 RA（Router Advertisement）表示自己是路由器，可以分配地址。那么，你需要首先阅读 [RFC 4861](https://www.rfc-editor.org/rfc/rfc4861)，理解其中关于 RS 的 RA 的部分，并能回答以下几个问题：

1. 数据格式是怎么样的？
2. IPv6 源地址是？目的地址是？
3. 在 RA 中，如何告诉客户端需要使用 DHCPv6 获取动态 IPv6 地址？
4. ICMPv6 的额外的 Options 是如何编码的？

客户端在收到 RA 以后，得知可以通过 DHCPv6 获得动态 IPv6 地址，此时客户端和服务端会按照 DHCPv6 协议来动态分配和获取 IPv6 地址。此时，你需要阅读 [RFC 8415](https://www.rfc-editor.org/rfc/rfc8415.html)，理解客户端和服务端之间发送的四个消息，并能回答下面的几个问题：

1. 客户端第一步要发送的是哪个消息？
2. 服务端收到客户端第一步发送的消息后，应该回应什么消息？
3. 客户端收到服务端的消息后，又要发送什么消息？
4. 最后服务端要发送什么消息，来完成 DHCPv6 的地址分配？

!!! attention "HONOR CODE"

    在 `router` 目录中，有一个 `HONOR-CODE.md` 文件，你需要在这个文件中以 Markdown 格式记录你完成这个作业时参考网上的文章或者代码、与同学的交流情况。
