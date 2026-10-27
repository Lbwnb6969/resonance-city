using System.Collections.Generic;
using System.Linq;
using Code;
using Drawing;
using UnityEngine;

public class Hydra : MonoBehaviour
{
	public ArrayExt<Vector3> pathData = new ArrayExt<Vector3>(30);

	public Quaternion HydraMoveRotationTarget;

	public float HydraMoveSpeed = 10f;

	public float HydraTurnSpeed = 1f;

	public GameObject Body;

	public float bodyWiggleSpeed = 10f;

	public float bodyWiggleStrength = 0.5f;

	private float stateTime;

	private float distanceTraveled;

	private Vector3 smoothedLookVec;

	public GameObject headPrefab;

	public List<HydraHead> heads;

	public HydraTail tail;

	public float disabledHeadWiggleSpeed = 10f;

	public float disabledHeadWiggleAmount = 10f;

	public float headSpacing = 2f;

	public float staggerSpacing = 2f;

	public Transform hydraHeadMountPoint;

	public float headRegrowTime = 5f;

	public List<float> pendingHeadTimers;

	public float lookAheadDistance = 20f;

	public float stopDistance = 10f;

	public float hydraAcceleration = 1f;

	public bool hydraNeedToMove;

	public ArrayExt<int> blockingCells = new ArrayExt<int>(10);

	private bool[] touchedCells;

	private Vector3[] directions = new Vector3[5]
	{
		Vector3.zero,
		Vector3.forward,
		Vector3.back,
		Vector3.right,
		Vector3.left
	};

	private Cell lastTouchCell;

	private HashSet<Building> bodyTouchedCells = new HashSet<Building>();

	public void ShootAcid()
	{
		heads[Random.Range(0, heads.Count)].ShootAcid();
	}

	private void Start()
	{
		AddNewHeadInstantly();
	}

	public void ManualUpdate()
	{
		for (int i = 0; i < pendingHeadTimers.Count; i++)
		{
			pendingHeadTimers[i] -= Time.deltaTime;
			if (pendingHeadTimers[i] <= 0f)
			{
				pendingHeadTimers.RemoveAt(i);
				i--;
				AddNewHead();
			}
		}
		float num = HydraMoveSpeed * transform.lossyScale.z;
		float num2 = stopDistance * transform.lossyScale.z;
		float num3 = lookAheadDistance * transform.lossyScale.z;
		float num4 = bodyWiggleSpeed / transform.lossyScale.z;
		Vector3 vector = transform.position;
		if (Physics.Raycast(new Ray(transform.position + Vector3.up * 10f, -Vector3.up), out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
		{
			vector = hitInfo.point;
		}
		Vector3 vector2 = vector;
		Vector3 vector3 = vector;
		float num5 = 0f;
		bool flag = false;
		for (int j = 0; j < pathData.Count; j++)
		{
			Vector3 vector4 = pathData.data[j];
			float num6 = num3 - num5;
			float num7 = Vector3.Distance(vector3, vector4);
			if (num6 < num7)
			{
				vector2 = Vector3.Lerp(vector3, vector4, num6 / num7);
				flag = true;
				break;
			}
			num5 += num7;
			vector3 = vector4;
		}
		if (!flag)
		{
			vector2 = vector3;
		}
		if (pathData.Count == 0)
		{
			vector2 += transform.forward * num3;
		}
		if (Physics.Raycast(new Ray(vector2 + Vector3.up * 10f, -Vector3.up), out var hitInfo2, 1000f, LayerMask.GetMask("Terrain")))
		{
			vector2 = hitInfo2.point;
		}
		using (Draw.editor.WithColor(Color.blue))
		{
			Draw.editor.SphereOutline(vector2, 1f);
		}
		List<HydraHead> list = new List<HydraHead>();
		list.AddRange(heads.Where((HydraHead head) => head.growth < 1f));
		if (list.Count > 0)
		{
			for (int num8 = 0; num8 < heads.Count; num8++)
			{
				HydraHead hydraHead = heads[num8];
				if (list.Contains(hydraHead))
				{
					Vector3 forward = transform.forward;
					Vector3 rhs = -Vector3.Cross(forward, Vector3.up);
					Vector3 upwards = Vector3.Cross(forward, rhs);
					hydraHead.headHandle.rotation = Quaternion.LookRotation(forward, upwards);
					continue;
				}
				HydraHead hydraHead2 = null;
				float num9 = float.MaxValue;
				foreach (HydraHead item in list)
				{
					float num10 = Vector3.Distance(hydraHead.headHandle.position, item.headHandle.position);
					if (num10 < num9)
					{
						num9 = num10;
						hydraHead2 = item;
					}
				}
				Vector3 normalized = (hydraHead2.headHandle.position - hydraHead.headHandle.position).normalized;
				Vector3 rhs2 = -Vector3.Cross(normalized, Vector3.up);
				Vector3 upwards2 = Vector3.Cross(normalized, rhs2);
				hydraHead.headHandle.rotation = Quaternion.LookRotation(normalized, upwards2);
			}
		}
		else
		{
			foreach (HydraHead head in heads)
			{
				Vector3 normalized2 = (vector2 - head.headHandle.position).normalized;
				Vector3 rhs3 = -Vector3.Cross(normalized2, Vector3.up);
				Vector3 upwards3 = Vector3.Cross(normalized2, rhs3);
				head.headHandle.rotation = Quaternion.LookRotation(normalized2, upwards3);
			}
		}
		tail.BodyPanic(heads.Count == 0);
		if (Input.GetKeyDown(KeyCode.Space))
		{
			ShootAcid();
		}
		float num11 = 0f;
		Vector3 a = vector;
		for (int num12 = 0; num12 < pathData.Count; num12++)
		{
			num11 += Vector3.Distance(a, pathData.data[num12]);
			a = pathData.data[num12];
		}
		hydraNeedToMove = num11 - num2 > 1f;
		hydraAcceleration = Mathf.Clamp01(num11 - num2);
		Vector3 vector5 = vector2 - vector;
		vector5.y = 0f;
		if (vector5 != Vector3.zero)
		{
			smoothedLookVec = smoothedLookVec * 0.9f + vector5.normalized * 0.1f;
			HydraMoveRotationTarget = Quaternion.LookRotation(smoothedLookVec, Vector3.up);
		}
		if (pathData.Count > 0)
		{
			Debug.DrawLine(transform.position, pathData.data[0], Color.red);
		}
		for (int num13 = 0; num13 < pathData.Count - 2; num13++)
		{
			Debug.DrawLine(pathData.data[num13], pathData.data[num13 + 1], Color.red);
		}
		float num14 = num * hydraAcceleration * Time.deltaTime;
		int num15 = 0;
		while (num15 < pathData.Count)
		{
			Vector3 vector6 = pathData.data[num15];
			float num16 = Vector3.Distance(vector, vector6);
			if (num16 < num14)
			{
				distanceTraveled += Vector3.Distance(vector.xz(), vector6.xz());
				vector = vector6;
				num14 -= num16;
				pathData.RemoveAt(num15);
				num15--;
				num15++;
				continue;
			}
			Vector3 input = vector;
			vector = Vector3.MoveTowards(vector, vector6, num14);
			distanceTraveled += Vector3.Distance(input.xz(), vector.xz());
			break;
		}
		if (vector.y < Water.inst.transform.position.y - 0.5f * transform.lossyScale.z)
		{
			vector.y = Water.inst.transform.position.y - 0.5f * transform.lossyScale.z;
		}
		transform.position = vector;
		float num17 = Mathf.Clamp01((Quaternion.Angle(transform.rotation, HydraMoveRotationTarget) - 30f * (1f - hydraAcceleration)) / 60f);
		transform.rotation = Quaternion.RotateTowards(transform.rotation, HydraMoveRotationTarget, HydraTurnSpeed * num17 * Time.deltaTime);
		Body.transform.localPosition = new Vector3(Mathf.Sin(distanceTraveled * num4) * bodyWiggleStrength, 0f);
		float num18 = (float)(heads.Count - 1) * headSpacing;
		for (int num19 = 0; num19 < heads.Count; num19++)
		{
			float x = 0f;
			if (heads.Count != 1)
			{
				x = Mathf.Lerp((0f - num18) / 2f, num18 / 2f, (float)num19 / (float)(heads.Count - 1));
			}
			float y = 0f;
			if (heads.Count >= 3)
			{
				y = staggerSpacing * (float)(num19 % 2);
			}
			heads[num19].transform.GetChild(0).localPosition += (new Vector3(x, y, 0f) - heads[num19].transform.GetChild(0).localPosition) * Time.deltaTime;
		}
		Cell cellDataClamped = World.inst.GetCellDataClamped(transform.position);
		if (cellDataClamped != lastTouchCell && cellDataClamped != null)
		{
			World.inst.treeSystem.FellAllTrees(cellDataClamped);
		}
		lastTouchCell = cellDataClamped;
		float num20 = tail.BodySizeGradient.Evaluate(0f) * 0.5f;
		new ArrayExt<int>(5);
		if (touchedCells == null)
		{
			touchedCells = new bool[World.inst.GridWidth * World.inst.GridHeight];
		}
		Util.Memset(touchedCells, 0);
		Vector3[] array = directions;
		foreach (Vector3 vector7 in array)
		{
			Cell cellData = World.inst.GetCellData(Body.transform.position + vector7 * num20);
			int index = cellData.index;
			if (!touchedCells[index])
			{
				touchedCells[index] = true;
				Building topStructure = cellData.TopStructure;
				if (topStructure != null && topStructure.categoryHash != World.pathHash)
				{
					float dmg = Mathff.Max(0.5f, topStructure.MaxLife / 4f);
					cellData.TopMostStructure.TakeDamage(dmg, Body.transform.position, "LOC: Hydra");
				}
			}
		}
		Cell cellDataClamped2 = World.inst.GetCellDataClamped(transform.position);
		World.inst.ForEachTileInRadius(cellDataClamped2.x, cellDataClamped2.z, 3, (int num23, int z, Cell cell) =>
		{
			int index2 = cell.index;
			VillagerGrid villagerGrid = World.inst.villagerGrid[index2];
			for (int k = 0; k < villagerGrid.villagers.Count; k++)
			{
				Villager obj = villagerGrid.villagers.data[k];
				Vector3 normalized3 = (obj.Pos.xz() - transform.position.xz()).normalized;
				obj.Scare(obj.Pos + normalized3 * 3f);
			}
		});
		for (int num22 = 0; num22 < blockingCells.Count; num22++)
		{
			World.inst.GetPathCell(blockingCells.data[num22]).hydraBlockingCost = 0;
		}
		blockingCells.Clear();
		Cell cellData2 = World.inst.GetCellDataClamped(transform.position);
		World.inst.ForEachTileInRadius(cellData2.x, cellData2.z, 5, (int num24, int z, Cell cell) =>
		{
			PathCell pathCell = World.inst.GetPathCell(cell.index);
			float num23 = Vector3.Distance(cellData2.Center2D, cell.Center2D);
			pathCell.hydraBlockingCost = (int)Mathf.Lerp(500f, 50f, (num23 - 3f) / 2f);
			blockingCells.Add(cell.index);
		});
	}

	public HydraHead AddNewHead()
	{
		HydraHead component = Object.Instantiate(headPrefab, hydraHeadMountPoint).GetComponent<HydraHead>();
		component.gameObject.SetActive(value: true);
		component.growth = 0f;
		heads.Insert(heads.Count / 2, component);
		return component;
	}

	public void AddNewHeadInstantly()
	{
		AddNewHead().growth = 1f;
	}

	public void RemoveHead(HydraHead head, bool regrow)
	{
		heads.Remove(head);
		Object.Destroy(head.gameObject);
		if (regrow)
		{
			pendingHeadTimers.Add(headRegrowTime);
			pendingHeadTimers.Add(headRegrowTime);
		}
	}

	public void ReplaceHead(HydraHead head)
	{
		heads.Remove(head);
		Object.Destroy(head.gameObject);
		pendingHeadTimers.Add(0f);
	}
}
