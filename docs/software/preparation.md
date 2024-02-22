# 准备工作

## 系统支持

该实验支持的系统如下：

1. Ubuntu 22.04 及更新
2. Debian 11 及更新

如果你用的是 Windows 系统，你可以在 WSL 2 或虚拟机上进行以下所有相关的操作。请注意，MinGW 和 Cygwin 也是不支持的。不建议用 CentOS/RHEL，因为软件版本通常比较旧。也不建议使用 WSL 1，因为 WSL 1 缺少一些内核特性，例如 netns。

**如果你还没有 Linux 系统环境，请在做实验前提前通过 WSL 2/虚拟机/双系统等方式准备好。**

另外，编程作业部分因为不涉及到 Linux 的 API，所以支持的系统更多，包括 macOS，但由于其余部分仅支持 Linux，还是应当提前准备好 Linux 环境。

## 知识储备

完成该实验需要一定的 **C++、Git、Make、SSH、Shell、Python3 和 Linux** 的使用知识。如果你是大三或之后选的课程，那么你应该已经在《程序设计基础》《程序设计训练》《软件工程》《编译原理》等课程中学到了相应的知识。如果你尚未学习这些相关课程，请参考以下的教程 **进行预习**：

- Git: [计算机系科协技能引导文档 - Git：分布式版本控制软件](https://docs.net9.org/basic/git/) [简明指南](https://rogerdudler.github.io/git-guide/index.zh.html) [Git 教程](https://www.liaoxuefeng.com/wiki/896043488029600) [缺失的一课](https://missing-semester-cn.github.io/2020/version-control/) [Git Cheatsheet](https://education.github.com/git-cheat-sheet-education.pdf)
- Make: 见[附录](../appendix/make.md)
- SSH: [GitLab SSH 配置（注意用的是 git.tsinghua.edu.cn 而不是 gitlab.com）](https://www.yiibai.com/gitlab/gitlab_ssh_key_setup.html)
- Shell: [缺失的一课](https://missing-semester-cn.github.io/2020/command-line/) [Command Line Cheatsheet](https://threenine.co.uk/download/1846/)
- Linux: [计算机系科协技能引导文档 - Linux 入门](https://docs.net9.org/basic/linux/) [USTC LUG Linux 101 在线讲义](https://101.lug.ustc.edu.cn/)

其中特别推荐 [计算机教育中缺失的一课](https://missing-semester-cn.github.io/)。

在最终评测时，你编写的路由器代码都将在树莓派上的 Linux 系统上运行。

## 配置开发环境

装好 Linux 系统后，需要安装一些实验中会涉及到的软件。如果你运行的是 Debian 系列发行版（包括 Ubuntu、Raspberry Pi OS），你可以用以下命令安装所有可能需要的依赖：

```bash
sudo apt update
sudo apt install git make cmake python3 python3-pip libpcap-dev libreadline-dev libncurses-dev wireshark tshark iproute2 g++ bird2 ethtool ndisc6 dhcpcd5 tftpd-hpa tftp-hpa radvd isc-dhcp-server
pip3 install pyshark
```

需要注意的是，Debian 系列发行版在安装一些带有服务的包的时候，会默认启动服务并设置为开机启动。如果你不希望这些服务启动，可以用下面的命令停止服务并取消开机启动：

```shell
sudo systemctl disable --now tftpd-hpa isc-dhcp-server dhcpcd radvd bird
```

如果安装时网络较慢，可以参考 [TUNA 镜像站](https://mirrors.tuna.tsinghua.edu.cn/help/debian/) 或者 [OpenTUNA 镜像站](https://opentuna.cn/help/debian) 的 Debian 镜像使用帮助进行配置。其他发行版也有类似的包管理器安装方法。

如果你使用的是 macOS 系统，推荐使用 Homebrew，可以参考 [TUNA 镜像站的 Homebrew 镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/) 进行配置。然后运行如下的命令：

```bash
brew install git cmake python3
brew install --cask wireshark
pip3 install pyshark
```
