public class EdgeTrigger
{
	private bool oldValue;

	public EdgeTrigger(bool initialState = false)
	{
		oldValue = initialState;
	}

	public bool CheckFalling(bool newValue)
	{
		if (newValue != oldValue)
		{
			oldValue = newValue;
			return !newValue;
		}
		return false;
	}

	public bool CheckRising(bool newValue)
	{
		if (newValue != oldValue)
		{
			oldValue = newValue;
			return newValue;
		}
		return false;
	}
}
