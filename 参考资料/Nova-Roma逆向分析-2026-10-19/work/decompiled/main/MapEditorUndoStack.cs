using System.Collections.Generic;
using Code;

public static class MapEditorUndoStack
{
	private static readonly Stack<IMapEditorUndoEntry> stack = new Stack<IMapEditorUndoEntry>();

	public static bool RescanPending;

	public static bool CanUndo => stack.Count > 0;

	public static IMapEditorUndoEntry Peek()
	{
		if (stack.Count <= 0)
		{
			return null;
		}
		return stack.Peek();
	}

	public static void Push(IMapEditorUndoEntry entry)
	{
		stack.Push(entry);
	}

	public static void PerformUndo()
	{
		if (stack.Count > 0)
		{
			stack.Pop().Undo();
			Water.UpdateNeeded = true;
			RescanPending = true;
		}
	}

	public static void Clear()
	{
		stack.Clear();
	}
}
