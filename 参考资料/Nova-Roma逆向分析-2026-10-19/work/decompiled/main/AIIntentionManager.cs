using UnityEngine;

public class AIIntentionManager : MonoBehaviour
{
	public AIIntentionManager inst;

	public AIKingdom Kingdom;

	public GameObject intentionRoot;

	private void Awake()
	{
		inst = this;
	}

	public void Init(AIKingdom aiKingdom)
	{
		Kingdom = aiKingdom;
		intentionRoot = new GameObject("intention_root");
		intentionRoot.transform.SetParent(Kingdom.transform);
	}

	public T AddIntention<T>(string desc) where T : AIIntentionBase
	{
		GameObject gameObject = new GameObject(desc);
		gameObject.transform.SetParent(transform);
		T val = gameObject.AddComponent<T>();
		val.ManagerReference = this;
		val.Kingdom = Kingdom;
		val.Layout = Kingdom.Layout;
		val.LandmassOwner = Kingdom.LandmassOwner;
		val.LandMass = Kingdom.Layout.LandMass;
		val.transform.SetParent(intentionRoot.transform);
		return val;
	}

	public void Tick(float dt)
	{
		for (int i = 0; i < intentionRoot.transform.childCount; i++)
		{
			AIIntentionBase component = intentionRoot.transform.GetChild(i).GetComponent<AIIntentionBase>();
			if (component.Done)
			{
				Object.Destroy(intentionRoot.transform.GetChild(i).gameObject);
			}
			else
			{
				component.Tick(Time.deltaTime);
			}
		}
	}
}
