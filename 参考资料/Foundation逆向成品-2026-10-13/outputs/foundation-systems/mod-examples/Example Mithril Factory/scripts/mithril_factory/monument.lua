local mod = ...

mod:registerAssetId("models/MithrilFactory.fbx/Materials/MithrilFactory_Diffuse", "MATERIAL_MITHRIL_FACTORY")
mod:registerAssetId("models/MithrilFactory.fbx/Materials/MithrilFactory_Diffuse2", "MATERIAL_MITHRIL_FACTORY_ALT1")
mod:registerAssetId("models/MithrilFactory.fbx/Materials/MithrilFactory_Diffuse3", "MATERIAL_MITHRIL_FACTORY_ALT2")

-- Apply building asset processor
mod:registerAssetProcessor("models/MithrilFactory.fbx", {
	DataType = "BUILDING_ASSET_PROCESSOR"
})

-- Register all mithril factory building parts and their properties
mod:dofile("scripts/mithril_factory/building_functions.lua")
mod:dofile("scripts/mithril_factory/building_parts.lua")

-- Register the mithril factory material set list
mod:registerAsset({
	DataType = "MATERIAL_SET_LIST",
	Id = "MITHRIL_FACTORY_MATERIAL_SET_LIST",
	MaterialSetList = {
		{ SetName = "DEFAULT", AssetSelectionButtonImage = "ICON_BUTTON_RECOLOR_SWATCH_BLUE", MaterialList = { "MATERIAL_MITHRIL_FACTORY" } },
		{ SetName = "ALT_1", AssetSelectionButtonImage = "ICON_BUTTON_RECOLOR_SWATCH_RED", MaterialList = { "MATERIAL_MITHRIL_FACTORY_ALT1" } },
		{ SetName = "ALT_2", AssetSelectionButtonImage = "ICON_BUTTON_RECOLOR_SWATCH_GREEN", MaterialList = { "MATERIAL_MITHRIL_FACTORY_ALT2" } }
	}
})

-- Register the mithril factory monument
mod:registerAsset({
	DataType = "BUILDING",
	Id = "MITHRIL_FACTORY_MONUMENT",
	Name = "MITHRIL_FACTORY_NAME",
	Description = "MITHRIL_FACTORY_DESC",
	BuildingType = BUILDING_TYPE.MONUMENT,
	AssetCoreBuildingPart = "BUILDING_PART_MONUMENT_POLE",
	AssetBuildingPartList = {
		"MITHRIL_FACTORY_CORE_ROOT_PART",
		"MITHRIL_FACTORY_EXTENSION_A_ROOT_PART",
		"MITHRIL_FACTORY_EXTENSION_B_ROOT_PART",
		"MITHRIL_FACTORY_DOOR_A_PART",
		"MITHRIL_FACTORY_DOOR_B_PART",
		"MITHRIL_FACTORY_DECORATION_A_PART",
		"MITHRIL_FACTORY_DECORATION_B_PART"
	},
	SubAssetBuildingList = {
		"MITHRIL_FACTORY_MONUMENT_MITHRIL_MINE",
		"MITHRIL_FACTORY_MONUMENT_MITHRIL_CHAINMAIL",
		"MITHRIL_FACTORY_MONUMENT_MITHRIL_NECKLACE"
	},
	AssetMaterialSetList = "MITHRIL_FACTORY_MATERIAL_SET_LIST",
	RequiredPartList = {},
	AssetBuildingConditionConfigList = {},
	IsManuallyUnlocked = true,
	IsDestructible = true,
	IsEditable = true,
	IsClearTrees = true
})

function registerMithrilFactorySubBuilding(_suffix, _buildingFunction)
	mod:registerAsset({
		DataType = "BUILDING",
		Id = "MITHRIL_FACTORY_MONUMENT_MITHRIL_" .. _suffix,
		Name = "MITHRIL_FACTORY_" .. _suffix .. "_NAME",
		Description = "MITHRIL_FACTORY_" .. _suffix .. "_DESC",
		BuildingType = BUILDING_TYPE.MONUMENT,
		AssetCoreBuildingPart = "BUILDING_PART_MONUMENT_POLE",
		AssetBuildingPartList = {}, -- no need to add any, it uses the parent building's parts
		RequiredPartList = {
			-- Necessarily a list of 'MONUMENT_REQUIRED_PART_PAIR', no need to specify the DataType of each element of the list
			{ Category = "CORE", Min = 1 },
			{ Category = "DOOR", Min = 1 },
		},
		AssetBuildingFunction = _buildingFunction,
		IsManuallyUnlocked = false,
		IsDestructible = true,
		IsEditable = true,
		IsClearTrees = true
	})
end

-- Register the mithril factory mining sub-buildings
registerMithrilFactorySubBuilding("MINE", "MITHRIL_FACTORY_CORE_FUNCTION")
registerMithrilFactorySubBuilding("CHAINMAIL", "MITHRIL_FACTORY_EXTENSION_A_FUNCTION")
registerMithrilFactorySubBuilding("NECKLACE", "MITHRIL_FACTORY_EXTENSION_B_FUNCTION")

mod:registerAsset({
	DataType = "UNLOCKABLE",
	Id = "UNLOCKABLE_MITHRIL_FACTORY",
	Name = "UNLOCKABLE_MITHRIL_FACTORY_NAME",
	Description = "UNLOCKABLE_MITHRIL_FACTORY_DESC",
	DataCost = {
		DataInfluenceCostList = {},
		ResourceCollection = {
			{ Resource = "GOLD_COINS", Quantity = 50 },
		}
	},
	PrerequisiteUnlockableList = {},
	ActionList = {
		{
			DataType = "GAME_ACTION_UNLOCK_BUILDING_LIST",
			BuildingProgressData = {
				AssetBuildingList = {
					"MITHRIL_FACTORY_MONUMENT"
				},
			}
		}
	}
})
