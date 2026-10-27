using System;
using System.Collections.Generic;
using Assets;
using Drawing;
using FMODUnity;
using Unity.Collections;
using UnityEngine;

public class ChariotRaceTrack : Tickable, IWorkerUIDisplay, IOutputInfo
{
	public enum Status
	{
		Resting,
		StartRace,
		Racing,
		Finished,
		ReturnToGate,
		BetStartRace,
		BetRacing,
		BetFinished
	}

	public delegate void OnStatusChange(Status status);

	public struct FanEntry
	{
		public float animTime;

		public float jumpTime;

		public Vector3 origPos;

		public Vector3 pos;

		public Vector3 dir;
	}

	[Serializable]
	public class Track
	{
		public Vector3 center;

		public float radiusX;

		public float radiusZ;

		public float varianceX;

		public float varianceZ;

		public float prevVarianceX;

		public float prevVarianceZ;

		public float desiredVarianceX;

		public float desiredVarianceZ;

		public Track(float rX, float rZ)
		{
			radiusX = rX;
			radiusZ = rZ;
			varianceX = (desiredVarianceX = (prevVarianceX = 0f));
			varianceZ = (desiredVarianceZ = (prevVarianceZ = 0f));
		}

		public void GenerateVariance(float variance)
		{
			prevVarianceX = desiredVarianceX;
			prevVarianceZ = desiredVarianceZ;
			desiredVarianceX = SRand.Range(0f - variance, variance);
			desiredVarianceZ = SRand.Range(0f - variance, variance);
		}
	}

	public struct Incident
	{
		public bool isActive;

		public bool hasTriggered;

		public bool hasCompleted;

		public float t;

		public int type;

		public Vector3 targetPos;

		public const int WHEEL_FELL_OFF = 0;

		public const int CRASH_INTO_WALL = 1;

		public void Reset()
		{
			isActive = (hasTriggered = (hasCompleted = false));
		}
	}

	[Serializable]
	public class Charioteer : IComparable<Charioteer>
	{
		public PersonProfile profile;

		public string name;

		public Chance chance;

		public int predictedFinishPos;

		public int currFinishPos;

		public Vector2[] points = new Vector2[101];

		public ModelData mData;

		public int modelPoolIdx;

		public float pathDist;

		public int trackIdx;

		public Vector3 desiredPos;

		public Vector3 currentPos;

		public Vector3 velocity;

		public Quaternion desiredRot;

		public Quaternion currentRot;

		public float[] horseBounceT;

		public Incident incident;

		public int laps;

		public int CompareTo(Charioteer toCompare)
		{
			if (toCompare != null)
			{
				return trackIdx.CompareTo(toCompare.trackIdx);
			}
			return 1;
		}

		public float Evaluate(float t)
		{
			int num = Mathf.FloorToInt(t * 100f);
			float num2 = 0.01f;
			float t2 = (t - (float)num * num2) / num2;
			float y = points[num].y;
			float b = ((num >= points.Length - 1) ? y : points[num + 1].y);
			return Mathff.Lerp(y, b, t2);
		}
	}

	[Serializable]
	public struct ModelData
	{
		public Transform root;

		public Transform cart;

		public ParticleSystem pSystem;

		public Transform[] wheels;

		public Transform[] horses;

		public Sprite icon;

		public ObjectHighlighter highlighter;
	}

	public struct Group
	{
		public List<Charioteer> charioteers;

		public List<Track> paths;
	}

	public struct Chance
	{
		public float weight;

		public int percent;

		public int rewardAmt;

		public int goldCost;

		public bool isSponsored;

		public int finishPos;

		public float adjustedWeight;
	}

	public static float prevIncidentSfxTime = 0f;

	[ReadOnly]
	private Status status;

	public Building b;

	public float offsetAngle;

	public float variance = 0.175f;

	public float charioteerMoveSpeed = 1f;

	public float pathSpeed = 0.1f;

	public float pathSpeedMod = 0.2f;

	public float outGateSpeed = 1f;

	private float currOutGateSpeed;

	public float horseRotationSpeed = 15f;

	public float horseBounceSpeed = 1f;

	public float horseMinBounceSpeed = 0.25f;

	public float horseMaxBounceSpeed = 0.5f;

	public float swapDistThreshold = 0.035f;

	public const int STEPS = 100;

	public const int Racers = 4;

	public float accelerationStrength = 0.005f;

	public float damping = 0.95f;

	public float maxVelocity = 0.03f;

	public float minVelocity = 0.003f;

	public float spreadRangeMin = 0.00025f;

	public float spreadRangeMax = 0.0005f;

	public float minPlaceOffset = 0.003f;

	public float maxPlaceOffset = 0.005f;

	public float trackRadiusX = 1f;

	public float trackRadiusZ = 5f;

	public float trackSeperation = 0.2f;

	public float horseSampleOffset = 0.0001f;

	public int trackSampleRatio = 5;

	public float raceTime;

	public float raceSpeed = 0.01f;

	public float DesiredRaceDuration = 30f;

	public Transform[] camLocations;

	public OnStatusChange onStatusChange;

	public Transform[] confettiPositions;

	public Transform[] internalWallPoints;

	public Transform[] externalWallPoints;

	public List<Vector2> ellipses = new List<Vector2>();

	public List<Charioteer> charioteers;

	public List<Track> tracks;

	public int numOfGroups = 1;

	public float initialSeparation = 0.075f;

	public List<Group> groups = new List<Group>(18);

	public ModelData[] modelPool = new ModelData[6];

	public Transform[] startingPositions = new Transform[6];

	private Transform offset;

	private bool isAttractionJobsEnabled;

	public int randomizeTrackAfterFrame = 25;

	private int frameCount;

	private Color[] colors = new Color[7]
	{
		Color.green,
		Color.blue,
		Color.magenta,
		Color.red,
		Color.yellow,
		Color.gray,
		Color.white
	};

	private Timer confettiTimer = new Timer(1f);

	public ArrayExt<Chance> currChances = new ArrayExt<Chance>(32);

	public ArrayExt<int> scratchIdx = new ArrayExt<int>(4);

	public ArrayExtRef<Charioteer> scratchCharioteers = new ArrayExtRef<Charioteer>(8);

	public float oddWeightBias = 1f;

	private static ArrayExt<int> trackIdx = new ArrayExt<int>(4);

	private static ArrayExt<int> modelIdx = new ArrayExt<int>(4);

	public Status GetStatus()
	{
		return status;
	}

	public Charioteer GetWinningRacer()
	{
		float num = float.MinValue;
		Charioteer result = null;
		for (int i = 0; i < charioteers.Count; i++)
		{
			if (charioteers[i].pathDist > num)
			{
				num = charioteers[i].pathDist;
				result = charioteers[i];
			}
		}
		return result;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		offset = base.transform.GetChild(0);
		charioteers = new List<Charioteer>(4);
		tracks = new List<Track>(4);
		for (int i = 0; i < 4; i++)
		{
			charioteers.Add(new Charioteer());
			charioteers[i].modelPoolIdx = i;
			ModelData modelData = modelPool[i];
			List<MeshRenderer> list = new List<MeshRenderer>(12);
			for (int j = 0; j < modelData.horses.Length; j++)
			{
				Transform transform = modelData.horses[j];
				list.AddRange(transform.GetComponentsInChildren<MeshRenderer>());
			}
			for (int k = 0; k < modelData.wheels.Length; k++)
			{
				Transform transform2 = modelData.wheels[k];
				list.AddRange(transform2.GetComponentsInChildren<MeshRenderer>());
			}
			list.AddRange(modelData.cart.GetComponentsInChildren<MeshRenderer>());
			modelData.highlighter = ObjectHighlighter.SetupOutlines(gameObject, list, null);
			modelPool[i] = modelData;
			charioteers[i].horseBounceT = new float[modelPool[i].horses.Length];
			for (int l = 0; l < charioteers[i].horseBounceT.Length; l++)
			{
				charioteers[i].horseBounceT[l] = SRand.Range(0f, 100f);
			}
			tracks.Add(new Track(trackRadiusX + (float)i * trackSeperation, trackRadiusZ + (float)i * trackSeperation));
		}
		SetStatus(Status.Resting);
		for (int m = 0; m < modelPool.Length; m++)
		{
			ModelData modelData2 = modelPool[m];
			Util.SetActive(modelData2.root.gameObject, active: false);
			modelData2.pSystem.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
		}
		Building building = b;
		building.onJobAssignmentUpdated = (Building.OnJobAssignmentUpdated)Delegate.Combine(building.onJobAssignmentUpdated, new Building.OnJobAssignmentUpdated(OnJobAssignmentUpdated));
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (b.IsBuilt() && !undo)
		{
			for (int i = 0; i < modelPool.Length && i < 4; i++)
			{
				Util.SetActive(modelPool[i].root.gameObject, active: true);
			}
		}
	}

	private void OnBuilt()
	{
		for (int i = 0; i < modelPool.Length && i < 4; i++)
		{
			Util.SetActive(modelPool[i].root.gameObject, active: true);
		}
	}

	private void ShowVisuals()
	{
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				IdleJob idleJob = new IdleJob(b, IdleJob.IdleBehavior.Celebrate);
				idleJob.ManualAssignment = true;
				b.SetAndAddJob(i, idleJob);
			}
		}
		isAttractionJobsEnabled = false;
		OnJobAssignmentUpdated(null, isAssigned: false);
	}

	private void OnJobAssignmentUpdated(Villager v, bool isAssigned)
	{
		if (v != null && v.job.idleJob)
		{
			return;
		}
		if (!isAttractionJobsEnabled && b.GetWorkerPercent() >= 1f)
		{
			for (int i = 0; i < b.attractionJobs.Count; i++)
			{
				b.attractionJobs[i].ManualAssignment = false;
			}
			isAttractionJobsEnabled = true;
		}
		else
		{
			if (!isAttractionJobsEnabled || !(b.GetWorkerPercent() < 1f))
			{
				return;
			}
			for (int j = 0; j < b.attractionJobs.Count; j++)
			{
				Job job = b.attractionJobs[j];
				job.ManualAssignment = true;
				if (job.HasEmployee())
				{
					job.ReleaseEmployee();
				}
			}
			isAttractionJobsEnabled = false;
		}
	}

	public void SetStatus(Status st)
	{
		switch (st)
		{
		case Status.StartRace:
		{
			raceTime = 0f;
			currOutGateSpeed = 0f;
			GenerateCharioteerFinishingPositions();
			GenerateCharioteerPathCurve();
			for (int k = 0; k < charioteers.Count; k++)
			{
				ParticleSystem pSystem2 = modelPool[charioteers[k].modelPoolIdx].pSystem;
				ParticleSystem.MainModule main2 = pSystem2.main;
				main2.useUnscaledTime = false;
				pSystem2.Play();
			}
			break;
		}
		case Status.Racing:
			raceTime = 0f;
			break;
		case Status.ReturnToGate:
			raceTime = 0f;
			break;
		case Status.BetStartRace:
		{
			raceTime = 0f;
			currOutGateSpeed = 0f;
			GenerateCharioteerFinishingPositions();
			GenerateCharioteerPathCurve();
			for (int j = 0; j < charioteers.Count; j++)
			{
				ParticleSystem pSystem = modelPool[charioteers[j].modelPoolIdx].pSystem;
				ParticleSystem.MainModule main = pSystem.main;
				main.useUnscaledTime = true;
				pSystem.Play();
			}
			break;
		}
		case Status.BetRacing:
			raceTime = 0f;
			break;
		case Status.Resting:
		{
			CollectRandomOddsAndNames();
			for (int i = 0; i < charioteers.Count; i++)
			{
				Charioteer charioteer = charioteers[i];
				Transform transform = startingPositions[charioteer.trackIdx];
				ModelData modelData = modelPool[charioteer.modelPoolIdx];
				charioteer.desiredPos = (charioteer.currentPos = transform.position);
				modelData.root.position = transform.position;
				modelData.root.rotation = transform.rotation;
				modelData.cart.localRotation = Quaternion.identity;
				modelData.cart.localPosition = new Vector3(0f, 0.08f, 0f);
				modelData.horses[0].localRotation = Quaternion.identity;
				modelData.horses[1].localRotation = Quaternion.identity;
				modelPool[charioteers[i].modelPoolIdx].pSystem.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
			}
			break;
		}
		case Status.BetFinished:
			ChariotRaceTrackUI.inst.SetStatus(3);
			break;
		}
		status = st;
		onStatusChange?.Invoke(st);
	}

	private Color GetColor(int idx)
	{
		return colors[idx % colors.Length];
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!b.IsBuilt())
		{
			return;
		}
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		switch (status)
		{
		case Status.Resting:
			if (b.DuringWorkHours(0f) && b.GetWorkerPercent() >= 1f && !GameUI.inst.IsChariotRaceModeActive())
			{
				SetStatus(Status.StartRace);
			}
			break;
		case Status.StartRace:
		case Status.BetStartRace:
		{
			float num = ((status == Status.BetStartRace) ? unscaledDeltaTime : dt);
			raceTime = Mathff.Clamp01(raceTime + num * currOutGateSpeed);
			currOutGateSpeed = Mathf.MoveTowards(currOutGateSpeed, outGateSpeed, num);
			for (int n = 0; n < charioteers.Count; n++)
			{
				Charioteer charioteer4 = charioteers[n];
				Transform obj = startingPositions[charioteer4.trackIdx];
				ModelData modelData3 = modelPool[charioteer4.modelPoolIdx];
				Track track4 = tracks[charioteer4.trackIdx];
				GetPathPosition(track4, out var pos7, out var dir5, 0f);
				pos7 = offset.TransformPoint(pos7);
				dir5 = offset.TransformDirection(dir5);
				Vector3 currentPos2 = charioteer4.currentPos;
				Vector3 forward2 = Vector3.Lerp(obj.forward, dir5, raceTime);
				Vector3 desiredPos2 = Vector3.Lerp(obj.position, pos7, raceTime);
				charioteer4.currentPos = (charioteer4.desiredPos = desiredPos2);
				charioteer4.currentRot = (charioteer4.desiredRot = Quaternion.LookRotation(dir5));
				modelData3.root.SetPositionAndRotation(charioteer4.currentPos, Quaternion.LookRotation(forward2));
				charioteer4.velocity = charioteer4.currentPos - currentPos2;
				UpdateWheelsAndHorseBounce(charioteer4, charioteer4.velocity.magnitude);
			}
			if (raceTime >= 1f)
			{
				if (status == Status.BetStartRace)
				{
					SetStatus(Status.BetRacing);
				}
				else
				{
					SetStatus(Status.Racing);
				}
			}
			break;
		}
		case Status.Racing:
		case Status.BetRacing:
		{
			float num = ((status == Status.BetRacing) ? unscaledDeltaTime : dt);
			Mathff.Clamp01(raceTime / DesiredRaceDuration);
			raceTime += num;
			float num2 = Mathff.Clamp01(raceTime / DesiredRaceDuration);
			frameCount = (frameCount + 1) % randomizeTrackAfterFrame;
			for (int j = 0; j < tracks.Count; j++)
			{
				Track track2 = tracks[j];
				if (frameCount == 0)
				{
					track2.GenerateVariance(variance);
				}
				float t = (float)frameCount / (float)randomizeTrackAfterFrame;
				track2.varianceX = Mathf.Lerp(track2.prevVarianceX, track2.desiredVarianceX, t);
				track2.varianceZ = Mathf.Lerp(track2.prevVarianceZ, track2.desiredVarianceZ, t);
				DebugEx.DrawEllipse(base.transform.GetChild(0), track2.radiusX + track2.varianceX, track2.radiusZ + track2.varianceZ, GetColor(j), 32);
			}
			for (int k = 0; k < charioteers.Count; k++)
			{
				Charioteer charioteer2 = charioteers[k];
				ModelData modelData2 = modelPool[charioteer2.modelPoolIdx];
				Track track3 = tracks[charioteer2.trackIdx];
				float t2 = num2;
				float num3 = num;
				if (charioteer2.incident.isActive && num2 >= charioteer2.incident.t)
				{
					if (!charioteer2.incident.hasTriggered)
					{
						if (status == Status.BetRacing && Time.unscaledTime - prevIncidentSfxTime > 3.5f)
						{
							if (!ChariotRaceTrackUI.inst.IsFadingToEnd())
							{
								RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_cheer", b.Center());
								RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_shock", b.Center());
							}
							prevIncidentSfxTime = Time.unscaledTime;
						}
						if (charioteer2.incident.type == 0)
						{
							Util.SetActive(modelData2.wheels[0].gameObject, active: false);
							modelData2.pSystem.Stop();
							if (status == Status.BetRacing)
							{
								RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_cart_crash_wheel_break", charioteer2.currentPos);
							}
							EffectsMan.inst.WoodHitSmallEffect.CreateAndPlay(modelData2.wheels[0].position).UseRealtime = true;
							modelData2.cart.localEulerAngles = new Vector3(10f, 0f, 20f);
						}
						else if (charioteer2.incident.type == 1)
						{
							if (status == Status.BetRacing && ChariotRaceTrackUI.inst.IsFadingToEnd())
							{
								float num4 = (charioteer2.pathDist = charioteer2.Evaluate(charioteer2.incident.t) * (float)trackSampleRatio);
								GetPathPosition(track3, out var pos2, out var dir2, num4);
								UpdateChariotPosRotVel(charioteer2, pos2, dir2, num3 * 100f);
								GetPathPosition(track3, out var pos3, (num4 + horseSampleOffset) % 1f);
								RotateHorses(charioteer2, offset.TransformPoint(pos3), num3 * 100f);
								charioteer2.velocity *= 10f;
							}
							float t3 = charioteer2.Evaluate(charioteer2.incident.t + 0.05f) * (float)trackSampleRatio;
							GetPathPosition(track3, out var pos4, out var dir3, t3);
							Vector3 p = offset.TransformPoint(pos4);
							p.y = 0f;
							Vector3 input = offset.TransformDirection(dir3);
							input.y = 0f;
							input.NonAllocateNormalize();
							float num5 = float.MaxValue;
							Vector3 vector = default;
							Transform[] array = externalWallPoints;
							if (charioteer2.trackIdx >= 1 && SRand.CoinFlip())
							{
								array = internalWallPoints;
							}
							for (int l = 0; l < array.Length; l++)
							{
								Vector3 position = array[l].position;
								position.y = 0f;
								Vector3 position2 = array[(l + 1) % array.Length].position;
								position2.y = 0f;
								Vector3 vector2 = Mathff.ClosestPointOnSegment(position, position2, p);
								float num6 = Mathff.DistSqrd(vector2, p);
								if (num6 < num5)
								{
									vector = vector2;
									num5 = num6;
								}
							}
							float y = Vector3.Cross(input, vector).y;
							Util.SetActive(modelData2.wheels[(!(y < 0f)) ? 1u : 0u].gameObject, active: false);
							if (status == Status.BetRacing)
							{
								RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_cart_crash_wheel_break", charioteer2.currentPos);
								RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_cart_crash_stall", charioteer2.currentPos);
							}
							OneOffEffect oneOffEffect = EffectsMan.inst.WoodHitSmallEffect.CreateAndPlay(modelData2.wheels[(!(y < 0f)) ? 1u : 0u].position);
							if (y < 0f)
							{
								modelData2.cart.localEulerAngles = new Vector3(10f, 0f, 20f);
							}
							else
							{
								modelData2.cart.localEulerAngles = new Vector3(-10f, 0f, -20f);
							}
							oneOffEffect.UseRealtime = true;
							vector.y = charioteer2.currentPos.y;
							if (array == externalWallPoints)
							{
								Vector3 input2 = charioteer2.currentPos - vector;
								input2.NonAllocateNormalize();
								vector += input2 * 0.4f;
							}
							charioteer2.incident.targetPos = vector;
						}
						charioteer2.incident.hasTriggered = true;
					}
					if (charioteer2.incident.type == 0)
					{
						float num7 = 1f - Mathff.Clamp01((num2 - charioteer2.incident.t) / 0.075f);
						num3 = num * (num7 * num7);
						t2 = Mathff.Min(num2, charioteer2.incident.t + 0.075f);
						if (num2 >= charioteer2.incident.t + 0.075f)
						{
							charioteer2.incident.hasCompleted = true;
						}
					}
				}
				if (charioteer2.incident.isActive && charioteer2.incident.type == 1 && charioteer2.incident.hasTriggered)
				{
					Draw.WireSphere(charioteer2.incident.targetPos, 0.1f);
					if (charioteer2.incident.hasCompleted)
					{
						continue;
					}
					Vector3 input3 = charioteer2.incident.targetPos - charioteer2.currentPos;
					input3.NonAllocateNormalize();
					bool flag = Mathff.MoveTowards(charioteer2.currentPos, charioteer2.incident.targetPos, charioteer2.velocity.magnitude, out var _, out var newPos);
					Quaternion currentRot = Quaternion.Lerp(charioteer2.currentRot, Quaternion.LookRotation(input3), num * charioteerMoveSpeed);
					charioteer2.currentPos = newPos;
					charioteer2.currentRot = currentRot;
					modelData2.root.SetPositionAndRotation(charioteer2.currentPos, charioteer2.currentRot);
					UpdateWheelsAndHorseBounce(charioteer2, charioteer2.velocity.magnitude);
					RotateHorses(charioteer2, charioteer2.incident.targetPos + input3, num3);
					if (status != Status.BetRacing || !ChariotRaceTrackUI.inst.IsFadingToEnd())
					{
						for (int m = 0; m < charioteers.Count; m++)
						{
							Charioteer charioteer3 = charioteers[m];
							if (charioteer3 != charioteer2 && !charioteer3.incident.isActive && Mathff.DistSqrd(charioteer3.currentPos, newPos) < 0.05f && SRand.CoinFlip())
							{
								charioteer3.incident.isActive = true;
								charioteer3.incident.type = 1;
								charioteer3.incident.t = num2;
							}
						}
					}
					if (flag)
					{
						Util.SetActive(modelData2.wheels[0].gameObject, active: false);
						Util.SetActive(modelData2.wheels[1].gameObject, active: false);
						modelData2.cart.localPosition = new Vector3(0f, 0.05f, 0f);
						modelData2.cart.localRotation = Quaternion.identity;
						if (status == Status.BetRacing)
						{
							RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_cart_crash", charioteer2.currentPos);
						}
						EffectsMan.inst.WoodHitEffect.CreateAndPlay(charioteer2.currentPos).UseRealtime = true;
						charioteer2.incident.hasCompleted = true;
					}
				}
				else
				{
					float num8 = (charioteer2.pathDist = charioteer2.Evaluate(t2) * (float)trackSampleRatio);
					GetPathPosition(track3, out var pos5, out var dir4, num8);
					UpdateChariotPosRotVel(charioteer2, pos5, dir4, num3);
					UpdateWheelsAndHorseBounce(charioteer2, charioteer2.velocity.magnitude);
					GetPathPosition(track3, out var pos6, (num8 + horseSampleOffset) % 1f);
					RotateHorses(charioteer2, offset.TransformPoint(pos6), num3);
				}
			}
			if (num2 >= 1f)
			{
				if (status == Status.BetRacing)
				{
					SetStatus(Status.BetFinished);
				}
				else
				{
					SetStatus(Status.Finished);
				}
			}
			break;
		}
		case Status.Finished:
		case Status.BetFinished:
		{
			frameCount = (frameCount + 1) % randomizeTrackAfterFrame;
			float num = ((status == Status.BetFinished) ? unscaledDeltaTime : dt);
			if (confettiTimer.Update(unscaledDeltaTime))
			{
				Vector3 position3 = confettiPositions[SRand.Range(0, confettiPositions.Length)].position;
				EffectsMan.inst.ConfettiUSEffect.CreateAndPlay(position3);
			}
			for (int num9 = 0; num9 < tracks.Count; num9++)
			{
				Track track5 = tracks[num9];
				if (frameCount == 0)
				{
					track5.GenerateVariance(variance);
				}
				float t4 = (float)frameCount / (float)randomizeTrackAfterFrame;
				track5.varianceX = Mathf.Lerp(track5.prevVarianceX, track5.desiredVarianceX, t4);
				track5.varianceZ = Mathf.Lerp(track5.prevVarianceZ, track5.desiredVarianceZ, t4);
				DebugEx.DrawEllipse(base.transform.GetChild(0), track5.radiusX + track5.varianceX, track5.radiusZ + track5.varianceZ, GetColor(num9), 32);
			}
			for (int num10 = 0; num10 < charioteers.Count; num10++)
			{
				Charioteer charioteer5 = charioteers[num10];
				_ = ref modelPool[charioteer5.modelPoolIdx];
				Track track6 = tracks[charioteer5.trackIdx];
				if (!charioteer5.incident.isActive)
				{
					float num11 = maxVelocity * 0.9f;
					if (charioteer5.currFinishPos == 0 && status != Status.Finished)
					{
						num11 = maxVelocity;
					}
					float num12 = num * raceSpeed / 0.0033333334f * num11;
					float num13 = charioteer5.pathDist % 1f;
					charioteer5.pathDist += num12;
					float num14 = charioteer5.pathDist % 1f;
					if (status == Status.Finished && (!b.DuringWorkHours(0f) || b.GetWorkerPercent() < 1f) && num13 <= 0.5f && num14 >= 0.5f)
					{
						SetStatus(Status.ReturnToGate);
					}
					GetPathPosition(track6, out var pos8, out var dir6, num14);
					UpdateChariotPosRotVel(charioteer5, pos8, dir6, num);
					UpdateWheelsAndHorseBounce(charioteer5, charioteer5.velocity.magnitude);
					GetPathPosition(track6, out var pos9, (num14 + horseSampleOffset) % 1f);
					RotateHorses(charioteer5, offset.TransformPoint(pos9), num);
				}
			}
			break;
		}
		case Status.ReturnToGate:
		{
			raceTime = Mathff.Clamp01(raceTime + dt * (outGateSpeed * 0.75f));
			for (int i = 0; i < charioteers.Count; i++)
			{
				Charioteer charioteer = charioteers[i];
				Transform transform = startingPositions[charioteer.trackIdx + 4];
				ModelData modelData = modelPool[charioteer.modelPoolIdx];
				Track track = tracks[charioteer.trackIdx];
				GetPathPosition(track, out var pos, out var dir, charioteer.pathDist % 1f);
				pos = offset.TransformPoint(pos);
				dir = offset.TransformDirection(dir);
				Vector3 currentPos = charioteer.currentPos;
				Vector3 forward = Vector3.Lerp(dir, transform.forward, raceTime);
				Vector3 desiredPos = Vector3.Lerp(pos, transform.position, raceTime);
				charioteer.currentPos = (charioteer.desiredPos = desiredPos);
				charioteer.currentRot = (charioteer.desiredRot = Quaternion.LookRotation(dir));
				modelData.root.SetPositionAndRotation(charioteer.currentPos, Quaternion.LookRotation(forward));
				charioteer.velocity = charioteer.currentPos - currentPos;
				UpdateWheelsAndHorseBounce(charioteer, charioteer.velocity.magnitude);
			}
			if (raceTime >= 1f)
			{
				SetStatus(Status.Resting);
			}
			break;
		}
		}
	}

	public void UpdateChariotPosRotVel(Charioteer charioteer, Vector3 newPos, Vector3 newDir, float delta)
	{
		ModelData modelData = modelPool[charioteer.modelPoolIdx];
		charioteer.desiredPos = offset.TransformPoint(newPos);
		charioteer.desiredRot = Quaternion.LookRotation(offset.TransformDirection(newDir));
		Vector3 currentPos = charioteer.currentPos;
		charioteer.currentPos = Vector3.Lerp(charioteer.currentPos, charioteer.desiredPos, delta * charioteerMoveSpeed);
		charioteer.currentRot = Quaternion.Lerp(charioteer.currentRot, charioteer.desiredRot, delta * charioteerMoveSpeed);
		modelData.root.SetPositionAndRotation(charioteer.currentPos, charioteer.currentRot);
		DebugEx.DrawCircleXZ(charioteer.desiredPos, 0.1f, Color.red);
		charioteer.velocity = charioteer.currentPos - currentPos;
	}

	public void UpdateWheelsAndHorseBounce(Charioteer charioteer, float velocity)
	{
		ModelData modelData = modelPool[charioteer.modelPoolIdx];
		float xAngle = velocity / 0.1f * 57.29578f;
		Transform[] wheels = modelData.wheels;
		for (int i = 0; i < wheels.Length; i++)
		{
			wheels[i].Rotate(xAngle, 0f, 0f);
		}
		Transform[] horses = modelData.horses;
		for (int j = 0; j < horses.Length; j++)
		{
			Transform child = horses[j].GetChild(0);
			charioteer.horseBounceT[j] += Mathff.Clamp(velocity * horseBounceSpeed, 0f, horseMaxBounceSpeed);
			float num = Mathff.Abs(Mathf.Sin(charioteer.horseBounceT[j]));
			child.localRotation = Quaternion.Euler(-15f + num * 30f, 0f, 0f);
		}
	}

	public void RotateHorses(Charioteer charioteer, Vector3 fwdPos, float tempDelta)
	{
		DebugEx.DrawCircleXZ(fwdPos, 0.1f, Color.yellow);
		Transform[] horses = modelPool[charioteer.modelPoolIdx].horses;
		foreach (Transform transform in horses)
		{
			Vector3 forward = fwdPos - transform.position;
			transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.LookRotation(forward), tempDelta * horseRotationSpeed);
		}
	}

	public void GetPathPosition(Track track, out Vector3 pos, out Vector3 dir, float t)
	{
		float f = t * 2f * MathF.PI + offsetAngle * (MathF.PI / 180f);
		float num = track.radiusX + track.varianceX;
		float num2 = track.radiusZ + track.varianceZ;
		float x = (0f - num) * Mathf.Sin(f);
		float z = num2 * Mathf.Cos(f);
		dir = new Vector3(x, 0f, z).normalized;
		pos.x = num * Mathf.Cos(f);
		pos.y = 0f;
		pos.z = num2 * Mathf.Sin(f);
	}

	public void GetPathPosition(Track track, out Vector3 pos, float t)
	{
		float f = t * 2f * MathF.PI + offsetAngle * (MathF.PI / 180f);
		float num = track.radiusX + track.varianceX;
		float num2 = track.radiusZ + track.varianceZ;
		pos.x = num * Mathf.Cos(f);
		pos.y = 0f;
		pos.z = num2 * Mathf.Sin(f);
	}

	public void GetPathDirection(Track track, out Vector3 dir, float t)
	{
		float f = t * 2f * MathF.PI + offsetAngle * (MathF.PI / 180f);
		float x = (0f - track.radiusX) * Mathf.Sin(f);
		float z = track.radiusZ * Mathf.Cos(f);
		dir = new Vector3(x, 0f, z).normalized;
	}

	public void CollectRandomOddsAndNames()
	{
		trackIdx.ClearFast();
		modelIdx.ClearFast();
		for (int i = 0; i < 4; i++)
		{
			trackIdx.Add(i);
			modelIdx.Add(i);
		}
		currChances.ClearFast();
		int num = 100;
		int num2 = 0;
		for (int num3 = 3; num3 >= 0; num3--)
		{
			charioteers[num3].profile = PersonProfile.GetRandomProfile(male: true, 0);
			charioteers[num3].trackIdx = trackIdx.PopIndex(trackIdx.RandomIdx());
			charioteers[num3].modelPoolIdx = modelIdx.PopIndex(modelIdx.RandomIdx());
			Util.SetActive(modelPool[charioteers[num3].modelPoolIdx].wheels[0].gameObject, active: true);
			Util.SetActive(modelPool[charioteers[num3].modelPoolIdx].wheels[1].gameObject, active: true);
			int num4 = num / 5 - num3;
			int num5 = ((num3 == 0) ? num4 : SRand.Range(1, num4)) * 5;
			num -= num5;
			int num6 = Mathff.Max(1, Mathf.CeilToInt(Mathf.Pow(1f - (float)num5 / 100f, 2f) * 9f));
			Chance chance = new Chance
			{
				percent = num5,
				weight = (float)num5 / 100f,
				rewardAmt = num6 + SRand.Range(0, 1),
				goldCost = 50 + num6 * 75 + SRand.Range(0, 5)
			};
			charioteers[num3].chance = chance;
			if (num2 < 3 && SRand.Range(0, 100) <= 5)
			{
				Incident incident = charioteers[num3].incident;
				incident.Reset();
				if (SRand.CoinFlip())
				{
					incident.isActive = true;
					incident.type = 1;
					incident.t = SRand.Range(0.15f, 0.85f);
				}
				else
				{
					incident.isActive = true;
					incident.type = 0;
					incident.t = SRand.Range(0.15f, 0.9f);
				}
				charioteers[num3].incident = incident;
				num2++;
			}
			else
			{
				charioteers[num3].incident.Reset();
			}
		}
	}

	public void GenerateCharioteerFinishingPositions()
	{
		scratchCharioteers.ClearFast();
		scratchCharioteers.AddRange(charioteers);
		for (int i = 0; i < 4; i++)
		{
			RandomlySelectChance(scratchCharioteers).predictedFinishPos = i;
		}
	}

	private Charioteer RandomlySelectChance(ArrayExtRef<Charioteer> charioteer)
	{
		float num = 0f;
		float num2 = 1f;
		float num3 = 0f;
		for (int i = 0; i < charioteer.Count; i++)
		{
			Chance chance = charioteer.data[i].chance;
			if (charioteer.data[i].incident.isActive)
			{
				chance.adjustedWeight = 0f;
			}
			else if (chance.isSponsored)
			{
				chance.adjustedWeight = chance.weight + (float)Mathf.FloorToInt((1f - chance.weight) / 4f / 0.05f) * 0.05f;
				num2 = 1f - chance.adjustedWeight;
				num3 = chance.adjustedWeight;
			}
			else
			{
				chance.adjustedWeight = chance.weight;
				num += chance.weight;
			}
			charioteer.data[i].chance = chance;
		}
		for (int j = 0; j < charioteer.Count; j++)
		{
			Chance chance2 = charioteer.data[j].chance;
			if (!chance2.isSponsored)
			{
				chance2.adjustedWeight = chance2.weight / num * num2;
				num3 += chance2.adjustedWeight;
				charioteer.data[j].chance = chance2;
			}
		}
		float num4 = 0f;
		float num5 = SRand.value * num3;
		for (int k = 0; k < charioteer.Count; k++)
		{
			num4 += charioteer.data[k].chance.adjustedWeight;
			if (num5 <= num4)
			{
				return charioteer.PopIndex(k);
			}
		}
		return charioteer.PopLast();
	}

	public void GenerateCharioteerPathCurve()
	{
		float num = 0f;
		int num2 = SRand.Range(0, charioteers.Count);
		scratchCharioteers.ClearFast();
		for (int i = 0; i < charioteers.Count; i++)
		{
			int predictedFinishPos = charioteers[i].predictedFinishPos;
			int index = 0;
			for (int j = 0; j < scratchCharioteers.Count && scratchCharioteers.data[j].predictedFinishPos <= predictedFinishPos; j++)
			{
				index = j + 1;
			}
			scratchCharioteers.Insert(index, charioteers[i]);
		}
		for (int k = 0; k < scratchCharioteers.Count; k++)
		{
			Charioteer charioteer = scratchCharioteers.data[k];
			float num3 = 0f;
			float num4 = 0f;
			float num5 = (num2 + k) % scratchCharioteers.Count;
			for (int l = 0; l <= 100; l++)
			{
				float x = (float)l / 100f;
				float num6 = (SRand.Range(0f, 1f) * 2f - 1f) * accelerationStrength;
				if (l == 0)
				{
					num4 += ((float)(scratchCharioteers.Count - 1) - num5) * SRand.Range(spreadRangeMin, spreadRangeMax);
				}
				num4 += num6;
				num4 = Mathff.Max(num4, minVelocity);
				num4 = Mathff.Min(num4 * damping, maxVelocity);
				num3 += num4;
				charioteer.points[l] = new Vector2(x, num3);
			}
			if (k != 0)
			{
				num += SRand.Range(minPlaceOffset, maxPlaceOffset);
			}
			float num7 = (1f - num) / charioteer.points[100].y;
			for (int m = 0; m <= 100; m++)
			{
				Vector2 vector = charioteer.points[m];
				vector.y *= num7;
				charioteer.points[m] = vector;
			}
		}
	}

	public string GetError()
	{
		return "";
	}

	public bool ShowCustomButton()
	{
		return true;
	}

	public bool CustomButtonInteractable()
	{
		return true;
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
