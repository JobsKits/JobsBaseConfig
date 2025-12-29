#!/usr/bin/env zsh
set -euo pipefail

# ================================== Git添加子模块（可重复执行/修复旧状态） ==================================

# 终端执行目录转向目前脚本所在目录
script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
cd "$script_path"

# ================================== 工具函数 ==================================

info()  { print -P "%F{cyan}🔧 $*%f" }
ok()    { print -P "%F{green}✅ $*%f" }
warn()  { print -P "%F{yellow}⚠️  $*%f" }
err()   { print -P "%F{red}❌ $*%f" }

ensure_git_repo() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ok "当前目录已是 Git 仓库：$(pwd)"
  else
    info "初始化 Git 仓库：$(pwd)"
    git init
    ok "Git init 完成"
  fi
}

ensure_first_commit_if_needed() {
  # 没有任何提交时，submodule 操作经常会受限；这里自动做一次初始提交（如果需要）
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    ok "已存在提交：$(git rev-parse --short HEAD)"
    return
  fi

  warn "当前仓库还没有任何提交，先做一次初始提交（避免后续 submodule 流程卡住）"
  git add -A
  git commit -m "chore: initial commit for submodules" || true
  ok "初始提交完成"
}

print_status() {
  info "Git 状态："
  git status
}

# 彻底移除“旧的/半残”的 submodule 记录 + 工作区目录 + modules 缓存
remove_existing_submodule() {
  local path="$1"

  # 1) 如果这个 path 在 .gitmodules 或 git config 中被识别为 submodule，先 deinit
  if git config -f .gitmodules --get-regexp "^submodule\..*\.path$" 2>/dev/null | awk '{print $2}' | grep -Fxq "$path"; then
    warn "发现 .gitmodules 中已有该子模块 path：$path，执行 deinit"
    git submodule deinit -f -- "$path" || true
  fi

  # 2) 如果 index 里已经记录了这个 gitlink（导致你报 already exists in the index），必须 git rm
  if git ls-files --stage -- "$path" | grep -q .; then
    warn "发现 index 已记录该 path：$path，执行 git rm（清理 gitlink）"
    git rm -f --cached -- "$path" || true
    git rm -f -- "$path" || true
  fi

  # 3) 清理父仓库的 .git/modules 缓存
  if [[ -d ".git/modules/$path" ]]; then
    warn "清理 .git/modules 缓存：.git/modules/$path"
    rm -rf ".git/modules/$path"
  fi

  # 4) 清理工作区残留目录
  if [[ -e "$path" ]]; then
    warn "清理工作区残留：$path"
    rm -rf "$path"
  fi

  ok "移除旧状态完成：$path"
}

add_submodule() {
  local branch="$1"
  local url="$2"
  local path="$3"

  info "添加子模块：$url -> $path （branch=$branch）"
  git submodule add -b "$branch" "$url" "$path"
  ok "已添加：$path"
}

sync_and_update_submodules() {
  info "同步 submodule url 记录"
  git submodule sync --recursive

  info "首次拉取/初始化子模块内容"
  git submodule update --init --recursive --jobs="$(sysctl -n hw.ncpu)"

  info "吸收子模块内部 .git 目录（确保子模块里 .git 是文件形式 gitfile）"
  git submodule absorbgitdirs --recursive

  info "让全部子模块按各自 branch 前移（可选：你想跟随远端最新就开）"
  git submodule update --remote --merge --recursive --jobs="$(sysctl -n hw.ncpu)"

  info "再吸收一次（防止 update 过程中又出现 .git 目录）"
  git submodule absorbgitdirs --recursive

  ok "子模块同步/更新完成"
}

commit_submodule_changes_if_any() {
  # 把 .gitmodules 和 submodule gitlink 统一提交
  info "提交子模块变更（如有）"
  git add -A

  if git diff --cached --quiet; then
    warn "暂存区无变更，不需要提交"
    return
  fi

  git commit -m "chore: sync submodules (OC/Swift/Flutter)"
  ok "已提交子模块变更"
}

verify_gitfile_form() {
  local path="$1"
  if [[ -f "$path/.git" ]]; then
    ok "子模块 .git 为文件形式（符合预期）：$path/.git"
    return 0
  fi
  if [[ -d "$path/.git" ]]; then
    warn "子模块 .git 仍是目录（通常表示未 absorbgitdirs 或不是 submodule 状态）：$path/.git"
    return 1
  fi
  warn "子模块缺少 .git（不正常）：$path"
  return 1
}

# ================================== 主流程 ==================================

main() {
  ensure_git_repo
  ensure_first_commit_if_needed
  print_status

  # ---- 你的三个子仓库配置（统一在这里管理） ----
  local branch="main"

  local url_oc="https://github.com/JobsKits/JobsOCBaseConfigDemo"
  local url_swift="https://github.com/JobsKits/JobsSwiftBaseConfigDemo"
  local url_flutter="https://github.com/JobsKits/JobsFlutterBaseConfigDemo"

  local path_oc="./JobsBaseConfig@JobsOCBaseConfigDemo"
  local path_swift="./JobsBaseConfig@JobsSwiftBaseConfigDemo"
  local path_flutter="./JobsBaseConfig@JobsFlutterBaseConfigDemo"

  # 1) 先把旧的/半残的记录全部清掉（否则你就会一直遇到 already exists in the index）
  remove_existing_submodule "$path_oc"
  remove_existing_submodule "$path_swift"
  remove_existing_submodule "$path_flutter"

  # 2) 重新添加三者（保证 Flutter 一定会加上）
  add_submodule "$branch" "$url_oc" "$path_oc"
  add_submodule "$branch" "$url_swift" "$path_swift"
  add_submodule "$branch" "$url_flutter" "$path_flutter"

  # 3) 同步/初始化/吸收 .git 目录 -> 文件形式
  sync_and_update_submodules

  # 4) 提交（如有）
  commit_submodule_changes_if_any

  # 5) 验证：你关心的 “.git 是否变成文件”
  info "验证子模块 .git 形态："
  verify_gitfile_form "$path_oc" || true
  verify_gitfile_form "$path_swift" || true
  verify_gitfile_form "$path_flutter" || true

  ok "全部完成"
  print_status
}

main "$@"
