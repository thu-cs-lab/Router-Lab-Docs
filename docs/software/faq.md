# FAQ

!!! question "我用的是纯命令行环境，没有 Wireshark 图形界面可以用，咋办？"

    你可以用 tcpdump 代替 Wireshark，它的特点是一次性输出所有内容；或者用 tshark，是 Wireshark 官方的 CLI 版本；也可以用 termshark，它是 Wireshark 的 TUI 版，操作方式和 Wireshark 是一致的。比较常用的 tshark 用法是 `sudo tshark -i [interface_name] -V -l [filter]` ，其中 `interface_name` 是网卡名字，如 `eth0` ，`-V` 表示打印出解析树， `-l` 表示关闭输出缓冲， `[filter]` 表示过滤，常见的有 `arp` `ip` `icmp` `ip6` `icmp6` 等等。

!!! question "运行 `grade.py` 的时候，提示找不到 tshark，怎么办？"

    用你的包管理器安装 wireshark 或者 tshark 都行。如果你在使用 Windows，需要注意 Windows 版的 Wireshark 和 WSL 内部的 Wireshark 是需要分别安装的。

!!! question "tshark 好像默认不会检查 IP Header Checksum 等各种 Checksum，我怎么让它进行校验？"

    给它命令行参数 `-o ip.check_checksum:TRUE` `-o tcp.check_checksum:TRUE` 和 `-o udp.check_checksum:TRUE` 就可以打开它的校验功能。如果你使用 Wireshark，直接在 Protocol Preferences 中选择即可。

!!! question "我没有趁手的 Linux 环境，我可以用 WSL 吗？"

    由于 WSL1 没有实现 pcap，如果使用 Linux 后端，即使 sudo 运行也会报告找不到可以抓包的网口，所以你只能用文件后端进行测试。如果你使用 WSL2，应当可以正常的使用 Linux 后端的所有功能（但不保证没有问题）。

!!! question "有时候会出现 `pcap_inject failed with send: Message too long` ，这是什么情况？"

    这一般是因为传给 `HAL_SendIPPacket` 的长度参数大于网口的 MTU，请检查你传递的参数是否正确。需要注意的是，在一些情况下，在 Linux 后端中， `HAL_ReceiveIPPacket` 有时候会返回一个长度大于 MTU 的 IP 分组，这是 TSO (TCP Segment Offload) 或者类似的技术导致的（在网卡中若干个 IP 分组被合并为一个）。你可以用 `ethtool -K 网口名称 tso off` 来尝试关闭 TSO，然后在 `ethtool -k 网口名称` 的输出中找到 `tcp-segmentation-offload: on/off` 确认一下是否成功关闭。另外，有的网卡的设置是 `generic-receive-offload`，相应地，用 `ethtool -K 网口名称 generic-receive-offload off` 关闭即可。

!!! question "我通过 `veth` 建立了两个 netns 之间的连接，路由器也写好了，RIP 可以通，ICMP 也没问题，但就是 TCP 不工作，抓包也能看到 SYN 但是看不到 SYN+ACK，这是为啥？"

    这是因为 Linux 对于网卡有 TX Offload 机制，对于传输层协议的 Checksum 可以交由硬件计算；因此在经过 `veth` 转发时，TCP Checksum 一般是不正确的，这有可能引起一些问题。解决方案和上面类似，用 `ethtool -K veth 名称 tx off` 即可，注意 veth 的两侧都要配置。

!!! question "这个实验怎么要用到怎么多工具啊？我好像都没学过，这不是为难我吗？"

    实验所使用的大部分工具相信同学们在若干先前已经修过的课程中已经有所接触，如 Git（《软件工程》《编译原理》）、Make（《面向对象程序设计基础》）、Python（《程序设计训练》）、SSH（《高性能计算导论》）等，只有 Wireshark 和 iproute2 才是完成此次实验需要额外学习的。Wireshark 能帮助同学们完成调试，iproute2 是管理 Linux 操作系统网络的必备工具，在附录中提供了一份简短的使用说明。学习并掌握工具的使用方法会更有利于完成实验，这里不做强制要求。
    
    顺便提一句，物理系和工物系的小学期课程《实验物理的大数据方法》上课内容囊括了 Git、Make、Python、SSH 和 Linux 的使用，大家也都很好地完成了任务。身为计算机系的同学，更应该掌握这些生存必须的技能。如果有问题，欢迎随时咨询助教和身边的同学。

!!! question "我听说过转发表这个概念，它和路由表是什么关系？"

    实际上这两个是不一样的，路由协议操作路由表，转发操作查询转发表，转发表从路由表中来。但软件实现的路由器其实可以不对二者进行区分，所以在文档里统称为路由表。在 router.h 里的 RoutingTableEntry 只有转发需要的内容，但为了支持 RIPng 协议，你还需要额外添加一些字段，如 metric 等等。

!!! question "树莓派和计算机组成原理用的板子有什么区别？"

    树莓派就是一个小型的计算机，只不过指令集是 ARM，其余部分用起来和笔记本电脑没有本质区别；计算机组成原理的板子核心是 FPGA，你需要编写 Verilog 代码对它进行编程。

!!! question "我在树莓派写的可以工作的代码，放到我的 x86 电脑上跑怎么就不工作了呢？或者反过来，我在 x86 电脑上写的可以工作的代码，放到树莓派上怎么就不工作了呢？或者我本地评测通过的代码，在线为什么不通过呢？"

    一个可能的原因是代码出现了 Undefined Behavior，编译器在不同环境下编译出不同的代码，导致行为不一致。可以用 UBSan 来发现这种问题。在路由器代码里，一个很常见的 Undefined Behavior 就是对 32 位整数左移或右移 32 位，或者调用 `__builtin_clz(0)`，或者更常见的未初始化变量、数组越界等等。还需要注意 char 可能有符号，也可能无符号，建议显式地使用 int8_t 或 uint8_t。

!!! question "我在 macOS 上安装了 Wireshark，但是报错找不到 tshark？"

    tshark 可能被安装到了 /Applications/Wireshark.app/Contents/MacOS/tshark 路径下，如果存在这个文件，把目录放到 PATH 环境变量里就可以了。

!!! question "我在 WSL 下编译，发现编译不通过，`checksum.cpp` 等几个 cpp 文件都不是合法的 cpp 代码。"

    对于 WSL1：这是因为，在 Windows 里 git clone 创建的符号链接，在 WSL 内看到的是普通文件。建议在 WSL1 中进行 git clone 的操作，这样符号链接才是正确的。WSL1 和 Windows 的符号链接互不相通。

    对于 WSL2：同样地，用 WSL2 内部的 git，并且不要在 WSL2 和 Windows 的共享目录中进行。

    更多讨论，见 [Symlinks in Windows 10](https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/) 和 [git-for-windows: Symbolic Links](https://github.com/git-for-windows/git/wiki/Symbolic-Links)

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

!!! question "用 CMake 编译的时候，出现 CMake Error：if given arguments STREQUAL EMCC"

    你可能直接在 Example 目录下使用 CMake 了。Example 是 Router-Lab 的子项目，不能单独使用。

!!! question "我用 netns 和 veth 搭建好了网络，路由器也写好了，RIPng 可以通，但 ICMP 到 R1 以后就不转发了，R1 上运行的是 BIRD，这是为什么呢？"

    BIRD 只负责路由协议，它会把学习到的路由协议和 Linux 的路由表进行同步，并不会做转发的功能。为了打开 Linux 自带的转发功能，需要运行 `ip netns exec R1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"` 命令，在 R1 netns 下把所有接口的 IPv6 的转发打开。但请注意，运行自己编写的路由器的 netns 中不需要 Linux 自带的转发功能，可以把 1 改成 0 以关闭转发功能。

!!! question "我用在本地用 netns 和 veth 搭建好了网络，也可以完成所要求的测试，但是在在线评测的时候一个都不过，这可能是为什么呢？"

    除了检查一下上面提到的 netns 与真实网络的区别以外，并且排除代码的各种问题后，还可以检查一下，OSPF/RIPng/DHCPv6/ICMPv6 协议的目的 MAC 地址是否正确填写。

!!! question "我的程序在真机评测中，stdout 显示是空的，即使我程序一开始就输出了内容？"

    这一般是因为程序在评测过程中异常退出，或者输出的内容没有达到缓冲区的大小，此时写入到 stdout 的数据在缓存中，没有写入到文件中，评测系统取到的文件就是空白的。解决方法是在输出到标准输出（比如 `printf`）的时候，调用 `fflush(stdout)` 来强制清空缓冲区，把输出内容写入到文件。

!!! question "运行 BIRD 的时候，显示 Cannot create control socket bird-r1.ctl: Operation not supported"

    如果是在 WSL 里面运行 BIRD，由于 WSL 共享目录的文件系统不支持 unix socket，所以 BIRD 创建 control socket 会失败。解决方法有两种：1) 把整个 Router-Lab 目录挪到 HOME 下面 2) 参数 `-s bird-r1.ctl` 改为 `-s ~/bird-r1.ctl`，也就是把 control socket 挪到 HOME 下面。

!!! question "在 CI 上提交的时候，报错 BAD signature"

    这是因为实验仓库对 `.gitlab-ci.yml` 做了签名检查，如果误修改了这个文件或者经过了换行符的变化（比如在 Windows Git clone 的仓库又在 WSL 里打开），请用 WSL 的 git 克隆模板仓库，然后用模板仓库中的文件覆盖自己仓库里的文件。

!!! question "运行路由器时报错 no viable interfaces open for capture"

    这是因为路由器程序找不到对应的 interface。可能的原因有：1）没有用 root 权限运行；2）运行在错误的 netns 或者 netns 和路由器 r1-r3 不匹配；3）没有正确配置 netns 或其他虚拟网络环境

!!! question "通过 git commit 提交代码到 GitLab 上后，TANLabs 实验平台的构建历史看不到更新？"

    这说明你的代码在 CI 上构建时失败了，请前往 GitLab，找到对应的 commit，进入 CI 详细信息，就可以知道为什么构建失败了。

!!! question "配置 netns 环境时提示 Failed to create network namespace，即使用 root 用户也不行"

    这说明你的环境不支持 netns，大概率就是 WSL1，WSL1 不支持 netns，请更新到 WSL2。
