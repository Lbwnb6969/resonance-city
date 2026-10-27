using UnityEngine;

public class BuildingCollider : MonoBehaviour
{
	[HideInInspector]
	public Collider Collider;

	public ISelectableBuilding Building;

	public Building BuildingAsBuilding;

	private void Awake()
	{
		Collider = GetComponent<Collider>();
	}

	private void Start()
	{
		Transform parent = transform;
		while (parent != null)
		{
			ISelectableBuilding selectableBuilding = parent.gameObject.GetInterface<ISelectableBuilding>();
			if (selectableBuilding != null)
			{
				Building = selectableBuilding;
				if (selectableBuilding is Building buildingAsBuilding)
				{
					BuildingAsBuilding = buildingAsBuilding;
				}
				else
				{
					BuildingAsBuilding = null;
				}
				break;
			}
			parent = parent.parent;
		}
	}

	public void EnableColliders(bool enable)
	{
		if (Collider != null)
		{
			Collider.enabled = enable;
		}
	}
}
