local mod = ...

-- Apply building asset processor
mod:registerAssetProcessor("models/SciFiBridge.fbx", {
	DataType = "BUILDING_ASSET_PROCESSOR"
})

-- Register all Sci-Fi bridge building parts and their properties
mod:dofile("scripts/sci_fi_bridge/building_parts.lua")

-- Register the Sci-Fi bridge monument
mod:registerAsset({
	DataType = "BUILDING",
	Id = "SCI_FI_BRIDGE",
	Name = "SCI_FI_BRIDGE_NAME",
	Description = "SCI_FI_BRIDGE_DESC",
	BuildingType = BUILDING_TYPE.BRIDGE,
	AssetCoreBuildingPart = "SCI_FI_BRIDGE_CORE_PART",
	IsManuallyUnlocked = true,
	IsDestructible = true,
	IsEditable = true,
	IsClearTrees = true
})

mod:registerAsset({
	DataType = "UNLOCKABLE",
	Id = "UNLOCKABLE_SCI_FI_BRIDGE",
	Name = "UNLOCKABLE_SCI_FI_BRIDGE_NAME",
	Description = "UNLOCKABLE_SCI_FI_BRIDGE_DESC",
	DataCost = {
		DataInfluenceCostList = {},
		ResourceCollection = {
			{ Resource = "GOLD_COINS", Quantity = 25 },
		}
	},
	PrerequisiteUnlockableList = {
		"UNLOCKABLE_MITHRIL_FACTORY",
	},
	ActionList = {
		{
			DataType = "GAME_ACTION_UNLOCK_BUILDING_LIST",
			BuildingProgressData = {
				AssetBuildingList = {
					"SCI_FI_BRIDGE",
				},
			},
		},
	},
})