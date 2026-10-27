using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization;

[Serializable]
public class GridManager
{
	private int width;

	private int height;

	private List<object[]> grids = new List<object[]>();

	[NonSerialized]
	private Hashtable typeLookup = new Hashtable();

	public GridManager(int width, int height)
	{
		this.width = width;
		this.height = height;
	}

	public T GetCellUnsafe<T>(int x, int z)
	{
		Type typeFromHandle = typeof(T);
		return (typeLookup[typeFromHandle] as T[])[z * width + x];
	}

	public T[] GetGrid<T>() where T : GridCell, new()
	{
		foreach (object[] grid in grids)
		{
			if (grid[0].GetType() == typeof(T))
			{
				return grid as T[];
			}
		}
		T[] array = new T[width * height];
		for (int i = 0; i < array.Length; i++)
		{
			array[i] = new T
			{
				x = i % width,
				z = i / width
			};
		}
		List<object[]> list = grids;
		object[] item = array;
		list.Add(item);
		typeLookup[typeof(T)] = array;
		return array;
	}

	[OnDeserialized]
	public void OnDeserializedMethod(StreamingContext context)
	{
		typeLookup = new Hashtable();
		foreach (object[] grid in grids)
		{
			typeLookup[grid.GetType().GetElementType()] = grid;
		}
	}
}
