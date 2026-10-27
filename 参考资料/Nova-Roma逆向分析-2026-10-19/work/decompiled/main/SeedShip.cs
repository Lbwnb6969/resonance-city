using System;
using Assets.Code;
using UnityEngine;

public class SeedShip : ShipBase, ISelectable, IMoveableUnit, IMoveTarget
{
	public bool CanDisband = true;

	public int SearchRadius;

	public int SettlerVillagers = 5;

	public ResourceAmount SettleStockPiles;

	public bool CanSettle;

	private Cell prevCell;

	bool IMoveTarget.IsStationary()
	{
		return false;
	}

	public Vector3 GetDestPos()
	{
		if (!arrived)
		{
			if (deferredPath.status != GamePath.Status.Uninitialized)
			{
				return deferredPath.end;
			}
			if (path.Count > 0)
			{
				return path.data[path.Count - 1];
			}
		}
		return GetPos();
	}

	public bool IsBlockingCell()
	{
		return false;
	}

	public Vector3 GetToNextCell()
	{
		return transform.forward;
	}

	public int TeamID()
	{
		return teamID;
	}

	public AttackType GetAttackType()
	{
		return AttackType.Melee;
	}

	public int GetLOS()
	{
		return 8;
	}

	UnitType IMoveableUnit.GetUnitType()
	{
		return UnitType.Ship;
	}

	MoveType IMoveableUnit.GetMoveType()
	{
		return MoveType.Water;
	}

	void IMoveableUnit.MoveTo(IMoveTarget target)
	{
		MoveTo(target);
	}

	public void Disband()
	{
		EffectsMan.inst.BuildPuff.CreateAndPlay(transform.position);
		SfxSystem.inst.PlayFromBank("DestroyTransportShip", transform.position);
		OrdersManager.inst.DestroyUnit(this);
	}

	IMoveTarget IMoveableUnit.GetMoveTarget()
	{
		return moveTarget;
	}

	public void DoUnload(IMoveableUnit u)
	{
	}

	public bool CanAttack()
	{
		return false;
	}

	public bool CanCarry()
	{
		return false;
	}

	public bool CanBeCarried()
	{
		return false;
	}

	public bool TryBeCarried()
	{
		return false;
	}

	public void StopBeingCarried()
	{
	}

	public bool IsFullCapacity()
	{
		return false;
	}

	public bool IsPendingLoadTargets()
	{
		return false;
	}

	public bool IsBeingCarried()
	{
		return false;
	}

	public bool PendingCarry(IMoveableUnit u)
	{
		return false;
	}

	public int GetRemainingCapacity()
	{
		return 0;
	}

	public int CarryCount()
	{
		return 0;
	}

	public IMoveableUnit GetCarried(int i)
	{
		return null;
	}

	public int FormationIdx()
	{
		return 0;
	}

	public Guid GetGuid()
	{
		return guid;
	}

	public float CurrHealth()
	{
		return life;
	}

	public float MaxHealth()
	{
		return maxLife;
	}

	public void DestroyUnit()
	{
		UnityEngine.Object.Destroy(gameObject);
	}

	public void OnUnitTargetsUs(IMoveableUnit unit)
	{
	}

	public void OnUnitStoppedTargetingUs(IMoveableUnit u)
	{
	}

	void IMoveableUnit.NotifyOtherUnitDeath(IMoveableUnit u)
	{
	}

	bool ISelectable.ExclusiveSelect()
	{
		return false;
	}

	bool ISelectable.ValidToSelect()
	{
		return state == State.Sailing;
	}

	void ISelectable.SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	void ISelectable.OnSelected()
	{
	}

	bool ISelectable.InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		int num = (int)GetPos().x;
		int num2 = (int)GetPos().z;
		if (minx <= num && num <= maxx && minz <= num2)
		{
			return num2 <= maxz;
		}
		return false;
	}

	private void UpdateBanners()
	{
		UpdateMaterial();
	}

	public void Settle(Building outpost)
	{
		outpost.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		minX = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
		maxX = Mathff.Clamp(maxX + 1, 0, World.inst.GridWidth - 1);
		minZ = Mathff.Clamp(minZ - 1, 0, World.inst.GridHeight - 1);
		maxZ = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
		Vector3 vector = outpost.GetPos();
		Vector3 vector2 = vector;
		float num = 0f;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j < maxX; j++)
			{
				float num2 = Mathff.DistSqrdXZ(vector, new Vector3(j, 0f, i));
				if (num2 > num)
				{
					num = num2;
					vector2 = World.inst.GetCellData(j, i).Center2D;
				}
			}
		}
		float num3 = (float)Math.Ceiling(Mathf.Sqrt(4f));
		float num4 = 1f / num3;
		num4 *= 0.9f;
		for (int k = 0; k < FreeResourceSystem.inst.resourceDefs.Count; k++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[k];
			Vector3 vector3 = new Vector3(-0.425f, 0f, -0.425f) + vector2;
			float x = (float)k / num3 * num4;
			float z = (float)k % num3 * num4;
			vector3 += new Vector3(x, 0f, z);
			int num5 = SettleStockPiles.Get(resourceDef.ID);
			if (resourceDef.ID != 4 && num5 > 0)
			{
				FreeResourceManager.inst.GetAutoStackFor(resourceDef.ID, num5, vector3);
			}
		}
		for (int l = 0; l < SettlerVillagers; l++)
		{
			Villager villager = Villager.CreateVillager();
			Player.inst.Workers.Add(villager);
			Player.inst.Homeless.Add(villager);
			villager.TeleportTo(vector2 + SRand.insideUnitSquareXZ * 0.5f);
		}
		EffectsMan.inst.BuildPuff.CreateAndPlay(vector2);
		Disband();
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		bool flag = false;
		Cell cellDataClamped = World.inst.GetCellDataClamped(GetPos());
		Vector3 center2D = cellDataClamped.Center2D;
		int num = (int)Mathff.Clamp(center2D.x - (float)SearchRadius, 0f, World.inst.GridWidth - 1);
		int num2 = (int)Mathff.Clamp(center2D.x + (float)SearchRadius, 0f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(center2D.z - (float)SearchRadius, 0f, World.inst.GridHeight - 1);
		int num4 = (int)Mathff.Clamp(center2D.z + (float)SearchRadius, 0f, World.inst.GridHeight - 1);
		int num5 = SearchRadius * SearchRadius;
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j < num2; j++)
			{
				if ((center2D.x - (float)j) * (center2D.x - (float)j) + (center2D.z - (float)i) * (center2D.z - (float)i) <= (float)num5 && World.inst.GetCellData(j, i).Type != TerrainType.Water)
				{
					flag = true;
					break;
				}
			}
		}
		if (flag != CanSettle)
		{
			CanSettle = flag;
		}
		if (prevCell != cellDataClamped && GameUI.inst.CurrPlacementMode.IsPlacing() && GameUI.inst.CurrPlacementMode.heldPrefab.UniqueName == World.romanOutpostName)
		{
			prevCell = cellDataClamped;
			GameUI.inst.CurrPlacementMode.UpdateTerrainTexture();
		}
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
		OrdersManager.inst.RemoveUnit(this);
	}
}
