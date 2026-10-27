namespace Assets;

public interface AIPersonality
{
	bool CompletesRoads { get; }

	bool AllowLibraries { get; }

	int StartThreatLevel { get; }

	bool BelievesInWalls { get; }

	int ExtraHeightForTowers { get; }

	AILayoutBlock[] BlockStamps { get; }
}
