using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;
using cakeslice;

public class DockRouteCursorMode : CursorMode
{
	public enum Error
	{
		None,
		DockNotValid
	}

	private class PathCache
	{
		public List<Vector3> path = new List<Vector3>();

		public Vector3 start;

		public Vector3 end;

		public void Reset()
		{
			start = (end = Vector3.zero);
			path.Clear();
		}
	}

	public struct Cylinder
	{
		public Vector3 pos;

		public Vector3 axis;

		public float radius;
	}

	public class Route
	{
		public List<Vector3> cachedPath = new List<Vector3>();

		public List<Cylinder> cylinders = new List<Cylinder>();

		public Vector3 start;

		public Vector3 end;
	}

	public delegate bool dockValidationDelegate(Building b);

	public Error currError;

	private Vector3 endPointScale = new Vector3(0.7f, 0.12f, 0.7f);

	private List<Ship.LogisticsOrder> orders;

	private FloodFillCrawler floodFill = new FloodFillCrawler();

	private PathCache[] pathCache = new PathCache[100];

	private int numPathsCached;

	public bool isCart;

	private int specialInsertIdx = -1;

	private int selectedEndpointIdx = -1;

	private Vector3 nodeStart;

	private List<Route> routes = new List<Route>();

	private float routeWidth = 0.125f;

	private float routeSpacing = 0.25f;

	private float routeHeight = 0.025f;

	private int renderCount;

	public Color[] routeColors = new Color[4]
	{
		Color.cyan,
		Color.yellow,
		new Color(1f, 0.5f, 0f),
		new Color(0.5f, 1f, 0.5f)
	};

	public Mesh straightMesh;

	public Mesh cornerMesh;

	public Mesh arrowMesh;

	public Mesh crossMesh;

	public Material pathMat;

	public Material crossMat;

	private int highlightedEndpointIdx = -1;

	private int highlightOrderIdx = -1;

	private int endPointCount;

	private MaterialPropertyBlock endPointProps = new MaterialPropertyBlock();

	private Vector4[] endPointColors = new Vector4[1023];

	private Matrix4x4[] endPointMatrices = new Matrix4x4[1023];

	private Cylinder[] endPointCylinders = new Cylinder[1023];

	private Outline[] endpointOutlines = new Outline[1023];

	private float buildingExpand = 1f;

	private int arrowCount;

	private MaterialPropertyBlock arrowProps = new MaterialPropertyBlock();

	private Vector4[] arrowColors = new Vector4[1023];

	private Matrix4x4[] arrowMatrices = new Matrix4x4[1023];

	private MaterialPropertyBlock props = new MaterialPropertyBlock();

	private Matrix4x4[] matrices = new Matrix4x4[1023];

	private Matrix4x4[] cornerMatrices = new Matrix4x4[1023];

	private Vector4[] colors = new Vector4[1023];

	private bool movingNode;

	private float totalTime;

	private ArrayExt<Vector3> path = new ArrayExt<Vector3>(32);

	private int newArrowCount;

	private Matrix4x4 hoverPointMatrix;

	private bool hoverBool;

	private Matrix4x4 insertStraightMatrix;

	private bool insertStraightBool;

	private Matrix4x4 insertCornerMatrix;

	private bool insertCornerBool;

	private Matrix4x4 crossMatrix;

	private bool crossBool;

	public bool InvalidInsertionPoint;

	public string InvalidInsertionPointMessage = "";

	public dockValidationDelegate ValidForDocking;

	public object lastObject = new object();

	public float lastSoundTickTime;

	private bool uiDirty;

	public bool MovingNode => movingNode;

	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		if (Cam.inst.desiredDist < 20f)
		{
			Cam.inst.desiredDist = 20f;
		}
		if (Cam.inst.desiredPhi < 55f)
		{
			Cam.inst.desiredPhi = 55f;
		}
		base.Init();
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		if (highlightedEndpointIdx == -1 && highlightOrderIdx == -1 && selectedEndpointIdx == -1 && specialInsertIdx == -1)
		{
			return true;
		}
		return false;
	}

	private void ClearRoutes()
	{
		routes.Clear();
		renderCount = 0;
	}

	private bool GetBlocksPath(PathCell cell)
	{
		if (isCart)
		{
			return PathCell.GetBlocksFootPathForTransportCart(cell, 0);
		}
		return PathCell.GetBlocksWaterPath(cell, 0);
	}

	public void SetCurrOrders(List<Ship.LogisticsOrder> shipOrders)
	{
		endPointCount = 0;
		orders = shipOrders;
		CleanUpBlockedPositions();
		int num = 0;
		for (int i = 0; i < orders.Count; i++)
		{
			endPointColors[i] = routeColors[num % routeColors.Length];
			if (orders[i].endType == Ship.LogisticsOrderType.Position)
			{
				endPointMatrices[i] = Matrix4x4.TRS(orders[i].GetEnd(), Quaternion.identity, endPointScale);
				endPointCylinders[i].pos = orders[i].GetEnd();
				endPointCylinders[i].axis = new Vector3(0f, endPointScale.y, 0f);
				endPointCylinders[i].radius = endPointScale.x;
				if (i == 0)
				{
					num++;
				}
			}
			else
			{
				int num2 = 0;
				for (int num3 = i - 1; num3 >= 0; num3--)
				{
					if (orders[i].GetBuilding() == orders[num3].GetBuilding() && orders[num3].endType == Ship.LogisticsOrderType.Building)
					{
						num2++;
					}
				}
				endPointMatrices[i] = MtxForBuilding(orders[i].GetBuilding(), num2, ref endPointCylinders[i]);
				num++;
			}
			if (endpointOutlines[i] == null)
			{
				endpointOutlines[i] = new Outline(cornerMesh);
			}
			endpointOutlines[i].Disable();
			endpointOutlines[i].meshMtx = endPointMatrices[i];
			endPointCount++;
		}
		BuildPaths(testCache: false);
	}

	private void CleanUpBlockedPositions()
	{
		for (int i = 0; i < orders.Count; i++)
		{
			if (orders[i].endType != Ship.LogisticsOrderType.Position)
			{
				continue;
			}
			Vector3 end = orders[i].GetEnd();
			PathCell pathCell = World.inst.GetPathCell(end);
			if (!GetBlocksPath(pathCell))
			{
				continue;
			}
			floodFill.Reset();
			floodFill.Tick(end, delegate(Cell c, ref List<Cell> openSet)
			{
				if (!GetBlocksPath(World.inst.GetPathCell(c)))
				{
					end = c.Center2D;
					return false;
				}
				floodFill.AddAllCardinalToOpenSet(c);
				return true;
			});
			orders[i].SetEnd(end);
		}
	}

	private int FindCachedPath(Vector3 start, Vector3 end)
	{
		float num = 0.0001f;
		for (int i = 0; i < numPathsCached; i++)
		{
			if (Mathff.DistSqrdXZ(pathCache[i].start, start) < num && Mathff.DistSqrdXZ(pathCache[i].end, end) < num)
			{
				return i;
			}
		}
		return -1;
	}

	private void BuildPaths(bool testCache)
	{
		if (pathCache[0] == null)
		{
			for (int i = 0; i < pathCache.Length; i++)
			{
				pathCache[i] = new PathCache();
			}
		}
		numPathsCached = 0;
		for (int j = 0; j < routes.Count; j++)
		{
			pathCache[j].Reset();
			pathCache[j].end = routes[j].end;
			pathCache[j].start = routes[j].start;
			for (int k = 0; k < routes[j].cachedPath.Count; k++)
			{
				pathCache[j].path.Add(routes[j].cachedPath[k]);
			}
			numPathsCached++;
		}
		routes.Clear();
		renderCount = 0;
		arrowCount = 0;
		int num = 0;
		for (int l = 1; l < orders.Count; l++)
		{
			Vector3 end = orders[l - 1].GetEnd();
			Vector3 end2 = orders[l].GetEnd();
			int num2 = FindCachedPath(end, end2);
			if (num2 == -1)
			{
				if (isCart)
				{
					World.inst.pather.FindPath(end, startUseUpperGrid: false, end2, endUseUpperGrid: false, ref path, PathCell.NoBlock, PathCell.GetBlocksFootPathForTransportCart, PathCell.GetTransportCartFootPathCost, 0, doDiagonal: false, doTrimming: true, allowUpperGrid: false);
				}
				else
				{
					World.inst.pather.FindPath(end, startUseUpperGrid: false, end2, endUseUpperGrid: false, ref path, PathCell.NoBlock, PathCell.GetBlocksWaterPath, PathCell.GetBoatPathCost, 0, doDiagonal: false, doTrimming: true, allowUpperGrid: false);
				}
				path.Insert(0, end);
				path.Insert(0, end);
				num++;
			}
			else
			{
				path.Clear();
				for (int m = 0; m < pathCache[num2].path.Count; m++)
				{
					path.Add(pathCache[num2].path[m]);
				}
			}
			Route route = new Route();
			route.end = end2;
			route.start = end;
			for (int n = 0; n < path.Count; n++)
			{
				route.cachedPath.Add(path.data[n]);
			}
			int maxOffset = 0;
			int num3 = FindOffsetForSegment(path.data[1], path.data[2]);
			Vector3 vector = path.data[2] - path.data[1];
			Vector3 vector2 = new Vector3(0f - vector.z, 0f, vector.x).normalized * num3 * routeSpacing;
			Vector3 outPrevB = path.data[1] + vector2;
			for (int num4 = 1; num4 < path.Count - 2; num4++)
			{
				Cylinder item = default;
				SetInstanceForSegment(path.data[num4], path.data[num4 + 1], outPrevB, path.data[num4 + 1], path.data[num4 + 2], endPointColors[l], renderCount++, ref maxOffset, ref item.pos, ref item.axis, out outPrevB);
				route.cylinders.Add(item);
			}
			routes.Add(route);
		}
	}

	public override void HandlePrimaryDown()
	{
		if (movingNode)
		{
			movingNode = false;
			return;
		}
		SelectEndpoint(-1);
		Ray ray = PointingSystem.GetRay();
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		if (highlightedEndpointIdx != -1)
		{
			SelectEndpoint(highlightedEndpointIdx);
			nodeStart = orders[selectedEndpointIdx].GetEnd();
			movingNode = true;
			SfxSystem.inst.PlayFromBank("UIPathCreate", point);
			lastSoundTickTime = Time.time;
		}
		else if (highlightOrderIdx != -1)
		{
			Ship.LogisticsOrder logisticsOrder = new Ship.LogisticsOrder();
			logisticsOrder.SetEnd(point);
			orders.Insert(highlightOrderIdx + 1, logisticsOrder);
			SelectEndpoint(highlightOrderIdx + 1);
			nodeStart = orders[selectedEndpointIdx].GetEnd();
			movingNode = true;
			SfxSystem.inst.PlayFromBank("UIPathCreate", point);
			lastSoundTickTime = Time.time;
			SetCurrOrders(orders);
		}
		else if (specialInsertIdx != -1)
		{
			int newIdx = 0;
			Ship.LogisticsOrder logisticsOrder2 = new Ship.LogisticsOrder();
			logisticsOrder2.SetEnd(point);
			if (specialInsertIdx == 0)
			{
				orders.Insert(0, logisticsOrder2);
			}
			else
			{
				orders.Add(logisticsOrder2);
				newIdx = orders.Count - 1;
			}
			SetCurrOrders(orders);
			SelectEndpoint(newIdx);
			nodeStart = orders[selectedEndpointIdx].GetEnd();
			movingNode = true;
			SfxSystem.inst.PlayFromBank("UIPathCreate", point);
			lastSoundTickTime = Time.time;
			specialInsertIdx = -1;
		}
		base.HandlePrimaryDown();
	}

	public bool SelectingEndpoint()
	{
		return selectedEndpointIdx != -1;
	}

	public void DeleteSelectedEndpoint()
	{
		if (orders.Count > 2)
		{
			orders.RemoveAt(selectedEndpointIdx);
			SetCurrOrders(orders);
			SelectEndpoint(-1);
		}
	}

	public void DeleteSelectedEndpointIfTooClose()
	{
		if (selectedEndpointIdx == -1)
		{
			return;
		}
		for (int i = 0; i < orders.Count; i++)
		{
			if (i != selectedEndpointIdx && Mathff.DistSqrdXZ(orders[i].GetEnd(), orders[selectedEndpointIdx].GetEnd()) < 0.01f && Mathf.Abs(selectedEndpointIdx - i) == 1)
			{
				DeleteSelectedEndpoint();
				break;
			}
		}
		uiDirty = true;
	}

	public override void HandlePrimaryUp()
	{
		if (movingNode)
		{
			DeleteSelectedEndpointIfTooClose();
		}
		base.HandlePrimaryUp();
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		movingNode = false;
		DeleteSelectedEndpointIfTooClose();
		path.Clear();
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	private int FindOffsetForSegment(Vector3 a, Vector3 b)
	{
		if (Mathff.DistSqrdXZ(a, b) < 0.0001f)
		{
			return 0;
		}
		int num = 0;
		for (int i = 0; i < routes.Count; i++)
		{
			for (int j = 0; j < routes[i].cachedPath.Count - 1; j++)
			{
				Vector3 vector = routes[i].cachedPath[j];
				Vector3 vector2 = routes[i].cachedPath[j + 1];
				if (Mathff.DistSqrdXZ(a, vector2) < 0.001f && Vector3.Dot((b - a).normalized, (vector2 - vector).normalized) <= -0.9f)
				{
					num++;
					break;
				}
			}
		}
		return num;
	}

	private Matrix4x4 SetInstanceForSegment(Vector3 a, Vector3 b, Vector3 prevB, Vector3 nextA, Vector3 nextB, Vector4 color, int idx, ref int maxOffset, ref Vector3 cylinderPos, ref Vector3 cylinderAxis, out Vector3 outPrevB)
	{
		int a2 = FindOffsetForSegment(a, b);
		int a3 = FindOffsetForSegment(nextA, nextB);
		int num = Mathff.Max(a2, Mathff.Max(a3, maxOffset));
		a3 = (a2 = (maxOffset = num));
		Vector3 vector = nextB - nextA;
		Vector3 vector2 = new Vector3(0f - vector.z, 0f, vector.x).normalized * a3 * routeSpacing;
		Vector3 vector3 = nextA + vector2;
		Vector3 vector4 = nextB + vector2;
		Vector3 vector5 = vector4 - vector3;
		Vector3 vector6 = b - a;
		Vector3 vector7 = new Vector3(0f - vector6.z, 0f, vector6.x).normalized * a2 * routeSpacing;
		Vector3 vector8 = a + vector7;
		Vector3 vector9 = b + vector7;
		Vector3 vector10 = vector9 - vector8;
		Vector3 start = vector8;
		Vector3 vector11 = vector9;
		if (idx == 0)
		{
			Debug.DrawLine(vector9, vector8 - vector10 * 10f, Color.yellow);
			Debug.DrawLine(vector8, vector9 + vector10 * 10f, Color.red);
			Debug.DrawLine(vector4, vector3 - vector5, Color.red);
			Debug.DrawLine(start, vector11, Color.white);
		}
		float i_x = 0f;
		float i_y = 0f;
		start = prevB;
		if (1 == Mathff.LineSegmentIntersection2D(vector8.x, vector8.z, vector9.x + vector10.x * 10f, vector9.z + vector10.z * 10f, vector4.x, vector4.z, vector3.x - vector5.x * 10f, vector3.z - vector5.z * 10f, ref i_x, ref i_y))
		{
			vector11 = new Vector3(i_x, 0f, i_y);
		}
		Vector3 vector12 = vector11 - start;
		Vector3 vector13 = start + vector12 * 0.5f;
		outPrevB = vector11;
		vector13.y += 0.05f;
		vector11.y += 0.05f;
		Quaternion quaternion = Quaternion.LookRotation(vector12);
		Vector3 vector14 = new Vector3(routeWidth, routeHeight, vector12.magnitude);
		Mathff.SetTRS(ref matrices[idx], vector13, quaternion, vector14);
		Mathff.SetTRS(ref cornerMatrices[idx], vector11, Quaternion.identity, new Vector3(routeWidth, routeHeight * 0.5f, routeWidth));
		float magnitude = vector12.magnitude;
		for (float num2 = 0.5f; num2 < magnitude - 0.5f; num2 += 2f)
		{
			Vector3 pos = Vector3.Lerp(start, vector11, num2 / magnitude);
			arrowColors[arrowCount] = color * 0.75f;
			arrowMatrices[arrowCount++] = Matrix4x4.TRS(pos, quaternion, new Vector3(1.5f, 0.85f, 1.5f));
		}
		cylinderPos = vector13;
		cylinderAxis = vector12 * 0.5f;
		colors[idx] = color;
		return Matrix4x4.TRS(vector13, quaternion, vector14);
	}

	private Matrix4x4 MtxForBuilding(Building b, int overlapped, ref Cylinder c)
	{
		Vector3 vector = b.Center();
		vector = new Vector3(vector.x, -0.05f, vector.z);
		float num = (float)overlapped * 0.5f;
		Vector3 vector2 = new Vector3(b.size.x + buildingExpand, endPointScale.y, b.size.x + buildingExpand);
		Vector3 pos = vector - new Vector3(0f, (float)overlapped * 0.05f, 0f);
		Vector3 s = vector2 + new Vector3(num, 0f, num);
		c.axis = new Vector3(0f, s.y, 0f);
		c.pos = pos;
		c.radius = s.x * 0.5f;
		return Matrix4x4.TRS(pos, Quaternion.identity, s);
	}

	public override void Tick(float dt)
	{
		totalTime += dt;
		int count = renderCount;
		currError = Error.None;
		Ray ray = PointingSystem.GetRay();
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		Cell cellDataClamped = World.inst.GetCellDataClamped(point);
		hoverBool = false;
		insertCornerBool = false;
		insertStraightBool = false;
		crossBool = false;
		for (int i = 0; i < orders.Count; i++)
		{
			if (orders[i].endType == Ship.LogisticsOrderType.Position)
			{
				float num = 1f + (Mathf.Sin(totalTime * 10f) + 0.5f) * 0.1f;
				if (selectedEndpointIdx != -1)
				{
					num = 1f;
				}
				endPointMatrices[i] = Matrix4x4.TRS(orders[i].GetEnd(), Quaternion.identity, endPointScale * num);
				endPointCylinders[i].pos = orders[i].GetEnd();
				endPointCylinders[i].axis = new Vector3(0f, endPointScale.y, 0f);
				endPointCylinders[i].radius = endPointScale.x;
			}
		}
		UpdateEndpointHighlightTest(ray);
		UpdateRouteHighlightTest(ray, point);
		UpdateSpecialEndpointInsertion(point, cellDataClamped);
		UpdateSelectedEndpoint(point, cellDataClamped);
		props.SetVectorArray("_Color", colors);
		Graphics.DrawMeshInstanced(straightMesh, 0, pathMat, matrices, count, props, ShadowCastingMode.Off);
		Graphics.DrawMeshInstanced(cornerMesh, 0, pathMat, cornerMatrices, count, props, ShadowCastingMode.Off);
		endPointProps.SetVectorArray("_Color", endPointColors);
		Graphics.DrawMeshInstanced(cornerMesh, 0, pathMat, endPointMatrices, endPointCount, endPointProps, ShadowCastingMode.Off);
		newArrowCount = arrowCount;
		if (orders.Count > 2)
		{
			Vector3 end = orders[0].GetEnd();
			Vector3 end2 = orders[orders.Count - 1].GetEnd();
			Vector3 forward = end - end2;
			if (forward.sqrMagnitude > 0f)
			{
				Quaternion q = Quaternion.LookRotation(forward);
				float magnitude = forward.magnitude;
				for (int j = 0; (float)j < magnitude; j += 3)
				{
					arrowColors[newArrowCount] = endPointColors[endPointCount - 1];
					arrowMatrices[newArrowCount++] = Matrix4x4.TRS(Vector3.Lerp(end2, end, (float)j / magnitude), q, new Vector3(2f, 0.85f, 2f));
				}
			}
		}
		arrowProps.SetVectorArray("_Color", arrowColors);
		Graphics.DrawMeshInstanced(arrowMesh, 0, pathMat, arrowMatrices, newArrowCount, arrowProps, ShadowCastingMode.Off);
		base.Tick(dt);
	}

	public void DrawWithCommandBufer(CommandBuffer commandBuffer, Material mat, int pass)
	{
		int count = renderCount;
		commandBuffer.DrawMeshInstanced(straightMesh, 0, mat, pass, matrices, count);
		commandBuffer.DrawMeshInstanced(cornerMesh, 0, mat, pass, cornerMatrices, count);
		commandBuffer.DrawMeshInstanced(cornerMesh, 0, mat, pass, endPointMatrices, endPointCount);
		commandBuffer.DrawMeshInstanced(arrowMesh, 0, mat, pass, arrowMatrices, newArrowCount);
		if (hoverBool)
		{
			commandBuffer.DrawMesh(cornerMesh, hoverPointMatrix, mat, 0, pass);
		}
		if (insertCornerBool)
		{
			commandBuffer.DrawMesh(cornerMesh, insertCornerMatrix, mat, 0, pass);
		}
		if (insertStraightBool)
		{
			commandBuffer.DrawMesh(straightMesh, insertStraightMatrix, mat, 0, pass);
		}
		if (crossBool)
		{
			commandBuffer.DrawMesh(crossMesh, crossMatrix, mat, 0, pass);
		}
	}

	private void UpdateEndpointHighlightTest(Ray ray)
	{
		if (highlightedEndpointIdx != -1 && selectedEndpointIdx != highlightedEndpointIdx)
		{
			endpointOutlines[highlightedEndpointIdx].Disable();
		}
		highlightedEndpointIdx = -1;
		float T = 0f;
		_ = Vector3.zero;
		Vector3 outPos = Vector3.zero;
		for (int i = 0; i < orders.Count; i++)
		{
			if (Mathff.RayCylinderIntersect(ray.origin, ray.direction, endPointCylinders[i].pos - endPointCylinders[i].axis, endPointCylinders[i].pos + endPointCylinders[i].axis, endPointCylinders[i].radius, ref T, ref outPos))
			{
				endpointOutlines[i].Enable();
				highlightedEndpointIdx = i;
				break;
			}
			if (selectedEndpointIdx == i)
			{
				endpointOutlines[i].Enable();
			}
		}
	}

	private void UpdateRouteHighlightTest(Ray ray, Vector3 mousePos)
	{
		if (highlightedEndpointIdx != -1)
		{
			return;
		}
		_ = Vector3.zero;
		Vector3 outPos = Vector3.zero;
		float T = 0f;
		highlightOrderIdx = -1;
		for (int i = 0; i < routes.Count; i++)
		{
			for (int j = 0; j < routes[i].cylinders.Count; j++)
			{
				if (Mathff.RayCylinderIntersect(ray.origin, ray.direction, routes[i].cylinders[j].pos - routes[i].cylinders[j].axis, routes[i].cylinders[j].pos + routes[i].cylinders[j].axis, routeWidth * 1.5f, ref T, ref outPos))
				{
					highlightOrderIdx = i;
					break;
				}
			}
		}
		if (highlightOrderIdx != -1)
		{
			hoverPointMatrix = Matrix4x4.TRS(mousePos, Quaternion.identity, endPointScale * (1f + (Mathf.Sin(totalTime * 20f) + 0.5f) * 0.5f));
			hoverBool = true;
			Graphics.DrawMesh(cornerMesh, hoverPointMatrix, pathMat, 0);
		}
	}

	public void DeleteHighlightEndPoint(ref List<Ship.LogisticsOrder> orders)
	{
		if (orders.Count > 2)
		{
			if (selectedEndpointIdx != -1)
			{
				DeleteSelectedEndpoint();
			}
			else if (highlightedEndpointIdx != -1)
			{
				endpointOutlines[highlightedEndpointIdx].Disable();
				orders.RemoveAt(highlightedEndpointIdx);
				SetCurrOrders(orders);
				highlightedEndpointIdx = -1;
			}
		}
	}

	private void UpdateSpecialEndpointInsertion(Vector3 mousePos, Cell cell)
	{
		InvalidInsertionPoint = false;
		if (highlightedEndpointIdx != -1 || highlightOrderIdx != -1 || movingNode)
		{
			return;
		}
		specialInsertIdx = -1;
		Vector3 vector = Vector3.zero;
		Ship.LogisticsOrder logisticsOrder = orders[0];
		if (logisticsOrder.endType == Ship.LogisticsOrderType.Building)
		{
			Building building = logisticsOrder.GetBuilding();
			float num = Mathff.DistXZ(mousePos, building.Center());
			if (num > (building.size.x + buildingExpand) / 2f && num < (building.size.x + buildingExpand) / 2f + 3.5f)
			{
				specialInsertIdx = 0;
				vector = building.Center();
			}
		}
		Ship.LogisticsOrder logisticsOrder2 = orders[orders.Count - 1];
		if (logisticsOrder2.endType == Ship.LogisticsOrderType.Building)
		{
			Building building2 = logisticsOrder2.GetBuilding();
			float num2 = Mathff.DistXZ(mousePos, building2.Center());
			if (num2 > (building2.size.x + buildingExpand) / 2f && num2 < (building2.size.x + buildingExpand) / 2f + 3.5f)
			{
				specialInsertIdx = 1;
				vector = building2.Center();
			}
		}
		if (specialInsertIdx == -1)
		{
			return;
		}
		InvalidInsertionPointMessage = "";
		Building building3 = null;
		if (isCart && cell.Type == TerrainType.Water)
		{
			float num3 = float.MaxValue;
			int num4 = Mathff.Clamp(cell.x, 0, World.inst.GridWidth - 1);
			int num5 = Mathff.Clamp(cell.z, 0, World.inst.GridHeight - 1);
			int num6 = Mathff.Clamp(cell.x, 0, World.inst.GridWidth - 1);
			int num7 = Mathff.Clamp(cell.z, 0, World.inst.GridHeight - 1);
			for (int i = num5; i <= num7; i++)
			{
				for (int j = num4; j <= num6; j++)
				{
					Cell cellData = World.inst.GetCellData(j, i);
					if (ValidBuilding(cellData.TopStructure))
					{
						float num8 = Mathff.DistSqrdXZ(cellData.TopStructure.Center(), cell.Center2D);
						if (num8 < num3)
						{
							num3 = num8;
							building3 = cellData.TopStructure;
						}
					}
				}
			}
		}
		if (((!isCart && cell.Type != TerrainType.Water) || (isCart && cell.Type == TerrainType.Water && building3 == null)) && building3 == null)
		{
			specialInsertIdx = -1;
			InvalidInsertionPoint = true;
			InvalidInsertionPointMessage = (isCart ? ScriptLocalization.PVRLandInvalidInsertionPoint : ScriptLocalization.PVRWaterInvalidInsertionPoint);
		}
		float num9 = (isCart ? 0.15f : 0f);
		insertCornerMatrix = Matrix4x4.TRS(new Vector3(mousePos.x, mousePos.y + num9, mousePos.z), Quaternion.identity, endPointScale * (1f + (Mathf.Sin(totalTime * 10f) + 0.5f) * 0.25f));
		insertCornerBool = true;
		Graphics.DrawMesh(cornerMesh, insertCornerMatrix, InvalidInsertionPoint ? crossMat : pathMat, 0);
		Vector3 vector2 = (mousePos - vector).xz();
		Quaternion q = Quaternion.LookRotation(vector2);
		insertStraightMatrix = Matrix4x4.TRS(s: new Vector3(routeWidth, routeHeight, vector2.magnitude), pos: new Vector3(vector.x, vector.y + num9, vector.z) + vector2 * 0.5f, q: q);
		insertStraightBool = true;
		Graphics.DrawMesh(straightMesh, insertStraightMatrix, InvalidInsertionPoint ? crossMat : pathMat, 0);
	}

	public bool ValidBuilding(Building b)
	{
		if (b == null)
		{
			return false;
		}
		if (isCart)
		{
			TransportCart transportCart = ShipLogisticsUI.inst.transport as TransportCart;
			if (transportCart != null && b.LandMass() != transportCart.landmass)
			{
				return false;
			}
			if (b.CategoryName == "stockpile" || b.CategoryName == "market" || b.CategoryName == "granary" || b.uniqueNameHash == World.produceStandHash || b.uniqueNameHash == World.butcherHash || b.uniqueNameHash == World.fishMongerHash)
			{
				return true;
			}
		}
		if (b.UniqueName == "dock")
		{
			return true;
		}
		return false;
	}

	public bool ValidCell(Cell cell)
	{
		if (!isCart && cell.Type == TerrainType.Water)
		{
			return true;
		}
		if (isCart)
		{
			TransportCart transportCart = ShipLogisticsUI.inst.transport as TransportCart;
			if (cell.Type != TerrainType.None || (transportCart != null && transportCart.landmass != cell.landMassIdx))
			{
				return false;
			}
			if (cell.OccupyingStructure.Count <= 0)
			{
				return true;
			}
			if (cell.BottomStructureIsCategory(World.pathHash) || cell.BottomStructureIs(World.farmHash) || cell.BottomStructureIs(World.townsquareHash))
			{
				return true;
			}
		}
		return false;
	}

	private void UpdateSelectedEndpoint(Vector3 mousePos, Cell cell)
	{
		if (selectedEndpointIdx == -1)
		{
			return;
		}
		if (movingNode)
		{
			float num = Mathf.Clamp(Mathff.DistXZ(nodeStart, orders[selectedEndpointIdx].GetEnd()) - 7f, 0f, 20f);
			if (Cam.inst.desiredDist < num + 35f)
			{
				Cam.inst.desiredDist = num + 35f;
			}
			Building building = null;
			float num2 = float.MaxValue;
			int num3 = 2;
			if ((selectedEndpointIdx + 1 < orders.Count && orders[selectedEndpointIdx + 1].endType == Ship.LogisticsOrderType.Building) || (selectedEndpointIdx - 1 >= 0 && orders[selectedEndpointIdx - 1].endType == Ship.LogisticsOrderType.Building))
			{
				num3 = 0;
			}
			int num4 = Mathff.Clamp(cell.x - num3, 0, World.inst.GridWidth - 1);
			int num5 = Mathff.Clamp(cell.z - num3, 0, World.inst.GridHeight - 1);
			int num6 = Mathff.Clamp(cell.x + num3, 0, World.inst.GridWidth - 1);
			int num7 = Mathff.Clamp(cell.z + num3, 0, World.inst.GridHeight - 1);
			for (int i = num5; i <= num7; i++)
			{
				for (int j = num4; j <= num6; j++)
				{
					Cell cellData = World.inst.GetCellData(j, i);
					if (ValidBuilding(cellData.TopStructure))
					{
						float num8 = Mathff.DistSqrdXZ(cellData.TopStructure.Center(), cell.Center2D);
						if (num8 < num2)
						{
							num2 = num8;
							building = cellData.TopStructure;
						}
					}
				}
			}
			if ((bool)building && ValidBuilding(building))
			{
				if (ValidForDocking(building))
				{
					if (orders[selectedEndpointIdx].endType != Ship.LogisticsOrderType.Building || (orders[selectedEndpointIdx].endType == Ship.LogisticsOrderType.Building && orders[selectedEndpointIdx].GetBuilding() != building))
					{
						uiDirty = true;
					}
					orders[selectedEndpointIdx].SetEnd(building);
					Matrix4x4 matrix4x = MtxForBuilding(building, 0, ref endPointCylinders[selectedEndpointIdx]);
					endPointMatrices[selectedEndpointIdx] = matrix4x;
					endpointOutlines[selectedEndpointIdx].meshMtx = matrix4x;
					if (lastObject != building)
					{
						SfxSystem.inst.PlayFromBank("UIPathBuildingPop", building.cachedPos);
					}
					lastObject = building;
				}
				else
				{
					Vector3 forward = Cam.inst.transform.position - building.Center();
					Vector3 pos = building.Center() + new Vector3(0f, 2f, 0f) + forward.normalized * 1f;
					crossMatrix = Matrix4x4.TRS(pos, Quaternion.LookRotation(forward), Vector3.one);
					crossBool = true;
					Graphics.DrawMesh(crossMesh, crossMatrix, crossMat, 0);
					currError = Error.DockNotValid;
				}
			}
			else
			{
				if (orders[selectedEndpointIdx].endType == Ship.LogisticsOrderType.Building)
				{
					uiDirty = true;
				}
				if (ValidCell(cell))
				{
					orders[selectedEndpointIdx].SetEnd(cell.Center2D);
					Matrix4x4 matrix4x2 = Matrix4x4.TRS(mousePos, Quaternion.identity, endPointScale * 2f);
					endPointMatrices[selectedEndpointIdx] = matrix4x2;
					endpointOutlines[selectedEndpointIdx].meshMtx = matrix4x2;
					endPointCylinders[selectedEndpointIdx].pos = mousePos;
					endPointCylinders[selectedEndpointIdx].axis = new Vector3(0f, endPointScale.y, 0f);
					endPointCylinders[selectedEndpointIdx].radius = endPointScale.x * 2f;
					if (cell != lastObject && Time.time - lastSoundTickTime > 0.03f)
					{
						SfxSystem.inst.PlayFromBank("UIPathDrag", cell.Center2D);
						lastSoundTickTime = Time.time;
					}
					lastObject = cell;
				}
				if (!ShipLogisticsUI.inst.overTrash)
				{
					Vector2 vector = Mathff.WorldPosToScreen(mousePos, GameUI.inst.rectT);
					float num9 = GameUI.inst.rectT.offsetMin.x * 0.6f;
					float num10 = GameUI.inst.rectT.offsetMin.y * 0.86f;
					float num11 = GameUI.inst.rectT.offsetMax.x * 0.6f;
					float num12 = GameUI.inst.rectT.offsetMax.y * 0.86f;
					if (vector.x < num9 || vector.x > num11 || vector.y < num10 || vector.y > num12)
					{
						float num13 = 0f;
						num13 = ((!(vector.x < num9)) ? ((vector.x - num11) / (GameUI.inst.rectT.offsetMax.x - num11)) : ((vector.x - num9) / (GameUI.inst.rectT.offsetMin.x - num9)));
						float num14 = 0f;
						num14 = ((!(vector.y < num10)) ? ((vector.y - num12) / (GameUI.inst.rectT.offsetMax.y - num12)) : ((vector.y - num10) / (GameUI.inst.rectT.offsetMin.y - num10)));
						Vector3 desiredTrackingPos = Cam.inst.TrackingPos + (mousePos - Cam.inst.TrackingPos).normalized * (Mathff.Max(num13, num14) * 7f);
						Cam.inst.SetDesiredTrackingPos(desiredTrackingPos);
					}
				}
			}
			BuildPaths(testCache: true);
		}
		if ((Input.GetKeyDown(KeyCode.Delete) || Input.GetKeyDown(KeyCode.Backspace)) && orders.Count > 2)
		{
			orders.RemoveAt(selectedEndpointIdx);
			SetCurrOrders(orders);
			SelectEndpoint(-1);
			uiDirty = true;
		}
	}

	private void SelectEndpoint(int newIdx)
	{
		if (selectedEndpointIdx != -1 && selectedEndpointIdx != newIdx)
		{
			endpointOutlines[selectedEndpointIdx].color = 0;
			endpointOutlines[selectedEndpointIdx].Disable();
		}
		selectedEndpointIdx = newIdx;
		if (selectedEndpointIdx != -1)
		{
			endpointOutlines[selectedEndpointIdx].color = 1;
			endpointOutlines[selectedEndpointIdx].Enable();
		}
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		if (highlightedEndpointIdx != -1)
		{
			SelectEndpoint(highlightedEndpointIdx);
			highlightedEndpointIdx = -1;
			return true;
		}
		if (highlightOrderIdx != -1 || specialInsertIdx != -1 || selectedEndpointIdx != -1)
		{
			highlightOrderIdx = -1;
			specialInsertIdx = -1;
			selectedEndpointIdx = -1;
			highlightedEndpointIdx = -1;
			return true;
		}
		return base.DoPrimaryClick(clickedBuilding, clickedCell);
	}

	public override bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		if (highlightedEndpointIdx == -1)
		{
			return true;
		}
		return false;
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		selectedEndpointIdx = -1;
		highlightOrderIdx = -1;
		highlightedEndpointIdx = -1;
		specialInsertIdx = -1;
		for (int i = 0; i < orders.Count; i++)
		{
			endpointOutlines[i].Disable();
		}
		ClearRoutes();
		orders = null;
		movingNode = false;
		base.Shutdown();
	}

	public bool ConsumeUIDirty()
	{
		if (uiDirty)
		{
			uiDirty = false;
			return true;
		}
		return false;
	}
}
