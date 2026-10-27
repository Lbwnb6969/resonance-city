using TMPro;

public class ConsoleUIDropdown : ConsoleUISelectable
{
	public TMP_Dropdown dropdown;

	public override void Submit()
	{
		dropdown.Show();
	}

	public override void Focus()
	{
		dropdown.Hide();
	}
}
