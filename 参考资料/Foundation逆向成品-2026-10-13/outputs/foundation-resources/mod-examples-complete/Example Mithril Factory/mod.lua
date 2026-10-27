local mithrilFactoryMod = foundation.createMod();

-- Resources and their assets (icons)
mithrilFactoryMod:dofile("scripts/resources.lua")

-- Jobs
mithrilFactoryMod:dofile("scripts/jobs.lua")

-- Particle system
mithrilFactoryMod:dofile("scripts/particle_system.lua")

-- Components
mithrilFactoryMod:dofile("scripts/component/COMP_ANTENNA.lua")

-- Register new building part types (enumeration values)
mithrilFactoryMod:registerEnumValue("BUILDING_PART_TYPE", "EXTENSION")
mithrilFactoryMod:registerEnumValue("BUILDING_PART_TYPE", "DECORATION")

-- Monuments (mithril factory and Sci-Fi bridge)
mithrilFactoryMod:dofile("scripts/behavior_tree.lua")
mithrilFactoryMod:dofile("scripts/mithril_factory/monument.lua")
mithrilFactoryMod:dofile("scripts/sci_fi_bridge/monument.lua")
mithrilFactoryMod:dofile("scripts/sci_fi_wall/wall.lua")

-- Override default common progress tiers
mithrilFactoryMod:overrideAsset({
	Id = "PROGRESS_TIER_COMMON_T1",
	UnlockableList = {
		Action = "APPEND",
		"UNLOCKABLE_MITHRIL_FACTORY",
	},
})

mithrilFactoryMod:overrideAsset({
	Id = "PROGRESS_TIER_COMMON_T2",
	UnlockableList = {
		Action = "APPEND",
		"UNLOCKABLE_SCI_FI_BRIDGE",
		"UNLOCKABLE_SCI_FI_WALL"
	}
})

-- Override default balancing
mithrilFactoryMod:overrideAsset({
	Id = "DEFAULT_BALANCING",
	Name = "NOT_SO_DEFAULT_NOW",
	TerritoryPrice = {
		Action = "APPEND", -- Append the following value(s) to the existing list
		{ Resource = "WOOD", Quantity = 50 }, -- Append the price of 50 wood to purchase a tile, in addition to the default 500 gold
	},
	StartingTileResourceRequirement = {
		Action = "OVERRIDE", -- Override the whole list with the following value(s), optional (since the list will be overriden by default)
		{ Resource = "WOOD", Quantity = 20 }, -- Replace the starting tile resource requirement to allow any tile containing only 20 trees to be the first tile
	}
})