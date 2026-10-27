using System;
using UnityEngine;

public interface IUnitControllable
{
	int GetFormationIdx();

	int GetUnitType();

	int TeamID();

	int GetMoveType();

	int GetSlotsOccupied();

	void MoveTo(IMoveTarget target);

	IMoveTarget GetMoveTarget();

	void SetPos(Vector3 pos);

	Vector3 GetPos();

	Vector3 GetDestPos();

	Vector3 GetToNextCell();

	bool IsBlockingCell();

	int GetLOS();

	int GetAttackType();

	void OnUnitTargetsUs(IUnitControllable u);

	void OnUnitStoppedTargetingUs(IUnitControllable u);

	void NotifyOtherUnitDeath(IUnitControllable u);

	void DestroyUnit();

	bool CanAttack();

	bool CanCarry();

	bool CanBeCarried();

	bool TryBeCarried();

	void StopBeingCarried();

	bool IsBeingCarried();

	bool IsPendingLoadTargets();

	int GetRemainingCapacity();

	int CarryCount();

	IUnitControllable GetCarried(int i);

	float CurrHealth();

	float MaxHealth();

	void Disband();

	bool PendingCarry(IUnitControllable toLoad);

	Guid GetGuid();

	void DoUnload(IUnitControllable u);
}
