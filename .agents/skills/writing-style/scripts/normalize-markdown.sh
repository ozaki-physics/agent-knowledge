#!/usr/bin/env bash
# エラー、未定義変数、パイプライン中の失敗を検出したら終了する。
set -euo pipefail

# 使用方法を表示する。
usage() {
  cat <<'USAGE'
使い方:
  normalize-markdown.sh --in-place INPUT.md [INPUT.md ...]
  normalize-markdown.sh --output OUTPUT.md INPUT.md
  normalize-markdown.sh --output-dir DIRECTORY INPUT.md [INPUT.md ...]

出力方法:
  --in-place          入力ファイルを直接更新する
  --output FILE       1つの入力を指定したファイルへ出力する
  --output-dir DIR    入力を指定したディレクトリへ同名で出力する

コードフェンスとインラインコードの中は置換しない。
USAGE
}

# エラーメッセージを表示して終了する。
die() {
  echo "エラー: $*" >&2
  exit 1
}

# 1つのMarkdownファイルを正規化して出力先へ書き出す。
normalize_file() {
  local input_file="$1"
  local output_file="$2"
  local temporary_file

  temporary_file="$(mktemp)"
  # 関数の途中で失敗しても一時ファイルを残さない。
  trap 'rm -f "$temporary_file"' RETURN

  # Bash の引数処理と独立させた Markdown の行変換を awk へ委譲する。
  awk -f "$script_dir/normalize-markdown.awk" "$input_file" > "$temporary_file"

  # 出力先の親ディレクトリを作成してから、変換済みの内容を配置する。
  mkdir -p "$(dirname "$output_file")"
  cp "$temporary_file" "$output_file"
  trap - RETURN
  rm -f "$temporary_file"
}

# コマンドライン引数を解釈して対象ファイルを正規化する。
main() {
  local mode=""
  local output=""
  local output_dir=""
  local input
  local destination
  local -a inputs=()

  # 出力方法と入力ファイルを分けて受け取り、後段の検証を単純にする。
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --in-place)
        [ -z "$mode" ] || die "出力方法は1つだけ指定してください"
        mode="in-place"
        shift
        ;;
      --output)
        [ -z "$mode" ] || die "出力方法は1つだけ指定してください"
        [ "$#" -ge 2 ] || die "--output には出力ファイルが必要です"
        mode="output"
        output="$2"
        shift 2
        ;;
      --output-dir)
        [ -z "$mode" ] || die "出力方法は1つだけ指定してください"
        [ "$#" -ge 2 ] || die "--output-dir には出力ディレクトリが必要です"
        mode="output-dir"
        output_dir="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        inputs+=("$@")
        break
        ;;
      -*)
        die "不明なオプションです: $1"
        ;;
      *)
        inputs+=("$1")
        shift
        ;;
    esac
  done

  [ -n "$mode" ] || die "--in-place, --output, --output-dir のいずれかを指定してください"
  [ "${#inputs[@]}" -gt 0 ] || die "入力ファイルを指定してください"
  if [ "$mode" = "output" ] && [ "${#inputs[@]}" -ne 1 ]; then
    die "--output で指定できる入力ファイルは1つだけです"
  fi

  # 入力の妥当性を確認してから、出力先を決めて1ファイルずつ処理する。
  for input in "${inputs[@]}"; do
    [ -f "$input" ] || die "入力ファイルがありません: $input"
    case "$input" in
      *.md|*.markdown) ;;
      *) die "Markdown ファイルだけを指定してください: $input" ;;
    esac

    case "$mode" in
      in-place) destination="$input" ;;
      output) destination="$output" ;;
      output-dir) destination="${output_dir%/}/$(basename "$input")" ;;
    esac

    normalize_file "$input" "$destination"
    echo "正規化しました: $input -> $destination"
  done
}

# このスクリプト自身の場所から awk ファイルを常に解決できるようにする。
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# 引数の解釈から実行までの入口を1か所にする。
main "$@"
