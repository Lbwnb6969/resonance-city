using System;
using System.Collections;
using System.Collections.Generic;

namespace Priority_Queue;

public sealed class SimplePriorityQueue<T> : IPriorityQueue<T>, IEnumerable<T>, IEnumerable
{
	private class SimpleNode : FastPriorityQueueNode
	{
		public T Data { get; private set; }

		public SimpleNode(T data)
		{
			Data = data;
		}
	}

	private const int INITIAL_QUEUE_SIZE = 10;

	private readonly FastPriorityQueue<SimpleNode> _queue;

	public int Count
	{
		get
		{
			lock (_queue)
			{
				return _queue.Count;
			}
		}
	}

	public T First
	{
		get
		{
			lock (_queue)
			{
				if (_queue.Count <= 0)
				{
					throw new InvalidOperationException("Cannot call .First on an empty queue");
				}
				SimpleNode first = _queue.First;
				return (first != null) ? first.Data : default(T);
			}
		}
	}

	public SimplePriorityQueue()
	{
		_queue = new FastPriorityQueue<SimpleNode>(10);
	}

	private SimpleNode GetExistingNode(T item)
	{
		EqualityComparer<T> equalityComparer = EqualityComparer<T>.Default;
		foreach (SimpleNode item2 in _queue)
		{
			if (equalityComparer.Equals(item2.Data, item))
			{
				return item2;
			}
		}
		T val = item;
		throw new InvalidOperationException("Item cannot be found in queue: " + val);
	}

	public void Clear()
	{
		lock (_queue)
		{
			_queue.Clear();
		}
	}

	public bool Contains(T item)
	{
		lock (_queue)
		{
			EqualityComparer<T> equalityComparer = EqualityComparer<T>.Default;
			foreach (SimpleNode item2 in _queue)
			{
				if (equalityComparer.Equals(item2.Data, item))
				{
					return true;
				}
			}
			return false;
		}
	}

	public T Dequeue()
	{
		lock (_queue)
		{
			if (_queue.Count <= 0)
			{
				throw new InvalidOperationException("Cannot call Dequeue() on an empty queue");
			}
			return _queue.Dequeue().Data;
		}
	}

	public void Enqueue(T item, double priority)
	{
		lock (_queue)
		{
			SimpleNode node = new SimpleNode(item);
			if (_queue.Count == _queue.MaxSize)
			{
				_queue.Resize(_queue.MaxSize * 2 + 1);
			}
			_queue.Enqueue(node, priority);
		}
	}

	public void Remove(T item)
	{
		lock (_queue)
		{
			try
			{
				_queue.Remove(GetExistingNode(item));
			}
			catch (InvalidOperationException innerException)
			{
				T val = item;
				throw new InvalidOperationException("Cannot call Remove() on a node which is not enqueued: " + val, innerException);
			}
		}
	}

	public void UpdatePriority(T item, double priority)
	{
		lock (_queue)
		{
			try
			{
				SimpleNode existingNode = GetExistingNode(item);
				_queue.UpdatePriority(existingNode, priority);
			}
			catch (InvalidOperationException innerException)
			{
				T val = item;
				throw new InvalidOperationException("Cannot call UpdatePriority() on a node which is not enqueued: " + val, innerException);
			}
		}
	}

	public IEnumerator<T> GetEnumerator()
	{
		List<T> list = new List<T>();
		lock (_queue)
		{
			foreach (SimpleNode item in _queue)
			{
				list.Add(item.Data);
			}
		}
		return list.GetEnumerator();
	}

	IEnumerator IEnumerable.GetEnumerator()
	{
		return GetEnumerator();
	}

	public bool IsValidQueue()
	{
		lock (_queue)
		{
			return _queue.IsValidQueue();
		}
	}
}
