using System;

[Serializable]
public struct DamBlockState(Building building)
{
	public float life = building.Life;

	public float modifiedMaxLife = building.ModifiedMaxLife;

	public bool IsDamaged => life < modifiedMaxLife;

	public void RestoreToBuilding(Building target)
	{
		target.Life = life;
		target.ModifiedMaxLife = modifiedMaxLife;
		if (IsDamaged)
		{
			target.TakeDamage(0f, target.Center(), "dam_restore");
		}
	}
}
