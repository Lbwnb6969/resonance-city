using System;
using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;

namespace Assets.Code.Jobs;

public class WoodCutterJob : Job
{
	protected enum ClearType
	{
		Trees,
		CoppiceTrees,
		Done
	}

	protected enum AnimState
	{
		Idle,
		Chopping,
		ChopWait,
		Falling
	}

	private enum Status
	{
		Idle,
		Looking,
		Traveling,
		Chopping,
		HarvestWood,
		TimeOff
	}

	[Serializable]
	public class WoodCutterJobSaveData : JobSaveData<WoodCutterJob, WoodCutterJobSaveData>
	{
		public override WoodCutterJobSaveData Pack(WoodCutterJob j)
		{
			return base.Pack(j);
		}

		public override WoodCutterJob Unpack(WoodCutterJob j)
		{
			return base.Unpack(j);
		}
	}

	protected GameObject workingIcon;

	protected int chops = 16;

	[NonSerialized]
	public Cell cellToChop;

	protected ClearType clearType;

	protected AnimState animState;

	protected int chopsLeft;

	private float animDelay;

	private Forester forester;

	private Status status;

	private List<Cell> validTreeBuffer = new List<Cell>();

	public void ClearCellToChop()
	{
		if ((bool)workingIcon)
		{
			workingIcon.SetActive(value: false);
		}
		if (cellToChop != null && cellToChop.Busy)
		{
			cellToChop.RemoveBusy(this);
		}
		cellToChop = null;
		animState = AnimState.Idle;
	}

	public override void OnJobRemoved()
	{
		ClearCellToChop();
		UnityEngine.Object.Destroy(workingIcon);
		workingIcon = null;
		base.OnJobRemoved();
	}

	public override void OnEmployeeQuit()
	{
		ClearCellToChop();
		base.OnEmployeeQuit();
	}

	protected TreeSystem GetSystem()
	{
		if (clearType == ClearType.Trees)
		{
			return World.inst.treeSystem;
		}
		if (clearType == ClearType.CoppiceTrees)
		{
			return World.inst.coppiceTreeSystem;
		}
		return null;
	}

	protected void UpdateClearType()
	{
		clearType = ClearType.Trees;
		while (GetSystem().ItemAmount(cellToChop) == 0)
		{
			clearType++;
			if (clearType == ClearType.Done)
			{
				break;
			}
		}
	}

	public void StartChoppingAt(Cell c)
	{
		cellToChop = c;
		cellToChop.AddBusy(this);
		UpdateClearType();
		int firstItem = GetSystem().GetFirstItem(cellToChop);
		TreeSystem.TreeData item = GetSystem().GetItem(cellToChop, firstItem);
		if (Employee != null)
		{
			Vector3 newPos = item.pos + (Employee.Pos - item.pos).normalized * 0.2f;
			newPos.x = Mathf.Clamp(newPos.x, (float)cellToChop.x + 0.01f, (float)cellToChop.x + 0.95f);
			newPos.z = Mathf.Clamp(newPos.z, (float)cellToChop.z + 0.01f, (float)cellToChop.z + 0.95f);
			Employee.MoveToDeferred(newPos);
		}
		workingIcon.transform.position = cellToChop.Center3D + Vector3.up * 0.25f;
		workingIcon.SetActive(!World.IsAILandmass(c.landMassIdx));
	}

	public float GetChoppingProgress()
	{
		if (animState != AnimState.Chopping && animState != AnimState.ChopWait)
		{
			return 0f;
		}
		return 1f - Mathff.Clamp01((float)chopsLeft / (float)chops);
	}

	public WoodCutterJob(IEmployer e)
		: base(e)
	{
		workingIcon = UnityEngine.Object.Instantiate(Resources.Load("cursor_axe")) as GameObject;
		workingIcon.GetComponent<MeshRenderer>().material = World.inst.uniMaterialNoFog;
		workingIcon.GetComponent<MeshRenderer>().shadowCastingMode = ShadowCastingMode.Off;
		workingIcon.transform.localScale = new Vector3(0.8f, 0.8f, 0.8f);
		workingIcon.SetActive(value: false);
		meshType = VillagerSystem.MeshType.Axeman;
		ManualFreetime = true;
		if (e is Building)
		{
			forester = (e as Building).GetComponent<Forester>();
		}
		meshType = VillagerSystem.MeshType.Axeman;
	}

	public override void OnEmployeeAssigned()
	{
		TransitionToIdle();
		chops = GetChops();
		base.OnEmployeeAssigned();
	}

	private int GetChops()
	{
		int num = 16;
		if ((bool)forester && forester.toolUsage > 0)
		{
			num = (int)((float)num * 0.75f);
			forester.DoToolUsage();
		}
		if (Employee.FindSkill("Woodcutting".GetHashCode()) > 0.5f)
		{
			num -= 2;
		}
		if (StreamerEffects.Flag_ChopFaster)
		{
			num /= 2;
		}
		return num;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.Looking:
			text += ScriptLocalization.jobWoodCutterDescriptionSearching;
			break;
		case Status.Traveling:
			text += ScriptLocalization.jobWoodCutterDescriptionTraveling;
			break;
		case Status.Chopping:
			text += ScriptLocalization.jobDescriptionCuttingTree;
			break;
		case Status.HarvestWood:
			text += string.Format(ScriptLocalization.jobDescriptionCollecting, ResourceAmount.ResourceIcon(1));
			break;
		}
		return text;
	}

	public void TransitionToIdle()
	{
		ClearCellToChop();
		status = Status.Idle;
		animState = AnimState.Idle;
	}

	public static void GetNonBusyTreeCellInRadius(Vector3 s, float r, ref List<Cell> results)
	{
		results.Clear();
		int num = (int)s.x;
		int num2 = (int)s.z;
		int num3 = (int)r;
		int num4 = Mathf.Max(num - num3, 0);
		int num5 = Mathf.Max(num2 - num3, 0);
		int num6 = Mathf.Min(num + num3, World.inst.GridWidth - 1);
		int num7 = Mathf.Min(num2 + num3, World.inst.GridHeight - 1);
		for (int i = num4; i <= num6; i++)
		{
			for (int j = num5; j <= num7; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i, j);
				if (!cellDataUnsafe.Busy && (World.inst.coppiceTreeSystem.ItemAmount(cellDataUnsafe) > 0 || World.inst.treeSystem.ItemAmount(cellDataUnsafe) > 0) && World.inst.TileTouchingRadius(cellDataUnsafe, s, r))
				{
					results.Add(cellDataUnsafe);
				}
			}
		}
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		if (cellToChop != null && World.inst.treeSystem.ItemAmountIncludeAnimatingTrees(cellToChop) == 0 && status != Status.Idle && status != Status.Looking)
		{
			TransitionToIdle();
		}
		if (cellToChop != null && cellToChop.busyObj is Fire)
		{
			if (status == Status.Chopping && World.inst.GetVillagerCountForLandmass(employer.LandMass()) > 5)
			{
				Player.inst.DestroyPerson(villager, leaveBehindBody: true);
			}
			else
			{
				status = Status.Looking;
			}
		}
		switch (status)
		{
		case Status.Idle:
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
				ClearCellToChop();
			}
			else if (!forester.halted)
			{
				status = Status.Looking;
			}
			break;
		case Status.Looking:
		{
			int radius = forester.Radius;
			validTreeBuffer.Clear();
			int num = Mathf.CeilToInt(MathF.PI * (float)(radius + 1) * (float)(radius + 1));
			if (num > validTreeBuffer.Capacity)
			{
				validTreeBuffer.Capacity = num;
			}
			GetNonBusyTreeCellInRadius(forester.GetComponent<Building>().Center(), radius, ref validTreeBuffer);
			ClearCellToChop();
			if (validTreeBuffer.Count > 0)
			{
				Cell cell = validTreeBuffer[SRand.Range(0, validTreeBuffer.Count)];
				if (cell != null)
				{
					status = Status.Traveling;
					StartChoppingAt(cell);
				}
			}
			else
			{
				TransitionToIdle();
			}
			break;
		}
		case Status.Traveling:
			if (Mathff.DistSqrdXZ(villager.Pos, cellToChop.Center3D) < 1f)
			{
				chops = GetChops();
				status = Status.Chopping;
				UpdateClearType();
				animState = AnimState.Chopping;
				chopsLeft = chops;
			}
			break;
		case Status.TimeOff:
			if (employer.DuringWorkHours())
			{
				villager.FreeTime(_freeTime: false);
				TransitionToIdle();
			}
			else
			{
				villager.FreeTime(_freeTime: true);
			}
			break;
		}
		workingIcon.transform.Rotate(0f, 0f, Mathf.Sin(Time.unscaledTime * 10f) * 0.4f);
		switch (animState)
		{
		case AnimState.Chopping:
		{
			SfxSystem.inst.PlayFromBankIfVisibleOneShot((chopsLeft == 0) ? "treechopfinal" : "treechop", villager.Pos);
			int num2 = -1;
			if (GetSystem() != null)
			{
				num2 = GetSystem().GetFirstItem(cellToChop);
			}
			if (num2 != -1)
			{
				if (!World.IsAILandmass(cellToChop.landMassIdx))
				{
					GetSystem().ShakeItem(cellToChop, num2);
				}
				chopsLeft--;
				if (chopsLeft != 0)
				{
					animState = AnimState.ChopWait;
					animDelay = 0.6f;
					break;
				}
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("treefall", villager.Pos);
				GetSystem().FellTree(cellToChop, num2);
				animState = AnimState.Falling;
				animDelay = 1.7f;
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

	protected int DoHarvest()
	{
		int num = 2;
		int cellsWithTrees = 0;
		World.inst.ForEachTile(cellToChop.x - 1, cellToChop.z - 1, cellToChop.x + 1, cellToChop.z + 1, (int x, int z, Cell cell) =>
		{
			if (World.inst.coppiceTreeSystem.ItemAmount(cell) > 0 || World.inst.treeSystem.ItemAmount(cell) > 0)
			{
				cellsWithTrees++;
			}
		});
		int num2 = 0;
		if (cellsWithTrees >= 4)
		{
			num2 = 1;
		}
		if (cellsWithTrees >= 6)
		{
			num2 = 2;
		}
		if (cellsWithTrees >= 9)
		{
			num2 = 3;
		}
		num += num2;
		workingIcon.SetActive(value: false);
		int num3 = Mathf.Min(num, forester.stack.MaxCapacity() - forester.stack.Count());
		ResourceTextStackManager.inst.ShowResourceAmount(this, forester.GetComponent<Building>().Center(), 1, num3);
		forester.AddToWoodPile(num3);
		ResourceStatistics.AddProduction(employer.LandMass(), World.foresterName, 1, num);
		status = Status.Idle;
		return num;
	}
}
