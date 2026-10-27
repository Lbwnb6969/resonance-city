local mod = ...

-- Register crenation model asset
mod:registerAssetId("models/SciFiCrenation.fbx/Prefab", "SCI_FI_WALL_CRENATION_PREFAB")

-- Register texture assets
mod:registerAssetId("models/SciFiWall.png", "TEXTURE_SCI_FI_WALL")
mod:registerAssetId("models/SciFiWallTop.png", "TEXTURE_SCI_FI_WALL_TOP")

-- Register new material for the wall texture
mod:registerAsset({
	DataType = "MATERIAL",
	Id = "MATERIAL_SCI_FI_WALL",
	HasAlphaTest = false,
	AlbedoTexture = "TEXTURE_SCI_FI_WALL"
})

-- Register new material for the wall top texture
mod:registerAsset({
	DataType = "MATERIAL",
	Id = "MATERIAL_SCI_FI_WALL_TOP",
	HasAlphaTest = false,
	AlbedoTexture = "TEXTURE_SCI_FI_WALL_TOP"
})

-- Register the wall building
mod:registerAsset({
	DataType = "BUILDING",
	Id = "BUILDING_SCI_FI_WALL",
	Name = "SCI_FI_WALL",
	BuildingType = "FORTIFICATION",
	AssetCoreBuildingPart = "BUILDING_PART_MONUMENT_POLE",
	AssetBuildingPartList = {
		"BUILDING_PART_SCI_FI_WALL"
	}
})

-- Register the wall building parts
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "BUILDING_PART_SCI_FI_WALL_SEGMENT",
	Name = "SCI_FI_WALL",
	Category = "WALL",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "PREFAB_EMPTY_PART"
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {{
			{ Resource = "MITHRIL_ORE", Quantity = 1 }
		}}
	}
})

mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "BUILDING_PART_SCI_FI_WALL_SECTION",
	Category = "WALL",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "PREFAB_EMPTY_PART"
	}
})

mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "BUILDING_PART_SCI_FI_WALL",
	Name = "SCI_FI_WALL",
	Category = "WALL",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_WALL",
		ControlPointPart = "DEFAULT_WALL_CONTROL_POINT",
		SectionPart = "BUILDING_PART_SCI_FI_WALL_SECTION",
		SegmentPart = "BUILDING_PART_SCI_FI_WALL_SEGMENT",
		Width = 0.1,
		CrenelationList = {
			{
				DataType = "DATA_WALL_CRENELATION",
				Visual = "SCI_FI_WALL_CRENATION_PREFAB",
				Length = 4,
				Offset = { 0, 0, 0.05 },
			}
		},
		-- FYI: This is the old way for making a wall.
		-- New walls uses SegmentList to configure a set of wall segment (small part of a whole section between two control point)
		ProceduralMesh = {
			DataType = "DATA_WALL_PROCEDURAL_MESH",
			SideMaterial = "MATERIAL_SCI_FI_WALL",
			TopMaterial = "MATERIAL_SCI_FI_WALL_TOP",
			SegmentLength = 4,
			Height = 3,
			UvTilingTop = 1,
			UvTilingSide = 1,
			OffsetY = 0
		}
	}
})

mod:registerAsset({
	DataType = "UNLOCKABLE",
	Id = "UNLOCKABLE_SCI_FI_WALL",
	Name = "UNLOCKABLE_SCI_FI_WALL_NAME",
	Description = "UNLOCKABLE_SCI_FI_WALL_DESC",
	DataCost = {
		ResourceCollection = {
			{ Resource = "GOLD_COINS", Quantity = 25 }
		}
	},
	PrerequisiteUnlockableList = {
		"UNLOCKABLE_MITHRIL_FACTORY"
	},
	ActionList = {
		{
			DataType = "GAME_ACTION_UNLOCK_BUILDING_LIST",
			BuildingProgressData = {
				AssetBuildingList = {
					"BUILDING_SCI_FI_WALL"
				}
			}
		}
	}
})