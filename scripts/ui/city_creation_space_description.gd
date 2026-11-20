extends RefCounted
## Shared descriptions from the published spatial contracts, with no city writes.
const STAGES={"trait":"特色","cluster":"局部空间","district":"成区"}
static func detail(space:Dictionary,network_ready:bool)->String:
	var detail:String="真实院落 · 公共通口已接通" if space.eligibility.district else "真实院落 · 等待道路发布" if space.eligibility.reason=="network_waiting" else "真实院落 · 院内入口尚未接通公共路网" if space.eligibility.reason=="portal_disconnected" else "真实院落 · 需要通向院内的公共入口" if space.stage=="cluster" else "居住体量 · 尚无已验证院落"
	if space.evidence.geometry=="half_enclosure":detail="半围合 · "+("留有可进入的干地" if space.evidence.open_access else "开口通路受阻")+(" · 道路待更新" if not network_ready else "")
	if space.evidence.geometry=="narrow_lane":detail="连续窄巷 · "+("两侧入口与公共路网已接通" if space.eligibility.district else "等待道路发布" if space.eligibility.reason=="network_waiting" else "两侧入口尚未接通公共路网")
	if space.eligibility.reason=="height_access_missing":detail="连续窄巷 · 门前高差尚无可用接续"
	if space.kind=="waterfront":detail="面水公共界面 · "+("入口与公共路网已接通" if space.eligibility.district else "等待道路发布" if space.eligibility.reason=="network_waiting" else "附近尚无真实水域" if space.eligibility.reason=="water_missing" else "尚无可用的面水公共界面" if space.eligibility.reason=="shore_face_missing" else "入口接续尚待验证" if space.eligibility.reason=="entry_support_unverified" else "面水通路地形受阻" if space.eligibility.reason=="ground_access_missing" else "门前高差尚无可用接续" if space.eligibility.reason=="height_access_missing" else "入口尚未接通面水公共道路")
	if space.kind=="waterfront" and space.eligibility.district and space.evidence.public_entries.any(func(row):return row.get("surface","")=="public_stone_steps"):
		detail="面水公共界面 · 可沿公共道路抵达亲水石埠"
	elif space.kind=="waterfront" and space.eligibility.district and space.evidence.public_entries.any(func(row):return row.height_access.kind=="modern_terrace_deck"):
		detail="面水公共界面 · 退台入口接通公共道路"
	if space.kind=="artisan":detail="百工前庭 · "+("入口与公共路网已接通" if space.eligibility.district else "等待道路发布" if space.eligibility.reason=="network_waiting" else "钟楼特色尚无已验证作业体量" if space.eligibility.reason=="work_body_missing" else "尚无可用的干地前庭" if space.eligibility.reason=="forecourt_missing" else "门前高差尚无可用接续" if space.eligibility.reason=="height_access_missing" else "入口尚未接通公共道路")
	if space.kind=="civic":detail="礼乐前场 · "+("入口与公共路网已接通" if space.eligibility.district else "等待道路发布" if space.eligibility.reason=="network_waiting" else "柱脚阻挡公共入口" if space.eligibility.reason=="column_obstruction" else "尚无可用的干地前场" if space.eligibility.reason=="forecourt_missing" else "门前高差尚无可用接续" if space.eligibility.reason=="height_access_missing" else "入口尚未接通公共道路")
	if space.evidence.geometry=="paved_plaza":detail="真实闭合路环 · 基础铺装，未绑定经营或居民"
	return detail
