using UnityEngine;

public class SiegeWorkshop : Tickable
{
	public Transform bigGear1;

	public Transform bigGear2;

	public Transform smallGear;

	public Transform inprogressCatapult;

	private Barracks barracks;

	private Building b;

	public float smallGearSpeed = 25f;

	public float bigGearSpeed = 10f;

	private bool wasTraining;

	private OneOffEffect buildEffect;

	public override void OnEnableInternal()
	{
		barracks = GetComponent<Barracks>();
		b = GetComponent<Building>();
		base.OnEnableInternal();
	}

	public void OnBuilt()
	{
		bigGear1.gameObject.SetActive(value: true);
		bigGear2.gameObject.SetActive(value: true);
		smallGear.gameObject.SetActive(value: true);
	}

	private void OnFinishedLoad()
	{
		bigGear1.gameObject.SetActive(b.IsBuilt());
		bigGear2.gameObject.SetActive(b.IsBuilt());
		smallGear.gameObject.SetActive(b.IsBuilt());
	}

	public override void Tick(float dt, int currFrame)
	{
		if (barracks.training)
		{
			bigGear1.Rotate(dt * bigGearSpeed, 0f, 0f);
			bigGear2.Rotate(dt * bigGearSpeed, 0f, 0f);
			smallGear.Rotate(dt * smallGearSpeed, 0f, 0f);
			if (!wasTraining)
			{
				buildEffect = EffectsMan.inst.BuildEffect.CreateAndPlay(barracks.spawnPoint.position - new Vector3(0.5f, 0f, 0.5f));
				buildEffect.AllowRelease = true;
			}
		}
		else if (!barracks.training && wasTraining && (bool)buildEffect)
		{
			buildEffect.Stop();
			buildEffect = null;
		}
		wasTraining = barracks.training;
		inprogressCatapult.gameObject.SetActive(barracks.training);
	}

	public override void OnDisableInternal()
	{
		if ((bool)buildEffect)
		{
			buildEffect.StopImmediately();
			buildEffect = null;
		}
		base.OnDisableInternal();
	}
}
