# Design Document の目次

## 運用
- 運用ドキュメント は `docs/design-docs/` 配下で管理する
- ファイル分割は "読みやすさ" と "変更しやすさ" を優先して決める
- 小さな機能は 1ファイルにまとめてよい
- 大きな機能や長期運用の対象は `概要` と `詳細` (API / DB / フロー / エラー設計 など) に分割してよい
- 新しい設計ドキュメントを追加したら この目次に追記する

## 書き方
- 最低限 `何をどう実装するか` が分かるように書く
- 先頭は 自由記述でよい (`対象 / 目的 / 更新日` は 必要なときだけ書く)
- まず 結論(採用案)を短く書く
- 詳細(API / DB / フロー / エラー設計 など) は 必要なものだけ書く
- 1ファイルが 長くなったら分割し 相互リンクにする

## ADR との違い
- design-docs は "どう実装するか" を記録する
- ADR(`docs/ard`) は "なぜ その方針を選んだか" を記録する
- 方針決定が必要なテーマは ADR を先に作成して 実装詳細を design-docs に落とし込む

## 目次
- [index](./coding-think-mind.md): コーディング思想
- [deployment-guide](./deployment-guide.md): deploy手順 (開発(development) / 検証(staging) / 本番(production), Docker コンテナ)
- [error-design](./error-design.md): エラー設計
