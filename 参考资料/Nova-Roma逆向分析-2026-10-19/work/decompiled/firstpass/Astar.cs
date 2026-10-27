using System.Collections.Generic;
using Priority_Queue;

public class Astar<T>
{
	public class AstarPathNode
	{
		public float G = float.PositiveInfinity;

		public float F;

		public AstarPathNode previous;

		public bool visited;

		public T data;
	}

	public delegate float EvaluateNodes(T prev, T curr);

	public delegate T[] GetNeighbors(T prev);

	public delegate bool EndNode(T node);

	private Dictionary<T, AstarPathNode> quickNodeLookup;

	private SimplePriorityQueue<AstarPathNode> pQueue;

	private EvaluateNodes pathFunction;

	private EvaluateNodes heuristicFunction;

	private GetNeighbors getNeighbors;

	private EndNode endNode;

	public Astar(EvaluateNodes pathFunction, EvaluateNodes heuristicFunction, GetNeighbors getNeighbors)
	{
		this.pathFunction = pathFunction;
		this.heuristicFunction = heuristicFunction;
		this.getNeighbors = getNeighbors;
		endNode = endNode;
		pQueue = new SimplePriorityQueue<AstarPathNode>();
		quickNodeLookup = new Dictionary<T, AstarPathNode>();
	}

	private void AddNode(AstarPathNode node)
	{
		pQueue.Enqueue(node, node.F);
		quickNodeLookup.Add(node.data, node);
	}

	public List<T> FindPath(T start, EndNode endPredicate, bool debug = false)
	{
		List<T> list = null;
		if (endPredicate(start))
		{
			list = new List<T>();
			list.Add(start);
			return list;
		}
		AstarPathNode astarPathNode = new AstarPathNode();
		astarPathNode.data = start;
		astarPathNode.G = 0f;
		astarPathNode.F = 0f;
		AddNode(astarPathNode);
		while (pQueue.Count > 0)
		{
			AstarPathNode astarPathNode2 = pQueue.Dequeue();
			if (endPredicate(astarPathNode2.data))
			{
				list = new List<T>();
				list.Add(astarPathNode2.data);
				while (astarPathNode2.previous != null)
				{
					astarPathNode2 = astarPathNode2.previous;
					list.Add(astarPathNode2.data);
				}
				list.Reverse();
				break;
			}
			astarPathNode2.visited = true;
			T[] array = getNeighbors(astarPathNode2.data);
			for (int i = 0; i < array.Length; i++)
			{
				if (array[i] == null)
				{
					continue;
				}
				AstarPathNode value = null;
				quickNodeLookup.TryGetValue(array[i], out value);
				if (value == null)
				{
					value = new AstarPathNode();
					value.data = array[i];
					AddNode(value);
				}
				if (!value.visited)
				{
					float num = astarPathNode2.G + pathFunction(astarPathNode2.data, array[i]);
					if (num < value.G)
					{
						value.G = num;
						value.F = value.G + heuristicFunction(astarPathNode2.data, value.data);
						value.previous = astarPathNode2;
						pQueue.UpdatePriority(value, value.F);
					}
				}
			}
		}
		quickNodeLookup.Clear();
		pQueue.Clear();
		return list;
	}

	public List<T> FindPath(T start, T end, bool debug = false)
	{
		List<T> list = null;
		if (start.Equals(end))
		{
			list = new List<T>();
			list.Add(end);
			return list;
		}
		AstarPathNode astarPathNode = new AstarPathNode();
		astarPathNode.data = start;
		astarPathNode.G = 0f;
		astarPathNode.F = heuristicFunction(start, end);
		AddNode(astarPathNode);
		while (pQueue.Count > 0)
		{
			AstarPathNode astarPathNode2 = pQueue.Dequeue();
			if (astarPathNode2.data.Equals(end))
			{
				list = new List<T>();
				list.Add(astarPathNode2.data);
				while (astarPathNode2.previous != null)
				{
					astarPathNode2 = astarPathNode2.previous;
					list.Add(astarPathNode2.data);
				}
				list.Reverse();
				break;
			}
			astarPathNode2.visited = true;
			T[] array = getNeighbors(astarPathNode2.data);
			for (int i = 0; i < array.Length; i++)
			{
				if (array[i] == null)
				{
					continue;
				}
				AstarPathNode value = null;
				quickNodeLookup.TryGetValue(array[i], out value);
				if (value == null)
				{
					value = new AstarPathNode();
					value.data = array[i];
					AddNode(value);
				}
				if (!value.visited)
				{
					float num = astarPathNode2.G + pathFunction(astarPathNode2.data, array[i]);
					if (num < value.G)
					{
						value.G = num;
						value.F = value.G + heuristicFunction(value.data, end);
						value.previous = astarPathNode2;
						pQueue.UpdatePriority(value, value.F);
					}
				}
			}
		}
		quickNodeLookup.Clear();
		pQueue.Clear();
		return list;
	}
}
