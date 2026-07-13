#!/usr/bin/env bash
# エラーが発生した場合にスクリプトを終了
# 未定義の変数の使用を禁止
# パイプライン内のコマンドが失敗した場合にスクリプトを終了する設定
set -euo pipefail

# このスクリプトの使い方を表示する関数
usage() {
  cat <<'USAGE'
使い方:
  link_agents_assets.sh [options]

目的:
  .agents 配下の skills, subagents, instructions, prompts をリンク元として扱い、
  .codex, .github, .claude, ホームディレクトリ など 任意のディレクトリへ シンボリックリンクで配置する。
  コピーではなくリンクで配置することで、実体の管理場所を .agents に集約する。

オプション:
  --profile repo|codex|claude|github|agents|custom
  --target PATH
  --type skills|subagents|instructions|prompts|all
  --name NAME[,NAME...]      リンク元の名前で絞り込む。複数回指定できる。
  --list                     リンク状態を一覧表示する。
  --remove                   このスクリプトが扱う位置のシンボリックリンクを削除する。
  --force                    既存シンボリックリンクを張り替える。実ファイルはスキップする。
  --dry-run                  ファイルを変更せず、実行予定だけ表示する。
  -h, --help                 このヘルプを表示する。

実行例:
  # リポジトリ内の代表的なリンク状態を確認
  link_agents_assets.sh --profile repo --list

  # リポジトリ内に代表的なリンクを作成
  link_agents_assets.sh --profile repo

  # Codex 用の skills を任意の .codex ディレクトリへ配置
  link_agents_assets.sh --profile codex --target /path/to/project --type skills

  # Claude 用にホームディレクトリへ配置
  link_agents_assets.sh --profile claude --target ~

  # GitHub Copilot 用の instructions を明示的に配置
  link_agents_assets.sh --profile github --target /path/to/project --type instructions

  # Claude と GitHub Copilot 用の prompts をリポジトリ内へ配置
  link_agents_assets.sh --profile repo --type prompts

  # 特定の skill だけ配置予定を確認
  link_agents_assets.sh --profile codex --target ~ --type skills --name link-agents-assets --dry-run

  # このスクリプトで作る位置のシンボリックリンクだけ削除
  link_agents_assets.sh --profile claude --target ~ --remove
USAGE
}

# スクリプト自身の場所から リポジトリルート を推定する
# 想定する配置は .agents/skills/link-agents-assets/scripts/link_agents_assets.sh
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../../../.." && pwd -P)"

# リンク先の構造を選ぶ profile
# デフォルトでは リポジトリ内の代表的なリンク先を扱う
profile="repo"
# リンク先の起点ディレクトリ
# 未指定の場合は profile に応じて後で補完する
target=""
# リンク対象の種類
# all の場合は skills, subagents, instructions, prompts を順番に処理する
type_filter="all"
# リンク状態を一覧表示するフラグ
list_mode=0
# シンボリックリンクを削除するフラグ
remove_mode=0
# 既存シンボリックリンクを張り替えるフラグ
force_mode=0
# 実際には変更せず 実行予定だけを表示するフラグ
dry_run=0
# --name で指定された 対象名の絞り込み条件
names=()

# 値を必要とするオプションに 値が渡されているか確認する関数
require_value() {
  local option="$1"
  local value="${2-}"
  if [[ -z "$value" ]]; then
    echo "$option には値が必要です" >&2
    exit 2
  fi
  printf '%s\n' "$value"
}

# --name の値を カンマ区切り または 複数指定 のどちらでも扱えるように配列へ追加する関数
add_names() {
  local raw="$1"
  local part
  local -a parts
  IFS=',' read -ra parts <<< "$raw"
  for part in "${parts[@]}"; do
    part="${part#"${part%%[![:space:]]*}"}"
    part="${part%"${part##*[![:space:]]}"}"
    if [[ -n "$part" ]]; then
      names+=("$part")
    fi
  done
}

# コマンドライン引数を解析して フラグや設定値を更新する関数
parse_args() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        profile="$(require_value "$1" "${2-}")"
        shift 2
        ;;
      --target)
        target="$(require_value "$1" "${2-}")"
        shift 2
        ;;
      --type)
        type_filter="$(require_value "$1" "${2-}")"
        shift 2
        ;;
      --name)
        add_names "$(require_value "$1" "${2-}")"
        shift 2
        ;;
      --list)
        list_mode=1
        shift
        ;;
      --remove)
        remove_mode=1
        shift
        ;;
      --force)
        force_mode=1
        shift
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "不明なオプションです: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done
}

# profile と type が対応している値か確認する関数
validate_options() {
  case "$profile" in
    repo|codex|claude|github|agents|custom) ;;
    *)
      echo "未対応の profile です: $profile" >&2
      exit 2
      ;;
  esac

  case "$type_filter" in
    skills|subagents|instructions|prompts|all) ;;
    *)
      echo "未対応の type です: $type_filter" >&2
      exit 2
      ;;
  esac
}

# profile に応じて target を決め 絶対パスへ変換する関数
resolve_target() {
  if [[ -z "$target" ]]; then
    if [[ "$profile" == "repo" ]]; then
      target="$repo_root"
    else
      target="$PWD"
    fi
  fi

  # 絶対パスで始まっていないなら シェルスクリプトを実行した場所を PWD として パスを作る
  # --target ~/.claude のように ~ で書かれたときは 絶対パスに展開されて から シェルスクリプトが実行される
  if [[ "$target" != /* ]]; then
    target="$PWD/$target"
  fi

  # 末尾のスラッシュを取り除いて 出力や結合結果を安定させる
  target="${target%/}"

  # ツール固有 profile は target を親ディレクトリとして受け取り、
  # 対応するツール固有ディレクトリを自動的に補完する。
  # 既に固有ディレクトリまで指定されている場合は二重に追加しない。
  case "$profile" in
    codex)
      [[ "$target" == */.codex ]] || target="$target/.codex"
      ;;
    claude)
      [[ "$target" == */.claude ]] || target="$target/.claude"
      ;;
    github)
      [[ "$target" == */.github ]] || target="$target/.github"
      ;;
    agents)
      [[ "$target" == */.agents ]] || target="$target/.agents"
      ;;
  esac
}

# --name で絞り込みが指定されている場合に 対象名が一致するか確認する関数
# ディレクトリ名や拡張子付きファイル名のどちらでも指定できるようにする
name_matches() {
  local name="$1"
  local file_name="$2"
  local filter
  if [[ ${#names[@]} -eq 0 ]]; then
    return 0
  fi
  for filter in "${names[@]}"; do
    if [[ "$filter" == "$name" || "$filter" == "$file_name" ]]; then
      return 0
    fi
  done
  return 1
}

# リンク先の現在状態を判定する関数
# symlink: シンボリックリンク
# exists : 実ファイルまたは実ディレクトリ
# none   : 未配置
status_of() {
  local path="$1"
  if [[ -L "$path" ]]; then
    echo "symlink"
  elif [[ -e "$path" ]]; then
    echo "exists"
  else
    echo "none"
  fi
}

# profile と kind の組み合わせから 実際のリンク先パスを出力する関数
# 1つのリンク元から 複数のリンク先を出力する profile もある
emit_destinations() {
  local kind="$1"
  local name="$2"
  local file_name="$3"

  case "$profile:$kind" in
    repo:skills)
      # Codex と VS Code は .agents/skills を直接探索できるため Claude Code 用だけ配置する
      printf '%s\n' "$target/.claude/skills/$name"
      ;;
    repo:subagents)
      printf '%s\n' "$target/.claude/agents/$file_name"
      ;;
    repo:prompts)
      printf '%s\n' "$target/.claude/commands/$name.md"
      printf '%s\n' "$target/.github/prompts/$name.prompt.md"
      ;;
    repo:instructions)
      if [[ "$file_name" == "AGENTS.md" ]]; then
        printf '%s\n' "$target/AGENTS.md"
      fi
      ;;
    codex:skills)
      printf '%s\n' "$target/skills/$name"
      ;;
    claude:skills)
      printf '%s\n' "$target/skills/$name"
      ;;
    claude:subagents)
      printf '%s\n' "$target/agents/$file_name"
      ;;
    claude:prompts)
      printf '%s\n' "$target/commands/$name.md"
      ;;
    claude:instructions)
      if [[ "$file_name" == "AGENTS.md" || "$file_name" == "CLAUDE.md" ]]; then
        # .agents の共通指示ファイル AGENTS.md は Claude 用に CLAUDE.md として公開する
        printf '%s\n' "$target/CLAUDE.md"
      fi
      ;;
    github:skills)
      # .agents/skills を直接利用できない環境向けに --type skills の明示指定時だけ配置する
      if [[ "$type_filter" == "skills" ]]; then
        printf '%s\n' "$target/skills/$name"
      fi
      ;;
    github:subagents)
      printf '%s\n' "$target/agents/$file_name"
      ;;
    github:prompts)
      printf '%s\n' "$target/prompts/$name.prompt.md"
      ;;
    github:instructions)
      # --type instructions を明示した場合だけ copilot-instructions.md を配置する
      if [[ "$type_filter" == "instructions" && "$file_name" == "AGENTS.md" ]]; then
        printf '%s\n' "$target/copilot-instructions.md"
      fi
      ;;
    agents:*|custom:*)
      printf '%s\n' "$target/$kind/$file_name"
      ;;
  esac
}

# 処理対象にする kind の一覧を出力する関数
collect_kinds() {
  if [[ "$type_filter" == "all" ]]; then
    printf '%s\n' skills subagents instructions prompts
  else
    printf '%s\n' "$type_filter"
  fi
}

# kind と profile に応じて処理対象のリンク元を出力する関数
collect_sources() {
  local kind="$1"
  local source_dir="$repo_root/.agents/$kind"

  if [[ "$kind" == "skills" ]]; then
    find "$source_dir" -mindepth 1 -maxdepth 1 -type d
    return
  fi

  if [[ "$kind" == "subagents" ]]; then
    case "$profile" in
      repo|claude)
        find "$source_dir" -mindepth 1 -maxdepth 1 -type f -name '*.md'
        if [[ -d "$source_dir/claude" ]]; then
          find "$source_dir/claude" -mindepth 1 -maxdepth 1 -type f -name '*.md'
        fi
        ;;
      github)
        # 共通定義は GitHub Copilot が .agents から直接読むため 固有定義だけを配置する
        if [[ -d "$source_dir/github" ]]; then
          find "$source_dir/github" -mindepth 1 -maxdepth 1 -type f -name '*.agent.md'
        fi
        ;;
      *)
        find "$source_dir" -mindepth 1 -maxdepth 1 -type f
        ;;
    esac
    return
  fi

  find "$source_dir" -mindepth 1 -maxdepth 1 -type f
}

# 配置先で同名になる subagent がないことを処理前に確認する関数
validate_subagent_sources() {
  local source
  local subagent_name
  local -A source_by_name=()

  while IFS= read -r source; do
    subagent_name="$(basename "$source")"
    if [[ -n "${source_by_name[$subagent_name]-}" ]]; then
      echo "subagent の名前が重複しています: $subagent_name" >&2
      echo "  ${source_by_name[$subagent_name]}" >&2
      echo "  $source" >&2
      exit 2
    fi
    source_by_name["$subagent_name"]="$source"
  done < <(collect_sources "subagents" | sort)
}

# シンボリックリンクを作成する関数
# 実ファイルや実ディレクトリが既にある場合は 上書きせずにスキップする
create_link() {
  local source="$1"
  local destination="$2"
  local link_source
  local status
  status="$(status_of "$destination")"

  # リポジトリを別の場所へ clone / move してもリンクが壊れないよう リンク先ディレクトリから見た相対パスを記録する。
  link_source="$(realpath -m --relative-to="$(dirname "$destination")" "$source")"

  # 既にシンボリックリンクがある場合は --force のときだけ張り替える
  if [[ "$status" == "symlink" ]]; then
    if [[ "$force_mode" -ne 1 ]]; then
      echo "スキップ $destination (既にシンボリックリンクです。張り替える場合は --force を指定してください)"
      return
    fi
    if [[ "$dry_run" -eq 1 ]]; then
      echo "張り替え予定 $destination -> $link_source"
      return
    fi
    unlink "$destination"
  elif [[ "$status" == "exists" ]]; then
    # 実ファイルや実ディレクトリは ユーザーの作業物である可能性があるため削除しない
    echo "スキップ $destination (実ファイルまたは実ディレクトリが存在するためスキップします)"
    return
  fi

  # dry-run の場合は 実際には作成せず 予定だけを表示する
  if [[ "$dry_run" -eq 1 ]]; then
    echo "作成予定 $destination -> $link_source"
    return
  fi

  mkdir -p "$(dirname "$destination")"
  ln -s "$link_source" "$destination"
  echo "作成 $destination -> $link_source"
}

# シンボリックリンクを削除する関数
# リンク元の実体は削除しない
remove_link() {
  local destination="$1"
  local status
  status="$(status_of "$destination")"

  # 何もない場合は 削除せずにスキップする
  if [[ "$status" == "none" ]]; then
    echo "スキップ $destination (存在しません)"
    return
  fi
  # 実ファイルや実ディレクトリは削除しない
  if [[ "$status" != "symlink" ]]; then
    echo "スキップ $destination (シンボリックリンクではないため削除しません)"
    return
  fi
  # dry-run の場合は 実際には削除せず 予定だけを表示する
  if [[ "$dry_run" -eq 1 ]]; then
    echo "削除予定 $destination"
    return
  fi
  unlink "$destination"
  echo "削除 $destination"
}

# リンク先1件に対して list, remove, link のいずれかを実行する関数
process_destination() {
  local kind="$1"
  local name="$2"
  local source="$3"
  local destination="$4"
  local marker

  if [[ "$list_mode" -eq 1 ]]; then
    case "$(status_of "$destination")" in
      symlink) marker='[L]' ;;
      exists) marker='[F]' ;;
      none) marker='[ ]' ;;
    esac
    printf '%s %-12s %-28s -> %s\n' "$marker" "$kind" "$name" "$destination"
  elif [[ "$remove_mode" -eq 1 ]]; then
    remove_link "$destination"
  else
    create_link "$source" "$destination"
  fi
}

# リンク元1件に対して 対象 profile のリンク先を処理する関数
# list, remove, link のどの動作を行うかは フラグで切り替える
process_item() {
  local kind="$1"
  local source="$2"
  local file_name
  local name
  local destination

  # skills はディレクトリ名を名前として扱う
  # それ以外はファイル名から拡張子を除いたものを名前として扱う
  file_name="$(basename "$source")"
  if [[ "$kind" == "skills" ]]; then
    name="$file_name"
  elif [[ "$profile:$kind" == "github:subagents" ]]; then
    name="${file_name%.agent.md}"
  else
    name="${file_name%.*}"
  fi

  # --name の絞り込みに一致しないリンク元は処理しない
  if ! name_matches "$name" "$file_name"; then
    return
  fi
  # profile に応じたリンク先を1件ずつ処理する
  while IFS= read -r destination; do
    [[ -n "$destination" ]] || continue
    # 少なくとも1件のリンク先が処理対象になったことを記録する
    matched=1
    process_destination "$kind" "$name" "$source" "$destination"
  done < <(emit_destinations "$kind" "$name" "$file_name")
}

# 実行対象の情報を表示する関数
print_context() {
  echo "リポジトリ: $repo_root"
  echo "profile   : $profile"
  echo "配置先    : $target"
}

# .agents 配下からリンク元を収集して処理する関数
process_sources() {
  local kind
  local source
  local source_dir

  # シェルの グローバル変数として定義
  matched=0

  # collect_kinds の出力を1行ずつ読み込んで kind に代入
  while IFS= read -r kind; do
    source_dir="$repo_root/.agents/$kind"
    # ディレクトリの存在を確認して なければ スキップ
    [[ -d "$source_dir" ]] || continue

    if [[ "$kind" == "subagents" ]]; then
      validate_subagent_sources
    fi

    while IFS= read -r source; do
      process_item "$kind" "$source"
    done < <(collect_sources "$kind" | sort)
  done < <(collect_kinds)

  if [[ "$matched" -eq 0 ]]; then
    echo "一致するリンク元がありません。"
  fi
}

# スクリプト全体の処理順を定義する関数
main() {
  parse_args "$@"
  validate_options
  resolve_target
  print_context
  process_sources
}

# 実行部分
main "$@"
