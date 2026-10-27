using Sirenix.OdinInspector;
using UnityEngine;

public class MountainPlacerTerrainModifier : MonoBehaviour
{
	public int Type;

	public const int DefaultType = 0;

	public const int PersistantType = 1;

	public const int AdditiveType = 2;

	public static ValueDropdownList<int> TypeDropdownOptions = new ValueDropdownList<int>
	{
		{ "Default", 0 },
		{ "Persistant", 1 },
		{ "Additive", 2 }
	};
}
