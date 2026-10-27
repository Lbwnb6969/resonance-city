using Assets.Code;
using Assets.Code.Interface;
using UnityEngine;
using UnityEngine.Serialization;

public abstract class ExtractionBuilding : Tickable, IResourceProviderContainer, IProductionInfo, IOutputInfo, IWorkerUIDisplay
{
	[FormerlySerializedAs("clayIcon")]
	[FormerlySerializedAs("orchardIcon")]
	public Sprite productionIcon;

	public ResourceAmount resourceStorageMax;

	public GraphicalResourceStack stack;

	protected BuildingProductionUI.CustomProductionItem[] customProductionItems = new BuildingProductionUI.CustomProductionItem[1];

	protected Building b;

	protected virtual void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	protected abstract void PlacementValidation(ref PlacementValidationResult validationResult);

	protected void OnDemolished()
	{
		if (stack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(stack.resourceID, stack.Count(), b.GetCell().Position);
		}
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(stack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stack);
	}

	ResourceAmount IProductionInfo.GetCost()
	{
		return null;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		return null;
	}

	public int GetInputStorage(int rID)
	{
		return 0;
	}

	public int GetInputMaxStorage(int rID)
	{
		return 0;
	}

	public int GetOutputMaxStorage(int rID)
	{
		return resourceStorageMax.Get(rID);
	}

	public virtual int GetOutputStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.Count();
	}

	public abstract int GetResult(int rID);

	public abstract bool ShowResultStorage();

	public abstract BuildingProductionUI.CustomProductionItem[] GetCustomCost();

	public abstract float GetProgress();

	public abstract int GetTotalBonus();

	public abstract string GetCustomText();

	public abstract string GetError();

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
