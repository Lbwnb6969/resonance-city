# 未完成夜景探针

Root在32张新纹理尚未实际导入Godot缓存时提前启动实窗，`load_catalog`加载所有新PNG失败。`.import`描述文件存在不代表压缩纹理缓存已生成。日志输出路径的父目录也尚未建立，因此本次只有终端错误和部分截图，没有完整live.json。实际进程被停止，退出1，不计入技术或截图通过。

终端主要诊断：`Failed loading resource: res://资源/精制河湾/夜光/refined_house_terrace_emission.png`（共32种）；由于灯表为空，最后访问building-00025时报Dictionary无对应key。随后安排独占headless editor导入，并重跑同一条实窗。

探针另修正SceneTree.process_frame信号先于Demo._process的观察时序：修改夜相/黑屏后等待两个帧再查显示状态。生产代码未靠放宽门控绕过失败。
