# 子Git配置

## 1、光速回退

* 删除父仓库根目录下的`.git`文件夹后运行` 【MacOS】⬆️Git添加子模块.command`

### 2、彻底重置（推荐，但相关文件需要做保存到别处）

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

### 3、`独立仓`改造为`子git`

```shell
mv JobsBaseConfig@JobsFlutterBaseConfigDemo/.git /tmp/backup-JobsFlutterBaseConfigDemo.gitdir
git rm -f --cached JobsBaseConfig@JobsFlutterBaseConfigDemo 2>/dev/null || true
rm -rf .git/modules/JobsBaseConfig@JobsFlutterBaseConfigDemo 2>/dev/null || true

git submodule add -b main https://github.com/JobsKits/JobsFlutterBaseConfigDemo JobsBaseConfig@JobsFlutterBaseConfigDemo
git submodule update --init --recursive JobsBaseConfig@JobsFlutterBaseConfigDemo
```

