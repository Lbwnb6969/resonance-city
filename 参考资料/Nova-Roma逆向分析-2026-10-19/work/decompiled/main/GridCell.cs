using System;

[Serializable]
public class GridCell : ICellXZ
{
	public int x;

	public int z;

	public int X
	{
		get
		{
			return x;
		}
		set
		{
			x = value;
		}
	}

	public int Z
	{
		get
		{
			return z;
		}
		set
		{
			z = value;
		}
	}

	public Cell GetWorldCell()
	{
		return World.inst.GetCellDataUnsafe(x, z);
	}
}
