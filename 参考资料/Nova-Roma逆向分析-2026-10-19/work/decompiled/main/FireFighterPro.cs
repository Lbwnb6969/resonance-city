using System;
using Assets.Code;
using I2.Loc;
using UnityEngine;

public class FireFighterPro : FireFighter
{
	[Serializable]
	public class FireFighterProJobSaveData : JobSaveData<FireFighterPro, FireFighterProJobSaveData>
	{
		public override FireFighterProJobSaveData Pack(FireFighterPro j)
		{
			return base.Pack(j);
		}

		public override FireFighterPro Unpack(FireFighterPro j)
		{
			base.Unpack(j);
			return j;
		}
	}

	private bool triggerOnce;

	public FireFighterPro(Building b)
		: base(b)
	{
		ManualAssignment = false;
		fireContributeCount = 2;
	}

	public override void OnEmployeeAssigned()
	{
		base.OnEmployeeAssigned();
		Employee.speedBonusMultiplier = 1.4f;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		if (currentTask == Task.FindWater || currentTask == Task.FightFire)
		{
			text += LocalizationManager.GetTranslation("jobDescriptionProfessionalFirefighter");
		}
		return text;
	}

	private void UpdateFireTarget()
	{
		float num = float.MaxValue;
		Vector3 position = (employer as MonoBehaviour).transform.position;
		Transform transform = FireManager.inst.fireContainer.transform;
		int i = 0;
		for (int childCount = transform.childCount; i < childCount; i++)
		{
			Fire component = transform.GetChild(i).GetComponent<Fire>();
			if (component.LandMass() == employer.LandMass() && !component.Dying)
			{
				float num2 = Mathff.DistSqrdXZ(transform.GetChild(i).position, position);
				if (num2 < num)
				{
					num = num2;
					fireTarget = component;
					triggerOnce = true;
				}
			}
		}
		if (fireTarget != null && Employee != null)
		{
			Employee.FreeTime(_freeTime: false);
		}
	}

	public override void UpdateAlways(float dt)
	{
		if (fireTarget == null || !fireTarget.gameObject.activeSelf || fireTarget.Dying)
		{
			fireTarget = null;
			bool flag = true;
			if (currentTask == Task.FindWater || currentTask == Task.FightFire)
			{
				UpdateFireTarget();
				if ((bool)fireTarget)
				{
					if (currentTask == Task.FightFire)
					{
						SetCurrTask(currentTask);
					}
					else
					{
						_ = currentTask;
						_ = 1;
					}
					flag = false;
				}
			}
			if (flag && triggerOnce)
			{
				triggerOnce = false;
				SetCurrTask(Task.NotWorried);
			}
		}
		if (fireTarget == null && HasEmployee())
		{
			UpdateFireTarget();
			if ((bool)fireTarget && currentTask == Task.NotWorried)
			{
				SetCurrTask(Task.FightFire);
			}
		}
		base.UpdateAlways(dt);
	}
}
