using System;
using Assets;
using Assets.Code.Jobs;
using I2.Loc;
using UnityEngine;

public class Herbalist : MonoBehaviour, IOutputInfo
{
	private Building b;

	private WagePayer w;

	string IOutputInfo.GetError()
	{
		if (b.GetWorkerPercent() <= 0f)
		{
			return "ScriptLocalization.HerbalistNoStaff";
		}
		return null;
	}

	public string GetExplanation(OutputTileUI tileOutput)
	{
		string text = "ScriptLocalization.HerbalistReady" + Environment.NewLine;
		if (b.GetWorkerPercent() > 0f)
		{
			float num = (float)w.GetGoldWage(b.GetLandMassOwner()) * w.PaydaysPerYear();
			text += string.Format(ScriptLocalization.Wages, (int)num);
		}
		return text;
	}

	private void OnInit()
	{
		b = GetComponent<Building>();
		w = GetComponent<WagePayer>();
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(HealerJob)))
			{
				b.SetAndAddJob(i, new HealerJob(b));
			}
		}
	}
}
