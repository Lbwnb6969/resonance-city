local TTC = ...

--[[---------------------------- BUILDING FUNCTION ----------------------------]]--

local TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME = {
	TypeName = "TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME",
	ParentType = "TAXATION_FUNCTION_BRACKET",
	Properties = {
		{ Name = "MaximumAmount", Type = "integer", Default = 50 },
		{ Name = "AmountPerSecond", Type = "float", Default = 0.2 }
	}
}

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:init(_instTaxationFunction)
	TTC:log("Taxation Function Over Time init")

	local taxationManager = _instTaxationFunction:getTaxationManager()
	self:initTaxOffices(taxationManager, _instTaxationFunction);

	local taxOfficeComponentManager = taxationManager:getLevel():getComponentManager("COMP_WORKPLACE_TAX_OFFICE")
	event.register(self, taxOfficeComponentManager.ON_COMPONENT_INITIALIZED, function(_component)
		self:addTaxableComponent(_component, taxationManager, _instTaxationFunction)
	end)

	event.register(self, taxOfficeComponentManager.ON_COMPONENT_DESTROYED, function(_component)
		self:removeTaxableComponent(_component, taxationManager, _instTaxationFunction)
	end)
end

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:finalize(instTaxationFunction)
	TTC:log("Taxation Function Over Time finalize")

	--local taxOfficeComponentManager = taxationManager:getLevel():getComponentManager("COMP_WORKPLACE_TAX_OFFICE")
	--event.unregister(self, taxOfficeComponentManager.ON_COMPONENT_INITIALIZED)
	--event.unregister(self, taxOfficeComponentManager.ON_COMPONENT_DESTROYED)
	-- Calling `event.clear(self)` since we register on all tax offices so it makes it harder to call `unregister` on all of them
	event.clear(self);
end

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:getMaximumAmountToCollect(taxCollectable)
	TTC:log("Taxation Function Over Time getMaximumAmountToCollect")

	return self.MaximumAmount;
end

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:collect(_taxCollectable)
	local taxOffice = _taxCollectable:getOwner():findFirstParentWithComponent("COMP_WORKPLACE_TAX_OFFICE")
	if (taxOffice ~= nil) then
		local taxationBracketList = self:getDataTaxationBracketList()
		local taxPercentage = taxationBracketList[_taxCollectable:getInstTaxationFunction():getBracket()]:getTaxPercentage()
		local taxAmount = _taxCollectable:getLevel():getDeltaTime() * self.AmountPerSecond * taxPercentage

		local myData = foundation.createData(
			{
				DataType = "INST_TAXATION_COLLECT_INFO_BUILDING", 
			}
		)

		myData:addBuildable(taxOffice:getOwner():findFirstObjectWithComponentUp("COMP_BUILDING"))
		myData:cumulateTaxAmount("GOLD_COINS", taxAmount)

		return myData
	end

	return nil
end

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:initTaxOffices(_taxationManager, _instTaxationFunction)
	TTC:log("Taxation Function initTaxOffices")
	local taxOfficeComponentManager = _taxationManager:getLevel():getComponentManager("COMP_WORKPLACE_TAX_OFFICE")
	taxOfficeComponentManager:getAllComponent("COMP_WORKPLACE_TAX_OFFICE"):forEach(
		function(_taxOffice)
			self:addTaxableComponent(_taxOffice, _taxationManager, _instTaxationFunction)
		end)
end

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:addTaxableComponent(_taxOffice, _taxationManager, _instTaxationFunction)
	TTC:log("Taxation Function Over Time addTaxableComponent")

	_taxationManager:addTaxableComponent(_taxOffice:getOwner(), self)
end

function TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME:removeTaxableComponent(_taxOffice, _taxationManager, _instTaxationFunction)
	TTC:log("Taxation Function Over Time removeTaxableComponent")

	_taxationManager:removeTaxableComponent(_taxOffice:getOwner(), self)
end

TTC:registerClass(TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME)

TTC:registerAsset({
	DataType = "TAXATION_FUNCTION_TAX_OFFICE_OVER_TIME",
	Id = "TTC_TAXATION_FUNCTION_OVER_TIME",
	NameKey = "TTC_TAXATION_FUNCTION_OVER_TIME_NAME",
	DescriptionKey = "TTC_TAXATION_FUNCTION_OVER_TIME_DESCRIPTION",
	CategoryKey = "TTC_TAXATION_FUNCTION_CATEGORY",
	TaxedNameKey = "TTC_BUILDINGS_TAXES_TAX_OFFICE_OVER_TIME",
	--Texture = ,
	TaxationBracketList = {
		{
			DataType = "TAXATION_BRACKET",
			TaxPercentage = 1.0
		}
	}
})

TTC:overrideAsset({
	Id = "DEFAULT_TAXATION_SETTINGS",
	AssetTaxationFunctionList = {
		Action = "APPEND",
		"TTC_TAXATION_FUNCTION_OVER_TIME"
	}
})
