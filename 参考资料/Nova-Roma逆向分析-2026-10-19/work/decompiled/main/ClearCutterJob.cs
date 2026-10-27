using System;
using Assets;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;

public class ClearCutterJob : Job
{
	private enum AnimState
	{
		Idle,
		Chopping,
		ChopWait,
		Falling
	}

	private enum Status
	{
		Traveling,
		StartChop,
		Chopping
	}

	private enum ClearType
	{
		Trees,
		CoppiceTrees,
		Rocks,
		Done
	}

	[Serializable]
	public class ClearCutterJobSaveData : JobSaveData<ClearCutterJob, ClearCutterJobSaveData>
	{
		public int x;

		public int z;

		public override ClearCutterJobSaveData Pack(ClearCutterJob j)
		{
			x = (int)j.cellToChop.Position.x;
			z = (int)j.cellToChop.Position.z;
			return base.Pack(j);
		}

		public override ClearCutterJob Unpack(ClearCutterJob j)
		{
			base.Unpack(j);
			j.StartClearingAt(World.inst.GetCellData(x, z));
			return j;
		}
	}

	protected GameObject workingIcon;

	[NonSerialized]
	public Cell cellToChop;

	private AnimState animState;

	private int chopsLeft;

	private float animDelay;

	public Vector3 nextToTree;

	private Status status;

	private ClearType clearType;

	public ClearCutterJob(IEmployer e)
		: base(e)
	{
		ManualFreetime = true;
		meshType = VillagerSystem.MeshType.Axeman;
	}

	public void StartClearingAt(Cell c)
	{
		cellToChop = c;
		cellToChop.AddBusy(this);
		UpdateClearType();
		if (clearType == ClearType.Done)
		{
			JobSystem.inst.RemoveJobDeferred(this);
			return;
		}
		if (clearType == ClearType.Rocks)
		{
			workingIcon = UnityEngine.Object.Instantiate(Resources.Load("cursor_pickaxe")) as GameObject;
		}
		else
		{
			workingIcon = UnityEngine.Object.Instantiate(Resources.Load("cursor_axe")) as GameObject;
		}
		workingIcon.GetComponent<MeshRenderer>().material = World.inst.uniMaterialNoFog;
		workingIcon.GetComponent<MeshRenderer>().shadowCastingMode = ShadowCastingMode.Off;
		workingIcon.transform.localScale = new Vector3(1f, 1f, 1f);
		workingIcon.SetActive(value: false);
		int firstItem = GetSystem().GetFirstItem(cellToChop);
		TreeSystem.TreeData item = GetSystem().GetItem(cellToChop, firstItem);
		if (Employee != null)
		{
			nextToTree = item.pos + (Employee.Pos - item.pos).normalized * 0.2f;
		}
		else
		{
			nextToTree = item.pos + new Vector3(SRand.Range(-1f, 1f), 0f, SRand.Range(-1f, 1f)).normalized * 0.2f;
		}
		nextToTree.x = Mathf.Clamp(nextToTree.x, (float)cellToChop.x + 0.01f, (float)cellToChop.x + 0.95f);
		nextToTree.z = Mathf.Clamp(nextToTree.z, (float)cellToChop.z + 0.01f, (float)cellToChop.z + 0.95f);
		if (Employee != null)
		{
			Employee.MoveToDeferred(nextToTree);
		}
		workingIcon.transform.position = cellToChop.Center3D + Vector3.up * 0.75f;
		workingIcon.SetActive(!World.IsAILandmass(c.landMassIdx));
	}

	private int GetChops()
	{
		int num = 1;
		if (clearType == ClearType.Trees || clearType == ClearType.CoppiceTrees)
		{
			num = 16;
		}
		else if (clearType == ClearType.Rocks)
		{
			num = 30;
		}
		if (StreamerEffects.Flag_ChopFaster)
		{
			num /= 2;
		}
		return num;
	}

	public override void OnEmployeeAssigned()
	{
		clearType = ClearType.Trees;
		animState = AnimState.Idle;
		status = Status.Traveling;
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		Employee.MeshType = VillagerSystem.MeshType.Default;
		base.OnEmployeeQuit();
	}

	public override void OnJobRemoved()
	{
		if (cellToChop != null)
		{
			cellToChop.RemoveBusy(this);
		}
		cellToChop = null;
		animState = AnimState.Idle;
		UnityEngine.Object.Destroy(workingIcon);
		workingIcon = null;
		base.OnJobRemoved();
	}

	public override string GetDescription()
	{
		string result = "";
		switch (status)
		{
		case Status.Traveling:
			result = ScriptLocalization.jobClearCuttingDescriptionTraveling;
			break;
		case Status.Chopping:
			result = ((clearType != ClearType.Rocks) ? ScriptLocalization.jobDescriptionCuttingTree : ScriptLocalization.jobDescriptionBreakingStone);
			break;
		}
		return result;
	}

	public override void UpdateWithEmployee(float dt)
	{
		if (cellToChop == null)
		{
			JobSystem.inst.RemoveJobDeferred(this);
			return;
		}
		if (cellToChop.IsCellClear() && (status == Status.StartChop || status == Status.Traveling))
		{
			JobSystem.inst.RemoveJobDeferred(this);
			return;
		}
		Villager villager = Employee;
		switch (status)
		{
		case Status.Traveling:
			if ((villager.Pos - cellToChop.Center3D).sqrMagnitude < 0.5f)
			{
				TransitionToStartChop();
			}
			break;
		case Status.StartChop:
			if (GetSystem() != null && GetSystem().ItemAmount(cellToChop) > 0)
			{
				status = Status.Chopping;
				animState = AnimState.Chopping;
				chopsLeft = GetChops();
			}
			break;
		case Status.Chopping:
		{
			int firstItem = GetSystem().GetFirstItem(cellToChop);
			if (firstItem != -1)
			{
				TreeSystem.TreeData item = GetSystem().GetItem(cellToChop, firstItem);
				Vector3 target = item.pos + (Employee.Pos - item.pos).normalized * 0.2f;
				Employee.Pos = Vector3.MoveTowards(Employee.Pos, target, 0.7f * dt);
			}
			break;
		}
		}
		workingIcon.transform.rotation = Quaternion.Euler(0f, 0f, Mathf.Sin(Time.unscaledTime * 9f) * 10f);
		switch (animState)
		{
		case AnimState.Chopping:
		{
			int firstItem2 = GetSystem().GetFirstItem(cellToChop);
			if (firstItem2 != -1)
			{
				if (!World.IsAILandmass(cellToChop.landMassIdx) && clearType != ClearType.Rocks)
				{
					GetSystem().ShakeItem(cellToChop, firstItem2);
				}
				chopsLeft--;
				if (chopsLeft != 0)
				{
					animState = AnimState.ChopWait;
					animDelay = 0.6f;
					int firstItem3 = GetSystem().GetFirstItem(cellToChop);
					TreeSystem.TreeData item2 = GetSystem().GetItem(cellToChop, firstItem3);
					if (clearType == ClearType.Rocks)
					{
						EffectsMan.inst.WallHitSmallEffect.CreateAndPlayVisibilityCheck(item2.pos, Quaternion.LookRotation(villager.Rot * new Vector3(1f, 0f, 0f)));
						Util.SFXPlayOneShotDistCheck("event:/SFX ASITP/sfx_villagers_chop_stone", villager.Pos);
					}
					if (clearType == ClearType.Trees || clearType == ClearType.CoppiceTrees)
					{
						EffectsMan.inst.WoodHitSmallEffect.CreateAndPlayVisibilityCheck(item2.pos, Quaternion.LookRotation(villager.Rot * new Vector3(1f, 0f, 0f)));
						Util.SFXPlayOneShotDistCheck("event:/SFX ASITP/sfx_villagers_chop_trees", villager.Pos);
					}
					break;
				}
				if (clearType == ClearType.Trees || clearType == ClearType.CoppiceTrees)
				{
					Util.SFXPlayOneShotDistCheck("event:/SFX ASITP/sfx_villagers_chop_trees_complete", villager.Pos);
					GetSystem().FellTree(cellToChop, firstItem2);
				}
				else
				{
					if (clearType == ClearType.Rocks)
					{
						Util.SFXPlayOneShotDistCheck("event:/SFX ASITP/sfx_villagers_chop_stone_complete", villager.Pos);
					}
					GetSystem().RemoveTree(cellToChop, firstItem2);
				}
				animState = AnimState.Falling;
				if (clearType == ClearType.Rocks)
				{
					animDelay = 0f;
				}
				else
				{
					animDelay = 1.7f;
				}
			}
			else
			{
				animState = AnimState.Idle;
				DoHarvest();
			}
			break;
		}
		case AnimState.ChopWait:
			animDelay -= dt;
			if (animDelay <= 0f)
			{
				animState = AnimState.Chopping;
			}
			break;
		case AnimState.Falling:
			animDelay -= dt;
			if (animDelay <= 0f)
			{
				animState = AnimState.Idle;
				DoHarvest();
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}

	private void UpdateClearType()
	{
		while (GetSystem().ItemAmountIncludeAnimatingTrees(cellToChop) == 0)
		{
			clearType++;
			if (clearType == ClearType.Done)
			{
				break;
			}
		}
	}

	private void TransitionToStartChop()
	{
		status = Status.StartChop;
		UpdateClearType();
	}

	private TreeSystem GetSystem()
	{
		if (clearType == ClearType.Trees)
		{
			return World.inst.treeSystem;
		}
		if (clearType == ClearType.CoppiceTrees)
		{
			return World.inst.coppiceTreeSystem;
		}
		if (clearType == ClearType.Rocks)
		{
			return World.inst.rockScatterSystem;
		}
		return null;
	}

	protected int DoHarvest()
	{
		int num = 0;
		int num2 = -1;
		if (clearType == ClearType.Trees || clearType == ClearType.CoppiceTrees)
		{
			int num3 = ((!StreamerEffects.Flag_TreeDoubleYield) ? 1 : 2);
			num = SRand.Range(3, 4) * num3;
			num2 = 1;
			EffectsMan.inst.TreeFallEffect.CreateAndPlayVisibilityCheck(cellToChop.Center3D + new Vector3(0f, 0.2f, 0f));
		}
		else if (clearType == ClearType.Rocks)
		{
			num2 = 2;
			num = SRand.Range(5, 8);
			EffectsMan.inst.WallHitEffect.CreateAndPlayVisibilityCheck(cellToChop.Center3D + new Vector3(0f, 0.4f, 0f));
		}
		EffectsMan.inst.BuildEffectPuffSmall.CreateAndPlayVisibilityCheck(cellToChop.Center3D + new Vector3(0f, 0.1f, 0f));
		if (num > 0)
		{
			ResourceTextStackManager.inst.ShowResourceAmount(this, Employee.Pos, num2, num);
			FreeResourceManager.inst.AddOrMakeAutoStackFor(num2, num, cellToChop.Center3D);
			ResourceStatistics.AddProduction(employer.LandMass(), "clearcutter", num2, num);
		}
		TransitionToStartChop();
		return num;
	}
}
