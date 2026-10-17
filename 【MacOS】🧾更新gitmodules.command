#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】🧾更新gitmodules.command
# - 核心用途：按工程根目录第一层真实子 Git 增量补齐 .gitmodules，保留已有登记。
# - 影响范围：只改写或新建当前工程根目录下的 .gitmodules，不自动 stage、commit、push，也不改子仓库内容。
# - 运行提示：先回车查看计划；写入前回车跳过、输入任意字符执行；DRY_RUN=1 仅预览。

# 仅渲染自述：标题红色加粗，编号正文蓝色常规字重；非彩色终端输出纯文本。
jobs_intro_style() {
  local intro_color=0
  if [ -t 1 ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != dumb ] &&
     [ -z "${NO_COLOR+x}" ] && [ "${PLAIN_OUTPUT:-0}" != 1 ] &&
     [ "${IS_SOURCETREE_RUNTIME:-0}" != 1 ]; then
    intro_color=1
  fi
  /usr/bin/awk -v color="$intro_color" -v role="${1:-body}" '
    BEGIN { esc = sprintf("%c", 27) }
    {
      gsub(esc "\\[[0-9;]*m", "")
      gsub(/\\(033|e|x1[bB])\[[0-9;]*m/, "")
      if (!color || $0 ~ /^[[:space:]]*$/) { print; next }
      numbered = ($0 ~ /^[[:space:]➤ℹ🔹✔⚠]*([0-9]+[、.)）]|[0-9]+️⃣|[-•])/)
      heading = ($0 ~ /^[[:space:]]*#{1,6}[[:space:]]/ || $0 ~ /[：:][[:space:]]*$/ || $0 ~ /^[[:space:]]*[=━─-]{3}/)
      title = (!numbered && (role == "title" || heading))
      if (role == "auto" && !seen && !numbered) title = 1
      if ($0 !~ /^[[:space:]]*[=━─-]+[[:space:]]*$/) seen = 1
      printf "%s%s%s\n", esc (title ? "[1;31m" : "[0;34m"), $0, esc "[0m"
    }
  '
}
SCRIPT_FILE="${(%):-%x}"
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_FILE")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$SCRIPT_FILE")"
SCRIPT_BASENAME="$(basename "$SCRIPT_FILE" | sed 's/\.[^.]*$//')"
REPO_ROOT="$SCRIPT_DIR"
GITMODULES_FILE="${REPO_ROOT}/.gitmodules"
LOG_FILE="${TMPDIR:-/tmp/}${SCRIPT_BASENAME}.log"
DRY_RUN="${DRY_RUN:-0}"
GITMODULES_CHECKSUM=""

typeset -ga CURRENT_SUBGIT_DIRS
typeset -ga WRITABLE_SUBGIT_DIRS
typeset -ga SKIPPED_SUBGIT_DIRS
typeset -ga STALE_GITMODULE_PATHS
typeset -gA EXISTING_SECTION_NAMES
typeset -gA EXISTING_BRANCHES
typeset -gA SUBMODULE_URLS
typeset -gA SUBMODULE_BRANCHES
CURRENT_SUBGIT_DIRS=()
WRITABLE_SUBGIT_DIRS=()
SKIPPED_SUBGIT_DIRS=()
STALE_GITMODULE_PATHS=()

# 输出日志并同步写入日志文件。
log() {
  echo -e "$1" | tee -a "$LOG_FILE"
}
# 按当前输出级别记录普通信息。
info_echo() {
  log "\033[1;34mℹ $1\033[0m"
}
# 按当前输出级别记录成功信息。
success_echo() {
  log "\033[1;32m✔ $1\033[0m"
}
# 按当前输出级别记录警告信息。
warn_echo() {
  log "\033[1;33m⚠ $1\033[0m"
}
# 按当前输出级别记录说明信息。
note_echo() {
  log "\033[1;35m➤ $1\033[0m"
}
# 按当前输出级别记录错误信息。
error_echo() {
  log "\033[1;31m✖ $1\033[0m"
}
# 按当前输出级别记录高亮信息。
highlight_echo() {
  log "\033[1;36m🔹 $1\033[0m"
}
# 按当前输出级别记录次要信息。
gray_echo() {
  log "\033[0;90m$1\033[0m"
}
# 打印脚本内置自述，避免误触后直接修改 .gitmodules。
show_script_intro_and_wait() {
  clear 2>/dev/null || true
  print -r -- '============================== 脚本内置自述 ==============================' | jobs_intro_style title
  print -r -- '脚本名称：【MacOS】🧾更新gitmodules.command' | jobs_intro_style title
  print -r -- '核心用途：扫描直属子 Git 并增量补齐 .gitmodules；已有 URL、分支、扩展字段和缺失目录登记均保留。' | jobs_intro_style body
  print -r -- '影响范围：只改写或新建 .gitmodules；不会自动 git add、commit、push，也不会修改子仓库内容。' | jobs_intro_style body
  print -r -- '运行策略：先展示扫描结果和 diff，写入前回车跳过、输入任意字符执行；DRY_RUN=1 仅预览。' | jobs_intro_style body
  print -r -- "日志位置：${LOG_FILE}" | jobs_intro_style body
  print -r -- '取消方式：确认前按 Ctrl+C 终止，不会继续执行后续业务。' | jobs_intro_style body
  print -r -- '============================================================================' | jobs_intro_style title
  [[ "$DRY_RUN" == 1 ]] && return 0
  if [[ ! -t 0 ]]; then
    print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'
    return 1
  fi
  echo "" | jobs_intro_style body
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
}
# 普通更新动作回车跳过，输入任意字符后执行。
ask_enter_to_run() {
  local message="$1"
  local answer=""
  read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
  [[ -n "$answer" ]]
}
# 初始化 Shell 运行选项和日志文件。
initialize_script_runtime() {
  set -e
  set -o pipefail
  setopt NO_NOMATCH
  if [[ "$SCRIPT_FILE" != /* ]]; then
    SCRIPT_FILE="${PWD}/${SCRIPT_FILE}"
  fi
  : > "$LOG_FILE"
}
# 检查当前目录和 Git 命令是否满足刷新条件。
check_environment() {
  local git_root=""

  if ! command -v git >/dev/null 2>&1; then
    error_echo "未找到 git 命令，请先确认 Git 已安装。"
    return 1
  fi

  if [[ ! -d "${REPO_ROOT}/.git" && ! -f "${REPO_ROOT}/.git" ]]; then
    error_echo "脚本所在目录不是 Git 仓库根目录：${REPO_ROOT}"
    return 1
  fi

  git_root="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "$git_root" || "$git_root" != "$REPO_ROOT" ]]; then
    error_echo "脚本必须放在目标 Git 仓库根目录运行：${REPO_ROOT}"
    return 1
  fi
  [[ ! -L "$GITMODULES_FILE" && ( ! -e "$GITMODULES_FILE" || -f "$GITMODULES_FILE" ) ]] || { error_echo '.gitmodules 必须是普通文件。'; return 1; }
  if [[ -f "$GITMODULES_FILE" ]]; then
    git config --file "$GITMODULES_FILE" --list >/dev/null || { error_echo '.gitmodules 语法无效。'; return 1; }
    GITMODULES_CHECKSUM="$(cksum < "$GITMODULES_FILE")"
  else
    GITMODULES_CHECKSUM=absent
  fi
}
# 判断数组中是否包含指定值。
array_contains() {
  local needle="$1"
  shift || true
  local item=""
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}
# 按零字节分隔读取已有映射，保留含空格路径和未设置 branch 的状态。
load_existing_gitmodules() {
  local record="" key="" sub_path="" section="" branch=""
  local -A sections
  EXISTING_SECTION_NAMES=(); EXISTING_BRANCHES=()
  [[ -f "$GITMODULES_FILE" ]] || return 0
  while IFS= read -r -d '' record; do
    key="${record%%$'\n'*}"; sub_path="${record#*$'\n'}"
    section="${key#submodule.}"; section="${section%.path}"
    [[ -n "$sub_path" && -n "$section" && -z "${EXISTING_SECTION_NAMES[$sub_path]:-}" && -z "${sections[$section]:-}" ]] || { error_echo '子模块 section 或 path 为空或重复。'; return 1; }
    EXISTING_SECTION_NAMES[$sub_path]="$section"; sections[$section]="$sub_path"
    branch="$(git config --file "$GITMODULES_FILE" --get "submodule.${section}.branch" 2>/dev/null || true)"
    [[ -z "$branch" ]] || EXISTING_BRANCHES[$sub_path]="$branch"
  done < <(git config --null --file "$GITMODULES_FILE" --get-regexp '^submodule\..*\.path$' 2>/dev/null || true)
}
# 扫描工程根目录第一层真实存在的子 Git 目录。
discover_current_subgit_dirs() {
  local marker=""
  local child_dir=""
  local sub_path=""

  CURRENT_SUBGIT_DIRS=()
  while IFS= read -r -d '' marker; do
    child_dir="$(dirname "$marker")"
    sub_path="${child_dir#${REPO_ROOT}/}"
    [[ "$sub_path" == "$child_dir" ]] && continue
    CURRENT_SUBGIT_DIRS+=("$sub_path")
  done < <(find "$REPO_ROOT" -mindepth 2 -maxdepth 2 \( -type f -name .git -o -type d -name .git \) -print0)

  if [[ ${#CURRENT_SUBGIT_DIRS[@]} -gt 0 ]]; then
    CURRENT_SUBGIT_DIRS=("${(@f)$(printf '%s\n' "${CURRENT_SUBGIT_DIRS[@]}" | sort -u)}")
  fi

  if [[ ${#CURRENT_SUBGIT_DIRS[@]} -eq 0 ]]; then
    error_echo "未在工程根目录第一层发现任何带 .git 的子目录。"
    return 1
  fi
}
# 解析可证明仓库层级的托管地址；本地路径、未知协议和歧义路径不参与相对化。
hosted_url_parts() {
  local value="$1" rest="" authority="" repository_path="" namespace="" repository=""
  [[ -n "$value" && "$value" != *$'\n'* && "$value" != *$'\r'* && "$value" != *$'\t'* && "$value" != *\?* && "$value" != *\#* && "$value" != *\\* ]] || return 1
  case "$value" in
    http://*|https://*|ssh://*)
      rest="${value#*://}"
      [[ "$rest" == */* ]] || return 1
      authority="${rest%%/*}"; repository_path="${rest#*/}"
      if [[ "$value" == ssh://* ]]; then
        [[ "${authority%%@*}" != *:* || "$authority" != *@* ]] || return 1
      else
        [[ "$authority" != *@* ]] || return 1
      fi
      authority="${authority##*@}"
      ;;
    *://*) return 1 ;;
    *:*)
      authority="${value%%:*}"; repository_path="${value#*:}"
      [[ "$authority" != */* && "$authority" != -* && "$repository_path" != /* ]] || return 1
      authority="${authority##*@}"
      ;;
    *) return 1 ;;
  esac
  [[ -n "$authority" && "$authority" != *[[:space:]@/]* && "$repository_path" == */* && "$repository_path" != /* && "$repository_path" != */ && "$repository_path" != *//* ]] || return 1
  [[ "/$repository_path/" != */../* && "/$repository_path/" != */./* && "$repository_path" != '~'* ]] || return 1
  namespace="${repository_path%/*}"; repository="${repository_path##*/}"; repository="${repository%.git}"
  [[ -n "$repository" && "$repository" != . && "$repository" != .. && "$repository" != -* ]] || return 1
  if [[ "$authority" == *:* ]]; then
    authority="${value%%://*}://${authority}"
  fi
  print -rl -- "${(L)authority}" "$namespace" "$repository"
}
# 只有父子所有已配置托管线路逐一同站同命名空间、子仓名称一致时生成共享相对 URL。
relative_submodule_url() {
  local parent_repo="$1" child_repo="$2" selected_url="$3" record="" remote_url="" endpoint="" repository="" key="" repo=""
  local -a parts
  local -A parent_endpoints child_endpoints
  hosted_url_parts "$selected_url" >/dev/null || return 1
  for repo in "$parent_repo" "$child_repo"; do
    while IFS= read -r -d '' record; do
      remote_url="${record#*$'\n'}"
      parts=("${(@f)$(hosted_url_parts "$remote_url")}")
      (( ${#parts} == 3 )) || return 1
      endpoint="${parts[1]}/${parts[2]}"
      if [[ "$repo" == "$parent_repo" ]]; then
        parent_endpoints[$endpoint]=1
      else
        [[ -z "$repository" || "$repository" == "${parts[3]}" ]] || return 1
        repository="${parts[3]}"
        child_endpoints[$endpoint]=1
      fi
    done < <(git -C "$repo" config --local --null --get-regexp '^remote\..*\.url$' 2>/dev/null || true)
  done
  (( ${#parent_endpoints} && ${#parent_endpoints} == ${#child_endpoints} )) || return 1
  for key in "${(@k)parent_endpoints}"; do
    [[ -n "${child_endpoints[$key]:-}" ]] || return 1
  done
  [[ -n "$repository" ]] || return 1
  print -r -- "../${repository}.git"
}
# 优先保留已有 URL；新增登记只读取真实 origin，不根据目录名猜测远端。
read_origin_url_for_subgit() {
  local sub_path="$1" section="${EXISTING_SECTION_NAMES[$1]:-}" url=""
  if [[ -n "$section" ]]; then
    url="$(git config --file "$GITMODULES_FILE" --get "submodule.${section}.url" 2>/dev/null || true)"
  fi
  [[ -n "$url" ]] || url="$(git -C "$REPO_ROOT/$sub_path" remote get-url origin 2>/dev/null || true)"
  [[ -n "$url" && "$url" != -* && "$url" != *$'\n'* && "$url" != *$'\r'* && "$url" != *$'\t'* ]] || return 1
  print -r -- "$url"
}
# 新 section 只记录实际检出的本地分支；游离 HEAD 保持缺省，不猜 main。
read_branch_for_subgit() {
  git -C "$REPO_ROOT/$1" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}
# 收集可写入 .gitmodules 的子 Git 元数据，缺少 URL 的目录只提示并跳过。
collect_submodule_metadata() {
  local sub_path=""
  local url=""
  local branch="" section="" stored_url="" relative_url=""

  WRITABLE_SUBGIT_DIRS=()
  SKIPPED_SUBGIT_DIRS=()
  SUBMODULE_URLS=()
  SUBMODULE_BRANCHES=()
  for sub_path in "${CURRENT_SUBGIT_DIRS[@]}"; do
    url="$(read_origin_url_for_subgit "$sub_path" || true)"
    if [[ -z "$url" ]]; then
      SKIPPED_SUBGIT_DIRS+=("$sub_path")
      continue
    fi

    section="${EXISTING_SECTION_NAMES[$sub_path]:-}"
    stored_url=""
    [[ -z "$section" ]] || stored_url="$(git config --file "$GITMODULES_FILE" --get "submodule.${section}.url" 2>/dev/null || true)"
    if [[ -z "$stored_url" ]]; then
      if relative_url="$(relative_submodule_url "$REPO_ROOT" "$REPO_ROOT/$sub_path" "$url")"; then
        url="$relative_url"
      else
        warn_echo "${sub_path}：远端映射无法统一验证，保留明确原地址。"
      fi
    fi
    branch="${EXISTING_BRANCHES[$sub_path]:-}"
    [[ -n "$section" ]] || branch="$(read_branch_for_subgit "$sub_path")"
    SUBMODULE_URLS[$sub_path]="$url"
    SUBMODULE_BRANCHES[$sub_path]="$branch"
    WRITABLE_SUBGIT_DIRS+=("$sub_path")
  done

  if [[ ${#WRITABLE_SUBGIT_DIRS[@]} -eq 0 ]]; then
    error_echo "没有发现可写入 .gitmodules 的子 Git；请先确认至少一个子目录配置了 origin URL。"
    return 1
  fi
}
# 找出 .gitmodules 中已经不存在于磁盘真实子 Git 目录的旧 path。
collect_stale_gitmodules_paths() {
  local sub_path=""

  STALE_GITMODULE_PATHS=()
  for sub_path in "${(@k)EXISTING_SECTION_NAMES}"; do
    if ! array_contains "$sub_path" "${CURRENT_SUBGIT_DIRS[@]}"; then
      STALE_GITMODULE_PATHS+=("$sub_path")
    fi
  done

  if [[ ${#STALE_GITMODULE_PATHS[@]} -gt 0 ]]; then
    STALE_GITMODULE_PATHS=("${(@f)$(printf '%s\n' "${STALE_GITMODULE_PATHS[@]}" | sort -u)}")
  fi
}
# 打印扫描结果，方便写入前人工确认。
print_scan_report() {
  local sub_path=""

  highlight_echo "============================== 当前真实子 Git 目录 =============================="
  for sub_path in "${CURRENT_SUBGIT_DIRS[@]}"; do
    note_echo "$sub_path"
  done
  highlight_echo "============================================================================="
  echo ""

  highlight_echo "============================== 将写入 .gitmodules 的目录 =============================="
  for sub_path in "${WRITABLE_SUBGIT_DIRS[@]}"; do
    note_echo "${sub_path} -> ${SUBMODULE_URLS[$sub_path]} (${SUBMODULE_BRANCHES[$sub_path]})"
  done
  highlight_echo "=================================================================================="
  echo ""

  if [[ ${#SKIPPED_SUBGIT_DIRS[@]} -gt 0 ]]; then
    warn_echo "以下子 Git 缺少 origin URL，本次不会写入 .gitmodules："
    for sub_path in "${SKIPPED_SUBGIT_DIRS[@]}"; do
      warn_echo "$sub_path"
    done
    echo ""
  fi

  if [[ ${#STALE_GITMODULE_PATHS[@]} -gt 0 ]]; then
    warn_echo "以下 .gitmodules path 暂缺工作目录，保留原有登记："
    for sub_path in "${STALE_GITMODULE_PATHS[@]}"; do
      warn_echo "$sub_path"
    done
    echo ""
  fi
}
# 从原配置增量补齐，避免抹掉相对 URL、缺失目录、分支与扩展字段。
build_gitmodules_file() {
  local target_file="$1" sub_path="" section="" existing_url=""
  if [[ -f "$GITMODULES_FILE" ]]; then cp -p "$GITMODULES_FILE" "$target_file"; else : > "$target_file"; fi
  for sub_path in "${WRITABLE_SUBGIT_DIRS[@]}"; do
    section="${EXISTING_SECTION_NAMES[$sub_path]:-$sub_path}"
    if [[ -z "${EXISTING_SECTION_NAMES[$sub_path]:-}" ]]; then
      git config --file "$target_file" "submodule.${section}.path" "$sub_path"
      [[ -z "${SUBMODULE_BRANCHES[$sub_path]}" ]] || git config --file "$target_file" "submodule.${section}.branch" "${SUBMODULE_BRANCHES[$sub_path]}"
    fi
    existing_url="$(git config --file "$target_file" --get "submodule.${section}.url" 2>/dev/null || true)"
    [[ -n "$existing_url" ]] || git config --file "$target_file" "submodule.${section}.url" "${SUBMODULE_URLS[$sub_path]}"
  done
}
# 打印本次计划写入的 .gitmodules diff。
print_planned_diff() {
  local planned_file="$1"

  highlight_echo "============================== 计划变更 diff =============================="
  if [[ -f "$GITMODULES_FILE" ]]; then
    diff -u "$GITMODULES_FILE" "$planned_file" 2>&1 | tee -a "$LOG_FILE" || true
  else
    cat "$planned_file" | tee -a "$LOG_FILE"
  fi
  highlight_echo "==========================================================================="
}
# 将计划内容写入 .gitmodules，DRY_RUN 模式只打印不落盘。
write_gitmodules_file() {
  local planned_file="$1"

  if [[ "$DRY_RUN" == "1" ]]; then
    warn_echo "DRY_RUN=1，本次只预览，不写入 .gitmodules。"
    return 0
  fi

  local current_checksum=absent
  [[ ! -f "$GITMODULES_FILE" ]] || current_checksum="$(cksum < "$GITMODULES_FILE")"
  [[ "$current_checksum" == "$GITMODULES_CHECKSUM" ]] || { error_echo '.gitmodules 在预览后变化，请重新运行。'; return 1; }
  cp "$planned_file" "$GITMODULES_FILE"
  success_echo '.gitmodules 已增量补齐，原有登记和字段保留。'
}
# 打印刷新后的 Git 状态和 .gitmodules 差异。
print_final_report() {
  highlight_echo "============================== 当前 .gitmodules diff =============================="
  if git -C "$REPO_ROOT" ls-files --error-unmatch .gitmodules >/dev/null 2>&1; then
    git -C "$REPO_ROOT" diff -- .gitmodules 2>&1 | tee -a "$LOG_FILE" || true
  else
    warn_echo ".gitmodules 当前还没有被 Git 跟踪，下面是本次生成内容："
    cat "$GITMODULES_FILE" | tee -a "$LOG_FILE"
  fi
  highlight_echo "================================================================================"
  echo ""
  highlight_echo "============================== 当前 git status =============================="
  git -C "$REPO_ROOT" status --short 2>&1 | tee -a "$LOG_FILE" || true
  highlight_echo "==========================================================================="
  note_echo "日志文件：${LOG_FILE}"
}
# 执行预览、确认和写入 .gitmodules 的核心流程。
run_business() {
  local planned_file=""

  planned_file="$(mktemp "/tmp/${SCRIPT_BASENAME}.gitmodules.XXXXXX")"
  build_gitmodules_file "$planned_file"
  print_scan_report
  print_planned_diff "$planned_file"

  if [[ -f "$GITMODULES_FILE" ]] && cmp -s "$GITMODULES_FILE" "$planned_file"; then
    success_echo ".gitmodules 已经和当前可写入的子 Git 目录一致，无需更新。"
    rm -f "$planned_file"
    return 0
  fi

  if [[ "$DRY_RUN" == 1 ]]; then
    warn_echo 'DRY_RUN=1，只预览，不写入 .gitmodules。'
    rm -f "$planned_file"
    return 0
  fi
  echo ""
  if ! ask_enter_to_run "确认按上述增量计划更新 .gitmodules 吗？"; then
    warn_echo "用户选择跳过 .gitmodules 更新。"
    rm -f "$planned_file"
    return 0
  fi

  write_gitmodules_file "$planned_file"
  if [[ "$DRY_RUN" == "1" ]]; then
    rm -f "$planned_file"
    return 0
  fi
  rm -f "$planned_file"
  print_final_report
}
# 编排脚本的高层业务流程。
main() {
  show_script_intro_and_wait # 展示脚本内置自述，并完成第一层防误触确认。
  initialize_script_runtime # 初始化 Shell 选项和日志，确保后续命令失败能及时中断。
  check_environment # 检查 Git 命令和脚本所在仓库根目录是否可用。
  load_existing_gitmodules # 读取旧配置，用于保留已有 section 名和分支配置。
  discover_current_subgit_dirs # 扫描根目录第一层真实存在的子 Git 目录。
  collect_submodule_metadata # 收集每个可写入子 Git 的 URL 和分支。
  collect_stale_gitmodules_paths # 识别暂缺目录并保留旧登记。
  run_business # 展示增量计划，确认后仅补齐缺失字段。
}

main "$@"
