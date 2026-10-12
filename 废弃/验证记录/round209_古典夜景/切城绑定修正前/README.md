# 切城绑定补修前：21/22

首次已导入完整32夜光资源的Windows实窗为21/22，退出1。夜景、暖庭同源四秒试听、800×600目标净空、黑屏、render-ahead不提前亮未来房屋、25栋可听作者根屋及4秒88200设备输入均通过，0削波/0新增underrun；失败项为 `switching_city_discards_all_old_light_children`。

根因：切城时清空真实 Sprite，却保留了可复用 building_geometry；24个同位置同资产的几何缓存命中时，geometry_dirty=false，导致新Sprite未挂暖光。不是断言范围过宽。补修为每次创建新Sprite时都刷新其资源/子灯绑定，继续保留几何缓存。旧父子实例按原有queue_free回收。

只对受影响路径补实际Windows窗口，`验证记录/round209_古典夜景/reentry_2026-10-12T17-04-16/` 11/11退出0，26个实际当前房屋全部按自己的资源与新父绑定，真实文化馆、黑屏、昼夜与4秒设备输入通过。未重跑整条22项或历史多段链。
