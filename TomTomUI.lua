-- User Interface

local function L(x) return Translations.TomTom.L(x) end

local miniWindow
local context
local triggers={}

function TomTom.addFlipHandler(handler)
	table.insert(triggers, handler)
end

local function trigger(n)
	local i, v
	for i,v in ipairs(triggers) do
		v(n)
	end
end

function TomTom.BuildMiniWindow()
	miniWindow=UI.CreateFrame("Frame", "TomTom", context)
	miniWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", TomTomChar.xpos, TomTomChar.ypos)
	miniWindow:SetWidth(100)
	miniWindow:SetHeight(140)
	miniWindow:SetBackgroundColor(0.1, 0.1, 0.1, 0.8)
	miniWindow:SetVisible(true)
	miniWindow.state={}
	miniWindow:EventAttach(Event.UI.Input.Mouse.Left.Down, function(handle)
	-- function miniWindow.Event:LeftDown()
		miniWindow.state.mouseDown = true
		local mouse = Inspect.Mouse()
		miniWindow.state.startX = miniWindow:GetLeft()
		miniWindow.state.startY = miniWindow:GetTop()
		miniWindow.state.mouseStartX = mouse.x
		miniWindow.state.mouseStartY = mouse.y
		miniWindow:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
	end
	, "startMoving")

	miniWindow:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(handle)
	-- function miniWindow.Event:MouseMove()
		if miniWindow.state.mouseDown then
			local mouse = Inspect.Mouse()
			TomTomChar.xpos=mouse.x - miniWindow.state.mouseStartX + miniWindow.state.startX
			TomTomChar.ypos=mouse.y - miniWindow.state.mouseStartY + miniWindow.state.startY
			miniWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
				TomTomChar.xpos, TomTomChar.ypos)
		end
	end
	, "whileMoving")

	miniWindow:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	-- function miniWindow.Event:LeftUp()
		if miniWindow.state.mouseDown then
			miniWindow.state.mouseDown = false
			miniWindow:SetBackgroundColor(0.1, 0.1, 0.1, 0.8)
		end
	end
	, "stopMoving")

	miniWindow.direction = UI.CreateFrame("Texture", "direction", miniWindow)
	miniWindow.direction:SetPoint("TOPLEFT", miniWindow, "TOPLEFT", 0, 0)
	miniWindow.direction:SetWidth(100)
	miniWindow.direction:SetHeight(100)
	miniWindow.direction:SetTexture("TomTom", "nodir.png")
	
	miniWindow.back=UI.CreateFrame("Texture", "directionback", miniWindow.direction)
	miniWindow.back:SetPoint("TOPLEFT", miniWindow.direction, "TOPLEFT", 0, 0)
	miniWindow.back:SetWidth(17)
	miniWindow.back:SetHeight(17)
	miniWindow.back:SetTexture("TomTom", "back.png")
	miniWindow.back:SetVisible(true)
	miniWindow.back:SetLayer(miniWindow.direction:GetLayer()+1)

	miniWindow.forward=UI.CreateFrame("Texture", "directionforward", miniWindow.direction)
	miniWindow.forward:SetPoint("TOPRIGHT", miniWindow.direction, "TOPRIGHT", 0, 0)
	miniWindow.forward:SetWidth(17)
	miniWindow.forward:SetHeight(17)
	miniWindow.forward:SetTexture("TomTom", "forward.png")
	miniWindow.forward:SetVisible(true)
	miniWindow.forward:SetLayer(miniWindow.direction:GetLayer()+1)
	
	miniWindow.back:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	-- function miniWindow.back.Event:LeftUp()
		trigger(-1);
	end
	, "moveoneback")
	
	miniWindow.forward:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	-- function miniWindow.forward.Event:LeftUp()
		trigger(1);
	end
	, "moveoneforward")

	miniWindow.menu = UI.CreateFrame("Texture", "menu", miniWindow.direction)
	miniWindow.menu:SetPoint("BOTTOMRIGHT", miniWindow.direction, "BOTTOMRIGHT", 0, 0)
	miniWindow.menu:SetWidth(17)
	miniWindow.menu:SetHeight(17)
	miniWindow.menu:SetTexture("TomTom", "menu.png")
	miniWindow.menu:SetVisible(true)
	miniWindow.menu:SetLayer(miniWindow.direction:GetLayer()+1)
	miniWindow.menu:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	--function miniWindow.menu.Event:LeftUp()
		miniWindow.menuFrame:SetVisible(not miniWindow.menuFrame:GetVisible());
	end
	, "showhideMenu")

	miniWindow.title = UI.CreateFrame("Text", "text", miniWindow)
	miniWindow.title:SetText(L("TomTom"))
	miniWindow.title:SetPoint("TOPLEFT", miniWindow, "TOPLEFT", 0, 100)

	miniWindow.comment = UI.CreateFrame("Text", "text", miniWindow)
	miniWindow.comment:SetText("")
	miniWindow.comment:SetPoint("TOPLEFT", miniWindow.title, "BOTTOMLEFT", 0, 0)

	miniWindow.menuFrame=UI.CreateFrame("Frame", "TomTom", context)
	miniWindow.menuFrame:SetPoint("TOPLEFT", miniWindow.comment, "BOTTOMLEFT", 0, 0)
	miniWindow.menuFrame:SetVisible(false)
	miniWindow.menuFrame:SetBackgroundColor(0.9, 0.9, 0.9, 0)

	miniWindow.ore = UI.CreateFrame("Text", "text", miniWindow.menuFrame)
	miniWindow.ore:SetText(L("Ore"))
	miniWindow.ore:SetPoint("TOPLEFT", miniWindow.menuFrame, "TOPLEFT", 0, 0)
	miniWindow.ore:SetWidth(33)
	miniWindow.ore:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
	miniWindow.ore:SetFontColor(0.23, 0.86, 0.13, 1)
	miniWindow.ore:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	--function miniWindow.ore.Event:LeftUp()
		TomTom.route("crafting material metal")
		miniWindow.menuFrame:SetVisible(false)
	end, "routeOre")
	
	miniWindow.wood = UI.CreateFrame("Text", "text", miniWindow.menuFrame)
	miniWindow.wood:SetText(L("Wood"))
	miniWindow.wood:SetPoint("TOPLEFT", miniWindow.menuFrame, "TOPLEFT", 33, 0)
	miniWindow.wood:SetWidth(33)
	miniWindow.wood:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
	miniWindow.wood:SetFontColor(0.23, 0.86, 0.13, 1)
	miniWindow.wood:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	--function miniWindow.wood.Event:LeftUp()
		TomTom.route("crafting material wood")
		miniWindow.menuFrame:SetVisible(false)
	end, "routeWood")

	miniWindow.plant = UI.CreateFrame("Text", "text", miniWindow.menuFrame)
	miniWindow.plant:SetText(L("Plant"))
	miniWindow.plant:SetPoint("TOPLEFT", miniWindow.menuFrame, "TOPLEFT", 66, 0)
	miniWindow.plant:SetWidth(33)
	miniWindow.plant:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
	miniWindow.plant:SetFontColor(0.23, 0.86, 0.13, 1)
	miniWindow.plant:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	--function miniWindow.plant.Event:LeftUp()
		TomTom.route("crafting material plant")
		miniWindow.menuFrame:SetVisible(false)
	end, "routeplant")

	miniWindow.arti = UI.CreateFrame("Text", "text", miniWindow.menuFrame)
	miniWindow.arti:SetText(L("Artifacts"))
	miniWindow.arti:SetPoint("TOPLEFT", miniWindow.ore, "BOTTOMLEFT", 0, 0)
	miniWindow.arti:SetWidth(100)
	miniWindow.arti:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
	miniWindow.arti:SetFontColor(0.23, 0.86, 0.13, 1)
	miniWindow.arti:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	-- function miniWindow.arti.Event:LeftUp()
		TomTom.route("misc collectible")	
		miniWindow.menuFrame:SetVisible(false)
	end, "routeArti")

	miniWindow.extensions={}
	local lastFrame=miniWindow.arti
	for k,v in pairs(TomTom.extensions) do
		miniWindow.extensions[k] = UI.CreateFrame("Text", "text", miniWindow.menuFrame)
		miniWindow.extensions[k]:SetText(k)
		miniWindow.extensions[k]:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, 0)
		miniWindow.extensions[k]:SetWidth(100)
		miniWindow.extensions[k]:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
		miniWindow.extensions[k]:SetFontColor(0.23, 0.86, 0.13, 1)
		miniWindow.extensions[k]:EventAttach(Event.UI.Input.Mouse.Left.Up,
			function (handle)
				TomTom.routeExtension(k)
				miniWindow.menuFrame:SetVisible(false)
			end
		, "menu select handler")
		lastFrame=miniWindow.extensions[k]
	end

	miniWindow.raremobs = UI.CreateFrame("Text", "text", miniWindow.menuFrame)
	miniWindow.raremobs:SetText(L("Rare mobs"))
	miniWindow.raremobs:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, 0)
	miniWindow.raremobs:SetWidth(100)
	miniWindow.raremobs:SetBackgroundColor(0.4, 0.4, 0.4, 0.8)
	miniWindow.raremobs:SetFontColor(0.23, 0.86, 0.13, 1)
	miniWindow.raremobs:EventAttach(Event.UI.Input.Mouse.Left.Up, function(handle)
	-- function miniWindow.raremobs.Event:LeftUp()
		if RareDar then 
			TomTom.raredar()
			TomTom.route("RareDar")
		elseif RareNerd_rares then
			TomTom.route("RareNerd")		
			TomTom.rarenerd()
		else
			print(L("This needs either RareDar or RareNerd installed."))
		end
		miniWindow.menuFrame:SetVisible(false)
	end, "routeRareMobs")

end

function TomTom.createUI()
	if context == nil then
		context=UI.CreateContext("TomTom")
	end

	if (miniWindow == nil) then
		if not TomTomChar.xpos then TomTomChar.xpos=500 end
		if not TomTomChar.ypos then TomTomChar.ypos=20 end
		TomTom.BuildMiniWindow()
	end
end

function TomTom.setInfoWindowText(text, comment)
	miniWindow.title:SetText(text)
	if comment then
		miniWindow.comment:SetText(comment)
	else
		miniWindow.comment:SetText("")
	end
end

function TomTom.setInfoWindowDirection(dir)
	miniWindow.direction:SetTexture("TomTom", dir..".png")
	-- miniWindow.forward:SetTexture("TomTom", "forward.png")
	-- miniWindow.back:SetTexture("TomTom", "back.png")
	-- print ("direction: " .. miniWindow.direction:GetStrata())
	-- print ("forward: " .. miniWindow.forward:GetStrata())
	-- print ("back: " .. miniWindow.back:GetStrata())
end

function TomTom.setUIVisibility(flag)
	miniWindow:SetVisible(flag)
end

