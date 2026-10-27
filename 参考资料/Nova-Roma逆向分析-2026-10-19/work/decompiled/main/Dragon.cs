using System;
using Assets;
using UnityEngine;

public class Dragon : MonoBehaviour, IProjectileHitable
{
	public enum GroundDestructionType
	{
		SingleCell,
		PlusSign,
		ThreeByThree
	}

	private enum RoarAnimState
	{
		Open,
		Wait,
		Close
	}

	[Serializable]
	public class DragonSaveData : SaveClass<Dragon, DragonSaveData>
	{
		private float hp;

		private float maxHp;

		private float waggleIntensity;

		private float flySpeed;

		private float strengthScaler;

		private SerializableVector3 position;

		private SerializableQuaternion rotation;

		public override DragonSaveData Pack(Dragon d)
		{
			hp = d.hp;
			maxHp = d.maxHp;
			waggleIntensity = d.waggleIntensity;
			flySpeed = d.maxFlySpeed;
			strengthScaler = d.flyStrength;
			position = d.transform.position;
			rotation = d.transform.rotation;
			return this;
		}

		public override Dragon Unpack(Dragon d)
		{
			d.hp = hp;
			d.maxHp = maxHp;
			d.waggleIntensity = waggleIntensity;
			d.maxFlySpeed = flySpeed;
			d.flyStrength = strengthScaler;
			d.Create(d.hp, d.flyStrength);
			d.transform.position = position;
			d.transform.rotation = rotation;
			return d;
		}
	}

	public int lastAttackerTeamId = -1;

	public DragonController dragonController;

	private float hitFlashTime;

	private ParticleSystem fire;

	private GameObject fireBreath;

	public GameObject head;

	public GameObject fireBreathPrefab;

	public AudioClip SFX_dragonFlap;

	public AudioClip SFX_dragonBreath;

	public AudioClip SFX_dragonRoar;

	public float animationSpeed = 1f;

	private Animator animator;

	private Vector3 desiredLookTargetPosition = Vector3.zero;

	private Vector3 lookTargetPosition = Vector3.zero;

	private Vector3 lookVelocity = Vector3.zero;

	private float flyAccel;

	private float flyStrength = 1f;

	private float flyCurrVelocity = 1f;

	private float flyDesiredVelocity;

	private float fallVelocity;

	private float maxFlySpeed = 1f;

	private float hp;

	private float maxHp;

	private object lookTarget;

	private float waggleIntensity;

	private bool fireEnabled;

	private bool stopped;

	private bool dying;

	private bool falling;

	private bool dead;

	private float startDie;

	public GroundDestructionType destructionType;

	public HealthBar healthBar;

	private float originalEmissionRate;

	private CatmullRomSpline<object> spline;

	public SplineTraveler<object> splineTravler;

	private Material[] materials;

	private Color[] origColors;

	private bool jawOpen;

	private float jawOpenAmount;

	private float roarTime;

	private RoarAnimState roarAnim = RoarAnimState.Close;

	private bool roaring;

	private float startStopping = 3f;

	private float endStopping = 1f;

	private float currFlyHeight = 3f;

	private float currFlyHeightVel;

	public bool JawOpen
	{
		get
		{
			return jawOpen;
		}
		set
		{
			if (!roaring)
			{
				if (jawOpen != value)
				{
					float weight = (value ? 1f : 0f);
					animator.SetLayerWeight(1, weight);
					jawOpenAmount = weight;
				}
				jawOpen = value;
			}
		}
	}

	bool IProjectileHitable.IsInvalid()
	{
		return hp <= 0f;
	}

	float IProjectileHitable.GetRadius()
	{
		return 1f;
	}

	public Vector3 GetPosition()
	{
		return transform.position;
	}

	Vector3 IProjectileHitable.GetPredictedPosition(float time)
	{
		return PredictPosition(time);
	}

	Vector3 IProjectileHitable.GetVelocity()
	{
		return transform.forward * flyCurrVelocity;
	}

	HitSfxResult IProjectileHitable.TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int teamID)
	{
		EffectsMan.inst.GibsEffect.CreateAndPlay(transform.position);
		TakeDamage(dmg);
		for (int i = 0; i < materials.Length; i++)
		{
			materials[i].color = Color.white;
		}
		hitFlashTime = 0.06f;
		lastAttackerTeamId = teamID;
		return HitSfxResult.None;
	}

	public void Awake()
	{
		dragonController = GetComponent<DragonController>();
	}

	public void Create(float hp, float strengthScaler)
	{
		this.hp = (maxHp = hp);
		flyStrength = strengthScaler;
		dying = false;
		if (spline == null)
		{
			spline = new CatmullRomSpline<object>(looping: false);
		}
		splineTravler = new SplineTraveler<object>(spline);
		animator = GetComponent<Animator>();
		animator.speed = animationSpeed;
		if (fireBreath != null)
		{
			UnityEngine.Object.Destroy(fireBreath);
		}
		fireBreath = UnityEngine.Object.Instantiate(fireBreathPrefab);
		fireBreath.transform.SetParent(head.transform, worldPositionStays: false);
		fireBreath.transform.localPosition = Vector3.zero;
		fireBreath.transform.localRotation = Quaternion.identity;
		fire = fireBreath.GetComponentInChildren<ParticleSystem>();
		originalEmissionRate = fire.emission.rateOverTime.constant;
		fire.Stop();
		fire.Clear();
		ParticleSystem.EmissionModule emission = fire.emission;
		emission.enabled = true;
		fire.Play();
		emission.rateOverTime = 0f;
		transform.position = new Vector3(0f, 3f, 0f);
		desiredLookTargetPosition = new Vector3(World.inst.GridWidth / 2, 0f, World.inst.GridHeight);
		MeshRenderer[] componentsInChildren = GetComponentsInChildren<MeshRenderer>();
		materials = new Material[componentsInChildren.Length];
		origColors = new Color[componentsInChildren.Length];
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			materials[i] = componentsInChildren[i].material;
			origColors[i] = materials[i].color;
		}
	}

	private void OnEnable()
	{
		healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
	}

	private void OnDisable()
	{
		if ((bool)healthBar)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
		}
	}

	public void PlayFlap()
	{
		SfxSystem.inst.PlayFromBank("DragonWingFlap", transform.position);
	}

	public void PlayBurn()
	{
		SfxSystem.inst.PlayFromBankIfVisible("DragonFlameThrower", transform.position);
	}

	public void TakeDamage(float damage)
	{
		if (StreamerEffects.Flag_StrongerEnemies)
		{
			damage /= 2f;
		}
		hp -= damage;
	}

	private void Update()
	{
		UpdateMovement();
		UpdateActions();
		ParticleSystem.EmissionModule emission = fire.emission;
		emission.rateOverTime = originalEmissionRate * (fireEnabled ? 1f : 0f);
		healthBar.SetPos(transform.position + new Vector3(0f, 1f, 0f));
		healthBar.life = hp / maxHp;
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (hitFlashTime > 0f && hitFlashTime - unscaledDeltaTime <= 0f)
		{
			for (int i = 0; i < materials.Length; i++)
			{
				materials[i].color = origColors[i];
			}
		}
		hitFlashTime -= unscaledDeltaTime;
		if (!roaring)
		{
			return;
		}
		roarTime += unscaledDeltaTime;
		switch (roarAnim)
		{
		case RoarAnimState.Open:
		{
			float num2 = Mathf.Clamp01(roarTime / 0.2f);
			animator.SetLayerWeight(1, num2);
			jawOpenAmount = num2;
			if (num2 >= 1f)
			{
				roarTime = 0f;
				roarAnim = RoarAnimState.Wait;
			}
			break;
		}
		case RoarAnimState.Wait:
			if (Mathf.Clamp01(roarTime / 1f) >= 1f)
			{
				roarTime = 0f;
				roarAnim = RoarAnimState.Close;
			}
			break;
		case RoarAnimState.Close:
		{
			float num = Mathf.Clamp01(roarTime / 0.3f);
			animator.SetLayerWeight(1, 1f - num);
			jawOpenAmount = 1f - num;
			if (num >= 1f)
			{
				roarTime = 0f;
				roaring = false;
			}
			break;
		}
		}
	}

	private void LateUpdate()
	{
		LookWithHead();
	}

	public void Roar()
	{
		if (!roaring && !JawOpen)
		{
			roaring = true;
			roarTime = 0f;
			roarAnim = RoarAnimState.Open;
			SfxSystem.inst.PlayFromBank("DragonRoar", transform.position);
		}
	}

	public Vector3 PredictPosition(float timeAhead)
	{
		return transform.position + transform.forward * timeAhead * flyCurrVelocity;
	}

	public void SetLookTarget(object target)
	{
		lookTarget = target;
	}

	public void FireBreath(bool on)
	{
		JawOpen = on;
		fireEnabled = on;
	}

	public void MouthOpen(bool open)
	{
		JawOpen = open;
		fireEnabled = false;
	}

	public void HeadWaggleIntensity(float intensity)
	{
		waggleIntensity = intensity;
	}

	public float HP()
	{
		return hp;
	}

	public float MaxHP()
	{
		return maxHp;
	}

	public void SetFlySpeed(float newSpeed)
	{
		maxFlySpeed = newSpeed;
	}

	public bool IsMoving()
	{
		return !IsStopped();
	}

	public bool NearEnd()
	{
		int num = spline.LastUsefulControlPointIndex();
		if (num >= 0 && num < spline.controlPointsList.Count)
		{
			return Vector3.Distance(transform.position, spline.controlPointsList[num].pos) < 3f;
		}
		return true;
	}

	private bool IsStopped()
	{
		return (double)flyCurrVelocity < 0.1;
	}

	public void CancelMove()
	{
		stopped = true;
		flyCurrVelocity = 0f;
	}

	public void Die()
	{
		if (!dead && !dying)
		{
			FireBreath(on: false);
			Roar();
			CancelMove();
			startDie = Time.timeSinceLevelLoad;
			dying = true;
			animator.SetTrigger("Falling");
		}
	}

	public void Fall()
	{
		falling = true;
	}

	private void HitGround()
	{
		dead = true;
		animator.SetTrigger("HitGround");
		if (FogOfWar.inst.IsVisible(transform.position))
		{
			Cam.inst.Shake(Vector3.down * 5f);
			EffectsMan.inst.GroundImpactEffect.CreateAndPlay(transform.position);
			SfxSystem.inst.PlayFromBankIfVisible("DragonFallHit", transform.position);
		}
	}

	public void MoveInCircleAround(Vector3 pos, float radius)
	{
		if (dying || dead)
		{
			return;
		}
		stopped = false;
		spline.ClearControlPoints();
		float num = Mathf.Min(3f, Vector3.Distance(pos, transform.position));
		if (num < 3f)
		{
			num *= 0.5f;
		}
		Vector3 pos2 = transform.position - transform.forward * num;
		Vector3 position = transform.position;
		Vector3 vector = transform.position + transform.forward * num;
		Vector3 vector2 = transform.position - pos;
		vector2.y = 0f;
		vector2.Normalize();
		Vector3 vector3 = pos + vector2 * radius * 2f;
		vector3.y = 3f;
		Vector3 normalized = (vector3 - position).normalized;
		spline.AddControlPoint(pos2);
		spline.AddControlPoint(position);
		spline.AddControlPoint(vector);
		spline.AddControlPoint(vector3);
		if (Vector3.Dot(transform.forward, normalized) < 0f)
		{
			if (Vector3.Dot(transform.right, normalized) > 0f)
			{
				spline.controlPointsList[3].pos = vector + transform.right * num;
			}
			else
			{
				spline.controlPointsList[3].pos = vector - transform.right * num;
			}
		}
		spline.SplitSplineIntoLengthSegments(2, 2f);
		float num2 = 33f;
		for (int i = 0; i < 10; i++)
		{
			Vector3 vector4 = Quaternion.AngleAxis(num2, Vector3.up) * vector2;
			Vector3 pos3 = pos + vector4 * radius;
			pos3.y = 3f;
			spline.AddControlPoint(pos3);
			num2 += 33f;
		}
		splineTravler.Reset();
	}

	public void MoveTo(Vector3 pos)
	{
		if (dying || dead)
		{
			return;
		}
		stopped = false;
		spline.ClearControlPoints();
		float num = Mathf.Min(3f, Vector3.Distance(pos, transform.position));
		if (num < 3f)
		{
			num *= 0.5f;
		}
		Vector3 pos2 = transform.position - transform.forward * num;
		Vector3 position = transform.position;
		Vector3 vector = transform.position + transform.forward * num;
		Vector3 pos3 = pos + (pos - position).normalized * num;
		Vector3 normalized = (pos - position).normalized;
		spline.AddControlPoint(pos2);
		spline.AddControlPoint(position);
		spline.AddControlPoint(vector);
		spline.AddControlPoint(pos);
		spline.AddControlPoint(pos3);
		spline.SplitSplineIntoLengthSegments(2, 2f);
		if (Vector3.Dot(transform.forward, normalized) < 0f)
		{
			if (spline.controlPointsList[3].pos == pos)
			{
				spline.AddControlPoint(pos, null, 3);
			}
			if (Vector3.Dot(transform.right, normalized) > 0f)
			{
				spline.controlPointsList[3].pos = vector + transform.right * num;
			}
			else
			{
				spline.controlPointsList[3].pos = vector - transform.right * num;
			}
		}
		splineTravler.Reset();
	}

	private void OnDestroy()
	{
		UnityEngine.Object.Destroy(fireBreath.gameObject);
	}

	private void UpdateMovement()
	{
		if (dead)
		{
			return;
		}
		if (dying && falling)
		{
			Cell cellData = World.inst.GetCellData(transform.position);
			fallVelocity += 2f * Time.deltaTime;
			float y = transform.position.y - fallVelocity * Time.deltaTime;
			if (cellData != null)
			{
				transform.position += (cellData.Center2D - transform.position) * Time.deltaTime;
			}
			transform.position = transform.position.xz() + new Vector3(0f, y, 0f);
			if (transform.position.y <= 0f)
			{
				HitGround();
			}
		}
		float num = 0f;
		if (spline.controlPointsList.Count > 0)
		{
			num = spline.RoughDistanceToEnd(splineTravler, startStopping + 0.5f);
		}
		if (stopped)
		{
			flyDesiredVelocity = 0f;
		}
		else if (num < startStopping)
		{
			float num2 = startStopping - endStopping;
			float t = (num - endStopping) / num2;
			flyDesiredVelocity = Mathf.Lerp(0f, maxFlySpeed, t);
		}
		else
		{
			flyDesiredVelocity = maxFlySpeed;
		}
		flyAccel = (flyDesiredVelocity - flyCurrVelocity) * flyStrength;
		flyCurrVelocity += flyAccel * Time.deltaTime;
		float num3 = flyCurrVelocity * Time.deltaTime;
		if (spline != null && spline.Valid() && IsMoving())
		{
			Vector3 vector = splineTravler.Travel(num3);
			float buildingHeight = 0f;
			Vector3 vector2 = vector + transform.forward * Mathff.Clamp(flyCurrVelocity, 0f, 2f);
			World.inst.ForEachTileInRadius((int)vector2.x, (int)vector2.z, 1, (int x, int z, Cell c) =>
			{
				Building topStructure = c.TopStructure;
				World.inst.DrawLandmassCircleAt(c.Center2D, 0);
				if (topStructure != null)
				{
					float num5 = topStructure.cachedPos.y + topStructure.size.y + 1f;
					if (num5 > buildingHeight)
					{
						buildingHeight = num5;
					}
				}
			});
			float num4 = Mathff.Max(buildingHeight, 3f);
			currFlyHeight = Mathf.SmoothDamp(currFlyHeight, num4, ref currFlyHeightVel, Mathff.Clamp(Mathf.Abs(num4 - currFlyHeight) / 1f, 0.1f, 1.5f));
			vector.y = currFlyHeight;
			transform.position = vector;
			Vector3 forward = splineTravler.GetForward();
			transform.rotation = Quaternion.LookRotation(forward, Vector3.up);
		}
		animator.SetFloat("Velocity", flyCurrVelocity / maxFlySpeed);
	}

	private void UpdateActions()
	{
		if (spline != null && spline.Valid())
		{
			Vector3 vector = transform.position + transform.forward * 3f;
			Vector3 vector2 = vector;
			if (lookTarget is Vector3)
			{
				vector2 = (Vector3)lookTarget;
			}
			else if (lookTarget is Building && lookTarget as Building != null)
			{
				vector2 = ((Building)lookTarget).Center();
				vector2.y = 1f;
			}
			else if (lookTarget is Transform && lookTarget as Transform != null)
			{
				vector2 = ((Transform)lookTarget).position;
			}
			else if (lookTarget is GameObject && lookTarget as GameObject != null)
			{
				vector2 = ((GameObject)lookTarget).transform.position;
			}
			else if (lookTarget is MonoBehaviour && lookTarget as MonoBehaviour != null)
			{
				vector2 = ((MonoBehaviour)lookTarget).transform.position;
			}
			Vector3 lhs = vector2 - head.transform.position;
			if (Vector3.Dot(lhs, transform.forward) > -0.45f)
			{
				desiredLookTargetPosition = vector2;
				if (Vector3.Distance(desiredLookTargetPosition.xz(), head.transform.position.xz()) < 1f)
				{
					transform.position += -transform.forward * Time.deltaTime * 0.2f;
				}
			}
			else if (IsStopped())
			{
				Vector3 vector3 = Vector3.Dot(lhs, -transform.forward) * -transform.forward;
				desiredLookTargetPosition = vector2 - vector3;
				int num = ((Vector3.Dot(vector2 - transform.position, transform.right) > 0f) ? 1 : (-1));
				transform.rotation *= Quaternion.AngleAxis((float)(num * 90) * Time.deltaTime, Vector3.up);
			}
			else
			{
				desiredLookTargetPosition = vector;
			}
		}
		desiredLookTargetPosition += jawOpenAmount * (Mathf.Sin(Time.timeSinceLevelLoad * 2f) * 0.5f * transform.right * waggleIntensity);
	}

	private void LookWithHead()
	{
		if (dying)
		{
			if (!dead)
			{
				if (falling)
				{
					head.transform.localRotation = Quaternion.RotateTowards(head.transform.localRotation, Quaternion.Euler(0f, -90f, 0f), 45f);
					return;
				}
				float num = Mathf.Sin((Time.timeSinceLevelLoad - startDie) * 6f) * 50f * jawOpenAmount;
				head.transform.localRotation = Quaternion.RotateTowards(head.transform.localRotation, Quaternion.Euler(-25f, -90f + num, 0f), 999f);
			}
		}
		else
		{
			lookTargetPosition = Vector3.SmoothDamp(lookTargetPosition, desiredLookTargetPosition, ref lookVelocity, 0.1f, 50f);
			Vector3 worldUp = Vector3.Lerp(Vector3.up, transform.forward, Vector3.Dot(new Vector3(0f, -1f, 0f), head.transform.forward));
			head.transform.LookAt(lookTargetPosition, worldUp);
			fire.transform.LookAt(lookTargetPosition, worldUp);
		}
	}

	private void OnDrawGizmos()
	{
		if (spline != null && Camera.current == GameUI.inst.WorldCamera)
		{
			spline.DrawGizmo();
			Gizmos.color = Color.blue;
			Gizmos.DrawLine(head.transform.position, lookTargetPosition);
			Gizmos.color = Color.magenta;
			Gizmos.DrawLine(head.transform.position, desiredLookTargetPosition);
		}
	}
}
