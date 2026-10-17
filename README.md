# <span id="前言">JobsBaseConfig</span>

![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

<strong id="submodule-quick-look">父子仓多平台地址速览</strong>

当前 `./.gitmodules` 使用相对地址，例如：

```ini
[submodule "JobsBaseConfig@JobsOCBaseConfigDemo"]
    path = JobsBaseConfig@JobsOCBaseConfigDemo
    url = ../JobsOCBaseConfigDemo.git
    branch = main
```

从下列父仓地址全新克隆、没有本地 URL 覆盖时，结果如下。前两行来自本地已配置的 [**GitHub**](https://github.com) / [**Gitee**](https://gitee.com) 远端；自建平台仅为结构示例，未部署。

| 平台 | 父仓克隆地址 | 子仓解析地址 |
| --- | --- | --- |
| GitHub | `git@github.com:JobsKits/JobsBaseConfig.git` | `git@github.com:JobsKits/JobsOCBaseConfigDemo.git` |
| Gitee | `git@gitee.com:JobsGo/JobsBaseConfig.git` | `git@gitee.com:JobsGo/JobsOCBaseConfigDemo.git` |
| 自建平台，仅结构示例 | `ssh://git@git.example.com:2222/team/JobsBaseConfig.git` | `ssh://git@git.example.com:2222/team/JobsOCBaseConfigDemo.git` |

`path` 是本地目录，`url` 是远端仓库位置；相对 URL 跟随父仓默认远端的平台、组织、协议与端口，前提是该平台已有对应子仓及父仓锁定的提交。已有克隆须核对默认远端和本地子模块配置，仅新增 remote 不会切换线路。

## 一、项目白皮书 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

本目录中可独立运行的 `.command` 入口先显示内置自述：标题红色加粗，编号正文蓝色且不加粗；在终端按回车确认后才进入原有流程，按 `Ctrl+C` 取消。非彩色终端显示纯文本；没有可交互输入时停止，避免确认缺失后继续执行。

> 程序员是一个高消耗的职业，除了日常基本的业务开发以外，新事物的不断涌现也需要持续性的学习，所以是一件非常消耗精力的事；而且由于长期的高压、高情绪、熬夜，**会打乱人体内正常的内分泌节奏**，大概率也会逐渐的引发各种职业疾病。业内普遍认为程序员的**黄金年龄在25～35周岁**。那么，还是希望，在我们（亦或者是暂时性的）离开这个行业的时候，一定要为自己或者后人，留下点什么，算是这么多年的一个工作总结。此外，能最大化的辅助人，帮助其在极短的时间内去：<u>回忆/上手/学习/实验</u>这个编程语言下的工程项目。所以，此项目就一定是要结合商业需求去务实拓展，解决当前痛点。

* 此项目名下管理了：
  * [**Flutter**](https://flutter.dev/)@[实例代码工程项目](https://github.com/JobsKits/JobsFlutterBaseConfigDemo)
  * [**Objc**]()@[实例代码工程项目](https://github.com/JobsKits/JobsOCBaseConfigDemo)
  * [**Swift**]()@[实例代码工程项目](https://github.com/JobsKits/JobsSwiftBaseConfigDemo)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
