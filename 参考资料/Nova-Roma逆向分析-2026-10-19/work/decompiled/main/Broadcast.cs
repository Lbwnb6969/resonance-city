public class Broadcast
{
	public static BuildingBroadcast<OnBuildingAddRemove> BuildingAddRemove = new BuildingBroadcast<OnBuildingAddRemove>();

	public static BuildingBroadcast<OnBuildingOpenClose> BuildingOpenClose = new BuildingBroadcast<OnBuildingOpenClose>();

	public static BuildingBroadcast<OnBuildingBuilt> BuildingBuilt = new BuildingBroadcast<OnBuildingBuilt>();

	public static EventBroadcast<OnCemetryEvent> CemeteryEvent = new EventBroadcast<OnCemetryEvent>();

	public static EventBroadcast<SeasonEventData> SeasonEvent = new EventBroadcast<SeasonEventData>();

	public static EventBroadcast<TimeOfDayEventData> MorningEvent = new EventBroadcast<TimeOfDayEventData>();

	public static EventBroadcast<TimeOfDayEventData> EveningEvent = new EventBroadcast<TimeOfDayEventData>();

	public static EventBroadcast<NewYearEvent> NewYearEvent = new EventBroadcast<NewYearEvent>();

	public static EventBroadcast<OnStorageFullEvent> StorageFullEvent = new EventBroadcast<OnStorageFullEvent>();

	public static EventBroadcast<OnAICastleRegionUpdateEvent> CastleRegionUpdateEvent = new EventBroadcast<OnAICastleRegionUpdateEvent>();

	public static EventBroadcast<OnWolfKillVillager> WolfKillVillagerEvent = new EventBroadcast<OnWolfKillVillager>();

	public static EventBroadcast<OnTechnologyTreeUnlock> TechnologyTreeUnlockEvent = new EventBroadcast<OnTechnologyTreeUnlock>();

	public static EventBroadcast<OnSaveEvent> OnSaveEvent = new EventBroadcast<OnSaveEvent>();

	public static EventBroadcast<OnLoadedEvent> OnLoadedEvent = new EventBroadcast<OnLoadedEvent>();

	public static EventBroadcast<int> UpdateAIWall = new EventBroadcast<int>();

	public static void Clear()
	{
		BuildingAddRemove.Clear();
		BuildingOpenClose.Clear();
		BuildingBuilt.Clear();
		CemeteryEvent.Clear();
		SeasonEvent.Clear();
		MorningEvent.Clear();
		EveningEvent.Clear();
		NewYearEvent.Clear();
		StorageFullEvent.Clear();
		CastleRegionUpdateEvent.Clear();
		WolfKillVillagerEvent.Clear();
		UpdateAIWall.Clear();
	}
}
