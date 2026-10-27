using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CommuteUI : MonoBehaviour, IWorkerUIElement
{
	public static CommuteUI inst;

	public Slider commuteSlider;

	public GameObject noWorkers;

	public GameObject noStaffDisable;

	private List<SeasonDefinition> seasons;

	private List<GamePath> deferredPath = new List<GamePath>();

	private float commuteFactor = 0.5f;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		seasons = SeasonManager.inst.currentPlanner();
	}

	public float GetCommuteFactor(Building b)
	{
		return commuteFactor;
	}

	private void Update()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (!(buildingSelected != null))
		{
			return;
		}
		int num = 0;
		float num2 = 0f;
		for (int i = 0; i < buildingSelected.jobs.Count; i++)
		{
			if (deferredPath[i].status == GamePath.Status.Uninitialized)
			{
				TryInitPathRequest(i, buildingSelected);
			}
			if (deferredPath[i].status != GamePath.Status.Complete || deferredPath[i].result.Count <= 0)
			{
				continue;
			}
			ArrayExt<Vector3> result = deferredPath[i].result;
			Vector3 vector = deferredPath[i].result.data[0];
			int num3 = 0;
			float num4 = 0.033f;
			float num5 = 0f;
			while (num3 < result.Count)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(vector);
				float num6 = 1f * cellDataClamped.speedModifier * num4;
				while (num6 > 0f && num3 < result.Count)
				{
					if (Mathff.MoveTowards(vector, result.data[num3], num6, out var actualAmt, out var newPos))
					{
						num3++;
					}
					vector = newPos;
					num6 -= actualAmt;
				}
				num5 += num4;
			}
			for (int j = 0; j < seasons.Count; j++)
			{
				float num7 = seasons[j].duration / (float)seasons[j].nights;
				float num8 = num5 / num7 * 24f / (buildingSelected.workEndHour - buildingSelected.workStartHour);
				num2 += num8;
				num++;
			}
		}
		if (num > 0)
		{
			commuteFactor = Mathff.Clamp01(1f - num2 / (float)num);
		}
		else
		{
			commuteFactor = 0.5f;
		}
		Util.SetActive(noWorkers, buildingSelected.WorkersAllocated <= 0 || commuteFactor == -1f);
		Util.SetActive(noStaffDisable, buildingSelected.WorkersAllocated <= 0);
		Util.SetActive(commuteSlider.gameObject, commuteFactor != -1f);
		if (commuteFactor >= 0f)
		{
			commuteSlider.value = commuteFactor;
		}
	}

	private void TryInitPathRequest(int i, Building b)
	{
		if (b.jobs[i].Employee != null && b.jobs[i].Employee.Residence != null)
		{
			deferredPath[i].start = b.jobs[i].Employee.Residence.GetPosition();
			deferredPath[i].end = b.jobs[i].Employee.job.employer.GetPositionForPerson(b.jobs[i].Employee).position;
			deferredPath[i].pathType = GamePath.PathType.VillagerPath;
			World.inst.threadedPather.RequestPath(deferredPath[i]);
		}
	}

	void IWorkerUIElement.TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && ((bool)buildingSelected.GetComponent<YieldProducer>() || (bool)buildingSelected.GetComponent<FishingHut>() || (bool)buildingSelected.GetComponent<Forester>() || (bool)buildingSelected.GetComponent<Mason>()))
		{
			gameObject.SetActive(value: true);
			for (int i = 0; i < buildingSelected.jobs.Count; i++)
			{
				if (deferredPath.Count <= i)
				{
					deferredPath.Add(new GamePath());
				}
				deferredPath[i].Reset();
				TryInitPathRequest(i, buildingSelected);
			}
		}
		else
		{
			gameObject.SetActive(value: false);
		}
	}

	void IWorkerUIElement.UpdateForNewSelection()
	{
	}
}
