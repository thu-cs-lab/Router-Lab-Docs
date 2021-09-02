# 开始实验

在 TanLabs 上接受作业后，第一步是克隆本仓库（不要忘记先在 GitLab 上添加你的 SSH Key）：

```shell
> git clone git@git.tsinghua.edu.cn:network-2022fall/router-lab-xxx.git Router-Lab # 将 xxx 替换为你的用户名
> cd Router-Lab
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
