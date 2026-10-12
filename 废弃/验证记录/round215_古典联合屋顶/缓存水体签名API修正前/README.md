缓存改进时误写 PackedVector2Array.hash()；Godot 没有该方法，改用全局 hash(value)。原 17/17 JSON 是此次改动前的结果，不作为失败源码通过证据。当前修正后另跑最低合同。原源码与原日志保留。
