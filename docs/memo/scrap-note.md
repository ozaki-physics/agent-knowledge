# scrap note
## 概要
気になったこと や メモ書き を 置いておく

### ツールのバージョンアップ
#### Codex の バージョンアップ
`npm install -g @openai/codex@latest`
`codex --version`
`codex` で起動
https://github.com/openai/codex/releases
https://developers.openai.com/codex/changelog
#### GitHub Copilot の バージョンアップ
`npm install -g @github/copilot@latest`
`copilot update` でも `copilot` で対話モードにしてから `/update` でも よいらしい
`copilot` で起動

https://github.blog/changelog/label/copilot/

### ディレクトリのコピー
`cp -r <コピー元> <コピー先>`
### Linux の シンボリックリンク の作り方
`ln -s <元のパス> <作りたい名前>`
`ln -s "/mnt/c/Users/Owner/My Documents/github_repository" ~/win-github_repository`

`pwd -P` で シンボリックリンク の 元の物理的な場所を確認できる
### Windows の シンボリックリンク の作り方
`New-Item -ItemType SymbolicLink -Path <作りたい名前> -Target <元のパス>`
`New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.codex\skills\hello" -Target "$env:USERPROFILE\source\repos\temp\hello"`

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
### bash の設定ファイル
`.bashrc` が設定ファイル
設定を変えたときに 反映して ターミナルを再起動するコマンド
`source ~/.bashrc`
### WSL の 初期設定
```bash
sudo apt update && sudo apt upgrade -y
locale
echo $LANG
sudo apt install -y language-pack-ja
sudo update-locale LANG=ja_JP.UTF-8
locale
```
### WSL を起動したときに 表示されるメッセージを抑制する
`touch ~/.hushlogin`
### Git の 設定
```bash
git config --global user.name "<アカウント名>"
git config --global user.email "<メアド>"
git config --list | grep user
ssh-keygen -t ed25519 -a 100 -C "<メアド>"
```
### Git 操作
リモートの変更を確認: `git fetch`
#### Git Worktree
##### パターン1: 新規ブランチで worktree を作る
```bash
# 新しいブランチとworktreeを同時に作成
git worktree add -b <新しいブランチ名> <作成先のパス>
git worktree add -b feature/new-ui ../my-project-new-ui

# これで以下が同時に行われる:
# 1. feature/new-uiブランチが作成される
# 2. ../my-project-new-uiフォルダが作成される
# 3. そのフォルダでfeature/new-uiがチェックアウトされる
```

##### パターン2: 既存ブランチで worktree を作る
```bash
# 既存のブランチで worktree を作成
git worktree add <作成先のパス> <ブランチ名>
git worktree add ../my-project-hotfix hotfix/bug-123

# hotfix/bug-123ブランチが既に存在する必要がある
```

##### Worktree の 削除
```bash
# ワークツリーの確認
git worktree list

# worktree を削除
git worktree remove <作成先のパス>
git worktree remove ../my-project-new-ui

# フォルダを直接削除した場合は 参照を整理
# フォルダを直接削除した場合
rm -rf <作成先のパス>
rm -rf ../my-project-new-ui
# Git に 削除された worktree の情報を整理させる
git worktree prune
```
### ドキュメント を書くときの コマンド の規約
説明用: `<placeholder>`
省略可能: `[optional]`
分岐: `{a|b}`
複数: `...`
実行例: 実値を書く(プレースホルダは使わない)
例: `command <required> [optional] {choice1|choice2} <arg>...`

試しに `git --help` を行ったとき
```
$ git --help
usage: git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--bare]
           [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]
           [--config-env=<name>=<envvar>] <command> [<args>]
```
