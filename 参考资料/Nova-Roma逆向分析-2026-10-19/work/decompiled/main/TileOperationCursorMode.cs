public class TileOperationCursorMode : CursorMode
{
	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		base.Init();
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		base.Shutdown();
	}
}
