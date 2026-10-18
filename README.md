# <span id="前言">JobsBaseConfig</span>

![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

子仓下载、关联修复与清单补缺见[Git 子模块脚本](#submodule-scripts)。

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

## 二、<span id="submodule-scripts">Git 子模块脚本</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### [【MacOS】⏬下载配置当前Git子模块.command](./【MacOS】⏬下载配置当前Git子模块.command)

> **目的：** 将选中的直属子仓更新到远端目标分支最新版本，并维护父仓关联。

* 确认自述后读取脚本清单、检查远端，尝试拉取父仓。
* 父仓有未提交改动：跳过父仓拉取，继续处理子仓。
* 在菜单中选择同步范围。
  * 全量同步：选择清单内全部目标重建，须输入 `YES` 执行，其它输入取消。
  * 只更新已有：更新清单内已存在的子仓；一个都没有时转全量同步。
  * 指定子模块：回车勾选或取消，空格确认开始。
  * 添加地址：输入新仓地址和目录，本轮登记并同步。
* 补齐关联配置，检查并处理目标子仓目录。
  * 全量模式：清洁检查通过后删除目标目录、对应仓名的旧目录及缓存，再重新克隆。
  * 其它模式：缺失的目标目录首次克隆，已有子仓继续更新。
  * 子仓有未提交改动：停止该项更新。
* 拉取并强制对齐远端目标分支最新提交，默认优先 `main`，不存在时使用远端默认分支。
  * 使用 `checkout -B` 和 `reset --hard`：目标本地分支未推送的独有提交可能被覆盖。
* 按子仓记录的提交同步更深层子模块，整理 Git 元数据与来源日志。
* 默认自动提交父仓的关联变化，不自动推送。
  * 设置 `AUTO_PARENT_COMMIT=0`：跳过提交；`AUTO_PARENT_PUSH=1`：启用父仓推送。

### [【MacOS】🧭更新引用Git父仓=>子仓.command](./【MacOS】🧭更新引用Git父仓=%3E子仓.command)

> **目的：** 修复目录改名、旧路径残留或元数据指向错误，让父仓关联符合当前磁盘布局。

* 扫描父仓第一层实际带 `.git` 的子目录，读取远端和已有登记。
  * 远端缺失、元数据归属不明或属于链接工作树：停止修复。
* 展示磁盘目录、父仓状态与清理计划，确认后备份关联状态。
  * 直接回车：跳过；输入任意字符后回车：执行；`--dry-run`：只预览。
* 按现存目录对齐 `.gitmodules`，保留仍存在条目的 URL、分支及扩展字段。
  * 目录缺失，包括尚未下载：移除旧登记和旧子模块指针，磁盘文件保留。
* 修复可证明失效的工作树指向，暂存各子仓当前提交号，用官方命令归集元数据并补齐父仓本地登记。
* 核对磁盘目录、清单和父仓子模块指针是否一致，输出状态；不拉取代码、不提交、不推送。

### [【MacOS】🧾更新gitmodules.command](./【MacOS】🧾更新gitmodules.command)

> **目的：** 将新放入的直属子仓完整纳入父仓子模块管理，保留已有登记与指针。

* 读取已有登记，扫描直属子仓，预检远端、提交、索引和元数据冲突。
  * 有冲突或缺少必要信息：停止，展示问题。
* 生成增量计划，保留已有 URL、分支、扩展字段、子模块指针和暂缺目录登记。
  * `--dry-run` 或 `DRY_RUN=1`：只预览，不执行关联写入。
* 确认计划后备份关联配置和父仓索引。
  * 直接回车：跳过；输入任意字符后回车：执行。
* 补齐 `.gitmodules` 和缺失的子模块指针，初始化本地登记，将元数据归集到父仓。
* 核验父子关系和子仓提交号；仅暂存必要关联，不联网拉取、不提交、不推送。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
