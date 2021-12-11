# 开始实验

在 TANLabs 上仔细阅读 Honor Code，确定不会违反以下的要求后接受作业：

1. 我在完成作业过程中不抄袭他人的代码。如果参考了任何他人的代码或思路，一定会在使用处以代码注释的方式注明出处。
2. 如果有其他选课的同学在本学期结束之前寻求自己的帮助，我会确保这些同学不会不加引用地直接使用自己的想法或代码。因为不允许代码层面的借鉴，所以我不会源代码直接提供给他人（包括截图、视频等形式）。
3. 我不会使用修过或者在修本课程的其他同学发布的代码，也包括往届同学在结课后发布的代码。
4. 我不会破坏评测系统，导致评测系统工作异常，例如擅自修改评测数据和 CI 脚本、进行网络攻击、修改 GitLab 项目配置等。当我认为自己的行为可能导致评测系统工作异常时，会先咨询助教。
5. 如果出现了违背以上规则的情况，我愿意承受惩罚，包括但不限于本课程全部实验成绩记零分。

接受作业后，第一步是克隆本仓库（不要忘记先在 GitLab 上添加你的 SSH Key）：

```shell
> git clone git@git.tsinghua.edu.cn:network-2022fall/router-lab-xxx.git Router-Lab # 将 xxx 替换为你的用户名
> cd Router-Lab
```

修改代码后，使用 git 提交：

```shell
> git add .
> git commit -m "Describe what you have done here"
> git push origin master
```

如果原始框架代码有更新（届时会通过多种渠道通知），你可以如下合并这些更新：

```shell
> git remote add upstream git@git.tsinghua.edu.cn:Router-Lab/Router-Lab.git
> git fetch upstream
> git merge upstream/master
```

或者，更简单地，直接：

```shell
> git pull git@git.tsinghua.edu.cn:Router-Lab/Router-Lab.git master
```

!!! info "注意更新方式"

    所有的用户对于自己的作业仓库没有 force push 权限，所以请不要使用 rebase 来合并上游更新，平时也不要随意修改已经 push 的 commit。如果出现问题，请自行查询并使用 `git reflog` 解决。
