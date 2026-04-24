local TomTomAddonData, PrivateTable = ...

if TomTom then
	print ("TomTom already loaded")
	return
end

TomTom = {
	version=TomTomAddonData.toc.Version,
	localPatch="debug-guard-20260423"
}

local function L(x) return Translations.TomTom.L(x) end

local function tableLength(t)
	if table.getn then return table.getn(t) end
	return #t
end

local function atan2(y, x)
	if math.atan2 then return math.atan2(y, x) end
	if x > 0 then return math.atan(y / x) end
	if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
	if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
	if x == 0 and y > 0 then return math.pi / 2 end
	if x == 0 and y < 0 then return -math.pi / 2 end
	return 0
end

local debugEnabled=false
local debugNextTime=0
local debugUpdateCount=0
local debugLastMessage=""
local function debugPrint(message, force)
	if not debugEnabled then return end
	local now=Inspect.Time.Frame()
	if force or now>=debugNextTime or message~=debugLastMessage then
		print("[TomTom debug] "..message)
		debugNextTime=now+2
		debugLastMessage=message
	end
end


local function ensureVariablesInited()
	if not TomTomChar then TomTomChar={} end	
	if not TomTomShard then TomTomShard={} end
	if not TomTomGlobal then TomTomGlobal={} end
	if not TomTomGlobal.PickupLocations then
		TomTomGlobal.PickupLocations={}
	end
end

local function markLocation(name, xs, zs, comment)
	ensureVariablesInited()
	if not TomTomGlobal.PickupLocations[name] then
		TomTomGlobal.PickupLocations[name]={}
	end
	local playerdetail=Inspect.Unit.Detail("player")
	if not playerdetail then return end
	local found = false
	local i, d
	local x,z

	if xs~=nil and tonumber(xs)>0 then x=tonumber(xs) else x=playerdetail.coordX end
	if zs~=nil and tonumber(zs)>0 then z=tonumber(zs) else z=playerdetail.coordZ end

	for i, d in ipairs (TomTomGlobal.PickupLocations[name]) do
		if d[1]==playerdetail.zone
		and (x-d[2])*(x-d[2])+
		    (z-d[3])*(z-d[3]) < 100 then
		    d[4]=(d[4] or 1)+1
		    found = true
		end
	end
	if not found then
		if TomTomGlobal.verbose then
			print (L("mark ") .. name .. L(" at ") .. x .. "," .. z .. " " .. (comment or ""))
		end
		table.insert(TomTomGlobal.PickupLocations[name],
			{ playerdetail.zone, x, z, 1, comment }
		)
	end
end

local function forgetLocation(xs, zs) 
	local playerdetail=Inspect.Unit.Detail("player")
	if not playerdetail then return end
	
	local x, z, name, data, i, d
	if xs~=nil and tonumber(xs)>0 then x=tonumber(xs) else x=playerdetail.coordX end
	if zs~=nil and tonumber(zs)>0 then z=tonumber(zs) else z=playerdetail.coordZ end
	
	for name, data in pairs(TomTomGlobal.PickupLocations) do
		for i, d in ipairs(data) do
			if d[1]==playerdetail.zone
			and (x-d[2])*(x-d[2])+
			    (z-d[3])*(z-d[3]) < 100 then
				if TomTomGlobal.verbose then
					print(L("forget ")..name)
				end
				table.remove(data, i)
			end
		end
	end
end

local savedinslot={}
local function itemChanged(handle, updates)
	ensureVariablesInited()
	local k, v
	for k, v in pairs(updates) do
		--print ("slot "..k)
		--print ("slot type "..k:sub(1,2))
		if k:sub(1, 2) == "si" 
		and k:sub(1, 4) ~= "sibg"
		and v ~= false and v ~= nil and v ~= "nil" then
			local itemdetail=Inspect.Item.Detail(v)
--[[			
			print ("TomTom: " .. k .. " " .. v)
			if not savedinslot[k] then 
				print ("slot was empty")
			elseif (savedinslot[k].id ~= itemdetail.id) then
				print ("replaced "..(savedinslot[k].id or "none") .. " with " .. (itemdetail.id or "none") .. "=> item swap?")
			elseif (savedinslot[k].stack ~= v.stack) then
				print ("stack was " .. (savedinslot[k].stack or "none") .. ", changed to " .. (itemdetail.stack or "none"))
			end
--]]
			if itemdetail and itemdetail.rarity ~= "sellable" and (								-- ignore trash
			   not savedinslot[k] 									-- slot was empty
			   or (savedinslot[k].id == itemdetail.id and savedinslot[k].stack ~= itemdetail.stack) -- stack size changed
			) then
				-- dump(itemdetail)
				markLocation(itemdetail.name)
				if (itemdetail.category ~= nil) then
					markLocation(itemdetail.category, nil, nil, itemdetail.name)
				end
			end
			savedinslot[k]=itemdetail
		else
			savedinslot[k]=nil
		end
	end
end

local inventoryInitialized=false
local function initInventory()
	local b, i
	for b=1, 5 do
		for i=1, 32 do
			slot = Utility.Item.Slot.Inventory(b , i)
			item=Inspect.Item.Detail(slot)
			savedinslot[slot]=item
			if item then
				-- print ("init "..slot.." with "..item.id .. "/" .. (item.stack or "?"))
				inventoryInitialized=true
			end
		end
	end
end
		
function TomTom.printVersion()
	LibVersionCheck.register("TomTom", TomTom.version)
	print(L("TomTom Version ") .. (TomTom.version) .. L(" installed!"))
end

local routingPoints={}
local currentZone
local playerdetail
local nextroutingpoint=1

local function flip(n)
	nextroutingpoint=nextroutingpoint+n
	if nextroutingpoint<1 then nextroutingpoint=1 end
	if nextroutingpoint>tableLength(routingPoints) then
		nextroutingpoint=tableLength(routingPoints)+1
		TomTom.setInfoWindowText("TomTom")
		TomTom.setInfoWindowDirection("nodir")
	end
	TomTom.checkAutoHide()
end

local function printRoute()
	for i,p in ipairs(routingPoints) do
		print (i..": Go to "..p[1].." / "..p[2])
	end
end

local function startRouting()
	playerdetail=Inspect.Unit.Detail("player")
	routingPoints={}
	routingPoints[1]={playerdetail.coordX, playerdetail.coordZ}
	-- print("start routing at point ("..playerdetail.coordX..","..playerdetail.coordZ..")")
	if Library and Library.LibMapNotes then
		Library.LibMapNotes.AddNodes("TomTom", { { x=playerdetail.coordX, z=playerdetail.coordZ, n="player start", itex="nodir.png", isrc="TomTom", isiz=16 } });
	end
end

local function addRouting(str)
	local k, v, i, p, bestcost
	-- print ("adding points for "..str)
	if not TomTomGlobal.PickupLocations[str] then return end
	for k,v in pairs(TomTomGlobal.PickupLocations[str]) do
		-- dump(v)
		if v[1] == playerdetail.zone and v[2] and v[3] then
			local x=v[2]
			local z=v[3]
			-- print ("add "..x.."/"..z)
			bestcost=-1
			for i,p in ipairs(routingPoints) do
				local currentcost
				local dx1=x-p[1]
				local dz1=z-p[2]
				local dist1=math.sqrt(dx1*dx1+dz1*dz1)
				if i==tableLength(routingPoints) then
					currentcost=dist1
				else
					local dx2=x-routingPoints[i+1][1];
					local dz2=z-routingPoints[i+1][2];
					local dist2=math.sqrt(dx2*dx2+dz2*dz2)

					local dx3=p[1]-routingPoints[i+1][1];
					local dz3=p[2]-routingPoints[i+1][2];
					local dist3=math.sqrt(dx3*dx3+dz3*dz3)
					
					currentcost=dist1+dist2-dist3
				end
				if bestcost==-1 or currentcost < bestcost then
					bestcost=currentcost
					bestbehind=i
				end
			end
			i=tableLength(routingPoints)
			while (i>bestbehind) do
				routingPoints[i+1]=routingPoints[i]
				i=i-1
			end
			routingPoints[bestbehind+1]={x, z, v[5]}
			-- print ("added point ("..x..","..z..") at position "..bestbehind)
			-- print ("route is now: ")
			-- printRoute()
			if Library and Library.LibMapNotes then
				Library.LibMapNotes.AddNodeToSet("TomTom", { x=x, z=z, n=v[5], itex="nodir.png", isrc="TomTom", isiz=16 });
			end

		end
		-- print ("-----------------------------------------")
	end
	nextroutingpoint=2
	TomTom.checkAutoHide()
end

local function spam(s)
	if TomTomGlobal.verbose then
		print(s)
	end
end

function TomTom.raredar(flag)
	if RareDar and  RareDar.data then
		local lang=Inspect.System.Language()
		local player=Inspect.Unit.Detail("player")
		local zone=Inspect.Zone.Detail(player.zone)
		TomTomGlobal.PickupLocations["RareDar"]={}
		for i,z in ipairs(RareDar.data) do
			-- print(z.zone[lang])
			if z.zone[lang]==zone.name then
				print("found "..zone.name)
				for j, data in ipairs(z.mobs) do
					if not flag and data.killed then
						print (L("ignoring ")..data.targ[lang]..L(" because you already have it."))
					elseif (flag or data.killed==false) then	-- check false, might be nil
						for k, pos in ipairs(data.pos) do 
							markLocation("RareDar", pos[1], pos[2], data.targ[lang])
						end
					end
				end
			end
		end
	elseif  RareDar_rares then
		local lang=Inspect.System.Language()
		local player=Inspect.Unit.Detail("player")
		local zone=Inspect.Zone.Detail(player.zone)
		-- print ("lang=" .. lang .. ", zone=" .. zone.name)
		TomTomGlobal.PickupLocations["RareDar"]={}
		if not RareDar_rares[lang][zone.name] then
			print(L("no rares in ")..zone.name)
			return
		end
		for k, v in pairs(RareDar_rares[lang][zone.name]) do
			if not v[6] then
				markLocation("RareDar", v[1], v[2], k)
			elseif TomTomGlobal.verbose then
				print (L("ignoring ") .. k .. L(" because you already have it."))
			end
		end
	else
		print "RareDar not loaded"
		return
	end
end

function TomTom.rarenerd()
	if not RareNerd_rares then
		print "RareNerd not loaded"
		return
	end
	local lang=Inspect.System.Language()
	local player=Inspect.Unit.Detail("player")
	local zone=Inspect.Zone.Detail(player.zone)
	-- print ("lang=" .. lang .. ", zone=" .. zone.name)
	TomTomGlobal.PickupLocations["RareNerd"]={}
	if not RareNerd_rares[lang][zone.name] then
		print(L("no rares in ")..zone.name)
		return
	end
	for k, v in pairs(RareNerd_rares[lang][zone.name]) do
		if not v[6] then
			markLocation("RareNerd", v[1], v[2], k)
		else
			spam(L("ignoring ") .. k .. L(" because you already have it."))
		end
	end
end

TomTom.extensions={}
function TomTom.register(name, db)
	TomTom.extensions[name]=db
end

function TomTom.importExtension(name, allflag)
	if not TomTom.extensions[name] then return end
	local player=Inspect.Unit.Detail("player");
	local lang=Inspect.System.Language()
	local i, v

	TomTomGlobal.PickupLocations[name]={}
	for i, v in ipairs(TomTom.extensions[name]) do
		if v.zone==player.zone then
			local achv = nil
			if v.achv then
				achv=Inspect.Achievement.Detail(v.achv)
			end
			for j, w in ipairs(v.locations) do
				local locationName=w[lang]
				if not locationName then locationName=w.description end
				if not locationName and achv and achv.requirement and achv.requirement[j] then locationName=achv.requirement[j].name end
				if not locationName and achv then locationName=achv.name .. " / "..j end
				if not locationName then locationName=name .. " "..j end
				
				if w.xpos==0 or w.zpos==0 then
					spam(L("no location known for ")..locationName)
				elseif v.achv then
					if allflag or achv.complete ~= true then
						if achv.requirement and achv.requirement[j] then
							if allflag or achv.requirement[j]~= true then
								markLocation(name, w.xpos, w.zpos, locationName)
							else
								spam(achv.requirement[j].name .. L(" already finshed"))
							end
						else
							markLocation(name, w.xpos, w.zpos, achv.name)
						end
					else
						spam(achv.name .. L(" already finshed"))
					end
				else
					markLocation(name, w.xpos, w.zpos, locationName)
				end
			end
		end
	end
	return name
end

function TomTom.route(name)
	startRouting()
	addRouting(name)
end

function TomTom.routeExtension(name, allflag)
	TomTom.importExtension(name, allflag)
	TomTom.route(name)
end

function TomTom.routeAchieves()
	return TomTom.routeExtension("Achievements");
end

function TomTom.routePortals()
	return TomTom.routeExtension("Portals");
end

local tmpFlag=false
local crashedInUpdate=false
local lastTime=0
local lastX=0
local lastZ=0
local playerDirection=0
local lastspX=0
local lastspZ=0
local speed=0

local function systemUpdateCore(handle)
	debugUpdateCount=debugUpdateCount+1
	if tmpFlag == true then return end
	if crashedInUpdate == true then return end
	crashedInUpdate = true

	if not inventoryInitialized then
		initInventory()
	end

	local playerdetail=Inspect.Unit.Detail("player")
	if playerdetail == nil or playerdetail.coordX == nil then
		debugPrint("update #"..debugUpdateCount..": waiting for player coordinates")
		-- happens during ports
		crashedInUpdate = false
		return
	end

	local dirx=lastX-playerdetail.coordX
	local dirz=lastZ-playerdetail.coordZ
	lastX=playerdetail.coordX
	lastZ=playerdetail.coordZ
	
	local now=Inspect.Time.Frame()
	local delta=now-lastTime
	if delta > 1 then
		local spx=lastspX-playerdetail.coordX
		local spz=lastspZ-playerdetail.coordZ
		lastspX=playerdetail.coordX
		lastspZ=playerdetail.coordZ
		speed=math.floor(math.sqrt((spx*spx)+(spz*spz))/delta*10)/10
		lastTime=now
	end

	if nextroutingpoint <= tableLength(routingPoints) then
		local dx, dz, dist
		repeat
			dx=routingPoints[nextroutingpoint][1]-playerdetail.coordX
			dz=routingPoints[nextroutingpoint][2]-playerdetail.coordZ
			dist=math.sqrt(dx*dx+dz*dz)
			if dist<10 then
				nextroutingpoint=nextroutingpoint+1
				if nextroutingpoint > tableLength(routingPoints) then
					TomTom.setInfoWindowText("TomTom")
					TomTom.setInfoWindowDirection("nodir")
					TomTom.checkAutoHide()
					crashedInUpdate = false
					return
				end
			end
		until (dist >= 10)
		if (dirx ~= 0 or dirz ~= 0) then
			playerDirection=180/3.14159265*atan2(dirz, dirx)
		end
		local angle=180/3.14159265*atan2(dz, dx)
		if TomTomGlobal.relativeArrow then angle=angle-playerDirection+90 end
		while (angle < -180) do angle=angle+360 end
		while (angle >  180) do angle=angle-360 end
		-- if TomTomGlobal.relativeArrow then
			-- print ("angle= "..(180/3.14159265*atan2(dz, dx)) .. ", player moves "..playerDirection.." results in "..angle)
		-- end
		if     (angle < -169) then dir="w"
		elseif (angle < -146) then dir="nww"
		elseif (angle < -124) then dir="nw"
		elseif (angle < -101) then dir="nnw"
		elseif (angle <  -79) then dir="n"
		elseif (angle <  -56) then dir="nne"
		elseif (angle <  -34) then dir="ne"
		elseif (angle <  -11) then dir="nee"
		elseif (angle <   11) then dir="e"
		elseif (angle <   34) then dir="see"
		elseif (angle <   56) then dir="se"
		elseif (angle <   79) then dir="sse"
		elseif (angle <  101) then dir="s"
		elseif (angle <  124) then dir="ssw"
		elseif (angle <  146) then dir="sw"
		elseif (angle <  169) then dir="sww"
		else                       dir="w"
		end
		TomTom.setInfoWindowText(""..nextroutingpoint.."/"..tableLength(routingPoints)..": "..math.floor(dist).."m "..dir,
			routingPoints[nextroutingpoint][3])
		TomTom.setInfoWindowDirection(dir)
		debugPrint("update #"..debugUpdateCount..": route "..nextroutingpoint.."/"..tableLength(routingPoints).." dist="..math.floor(dist).." dir="..dir)
	else
		TomTom.setInfoWindowText("travel speed", speed .. "m/s")
		debugPrint("update #"..debugUpdateCount..": no active route; speed="..speed.." x="..math.floor(playerdetail.coordX).." z="..math.floor(playerdetail.coordZ))
	end
	crashedInUpdate = false
end

local lastUpdateError=""
local function systemUpdate(handle)
	local ok, err=pcall(systemUpdateCore, handle)
	if not ok then
		crashedInUpdate=false
		local message=tostring(err)
		if message~=lastUpdateError then
			print("[TomTom error] systemUpdate failed: "..message)
			lastUpdateError=message
		end
	end
end

local function usage()
	print (L("Usage")..": tomtom mark <name> [x] [z] [comment] | forget | verbose | silent | next | prev | relative | absolute | raredar | achieves | portals | route <type> ... | goto <x> <z> | print | show | hide | autohide [on] | debug [on|off]")
end

function TomTom.checkAutoHide()
	if TomTomChar.autohide then
		if nextroutingpoint > tableLength(routingPoints)  then
			TomTom.setUIVisibility(false)
		else
			TomTom.setUIVisibility(true)
		end
	end
end

function TomTom.SlashHandler(handle, args)
	local r = {}
	local numargs = 1
	local inquote = false
	local token, tmptoken
	for token in string.gmatch(args, "[^%s]+") do
		--print(token)
		if token:sub(1, 1) == "\"" then
			tmptoken=""
			token=token:sub(2) -- handle "abc" case
			inquote=true
			--print("start qoute token="..token)
		end
		if inquote then
			--print ("in quote, last char: "..token:sub(-1))
			if token:sub(-1) == "\"" then
				inquote=false
				token=token:sub(1, -2)
				token=tmptoken .. token
				--print ("combined string is "..token)
			else
				tmptoken=tmptoken .. token .. " "
				--print ("tmp token is "..token)
			end
		end
		if not inquote then
			r[numargs] = token
			-- print ("r["..numargs.."] ='"..token.."'")
			numargs=numargs+1
		end
	end
	if numargs>1 then
		if r[1] == "version" then
			TomTom.printVersion()
		elseif r[1] == "mark" and numargs>2 and r[2]~=nil then
			if r[3] then
				if tonumber(r[3])==nil or tonumber(r[3])<0 or tonumber(r[3])>18000 then
					print(L("second argument '")..r[3]..L("' must be a valid x coordinate (left to right)"))
					return
				end
			end
			if r[4] then
				if tonumber(r[4])==nil or tonumber(r[4])<0 or tonumber(r[4])>18000 then
					print(L("third argument '")..r[4]..L("' must be a valid z coordinate (top to bottom)"))
					return
				end
			end
			markLocation(r[2], r[3], r[4], r[5])
		elseif r[1] == "goto" and numargs>3 then
			if r[2] then
				if tonumber(r[2])==nil or tonumber(r[2])<0 or tonumber(r[2])>16384 then
					print(L("second argument '")..r[3]..L("' must be a valid x coordinate (left to right)"))
					return
				end
			end
			if r[3] then
				if tonumber(r[3])==nil or tonumber(r[3])<0 or tonumber(r[3])>16384 then
					print(L("third argument '")..r[3]..L("' must be a valid z coordinate (top to bottom)"))
					return
				end
			end
			TomTomGlobal.PickupLocations["goto"]={}
			markLocation("goto", r[2], r[3], "goto target")
			startRouting()
			addRouting("goto")
		elseif r[1] == "forget" then
			forgetLocation(r[2], r[3])
		elseif r[1] == "silent" then
			print(L("Tomtom won't bother you again."));
			TomTomGlobal.verbose = false
		elseif r[1] == "verbose" then
			print(L("Tomtom telling you what it remembers."));
			TomTomGlobal.verbose = true
		elseif r[1] == "next" then
			flip(1)
		elseif r[1] == "prev" or r[1] == "previous" then
			flip(-1)
		elseif r[1] == "absolute" then
			TomTomGlobal.relativeArrow=false
		elseif r[1] == "relative" then
			TomTomGlobal.relativeArrow=true
		elseif r[1] == "raredar" then
			if r[2] == "all" then
				TomTom.raredar(true)
			else
				TomTom.raredar(false)
			end
			startRouting()
			addRouting("RareDar")
		elseif r[1] == "rarenerd" then
			TomTom.rarenerd()
			startRouting()
			addRouting("RareNerd")
		elseif r[1] == "achieves" or r[1] == "Erfolge" then
			TomTom.routeAchieves(r[2]=="all")
		elseif r[1] == "portals" then
			TomTom.routePortals(r[2]=="all")
		elseif r[1] == "extension" and r[2] then
			TomTom.routeExtension(r[2], r[3]=="all")
		elseif r[1] == "route" then
			startRouting()
			local i=2
			while (i<numargs) do
				addRouting(r[i])
				i=i+1
			end
		elseif r[1] == "args" then
			local i=2
			while (i<numargs) do
				print("|" .. r[i] .. "|  ")
				i=i+1
			end
		elseif r[1] == "print" then
			printRoute()
		elseif r[1] == "debug" then
			if r[2] == "off" then
				debugEnabled=false
				print("[TomTom debug] off")
			else
				debugEnabled=true
				debugNextTime=0
				local pd=Inspect.Unit.Detail("player")
				if pd and pd.coordX then
					print("[TomTom debug] on: zone="..tostring(pd.zone).." x="..math.floor(pd.coordX).." z="..math.floor(pd.coordZ).." route="..nextroutingpoint.."/"..tableLength(routingPoints))
				else
					print("[TomTom debug] on: player coordinates unavailable")
				end
			end
		elseif r[1] == "show" then
			TomTom.setUIVisibility(true)
		elseif r[1] == "hide" then
			TomTom.setUIVisibility(false)
			print (L("hidden. Use /tomtom show to show it again."))
		elseif r[1] == "autohide" then
			if r[2] and r[2]=="on" then
				TomTomChar.autohide=true
				print (L("Autohide set to on."))
				TomTom.checkAutoHide()
			else
				TomTomChar.autohide=false
				print (L("Autohide set to off. Use /tomtom autohide on to turn it on."))
				TomTom.setUIVisibility(true)
			end
		else
			usage()
		end
	else
		usage()
	end
end

local function addonLoaded(handle, addon) 
	if (addon == "TomTom") then
		TomTom.printVersion()
		print("[TomTom] local patch "..TomTom.localPatch.." loaded. Use /tomtom debug to inspect updates.")
		ensureVariablesInited()
		TomTom.createUI()
		TomTom.addFlipHandler(flip)
		initInventory()
		if TomTomChar.autohide then
			print("TomTom autohide is set, so the UI doesn't show. Use /tomtom autohide to turn this off and show the UI.")
			TomTom.setUIVisibility(false)
		end
	end
end

Command.Event.Attach(Event.Item.Slot,   		itemChanged, "ItemSlotUpdated")
Command.Event.Attach(Event.Item.Update, 		itemChanged, "ItemUpdated")
Command.Event.Attach(Event.Addon.Load.End, 		addonLoaded, "AddonLoaded")
Command.Event.Attach(Event.System.Update.Begin, 	systemUpdate, "systemUpdate")
Command.Event.Attach(Command.Slash.Register("tomtom"), 	TomTom.SlashHandler, "SlashHandler")
