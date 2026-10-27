using System.Collections.Generic;
using System.Linq;

public class Dijkstra
{
	public List<PathVertex> vertices = new List<PathVertex>();

	public List<PathEdge> edges = new List<PathEdge>();

	public Dictionary<PathVertex, List<PathEdge>> edgesByVertex = new Dictionary<PathVertex, List<PathEdge>>();

	public Dijkstra(List<PathVertex> vertices, List<PathEdge> edges)
	{
		this.vertices.AddRange(vertices);
		this.edges.AddRange(edges);
		for (short num = 0; num < this.vertices.Count; num++)
		{
			this.vertices[num].pathingId = num;
		}
		foreach (PathVertex vertex in vertices)
		{
			edgesByVertex.Add(vertex, new List<PathEdge>());
		}
		foreach (PathEdge edge in edges)
		{
			if (edge.direction == PathEdge.Direction.Directional)
			{
				edgesByVertex[edge.a].Add(edge);
			}
			if (edge.direction == PathEdge.Direction.BiDirectional)
			{
				edgesByVertex[edge.a].Add(edge);
				edgesByVertex[edge.b].Add(edge);
			}
		}
	}

	public void GetShortestPathsFrom(PathVertex start, ref short[] tree, int offset)
	{
		Dictionary<PathVertex, float> distances = new Dictionary<PathVertex, float>();
		List<PathVertex> list = new List<PathVertex>();
		foreach (PathVertex vertex in vertices)
		{
			distances.Add(vertex, float.MaxValue);
			list.Add(vertex);
		}
		distances[start] = 0f;
		while (list.Count > 0)
		{
			PathVertex pathVertex = list.OrderBy((PathVertex x) => distances[x]).First();
			list.Remove(pathVertex);
			foreach (PathEdge item in edgesByVertex[pathVertex])
			{
				PathVertex pathVertex2 = ((item.a == pathVertex) ? item.b : item.a);
				if (list.Contains(pathVertex2))
				{
					float num = distances[pathVertex] + item.weight;
					if (num < distances[pathVertex2])
					{
						distances[pathVertex2] = num;
						tree[offset + pathVertex2.pathingId] = pathVertex.pathingId;
					}
				}
			}
		}
	}
}
