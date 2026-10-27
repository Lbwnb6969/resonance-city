using UnityEngine;
using UnityEngine.EventSystems;

public class TechnologyTreeConnector : MonoBehaviour
{
	public RectTransform rectT;

	public GameObject containerObj;

	public TooltipHook tooltipHook;

	public TechnologyTree.TechnologyTreeRequireLink link;

	private bool isVisible = true;

	public void SetVisibility(bool v)
	{
		if (v != isVisible && link != null)
		{
			Util.SetActive(link.requirerLine.node1Mask.gameObject, v);
			for (int i = 0; i < link.lines.Count; i++)
			{
				Util.SetActive(link.lines[i].node2Mask.gameObject, v);
			}
		}
		Util.SetActive(containerObj, v);
		isVisible = v;
	}

	public void OnPointerEnter(BaseEventData eData)
	{
		for (int i = 0; i < link.nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = link.nodes[i];
			Util.SetEnabled(technologyTreeNode.outlineImg, active: true);
			technologyTreeNode.outlineImg.color = (technologyTreeNode.isUnlocked ? TechnologyTree.inst.preqSucessColor : TechnologyTree.inst.preqFailColor);
		}
	}

	public void OnPointerExit(BaseEventData eData)
	{
		for (int i = 0; i < link.nodes.Count; i++)
		{
			Util.SetEnabled(link.nodes[i].outlineImg, active: false);
		}
	}
}
