---
name: writing-style
description: >
  僕の文章スタイルでMarkdownを書く、既存文章を僕の書き方へ直す、またはMarkdownを機械的に正規化するスキル。
  「僕のスタイルで書いて」「writing-style」「Markdownをフォーマットして」「全角括弧や全角スペースを直して」などの依頼で使う。
---

# writing-style

依頼に応じて 次の処理を選ぶ。
このスキルは 登壇資料やブログ記事など ではなく 日常的なメモ・ドキュメント向けのスタイル。
普段のマークダウン文章スタイルでテキストを生成する。
登壇資料やブログ記事などの文章スタイルは このスキルをベースにしつつ 依頼に応じて別のスキルを使う。

## 新しく文章を書く または 内容を推敲する

`references/style-guide.md` を読み 文章へスタイルを反映する。
既存ファイルを編集した場合は 差分を確認する。

## Markdown を機械的に正規化する

文章の意味を判断する必要がなければ `scripts/normalize-markdown.sh` を使う。
この処理だけなら `references/style-guide.md` は読まない。

出力方法を明示して実行する。

```bash
# 原本を直接更新する
bash <skill-dir>/scripts/normalize-markdown.sh --in-place path/to/input.md

# 出力ファイルを指定して複製する
bash <skill-dir>/scripts/normalize-markdown.sh --output ./assets/input.md path/to/input.md

# 1つ以上の入力を指定したディレクトリへ同名で複製する
bash <skill-dir>/scripts/normalize-markdown.sh --output-dir ./assets path/to/input.md path/to/other.md
```

`--in-place`, `--output`, `--output-dir` のどれを使うか不明な場合は 原本を変更せずユーザーへ確認する。
複製を指示された場合は `--output` または `--output-dir` を使う。

スクリプトは 次の置換だけを行う。

- 全角スペースを半角スペースにする
- 全角括弧 `（）` を半角括弧 `()` にする
- 全角ハイフン `—` `―` を半角ハイフン `-` にする
- 矢印 `→` を `->` にする
- ファイル末尾の改行を1つにする

コードフェンス と インラインコードの中は置換しない。
既存の行末半角スペース2個は保持し 全行へ新しく追加しない。
`「」`, `『』`, `【】`, 句読点など 文脈判断が必要な記号は機械的に置換しない。

## 内容の修正と機械的な正規化を両方行う

先に `references/style-guide.md` を読んで内容を編集する。
その後 明示された出力方法で正規化スクリプトを実行して 差分または出力ファイルを確認する。
