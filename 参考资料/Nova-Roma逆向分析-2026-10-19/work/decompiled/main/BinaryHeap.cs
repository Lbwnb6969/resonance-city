using System;
using System.Collections;
using System.Collections.Generic;

public class BinaryHeap<T> : ICollection<T>, IEnumerable<T>, IEnumerable where T : IComparable<T>
{
	private const int DEFAULT_SIZE = 4;

	public T[] _data = new T[4];

	private int _count;

	private int _capacity = 4;

	private bool _sorted;

	public int Count => _count;

	public int Capacity
	{
		get
		{
			return _capacity;
		}
		set
		{
			int capacity = _capacity;
			_capacity = Math.Max(value, _count);
			if (_capacity != capacity)
			{
				T[] array = new T[_capacity];
				Array.Copy(_data, array, _count);
				_data = array;
			}
		}
	}

	public bool IsReadOnly => false;

	public BinaryHeap()
	{
	}

	private BinaryHeap(T[] data, int count)
	{
		Capacity = count;
		_count = count;
		Array.Copy(data, _data, count);
	}

	public T Peek()
	{
		return _data[0];
	}

	public void Clear()
	{
		_count = 0;
		_sorted = false;
	}

	public void Add(T item)
	{
		if (_count == _capacity)
		{
			Capacity *= 2;
		}
		_data[_count] = item;
		UpHeap();
		_count++;
	}

	public T Remove()
	{
		if (_count == 0)
		{
			throw new InvalidOperationException("Cannot remove item, heap is empty.");
		}
		T result = _data[0];
		_count--;
		_data[0] = _data[_count];
		_data[_count] = default;
		DownHeap();
		return result;
	}

	private void UpHeap()
	{
		_sorted = false;
		int num = _count;
		T val = _data[num];
		int num2 = Parent(num);
		while (num2 > -1 && val.CompareTo(_data[num2]) < 0)
		{
			_data[num] = _data[num2];
			num = num2;
			num2 = Parent(num);
		}
		_data[num] = val;
	}

	private void DownHeap()
	{
		_sorted = false;
		int num = 0;
		T val = _data[num];
		while (true)
		{
			int num2 = Child1(num);
			if (num2 >= _count)
			{
				break;
			}
			int num3 = Child2(num);
			int num4;
			if (num3 >= _count)
			{
				num4 = num2;
			}
			else
			{
				ref readonly T reference = ref _data[num2];
				T other = _data[num3];
				num4 = ((reference.CompareTo(other) < 0) ? num2 : num3);
			}
			if (val.CompareTo(_data[num4]) <= 0)
			{
				break;
			}
			_data[num] = _data[num4];
			num = num4;
		}
		_data[num] = val;
	}

	private void EnsureSort()
	{
		if (!_sorted)
		{
			Array.Sort(_data, 0, _count);
			_sorted = true;
		}
	}

	private static int Parent(int index)
	{
		return index - 1 >> 1;
	}

	private static int Child1(int index)
	{
		return (index << 1) + 1;
	}

	private static int Child2(int index)
	{
		return (index << 1) + 2;
	}

	public BinaryHeap<T> Copy()
	{
		return new BinaryHeap<T>(_data, _count);
	}

	public IEnumerator<T> GetEnumerator()
	{
		EnsureSort();
		for (int i = 0; i < _count; i++)
		{
			yield return _data[i];
		}
	}

	IEnumerator IEnumerable.GetEnumerator()
	{
		return GetEnumerator();
	}

	public bool Contains(T item)
	{
		EnsureSort();
		return Array.BinarySearch(_data, 0, _count, item) >= 0;
	}

	public void CopyTo(T[] array, int arrayIndex)
	{
		EnsureSort();
		Array.Copy(_data, array, _count);
	}

	public bool Remove(T item)
	{
		EnsureSort();
		int num = Array.BinarySearch(_data, 0, _count, item);
		if (num < 0)
		{
			return false;
		}
		Array.Copy(_data, num + 1, _data, num, _count - num);
		_data[_count] = default;
		_count--;
		return true;
	}
}
