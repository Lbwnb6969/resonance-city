using System;
using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

public class ResourceStatistics : MonoBehaviour
{
	[Serializable]
	public struct Statistics
	{
		public Dictionary<string, ResourceAmount> data;

		public ResourceAmount amount;

		public void Add(string uniqueCategory, ResourceAmount amt)
		{
			if (data == null)
			{
				data = new Dictionary<string, ResourceAmount>(32);
			}
			if (!data.ContainsKey(uniqueCategory))
			{
				data.Add(uniqueCategory, new ResourceAmount());
			}
			Resource resource = null;
			for (int i = 0; i < amt.resources.Count; i++)
			{
				resource = amt.resources[i];
				if (resource.Amount > 0)
				{
					data[uniqueCategory].Add(resource.resourceID, resource.Amount);
				}
			}
		}

		public void Add(string uniqueCategory, int rType, int amt)
		{
			if (data == null)
			{
				data = new Dictionary<string, ResourceAmount>(32);
			}
			if (!data.ContainsKey(uniqueCategory))
			{
				data.Add(uniqueCategory, new ResourceAmount());
			}
			data[uniqueCategory].Add(rType, amt);
		}

		public bool Contains(int rID)
		{
			if (data == null || data.Count == 0)
			{
				return false;
			}
			foreach (KeyValuePair<string, ResourceAmount> datum in data)
			{
				if (datum.Value.Contains(rID))
				{
					return true;
				}
			}
			return false;
		}

		public void Reset()
		{
			data?.Clear();
			amount?.Clear();
		}
	}

	[Serializable]
	public class ResourceStatisticsSaveData : SaveClass<ResourceStatistics, ResourceStatisticsSaveData>
	{
		[Serializable]
		public struct StatisticsWrapper
		{
			public SerializableDictionary<string, ResourceAmount> data;

			public ResourceAmount amount;
		}

		public StatisticsWrapper[] currProductionData;

		public StatisticsWrapper[] prevProductionData;

		public StatisticsWrapper[] currConsumptionData;

		public StatisticsWrapper[] prevConsumptionData;

		public List<int> playerEncounteredResources;

		private static ResourceAmount CopyOrEmpty(ResourceAmount r)
		{
			if (!(r != null))
			{
				return new ResourceAmount();
			}
			return new ResourceAmount(r);
		}

		public override ResourceStatisticsSaveData Pack(ResourceStatistics obj)
		{
			int numLandMasses = World.inst.NumLandMasses;
			currProductionData = new StatisticsWrapper[numLandMasses];
			prevProductionData = new StatisticsWrapper[numLandMasses];
			currConsumptionData = new StatisticsWrapper[numLandMasses];
			prevConsumptionData = new StatisticsWrapper[numLandMasses];
			for (int i = 0; i < numLandMasses; i++)
			{
				if (obj.currProduction[i].data != null)
				{
					currProductionData[i].data = new SerializableDictionary<string, ResourceAmount>(obj.currProduction[i].data);
				}
				currProductionData[i].amount = CopyOrEmpty(obj.currProduction[i].amount);
				if (obj.prevProduction[i].data != null)
				{
					prevProductionData[i].data = new SerializableDictionary<string, ResourceAmount>(obj.prevProduction[i].data);
				}
				prevProductionData[i].amount = CopyOrEmpty(obj.prevProduction[i].amount);
				if (obj.currConsumption[i].data != null)
				{
					currConsumptionData[i].data = new SerializableDictionary<string, ResourceAmount>(obj.currConsumption[i].data);
				}
				currConsumptionData[i].amount = CopyOrEmpty(obj.currConsumption[i].amount);
				if (obj.prevConsumption[i].data != null)
				{
					prevConsumptionData[i].data = new SerializableDictionary<string, ResourceAmount>(obj.prevConsumption[i].data);
				}
				prevConsumptionData[i].amount = CopyOrEmpty(obj.prevConsumption[i].amount);
			}
			playerEncounteredResources = new List<int>(obj.playerEncounteredResources);
			return this;
		}

		public override ResourceStatistics Unpack(ResourceStatistics obj)
		{
			int num = currProductionData.Length;
			for (int i = 0; i < num; i++)
			{
				if (currProductionData[i].data != null)
				{
					obj.currProduction[i].data = new Dictionary<string, ResourceAmount>(currProductionData[i].data);
				}
				obj.currProduction[i].amount = CopyOrEmpty(currProductionData[i].amount);
				if (prevProductionData[i].data != null)
				{
					obj.prevProduction[i].data = new Dictionary<string, ResourceAmount>(prevProductionData[i].data);
				}
				obj.prevProduction[i].amount = CopyOrEmpty(prevProductionData[i].amount);
				if (currConsumptionData[i].data != null)
				{
					obj.currConsumption[i].data = new Dictionary<string, ResourceAmount>(currConsumptionData[i].data);
				}
				obj.currConsumption[i].amount = CopyOrEmpty(currConsumptionData[i].amount);
				if (prevConsumptionData[i].data != null)
				{
					obj.prevConsumption[i].data = new Dictionary<string, ResourceAmount>(prevConsumptionData[i].data);
				}
				obj.prevConsumption[i].amount = CopyOrEmpty(prevConsumptionData[i].amount);
			}
			if (playerEncounteredResources != null)
			{
				obj.playerEncounteredResources.Clear();
				for (int j = 0; j < playerEncounteredResources.Count; j++)
				{
					obj.TrySetEncounteredResource(playerEncounteredResources[j]);
				}
			}
			return obj;
		}
	}

	public static ResourceStatistics inst;

	private EventHandler<NewYearEvent> eventHandler;

	private const int MAX_LANDMASS_COUNT = 32;

	[NonSerialized]
	public Statistics[] currProduction = new Statistics[32];

	[NonSerialized]
	public Statistics[] prevProduction = new Statistics[32];

	[NonSerialized]
	public Statistics[] currConsumption = new Statistics[32];

	[NonSerialized]
	public Statistics[] prevConsumption = new Statistics[32];

	[NonSerialized]
	public Dictionary<int, List<string>> productionUniqueCategories = new Dictionary<int, List<string>>(64);

	[NonSerialized]
	public Dictionary<int, List<string>> consumptionUniqueCategories = new Dictionary<int, List<string>>(64);

	[NonSerialized]
	public HashSet<int> playerEncounteredResources = new HashSet<int>(32);

	private static int frameCount;

	private const int frameSeparation = 16;

	public const string GOLD_SUFFIX = "gold_";

	private void Awake()
	{
		inst = this;
	}

	private void OnDestroy()
	{
		if (eventHandler != null)
		{
			Broadcast.NewYearEvent.Unlisten(eventHandler);
		}
	}

	private void Update()
	{
		if (!GameState.inst.IsPlayMode() || LoadSave.Loading)
		{
			return;
		}
		for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			int num = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i];
			ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[num];
			for (int j = 0; j < resourceAmount.resources.Count; j++)
			{
				Resource resource = resourceAmount.resources[j];
				if (resource.Amount > 0)
				{
					TrySetEncounteredResource(resource.resourceID);
				}
			}
		}
		if (frameCount++ % 16 != 0)
		{
			return;
		}
		for (int k = 0; k < 32; k++)
		{
			Statistics statistics = currConsumption[k];
			if (statistics.data == null)
			{
				continue;
			}
			foreach (KeyValuePair<string, ResourceAmount> datum in statistics.data)
			{
				if (datum.Key.StartsWith("gold_"))
				{
					int num2 = datum.Value.Get(4);
					statistics.amount.Add(4, -num2);
					datum.Value.Clear();
				}
			}
			Statistics statistics2 = currProduction[k];
			if (statistics2.data == null)
			{
				continue;
			}
			foreach (KeyValuePair<string, ResourceAmount> datum2 in statistics2.data)
			{
				if (datum2.Key.StartsWith("gold_"))
				{
					int num3 = datum2.Value.Get(4);
					statistics2.amount.Add(4, -num3);
					datum2.Value.Clear();
				}
			}
		}
		for (int l = 0; l < Player.inst.WagePayers.Count; l++)
		{
			WagePayer wagePayer = Player.inst.WagePayers.data[l];
			Building building = wagePayer?.bi;
			if (!(building == null) && building.TeamID() == 0 && building.IsOpen() && building.IsBuilt() && !(building.GetWorkerPercent() <= 0f))
			{
				int num4 = building.LandMass();
				LandmassOwner landmassOwner = World.GetLandmassOwner(num4);
				int num5 = Mathf.FloorToInt((float)wagePayer.GetGoldWage(landmassOwner) * wagePayer.PaydaysPerYear());
				currConsumption[num4].Add("gold_" + building.CategoryName, 4, num5);
				currConsumption[num4].amount.Add(4, num5);
			}
		}
		for (int m = 0; m < Player.inst.ResidentialsPerLandmass.Length; m++)
		{
			ArrayExt<Home> arrayExt = Player.inst.ResidentialsPerLandmass[m];
			int num6 = m;
			float num7 = 0f;
			for (int n = 0; n < arrayExt.Count; n++)
			{
				Home home = arrayExt.data[n];
				Building building2 = home?.b;
				if (!(building2 == null) && building2.TeamID() == 0 && building2.IsBuilt() && home.Residents.Count != 0)
				{
					num7 += home.GetEstimatedTaxYield();
				}
			}
			currProduction[num6].Add("gold_home", 4, Mathf.FloorToInt(num7));
			currProduction[num6].amount.Add(4, Mathf.FloorToInt(num7));
		}
	}

	public void Reset()
	{
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			currProduction[i].data?.Clear();
			currProduction[i].amount = new ResourceAmount();
			prevProduction[i].data?.Clear();
			prevProduction[i].amount = new ResourceAmount();
			currConsumption[i].data?.Clear();
			currConsumption[i].amount = new ResourceAmount();
			prevConsumption[i].data?.Clear();
			prevConsumption[i].amount = new ResourceAmount();
			StubBasicStatistics(i);
		}
		if (eventHandler != null)
		{
			Broadcast.NewYearEvent.Unlisten(eventHandler);
		}
		eventHandler = Broadcast.NewYearEvent.Listen(OnNewYear);
		playerEncounteredResources.Clear();
	}

	private void OnNewYear(object sender, NewYearEvent data)
	{
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			if (currProduction[i].data != null)
			{
				ref Dictionary<string, ResourceAmount> data2 = ref prevProduction[i].data;
				if (data2 == null)
				{
					data2 = new Dictionary<string, ResourceAmount>(32);
				}
				prevProduction[i].data.Clear();
				foreach (KeyValuePair<string, ResourceAmount> datum in currProduction[i].data)
				{
					prevProduction[i].data.Add(datum.Key, new ResourceAmount(datum.Value));
					datum.Value.Clear();
				}
			}
			prevProduction[i].amount.Clear();
			prevProduction[i].amount.Add(in currProduction[i].amount);
			currProduction[i].amount.Clear();
			if (currConsumption[i].data != null)
			{
				ref Dictionary<string, ResourceAmount> data2 = ref prevConsumption[i].data;
				if (data2 == null)
				{
					data2 = new Dictionary<string, ResourceAmount>(32);
				}
				prevConsumption[i].data.Clear();
				foreach (KeyValuePair<string, ResourceAmount> datum2 in currConsumption[i].data)
				{
					prevConsumption[i].data.Add(datum2.Key, new ResourceAmount(datum2.Value));
					datum2.Value.Clear();
				}
			}
			prevConsumption[i].amount.Clear();
			prevConsumption[i].amount.Add(in currConsumption[i].amount);
			currConsumption[i].amount.Clear();
		}
	}

	public void StubBasicStatistics(int lm)
	{
		currConsumption[lm].Add("home", 0, 0);
		prevConsumption[lm].Add("home", 0, 0);
		currConsumption[lm].Add("home", 1, 0);
		prevConsumption[lm].Add("home", 1, 0);
		currConsumption[lm].Add("construction", 1, 0);
		prevConsumption[lm].Add("construction", 1, 0);
		currConsumption[lm].Add("construction", 2, 0);
		prevConsumption[lm].Add("construction", 2, 0);
		currProduction[lm].Add("farm", 0, 0);
		prevProduction[lm].Add("farm", 0, 0);
		currProduction[lm].Add("clearcutter", 1, 0);
		prevProduction[lm].Add("clearcutter", 1, 0);
		currProduction[lm].Add("clearcutter", 2, 0);
		prevProduction[lm].Add("clearcutter", 2, 0);
	}

	public static void AddProduction(int landmass, string uniqueCategory, ResourceAmount amt)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Add Production - Landmass: {landmass}");
			return;
		}
		inst.currProduction[landmass].Add(uniqueCategory, amt);
		inst.currProduction[landmass].amount.Add(in amt);
	}

	public static void AddProduction(int landmass, string uniqueCategory, int resourceID, int amt)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Add Production - Landmass: {landmass}");
			return;
		}
		ResourceAmount resourceAmount = new ResourceAmount();
		resourceAmount.Add(resourceID, amt);
		inst.currProduction[landmass].Add(uniqueCategory, resourceAmount);
		inst.currProduction[landmass].amount.Add(resourceID, amt);
	}

	public static void AddConsumption(int landmass, string uniqueCategory, ResourceAmount amt)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Add Consumption - Landmass: {landmass}");
			return;
		}
		inst.currConsumption[landmass].Add(uniqueCategory, amt);
		inst.currConsumption[landmass].amount.Add(in amt);
	}

	public static int GetPreviousProduction(int landmass, int resourceID)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Get Current Consumption Resource - Landmass: {landmass}");
			return 0;
		}
		return inst.prevProduction[landmass].amount.Get(resourceID);
	}

	public static ResourceAmount GetPreviousProduction(int landmass)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Get  Previous Production ResourceAmount - Landmass: {landmass}");
			return ResourceAmount.empty;
		}
		return inst.prevProduction[landmass].amount;
	}

	public static void AddConsumption(int landmass, string uniqueCategory, int resourceID, int amt)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Add Consumption - Landmass: {landmass}");
			return;
		}
		ResourceAmount resourceAmount = new ResourceAmount();
		resourceAmount.Add(resourceID, amt);
		inst.currConsumption[landmass].Add(uniqueCategory, resourceAmount);
		inst.currConsumption[landmass].amount.Add(resourceID, amt);
	}

	public static ResourceAmount GetCurrentConsumption(int landmass)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Get Current Consumption - Landmass: {landmass}");
			return null;
		}
		return inst.currConsumption[landmass].amount;
	}

	public static int GetCurrentConsumption(int landmass, int resourceID)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Get Current Consumption Resource - Landmass: {landmass}");
			return 0;
		}
		return inst.currConsumption[landmass].amount.Get(resourceID);
	}

	public static ResourceAmount GetPreviousConsumption(int landmass)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Get Previous Consumption - Landmass: {landmass}");
			return null;
		}
		return inst.prevConsumption[landmass].amount;
	}

	public static int GetPreviousConsumption(int landmass, int resourceID)
	{
		if (landmass < 0 || landmass > 31)
		{
			Debug.Log($"Failed to Get Previous Consumption Resource - Landmass: {landmass}");
			return 0;
		}
		return inst.prevConsumption[landmass].amount.Get(resourceID);
	}

	public void TrySetEncounteredResource(int resourceID)
	{
		if (resourceID != -1 && !inst.playerEncounteredResources.Contains(resourceID))
		{
			inst.playerEncounteredResources.Add(resourceID);
			ResourceStatisticsUI.inst.OnEncounteredResource(resourceID);
		}
	}
}
