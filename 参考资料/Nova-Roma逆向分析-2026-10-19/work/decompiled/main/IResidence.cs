using System.Collections.Generic;
using UnityEngine;

public interface IResidence
{
	Vector3 GetPosition();

	TransformData GetPositionForPerson(Villager p);

	bool Open();

	int GetAvailableResidentialSlots();

	int GetTotalResidentialSlots();

	void AddResident(Villager person);

	void RemoveResident(Villager person);

	int GetHappiness();

	float GetHealth();

	List<Villager> GetResidents();

	float GetEstimatedTaxYield();

	int LandMass();

	bool TryEatType(int type);
}
