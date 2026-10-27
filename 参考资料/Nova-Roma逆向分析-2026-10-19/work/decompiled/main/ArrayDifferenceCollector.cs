using System.Collections.Generic;

public class ArrayDifferenceCollector
{
	public delegate void DiffDelegate(int index, float value);

	private Dictionary<int, float> differenceCollection = new Dictionary<int, float>(50);

	public void AddDifference(int index, float value)
	{
		if (differenceCollection.ContainsKey(index))
		{
			differenceCollection[index] += value;
		}
		else
		{
			differenceCollection.Add(index, value);
		}
	}

	public void SetDifference(int index, float value)
	{
		if (differenceCollection.ContainsKey(index))
		{
			differenceCollection[index] = value;
		}
		else
		{
			differenceCollection.Add(index, value);
		}
	}

	public void ApplyDifferences(DiffDelegate diffDelegate)
	{
		foreach (KeyValuePair<int, float> item in differenceCollection)
		{
			diffDelegate(item.Key, item.Value);
		}
	}

	public IEnumerable<int> GetKeys()
	{
		return differenceCollection.Keys;
	}

	public void Reset()
	{
		differenceCollection.Clear();
	}
}
