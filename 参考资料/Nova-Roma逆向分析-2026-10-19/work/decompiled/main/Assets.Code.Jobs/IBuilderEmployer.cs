namespace Assets.Code.Jobs;

public interface IBuilderEmployer : IEmployer
{
	string FriendlyName();

	void GetNextResourceNeededToFinishConstruction(out int type, out int amount);

	void PromiseResources(int _resourceID, int num, Villager villager);

	void EndPromise(Villager villager);

	void AddBuildResource(int resourceID, int amount);

	bool HasEnoughToBuild();

	void UpdateBuildProgress();

	void GetBoundingFootprint(out int minX, out int minZ, out int maxX, out int maxZ);
}
