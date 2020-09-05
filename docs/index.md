# 总述

!!! danger "版权声明"

    本项目为 2019 年秋季学期起清华大学计算机系开设的《计算机网络原理》课程的实验框架。
    **所有内容（包括文档、代码等）未经作者授权，禁止用作任何其他用途，包括且不限于在其他课程或者其他学校中使用。**
    
    如需使用授权，可通过 shengqi dot chen at tuna dot tsinghua dot edu dot cn 联系作者。作者保留一切追究侵权责任的权利。

## 实验说明

如果你参加的是联合实验，点击上面菜单里的 “计网联合实验”。

这里是 2020 年网络原理课程原理课程实验采用的框架。它有以下的设计目标：

1. 降低难度，把与底层打交道的部分抽象成通用的接口，减少学习底层 API 的负担
2. 复用代码，在一个平台上编写的程序可以直接用于其他平台
3. 方便测试，提供文件读写 PCAP 的后端，可以直接用数据进行黑箱测试

实验的目标是完成一个具有以下功能的路由器：

1. 转发：收到一个路过的 IP 包，通过查表得到下一棒（特别地，如果目的地址直接可达，下一棒就是目的地址），然后“接力”给下一棒。
2. 路由：通过 RIP 协议，学习到网络的拓扑信息用于转发，使得网络可以连通。

本实验目标是让大家掌握如下技能：

1. 网络环境的调试，利用 ping 和抓包等工具，找到网络中出问题的地方并解决
2. 阅读，理解和实现 RFC 文档的能力，在本实验里主要是 [RFC2453 RIP Version 2](https://tools.ietf.org/html/rfc2453)
3. Linux 系统网络的配置

本文档默认你已经在软件工程、编译原理、程序设计训练等课程中已经学习到了足够的 **Git 、Make 、SSH 、Python3 和 Linux** 的使用知识。如果你用的是 Windows 系统，你可以 WSL/虚拟机/领取的树莓派上进行以下所有相关的操作。无论你电脑是用的是什么系统，最终都需要在树莓派的 Linux 上运行路由器。

如果你运行的是 Debian 系列发行版（包括 Ubuntu、Raspbian），你可以一把梭地安装所有可能需要的依赖：

```bash
> sudo apt update
> sudo apt install git make cmake python3 python3-pip libpcap-dev libreadline-dev libncurses-dev wireshark tshark iproute2 g++
> pip3 install pyshark
```

如果安装时网络较慢，可以参考 [TUNA 镜像站](https://mirrors.tuna.tsinghua.edu.cn/help/debian/) 或者 [OpenTUNA 镜像站](https://opentuna.cn/help/debian) 的 Debian 镜像使用帮助进行配置。其他发行版也有类似的包管理器安装方法。

如果你使用的是 macOS 系统，请安装 Homebrew，可以参考 [TUNA 镜像站的 Homebrew 镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/) 进行配置。然后运行如下的命令：

```bash
> brew install git cmake python3
> brew cask install wireshark
> pip3 install pyshark
```

## 项目作者

总设计师： @z4yx

后续维护： @Harry-Chen @jiegec

提交贡献： @Konano @nzh63 @linusboyle
