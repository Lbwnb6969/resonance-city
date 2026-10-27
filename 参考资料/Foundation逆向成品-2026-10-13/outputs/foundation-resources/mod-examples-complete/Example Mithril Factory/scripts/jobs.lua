local mod = ...

-- Register mithril miner job
mod:registerAsset({
	DataType = "JOB",
	Id = "MITHRIL_MINER",
	JobName = "MITHRIL_MINER_NAME",
	JobDescription = "MITHRIL_MINER_DESC",
	CharacterSetup = {},
	IsLockedByDefault = true,
	UseWorkplaceBehavior = true,
	AssetJobProgression = "DEFAULT_JOB_PROGRESSION"
})

-- Register mithril artisan job (used here to craft chainmails AND necklaces)
mod:registerAsset({
	DataType = "JOB",
	Id = "MITHRIL_ARTISAN",
	JobName = "MITHRIL_ARTISAN_NAME",
	JobDescription = "MITHRIL_ARTISAN_DESC",
	CharacterSetup = {},
	IsLockedByDefault = true,
	UseWorkplaceBehavior = true,
	AssetJobProgression = "DEFAULT_JOB_PROGRESSION"
})

mod:overrideAsset({
	Id = "STATUS_VILLAGER_SERF",
	CompatibleJobList = {
		Action = "APPEND",
		"MITHRIL_ARTISAN",
		"MITHRIL_MINER"
	}
})