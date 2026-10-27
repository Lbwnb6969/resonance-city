using UnityEngine.UI;

public class TextChanger<T>
{
	private T lastVal;

	private Text text;

	public TextChanger(Text ourText, T newVal)
	{
		lastVal = newVal;
		text = ourText;
		text.text = newVal.ToString();
	}

	public void Update(T val)
	{
		object obj = lastVal;
		if (!val.Equals(obj))
		{
			lastVal = val;
			text.text = val.ToString();
		}
	}
}
