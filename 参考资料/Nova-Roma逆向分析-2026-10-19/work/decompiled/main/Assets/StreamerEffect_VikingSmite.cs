using UnityEngine;

namespace Assets;

public class StreamerEffect_VikingSmite : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "VikingSmite";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\plague");
		for (int i = 0; i < RaiderSystem.inst.unitData.Count; i++)
		{
			IUnitControllable unit = RaiderSystem.inst.unitData[i].unit;
			if (unit.IsBeingCarried())
			{
				continue;
			}
			Weather.inst.LightningStrike(unit.GetPos(), doFire: false, smallstrike: true);
			if (unit is ArmySystem.Army)
			{
				ArmySystem.Army army = unit as ArmySystem.Army;
				for (int j = 0; j < army.units.Count; j++)
				{
					ArmySystem.inst.QuickDeath(army.units.data[j]);
				}
				army.generalLife = 0f;
			}
			else
			{
				(unit as MonoBehaviour).GetComponent<IProjectileHitable>()?.TakeProjectileDamage(99999f, DamageType.Standard, DamageSource.Ranged, new Vector3(0f, 100f, 0f), new Vector3(0f, -100f, 0f), -1);
			}
		}
	}

	public override void OnEnd()
	{
	}
}
