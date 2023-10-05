--[DEBUGGING HELPER FUNCTIONS]--
DebugTimerID	= 0

function StartDebugTimer()
	if (DebugTimerID ~= 0) then
		DebugTimerID = C4:KillTimer(DebugTimerID)
	end
		DebugTimerID = C4:AddTimer(120, "MINUTES")
end


function DebugLevel(DebugText, Level)
	dbg(string.rep("	", Level) .. DebugText)
end

function Debug(DebugText)
		if type(DebugText) == 'table' then
			DebugTable(DebugText)
		else
			dbg(DebugText)
		end
end

function DebugTable(DebugT)
	--print("@@@@@@@@@@@@@@@@@@@@@")
	dbg(C4:JsonEncode(DebugT, true, true))
	--local s = '{ '
	--for k,v in pairs(o) do
	--if type(k) ~= 'number' then k = '"'..k..'"' end
		  --s = s .. '['..k..'] = ' .. dump(v) .. ','
	--end
	--return s .. '} '
end

function DebugHeader(DebugText)
		local BorderLen = 2
		local TextLen = DebugText:len()
		dbg(string.rep("-", TextLen + (BorderLen * 2)))
		dbg("| " .. DebugText .. " |")
		dbg(string.rep("-", TextLen + (BorderLen * 2)))
end

function DebugDivider(DividerChar)
		dbg(string.rep(DividerChar, 50))
end