using System;
using System.Collections.Generic;
using FMODUnity;
using UnityEngine;

public class ArenaFighter : MonoBehaviour
{
	private enum State
	{
		Ready,
		Lunging,
		Executing,
		Dodging,
		Blocking,
		Stunned,
		Waiting,
		Fleeing,
		Dying,
		Dead
	}

	internal Gladiator gladiator;

	internal BeastTemplate beast;

	[Header("Tuning")]
	public float radius = 0.125f;

	public float walkSpeed = 1.2f;

	public float lungeDistance = 0.15f;

	public float healthBarHeight = 0.5f;

	[Tooltip("Beast style: rock the mesh side to side while walking instead of using the walk bounce curve.")]
	public bool wobbleWalk;

	[SerializeField]
	private Transform meshRoot;

	private HealthBar healthBar;

	private Renderer[] renderers;

	private Color[] originalColors;

	private float walkTime;

	private const float meleeRange = 0.3f;

	private bool inMeleeRange;

	[NonSerialized]
	private Animator animator;

	private Vector3 animForward;

	private State currState;

	private float lungeTimer;

	private Vector3 lungeDir;

	private const float lungeDuration = 0.2f;

	public float lungeDamage = 5f;

	public float lungeHitRadius = 0.35f;

	private bool lungeHasHit;

	public float lungeHitStart = 0.12f;

	private const float dodgeDuration = 0.2f;

	private float stunTimer;

	public float stunDuration = 0.8f;

	private bool isFlashing;

	private float flashTimer;

	private const float flashDuration = 0.2f;

	private float deathTimer;

	private const float deathDuration = 0.5f;

	private Quaternion deathStartRot;

	private bool isMercyAnimating;

	private float mercyTimer;

	private const float mercyDuration = 0.6f;

	private Quaternion mercyStartRot;

	[Range(0f, 1f)]
	public float fleeChancePerHit = 0.35f;

	private const float fleeHpFraction = 0.25f;

	private const int fleeSkillGap = 2;

	private float fleeTimeLeft;

	private const float chaseForce = 5f;

	private const float fleeForce = 10f;

	private const int fleeTargetSamples = 16;

	private Vector3 fleeTarget;

	private int teamId;

	private ColosseumRound.Role role;

	private ArenaFighter executionTarget;

	private string currAttackAnim = "";

	public float blockReactRange = 0.6f;

	[Range(-1f, 1f)]
	public float blockReactFacing = 0.5f;

	private const float CheerCooldown = 6f;

	private static float nextCheerTime;

	private static readonly List<GameObject> equippedScratch = new List<GameObject>();

	private static readonly int DEATH = Animator.StringToHash("death");

	private static readonly int BLOCK = Animator.StringToHash("block");

	private static readonly int STAGGER = Animator.StringToHash("stagger");

	private static readonly int STANDING_IDLE = Animator.StringToHash("standingIdle");

	private static readonly int FALL_BACK_DEATH = Animator.StringToHash("fall_back_death");

	private bool animatedDeath;

	private float readyTime;

	private bool tryAttackDamage;

	internal ArenaFightManager afm;

	public float lungeForce = 100f;

	public float dodgeForce = 60f;

	public string DisplayName { get; private set; }

	public Vector3 Position
	{
		get
		{
			return transform.position;
		}
		set
		{
			transform.position = value;
		}
	}

	public Vector3 Velocity { get; set; }

	public Vector3 Acceleration { get; set; }

	public float Radius => radius;

	public Transform Root => transform;

	public float CurrentHp { get; private set; }

	public float MaxHp { get; private set; }

	private List<ArenaFighter> Enemies
	{
		get
		{
			if (teamId != 0)
			{
				return afm.team1;
			}
			return afm.team2;
		}
	}

	internal int CombatSkill
	{
		get
		{
			if (gladiator == null)
			{
				return beast.tier * 2;
			}
			return gladiator.skills.GetSkill(role);
		}
	}

	public void ApplyAnimForward()
	{
		transform.rotation = Quaternion.LookRotation(animForward);
	}

	private void PickFleeTarget()
	{
		ArenaFighter arenaFighter = null;
		ArenaFighter arenaFighter2 = null;
		float num = float.MaxValue;
		float num2 = float.MaxValue;
		List<ArenaFighter> enemies = Enemies;
		for (int i = 0; i < enemies.Count; i++)
		{
			if (!(enemies[i].CurrentHp <= 0f))
			{
				float num3 = Mathff.DistSqrd(enemies[i].Position, Position);
				if (num3 < num)
				{
					arenaFighter2 = arenaFighter;
					num2 = num;
					arenaFighter = enemies[i];
					num = num3;
				}
				else if (num3 < num2)
				{
					arenaFighter2 = enemies[i];
					num2 = num3;
				}
			}
		}
		Vector3 position = afm.arenaCenter.position;
		float num4 = afm.arenaRadius - 2f * radius;
		fleeTarget = Position;
		float num5 = -1f;
		for (int j = 0; j < 16; j++)
		{
			float f = (float)j * (MathF.PI / 8f);
			Vector3 vector = position + new Vector3(Mathf.Cos(f), 0f, Mathf.Sin(f)) * num4;
			float num6 = float.MaxValue;
			if (arenaFighter != null)
			{
				num6 = (vector - arenaFighter.Position).xz().sqrMagnitude;
			}
			if (arenaFighter2 != null)
			{
				num6 = Mathf.Min(num6, (vector - arenaFighter2.Position).xz().sqrMagnitude);
			}
			if (num6 > num5)
			{
				num5 = num6;
				fleeTarget = vector;
			}
		}
	}

	public void Init(string displayName, float maxHp, ArenaFightManager arenaFightManager, int team, Gladiator g, BeastTemplate b)
	{
		gladiator = g;
		beast = b;
		teamId = team;
		afm = arenaFightManager;
		DisplayName = displayName;
		MaxHp = maxHp;
		CurrentHp = maxHp;
		GladiatorVisual component = GetComponent<GladiatorVisual>();
		role = component.currRole;
		if (meshRoot == null)
		{
			meshRoot = ((transform.childCount > 0) ? transform.GetChild(0) : transform);
		}
		renderers = GetComponentsInChildren<Renderer>();
		originalColors = new Color[renderers.Length];
		for (int i = 0; i < renderers.Length; i++)
		{
			if (renderers[i].material.HasProperty("_Color"))
			{
				originalColors[i] = renderers[i].material.color;
			}
			else
			{
				originalColors[i] = Color.white;
			}
		}
		if (Player.inst != null && Player.inst.healthBarPrefab != null)
		{
			healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
			healthBar.maxTimeShowing = 999f;
			healthBar.life = 1f;
			healthBar.gameObject.SetActive(value: true);
		}
		animator = GetComponent<Animator>();
		animator.Play("standingIdle");
	}

	public bool MoveToward(Vector3 target, float dt)
	{
		Vector3 vector = target - transform.position;
		vector.y = 0f;
		if (vector.magnitude <= 0.3f)
		{
			inMeleeRange = true;
			if (vector.sqrMagnitude > 0.001f)
			{
				transform.rotation = Quaternion.LookRotation(vector.normalized);
			}
			UpdateHealthBarPos();
			return true;
		}
		inMeleeRange = false;
		vector.Normalize();
		transform.rotation = Quaternion.LookRotation(vector);
		transform.position += vector * walkSpeed * dt;
		float num;
		if (wobbleWalk)
		{
			walkTime += dt * 4f;
			if (meshRoot != null)
			{
				meshRoot.localRotation = Quaternion.Euler(0f, 0f, Mathf.Sin(walkTime * MathF.PI * 2f) * 15f);
			}
			num = Mathf.Abs(Mathf.Sin(walkTime * MathF.PI * 2f)) * 0.02f;
		}
		else
		{
			walkTime += dt * 3f;
			if (walkTime > 1f)
			{
				walkTime--;
			}
			num = 0f;
			if (Player.inst != null && Player.inst.walkBounce != null)
			{
				num = Player.inst.walkBounce.Evaluate(walkTime) * 0.03f;
			}
		}
		Vector3 position = transform.position;
		position.y += num;
		transform.position = position;
		UpdateHealthBarPos();
		return false;
	}

	public void PlayExecutionAttack(ArenaFighter victim)
	{
		executionTarget = victim;
		currState = State.Executing;
		transform.rotation = Quaternion.LookRotation((victim.Position - Position).xz());
		lungeTimer = 0f;
		lungeDir = transform.forward;
		lungeHasHit = false;
		tryAttackDamage = false;
		if (animator != null)
		{
			currAttackAnim = AttackAnimForRole();
			animator.CrossFade(currAttackAnim, 0.1f);
			animator.Update(0f);
		}
	}

	private void TakeExecutionBlow(ArenaFighter executioner)
	{
		OneOffEffect oneOffEffect = EffectsMan.inst.GibsSmallEffect.Create(Position);
		oneOffEffect.UseRealtime = true;
		oneOffEffect.Play();
		if (executioner.gladiator != null)
		{
			RuntimeManager.PlayOneShot("event:/OldSFX/Soldier_SwordImpact_Body", Position);
		}
		isFlashing = true;
		flashTimer = 0f;
		SetRenderersColor(Color.red);
		animator.CrossFade(FALL_BACK_DEATH, 0.1f);
		Acceleration += (Position - executioner.Position).xz().normalized * 250f;
	}

	private string AttackAnimForRole()
	{
		if (role == ColosseumRound.Role.Retiarus || role == ColosseumRound.Role.Bestiarius)
		{
			return "stab";
		}
		return "lunge_forward";
	}

	public void PlayAttack()
	{
		if (currState != State.Lunging)
		{
			currState = State.Lunging;
			ColosseumUI.inst.fightUI.AddSpectacle(SRand.Range(0, 1));
			lungeTimer = 0f;
			lungeDir = transform.forward;
			lungeHasHit = false;
			tryAttackDamage = false;
			List<ArenaFighter> enemies = Enemies;
			for (int i = 0; i < enemies.Count; i++)
			{
				enemies[i].TryReactiveBlock(this);
			}
			if (animator != null)
			{
				currAttackAnim = AttackAnimForRole();
				animator.CrossFade(currAttackAnim, 0.1f);
			}
		}
	}

	public void PlayDodge(Vector3 dir)
	{
		if (currState == State.Ready && !(SRand.value >= afm.DefenseChance))
		{
			currState = State.Dodging;
			lungeTimer = 0f;
			lungeDir = dir.normalized;
			int stateHashName = Animator.StringToHash("dodge_back");
			animForward = dir;
			animator.CrossFade(stateHashName, 0.1f);
		}
	}

	public void PlayBlock()
	{
		if (currState == State.Ready && !(SRand.value >= afm.DefenseChance))
		{
			currState = State.Blocking;
			animator.CrossFade(BLOCK, 0.1f);
		}
	}

	private void TryReactiveBlock(ArenaFighter attacker)
	{
		if (gladiator == null || currState != State.Ready)
		{
			return;
		}
		Vector3 vector = (Position - attacker.Position).xz();
		if (!(vector.sqrMagnitude > blockReactRange * blockReactRange) && !(Vector3.Dot(attacker.transform.forward.xz().normalized, vector.normalized) < blockReactFacing))
		{
			float num = Mathf.Clamp01((float)(CombatSkill - attacker.CombatSkill - 1) / 3f) * 0.5f;
			if (SRand.value < num)
			{
				PlayBlock();
			}
		}
	}

	private void GetBlocked(ArenaFighter blocker)
	{
		animator.CrossFade(STAGGER, 0.05f);
		currState = State.Ready;
		OneOffEffect oneOffEffect = EffectsMan.inst.SparksSmallEffect.Create(transform.position);
		oneOffEffect.UseRealtime = true;
		oneOffEffect.Play();
		RuntimeManager.PlayOneShot("event:/OldSFX/Soldier_SwordImpact_Sword", transform.position);
		Vector3 normalized = (Position - blocker.Position).xz().normalized;
		Acceleration += normalized * 250f;
	}

	public void PlayStun()
	{
		if (currState != State.Stunned && currState != State.Dying && currState != State.Dead)
		{
			currState = State.Stunned;
			EffectsMan.inst.StunEffect.CreateAndPlay(Position);
			stunTimer = 0f;
		}
	}

	public void PlayWaiting()
	{
		currState = State.Waiting;
		if (animator != null)
		{
			animator.CrossFade("victory", 0.3f);
		}
	}

	private void DropEquipment(ArenaFighter attacker)
	{
		equippedScratch.Clear();
		GladiatorVisual component = GetComponent<GladiatorVisual>();
		component.GetEquipped(equippedScratch);
		Vector3 normalized = (Position - attacker.Position).xz().normalized;
		for (int i = 0; i < equippedScratch.Count; i++)
		{
			afm.AddDebris(equippedScratch[i], normalized);
		}
		component.ShowBareHead();
	}

	public void KnockOut()
	{
		CurrentHp = 0f;
		if (healthBar != null)
		{
			healthBar.life = 0f;
		}
	}

	public void TakeDamage(float amount, ArenaFighter attacker)
	{
		if (CurrentHp > 0f && CurrentHp - amount <= 0f && gladiator != null)
		{
			DropEquipment(attacker);
			RuntimeManager.PlayOneShot("event:/OldSFX/VikingDeath", transform.position);
		}
		CurrentHp = Mathf.Max(0f, CurrentHp - amount);
		if (Time.unscaledTime >= nextCheerTime && CurrentHp > 0f)
		{
			nextCheerTime = Time.unscaledTime + 6f;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_cheer", transform.position);
		}
		if (healthBar != null)
		{
			healthBar.life = CurrentHp / MaxHp;
		}
		isFlashing = true;
		flashTimer = 0f;
		SetRenderersColor(Color.red);
	}

	public void PlayDeath()
	{
		if (currState != State.Dying)
		{
			currState = State.Dying;
			deathTimer = 0f;
			deathStartRot = transform.rotation;
			animatedDeath = animator != null && animator.HasState(0, DEATH);
			if (animatedDeath)
			{
				animator.CrossFade(DEATH, 0.1f);
			}
		}
	}

	public void PlayKneel()
	{
		animator.CrossFade("getup_back_submit", 0.25f);
	}

	public void PlayMercy()
	{
		if (animatedDeath)
		{
			animator.CrossFade(STANDING_IDLE, 0.3f);
			return;
		}
		isMercyAnimating = true;
		mercyTimer = 0f;
		mercyStartRot = transform.rotation;
	}

	public void PlayExecution()
	{
		OneOffEffect oneOffEffect = EffectsMan.inst.GibsSmallEffect.Create(transform.position + new Vector3(0f, 0.05f, 0f));
		oneOffEffect.UseRealtime = true;
		oneOffEffect.Play();
	}

	public void Cleanup()
	{
		if (healthBar != null)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
			healthBar = null;
		}
		UnityEngine.Object.Destroy(gameObject);
	}

	public void StartAttackDamage()
	{
		tryAttackDamage = true;
	}

	private void Update()
	{
		if (afm == null)
		{
			return;
		}
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (wobbleWalk && inMeleeRange && meshRoot != null)
		{
			meshRoot.localRotation = Quaternion.identity;
		}
		switch (currState)
		{
		case State.Ready:
		{
			DebugEx.DrawSphere(transform.position, 0.25f, Color.green);
			bool flag2 = true;
			if (animator != null && !animator.GetCurrentAnimatorStateInfo(0).IsName("standingIdle"))
			{
				flag2 = false;
			}
			if (!flag2)
			{
				break;
			}
			ArenaFighter arenaFighter = null;
			float num4 = float.MaxValue;
			List<ArenaFighter> enemies2 = Enemies;
			for (int j = 0; j < enemies2.Count; j++)
			{
				float num5 = Mathff.DistSqrd(enemies2[j].Position, Position);
				if (num5 < num4)
				{
					num4 = num5;
					arenaFighter = enemies2[j];
				}
			}
			if (arenaFighter != null)
			{
				Vector3 vector3 = arenaFighter.Position - Position;
				_ = vector3.magnitude;
				vector3.xz().Normalize();
				Acceleration += vector3 * 5f;
				transform.rotation = Quaternion.LookRotation(vector3);
			}
			readyTime += unscaledDeltaTime;
			int num6 = 3;
			if (gladiator != null)
			{
				num6 = gladiator.skills.GetSkill(role);
			}
			float num7 = 0.25f + Mathf.Lerp(0f, 0.25f, Mathf.Clamp01(5 - num6));
			if (!(readyTime > num7))
			{
				break;
			}
			readyTime = 0f;
			if (gladiator != null)
			{
				int num8 = SRand.Range(0, 5);
				if (num8 == 0 || num8 == 1)
				{
					PlayAttack();
				}
				if (num8 == 2)
				{
					int num9 = SRand.Range(0, 3);
					if (num9 == 0)
					{
						PlayDodge(-transform.forward);
					}
					if (num9 == 1)
					{
						PlayDodge(-transform.right);
					}
					if (num9 == 2)
					{
						PlayDodge(transform.right);
					}
				}
				if (num8 == 4)
				{
					PlayBlock();
				}
			}
			if (beast == null)
			{
				break;
			}
			int num10 = SRand.Range(0, 5);
			if (num10 == 0)
			{
				PlayAttack();
			}
			if (num10 == 1 || num10 == 2 || num10 == 3)
			{
				int num11 = SRand.Range(0, 3);
				if (num11 == 0)
				{
					PlayDodge(-transform.forward);
				}
				if (num11 == 1)
				{
					PlayDodge(-transform.right);
				}
				if (num11 == 2)
				{
					PlayDodge(transform.right);
				}
			}
			break;
		}
		case State.Lunging:
			DebugEx.DrawSphere(transform.position, 0.25f, Color.yellow);
			lungeTimer += unscaledDeltaTime;
			if (lungeTimer + unscaledDeltaTime > 0.1f)
			{
				Acceleration += lungeDir * lungeForce;
			}
			if (!lungeHasHit && tryAttackDamage)
			{
				List<ArenaFighter> enemies = Enemies;
				for (int i = 0; i < enemies.Count; i++)
				{
					float num = lungeHitRadius + enemies[i].Radius;
					Vector3 vector2 = Position + transform.forward * radius;
					if (Mathff.DistSqrd(enemies[i].Position, vector2) < num * num)
					{
						DebugEx.DrawSphere(vector2, lungeHitRadius, Color.green);
						if (enemies[i].currState == State.Blocking)
						{
							GetBlocked(enemies[i]);
							break;
						}
						float num2 = lungeDamage;
						if (gladiator != null)
						{
							num2 += SRand.Range(0f, gladiator.skills.GetSkill(role));
						}
						enemies[i].TakeDamage(num2, this);
						OneOffEffect oneOffEffect = EffectsMan.inst.GibsSmallEffect.Create(enemies[i].Position);
						oneOffEffect.UseRealtime = true;
						oneOffEffect.Play();
						lungeHasHit = true;
						if (gladiator != null)
						{
							RuntimeManager.PlayOneShot("event:/OldSFX/Soldier_SwordImpact_Body", enemies[i].Position);
						}
						if (enemies[i].CurrentHp > 0f)
						{
							if ((bool)enemies[i].animator)
							{
								float num3 = enemies[i].CurrentHp / enemies[i].MaxHp;
								if (num3 < 0.5f && 1f - num3 > SRand.value)
								{
									enemies[i].animator.CrossFade("fall_back", 0.1f);
								}
								else
								{
									enemies[i].animator.CrossFade("stagger", 0.05f);
								}
							}
							if (enemies[i].currState != State.Fleeing)
							{
								enemies[i].currState = State.Ready;
							}
						}
						Vector3 normalized = (enemies[i].Position - transform.position).xz().normalized;
						enemies[i].Acceleration += normalized * 250f;
					}
					else
					{
						DebugEx.DrawSphere(vector2, lungeHitRadius, Color.green);
					}
				}
				if (lungeHasHit)
				{
					ColosseumUI.inst.fightUI.AddSpectacle(SRand.Range(1, 2));
				}
			}
			if (animator != null && !animator.GetCurrentAnimatorStateInfo(0).IsName(currAttackAnim) && !animator.GetNextAnimatorStateInfo(0).IsName(currAttackAnim))
			{
				currState = State.Ready;
			}
			break;
		case State.Executing:
			lungeTimer += unscaledDeltaTime;
			if (lungeTimer + unscaledDeltaTime > 0.1f)
			{
				Acceleration += lungeDir * lungeForce;
			}
			if (!lungeHasHit && (tryAttackDamage || animator == null))
			{
				lungeHasHit = true;
				executionTarget.TakeExecutionBlow(this);
			}
			if (animator == null || (!animator.GetCurrentAnimatorStateInfo(0).IsName(currAttackAnim) && !animator.GetNextAnimatorStateInfo(0).IsName(currAttackAnim)))
			{
				executionTarget = null;
				PlayWaiting();
			}
			break;
		case State.Dodging:
			if (lungeTimer < 0.2f)
			{
				Acceleration += lungeDir * dodgeForce;
				lungeTimer += unscaledDeltaTime;
			}
			else if (animator.GetCurrentAnimatorStateInfo(0).IsName("standingIdle"))
			{
				currState = State.Ready;
			}
			break;
		case State.Blocking:
		{
			bool flag = true;
			if (animator != null && (animator.GetCurrentAnimatorStateInfo(0).IsName("block") || animator.GetNextAnimatorStateInfo(0).IsName("block")))
			{
				flag = false;
			}
			if (flag)
			{
				currState = State.Ready;
			}
			break;
		}
		case State.Fleeing:
		{
			fleeTimeLeft -= unscaledDeltaTime;
			Vector3 vector = (fleeTarget - Position).xz();
			if (fleeTimeLeft <= 0f || vector.sqrMagnitude <= radius * radius)
			{
				currState = State.Ready;
				break;
			}
			vector.Normalize();
			Acceleration += vector * 10f;
			transform.rotation = Quaternion.LookRotation(vector);
			break;
		}
		case State.Stunned:
			stunTimer += unscaledDeltaTime;
			if (meshRoot != null)
			{
				meshRoot.localRotation = Quaternion.Euler(0f, 0f, Mathf.Sin(stunTimer * MathF.PI * 8f) * 20f);
			}
			if (stunTimer >= stunDuration)
			{
				if (meshRoot != null)
				{
					meshRoot.localRotation = Quaternion.identity;
				}
				currState = State.Ready;
			}
			break;
		case State.Dying:
			deathTimer += unscaledDeltaTime;
			if (!animatedDeath)
			{
				float t = Mathf.Clamp01(deathTimer / 0.5f);
				transform.rotation = Quaternion.Slerp(deathStartRot, deathStartRot * Quaternion.Euler(90f, 0f, 0f), t);
			}
			if (deathTimer >= 0.5f)
			{
				currState = State.Dead;
			}
			break;
		}
		if (isFlashing)
		{
			flashTimer += unscaledDeltaTime;
			if (flashTimer >= 0.2f)
			{
				isFlashing = false;
				RestoreRenderersColor();
			}
		}
		if (isMercyAnimating)
		{
			mercyTimer += unscaledDeltaTime;
			float t2 = Mathf.Clamp01(mercyTimer / 0.6f);
			transform.rotation = Quaternion.Slerp(mercyStartRot, deathStartRot, t2);
			if (mercyTimer >= 0.6f)
			{
				isMercyAnimating = false;
			}
		}
		UpdateHealthBarPos();
	}

	private void UpdateHealthBarPos()
	{
		if (healthBar != null)
		{
			healthBar.SetPos(transform.position + Vector3.up * healthBarHeight);
			healthBar.origScale = new Vector3(0.3f, 0.3f, 0.3f);
		}
	}

	private void SetRenderersColor(Color c)
	{
		for (int i = 0; i < renderers.Length; i++)
		{
			if (renderers[i] != null && renderers[i].material.HasProperty("_Color"))
			{
				renderers[i].material.color = c;
			}
		}
	}

	private void RestoreRenderersColor()
	{
		for (int i = 0; i < renderers.Length; i++)
		{
			if (renderers[i] != null && renderers[i].material.HasProperty("_Color"))
			{
				renderers[i].material.color = originalColors[i];
			}
		}
	}
}
