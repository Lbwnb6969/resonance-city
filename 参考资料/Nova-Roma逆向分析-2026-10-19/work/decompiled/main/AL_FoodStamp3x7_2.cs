public class AL_FoodStamp3x7_2 : AL_FoodStamp
{
	public override void Init()
	{
		isUnique = true;
		ParseEditorCodes(AIBuildingBlockType.Food, "3,7:F,farm,0,0,1,1:F,farm,1,0,1,1:F,farm,2,0,1,1:F,farm,0,1,1,1:F,farm,1,1,1,1:F,farm,2,1,1,1:F,farm,0,2,1,1:F,farm,1,2,1,1:F,farm,2,2,1,1:F,0,3,1,1:F,well,1,3,1,1:F,2,3,1,1:F,farm,0,4,1,1:F,farm,1,4,1,1:F,farm,2,4,1,1:F,farm,0,5,1,1:F,farm,1,5,1,1:F,farm,2,5,1,1:F,farm,0,6,1,1:F,farm,1,6,1,1:F,farm,2,6,1,1");
	}
}
