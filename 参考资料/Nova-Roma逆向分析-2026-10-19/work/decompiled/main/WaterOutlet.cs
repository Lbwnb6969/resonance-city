using System;
using UnityEngine;

public class WaterOutlet : AqueductBuilding, IWorkerUIDisplay, IOutputInfo
{
	[Serializable]
	public class WaterOutletSaveData : SaveClass<WaterOutlet, WaterOutletSaveData>
	{
		public float targetOutflow;

		public override WaterOutletSaveData Pack(WaterOutlet obj)
		{
			targetOutflow = obj.targetOutflow;
			return this;
		}

		public override WaterOutlet Unpack(WaterOutlet obj)
		{
			obj.targetOutflow = targetOutflow;
			if (obj.b != null && obj.b.IsBuilt())
			{
				obj.ApplyDemand();
			}
			return obj;
		}
	}

	public float targetOutflow = AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS;

	public Transform outputsContainer;

	public float minFallDistance = 0.02f;

	private int meshIndex = -1;

	private Vector3 outputPos;

	private bool canBlock = true;

	private bool blocked;

	private bool sourceActive;

	private bool everWritten;

	private float lastWrittenPour = -1f;

	private float pour;

	private bool outputResolved;

	private WaterOutletSpout spout;

	private bool fallOn;

	private float lastLife = -1f;

	private float lastPour = -1f;

	private bool splashOn;

	private float fallStartTime = -1f;

	private Quaternion splashBaseRot = Quaternion.identity;

	private const float BLOCK_DEPTH_EPSILON = 0.05f;

	private const float POUR_WRITE_EPSILON = 0.01f;

	private const float WATER_SURFACE_EPSILON = 0.02f;

	private const float FALL_PARTICLE_HEADROOM = 1.5f;

	private const int MIN_FALL_PARTICLES = 16;

	private const float FALL_SIZE_AT_MIN_FLOW = 0.1f;

	private const float FALL_SIZE_AT_FULL_FLOW = 0.3f;

	private const float FALL_RATE_AT_MIN_FLOW = 40f;

	private const float FALL_RATE_AT_FULL_FLOW = 20f;

	private const float FALL_COUNT_AT_MIN_FLOW = 60f;

	private const float FALL_COUNT_AT_FULL_FLOW = 40f;

	private const float FALL_LOOK_FLOW_EPSILON = 0.5f;

	private WaterError waterError;

	private EventHandler<OnBuildingOpenClose> openCloseHandler;

	private void Awake()
	{
		onlyIncoming = true;
		onlyOutgoing = false;
	}

	private void OnBuilt()
	{
		InitOutlet();
		UpdateState();
		SubscribeOpenClose();
	}

	private void OnPlaced()
	{
		SetMarkersVisible(visible: false);
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt())
		{
			InitOutlet();
			SubscribeOpenClose();
		}
	}

	private void OnShutdown()
	{
		ClearGroundSource();
		StopWaterfall();
		waterFlow = 0f;
		UnsubscribeOpenClose();
	}

	private void SubscribeOpenClose()
	{
		if (openCloseHandler == null)
		{
			openCloseHandler = Broadcast.BuildingOpenClose.Listen(World.waterOutletHash, OnOpenClose);
		}
	}

	private void UnsubscribeOpenClose()
	{
		if (openCloseHandler != null)
		{
			Broadcast.BuildingOpenClose.Unlisten(World.waterOutletHash, openCloseHandler);
			openCloseHandler = null;
		}
	}

	private void OnOpenClose(object sender, OnBuildingOpenClose data)
	{
		if (!(data.targetBuilding != b))
		{
			ApplyDemand(data.open);
			ApplyGroundInjection(data.open);
			UpdateState();
		}
	}

	public override void OnDestroy()
	{
		ClearGroundSource();
		UnsubscribeOpenClose();
		base.OnDestroy();
	}

	private void InitOutlet()
	{
		ResolveOutput();
		if (outputResolved)
		{
			RefreshBlockedState();
		}
		ApplyDemand();
		ApplyGroundInjection();
		SetMarkersVisible(visible: false);
	}

	public void SetMarkersVisible(bool visible)
	{
		BobObject[] componentsInChildren = GetComponentsInChildren<BobObject>(includeInactive: true);
		foreach (BobObject bobObject in componentsInChildren)
		{
			if (bobObject.gameObject.activeSelf != visible)
			{
				bobObject.gameObject.SetActive(visible);
			}
		}
	}

	private void ResolveOutput()
	{
		ClearGroundSource();
		outputResolved = false;
		spout = null;
		if (b == null)
		{
			return;
		}
		Transform transform = ((outputsContainer != null) ? outputsContainer : base.transform.Find("Outputs"));
		if (transform != null && transform.childCount > 0)
		{
			if (transform.childCount > 1)
			{
				Debug.LogWarning("WaterOutlet supports a single output; using the first child of " + transform.name, this);
			}
			Transform child = transform.GetChild(0);
			spout = child.GetComponent<WaterOutletSpout>();
			StopFall(spout);
			StopSplash(spout);
			outputPos = child.position;
			meshIndex = DynamicWater.MapWorldPosToMeshIndex(child.position, World.MeshWidth);
			canBlock = true;
			splashBaseRot = ((spout != null && spout.Splash != null) ? spout.Splash.transform.rotation : Quaternion.identity);
			outputResolved = true;
		}
		else
		{
			Cell cell = b.GetCell();
			if (cell != null)
			{
				outputPos = cell.Center3D;
				canBlock = false;
				meshIndex = DynamicWater.MapIndexWorldToMesh(cell.index, World.inst.GridWidth);
				outputResolved = true;
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (!GameState.IsQuitting && !LoadSave.Loading && !(b == null) && b.IsBuilt())
		{
			CalculateWaterFlow();
			ApplyGroundInjection();
			UpdateWaterfalls();
		}
	}

	public override void UpdateWaterFlow()
	{
		base.UpdateWaterFlow();
		UpdateState();
		ApplyGroundInjection();
	}

	private void RefreshBlockedState()
	{
		bool flag = meshIndex < 0 || (DynamicWater.inst != null && DynamicWater.inst.waterGrid.IsCreated && meshIndex >= DynamicWater.inst.waterGrid.Length);
		blocked = flag || (canBlock && IsBlocked(outputPos));
	}

	private void ApplyGroundInjection(bool? knownOpen = null)
	{
		if (GameState.IsQuitting || LoadSave.Loading || DynamicWater.inst == null || !DynamicWater.inst.waterGrid.IsCreated)
		{
			return;
		}
		bool flag = blocked;
		if (!outputResolved)
		{
			ResolveOutput();
			if (!outputResolved)
			{
				return;
			}
		}
		RefreshBlockedState();
		if (blocked != flag)
		{
			ApplyDemand(knownOpen ?? b.IsOpen());
			UpdateState();
		}
		if (meshIndex < 0 || meshIndex >= DynamicWater.inst.waterGrid.Length)
		{
			return;
		}
		pour = (blocked ? 0f : waterFlow);
		float num = ((pour > 0f) ? (AqueductBuilding.HumanToSystem(pour) / DynamicWater.inst.TimeStep) : 0f);
		if (WaterFlowDiagnostics.Enabled)
		{
			DynamicWater.inst.dynamicWaterJobHandle.Complete();
			float num2 = Mathf.Max(DynamicWater.inst.rainMul * SeasonManager.inst.waterSourceMul, -1f);
			float num3 = ((DynamicWater.inst.waterGrid[meshIndex].isManMadeSource != 0) ? 1f : (1f + num2));
			WaterFlowDiagnostics.ReportAdded(this, pour * DynamicWater.inst.debug_produceWater * num3);
		}
		bool num4;
		if (!(num > 0f))
		{
			num4 = sourceActive;
		}
		else
		{
			if (!sourceActive)
			{
				goto IL_01a0;
			}
			num4 = Mathff.Abs(pour - lastWrittenPour) > 0.01f;
		}
		if (!num4)
		{
			return;
		}
		goto IL_01a0;
		IL_01a0:
		DynamicWater.inst.SetWaterContribution(meshIndex, this, num, natural: false);
		sourceActive = num > 0f;
		everWritten = true;
		lastWrittenPour = pour;
	}

	private void ApplyDemand()
	{
		ApplyDemand(b.IsOpen());
	}

	private void ApplyDemand(bool isOpen)
	{
		SetConsumption((blocked || !isOpen) ? 0f : targetOutflow);
	}

	private bool IsBlocked(Vector3 worldPos)
	{
		if (TerrainGen.inst == null)
		{
			return false;
		}
		return TerrainGen.inst.GetInterpolatedHeight(worldPos) > worldPos.y + 0.05f;
	}

	private void UpdateWaterfalls()
	{
		if (DynamicWater.inst == null || TerrainGen.inst == null)
		{
			return;
		}
		ParticleSystem particleSystem = ((spout != null) ? spout.fall : null);
		if (particleSystem == null)
		{
			return;
		}
		float interpolatedHeightWithNormal = TerrainGen.inst.GetInterpolatedHeightWithNormal(outputPos, out var normal);
		float num = Mathf.Max(0f, DynamicWater.inst.GetExactWaterAmount(outputPos));
		float num2 = interpolatedHeightWithNormal + num;
		if (num > 0.02f)
		{
			normal = Vector3.up;
		}
		float num3 = spout.Origin.position.y - num2;
		bool flag = sourceActive && !blocked && num3 >= minFallDistance;
		if (flag)
		{
			ParticleSystem.MainModule main = particleSystem.main;
			float t = Mathf.InverseLerp(1f, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS, pour);
			float num4 = Mathf.Lerp(0.1f, 0.3f, t);
			float num5 = Mathf.Lerp(40f, 20f, t);
			float f = Mathf.Lerp(60f, 40f, t);
			float g = main.gravityModifier.constant * (0f - Physics.gravity.y);
			float vy = main.startSpeed.constant * particleSystem.transform.forward.y;
			float num6 = FallLifetime(num3, vy, g);
			bool flag2 = Mathff.Abs(pour - lastPour) > 0.5f;
			bool flag3 = Mathff.Abs(num6 - lastLife) > 0.01f;
			if (flag2)
			{
				main.startSize = num4;
				ParticleSystem.EmissionModule emission = particleSystem.emission;
				emission.rateOverTime = num5;
				lastPour = pour;
			}
			if (flag3)
			{
				main.startLifetime = num6;
				lastLife = num6;
			}
			if (flag2 | flag3)
			{
				int num7 = Mathf.CeilToInt(num5 * num6 * 1.5f);
				main.maxParticles = Mathf.Max(16, Mathf.Max(Mathf.CeilToInt(f), num7));
			}
		}
		if (flag && !fallOn)
		{
			particleSystem.Play();
			fallOn = true;
			fallStartTime = Time.time;
		}
		else if (!flag && fallOn)
		{
			particleSystem.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
			fallOn = false;
		}
		UpdateSplash(particleSystem, num2, normal);
	}

	private void UpdateSplash(ParticleSystem fall, float surfaceY, Vector3 surfaceNormal)
	{
		ParticleSystem particleSystem = ((spout != null) ? spout.Splash : null);
		if (!(particleSystem == null))
		{
			if (fallOn && fall.particleCount > 0 && (fall.main.prewarm || Time.time - fallStartTime >= lastLife) && !splashOn)
			{
				particleSystem.Play(withChildren: true);
				splashOn = true;
			}
			else if (splashOn && fall.particleCount == 0)
			{
				particleSystem.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
				splashOn = false;
			}
			if (splashOn)
			{
				Transform transform = particleSystem.transform;
				transform.position = new Vector3(outputPos.x, surfaceY, outputPos.z);
				transform.rotation = Quaternion.FromToRotation(Vector3.up, surfaceNormal) * splashBaseRot;
			}
		}
	}

	private static float FallLifetime(float distance, float vy, float g)
	{
		if (g <= 0.0001f)
		{
			return 0f;
		}
		distance = Mathf.Max(0f, distance);
		return (vy + Mathf.Sqrt(vy * vy + 2f * g * distance)) / g;
	}

	private void StopWaterfall()
	{
		StopFall(spout);
		StopSplash(spout);
		fallOn = false;
		splashOn = false;
		lastLife = -1f;
		lastPour = -1f;
	}

	private static void StopFall(WaterOutletSpout spout)
	{
		if (spout != null && spout.fall != null)
		{
			spout.fall.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
		}
	}

	private static void StopSplash(WaterOutletSpout spout)
	{
		if (spout != null && spout.Splash != null)
		{
			spout.Splash.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
		}
	}

	private void ClearGroundSource()
	{
		if (!GameState.IsQuitting && !(DynamicWater.inst == null) && DynamicWater.inst.waterGrid.IsCreated && everWritten && meshIndex >= 0 && meshIndex < DynamicWater.inst.waterGrid.Length)
		{
			DynamicWater.inst.ClearWaterContribution(meshIndex, this);
			sourceActive = false;
			everWritten = false;
			lastWrittenPour = -1f;
		}
	}

	public void SetTargetOutflow(float humanUnits)
	{
		targetOutflow = Mathf.Clamp(humanUnits, 0f, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
		ApplyDemand();
		ApplyGroundInjection();
	}

	public float CurrentOutflow()
	{
		return waterFlow;
	}

	private void UpdateState()
	{
		waterError = UpdateWaterErrorState();
		if (waterError == WaterError.None && blocked)
		{
			waterError = WaterError.OutputsBlocked;
		}
		ApplyWaterErrorThought(waterError);
	}

	public string GetError()
	{
		return AqueductBuilding.GetErrorString(waterError);
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
