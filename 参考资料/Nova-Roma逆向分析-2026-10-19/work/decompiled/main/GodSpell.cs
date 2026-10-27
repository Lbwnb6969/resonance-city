using I2.Loc;

public class GodSpell
{
	public delegate void CastSpell();

	public delegate bool IsValid();

	public string descTerm;

	public string invalidTerm;

	public int cost;

	public int godIdx;

	public float cooldown;

	public float maxCooldown = 100f;

	public CastSpell castSpell;

	public IsValid isValid;

	public string GetDescription()
	{
		return LocalizationManager.GetTranslation(descTerm);
	}
}
