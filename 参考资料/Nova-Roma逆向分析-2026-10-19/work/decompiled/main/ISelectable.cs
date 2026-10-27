using UnityEngine;

public interface ISelectable
{
	Vector3 GetPos();

	bool ExclusiveSelect();

	bool ValidToSelect();

	void SetHighlightImmediate(int colorIdx);

	void OnSelected();

	bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz);

	bool IntersectsRay(Ray ray, out float hitDist);

	int TeamID();
}
