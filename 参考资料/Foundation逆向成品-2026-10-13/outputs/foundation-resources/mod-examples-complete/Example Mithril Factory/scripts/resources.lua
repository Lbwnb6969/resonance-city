local mod = ...

-- Register image assets
mod:registerAssetId("icons/mithril-ore.png", "ICON_MITHRIL_ORE", "ATLAS_CELL")
mod:registerAssetId("icons/mithril-chainmail.png", "ICON_MITHRIL_CHAINMAIL", "ATLAS_CELL")
mod:registerAssetId("icons/mithril-necklace.png", "ICON_MITHRIL_NECKLACE", "ATLAS_CELL")

-- Register asteroid ore (resource)
mod:registerAsset({
	DataType = "RESOURCE",
	Id = "MITHRIL_ORE",
	ResourceName = "MITHRIL_ORE",
	Icon = "ICON_MITHRIL_ORE",
	DisplayInToolbar = true,
	ResourceTypeList = { "RESOURCE" },
	ResourceVisualPrefabList = { "PREFAB_RESOURCE_VISUAL_CRATE" },
	IndividualResourceVisualPrefabList = { "PREFAB_RESOURCE_VISUAL_CRATE" }
})

-- Register mithril chainmail (goods)
mod:registerAsset({
	DataType = "RESOURCE",
	Id = "MITHRIL_CHAINMAIL",
	ResourceName = "MITHRIL_CHAINMAIL",
	Icon = "ICON_MITHRIL_CHAINMAIL",
	DisplayInToolbar = true,
	ResourceTypeList = { "GOODS" },
	ResourceVisualPrefabList = { "PREFAB_RESOURCE_VISUAL_CRATE" },
	IndividualResourceVisualPrefabList = { "PREFAB_RESOURCE_VISUAL_CRATE" }
})

-- Register mithril necklace (luxury)
mod:registerAsset({
	DataType = "RESOURCE",
	Id = "MITHRIL_NECKLACE",
	ResourceName = "MITHRIL_NECKLACE",
	DisplayInToolbar = true,
	Icon = "ICON_MITHRIL_NECKLACE",
	ResourceTypeList = { "LUXURY" },
	ResourceVisualPrefabList = { "PREFAB_RESOURCE_VISUAL_CRATE" },
	IndividualResourceVisualPrefabList = { "PREFAB_RESOURCE_VISUAL_CRATE" }
})