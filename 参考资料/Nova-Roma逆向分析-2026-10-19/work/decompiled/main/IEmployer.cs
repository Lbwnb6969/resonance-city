using UnityEngine;

public interface IEmployer
{
	Vector3 GetPosition();

	TransformData GetPositionForPerson(Villager p);

	bool IsOpen();

	void OnAssigned(Villager p);

	void OnUnAssigned(Villager p);

	void OnJobRemoved(Job j);

	string GetUsedSkill();

	int LandMass();

	int GetJobCategory();

	bool DuringWorkHours(float buffer = 0f);

	float GetStartHour();

	float GetEndHour();
}
