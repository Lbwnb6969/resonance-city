using System;
using Assets;
using Assets.Code.Jobs;
using UnityEngine;

public class DeadVillager : InstanceSystem.Owner
{
	[Serializable]
	public class DeadVillagerSaveData : SaveClass<DeadVillager, DeadVillagerSaveData>
	{
		public SerializableVector3 Pos;

		public SerializableQuaternion Rot;

		public string name;

		public float timeAlive;

		public Timer plagueTimer;

		public bool hasNotified;

		public bool useLady;

		public bool fromDeadBodyPlague;

		public override DeadVillagerSaveData Pack(DeadVillager obj)
		{
			Pos = obj.Pos;
			Rot = obj.Rot;
			name = obj.name;
			timeAlive = obj.timeAlive;
			plagueTimer = obj.timeToExplode;
			hasNotified = obj.hasNotified;
			useLady = obj.useLadyMesh;
			fromDeadBodyPlague = obj.fromDeadBodyPlague;
			return this;
		}

		public override DeadVillager Unpack(DeadVillager obj)
		{
			obj.Init(Pos, Rot, useLady);
			obj.name = name;
			obj.timeAlive = timeAlive;
			obj.timeToExplode = plagueTimer;
			obj.hasNotified = hasNotified;
			obj.fromDeadBodyPlague = fromDeadBodyPlague;
			obj.Drop();
			return obj;
		}
	}

	public bool useLadyMesh;

	public Vector3 Pos;

	public Quaternion Rot;

	public bool visible;

	public string name;

	public float timeAlive;

	public bool fromDeadBodyPlague;

	private Timer timeToExplode = new Timer(100f);

	public bool hasNotified;

	private float happyTime = 3f;

	private bool wasHeld;

	private ThoughtBubbleSystem.ThoughtBubble warningBubble;

	public int landmass;

	public GraveWorkerJob graveKeeper;

	public bool isHeld;

	private bool firstUpdate;

	public void Init(Vector3 _pos, Quaternion _rot, bool _useLadyMesh)
	{
		useLadyMesh = _useLadyMesh;
		Pos = _pos;
		TerrainGen.inst.GetGroundHeight(ref Pos);
		Pos.y -= 0.05f;
		Rot = _rot;
		DeadVillagerSystem.inst.Add(this, Pos, Rot, Vector3.one);
		Matrix4x4[][] data = DeadVillagerSystem.inst.deadVillagers.silos.data;
		if (_useLadyMesh)
		{
			data = DeadVillagerSystem.inst.deadLadyVillagers.silos.data;
		}
		Mathff.SetTRS(ref data[s][idx], Pos, Rot, Vector3.one);
		landmass = World.inst.GetCellDataClamped(_pos).landMassIdx;
		if (landmass == -1)
		{
			Debug.LogError("LANDMASS ERROR!");
		}
		warningBubble = ThoughtBubbleSystem.inst.AddThoughtBubble(Pos);
		warningBubble.scaleMod = 0.8f;
		warningBubble.visible = false;
		warningBubble.thought = ThoughtBubbleSystem.Thought.DeadBody;
		timeAlive = 0f;
		hasNotified = false;
		timeToExplode.Reset();
		happyTime = 3f;
		wasHeld = false;
	}

	public DeadVillager(Vector3 _pos, Quaternion _rot, bool _useLadyMesh)
	{
		Init(_pos, _rot, _useLadyMesh);
	}

	public DeadVillager()
	{
	}

	public void Shutdown()
	{
		if (graveKeeper != null)
		{
			graveKeeper.assignedBody = null;
		}
		graveKeeper = null;
		if (warningBubble != null)
		{
			ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref warningBubble);
		}
		DeadVillagerSystem.inst.Remove(this);
	}

	public void Tick(float dt)
	{
		if (graveKeeper == null)
		{
			GraveWorkerJob.AssignGraveWorker(this);
		}
		else if (isHeld)
		{
			Pos = graveKeeper.Employee.GetPosWithOffset();
			Rot = graveKeeper.Employee.Rot;
			Matrix4x4[][] data = DeadVillagerSystem.inst.deadVillagers.silos.data;
			if (useLadyMesh)
			{
				data = DeadVillagerSystem.inst.deadLadyVillagers.silos.data;
			}
			Mathff.SetTRS(ref data[s][idx], Pos, Rot, Vector3.one);
		}
		warningBubble.pos = Pos;
		if (FogOfWar.inst.dirty || firstUpdate)
		{
			Vector3 pos = Pos;
			int x = (int)pos.x;
			int z = (int)pos.z;
			bool flag = FogOfWar.inst.IsVisible(x, z);
			if (flag != visible)
			{
				visible = flag;
			}
		}
		firstUpdate = false;
		if (isHeld && !wasHeld)
		{
			happyTime = 3f;
		}
		wasHeld = isHeld;
		if (!isHeld)
		{
			if (hasNotified)
			{
				warningBubble.thought = ThoughtBubbleSystem.Thought.DeadBodyWarning;
				warningBubble.visible = visible;
			}
			else if (timeToExplode.CurrTime > timeToExplode.Duration * 0.33f)
			{
				warningBubble.thought = ThoughtBubbleSystem.Thought.DeadBody;
				warningBubble.visible = visible;
			}
			else
			{
				warningBubble.visible = false;
			}
			if (timeToExplode.Update(Time.deltaTime))
			{
				if (hasNotified)
				{
					Player.inst.ReportOldPlagueVillager(this);
					Shutdown();
				}
				else
				{
					hasNotified = true;
				}
			}
		}
		else
		{
			happyTime -= Time.deltaTime;
			if (happyTime > 0f)
			{
				warningBubble.visible = visible;
				warningBubble.thought = ThoughtBubbleSystem.Thought.DeadBodySafe;
			}
			else
			{
				warningBubble.visible = false;
			}
		}
	}

	public float GetDangerFactor()
	{
		float num = timeToExplode.CurrTime / timeToExplode.Duration * 0.5f;
		if (hasNotified)
		{
			num += 0.5f;
		}
		return num;
	}

	public void CopyDataFromPerson(Villager villager)
	{
		name = villager.name;
		timeAlive = villager.timeAlive;
		fromDeadBodyPlague = villager.sick && villager.sickFromDeadBody;
		timeToExplode = new Timer(160f);
		hasNotified = false;
	}

	public void CopyDataFromUnit()
	{
		name = PersonProfile.GetRandomProfile().Name;
		float num = SeasonManager.inst.TimeInYear();
		timeAlive = num * (float)SRand.Range(18, 60);
		timeToExplode = new Timer(200f);
		hasNotified = false;
	}

	internal void Drop()
	{
		isHeld = false;
		graveKeeper = null;
		TerrainGen.inst.GetGroundHeight(ref Pos);
		Pos.y -= 0.05f;
	}
}
