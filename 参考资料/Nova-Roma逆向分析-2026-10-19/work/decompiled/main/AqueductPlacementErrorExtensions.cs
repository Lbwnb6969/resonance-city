using I2.Loc;

public static class AqueductPlacementErrorExtensions
{
	public static string GetErrorString(this AqueductPlacementError error)
	{
		return error switch
		{
			AqueductPlacementError.UsingSourceAsIncoming => ScriptLocalization.AqueductUsingSourceAsIncoming, 
			AqueductPlacementError.UsingDestinationAsOutgoing => ScriptLocalization.AqueductUsingDestinationAsOutgoing, 
			AqueductPlacementError.TooFlat => ScriptLocalization.AqueductTooFlat, 
			AqueductPlacementError.TooSteep => ScriptLocalization.AqueductTooSteep, 
			AqueductPlacementError.NotEnoughResources => ScriptLocalization.b_Insufficient_resources_b, 
			AqueductPlacementError.AlreadyConnected => ScriptLocalization.AqueductAlreadyConnected, 
			AqueductPlacementError.NoAvailableSlots => LocalizationManager.GetTranslation("aqueduct_noconnectionslots"), 
			AqueductPlacementError.InOcean => LocalizationManager.GetTranslation("aqueduct_in_ocean"), 
			AqueductPlacementError.CantIntersectBuilding => LocalizationManager.GetTranslation("aqueduct_intersecting_building"), 
			AqueductPlacementError.TooShort => LocalizationManager.GetTranslation("aqueduct_too_short"), 
			AqueductPlacementError.CoincidentWithExistingLine => LocalizationManager.GetTranslation("aqueduct_coincident_line"), 
			AqueductPlacementError.DamNoWaterBehindWall => ScriptLocalization.pvr_nowateronotherside_error, 
			AqueductPlacementError.DamTapApproachTooOblique => LocalizationManager.GetTranslation("aqueduct_dam_tap_approach_angle"), 
			AqueductPlacementError.DamWaterTooLow => LocalizationManager.GetTranslation("aqueduct_dam_water_too_low"), 
			_ => "", 
		};
	}
}
