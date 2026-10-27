using System;
using UnityEngine;

public class Upgradeable : MonoBehaviour
{
	[Serializable]
	public class UpgradeableSaveData : SaveClass<Upgradeable, UpgradeableSaveData>
	{
		public int level;

		public override UpgradeableSaveData Pack(Upgradeable obj)
		{
			level = obj.level;
			return this;
		}

		public override Upgradeable Unpack(Upgradeable obj)
		{
			obj.SetUpgrade(level);
			return obj;
		}
	}

	public int level;

	public Upgrade[] upgrades;

	public void OnInit()
	{
		level = 0;
	}

	public bool TryUpgrade()
	{
		SendMessage("UpgradeTo", level + 1, SendMessageOptions.DontRequireReceiver);
		GetComponent<Building>().FinishAnimateUpgrade(6f, upgrades[level].model);
		upgrades[level + 1].model.SetActive(value: true);
		level++;
		return true;
	}

	public void SetUpgrade(int _level)
	{
		level = _level;
		for (int i = 0; i < upgrades.Length; i++)
		{
			upgrades[i].model.SetActive(value: false);
		}
		SendMessage("UpgradeTo", level, SendMessageOptions.DontRequireReceiver);
		upgrades[level].model.SetActive(value: true);
	}

	public bool IsFullyUpgraded()
	{
		return level == upgrades.Length - 1;
	}
}
