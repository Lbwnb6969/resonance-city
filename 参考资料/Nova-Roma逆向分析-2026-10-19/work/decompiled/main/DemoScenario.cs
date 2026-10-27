using System;
using System.Collections.Generic;
using UnityEngine;

public class DemoScenario : MonoBehaviour
{
	private enum IntroSequence
	{
		Start,
		Running,
		Done
	}

	[Serializable]
	public class DemoScenarioSaveData : SaveClass<DemoScenario, DemoScenarioSaveData>
	{
		private float volcanoTimer;

		private SerializableVector3 volcanoPosition;

		private IntroSequence status;

		public override DemoScenarioSaveData Pack(DemoScenario obj)
		{
			status = obj.introStatus;
			volcanoTimer = obj.volcanoTimer.CurrTime;
			GameObject gameObject = GameObject.Find("VolcanoPosition");
			if ((bool)gameObject)
			{
				volcanoPosition = gameObject.transform.position;
			}
			return this;
		}

		public override DemoScenario Unpack(DemoScenario obj)
		{
			obj.introStatus = status;
			obj.volcanoTimer.CurrTime = volcanoTimer;
			obj.volcanoPosition = volcanoPosition;
			return obj;
		}
	}

	public static DemoScenario inst;

	public Vector3 volcanoPosition;

	private Timer volcanoTimer = new Timer(1f);

	private int volcanoID = -1;

	public List<string> terms;

	private IntroSequence introStatus;

	private void Awake()
	{
		inst = this;
	}

	public void Setup()
	{
		introStatus = IntroSequence.Start;
		volcanoTimer.Reset();
		Cinematics.inst.ShowBars(show: true);
		Cinematics.inst.OnLineStart += OnLineStart;
	}

	private void OnDestroy()
	{
		GodUI godUI = GodUI.inst;
		godUI.onConversationEnd = (GodUI.OnConversationEvent)Delegate.Remove(godUI.onConversationEnd, new GodUI.OnConversationEvent(OnGodConversationEnded));
		VolcanoManager volcanoManager = VolcanoManager.inst;
		volcanoManager.onVolcanoEnd = (VolcanoManager.OnVolcanoEvent)Delegate.Remove(volcanoManager.onVolcanoEnd, new VolcanoManager.OnVolcanoEvent(OnVolcanoEnd));
		Cinematics.inst.OnLineStart -= OnLineStart;
	}

	private void Update()
	{
		if (!GameState.inst.IsPlayMode() || !World.inst.isDemo)
		{
			return;
		}
		switch (introStatus)
		{
		case IntroSequence.Start:
			StartVolcano();
			TechnologyTree.inst.Reset();
			Player.inst.ResetProsperity();
			introStatus = IntroSequence.Running;
			break;
		case IntroSequence.Running:
		{
			float deltaTime = Time.deltaTime;
			if (volcanoTimer.Update(deltaTime))
			{
				volcanoTimer.Enabled = false;
				Cinematics.inst.SetTextList(terms);
			}
			if (!volcanoTimer.Enabled && Cinematics.inst.IsTextDone())
			{
				introStatus = IntroSequence.Done;
				Cinematics.inst.ShowBars(show: false);
				TimeManager.inst.SetPlay1(skipSfx: true);
				ArrayExt<Building> buildingList = Player.inst.GetBuildingList("romanoutpost".GetHashCode());
				if (buildingList.Count > 0)
				{
					Cam.inst.SetDesiredTrackingPos(buildingList.data[0].Center());
					Cam.inst.desiredDist = 15f;
				}
			}
			break;
		}
		}
	}

	private void OnLineStart(int lineIdx)
	{
		if (lineIdx == 1)
		{
			VolcanoManager.inst.TriggerEruption(volcanoID);
			Cam.inst.SetDesiredTrackingPos(volcanoPosition);
			TimeManager.inst.SetPlay3(skipSfx: true);
		}
	}

	public bool StartVolcano()
	{
		VolcanoManager.inst.MaxLavaProduction = 24f;
		VolcanoManager.inst.CoolingTime = 20f;
		bool result;
		(result, volcanoID) = VolcanoManager.inst.CreateVolcano(volcanoPosition);
		return result;
	}

	private void OnGodConversationEnded(string key)
	{
		if (key == "VulcanDemo1")
		{
			if (StartVolcano())
			{
				VolcanoManager volcanoManager = VolcanoManager.inst;
				volcanoManager.onVolcanoEnd = (VolcanoManager.OnVolcanoEvent)Delegate.Combine(volcanoManager.onVolcanoEnd, new VolcanoManager.OnVolcanoEvent(OnVolcanoEnd));
				Cam.inst.SetDesiredTrackingPos(volcanoPosition);
				GodUI godUI = GodUI.inst;
				godUI.onConversationEnd = (GodUI.OnConversationEvent)Delegate.Remove(godUI.onConversationEnd, new GodUI.OnConversationEvent(OnGodConversationEnded));
			}
			else
			{
				Debug.LogError($"Failed to place Volcano at {volcanoPosition}");
			}
		}
	}

	private void OnVolcanoEnd(int volcanoID)
	{
		if (this.volcanoID != -1)
		{
			_ = this.volcanoID;
		}
	}
}
