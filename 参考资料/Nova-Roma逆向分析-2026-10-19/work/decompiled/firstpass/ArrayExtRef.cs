using System.Collections.Generic;
using UnityEngine;

public class ArrayExtRef<T> where T : class
{
	public delegate int Compare(T curr, T target);

	public T[] data;

	private int count;

	public int Count => count;

	public ArrayExtRef(int maxSize)
	{
		data = new T[maxSize];
	}

	public ArrayExtRef(ArrayExtRef<T> source)
	{
		data = new T[source.Count];
		count = source.count;
		for (int i = 0; i < source.Count; i++)
		{
			data[i] = source.data[i];
		}
	}

	public int RandomIdx()
	{
		return SRand.Range(0, count);
	}

	public T RandomElement()
	{
		return data[SRand.Range(0, count)];
	}

	public T Last()
	{
		if (count > 0)
		{
			return data[count - 1];
		}
		return null;
	}

	public T First()
	{
		if (count > 0)
		{
			return data[0];
		}
		return null;
	}

	public T PopIndex(int idx)
	{
		if (idx >= count || idx < 0)
		{
			return null;
		}
		T result = data[idx];
		RemoveAt(idx);
		return result;
	}

	public T PopFirst()
	{
		T result = First();
		RemoveAt(0);
		return result;
	}

	public T PopLast()
	{
		if (count == 0)
		{
			return null;
		}
		count--;
		return data[count];
	}

	public void ClearFast()
	{
		count = 0;
	}

	public void Clear()
	{
		for (int i = 0; i < count; i++)
		{
			data[i] = null;
		}
		count = 0;
	}

	public int IndexOf(T item)
	{
		for (int i = 0; i < count; i++)
		{
			if (data[i] == item)
			{
				return i;
			}
		}
		return -1;
	}

	public bool Contains(T item)
	{
		return IndexOf(item) != -1;
	}

	public void Remove(T item)
	{
		if (count <= 0)
		{
			return;
		}
		if (data[count - 1].Equals(item))
		{
			count--;
			return;
		}
		int num = int.MaxValue;
		for (int i = 0; i < count - 1; i++)
		{
			if (data[i] == item)
			{
				num = i;
				break;
			}
		}
		for (int j = num; j < count - 1; j++)
		{
			data[j] = data[j + 1];
		}
		if (num != int.MaxValue)
		{
			count--;
		}
	}

	public void RemoveAt(int i)
	{
		for (int j = i; j < count - 1; j++)
		{
			data[j] = data[j + 1];
		}
		data[count - 1] = null;
		count--;
	}

	public void RemoveRange(int i, int removeCount)
	{
		for (int j = i; j < count - removeCount; j++)
		{
			data[j] = data[j + removeCount];
		}
		data[count - 1] = null;
		count -= removeCount;
	}

	public void RemoveAtSwap(int i)
	{
		data[i] = data[count - 1];
		data[count - 1] = null;
		count--;
	}

	public void RemoveAtSwapBoth(int i)
	{
		T val = data[i];
		data[i] = data[count - 1];
		data[count - 1] = val;
		count--;
	}

	public bool RemoveSwap(T item)
	{
		int i = 0;
		for (int num = count; i < num; i++)
		{
			if (data[i] == item)
			{
				RemoveAtSwap(i);
				return true;
			}
		}
		return false;
	}

	public void Add(T item)
	{
		if (count >= data.Length)
		{
			Expand();
		}
		data[count] = item;
		count++;
	}

	public T GetNew()
	{
		return data[count++];
	}

	public int AddNoExpand(T item)
	{
		data[count] = item;
		return count++;
	}

	public void AddRange(IEnumerable<T> items)
	{
		IEnumerator<T> enumerator = items.GetEnumerator();
		while (enumerator.MoveNext())
		{
			Add(enumerator.Current);
		}
		enumerator.Dispose();
	}

	public void AddRange(ArrayExtRef<T> list)
	{
		for (int i = 0; i < list.Count; i++)
		{
			Add(list.data[i]);
		}
	}

	public void Insert(int index, T item)
	{
		if (count + 1 >= data.Length)
		{
			Expand();
		}
		index = Mathf.Clamp(index, 0, count);
		for (int num = count - 1; num >= index; num--)
		{
			data[num + 1] = data[num];
		}
		data[index] = item;
		count++;
	}

	private void Expand()
	{
		int num = (int)((float)data.Length * 1.5f);
		if (num < data.Length + 5)
		{
			num = data.Length + 5;
		}
		T[] array = new T[num];
		for (int i = 0; i < count; i++)
		{
			array[i] = data[i];
			data[i] = null;
		}
		data = array;
	}

	public void Sort(Compare c)
	{
		if (Count <= 1)
		{
			return;
		}
		for (int i = 0; i < Count; i++)
		{
			int num = i;
			for (int j = i + 1; j < Count; j++)
			{
				if (c(data[j], data[num]) < 0)
				{
					num = j;
				}
			}
			T[] array = data;
			int num2 = i;
			T[] array2 = data;
			int num3 = num;
			T val = data[num];
			T val2 = data[i];
			array[num2] = val;
			array2[num3] = val2;
		}
	}
}
