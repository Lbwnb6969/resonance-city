local mod = ...

mod:registerAssetId("models/Smoke.png", "SMOKE_TEXTURE")

mod:registerAsset({
	DataType = "MATERIAL",
	Id = "SMOKE_MATERIAL",
	BackFaceVisible = true,
	AlbedoTexture = "SMOKE_TEXTURE"
})

mod:registerAsset({
	DataType = "PARTICLE_SYSTEM",
	Id = "AIR_VENT_PARTICLE_SYSTEM",
	Material = "SMOKE_MATERIAL",
	BillboardBehavior = PARTICLE_BILLBOARD_BEHAVIOR.FACE_CAMERA,
	Duration = 4,
	Looping = true,
	Delay = {0,0},
	LifeTime = 12,
	StartSpeed = { 0.2, 0.33 },
	StartSize = { 4, 5 },
	StartRotation = { 0, 0 },
	StartColor = { 1, 1, 1, 0.07 },
	GravityModifier = 0,
	RateOverTime = 12,
	BurstList = {},
	Shape = {
		DataType = "PARTICLE_EMITTER_SHAPE_CONE",
		Angle = 3.46,
		Radius = 0.0001,
	},
	LinearVelocity = {
		DataType = "PARTICLE_FLOAT3_VALUE_CONSTANT_RANDOM",
		ValueA = { 0.05, 0, 0.05 },
		ValueB = { 0.03, 0.2, 0.03 },
	},
	ColorOverLifeTime = {
		DataType = "GRADIENT",
		ColorList = {
			{ T = 0, Color = { 0.6, 0.6, 0.6, 1 } },
			{ T = 1, Color = { 0.1, 0.1, 0.1, 1 } }
		},
		AlphaList = {
			{ T = 0, Alpha = 0 },
			{ T = 0.3, Alpha = 100 },
			{ T = 1, Alpha = 0 }
		},
	},
	SizeOverLifetime = {
		{ T = 0, Value = 0.1 },
		{ T = 0.7, Value = 0.25 },
		{ T = 1, Value = 0.3 }
	},
	RotationOverLifetime = { -45, 45 },
})