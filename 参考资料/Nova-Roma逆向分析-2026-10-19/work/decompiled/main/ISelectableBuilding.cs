using UnityEngine;

public interface ISelectableBuilding
{
	string CustomName { get; set; }

	string Description { get; }

	void SetOutlineImmediate(int i);

	int LandMass();

	int TeamID();

	bool CanDemolishBuilding();

	void DemolishBuilding();

	void PlaySelectSound();

	bool UnderConstruction();

	bool ConstructionPaused();

	void PauseConstruction();

	void UnpauseConstruction();

	void GetConstructionSummary(ref ConstructionForeman.ConstructionSummary summary);

	bool BuildFootprintClear();

	bool WorkersAssignedToClearFootprint();

	int GetBuildAllowedWorkers();

	Vector3 Center();

	int CategoryHash();

	int UniqueNameHash();

	bool IsOpen();
}
