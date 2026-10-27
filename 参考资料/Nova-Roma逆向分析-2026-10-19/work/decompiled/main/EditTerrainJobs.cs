using System;
using Assets;
using Assets.Code;
using I2.Loc;
using UnityEngine;

public class EditTerrainJobs : Job
{
	public enum Status
	{
		Searching,
		GoingToResource,
		TakingToDropoff,
		TimeOff
	}

	[Serializable]
	public class EditTerrainJobsSaveData : JobSaveData<EditTerrainJobs, EditTerrainJobsSaveData>
	{
		[NonSerialized]
		public EditTerrainProject ProjectRef_Injected;

		public Status status;

		public EditTerrainProject.EditTerrainMoveUnit moveUnit;

		public override EditTerrainJobsSaveData Pack(EditTerrainJobs j)
		{
			status = j.status;
			if (j.moveUnit != null)
			{
				moveUnit = new EditTerrainProject.EditTerrainMoveUnit(j.moveUnit);
			}
			else
			{
				moveUnit = null;
			}
			return base.Pack(j);
		}

		public override EditTerrainJobs Unpack(EditTerrainJobs j)
		{
			base.Unpack(j);
			j.status = status;
			j.project = ProjectRef_Injected;
			if (moveUnit != null)
			{
				j.moveUnit = new EditTerrainProject.EditTerrainMoveUnit(moveUnit);
			}
			else
			{
				j.moveUnit = null;
			}
			return j;
		}
	}

	private Status status;

	private static int updateID;

	private static int searchUpdateID;

	private EditTerrainProject project;

	private EditTerrainProject.EditTerrainMoveUnit moveUnit;

	private bool forceUpdatePath = true;

	private FrameUpdater pathUpdate;

	private FrameUpdater searchUpdate;

	public EditTerrainJobs(IEmployer e)
		: base(e)
	{
		pathUpdate = new FrameUpdater(ref updateID, 30);
		searchUpdate = new FrameUpdater(ref searchUpdateID, 30);
		project = e as EditTerrainProject;
		meshType = VillagerSystem.MeshType.HandCart;
		ManualFreetime = true;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.Searching:
			text += string.Format(ScriptLocalization.jobDescriptionSearching, ResourceAmount.ResourceIcon(17));
			break;
		case Status.GoingToResource:
			text += string.Format(ScriptLocalization.jobDescriptionFetching, ResourceAmount.ResourceIcon(17));
			break;
		case Status.TakingToDropoff:
			text += string.Format(ScriptLocalization.jobDescriptionReturning, ResourceAmount.ResourceIcon(17));
			break;
		}
		return text;
	}

	public override void BeforeJobRemoved()
	{
		Employee?.DestroyHeldResources();
		base.BeforeJobRemoved();
	}

	public override void OnEmployeeQuit()
	{
		Employee?.DestroyHeldResources();
		base.OnEmployeeQuit();
	}

	public void MakeGroundDirt(int index)
	{
		int num = index % World.MeshWidth;
		int num2 = index / World.MeshWidth;
		bool flag = num % 2 == 0;
		bool flag2 = num2 % 2 == 0;
		for (int i = (flag ? (-1) : 0); i <= (flag ? 1 : 0); i++)
		{
			for (int j = (flag2 ? (-1) : 0); j <= (flag2 ? 1 : 0); j++)
			{
				int num3 = num + i;
				int num4 = num2 + j;
				if (num3 >= 0 && num4 >= 0 && num3 < World.MeshWidth && num4 < World.MeshHeight)
				{
					int i2 = DynamicWater.MapIndexMeshToWorld(num3 + num4 * World.MeshWidth, World.inst.GridWidth);
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i2);
					TerrainGen.inst.SetTempEffectTile(cellDataUnsafe, 1, 250f);
					TerrainGen.inst.ClearGrassTile(cellDataUnsafe, 250f);
				}
			}
		}
	}

	public override void UpdateWithEmployee(float dt)
	{
		pathUpdate.Update();
		searchUpdate.Update();
		switch (status)
		{
		case Status.Searching:
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
				break;
			}
			moveUnit = project.GetNewMoveUnit();
			if (moveUnit != null)
			{
				status = Status.GoingToResource;
			}
			else
			{
				project.LooksLikeImDoneHere(this);
			}
			break;
		case Status.GoingToResource:
		{
			Vector3 pos2 = moveUnit.pickupPosition;
			TerrainGen.inst.GetGroundHeight(ref pos2);
			if (Mathff.DistSqrd(Employee.Pos, pos2) < 0.010000001f)
			{
				status = Status.TakingToDropoff;
				FreeResource resource = FreeResourceSystem.inst.AddFreeResource(17, Employee.Pos, employer.LandMass());
				MakeGroundDirt(moveUnit.fromMeshIndex);
				Employee.PickupResource(resource);
				project.Pickup(moveUnit);
				forceUpdatePath = true;
			}
			else if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				Employee.MoveToDeferred(pos2);
			}
			break;
		}
		case Status.TakingToDropoff:
		{
			Vector3 pos = moveUnit.dropoffPosition;
			TerrainGen.inst.GetGroundHeight(ref pos);
			if (Mathff.DistSqrdXZ(Employee.Pos, pos) < 0.010000001f)
			{
				Employee.DestroyHeldResources();
				MakeGroundDirt(moveUnit.toMeshIndex);
				project.DropOff(moveUnit);
				status = Status.Searching;
				forceUpdatePath = true;
			}
			else if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				Employee.MoveToDeferred(pos);
			}
			break;
		}
		case Status.TimeOff:
			if (searchUpdate.Trigger())
			{
				if (employer.DuringWorkHours())
				{
					Employee.FreeTime(_freeTime: false);
					status = Status.Searching;
				}
				else
				{
					Employee.FreeTime(_freeTime: true);
				}
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}
}
