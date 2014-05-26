require "Window"

local BetterWho = {} 

function BetterWho:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    BetterWho.sortField = "strName"
    return o
end

function BetterWho:Init()
    Apollo.RegisterAddon(self)
    Apollo.RegisterEventHandler("WhoResponse", "OnWhoResponse", self)
end
 

function BetterWho:OnLoad()
	self.Xml = XmlDoc.CreateFromFile("BetterWho.xml")
end

function BetterWho:OnWhoResponse(arResponse, eWhoResult)
	if self.wndMain ~= nil then self.wndMain:Destroy() end
	self.wndMain = Apollo.LoadForm(self.Xml, "BetterWhoForm", nil, self)
	self.list = self.wndMain:FindChild("ListContainer")

	if eWhoResult == GameLib.CodeEnumWhoResult.OK or eWhoResult == GameLib.CodeEnumWhoResult.Partial then
		if arResponse == nil or #arResponse == 0 then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, Apollo.GetString("Who_NoResults"))
			return
		end

		self.results = arResponse

		self:FillResults()

		self.wndMain:Show(true)
	elseif eWhoResult == GameLib.CodeEnumWhoResult.UnderCooldown then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, Apollo.GetString("Who_UnderCooldown"), "")
		self.wndMain:Show(false)
	end
end

function BetterWho.sort(objA, objB)
	return objA[BetterWho.sortField] < objB[BetterWho.sortField]
end

function BetterWho:OnSortColumn( wndHandler, wndControl, eMouseButton )
	local name = wndControl:GetName()
	if name == "btnName" then BetterWho.sortField = "strName" end
	if name == "btnLevel" then BetterWho.sortField = "nLevel" end
	if name == "btnRace" then BetterWho.sortField = "strRace" end
	if name == "btnClass" then BetterWho.sortField = "strClass" end
	if name == "btnPath" then BetterWho.sortField = "strPath" end
	if name == "btnZone" then BetterWho.sortField = "strZone" end

	self:FillResults()
end

function BetterWho:FillResults()
	for i, child in ipairs(self.list:GetChildren()) do
		child:Destroy()
	end

	table.sort(self.results, BetterWho.sort)
	for _, tWho in ipairs(self.results) do
		-- each line in arResponse has strName, nLevel, eRaceId, eClassId, ePlayerPathType, nWorldZone, strRace, strClass, strZone, strPath, the last 4 can be nil
		local listEntry = Apollo.LoadForm(self.Xml, "WhoListItem", self.list, self)
		listEntry:FindChild("txtName"):SetText(tWho.strName)
		listEntry:FindChild("txtLevel"):SetText(tostring(tWho.nLevel))
		listEntry:FindChild("txtRace"):SetText(String_GetWeaselString("$1n", tWho.strRace) or "-")
		listEntry:FindChild("txtClass"):SetText(tWho.strClass or "-")
		listEntry:FindChild("txtPath"):SetText(tWho.strPath or "-")
		listEntry:FindChild("txtZone"):SetText(tWho.strZone or "-")
		listEntry:SetData(tWho.strName)
	end
	self.list:ArrangeChildrenVert()
end

function BetterWho:OnClose( wndHandler, wndControl, eMouseButton )
	self.wndMain:Show(false)
end

function BetterWho:OnMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local unitToT = wndHandler:GetData()

	if eMouseButton == GameLib.CodeEnumInputMouse.Right and unitToT ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", nil, unitToT)
		return true
	end

	return false
end


local BetterWhoInst = BetterWho:new()
BetterWhoInst:Init()
