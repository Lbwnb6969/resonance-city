using Drawing;
using UnityEngine;

public class HeightTester : MonoBehaviour
{
	public int size = 20;

	public Material material;

	public Mesh mesh;

	public Matrix4x4[] matrices;

	private Vector3[] triangle;

	private void Update()
	{
		if (matrices.Length != size * size)
		{
			matrices = new Matrix4x4[size * size];
		}
		if (triangle == null)
		{
			triangle = new Vector3[3];
		}
		for (int i = 0; i < size; i++)
		{
			for (int j = 0; j < size; j++)
			{
				Vector3 position = transform.position;
				position.y = TerrainGen.inst.GetInterpolatedHeight_WithBridging(position);
				matrices[i + j * size] = Matrix4x4.TRS(position, Quaternion.identity, Vector3.one * 0.25f);
			}
		}
		Vector3 position2 = transform.position;
		TerrainGen.inst.GetTriangleAtPointBridge(position2.x, position2.z, ref triangle);
		Draw.editor.Line(triangle[0], triangle[1], Color.white);
		Draw.editor.Line(triangle[1], triangle[2], Color.white);
		Draw.editor.Line(triangle[2], triangle[0], Color.white);
		Graphics.DrawMeshInstanced(mesh, 0, material, matrices, matrices.Length);
	}
}
