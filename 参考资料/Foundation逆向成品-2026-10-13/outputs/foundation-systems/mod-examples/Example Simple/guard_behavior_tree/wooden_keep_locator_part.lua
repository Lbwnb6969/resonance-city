local mod = ...

mod:registerAssetId("models/soldier_locator.fbx/Prefab/Arrow", "PREFAB_SOLDIER_LOCATOR")

--------------------------------------------------------------------------
-- Create COMP_GUARD_LOCATOR (doesn't do anything, except it is used to locate locators)
local COMP_GUARD_LOCATOR = {
	TypeName = "COMP_GUARD_LOCATOR",
	ParentType = "COMPONENT",
	Properties = {
		{ Name = "AssignedSoldier", Type = "COMP_AGENT", Default = nil, Flags = { "SAVE_GAME" } },
	}
}

function COMP_GUARD_LOCATOR:isSoldierAssigned()
	return self.AssignedSoldier ~= nil
end

function COMP_GUARD_LOCATOR:assignSoldier(_agent)
	if (not self:isSoldierAssigned()) then
		self.AssignedSoldier = _agent
	else
		mod:logError("Cannot assign soldier, another one is already assigned")
	end
end

function COMP_GUARD_LOCATOR:unassignSoldier()
	if (self:isSoldierAssigned()) then
		self.AssignedSoldier = nil
	else
		mod:logError("Cannot unassign soldier, none is currently assigned")
	end
end

mod:registerClass(COMP_GUARD_LOCATOR)

--------------------------------------------------------------------------
-- Add COMP_BUILDING_PART and COMP_GUARD_LOCATOR on soldier guard locator prefab
mod:registerPrefabComponent("models/soldier_locator.fbx/Prefab/Arrow", { DataType = "COMP_BUILDING_PART" })
mod:registerPrefabComponent("models/soldier_locator.fbx/Prefab/Arrow", { DataType = "COMP_GUARD_LOCATOR" })

--------------------------------------------------------------------------
-- Add a new job for soldier guard
mod:registerAsset({
	DataType = "JOB",
	Id = "JOB_SOLDIER_GUARD",
	JobName = "MY_MOD_JOB_SOLDIER_GUARD",
	DefaultBehavior = "BEHAVIOR_SOLDIER_GUARD_LOCATOR",
	AssetJobProgression = "COMBATANT_JOB_PROGRESSION"
})

--------------------------------------------------------------------------
-- Add soldier guard job in minimum status required
mod:overrideAsset({
	Id = "STATUS_COMBATANT_MILITIAMAN",
	CompatibleJobList = {
		Action = "APPEND",
		"JOB_SOLDIER_GUARD"
	}
})
--------------------------------------------------------------------------
-- Add a new building function workplace to set the soldier guard behavior
mod:registerAsset({
	DataType = "BUILDING_FUNCTION_WORKPLACE",
	Id = "BUILDING_FUNCTION_WORKPLACE_SOLDIER_GUARD",
	RelatedJob = {
		DataType = "ASSOCIATION_JOB_BEHAVIOR",
		Job = "JOB_SOLDIER_GUARD",
		Behavior = "BEHAVIOR_SOLDIER_GUARD_LOCATOR"
	}
})

--------------------------------------------------------------------------
-- Add new building part type LOCATOR
mod:registerEnumValue("BUILDING_PART_TYPE", "LOCATOR")

--------------------------------------------------------------------------
-- Register guard locator building part
mod:registerAsset({
	DataType = "BUILDING_PART",
	Id = "SOLDIER_PATROL_LOCATOR_PART",
	Name = "SOLDIER_GUARD_LOCATOR_NAME",
	Description = "SOLDIER_GUARD_LOCATOR_DESC",
	Category = BUILDING_PART_TYPE.LOCATOR,
	IsVisibleWhenBuilt = false,
	IsShowInUi = true,
	ConstructorData = {
		DataType = "BUILDING_CONSTRUCTOR_DEFAULT",
		CoreObjectPrefab = "PREFAB_SOLDIER_LOCATOR"
	},
	AssetBuildingFunction = "BUILDING_FUNCTION_WORKPLACE_SOLDIER_GUARD",
	BuildingZone = {},
	Cost = {}
})

--------------------------------------------------------------------------
-- Add this building part to the Castle keep's part list
mod:overrideAsset({
	Id = "BUILDING_CASTLE_CASTLE_KEEP",
	AssetBuildingPartList = {
		Action = "APPEND",
		"SOLDIER_PATROL_LOCATOR_PART"
	}
})