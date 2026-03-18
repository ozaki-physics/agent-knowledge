# scrap note
## 概要
気になったこと や メモ書き を 置いておく

### ディレクトリのコピー
`cp -r <コピー元> <コピー先>`
### Linux の シンボリックリンク の作り方
`ln -s 元のパス 作りたい名前`
`ln -s "/mnt/c/Users/Owner/My Documents/github_repository" ~/win-github_repository`

`pwd -P` で シンボリックリンク の 元の物理的な場所を確認できる
### codex の skill を 一元管理 できるようになった!
方法は Windows の シンボリックリンク を使うこと
管理者権限 で 以下のようなコマンドを実行する
`New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.codex\skills\hello" -Target "$env:USERPROFILE\source\repos\temp\hello"`
これで 対象ディレクトリにいない リポジトリで管理している スキル を 対象ディレクトリにいるかのように 扱うことができる

よくある Windows の リンク(.lnk)では ただのファイルで 対象ディレクトリに入れても認識してくれない
OS レベルで解決される透明な参照にする必要がある

codex 側を全部 シンボリックリンク にして 外部に出して それを git 管理したらいいのかな?w
`New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\source\repos\temp\skills" -Target "$env:USERPROFILE\.codex\skills"`

気をつけないといけないのは コピーじゃないから 消したら 大元も全部消えること笑

実証実験 は 終わったけど ちゃんと管理するのは ちょっと手間がかかるので 一旦放置する
skills も 増えると Context を 圧迫するから 気をつけないといけない
必要な場所で 必要な量だけの Context を与えること
codex って 各リポジトリ の skills を参照できないのかな?
-> 見れるじゃん! `リポジトリ\.codex\skills\hello\SKILL.md`
これで リポジトリごとで使いまわしたい系 と 僕として使いまわしたい系 が 分けられる
僕として使いまわしたい系 も git 管理できるし codex 全体に 読み込ませればいい
リポジトリ 配下に 適宜 シンボリックリンク で追加しちゃうと リポジトリ共有したときに困る
### WSL での Windows 側のマウントの場所
`"/mnt/c/Users/Owner/My Documents/github_repository/raison-me/docs/design-docs"`
`My Documents` で スペースがあるので ダブルクオートで囲む必要がある
