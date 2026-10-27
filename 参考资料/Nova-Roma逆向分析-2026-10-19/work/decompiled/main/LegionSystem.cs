using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Runtime.Serialization;
using Drawing;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Serialization;

public class LegionSystem : MonoBehaviour
{
	public struct JobPathNode
	{
		public Vector3 waypoint;

		public int index;

		public bool lastNode;
	}

	public enum ObstructionType
	{
		None,
		General,
		Building,
		Mountain
	}

	public struct ObstructionCell
	{
		public ObstructionType oType;

		public int teamId;

		public unsafe fixed bool blocksTeamID[5];
	}

	[Serializable]
	public class RenderData
	{
		public Mesh mesh;

		public Material materialPrefab;

		private Material material;

		private uint[] args;

		internal ComputeBuffer computeBuffer;

		internal ComputeBuffer computeArgs;

		internal NativeArray<float4x4> matrices;

		internal string debugName;

		internal void Dispose()
		{
			if (matrices.IsCreated)
			{
				matrices.Dispose();
			}
			if (computeBuffer != null)
			{
				computeBuffer.Dispose();
				computeBuffer = null;
			}
			if (computeArgs != null)
			{
				computeArgs.Dispose();
				computeArgs = null;
			}
			if (material != null)
			{
				UnityEngine.Object.Destroy(material);
				material = null;
			}
		}

		internal void Init(int count)
		{
			matrices = new NativeArray<float4x4>(1000 * count, Allocator.Persistent);
			if (!(materialPrefab == null))
			{
				computeBuffer = new ComputeBuffer(matrices.Length, 64);
				string text = (string.IsNullOrEmpty(debugName) ? "LegionSystem" : debugName);
				ComputeBufferNaming.SetName(computeBuffer, text + "_MatrixBuffer");
				computeBuffer.SetData(matrices);
				material = UnityEngine.Object.Instantiate(materialPrefab);
				material.SetBuffer("matrixBuffer", computeBuffer);
				args = new uint[5];
				args[0] = ((mesh != null) ? mesh.GetIndexCount(0) : 0u);
				args[1] = (uint)matrices.Length;
				args[2] = ((mesh != null) ? mesh.GetIndexStart(0) : 0u);
				args[3] = ((mesh != null) ? mesh.GetBaseVertex(0) : 0u);
				args[4] = 0u;
				computeArgs = new ComputeBuffer(1, args.Length * 4, ComputeBufferType.DrawIndirect);
				ComputeBufferNaming.SetName(computeArgs, text + "_ArgsBuffer");
				computeArgs.SetData(args);
			}
		}

		public void DrawMeshes(NativeArray<int> drawnSoldiersCount)
		{
			if (!(material == null))
			{
				int num = drawnSoldiersCount[0];
				if (num > 0)
				{
					computeBuffer.SetData(matrices, 0, 0, num);
				}
				args[1] = (uint)num;
				computeArgs.SetData(args);
				Graphics.DrawMeshInstancedIndirect(bounds: new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f)), mesh: mesh, submeshIndex: 0, material: material, bufferWithArgs: computeArgs);
			}
		}
	}

	[Serializable]
	public class LegionDef
	{
		public string name;

		public int recruitUnitType;

		public int teamID;

		public Mesh flagMesh;

		public RenderData shieldRD;

		public RenderData swordRD;

		public RenderData soldierRD;

		internal NativeArray<int> drawnSoldiersCount;

		internal JobHandle jobHandle;

		public void Init(int count)
		{
			drawnSoldiersCount = new NativeArray<int>(1, Allocator.Persistent);
			string arg = (string.IsNullOrEmpty(name) ? $"LegionTeam{teamID}_Type{recruitUnitType}" : name.Replace(' ', '_'));
			shieldRD.debugName = $"{arg}_Team{teamID}_Shield";
			swordRD.debugName = $"{arg}_Team{teamID}_Sword";
			soldierRD.debugName = $"{arg}_Team{teamID}_Soldier";
			shieldRD.Init(count);
			swordRD.Init(count);
			soldierRD.Init(count);
		}

		public void Dispose()
		{
			shieldRD.Dispose();
			swordRD.Dispose();
			soldierRD.Dispose();
			if (drawnSoldiersCount.IsCreated)
			{
				drawnSoldiersCount.Dispose();
			}
		}

		internal void DrawMeshes()
		{
			soldierRD.DrawMeshes(drawnSoldiersCount);
			swordRD.DrawMeshes(drawnSoldiersCount);
			shieldRD.DrawMeshes(drawnSoldiersCount);
		}
	}

	public struct SoldierExtraData
	{
		public float frameMovement;

		public int currentAnimationId;

		public float currentAnimationTime;

		public int loopAnimation;

		public float deathTime;
	}

	[BurstCompile]
	public struct UpdateRenderData : IJob
	{
		public int worldWidth;

		public int worldHeight;

		[ReadOnly]
		public NativeArray<float> heightMap;

		[ReadOnly]
		public NativeArray<float> bridgeHeightMap;

		public NativeArray<LegionCell> lcells;

		public NativeArray<LegionGroup> groups;

		public BlobAssetReference<LegionBurstAnimationBaker.AllAnimations> soldierAnimations;

		public NativeArray<SoldierExtraData> soldierExtraData;

		public NativeArray<Vector3> soldierPositions;

		public NativeArray<Quaternion> soldierRotations;

		public NativeArray<Vector3> soldierScales;

		public NativeArray<float4x4> soldierMatrices;

		public NativeArray<float4x4> swordMatrices;

		public NativeArray<float4x4> shieldMatrices;

		public NativeArray<int> drawnSoldiersCount;

		public float physicsTimeStep;

		public float totalTime;

		public Unity.Mathematics.Random random;

		public int soldierCount;

		public float deltaTime;

		public int teamFilter;

		public int typeFilter;

		public unsafe void Execute()
		{
			drawnSoldiersCount[0] = 0;
			for (int i = 0; i < groups.Length; i++)
			{
				if (groups[i].inUse != 0 && groups[i].isBeingCarried != 1 && groups[i].team == teamFilter && groups[i].type == typeFilter)
				{
					LegionGroup group = groups[i];
					for (int j = 0; j < group.numCells; j++)
					{
						BuildCellDrawMatrices(in group, lcells[group.cells[j]], physicsTimeStep, totalTime);
					}
				}
			}
			for (int k = 0; k < lcells.Length; k++)
			{
				LegionCell cell = lcells[k];
				if (cell.type == typeFilter && cell.dead && cell.inUse)
				{
					BuildCellDrawMatricesForDeath(in cell, physicsTimeStep, totalTime);
				}
			}
		}

		public void PickAnimationState(ref SoldierExtraData soldierExtraDataLocal, int row, bool fighting, int type)
		{
			if (fighting)
			{
				if (type == 5)
				{
					int num = random.NextInt(0, 6);
					if (num >= 0 && num < 3)
					{
						soldierExtraDataLocal.currentAnimationId = 1;
					}
					else if (num >= 3 && num < 5)
					{
						soldierExtraDataLocal.currentAnimationId = random.NextInt(2, 4);
					}
					else
					{
						soldierExtraDataLocal.currentAnimationId = random.NextInt(8, 10);
					}
				}
				else
				{
					switch (row)
					{
					case 0:
						soldierExtraDataLocal.currentAnimationId = random.NextInt(1, 4);
						break;
					case 1:
					{
						int currentAnimationId = 1;
						if (random.NextInt(0, 6) <= 3)
						{
							currentAnimationId = random.NextInt(8, 10);
						}
						soldierExtraDataLocal.currentAnimationId = currentAnimationId;
						break;
					}
					case 2:
						soldierExtraDataLocal.currentAnimationId = random.NextInt(8, 10);
						break;
					default:
						soldierExtraDataLocal.currentAnimationId = 6;
						break;
					}
				}
			}
			else
			{
				soldierExtraDataLocal.currentAnimationId = 5;
			}
			soldierExtraDataLocal.loopAnimation = 1;
		}

		public void BuildCellDrawMatricesForDeath(in LegionCell cell, float dt, float time)
		{
			for (int i = 0; i < soldierCount; i++)
			{
				int index = cell.id * soldierCount + i;
				SoldierExtraData soldierExtraData = this.soldierExtraData[index];
				AnimationPosition(soldierExtraData, 0);
				Quaternion quaternion2 = AnimationRotation(soldierExtraData, 3);
				Vector3 vector = AnimationPosition(soldierExtraData, 6);
				Vector3 vector2 = AnimationPosition(soldierExtraData, 12);
				Quaternion quaternion3 = AnimationRotation(soldierExtraData, 9);
				Quaternion quaternion4 = AnimationRotation(soldierExtraData, 15);
				if (soldierExtraData.deathTime > 0f && soldierExtraData.deathTime - deltaTime <= 0f)
				{
					soldierExtraData.currentAnimationTime = 0f;
					soldierExtraData.currentAnimationId = 7;
					soldierExtraData.loopAnimation = 0;
					soldierRotations[index] *= Quaternion.Euler(0f, random.NextFloat() * 90f - 45f, 0f);
				}
				soldierExtraData.deathTime -= deltaTime;
				soldierExtraData.currentAnimationTime += deltaTime;
				Vector3 vector3 = new Vector3(0f, 0f, 0f);
				int index2 = drawnSoldiersCount[0];
				soldierMatrices[index2] = float4x4.TRS(soldierPositions[index], soldierRotations[index] * quaternion2, soldierScales[index]);
				swordMatrices[index2] = float4x4.TRS(vector3 + soldierPositions[index] + soldierRotations[index] * vector, soldierRotations[index] * quaternion3, Vector3.one);
				shieldMatrices[index2] = float4x4.TRS(vector3 + soldierPositions[index] + soldierRotations[index] * vector2, soldierRotations[index] * quaternion4, Vector3.one);
				drawnSoldiersCount[0]++;
				this.soldierExtraData[index] = soldierExtraData;
			}
		}

		public void BuildCellDrawMatrices(in LegionGroup group, in LegionCell cell, float dt, float time)
		{
			Quaternion quaternion2 = Quaternion.LookRotation(cell.direction);
			int num = Mathf.RoundToInt(Mathf.Sqrt(soldierCount));
			float num2 = 1f;
			if (cell.attackingCellId != -1)
			{
				num2 = 0.8f;
			}
			for (int i = 0; i < soldierCount; i++)
			{
				float num3 = 1f / (float)num;
				float num4 = (float)(i % num) * num3 - 0.5f + num3 / 2f;
				float num5 = (float)(i / num) * num3 * num2 - (0.5f - (1f - num2)) + num3 / 2f;
				if (group.flipOffset)
				{
					num5 = (float)(i / num) * num3 * num2 - 0.5f + num3 / 2f;
				}
				int index = cell.id * soldierCount + i;
				SoldierExtraData soldierExtraDataLocal = soldierExtraData[index];
				int num6 = num - 1 - i / num;
				if (group.flipOffset)
				{
					num6 = num - 1 - num6;
				}
				Vector3 vector = quaternion2 * new Vector3(num4, 0f, num5);
				if (group.flipOffset)
				{
					vector = quaternion2 * new Vector3(0f - num4, 0f, 0f - num5);
				}
				Vector3 vector2 = cell.position + vector;
				vector2.y = 0f;
				if (soldierExtraDataLocal.currentAnimationId == 0)
				{
					PickAnimationState(ref soldierExtraDataLocal, num6, cell.attackingCellId != -1, group.type);
				}
				float duration = soldierAnimations.Value.Animations[soldierExtraDataLocal.currentAnimationId - 1].Curves[0].Duration;
				if (soldierExtraDataLocal.currentAnimationTime > duration && soldierExtraDataLocal.loopAnimation == 1)
				{
					soldierExtraDataLocal.currentAnimationTime = 0f;
					PickAnimationState(ref soldierExtraDataLocal, num6, cell.attackingCellId != -1, group.type);
				}
				vector2.y = SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, vector2, out var _);
				float num7 = Vector3.Distance(soldierPositions[index], vector2);
				float num8 = Mathff.Clamp01(num7 / 0.1f);
				float num9 = (Mathf.Sin(time * 20f + (float)i + (float)i * 100f * (float)group.id) * 0.5f + 0.5f) * 0.03f * num8;
				Vector3 vector3 = AnimationPosition(soldierExtraDataLocal, 0);
				Quaternion quaternion3 = AnimationRotation(soldierExtraDataLocal, 3);
				Vector3 vector4 = AnimationPosition(soldierExtraDataLocal, 6);
				Vector3 vector5 = AnimationPosition(soldierExtraDataLocal, 12);
				Quaternion quaternion4 = AnimationRotation(soldierExtraDataLocal, 9);
				Quaternion quaternion5 = AnimationRotation(soldierExtraDataLocal, 15);
				if (Vector3.Distance(soldierPositions[index], vector2) > 1f)
				{
					soldierPositions[index] = vector2;
				}
				float num10 = Mathff.Clamp(num7 * 6f + (float)i * 0.01f, 0.1f, 10f);
				soldierPositions[index] = Mathff.MoveTowards(soldierPositions[index], vector2, deltaTime * num10);
				Vector3 vector6 = soldierPositions[index] + quaternion2 * vector3;
				vector6.y += num9;
				soldierRotations[index] = Quaternion.Lerp(soldierRotations[index], quaternion2, deltaTime * 4f);
				soldierExtraDataLocal.currentAnimationTime += deltaTime;
				Vector3 vector7 = new Vector3(0f, 0f, 0f);
				if (group.type == 5)
				{
					vector7 = new Vector3(0f, 0.1f, 0f);
				}
				int index2 = drawnSoldiersCount[0];
				soldierMatrices[index2] = float4x4.TRS(vector6, soldierRotations[index] * quaternion3, soldierScales[index]);
				swordMatrices[index2] = float4x4.TRS(vector7 + soldierPositions[index] + soldierRotations[index] * vector4, soldierRotations[index] * quaternion4, Vector3.one);
				shieldMatrices[index2] = float4x4.TRS(vector7 + soldierPositions[index] + soldierRotations[index] * vector5, soldierRotations[index] * quaternion5, Vector3.one);
				drawnSoldiersCount[0]++;
				soldierExtraData[index] = soldierExtraDataLocal;
			}
		}

		public Vector3 AnimationPosition(SoldierExtraData ed, int entityId)
		{
			if (!soldierAnimations.IsCreated)
			{
				Debug.LogError("soldierAnimations is not created!");
				return Vector3.zero;
			}
			if (ed.currentAnimationId <= 0 || ed.currentAnimationId > soldierAnimations.Value.Animations.Length)
			{
				Debug.LogError($"Invalid animation ID: {ed.currentAnimationId}. Total animations: {soldierAnimations.Value.Animations.Length}");
				return Vector3.zero;
			}
			ref LegionBurstAnimationBaker.OneAnimation reference = ref soldierAnimations.Value.Animations[ed.currentAnimationId - 1];
			if (reference.Curves.Length <= entityId + 2)
			{
				Debug.LogError($"Invalid curve index: {entityId}. Total curves: {reference.Curves.Length}");
				return Vector3.zero;
			}
			return new Vector3(reference.Curves[entityId].Evaluate(ed.currentAnimationTime), reference.Curves[entityId + 1].Evaluate(ed.currentAnimationTime), reference.Curves[entityId + 2].Evaluate(ed.currentAnimationTime));
		}

		public Quaternion AnimationRotation(SoldierExtraData ed, int entityId)
		{
			return Quaternion.Euler(soldierAnimations.Value.Animations[ed.currentAnimationId - 1].Curves[entityId].Evaluate(ed.currentAnimationTime), soldierAnimations.Value.Animations[ed.currentAnimationId - 1].Curves[entityId + 1].Evaluate(ed.currentAnimationTime), soldierAnimations.Value.Animations[ed.currentAnimationId - 1].Curves[entityId + 2].Evaluate(ed.currentAnimationTime));
		}
	}

	[BurstCompile]
	public struct UpdateGroups : IJob
	{
		private delegate void ActionRef<T>(ref T item);

		public CommandBuilder commandBuilder;

		public bool debug;

		public int physicsUpdateCount;

		public float physicsTimeStep;

		public float cellDamping;

		public float uphillDamping;

		public float maxUphillInclineDampening;

		public float antiPenetrationForce;

		public float cellAccel;

		public float cellAccelForCharge;

		public float springConstant;

		public float springBreakThreshold;

		public bool doDamage;

		public float normalPepDrain;

		public float idleRecoup;

		public float walkingDrainForCharge;

		public float groupFightingRange;

		public float moralePointReduction;

		public float cellFightingRange;

		public float cellBlockingAngle;

		public float spearThrowRange;

		public float heightAdvantageMaxHeight;

		public float heightAdvantagePercentBonus;

		public bool isFrenzied;

		[ReadOnly]
		public NativeArray<float> heightMap;

		[ReadOnly]
		public NativeArray<float> bridgeHeightMap;

		public NativeArray<LegionCell> lcells;

		public NativeArray<LegionGroup> groups;

		public NativeArray<JobPathNode> nextPositions;

		public NativeArray<int> nextPositionsIndex;

		public int worldWidth;

		public int worldHeight;

		public int soldierCount;

		public NativeArray<ObstructionCell> obstructionMap;

		public NativeArray<float> leftRightObstructionCooldowns;

		public Unity.Mathematics.Random random;

		public NativeArray<SoldierExtraData> soldierExtraData;

		[ReadOnly]
		public NativeArray<DynamicWater.WaterCell> waterGrid;

		[ReadOnly]
		public NativeArray<float> waterFlow;

		public int waterMeshWidth;

		public float waterPepDrain;

		public float waterFlowDamageThreshold;

		public static readonly int formationCount = 4;

		public unsafe void Execute()
		{
			for (int i = 0; i < physicsUpdateCount; i++)
			{
				UpdatePhysics(physicsTimeStep);
				for (int j = 0; j < groups.Length; j++)
				{
					LegionGroup group = groups[j];
					if (GroupValid(ref group))
					{
						UpdateFacing(ref group);
						UpdateGroupPhysics(ref group);
						UpdateCellsPhysics(ref group, physicsTimeStep);
						SaveGroup(group);
					}
				}
			}
			float num = physicsTimeStep * (float)physicsUpdateCount;
			for (int k = 0; k < groups.Length; k++)
			{
				if (groups[k].inUse != 0)
				{
					if (groups[k].dead == 1)
					{
						LegionGroup value = groups[k];
						value.deadTime += num;
						groups[k] = value;
					}
					else
					{
						UpdateLogic(groups[k].id, num);
					}
				}
			}
			UpdateDeadCells(num);
			if (!debug)
			{
				return;
			}
			for (int l = 0; l < groups.Length; l++)
			{
				LegionGroup group2 = groups[l];
				if (GroupValid(ref group2))
				{
					Vector3* corners = stackalloc Vector3[4];
					GetCorners(ref corners, lcells[groups[l].leaderCellId].position, group2.facing, (float)group2.numCells * 0.5f);
					Vector3 vector = new Vector3(0f, lcells[groups[l].leaderCellId].position.y, 0f);
					commandBuilder.Line(*corners + vector, corners[1] + vector);
					commandBuilder.Line(corners[1] + vector, corners[2] + vector);
					commandBuilder.Line(corners[2] + vector, corners[3] + vector);
					commandBuilder.Line(corners[3] + vector, *corners + vector);
				}
			}
		}

		private unsafe void UpdatePhysics(float dt)
		{
			int length = groups.Length;
			for (int i = 0; i < length; i++)
			{
				LegionGroup group = groups[i];
				if (!GroupValid(ref group))
				{
					continue;
				}
				for (int j = 0; j < group.numCells; j++)
				{
					LegionCell value = lcells[group.cells[j]];
					value.hitObstruction = false;
					value.contactNormal = Vector3.zero;
					for (int k = i; k < length; k++)
					{
						LegionGroup group2 = groups[k];
						if (!GroupValid(ref group2) || i == k)
						{
							continue;
						}
						for (int l = 0; l < group2.numCells; l++)
						{
							LegionCell value2 = lcells[group2.cells[l]];
							if (value.id == value2.id)
							{
								continue;
							}
							float num = 0.9f;
							if (group.team == group2.team && group.AttackTargetId == -1 && group2.AttackTargetId == -1)
							{
								num = 0f;
							}
							if (Mathff.DistSqrd(value.position, value2.position) <= num * num)
							{
								Vector3 vector = value.position - value2.position;
								vector.y = 0f;
								Vector3 normalized = vector.normalized;
								float num2 = 1f - vector.magnitude;
								float num3 = 0.5f;
								float num4 = 0.5f;
								float num5 = value.velocity.magnitude;
								if (value.attackingCellId != -1 || group.beingAttackedTime > 0f)
								{
									num5 *= 0.5f;
								}
								float num6 = value2.velocity.magnitude;
								if (value2.attackingCellId != -1 || group2.beingAttackedTime > 0f)
								{
									num6 *= 0.5f;
								}
								float num7 = num5 + num6;
								if (num7 > 0f)
								{
									num3 = num5 / num7;
									num4 = num6 / num7;
								}
								value.acceleration += normalized * num2 * num3 * antiPenetrationForce;
								value2.acceleration += -normalized * num2 * num4 * antiPenetrationForce;
								if (value.attackingCellId == -1 || group.beingAttackedTime > 0f)
								{
									value.contactNormal += normalized;
									value.hitObstruction = true;
								}
								if (value2.attackingCellId == -1 || group2.beingAttackedTime > 0f)
								{
									value2.contactNormal += -normalized;
									value2.hitObstruction = true;
								}
								lcells[value.id] = value;
								lcells[value2.id] = value2;
							}
						}
					}
					Vector3 position = value.position;
					int num8 = (int)position.x;
					int num9 = (int)position.z;
					int num10 = Mathff.Clamp(num8 - 1, 0, worldWidth - 1);
					int num11 = Mathff.Clamp(num9 - 1, 0, worldHeight - 1);
					int num12 = Mathff.Clamp(num8 + 1, 0, worldWidth - 1);
					int num13 = Mathff.Clamp(num9 + 1, 0, worldHeight - 1);
					if (!IsObstructedFor(num8, num9, group.team, obstructionMap, worldWidth))
					{
						for (int m = num10; m <= num12; m++)
						{
							for (int n = num11; n <= num13; n++)
							{
								if ((m == num8 && n == num9) || !IsObstructedFor(m, n, group.team, obstructionMap, worldWidth))
								{
									continue;
								}
								Vector3 vector2 = new Vector3((float)m + 0.5f, 0f, (float)n + 0.5f);
								bool flag = false;
								if ((IsObstructedFor(n + 1, m, group.team, obstructionMap, worldWidth) && IsObstructedFor(n - 1, m, group.team, obstructionMap, worldWidth)) || (IsObstructedFor(n, m + 1, group.team, obstructionMap, worldWidth) && IsObstructedFor(n, m - 1, group.team, obstructionMap, worldWidth)))
								{
									flag = true;
									if (debug)
									{
										commandBuilder.SphereOutline(vector2, 0.5f, Color.cyan);
									}
								}
								if (flag)
								{
									float num14 = 0.49f;
									Vector3 vector3 = Mathff.ClosestPointOnBoxXZ(new Vector3(m, 0f, n), new Vector3(m + 1, 0f, n + 1), position);
									if (Vector3.Distance(vector3, position) <= num14)
									{
										Vector3 vector4 = position - vector3;
										vector4.y = 0f;
										Vector3 normalized2 = vector4.normalized;
										float num15 = num14 - vector4.magnitude;
										value.acceleration += normalized2 * num15 * antiPenetrationForce;
										value.hitObstruction = true;
										value.contactNormal += normalized2;
									}
								}
								else
								{
									Vector3 vector5 = position - vector2;
									vector5.y = 0f;
									if (vector5.magnitude < 1f)
									{
										Vector3 normalized3 = vector5.normalized;
										float num16 = 1f - vector5.magnitude;
										value.acceleration += normalized3 * num16 * antiPenetrationForce;
										lcells[value.id] = value;
										value.hitObstruction = true;
										value.contactNormal += normalized3;
									}
								}
							}
						}
					}
					value.contactNormal.Normalize();
					lcells[value.id] = value;
				}
			}
		}

		public static bool GroupValid(ref LegionGroup group)
		{
			if (group.inUse == 0)
			{
				return false;
			}
			if (group.dead == 1)
			{
				return false;
			}
			if (group.isBeingCarried == 1)
			{
				return false;
			}
			return true;
		}

		private float ForceFalloff(ref LegionGroup group, Vector3 pos, Vector3 targetPos)
		{
			float magnitude = (targetPos - pos).magnitude;
			float result = Mathf.Lerp(0f, 1f, (magnitude - 0.05f) / 0.125f);
			if (!nextPositions[group.id].lastNode)
			{
				result = 1f;
			}
			return result;
		}

		private void ApplyForceWithCollision(ref LegionGroup group, ref LegionCell cell, float acceleration, Vector3 targetPos, Vector3 finalDestPos)
		{
			Vector3 vector = (targetPos - cell.position).xz();
			Vector3 vector2 = vector.normalized;
			if (cell.hitObstruction && cell.contactNormal.magnitude > 0f)
			{
				Vector3 vector3 = new Vector3(cell.contactNormal.z, 0f, 0f - cell.contactNormal.x);
				if (Vector3.Dot(vector3, vector2) < -0.2f)
				{
					vector3 *= -1f;
				}
				vector2 = vector3;
			}
			Vector3 vector4 = vector2 * acceleration * ForceFalloff(ref group, cell.position, finalDestPos);
			float num = Mathf.Lerp(1f, 2f, vector.magnitude * 2f);
			if (vector4.IsNan())
			{
				_ = 0;
			}
			cell.acceleration += vector4 * num;
			if (debug)
			{
				commandBuilder.Arrow(cell.position, cell.position + vector4 / 10f, Color.yellow);
			}
		}

		public unsafe static void CalcSubordinateFormationPositions(NativeArray<float> heightMap, NativeArray<float> bridgeHeightMap, int worldWidth, int worldHeight, Vector3 leaderPosition, Vector3 dir, Vector3* formations)
		{
			*formations = new Vector3(0f - dir.z, 0f, dir.x) + leaderPosition;
			formations[1] = new Vector3(dir.z, 0f, 0f - dir.x) + leaderPosition;
			formations[2] = new Vector3(0f - dir.z, 0f, dir.x) * 2f + leaderPosition;
			formations[3] = new Vector3(dir.z, 0f, 0f - dir.x) * 2f + leaderPosition;
			for (int i = 0; i < 4; i++)
			{
				formations[i].x = Mathff.Clamp(formations[i].x, 0f, worldWidth - 1);
				formations[i].z = Mathff.Clamp(formations[i].z, 0f, worldHeight - 1);
				formations[i].y = SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, formations[i], out var _);
			}
		}

		public unsafe void UpdateGroupPhysics(ref LegionGroup group)
		{
			LegionCell legionCell = lcells[group.leaderCellId];
			Vector3 vector = legionCell.position;
			float num = 1f;
			if (isFrenzied && group.team == 0)
			{
				num = 1.25f;
			}
			if (group.recuperating == 1)
			{
				num = 2.5f;
			}
			if (group.movingToPosition && (!nextPositions[group.id].lastNode || !(Vector3.Distance(nextPositions[group.id].waypoint, legionCell.position) < 0.1f)))
			{
				vector = nextPositions[group.id].waypoint;
				vector.y = SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, vector, out var _);
			}
			float num2 = (group.chargeMode ? cellAccelForCharge : cellAccel) * num;
			if (group.type == 5)
			{
				num2 *= 1.5f;
			}
			if (group.inWater)
			{
				num2 *= 0.5f;
			}
			if (group.team == 1)
			{
				num2 *= 0.75f;
			}
			if (group.beingAttackedTime > 0f)
			{
				num2 *= 0.75f;
				num2 *= Mathff.Clamp01(Vector3.Dot(group.facing, (vector - legionCell.position).xz().normalized));
			}
			Vector3 vector2 = (vector - legionCell.position).xz().normalized * num2 * ForceFalloff(ref group, legionCell.position, vector);
			if (vector2.IsNan())
			{
				_ = 0;
			}
			if (debug)
			{
				commandBuilder.Arrow(legionCell.position, vector2 / 10f + legionCell.position, Color.yellow);
			}
			legionCell.acceleration += vector2;
			Vector3* ptr = stackalloc Vector3[formationCount];
			Vector3* ptr2 = stackalloc Vector3[formationCount];
			CalcSubordinateFormationPositions(heightMap, bridgeHeightMap, worldWidth, worldHeight, legionCell.position.xz(), group.facing, ptr);
			CalcSubordinateFormationPositions(heightMap, bridgeHeightMap, worldWidth, worldHeight, vector, group.facing, ptr2);
			if (leftRightObstructionCooldowns[group.id] <= 0f)
			{
				for (int i = 0; i < group.numCells; i++)
				{
					if (group.leaderCellId == group.cells[i])
					{
						continue;
					}
					LegionCell cell = lcells[group.cells[i]];
					int num3 = 0;
					for (int j = 0; j < formationCount; j++)
					{
						if (group.formationAssignment[j] == i)
						{
							num3 = j;
							break;
						}
					}
					Vector3 vector3 = ptr[num3];
					Vector3 finalDestPos = ptr2[num3];
					if (Mathff.DistSqrd(cell.position, vector3) < 0.010000001f && cell.attackingCellId != -1)
					{
						Vector3 position = lcells[cell.attackingCellId].position;
						Vector3 normalized = (lcells[cell.id].position - position).normalized;
						vector3 = (finalDestPos = position + normalized * 1f);
					}
					ApplyForceWithCollision(ref group, ref cell, num2, vector3, finalDestPos);
					lcells[group.cells[i]] = cell;
				}
			}
			else
			{
				LegionCell cell2 = legionCell;
				for (int k = 0; k < group.numCells; k++)
				{
					if (group.cells[k] != group.leaderCellId)
					{
						LegionCell cell3 = lcells[group.cells[k]];
						LegionConstraint.ApplyConstraint(springConstant, springBreakThreshold, ref cell2, ref cell3, cell1IsLeader: true, cell2IsLeader: false, 1f);
						lcells[group.cells[k]] = cell3;
						cell2 = cell3;
					}
				}
			}
			for (int l = 0; l < group.numCells && l < formationCount; l++)
			{
				Vector3 vector4 = ptr[l];
				if (IsObstructedFor((int)vector4.x, (int)vector4.z, group.team, obstructionMap, worldWidth))
				{
					if (debug)
					{
						commandBuilder.Cross(vector4, 0.5f, Color.red);
					}
					leftRightObstructionCooldowns[group.id] = 1f;
				}
			}
			if (legionCell.onBridge)
			{
				leftRightObstructionCooldowns[group.id] = 1f;
			}
			lcells[group.leaderCellId] = legionCell;
		}

		public unsafe void UpdateCellsPhysics(ref LegionGroup group, float dt)
		{
			for (int i = 0; i < group.numCells; i++)
			{
				LegionCell cell = lcells[group.cells[i]];
				if (group.cells[i] == group.leaderCellId)
				{
					Vector3 position = cell.position;
					UpdateCellPhysics(ref group, ref cell, dt);
					float num = Vector3.Distance(position.xz(), cell.position.xz());
					leftRightObstructionCooldowns[group.id] = Mathff.Max(0f, leftRightObstructionCooldowns[group.id] - num);
					leftRightObstructionCooldowns[group.id] = Mathff.Max(0f, leftRightObstructionCooldowns[group.id] - dt * 2f);
				}
				else
				{
					UpdateCellPhysics(ref group, ref cell, dt);
				}
				lcells[group.cells[i]] = cell;
			}
		}

		public unsafe void GetCorners(ref Vector3* corners, Vector3 pos, Vector3 dir, float halfWidth)
		{
			Vector3 vector = Vector3.Cross(dir, Vector3.up);
			Vector3 vector2 = -vector;
			*corners = pos + dir * 0.5f + vector * halfWidth;
			corners->y = 0f;
			corners[1] = pos + dir * 0.5f + vector2 * halfWidth;
			corners[1].y = 0f;
			corners[2] = pos + dir * -0.5f + vector2 * halfWidth;
			corners[2].y = 0f;
			corners[3] = pos + dir * -0.5f + vector * halfWidth;
			corners[3].y = 0f;
		}

		private void UpdateCellFacing(int id, Vector3 groupFacing)
		{
			LegionCell value = lcells[id];
			value.direction = groupFacing;
			if (value.attackingCellId != -1)
			{
				value.direction = (lcells[value.attackingCellId].position - value.position).normalized;
			}
			lcells[id] = value;
		}

		private unsafe void UpdateFacing(ref LegionGroup group)
		{
			Vector3 vector = group.facing;
			Vector3 vector2 = nextPositions[group.id].waypoint.xz() - lcells[group.leaderCellId].position.xz();
			if (vector2.magnitude > 0.2f)
			{
				vector = vector2.normalized;
			}
			if (group.AttackTargetId != -1)
			{
				LegionCell legionCell = lcells[group.leaderCellId];
				LegionGroup legionGroup = groups[group.AttackTargetId];
				LegionCell legionCell2 = lcells[legionGroup.leaderCellId];
				Vector3 vector3 = legionCell2.position - legionCell.position;
				vector3.y = 0f;
				vector3.Normalize();
				vector = vector3;
				if (debug)
				{
					commandBuilder.SphereOutline(legionCell2.position, 0.3f, Color.red);
				}
			}
			else
			{
				Vector3 waypoint = nextPositions[group.id].waypoint;
				waypoint.y = SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, waypoint, out var _);
				if (debug)
				{
					commandBuilder.SphereOutline(waypoint, 0.25f, Color.cyan);
				}
			}
			if (Vector3.Dot(vector, group.facing) < 0f)
			{
				group.flipOffset = !group.flipOffset;
			}
			group.facing = vector;
			for (int i = 0; i < group.numCells; i++)
			{
				UpdateCellFacing(group.cells[i], vector);
			}
			if (debug)
			{
				commandBuilder.Arrow(lcells[group.leaderCellId].position, lcells[group.leaderCellId].position + group.facing, Color.cyan);
			}
		}

		private unsafe Vector3 GetBestPointForApproach(LegionGroup subjectGroup, int targetGroupID)
		{
			LegionGroup legionGroup = groups[targetGroupID];
			Vector3* corners = stackalloc Vector3[4];
			GetCorners(ref corners, lcells[legionGroup.leaderCellId].position, legionGroup.facing, (float)legionGroup.numCells * 0.5f);
			Vector3 position = lcells[subjectGroup.leaderCellId].position;
			position.y = 0f;
			Vector3 position2 = lcells[legionGroup.leaderCellId].position;
			Vector3 vector = new Vector3(0f, position2.y, 0f);
			position2.y = 0f;
			float num = float.MaxValue;
			Vector3 vector2 = Vector3.zero;
			checked
			{
				_ = (nuint)4u * unchecked((nuint)sizeof(Vector3));
				_ = (nuint)4u * unchecked((nuint)sizeof(Vector3));
			}
			for (int i = 0; i < 4; i++)
			{
				Vector3 vector3 = Vector3.Lerp(corners[i], corners[(i + 1) % 4], 0.5f);
				Vector3 vector4 = Vector3.Cross(Vector3.up, (corners[i] - corners[(i + 1) % 4]).normalized) * 0.5f;
				Vector3 vector5 = vector3 + vector4;
				commandBuilder.SphereOutline(vector5 + vector, 0.15f, Color.red);
				float num2 = Vector3.Distance(vector5, position);
				if (num2 < num)
				{
					num = num2;
					vector2 = vector5;
				}
			}
			vector2.y = SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, vector2, out var _);
			return vector2;
		}

		public unsafe void SetupSubordinateCells(ref LegionGroup group, int leaderID)
		{
			Vector3* ptr = stackalloc Vector3[formationCount];
			if (leftRightObstructionCooldowns[group.id] > 0f)
			{
				for (int i = 0; i < formationCount; i++)
				{
					ptr[i] = lcells[group.leaderCellId].position - group.facing * (i + 1);
				}
			}
			else
			{
				CalcSubordinateFormationPositions(heightMap, bridgeHeightMap, worldWidth, worldHeight, lcells[group.leaderCellId].position, group.facing, ptr);
			}
			for (int j = 0; j < formationCount; j++)
			{
				group.formationAssignment[j] = -1;
			}
			for (int k = 0; k < formationCount; k++)
			{
				int num = -1;
				float num2 = float.MaxValue;
				for (int l = 0; l < group.numCells; l++)
				{
					if (group.cells[l] == group.leaderCellId)
					{
						continue;
					}
					float num3 = Vector3.Distance(lcells[group.cells[l]].position, ptr[k]);
					if (!(num3 < num2))
					{
						continue;
					}
					bool flag = false;
					for (int m = 0; m < formationCount; m++)
					{
						if (group.formationAssignment[m] == l)
						{
							flag = true;
							break;
						}
					}
					if (!flag)
					{
						num2 = num3;
						num = l;
					}
				}
				group.formationAssignment[k] = num;
			}
		}

		private void UpdateDeadCells(float dt)
		{
			for (int i = 0; i < lcells.Length; i++)
			{
				LegionCell value = lcells[i];
				if (!value.dead || !value.inUse)
				{
					continue;
				}
				if (value.deadTime == 0f)
				{
					for (int j = 0; j < soldierCount; j++)
					{
						int index = value.id * soldierCount + j;
						SoldierExtraData value2 = soldierExtraData[index];
						value2.deathTime = random.NextFloat();
						soldierExtraData[index] = value2;
					}
				}
				value.deadTime += dt;
				if (value.deadTime > 2f)
				{
					value.inUse = false;
				}
				lcells[i] = value;
			}
		}

		public unsafe void UpdateLogic(int subject, float dt)
		{
			LegionGroup group = groups[subject];
			SetupSubordinateCells(ref group, group.leaderCellId);
			if (group.AttackTargetId != -1 && (groups[group.AttackTargetId].inUse == 0 || groups[group.AttackTargetId].dead == 1))
			{
				group.AttackTargetId = -1;
				for (int i = 0; i < group.numCells; i++)
				{
					LegionCell value = lcells[group.cells[i]];
					value.attackingCellId = -1;
					value.spearTargetCellId = -1;
					lcells[group.cells[i]] = value;
				}
			}
			if (group.movingToPosition && Vector3.Distance(lcells[group.leaderCellId].position.xz(), group.desiredPosition.xz()) < 0.1f)
			{
				group.movingToPosition = false;
			}
			group.inWater = false;
			float num = 0f;
			if (group.isBeingCarried != 1)
			{
				for (int j = 0; j < group.numCells; j++)
				{
					LegionCell closestCell = lcells[group.cells[j]];
					int num2 = Mathf.Clamp(Mathf.FloorToInt(closestCell.position.x), 1, worldWidth - 2);
					int num3 = Mathf.Clamp(Mathf.FloorToInt(closestCell.position.z), 1, worldHeight - 2);
					int index = DynamicWater.MapWorldPosToMeshIndex(closestCell.position, waterMeshWidth);
					float waterAmount = waterGrid[index].waterAmount;
					float num4 = SampleHeight(heightMap, worldWidth, closestCell.position) + waterAmount;
					if (num4 < 0f)
					{
						num4 = 0f;
					}
					float num5 = Mathf.Max(0f, num4 - closestCell.position.y);
					if (num5 > 0.05f)
					{
						group.inWater = true;
					}
					float num6 = waterFlow[num3 * worldWidth + num2];
					if (num6 > num)
					{
						num = num6;
					}
					if ((num6 > 1f && num5 > 0.25f) || (num6 > waterFlowDamageThreshold && num5 > 0.05f) || num5 > 0.5f)
					{
						TakeDamage(group, closestCell, waterPepDrain / (float)group.numCells * dt, lcells, groups);
						group = groups[subject];
					}
				}
			}
			if (group.AttackTargetId == -1 && group.beingAttackedTime <= 0f && num <= waterFlowDamageThreshold)
			{
				group.pep = Mathf.Clamp(group.pep + idleRecoup * dt, 0f, group.numCells);
			}
			if (group.pep > 0.25f && group.chargeMode)
			{
				group.pep = Mathf.Max(group.pep - walkingDrainForCharge * dt, 0.25f);
			}
			group.heightAdvantageBonus = 0f;
			group.flankBonus = 0f;
			for (int k = 0; k < groups.Length; k++)
			{
				LegionGroup group2 = groups[k];
				if (!GroupValid(ref group2) || group2.team == group.team)
				{
					continue;
				}
				for (int l = 0; l < group.numCells; l++)
				{
					LegionCell value2 = lcells[group.cells[l]];
					for (int m = 0; m < group2.numCells; m++)
					{
						LegionCell legionCell = lcells[group2.cells[m]];
						Vector3 lhs = legionCell.position - value2.position;
						if (Vector3.Dot(lhs, value2.velocity) > Mathf.Cos(0.34906584f) && lhs.magnitude < spearThrowRange)
						{
							value2.spearTargetCellId = legionCell.id;
							break;
						}
					}
					lcells[value2.id] = value2;
				}
			}
			for (int n = 0; n < group.numCells; n++)
			{
				LegionCell value3 = lcells[group.cells[n]];
				if (value3.spearTargetCellId != -1 && Vector3.Distance(lcells[value3.spearTargetCellId].position, value3.position) > spearThrowRange * 1.4f)
				{
					value3.spearTargetCellId = -1;
				}
				lcells[value3.id] = value3;
			}
			if (group.AttackTargetId == -1 && group.recuperating == 0)
			{
				for (int num7 = 0; num7 < groups.Length; num7++)
				{
					LegionGroup group3 = groups[num7];
					if (!GroupValid(ref group3) || group3.team == group.team)
					{
						continue;
					}
					for (int num8 = 0; num8 < group.numCells; num8++)
					{
						LegionCell legionCell2 = lcells[group.cells[num8]];
						int num9 = 0;
						while (num9 < group3.numCells)
						{
							LegionCell legionCell3 = lcells[group3.cells[num9]];
							if ((!(Vector3.Dot(legionCell3.position - legionCell2.position, group.facing) > Mathf.Cos(MathF.PI / 180f * cellBlockingAngle)) && group.movingToPosition) || !(Mathff.DistSqrdXZ(legionCell3.position, legionCell2.position) < cellFightingRange * cellFightingRange) || !(Mathf.Abs(legionCell3.position.y - legionCell2.position.y) < cellFightingRange))
							{
								num9++;
								continue;
							}
							goto IL_05f8;
						}
						continue;
						IL_05f8:
						group.AttackTargetId = group3.id;
						group.desiredPosition = GetBestPointForApproach(group, group.AttackTargetId);
						break;
					}
				}
			}
			if (group.AttackTargetId != -1 && group.recuperating == 0)
			{
				bool flag = false;
				for (int num10 = 0; num10 < group.numCells; num10++)
				{
					LegionGroup attackTarget = groups[group.AttackTargetId];
					LegionCell value4 = lcells[group.cells[num10]];
					value4.attackingCellId = -1;
					value4.spearTargetCellId = -1;
					LegionCell closestCell2 = default;
					float num11 = float.MaxValue;
					for (int num12 = 0; num12 < attackTarget.numCells; num12++)
					{
						LegionCell legionCell4 = lcells[attackTarget.cells[num12]];
						float num13 = Vector3.Distance(value4.position.xz(), legionCell4.position.xz());
						if (num13 < num11)
						{
							closestCell2 = legionCell4;
							num11 = num13;
						}
					}
					if (num11 < spearThrowRange * 1.1f)
					{
						value4.spearTargetCellId = closestCell2.id;
					}
					if (num11 < cellFightingRange * 1.1f)
					{
						flag = true;
						value4.attackingCellId = closestCell2.id;
						float f = Mathf.Clamp((SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, value4.position, out var _) - SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, closestCell2.position, out var _)) / heightAdvantageMaxHeight, -1f, 1f);
						float num14 = 0f;
						if (Mathf.Abs(f) > 0.33f)
						{
							num14 = heightAdvantagePercentBonus * 0.5f * Mathf.Sign(f);
						}
						if (Mathf.Abs(f) > 0.66f)
						{
							num14 = heightAdvantagePercentBonus * 1f * Mathf.Sign(f);
						}
						group.heightAdvantageBonus += num14;
						float num15 = normalPepDrain;
						if (group.type == 5)
						{
							num15 *= 1.5f;
						}
						float num16 = Vector3.Dot(group.facing, attackTarget.facing);
						float num17 = 0f;
						if (num16 > Mathf.Cos(MathF.PI * 23f / 36f))
						{
							num17 = 0.5f;
							if (num16 > Mathf.Cos(MathF.PI * 11f / 60f))
							{
								num17 = 1f;
							}
						}
						group.flankBonus += num17;
						float num18 = num15 * (1f + num14) * (1f + num17);
						float num19 = moralePointReduction * (float)attackTarget.morale;
						num19 += (attackTarget.inWater ? (-0.25f) : 0f);
						num18 *= 1f - num19;
						if (isFrenzied && group.team == 0)
						{
							num18 *= 1.25f;
						}
						if (TakeDamage(attackTarget, closestCell2, num18 * dt * (float)((attackTarget.team != 1) ? 1 : 2), lcells, groups, group.team))
						{
							if (group.type != 4)
							{
								group.morale++;
							}
							if (group.morale > 3)
							{
								group.morale = 3;
							}
							SaveGroup(group);
							return;
						}
					}
					lcells[value4.id] = value4;
				}
				if (!flag)
				{
					group.AttackTargetId = -1;
				}
				group.flankBonus /= group.numCells;
				group.heightAdvantageBonus /= group.numCells;
			}
			for (int num20 = 0; num20 < group.numCells; num20++)
			{
				LegionCell value5 = lcells[group.cells[num20]];
				value5.attackBuildingX = (value5.attackBuildingZ = -1);
				Vector3 vector = value5.position + value5.direction * 0.6f;
				ObstructionCell obstructionCell = obstructionMap[(int)vector.z * worldWidth + (int)vector.x];
				if (obstructionCell.oType == ObstructionType.Building && obstructionCell.teamId != group.team)
				{
					value5.attackBuildingX = (int)vector.x;
					value5.attackBuildingZ = (int)vector.z;
				}
				lcells[group.cells[num20]] = value5;
			}
			group.beingAttackedTime -= dt;
			SaveGroup(group);
		}

		public void UpdateCellPhysics(ref LegionGroup group, ref LegionCell cell, float dt)
		{
			cell.acceleration.y = 0f;
			cell.velocity += cell.acceleration * dt;
			if (cell.velocity.magnitude > 10f)
			{
				cell.velocity = cell.velocity.normalized * 10f;
			}
			Vector3 position = cell.position;
			Vector3 position2 = cell.position + (cell.velocity + -cell.velocity * cellDamping * dt) * dt;
			float num = SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, position, out var hitBridge);
			cell.onBridge = hitBridge;
			float num2 = Mathf.Clamp01(Mathf.Max(SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, position2, out var _) - num, 0f) / maxUphillInclineDampening);
			float num3 = cellDamping;
			if (group.team == 1)
			{
				num3 *= 1.3f;
			}
			if (group.beingAttackedTime > 0f)
			{
				num3 *= 1.5f;
			}
			if (group.inWater)
			{
				num3 *= 1.3f;
			}
			cell.dampForceThisFrame = -cell.velocity * (num3 + num2 * uphillDamping);
			cell.velocity += cell.dampForceThisFrame * dt;
			cell.position += cell.velocity * dt;
			cell.position = new Vector3(cell.position.x, SampleHeightWithBridge(heightMap, bridgeHeightMap, worldWidth, cell.position, out var _), cell.position.z);
			cell.acceleration = Vector3.zero;
		}

		public void SaveGroup(LegionGroup group)
		{
			groups[group.id] = group;
		}
	}

	[Serializable]
	public class LegionSystemSaveData : SaveClass<LegionSystem, LegionSystemSaveData>
	{
		[Serializable]
		private class GroupSaveData
		{
			public int type;

			public int team;

			public float pep;

			public int numCells;

			public SerializableVector3[] positions = new SerializableVector3[5];

			public SerializableVector3 facing;

			public Guid guid;

			public int morale;

			public int origNumCells;
		}

		private List<GroupSaveData> groupData = new List<GroupSaveData>();

		public unsafe override LegionSystemSaveData Pack(LegionSystem d)
		{
			d.CompleteJobs();
			for (int i = 0; i < d.groups.Length; i++)
			{
				LegionGroup legionGroup = d.groups[i];
				if (legionGroup.inUse != 0)
				{
					GroupSaveData groupSaveData = new GroupSaveData
					{
						type = legionGroup.type,
						team = legionGroup.team,
						pep = legionGroup.pep,
						numCells = legionGroup.numCells,
						facing = legionGroup.facing,
						guid = legionGroup.guid,
						morale = legionGroup.morale,
						origNumCells = legionGroup.origNumCells
					};
					for (int j = 0; j < 5 && j < legionGroup.numCells; j++)
					{
						groupSaveData.positions[j] = d.legionCells[legionGroup.cells[j]].position;
					}
					groupData.Add(groupSaveData);
				}
			}
			return this;
		}

		public unsafe override LegionSystem Unpack(LegionSystem d)
		{
			for (int i = 0; i < groupData.Count; i++)
			{
				GroupSaveData groupSaveData = groupData[i];
				LegionUnit legionUnit = d.TrySpawn(groupSaveData.type, groupSaveData.positions[groupSaveData.numCells / 2], groupSaveData.team, groupSaveData.numCells);
				LegionGroup value = legionUnit.GetGroup();
				value.facing = groupSaveData.facing;
				value.guid = groupSaveData.guid;
				value.morale = groupSaveData.morale;
				legionUnit.lastMorale = value.morale;
				if (groupSaveData.origNumCells != 0)
				{
					value.origNumCells = groupSaveData.origNumCells;
				}
				for (int j = 0; j < 5 && j < value.numCells; j++)
				{
					LegionCell value2 = d.legionCells[value.cells[j]];
					value2.position = groupSaveData.positions[j];
					d.legionCells[value.cells[j]] = value2;
				}
				d.groups[value.id] = value;
			}
			return d;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
		}
	}

	public const int MaxCells = 1000;

	public GamePath[] deferredPaths;

	internal NativeArray<LegionCell> legionCells;

	internal NativeArray<LegionGroup> groups;

	internal NativeArray<JobPathNode> nextPositions;

	internal NativeArray<int> nextPositionsIndex;

	public BlobAssetReference<LegionBurstAnimationBaker.AllAnimations> bakedSoldierAnimations;

	internal NativeArray<SoldierExtraData> soldierExtraData;

	internal NativeArray<float> heightMap;

	internal NativeArray<float> bridgeHeightMap;

	internal NativeArray<ObstructionCell> obstructionMap;

	internal NativeArray<float> leftRightObstructionCooldowns;

	public float heightAdvantageMaxHeight = 0.015f;

	public float heightAdvantagePercentBonus = 0.1f;

	public float DamageToBuilding = 0.1f;

	public bool doDamage = true;

	public float normalPepDrain = 0.1f;

	public float moralePointReduction = 0.9f;

	public float walkingDrainForCharge = 0.2f;

	public float idleRecoup = 0.025f;

	public float waterPepDrain = 0.2f;

	public float waterFlowDamageThreshold = 0.5f;

	public float groupFightingRange = 1.2f;

	public float cellFightingRange = 1f;

	public float spearThrowRange = 3f;

	public bool debug;

	public bool debugObstructionMap;

	private bool isFrenzied;

	private float currFrenzyTime;

	private const float MAX_FRENZY_TIME = 150f;

	private ArrayExtRef<OneOffEffect> frenzyFX = new ArrayExtRef<OneOffEffect>(64);

	[FormerlySerializedAs("soliderCount")]
	public int soldierCount = 9;

	private static LegionSystem inst;

	public LegionDef[] legionDefs;

	private bool haveBakedAnimations;

	private Vector3[] corners = new Vector3[4];

	public float cellBlockingAngle = 45f;

	public float camScaleMinDist = 10f;

	public float camScaleMaxDist = 40f;

	public float camScaleMax = 2f;

	private float totalTime;

	private bool commandBuilderValid;

	private CommandBuilder commandBuilder;

	private JobHandle updateGroupsHandle;

	internal NativeArray<Vector3> soldierPositions;

	internal NativeArray<Quaternion> soldierRotations;

	internal NativeArray<Vector3> soldierScales;

	private int physicsUpdateCount;

	private float accumulator;

	private Vector2 mousePosOnMiddleDown;

	public static LegionSystem Inst
	{
		get
		{
			if (inst == null)
			{
				inst = UnityEngine.Object.FindAnyObjectByType<LegionSystem>();
			}
			return inst;
		}
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	internal static float SampleHeightWithBridge(NativeArray<float> baseHeightMap, NativeArray<float> bridgeHeightMap, int worldWidth, Vector3 position, out bool hitBridge)
	{
		return TerrainGen.GetInterpolatedHeightStatic_WithBridging(baseHeightMap, bridgeHeightMap, worldWidth, position, out hitBridge);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	internal static float SampleHeight(NativeArray<float> baseHeightMap, int worldWidth, Vector3 position)
	{
		return TerrainGen.GetInterpolatedHeightStatic(baseHeightMap, worldWidth, position);
	}

	public static bool DoesGroupHaveDuplicateLeader(NativeArray<LegionGroup> groups)
	{
		for (int i = 0; i < groups.Length; i++)
		{
			if (groups[i].inUse == 0)
			{
				continue;
			}
			for (int j = 0; j < groups.Length; j++)
			{
				if (i != j && groups[j].inUse != 0 && groups[i].leaderCellId == groups[j].leaderCellId)
				{
					return true;
				}
			}
		}
		return false;
	}

	public bool IsFrenzied()
	{
		return isFrenzied;
	}

	public void ActivateFrenzy()
	{
		isFrenzied = true;
		currFrenzyTime = 150f;
	}

	internal unsafe void ReleaseGroup(int groupID)
	{
		LegionGroup value = groups[groupID];
		value.inUse = 0;
		groups[groupID] = value;
		for (int i = 0; i < value.numCells; i++)
		{
			int index = value.cells[i];
			LegionCell value2 = legionCells[index];
			value2.inUse = false;
			legionCells[index] = value2;
			value.cells[i] = -1;
		}
	}

	public LegionDef GetLegionDef(int type, int teamID)
	{
		for (int i = 0; i < legionDefs.Length; i++)
		{
			if (legionDefs[i].recruitUnitType == type && legionDefs[i].teamID == teamID)
			{
				return legionDefs[i];
			}
		}
		return null;
	}

	public static Vector3 CellPos(int id)
	{
		return inst.legionCells[id].position;
	}

	public static void CellPos(int id, Vector3 newPos)
	{
		LegionCell value = inst.legionCells[id];
		value.position = newPos;
		inst.legionCells[id] = value;
	}

	public bool TryGetGroup(int idx, out LegionGroup group)
	{
		group = default;
		if (idx < 0 || idx >= groups.Length)
		{
			return false;
		}
		group = groups[idx];
		return true;
	}

	public int GetRemainingAvailableUnits()
	{
		int num = 0;
		for (int i = 0; i < groups.Length; i++)
		{
			if (groups[i].inUse == 0)
			{
				num++;
			}
		}
		return num;
	}

	public bool IsAtMaxUnits()
	{
		for (int i = 0; i < groups.Length; i++)
		{
			if (groups[i].inUse == 0)
			{
				return false;
			}
		}
		return true;
	}

	public LegionUnit TrySpawn(int unitType, Vector3 position, int team, int numCells = 3)
	{
		for (int i = 0; i < groups.Length; i++)
		{
			if (groups[i].inUse == 0)
			{
				LegionGroup value = groups[i];
				value.team = team;
				value.type = unitType;
				value.Init(position, Vector3.forward, numCells);
				groups[i] = value;
				UnitSystem.inst.TryAddUnit(i, out var unit);
				return unit;
			}
		}
		return null;
	}

	public void CompleteJobs()
	{
		updateGroupsHandle.Complete();
		for (int i = 0; i < legionDefs.Length; i++)
		{
			legionDefs[i].jobHandle.Complete();
		}
	}

	public void Cleanup()
	{
		CompleteJobs();
		if (commandBuilderValid)
		{
			commandBuilder.DiscardAndDispose();
			commandBuilderValid = false;
		}
		if (heightMap.IsCreated)
		{
			heightMap.Dispose();
		}
		if (bridgeHeightMap.IsCreated)
		{
			bridgeHeightMap.Dispose();
		}
		if (groups.IsCreated)
		{
			groups.Dispose();
		}
		if (legionCells.IsCreated)
		{
			legionCells.Dispose();
		}
		if (nextPositions.IsCreated)
		{
			nextPositions.Dispose();
		}
		if (nextPositionsIndex.IsCreated)
		{
			nextPositionsIndex.Dispose();
		}
		if (soldierPositions.IsCreated)
		{
			soldierPositions.Dispose();
		}
		if (soldierRotations.IsCreated)
		{
			soldierRotations.Dispose();
		}
		if (soldierScales.IsCreated)
		{
			soldierScales.Dispose();
		}
		if (obstructionMap.IsCreated)
		{
			obstructionMap.Dispose();
		}
		if (leftRightObstructionCooldowns.IsCreated)
		{
			leftRightObstructionCooldowns.Dispose();
		}
		if (soldierExtraData.IsCreated)
		{
			soldierExtraData.Dispose();
		}
		for (int i = 0; i < legionDefs.Length; i++)
		{
			legionDefs[i].Dispose();
		}
		haveBakedAnimations = false;
		if (bakedSoldierAnimations.IsCreated)
		{
			bakedSoldierAnimations.Dispose();
		}
	}

	public void OnDestroy()
	{
		Cleanup();
	}

	public void Reset()
	{
		totalTime = 0f;
		int length = 100;
		Cleanup();
		heightMap = new NativeArray<float>(World.MeshWidth * World.MeshHeight, Allocator.Persistent);
		bridgeHeightMap = new NativeArray<float>(World.MeshWidth * World.MeshHeight, Allocator.Persistent);
		groups = new NativeArray<LegionGroup>(length, Allocator.Persistent);
		legionCells = new NativeArray<LegionCell>(1000, Allocator.Persistent);
		nextPositions = new NativeArray<JobPathNode>(length, Allocator.Persistent);
		nextPositionsIndex = new NativeArray<int>(length, Allocator.Persistent);
		soldierPositions = new NativeArray<Vector3>(1000 * soldierCount, Allocator.Persistent);
		Quaternion identity = Quaternion.identity;
		soldierRotations = new NativeArray<Quaternion>(1000 * soldierCount, Allocator.Persistent);
		for (int i = 0; i < soldierRotations.Length; i++)
		{
			soldierRotations[i] = identity;
		}
		soldierScales = new NativeArray<Vector3>(1000 * soldierCount, Allocator.Persistent);
		for (int j = 0; j < soldierScales.Length; j++)
		{
			soldierScales[j] = new Vector3(SRand.Range(1f, 1.1f), SRand.Range(1f, 1.2f), SRand.Range(1f, 1.1f));
		}
		obstructionMap = new NativeArray<ObstructionCell>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		leftRightObstructionCooldowns = new NativeArray<float>(length, Allocator.Persistent);
		soldierExtraData = new NativeArray<SoldierExtraData>(1000 * soldierCount, Allocator.Persistent);
		if (!haveBakedAnimations)
		{
			haveBakedAnimations = true;
			bakedSoldierAnimations = LegionBurstAnimationBaker.inst.GetAnimationBlob();
		}
		deferredPaths = new GamePath[100];
		for (int k = 0; k < deferredPaths.Length; k++)
		{
			deferredPaths[k] = new GamePath();
			deferredPaths[k].pathType = GamePath.PathType.MilitaryPathPostBlock;
		}
		for (int l = 0; l < soldierExtraData.Length; l++)
		{
			SoldierExtraData value = soldierExtraData[l];
			value.currentAnimationTime = SRand.Range(0f, 0.5f);
			soldierExtraData[l] = value;
		}
		for (int m = 0; m < legionCells.Length; m++)
		{
			LegionCell value2 = legionCells[m];
			value2.id = m;
			value2.attackingCellId = -1;
			value2.spearTargetCellId = -1;
			value2.inUse = false;
			value2.dead = false;
			value2.onBridge = false;
			value2.deadTime = 0f;
			legionCells[m] = value2;
		}
		for (int n = 0; n < groups.Length; n++)
		{
			LegionGroup value3 = groups[n];
			value3.id = n;
			value3.inUse = 0;
			groups[n] = value3;
		}
		for (int num = 0; num < legionDefs.Length; num++)
		{
			legionDefs[num].Init(soldierCount);
		}
		for (int num2 = 0; num2 < frenzyFX.Count; num2++)
		{
			frenzyFX.data[num2].Release();
		}
		frenzyFX.ClearFast();
	}

	public unsafe void UpdateObstructionForCell(Cell cell)
	{
		updateGroupsHandle.Complete();
		ObstructionCell value = obstructionMap[cell.index];
		value.oType = ObstructionType.None;
		value.teamId = -1;
		if (cell.Type == TerrainType.Obstruction)
		{
			value.oType = ObstructionType.Mountain;
			if (cell.HasAccessibleTerrainResourceType(14) && cell.terrainResource.meshFilter.transform.localScale.x < 1.9f && cell.terrainResource.meshFilter.transform.localScale.z < 1.9f)
			{
				value.oType = ObstructionType.None;
			}
		}
		else
		{
			bool flag = false;
			PathCell pathCell = World.inst.GetPathCell(cell);
			for (int i = 0; i < 5; i++)
			{
				if (cell.OccupyingStructure.Count > 0)
				{
					value.blocksTeamID[i] = PathCell.GetBlocksFootPathForArmies(pathCell, i) || PathCell.GetMilitaryFootPathCost(pathCell, i) >= PathCell.buildingFootpathCost;
				}
				else if (cell.Type == TerrainType.Water)
				{
					value.blocksTeamID[i] = true;
				}
				else
				{
					value.blocksTeamID[i] = false;
				}
				if (value.blocksTeamID[i])
				{
					flag = true;
				}
			}
			if (flag)
			{
				if (cell.OccupyingStructure.Count > 0)
				{
					value.oType = ObstructionType.Building;
					value.teamId = cell.OccupyingStructure[0].TeamID();
				}
				else
				{
					value.oType = ObstructionType.General;
				}
			}
		}
		obstructionMap[cell.index] = value;
	}

	public void RebuildObstructionMap()
	{
		int i = 0;
		for (int num = World.inst.GridWidth * World.inst.GridHeight; i < num; i++)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i);
			UpdateObstructionForCell(cellDataUnsafe);
		}
	}

	private void Awake()
	{
		inst = this;
	}

	private void DrawDebugObstructionMap()
	{
		for (int i = 0; i < World.inst.GridWidth * World.inst.GridHeight; i++)
		{
			if (obstructionMap[i].oType == ObstructionType.Mountain)
			{
				Draw.ingame.SphereOutline(World.inst.GetCellDataUnsafe(i).Center3D, 0.5f, Color.red);
			}
			if (obstructionMap[i].oType == ObstructionType.General)
			{
				Draw.ingame.SphereOutline(World.inst.GetCellDataUnsafe(i).Center3D, 0.5f, Color.orange);
			}
			if (obstructionMap[i].oType == ObstructionType.Building)
			{
				Draw.ingame.SphereOutline(World.inst.GetCellDataUnsafe(i).Center3D, 0.5f, Color.purple);
			}
		}
	}

	private void DrawDebug()
	{
		for (int i = 0; i < groups.Length; i++)
		{
			if (groups[i].inUse != 0)
			{
				groups[i].Draw(debug: true);
				if (deferredPaths[i].status == GamePath.Status.Complete)
				{
					Vector3 curr = CellPos(groups[i].leaderCellId);
					deferredPaths[i].DrawDebug(curr, Color.green);
				}
			}
		}
	}

	public void GetCornersNonJob(ref Vector3[] corners, Vector3 pos, Vector3 dir, float halfWidth)
	{
		Vector3 vector = Vector3.Cross(dir, Vector3.up);
		Vector3 vector2 = -vector;
		corners[0] = pos + dir * 0.5f + vector * halfWidth;
		corners[0].y = 0f;
		corners[1] = pos + dir * 0.5f + vector2 * halfWidth;
		corners[1].y = 0f;
		corners[2] = pos + dir * -0.5f + vector2 * halfWidth;
		corners[2].y = 0f;
		corners[3] = pos + dir * -0.5f + vector * halfWidth;
		corners[3].y = 0f;
	}

	private Vector3 GetBestPointForApproachNonJob(LegionGroup subjectGroup, int targetGroupID)
	{
		LegionGroup legionGroup = groups[targetGroupID];
		NativeArray<LegionCell> nativeArray = legionCells;
		GetCornersNonJob(ref corners, nativeArray[legionGroup.leaderCellId].position, legionGroup.facing, (float)legionGroup.numCells * 0.5f);
		Vector3 position = nativeArray[subjectGroup.leaderCellId].position;
		position.y = 0f;
		Vector3 position2 = nativeArray[legionGroup.leaderCellId].position;
		position2.y = 0f;
		float num = float.MaxValue;
		Vector3 vector = Vector3.zero;
		for (int i = 0; i < 4; i++)
		{
			Vector3 vector2 = Vector3.Lerp(corners[i], corners[(i + 1) % 4], 0.5f);
			Vector3 vector3 = Vector3.Cross(Vector3.up, (corners[i] - corners[(i + 1) % 4]).normalized) * 0.5f;
			Vector3 vector4 = vector2 + vector3;
			DebugEx.DrawSphere(vector4 + new Vector3(0f, nativeArray[legionGroup.leaderCellId].position.y, 0f), 0.2f, Color.red, 8f, 0.1f);
			float num2 = Vector3.Distance(vector4, position);
			if (num2 < num)
			{
				num = num2;
				vector = vector4;
			}
		}
		vector.y = SampleHeightWithBridge(heightMap, bridgeHeightMap, World.inst.GridWidth, vector, out var _);
		return vector;
	}

	public bool TestLegionPosForTrim(Vector3 pos, Vector3 cellPos, float rad, ref float minDist)
	{
		float num = Mathff.DistSqrdXZ(pos, cellPos);
		if (num < rad && num < minDist)
		{
			minDist = num;
			return true;
		}
		return false;
	}

	public unsafe bool TrimPathForBlockedCells(ref LegionGroup subjectGroup, Vector3 startPos, ref ArrayExt<Vector3> path, int teamId, IMoveTarget moveTarget, Pathfinder.blocksPathTest bt)
	{
		if (IsObstructedFor((int)startPos.x, (int)startPos.z, teamId, obstructionMap, World.inst.GridWidth))
		{
			return false;
		}
		if (path.Count > 0)
		{
			World.inst.GetPathCell(startPos);
			bool flag = false;
			bool flag2 = flag;
			Vector3 rhs = subjectGroup.facing;
			PathCell pathCell = null;
			Vector3 vector = startPos;
			int num = 0;
			while (num < path.Count)
			{
				Vector3 pos = path.data[num];
				TerrainGen.inst.GetGroundHeight(ref pos);
				if (Mathff.MoveTowards(vector, pos, 1f, out var _, out var newPos))
				{
					num++;
				}
				if ((newPos - vector).magnitude > 0.1f)
				{
					rhs = (newPos - vector).normalized;
				}
				PathCell pathCell2 = World.inst.GetPathCell(vector);
				if (pathCell2 == pathCell)
				{
					vector = newPos;
					continue;
				}
				Vector3 pos2 = vector;
				TerrainGen.inst.GetGroundHeight(ref pos2);
				if (debug)
				{
					DebugEx.DrawSphere(pos2, 0.25f, Color.cyan);
				}
				if (pathCell2.isStairs && path.data[num].y > 0.01f)
				{
					if (!flag2)
					{
						flag = !flag;
					}
					flag2 = true;
				}
				else
				{
					flag2 = false;
				}
				int num2 = -1;
				int num3 = 1;
				ArrayExt<LegionUnit> legionUnits = UnitSystem.inst.legionUnits;
				float minDist = float.MaxValue;
				for (int i = 0; i < legionUnits.Count; i++)
				{
					LegionGroup group = legionUnits.data[i].GetGroup();
					if (!UpdateGroups.GroupValid(ref group) || (group.team == teamId && (group.movingToPosition || group.AttackTargetId == -1)))
					{
						continue;
					}
					Vector3 pos3 = pathCell2.Center;
					TerrainGen.inst.GetGroundHeight(ref pos3);
					for (int j = 0; j < group.numCells; j++)
					{
						LegionCell legionCell = legionCells[group.cells[j]];
						if (Vector3.Dot((legionCell.position - vector).normalized, rhs) > Mathf.Cos(MathF.PI / 180f * cellBlockingAngle) && TestLegionPosForTrim(legionCell.position, pos3, num3, ref minDist))
						{
							num2 = group.id;
						}
					}
				}
				if ((IsObstructedFor(pathCell2.x, pathCell2.z, teamId, obstructionMap, World.inst.GridWidth) || num2 != -1) && (!flag || pathCell2.isUpperGridBlocked || pathCell2.Type != TerrainType.None))
				{
					path.RemoveRange(num, path.Count - num);
					if (num2 != -1)
					{
						path.Add(GetBestPointForApproachNonJob(subjectGroup, num2));
					}
					else
					{
						path.Add(vector);
					}
					DebugEx.DrawSphere(path.Last(), 0.35f, Color.yellow, 8f, 0.2f);
					Cell cellData = World.inst.GetCellData(pathCell2);
					for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
					{
						if (cellData.OccupyingStructure[k] == moveTarget)
						{
							return false;
						}
					}
					return true;
				}
				vector = newPos;
				pathCell = pathCell2;
			}
		}
		return false;
	}

	private void Update()
	{
		if (!LoadSave.Loading && TerrainGen.inst.heightCache != null)
		{
			CompleteJobs();
			DrawMeshes();
			commandBuilder.Dispose();
			commandBuilderValid = false;
		}
	}

	public unsafe void LateUpdate()
	{
		if (LoadSave.Loading || TerrainGen.inst.heightCache == null)
		{
			return;
		}
		float t = Mathff.Clamp01((Cam.inst.dist - camScaleMinDist) / camScaleMaxDist);
		float value = Mathff.Lerp(1f, camScaleMax, t);
		Shader.SetGlobalFloat("_armyCamScale", value);
		totalTime += Time.deltaTime;
		float deltaTime = Time.deltaTime;
		if (isFrenzied)
		{
			currFrenzyTime -= deltaTime;
			if (currFrenzyTime <= 0f)
			{
				isFrenzied = false;
				for (int i = 0; i < frenzyFX.Count; i++)
				{
					frenzyFX.data[i].Release();
				}
				frenzyFX.ClearFast();
			}
			else
			{
				int num = 0;
				for (int j = 0; j < UnitSystem.inst.legionUnits.Count; j++)
				{
					LegionUnit legionUnit = UnitSystem.inst.legionUnits.data[j];
					if (legionUnit.TeamID() != 0 || !legionUnit.ValidToSelect())
					{
						continue;
					}
					LegionGroup legionGroup = legionUnit.GetGroup();
					for (int k = 0; k < legionGroup.numCells; k++)
					{
						LegionCell legionCell = Inst.legionCells[legionGroup.cells[k]];
						if (frenzyFX.Count <= num + 1)
						{
							frenzyFX.Add(EffectsMan.inst.EmboldenedUnitLoopingEffect.CreateAndPlay(legionCell.position));
						}
						else
						{
							frenzyFX.data[num].transform.position = legionCell.position;
						}
						num++;
					}
					for (int num2 = frenzyFX.Count - 1; num2 >= num; num2--)
					{
						frenzyFX.data[num2].Release();
						frenzyFX.RemoveAt(num2);
					}
				}
			}
		}
		accumulator += deltaTime;
		if (LegionPhysicsSystem.Inst.physicsStepSize < 1E-05f)
		{
			LegionPhysicsSystem.Inst.physicsStepSize = 1E-05f;
		}
		physicsUpdateCount = (int)(accumulator / LegionPhysicsSystem.Inst.physicsStepSize);
		accumulator -= LegionPhysicsSystem.Inst.physicsStepSize * (float)physicsUpdateCount;
		if (debug)
		{
			DrawDebug();
		}
		if (debugObstructionMap)
		{
			DrawDebugObstructionMap();
		}
		for (int l = 0; l < groups.Length; l++)
		{
			LegionGroup group = groups[l];
			if (!UpdateGroups.GroupValid(ref group))
			{
				continue;
			}
			if (!group.pathReady && deferredPaths[l].status == GamePath.Status.Complete)
			{
				group.pathReady = true;
				LegionCell legionCell2 = legionCells[group.leaderCellId];
				TrimPathForBlockedCells(ref group, legionCell2.position, ref deferredPaths[l].result, group.team, null, PathCell.GetBlocksFootPathForArmies);
				if (debug)
				{
					Vector3 start = legionCell2.position;
					for (int m = 0; m < deferredPaths[l].result.Count; m++)
					{
						Debug.DrawLine(start, deferredPaths[l].result.data[m], Color.cyan);
						DebugEx.DrawSphere(deferredPaths[l].result.data[m], 0.3f, Color.cyan);
						start = deferredPaths[l].result.data[m];
					}
				}
				if (deferredPaths[l].result.Count > 0)
				{
					if (deferredPaths[l].result.Count > 1)
					{
						deferredPaths[l].result.RemoveAt(deferredPaths[l].result.Count - 2);
					}
					nextPositionsIndex[l] = 0;
					nextPositions[l] = new JobPathNode
					{
						waypoint = deferredPaths[l].result.data[0],
						lastNode = (deferredPaths[l].result.Count <= 1),
						index = 0
					};
				}
			}
			if (deferredPaths[l].status != GamePath.Status.Finding && leftRightObstructionCooldowns[group.id] > 0f)
			{
				int num3 = -1;
				float num4 = float.MaxValue;
				int leaderCellId = -1;
				for (int n = 0; n < group.numCells; n++)
				{
					FindFurthestPathIndex(deferredPaths[l], legionCells[group.cells[n]].position, out var index, out var distanceFromNextPoint);
					if (index > num3)
					{
						num3 = index;
						num4 = distanceFromNextPoint;
						leaderCellId = group.cells[n];
					}
					else if (index == num3 && distanceFromNextPoint < num4)
					{
						num4 = distanceFromNextPoint;
						leaderCellId = group.cells[n];
					}
				}
				if (num3 >= 0)
				{
					nextPositionsIndex[l] = num3;
					nextPositions[l] = new JobPathNode
					{
						waypoint = deferredPaths[l].result.data[num3],
						lastNode = (num3 == deferredPaths[l].result.Count - 1),
						index = num3
					};
				}
				group.leaderCellId = leaderCellId;
			}
			if (group.needsPathing && deferredPaths[l].status != GamePath.Status.Finding)
			{
				group.needsPathing = false;
				group.pathReady = false;
				deferredPaths[l].start = legionCells[group.leaderCellId].position;
				deferredPaths[l].end = group.desiredPosition;
				deferredPaths[l].teamId = group.team;
				World.inst.threadedPather.RequestPath(deferredPaths[l]);
			}
			if (deferredPaths[l].status == GamePath.Status.Complete)
			{
				Vector3 waypoint = nextPositions[group.id].waypoint;
				if (Vector3.Distance(legionCells[group.leaderCellId].position.xz(), waypoint.xz()) < 0.1f && nextPositionsIndex[group.id] < deferredPaths[l].result.Count)
				{
					nextPositionsIndex[group.id]++;
				}
				if (deferredPaths[l].result.Count == 0)
				{
					continue;
				}
				int num5 = Mathf.Min(nextPositionsIndex[l], deferredPaths[l].result.Count - 1);
				nextPositions[l] = new JobPathNode
				{
					waypoint = deferredPaths[l].result.data[num5],
					index = num5,
					lastNode = (num5 == deferredPaths[l].result.Count - 1)
				};
			}
			groups[l] = group;
		}
		heightMap.CopyFrom(TerrainGen.inst.heightCache);
		bridgeHeightMap.CopyFrom(TerrainGen.inst.bridgeHeightCache);
		commandBuilder = DrawingManager.GetBuilder(renderInGame: true);
		commandBuilderValid = true;
		uint seed = (uint)DateTime.Now.Ticks;
		Unity.Mathematics.Random random = new Unity.Mathematics.Random(seed);
		UpdateGroups jobData = new UpdateGroups
		{
			commandBuilder = commandBuilder,
			debug = debug,
			physicsUpdateCount = physicsUpdateCount,
			physicsTimeStep = LegionPhysicsSystem.Inst.physicsStepSize,
			cellDamping = LegionPhysicsSystem.Inst.cellDamping,
			uphillDamping = LegionPhysicsSystem.Inst.uphillDamping,
			maxUphillInclineDampening = LegionPhysicsSystem.Inst.maxUphillInclineDampening,
			antiPenetrationForce = LegionPhysicsSystem.Inst.antiPenetrationForce,
			cellAccel = LegionPhysicsSystem.Inst.cellAccel,
			cellAccelForCharge = LegionPhysicsSystem.Inst.cellAccelForCharge,
			springConstant = LegionPhysicsSystem.Inst.springConstant,
			springBreakThreshold = LegionPhysicsSystem.Inst.springBreakThreshold,
			doDamage = doDamage,
			normalPepDrain = normalPepDrain,
			idleRecoup = idleRecoup,
			walkingDrainForCharge = walkingDrainForCharge,
			groupFightingRange = groupFightingRange,
			moralePointReduction = moralePointReduction,
			cellFightingRange = cellFightingRange,
			cellBlockingAngle = cellBlockingAngle,
			spearThrowRange = spearThrowRange,
			heightAdvantageMaxHeight = heightAdvantageMaxHeight,
			heightAdvantagePercentBonus = heightAdvantagePercentBonus,
			groups = groups,
			lcells = legionCells,
			heightMap = heightMap,
			bridgeHeightMap = bridgeHeightMap,
			worldWidth = World.inst.GridWidth,
			worldHeight = World.inst.GridHeight,
			soldierCount = soldierCount,
			nextPositions = nextPositions,
			nextPositionsIndex = nextPositionsIndex,
			soldierExtraData = soldierExtraData,
			isFrenzied = isFrenzied,
			obstructionMap = obstructionMap,
			leftRightObstructionCooldowns = leftRightObstructionCooldowns,
			random = random,
			waterGrid = DynamicWater.inst.waterGridCopy,
			waterFlow = DynamicWater.inst.simplifiedWaterFlowMagnitudeNativeCopy,
			waterMeshWidth = DynamicWater.inst.width,
			waterPepDrain = waterPepDrain,
			waterFlowDamageThreshold = waterFlowDamageThreshold
		};
		updateGroupsHandle = IJobExtensions.Schedule(jobData);
		totalTime += deltaTime;
		for (int num6 = 0; num6 < legionDefs.Length; num6++)
		{
			UpdateRenderData jobData2 = new UpdateRenderData
			{
				random = random,
				deltaTime = deltaTime,
				groups = groups,
				lcells = legionCells,
				heightMap = heightMap,
				bridgeHeightMap = bridgeHeightMap,
				worldWidth = World.inst.GridWidth,
				worldHeight = World.inst.GridHeight,
				soldierCount = soldierCount,
				physicsTimeStep = LegionPhysicsSystem.Inst.physicsStepSize,
				totalTime = totalTime,
				soldierAnimations = bakedSoldierAnimations,
				soldierPositions = soldierPositions,
				soldierRotations = soldierRotations,
				soldierScales = soldierScales,
				soldierMatrices = legionDefs[num6].soldierRD.matrices,
				swordMatrices = legionDefs[num6].swordRD.matrices,
				shieldMatrices = legionDefs[num6].shieldRD.matrices,
				drawnSoldiersCount = legionDefs[num6].drawnSoldiersCount,
				soldierExtraData = soldierExtraData,
				teamFilter = legionDefs[num6].teamID,
				typeFilter = legionDefs[num6].recruitUnitType
			};
			if (num6 == 0)
			{
				legionDefs[num6].jobHandle = IJobExtensions.Schedule(jobData2, updateGroupsHandle);
			}
			else
			{
				legionDefs[num6].jobHandle = IJobExtensions.Schedule(jobData2, legionDefs[num6 - 1].jobHandle);
			}
		}
	}

	internal void SetPositionForCell(int idx, Vector3 pos, LegionGroup group)
	{
		LegionCell value = legionCells[idx];
		value.position = pos;
		legionCells[idx] = value;
		nextPositions[group.id] = new JobPathNode
		{
			waypoint = pos,
			lastNode = false,
			index = 0
		};
	}

	private void FindFurthestPathIndex(GamePath path, Vector3 position, out int index, out float distanceFromNextPoint, bool debug = false)
	{
		position.y = 0f;
		Vector3[] data = path.result.data;
		int num = -1;
		float num2 = float.MaxValue;
		bool flag = false;
		for (int i = 0; i < path.result.Count - 2; i++)
		{
			Vector3 vector = data[i];
			Vector3 vector2 = data[i + 1];
			Vector3 normalized = (position - vector).normalized;
			Vector3 normalized2 = (position - vector2).normalized;
			if (Vector3.Dot(normalized, normalized2) < 0f)
			{
				Vector3 vector3 = Mathff.NearestPointOnLine(vector, vector2 - vector, position, i != -1);
				if (debug)
				{
					Draw.ingame.SphereOutline(vector3, 0.25f, Color.green);
				}
				float num3 = Vector3.Distance(vector3, position);
				if (num3 < num2)
				{
					num2 = num3;
					num = i + 1;
					flag = true;
				}
				break;
			}
		}
		if (!flag && path.result.Count > 0)
		{
			num = 0;
			num2 = Vector3.Distance(data[0], position);
		}
		if (num == -1)
		{
			index = 0;
			distanceFromNextPoint = 0f;
		}
		else
		{
			index = num;
			distanceFromNextPoint = Vector3.Distance(position, path.result.data[num]);
		}
	}

	public void DrawMeshes()
	{
		for (int i = 0; i < legionDefs.Length; i++)
		{
			legionDefs[i].DrawMeshes();
		}
	}

	public unsafe void LegionDebugController()
	{
		_ = Vector3.zero;
		Ray ray = PointingSystem.GetRay();
		if (Physics.Raycast(ray, out var hitInfo, 100f, LayerMask.GetMask("Terrain")))
		{
			ray.GetPoint(hitInfo.distance);
		}
		if (Input.GetKeyDown(KeyCode.Alpha7) && GameState.inst.AlphaNumericHotkeysEnabled)
		{
			for (int i = 0; i < groups[0].numCells; i++)
			{
				LegionGroup legionGroup = groups[0];
				SetPositionForCell(legionGroup.cells[i], GameUI.inst.GridPointerIntersection(), legionGroup);
			}
		}
		Input.GetKeyDown(KeyCode.P);
	}

	private unsafe static bool IsObstructedFor(int ox, int oz, int team, NativeArray<ObstructionCell> obMap, int worldWidth)
	{
		ObstructionCell obstructionCell = obMap[oz * worldWidth + ox];
		if ((obstructionCell.oType == ObstructionType.Building && obstructionCell.blocksTeamID[team]) || obstructionCell.oType == ObstructionType.General || obstructionCell.oType == ObstructionType.Mountain)
		{
			return true;
		}
		return false;
	}

	public unsafe static bool TakeDamage(LegionGroup attackTarget, LegionCell closestCell, float amt, NativeArray<LegionCell> lcells, NativeArray<LegionGroup> groups, int team = -1)
	{
		attackTarget.pep -= amt;
		attackTarget.pep = Mathff.Clamp(attackTarget.pep, 0f, attackTarget.numCells);
		attackTarget.beingAttackedTime = 0.5f;
		int num = 0;
		for (int i = 0; i < attackTarget.numCells; i++)
		{
			if (!lcells[attackTarget.cells[i]].dead)
			{
				num++;
			}
		}
		if (attackTarget.pep < (float)(num - 1) || attackTarget.pep <= 0f)
		{
			int num2 = 0;
			for (int j = 0; j < attackTarget.numCells; j++)
			{
				if (lcells[attackTarget.cells[j]].id != closestCell.id)
				{
					attackTarget.cells[num2++] = attackTarget.cells[j];
				}
			}
			attackTarget.numCells--;
			if (closestCell.id == attackTarget.leaderCellId)
			{
				attackTarget.leaderCellId = lcells[attackTarget.cells[0]].id;
			}
			closestCell.dead = true;
			lcells[closestCell.id] = closestCell;
		}
		if (attackTarget.pep <= 0f && attackTarget.dead == 0)
		{
			attackTarget.dead = 1;
			attackTarget.killerID = team;
		}
		groups[attackTarget.id] = attackTarget;
		return attackTarget.dead == 1;
	}

	public static void ResetAnimationForCell(LegionCell cell, int animID, int soldierCount, NativeArray<SoldierExtraData> soldierExtraData, bool looping)
	{
		for (int i = 0; i < soldierCount; i++)
		{
			int index = cell.id * soldierCount + i;
			SoldierExtraData value = soldierExtraData[index];
			value.currentAnimationTime = 0f;
			value.currentAnimationId = animID;
			value.loopAnimation = (looping ? 1 : 0);
			soldierExtraData[index] = value;
		}
	}
}
