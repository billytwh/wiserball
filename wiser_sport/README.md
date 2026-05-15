# Wiser Sport (Flutter)

如果你本机还没有 Flutter 工程骨架，建议先在此目录外执行：

```bash
flutter create wiser_sport
```

然后用本目录的 `lib/`、`test/`、`pubspec.yaml` 覆盖生成项目中的同名文件，再执行：

```bash
flutter pub get
flutter run
```

本项目包含：
- 2 队（Red / White），默认每队 7 球
- 球状态：Contesting → First-Locked（黄）→ Second-Locked（红）→ Struck-Out
- 点击球推进状态；开启 Rescue 后点击球反向回退一档
- 90 分钟倒计时（手动开始，无暂停），崩溃/重启可恢复继续
- 按权重计分并计算胜负：Contesting=5，First-Locked=2，Second-Locked=1
- 工具页：2 秒拦截计时、出界清单、犯规记录与严重犯规“即时淘汰”
- 参考页：场地与器材要点（文本版）

