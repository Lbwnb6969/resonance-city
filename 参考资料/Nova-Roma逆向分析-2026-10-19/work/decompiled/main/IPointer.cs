using UnityEngine;

public interface IPointer
{
	Ray GetRay();

	bool GetPrimaryDown();

	bool GetPrimaryDownThisFrame();

	bool GetPrimaryUp();

	bool GetSecondaryDown();

	bool GetSecondaryDownThisFrame();

	bool GetSecondaryUp();

	bool GetTertiaryDown();

	bool GetTertiaryUp();

	Vector3 GetScreenPos(Vector3 worldPos);
}
