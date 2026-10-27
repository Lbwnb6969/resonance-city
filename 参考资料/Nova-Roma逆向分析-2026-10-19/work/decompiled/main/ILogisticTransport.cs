using System.Collections.Generic;
using Assets.Code;

public interface ILogisticTransport
{
	List<Ship.LogisticsOrder> GetOrders();

	string GetErrorText();

	bool isErrorVisible();

	bool isPaused();

	void SetPaused(bool paused);

	Ship.Behavior GetLogisiticBehavior();

	void SetLogisiticBehavior(Ship.Behavior behavior);

	void SetMaxYear(int maxYear);

	int GetMaxCycle();

	string GetTransportName();

	void SetTransportName(string name);

	bool ValidForDocking(Building b);

	string GetDescription();

	void SetOutlineImmediate(int i);

	ResourceAmount GetHold();

	int GetMaxHold();

	void ValidateOrders();

	bool ValidForOrder(Cell c);

	int TeamID();
}
