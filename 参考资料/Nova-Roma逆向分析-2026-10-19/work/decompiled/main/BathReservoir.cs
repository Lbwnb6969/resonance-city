using System;
using System.Runtime.Serialization;
using I2.Loc;
using UnityEngine;

public class BathReservoir : AqueductBuilding, IOutputInfo, IWorkerUIDisplay
{
	private enum DemandBand
	{
		Fill,
		TopUp,
		Maintain
	}

	[Serializable]
	public class BathReservoirSaveData : SaveClass<BathReservoir, BathReservoirSaveData>
	{
		public float currWaterStorage;

		[OptionalField(VersionAdded = 5)]
		private bool savedAsFraction;

		[OptionalField(VersionAdded = 5)]
		private float storageFraction;

		public override BathReservoirSaveData Pack(BathReservoir obj)
		{
			savedAsFraction = true;
			storageFraction = ((MAX_WATER_STORAGE > 0f) ? Mathf.Clamp01(obj.currWaterStorage / MAX_WATER_STORAGE) : 0f);
			currWaterStorage = 0f;
			return this;
		}

		public override BathReservoir Unpack(BathReservoir obj)
		{
			float num = (savedAsFraction ? storageFraction : Mathf.Clamp01(currWaterStorage / 30f));
			obj.currWaterStorage = num * MAX_WATER_STORAGE;
			return obj;
		}
	}

	public Transform waterT;

	public GameObject topObj;

	[NonSerialized]
	public float currWaterStorage;

	public static float MAX_WATER_STORAGE = 500f;

	public const float DEFAULT_REFILL_RATE = 1f;

	public BathManager.BathGroup Group;

	private DemandBand demandBand;

	private const float BAND_FULL_FRACTION = 0.98f;

	[NonSerialized]
	public float bandTarget;

	public ThoughtBubbleSystem.ThoughtBubble thought;

	private bool isFulfillingBath;

	private const float LEGACY_MAX_WATER_STORAGE = 30f;

	public bool BathWaterFulfilled
	{
		get
		{
			return isFulfillingBath;
		}
		set
		{
			isFulfillingBath = value;
			thought.visible = !value;
		}
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		solverPriority = 0;
		thought = ThoughtBubbleSystem.inst.AddThoughtBubble(Vector3.zero);
		thought.thought = ThoughtBubbleSystem.Thought.WaterCritical;
		thought.offset = new Vector3(0f, 1f, 0f);
		thought.visible = false;
	}

	private void Update()
	{
		if (!LoadSave.Loading)
		{
			UpdateVisual();
		}
	}

	private void UpdateVisual()
	{
		float t = currWaterStorage / MAX_WATER_STORAGE;
		waterT.localPosition = new Vector3(0f, Mathff.Lerp(0.18f, 0.95f, t), 0f);
		Util.SetActive(waterT.gameObject, currWaterStorage > 0f);
		if (b.IsBuilt())
		{
			Building buildingSelected = GameUI.inst.GetBuildingSelected();
			Util.SetActive(topObj, buildingSelected != b);
		}
	}

	public override float GetCurrentWaterConsumption()
	{
		return waterConsumption;
	}

	public override float GetWaterDemandTotal()
	{
		if (Group == null)
		{
			return 0f;
		}
		int contributingReservoirs = Group.reservoirs.Count;
		if (Group.contributingReservoirs > 0)
		{
			contributingReservoirs = Group.contributingReservoirs;
		}
		if (contributingReservoirs > 0)
		{
			return Group.wConsumption / (float)contributingReservoirs;
		}
		return 0f;
	}

	public float GroupIntake()
	{
		return Mathff.Min(AqueductFlowController.GetReservoirCommittedIntake(this), waterFlow);
	}

	protected override float NetworkDraw()
	{
		return GroupIntake();
	}

	public void UpdateBand(float share)
	{
		float num = ((MAX_WATER_STORAGE > 0f) ? (currWaterStorage / MAX_WATER_STORAGE) : 1f);
		DemandBand demandBand = this.demandBand;
		switch (this.demandBand)
		{
		case DemandBand.Fill:
			if (num >= 0.98f)
			{
				this.demandBand = DemandBand.Maintain;
			}
			break;
		case DemandBand.Maintain:
			if (num < 0.95f)
			{
				this.demandBand = DemandBand.TopUp;
			}
			break;
		case DemandBand.TopUp:
			if (num >= 0.98f)
			{
				this.demandBand = DemandBand.Maintain;
			}
			else if (num < 0.5f)
			{
				this.demandBand = DemandBand.Fill;
			}
			break;
		}
		if (this.demandBand != demandBand)
		{
			AqueductFlowDiagnostics.Note($"res({(int)transform.position.x},{(int)transform.position.z}) band {demandBand}->{this.demandBand} tank={num:P0}");
		}
		bandTarget = BandMultiplier() * share;
	}

	private float BandMultiplier()
	{
		return demandBand switch
		{
			DemandBand.Fill => 2f, 
			DemandBand.TopUp => 1.5f, 
			_ => 1f, 
		};
	}

	public override void OnDestroy()
	{
		base.OnDestroy();
		if (thought != null)
		{
			ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref thought);
		}
	}

	public new void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			if (LoadSave.Loading && b.IsBuilt())
			{
				BathManager.inst.Register(b);
			}
			thought.pos = b.Center();
		}
		else if (b.IsBuilt())
		{
			BathManager.inst.Deregister(b);
		}
		base.OnBuildingPlacement(undo);
	}

	public void OnBuilt()
	{
		BathManager.inst.Register(b);
	}

	public bool HasAnyConnection()
	{
		return aqueductLines.Count > 0;
	}

	public string GetError()
	{
		string text = ((Group != null) ? Group.GetWaterWarningTerm() : null);
		if (text != null && text != "workerui_bathui_warning_drainingreserves" && !HasAnyConnection())
		{
			text = "workerui_bathui_warning_connectaqueduct";
		}
		if (text == null)
		{
			return string.Empty;
		}
		return LocalizationManager.GetTranslation(text);
	}

	public override bool IsWaterEnRoute()
	{
		if (Group != null && HasAnyConnection())
		{
			return Group.IsWaterEnRoute();
		}
		return false;
	}

	public bool ParticipatesInComplexWater()
	{
		if (b != null)
		{
			return b.IsOpen();
		}
		return false;
	}

	public bool IsLiveReservoir()
	{
		if (ParticipatesInComplexWater())
		{
			return HasAnyConnection();
		}
		return false;
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
