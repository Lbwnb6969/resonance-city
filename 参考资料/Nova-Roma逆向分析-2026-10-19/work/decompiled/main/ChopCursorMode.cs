using UnityEngine;
using UnityEngine.Rendering;

public class ChopCursorMode : TileOperationCursorMode
{
	private ArrayExt<Renderer> normal = new ArrayExt<Renderer>(1000);

	private ArrayExt<Renderer> highlight = new ArrayExt<Renderer>(1000);

	public override void Init()
	{
		WorldMask.inst.Activate(Masking);
		base.Init();
	}

	public override void Shutdown()
	{
		WorldMask.inst.Deactivate();
		base.Shutdown();
	}

	public void Masking(CommandBuffer buffer, Material maskingMaterial, RenderTexture rTexture)
	{
		buffer.Clear();
		buffer.SetRenderTarget(rTexture);
		buffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.green);
		_ = Player.inst.FocusedLandMassIdxLastValid;
		normal.Clear();
		highlight.Clear();
		World.inst.treeSystem.DrawWithCommandBuffer(buffer, 3);
		World.inst.rockScatterSystem.DrawWithCommandBuffer(buffer, 3);
	}

	public override void Tick(float dt)
	{
		if (WorldMask.inst.activated)
		{
			WorldMask.inst.ForceUpdate();
		}
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		bool sfx = true;
		for (int i = minZ; i < maxZ; i++)
		{
			for (int j = minX; j < maxX; j++)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(j, i);
				if (Player.inst.LandMassIsAPlayerLandMass(cellDataClamped.landMassIdx) && GameUI.inst.AddChopJobToCell(cellDataClamped, sfx))
				{
					sfx = false;
				}
			}
		}
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell cellData)
	{
		if (cellData != null && !Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx))
		{
			return true;
		}
		if (clickedBuilding != null && clickedBuilding.TeamID() != 0)
		{
			return true;
		}
		if (cellData != null)
		{
			GameUI.inst.AddChopJobToCell(cellData);
		}
		else if (clickedBuilding != null && clickedBuilding.UniqueNameHash() == "coppice".GetHashCode())
		{
			Building building = clickedBuilding as Building;
			GameUI.inst.AddChopJobToCell(building.GetCell());
		}
		return true;
	}
}
