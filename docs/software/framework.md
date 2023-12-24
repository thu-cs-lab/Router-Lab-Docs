# 如何使用框架

框架的 HAL 库提供了以下这些函数：

1. `HAL_Init`: 使用 HAL 库的第一步，**必须调用且仅调用一次**，需要提供每个网口上绑定的 IP 地址，第一个参数表示是否打开 HAL 的测试输出
2. `HAL_GetTicks`：获取从启动到当前时刻的毫秒数
3. `HAL_GetNeighborMacAddress`：从 IPv6 ND 邻居表中查询 IPv6 地址对应的 MAC 地址，在找不到的时候会发出 IPv6 ND 请求
4. `HAL_GetInterfaceMacAddress`：获取指定网口上绑定的 MAC 地址
5. `HAL_ReceiveIPPacket`：从指定的若干个网口中读取一个 IPv6 报文，并得到源 MAC 地址和目的 MAC 地址等信息；它还会在内部处理 IPv6 ND 邻居表的更新和响应，需要定期调用
6. `HAL_SendIPPacket`：向指定的网口发送一个 IPv6 报文

这些函数的定义和功能都在 `router_hal.h` 详细地解释了，请阅读函数前的文档。为了易于调试，HAL 没有实现 IPv6 ND 邻居表的老化，你可以自己在代码中实现，并不困难。

你可以利用 HAL 本身的调试输出，只需要在运行 `HAL_Init` 的时候设置 `debug` 标志，你就可以在 stderr 上看到一些有用的输出。
