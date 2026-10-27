using UnityEngine;
using UnityEngine.Rendering;

namespace cakeslice;

public interface IProceduralOutline
{
	void DrawOutline(CommandBuffer commandBuffer, Material highlightMaterial);
}
