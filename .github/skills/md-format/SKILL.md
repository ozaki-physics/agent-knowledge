---
name: md-format
description: このスキルは markdown file をフォーマットしたいときに使う, markdown file に対して"フォーマットして", "改行入れて", "半角スペース入れて"と言及したときに起動する
---

# markdown file フォーマット

このスキルは markdown file に対して 以下の内容をフォーマットするときに使う。
markdown file 以外であれば 処理しない。
複数のファイルがあるときは 1ファイルずつ実施して 対応するファイルを ./assets に格納する。


- 全角のカッコ があれば 半角のカッコ にする
- 全角スペース があれば 半角スペース にする
- 行末に 半角スペースが2個なければ 半角スペース2個を入れる

## トリガー条件
- 編集対象が markdown file

## ステップ01

全角のカッコ があれば 半角のカッコ にする

実行スクリプト: `./.github/skills/md-format/scripts/bracket_slimmer.sh`

実行例:
```
mkdir -p ./assets
./.github/skills/md-format/scripts/bracket_slimmer.sh path/to/input.md ./assets/input.brackets.md
```

## ステップ02

全角スペース があれば 半角スペース にする

実行スクリプト: `./.github/skills/md-format/scripts/whitespace_normalizer.sh`

実行例:
```
./.github/skills/md-format/scripts/whitespace_normalizer.sh ./assets/input.brackets.md ./assets/input.spaces.md
```

## ステップ03

行の末尾に 半角スペース 2個入れる

実行スクリプト: `./.github/skills/md-format/scripts/line_end_two_space.sh`

実行例:
```
./.github/skills/md-format/scripts/line_end_two_space.sh ./assets/input.spaces.md ./assets/input.final.md
```

## ステップ04

指示されたファイルに対応する 変換後のファイルがそれぞれあるか確認する
対応するファイルのパスを 出力する
中間ファイルは削除して 入力ファイルと出力ファイルのみ保持する
