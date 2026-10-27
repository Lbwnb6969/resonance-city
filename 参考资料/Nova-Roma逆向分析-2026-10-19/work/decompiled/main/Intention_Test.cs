using UnityEngine;

public class Intention_Test : AIIntentionBase
{
	private Intention_BuildBuilding buildIntention;

	public void Init()
	{
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		Vector3 idealPosition = GameUI.inst.GridPointerIntersection();
		if (buildIntention == null)
		{
			buildIntention = AddSubIntention<Intention_BuildBuilding>("build farm");
			buildIntention.Init("farm", AIBuildingBlockType.Food, idealPosition);
		}
		if (KillAndNullFinishedIntention(ref buildIntention))
		{
			Done = true;
		}
	}
}
