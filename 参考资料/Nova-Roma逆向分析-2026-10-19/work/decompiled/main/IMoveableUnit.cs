using System;
using UnityEngine;

public interface IMoveableUnit
{
	UnitType GetUnitType();

	int TeamID();

	MoveType GetMoveType();

	void MoveTo(IMoveTarget target);

	IMoveTarget GetMoveTarget();

	void SetPos(Vector3 pos);

	Vector3 GetPos();

	Vector3 GetDestPos();

	Vector3 GetToNextCell();

	bool IsBlockingCell();

	int GetLOS();

	AttackType GetAttackType();

	int FormationIdx();

	void OnUnitTargetsUs(IMoveableUnit u);

	void OnUnitStoppedTargetingUs(IMoveableUnit u);

	void NotifyOtherUnitDeath(IMoveableUnit u);

	void DestroyUnit();

	bool CanAttack();

	bool CanCarry();

	bool CanBeCarried();

	bool TryBeCarried();

	void StopBeingCarried();

	bool IsBeingCarried();

	bool IsFullCapacity();

	bool IsPendingLoadTargets();

	int GetRemainingCapacity();

	int CarryCount();

	IMoveableUnit GetCarried(int i);

	float CurrHealth();

	float MaxHealth();

	void Disband();

	bool PendingCarry(IMoveableUnit toLoad);

	Guid GetGuid();

	void DoUnload(IMoveableUnit u);
}
