require ("GMC4_Common.debugging")
require ("GMC4_Common.helpers")
require ("drivers-common-public.global.lib")
require ("drivers-common-public.global.handlers")

MyEvents = {}
DriverVersion = "0.2"

function OnDriverLateInit (reason)
	OPC.Debug_Mode(Properties['Debug Mode'])
	OPC.Server_Mode(Properties['Server Mode'])
	GetMyEvents()
	AddMyEvents()
	
	UpdatePropertyURLs()
	StartServer()
	
	C4:UpdateProperty("Driver Version", DriverVersion)
	C4:RegisterSystemEvent(C4SystemEvents["OnDirectorIPAddressChanged"], 0)
end

function OPC.Debug_Mode(value)
	if(value == "Print") then
		DEBUGPRINT = true
	else
		DEBUGPRINT = false
	end
end

function OPC.Server_Mode(value)
	UpdatePropertyURLs()
	StartServer()
end

function OPC.Port(value)
	UpdatePropertyURLs()
	StartServer()
end

function OPC.Password(value)
	UpdatePropertyURLs()
end

function OSE.OnDirectorIPAddressChanged(event)
	UpdatePropertyURLs()
end



function EC.ShowEvents(tParams)
	Debug("EC.ShowEvents")
	GetMyEvents()
	
	local EventIDs = {}

	for k in pairs(MyEvents) do 
		table.insert(EventIDs, k) 
	end
	table.sort(EventIDs, function(E1, E2) 
													return tonumber(E1) < tonumber(E2)
											 end)
	for _, k in ipairs(EventIDs) do 
		Debug(k .. " = " .. MyEvents[k].EventName) 
	end
end

function EC.CreateEvent(tParams)
	DebugHeader("EC.CreateEvent")
	Debug(tParams)
	
	GetMyEvents()
	local NewEvent = {}
	NewEvent.EventID						= tonumber(tParams.EventID)
	NewEvent.EventName					= tParams.EventName
	NewEvent.Description				= tParams.EventDescription
	
	if(NewEvent.Description == nil or NewEvent.Description == "") then
		NewEvent.Description = NewEvent.EventName
	end
	
	MyEvents[NewEvent.EventID] 	= NewEvent
	SetMyEvents()
	
	C4:AddEvent(NewEvent.EventID, NewEvent.EventName, NewEvent.Description)
	Debug(MyEvents)
end

function EC.DeleteEvent(tParams)
	DebugHeader("EC.DeleteEvent")
	Debug(tParams)
	
	GetMyEvents()
	MyEvents[tobumber(tParams.EventID)] = nil
	SetMyEvents()
	
	C4:DeleteEvent(tonumber(tParams.EventID))
	
	Debug(MyEvents)
end

function GetMyEvents()
	MyEvents = C4:PersistGetValue("MyEvents")
	if(MyEvents == nil) then
		MyEvents = {}
	end
end

function AddMyEvents()
	if(MyEvents == nil) then
		return
	end
	for k,v in pairs(MyEvents) do
		local EventID			= v.EventID
		local EventName		= v.EventName
		local Description	= v.Description
		
		if(Description == nil or Description == "") then
			Description = EventName
		end
		
		Debug("Adding " .. EventName .. " (" .. EventID .. ") - " .. Description .. "...")
		
		C4:AddEvent(EventID, EventName , Description)
	end
end

function SetMyEvents()
	C4:PersistSetValue("MyEvents", MyEvents, false) 
end

function GetCommandParamList(commandName, paramName)
	local tList = {}
	if (commandName == "Execute Event") then
		GetMyEvents()
		for k,v in pairs(MyEvents) do
			table.insert(tList, v.EventID .. ": " .. v.EventName)
		end
	end
	return (tList)
end








function StringSplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function EC.Execute_Event(tParams)
	Debug("Execute Event Command: " .. tParams["Event"])
	
	local EventID = StringSplit(tParams["Event"], ":")[1]
	Debug("Firing Event: " .. EventID)
	
	C4:FireEventByID(EventID);
end














function HideProperty(Name)
	C4:SetPropertyAttribs(Name, 1)
end
function ShowProperty(Name)
	C4:SetPropertyAttribs(Name, 0)
end










function UpdatePropertyURLs()	
	local ControllerIP = C4:GetControllerNetworkAddress()
	C4:UpdateProperty("Get Commands (JSON)"	, Properties['Server Mode'] .. "://" .. ControllerIP .. ":" .. Properties['Port'] .. "/GetCommands?PW=" .. Properties['Password'])
	C4:UpdateProperty("Get Commands (XML)"	, Properties['Server Mode'] .. "://" .. ControllerIP .. ":" .. Properties['Port'] .. "/GetCommandsXML?PW=" .. Properties['Password'])
	C4:UpdateProperty("Get Commands (HTML)"	, Properties['Server Mode'] .. "://" .. ControllerIP .. ":" .. Properties['Port'] .. "/GetCommandsHTML?PW=" .. Properties['Password'])
end

function StartServer()
	local ServerPort = Properties["Port"]
	local ServerMode = Properties['Server Mode']
	
	Debug("Destroying Server on Port " .. ServerPort)
	C4:DestroyServer(ServerPort)
	
	Debug("Starting " .. ServerMode ..  " Server on Port " .. ServerPort)
	if(ServerMode == "HTTPS") then
		ShowProperty("TLS - Certificate")
		ShowProperty("TLS - Private Key")
		C4:CreateTLSServer(ServerPort, '', 0, 1, '', Properties["TLS - Certificate"], Properties["TLS - Private Key"], '', '')
	else
		HideProperty("TLS - Certificate")
		HideProperty("TLS - Private Key")
		
		C4:CreateServer(ServerPort)
	end
end

---------------------------
----[ SERVER DATA IN ] ----
---------------------------
function OnServerDataIn(nHandle, strData)
	Debug("Data IN: " .. strData)
	local msg = ''
	local ResponseContentType = ""
	local ResponseData = ""

	QueryParams = ParseRequest(strData)
	Response = ProcessRequest(QueryParams)
	
	if(Response.ContentType == "JSON") then
		Debug("JSON")
		ResponseContentType = "application/json"
		ResponseData = C4:JsonEncode(Response.Data, true, true)
	elseif(Response.ContentType == "XML") then
		Debug("XML")
		ResponseContentType = "application/xml"
		ResponseData = Response.Data
	elseif(Response.ContentType == "HTML") then
		Debug("HTML")
		ResponseContentType = "text/html"
		ResponseData = Response.Data
	elseif(Response.ContentType == "TEXT") then
		Debug("TEXT")
		ResponseContentType = "text/plain"
		ResponseData = Response.Data
	else
		Debug("ERROR")
		ResponseContentType = "text/plain"
		ResponseData = "Content Type NOT Set, Check ProcessRequest()"
	end
	
	local ResponseHeaders = "HTTP/1.0 " .. Response.StatusCode .. " " .. Response.StatusText .."\r\nContent-Length: " .. ResponseData:len() .. "\r\nContent-Type: " .. ResponseContentType .. "\r\n\r\n"
	C4:ServerSend(nHandle, ResponseHeaders .. ResponseData)
	C4:ServerCloseClient(nHandle)
end

function ProcessRequest(QueryParams)
	local Response = {}
	Response.ContentType = ""
	Response.StatusCode = "200"
	Response.StatusText = "OK"
	
	if(QueryParams.url == "favicon.ico") then
		Response.StatusCode		= "404"
		Response.StatusText		= "NOT FOUND"
		Response.ContentType	= "TEXT"
		Response.Data					= "404 FILE NOT FOUND"
		return Response
	end
	
	if(QueryParams.pw ~= nil) then
		Debug("Set PW: " .. Properties["Password"])
		Debug("Request PW: " .. QueryParams.pw)
	end
	
	if(QueryParams.pw ~= Properties["Password"]) then
		DebugHeader("INVALID PASSWORD")
		Response.StatusCode		= "403"
		Response.StatusText		= "FORBIDDEN"
		Response.ContentType	= "TEXT"
		Response.Data					= "NOT AUTHORIZED"
		return Response
	end
	
	if(QueryParams.url == string.lower("GetCommandsXML")) then
		Response.ContentType = "XML"
		Response.Data = GetCommandsXML()
	elseif(QueryParams.url == string.lower("GetCommandsHTML")) then
		Response.ContentType = "HTML"
		Response.Data = GetCommandsHTML()
	elseif(QueryParams.url == string.lower("GetCommands")) then
		Response.ContentType = "JSON"
		Response.Data = GetDevices()
	elseif(QueryParams.url == string.lower("GetVariable")) then
		Response.ContentType = "JSON"
		Response.Data = {}
		Response.Data.DeviceID = QueryParams.deviceid
		Response.Data.VariableID = QueryParams.variableid
		Response.Data.VariableName = GetVariableName(Response.Data.DeviceID, Response.Data.VariableID)
		Response.Data.Value = GetVariable(Response.Data.DeviceID, Response.Data.VariableID)
	elseif(QueryParams.url == string.lower("SetVariable")) then
		Response.ContentType = "JSON"
		
		Response.Data = {}
		Response.Data.DeviceID = QueryParams.deviceid
		Response.Data.VariableID = QueryParams.variableid
		Response.Data.VariableName = GetVariableName(Response.Data.DeviceID, Response.Data.VariableID)
		SetVariable(Response.Data.DeviceID, Response.Data.VariableID, QueryParams.newvalue)
		Response.Data.Value = GetVariable(Response.Data.DeviceID, Response.Data.VariableID)
	elseif(QueryParams.url == string.lower("FireEvent")) then
		Response.ContentType = "JSON"
		Response.Data = {}
		Response.Data.EventID = QueryParams.eventid
		C4:FireEventByID(Response.Data.EventID);
	elseif(QueryParams.url == string.lower("SendCommand")) then
		Response.ContentType = "JSON"
		
		Response.Data = {}
		Response.Data.DeviceID = QueryParams.deviceid
		Response.Data.CommandName = QueryParams.commandname
		Response.Data.CommandArgs = C4:JsonDecode(C4:Base64Decode(QueryParams.commandargs))
		C4:SendToDevice(Response.Data.DeviceID, Response.Data.CommandName,{})
	else
		Response.StatusCode		= "404"
		Response.StatusText		= "NOT FOUND"
		Response.ContentType	= "TEXT"
		Response.Data					= "404 FILE NOT FOUND"
	end
	return Response
end

function DecodeURL(str)
	Debug("(((" .. str .. ")))")
	str = str:gsub('+', ' ')
	str = str:gsub('%%(%x%x)', function(h)
							return string.char(tonumber(h, 16))
							end)
	return str
end

function ParseRequest(recRequest)
	local _, _, url = string.find(recRequest, "GET /(.*) HTTP")
	url = url or ""
	DebugHeader("URL: " .. url)
	
	if (string.len(url) == 0) then
		return nil
	end

	local QueryParams = {}
	QueryParams.url = string.lower(url)
	if(string.find(QueryParams.url, "?") ~= nil) then
		QueryParams.url = string.sub(QueryParams.url, 1, string.find(QueryParams.url, "?") - 1)
	end
	Debug("FileURL: " .. QueryParams.url)
	url = url:gsub('?', '	', 1)
	url = url:match('%s+(.+)')
	

	if (url == '' or url == nil) then
		return QueryParams
	end

	for k,v in url:gmatch('([^&=?]-)=([^&=?]+)' ) do
		QueryParams[string.lower(k)] = DecodeURL(v)
	end
	return QueryParams
end


function GetCommandsXML()
	local Devices = GetDevices()
	local DevicesXML = "<xml>\r\n"
	for k, Device in pairs(Devices) do
		DevicesXML = DevicesXML .. "<device id=\"" .. Device.DeviceID .. "\" name=\"" .. Device.DeviceName .. "\" room=\"" .. Device.RoomName .. "\">\r\n"
		
			DevicesXML = DevicesXML .. "\t<variables>\r\n"
			for kv, Variable in pairs(Device.Variables) do
			DevicesXML = DevicesXML .. "\t\t<variable id=\"" .. Variable.VariableID .. "\" name=\"" .. Variable.VariableName .. "\" current_value=\"" .. C4:XmlEscapeString(Variable.CurrentValue) .. "\"/>\r\n"
			end
			DevicesXML = DevicesXML .. "\t</variables>\r\n"
		
		DevicesXML = DevicesXML .. "</device>\r\n"
	end
	DevicesXML = DevicesXML .. "</xml>"
	return DevicesXML
end

function GetCommandsHTML()
	local ControllerIP = C4:GetControllerNetworkAddress()
	local Devices = GetDevices()
	local DevicesHTML = "<html>\r\n"
	DevicesHTML = DevicesHTML .. "<head>\r\n"
	DevicesHTML = DevicesHTML .. "<title>Control4 WebEventsC4 Device List</title>\r\n"
	--DevicesHTML = DevicesHTML .. "<link rel=\"stylesheet\" href=\"https://" ..  ControllerIP .. "/driver/WebEventsAgent/style.css\">\r\n"
	
	DevicesHTML = DevicesHTML .. "<style>\r\n"
	DevicesHTML = DevicesHTML .. StyleSheet .. "\r\n"
	DevicesHTML = DevicesHTML .. "</style>\r\n"
	

	DevicesHTML = DevicesHTML .. "</head>\r\n"
	DevicesHTML = DevicesHTML .. "<body>\r\n"
	
	DevicesHTML = DevicesHTML .. "<h4>Agent Events</h4>\r\n"
	DevicesHTML = DevicesHTML .. "<ul>\r\n"
	GetMyEvents()
	for k,v in pairs(MyEvents) do
		DevicesHTML = DevicesHTML .. "<li>" .. v.EventName  .. ": <a href=\"" .. GetFireEventURL(v.EventID) .. "\">" .. GetFireEventURL(v.EventID) ..  "</a></li>\r\n"
	end
	DevicesHTML = DevicesHTML .. "</ul>\r\n"
	
	
	DevicesHTML = DevicesHTML .. '\t<table class="darkTable">\r\n'
	DevicesHTML = DevicesHTML .. "\t<thead>\r\n"
	DevicesHTML = DevicesHTML .. "\t<tr>\r\n"
	DevicesHTML = DevicesHTML .. "\t\t<th>Variable ID</th>\r\n"
	DevicesHTML = DevicesHTML .. "\t\t<th>Variable Name</th>\r\n"
	DevicesHTML = DevicesHTML .. "\t\t<th>Current Value</th>\r\n"
	DevicesHTML = DevicesHTML .. "\t\t<th>URLs</th>\r\n"
	DevicesHTML = DevicesHTML .. "\t</tr>\r\n"
	DevicesHTML = DevicesHTML .. "\t</thead>\r\n"
	DevicesHTML = DevicesHTML .. "\t<tbody>\r\n"
	
	for k, Device in pairs(Devices) do
		Debug("Generating Device: " .. Device.DeviceName)
		if(#Device.Variables > 0) then
			DevicesHTML = DevicesHTML .. "\t<tr>\r\n"
			DevicesHTML = DevicesHTML .. '<td class="DeviceName" colspan="4">[' .. Device.RoomName .. '] ' .. Device.DeviceName .. '(' .. Device.DeviceID .. '}</td>\r\n'
			DevicesHTML = DevicesHTML .. "\t</tr>\r\n"
			
			for kv, Variable in pairs(Device.Variables) do
				DevicesHTML = DevicesHTML .. "\t<tr>\r\n"
				DevicesHTML = DevicesHTML .. "\t\t<td>" .. Variable.VariableID .. "</td>\r\n"
				DevicesHTML = DevicesHTML .. "\t\t<td>" .. Variable.VariableName .. "</td>\r\n"
				DevicesHTML = DevicesHTML .. "\t\t<td>" .. Variable.CurrentValue .. "</td>\r\n"
				
				
				DevicesHTML = DevicesHTML .. '\t\t<td style="white-space: nowrap;">'
				DevicesHTML = DevicesHTML .. Variable.GetCommand
				
				if(Variable.SetCommand ~= nil) then
					DevicesHTML = DevicesHTML .. "<br />"
					DevicesHTML = DevicesHTML .. Variable.SetCommand
				end
				DevicesHTML = DevicesHTML .. "\t\t</td>\r\n"
				
				
				DevicesHTML = DevicesHTML .. "\t</tr>\r\n"
			end
			
		end
	end
	DevicesHTML = DevicesHTML .. "\t</tbody>\r\n"
	DevicesHTML = DevicesHTML .. "\t</table>\r\n"
	
	DevicesHTML = DevicesHTML .. "</body>\r\n"
	DevicesHTML = DevicesHTML .. "</html>"
	return DevicesHTML
end

function GetBaseURL()
	local ControllerIP = C4:GetControllerNetworkAddress()
	return string.lower(Properties['Server Mode']) .. "://" .. ControllerIP .. ":" .. Properties['Port'] .. "/"
end

function GetFireEventURL(EventID)
	return GetBaseURL() .. "FireEvent?PW=" .. Properties["Password"] .. "&EventID=" .. EventID
end

function GetDevices()
	local Devices = {}
	for DevID, DevProps in pairs(C4:GetDevices()) do
			local Device = {}
			Device.Variables = {}
			Device.Commands = {}
			Device.DeviceID = DevID
			Device.DeviceName = DevProps.deviceName
			Device.RoomName = DevProps.roomName
			
			--print(C4:GetDeviceData(Device.DeviceID))
			--print("----------------------")
			
			--local RoomContainer = C4:ListGetDeviceContainer(DevID)
			--print(DevID .. " - (" .. RoomContainer .. ") " .. DeviceName)
			for k,v in pairs(C4:GetDeviceVariables(DevID)) do
				local variableLine = " • " .. k .. " " .. v.name .. " [" .. v.value .. "]"
				local Variable = {}
				Variable.VariableID = k
				Variable.VariableName = v.name
				Variable.CurrentValue = v.value
				Variable.GetCommand = GetBaseURL() .. "GetVariable?PW=" .. Properties["Password"] .. "&DeviceID=" .. Device.DeviceID .. "&VariableID=" .. Variable.VariableID
				if(IsVariableReadOnly(Variable.VariableName) == false) then
					Variable.SetCommand = GetBaseURL() .. "SetVariable?PW=" .. Properties["Password"] .. "&DeviceID=" .. Device.DeviceID .. "&VariableID=" .. Variable.VariableID .. "&NewValue=[NEW_VALUE]"
				end
				
				table.insert(Device.Variables, Variable)
			 end
			 table.insert(Devices, Device)
		 --end
	 end
	 return Devices
end

VarsRO =	{
		"CURRENT_POWER", 
		"MINUTES_OFF",
		"MINUTES_ON",
		"OVER_RATED_WATTAGE",
		"SHORT_CIRCUIT_DETECTED",
		"MINUTES_ON_TODAY",
		"ENERGY_USED",
		"ENERGY_USED_TODAY",
		"OVER_TEMPERATURE",
		"FAN_SPEED",
		"CURRENT_SPEED",
		"",
		"",
		"",
		"",
		""
		}
		
function IsVariableReadOnly(VariableName)
	for k,v in pairs(VarsRO) do 
		if(v == VariableName) then
			return true
		end
	end
	return false
end


function SetVariable(DeviceID, VariableID, NewValue)
	if (NewValue == nil or NewValue == '0' or NewValue == '') then
		newValue = 0
	end
	
	C4:SetDeviceVariable(DeviceID, VariableID, NewValue)
end

function GetVariable(DeviceID, VariableID)
	return C4:GetDeviceVariable(DeviceID, VariableID)
end

function GetVariableName(DeviceID, VariableID)
	for k,v in pairs(C4:GetDeviceVariables(DeviceID)) do
		if(k == VariableID) then
			return v.name 
		end
	end
	return ""
end

StyleSheet = 
[[
table.darkTable {
  border: 2px solid #000000;
  background-color: #CBCBCB;
  width: 100%;
  height: 200px;
  text-align: center;
  border-collapse: collapse;
}
table.darkTable td, table.darkTable th {
  border: 1px solid #4A4A4A;
  padding: 3px 2px;
}

table.darkTable td.DeviceName {
  background-color: #5B5B5B;
  color: #FFFFFF;
}

table.darkTable tr:nth-child(even) {
  background: #A7A7A7;
}
table.darkTable thead {
  background: #570E0E;
}
table.darkTable thead th {
  font-size: 15px;
  font-weight: bold;
  color: #FFFFFF;
  text-align: center;
}
table.darkTable tfoot {
  font-size: 12px;
  font-weight: bold;
  color: #E6E6E6;
  background: #000000;
  border-top: 1px solid #4A4A4A;
}
table.darkTable tfoot td {
  font-size: 12px;
}
]]