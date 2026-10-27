using System;
using Assets;
using Drawing;
using UnityEngine;

public class BathManager : MonoBehaviourGizmos
{
	public struct BathCell
	{
		[NonSerialized]
		public BathGroup bGroup;

		[NonSerialized]
		public BathGroup.PoolGroup pGroup;
	}

	public class BathGroup
	{
		public class PoolGroup
		{
			public int id;

			public static int count;

			public int heatType;

			[NonSerialized]
			public bool isMerging;

			public ArrayExt<BathPool> pools = new ArrayExt<BathPool>(32);

			public bool isHeated;

			public PoolGroup(int heatType)
			{
				id = count++;
				this.heatType = heatType;
			}

			public void UpdateHeat(float dt, bool hasWater)
			{
				if (heatType != 1)
				{
					return;
				}
				float num = SeasonManager.inst.TimeInYear();
				bool flag = hasWater;
				if (hasWater)
				{
					for (int i = 0; i < pools.Count; i++)
					{
						BathHotPool bathHotPool = (BathHotPool)pools.data[i];
						if ((!bathHotPool.HasCharcoal() && !(bathHotPool.consumptionTime + dt < num)) || !(bathHotPool.b.GetWorkerPercent() >= 1f))
						{
							flag = false;
							break;
						}
					}
				}
				if (!flag)
				{
					isHeated = false;
					return;
				}
				bool flag2 = !isHeated;
				isHeated = true;
				for (int j = 0; j < pools.Count; j++)
				{
					BathHotPool bathHotPool2 = (BathHotPool)pools.data[j];
					if (flag2)
					{
						bathHotPool2.TryEnableIdleJobs();
					}
					bathHotPool2.consumptionTime += dt;
					if (bathHotPool2.consumptionTime >= num && bathHotPool2.HasCharcoal())
					{
						bathHotPool2.ConsumeCharcoal();
					}
				}
			}
		}

		public int id;

		public static int count;

		[NonSerialized]
		public bool isMerging;

		[NonSerialized]
		public bool isDirty;

		[NonSerialized]
		public float wConsumption;

		[NonSerialized]
		public float wProduction;

		[NonSerialized]
		public float wStorage;

		[NonSerialized]
		public bool hasWater;

		[NonSerialized]
		public float storage;

		[NonSerialized]
		public int connectedReservoirs;

		[NonSerialized]
		public int contributingReservoirs;

		[NonSerialized]
		public float solverDemand;

		[NonSerialized]
		public float solverMinServe;

		public int solverPriority;

		[NonSerialized]
		public bool waterViable = true;

		[NonSerialized]
		public bool runningOnReserves;

		private const float STORAGE_EMPTY_EPSILON = 0.5f;

		private const float CANSUSTAIN_EPSILON = 0.5f;

		public ArrayExt<BathReservoir> reservoirs = new ArrayExt<BathReservoir>(16);

		public ArrayExt<BathPool> pools = new ArrayExt<BathPool>(64);

		public ArrayExt<BathPalaestra> palaestras = new ArrayExt<BathPalaestra>(16);

		public ArrayExt<BathLibrary> libraries = new ArrayExt<BathLibrary>(16);

		public ArrayExt<BathGarden> gardens = new ArrayExt<BathGarden>(16);

		public ArrayExt<ObjectHighlighter> highlights = new ArrayExt<ObjectHighlighter>(128);

		public ArrayExt<RadiusBonus> radBonuses = new ArrayExt<RadiusBonus>(128);

		public int bonusCount;

		public int totalBonuses;

		public bool hasSmallHeatedPool;

		public bool isSmallHeatedPoolActive;

		public bool hasRequiredWorkersForSmallHeatPool;

		public bool hasMediumHeatedPool;

		public bool isMediumHeatedPoolActive;

		public bool hasRequiredWorkersForMediumHeatPool;

		public bool hasLargeHeatedPool;

		public bool isLargeHeatedPoolActive;

		public bool hasRequiredWorkersForLargeHeatPool;

		public bool hasSmallColdPool;

		public bool isSmallColdPoolActive;

		public bool hasMediumColdPool;

		public bool isMediumColdPoolActive;

		public bool hasLargeColdPool;

		public bool isLargeColdPoolActive;

		public bool hasSmallLibrary;

		public bool hasMediumLibrary;

		public bool hasLargeLibrary;

		public bool hasSmallPalaestra;

		public bool hasMediumPalaestra;

		public bool hasLargePalaestra;

		public bool hasSmallGarden;

		public bool hasMediumGarden;

		public bool hasLargeGarden;

		public const string TERM_WARN_CONNECT = "workerui_bathui_warning_connectaqueduct";

		public const string TERM_WARN_NO_ARRIVING = "workerui_bathui_warning_nowaterarriving";

		public const string TERM_WARN_SHORTFALL = "workerui_bathui_warning_supplyshortfall";

		public const string TERM_WARN_SUSPENDED = "workerui_bathui_warning_supplysuspended";

		public const string TERM_WARN_DRAINING = "workerui_bathui_warning_drainingreserves";

		public ArrayExt<PoolGroup> pGroups = new ArrayExt<PoolGroup>(8);

		public WaterPriority WaterPriorityLevel
		{
			get
			{
				return (WaterPriority)solverPriority;
			}
			set
			{
				SetWaterPriority(value);
			}
		}

		public int GetTotalBathBuildings()
		{
			return reservoirs.Count + pools.Count + libraries.Count + palaestras.Count + gardens.Count;
		}

		public BathGroup()
		{
			id = count++;
		}

		public void CalculateWater()
		{
			wConsumption = pools.Count * BathPool.wConsumption;
			wProduction = 0f;
			float num = 0f;
			int num2 = 0;
			for (int i = 0; i < reservoirs.Count; i++)
			{
				BathReservoir bathReservoir = reservoirs.data[i];
				if (bathReservoir.ParticipatesInComplexWater())
				{
					if (bathReservoir.HasAnyConnection())
					{
						num2++;
					}
					wProduction += bathReservoir.GroupIntake();
					num += bathReservoir.currWaterStorage;
				}
			}
			storage = num;
			wStorage = storage;
			connectedReservoirs = num2;
			if (RecomputePriorityFromReservoirs())
			{
				AqueductFlowController.MarkDemandDirty("CalculateWater");
			}
			UpdateDemandDecision();
			hasWater = wProduction + storage > 0f && wProduction + storage >= wConsumption;
			for (int j = 0; j < reservoirs.Count; j++)
			{
				reservoirs.data[j].BathWaterFulfilled = hasWater || wConsumption <= 0f;
			}
			for (int k = 0; k < pools.Count; k++)
			{
				pools.data[k].UpdateWater(hasWater);
			}
		}

		public void IntegrateStorage()
		{
			float deltaTime = Time.deltaTime;
			int num = 0;
			int num2 = 0;
			float num3 = 0f;
			for (int i = 0; i < reservoirs.Count; i++)
			{
				BathReservoir bathReservoir = reservoirs.data[i];
				if (bathReservoir.ParticipatesInComplexWater())
				{
					bool flag = bathReservoir.HasAnyConnection();
					if (flag)
					{
						num++;
					}
					if (flag || bathReservoir.currWaterStorage > 0.5f)
					{
						num2++;
					}
					num3 += bathReservoir.GroupIntake();
				}
			}
			if (num != connectedReservoirs)
			{
				AqueductFlowController.MarkTopologyDirty("IntegrateStorage");
			}
			connectedReservoirs = num;
			contributingReservoirs = num2;
			float a = ((num2 > 0) ? (wConsumption / (float)num2) : 0f);
			float num4 = wConsumption;
			for (int j = 0; j < reservoirs.Count; j++)
			{
				BathReservoir bathReservoir2 = reservoirs.data[j];
				if (!bathReservoir2.ParticipatesInComplexWater())
				{
					bathReservoir2.waterConsumption = 0f;
				}
				else if (!bathReservoir2.HasAnyConnection())
				{
					if (bathReservoir2.currWaterStorage > 0.5f)
					{
						float num5 = (bathReservoir2.waterConsumption = Mathff.Min(a, bathReservoir2.currWaterStorage / Mathff.Max(deltaTime, 1E-06f)));
						bathReservoir2.currWaterStorage = Mathff.Clamp(bathReservoir2.currWaterStorage - num5 * deltaTime, 0f, BathReservoir.MAX_WATER_STORAGE);
						num4 -= num5;
					}
					else
					{
						bathReservoir2.waterConsumption = 0f;
					}
				}
			}
			if (num4 < 0f)
			{
				num4 = 0f;
			}
			if (num3 >= num4)
			{
				float num6 = num3 - num4;
				float num7 = 0f;
				for (int k = 0; k < reservoirs.Count; k++)
				{
					BathReservoir bathReservoir3 = reservoirs.data[k];
					if (bathReservoir3.IsLiveReservoir())
					{
						num7 += Mathff.Max(0f, BathReservoir.MAX_WATER_STORAGE - bathReservoir3.currWaterStorage);
					}
				}
				for (int l = 0; l < reservoirs.Count; l++)
				{
					BathReservoir bathReservoir4 = reservoirs.data[l];
					if (bathReservoir4.IsLiveReservoir())
					{
						float num8 = Mathff.Max(0f, BathReservoir.MAX_WATER_STORAGE - bathReservoir4.currWaterStorage);
						float num9 = ((num7 > 0f) ? (num6 * (num8 / num7)) : 0f);
						float num10 = bathReservoir4.GroupIntake();
						if (wConsumption <= 0f)
						{
							num9 = num10;
						}
						if (num9 > num10)
						{
							num9 = num10;
						}
						bathReservoir4.waterConsumption = num10 - num9;
						bathReservoir4.currWaterStorage = Mathff.Clamp(bathReservoir4.currWaterStorage + num9 * deltaTime, 0f, BathReservoir.MAX_WATER_STORAGE);
					}
				}
			}
			else
			{
				float num11 = num4 - num3;
				float num12 = 0f;
				for (int m = 0; m < reservoirs.Count; m++)
				{
					BathReservoir bathReservoir5 = reservoirs.data[m];
					if (bathReservoir5.IsLiveReservoir())
					{
						num12 += bathReservoir5.currWaterStorage;
					}
				}
				for (int n = 0; n < reservoirs.Count; n++)
				{
					BathReservoir bathReservoir6 = reservoirs.data[n];
					if (bathReservoir6.IsLiveReservoir())
					{
						float num13 = ((num12 > 0f) ? (num11 * (bathReservoir6.currWaterStorage / num12)) : 0f);
						bathReservoir6.waterConsumption = bathReservoir6.GroupIntake() + num13;
						bathReservoir6.currWaterStorage = Mathff.Clamp(bathReservoir6.currWaterStorage - num13 * deltaTime, 0f, BathReservoir.MAX_WATER_STORAGE);
					}
				}
			}
			float num14 = 0f;
			for (int num15 = 0; num15 < reservoirs.Count; num15++)
			{
				if (reservoirs.data[num15].ParticipatesInComplexWater())
				{
					num14 += reservoirs.data[num15].currWaterStorage;
				}
			}
			storage = num14;
			wProduction = num3;
		}

		private void UpdateDemandDecision()
		{
			float num = wConsumption;
			if (num <= 0f)
			{
				waterViable = true;
				runningOnReserves = false;
				float num2 = 0f;
				for (int i = 0; i < reservoirs.Count; i++)
				{
					BathReservoir bathReservoir = reservoirs.data[i];
					bathReservoir.bandTarget = ((bathReservoir.IsLiveReservoir() && bathReservoir.currWaterStorage < BathReservoir.MAX_WATER_STORAGE) ? 1f : 0f);
					num2 += bathReservoir.bandTarget;
				}
				SetGroupSolverDemand(num2, 0f);
				return;
			}
			float groupAchievablePull = AqueductFlowController.GetGroupAchievablePull(this);
			bool flag = groupAchievablePull >= num - 0.5f;
			bool flag2 = storage > 0.5f;
			bool flag3 = waterViable;
			if (waterViable)
			{
				if (!flag && !flag2)
				{
					waterViable = false;
				}
			}
			else if (flag)
			{
				waterViable = true;
			}
			if (waterViable != flag3)
			{
				AqueductFlowDiagnostics.Note(string.Format("group#{0} latch {1} achievable={2:F1} committed={3:F1} need={4:F1} storage={5:F0}", id, flag3 ? "viable->STARVED" : "starved->VIABLE", groupAchievablePull, AqueductFlowController.GetGroupCommittedPull(this), num, storage));
			}
			runningOnReserves = (waterViable && !flag) & flag2;
			float share = ((contributingReservoirs > 0) ? (num / (float)contributingReservoirs) : 0f);
			float num3 = 0f;
			for (int j = 0; j < reservoirs.Count; j++)
			{
				BathReservoir bathReservoir2 = reservoirs.data[j];
				if (bathReservoir2.IsLiveReservoir())
				{
					bathReservoir2.UpdateBand(share);
					num3 += bathReservoir2.bandTarget;
				}
				else
				{
					bathReservoir2.bandTarget = 0f;
				}
			}
			if (waterViable)
			{
				SetGroupSolverDemand(num3, 0f);
			}
			else
			{
				SetGroupSolverDemand(num + 3f, num);
			}
		}

		private void SetGroupSolverDemand(float demand, float minServe)
		{
			if (Mathff.Abs(solverDemand - demand) > 0.5f || Mathff.Abs(solverMinServe - minServe) > 0.5f)
			{
				AqueductFlowDiagnostics.Note($"group#{id} demand {solverDemand:F1}->{demand:F1} floor {solverMinServe:F1}->{minServe:F1}");
				solverDemand = demand;
				solverMinServe = minServe;
				AqueductFlowController.MarkDemandDirty("SetGroupSolverDemand");
			}
		}

		public string GetWaterWarningTerm()
		{
			if (wConsumption <= 0f)
			{
				return null;
			}
			if (hasWater)
			{
				if (!runningOnReserves)
				{
					return null;
				}
				return "workerui_bathui_warning_drainingreserves";
			}
			if (connectedReservoirs == 0)
			{
				return "workerui_bathui_warning_connectaqueduct";
			}
			if (IsWaterEnRoute())
			{
				return null;
			}
			if (!waterViable && AqueductFlowController.GetGroupRolledBack(this))
			{
				return "workerui_bathui_warning_supplysuspended";
			}
			if (!(wProduction > 0f))
			{
				return "workerui_bathui_warning_nowaterarriving";
			}
			return "workerui_bathui_warning_supplyshortfall";
		}

		public bool IsWaterEnRoute()
		{
			if (wConsumption < 1f)
			{
				return false;
			}
			if (AqueductBuilding.WaterHasArrived(AqueductFlowController.GetGroupCommittedPull(this), wConsumption))
			{
				return !AqueductBuilding.WaterHasArrived(wProduction, wConsumption);
			}
			return false;
		}

		public void SetWaterPriority(WaterPriority priority)
		{
			for (int i = 0; i < reservoirs.Count; i++)
			{
				reservoirs.data[i].solverPriority = (int)priority;
			}
			if (RecomputePriorityFromReservoirs())
			{
				AqueductFlowController.MarkDemandDirty("SetWaterPriority");
			}
		}

		public bool RecomputePriorityFromReservoirs()
		{
			int num = 0;
			bool flag = false;
			for (int i = 0; i < reservoirs.Count; i++)
			{
				int num2 = reservoirs.data[i].solverPriority;
				if (!flag || num2 > num)
				{
					num = num2;
					flag = true;
				}
			}
			if (solverPriority == num)
			{
				return false;
			}
			solverPriority = num;
			return true;
		}

		public void CalculateBonuses()
		{
			ResetBonuses();
			for (int i = 0; i < pGroups.Count; i++)
			{
				PoolGroup poolGroup = pGroups.data[i];
				int num = poolGroup.pools.Count;
				if (num < 1)
				{
					continue;
				}
				if (num < 6)
				{
					if (poolGroup.heatType == 0)
					{
						hasSmallColdPool = true;
						if (hasWater)
						{
							ApplyBonus(ref isSmallColdPoolActive, 1);
						}
					}
					else
					{
						if (poolGroup.heatType != 1)
						{
							continue;
						}
						hasSmallHeatedPool = true;
						hasRequiredWorkersForSmallHeatPool = poolGroup.isHeated;
						if (hasWater && poolGroup.isHeated)
						{
							ApplyBonus(ref isSmallHeatedPoolActive, 1);
						}
						else
						{
							if (hasRequiredWorkersForSmallHeatPool)
							{
								continue;
							}
							int num2 = 0;
							while (true)
							{
								if (num2 < num)
								{
									if (!(poolGroup.pools.data[num2].b.GetWorkerPercent() >= 1f))
									{
										hasRequiredWorkersForSmallHeatPool = false;
										break;
									}
									num2++;
									continue;
								}
								hasRequiredWorkersForSmallHeatPool = true;
								break;
							}
						}
					}
				}
				else if (num < 12)
				{
					if (poolGroup.heatType == 0)
					{
						hasMediumColdPool = true;
						if (hasWater)
						{
							ApplyBonus(ref isMediumColdPoolActive, 4);
						}
					}
					else
					{
						if (poolGroup.heatType != 1)
						{
							continue;
						}
						hasMediumHeatedPool = true;
						hasRequiredWorkersForMediumHeatPool = poolGroup.isHeated;
						if (hasWater && poolGroup.isHeated)
						{
							ApplyBonus(ref isMediumHeatedPoolActive, 4);
						}
						else
						{
							if (hasRequiredWorkersForMediumHeatPool)
							{
								continue;
							}
							int num3 = 0;
							while (true)
							{
								if (num3 < num)
								{
									if (!(poolGroup.pools.data[num3].b.GetWorkerPercent() >= 1f))
									{
										hasRequiredWorkersForMediumHeatPool = false;
										break;
									}
									num3++;
									continue;
								}
								hasRequiredWorkersForMediumHeatPool = true;
								break;
							}
						}
					}
				}
				else if (poolGroup.heatType == 0)
				{
					hasLargeColdPool = true;
					if (hasWater)
					{
						ApplyBonus(ref isLargeColdPoolActive, 6);
					}
				}
				else
				{
					if (poolGroup.heatType != 1)
					{
						continue;
					}
					hasLargeHeatedPool = true;
					hasRequiredWorkersForLargeHeatPool = poolGroup.isHeated;
					if (hasWater && poolGroup.isHeated)
					{
						ApplyBonus(ref isLargeHeatedPoolActive, 6);
					}
					else
					{
						if (hasRequiredWorkersForLargeHeatPool)
						{
							continue;
						}
						int num4 = 0;
						while (true)
						{
							if (num4 < num)
							{
								if (!(poolGroup.pools.data[num4].b.GetWorkerPercent() >= 1f))
								{
									hasRequiredWorkersForLargeHeatPool = false;
									break;
								}
								num4++;
								continue;
							}
							hasRequiredWorkersForLargeHeatPool = true;
							break;
						}
					}
				}
			}
			int num5 = libraries.Count;
			if (num5 >= 1)
			{
				if (num5 < 3)
				{
					ApplyBonus(ref hasSmallLibrary, 1);
				}
				else if (num5 < 6)
				{
					ApplyBonus(ref hasMediumLibrary, 2);
				}
				else
				{
					ApplyBonus(ref hasLargeLibrary, 3);
				}
			}
			int num6 = palaestras.Count;
			if (num6 >= 1)
			{
				if (num6 < 3)
				{
					ApplyBonus(ref hasSmallPalaestra, 1);
				}
				else if (num6 < 6)
				{
					ApplyBonus(ref hasMediumPalaestra, 2);
				}
				else
				{
					ApplyBonus(ref hasLargePalaestra, 3);
				}
			}
			int num7 = gardens.Count;
			if (num7 >= 1)
			{
				if (num7 < 3)
				{
					ApplyBonus(ref hasSmallGarden, 1);
				}
				else if (num7 < 6)
				{
					ApplyBonus(ref hasMediumGarden, 2);
				}
				else
				{
					ApplyBonus(ref hasLargeGarden, 3);
				}
			}
			if (bonusCount >= 3)
			{
				totalBonuses++;
			}
			if (bonusCount >= 6)
			{
				totalBonuses++;
			}
			if (bonusCount >= 9)
			{
				totalBonuses += 2;
			}
			int radius = Mathff.Min(10, 4 + Mathf.FloorToInt((float)(pools.Count + libraries.Count + palaestras.Count + gardens.Count + reservoirs.Count) / 4f));
			SetRadiusBonuses(radius, totalBonuses);
		}

		private void SetRadiusBonuses(int radius, int happiness)
		{
			for (int i = 0; i < radBonuses.Count; i++)
			{
				RadiusBonus radiusBonus = radBonuses.data[i];
				if ((int)radiusBonus.radiusMax != radius || radiusBonus.Happiness != happiness)
				{
					if (radiusBonus.applied)
					{
						radiusBonus.RemoveBonus();
					}
					radiusBonus.radiusMax = radius;
					radiusBonus.Happiness = happiness;
					radiusBonus.ApplyBonus();
				}
			}
		}

		public void ApplyBonus(ref bool val, int bonus)
		{
			if (!val)
			{
				bonusCount++;
				totalBonuses += bonus;
			}
			val = true;
		}

		public void ResetBonuses()
		{
			bonusCount = 0;
			totalBonuses = 0;
			hasSmallHeatedPool = (hasMediumHeatedPool = (hasLargeHeatedPool = false));
			hasSmallColdPool = (hasMediumColdPool = (hasLargeColdPool = false));
			hasSmallLibrary = (hasMediumLibrary = (hasLargeLibrary = false));
			hasSmallPalaestra = (hasMediumPalaestra = (hasLargePalaestra = false));
			hasSmallGarden = (hasMediumGarden = (hasLargeGarden = false));
			isSmallColdPoolActive = (isMediumColdPoolActive = (isLargeColdPoolActive = false));
			isSmallHeatedPoolActive = (isMediumHeatedPoolActive = (isLargeHeatedPoolActive = false));
			hasRequiredWorkersForSmallHeatPool = (hasRequiredWorkersForMediumHeatPool = (hasRequiredWorkersForLargeHeatPool = false));
		}

		public void AddPool(BathPool pool)
		{
			pools.Add(pool);
			AddHighlight(pool.b);
			AddRadiusBonus(pool.b);
		}

		public void RemovePool(BathPool pool)
		{
			RemoveHighlight(pool.b);
			RemoveRadiusBonus(pool.b);
			pools.RemoveSwap(pool);
		}

		public void AddReservoir(BathReservoir reservoir)
		{
			reservoirs.Add(reservoir);
			reservoir.Group = this;
			AddHighlight(reservoir.b);
			AddRadiusBonus(reservoir.b);
			OnMembershipChanged();
		}

		public void RemoveReservoir(BathReservoir reservoir)
		{
			if (reservoir.Group == this)
			{
				reservoir.Group = null;
			}
			RemoveHighlight(reservoir.b);
			RemoveRadiusBonus(reservoir.b);
			reservoirs.RemoveSwap(reservoir);
			OnMembershipChanged();
		}

		private void OnMembershipChanged()
		{
			AqueductFlowController.MarkTopologyDirty("OnMembershipChanged");
		}

		public void AddPalaestra(BathPalaestra palaestra)
		{
			palaestras.Add(palaestra);
			AddHighlight(palaestra.b);
			AddRadiusBonus(palaestra.b);
		}

		public void RemovePalaestra(BathPalaestra palaestra)
		{
			RemoveHighlight(palaestra.b);
			RemoveRadiusBonus(palaestra.b);
			palaestras.RemoveSwap(palaestra);
		}

		public void AddLibrary(BathLibrary library)
		{
			libraries.Add(library);
			AddHighlight(library.b);
			AddRadiusBonus(library.b);
		}

		public void RemoveLibrary(BathLibrary library)
		{
			RemoveHighlight(library.b);
			RemoveRadiusBonus(library.b);
			libraries.RemoveSwap(library);
		}

		public void AddGarden(BathGarden garden)
		{
			gardens.Add(garden);
			AddHighlight(garden.b);
			AddRadiusBonus(garden.b);
		}

		public void RemoveGarden(BathGarden garden)
		{
			RemoveHighlight(garden.b);
			RemoveRadiusBonus(garden.b);
			gardens.RemoveSwap(garden);
		}

		public void AddHighlight(Building b)
		{
			ObjectHighlighter item = ObjectHighlighter.SetupOutlines(b.gameObject, b.meshesRequiringOutline, null);
			highlights.Add(item);
		}

		public void RemoveHighlight(Building b)
		{
			for (int i = 0; i < highlights.Count; i++)
			{
				if (!(highlights.data[i].go != b.gameObject))
				{
					highlights.RemoveAt(i);
					break;
				}
			}
		}

		public void AddRadiusBonus(Building b)
		{
			RadiusBonus component = b.GetComponent<RadiusBonus>();
			radBonuses.Add(component);
		}

		public void RemoveRadiusBonus(Building b)
		{
			RadiusBonus component = b.GetComponent<RadiusBonus>();
			radBonuses.RemoveSwap(component);
		}

		public void Reset()
		{
			pools.ClearFast();
			reservoirs.ClearFast();
			palaestras.ClearFast();
			libraries.ClearFast();
			gardens.ClearFast();
			highlights.Clear();
		}
	}

	public static BathManager inst;

	private const bool debug = false;

	private static ArrayExt<BathGroup> FloodFilledBathGroups = new ArrayExt<BathGroup>(4);

	private static ArrayExt<BathGroup.PoolGroup> FloodFilledPoolGroups = new ArrayExt<BathGroup.PoolGroup>(4);

	private bool[] hasVisited;

	private ArrayExt<Cell> openset = new ArrayExt<Cell>(64);

	[NonSerialized]
	public BathCell[] bathCells;

	[NonSerialized]
	public ArrayExt<BathGroup> bathGroups = new ArrayExt<BathGroup>(16);

	public const int POOL_BONUS_SMALL = 1;

	public const int POOL_BONUS_SMALL_REQUIREMENTS = 1;

	public const int POOL_BONUS_MEDIUM = 4;

	public const int POOL_BONUS_MEDIUM_REQUIREMENTS = 6;

	public const int POOL_BONUS_LARGE = 6;

	public const int POOL_BONUS_LARGE_REQUIREMENTS = 12;

	public const int LIBRARY_BONUS_SMALL = 1;

	public const int LIBRARY_BONUS_SMALL_REQUIREMENTS = 1;

	public const int LIBRARY_BONUS_MEDIUM = 2;

	public const int LIBRARY_BONUS_MEDIUM_REQUIREMENTS = 3;

	public const int LIBRARY_BONUS_LARGE = 3;

	public const int LIBRARY_BONUS_LARGE_REQUIREMENTS = 6;

	public const int PALAESTRA_BONUS_SMALL = 1;

	public const int PALAESTRA_BONUS_SMALL_REQUIREMENTS = 1;

	public const int PALAESTRA_BONUS_MEDIUM = 2;

	public const int PALAESTRA_BONUS_MEDIUM_REQUIREMENTS = 3;

	public const int PALAESTRA_BONUS_LARGE = 3;

	public const int PALAESTRA_BONUS_LARGE_REQUIREMENTS = 6;

	public const int GARDEN_BONUS_SMALL = 1;

	public const int GARDEN_BONUS_SMALL_REQUIREMENTS = 1;

	public const int GARDEN_BONUS_MEDIUM = 2;

	public const int GARDEN_BONUS_MEDIUM_REQUIREMENTS = 3;

	public const int GARDEN_BONUS_LARGE = 3;

	public const int GARDEN_BONUS_LARGE_REQUIREMENTS = 6;

	public const int FIRST_BONUS = 1;

	public const int FIRST_BONUS_REQUIREMENTS = 3;

	public const int SECOND_BONUS = 1;

	public const int SECOND_BONUS_REQUIREMENTS = 6;

	public const int THIRD_BONUS = 2;

	public const int THIRD_BONUS_REQUIREMENTS = 9;

	public const int HEAT_TYPE_COLD = 0;

	public const int HEAT_TYPE_HOT = 1;

	private int frameCount;

	private int frameSeparation = 5;

	private static ArrayExt<BathGroup.PoolGroup> sortedPoolGroup = new ArrayExt<BathGroup.PoolGroup>(8);

	private ArrayExtRef<BathGroup> deferPoolCalculation = new ArrayExtRef<BathGroup>(32);

	private void Awake()
	{
		inst = this;
	}

	public void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		for (int i = 0; i < deferPoolCalculation.Count; i++)
		{
			BathGroup bathGroup = deferPoolCalculation.data[i];
			if (bathGroup != null || !bathGroups.Contains(bathGroup))
			{
				CalculatePoolGroups_Internal(bathGroup);
			}
		}
		deferPoolCalculation.ClearFast();
		for (int j = 0; j < bathGroups.Count; j++)
		{
			bathGroups.data[j].IntegrateStorage();
		}
		frameCount++;
		float deltaTime = Time.deltaTime;
		if (frameCount % frameSeparation == 0)
		{
			for (int k = 0; k < bathGroups.Count; k++)
			{
				BathGroup bathGroup2 = bathGroups.data[k];
				bathGroup2.CalculateWater();
				bathGroup2.CalculateBonuses();
				for (int l = 0; l < bathGroup2.pGroups.Count; l++)
				{
					bathGroup2.pGroups.data[l].UpdateHeat(deltaTime, bathGroup2.hasWater);
				}
			}
			return;
		}
		for (int m = 0; m < bathGroups.Count; m++)
		{
			BathGroup bathGroup3 = bathGroups.data[m];
			for (int n = 0; n < bathGroup3.pGroups.Count; n++)
			{
				bathGroup3.pGroups.data[n].UpdateHeat(deltaTime, bathGroup3.hasWater);
			}
		}
	}

	public void Reset()
	{
		int num = World.inst.GridWidth * World.inst.GridHeight;
		if (bathCells == null || bathCells.Length != num)
		{
			bathCells = new BathCell[num];
		}
		else
		{
			for (int i = 0; i < bathCells.Length; i++)
			{
				bathCells[i] = default;
			}
		}
		if (hasVisited == null || hasVisited.Length != num)
		{
			hasVisited = new bool[num];
		}
		else
		{
			Util.Memset(hasVisited, 0);
		}
		bathGroups.ClearFast();
		deferPoolCalculation.ClearFast();
	}

	public void Register(Building b)
	{
		RegisterBathObject(b);
	}

	private void RegisterBathObject(Building b)
	{
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		minX = Mathff.Clamp(minX - 1, 0, gridWidth - 1);
		maxX = Mathff.Clamp(maxX + 1, 0, gridWidth - 1);
		minZ = Mathff.Clamp(minZ - 1, 0, gridHeight - 1);
		maxZ = Mathff.Clamp(maxZ + 1, 0, gridHeight - 1);
		BathGroup bathGroup = null;
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				if ((i == minX && j == minZ) || (i == maxX && j == minZ) || (i == maxX && j == maxZ) || (i == minX && j == maxZ) || (j != minZ && j != maxZ && i != minX && i != maxX))
				{
					continue;
				}
				int num = i + j * gridWidth;
				if (bathGroup != null)
				{
					BathGroup bGroup = bathCells[num].bGroup;
					if (bGroup != null && !bGroup.isMerging && bGroup != bathGroup)
					{
						MergeCopyTo(bGroup, bathGroup);
					}
					continue;
				}
				bathGroup = bathCells[num].bGroup;
				if (bathGroup != null)
				{
					AddBuildingToGroup(b, bathGroup);
					AddGroupToBuildingCells(bathGroup, b);
					bathGroup.isDirty = true;
				}
			}
		}
		if (bathGroup == null)
		{
			bathGroup = new BathGroup();
			AddBuildingToGroup(b, bathGroup);
			AddGroupToBuildingCells(bathGroup, b);
			bathGroup.isDirty = true;
			bathGroups.Add(bathGroup);
		}
		MilestoneManager.inst.CheckBathhouseSizeMilestones(bathGroup);
		DeferCalculatePoolGroups(bathGroup);
	}

	public void Deregister(Building b)
	{
		if (!LoadSave.Loading)
		{
			BathGroup bGroup = bathCells[b.GetCell().index].bGroup;
			DeregisterBathObject(b, bGroup);
		}
	}

	public void DeregisterBathObject(Building b, BathGroup origGroup)
	{
		RemoveBuildingFromGroup(b, origGroup);
		RemovePoolGroupFromBuildingCells(b);
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		minX = Mathff.Clamp(minX - 1, 0, gridWidth - 1);
		maxX = Mathff.Clamp(maxX + 1, 0, gridWidth - 1);
		minZ = Mathff.Clamp(minZ - 1, 0, gridHeight - 1);
		maxZ = Mathff.Clamp(maxZ + 1, 0, gridHeight - 1);
		Util.Memset(hasVisited, 0);
		openset.ClearFast();
		FloodFilledBathGroups.ClearFast();
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				if ((i == minX && j == minZ) || (i == maxX && j == minZ) || (i == maxX && j == maxZ) || (i == minX && j == maxZ) || (j != minZ && j != maxZ && i != minX && i != maxX))
				{
					continue;
				}
				int num = i + j * gridWidth;
				BathGroup bathGroup = bathCells[num].bGroup;
				if (bathGroup == null || hasVisited[num])
				{
					continue;
				}
				if (FloodFilledBathGroups.Contains(bathGroup))
				{
					bathGroup = new BathGroup();
					bathGroups.Add(bathGroup);
				}
				bathGroup.isDirty = true;
				FloodFilledBathGroups.Add(bathGroup);
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(num);
				openset.Add(cellDataUnsafe);
				while (openset.Count > 0)
				{
					Cell cell = openset.PopFirst();
					if (!hasVisited[cell.index])
					{
						hasVisited[cell.index] = true;
						if (origGroup != bathGroup)
						{
							Building b2 = cell.StructureFindByCategory(World.bathCategoryHash);
							AddBuildingToGroup(b2, bathGroup, origGroup);
						}
						bathCells[cell.index].bGroup = bathGroup;
						bathCells[cell.index].pGroup = null;
						AddCardinalBathCellsToOpenSet(openset, cell);
					}
				}
			}
		}
		if (FloodFilledBathGroups.Count == 0)
		{
			bathGroups.RemoveSwap(origGroup);
		}
		for (int k = 0; k < FloodFilledBathGroups.Count; k++)
		{
			DeferCalculatePoolGroups(FloodFilledBathGroups.data[k]);
		}
	}

	private int GetHeatType(BathPool bPool)
	{
		if (bPool == null || bPool.b.uniqueNameHash == World.bathColdPoolHash)
		{
			return 0;
		}
		return 1;
	}

	public void DeferCalculatePoolGroups(BathGroup bGroup)
	{
		for (int i = 0; i < bGroup.pGroups.Count; i++)
		{
			BathGroup.PoolGroup poolGroup = bGroup.pGroups.data[i];
			for (int j = 0; j < poolGroup.pools.Count; j++)
			{
				RemovePoolGroupFromBuildingCells(poolGroup.pools.data[j].b);
			}
		}
		bGroup.pGroups.Clear();
		if (!deferPoolCalculation.Contains(bGroup))
		{
			deferPoolCalculation.Add(bGroup);
		}
	}

	private void CalculatePoolGroups_Internal(BathGroup bGroup)
	{
		if (bGroup.pools.Count == 0)
		{
			return;
		}
		Util.Memset(hasVisited, 0);
		for (int i = 0; i < bGroup.pools.Count; i++)
		{
			BathPool bathPool = bGroup.pools.data[i];
			Cell cell = bathPool.b.GetCell();
			if (hasVisited[cell.index])
			{
				continue;
			}
			openset.ClearFast();
			openset.Add(cell);
			int heatType = GetHeatType(bathPool);
			BathGroup.PoolGroup poolGroup = new BathGroup.PoolGroup(heatType);
			while (openset.Count > 0)
			{
				Cell cell2 = openset.PopFirst();
				if (!hasVisited[cell2.index])
				{
					Building building = null;
					BathPool bathPool2 = null;
					if ((building = cell2.StructureFind<BathPool>()) == null || (bathPool2 = building.GetComponent<BathPool>()) == null)
					{
						hasVisited[cell2.index] = true;
					}
					else if (GetHeatType(bathPool2) == heatType)
					{
						hasVisited[cell2.index] = true;
						poolGroup.pools.Add(bathPool2);
						bathCells[cell2.index].pGroup = poolGroup;
						AddCardinalBathCellsToOpenSet(openset, cell2);
					}
				}
			}
			bGroup.pGroups.Add(poolGroup);
		}
		bGroup.isDirty = true;
	}

	private void AddCardinalBathCellsToOpenSet(ArrayExt<Cell> openset, Cell cell)
	{
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		int num2 = cell.x + 1 + cell.z * gridWidth;
		if (num2 >= 0 && num2 < num && bathCells[num2].bGroup != null)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
		num2 = cell.x + (cell.z + 1) * gridWidth;
		if (num2 >= 0 && num2 < num && bathCells[num2].bGroup != null)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
		num2 = cell.x - 1 + cell.z * gridWidth;
		if (num2 >= 0 && num2 < num && bathCells[num2].bGroup != null)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
		num2 = cell.x + (cell.z - 1) * gridWidth;
		if (num2 >= 0 && num2 < num && bathCells[num2].bGroup != null)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
	}

	private void AddCardinalPoolCellsToOpenSet(ArrayExt<Cell> openset, Cell cell, int heatType)
	{
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		int num2 = cell.x + 1 + cell.z * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(num2);
			if (bathCells[num2].pGroup != null && bathCells[num2].pGroup.heatType == heatType)
			{
				openset.Add(cellDataUnsafe);
			}
		}
		num2 = cell.x + (cell.z + 1) * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			Cell cellDataUnsafe2 = World.inst.GetCellDataUnsafe(num2);
			if (bathCells[num2].pGroup != null && bathCells[num2].pGroup.heatType == heatType)
			{
				openset.Add(cellDataUnsafe2);
			}
		}
		num2 = cell.x - 1 + cell.z * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			Cell cellDataUnsafe3 = World.inst.GetCellDataUnsafe(num2);
			if (bathCells[num2].pGroup != null && bathCells[num2].pGroup.heatType == heatType)
			{
				openset.Add(cellDataUnsafe3);
			}
		}
		num2 = cell.x + (cell.z - 1) * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			Cell cellDataUnsafe4 = World.inst.GetCellDataUnsafe(num2);
			if (bathCells[num2].pGroup != null && bathCells[num2].pGroup.heatType == heatType)
			{
				openset.Add(cellDataUnsafe4);
			}
		}
	}

	public void MergeCopyTo(BathGroup source, BathGroup target)
	{
		if (source != target)
		{
			source.isMerging = true;
			for (int i = 0; i < source.pGroups.Count; i++)
			{
				target.pGroups.Add(source.pGroups.data[i]);
			}
			for (int j = 0; j < source.pools.Count; j++)
			{
				BathPool bathPool = source.pools.data[j];
				target.AddPool(bathPool);
				AddGroupToBuildingCells(target, bathPool.b);
			}
			for (int k = 0; k < source.reservoirs.Count; k++)
			{
				BathReservoir bathReservoir = source.reservoirs.data[k];
				target.AddReservoir(bathReservoir);
				AddGroupToBuildingCells(target, bathReservoir.b);
			}
			for (int l = 0; l < source.palaestras.Count; l++)
			{
				BathPalaestra bathPalaestra = source.palaestras.data[l];
				target.AddPalaestra(bathPalaestra);
				AddGroupToBuildingCells(target, bathPalaestra.b);
			}
			for (int m = 0; m < source.libraries.Count; m++)
			{
				BathLibrary bathLibrary = source.libraries.data[m];
				target.AddLibrary(bathLibrary);
				AddGroupToBuildingCells(target, bathLibrary.b);
			}
			for (int n = 0; n < source.gardens.Count; n++)
			{
				BathGarden bathGarden = source.gardens.data[n];
				target.AddGarden(bathGarden);
				AddGroupToBuildingCells(target, bathGarden.b);
			}
			target.isDirty = true;
			bathGroups.RemoveSwap(source);
		}
	}

	public void MergeCopyTo(BathGroup bGroup, BathGroup.PoolGroup source, BathGroup.PoolGroup target)
	{
		if (source != target)
		{
			source.isMerging = true;
			for (int i = 0; i < source.pools.Count; i++)
			{
				BathPool bathPool = source.pools.data[i];
				target.pools.Add(bathPool);
				AddGroupToBuildingCells(target, bathPool.b);
			}
			bGroup.pGroups.RemoveSwap(source);
		}
	}

	public void AddGroupToBuildingCells(BathGroup bGroup, Building b)
	{
		int gridWidth = World.inst.GridWidth;
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				int num = i + j * gridWidth;
				bathCells[num].bGroup = bGroup;
			}
		}
	}

	public void AddGroupToBuildingCells(BathGroup.PoolGroup pGroup, Building b)
	{
		int gridWidth = World.inst.GridWidth;
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				int num = i + j * gridWidth;
				bathCells[num].pGroup = pGroup;
			}
		}
	}

	public void RemoveBathGroupFromBuildingCells(Building b)
	{
		int gridWidth = World.inst.GridWidth;
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				int num = i + j * gridWidth;
				bathCells[num].bGroup = null;
			}
		}
	}

	public void RemovePoolGroupFromBuildingCells(Building b)
	{
		int gridWidth = World.inst.GridWidth;
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				int num = i + j * gridWidth;
				bathCells[num].pGroup = null;
			}
		}
	}

	private void AddBuildingToGroup(Building b, BathGroup group, BathGroup toRemoveFrom = null)
	{
		BathPool component;
		BathReservoir component2;
		BathPalaestra component3;
		BathLibrary component4;
		BathGarden component5;
		if ((component = b.GetComponent<BathPool>()) != null)
		{
			group.AddPool(component);
			toRemoveFrom?.RemovePool(component);
			group.isDirty = true;
			if (toRemoveFrom != null)
			{
				toRemoveFrom.isDirty = true;
			}
		}
		else if ((component2 = b.GetComponent<BathReservoir>()) != null)
		{
			group.AddReservoir(component2);
			toRemoveFrom?.RemoveReservoir(component2);
		}
		else if ((component3 = b.GetComponent<BathPalaestra>()) != null)
		{
			group.AddPalaestra(component3);
			toRemoveFrom?.RemovePalaestra(component3);
		}
		else if ((component4 = b.GetComponent<BathLibrary>()) != null)
		{
			group.AddLibrary(component4);
			toRemoveFrom?.RemoveLibrary(component4);
		}
		else if ((component5 = b.GetComponent<BathGarden>()) != null)
		{
			group.AddGarden(component5);
			toRemoveFrom?.RemoveGarden(component5);
		}
	}

	private void RemoveBuildingFromGroup(Building b, BathGroup group)
	{
		if (b.uniqueNameHash == World.bathReservoirHash)
		{
			group.RemoveReservoir(b.GetComponent<BathReservoir>());
		}
		else if (b.uniqueNameHash == World.bathColdPoolHash || b.uniqueNameHash == World.bathHotPoolHash)
		{
			group.RemovePool(b.GetComponent<BathPool>());
		}
		else if (b.uniqueNameHash == World.bathPalaestraHash)
		{
			group.RemovePalaestra(b.GetComponent<BathPalaestra>());
		}
		else if (b.uniqueNameHash == World.bathLibraryHash)
		{
			group.RemoveLibrary(b.GetComponent<BathLibrary>());
		}
		else if (b.uniqueNameHash == World.bathGardenHash)
		{
			group.RemoveGarden(b.GetComponent<BathGarden>());
		}
		RemoveBathGroupFromBuildingCells(b);
	}

	private void RemovePoolBuildingFromGroup(Building b, BathGroup.PoolGroup group)
	{
		group.pools.RemoveSwap(b.GetComponent<BathPool>());
		RemovePoolGroupFromBuildingCells(b);
	}

	public void HighlightGroup(Building b, int colorIdx)
	{
		Cell cell = b.GetCell();
		BathGroup bGroup = bathCells[cell.index].bGroup;
		if (bGroup != null)
		{
			for (int i = 0; i < bGroup.highlights.Count; i++)
			{
				bGroup.highlights.data[i].SetOutlineImmediate(colorIdx);
			}
		}
	}
}
