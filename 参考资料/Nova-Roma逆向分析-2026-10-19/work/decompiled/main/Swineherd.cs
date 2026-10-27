using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Swineherd : Tickable, IResourceStorage, IResourceStorageBase, IResourceProviderContainer, IOutputInfo, IProductionInfo, IWorkerUIDisplay
{
	private class Pig : InstanceSystemBehaviour.Owner
	{
		public float eatTime;

		public float lifeTime;

		public float lifeSpan;

		public int missedMeals;

		public Vector3 pos;

		public Vector3 nextPos;

		public float posMoveTime;

		public float posUpdateTime;
	}

	[Serializable]
	public class SwineherdSaveData : SaveClass<Swineherd, SwineherdSaveData>
	{
		[Serializable]
		private struct PigData
		{
			public float eatTime;

			public float lifeTime;

			public float lifeSpan;

			public int missedMeals;

			public SerializableVector3 pos;

			public SerializableVector3 nextPos;

			public float posMoveTime;

			public float posUpdateTime;
		}

		private int porkStored;

		private ResourceAmount stored;

		private int lastSlaughter;

		private int currSlaughter;

		private int eatsLastYear;

		private int eatsThisYear;

		private bool lowLitterWarning;

		private List<PigData> pigs = new List<PigData>();

		private PigData[] pigsArray;

		public override SwineherdSaveData Pack(Swineherd obj)
		{
			porkStored = obj.hamStack.Count();
			stored = obj.resourcesStored;
			lastSlaughter = obj.lastSlaughter;
			currSlaughter = obj.currSlaughter;
			lowLitterWarning = obj.lowLitterWarning;
			pigsArray = new PigData[obj.pigs.Count];
			for (int i = 0; i < obj.pigs.Count; i++)
			{
				pigsArray[i].eatTime = obj.pigs.data[i].eatTime;
				pigsArray[i].lifeTime = obj.pigs.data[i].lifeTime;
				pigsArray[i].lifeSpan = obj.pigs.data[i].lifeSpan;
				pigsArray[i].missedMeals = obj.pigs.data[i].missedMeals;
				pigsArray[i].pos = obj.pigs.data[i].pos;
				pigsArray[i].nextPos = obj.pigs.data[i].nextPos;
				pigsArray[i].posMoveTime = obj.pigs.data[i].posMoveTime;
				pigsArray[i].posUpdateTime = obj.pigs.data[i].posUpdateTime;
			}
			return this;
		}

		public override Swineherd Unpack(Swineherd obj)
		{
			obj.hamStack.Add(porkStored);
			obj.resourcesStored = stored;
			obj.lastSlaughter = lastSlaughter;
			obj.currSlaughter = currSlaughter;
			obj.lowLitterWarning = lowLitterWarning;
			if (pigsArray == null)
			{
				for (int i = 0; i < pigs.Count; i++)
				{
					Pig pig = obj.BirthPig(pigs[i].pos);
					pig.eatTime = pigs[i].eatTime;
					pig.lifeTime = pigs[i].lifeTime;
					pig.lifeSpan = pigs[i].lifeSpan;
					pig.missedMeals = pigs[i].missedMeals;
					pig.pos = pigs[i].pos;
					pig.nextPos = pigs[i].nextPos;
					pig.posMoveTime = pigs[i].posMoveTime;
					pig.posUpdateTime = pigs[i].posUpdateTime;
				}
			}
			else
			{
				for (int j = 0; j < pigsArray.Length; j++)
				{
					Pig pig2 = obj.BirthPig(pigsArray[j].pos);
					pig2.eatTime = pigsArray[j].eatTime;
					pig2.lifeTime = pigsArray[j].lifeTime;
					pig2.lifeSpan = pigsArray[j].lifeSpan;
					pig2.missedMeals = pigsArray[j].missedMeals;
					pig2.pos = pigsArray[j].pos;
					pig2.nextPos = pigsArray[j].nextPos;
					pig2.posMoveTime = pigsArray[j].posMoveTime;
					pig2.posUpdateTime = pigsArray[j].posUpdateTime;
				}
			}
			return obj;
		}
	}

	public GraphicalResourceStack hamStack;

	private int currSlaughter;

	private int lastSlaughter;

	private float timeWithNoPrereqs;

	public ResourceAmount resourceStorageMax;

	private ResourceAmount resourcesStored = new ResourceAmount();

	public Transform resourceDropoff;

	private float eatTimeYear;

	public Material material;

	public MeshRenderer buildingMesh;

	private Building b;

	public Transform pigCenter;

	private ArrayExt<Pig> pigs = new ArrayExt<Pig>(20);

	private EventHandler<SeasonEventData> seasonEvent;

	private bool lowLitterWarning;

	public int MaxSlaughter = 6;

	private List<Pig> pigsToSlaughter = new List<Pig>();

	public int pigsPerLitter = 7;

	public float yearsUntilBreedable = 1f;

	public float yearsUntilSlaughter = 3f;

	public int minPigsAfterSlaughter = 5;

	public ResourceAmount pigEatAmount;

	private ResourceAmount cost = new ResourceAmount();

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(hamStack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(hamStack);
	}

	string IOutputInfo.GetError()
	{
		if (hamStack.Count() >= hamStack.MaxCapacity())
		{
			return string.Format(ScriptLocalization.workerui_error_internalstoragefull, "<sprite name=icon_pork>");
		}
		if (timeWithNoPrereqs > 120f)
		{
			return LocalizationManager.GetTranslation("NoFoodForPigs");
		}
		return null;
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStatistics.AddConsumption(LandMass(), "swineherd", 0, resources.Get(0));
		resourcesStored.Add(in resources);
		resources.Clear();
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	int IResourceStorageBase.SpaceAvailable(int t)
	{
		return resourceStorageMax.Get(t) - resourcesStored.Get(t);
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		if (resourceID == 10)
		{
			return hamStack.MaxCapacity();
		}
		return 0;
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		if (resourceID != hamStack.resourceID)
		{
			return 0;
		}
		return hamStack.AvailableAmount();
	}

	bool IResourceStorage.AcceptsType(int resourceID)
	{
		return false;
	}

	bool IResourceStorage.StoresTypePublic(int resourceID)
	{
		return resourceID == 10;
	}

	Vector3 IResourceStorageBase.DropOffLocation(int t)
	{
		return resourceDropoff.position;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
	}

	private void Start()
	{
		eatTimeYear = SeasonManager.inst.TimeInYear() * 0.6f;
	}

	private Pig BirthPig(Vector3 p)
	{
		Pig pig = new Pig();
		pig.eatTime = eatTimeYear;
		pig.lifeTime = SRand.Range(0f, SeasonManager.inst.TimeInYear());
		pig.lifeSpan = SeasonManager.inst.TimeInYear() * SRand.Range(4f, 5f);
		pig.posUpdateTime = SRand.Range(0.5f, 4f);
		pig.pos = p + new Vector3(SRand.Range(-0.1f, 0.1f), 0f, SRand.Range(-0.1f, 0.1f));
		pig.nextPos = pig.pos + new Vector3(SRand.Range(-0.1f, 0.1f), 0f, SRand.Range(-0.1f, 0.1f));
		PigSystem.inst.AddInstance(pig, pig.pos, Quaternion.identity, Vector3.one);
		pigs.Add(pig);
		return pig;
	}

	private void DeletePig(int idx)
	{
		DeletePig(pigs.data[idx]);
	}

	private void DeletePig(Pig p)
	{
		PigSystem.inst.ReleaseInstance(p);
		pigs.RemoveSwap(p);
	}

	private void OnBuilt()
	{
		resourcesStored.Set(0, 5);
		for (int i = 0; i < 2; i++)
		{
			BirthPig(b.Center());
		}
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		return true;
	}

	private void OnAddJobs(Building b)
	{
		List<Job> jobs = GetComponent<Building>().jobs;
		if (!b.VerifyJobIs(0, typeof(FreeResourceGathererJob)))
		{
			b.SetAndAddJob(0, new FreeResourceGathererJob(b, _consumeOnPickup: true));
		}
		(jobs[0] as FreeResourceGathererJob).Configure(0, JobFilter);
		if (!b.VerifyJobIs(1, typeof(FreeResourceGathererJob)))
		{
			b.SetAndAddJob(1, new FreeResourceGathererJob(b, _consumeOnPickup: true));
		}
		(jobs[1] as FreeResourceGathererJob).Configure(9, JobFilter);
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!b.IsBuilt())
		{
			return;
		}
		float num = 1f;
		if (b.GetWorkerPercent() <= 0f)
		{
			num = 2f;
		}
		bool isVisible = buildingMesh.isVisible;
		Matrix4x4[][] data = PigSystem.inst.silos.data;
		Vector3 position = pigCenter.position;
		for (int i = 0; i < pigs.Count; i++)
		{
			Pig pig = pigs.data[i];
			pig.eatTime -= dt;
			if (isVisible)
			{
				pig.posUpdateTime -= dt;
				if (Mathff.DistSqrdXZ(pig.nextPos, pig.pos) <= 0f)
				{
					pig.posUpdateTime = -1f;
				}
				if (pig.posUpdateTime < 0f)
				{
					pig.posUpdateTime = SRand.Range(0.5f, 4f);
					pig.pos = data[pig.s][pig.idx].GetPosition();
					pig.nextPos = pig.pos + new Vector3(SRand.Range(-0.2f, 0.2f), 0f, SRand.Range(-0.2f, 0.2f));
					if (Mathff.DistSqrdXZ(pig.nextPos, position) > 0.16000001f)
					{
						pig.nextPos = position + (pig.nextPos - position).normalized * 0.4f;
					}
					pig.posMoveTime = 0f;
				}
				pig.posMoveTime += dt;
				float t = Mathf.Clamp01(pig.posMoveTime * 0.66f);
				Vector3 pos = Vector3.Lerp(pig.pos, pig.nextPos, Mathf.SmoothStep(0f, 1f, t));
				float num2 = pig.lifeTime / pig.lifeSpan;
				num2 = Mathff.Lerp(0.5f, 1.5f, Mathff.Clamp01(num2 / 0.3f));
				Mathff.SetTRS(ref data[pig.s][pig.idx], pos, Quaternion.LookRotation(pig.nextPos - pig.pos), new Vector3(num2, num2, num2));
			}
			if (pig.eatTime < 0f)
			{
				if (resourcesStored.TrySubtract(pigEatAmount))
				{
					pig.missedMeals -= 2;
					if (pig.missedMeals < 0)
					{
						pig.missedMeals = 0;
					}
					ResourceStatistics.AddConsumption(LandMass(), "swineherd", 0, pigEatAmount.Get(0));
					ResourceStatistics.AddConsumption(LandMass(), "swineherd", 9, pigEatAmount.Get(9));
				}
				else
				{
					pig.missedMeals++;
				}
				pig.missedMeals = Mathff.Max(pig.missedMeals, 0);
				pig.eatTime = eatTimeYear;
			}
			pig.lifeTime += dt * num;
			if (pig.lifeTime > pig.lifeSpan && pigs.Count > 2)
			{
				DeletePig(i);
				i--;
			}
		}
		if (resourcesStored.Get(0) <= 0)
		{
			timeWithNoPrereqs += dt;
		}
		else
		{
			timeWithNoPrereqs = 0f;
		}
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		b = GetComponent<Building>();
		seasonEvent = Broadcast.SeasonEvent.Listen(Inst_OnSeasonChange);
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		Broadcast.SeasonEvent.Unlisten(seasonEvent);
		for (int i = 0; i < pigs.Count; i++)
		{
			PigSystem.inst.ReleaseInstance(pigs.data[i]);
		}
		pigs.Clear();
	}

	private void Inst_OnSeasonChange(object sender, SeasonEventData e)
	{
		List<Pig> list = new List<Pig>();
		int num = 0;
		for (int i = 0; i < pigs.Count; i++)
		{
			if (pigs.data[i].lifeTime > SeasonManager.inst.TimeInYear() * yearsUntilBreedable)
			{
				num++;
				if (num % 2 == 0)
				{
					list.Add(pigs.data[i]);
				}
			}
		}
		if (num > 0)
		{
			lowLitterWarning = false;
			for (int j = 0; j < list.Count; j++)
			{
				int num2 = pigsPerLitter + SRand.Range(-1, 1);
				if (b.GetWorkerPercent() > 0f)
				{
					if (list[j].missedMeals > 0)
					{
						num2 = SRand.Range(1, 2);
					}
				}
				else
				{
					num2 = 1;
				}
				if (list[j].missedMeals > 0)
				{
					lowLitterWarning = true;
				}
				for (int k = 0; k < num2; k++)
				{
					BirthPig(list[j].pos);
				}
				if (pigs.Count > 20)
				{
					break;
				}
			}
		}
		DoSlaughter();
		lastSlaughter = currSlaughter;
		currSlaughter = 0;
	}

	private int GetSlaughterCount()
	{
		int num = 0;
		float num2 = SeasonManager.inst.TimeInYear() * yearsUntilSlaughter;
		for (int i = 0; i < pigs.Count; i++)
		{
			if (pigs.data[i].lifeTime > num2)
			{
				num++;
			}
		}
		if (pigs.Count - num < minPigsAfterSlaughter)
		{
			num = pigs.Count - minPigsAfterSlaughter;
		}
		return Mathff.Min(num, MaxSlaughter);
	}

	private int UpdateSlaughterCount()
	{
		float num = SeasonManager.inst.TimeInYear() * yearsUntilSlaughter;
		pigsToSlaughter.Clear();
		for (int i = 0; i < pigs.Count; i++)
		{
			if (pigs.data[i].lifeTime > num && pigsToSlaughter.Count < MaxSlaughter)
			{
				pigsToSlaughter.Add(pigs.data[i]);
			}
		}
		int num2 = pigsToSlaughter.Count;
		if (pigs.Count - num2 < minPigsAfterSlaughter)
		{
			num2 = pigs.Count - minPigsAfterSlaughter;
		}
		return num2;
	}

	public void DoSlaughter()
	{
		if (!(b.GetWorkerPercent() > 0f))
		{
			return;
		}
		int num = UpdateSlaughterCount();
		if (num > 0)
		{
			bool flag = true;
			Renderer componentInChildren = b.GetComponentInChildren<Renderer>();
			if (componentInChildren != null)
			{
				flag = componentInChildren.isVisible;
			}
			for (int i = 0; i < num; i++)
			{
				if (flag)
				{
					EffectsMan.inst.GibsEffect.CreateAndPlay(pigsToSlaughter[i].pos);
				}
				DeletePig(pigs.IndexOf(pigsToSlaughter[i]));
			}
			int num2 = num;
			hamStack.Add(num2);
			if (flag)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), 10, num2);
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("PigSlaughter", b.cachedPos);
			}
			ResourceStatistics.AddProduction(LandMass(), "swineherd", 10, num2);
			currSlaughter += num2;
			for (int j = 0; j < b.jobs.Count; j++)
			{
				if (b.jobs[j] is DeliveryJob)
				{
					(b.jobs[j] as DeliveryJob).forceSearch = true;
				}
			}
		}
		pigsToSlaughter.Clear();
	}

	private void OnDemolished()
	{
		if (hamStack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(hamStack.resourceID, hamStack.Count() + pigs.Count, hamStack.transform.position);
		}
	}

	public ResourceAmount GetCost()
	{
		float num = SeasonManager.inst.TimeInYear() / 4f;
		cost.Set(0, pigEatAmount.Get(0) * Mathf.CeilToInt(num / eatTimeYear * (float)MaxSlaughter));
		cost.Set(9, pigEatAmount.Get(9) * Mathf.CeilToInt(num / eatTimeYear * (float)MaxSlaughter));
		return cost;
	}

	public int GetResult(int rID)
	{
		if (rID == 10)
		{
			return Mathff.Max(lastSlaughter, Mathff.Max(1, GetSlaughterCount()));
		}
		return 0;
	}

	public bool ShowResultStorage()
	{
		return true;
	}

	public int GetOutputStorage(int rID)
	{
		if (rID != 10)
		{
			return 0;
		}
		return hamStack.Count();
	}

	public int GetInputStorage(int rID)
	{
		return resourcesStored.Get(rID);
	}

	public int GetOutputMaxStorage(int rID)
	{
		if (rID != 10)
		{
			return 0;
		}
		return hamStack.MaxCapacity();
	}

	public int GetInputMaxStorage(int rID)
	{
		return resourceStorageMax.Get(rID);
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomCost()
	{
		return null;
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomResult()
	{
		return null;
	}

	public float GetProgress()
	{
		if (GetSlaughterCount() > 0)
		{
			return SeasonManager.inst.seasonElapsedTime / SeasonManager.inst.CurrentSeason.duration;
		}
		return 0f;
	}

	public int GetTotalBonus()
	{
		return 0;
	}

	public string GetCustomText()
	{
		string text = "";
		text = text + Environment.NewLine + LocalizationManager.GetTranslation("SwineherdYieldDesc") + Environment.NewLine;
		if (GetSlaughterCount() <= 0)
		{
			text = text + Environment.NewLine + "<color=yellow>" + LocalizationManager.GetTranslation("NoEnoughPigsToSlaughter") + "</color>";
		}
		if (lowLitterWarning)
		{
			text = text + "<color=yellow>" + LocalizationManager.GetTranslation("NoFoodForPigsLastSeason") + "</color>\n";
		}
		return text;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
