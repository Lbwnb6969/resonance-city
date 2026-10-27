local mod = ...

mod:registerBehaviorTreeNode({
    Name = "MY_CUSTOM_NODE",
    VariableList = {
		Var1 = "BEHAVIOR_TREE_DATA_AGENT",
		Var2 = "BEHAVIOR_TREE_DATA_WAIT",
		Var3 = "BEHAVIOR_TREE_DATA_LOCATION",
		Var4 = "BEHAVIOR_TREE_DATA_RESOURCE_TRANSPORT",
		Var5 = "BEHAVIOR_TREE_DATA_LOOP"
    },
    Init = function(self, instance)
		mod:log("INIT!")
    end,
    Update = function(self, level, instance)
		mod:log("UPDATE!")
		mod:log("Spawning immigrants...")
		mod:log("Days until next immigration: " .. tostring(level:find("COMP_IMMIGRATION_MANAGER"):getDaysUntilImmigration()))
		mod:log("Is immigration enabled: " .. tostring(level:find("COMP_IMMIGRATION_MANAGER"):getIsImmigrationEnabled()))
		mod:log("Triggering default immigration")
		level:find("COMP_IMMIGRATION_MANAGER"):triggerImmigration()
		mod:log("Triggering forced immigration of 4 villagers")
		level:find("COMP_IMMIGRATION_MANAGER"):triggerImmigration(true, 4)
		
		return self:updateFunc(level, instance)
    end,
    Finish = function(self, instance)
		mod:log("FINISH!")
    end,
	updateFunc = function(self, level, instance)
		mod:log("UPDATE FUNC!")
		mod:log("Agent data: " .. tostring(self.Var1))
		mod:log(tostring(self.Var1.Agent))
		mod:log("Wait data: " .. tostring(self.Var2))
		mod:log("Location data: " .. tostring(self.Var3))
		mod:log("Resource transport data: " .. tostring(self.Var4))
		mod:log("Loop data: " .. tostring(self.Var5))
		return BEHAVIOR_TREE_NODE_RESULT.TRUE
	end,
})

mod:registerBehaviorTree({
	Id = "MY_CUSTOM_BEHAVIOR_TREE",
	VariableList = {
		{
			Name = "AgentData",
			DataType = "BEHAVIOR_TREE_DATA_AGENT",
			IsPublic = true,
			InitialValue = {} -- Optional if empty, leaves the default values (if any)
		},
		{
			Name = "DoJobTimer",
			DataType = "BEHAVIOR_TREE_DATA_WAIT",
			IsPublic = false,
			InitialValue = {
				TimeToWait = 0,
				Animation = AGENT_ANIMATION_STATE.GATHER,
				SetIdleAfterWait = false,
			}
		},
		{
			Name = "WorkplacePosition",
			DataType = "BEHAVIOR_TREE_DATA_LOCATION",
			IsPublic = false,
			InitialValue = {
				CanNavigateOnGround = true,
				CanNavigateOnWater = false,
				IsSetOrientationOnDestination = true,
			}
		},
		{
			Name = "TransportData",
			DataType = "BEHAVIOR_TREE_DATA_RESOURCE_TRANSPORT",
			IsPublic = false,
		},
		{
			Name = "WorkLoop",
			DataType = "BEHAVIOR_TREE_DATA_LOOP",
			IsPublic = true,
			InitialValue = {
				LoopCount = 10,
				Duration = 0,
				IsInfinite = false,
				IsDuration = false,
			}
		},
		{
			Name = "ResourceProducedList",
			DataType = "BEHAVIOR_TREE_DATA_RESOURCE_PRODUCTION",
			IsPublic = false,
		},
		{
			Name = "ResourceProducedTransportData",
			DataType = "BEHAVIOR_TREE_DATA_RESOURCE_TRANSPORT",
			IsPublic = false,
		},
		{
			Name = "DepotLocation",
			DataType = "BEHAVIOR_TREE_DATA_LOCATION",
			IsPublic = false,
			InitialValue = {
				CanNavigateOnGround = true,
				CanNavigateOnWater = false,
				IsSetOrientationOnDestination = false,
			},
		},
	},
	Root = {
		Name = "WorkingGlobalSequencer",
		Type = "SEQUENCER",
		Children = {
			{
				Name = "Fetch Resource If Needed",
				Type = "FETCH_RESOURCE_IF_NEEDED",
				AgentData = "AgentData",
				TransportData = "TransportData",
			},
			{
				Name = "CUSTOM_NODE_INSTANCE",
				Type = "MY_CUSTOM_NODE",
				Var1 = "AgentData",
				Var2 = "DoJobTimer",
				Var3 = "WorkplacePosition",
				Var4 = "TransportData",
				Var5 = "WorkLoop",
			},
			{
				Name = "WorkLoopRepeater",
				Type = "REPEAT",
				RepeatData = "WorkLoop",
				Child = {
					Name = "WorkLoopSequencer",
					Type = "SEQUENCER",
					Children = {
						{
							Name = "SetupWork",
							Type = "SETUP_WORK",
							AgentData = "AgentData",
							TimeToWait = "DoJobTimer",
							WorkPosition = "WorkplacePosition",
						},
						{
							Name = "GoToResource",
							Type = "GO_TO",
							AgentData = "AgentData",
							Destination = "WorkplacePosition",
							BuildingPathType = "",
							AnimationData = "",
							AnimationSpeedMultiplier = "",
						},
						{
							Name = "ProduceResource",
							Type = "PRODUCE_RESOURCE",
							AgentData = "AgentData",
							TimeToWait = "DoJobTimer",
							ResourceProducedList = "ResourceProducedList",
						},
						{
							Name = "TransportResourceRepeater",
							Type = "REPEAT_UNTIL_FAIL",
							Child = {
								Name = "TransportResourceSequencer",
								Type = "SEQUENCER",
								Children = {
									{
										Name = "SetupWorkplaceResourceTransport",
										Type = "SETUP_WORKPLACE_TRANSPORT",
										AgentData = "AgentData",
										ResourceProducedData = "ResourceProducedList",
										TransportData = "ResourceProducedTransportData",
										DepotLocationData = "DepotLocation",
									},
									{
										Name = "WorkplaceResourceTransportSucceeder",
										Type = "SUCCEEDER",
										Child = {
											Name = "WorkplaceResourceGoTo",
											Type = "GO_TO",
											AgentData = "AgentData",
											Destination = "DepotLocation",
										},
									},
									{
										Name = "DropWorkplaceResourceToDepot",
										Type = "DROP_STUFF_TO_DEPOT",
										AgentData = "AgentData",
										TransportData = "ResourceProducedTransportData",
									},
								},
							},
						},
						{
							Name = "GettingXp",
							Type = "GIVE_JOB_XP",
							AgentData = "AgentData",
							ShouldReceiveXp = "",
						}
					}
				}
			}
		}
	}
})

mod:registerBehaviorTree({
	Id = "FETCH_RESOURCE_IF_NEEDED",
	VariableList = {
		{
			Name = "AgentData",
			DataType = "BEHAVIOR_TREE_DATA_AGENT",
			IsPublic = true,
			InitialValue = {} -- Optional if empty, leaves the default values (if any)
		},
		{
			Name = "TransportData",
			DataType = "BEHAVIOR_TREE_DATA_RESOURCE_TRANSPORT",
			IsPublic = true,
		},
	},
	Root = {
		Name = "WorkplaceResourceSelector",
		Type = "SELECTOR",
		Children = {
			{
				Name = "WorkplaceNeedsResourceInverter",
				Type = "INVERTER",
				Child = {
					Name = "WorkplaceNeedsResource",
					Type = "IS_WORKPLACE_NEED_RESOURCE",
					AgentData = "AgentData"
				}
			},
			{
				Name = "FetchResourceSequencer",
				Type = "SEQUENCER",
				Children = {
					{
						Name = "FindResourceForWorkplace",
						Type = "FIND_RESOURCE_FOR_WORKPLACE",
						AgentData = "AgentData",
						TransportData = "TransportData",
					},
					{
						Name = "Transport",
						Type = "BEHAVIOR_TRANSPORT",
						AgentData = "AgentData",
						TransportData = "TransportData",
					},
				},
			},
		},
	},
})