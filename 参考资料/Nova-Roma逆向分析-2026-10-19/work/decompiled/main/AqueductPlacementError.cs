public enum AqueductPlacementError
{
	None,
	UsingSourceAsIncoming,
	UsingDestinationAsOutgoing,
	TooFlat,
	TooSteep,
	NotEnoughResources,
	AlreadyConnected,
	CantIntersectBuilding,
	NoAvailableSlots,
	InOcean,
	TooShort,
	CoincidentWithExistingLine,
	DamNoWaterBehindWall,
	DamTapApproachTooOblique,
	DamWaterTooLow
}
