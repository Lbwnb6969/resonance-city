using UnityEngine;

public interface IMoveTarget
{
	Vector3 GetPredictedPosition(float time);

	Vector3 GetPos();

	int TeamID();

	bool IsStationary();
}
