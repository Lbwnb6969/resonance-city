public struct Rectangle(int x, int y, int width, int height)
{
	public static readonly Rectangle Empty;

	private int x = x;

	private int y = y;

	private int width = width;

	private int height = height;

	public int X
	{
		get
		{
			return x;
		}
		set
		{
			x = value;
		}
	}

	public int Y
	{
		get
		{
			return y;
		}
		set
		{
			y = value;
		}
	}

	public int Width
	{
		get
		{
			return width;
		}
		set
		{
			width = value;
		}
	}

	public int Height
	{
		get
		{
			return height;
		}
		set
		{
			height = value;
		}
	}

	public int Left => X;

	public int Top => Y;

	public int Right => X + Width;

	public int Bottom => Y + Height;

	public static Rectangle FromLTRB(int left, int top, int right, int bottom)
	{
		return new Rectangle(left, top, right - left, bottom - top);
	}
}
