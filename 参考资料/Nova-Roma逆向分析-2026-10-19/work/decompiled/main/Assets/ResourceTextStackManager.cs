using UnityEngine;

namespace Assets;

public class ResourceTextStackManager : MonoBehaviour
{
	private ArrayExt<ResourceTextStack> activeRts = new ArrayExt<ResourceTextStack>(20);

	private ArrayExt<ResourceTextStack> inActiveRts = new ArrayExt<ResourceTextStack>(20);

	public static ResourceTextStackManager inst;

	private void Awake()
	{
		inst = this;
	}

	public void ShowResourceAmount(object owner, Vector3 start, int type, int amount, float holdDuration = -1f)
	{
		if (!FogOfWar.inst.IsVisible((int)start.x, (int)start.z))
		{
			return;
		}
		if (owner is MonoBehaviour)
		{
			Renderer componentInChildren = (owner as MonoBehaviour).GetComponentInChildren<Renderer>();
			if (componentInChildren != null)
			{
				if (!componentInChildren.isVisible)
				{
					return;
				}
			}
			else if (!Cam.inst.IsInFrustum(start))
			{
				return;
			}
		}
		else if (!Cam.inst.IsInFrustum(start))
		{
			return;
		}
		if (amount != 0)
		{
			GetStack().ShowResourceAmount(type, amount, start, holdDuration);
		}
	}

	public void ShowText(object owner, Vector3 start, string text, float holdDuration = -1f)
	{
		if (FogOfWar.inst.IsVisible((int)start.x, (int)start.z))
		{
			GetStack().ShowText(text, start, holdDuration);
		}
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		for (int i = 0; i < activeRts.Count; i++)
		{
			ResourceTextStack resourceTextStack = activeRts.data[i];
			resourceTextStack.Tick(unscaledDeltaTime);
			if (resourceTextStack.GetShowingTexts() == 0)
			{
				activeRts.RemoveSwap(resourceTextStack);
				inActiveRts.Add(resourceTextStack);
			}
		}
	}

	private ResourceTextStack GetStack()
	{
		if (inActiveRts.Count > 0)
		{
			ResourceTextStack resourceTextStack = inActiveRts.Last();
			inActiveRts.RemoveAt(inActiveRts.Count - 1);
			activeRts.Add(resourceTextStack);
			return resourceTextStack;
		}
		ResourceTextStack resourceTextStack2 = new ResourceTextStack();
		activeRts.Add(resourceTextStack2);
		return resourceTextStack2;
	}
}
