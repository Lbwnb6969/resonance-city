using System;
using UnityEngine;

public class EatMeal : MonoBehaviour
{
	public enum EatType
	{
		None,
		Half,
		Full
	}

	[Serializable]
	public class EatItem
	{
		internal Mesh notEatenMesh;

		public GameObject food;

		public GameObject halfEaten;

		public GameObject fullEaten;

		public float time;

		internal bool done;

		public void SwitchTo(EatType t)
		{
			switch (t)
			{
			case EatType.None:
				food.SetActive(value: true);
				food.GetComponent<MeshFilter>().mesh = notEatenMesh;
				break;
			case EatType.Half:
				food.SetActive(value: true);
				if (halfEaten != null)
				{
					food.GetComponent<MeshFilter>().mesh = halfEaten.GetComponent<MeshFilter>().sharedMesh;
				}
				break;
			default:
				if (fullEaten != null)
				{
					food.SetActive(value: true);
					food.GetComponent<MeshFilter>().mesh = fullEaten.GetComponent<MeshFilter>().sharedMesh;
				}
				else
				{
					food.SetActive(value: false);
				}
				break;
			}
		}
	}

	private EatType eatType = EatType.Full;

	private bool init = true;

	private bool doEat;

	public EatItem[] eatItems;

	private float time;

	public void Eat(EatType t)
	{
		if (init)
		{
			for (int i = 0; i < eatItems.Length; i++)
			{
				eatItems[i].notEatenMesh = eatItems[i].food.GetComponent<MeshFilter>().mesh;
			}
			init = false;
		}
		for (int j = 0; j < eatItems.Length; j++)
		{
			eatItems[j].done = false;
			eatItems[j].SwitchTo(EatType.None);
		}
		time = 0f;
		eatType = t;
		doEat = true;
	}

	public bool IsDone()
	{
		return time > eatItems[eatItems.Length - 1].time + 1.5f;
	}

	private void Update()
	{
		if (!doEat)
		{
			return;
		}
		time += Time.unscaledDeltaTime;
		for (int i = 0; i < eatItems.Length; i++)
		{
			if (eatItems[i].done || !(eatItems[i].time <= time))
			{
				continue;
			}
			eatItems[i].done = true;
			if (eatType == EatType.Full)
			{
				if (SRand.Range(0, 100) < 80)
				{
					eatItems[i].SwitchTo(EatType.Full);
				}
				else
				{
					eatItems[i].SwitchTo(EatType.Half);
				}
			}
			else if (eatType == EatType.Half)
			{
				if (SRand.Range(0, 100) < 50)
				{
					eatItems[i].SwitchTo(EatType.Full);
				}
				else
				{
					eatItems[i].SwitchTo(EatType.Half);
				}
			}
			else if (SRand.Range(0, 100) < 30)
			{
				eatItems[i].SwitchTo(EatType.Half);
			}
		}
	}
}
