---
name: link-agents-assets
description: >
  .agents 配下の skills, subagents, instructions, prompts を、リポジトリ内の
  .codex/.github/.claude やホームディレクトリ配下、任意のツール固有ディレクトリへ
  シンボリックリンクで配置するスキル。
  「.agents からリンクして」「AGENTS.md をリンク」「スキルを .codex に同期」
  「subagents を .claude に配置」「link-agents-assets」などの指示があったときに使う。
  .agents をリンク元にしたリスト表示・リンク作成・リンク削除に対応する。
---

# link-agents-assets
AI エージェント向け資産の実体を `.agents/` に置き、必要なツール固有ディレクトリやホームディレクトリへシンボリックリンクで配置する。
ツール固有ディレクトリやホームディレクトリにはコピーせず、必要な場所へシンボリックリンクで配置する。

## 設計方針
- `.agents/` をツール非依存の実体置き場として扱う
- `.codex`, `.github`, `.claude` などのツール固有ディレクトリはリンク先として扱う
- 同じ skill や subagent を複数箇所へコピーせず、シンボリックリンクで参照する
- 形式差があるツール向けには、必要に応じて派生ファイルを作る
- リンク先に既存の実ファイルや実ディレクトリがある場合は、上書きせずユーザー判断を優先する

## 先に確認すること
- 実行するリポジトリや作業ディレクトリに `.agents/` があること
- リンク元:
  - `.agents/skills/<skill-name>/`
  - `.agents/subagents/<agent-name>.md`
  - `.agents/instructions/*`
  - `.agents/prompts/*`
- 既存の実ファイルや実ディレクトリは上書きしない。置換が必要なら、作業前にユーザーへ確認する。

## スクリプト

```bash
bash <skill_dir>/scripts/link_agents_assets.sh [options]
```

`<skill_dir>` はこの `SKILL.md` があるディレクトリ。

## 基本操作

```bash
# リポジトリ内の代表的なリンク状態を確認
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile repo --list

# リポジトリ内に代表的なリンクを作成
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile repo

# Codex 用の skills を任意の .codex ディレクトリへ配置
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile codex --target /path/to/project --type skills

# Claude 用にホームディレクトリへ配置
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile claude --target ~

# 特定の skill だけ配置
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile codex --target ~ --type skills --name link-agents-assets

# 既存シンボリックリンクだけ張り替える
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile claude --target ~ --force

# このスクリプトで作る位置のシンボリックリンクだけ削除
bash .agents/skills/link-agents-assets/scripts/link_agents_assets.sh --profile claude --target ~ --remove
```

## profile の使い分け

| profile | target の意味 | 配置先 |
| --- | --- | --- |
| `repo` | リポジトリルート | `AGENTS.md`, `.codex/skills`, `.github/skills`, `.claude/skills`, `.claude/agents` |
| `codex` | `.codex` ディレクトリ | `skills/<skill-name>` |
| `claude` | `.claude` ディレクトリ | `skills/<skill-name>`, `agents/<agent-name>.md`, `CLAUDE.md`（`AGENTS.md` を名称変換） |
| `github` | `.github` ディレクトリ | `skills/<skill-name>`, `agents/<agent-name>.agent.md` |
| `agents` | `.agents` ディレクトリ | `skills`, `subagents`, `instructions`, `prompts` と同じ構造 |
| `custom` | 任意の配置先ルート | `<type>/<name>` |

`--target` を省略した場合、`repo` はスクリプト位置から推定したリポジトリルート、それ以外はカレントディレクトリを親ディレクトリとして使う。`codex` / `claude` / `github` / `agents` では、それぞれ `.codex` / `.claude` / `.github` / `.agents` を自動的に補完する。

## オプション

| オプション | 既定値 | 説明 |
| --- | --- | --- |
| `--profile` | `repo` | 配置先の構造を選ぶ |
| `--target` | profile による | 配置先ディレクトリ |
| `--type` | `all` | `skills` / `subagents` / `instructions` / `prompts` / `all` |
| `--name` | 全件 | 対象名。複数指定またはカンマ区切りが可能 |
| `--list` | false | 状態を一覧表示して終了 |
| `--remove` | false | シンボリックリンクを削除する |
| `--force` | false | 既存シンボリックリンクだけ張り替える |
| `--dry-run` | false | 変更せず実行内容だけ表示 |

## 注意

- Windows ではシンボリックリンク作成に Developer Mode または管理者権限が必要な場合がある。
- `--remove` はリンクだけを削除し、リンク元の `.agents/` 配下の実体は削除しない。
- 既存の実ファイル・実ディレクトリがある場合はスキップする。削除や置換はユーザー確認後に別作業として行う。
