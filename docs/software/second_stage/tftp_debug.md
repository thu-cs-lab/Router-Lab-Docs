## 本地测试

在编写 TFTP 协议的客户端和服务端的时候，可以在本机搭建一个虚拟的和评测一样的网络拓扑，这样就可以在虚拟网络中按照评测流程一步一步进行，同时观察程序的行为，可以大大地加快代码的调试。

本地测试主要分为两个部分：首先，搭建网络拓扑，将网络中各个设备连接好；其次，在各个设备上，运行相应的软件，并配置好网络。

网络拓扑的具体过程见[附录中的拓扑搭建文档](../../appendix/topology.md)。

### 快捷脚本

实验仓库中，在 `Setup/tftp` 目录下提供了 netns 配置脚本以及评测脚本，你可以参考里面的内容进行配置。

具体来说，可以按照下列的顺序在本地进行评测：

1. 确认系统内没有正在运行的 TFTP 服务端（进程名为 server）、TFTP 客户端（进程名为 client）以及 tftpd 程序（进程名为 in.tftpd 或者 tftpd）；
2. 打开一个命令行窗口，进入 `Setup/tftp/setup` 目录，执行 `sudo ./setup-netns.sh` 配置 netns 环境，然后执行 `sudo ./start-standard-tftpd-r2.sh` 在 R2 上启动 TFTP 标准服务端，不要退出；
3. 再打开一个命令行窗口，进入 `Setup/tftp/test` 目录，依次执行 `sudo ./test2.sh` 和 `sudo ./test3.sh`，对应第二项和第三项测试；
4. 回到第一个命令行窗口，按 Ctrl-C 结束 TFTP 标准服务端，执行 `sudo ./start-custom-tftpd-r2.sh` 在 R2 上启动你编写的 TFTP 服务端，不要退出；
5. 回到第二个命令行窗口，依次执行 `sudo ./test5.sh`，`sudo ./test6.sh` 到 `sudo ./test9.sh`，对应第五项到第九项测试；
6. 所有项目评测完毕后，可以退出 R2 上的 TFTP 服务端。