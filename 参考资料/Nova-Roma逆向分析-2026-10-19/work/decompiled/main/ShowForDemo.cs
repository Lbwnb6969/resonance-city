using UnityEngine;

public class ShowForDemo : MonoBehaviour
{
	[SerializeField]
	private bool showInDemo = true;

	private string InfoBoxText
	{
		get
		{
			if (!showInDemo)
			{
				return "Will show in full game, won't show in demo builds.";
			}
			return "Will show in demo builds, won't show in full game.";
		}
	}

	private void Awake()
	{
		Update_();
	}

	private void OnEnable()
	{
		Update_();
	}

	private void Update_()
	{
		bool flag = false;
		gameObject.SetActive(showInDemo == flag);
	}
}
