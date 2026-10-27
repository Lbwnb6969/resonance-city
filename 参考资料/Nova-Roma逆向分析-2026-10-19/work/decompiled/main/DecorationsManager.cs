using System.Collections.Generic;
using UnityEngine;

public class DecorationsManager
{
	public static DecorationsManager inst;

	public Object[] assets;

	public DecorationsManager()
	{
		inst = this;
	}

	public Object GetAsset(string name)
	{
		for (int i = 0; i < assets.Length; i++)
		{
			if (assets[i].name == name)
			{
				return assets[i];
			}
		}
		return null;
	}

	public List<T> GetAssetsByComponent<T>()
	{
		List<T> list = new List<T>();
		for (int i = 0; i < assets.Length; i++)
		{
			GameObject gameObject = assets[i] as GameObject;
			if (!(gameObject == null))
			{
				T component = gameObject.GetComponent<T>();
				if (component != null)
				{
					list.Add(component);
				}
			}
		}
		return list;
	}
}
