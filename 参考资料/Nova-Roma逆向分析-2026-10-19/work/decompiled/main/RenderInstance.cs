using UnityEngine;

public class RenderInstance
{
	public Mesh mesh;

	public Material material;

	private Matrix4x4 hiddenMatrix;

	public int listIndex;

	public int arrayIndex;

	public InstanceSilo silo;

	private ArrayExt<Matrix4x4> cachedArray;

	public bool castShadows = true;

	private bool visible;

	public bool Visible
	{
		get
		{
			return visible;
		}
		set
		{
			if (!value && visible)
			{
				InstanceManager.inst.Remove(this);
			}
			if (value && !visible)
			{
				InstanceManager.inst.Add(this, hiddenMatrix, castShadows);
			}
			visible = value;
		}
	}

	public RenderInstance(Mesh mesh, Material material)
	{
		this.mesh = mesh;
		this.material = material;
	}

	public void UpdateIndex(InstanceSilo silo, int listIndex, int arrayIndex)
	{
		this.silo = silo;
		this.listIndex = listIndex;
		this.arrayIndex = arrayIndex;
		cachedArray = silo.matricies[listIndex];
	}

	public Matrix4x4 GetMatrix()
	{
		return hiddenMatrix;
	}

	public void UpdateMatrix(Matrix4x4 matrix)
	{
		if (Visible)
		{
			cachedArray.data[arrayIndex] = matrix;
		}
		hiddenMatrix = matrix;
	}

	public void UpdateTS(Vector3 pos, Vector3 scale)
	{
		Mathff.SetTS(ref hiddenMatrix, pos, scale);
		if (Visible)
		{
			cachedArray.data[arrayIndex] = hiddenMatrix;
		}
	}

	public void UpdateTRS(Vector3 pos, Quaternion rot, Vector3 scale)
	{
		Mathff.SetTRS(ref hiddenMatrix, pos, rot, scale);
		if (Visible)
		{
			cachedArray.data[arrayIndex] = hiddenMatrix;
		}
	}
}
