public class DynamicMeshSize
{
	public int id;

	public int sizeX;

	public int sizeZ;

	public int area;

	public bool IsSameSize(int targetX, int targetZ, out bool isRotated)
	{
		if ((sizeX == targetX && sizeZ == targetZ) || (targetX == sizeZ && targetZ == sizeX))
		{
			isRotated = targetX == sizeZ && targetZ == sizeX;
			return true;
		}
		isRotated = false;
		return false;
	}
}
