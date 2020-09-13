# FAQ

!!! question "我用的是纯命令行环境，没有 Wireshark 图形界面可以用，咋办？"

    你可以用 tcpdump 代替 Wireshark，它的特点是一次性输出所有内容；或者用 tshark，是 Wireshark 官方的 CLI 版本；也可以用 termshark ，它是 Wireshark 的 TUI 版，操作方式和 Wireshark 是一致的。比较常用的 tshark 用法是 `sudo tshark -i [interface_name] -V -l [filter]` ，其中 `interface_name` 是网卡名字，如 `eth0` ，`-V` 表示打印出解析树， `-l` 表示关闭输出缓冲， `[filter]` 表示过滤，常见的有 `arp` `ip` `icmp` 等等。

!!! question "运行 `grade.py` 的时候，提示找不到 tshark ，怎么办？"

    用你的包管理器安装 wireshark 或者 tshark 都行。如果你在使用 Windows，需要注意 Windows 版的 Wireshark 和 WSL 内部的 Wireshark 是需要分别安装的。

!!! question "tshark 好像默认不会检查 IP Header Checksum 等各种 Checksum，我怎么让它进行校验？"

    给它命令行参数 `-o ip.check_checksum:TRUE` `-o tcp.check_checksum:TRUE` 和 `-o udp.check_checksum:TRUE` 就可以打开它的校验功能。如果你使用 Wireshark，直接在 Protocol Preferences 中选择即可。

!!! question "为啥要搞 HAL 啊，2018 年让大家用 Linux 的 Raw Socket ，不也有人搞出来了吗？"

    我们认为 2018 年的 Linux 的 Raw Socket 是比较古老而且需要同学编写很多冗余代码的一套 API，另外比较复杂的 Quagga 的交互接口也让很多同学遇到了困难，结果就是只有少数同学很顺利地完成了所有任务，一些同学在不理解这些 API 的工作方式的情况下直接拿代码来就用，出现一些问题后就一筹莫展，这是我们不希望看到的一种情况，况且这部分知识与网络原理课程关系不大，日后也基本不会接触。2019 年我们采用的 `libpcap` 以一个更底层的方式进行收发，绕过了操作系统的 IP 层，这样可以避开 Raw Socket 的一些限制，不过也多了自行维护 ARP 的负担。同时，2019 年新增了硬件路由器实验，为了把二者统一，我们设计了 HAL 库，它维护了 ARP 的信息，在 Linux 等平台下用 `libpcap`，在 Xilinx 平台下用 IP 核的寄存器，和 stdio 后端用于在线评测。我们期望通过这些方法减少大家的负担。

!!! question "我没有趁手的 Linux 环境，我可以用 WSL 吗？"

    由于 WSL1 没有实现 pcap ，如果使用 Linux 后端，即使 sudo 运行也会报告找不到可以抓包的网口，所以你只能用文件后端进行测试。如果你使用 WSL2，应当可以正常的使用 Linux 后端的所有功能（但不保证没有问题）。

!!! question "有时候会出现 `pcap_inject failed with send: Message too long` ，这是什么情况？"

    这一般是因为传给 `HAL_SendIPPacket` 的长度参数大于网口的 MTU，请检查你传递的参数是否正确。需要注意的是，在一些情况下，在 Linux 后端中， `HAL_ReceiveIPPacket` 有时候会返回一个长度大于 MTU 的包，这是 TSO (TCP Segment Offload) 或者类似的技术导致的（在网卡中若干个 IP 包被合并为一个）。你可以用 `ethtool -K 网口名称 tso off` 来尝试关闭 TSO ，然后在 `ethtool -k 网口名称` 的输出中找到 `tcp-segmentation-offload: on/off` 确认一下是否成功关闭。

!!! question "RIP 协议用的是组播地址，但组播是用 IGMP 协议进行维护的，这个框架是怎么解决这个问题的？"

    在 Linux 和 macOS 后端的 `HAL_Init` 函数中，它会向所有网口都发一份 `IGMP Membership Join group 224.0.0.9` 表示本机进入了 RIP 协议的对应组播组之中。为了简化流程，退出时不会发送 Leave Group 的消息，你可以选择手动发送。

!!! question "我通过 `veth` 建立了两个 netns 之间的连接，路由器也写好了， RIP 可以通， ICMP 也没问题，但就是 TCP 不工作，抓包也能看到 SYN 但是看不到 SYN+ACK ，这是为啥？"

    这是因为 Linux 对于网卡有 TX Offload 机制，对于传输层协议的 Checksum 可以交由硬件计算；因此在经过 `veth` 转发时，TCP Checksum 一般是不正确的，这有可能引起一些问题。解决方案和上面类似，用 `ethtool -K veth名称 tx off` 即可，注意 veth 的两侧都要配置。

!!! question "这个实验怎么要用到怎么多工具啊？我好像都没学过，这不是为难我吗？"

    实验所使用的大部分工具相信同学们在若干先前已经修过的课程中已经有所接触，如 Git（《软件工程》《编译原理》）、Make（《面向对象程序设计基础》）、Python（《程序设计训练》）、SSH（《高性能计算导论》）等，只有 Wireshark 和 iproute2 才是完成此次实验需要额外学习的。Wireshark 能帮助同学们完成调试，iproute2 是管理 Linux 操作系统网络的必备工具，我们在下面的附录中提供了一份简短的使用说明。学习并掌握工具的使用方法会更有利于完成实验，这里不做强制要求。
    
    顺便提一句，物理系和工物系的小学期课程《实验物理的大数据方法》上课内容囊括了 Git、Make、Python、SSH 和 Linux 的使用，大家也都很好地完成了任务。身为计算机系的同学，更应该掌握这些生存必须的技能。如果有问题，欢迎随时咨询助教和身边的同学。

!!! question "我听说过转发表这个概念，它和路由表是什么关系？"

    实际上这两个是不一样的，路由协议操作路由表，转发操作查询转发表，转发表从路由表中来。但软件实现的路由器其实可以不对二者进行区分，所以在文档里统称为路由表。在 router.h 里的 RoutingTableEntry 只有转发需要的内容，但为了支持 RIP 协议，你还需要额外添加一些字段，如 metric 等等。

!!! question "树莓派和计算机组成原理用的板子有什么区别？"

    树莓派就是一个小型的计算机，只不过指令集是 ARM ，其余部分用起来和笔记本电脑没有本质区别；计算机组成原理的板子核心是 FPGA ，你需要编写 Verilog 代码对它进行编程。

!!! question "我在树莓派写的可以工作的代码，放到我的 x86 电脑上跑怎么就不工作了呢？或者反过来，我在 x86 电脑上写的可以工作的代码，放到树莓派上怎么就不工作了呢？"

    一个可能的原因是代码出现了 Undefined Behavior ，编译器在不同架构下编译出不同的代码，导致行为不一致。可以用 UBSan 来发现这种问题。在路由器代码里，一个很常见的 Undefined Behavior 就是对 32 位整数左移或右移 32 位，或者调用 `__builtin_clz(0)` 。

!!! question "我用 ssh 连不上树莓派，有什么办法可以进行诊断吗？"

    可以拿 HDMI 线把树莓派接到显示器上，然后插上 USB 的键盘和鼠标，登录进去用 `ip` 命令看它的网络情况。网络连接方面，可以用网线连到自己的电脑或者宿舍路由器上，也可以连接到 Wi-Fi 。如果没有显示器，也可以用 USB 转串口，把串口接到树莓派对应的引脚上。

!!! question "我在 macOS 上安装了 Wireshark，但是报错找不到 tshark ？"

    tshark 可能被安装到了 /Applications/Wireshark.app/Contents/MacOS/tshark 路径下，如果存在这个文件，把目录放到 PATH 环境变量里就可以了。

!!! question "为啥要用树莓派呢，电脑上装一个 Linux 双系统或者开个 Linux 虚拟机不好吗？"

    树莓派可以提供一个统一的环境，而且对同学的电脑的系统和硬盘空间没有什么要求，而虚拟机和双系统都需要不少的硬盘空间。另外，虚拟机的网络配置比树莓派要更加麻烦，一些同学的电脑也会因为没有开启虚拟化或者 Hyper-V 的原因运行不了 VirtualBox 和 VMWare，三种主流的虚拟机软件都有一些不同，让配置变得很麻烦。同时，树莓派的成熟度和文档都比较好，网上有很多完善的资料，学习起来并不困难，硬件成本也不高。

!!! question "我在 WSL 下编译 router，发现编译不通过，`checksum.cpp` 等几个 cpp 文件都不是合法的 cpp 代码。"

    这是因为在 Windows 里 git clone 的符号链接在 WSL 内看到的是普通文件，建议在 WSL 中进行 git clone 的操作，这样符号链接才是正确的。

!!! question "我想在 SHELL 里面随时看到我所在的 netns，有什么好办法吗"

    你可以用 `ip netns identify` 命令获取当前的 netns，将它加入 SHELL 的 `PS1` 或类似配置中即可。
    
    下面是一个 `fish` 配置的例子，放到 `~/.config/fish/config.fish` 中：
    
    ```shell
    function fish_prompt --description "Write out the prompt"
        set -l color_cwd
        set -l suffix
        switch "$USER"
            case root toor
                if set -q fish_color_cwd_root
                    set color_cwd $fish_color_cwd_root
                else
                    set color_cwd $fish_color_cwd
                end
                set suffix '#'
            case '*'
                set color_cwd $fish_color_cwd
                set suffix '>'
        end
        switch (ip netns identify)
            case ''
                set prefix ''
            case '*'
                set prefix "("(ip netns identify)") "
        end
    
        echo -n -s "$prefix" "$USER" @ (prompt_hostname) ' ' (set_color $color_cwd) (prompt_pwd) (set_color normal) "$suffix "
    end
    ```
