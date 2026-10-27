using System;
using System.Collections.Generic;
using UnityEngine;

public class AIIntentionBase : MonoBehaviour
{
	public enum FailType
	{
		LayoutBlockOutOfSpace,
		NotEnoughResources,
		None
	}

	[NonSerialized]
	public AIIntentionManager ManagerReference;

	[NonSerialized]
	public AIKingdom Kingdom;

	[NonSerialized]
	public AILayout Layout;

	[NonSerialized]
	public LandmassOwner LandmassOwner;

	[NonSerialized]
	public int LandMass = -1;

	public bool done;

	[NonSerialized]
	public FailType failType = FailType.None;

	protected List<AIIntentionBase> subIntentions = new List<AIIntentionBase>();

	private List<AIIntentionBase> deferredDestroy = new List<AIIntentionBase>();

	protected int priority;

	public bool Done
	{
		get
		{
			return done;
		}
		set
		{
			done = value;
			if (done)
			{
				DestroyChildren();
			}
		}
	}

	public T AddSubIntention<T>(string desc) where T : AIIntentionBase
	{
		GameObject gameObject = new GameObject(desc);
		gameObject.transform.SetParent(transform);
		T val = gameObject.AddComponent<T>();
		val.ManagerReference = ManagerReference;
		val.Kingdom = Kingdom;
		val.Layout = Layout;
		val.LandmassOwner = Kingdom.LandmassOwner;
		val.LandMass = Layout.LandMass;
		val.transform.SetParent(transform);
		subIntentions.Add(val);
		return val;
	}

	private void DestroyChildren()
	{
		for (int i = 0; i < subIntentions.Count; i++)
		{
			UnityEngine.Object.Destroy(subIntentions[i].gameObject);
		}
		subIntentions.Clear();
	}

	protected void DestroyIntention(AIIntentionBase intention)
	{
		if (!deferredDestroy.Contains(intention))
		{
			deferredDestroy.Add(intention);
		}
	}

	public virtual void Tick(float dt)
	{
		int siblingIndex = transform.GetSiblingIndex();
		if (siblingIndex > 0)
		{
			Transform child = transform.parent.GetChild(siblingIndex - 1);
			if (priority > child.GetComponent<AIIntentionBase>().priority)
			{
				transform.SetSiblingIndex(child.GetSiblingIndex());
			}
		}
		if (siblingIndex < transform.parent.childCount - 1)
		{
			Transform child2 = transform.parent.GetChild(siblingIndex + 1);
			if (priority < child2.GetComponent<AIIntentionBase>().priority)
			{
				transform.SetSiblingIndex(child2.GetSiblingIndex());
			}
		}
		for (int i = 0; i < deferredDestroy.Count; i++)
		{
			subIntentions.Remove(deferredDestroy[i]);
			UnityEngine.Object.Destroy(deferredDestroy[i].gameObject);
		}
		deferredDestroy.Clear();
		for (int j = 0; j < subIntentions.Count; j++)
		{
			if (!subIntentions[j].Done)
			{
				subIntentions[j].Tick(dt);
			}
		}
	}

	public bool KillAndNullIntention<T>(ref T intention) where T : AIIntentionBase
	{
		if (intention != null)
		{
			DestroyIntention(intention);
			intention = null;
			return true;
		}
		return false;
	}

	public bool KillAndNullFinishedIntention<T>(ref T intention) where T : AIIntentionBase
	{
		if (intention != null && intention.Done)
		{
			DestroyIntention(intention);
			intention = null;
			return true;
		}
		return false;
	}

	public void KillFinishedIntentions()
	{
		for (int i = 0; i < subIntentions.Count; i++)
		{
			if (subIntentions[i].done)
			{
				DestroyIntention(subIntentions[i]);
			}
		}
	}

	public bool IsBeingBuilt(int hash)
	{
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, hash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (!buildingListForLandMass.data[i].IsBuilt())
			{
				return true;
			}
		}
		return false;
	}
}
