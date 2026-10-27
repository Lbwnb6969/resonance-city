using System;
using Drawing;
using UnityEngine;

public struct LegionGroup
{
	public static readonly float cpuRelaxedDistanceThreshold = 15f;

	private static readonly int startMoral = 0;

	public static Vector3 heightAdvantageOffset = new Vector3(0f, 3f, -0.2f);

	public static float heightAdvantageSpacing = 0.21f;

	public static float heightAdvantageSize = 0.1f;

	public static Vector3 starOffset = new Vector3(0f, 3f, 0.2f);

	public static float starSpacing = 0.21f;

	public static float starSize = 0.1f;

	public int inUse;

	public int dead;

	public float deadTime;

	public int killerID;

	public int id;

	public Guid guid;

	public int type;

	public int isBeingCarried;

	public int leaderCellId;

	public unsafe fixed int cells[5];

	public unsafe fixed int formationAssignment[5];

	public int numCells;

	public int origNumCells;

	public bool standGround;

	public int team;

	public Vector3 desiredPosition;

	public bool movingToPosition;

	public int AttackTargetId;

	public int recuperating;

	public int morale;

	public float pep;

	public float flankBonus;

	public float heightAdvantageBonus;

	public bool chargeMode;

	public bool inWater;

	public bool retreating;

	public int lastAttackTarget;

	public bool needsPathing;

	public bool pathReady;

	public float beingAttackedTime;

	public Vector3 facing;

	public bool flipOffset;

	public static bool operator ==(LegionGroup lhs, LegionGroup rhs)
	{
		return lhs.id == rhs.id;
	}

	public static bool operator !=(LegionGroup lhs, LegionGroup rhs)
	{
		return !(lhs == rhs);
	}

	public unsafe void Init(Vector3 startPos, Vector3 forward, int cellCount)
	{
		guid = Guid.NewGuid();
		numCells = 0;
		for (int i = 0; i < cellCount; i++)
		{
			int num = -1;
			for (int j = 0; j < LegionSystem.Inst.legionCells.Length; j++)
			{
				LegionCell value = LegionSystem.Inst.legionCells[j];
				if (!value.inUse)
				{
					value.position = startPos;
					value.direction = forward;
					value.inUse = true;
					value.dead = false;
					value.deadTime = 0f;
					value.onBridge = false;
					value.attackingCellId = -1;
					value.spearTargetCellId = -1;
					value.type = type;
					LegionSystem.Inst.legionCells[j] = value;
					num = j;
					break;
				}
			}
			if (num == -1)
			{
				Debug.LogError($"LegionGroup.Init: out of legion cells, group {id} gets {numCells}/{cellCount}");
				break;
			}
			cells[numCells] = num;
			LegionSystem.ResetAnimationForCell(LegionSystem.Inst.legionCells[num], 5, LegionSystem.Inst.soldierCount, LegionSystem.Inst.soldierExtraData, looping: true);
			numCells++;
		}
		deadTime = 0f;
		dead = 0;
		inUse = 1;
		isBeingCarried = 0;
		killerID = -1;
		morale = startMoral;
		pep = numCells;
		AttackTargetId = -1;
		beingAttackedTime = 0f;
		inWater = false;
		recuperating = 0;
		leaderCellId = cells[numCells / 2];
		origNumCells = numCells;
		facing = forward;
		movingToPosition = false;
		desiredPosition = startPos;
		needsPathing = false;
		LegionSystem.Inst.nextPositions[id] = new LegionSystem.JobPathNode
		{
			waypoint = desiredPosition,
			lastNode = true,
			index = 0
		};
	}

	public static Vector3 CellPos(int id)
	{
		return LegionSystem.CellPos(id);
	}

	public static void CellPos(int id, Vector3 newPos)
	{
		LegionSystem.CellPos(id, newPos);
	}

	public unsafe void Draw(bool debug)
	{
		if (inUse == 0 || dead == 1 || isBeingCarried == 1)
		{
			return;
		}
		Vector3 vector = CellPos(cells[1]);
		new Vector2(1f, 0.1f);
		new Vector3(0f, 2f, 0f);
		new Vector3(0f, 2f, -0.1f);
		if (debug)
		{
			for (int i = 0; i < morale; i++)
			{
				DrawStar(vector + new Vector3((float)i * starSpacing - (float)morale * starSpacing / 2f, 0f, 0f) + starOffset, starSize);
			}
		}
	}

	public void DrawStar(Vector3 position, float size)
	{
		using (Drawing.Draw.ingame.WithColor(Color.yellow))
		{
			float num = MathF.PI / 6f;
			Drawing.Draw.ingame.SolidTriangle(position + size * new Vector3(Mathf.Cos(num), 0f, Mathf.Sin(num)), position + size * new Vector3(Mathf.Cos(num * 5f), 0f, Mathf.Sin(num * 5f)), position + size * new Vector3(Mathf.Cos(num * 9f), 0f, Mathf.Sin(num * 9f)));
			Drawing.Draw.ingame.SolidTriangle(position + size * new Vector3(Mathf.Cos(0f - num), 0f, Mathf.Sin(0f - num)), position + size * new Vector3(Mathf.Cos((0f - num) * 5f), 0f, Mathf.Sin((0f - num) * 5f)), position + size * new Vector3(Mathf.Cos((0f - num) * 9f), 0f, Mathf.Sin((0f - num) * 9f)));
		}
	}
}
