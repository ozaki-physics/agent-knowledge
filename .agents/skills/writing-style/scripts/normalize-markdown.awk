# このファイルは normalize-markdown.sh から `awk -f` で実行される。
#
# awk は入力を1行ずつ読み込み、各行を次の順序で処理する。
#
# 1. コードフェンスの開始・終了を判定する。
# 2. フェンス内なら行を一切変更せず出力する。
# 3. フェンス外なら、インラインコードを保護しながら本文だけを変換する。
# 4. 空行をいったん保留し、ファイル末尾の余分な空行を除いて出力する。
#
# このファイル内の変数は、awk の仕様により最初に値を代入した時点で自動的に初期化される。
# in_fence や pending_blank_lines の初期値を明示していないのは、その awk の挙動を利用しているためである。

# 通常テキストにだけ、意味を変えない機械的な文字置換を適用する。
function normalize_text(text) {
  gsub(/　/, " ", text)
  gsub(/（/, "(", text)
  gsub(/）/, ")", text)
  gsub(/—/, "-", text)
  gsub(/―/, "-", text)
  gsub(/→/, "->", text)
  return text
}

# インラインコードを保持し、コード外のテキストだけを正規化する。
#
# Markdown のインラインコードは、通常1個以上のバッククォートで始まり、
# 同じ長さのバッククォートで終わる。例えば次のような入力を考える。
#
#   変換対象 `（そのまま保持）` 変換対象
#
# match() でバッククォートのまとまりを順番に探し、コード開始前の文字列だけを normalize_text() に渡す
# コード中の文字列は置換せず、そのまま result に連結することで、コード内の記号を保護している。
#
# inline_code_marker は awk 全体で共有する状態である。
# 開始マーカーを行末で 見つけた場合も次の行へ保持するため、複数行にまたがるコードスパンを保護できる。
function normalize_outside_inline_code(line,    result, rest, marker, marker_length, marker_position, before_marker) {
  result = ""
  rest = line

  while (match(rest, /`+/)) {
    # RSTART と RLENGTH は、match() が見つけた文字列の位置と長さである。
    marker_position = RSTART
    marker_length = RLENGTH
    before_marker = substr(rest, 1, marker_position - 1)
    marker = substr(rest, marker_position, marker_length)

    if (inline_code_marker == "") {
      # コード開始前の本文だけを変換し、開始マーカー自体は保持する。
      result = result normalize_text(before_marker) marker
      inline_code_marker = marker
    } else if (marker == inline_code_marker) {
      # 開始時と同じバッククォート列ならコードの終端とみなす。
      # コードの中身と終端マーカーは変更しない。
      result = result before_marker marker
      inline_code_marker = ""
    } else {
      # コード中に別の長さのバッククォート列があっても、終端とはみなさない。
      result = result before_marker marker
    }

    # 処理済みのマーカーまでを rest から取り除き、次のマーカーを探す。
    rest = substr(rest, marker_position + marker_length)
  }

  if (inline_code_marker == "") {
    # 行の残りが本文なら、最後の部分も変換して返す。
    return result normalize_text(rest)
  }

  # 閉じるマーカーがない行は、残り全体をコードとして保持する。
  return result rest
}

# コードフェンスの開始または終了を表すバッククォート列・チルダ列を返す。
# 戻り値は見つかったマーカー全体（例: ``` や ~~~~）である。見つからない場合は空文字列を返す。
# 呼び出し側は、この値の先頭文字と長さを使って、開始したフェンスに対応する終了フェンスかどうかを判定する。
function fence_marker(line,    candidate) {
  # Markdown ではコードフェンスの前にインデントを置ける。
  # 行頭にある半角スペース(3個まで)があっても フェンスの判定対象にする。
  candidate = line
  sub(/^ {0,3}/, "", candidate)

  # バッククォートまたはチルダが3個以上連続する場合をフェンスとする。
  if (match(candidate, /^`{3,}/)) return substr(candidate, RSTART, RLENGTH)
  if (match(candidate, /^~{3,}/)) return substr(candidate, RSTART, RLENGTH)
  return ""
}

# 保留している空行を出力する。
# 空行を見つけた時点では出力せず、次に本文が現れたときに出力する。
# これにより、本文の後ろに連続する空行だけをファイル末尾の余分な空行として捨てられる。
function flush_pending_blank_lines() {
  while (pending_blank_lines > 0) {
    print ""
    pending_blank_lines--
  }
}

# 変換済みの行を出力し、ファイル末尾の余分な空行は捨てるため
# awk の print は、出力した各行の末尾に改行を1つ付ける。
# 空行を保留することで、入力末尾の改行文字の数ではなく「空の行」の数を制御できる。
function emit_line(line) {
  if (line == "") {
    # すぐには出力せず、後続に本文があるか確認できるまで数える。
    pending_blank_lines++
    return
  }

  # 本文が続く場合は、ここまで保留していた空行を本文の前に戻す。
  flush_pending_blank_lines()
  print line
  # END ブロックで、入力に本文があったか判定するためのフラグ。
  wrote_content = 1
}

{
  # $0 は awk が現在読み込んでいる1行全体を表す。
  # まずフェンスを判定し、本文の文字置換より先にコード領域を確定する。
  marker = fence_marker($0)

  if (!in_fence && marker != "") {
    # フェンス外でマーカーを見つけたら、コードフェンスの開始とみなす。
    # 開始記号の種類と長さを保持し、対応する終了記号だけを認識する。
    in_fence = 1
    fence_character = substr(marker, 1, 1)
    fence_length = length(marker)
    # 開始行自体もコードの一部なので、変換せずに出力する。
    emit_line($0)
    next
  }

  if (in_fence) {
    # コードフェンス内の行は、全角文字や矢印を含めてそのまま保持する。
    emit_line($0)
    # 開始時と同じ記号で、同じ長さ以上の記号が現れたらフェンスを閉じる。
    if (marker != "" && substr(marker, 1, 1) == fence_character && length(marker) >= fence_length) {
      in_fence = 0
    }
    next
  }

  # フェンス外では、インラインコードを除いた通常本文だけを変換する。
  emit_line(normalize_outside_inline_code($0))
}

END {
  # 入力に本文がなかった場合でも、出力を空ファイルにはせず、改行1つにする。
  # 本文がある場合、末尾に残った pending_blank_lines は意図的に出力しない。
  if (!wrote_content) print ""
}
