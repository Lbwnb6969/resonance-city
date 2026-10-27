public class AL_FoodStamp3x3_2 : AL_FoodStamp
{
	public override void Init()
	{
		isUnique = true;
		ParseEditorCodes(AIBuildingBlockType.Food, "3,3:F,farm,0,0,1,1:F,farm,0,1,1,1:F,farm,0,2,1,1:F,farm,1,0,1,1:F,farm,1,1,1,1:F,farm,1,2,1,1:F,farm,2,0,1,1:F,farm,2,1,1,1:F,farm,2,2,1,1");
	}
}
