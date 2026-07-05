# ADR 0002: Agent Customization の大本ディレクトリを `.agents` にする
Accepted

## 背景(コンテキスト)
このリポジトリでは 複数の AI コーディングエージェント向けの AGENTS.md, knowledge, skills, subagents, prompts, instructions を管理する。
例えば Codex, GitHub Copilot, VS Code, Claude Code など

各ツールは 似た概念を持つが, 参照する標準ディレクトリやファイル形式が異なる。
例えば skills については 以下を参照する
- Codex の skills は `.codex/skills/`
- VS Code / GitHub Copilot in VS Code の Agent Skills は `.github/skills/`, `.agents/skills/`
- Claude Code は `.claude/skills/`

例えば サブエージェント については 以下を参照する
- Codex は サブエージェントを自分で細かく設定する概念がない
- VS Code の custom agents は `.github/agents/`, `.claude/agents/`
- Claude Code の subagents は `.claude/agents/`

そのため ツールごとの標準ディレクトリに同じ内容をコピーすると 更新漏れや差分の不一致が起きる。
一方で どのツールにも属さない中立的な大本ディレクトリを用意し ツール固有のディレクトリからシンボリックリンクで参照すれば 実体を一箇所に集約できる。

## 課題
AI エージェント向けの設定や再利用資産を管理するとき 次の問題を避けたい。

- Codex, VS Code, GitHub Copilot, Claude Code ごとに同じ skill や agent 定義をコピーして重複管理する
- `.codex`, `.github`, `.claude` のどれかを大本にしてしまい, 特定ツールに寄った構成になる
- `AGENTS.md` のようなリポジトリ指示ファイルと skills, subagents の関係が曖昧になる
- skills と subagents の標準配置やファイル形式の違いを混同する
- VS Code が標準で認識しない `.agents/subagents/` を 設定なしで認識されるものとして扱ってしまう
- 将来ツールが増えたときに どこを編集すればよいか分からなくなる

## 決定
AI エージェント向けの再利用資産の大本ディレクトリは `.agents/` とする。

`.agents/` 配下に 中立的なマスタを置き ツール固有の標準ディレクトリは シンボリックリンク または ツール設定で対応する。

基本構成は 次の形を採用する。

```text
.agents/
  skills/
    <skill-name>/
      SKILL.md
  subagents/
    <agent-name>.md
  instructions/
    AGENTS.md
  prompts/
```

ツール固有ディレクトリへの対応は 次の方針にする。

```text
AGENTS.md -> .agents/instructions/AGENTS.md
copilot-instructions.md -> .agents/instructions/AGENTS.md
.codex/skills -> ../.agents/skills
.github/skills -> ../.agents/skills
.claude/skills -> ../.agents/skills
.github/agents/<agent-name>.agent.md -> ../.agents/subagents/<agent-name>.md
.claude/agents -> ../.agents/subagents
```

`AGENTS.md` は リポジトリルートに置く必要があるツール向けの入口として扱う。
ただし 実体は `.agents/instructions/AGENTS.md` に置き, ルートの `AGENTS.md` は シンボリックリンクにすることを基本方針とする。
シンボリックリンクが使えない環境でも `.agents/instructions/AGENTS.md` を 大本として ルートの `AGENTS.md` は 手動同期した派生物として扱う。

VS Code / GitHub Copilot in VS Code で skills を使う場合, `.agents/skills/` は標準探索場所として扱える。
一方で VS Code の subagents は 実体として custom agents であり, 標準探索場所は `.github/agents/` または `.claude/agents/` である。
`.agents/subagents/` を VS Code に見せる場合は `.claude/agents` へのシンボリックリンク を行う
(`chat.agentFilesLocations` による追加設定 で `.agents/subagents/` を VS Code の標準の探索対象にできるが ユーザー固有になるため避ける)

(Claude Code を使わないなら `.github/agents` でも良いが あえて `.claude/agents` にする理由は後述)

subagents は ツールごとにディレクトリを分けず, `.agents/subagents/` 直下に集約する。
基本形式は Claude Code の subagent 形式を採用する。
理由は VS Code が Workspace (Claude format) として `.claude/agents/` を標準探索場所にしているため `.claude/agents -> ../.agents/subagents` にすれば VS Code と Claude Code の両方から読みやすいからである。

ただし GitHub Copilot cloud agent など 利用するなら VS Code / GitHub Copilot 独自の frontmatter を使う必要がある。
(`.github/agents/*.agent.md` を作る前提)
その場合は `.agents/subagents/` の共通定義を無理に流用せず 必要に応じて `.github/agents/` に派生ファイルを作る。

## 記録
- 作成日: 2026-07-04
- 更新日: 2026-07-04
- 置き換え先 ADR: なし

## 検討した選択肢
1. `.agents/` を大本にする
2. `agent-tools/` を大本にする
3. `ai-tools/` を大本にする
4. `.codex/`, `.github/`, `.claude/` など ツール固有ディレクトリのどれかを大本にする

## 決定理由
`.agents/` は AI エージェント向けの AGENTS.md, skills, subagents, prompts, instructions をまとめる名前として意味が狭すぎず広すぎない。
また VS Code / GitHub Copilot in VS Code の Agent Skills では `.agents/skills/` が標準探索場所の一つとして扱われるため 完全な独自命名ではない。

`agent-tools/` は見えるディレクトリとして分かりやすいが tools という名前は スクリプトや補助 CLI まで含む印象が強い。
今回管理したい中心は ツールそのものではなく エージェントに読み込ませる設定, 知識, workflow である。

`ai-tools/` はさらに広く AI 関連の 検証スクリプト, 評価ツール, モデル実験, CLI ラッパー なども入り得る。
長期運用では 何でも置ける雑多な場所になりやすい。

一方で `.agents/` という名前には迷いがある。
他のツールでは `agents` ディレクトリが サブエージェント定義を置く場所として使われることが多い。
そのため このリポジトリで `.agents/` を大本ディレクトリにすると "`.agents/` そのものが subagents の置き場なのか", "`.agents/subagents/` が subagents の置き場なのか" が一瞬分かりにくくなる。
それでも `.agents/` を採用するのは VS Code / GitHub Copilot in VS Code の Agent Skills が `.agents/skills/` を標準の探索場所として扱っているためである。

今回の方針は 独自に `.agents/` という名前を発明するのではなく VS Code が先に採用している `.agents/skills/` の流儀に準拠し その上位ディレクトリを大本として使う判断である。
この分かりにくさは受け入れ `.agents/subagents/` という階層名 と ADR で補う。

`.codex/`, `.github/`, `.claude/` のどれかを大本にすると 特定ツールの流儀に寄ってしまう。
複数ツールに対応するリポジトリでは ツール固有ディレクトリは 出力先または互換レイヤーとして扱い 中立的な大本を別に置く方が更新箇所を明確にできる。

## メリット: 期待される効果
- AI エージェント向け資産の編集箇所を `.agents/` に集約できる
- Codex, VS Code, GitHub Copilot, Claude Code の標準配置差を シンボリックリンクや設定で吸収できる
- `.agents/skills/` は VS Code の標準探索場所の一つなので, skills については VS Code と相性がよい
- ツール固有ディレクトリを大本にしないため vendor-neutral な構成にできる
- `AGENTS.md` の実体も `.agents/instructions/` に置けるため エージェント向け指示を `.agents/` に集約できる
- subagents を `.agents/subagents/` 直下に集約できるため ツール別ディレクトリによる重複や探索負荷を減らせる

## デメリット: 受け入れるリスク
- `.agents/subagents/` は VS Code が標準で直接見る場所ではないため `.claude/agents` へのシンボリックリンク の設定が必要になる
- Windows では シンボリックリンク作成に 管理者権限 または Developer Mode が必要になる場合がある
- シンボリックリンクを削除するときに 実体ディレクトリを誤って削除しないよう注意が必要になる
- Copilot 形式の `.agent.md` と Claude 形式の `.md` は完全に同一ではないため, GitHub Copilot cloud agent 向けに独自 frontmatter が必要な場合は 派生ファイルが必要になる
- ルートの `AGENTS.md` をシンボリックリンクにする場合 シンボリックリンクを扱えない環境やツールで追加対応が必要になる
- 一般に `agents` ディレクトリは サブエージェント置き場として読まれやすいため, `.agents/` を大本にする構成は 初見では少し分かりにくい

## 影響範囲
- コード: 直接のアプリケーションコードには影響しない
- テスト: ディレクトリ方針の ADR 追加のみなのでテストは不要
- 運用: AI エージェント向けの AGENTS.md, skills, subagents, prompts, instructions を追加するときは 原則 `.agents/` 配下を大本として編集する
- ツール固有ディレクトリやルート `AGENTS.md` は シンボリックリンク または 設定で `.agents/` を参照する

## 将来の考慮事項
- Codex が 将来 `.codex/agents/` のような custom agent / subagent 標準配置を提供した場合は `.agents/subagents/` を参照できるか確認, 必要であれば派生ファイルや変換ルールを追加する
- VS Code の `chat.agentFilesLocations` の設定スキーマを実環境で確認し シンボリックリンクより設定で済む場合は 手順化する
- skills を複数ツールで共有する場合 `SKILL.md` の frontmatter が各ツールで互換かどうかを確認する
- subagents は Claude Code 形式を基本にするが VS Code / GitHub Copilot 独自の `agents`, `handoffs`, `user-invocable`, `disable-model-invocation`, `target` などを使いたい場合は 共通ファイルに混ぜるか派生ファイルに分けるかを再検討する

## 参考
- ドキュメント: <a href="https://code.visualstudio.com/docs/agent-customization/agent-skills#_create-a-skill" target="_blank" rel="noopener noreferrer">Use Agent Skills in VS Code の Create a skill</a>  
- ドキュメント: <a href="https://code.visualstudio.com/docs/agent-customization/custom-agents#_custom-agent-file-locations" target="_blank" rel="noopener noreferrer">Custom agents in VS Code の Custom agent file locations</a>  
- ドキュメント: <a href="https://code.visualstudio.com/docs/agents/subagents" target="_blank" rel="noopener noreferrer">Subagents in Visual Studio Code</a>  
- ドキュメント: <a href="https://code.claude.com/docs/en/sub-agents" target="_blank" rel="noopener noreferrer">Claude の Create custom subagents</a>  
