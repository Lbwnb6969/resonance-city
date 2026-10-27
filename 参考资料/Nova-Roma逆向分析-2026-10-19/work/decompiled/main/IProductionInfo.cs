using Assets.Code;

public interface IProductionInfo
{
	ResourceAmount GetCost();

	int GetResult(int rID);

	bool ShowResultStorage();

	int GetOutputStorage(int rID);

	int GetOutputMaxStorage(int rID);

	int GetInputStorage(int rID);

	int GetInputMaxStorage(int rID);

	BuildingProductionUI.CustomProductionItem[] GetCustomCost();

	BuildingProductionUI.CustomProductionItem[] GetCustomResult();

	float GetProgress();

	int GetTotalBonus();

	string GetCustomText();
}
