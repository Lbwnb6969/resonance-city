local mod = ...

--------------------------------------------------------------------------

-- Register IDs for all prefab nodes referenced here
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/CenterPart", "SCI_FI_BRIDGE_CENTER_PREFAB")
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/RootPart", "SCI_FI_BRIDGE_CENTER_ROOT_PREFAB")
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/StartSlopePart", "SCI_FI_BRIDGE_SLOPE_START_PREFAB")
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/EndSlopePart", "SCI_FI_BRIDGE_SLOPE_END_PREFAB")
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/StartPart", "SCI_FI_BRIDGE_START_PREFAB")
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/EndPart", "SCI_FI_BRIDGE_END_PREFAB")
mod:registerAssetId("models/SciFiBridge.fbx/Prefab/SciFiBridge/TilingPart", "SCI_FI_BRIDGE_TILING_PREFAB")

--------------------------------------------------------------------------

-- Register bridge tiling (the pillar part that extends to the ground)
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_TILING_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "SCI_FI_BRIDGE_TILING_PREFAB"
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 2 },
			},
		}
	},
})

-- Register bridge start part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_START_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_SLOPE",
		CoreObjectPrefab = "SCI_FI_BRIDGE_START_PREFAB",
		SlopePartList = {
			"SCI_FI_BRIDGE_SLOPE_START_PART"
		},
		CoreBasementPartList = {
			"SCI_FI_BRIDGE_TILING_PART"
		},
		UpperAttachType = ATTACH_NODE_TYPE.RIGHT,
		LowerAttachType = ATTACH_NODE_TYPE.LEFT,
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 5 },
			},
		},
	},
})

-- Register bridge end part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_END_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_SLOPE",
		CoreObjectPrefab = "SCI_FI_BRIDGE_END_PREFAB",
		SlopePartList = {
			"SCI_FI_BRIDGE_SLOPE_END_PART"
		},
		CoreBasementPartList = {
			"SCI_FI_BRIDGE_TILING_PART"
		},
		UpperAttachType = ATTACH_NODE_TYPE.LEFT,
		LowerAttachType = ATTACH_NODE_TYPE.RIGHT,
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 5 },
			},
		},
	},
})

-- Register bridge start slope part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_SLOPE_START_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_BASEMENT",
		CoreObjectPrefab = "SCI_FI_BRIDGE_SLOPE_START_PREFAB",
		FillerList = {
			"SCI_FI_BRIDGE_TILING_PART"
		},
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 2 },
			},
		},
	},
})

-- Register bridge end slope part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_SLOPE_END_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_BASEMENT",
		CoreObjectPrefab = "SCI_FI_BRIDGE_SLOPE_END_PREFAB",
		FillerList = {
			"SCI_FI_BRIDGE_TILING_PART"
		},
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 2 },
			},
		},
	},
})

-- Register bridge center top part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_CENTER_TOP_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "SCI_FI_BRIDGE_CENTER_PREFAB"
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 2 },
			},
		},
	},
})

-- Register the center root part (the scalable part that places multiple center top parts)
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_CENTER_CORE_PART",
	IsShowInUi = false,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_BASEMENT",
		CoreObjectPrefab = "SCI_FI_BRIDGE_CENTER_PREFAB",
		FillerList = {
			"SCI_FI_BRIDGE_TILING_PART"
		},
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	Cost = {
		DataType = "BUILDING_PART_COST",
		ResourceNeededList = {
			{
				{ Resource = "MITHRIL_ORE", Quantity = 10 },
			},
		},
	},
})

mod:registerAsset({
	DataType = "BUILDING_FUNCTION_BRIDGE",
	Id = "FUNCTION_BRIDGE_ID"
})

-- Register the core part (the part with the bridge mover)
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SCI_FI_BRIDGE_CORE_PART",
	Name = "SCI_FI_BRIDGE_CORE_NAME",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_BRIDGE",
		StartPart = "SCI_FI_BRIDGE_START_PART",
		EndPart = "SCI_FI_BRIDGE_END_PART",
		FillerList = {
			"SCI_FI_BRIDGE_CENTER_CORE_PART"
		},
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 2, 2 }),
				Type = {
					DEFAULT = true,
				}
			}
		}
	},
	BuildingFunction = "FUNCTION_BRIDGE_ID"
})

--------------------------------------------------------------------------

-- Configure all BRIDGE colliders

mod:configurePrefabFlagList("models/SciFiBridge.fbx/Prefab/SciFiBridge/CenterPart", { "BRIDGE" })
mod:configurePrefabFlagList("models/SciFiBridge.fbx/Prefab/SciFiBridge/StartPart", { "BRIDGE" })
mod:configurePrefabFlagList("models/SciFiBridge.fbx/Prefab/SciFiBridge/EndPart", { "BRIDGE" })
mod:configurePrefabFlagList("models/SciFiBridge.fbx/Prefab/SciFiBridge/StartSlopePart", { "BRIDGE" })
mod:configurePrefabFlagList("models/SciFiBridge.fbx/Prefab/SciFiBridge/EndSlopePart", { "BRIDGE" })