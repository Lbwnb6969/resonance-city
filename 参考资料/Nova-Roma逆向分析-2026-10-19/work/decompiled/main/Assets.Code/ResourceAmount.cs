using System;
using System.Collections.Generic;
using I2.Loc;

namespace Assets.Code;

[Serializable]
public class ResourceAmount
{
	public static readonly ResourceAmount empty = new ResourceAmount();

	public List<Resource> resources = new List<Resource>();

	public ResourceAmount()
	{
	}

	public ResourceAmount(ResourceAmount r)
	{
		for (int i = 0; i < r.resources.Count; i++)
		{
			Set(r.resources[i].resourceID, r.resources[i].Amount);
		}
	}

	public Resource FindResource(int rID)
	{
		int i = 0;
		for (int count = resources.Count; i < count; i++)
		{
			if (resources[i].resourceID == rID)
			{
				return resources[i];
			}
		}
		return null;
	}

	public int Get(int resourceID)
	{
		if (resourceID == -1)
		{
			return 0;
		}
		return FindResource(resourceID)?.Amount ?? 0;
	}

	public void Add(int resourceID, int val)
	{
		Resource resource = FindResource(resourceID);
		if (resource != null)
		{
			resource.Amount += val;
			return;
		}
		resources.Add(new Resource
		{
			resourceID = resourceID,
			Amount = val
		});
	}

	public void Add(in ResourceAmount addR)
	{
		for (int i = 0; i < addR.resources.Count; i++)
		{
			Resource resource = FindResource(addR.resources[i].resourceID);
			if (resource == null)
			{
				resources.Add(new Resource
				{
					resourceID = addR.resources[i].resourceID,
					Amount = addR.resources[i].Amount
				});
			}
			else
			{
				resource.Amount += addR.resources[i].Amount;
			}
		}
	}

	public void Subtract(in ResourceAmount subR)
	{
		for (int i = 0; i < subR.resources.Count; i++)
		{
			Resource resource = FindResource(subR.resources[i].resourceID);
			if (resource == null)
			{
				resources.Add(new Resource
				{
					resourceID = subR.resources[i].resourceID,
					Amount = -subR.resources[i].Amount
				});
			}
			else
			{
				resource.Amount -= subR.resources[i].Amount;
			}
		}
	}

	public void Set(int _resourceID, int val)
	{
		Resource resource = FindResource(_resourceID);
		if (resource != null)
		{
			resource.Amount = val;
			return;
		}
		resources.Add(new Resource
		{
			resourceID = _resourceID,
			Amount = val
		});
	}

	public static bool operator >=(ResourceAmount c1, ResourceAmount c2)
	{
		for (int i = 0; i < c1.resources.Count; i++)
		{
			if (c2.FindResource(c1.resources[i].resourceID).Amount > c1.resources[i].Amount)
			{
				return false;
			}
		}
		return true;
	}

	public static bool operator <=(ResourceAmount c1, ResourceAmount c2)
	{
		for (int i = 0; i < c1.resources.Count; i++)
		{
			if (c2.FindResource(c1.resources[i].resourceID).Amount < c1.resources[i].Amount)
			{
				return false;
			}
		}
		return true;
	}

	public static bool operator ==(ResourceAmount c1, ResourceAmount c2)
	{
		if ((object)c2 == null && (object)c1 != null)
		{
			return false;
		}
		if ((object)c2 != null && (object)c1 == null)
		{
			return false;
		}
		if ((object)c1 == null && (object)c2 == null)
		{
			return true;
		}
		for (int i = 0; i < c1.resources.Count; i++)
		{
			if (c1.resources[i].Amount != 0)
			{
				Resource resource = c2.FindResource(c1.resources[i].resourceID);
				if (resource == null)
				{
					return false;
				}
				if (resource.Amount != c1.resources[i].Amount)
				{
					return false;
				}
			}
		}
		for (int j = 0; j < c2.resources.Count; j++)
		{
			if (c2.resources[j].Amount != 0)
			{
				Resource resource2 = c1.FindResource(c2.resources[j].resourceID);
				if (resource2 == null)
				{
					return false;
				}
				if (resource2.Amount != c2.resources[j].Amount)
				{
					return false;
				}
			}
		}
		return true;
	}

	public static bool operator !=(ResourceAmount c1, ResourceAmount c2)
	{
		return !(c1 == c2);
	}

	public static ResourceAmount operator *(ResourceAmount c, float s)
	{
		ResourceAmount resourceAmount = new ResourceAmount(c);
		for (int i = 0; i < c.resources.Count; i++)
		{
			resourceAmount.Set(c.resources[i].resourceID, (int)((float)c.resources[i].Amount * s));
		}
		return resourceAmount;
	}

	public static ResourceAmount operator +(ResourceAmount c, ResourceAmount d)
	{
		ResourceAmount resourceAmount = new ResourceAmount(c);
		for (int i = 0; i < d.resources.Count; i++)
		{
			resourceAmount.Set(d.resources[i].resourceID, c.Get(d.resources[i].resourceID) + d.resources[i].Amount);
		}
		return resourceAmount;
	}

	public static ResourceAmount operator -(ResourceAmount c, ResourceAmount d)
	{
		ResourceAmount resourceAmount = new ResourceAmount(c);
		for (int i = 0; i < d.resources.Count; i++)
		{
			resourceAmount.Set(d.resources[i].resourceID, c.Get(d.resources[i].resourceID) - d.resources[i].Amount);
		}
		return resourceAmount;
	}

	public bool CanSubtract(ResourceAmount amt)
	{
		for (int i = 0; i < amt.resources.Count; i++)
		{
			if (Get(amt.resources[i].resourceID) < amt.resources[i].Amount)
			{
				return false;
			}
		}
		return true;
	}

	public bool TrySubtract(int resourceID, int amount)
	{
		if (Get(resourceID) - amount >= 0 || amount <= 0)
		{
			Add(resourceID, -amount);
			return true;
		}
		return false;
	}

	public bool TrySubtract(ResourceAmount r)
	{
		bool flag = false;
		for (int i = 0; i < r.resources.Count; i++)
		{
			int resourceID = r.resources[i].resourceID;
			if (Get(resourceID) - r.resources[i].Amount < 0 && r.resources[i].Amount > 0)
			{
				flag = true;
			}
		}
		if (!flag)
		{
			for (int j = 0; j < r.resources.Count; j++)
			{
				Add(r.resources[j].resourceID, -r.resources[j].Amount);
			}
			return true;
		}
		return false;
	}

	public void Clear()
	{
		for (int i = 0; i < resources.Count; i++)
		{
			resources[i].Amount = 0;
		}
	}

	public static ResourceAmount Make(int resourceID, int count)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		resourceAmount.Set(resourceID, count);
		return resourceAmount;
	}

	public string ToString(string delimiter = " ")
	{
		string text = "";
		int num = 0;
		for (int i = 0; i < resources.Count; i++)
		{
			if (resources[i].Amount > 0)
			{
				text = text + ((num++ == 0) ? "" : delimiter) + $"<link={resources[i].resourceID}>" + ResourceIcon(resources[i].resourceID) + "</link> " + resources[i].Amount;
			}
		}
		return text.Trim();
	}

	public string NeedCost(ResourceAmount have, string delimiter = "  ")
	{
		string text = "";
		for (int i = 0; i < resources.Count; i++)
		{
			int amount = resources[i].Amount;
			if (amount > 0)
			{
				text = ((have.Get(resources[i].resourceID) < amount) ? (text + $"<link={resources[i].resourceID}>" + MakeRed(ResourceIcon(resources[i].resourceID) + "</link> " + amount + delimiter)) : (text + $"<link={resources[i].resourceID}>" + ResourceIcon(resources[i].resourceID) + "</link> " + amount + delimiter));
			}
		}
		return text.Trim();
	}

	public bool HasCost(ResourceAmount cost)
	{
		for (int i = 0; i < cost.resources.Count; i++)
		{
			Resource resource = cost.resources[i];
			if (resource.Amount > 0 && resource.Amount > Get(resource.resourceID))
			{
				return false;
			}
		}
		return true;
	}

	public static string MakeRed(string str)
	{
		return "<color=#FF7373FF>" + str + "</color>";
	}

	public static string ExtraCostHelper(int have, int need, string icon)
	{
		string text = "";
		if (need > 0)
		{
			text = ((have < need) ? (text + MakeRed(icon + " " + need)) : (text + icon + " " + need));
		}
		return text;
	}

	public static string ResourceIcon(int resourceID)
	{
		if (FreeResourceSystem.inst.resourceDefMap.TryGetValue(resourceID, out var value))
		{
			return value.iconName;
		}
		return "";
	}

	public static string ExplainAmounts(int resourceID, int have, int max)
	{
		have = Mathff.Min(have, max);
		string text = "";
		if (max > 0)
		{
			if (have > 0)
			{
				bool flag = (float)have / (float)max <= 0.2f;
				if (flag)
				{
					text += "<color=yellow>";
				}
				text = text + string.Format(ScriptLocalization.ResourceAmountStoredAndReady, ResourceIcon(resourceID), have, max) + Environment.NewLine;
				if (flag)
				{
					text += "</color>";
				}
			}
			else
			{
				text = text + "<color=yellow>" + string.Format(ScriptLocalization.ResourceAmountHasNo, ResourceIcon(resourceID)) + "</color>" + Environment.NewLine;
			}
		}
		return text;
	}

	public static string ExplainAmounts(ResourceAmount resourcesStored, ResourceAmount resourceStorageMax)
	{
		string text = "";
		for (int i = 0; i < resourceStorageMax.resources.Count; i++)
		{
			int have = resourcesStored.Get(resourceStorageMax.resources[i].resourceID);
			int amount = resourceStorageMax.resources[i].Amount;
			text += ExplainAmounts(resourceStorageMax.resources[i].resourceID, have, amount);
		}
		return text;
	}

	public bool IsNone()
	{
		int num = 0;
		for (int i = 0; i < resources.Count; i++)
		{
			num += resources[i].Amount;
		}
		return num == 0;
	}

	public bool Contains(int rID)
	{
		for (int i = 0; i < resources.Count; i++)
		{
			if (rID == resources[i].resourceID)
			{
				return true;
			}
		}
		return false;
	}

	public bool TryGetAmount(int rID, out int amount)
	{
		amount = 0;
		for (int i = 0; i < resources.Count; i++)
		{
			if (rID == resources[i].resourceID)
			{
				amount = resources[i].Amount;
				return true;
			}
		}
		return false;
	}

	internal void CopyFrom(ResourceAmount resourceAmount)
	{
		Clear();
		for (int i = 0; i < resourceAmount.resources.Count; i++)
		{
			Set(resourceAmount.resources[i].resourceID, resourceAmount.resources[i].Amount);
		}
	}
}
