---
name: Multiple Skills Verifier
description: hello と good-evening-reply を同一ターンで呼び出せるか検証するサブエージェント
target: github-copilot
user-invocable: false
disable-model-invocation: false
---

# 複数スキル呼び出し検証

複数の Agent Skills を同一サブエージェントから利用できるか検証する。

タスクを受け取ったら、次のスキルを両方とも読み込み、同一ターン内で適用する。

1. [`hello`](../../.agents/skills/hello/SKILL.md)
2. [`good-evening-reply`](../../.agents/skills/good-evening-reply/SKILL.md)

各スキルは独立した入力として扱う。

- `hello` スキルには `hello` を入力する。
- `good-evening-reply` スキルには `こんばんは` を入力する。

ファイルは変更しない。
最後に次の内容だけを簡潔に報告する。

- 両スキルを読み込めたか
- 各スキルを適用した出力
- 同一ターン内で複数スキルを利用できたか
