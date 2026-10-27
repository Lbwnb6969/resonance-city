using System;
using System.Collections.Generic;
using UnityEngine;

public class SiegeCatapultSystem : MonoBehaviour
{
	[Serializable]
	public class SiegeCatapultSystemSaveData : SaveClass<SiegeCatapultSystem, SiegeCatapultSystemSaveData>
	{
		[Serializable]
		private struct SiegeCatapultSaveData
		{
			public int teamId;

			public Guid guid;

			public float life;

			public SerializableVector3 pos;

			public SerializableQuaternion rot;

			public string generalName;
		}

		private List<SiegeCatapultSaveData> catapultSaveData = new List<SiegeCatapultSaveData>();

		public override SiegeCatapultSystemSaveData Pack(SiegeCatapultSystem obj)
		{
			catapultSaveData.Clear();
			for (int i = 0; i < siegeCatapults.Count; i++)
			{
				SiegeCatapult siegeCatapult = siegeCatapults.data[i];
				SiegeCatapultSaveData item = new SiegeCatapultSaveData
				{
					teamId = siegeCatapult.TeamID(),
					guid = siegeCatapult.GetGuid(),
					life = siegeCatapult.life,
					pos = siegeCatapult.transform.position,
					rot = siegeCatapult.transform.rotation,
					generalName = siegeCatapult.generalName
				};
				catapultSaveData.Add(item);
			}
			return this;
		}

		public override SiegeCatapultSystem Unpack(SiegeCatapultSystem obj)
		{
			for (int i = 0; i < catapultSaveData.Count; i++)
			{
				SiegeCatapultSaveData siegeCatapultSaveData = catapultSaveData[i];
				GameObject gameObject = UnityEngine.Object.Instantiate(inst.siegeCatapultPrefab);
				SiegeCatapult component = gameObject.GetComponent<SiegeCatapult>();
				component.Init(siegeCatapultSaveData.teamId);
				component.guid = siegeCatapultSaveData.guid;
				component.life = siegeCatapultSaveData.life;
				component.generalName = siegeCatapultSaveData.generalName;
				gameObject.transform.position = siegeCatapultSaveData.pos;
				gameObject.transform.rotation = siegeCatapultSaveData.rot;
			}
			return obj;
		}
	}

	public static SiegeCatapultSystem inst;

	public GameObject siegeCatapultPrefab;

	public static ArrayExt<SiegeCatapult> siegeCatapults = new ArrayExt<SiegeCatapult>(32);

	private void Awake()
	{
		inst = this;
	}

	public void AddInView(Plane[] planes, int teamID, ref ArrayExt<IUnitControllable> objs)
	{
		for (int i = 0; i < siegeCatapults.Count; i++)
		{
			if (UnitControlSystem.inst.IsUnitControllableByTeam(siegeCatapults.data[i], teamID) && GeometryUtility.TestPlanesAABB(planes, siegeCatapults.data[i].GetComponentInChildren<Renderer>().bounds))
			{
				objs.Add(siegeCatapults.data[i]);
			}
		}
	}

	public void AddHighlights(int minx, int minz, int maxx, int maxz, ref List<ISelectable> highlightedObjs)
	{
		int i = 0;
		for (int count = siegeCatapults.Count; i < count; i++)
		{
			SiegeCatapult siegeCatapult = siegeCatapults.data[i];
			if (siegeCatapult.ValidToSelect() && siegeCatapult.InsideSelectionBounds(minx, minz, maxx, maxz) && !highlightedObjs.Contains(siegeCatapult))
			{
				highlightedObjs.Add(siegeCatapult);
			}
		}
	}
}
