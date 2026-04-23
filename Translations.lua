if not Translations then Translations = {} end
if not Translations.TomTom then Translations.TomTom = {} end

-- I speak german and english, but no other language, at least
-- not well enough to translate. If you have missing
-- translations, please tell me at blohm@s.netic.de.

local translationTable = {
	["German"] = {
		["TomTom"]		   = "TomTom",
		["TomTom Version "]	   = "TomTom Version ",
		[" installed!"] 	   = " installiert!",
		["Found Items"]		   = "gefundene Gegenstände",
		["mark "]		   = "markiere ",
		[" at "]		   = " an ",
		["forget "]		   = "vergesse ",
		["Tomtom won't bother you again."]=
					"Tomtom hält jetzt die Klappe.",
		["Tomtom telling you what it remembers."]=
					"TomTom erzählt nun was er sich merkt.",
		["ignoring "]		   = "ignoriere ",
		[" because you already have it."] = " weil Ihr den Mob schon habt.",
		["no rares in "]	   = "keine Raremobs in ",
		
		["hidden. Use /tomtom show to show it again."] =
			"versteckt. /tomtom show zeigt es wieder an.",
			
		["Autohide set to on."]	   = "Automatisches Verstecken an",
		["Autohide set to off. Use /tomtom autohide on to turn it on."]   = 
			"Automatisches Verstecken aus. /tomtom autohide on schaltet es an.",
		
		Ore			   = "Erz",
		Wood			   = "Holz",
		Plant			   = "Blume",
		
		Artifacts		   = "Artefakte",
		Achievements		   = "Erfolge",
		Portals			   = "Portale",
		["Rare mobs"]		   = "Seltene Mobs",
		
		["no location known for "] = "Keine bekannten Koordinaten für ",
		[" already finshed"]	   = " bereits beendet",
		
		["Ignoring portal at "]	   = "Ignoriere Portal an",
		[" because it's " ]	   = " weil es ",
		["."]			   = " ist.",			-- omg
		
		["Usage"]		   = "Verwendung",
		["second argument must be a valid x coordinate (left to right)"]
					   = "Zweites Argument muss eine gültige X-Koordinate (links nach rechts) sein",
		["third argument must be a valid z coordinate (top to bottom)"]
					   = "Drittes Argument muss eine gültige Z-Koordinate (oben nach unten) sein",
					   
		["second argument '"]		= "Zweites Argument '",
		["third argument '"]		= "Drittes Argument '", 
		["' must be a valid x coordinate (left to right)"]	= "' muss eine gültige X-Koordinate (links nach rechts) sein",
		["' must be a valid z coordinate (top to bottom)"]	= "' muss eine gültige Z-Koordinate (oben nach unten) sein",
					
					
	},
	-- french version thanks to Leetah
	["French"] = {
		["TomTom"]		   = "TomTom",
		["TomTom Version "]	   = "TomTom Version ",
		[" installed!"] 	   = " installé!",
		["Found Items"]		   = "Objets Trouvés",

		Wood			   = "Bois",


	},
	-- russian version thanks to Aybolitus (incomplete, copied from Heartometer)
	["Russian"] = {
		["TomTom"]         	= "TomTom",
		["TomTom Version "]	= "Версия TomTom ",
		[" installed!"]         = " установлена!",
	},
}

function Translations.TomTom.L(x)
	local lang=Inspect.System.Language()
	if  translationTable[lang]
	and translationTable[lang][x] then
		return translationTable[lang][x]
	elseif lang == "English"  then
		return x
	else
		if not translationTable[lang] then translationTable[lang]={} end
		translationTable[lang][x]=x
		print ("No translation yet for '" .. lang .. "'/'" .. x .. "'")
		return x
	end
end

