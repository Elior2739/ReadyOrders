
--[[

Mod Created By Elior.

The mod isn't optimized and may create perfomance issuses.
for any issue with the mod itself you can visit the github page

https://github.com/Elior2739/ReadyOrders

]]


local renderUpdates = {}

local readyTrays = {}
local updatingScreen = false
local loopStarted = false

function requestRenderOnAll()
	local monitors = FindAllOf("BP_OrderMonitor_C")

	if(monitors == nil or #monitors == 0) then return end

	for _, monitor in pairs(monitors) do
		local requestRender = monitor:GetPropertyValue("RequestRenderUpdate")
		requestRender:CallFunction(requestRender)
	end
end

function updateRender()
	for orderTable, orderData in pairs(renderUpdates) do
		hasAny = true
		for _, func in pairs(orderData["priceFuncs"]) do
			func:CallFunction(FText("Ready!"), FText("Ready!"))
		end

		for _, func in pairs(orderData["orderTime"]) do
			func:CallFunction(FText(""), FText(""))
		end

		for _, func in pairs(orderData["tableNums"]) do
			func:CallFunction(FText(""), FText(""))
		end
	end

	requestRenderOnAll()
end


ExecuteWithDelay(1000, function()
	RegisterHook("Function /Game/Blueprints/Gameplay/FastFood/BP_FoodTray.BP_FoodTray_C:SetIsReady", function(context) 
		local tray = context:get()
		local receipt = tray:GetPropertyValue("Receipt")
		local receiptOrder = receipt:GetPropertyValue("ReceiptOrder")
		local trayTableNumber = tostring(receiptOrder:GetPropertyValue("TableNumber"))
	
		if(readyTrays[trayTableNumber] ~= nil) then
			readyTrays[trayTableNumber] = nil
			renderUpdates[trayTableNumber] = nil
			return
		end
	
		local orders = FindAllOf("W_OrderMonitorElement_C")
	
		if(orders == nil or #orders == 0) then return end

		for _, order in pairs(orders) do
			local orderItself = order:GetPropertyValue("Order")
	
			if(orderItself:GetFullName() ~= nil) then
				local orderElementTableNumber = tostring(orderItself:GetPropertyValue("TableNumber"))
	
				if(orderElementTableNumber == trayTableNumber) then
					if(not loopStarted) then
						loopStarted = true
						LoopAsync(100, updateRender)
					end

					local orderTime = order:GetPropertyValue("OrderTimeTxt")
					local priceTxt = order:GetPropertyValue("PriceTxt")
					local tableNumberTxt = order:GetPropertyValue("TableNumberTxt")
	
					local OrderTimeTxt_SetText = orderTime:GetPropertyValue("SetText")
					local PriceTxt_SetText = priceTxt:GetPropertyValue("SetText")
					local TableNumberTxt_SetText = tableNumberTxt:GetPropertyValue("SetText")
	
					if(renderUpdates[trayTableNumber] == nil) then
						renderUpdates[trayTableNumber] = {
							priceFuncs = {PriceTxt_SetText},
							orderTime = {OrderTimeTxt_SetText},
							tableNums = {TableNumberTxt_SetText}
						}
					else
						table.insert(renderUpdates[trayTableNumber]["priceFuncs"], PriceTxt_SetText)
						table.insert(renderUpdates[trayTableNumber]["orderTime"], OrderTimeTxt_SetText)
						table.insert(renderUpdates[trayTableNumber]["tableNums"], TableNumberTxt_SetText)
					end
	
					readyTrays[trayTableNumber] = true
					OrderTimeTxt_SetText:CallFunction(FText(""), FText(""))
					PriceTxt_SetText:CallFunction(FText("Ready!"), FText("Ready!"))
					TableNumberTxt_SetText:CallFunction(FText(""), FText(""))
					requestRenderOnAll()
	
				end
			end
		end
	end)

	RegisterHook("Function /Game/Blueprints/Gameplay/Order/BP_OrderManager.BP_OrderManager_C:RemoveOrder", function(self, parms)
		local order = parms[1]

		if(order:GetFullName() == nil) then return end

		local orderTable = tostring(order:GetPropertyValue("TableNumber"))
		renderUpdates[orderTable] = nil
		readyTrays[orderTable] = nil
	end)
end)

