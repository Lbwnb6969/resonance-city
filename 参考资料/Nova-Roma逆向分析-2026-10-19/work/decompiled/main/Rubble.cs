using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using UnityEngine;

public class Rubble : MonoBehaviour, IWorkerUIDisplay
{
	[Serializable]
	public class RubbleSaveData : SaveClass<Rubble, RubbleSaveData>
	{
		[Serializable]
		public class BuildingState
		{
			public string uniqueName;

			public SerializableQuaternion rotation;

			public SerializableVector3 globalPosition;

			public SerializableVector3 localPosition;
		}

		public List<SerializableVector3> buildingCells;

		[OptionalField(VersionAdded = 2)]
		public bool canRebuild;

		[OptionalField(VersionAdded = 3)]
		public BuildingState[] stateData;

		public SerializableVector3 globalPos;

		public SerializableVector3 localPos;

		public SerializableQuaternion rotation;

		public string uniqueName;

		public override RubbleSaveData Pack(Rubble obj)
		{
			return this;
		}

		public override Rubble Unpack(Rubble obj)
		{
			return obj;
		}
	}

	private Building b;

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	public void OnBuildingPlacement(bool undo)
	{
		b.GetCell();
		int num = SRand.Range(0, 100);
		if (num >= 70 && num < 100)
		{
			transform.GetChild(0).GetChild(0).transform.localScale = new Vector3(1.65f, 2.2f, 1.65f);
		}
		else if (num >= 30 && num < 70)
		{
			transform.GetChild(0).GetChild(0).transform.localScale = new Vector3(1.2f, 1.5f, 1.2f);
		}
		else
		{
			transform.GetChild(0).GetChild(0).transform.localScale = new Vector3(0.9f, 0.9f, 0.9f);
		}
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
