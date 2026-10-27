local mod = ...

mod:registerAsset({ 
	DataType = "BUILDING_FUNCTION_WORKPLACE",
	Id = "MITHRIL_FACTORY_CORE_FUNCTION",
	WorkerCapacity = 4,
	RelatedJob = { Job = "MITHRIL_MINER", Behavior = "WORK_BEHAVIOR" },
	ResourceProduced = { -- Necessarily a list of 'RESOURCE_QUANTITY_PAIR', no need to specify the DataType	
		{ Resource = "MITHRIL_ORE", Quantity = 5 }
	}
})

mod:registerAsset({ 
	DataType = "BUILDING_FUNCTION_WORKPLACE",
	Id = "MITHRIL_FACTORY_EXTENSION_A_FUNCTION",
	WorkerCapacity = 1,
	RelatedJob = { Job = "MITHRIL_ARTISAN", Behavior = "MY_CUSTOM_BEHAVIOR_TREE" },
	InputInventoryCapacity = {{ Resource = "MITHRIL_ORE", Quantity = 20 }},
	ResourceListNeeded = {{ Resource = "MITHRIL_ORE", Quantity = 4 }},
	ResourceProduced = {{ Resource = "MITHRIL_CHAINMAIL", Quantity = 2 }}
})

mod:registerAsset({ 
	DataType = "BUILDING_FUNCTION_WORKPLACE",
	Id = "MITHRIL_FACTORY_EXTENSION_B_FUNCTION",
	WorkerCapacity = 1,
	RelatedJob = { Job = "MITHRIL_ARTISAN", Behavior = "WORK_BEHAVIOR" },
	InputInventoryCapacity = {{ Resource = "MITHRIL_ORE", Quantity = 30 }},
	ResourceListNeeded = {{ Resource = "MITHRIL_ORE", Quantity = 5 }},
	ResourceProduced = {{ Resource = "MITHRIL_NECKLACE", Quantity = 1 }}
})
