using System;
using System.Collections;
using System.Collections.Generic;
using Assets.Code;
using FMODUnity;
using PixelCrushers.DialogueSystem;
using UnityEngine;

public class GodManager : MonoBehaviour
{
	[Serializable]
	public class GodManagerSaveData : SaveClass<GodManager, GodManagerSaveData>
	{
		private struct GodMessageData
		{
			public int godIdx;

			public float timeActive;

			public GodMessage.MessageType messageType;

			public SerializableVector3 pos;

			public ResourceAmount offeringAmt;
		}

		private int[] currTasks;

		private int[] nextTasks;

		private int[] currTasksComplete;

		private int tasksComplete;

		private bool playerSawIntro;

		private float[] godAngerCooldown;

		private SerializableDictionary<string, bool> hintMap;

		private int[] festivalCount;

		private bool disableGodsAppearance;

		private float[] spellCooldowns;

		private int[] godEscalation;

		private List<GodMessageData> messages;

		public override GodManagerSaveData Pack(GodManager obj)
		{
			currTasks = obj.currTask;
			nextTasks = obj.nextTask;
			currTasksComplete = new int[numGods];
			godAngerCooldown = obj.godAngerCooldown;
			hintMap = new SerializableDictionary<string, bool>(obj.hintMap);
			for (int i = 0; i < currTasks.Length; i++)
			{
				if (currTasks[i] == -1)
				{
					currTasksComplete[i] = -1;
				}
				else
				{
					currTasksComplete[i] = obj.tasks[i][currTasks[i]].tasksComplete;
				}
			}
			godEscalation = obj.godEscalation;
			tasksComplete = obj.tasksComplete;
			playerSawIntro = obj.playerSawIntro;
			festivalCount = obj.festivalCount;
			spellCooldowns = new float[numGods];
			for (int j = 0; j < obj.spells.Length; j++)
			{
				if (obj.spells[j] != null)
				{
					spellCooldowns[j] = obj.spells[j].cooldown;
				}
			}
			disableGodsAppearance = obj.disableGodsAppearance;
			messages = new List<GodMessageData>(obj.godAnger.Count);
			for (int k = 0; k < obj.godAnger.Count; k++)
			{
				if (obj.godAnger[k].status == GodMessage.Status.Active)
				{
					GodMessageData item = new GodMessageData
					{
						godIdx = obj.godAnger[k].godIdx,
						timeActive = obj.godAnger[k].timeActive,
						messageType = obj.godAnger[k].messageType,
						pos = obj.godAnger[k].display.transform.position,
						offeringAmt = ((obj.godAnger[k].offeringAmt != null) ? new ResourceAmount(obj.godAnger[k].offeringAmt) : null)
					};
					messages.Add(item);
				}
			}
			return this;
		}

		public override GodManager Unpack(GodManager obj)
		{
			obj.tasksComplete = tasksComplete;
			obj.playerSawIntro = playerSawIntro;
			if (hintMap != null)
			{
				obj.hintMap = hintMap;
			}
			for (int i = 0; i < obj.currTask.Length && i < currTasks.Length; i++)
			{
				obj.currTask[i] = currTasks[i];
				if (obj.currTask[i] != -1)
				{
					if (currTasksComplete != null)
					{
						obj.tasks[i][currTasks[i]].tasksComplete = currTasksComplete[i];
					}
					obj.tasks[i][currTasks[i]].AcceptTask();
				}
			}
			for (int j = 0; j < obj.nextTask.Length && j < nextTasks.Length; j++)
			{
				obj.nextTask[j] = nextTasks[j];
			}
			if (godAngerCooldown != null)
			{
				for (int k = 0; k < obj.godAngerCooldown.Length && k < godAngerCooldown.Length; k++)
				{
					obj.godAngerCooldown[k] = godAngerCooldown[k];
				}
			}
			if (godEscalation != null)
			{
				for (int l = 0; l < obj.godEscalation.Length && l < godEscalation.Length; l++)
				{
					obj.godEscalation[l] = godEscalation[l];
				}
			}
			if (festivalCount != null)
			{
				for (int m = 0; m < obj.festivalCount.Length && m < festivalCount.Length; m++)
				{
					obj.festivalCount[m] = festivalCount[m];
				}
			}
			if (spellCooldowns != null)
			{
				for (int n = 0; n < spellCooldowns.Length; n++)
				{
					if (obj.spells[n] != null)
					{
						obj.spells[n].cooldown = spellCooldowns[n];
					}
				}
			}
			obj.disableGodsAppearance = disableGodsAppearance;
			if (messages != null)
			{
				for (int num = 0; num < messages.Count; num++)
				{
					GodMessageData godMessageData = messages[num];
					GodMessage newAnger = new GodMessage(godMessageData.godIdx, godMessageData.pos);
					newAnger.issueButton.onClick = () =>
					{
						obj.ShowMessage(newAnger);
					};
					newAnger.offeringAmt = godMessageData.offeringAmt;
					newAnger.timeActive = godMessageData.timeActive;
					newAnger.messageType = godMessageData.messageType;
					obj.godAnger.Add(newAnger);
				}
			}
			obj.doFirstUpdateAfterLoad = true;
			return obj;
		}
	}

	public class GodMessage
	{
		public enum MessageType
		{
			Warning,
			Damage,
			Message
		}

		public enum Status
		{
			Active,
			Disappearing
		}

		public int godIdx;

		public GodDisplayIndividual display;

		public InWorldExclamation issueButton;

		public float timeActive;

		public bool addressed;

		public ResourceAmount offeringAmt;

		private int maxPlagueAmt;

		private Timer punishmentTimer = new Timer(1f);

		public MessageType messageType;

		public Status status;

		public GodMessage(int god, Vector3 showPos)
		{
			godIdx = god;
			display = UnityEngine.Object.Instantiate(GodUI.inst.godDisplayIndividualPrefab).GetComponent<GodDisplayIndividual>();
			display.ShowAt(showPos, godIdx);
			issueButton = UnityEngine.Object.Instantiate(World.inst.issuePrefab);
			issueButton.transform.SetParent(display.transform);
			issueButton.transform.localPosition = new Vector3(0f, 4.25f, 0f);
			issueButton.transform.localScale = new Vector3(0.75f, 0.75f, 0.75f);
			issueButton.gameObject.SetActive(value: true);
			GodDisplayIndividual godDisplayIndividual = display;
			godDisplayIndividual.onClick = (GodDisplayIndividual.OnClickDelegate)Delegate.Combine(godDisplayIndividual.onClick, (GodDisplayIndividual.OnClickDelegate)(() =>
			{
				issueButton.onClick();
			}));
			Cell cellDataClamped = World.inst.GetCellDataClamped(showPos);
			int count = World.inst.GetVillagersForLandMass(cellDataClamped.landMassIdx).Count;
			if (godIdx == 3)
			{
				punishmentTimer.Duration = Mathf.Lerp(3.5f, 2f, (float)(count - 100) / 1500f);
				maxPlagueAmt = Player.inst.GetMaxInfectionsAtStart(cellDataClamped.landMassIdx);
			}
			else
			{
				punishmentTimer.Duration = Mathf.Lerp(3f, 1f, (float)(count - 100) / 1500f);
			}
		}

		public void TransitionToDisappearing()
		{
			status = Status.Disappearing;
			display.Hide();
		}

		public bool Tick(float dt)
		{
			if ((GodUI.inst.Visible() && GodUI.inst.temple != null) || GameUI.inst.InModal())
			{
				issueButton.transform.localScale = Vector3.zero;
				display.Hide();
			}
			else
			{
				issueButton.transform.localScale = Vector3.one;
				if (status != Status.Disappearing)
				{
					display.ShowAt(display.transform.position, godIdx);
				}
			}
			switch (status)
			{
			case Status.Active:
			{
				timeActive += dt;
				int num = 60;
				if (messageType == MessageType.Damage)
				{
					float num2 = 1f;
					switch (DifficultyManager.inst.currOption.godWrath)
					{
					case 2:
						num2 *= 1.2f;
						break;
					case 3:
						num2 *= 1.4f;
						break;
					case 4:
						num2 *= 1.6f;
						break;
					}
					int count = World.inst.GetVillagersForLandMass(World.inst.GetCellDataClamped(display.transform.position).landMassIdx).Count;
					num = (int)Mathf.Lerp(30f * num2, 75f * num2, (float)(count - 100) / 1500f);
				}
				if (messageType == MessageType.Message)
				{
					num = 120;
				}
				if (timeActive > (float)num)
				{
					TransitionToDisappearing();
				}
				if (messageType == MessageType.Damage)
				{
					switch (godIdx)
					{
					case 2:
						if (punishmentTimer.Update(dt))
						{
							Vector3 position2 = display.transform.position;
							position2.x += SRand.Range(-3f, 3f);
							position2.z += SRand.Range(-3f, 3f);
							Weather.inst.LightningStrike(position2, doFire: true, smallstrike: true);
						}
						break;
					case 1:
						if (punishmentTimer.Update(dt))
						{
							Vector3 position3 = display.transform.position;
							position3.x += SRand.Range(-3f, 3f);
							position3.z += SRand.Range(-3f, 3f);
							EffectsMan.inst.ExplodeEffect.CreateAndPlay(position3);
							FireManager.inst.StartFireAt(World.inst.GetCellDataClamped(position3));
						}
						break;
					case 5:
					{
						if (!punishmentTimer.Update(dt * 3f))
						{
							break;
						}
						Vector3 position4 = display.transform.position;
						position4.x += SRand.Range(-3f, 3f);
						position4.z += SRand.Range(-3f, 3f);
						Building building = World.inst.GetCellDataClamped(position4).StructureFindByCategory(World.farmHash);
						if (building != null)
						{
							building.GetComponent<YieldProducerSeason>().ResetYield();
							Field component = building.GetComponent<Field>();
							if ((bool)component)
							{
								component.RotStack();
								component.Curse();
								component.ResetField();
							}
							Orchard component2 = building.GetComponent<Orchard>();
							if ((bool)component2)
							{
								component2.RotStack();
								component2.ResetField();
							}
							EffectsMan.inst.FieldCurse.CreateAndPlay(position4);
						}
						break;
					}
					case 7:
						if (punishmentTimer.Update(dt * 3f))
						{
							Vector3 position5 = display.transform.position;
							position5.x += SRand.Range(-2f, 2f);
							position5.z += SRand.Range(-2f, 2f);
							Cell cellDataClamped = World.inst.GetCellDataClamped(position5);
							DynamicWater.inst.AddWaterToCellDeferred(cellDataClamped, 3f);
							EffectsMan.inst.WaterHitEffect.CreateAndPlay(cellDataClamped.Center3D);
						}
						break;
					case 3:
						if (punishmentTimer.Update(dt))
						{
							Vector3 position = display.transform.position;
							position.x += SRand.Range(-2f, 2f);
							position.z += SRand.Range(-2f, 2f);
							if (maxPlagueAmt > 0)
							{
								maxPlagueAmt -= Player.inst.PlagueStartAtLocation(position, Mathff.Min(1, maxPlagueAmt), 0.25f);
							}
							RuntimeManager.PlayOneShot("event:/OldSFX/VillagerCough", position);
							EffectsMan.inst.GreenSmoke.CreateAndPlay(position);
						}
						break;
					}
				}
				if (!GodUI.inst.Visible() && addressed)
				{
					TransitionToDisappearing();
				}
				break;
			}
			case Status.Disappearing:
				if (display.Status == GodDisplayIndividual.State.Disappeared)
				{
					_ = godIdx;
					_ = 7;
					return false;
				}
				break;
			}
			return true;
		}

		internal void Shutdown()
		{
			UnityEngine.Object.Destroy(display.gameObject);
			display = null;
			if (issueButton != null)
			{
				UnityEngine.Object.Destroy(issueButton.gameObject);
				issueButton = null;
			}
		}
	}

	public const int JUPITER = 2;

	public const int VULCAN = 1;

	public const int VENUS = 0;

	public const int CERES = 5;

	public const int MARS = 4;

	public const int NEPTUNE = 7;

	public const int MINERVA = 8;

	public const int APOLLO = 3;

	public static int numGods = 9;

	public static GodManager inst;

	private ArrayExt<ArrayExt<Building>> temples = new ArrayExt<ArrayExt<Building>>(3);

	internal GodSpell[] spells = new GodSpell[numGods];

	private int[] nextTask;

	private int[] currTask;

	internal List<GodTask>[] tasks;

	private int[] festivalCount;

	private ArrayExt<Vector3> scratchPositions = new ArrayExt<Vector3>(128);

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private bool doFirstUpdateAfterLoad;

	private Dictionary<string, bool> hintMap = new Dictionary<string, bool>();

	private List<GodMessage> toRemove = new List<GodMessage>();

	internal int tasksComplete;

	internal bool playerSawIntro;

	private List<GodMessage> godAnger = new List<GodMessage>();

	private int[] godEscalation = new int[numGods];

	private float[] godAngerCooldown = new float[numGods];

	internal bool disableGodsAppearance;

	private GodMessage currMessage;

	public Color jupiterColor;

	public Color neptuneColor;

	public Color ceresColor;

	public Color vulcanColor;

	public Color marsColor;

	public Color apolloColor;

	private void Awake()
	{
		inst = this;
		Reset();
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.categoryHash != World.templeHash)
		{
			return;
		}
		for (int i = 0; i < godAngerCooldown.Length; i++)
		{
			if (Player.inst.IsGodAngry(World.GetLandmassOwner(obj.targetBuilding.LandMass()), i))
			{
				godAngerCooldown[i] += 250f;
			}
		}
	}

	public void RefreshGodAngerAfterTempleDedication(int lm, int godIdx)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(lm);
		Player.inst.UpdateGodAnger(landmassOwner);
		for (int i = 0; i < godAnger.Count; i++)
		{
			if (!Player.inst.IsGodAngry(landmassOwner, godAnger[i].godIdx))
			{
				godAnger[i].addressed = true;
				godAnger[i].TransitionToDisappearing();
			}
		}
		godEscalation[godIdx] = 0;
		godAngerCooldown[godIdx] += 600f;
	}

	public void ClearGodAppearance()
	{
		for (int i = 0; i < godAnger.Count; i++)
		{
			godAnger[i].Shutdown();
		}
		godAnger.Clear();
	}

	public unsafe void Reset()
	{
		if (eventHandler != null)
		{
			Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		}
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		ClearGodAppearance();
		hintMap.Clear();
		for (int i = 0; i < godAngerCooldown.Length; i++)
		{
			godAngerCooldown[i] = 0f;
		}
		for (int j = 0; j < godEscalation.Length; j++)
		{
			godEscalation[j] = 0;
		}
		tasksComplete = 0;
		currTask = new int[numGods];
		nextTask = new int[numGods];
		festivalCount = new int[numGods];
		for (int k = 0; k < numGods; k++)
		{
			nextTask[k] = 0;
			currTask[k] = -1;
		}
		if (tasks == null)
		{
			tasks = new List<GodTask>[numGods];
		}
		for (int l = 0; l < tasks.Length; l++)
		{
			if (tasks[l] == null)
			{
				tasks[l] = new List<GodTask>();
			}
			else
			{
				tasks[l].Clear();
			}
		}
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 20,
			reward = 3
		});
		tasks[2].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "temple",
			descTerm = "godui_task_build_temples",
			reward = 3,
			ignoreScaling = true,
			skipIfComplete = true
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 30,
			reward = 4
		});
		ResourceAmount resourceAmount = new ResourceAmount();
		resourceAmount.Add(4, 10);
		tasks[2].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		tasks[2].Add(new BuildingCountTask
		{
			buildingCount = 4,
			uniqueName = "forumtile",
			categoryName = World.forumName,
			descTerm = "godui_task_build_forum",
			reward = 5,
			ignoreScaling = true
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 50,
			reward = 5
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 75,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 15);
		tasks[2].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 100,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 15);
		tasks[2].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 200,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 25);
		tasks[2].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[2].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "temple2",
			descTerm = "godui_task_build_temples2",
			reward = 4,
			ignoreScaling = true,
			skipIfComplete = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 50);
		tasks[2].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 500,
			reward = 5
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 1000,
			reward = 5
		});
		tasks[2].Add(new PopulationTask
		{
			populationGoal = 2000,
			reward = 5
		});
		tasks[5].Add(new BuildingCountTask
		{
			buildingCount = 5,
			uniqueName = "farm",
			descTerm = "godui_task_build_farms",
			reward = 3
		});
		tasks[5].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "temple",
			descTerm = "godui_task_build_temples",
			reward = 3,
			ignoreScaling = true,
			skipIfComplete = true
		});
		tasks[5].Add(new BuildingCountTask
		{
			buildingCount = 1,
			categoryName = "granary",
			descTerm = "godui_task_build_granaries",
			reward = 4,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(0, 10);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(0, 30);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[5].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "grapevine",
			descTerm = "godui_task_build_grapevine",
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(12, 10);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[5].Add(new BuildingCountTask
		{
			buildingCount = 1,
			categoryName = "baker",
			descTerm = "godui_task_build_bakeries",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(11, 5);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(13, 1);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(12, 10);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(11, 20);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 25);
		tasks[5].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(1, 20);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 3
		});
		tasks[1].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "temple",
			descTerm = "godui_task_build_temples",
			reward = 3,
			ignoreScaling = true,
			skipIfComplete = true
		});
		tasks[1].Add(new BuildingCountTask
		{
			buildingCount = 2,
			categoryName = "charcoal",
			descTerm = "godui_task_build_charcoalmakers",
			reward = 4,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(3, 10);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		tasks[1].Add(new BuildingCountTask
		{
			buildingCount = 2,
			categoryName = "quarry",
			descTerm = "godui_task_build_quarries",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(2, 10);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(3, 10);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 10);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[1].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "ironmine",
			descTerm = "godui_task_build_ironmines",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(5, 20);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[1].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "toolsmith",
			descTerm = "godui_task_build_toolsmith",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(6, 1);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[1].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "weaponsmith",
			descTerm = "godui_task_build_weaponsmith",
			reward = 5,
			ignoreScaling = true,
			skipIfComplete = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(7, 20);
		tasks[1].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[7].Add(new PopulationTask
		{
			populationGoal = 20,
			reward = 3,
			skipIfComplete = true,
			skipIfActive = true
		});
		tasks[7].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "temple",
			descTerm = "godui_task_build_temples",
			reward = 3,
			ignoreScaling = true,
			skipIfComplete = true
		});
		tasks[7].Add(new BuildingCountTask
		{
			buildingCount = 1,
			categoryName = "fishinghut",
			descTerm = "godui_task_build_fishinghut",
			reward = 4,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(8, 10);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 15);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		tasks[7].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "aqueduct",
			descTerm = "godui_task_build_aqueduct",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(13, 10);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[7].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "dock",
			descTerm = "godui_task_build_dock",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(13, 10);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[7].Add(new BuildingCountTask
		{
			buildingCount = 4,
			uniqueName = "damblock",
			descTerm = "godui_task_build_dam",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(8, 20);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 15);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(13, 20);
		tasks[7].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[4].Add(new PopulationTask
		{
			populationGoal = 20,
			reward = 3,
			skipIfComplete = true,
			skipIfActive = true
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "temple",
			descTerm = "godui_task_build_temples",
			reward = 3,
			ignoreScaling = true,
			skipIfComplete = true
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 10,
			uniqueName = "woodcastleblock",
			descTerm = "godui_task_build_palisade",
			reward = 4,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 4);
		tasks[4].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "woodengate",
			descTerm = "godui_task_build_woodengate",
			reward = 5,
			ignoreScaling = true
		});
		tasks[4].Add(new PopulationTask
		{
			populationGoal = 50,
			reward = 3,
			skipIfComplete = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 15);
		tasks[4].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "archer",
			descTerm = "godui_task_build_archer",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 15);
		tasks[4].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[4].Add(new PopulationTask
		{
			populationGoal = 75,
			reward = 3,
			skipIfComplete = true
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "ironmine",
			descTerm = "godui_task_build_ironmines",
			reward = 5,
			ignoreScaling = true
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "weaponsmith",
			descTerm = "godui_task_build_weaponsmith",
			reward = 5,
			ignoreScaling = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(7, 1);
		tasks[4].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[4].Add(new BuildingCountTask
		{
			buildingCount = 1,
			categoryName = "barracks",
			descTerm = "godui_task_build_barracks",
			reward = 5,
			ignoreScaling = true
		});
		tasks[3].Add(new PopulationTask
		{
			populationGoal = 20,
			reward = 3,
			skipIfComplete = true,
			skipIfActive = true
		});
		tasks[3].Add(new BuildingCountTask
		{
			buildingCount = 2,
			uniqueName = "temple",
			reward = 3,
			descTerm = "godui_task_build_temples",
			ignoreScaling = true,
			skipIfComplete = true
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 4);
		tasks[3].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 3
		});
		tasks[3].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "clinic",
			reward = 4,
			descTerm = "godui_task_build_clinics",
			ignoreScaling = true
		});
		tasks[3].Add(new DietTask
		{
			foodNeedsGoal = 3,
			homesGoal = 5,
			reward = 4
		});
		tasks[3].Add(new HealthTask
		{
			healthGoal = 75f,
			reward = 4
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(13, 5);
		tasks[3].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 4
		});
		tasks[3].Add(new DietTask
		{
			foodNeedsGoal = 4,
			homesGoal = 10,
			reward = 4
		});
		tasks[3].Add(new BuildingCountTask
		{
			buildingCount = 1,
			uniqueName = "publictoilets",
			reward = 5,
			descTerm = "godui_task_build_publictoilets",
			ignoreScaling = true
		});
		tasks[3].Add(new HealthTask
		{
			healthGoal = 85f,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(13, 5);
		tasks[3].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		resourceAmount = new ResourceAmount();
		resourceAmount.Set(4, 10);
		tasks[3].Add(new OfferingTask
		{
			offeringAmt = resourceAmount,
			reward = 5
		});
		tasks[3].Add(new DietTask
		{
			foodNeedsGoal = 5,
			homesGoal = 15,
			reward = 4
		});
		tasks[3].Add(new HealthTask
		{
			healthGoal = 95f,
			reward = 5
		});
		if (spells[2] == null)
		{
			spells[2] = new GodSpell
			{
				descTerm = "godui_jupiter_spell_desc",
				invalidTerm = "godui_jupiter_spell_requirement_desc",
				cost = 1,
				godIdx = 2,
				castSpell = () =>
				{
					TimeManager.inst.SetPlay1(skipSfx: true);
					Cinematics.inst.ShowBars(show: true);
					GameState.inst.AlphaNumericHotkeysEnabled = false;
					Cam.TransformCapture cData = Cam.inst.CaptureCameraTransform();
					Vector3 vector = Cam.inst.DesiredTrackingPos;
					float desiredDist = 125f;
					if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Drought)
					{
						int focusedLandMass = Player.inst.FocusedLandMass;
						for (int m = 0; m < DynamicWater.inst.gysers.Count; m++)
						{
							Cell cellData = World.inst.GetCellData(DynamicWater.inst.gysers[m].transform.position);
							if (cellData.landMassIdx == focusedLandMass)
							{
								vector = cellData.Center3D;
								EffectsMan.inst.WaterHitEffect.CreateAndPlay(vector);
								desiredDist = 20f;
								break;
							}
						}
					}
					SeasonManager.inst.SetWeather(SeasonManager.WeatherType.None);
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_jupiter", vector);
					Cam.inst.SetDesiredTrackingPos(vector);
					Cam.inst.desiredDist = desiredDist;
					Cam.inst.desiredPhi = 45f;
					StartCoroutine(ConcludeSpell(cData));
				},
				isValid = () => SeasonManager.inst.CurrWeather != SeasonManager.WeatherType.None,
				maxCooldown = 2250f
			};
		}
		else
		{
			spells[2].cooldown = 0f;
		}
		if (spells[5] == null)
		{
			spells[5] = new GodSpell
			{
				descTerm = "godui_ceres_spell_desc",
				invalidTerm = "godui_ceres_spell_requirement_desc",
				cost = 3,
				godIdx = 5,
				castSpell = () =>
				{
					TimeManager.inst.SetPlay1(skipSfx: true);
					Cinematics.inst.ShowBars(show: true);
					GameState.inst.AlphaNumericHotkeysEnabled = false;
					Cam.TransformCapture cData = Cam.inst.CaptureCameraTransform();
					scratchPositions.ClearFast();
					bool flag = false;
					LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
					for (int m = 0; m < playerLandmassOwner.ownedLandMasses.Count; m++)
					{
						int num = playerLandmassOwner.ownedLandMasses.data[m];
						ArrayExt<Home> arrayExt = Player.inst.ResidentialsPerLandmass[num];
						for (int n = 0; n < arrayExt.Count; n++)
						{
							Home component = arrayExt.data[n].GetComponent<Home>();
							if (component.missingFood != -1)
							{
								if (!flag)
								{
									scratchPositions.ClearFast();
									flag = true;
								}
								scratchPositions.Add(component.b.Center());
							}
							else if (!flag)
							{
								scratchPositions.Add(component.b.Center());
							}
							for (int num2 = 0; num2 < component.dietFilled.Length; num2++)
							{
								component.dietFilled[num2] = 2;
							}
							component.b.ForEachTileInBounds((int x, int z, Cell c) =>
							{
								OneOffEffect oneOffEffect = EffectsMan.inst.TileGodBonusEffect.Create(c.Center3D);
								oneOffEffect.Color = Color.green;
								oneOffEffect.Play();
							});
						}
					}
					GetSpellFocusPosition(scratchPositions, out var targetPos, 4f);
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_ceres", targetPos);
					Cam.inst.SetDesiredTrackingPos(targetPos);
					Cam.inst.desiredDist = 20f;
					Cam.inst.desiredPhi = 45f;
					StartCoroutine(ConcludeSpell(cData, 3f));
				},
				isValid = () =>
				{
					LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
					for (int m = 0; m < playerLandmassOwner.ownedLandMasses.Count; m++)
					{
						int num = playerLandmassOwner.ownedLandMasses.data[m];
						ArrayExt<Home> arrayExt = Player.inst.ResidentialsPerLandmass[num];
						for (int n = 0; n < arrayExt.Count; n++)
						{
							Home component = arrayExt.data[n].GetComponent<Home>();
							for (int num2 = 0; num2 < component.dietFilled.Length; num2++)
							{
								if (component.dietFilled[num2] < 0)
								{
									return true;
								}
							}
						}
					}
					return false;
				},
				maxCooldown = 2250f
			};
		}
		else
		{
			spells[5].cooldown = 0f;
		}
		if (spells[1] == null)
		{
			spells[1] = new GodSpell
			{
				descTerm = "godui_vulcan_spell_desc",
				invalidTerm = "godui_vulcan_spell_requirement_desc",
				cost = 1,
				godIdx = 1,
				castSpell = () =>
				{
					TimeManager.inst.SetPlay1(skipSfx: true);
					Cinematics.inst.ShowBars(show: true);
					GameState.inst.AlphaNumericHotkeysEnabled = false;
					Cam.TransformCapture cData = Cam.inst.CaptureCameraTransform();
					ArrayExt<int> ownedLandMasses = Player.inst.PlayerLandmassOwner.ownedLandMasses;
					ArrayExtRef<PooledObject> needTick = PooledObject.needTick;
					scratchPositions.ClearFast();
					for (int m = 0; m < needTick.Count; m++)
					{
						Fire fire = needTick.data[m] as Fire;
						if (!(fire == null) && fire.Cell != null && ownedLandMasses.Contains(fire.Cell.landMassIdx))
						{
							fire.Burnout(burndown: false);
							scratchPositions.Add(fire.GetCenter());
							Cell cell = fire.Cell;
							int index = 0;
							float num = float.MinValue;
							for (int n = 0; n < cell.OccupyingStructure.Count; n++)
							{
								Building building = cell.OccupyingStructure[n];
								float num2 = building.size.x * building.size.z;
								if (num2 > num)
								{
									index = n;
									num = num2;
								}
							}
							Building building2 = cell.OccupyingStructure[index];
							if (building2 != null)
							{
								building2.ForEachTileInBounds((int x, int z, Cell c) =>
								{
									OneOffEffect oneOffEffect = EffectsMan.inst.TileGodBonusEffect.Create(c.Center3D);
									oneOffEffect.Color = Color.red;
									oneOffEffect.Play();
								});
							}
						}
					}
					GetSpellFocusPosition(scratchPositions, out var targetPos, 8f);
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_vulcan", targetPos);
					Cam.inst.SetDesiredTrackingPos(targetPos);
					Cam.inst.desiredDist = 20f;
					Cam.inst.desiredPhi = 45f;
					StartCoroutine(ConcludeSpell(cData));
				},
				isValid = () =>
				{
					ArrayExt<int> ownedLandMasses = Player.inst.PlayerLandmassOwner.ownedLandMasses;
					ArrayExtRef<PooledObject> needTick = PooledObject.needTick;
					for (int m = 0; m < needTick.Count; m++)
					{
						Fire fire = needTick.data[m] as Fire;
						if (!(fire == null) && fire.Cell != null && ownedLandMasses.Contains(fire.Cell.landMassIdx))
						{
							return true;
						}
					}
					return false;
				},
				maxCooldown = 2250f
			};
		}
		else
		{
			spells[1].cooldown = 0f;
		}
		if (spells[7] == null)
		{
			spells[7] = new GodSpell
			{
				descTerm = "godui_neptune_spell_desc",
				invalidTerm = "godui_neptune_spell_requirement_desc",
				cost = 10,
				godIdx = 7,
				castSpell = () =>
				{
					TimeManager.inst.SetPlay1(skipSfx: true);
					Cinematics.inst.ShowBars(show: true);
					GameState.inst.AlphaNumericHotkeysEnabled = false;
					Cam.TransformCapture cData = Cam.inst.CaptureCameraTransform();
					scratchPositions.ClearFast();
					ArrayExt<ShipBase> ships = ShipSystem.inst.ships;
					for (int m = 0; m < ships.Count; m++)
					{
						ShipBase shipBase = ships.data[m];
						if (shipBase.type == ShipBase.ShipType.VikingTroopTransport)
						{
							shipBase.life = 0f;
							Vector3 pos = shipBase.GetPos();
							scratchPositions.Add(pos);
							EffectsMan.inst.LightingStrikeFocusEffect.CreateAndPlay(pos);
						}
					}
					GetSpellFocusPosition(scratchPositions, out var targetPos);
					RuntimeManager.PlayOneShot("event:/OldSFX/Thunder", targetPos);
					Cam.inst.SetDesiredTrackingPos(targetPos);
					Cam.inst.desiredDist = 30f;
					Cam.inst.desiredPhi = 45f;
					StartCoroutine(ConcludeSpell(cData));
				},
				isValid = () =>
				{
					_ = Player.inst.PlayerLandmassOwner.ownedLandMasses;
					_ = PooledObject.needTick;
					ArrayExt<ShipBase> ships = ShipSystem.inst.ships;
					for (int m = 0; m < ships.Count; m++)
					{
						ShipBase shipBase = ships.data[m];
						if (shipBase.type == ShipBase.ShipType.VikingTroopTransport && shipBase.life > 0f && shipBase.state != ShipBase.State.Sinking)
						{
							return true;
						}
					}
					return false;
				},
				maxCooldown = 7000f
			};
		}
		else
		{
			spells[7].cooldown = 0f;
		}
		if (spells[4] == null)
		{
			spells[4] = new GodSpell
			{
				descTerm = "godui_mars_spell_desc",
				invalidTerm = "godui_mars_spell_requirement_desc",
				cost = 4,
				godIdx = 4,
				castSpell = () =>
				{
					TimeManager.inst.SetPlay1(skipSfx: true);
					Cinematics.inst.ShowBars(show: true);
					GameState.inst.AlphaNumericHotkeysEnabled = false;
					Cam.TransformCapture cData = Cam.inst.CaptureCameraTransform();
					LegionSystem.Inst.ActivateFrenzy();
					scratchPositions.ClearFast();
					ArrayExt<LegionUnit> legionUnits = UnitSystem.inst.legionUnits;
					for (int m = 0; m < legionUnits.Count; m++)
					{
						LegionUnit legionUnit = legionUnits.data[m];
						if (legionUnit.TeamID() == 0 && legionUnit.ValidToSelect())
						{
							scratchPositions.Add(legionUnit.GetPosition());
							LegionGroup legionGroup = legionUnit.GetGroup();
							for (int n = 0; n < legionGroup.numCells; n++)
							{
								Vector3 position = LegionSystem.Inst.legionCells[legionGroup.cells[n]].position;
								OneOffEffect oneOffEffect = EffectsMan.inst.TileGodBonusEffect.Create(position);
								oneOffEffect.Color = Color.red;
								oneOffEffect.Play();
							}
						}
					}
					GetSpellFocusPosition(scratchPositions, out var targetPos);
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_combat_head", targetPos);
					Cam.inst.SetDesiredTrackingPos(targetPos);
					Cam.inst.desiredDist = 30f;
					Cam.inst.desiredPhi = 45f;
					StartCoroutine(ConcludeSpell(cData, 3f));
				},
				isValid = () => UnitSystem.inst.unitsByTeamID[0].Count > 0,
				maxCooldown = 2250f
			};
		}
		else
		{
			spells[4].cooldown = 0f;
		}
		if (spells[3] == null)
		{
			spells[3] = new GodSpell
			{
				descTerm = "godui_apollo_spell_desc",
				invalidTerm = "godui_apollo_spell_requirement_desc",
				cost = 10,
				godIdx = 3,
				castSpell = () =>
				{
					TimeManager.inst.SetPlay1(skipSfx: true);
					Cinematics.inst.ShowBars(show: true);
					GameState.inst.AlphaNumericHotkeysEnabled = false;
					Cam.TransformCapture cData = Cam.inst.CaptureCameraTransform();
					scratchPositions.ClearFast();
					LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
					for (int m = 0; m < playerLandmassOwner.ownedLandMasses.Count; m++)
					{
						int idx = playerLandmassOwner.ownedLandMasses.data[m];
						ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(idx);
						for (int n = 0; n < villagersForLandMass.Count; n++)
						{
							Villager villager = villagersForLandMass.data[n];
							if (villager.sick)
							{
								scratchPositions.Add(villager.Pos);
								EffectsMan.inst.HealthEffect.CreateAndPlay(villager.Pos);
							}
						}
					}
					GetSpellFocusPosition(scratchPositions, out var targetPos);
					Player.inst.CurePlague();
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_favourUnlocked", targetPos);
					Cam.inst.SetDesiredTrackingPos(targetPos);
					Cam.inst.desiredDist = 30f;
					Cam.inst.desiredPhi = 45f;
					StartCoroutine(ConcludeSpell(cData));
				},
				isValid = () =>
				{
					LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
					for (int m = 0; m < playerLandmassOwner.ownedLandMasses.Count; m++)
					{
						int idx = playerLandmassOwner.ownedLandMasses.data[m];
						ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(idx);
						for (int n = 0; n < villagersForLandMass.Count; n++)
						{
							if (villagersForLandMass.data[n].sick)
							{
								return true;
							}
						}
					}
					return false;
				},
				maxCooldown = 4000f
			};
		}
		else
		{
			spells[3].cooldown = 0f;
		}
	}

	private IEnumerator ConcludeSpell(Cam.TransformCapture cData, float waitDuration = 5f)
	{
		yield return new WaitForSecondsRealtime(waitDuration);
		Cinematics.inst.ShowBars(show: false);
		Cam.inst.ApplyTransformCapture(cData);
		GameState.inst.AlphaNumericHotkeysEnabled = true;
	}

	private void GetSpellFocusPosition(ArrayExt<Vector3> positions, out Vector3 targetPos, float inclusionRadius = 5f)
	{
		targetPos = Vector3.zero;
		float[] array = new float[positions.Count];
		for (int i = 0; i < positions.Count; i++)
		{
			Vector3 a = positions.data[i];
			for (int j = 0; j < positions.Count; j++)
			{
				if (i != j)
				{
					float num = Mathff.DistSqrdXZ(a, positions.data[j]);
					array[i] += num;
				}
			}
		}
		int num2 = 0;
		float num3 = float.MaxValue;
		for (int k = 0; k < array.Length; k++)
		{
			if (array[k] < num3)
			{
				num2 = k;
				num3 = array[k];
			}
		}
		int num4 = 1;
		Vector3 a2 = (targetPos = positions.data[num2]);
		for (int l = 0; l < positions.Count; l++)
		{
			if (num2 != l)
			{
				Vector3 vector = positions.data[l];
				if (Mathff.DistSqrdXZ(a2, vector) <= inclusionRadius * inclusionRadius)
				{
					targetPos.NonAllocateAdd(vector);
					num4++;
				}
			}
		}
		targetPos.NonAllocateDivide(num4);
	}

	public void ThrowFestival(int godIdx)
	{
		godEscalation[godIdx] = 0;
		godAngerCooldown[godIdx] += 600f;
		festivalCount[godIdx]++;
	}

	public ResourceAmount GetFestivalCost(int godIdx, int lmIdx)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		int count = World.inst.GetVillagersForLandMass(lmIdx).Count;
		resourceAmount.Set(4, count / 5 + SeasonManager.inst.CurrentYear() / 5 + festivalCount[godIdx] * 25);
		switch (godIdx)
		{
		case 2:
			if (count > 200)
			{
				resourceAmount.Set(13, count / 15);
			}
			if (count > 350)
			{
				resourceAmount.Set(12, count / 15);
			}
			break;
		case 5:
			if (count > 200)
			{
				resourceAmount.Set(11, count / 20);
			}
			if (count > 350)
			{
				resourceAmount.Set(12, count / 30);
			}
			if (count > 550)
			{
				resourceAmount.Set(9, count / 40);
			}
			if (count > 750)
			{
				resourceAmount.Set(18, count / 50);
			}
			break;
		case 1:
			if (count > 200)
			{
				resourceAmount.Set(13, count / 15);
			}
			if (count > 350)
			{
				resourceAmount.Set(3, count / 30);
			}
			break;
		case 7:
			if (count > 200)
			{
				resourceAmount.Set(8, count / 20);
			}
			if (count > 350)
			{
				resourceAmount.Set(13, count / 15);
			}
			break;
		case 4:
			if (count > 200)
			{
				resourceAmount.Set(13, count / 15);
			}
			if (count > 350)
			{
				resourceAmount.Set(7, count / 50);
			}
			break;
		case 3:
			if (count > 200)
			{
				resourceAmount.Set(11, count / 20);
			}
			if (count > 350)
			{
				resourceAmount.Set(13, count / 15);
			}
			break;
		}
		return resourceAmount;
	}

	private void Update()
	{
		if (LoadSave.Loading || !World.inst.Inited)
		{
			return;
		}
		if (doFirstUpdateAfterLoad)
		{
			for (int i = 0; i < currTask.Length; i++)
			{
				if (currTask[i] == -1 && GetNextTask(i) != null && nextTask[i] != 0)
				{
					AcceptNextTask(i);
				}
			}
			doFirstUpdateAfterLoad = false;
		}
		float deltaTime = Time.deltaTime;
		for (int j = 0; j < spells.Length; j++)
		{
			if (spells[j] != null)
			{
				spells[j].cooldown -= deltaTime;
			}
		}
		bool flag = false;
		for (int k = 0; k < currTask.Length; k++)
		{
			if (currTask[k] != -1 && currTask[k] < tasks[k].Count)
			{
				if (tasks[k][currTask[k]].GetProgress() >= 1f)
				{
					SetExclamationVisibility(k, visible: true);
					flag = true;
				}
				else
				{
					SetExclamationVisibility(k, visible: false);
				}
			}
		}
		if (flag)
		{
			ProsperityUI.inst.SetNotifyOnTasks(-1);
		}
		if (GodUI.inst.gameObject.activeSelf)
		{
			SetExclamationVisibility(-2, visible: false);
		}
		else
		{
			SetExclamationVisibility(-1, visible: true);
		}
		for (int l = 0; l < godAngerCooldown.Length; l++)
		{
			godAngerCooldown[l] -= deltaTime;
			if (godAngerCooldown[l] < 0f)
			{
				godAngerCooldown[l] = 0f;
			}
		}
		for (int m = 0; m < godAnger.Count; m++)
		{
			if (!godAnger[m].Tick(deltaTime))
			{
				toRemove.Add(godAnger[m]);
			}
		}
		for (int n = 0; n < toRemove.Count; n++)
		{
			toRemove[n].Shutdown();
			godAngerCooldown[toRemove[n].godIdx] += godEscalation[toRemove[n].godIdx] * SRand.Range(450, 600);
			godAnger.Remove(toRemove[n]);
		}
		toRemove.Clear();
		if (!hintMap.TryGetValue("MilitiaHint", out var value))
		{
			if (!RaiderSystem.inst.IsRaidInProgress() || UnitSystem.inst.unitsByTeamID[0].Count > 0)
			{
				return;
			}
			Ray ray = Cam.inst.GetRay();
			if (!TerrainGen.inst.Raycast(ray, out var hitInfo))
			{
				return;
			}
			int landMassIdx = World.inst.GetCellDataClamped(hitInfo.point).landMassIdx;
			if (Player.inst.LandMassIsAPlayerLandMass(landMassIdx))
			{
				GodMessage message = new GodMessage(2, hitInfo.point);
				message.issueButton.onClick = () =>
				{
					ShowMessage(message, "MilitiaHint");
				};
				message.messageType = GodMessage.MessageType.Message;
				godAnger.Add(message);
				hintMap["MilitiaHint"] = true;
			}
		}
		else
		{
			if (hintMap.TryGetValue("PlagueHint", out value) || Player.inst.Workers.Count < 200)
			{
				return;
			}
			Ray ray2 = Cam.inst.GetRay();
			if (!TerrainGen.inst.Raycast(ray2, out var hitInfo2))
			{
				return;
			}
			int landMassIdx2 = World.inst.GetCellDataClamped(hitInfo2.point).landMassIdx;
			if (Player.inst.LandMassIsAPlayerLandMass(landMassIdx2) && World.inst.GetVillagersForLandMass(landMassIdx2).Count >= 200)
			{
				GodMessage message2 = new GodMessage(3, hitInfo2.point);
				message2.issueButton.onClick = () =>
				{
					ShowMessage(message2, "PlagueHint");
				};
				message2.messageType = GodMessage.MessageType.Message;
				godAnger.Add(message2);
				hintMap["PlagueHint"] = true;
			}
		}
	}

	private void SetExclamationVisibility(int godIdx, bool visible)
	{
		ArrayExt<int> ownedLandMasses = Player.inst.PlayerLandmassOwner.ownedLandMasses;
		for (int i = 0; i < ownedLandMasses.Count; i++)
		{
			int landMass = ownedLandMasses.data[i];
			Player.inst.GetBuildingListsByCategoryForLandMass(landMass, "temple".GetHashCode(), ref temples);
			for (int j = 0; j < temples.Count; j++)
			{
				ArrayExt<Building> arrayExt = temples.data[j];
				for (int k = 0; k < arrayExt.Count; k++)
				{
					Building building = arrayExt.data[k];
					Temple component = building.GetComponent<Temple>();
					if (building.IsBuilt() && building.IsPlaced() && component != null && (component.GetDedicateIdx() == godIdx || godIdx == -2))
					{
						if ((building.WorkersAllocated <= 0) & visible)
						{
							building.GetComponent<Temple>().issueButton.gameObject.SetActive(value: false);
						}
						else if (visible && building.uniqueNameHash != World.templeHash && godIdx != -1)
						{
							building.GetComponent<Temple>().issueButton.gameObject.SetActive(value: false);
						}
						else
						{
							building.GetComponent<Temple>().issueButton.gameObject.SetActive(visible);
						}
					}
				}
			}
		}
	}

	internal GodTask GetNextTask(int godIdx)
	{
		int num = nextTask[godIdx];
		if (tasks[godIdx].Count > num)
		{
			GodTask godTask = tasks[godIdx][num];
			if (godTask is BuildingCountTask { uniqueName: "temple" })
			{
				for (int i = 0; i < numGods; i++)
				{
					int num2 = currTask[i];
					if (i != godIdx && num2 >= 0 && tasks[i].Count > num2 && tasks[i][num2] is BuildingCountTask { uniqueName: "temple" })
					{
						nextTask[godIdx]++;
						return GetNextTask(godIdx);
					}
				}
			}
			return godTask;
		}
		return null;
	}

	internal GodTask GetCurrTask(int godIdx)
	{
		if (godIdx == -1 || currTask[godIdx] == -1)
		{
			return null;
		}
		return tasks[godIdx][currTask[godIdx]];
	}

	internal void CompleteCurrTask(int godIdx)
	{
		tasks[godIdx][currTask[godIdx]].Complete();
		currTask[godIdx] = -1;
		tasksComplete++;
		MilestoneManager.inst.CheckForGodTaskMilestones();
		CheckGodAllTasksMilestones(godIdx);
		if (GetNextTask(godIdx) == null)
		{
			TechnologyTree.inst.ForceUnlock("unlockkey_temple2");
		}
	}

	private void CheckGodAllTasksMilestones(int godIdx)
	{
		if (tasks[godIdx].Count <= 0 || nextTask[godIdx] < tasks[godIdx].Count || currTask[godIdx] != -1)
		{
			return;
		}
		MilestoneManager.inst.TryGodAllTasksOneMilestone();
		bool flag = true;
		for (int i = 0; i < numGods; i++)
		{
			if (tasks[i].Count > 0 && (nextTask[i] < tasks[i].Count || currTask[i] != -1))
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			MilestoneManager.inst.TryGodAllTasksAllMilestone();
		}
	}

	private bool IsActive(GodTask task)
	{
		for (int i = 0; i < numGods; i++)
		{
			int num = currTask[i];
			if (num >= 0 && num < tasks[i].Count && tasks[i][num].Equals(task))
			{
				return true;
			}
		}
		return false;
	}

	internal void AcceptNextTask(int godIdx)
	{
		ProsperityUI.inst.SetNotifyOnTasks(godIdx);
		currTask[godIdx] = nextTask[godIdx];
		while (currTask[godIdx] >= 0 && currTask[godIdx] < tasks[godIdx].Count && ((tasks[godIdx][currTask[godIdx]].skipIfComplete && tasks[godIdx][currTask[godIdx]].IsComplete()) || (tasks[godIdx][currTask[godIdx]].skipIfActive && IsActive(tasks[godIdx][currTask[godIdx]]))))
		{
			nextTask[godIdx]++;
			currTask[godIdx] = nextTask[godIdx];
		}
		if (currTask[godIdx] >= tasks[godIdx].Count)
		{
			currTask[godIdx] = -1;
			nextTask[godIdx] = tasks[godIdx].Count;
			CheckGodAllTasksMilestones(godIdx);
			return;
		}
		if (currTask[godIdx] != -1)
		{
			tasks[godIdx][currTask[godIdx]].AcceptTask();
		}
		nextTask[godIdx]++;
	}

	public static int GodNameToIdx(string godName)
	{
		return godName.ToLower() switch
		{
			"jupiter" => 2, 
			"venus" => 0, 
			"ceres" => 5, 
			"vulcan" => 1, 
			"neptune" => 7, 
			"mars" => 4, 
			"apollo" => 3, 
			_ => -1, 
		};
	}

	private Cell GetTargetCellForAnger(int godIdx)
	{
		Cell centerCell = World.inst.GetCellDataClamped(Cam.inst.TrackingPos);
		return World.inst.FindMatchingSurroundingCell(centerCell, testOrigin: true, 7, (Cell cell) =>
		{
			if (cell.landMassIdx == -1)
			{
				return false;
			}
			if (Player.inst.TotalWorkersForLandMass(cell.landMassIdx) < 5)
			{
				return false;
			}
			if (godIdx == 5)
			{
				int num = 0;
				int farmCount = 0;
				World.inst.ForEachTileInRadius(cell.x, cell.z, 5, (int x, int z, Cell cell2) =>
				{
					if (cell2.StructureCompareCategory(World.farmHash))
					{
						farmCount++;
					}
				});
				if (World.inst.GetCellData(centerCell.x, centerCell.z + 1).StructureCompareCategory(World.farmHash))
				{
					num++;
				}
				if (World.inst.GetCellData(centerCell.x, centerCell.z - 1).StructureCompareCategory(World.farmHash))
				{
					num++;
				}
				if (World.inst.GetCellData(centerCell.x + 1, centerCell.z).StructureCompareCategory(World.farmHash))
				{
					num++;
				}
				if (World.inst.GetCellData(centerCell.x - 1, centerCell.z).StructureCompareCategory(World.farmHash))
				{
					num++;
				}
				if (farmCount > 4 && num > 1)
				{
					return true;
				}
			}
			else if (godIdx == 7)
			{
				int waterCount = 0;
				int structureCount = 0;
				World.inst.ForEachTileInRadius(cell.x, cell.z, 2, (int x, int z, Cell cell2) =>
				{
					if (cell2.Type == TerrainType.Water)
					{
						waterCount++;
					}
					structureCount += cell2.OccupyingStructure.Count;
				});
				if (waterCount > 5 && structureCount > 0)
				{
					return true;
				}
			}
			else if (godIdx == 3)
			{
				int residentCount = 0;
				World.inst.ForEachTileInRadius(cell.x, cell.z, 4, (int x, int z, Cell cell2) =>
				{
					Building building = cell2.StructureFindByCategory(World.houseCategoryHash);
					if (!(building == null))
					{
						Home component = building.GetComponent<Home>();
						residentCount += component.Residents.Count;
					}
				});
				if (residentCount > 10)
				{
					return true;
				}
			}
			else if (cell.OccupyingStructure.Count > 0)
			{
				return true;
			}
			return false;
		});
	}

	public void EnsureMinCooldown(float cooldown)
	{
		for (int i = 0; i < godAngerCooldown.Length; i++)
		{
			if (godAngerCooldown[i] < cooldown)
			{
				godAngerCooldown[i] = SRand.Range(cooldown, cooldown * 1.5f);
			}
		}
	}

	internal void SpawnGodAngerAtCam(int godIdx, bool force = false)
	{
		if (!force)
		{
			if (DifficultyManager.inst.currOption.godWrath == 0 || disableGodsAppearance || godAngerCooldown[godIdx] > 0f)
			{
				return;
			}
			bool flag = false;
			for (int i = 0; i < godAnger.Count; i++)
			{
				if (godAnger[i].godIdx == godIdx)
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				return;
			}
		}
		Cell targetCellForAnger = GetTargetCellForAnger(godIdx);
		if (targetCellForAnger == null)
		{
			return;
		}
		float num = float.MaxValue;
		for (int j = 0; j < godAnger.Count; j++)
		{
			float num2 = Vector3.Distance(godAnger[j].display.transform.position, targetCellForAnger.Center3D);
			if (num2 < num)
			{
				num = num2;
			}
		}
		if (!((num > 8f) | force))
		{
			return;
		}
		if (World.inst.demoMode && godEscalation[godIdx] >= 1)
		{
			Player.GodHonorInfo[] godHonor = Player.inst.PlayerLandmassOwner.godHonor;
			if (!godHonor[godIdx].templeNotStaffed && godHonor[godIdx].honor > 0)
			{
				return;
			}
		}
		for (int k = 0; k < godAngerCooldown.Length; k++)
		{
			godAngerCooldown[k] += SRand.Range(200, 300);
		}
		GodMessage newAnger = new GodMessage(godIdx, targetCellForAnger.Center3D);
		newAnger.issueButton.onClick = () =>
		{
			ShowMessage(newAnger);
		};
		if (godEscalation[godIdx] == 0)
		{
			newAnger.messageType = GodMessage.MessageType.Warning;
		}
		else if (godEscalation[godIdx] >= 1)
		{
			newAnger.messageType = GodMessage.MessageType.Damage;
			newAnger.offeringAmt = new ResourceAmount();
			float num3 = 25f;
			num3 += (float)World.inst.GetVillagersForLandMass(targetCellForAnger.landMassIdx).Count * 0.5f + (float)(SRand.Range(0, 3) * 5);
			newAnger.offeringAmt.Set(4, (int)num3);
		}
		godEscalation[godIdx]++;
		godAnger.Add(newAnger);
	}

	public string GetConvoForWarning(int godIdx, int landmassIdx)
	{
		Player.GodHonorInfo[] godHonor = World.GetLandmassOwner(landmassIdx).godHonor;
		if (godHonor[godIdx].templeNotStaffed)
		{
			return "GodWarningNotStaffed";
		}
		if (godHonor[godIdx].honor == 0)
		{
			return "GodWarning";
		}
		return "GodWarningMediumTemple";
	}

	internal void ShowMessage(GodMessage message, string customConvo = null)
	{
		currMessage = message;
		GodUI.inst.Show(null, message.display.transform.position);
		int landMassIdx = World.inst.GetCellDataClamped(message.display.transform.position).landMassIdx;
		if (message.messageType == GodMessage.MessageType.Warning)
		{
			GodUI.inst.StartConvo(GetConvoForWarning(message.godIdx, landMassIdx));
			message.addressed = true;
		}
		else if (message.messageType == GodMessage.MessageType.Damage)
		{
			GodUI.inst.StartConvo("GodDamage");
			DialogueLua.SetVariable("Var1", message.offeringAmt.ToString());
		}
		else if (message.messageType == GodMessage.MessageType.Message)
		{
			GodUI.inst.StartConvo(customConvo);
			message.addressed = true;
		}
		message.issueButton.gameObject.SetActive(value: false);
	}

	public bool CanAppeaseWithOffering()
	{
		return OfferingTask.ResourceProgress(currMessage.offeringAmt) >= 1f;
	}

	public void CancelAppease()
	{
		currMessage.issueButton.gameObject.SetActive(value: true);
	}

	public void AppeaseWithOffering()
	{
		OfferingTask.RemoveResources(currMessage.offeringAmt);
		currMessage.addressed = true;
		currMessage.TransitionToDisappearing();
	}

	private void HighlightAnger(Ray ray)
	{
		for (int i = 0; i < godAnger.Count; i++)
		{
			if (godAnger[i].display.GetGodInfo().Raycast(PointingSystem.GetRay(), out var _))
			{
				godAnger[i].display.GetGodInfo().highlight.SetOutlineImmediate(1);
			}
		}
	}

	internal Color GetColorForGod(int dedicate)
	{
		return dedicate switch
		{
			1 => vulcanColor, 
			5 => ceresColor, 
			2 => jupiterColor, 
			7 => neptuneColor, 
			4 => marsColor, 
			3 => apolloColor, 
			_ => Color.white, 
		};
	}
}
