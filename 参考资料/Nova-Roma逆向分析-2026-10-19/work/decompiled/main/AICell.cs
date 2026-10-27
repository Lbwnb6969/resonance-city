using System;

[Serializable]
public class AICell : GridCell
{
	[NonSerialized]
	public AILayoutBlock blockReference;

	[NonSerialized]
	public AIBuildingMeta buildingMeta;

	public bool Road;

	internal bool invalid;
}
