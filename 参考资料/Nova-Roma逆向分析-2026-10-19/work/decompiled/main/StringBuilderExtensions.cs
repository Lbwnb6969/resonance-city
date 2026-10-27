using System;
using System.Text;

public static class StringBuilderExtensions
{
	private static readonly char[] ms_digits = new char[16]
	{
		'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
		'A', 'B', 'C', 'D', 'E', 'F'
	};

	private static readonly uint ms_default_decimal_places = 5u;

	private static readonly char ms_default_pad_char = '0';

	public static StringBuilder Concat(this StringBuilder string_builder, uint uint_val, uint pad_amount, char pad_char, uint base_val)
	{
		uint num = 0u;
		uint num2 = uint_val;
		do
		{
			num2 /= base_val;
			num++;
		}
		while (num2 != 0);
		string_builder.Append(pad_char, (int)Math.Max(pad_amount, num));
		int num3 = string_builder.Length;
		while (num != 0)
		{
			num3--;
			string_builder[num3] = ms_digits[uint_val % base_val];
			uint_val /= base_val;
			num--;
		}
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, uint uint_val)
	{
		string_builder.Concat(uint_val, 0u, ms_default_pad_char, 10u);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, uint uint_val, uint pad_amount)
	{
		string_builder.Concat(uint_val, pad_amount, ms_default_pad_char, 10u);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, uint uint_val, uint pad_amount, char pad_char)
	{
		string_builder.Concat(uint_val, pad_amount, pad_char, 10u);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, int int_val, uint pad_amount, char pad_char, uint base_val)
	{
		if (int_val < 0)
		{
			string_builder.Append('-');
			uint uint_val = (uint)(-1 - int_val + 1);
			string_builder.Concat(uint_val, pad_amount, pad_char, base_val);
		}
		else
		{
			string_builder.Concat((uint)int_val, pad_amount, pad_char, base_val);
		}
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, int int_val)
	{
		string_builder.Concat(int_val, 0u, ms_default_pad_char, 10u);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, int int_val, uint pad_amount)
	{
		string_builder.Concat(int_val, pad_amount, ms_default_pad_char, 10u);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, int int_val, uint pad_amount, char pad_char)
	{
		string_builder.Concat(int_val, pad_amount, pad_char, 10u);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, float float_val, uint decimal_places, uint pad_amount, char pad_char)
	{
		if (decimal_places == 0)
		{
			int int_val = ((!(float_val >= 0f)) ? ((int)(float_val - 0.5f)) : ((int)(float_val + 0.5f)));
			string_builder.Concat(int_val, pad_amount, pad_char, 10u);
		}
		else
		{
			int num = (int)float_val;
			string_builder.Concat(num, pad_amount, pad_char, 10u);
			string_builder.Append('.');
			float num2 = Math.Abs(float_val - (float)num);
			do
			{
				num2 *= 10f;
				decimal_places--;
			}
			while (decimal_places != 0);
			num2 += 0.5f;
			string_builder.Concat((uint)num2, 0u, '0', 10u);
		}
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, float float_val)
	{
		string_builder.Concat(float_val, ms_default_decimal_places, 0u, ms_default_pad_char);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, float float_val, uint decimal_places)
	{
		string_builder.Concat(float_val, decimal_places, 0u, ms_default_pad_char);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, float float_val, uint decimal_places, uint pad_amount)
	{
		string_builder.Concat(float_val, decimal_places, pad_amount, ms_default_pad_char);
		return string_builder;
	}

	public static StringBuilder Concat(this StringBuilder string_builder, StringBuilder source)
	{
		int length = string_builder.Length;
		for (int i = 0; i < source.Length && length + i < string_builder.MaxCapacity; i++)
		{
			string_builder.Append(source[i]);
		}
		return string_builder;
	}

	public static StringBuilder Clear(this StringBuilder string_builder)
	{
		for (int i = 0; i < string_builder.Length; i++)
		{
			string_builder[i] = ' ';
		}
		string_builder.Length = 0;
		return string_builder;
	}

	public static bool CompareTo(this StringBuilder string_builder, string str)
	{
		if (str == null)
		{
			return false;
		}
		bool result = true;
		if (string_builder.Length != str.Length)
		{
			result = false;
		}
		else
		{
			for (int i = 0; i < string_builder.Length; i++)
			{
				if (string_builder[i] != str[i])
				{
					result = false;
					break;
				}
			}
		}
		return result;
	}

	public static bool CompareTo(this StringBuilder string_builder, StringBuilder str)
	{
		bool result = true;
		if (string_builder.Length != str.Length)
		{
			result = false;
		}
		else
		{
			for (int i = 0; i < string_builder.Length; i++)
			{
				if (string_builder[i] != str[i])
				{
					result = false;
					break;
				}
			}
		}
		return result;
	}

	public static int IndexOf(this StringBuilder string_builder, string str)
	{
		return string_builder.IndexOf(0, str);
	}

	public static int IndexOf(this StringBuilder string_builder, char c)
	{
		return string_builder.IndexOf(0, c);
	}

	public static int IndexOf(this StringBuilder string_builder, int start, char c)
	{
		for (int i = start; i < string_builder.Length; i++)
		{
			if (string_builder[i] == c)
			{
				return i;
			}
		}
		return -1;
	}

	public static int IndexOf(this StringBuilder string_builder, int start, string str)
	{
		for (int i = start; i < string_builder.Length; i++)
		{
			bool flag = false;
			for (int j = 0; j < str.Length; j++)
			{
				if (i + j >= string_builder.Length)
				{
					flag = true;
					break;
				}
				if (string_builder[i + j] != str[j])
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				return i;
			}
		}
		return -1;
	}

	public static int GetStringHash(this StringBuilder str)
	{
		int num = 5381;
		int num2 = num;
		for (int i = 0; i < str.Length - 1; i += 2)
		{
			int num3 = str[0];
			num = ((num << 5) + num) ^ num3;
			num3 = str[i + 1];
			if (num3 == 0)
			{
				break;
			}
			num2 = ((num2 << 5) + num2) ^ num3;
		}
		return num + num2 * 1566083941;
	}

	public static bool Contains(this StringBuilder string_builder, string str)
	{
		return string_builder.IndexOf(str) != -1;
	}
}
