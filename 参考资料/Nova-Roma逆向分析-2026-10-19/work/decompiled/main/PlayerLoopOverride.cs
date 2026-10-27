using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.LowLevel;

public class PlayerLoopOverride : MonoBehaviour
{
	[RuntimeInitializeOnLoadMethod]
	private static void AppStart()
	{
		PlayerLoopSystem defaultPlayerLoop = PlayerLoop.GetDefaultPlayerLoop();
		for (int i = 0; i < defaultPlayerLoop.subSystemList.Length; i++)
		{
			List<PlayerLoopSystem> list = new List<PlayerLoopSystem>(defaultPlayerLoop.subSystemList[i].subSystemList);
			for (int j = 0; j < list.Count; j++)
			{
				switch (list[j].type.Name)
				{
				case "UpdateKinect":
				case "EnlightenRuntimeUpdate":
				case "DeliverIosPlatformEvents":
				case "TangoUpdate":
				case "Physics2DFixedUpdate":
				case "Physics2DUpdate":
					list.RemoveAt(j);
					j--;
					break;
				}
			}
			defaultPlayerLoop.subSystemList[i].subSystemList = list.ToArray();
		}
		PlayerLoop.SetPlayerLoop(defaultPlayerLoop);
	}

	private static void CustomUpdate()
	{
		Debug.Log("Custom update running!");
	}

	private static void RecursivePlayerLoopPrint(PlayerLoopSystem def, StringBuilder sb, int depth)
	{
		if (depth == 0)
		{
			sb.AppendLine("ROOT NODE");
		}
		else if (def.type != null)
		{
			for (int i = 0; i < depth; i++)
			{
				sb.Append("\t");
			}
			sb.AppendLine(def.type.Name);
		}
		if (def.subSystemList != null)
		{
			depth++;
			PlayerLoopSystem[] subSystemList = def.subSystemList;
			for (int j = 0; j < subSystemList.Length; j++)
			{
				RecursivePlayerLoopPrint(subSystemList[j], sb, depth);
			}
			depth--;
		}
	}
}
