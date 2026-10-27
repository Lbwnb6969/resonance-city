using System;
using System.Collections.Generic;

namespace Roma.Aqueduct;

public sealed class AqueductFlowSolver
{
	private const float EPSILON = 1E-06f;

	private const int SUPER_SOURCE = 0;

	private const int SUPER_SINK = 1;

	private const int NODE_OFFSET = 2;

	private int _nodeCount;

	private readonly List<bool> _isSource = new List<bool>(64);

	private readonly List<float> _sourceCap = new List<float>(64);

	private readonly List<bool> _isConsumer = new List<bool>(64);

	private readonly List<float> _demand = new List<float>(64);

	private readonly List<int> _priority = new List<int>(64);

	private readonly List<float> _minServe = new List<float>(64);

	private readonly List<bool> _passthrough = new List<bool>(64);

	private readonly List<int> _edgeFrom = new List<int>(256);

	private readonly List<int> _edgeTo = new List<int>(256);

	private readonly List<float> _edgeCapInput = new List<float>(256);

	private readonly List<int> edgeTo = new List<int>(512);

	private readonly List<float> edgeCap = new List<float>(512);

	private readonly List<float> edgeFlow = new List<float>(512);

	private readonly List<float> edgeCommitted = new List<float>(512);

	private readonly List<List<int>> nodeAdj = new List<List<int>>(64);

	private readonly List<int> consumerOrder = new List<int>(32);

	private int[] _sinkEdge = Array.Empty<int>();

	private int[] _sourceEdge = Array.Empty<int>();

	private bool[] _rolledBack = Array.Empty<bool>();

	private int[] bfsDepth = Array.Empty<int>();

	private int[] bfsParentEdge = Array.Empty<int>();

	private readonly Queue<int> bfsQueue = new Queue<int>(64);

	private bool _solved;

	public int NodeCount => _nodeCount;

	public int EdgeCount => _edgeFrom.Count;

	public AqueductFlowSolver()
	{
	}

	public AqueductFlowSolver(int nodeCapacityHint, int edgeCapacityHint)
	{
	}

	public int AddNode()
	{
		int result = _nodeCount++;
		_isSource.Add(item: false);
		_sourceCap.Add(0f);
		_isConsumer.Add(item: false);
		_demand.Add(0f);
		_priority.Add(0);
		_minServe.Add(0f);
		_passthrough.Add(item: false);
		_solved = false;
		return result;
	}

	public void MarkSource(int node, float capacity)
	{
		ValidateNode(node);
		if (capacity < 0f)
		{
			throw new ArgumentOutOfRangeException("capacity", "capacity must be >= 0");
		}
		_isSource[node] = true;
		_sourceCap[node] = capacity;
		_solved = false;
	}

	public void MarkConsumer(int node, float demand, int priority = 0)
	{
		MarkConsumer(node, demand, priority, 0f);
	}

	public void MarkConsumer(int node, float demand, int priority, float minServe)
	{
		MarkConsumer(node, demand, priority, minServe, passthrough: false);
	}

	public void MarkConsumer(int node, float demand, int priority, float minServe, bool passthrough)
	{
		ValidateNode(node);
		if (demand < 0f)
		{
			throw new ArgumentOutOfRangeException("demand", "demand must be >= 0");
		}
		if (minServe < 0f)
		{
			throw new ArgumentOutOfRangeException("minServe", "minServe must be >= 0");
		}
		_isConsumer[node] = true;
		_demand[node] = demand;
		_priority[node] = priority;
		_minServe[node] = minServe;
		_passthrough[node] = passthrough;
		_solved = false;
	}

	public int AddEdge(int from, int to, float capacity)
	{
		ValidateNode(from);
		ValidateNode(to);
		if (capacity < 0f)
		{
			throw new ArgumentOutOfRangeException("capacity", "capacity must be >= 0");
		}
		int count = _edgeFrom.Count;
		_edgeFrom.Add(from);
		_edgeTo.Add(to);
		_edgeCapInput.Add(capacity);
		_solved = false;
		return count;
	}

	public void SetEdgeCapacity(int edgeId, float capacity)
	{
		ValidateEdge(edgeId);
		if (capacity < 0f)
		{
			throw new ArgumentOutOfRangeException("capacity", "capacity must be >= 0");
		}
		_edgeCapInput[edgeId] = capacity;
		_solved = false;
	}

	public void Clear()
	{
		_nodeCount = 0;
		_isSource.Clear();
		_sourceCap.Clear();
		_isConsumer.Clear();
		_demand.Clear();
		_priority.Clear();
		_minServe.Clear();
		_passthrough.Clear();
		_edgeFrom.Clear();
		_edgeTo.Clear();
		_edgeCapInput.Clear();
		ClearWorkingGraph();
		_solved = false;
	}

	public void Solve()
	{
		BuildWorkingGraph();
		ComputeConsumerOrder();
		RunMaxFlow();
		_solved = true;
	}

	public void SolveWithConduitDetection(int maxRounds = 4)
	{
		Solve();
		for (int i = 0; i < maxRounds; i++)
		{
			bool flag = false;
			for (int j = 0; j < _nodeCount; j++)
			{
				if (_isConsumer[j] && !_passthrough[j] && !(_demand[j] <= 1E-06f) && !WasRolledBack(j) && !(GetServedAmount(j) >= _demand[j] - 1E-06f) && !(GetNetworkOutflow(j) <= 1E-06f))
				{
					_passthrough[j] = true;
					flag = true;
				}
			}
			if (!flag)
			{
				break;
			}
			Solve();
		}
	}

	private void ClearWorkingGraph()
	{
		edgeTo.Clear();
		edgeCap.Clear();
		edgeFlow.Clear();
		edgeCommitted.Clear();
		for (int i = 0; i < nodeAdj.Count; i++)
		{
			nodeAdj[i].Clear();
		}
		consumerOrder.Clear();
	}

	private void BuildWorkingGraph()
	{
		ClearWorkingGraph();
		int num = _nodeCount + 2;
		while (nodeAdj.Count < num)
		{
			nodeAdj.Add(new List<int>(4));
		}
		if (_sinkEdge.Length < _nodeCount)
		{
			_sinkEdge = new int[_nodeCount];
		}
		if (_sourceEdge.Length < _nodeCount)
		{
			_sourceEdge = new int[_nodeCount];
		}
		for (int i = 0; i < _nodeCount; i++)
		{
			_sinkEdge[i] = -1;
			_sourceEdge[i] = -1;
		}
		for (int j = 0; j < _edgeFrom.Count; j++)
		{
			AddPairedEdge(Internal(_edgeFrom[j]), Internal(_edgeTo[j]), _edgeCapInput[j]);
		}
		for (int k = 0; k < _nodeCount; k++)
		{
			if (_isSource[k])
			{
				_sourceEdge[k] = edgeTo.Count;
				AddPairedEdge(0, Internal(k), _sourceCap[k]);
			}
			if (_isConsumer[k] && _demand[k] > 1E-06f)
			{
				_sinkEdge[k] = edgeTo.Count;
				AddPairedEdge(Internal(k), 1, 0f);
				consumerOrder.Add(k);
			}
		}
	}

	private void AddPairedEdge(int from, int to, float cap)
	{
		int count = edgeTo.Count;
		edgeTo.Add(to);
		edgeCap.Add(cap);
		edgeFlow.Add(0f);
		edgeCommitted.Add(0f);
		nodeAdj[from].Add(count);
		edgeTo.Add(from);
		edgeCap.Add(0f);
		edgeFlow.Add(0f);
		edgeCommitted.Add(0f);
		nodeAdj[to].Add(count + 1);
	}

	private float Residual(int e)
	{
		if ((e & 1) == 0)
		{
			return edgeCap[e] - edgeCommitted[e] - edgeFlow[e];
		}
		return 0f - edgeFlow[e];
	}

	private void ComputeConsumerOrder()
	{
		int count = nodeAdj.Count;
		if (bfsDepth.Length < count)
		{
			bfsDepth = new int[count];
		}
		for (int i = 0; i < count; i++)
		{
			bfsDepth[i] = int.MaxValue;
		}
		bfsDepth[0] = 0;
		bfsQueue.Clear();
		bfsQueue.Enqueue(0);
		while (bfsQueue.Count > 0)
		{
			int num = bfsQueue.Dequeue();
			List<int> list = nodeAdj[num];
			for (int j = 0; j < list.Count; j++)
			{
				int num2 = list[j];
				if ((num2 & 1) == 0 && !(edgeCap[num2] <= 1E-06f))
				{
					int num3 = edgeTo[num2];
					if (bfsDepth[num3] == int.MaxValue)
					{
						bfsDepth[num3] = bfsDepth[num] + 1;
						bfsQueue.Enqueue(num3);
					}
				}
			}
		}
		consumerOrder.Sort(CompareConsumers);
	}

	private int CompareConsumers(int a, int b)
	{
		if (_passthrough[a] != _passthrough[b])
		{
			if (!_passthrough[a])
			{
				return 1;
			}
			return -1;
		}
		int num = bfsDepth[Internal(a)];
		int num2 = bfsDepth[Internal(b)];
		if (_passthrough[a])
		{
			if (num != num2)
			{
				return num.CompareTo(num2);
			}
			if (_priority[a] != _priority[b])
			{
				return _priority[b].CompareTo(_priority[a]);
			}
		}
		else
		{
			if (_priority[a] != _priority[b])
			{
				return _priority[b].CompareTo(_priority[a]);
			}
			if (num != num2)
			{
				return num.CompareTo(num2);
			}
		}
		int num3 = _demand[b].CompareTo(_demand[a]);
		if (num3 != 0)
		{
			return num3;
		}
		return a.CompareTo(b);
	}

	private void RunMaxFlow()
	{
		int count = nodeAdj.Count;
		if (bfsParentEdge.Length < count)
		{
			bfsParentEdge = new int[count];
		}
		if (_rolledBack.Length < _nodeCount)
		{
			_rolledBack = new bool[_nodeCount];
		}
		for (int i = 0; i < _nodeCount; i++)
		{
			_rolledBack[i] = false;
		}
		for (int j = 0; j < consumerOrder.Count; j++)
		{
			int num = consumerOrder[j];
			int num2 = _sinkEdge[num];
			if (num2 < 0)
			{
				continue;
			}
			edgeCap[num2] = _demand[num];
			for (int k = 0; k < edgeFlow.Count; k++)
			{
				edgeFlow[k] = 0f;
			}
			int num3 = 0;
			int num4 = nodeAdj.Count * edgeTo.Count + 16;
			while (BfsAugmentingPath(1) && ++num3 <= num4)
			{
				float num5 = float.MaxValue;
				int num6 = 1;
				while (num6 != 0)
				{
					int num7 = bfsParentEdge[num6];
					float num8 = Residual(num7);
					if (num8 < num5)
					{
						num5 = num8;
					}
					num6 = edgeTo[num7 ^ 1];
				}
				if (num5 <= 1E-06f)
				{
					break;
				}
				int num9 = 1;
				while (num9 != 0)
				{
					int num10 = bfsParentEdge[num9];
					edgeFlow[num10] += num5;
					edgeFlow[num10 ^ 1] -= num5;
					num9 = edgeTo[num10 ^ 1];
				}
			}
			bool flag = ((num2 >= 0) ? edgeFlow[num2] : 0f) < _minServe[num] - 1E-06f;
			_rolledBack[num] = flag;
			for (int l = 0; l < edgeFlow.Count; l += 2)
			{
				if (!flag)
				{
					float num11 = edgeFlow[l];
					if (num11 > 0f)
					{
						edgeCommitted[l] += num11;
					}
				}
				edgeFlow[l] = 0f;
				edgeFlow[l + 1] = 0f;
			}
			if (flag && num2 >= 0)
			{
				edgeCap[num2] = 0f;
			}
		}
	}

	private bool BfsAugmentingPath(int target)
	{
		int count = nodeAdj.Count;
		for (int i = 0; i < count; i++)
		{
			bfsParentEdge[i] = -1;
		}
		bfsParentEdge[0] = -2;
		bfsQueue.Clear();
		bfsQueue.Enqueue(0);
		while (bfsQueue.Count > 0)
		{
			int num = bfsQueue.Dequeue();
			if (num == target)
			{
				return true;
			}
			List<int> list = nodeAdj[num];
			for (int j = 0; j < list.Count; j++)
			{
				int num2 = list[j];
				int num3 = edgeTo[num2];
				if (bfsParentEdge[num3] == -1 && !(Residual(num2) <= 1E-06f * (1f + edgeCap[num2 & -2])))
				{
					bfsParentEdge[num3] = num2;
					if (num3 == target)
					{
						return true;
					}
					bfsQueue.Enqueue(num3);
				}
			}
		}
		return false;
	}

	public float GetEdgeCapacityInput(int edgeId)
	{
		ValidateEdge(edgeId);
		return _edgeCapInput[edgeId];
	}

	public float GetEdgeFlow(int edgeId)
	{
		ValidateEdge(edgeId);
		if (!_solved)
		{
			return 0f;
		}
		return edgeCommitted[edgeId * 2];
	}

	public float GetServedAmount(int node)
	{
		ValidateNode(node);
		if (!_solved)
		{
			return 0f;
		}
		int num = _sinkEdge[node];
		if (num < 0)
		{
			return 0f;
		}
		return edgeCommitted[num];
	}

	public float GetNodeInflow(int node)
	{
		ValidateNode(node);
		if (!_solved)
		{
			return 0f;
		}
		float num = 0f;
		List<int> list = nodeAdj[Internal(node)];
		for (int i = 0; i < list.Count; i++)
		{
			int num2 = list[i];
			if ((num2 & 1) != 0)
			{
				num += edgeCommitted[num2 ^ 1];
			}
		}
		return num;
	}

	public float GetNetworkOutflow(int node)
	{
		ValidateNode(node);
		if (!_solved)
		{
			return 0f;
		}
		float num = 0f;
		List<int> list = nodeAdj[Internal(node)];
		for (int i = 0; i < list.Count; i++)
		{
			int num2 = list[i];
			if ((num2 & 1) == 0 && edgeTo[num2] != 1)
			{
				num += edgeCommitted[num2];
			}
		}
		return num;
	}

	public float GetSourceExtraction(int node)
	{
		ValidateNode(node);
		if (!_solved)
		{
			return 0f;
		}
		int num = _sourceEdge[node];
		if (num < 0)
		{
			return 0f;
		}
		return edgeCommitted[num];
	}

	public float GetNodeDemand(int node)
	{
		ValidateNode(node);
		if (!_isConsumer[node])
		{
			return 0f;
		}
		return _demand[node];
	}

	public bool IsUnderserved(int node)
	{
		ValidateNode(node);
		if (!_isConsumer[node])
		{
			return false;
		}
		return GetServedAmount(node) < _demand[node] - 1E-06f;
	}

	public bool IsPassthrough(int node)
	{
		ValidateNode(node);
		if (_isConsumer[node])
		{
			return _passthrough[node];
		}
		return false;
	}

	public bool WasRolledBack(int node)
	{
		ValidateNode(node);
		if (!_isConsumer[node])
		{
			return false;
		}
		if (node < _rolledBack.Length)
		{
			return _rolledBack[node];
		}
		return false;
	}

	public int GetBfsDepth(int node)
	{
		ValidateNode(node);
		if (!_solved)
		{
			return int.MaxValue;
		}
		return bfsDepth[Internal(node)];
	}

	private static int Internal(int publicNode)
	{
		return publicNode + 2;
	}

	private void ValidateNode(int node)
	{
		if (node < 0 || node >= _nodeCount)
		{
			throw new ArgumentOutOfRangeException("node", $"node {node} out of range [0,{_nodeCount})");
		}
	}

	private void ValidateEdge(int edgeId)
	{
		if (edgeId < 0 || edgeId >= _edgeFrom.Count)
		{
			throw new ArgumentOutOfRangeException("edgeId", $"edge {edgeId} out of range [0,{_edgeFrom.Count})");
		}
	}
}
