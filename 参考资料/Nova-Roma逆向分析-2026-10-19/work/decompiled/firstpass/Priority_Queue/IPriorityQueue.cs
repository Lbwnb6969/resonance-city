using System.Collections;
using System.Collections.Generic;

namespace Priority_Queue;

public interface IPriorityQueue<T> : IEnumerable<T>, IEnumerable
{
	T First { get; }

	int Count { get; }

	void Enqueue(T node, double priority);

	T Dequeue();

	void Clear();

	bool Contains(T node);

	void Remove(T node);

	void UpdatePriority(T node, double priority);
}
