local Http = game:GetService("HttpService")

local module = {}

module.apiKey = "YOUR API KEY"

module.groups = {}

local function dateTimeToString(dateTime)
	local year = dateTime.Year
	local month = dateTime.Month
	local day = dateTime.Day
	local hour = dateTime.Hour
	local minute = dateTime.Minute
	local second = dateTime.Second
	local millisecond = dateTime.Millisecond

	return string.format("%02d:%02d:%04d %02d:%02d:%02d:%03d", day, month, year, hour, minute, second, millisecond)
end

local function sendPatchRequest(url, apiKey, data)

	local jsonData = Http:JSONEncode(data)

	local headers = {
		["Content-Type"] = "application/json",
		["x-api-key"] = apiKey
	}

	local request = {
		Url = url,
		Method = "PATCH",
		Headers = headers,
		Body = jsonData
	}
  
	local success, response = pcall(function()
		return Http:RequestAsync(request)
	end)
  
	if success then
		return response.StatusCode, response.Body
	else
		error("Request failed: " .. tostring(response))
	end
end

local function sendPostRequest(url, apiKey, data)

	local jsonData = Http:JSONEncode(data)
	local headers = {
		["Content-Type"] = "application/json",
		["x-api-key"] = apiKey
	}

	local request = {
		Url = url,
		Method = "POST",
		Headers = headers,
		Body = jsonData
	}

	local success, response = pcall(function()
		return Http:RequestAsync(request)
	end)
	
	if success then
		return response.StatusCode, Http:JSONDecode(response.Body)
	else
		error("Request failed: " .. tostring(response))
	end
end

local function sendGetRequest(url, apiKey)

	local headers = {
		["x-api-key"] = apiKey
	}

	local request = {
		Url = url,
		Method = "GET",
		Headers = headers
	}

	local success, response = pcall(function()
		return Http:RequestAsync(request)
	end)

	if success then
		return response.StatusCode, Http:JSONDecode(response.Body)
	else
		error("Request failed: " .. tostring(response))
	end
end

function module.loadGroup(groupId:string)
	local roles = {}
	local memberships = {}
	local code, groupInfo = sendGetRequest("https://apis.roproxy.com/cloud/v2/groups/"..groupId, module.apiKey)
	local code, roleInfo = sendGetRequest("https://apis.roproxy.com/cloud/v2/groups/"..groupId.."/roles?maxPageSize=100", module.apiKey)
	local code, membershipInfo = sendGetRequest("https://apis.roproxy.com/cloud/v2/groups/"..groupId.."/memberships?maxPageSize=100", module.apiKey)	
	-- ROLE LOADING --
	for i, v in pairs(roleInfo.groupRoles) do
		roles[v.id] = {["rolePath"] = v.path, ["rank"] = v.rank, ["name"] = v.displayName, ["description"] = v.description, ["memberCount"] = v.memberCount}
	end
	
	-- MEMBERSHIP LOADING --
	for i, v in pairs(membershipInfo.groupMemberships) do
		memberships[string.split(v.user, "/")[2]] = {["user"] = v.user, ["membershipPath"] = v.path, ["roleId"] = string.split(v.role, "/")[4], ["joined"] = dateTimeToString(DateTime.fromIsoDate(v.createTime):ToUniversalTime())}
	end
	-- MORE ROLE LOADING --
	local nextRoleToken = roleInfo.nextPageToken
	while nextRoleToken ~= "" do
		local code, roleInfo =  sendGetRequest("https://apis.roproxy.com/cloud/v2/groups/"..groupId.."/roles?maxPageSize=100&pageToken="..nextRoleToken, module.apiKey)
		for i, v in pairs(roleInfo.groupRoles) do
			roles[v.id] = {["rolePath"] = v.path, ["rank"] = v.rank, ["name"] = v.displayName, ["description"] = v.description, ["memberCount"] = v.memberCount}
		end
		nextRoleToken = roleInfo.nextPageToken
	end
	-- MORE MEMBERSHIP LOADING --
	local nextMembershipToken = membershipInfo.nextPageToken
	while nextMembershipToken ~= "" do
		local code, membershipInfo =  sendGetRequest("https://apis.roproxy.com/cloud/v2/groups/"..groupId.."/memberships?maxPageSize=100&pageToken="..nextMembershipToken, module.apiKey)
		for i, v in pairs(membershipInfo.groupMemberships) do
			memberships[string.split(v.user, "/")[2]] = {["user"] = v.user, ["membershipPath"] = v.path, ["roleId"] = string.split(v.role, "/")[4], ["joined"] = dateTimeToString(DateTime.fromIsoDate(v.createTime):ToUniversalTime())}
		end
		nextMembershipToken = membershipInfo.nextPageToken
	end
	
	local group = {
		["name"] = groupInfo.displayName,
		["description"] = groupInfo.description,
		["ownerId"] = string.split(groupInfo.owner, "/")[2],
		["memberCount"] = groupInfo.memberCount,
		["roles"] = roles,
		["memberships"] = memberships
	}
	function group:getRoleByRank(rank:string)
		for i, item in pairs(self.roles) do
			if tostring(item.rank) == rank then
				return item
			end
		end
		warn("Failed to find a role for rank "..rank.."!")
	end
	function group:updateUserRole(userId:string, rank:string)
		local membership = self.memberships[userId]
		local role = self:getRoleByRank(rank)
		if not membership then error("User "..userId.." not found in group!") end
		if not role then error("Role with rank "..rank.." not found in group!") end
		local code, response = sendPatchRequest("https://apis.roproxy.com/cloud/v2/"..membership.membershipPath, module.apiKey, {["user"] = membership.user, ["role"] = role.rolePath})
		if code == 200 then
			print("Successfully changed "..membership.user.." role to "..role.name.."!")
			return true
		else
			error("Failed to change "..membership.user.." role to "..role.name.."!")
			return false
		end
	end
	
	module.groups[groupId] = group
	return module.groups[groupId]
end

return module
