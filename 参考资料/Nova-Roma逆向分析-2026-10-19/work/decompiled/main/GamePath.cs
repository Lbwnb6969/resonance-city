using UnityEngine;

public class GamePath
{
	public enum Status
	{
		Uninitialized,
		Finding,
		Complete
	}

	public enum PathType
	{
		VillagerPath,
		MilitaryPathPostBlock,
		OgrePathPostBlock,
		BoatPathPostBlock,
		TransportCartPathPostBlock,
		EnvoyPathPostBlock,
		HydraPath
	}

	public int teamId;

	public Vector3 start;

	public Vector3 end;

	public int lastStartX;

	public int lastStartZ;

	public int lastEndX;

	public int lastEndZ;

	public int lastGridID = -1;

	public ArrayExt<Vector3> result = new ArrayExt<Vector3>(32);

	public float time;

	public Status status;

	public PathType pathType;

	public void DrawDebug(Vector3 curr, Color color)
	{
		curr.y = TerrainGen.inst.GetInterpolatedHeight(new Vector3(curr.x, 0f, curr.z)) + 0.25f;
		if (curr.y < 0f)
		{
			curr.y = 0f;
		}
		for (int i = 0; i < result.Count; i++)
		{
			Vector3 vector = result.data[i];
			vector.y = TerrainGen.inst.GetInterpolatedHeight(new Vector3(curr.x, 0f, curr.z)) + 0.25f;
			if (vector.y < 0f)
			{
				vector.y = 0f;
			}
			Debug.DrawLine(curr, vector, color);
			DebugEx.DrawSphere(vector, 0.1f, color);
			curr = vector;
		}
	}

	public bool TryConsume(ref ArrayExt<Vector3> pathOut)
	{
		if (status == Status.Complete)
		{
			pathOut.Clear();
			int i = 0;
			for (int count = result.Count; i < count; i++)
			{
				pathOut.Add(result.data[i]);
			}
			status = Status.Uninitialized;
			return true;
		}
		return false;
	}

	public void Reset()
	{
		result.Clear();
		status = Status.Uninitialized;
	}
}
