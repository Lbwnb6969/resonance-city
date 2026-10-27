using System;
using UnityEngine;

public class ShipCatapultContainer : MonoBehaviour
{
	public Catapult catapultPrefab;

	[NonSerialized]
	public Catapult catapult;

	private TroopTransportShip transport;

	private void Start()
	{
		catapult = UnityEngine.Object.Instantiate(catapultPrefab);
		Transform parent = transform.Find("ShipCatapult");
		catapult.transform.SetParent(parent, worldPositionStays: true);
		catapult.transform.localPosition = Vector3.zero;
		catapult.transform.localRotation = Quaternion.identity;
		transport = GetComponent<TroopTransportShip>();
	}

	private void Update()
	{
		catapult.manned = transport.CarryCount() != 0;
		if (catapult.manned && catapult.GetStatus() == Catapult.Status.Idle)
		{
			catapult.SetTarget(Catapult.FindTarget(catapult, Catapult.DefaultShouldIgnore, transport.GetDestPos()));
		}
	}
}
