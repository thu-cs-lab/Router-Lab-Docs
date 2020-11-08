# 准备工作

## 知识储备

本文档默认你已经在《软件工程》《编译原理》《程序设计训练》等课程中已经学习到了足够的 **Git 、Make 、SSH 、Python3 和 Linux** 的使用知识。如果你用的是 Windows 系统，你可以 WSL/虚拟机/领取的树莓派上进行以下所有相关的操作。请注意，MinGW 也是不支持的。

如果你还不理解 **Make** 的使用方法，可以查看附录。如果使用 **Linux** 经验比较少，可以查看 [USTC LUG Linux 101 在线讲义](https://101.lug.ustc.edu.cn/) 进行学习。如果对 **Git** 使用不熟悉，可以阅读 [助教编写的 Git 速查文档](https://circuitcoder.github.io/Orange-ECC/ecc/git/)

在最终评测时，你编写的路由器代码都将在树莓派的 Linux 系统上运行。

## 配置开发环境

如果你运行的是 Debian 系列发行版（包括 Ubuntu、Raspbian），你可以用以下命令安装所有可能需要的依赖：

```bash
> sudo apt update
> sudo apt install git make cmake python3 python3-pip libpcap-dev libreadline-dev libncurses-dev wireshark tshark iproute2 g++
> pip3 install pyshark
```

如果安装时网络较慢，可以参考 [TUNA 镜像站](https://mirrors.tuna.tsinghua.edu.cn/help/debian/) 或者 [OpenTUNA 镜像站](https://opentuna.cn/help/debian) 的 Debian 镜像使用帮助进行配置。其他发行版也有类似的包管理器安装方法。

如果你使用的是 macOS 系统，我们推荐使用 Homebrew，可以参考 [TUNA 镜像站的 Homebrew 镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/) 进行配置。然后运行如下的命令：

```bash
> brew install git cmake python3
> brew cask install wireshark
> pip3 install pyshark
```
