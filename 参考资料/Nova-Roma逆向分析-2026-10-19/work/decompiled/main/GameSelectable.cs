using System.Collections.Generic;
using UnityEngine;

public class GameSelectable : MonoBehaviour
{
	private static ArrayExt<GameSelectable> gameSelectables = new ArrayExt<GameSelectable>(100);

	private void OnEnable()
	{
		gameSelectables.Add(this);
	}

	private void OnDisable()
	{
		gameSelectables.RemoveSwap(this);
	}

	internal static void AddHighlights(int minx, int minz, int maxx, int maxz, ref List<ISelectable> highlightedObjs)
	{
		for (int i = 0; i < gameSelectables.Count; i++)
		{
			ISelectable component = gameSelectables.data[i].GetComponent<ISelectable>();
			if (component != null && component.ValidToSelect() && component.InsideSelectionBounds(minx, minz, maxx, maxz) && !highlightedObjs.Contains(component))
			{
				highlightedObjs.Add(component);
			}
		}
	}

	internal static ISelectable GetHighlight(out float minDist)
	{
		Vector3 vector = GameUI.inst.GridPointerIntersection();
		Ray ray = PointingSystem.GetRay();
		int num = (int)(vector.x - 3f);
		int num2 = (int)(vector.x + 3f);
		int num3 = (int)(vector.z - 3f);
		int num4 = (int)(vector.z + 3f);
		ISelectable result = null;
		minDist = float.MaxValue;
		for (int i = 0; i < gameSelectables.Count; i++)
		{
			ISelectable component = gameSelectables.data[i].GetComponent<ISelectable>();
			if (component == null || !component.ValidToSelect())
			{
				continue;
			}
			Vector3 pos = component.GetPos();
			if (pos.x >= (float)num && pos.x <= (float)num2 && pos.z >= (float)num3 && pos.z <= (float)num4)
			{
				float hitDist = 0f;
				if (component.IntersectsRay(ray, out hitDist) && hitDist < minDist)
				{
					minDist = hitDist;
					result = component;
				}
			}
		}
		return result;
	}
}
