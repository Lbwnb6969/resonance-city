local TTC = ...

--[[---------------------------- BUILDING FUNCTION ----------------------------]]--

local TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR = {
	TypeName = "TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR",
	ParentType = "TAXATION_FUNCTION_BRACKET",
	Properties = {
		{ Name = "MaximumAmount", Type = "integer", Default = 50 }
	}
}

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:init(_instTaxationFunction)
	TTC:log("Taxation Function init")

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

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:finalize(instTaxationFunction)
	TTC:log("Taxation Function finalize")

	--local taxOfficeComponentManager = taxationManager:getLevel():getComponentManager("COMP_WORKPLACE_TAX_OFFICE")
	--event.unregister(self, taxOfficeComponentManager.ON_COMPONENT_INITIALIZED)
	--event.unregister(self, taxOfficeComponentManager.ON_COMPONENT_DESTROYED)
	-- Calling `event.clear(self)` since we register on all tax offices so it makes it harder to call `unregister` on all of them
	event.clear(self);
end

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:getMaximumAmountToCollect(taxCollectable)
	TTC:log("Taxation Function getMaximumAmountToCollect")

	return self.MaximumAmount;
end

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:registerAmountAvailableToCollect(_taxCollectable)
	TTC:log("Taxation Function registerAmountAvailableToCollect")

	local taxOffice = _taxCollectable:getOwner():findFirstParentWithComponent("COMP_WORKPLACE_TAX_OFFICE")
	if (taxOffice ~= nil) then
		event.register(self, taxOffice.ON_TAX_DEPOSIT, function(_goldAmount)
			TTC:log("Taxation Function - Tax has been collected!")
			taxationBracketList = self:getDataTaxationBracketList()
			taxPercentage = taxationBracketList[_taxCollectable:getInstTaxationFunction():getBracket()]:getTaxPercentage()
			taxAmount = _goldAmount * taxPercentage;
			TTC:log("Taxation Function - Tax has been collected: " .. taxAmount)
			local myData = foundation.createData(
				{
					DataType = "INST_TAXATION_COLLECT_INFO_BUILDING", 
				}
			)
			myData:addBuildable(taxOffice:getOwner():findFirstObjectWithComponentUp("COMP_BUILDING"))
			myData:cumulateTaxAmount("GOLD_COINS", taxAmount)

			_taxCollectable:addCumulatedInfo(myData)
		end)
	end
end

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:initTaxOffices(_taxationManager, _instTaxationFunction)
	TTC:log("Taxation Function initTaxOffices")
	local taxOfficeComponentManager = _taxationManager:getLevel():getComponentManager("COMP_WORKPLACE_TAX_OFFICE")
	taxOfficeComponentManager:getAllComponent("COMP_WORKPLACE_TAX_OFFICE"):forEach(
		function(_taxOffice)
			self:addTaxableComponent(_taxOffice, _taxationManager, _instTaxationFunction)
		end)
end

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:addTaxableComponent(_taxOffice, _taxationManager, _instTaxationFunction)
	TTC:log("Taxation Function addTaxableComponent")

	_taxationManager:addTaxableComponent(_taxOffice:getOwner(), self)
end

function TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR:removeTaxableComponent(_taxOffice, _taxationManager, _instTaxationFunction)
	TTC:log("Taxation Function removeTaxableComponent")

	_taxationManager:removeTaxableComponent(_taxOffice:getOwner(), self)
end

TTC:registerClass(TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR)

TTC:registerAsset({
	DataType = "TAXATION_FUNCTION_TAX_THE_TAX_COLLECTOR",
	Id = "TTC_TAXATION_FUNCTION",
	NameKey = "TTC_TAXATION_FUNCTION_NAME",
	DescriptionKey = "TTC_TAXATION_FUNCTION_DESCRIPTION",
	CategoryKey = "TTC_TAXATION_FUNCTION_CATEGORY",
	TaxedNameKey = "TTC_BUILDINGS_TAXES_TAX_OFFICE",
	--Texture = ,
	TaxationBracketList = {
		{
			DataType = "TAXATION_BRACKET",
			TaxPercentage = 0.1
		}
	}
})

TTC:overrideAsset({
	Id = "DEFAULT_TAXATION_SETTINGS",
	AssetTaxationFunctionList = {
		Action = "APPEND",
		"TTC_TAXATION_FUNCTION"
	}
})
