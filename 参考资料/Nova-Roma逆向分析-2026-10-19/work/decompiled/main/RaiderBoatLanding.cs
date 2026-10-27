using System;
using UnityEngine;

[Serializable]
public class RaiderBoatLanding
{
	public SerializableVector3 boatLanding;

	public SerializableVector3 CrewLanding;

	public SerializableVector3 side1;

	public SerializableVector3 side2;

	public Vector3 Side1 => side1;

	public Vector3 Side2 => side2;

	public Vector3 BoatLanding => boatLanding;

	public RaiderBoatLanding(Cell boatLanding, Cell crewLanding, Cell side1, Cell side2)
	{
		this.boatLanding = boatLanding.Center2D;
		CrewLanding = crewLanding.Center2D;
		this.side1 = side1.Center2D;
		this.side2 = side2.Center2D;
	}
}
