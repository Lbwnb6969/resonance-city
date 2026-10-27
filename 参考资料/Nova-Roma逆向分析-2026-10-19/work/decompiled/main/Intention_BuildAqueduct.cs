using System;

public class Intention_BuildAqueduct : AIIntentionBase
{
	private Intention_BuildExactBuilding buildPier;

	private Intention_BuildExactBuilding buildAqueduct;

	[NonSerialized]
	public Cell targetCell;

	public void Init(Cell cell)
	{
		targetCell = cell;
		transform.position = targetCell.Center2D;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (targetCell.StructureFind<Aqueduct>() != null)
		{
			Done = true;
			return;
		}
		if (targetCell.Type == TerrainType.Water && !targetCell.SubStructureCompareUniqueNameAll(World.pierHash) && buildPier == null)
		{
			buildPier = AddSubIntention<Intention_BuildExactBuilding>("build pier");
			buildPier.Init("pier", targetCell.Position, 0f, demoExisting: true);
		}
		if (((targetCell.Type == TerrainType.Water && targetCell.SubStructureCompareUniqueNameAll(World.pierHash)) || targetCell.Type == TerrainType.None) && buildAqueduct == null)
		{
			buildAqueduct = AddSubIntention<Intention_BuildExactBuilding>("build aqueduct");
			buildAqueduct.Init("aqueduct", targetCell.Position);
		}
		KillAndNullFinishedIntention(ref buildPier);
		if (KillAndNullFinishedIntention(ref buildAqueduct))
		{
			Done = true;
		}
	}
}
