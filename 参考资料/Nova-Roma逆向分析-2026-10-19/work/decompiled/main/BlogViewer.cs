using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BlogViewer : MonoBehaviour
{
	public SlideAnim slideAnim;

	public ScrollRect blogScrollRect;

	private WWW www;

	public string blogSite = "keys.lionshieldstudios.com";

	public void ShowNews(bool on)
	{
		if (on)
		{
			SfxSystem.PlayUiSelect();
			SfxSystem.inst.PlayFromBank("ui_Window_Close", Camera.main.transform.position);
			slideAnim.Play(SlideAnim.PlayMode.Forward);
			www = new WWW(blogSite);
			enabled = true;
		}
		else
		{
			SfxSystem.PlayUiCancel();
			SfxSystem.inst.PlayFromBank("ui_Window_Close", Camera.main.transform.position);
			slideAnim.Play(SlideAnim.PlayMode.Reverse);
		}
	}

	private void Update()
	{
		if (www != null && www.isDone)
		{
			GetComponent<TextMeshProUGUI>().text = www.text;
			if (string.IsNullOrEmpty(www.text))
			{
				GetComponent<TextMeshProUGUI>().text = www.error;
			}
			enabled = false;
			slideAnim.GetComponent<ScrollRect>().CalculateLayoutInputVertical();
		}
	}
}
