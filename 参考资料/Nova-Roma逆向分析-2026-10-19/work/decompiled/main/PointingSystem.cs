using UnityEngine;

public class PointingSystem : MonoBehaviour
{
	public static PointingSystem inst;

	private static IPointer pointer;

	public static IPointer GetPointer()
	{
		return pointer;
	}

	private void Awake()
	{
		inst = this;
		ReplacePointer(new MousePointer());
	}

	public static void ReplacePointer(IPointer _pointer)
	{
		pointer = _pointer;
	}

	public static Ray GetRay()
	{
		return GetPointer().GetRay();
	}

	public static Vector3 GetScreenPos(Vector3 worldPos)
	{
		return GetPointer().GetScreenPos(worldPos);
	}

	public static Vector3 GetWorldPos(Vector3 screenPos)
	{
		Ray ray = GetRay();
		Plane plane = new Plane(Vector3.up, Vector3.zero);
		ray = Camera.main.ViewportPointToRay(screenPos);
		if (plane.Raycast(ray, out var enter))
		{
			return ray.GetPoint(enter);
		}
		return Vector3.zero;
	}

	public static RaycastHit GetClosestRayHit(RaycastHit[] scratchHitResults)
	{
		Ray ray = GetRay();
		float num = float.MaxValue;
		int num2 = Physics.RaycastNonAlloc(ray, scratchHitResults, 100f);
		int num3 = -1;
		for (int i = 0; i < num2; i++)
		{
			if (scratchHitResults[i].distance < num)
			{
				num = scratchHitResults[i].distance;
				num3 = i;
			}
		}
		if (num3 != -1)
		{
			return scratchHitResults[num3];
		}
		return default;
	}

	public static RaycastHit GetClosestRayHitWithRay(Ray myRay, RaycastHit[] scratchHitResults)
	{
		float num = float.MaxValue;
		int num2 = Physics.RaycastNonAlloc(myRay, scratchHitResults, 100f);
		int num3 = -1;
		for (int i = 0; i < num2; i++)
		{
			if (scratchHitResults[i].distance < num)
			{
				num = scratchHitResults[i].distance;
				num3 = i;
			}
		}
		if (num3 != -1)
		{
			return scratchHitResults[num3];
		}
		return default;
	}
}
