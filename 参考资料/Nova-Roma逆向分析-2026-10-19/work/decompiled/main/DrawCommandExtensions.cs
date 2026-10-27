using Drawing;
using Unity.Collections;
using UnityEngine;

public static class DrawCommandExtensions
{
	public static void DrawNumber(this CommandBuilder cb, int number, Vector3 position, Color color)
	{
		position += Vector3.up * 0.5f;
		float num = 0.3f;
		FixedString32Bytes fixedString32Bytes = $"{number}";
		position -= Vector3.right * ((float)(fixedString32Bytes.Length - 1) * num * 0.5f);
		for (int i = 0; i < fixedString32Bytes.Length; i++)
		{
			Vector3 vector = position + Vector3.right * ((float)i * num * 1.1f);
			float num2 = num * 0.5f;
			float num3 = num * 0.5f;
			Vector3 vector2 = vector + new Vector3(0f - num2, num3, 0f);
			Vector3 vector3 = vector + new Vector3(num2, num3, 0f);
			Vector3 vector4 = vector + new Vector3(0f - num2, 0f, 0f);
			Vector3 vector5 = vector + new Vector3(num2, 0f, 0f);
			Vector3 vector6 = vector + new Vector3(0f - num2, 0f - num3, 0f);
			Vector3 vector7 = vector + new Vector3(num2, 0f - num3, 0f);
			switch ((char)fixedString32Bytes[i])
			{
			case '0':
				cb.Line(vector2, vector3, color);
				cb.Line(vector3, vector7, color);
				cb.Line(vector7, vector6, color);
				cb.Line(vector6, vector2, color);
				break;
			case '1':
				cb.Line(vector3, vector5, color);
				cb.Line(vector5, vector7, color);
				break;
			case '2':
				cb.Line(vector2, vector3, color);
				cb.Line(vector3, vector5, color);
				cb.Line(vector4, vector5, color);
				cb.Line(vector6, vector4, color);
				cb.Line(vector6, vector7, color);
				break;
			case '3':
				cb.Line(vector2, vector3, color);
				cb.Line(vector3, vector5, color);
				cb.Line(vector4, vector5, color);
				cb.Line(vector5, vector7, color);
				cb.Line(vector6, vector7, color);
				break;
			case '4':
				cb.Line(vector2, vector4, color);
				cb.Line(vector4, vector5, color);
				cb.Line(vector3, vector5, color);
				cb.Line(vector5, vector7, color);
				break;
			case '5':
				cb.Line(vector2, vector3, color);
				cb.Line(vector2, vector4, color);
				cb.Line(vector4, vector5, color);
				cb.Line(vector5, vector7, color);
				cb.Line(vector6, vector7, color);
				break;
			case '6':
				cb.Line(vector2, vector3, color);
				cb.Line(vector2, vector4, color);
				cb.Line(vector4, vector5, color);
				cb.Line(vector6, vector4, color);
				cb.Line(vector5, vector7, color);
				cb.Line(vector6, vector7, color);
				break;
			case '7':
				cb.Line(vector2, vector3, color);
				cb.Line(vector3, vector5, color);
				cb.Line(vector5, vector7, color);
				break;
			case '8':
				cb.Line(vector2, vector3, color);
				cb.Line(vector3, vector5, color);
				cb.Line(vector5, vector7, color);
				cb.Line(vector7, vector6, color);
				cb.Line(vector6, vector4, color);
				cb.Line(vector4, vector2, color);
				cb.Line(vector4, vector5, color);
				break;
			case '9':
				cb.Line(vector2, vector3, color);
				cb.Line(vector2, vector4, color);
				cb.Line(vector4, vector5, color);
				cb.Line(vector3, vector5, color);
				cb.Line(vector5, vector7, color);
				cb.Line(vector6, vector7, color);
				break;
			}
		}
	}
}
