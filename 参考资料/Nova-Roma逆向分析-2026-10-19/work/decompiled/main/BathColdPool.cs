using System;
using I2.Loc;
using UnityEngine;

public class BathColdPool : BathPool, IOutputInfo
{
	public ParticleSystem wFallFXPrefab;

	public BathPoolRamp rampPrefab;

	public GameObject waterObj;

	[SerializeField]
	private GameObject wFoundationObj;

	private int wFallPoolCount;

	private ArrayExt<ParticleSystem> wFallPool = new ArrayExt<ParticleSystem>(32);

	private int rampPoolCount;

	private ArrayExt<BathPoolRamp> rampPool = new ArrayExt<BathPoolRamp>(32);

	private static Cell[] scratch4 = new Cell[4];

	private static float MIN_HEIGHT_THRESHOLD = 0.1f;

	private Transform offset;

	protected override void AwakeInternal()
	{
		AdjacentMesh adjacentMesh = adjMesh;
		adjacentMesh.onRotationUpdate = (AdjacentMesh.OnRotationUpdate)Delegate.Combine(adjacentMesh.onRotationUpdate, new AdjacentMesh.OnRotationUpdate(OnRotationUpdate));
		offset = transform.GetChild(0);
	}

	public override void OnBuilt()
	{
		base.OnBuilt();
		OnRotationUpdate(adjMesh.currAdjType);
	}

	private void OnRotationUpdate(AdjacentMesh.AdjacentType adjtype)
	{
		if (!b.IsBuilt())
		{
			return;
		}
		wFallPoolCount = 0;
		rampPoolCount = 0;
		Cell cell = b.GetCell();
		World.inst.GetNeighborCells(cell, ref scratch4);
		for (int i = 0; i < scratch4.Length; i++)
		{
			Cell cell2 = scratch4[i];
			if (cell2 == null)
			{
				continue;
			}
			Building building = cell2.StructureFind(b.uniqueNameHash);
			if (building != null && b.transform.position.y - building.transform.position.y > MIN_HEIGHT_THRESHOLD)
			{
				ParticleSystem waterfall = GetWaterfall();
				Vector3 input = new Vector3(cell2.x - cell.x, 0f, cell2.z - cell.z);
				input.NonAllocateNormalize();
				Vector3 input2 = input;
				input2.NonAllocateMultiply(0.5f);
				input2.NonAllocateAdd(offset.position);
				waterfall.transform.position = input2;
				waterfall.transform.rotation = Quaternion.LookRotation(input, Vector3.up);
				Vector3 input3 = new Vector3(0f - input.z, 0f, input.x);
				input3.NonAllocateNormalize();
				Vector3 vector = -input3;
				Vector3 vector2 = input2 + vector * 0.375f;
				Vector3 vector3 = input2 + input3 * 0.375f;
				Vector3 vector4 = vector2 + input * 0.5f;
				vector4.y = building.transform.position.y;
				Vector3 vector5 = vector3 + input * 0.5f;
				vector5.y = building.transform.position.y;
				Cell cellData = World.inst.GetCellData(vector4 + input3);
				if (World.inst.GetCellData(vector5 + vector).StructureCompareUniqueNameAll(b.uniqueNameHash))
				{
					BathPoolRamp ramp = GetRamp();
					ramp.transform.position = input2;
					ramp.transform.rotation = Quaternion.LookRotation(input, Vector3.up);
					ramp.top.position = vector2;
					ramp.bottom.position = vector4;
					Vector3 vector6 = vector2 + input * 0.1f;
					ramp.ramp.position = vector6;
					Vector3 forward = vector4 - input * 0.1f - vector6;
					ramp.ramp.forward = forward;
					ramp.ramp.localScale = new Vector3(1f, 1f, forward.magnitude);
					Util.SetActive(ramp.gameObject, active: true);
				}
				if (cellData.StructureCompareUniqueNameAll(b.uniqueNameHash))
				{
					BathPoolRamp ramp2 = GetRamp();
					ramp2.transform.position = input2;
					ramp2.transform.rotation = Quaternion.LookRotation(input, Vector3.up);
					ramp2.top.position = vector3;
					ramp2.bottom.position = vector5;
					Vector3 vector7 = vector3 + input * 0.1f;
					ramp2.ramp.position = vector7;
					Vector3 forward2 = vector5 - input * 0.1f - vector7;
					ramp2.ramp.forward = forward2;
					ramp2.ramp.localScale = new Vector3(1f, 1f, forward2.magnitude);
					Util.SetActive(ramp2.gameObject, active: true);
				}
				Util.SetParticleEffects(waterfall, hasWater);
			}
		}
		for (int num = wFallPool.Count - 1; num >= wFallPoolCount; num--)
		{
			Util.SetParticleEffects(wFallPool.data[num], active: false);
		}
		for (int num2 = rampPool.Count - 1; num2 >= rampPoolCount; num2--)
		{
			Util.SetActive(rampPool.data[num2].gameObject, active: false);
		}
	}

	private ParticleSystem GetWaterfall()
	{
		if (wFallPoolCount == wFallPool.Count)
		{
			ParticleSystem item = UnityEngine.Object.Instantiate(wFallFXPrefab, offset);
			wFallPool.Add(item);
		}
		return wFallPool.data[wFallPoolCount++];
	}

	private BathPoolRamp GetRamp()
	{
		if (rampPoolCount == rampPool.Count)
		{
			BathPoolRamp item = UnityEngine.Object.Instantiate(rampPrefab, offset);
			rampPool.Add(item);
		}
		return rampPool.data[rampPoolCount++];
	}

	public override void UpdateWater(bool doWater)
	{
		base.UpdateWater(doWater);
		for (int i = 0; i < wFallPoolCount; i++)
		{
			Util.SetParticleEffects(wFallPool.data[i], doWater);
		}
		Util.SetActive(waterObj, doWater);
	}

	string IOutputInfo.GetError()
	{
		if (!hasWater)
		{
			return ScriptLocalization.workerui_outputinfoui_error_bathpool_nowater;
		}
		return string.Empty;
	}
}
