# round188 · 首作试玩反馈记录

这里记录真人试玩对首句候选、作者归属和成长因果的原话。技术合同只保证记录里的 `truth` 来自已观察到的城市/声音对象；`answer`、`correct` 和 `notes` 必须由试玩后填写，不能从界面文案推断。

## 最小记录

复制 `human_feedback_template.json`，每次试玩使用新的 `trial_id`。按 `文档/02_验收/DOD.md` §12 填写：

- `kind`：`HUMAN-EXPRESSION`、`HUMAN-AUTHOR`、`HUMAN-DIFF`、`HUMAN-CANDIDATE`、`HUMAN-NOTASK`、`HUMAN-FABRIC` 或 `HUMAN-TIER`。
- `tester_id`、`seed`、`layout_id`、`device`、`assist_state`：记录复现条件。
- `truth`：由现有真实成长/声部查询得到的建筑、社区、音级、句帧和实际声源；没有观察到的对象保持缺省，不填写未来目标。
- `answer`：玩家的选择、听感、因果解释和是否想继续；保留原话。
- `correct`：只有题目有明确答案时填写 `true`/`false`，主观作者感可留 `null`。
- `evidence`：对应截图和音频文件名；没有就留空。

检查命令：

```powershell
& 'D:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\GODOT\GODOTPRO\共鸣之城' --script res://tests/round188_experience_feedback_contract.gd
```

通过只表示记录结构与真实身份边界正确，不表示真人验收通过。
