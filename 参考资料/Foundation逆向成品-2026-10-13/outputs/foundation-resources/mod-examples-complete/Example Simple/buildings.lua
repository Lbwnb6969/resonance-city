
local myMod = ...

myMod:registerAsset({
	DataType = "BUILDING",
	Id = "MY_MOD_BUILDING_FOUNTAIN",
	Name = "MY_MOD_FOUNTAIN",
	Description = "MY_MOD_FOUNTAIN_DESC",
	BuildingType = "DECORATION",
	AssetCoreBuildingPart = "MY_MOD_BUILDING_PART_FOUNTAIN",
})

myMod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MY_MOD_BUILDING_PART_FOUNTAIN",
	Description = "",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "PREFAB_FOUNTAIN"
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createCircle(2.5),
				Type = {
					DEFAULT = true
				}
			}
		}
	},
	ConstructionVisual = "PREFAB_FOUNTAIN_CONSTRUCTION",
	Cost = {
		UpkeepCost = {
			{ Resource = "GOLD", Quantity = 5 }
		},
		ResourceNeededList = {
			{
				{ Resource = "WOOD", Quantity = 5 },
				{ Resource = "STONE", Quantity = 10 },
			},
		}
	}
})

--------------------------------------------------------------------------
-- Add new unlockable to unlock Fountain building
myMod:registerAsset({
	DataType = "UNLOCKABLE",
	Id = "UNLOCKABLE_COMMON_MY_MOD_FOUNTAIN",
	DataCost = {
		ResourceCollection = {
			{ Resource = "GOLD_COINS", Quantity = 0 }
		}
	},
	ActionList = {
		{
			DataType = "GAME_ACTION_UNLOCK_BUILDING_LIST",
			BuildingProgressData = {
				DataType = "BUILDING_PROGRESS",
				AssetBuildingList = {
					"MY_MOD_BUILDING_FOUNTAIN"
				}
			}
		}
	},
	UnlockableImage = "ICON_ASTEROID_ROCK"
})

--------------------------------------------------------------------------
-- Add unlockable to a unlockable tier
myMod:overrideAsset({
	Id = "PROGRESS_TIER_COMMON_T1",
	UnlockableList = {
		Action = "APPEND",
		"UNLOCKABLE_COMMON_MY_MOD_FOUNTAIN"
	}
})