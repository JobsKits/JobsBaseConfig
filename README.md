# JobsBaseConfig

## 一、项目白皮书

> 程序员是一个高消耗的职业，除了日常基本的业务开发以外，新事物的不断涌现也需要持续性的学习，所以是一件非常消耗精力的事；而且由于长期的高压、高情绪、熬夜，**会打乱人体内正常的内分泌节奏**，大概率也会逐渐的引发各种职业疾病。业内普遍认为程序员的**黄金年龄在25～35周岁**。那么，还是希望，在我们（亦或者是暂时性的）离开这个行业的时候，一定要为自己或者后人，留下点什么，算是这么多年的一个工作总结。此外，能最大化的辅助人，帮助其在极短的时间内去：<u>回忆/上手/学习/实验</u>这个编程语言下的工程项目。所以，此项目就一定是要结合商业需求去务实拓展，解决当前痛点。

* 此项目名下管理了：
  * [**Flutter**](https://flutter.dev/)@[实例代码工程项目](https://github.com/JobsKits/JobsFlutterBaseConfigDemo)
  * [**Objc**]()@[实例代码工程项目](https://github.com/JobsKits/JobsOCBaseConfigDemo)
  * [**Swift**]()@[实例代码工程项目](https://github.com/JobsKits/JobsSwiftBaseConfigDemo)

## 二、子Git配置

### 1、彻底重置（推荐，但相关文件需要做保存到别处）

* 在父仓库根目录执行：

  ```shell
  # 1) 先反注册（会清掉 .git/config 里的 submodule 记录）
  git submodule deinit -f -- JobsBaseConfig@JobsOCBaseConfigDemo
  git submodule deinit -f -- JobsBaseConfig@JobsSwiftBaseConfigDemo
  git submodule deinit -f -- JobsBaseConfig@JobsFlutterBaseConfigDemo
  
  # 2) 从父仓库索引移除（注意：--cached 不会删你本地目录内容）
  git rm -f --cached JobsBaseConfig@JobsOCBaseConfigDemo
  git rm -f --cached JobsBaseConfig@JobsSwiftBaseConfigDemo
  git rm -f --cached JobsBaseConfig@JobsFlutterBaseConfigDemo
  
  # 3) 删除父仓库保存的 submodule git 数据（关键）
  rm -rf .git/modules/JobsBaseConfig@JobsOCBaseConfigDemo
  rm -rf .git/modules/JobsBaseConfig@JobsSwiftBaseConfigDemo
  rm -rf .git/modules/JobsBaseConfig@JobsFlutterBaseConfigDemo
  
  # 4) 删除工作区目录（如果你要完全重来，建议删掉；否则里面旧 .git 目录会继续污染）
  rm -rf JobsBaseConfig@JobsOCBaseConfigDemo
  rm -rf JobsBaseConfig@JobsSwiftBaseConfigDemo
  rm -rf JobsBaseConfig@JobsFlutterBaseConfigDemo
  
  # 5) 如果 .gitmodules 里还有残留，手动打开删掉对应块，或直接重建
  # 然后提交一次清理
  git add .gitmodules
  git commit -m "chore: clean submodules"
  ```

* 然后再重新添加：

  ```shell
  git submodule add -b main https://github.com/JobsKits/JobsOCBaseConfigDemo      JobsBaseConfig@JobsOCBaseConfigDemo
  git submodule add -b main https://github.com/JobsKits/JobsSwiftBaseConfigDemo   JobsBaseConfig@JobsSwiftBaseConfigDemo
  git submodule add -b main https://github.com/JobsKits/JobsFlutterBaseConfigDemo JobsBaseConfig@JobsFlutterBaseConfigDemo
  
  git submodule sync
  git submodule update --init --recursive
  git add .gitmodules JobsBaseConfig@JobsOCBaseConfigDemo JobsBaseConfig@JobsSwiftBaseConfigDemo JobsBaseConfig@JobsFlutterBaseConfigDemo
  git commit -m "feat: add base config submodules"
  
  ```

### 2、`独立仓`改造为`子git`

```shell
mv JobsBaseConfig@JobsFlutterBaseConfigDemo/.git /tmp/backup-JobsFlutterBaseConfigDemo.gitdir
git rm -f --cached JobsBaseConfig@JobsFlutterBaseConfigDemo 2>/dev/null || true
rm -rf .git/modules/JobsBaseConfig@JobsFlutterBaseConfigDemo 2>/dev/null || true

git submodule add -b main https://github.com/JobsKits/JobsFlutterBaseConfigDemo JobsBaseConfig@JobsFlutterBaseConfigDemo
git submodule update --init --recursive JobsBaseConfig@JobsFlutterBaseConfigDemo
```

