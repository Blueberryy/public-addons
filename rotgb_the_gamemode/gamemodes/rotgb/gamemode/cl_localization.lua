AccessorFunc(GM, "CachedLocalizations", "CachedLocalizations")

function GM:GetLocalizedString(token, ...)
	local pieces = {["%"] = "%"}
	for k,v in pairs({...}) do
		pieces[string.format("%i", k)] = v
	end
	return string.gsub(language.GetPhrase(token), "%%(.)", pieces)
end

--[[function GM:GetCreatedOrCachedLocalizedString(token, ...)
	if not hook.Run("GetCachedLocalizations") then
		hook.Run("GetCachedLocalizations", {})
	end
	local cache = hook.Run("GetCachedLocalizations")
	if not cache[token] then
		cache[token] = hook.Run("GetLocalizedString", token, ...)
	end
	return cache[token]
end

function GM:ResetCachedLocalizedString(token)
	local cache = hook.Run("GetCachedLocalizations") 
	if cache then
		cache[token] = nil
	end
end

function GM:GetCachedLocalizedString(token)
	local cache = hook.Run("GetCachedLocalizations")
	if cache then
		return cache[token]
	end
end]]

-- TODO PZDraw: nestability
function GM:GetLocalizedMulticoloredString(token, replacements, defaultColor, replacementColors)
	local returnTable = {}
	local translationTable = string.ExplodeIncludeSeperators("%%.", language.GetPhrase(token), true)
	for i,v in ipairs(translationTable) do
		if i%2==0 then
			local token = string.match(v, "%%(.)")
			if token == "%" then
				table.insert(returnTable, "%")
			else
				token = tonumber(token)
				if token then
					table.insert(returnTable, replacementColors[token])
					table.insert(returnTable, replacements[token])
				end
			end
		else
			table.insert(returnTable, defaultColor)
			table.insert(returnTable, v)
		end
	end
	return returnTable
end