using UnityEngine;

public class AqueductTargetResolver
{
	private readonly RaycastHit[] raycastBuffer = new RaycastHit[100];

	public bool TryGetAqueductBuildingUnderCursor(Ray ray, out AqueductBuilding building, out RaycastHit hitInfo)
	{
		building = null;
		hitInfo = default;
		float num = float.MaxValue;
		if (Physics.Raycast(ray, out var hitInfo2, 1000f, LayerMask.GetMask("Terrain")))
		{
			num = hitInfo2.distance;
		}
		int num2 = Physics.RaycastNonAlloc(ray, raycastBuffer, 1000f);
		float num3 = float.MaxValue;
		for (int i = 0; i < num2; i++)
		{
			AqueductBuilding component = raycastBuffer[i].collider.GetComponent<AqueductBuilding>();
			if (component == null)
			{
				BuildingCollider component2 = raycastBuffer[i].collider.GetComponent<BuildingCollider>();
				if (component2 != null && component2.Building is MonoBehaviour monoBehaviour)
				{
					component = monoBehaviour.GetComponent<AqueductBuilding>();
				}
			}
			if (!(component == null))
			{
				float distance = raycastBuffer[i].distance;
				if (!(distance >= num - 0.01f) && distance < num3)
				{
					num3 = distance;
					building = component;
					hitInfo = raycastBuffer[i];
				}
			}
		}
		return building != null;
	}

	public bool TryGetAqueductLineUnderCursor(Ray ray, out AqueductLine line, out RaycastHit hitInfo)
	{
		line = null;
		hitInfo = default;
		float num = float.MaxValue;
		if (Physics.Raycast(ray, out var hitInfo2, 1000f, LayerMask.GetMask("Terrain")))
		{
			num = hitInfo2.distance;
		}
		int num2 = Physics.RaycastNonAlloc(ray, raycastBuffer, 1000f);
		float num3 = float.MaxValue;
		for (int i = 0; i < num2; i++)
		{
			BuildingCollider component = raycastBuffer[i].collider.GetComponent<BuildingCollider>();
			if (!(component == null) && component.Building is AqueductLine { fullyConstructed: not false } aqueductLine)
			{
				float distance = raycastBuffer[i].distance;
				if (!(distance >= num - 0.01f) && distance < num3)
				{
					num3 = distance;
					line = aqueductLine;
					hitInfo = raycastBuffer[i];
				}
			}
		}
		return line != null;
	}
}
