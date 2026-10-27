local mod = ...

--------------------------------------------------------------------------

-- Register core prefab nodes
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/RootPart", "MITHRIL_FACTORY_CORE_ROOT_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/TopPart", "MITHRIL_FACTORY_CORE_TOP_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/Tiling1Part", "MITHRIL_FACTORY_CORE_TILING1_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/Tiling2Part", "MITHRIL_FACTORY_CORE_TILING2_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/Tiling3Part", "MITHRIL_FACTORY_CORE_TILING3_PREFAB")

mod:registerPrefabChild("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/RootPart", "MITHRIL_FACTORY_CORE_WORK_LOCATION_PREFAB", "WORK_LOCATION")

-- Register extension A prefab nodes
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/RootPart", "MITHRIL_FACTORY_EXTENSION_A_ROOT_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/TopPart", "MITHRIL_FACTORY_EXTENSION_A_TOP_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/TopPart/SmokeEmitter", "MITHRIL_FACTORY_EXTENSION_A_TOP_SMOKE_EMITTER_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/Tiling1Part", "MITHRIL_FACTORY_EXTENSION_A_TILING1_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/Tiling2Part", "MITHRIL_FACTORY_EXTENSION_A_TILING2_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/Tiling3Part", "MITHRIL_FACTORY_EXTENSION_A_TILING3_PREFAB")

mod:registerPrefabChild("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/RootPart", "MITHRIL_FACTORY_EXTENSION_A_WORK_LOCATION_PREFAB", "WORK_LOCATION")

-- Register extension B prefab nodes
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/RootPart", "MITHRIL_FACTORY_EXTENSION_B_ROOT_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/TopPart", "MITHRIL_FACTORY_EXTENSION_B_TOP_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/Tiling1Part", "MITHRIL_FACTORY_EXTENSION_B_TILING1_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/Tiling2Part", "MITHRIL_FACTORY_EXTENSION_B_TILING2_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/Tiling3Part", "MITHRIL_FACTORY_EXTENSION_B_TILING3_PREFAB")

mod:registerPrefabChild("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/RootPart", "MITHRIL_FACTORY_EXTENSION_B_WORK_LOCATION_PREFAB", "WORK_LOCATION")

-- Register door prefab nodes
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorAPart", "MITHRIL_FACTORY_DOOR_A_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorBPart", "MITHRIL_FACTORY_DOOR_B_PREFAB")

mod:registerPrefabChild(
	"models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorAPart",
	"MITHRIL_FACTORY_DOOR_A_PATH_0_PREFAB",
	"PATH 0",
	{ Position = { 0, 0, 1 }, Rotation = { 0, -180, 0 } }
)

mod:registerPrefabChild(
	"models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorAPart",
	"MITHRIL_FACTORY_DOOR_A_PATH_1_PREFAB",
	"PATH 1",
	{ Position = { 0, 0, -2 } }
)

mod:registerPrefabChild(
	"models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorBPart",
	"MITHRIL_FACTORY_DOOR_B_PATH_0_PREFAB",
	"PATH 0",
	{ Position = { 0, 0, 1 }, Rotation = { 0, -180, 0 } }
)

mod:registerPrefabChild(
	"models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorBPart",
	"MITHRIL_FACTORY_DOOR_B_PATH_1_PREFAB",
	"PATH 1",
	{ Position = { 0, 0, -2 } }
)

-- Register decoration prefab nodes
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationAPart", "MITHRIL_FACTORY_DECORATION_A_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationAPart/SmokeEmitter", "MITHRIL_FACTORY_DECORATION_A_SMOKE_EMITTER_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationBPart", "MITHRIL_FACTORY_DECORATION_B_PREFAB")
mod:registerAssetId("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationBPart/Top", "MITHRIL_FACTORY_DECORATION_B_ANTENNA_PREFAB")

--------------------------------------------------------------------------

-- Create default building part registering function 
function registerDefaultBuildingPart(_nodePrefix)
	mod:registerAsset({
		DataType = "BUILDING_PART",
		Id = _nodePrefix .. "_PART",
		ConstructorData = { DataType = "BUILDING_CONSTRUCTOR_DEFAULT", CoreObjectPrefab = _nodePrefix .. "_PREFAB" }
	})
end

local defaultNodePrefixList = {
	"MITHRIL_FACTORY_CORE_TOP",
	"MITHRIL_FACTORY_CORE_TILING1",
	"MITHRIL_FACTORY_CORE_TILING2",
	"MITHRIL_FACTORY_CORE_TILING3",
	"MITHRIL_FACTORY_EXTENSION_A_TOP",
	"MITHRIL_FACTORY_EXTENSION_A_TILING1",
	"MITHRIL_FACTORY_EXTENSION_A_TILING2",
	"MITHRIL_FACTORY_EXTENSION_A_TILING3",
	"MITHRIL_FACTORY_EXTENSION_B_TOP",
	"MITHRIL_FACTORY_EXTENSION_B_TILING1",
	"MITHRIL_FACTORY_EXTENSION_B_TILING2",
	"MITHRIL_FACTORY_EXTENSION_B_TILING3"
}

-- Register simple building part assets
for i, nodePrefix in ipairs(defaultNodePrefixList) do
	registerDefaultBuildingPart(nodePrefix)
end

--------------------------------------------------------------------------

-- Register the mithril factory core part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_CORE_ROOT_PART",
	Name = "MITHRIL_FACTORY_CORE_NAME",
	Description = "MITHRIL_FACTORY_CORE_DESC",
	Category = "CORE",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_SCALER", -- Since there are different types of building constructor, 'DataType' is necessary here
		CoreObjectPrefab = "MITHRIL_FACTORY_CORE_ROOT_PREFAB",
		EndPart = "MITHRIL_FACTORY_CORE_TOP_PART",
		FillerList = {
			"MITHRIL_FACTORY_CORE_TILING1_PART",
			"MITHRIL_FACTORY_CORE_TILING2_PART",
			"MITHRIL_FACTORY_CORE_TILING3_PART"
		},
		BasementFillerList = {
			"MITHRIL_FACTORY_CORE_TILING1_PART",
			"MITHRIL_FACTORY_CORE_TILING2_PART",
			"MITHRIL_FACTORY_CORE_TILING3_PART"
		},
		MinimumScale = 3,
		IsVertical = true
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 8.5, 8.5 }),
				Type = {
					DEFAULT = true,
					NAVIGABLE = true
				}
			}
		}
	},
	Cost = {
		UpkeepCost = { -- List of RESOURCE_QUANTITY_PAIR
			{ Resource = "GOLD", Quantity = 3 }
		},
		ResourceNeededList = {
			{ -- Can be serialized as a RESOURCE_COLLECTION
				Collection = {
					{ Resource = "WOOD", Quantity = 20 },
					{ Resource = "STONE", Quantity = 10 },
				},
			},
			{ -- Or a list of RESOURCE_QUANTITY_PAIR (single property types only)
				{ Resource = "WOOD", Quantity = 10 },
				{ Resource = "STONE", Quantity = 10 },
			},
		}
	}
})

-- Register the mithril factory extension A part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_EXTENSION_A_ROOT_PART",
	Name = "MITHRIL_FACTORY_EXTENSION_A_NAME",
	Description = "MITHRIL_FACTORY_EXTENSION_DESC",
	Category = "CORE",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_SCALER", -- Since there are different types of building constructor, 'DataType' is necessary here
		CoreObjectPrefab = "MITHRIL_FACTORY_EXTENSION_A_ROOT_PREFAB",
		EndPart = "MITHRIL_FACTORY_EXTENSION_A_TOP_PART",
		FillerList = {
			"MITHRIL_FACTORY_EXTENSION_A_TILING1_PART",
			"MITHRIL_FACTORY_EXTENSION_A_TILING2_PART",
			"MITHRIL_FACTORY_EXTENSION_A_TILING3_PART"
		},
		BasementFillerList = {
			"MITHRIL_FACTORY_EXTENSION_A_TILING1_PART",
			"MITHRIL_FACTORY_EXTENSION_A_TILING2_PART",
			"MITHRIL_FACTORY_EXTENSION_A_TILING3_PART"
		},
		MinimumScale = 3,
		IsVertical = true
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 5, 4 }),
				Type = {
					DEFAULT = true,
					NAVIGABLE = true
				}
			}
		}
	},
	Cost = {
		UpkeepCost = { -- List of RESOURCE_QUANTITY_PAIR
			{ Resource = "GOLD", Quantity = 2 }
		},
		ResourceNeededList = {
			{
				{ Resource = "PLANK", Quantity = 15 },
			},
			{
				{ Resource = "POLISHED_STONE", Quantity = 10 },
				{ Resource = "TOOL", Quantity = 2 },
			},
		}
	}
})

-- Register the mithril factory extension B part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_EXTENSION_B_ROOT_PART",
	Name = "MITHRIL_FACTORY_EXTENSION_B_NAME",
	Description = "MITHRIL_FACTORY_EXTENSION_DESC",
	Category = "CORE",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_SCALER", -- Since there are different types of building constructor, 'DataType' is necessary here
		CoreObjectPrefab = "MITHRIL_FACTORY_EXTENSION_B_ROOT_PREFAB",
		EndPart = "MITHRIL_FACTORY_EXTENSION_B_TOP_PART",
		FillerList = {
			"MITHRIL_FACTORY_EXTENSION_B_TILING1_PART",
			"MITHRIL_FACTORY_EXTENSION_B_TILING2_PART",
			"MITHRIL_FACTORY_EXTENSION_B_TILING3_PART"
		},
		BasementFillerList = {
			"MITHRIL_FACTORY_EXTENSION_B_TILING1_PART",
			"MITHRIL_FACTORY_EXTENSION_B_TILING2_PART",
			"MITHRIL_FACTORY_EXTENSION_B_TILING3_PART"
		},
		MinimumScale = 3,
		IsVertical = true
	},
	BuildingZone = {
		ZoneEntryList = {
			{
				Polygon = polygon.createRectangle({ 4.5, 5.5 }),
				Type = {
					DEFAULT = true,
					NAVIGABLE = true
				}
			}
		}
	},
	Cost = {
		UpkeepCost = { -- List of RESOURCE_QUANTITY_PAIR
			{ Resource = "GOLD", Quantity = 3 }
		},
		ResourceNeededList = {
			{
				{ Resource = "PLANK", Quantity = 10 },
				{ Resource = "TOOL", Quantity = 3 },
			},
			{
				{ Resource = "POLISHED_STONE", Quantity = 15 },
			},
		}
	}
})

-- Register the mithril factory door A part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_DOOR_A_PART",
	Name = "MITHRIL_FACTORY_DOOR_A_NAME",
	Description = "MITHRIL_FACTORY_DOOR_A_DESC",
	Category = "DOOR",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "MITHRIL_FACTORY_DOOR_A_PREFAB"
	},
	BuildingZone = {
		ZoneEntryList = {
			{ Polygon = polygon.createRectangle({ 2.5, 1.5 }, { 0, -1 }), Type = { DEFAULT = true } },
			{ Polygon = polygon.createRectangle({ 2.5, 2.5 }, { 0, -1 }), Type = { NAVIGABLE = true } },
		}
	},
	Cost = {
		ResourceNeededList = {
			{
				{ Resource = "WOOD", Quantity = 5 },
			},
		}
	}
})

-- Register the mithril factory door B part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_DOOR_B_PART",
	Name = "MITHRIL_FACTORY_DOOR_B_NAME",
	Description = "MITHRIL_FACTORY_DOOR_B_DESC",
	Category = "DOOR",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "MITHRIL_FACTORY_DOOR_B_PREFAB"
	},
	BuildingZone = {
		ZoneEntryList = {
			{ Polygon = polygon.createRectangle({ 2.2, 6 }, { 0, -4 }), Type = { DEFAULT = true } },
			{
				Polygon = {
					{ -1.5, 0 },
					{ -1.5, -5.5 },
					{ 1, -5.5 },
					{ 1, -8 },
					{ 3.5, -8 },
					{ 3.5, -2.8 },
					{ 1.5, -2.8 },
					{ 1.5, 0 },
				},
				Type = { NAVIGABLE = true }
			},
		}
	},
	Cost = {
		ResourceNeededList = {
			{
				{ Resource = "STONE", Quantity = 5 },
			},
		}
	}
})

-- Register the mithril factory decoration A part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_DECORATION_A_PART",
	Name = "MITHRIL_FACTORY_DECORATION_A_NAME",
	Description = "MITHRIL_FACTORY_DECORATION_A_DESC",
	Category = "DECORATION",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "MITHRIL_FACTORY_DECORATION_A_PREFAB"
	},
	Cost = {
		ResourceNeededList = {
			{
				{ Resource = "WOOD", Quantity = 2 },
			},
		}
	}
})

-- Register the mithril factory decoration A part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "MITHRIL_FACTORY_DECORATION_B_PART",
	Name = "MITHRIL_FACTORY_DECORATION_B_NAME",
	Description = "MITHRIL_FACTORY_DECORATION_B_DESC",
	Category = "DECORATION",
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "MITHRIL_FACTORY_DECORATION_B_PREFAB"
	},
	Cost = {
		ResourceNeededList = {
			{
				{ Resource = "STONE", Quantity = 2 },
			},
		}
	}
})

--------------------------------------------------------------------------

-- Register grass clearing components

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Core/RootPart", {
	DataType = "COMP_DIRT_RECTANGLE",
	Size = {12, 12}
})
mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/RootPart", {
	DataType = "COMP_DIRT_RECTANGLE",
	Size = {8, 8}
})
mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionB/RootPart", {
	DataType = "COMP_DIRT_RECTANGLE",
	Size = {8, 8}
})
mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorAPart", {
	DataType = "COMP_DIRT_CIRCLE",
	HardRadius = 2,
	SoftRadius = 4
})
mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorBPart", {
	DataType = "COMP_DIRT_CIRCLE",
	HardRadius = 2,
	SoftRadius = 3
})

--------------------------------------------------------------------------

-- Register core and extension parts interactive locations

mod:registerAsset({
	DataType = "INTERACTIVE_LOCATION_SETUP",
	Id = "INTERACTIVE_LOCATION_MITHRIL_FACTORY",
	PurposeList = { INTERACTIVE_LOCATION_PURPOSE.WORK },
})

mod:registerPrefabComponent("MITHRIL_FACTORY_CORE_WORK_LOCATION_PREFAB", {
	DataType = "COMP_INTERACTIVE_LOCATION",
	InteractiveLocationSetup = "INTERACTIVE_LOCATION_MITHRIL_FACTORY",
})

mod:registerPrefabComponent("MITHRIL_FACTORY_EXTENSION_A_WORK_LOCATION_PREFAB", {
	DataType = "COMP_INTERACTIVE_LOCATION",
	InteractiveLocationSetup = "INTERACTIVE_LOCATION_MITHRIL_FACTORY",
})

mod:registerPrefabComponent("MITHRIL_FACTORY_EXTENSION_B_WORK_LOCATION_PREFAB", {
	DataType = "COMP_INTERACTIVE_LOCATION",
	InteractiveLocationSetup = "INTERACTIVE_LOCATION_MITHRIL_FACTORY",
})

--------------------------------------------------------------------------

-- Register flag assigner component on the Door B collider's type to 'PLATFORM'

mod:configurePrefabFlagList("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorBPart", { "PLATFORM" })

--------------------------------------------------------------------------

-- Override building part components properties (generated by the building asset processor) to add building zones

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/TopPart", {
	DataType = "COMP_BUILDING_PART",
	FeedbackComponentListToActivate = {
		{ "MITHRIL_FACTORY_EXTENSION_A_TOP_SMOKE_EMITTER_PREFAB", "COMP_PARTICLE_EMITTER_TOGGLE" }
	}
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorAPart", {
	DataType = "COMP_BUILDING_PART",
	BuildingPartType = ATTACH_NODE_TYPE.DOOR, -- Allows the door to be used as entrance
	PathList = {
		{
			PathType = "DEFAULT",
			WayPointList = { "MITHRIL_FACTORY_DOOR_A_PATH_0_PREFAB", "MITHRIL_FACTORY_DOOR_A_PATH_1_PREFAB" },
		}
	},
	IsAlwaysGrounded = true,	-- can use this instead of `COMP_GROUNDED`
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/DoorBPart", {
	DataType = "COMP_BUILDING_PART",
	BuildingPartType = ATTACH_NODE_TYPE.DOOR, -- Allows the door to be used as entrance
	PathList = {
		{
			PathType = "DEFAULT",
			WayPointList = { "MITHRIL_FACTORY_DOOR_B_PATH_0_PREFAB", "MITHRIL_FACTORY_DOOR_B_PATH_1_PREFAB" },
		}
	},
	IsAlwaysGrounded = true,	-- can use this instead of `COMP_GROUNDED`
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationAPart", {
	DataType = "COMP_BUILDING_PART",
	BuildingPartType = ATTACH_NODE_TYPE.MINOR -- Snaps the decoration only on minor attach nodes (here only on the roofs)
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationBPart", {
	DataType = "COMP_BUILDING_PART",
	BuildingPartType = ATTACH_NODE_TYPE.MINOR -- Snaps the decoration only on minor attach nodes (here only on the roofs)
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationAPart", {
	DataType = "COMP_BUILDING_PART",
	FeedbackComponentListToActivate = {
		{ "MITHRIL_FACTORY_DECORATION_A_SMOKE_EMITTER_PREFAB", "COMP_PARTICLE_EMITTER_TOGGLE" }
	}
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationBPart", {
	DataType = "COMP_BUILDING_PART",
	FeedbackComponentListToActivate = {
		{ "MITHRIL_FACTORY_DECORATION_B_ANTENNA_PREFAB", "COMP_ANTENNA" }
	}
})

--------------------------------------------------------------------------
-- Register air vent particle system

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationAPart/SmokeEmitter", {
	DataType = "COMP_PARTICLE_EMITTER",
	ParticleSystem = "AIR_VENT_PARTICLE_SYSTEM",
	IsPlaying = true,
	IsEmitting = false
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationAPart/SmokeEmitter", {
	DataType = "COMP_PARTICLE_EMITTER_TOGGLE",
	Enabled = false
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/TopPart/SmokeEmitter", {
	DataType = "COMP_PARTICLE_EMITTER",
	ParticleSystem = "AIR_VENT_PARTICLE_SYSTEM",
	IsPlaying = true,
	IsEmitting = false
})

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/ExtensionA/TopPart/SmokeEmitter", {
	DataType = "COMP_PARTICLE_EMITTER_TOGGLE",
	Enabled = false
})

--------------------------------------------------------------------------
-- Register antenna component

mod:registerPrefabComponent("models/MithrilFactory.fbx/Prefab/MithrilFactory/Decoratives/DecorationBPart/Top", {
	DataType = "COMP_ANTENNA",
	Enabled = false,
})