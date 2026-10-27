using System.Collections.Generic;
using FMODUnity;
using I2.Loc;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ArenaFightManager : MonoBehaviour
{
	internal enum FightPhase
	{
		None,
		Combat,
		Death,
		WaitingForThumbs,
		Done
	}

	public class FightResult
	{
		public Gladiator gladiator;

		public BeastTemplate beast;

		public int fatigueGain;

		public int fameGain;

		public string mercyBiasText;
	}

	public Transform arenaCenter;

	public float arenaRadius = 1f;

	public Transform spawnPointLeft;

	public Transform spawnPointRight;

	[SerializeField]
	private GameObject gladiatorPrefab;

	[SerializeField]
	private GameObject beastPrefab;

	[SerializeField]
	private float postDeathDelay = 1.2f;

	internal FightPhase phase;

	internal List<ArenaFighter> team1 = new List<ArenaFighter>();

	internal List<ArenaFighter> team2 = new List<ArenaFighter>();

	private int currentBeastTargetIndex;

	private float deathDelayTimer;

	public float defenseFadeStart = 5f;

	public float defenseFadeEnd = 15f;

	private float fightTime;

	private List<ArenaFighter> fighters = new List<ArenaFighter>();

	public float dampForce = 10f;

	private float antiPenetrationForce = 20f;

	public float wallForce = 40f;

	public float stunImpactSpeed = 3f;

	public float deathFallMargin = 0.35f;

	private const float maxPhysicsDt = 1f / 30f;

	internal List<FightResult> fightResults = new List<FightResult>();

	private bool team1loser;

	[Header("Debris")]
	[Tooltip("Gravity for dropped gear, scaled down to the miniature world (real gravity reads as far too fast)")]
	public float debrisGravity = 3f;

	public float debrisLaunchSpeed = 0.8f;

	public float debrisUpSpeed = 1.2f;

	public float debrisSpin = 12f;

	private Scene debrisScene;

	private PhysicsScene debrisPhysics;

	private readonly List<Rigidbody> debris = new List<Rigidbody>();

	internal float DefenseChance => 1f - Mathf.InverseLerp(defenseFadeStart, defenseFadeEnd, fightTime);

	public Vector3 GetAveragePos()
	{
		Vector3 zero = Vector3.zero;
		for (int i = 0; i < team1.Count; i++)
		{
			zero += team1[i].Position;
		}
		for (int j = 0; j < team2.Count; j++)
		{
			zero += team2[j].Position;
		}
		if (team1.Count + team2.Count > 0)
		{
			return zero / (team1.Count + team2.Count);
		}
		return arenaCenter.position;
	}

	public void StartFight(ColosseumRound round)
	{
		CleanupFighters();
		Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(round.combatant1Id);
		Gladiator gladiator2 = null;
		if (round.opponentType == OpponentType.School && round.opponentId >= 0)
		{
			gladiator2 = GladiatorSystem.inst?.GetGladiator(round.opponentId);
		}
		Vector3 position = spawnPointLeft.position;
		SpawnGladiator(team1, position, gladiator, 0, round.combatant1role);
		Vector3 position2 = spawnPointRight.position;
		if (round.opponentType == OpponentType.Beast)
		{
			int num = Mathf.Max(1, round.beastCount);
			for (int i = 0; i < num; i++)
			{
				Vector3 vector = new Vector3(Random.Range(-0.3f, 0.3f), 0f, Random.Range(-0.3f, 0.3f));
				string localizedName = GladiatorSystem.inst.GetBeastDefByName(round.beastType).GetLocalizedName();
				SpawnBeast(team2, position2 + vector, localizedName, round.beastType, 1);
			}
		}
		else
		{
			SpawnGladiator(team2, position2, gladiator2, 1, round.opponentrole);
		}
		currentBeastTargetIndex = 0;
		fightTime = 0f;
		for (int j = 0; j < team1.Count; j++)
		{
			fighters.Add(team1[j]);
		}
		for (int k = 0; k < team2.Count; k++)
		{
			fighters.Add(team2[k]);
		}
		phase = FightPhase.Combat;
	}

	public void TickFight(float dt)
	{
		switch (phase)
		{
		case FightPhase.Combat:
			TickCombat(dt);
			break;
		case FightPhase.Death:
			StepPhysics(dt);
			TickDeath(dt);
			break;
		case FightPhase.WaitingForThumbs:
			StepPhysics(dt);
			break;
		case FightPhase.Done:
			CleanupArena();
			break;
		}
	}

	public void SkipFight()
	{
		CleanupArena();
	}

	private void StepPhysics(float dt)
	{
		dt = Mathf.Min(dt, 1f / 30f);
		Vector3 position = arenaCenter.position;
		bool flag = phase == FightPhase.Combat;
		for (int i = 0; i < fighters.Count; i++)
		{
			for (int j = 0; j < fighters.Count; j++)
			{
				if (i != j)
				{
					ArenaFighter arenaFighter = fighters[i];
					ArenaFighter arenaFighter2 = fighters[j];
					float num = arenaFighter.Position.x - arenaFighter2.Position.x;
					float num2 = arenaFighter.Position.z - arenaFighter2.Position.z;
					float num3 = num * num + num2 * num2;
					float num4 = arenaFighter.Radius + arenaFighter2.Radius;
					if (num3 < num4 * num4)
					{
						Vector3 vector = new Vector3(num, 0f, num2);
						Vector3 normalized = vector.normalized;
						float num5 = num4 - vector.magnitude;
						float num6 = 0.5f;
						float num7 = 0.5f;
						fighters[i].Acceleration += normalized * num5 * num6 * antiPenetrationForce;
						fighters[j].Acceleration += -normalized * num5 * num7 * antiPenetrationForce;
					}
				}
			}
			float num8 = fighters[i].Position.x - position.x;
			float num9 = fighters[i].Position.z - position.z;
			float num10 = Mathf.Sqrt(num8 * num8 + num9 * num9);
			bool flag2 = fighters[i].CurrentHp <= 0f;
			float num11 = arenaRadius - (flag2 ? Mathf.Max(fighters[i].Radius, deathFallMargin) : fighters[i].Radius);
			if (num10 > num11 && num10 > 0.0001f)
			{
				Vector3 vector2 = new Vector3(num8 / num10, 0f, num9 / num10);
				fighters[i].Acceleration += -vector2 * (num10 - num11) * wallForce;
				if (flag && !flag2 && Vector3.Dot(fighters[i].Velocity, vector2) > stunImpactSpeed)
				{
					fighters[i].PlayStun();
				}
			}
		}
		DebugEx.DrawSphere(position, arenaRadius, Color.red);
		for (int k = 0; k < fighters.Count; k++)
		{
			DebugEx.DrawSphere(fighters[k].Position, fighters[k].Radius, Color.red);
			fighters[k].Velocity += fighters[k].Acceleration.xz() * dt;
			fighters[k].Acceleration = Vector3.zero;
			fighters[k].Velocity += -fighters[k].Velocity.xz() * dt * dampForce;
			Vector3 vector3 = fighters[k].Position + fighters[k].Velocity.xz() * dt;
			Vector3 vector4 = (vector3 - position).xz();
			if (vector4.sqrMagnitude > arenaRadius * arenaRadius)
			{
				vector4 = vector4.normalized * arenaRadius;
				vector3.x = position.x + vector4.x;
				vector3.z = position.z + vector4.z;
			}
			fighters[k].Position = vector3;
		}
	}

	private void TickCombat(float dt)
	{
		fightTime += dt;
		StepPhysics(dt);
		if (Input.GetKeyDown(KeyCode.Z))
		{
			fighters[0].PlayAttack();
		}
		List<ArenaFighter> list = null;
		bool flag = true;
		foreach (ArenaFighter item in team1)
		{
			if (item.CurrentHp > 0f)
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			list = team1;
		}
		if (list == null)
		{
			flag = true;
			foreach (ArenaFighter item2 in team2)
			{
				if (item2.CurrentHp > 0f)
				{
					flag = false;
					break;
				}
			}
			if (flag)
			{
				list = team2;
			}
		}
		if (list != null)
		{
			EndFight(list);
		}
	}

	private void EndFight(List<ArenaFighter> loserTeam)
	{
		team1loser = loserTeam == team1;
		List<ArenaFighter> list = (team1loser ? team2 : team1);
		RuntimeManager.PlayOneShot((list[0].beast != null) ? "event:/SFX ASITP/Ambiences/ambScatter_crowdReact_shock" : "event:/SFX ASITP/Ambiences/ambScatter_crowdReact_cheer", arenaCenter.position);
		foreach (ArenaFighter item in loserTeam)
		{
			item.PlayDeath();
		}
		phase = FightPhase.Death;
		foreach (ArenaFighter item2 in list)
		{
			item2.PlayWaiting();
		}
		deathDelayTimer = 0f;
		fightResults.Clear();
		for (int i = 0; i < fighters.Count; i++)
		{
			FightResult fightResult = new FightResult();
			fightResult.gladiator = fighters[i].gladiator;
			fightResult.beast = fighters[i].beast;
			if (fighters[i].CurrentHp / fighters[i].MaxHp < 0.25f)
			{
				fightResult.fatigueGain = 2;
				fightResult.mercyBiasText = LocalizationManager.GetTranslation("colosseum_reason_exhausted") + "\n";
			}
			else
			{
				fightResult.fatigueGain = 1;
			}
			if (fighters[i].gladiator != null)
			{
				if (!loserTeam.Contains(fighters[i]))
				{
					fighters[i].gladiator.fightsWon++;
					fightResult.fameGain = 1;
				}
				else
				{
					fighters[i].gladiator.fightsLost++;
				}
				fighters[i].gladiator.fatigueTier = Mathf.Min(5, fighters[i].gladiator.fatigueTier + fightResult.fatigueGain);
				fighters[i].gladiator.fame = Mathf.Clamp(fighters[i].gladiator.fame + fightResult.fameGain, 0, 5);
				if (fighters[i].gladiator.fame >= 3)
				{
					fightResult.mercyBiasText = fightResult.mercyBiasText + LocalizationManager.GetTranslation("colosseum_reason_crowd_loves") + "\n";
				}
				switch (fighters[i].gladiator.alignment)
				{
				case GladiatorAlignment.Hero:
					fightResult.mercyBiasText = fightResult.mercyBiasText + LocalizationManager.GetTranslation("colosseum_reason_hero") + "\n";
					break;
				case GladiatorAlignment.Heel:
					fightResult.mercyBiasText = fightResult.mercyBiasText + LocalizationManager.GetTranslation("colosseum_reason_villain") + "\n";
					break;
				}
			}
			fightResults.Add(fightResult);
		}
	}

	public void SkipToResult()
	{
		if (phase == FightPhase.Combat)
		{
			float num = GetLivingSkill(team1) + 1;
			float num2 = GetLivingSkill(team2) + 1;
			List<ArenaFighter> list = ((SRand.Range(0f, num + num2) < num) ? team2 : team1);
			foreach (ArenaFighter item in list)
			{
				item.KnockOut();
			}
			EndFight(list);
		}
		phase = FightPhase.WaitingForThumbs;
	}

	private static int GetLivingSkill(List<ArenaFighter> team)
	{
		int num = 0;
		foreach (ArenaFighter item in team)
		{
			if (item.CurrentHp > 0f)
			{
				num += item.CombatSkill;
			}
		}
		return num;
	}

	public bool IsWinningTeam(ArenaFighter f)
	{
		if ((team1loser ? team1 : team2).Contains(f))
		{
			return false;
		}
		return true;
	}

	public bool Team1Lost()
	{
		return team1loser;
	}

	public float GetWinnerHpFraction()
	{
		List<ArenaFighter> list = (team1loser ? team2 : team1);
		float num = 0f;
		float num2 = 0f;
		foreach (ArenaFighter item in list)
		{
			num += item.CurrentHp;
			num2 += item.MaxHp;
		}
		if (!(num2 > 0f))
		{
			return 0f;
		}
		return num / num2;
	}

	public FightResult GetWinnerResults()
	{
		List<ArenaFighter> list = (team1loser ? team1 : team2);
		for (int i = 0; i < fighters.Count; i++)
		{
			if (!list.Contains(fighters[i]))
			{
				return fightResults[i];
			}
		}
		return null;
	}

	public FightResult GetLoserResults()
	{
		List<ArenaFighter> list = (team1loser ? team1 : team2);
		for (int i = 0; i < fighters.Count; i++)
		{
			if (list.Contains(fighters[i]))
			{
				return fightResults[i];
			}
		}
		return null;
	}

	private void TickDeath(float dt)
	{
		deathDelayTimer += dt;
		if (deathDelayTimer >= postDeathDelay)
		{
			phase = FightPhase.WaitingForThumbs;
		}
	}

	private void SpawnGladiator(List<ArenaFighter> team, Vector3 pos, Gladiator gladiator, int teamId, ColosseumRound.Role role)
	{
		GameObject gameObject = Object.Instantiate(gladiatorPrefab, pos, Quaternion.identity);
		gameObject.GetComponent<GladiatorVisual>().ApplyDef(gladiator.visualDef);
		gameObject.GetComponent<GladiatorVisual>().SetRole(role);
		ArenaFighter component = gameObject.GetComponent<ArenaFighter>();
		component.Init(gladiator.name, 100f, this, teamId, gladiator, null);
		team.Add(component);
	}

	private void SpawnBeast(List<ArenaFighter> team, Vector3 pos, string name, string beastType, int teamId)
	{
		BeastTemplate beastDefByName = GladiatorSystem.inst.GetBeastDefByName(beastType);
		ArenaFighter component = Object.Instantiate(beastDefByName.mesh, pos, Quaternion.identity).GetComponent<ArenaFighter>();
		component.Init(name, 100f, this, teamId, null, beastDefByName);
		team.Add(component);
	}

	public void PlayLoserKneel()
	{
		foreach (ArenaFighter item in team1loser ? team1 : team2)
		{
			item.PlayKneel();
		}
	}

	public void PlayPostThumbsAnimation(bool isMercy)
	{
		List<ArenaFighter> list = (team1loser ? team1 : team2);
		List<ArenaFighter> list2 = (team1loser ? team2 : team1);
		if (isMercy)
		{
			foreach (ArenaFighter item in list)
			{
				item?.PlayMercy();
			}
			return;
		}
		ArenaFighter victim = list[0];
		foreach (ArenaFighter item2 in list2)
		{
			if (item2 != null && item2.CurrentHp > 0f)
			{
				item2.PlayExecutionAttack(victim);
			}
		}
		foreach (ArenaFighter item3 in list)
		{
			item3?.PlayExecution();
		}
	}

	public void CleanupArena()
	{
		CleanupFighters();
		phase = FightPhase.None;
	}

	private void CleanupFighters()
	{
		foreach (ArenaFighter fighter in fighters)
		{
			MonoBehaviour monoBehaviour = fighter;
			if ((object)monoBehaviour != null && monoBehaviour != null)
			{
				fighter.Cleanup();
			}
		}
		fighters.Clear();
		team1.Clear();
		team2.Clear();
		currentBeastTargetIndex = 0;
		for (int i = 0; i < debris.Count; i++)
		{
			Object.Destroy(debris[i].gameObject);
		}
		debris.Clear();
	}

	internal void AddDebris(GameObject go, Vector3 awayDir)
	{
		if (!debrisScene.IsValid())
		{
			debrisScene = SceneManager.CreateScene("ArenaDebris_" + GetInstanceID(), new CreateSceneParameters(LocalPhysicsMode.Physics3D));
			debrisPhysics = debrisScene.GetPhysicsScene();
			GameObject gameObject = new GameObject("ArenaDebrisFloor");
			gameObject.AddComponent<BoxCollider>().size = new Vector3(arenaRadius * 4f, 1f, arenaRadius * 4f);
			gameObject.transform.position = arenaCenter.position - Vector3.up * 0.5f;
			SceneManager.MoveGameObjectToScene(gameObject, debrisScene);
		}
		go.transform.SetParent(null, worldPositionStays: true);
		SceneManager.MoveGameObjectToScene(go, debrisScene);
		go.AddComponent<BoxCollider>();
		Rigidbody rigidbody = go.AddComponent<Rigidbody>();
		rigidbody.useGravity = false;
		rigidbody.linearVelocity = awayDir * debrisLaunchSpeed * SRand.Range(0.5f, 1f) + Vector3.up * debrisUpSpeed * SRand.Range(0.7f, 1f);
		rigidbody.angularVelocity = Random.insideUnitSphere * debrisSpin;
		debris.Add(rigidbody);
	}

	private void Update()
	{
		if (debris.Count != 0)
		{
			Vector3 force = Vector3.down * debrisGravity;
			for (int i = 0; i < debris.Count; i++)
			{
				debris[i].AddForce(force, ForceMode.Acceleration);
			}
			debrisPhysics.Simulate(Mathf.Min(Time.unscaledDeltaTime, 1f / 30f));
		}
	}

	internal void UnloadDebrisScene()
	{
		debris.Clear();
		if (debrisScene.IsValid())
		{
			SceneManager.UnloadSceneAsync(debrisScene);
		}
		debrisScene = default;
	}

	private void OnDestroy()
	{
		UnloadDebrisScene();
	}
}
