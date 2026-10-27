using UnityEngine;

public class BuildMenuButtonsUI : MonoBehaviour
{
	public SlideAnim slideAnim;

	private void Update()
	{
		bool flag = true;
		if (GameUI.inst.currCursorMode is DockRouteCursorMode || GamepadControl.inst.isControllerActive)
		{
			flag = false;
		}
		slideAnim.Play((!flag) ? SlideAnim.PlayMode.Forward : SlideAnim.PlayMode.Reverse);
	}
}
