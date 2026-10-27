using System;

[Serializable]
public class DefenseCell : GridCell
{
	public bool Castle;

	public bool CastleEdge;

	public bool innerWall;

	public bool DisallowCastleEdge;

	public bool DisallowCastle;
}
