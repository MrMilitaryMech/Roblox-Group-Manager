# Roblox-Group-Manager
Can be used to manage groups from directly in the game.

## Setup
1. Make an API key at https://create.roblox.com/dashboard/credentials?activeTab=ApiKeysTab
2. Give the API key the following permissions: `group:read` & `group:write`
3. Copy the API key and add it into `module.apiKey`

## What can it do?
This module was specifically made for chaging a user's roles, and so it is quite limited in what it can do.
You can:
- Load group stats e.g member count, name and description
- Load all group memberships and roles
- Change a user's role using user ID and rank

### How to use:
#### Group:
- name - Group name - string
- description - Group description - string
- memberCount - Group member count - number
- ownerId - Owner User ID - string
- roles - Table of roles - roles[roleId]
- memberships - Table of memberships - memberships[userId]
- getRoleByRank(rank:string)
- updateUserRole(userId:string, rank:string)
#### Role:
- name - Role name - string
- rank - Role rank - number
- description - Role description - string
- memberCount - Role member count
```lua
local module = require(game.ServerScriptService.ModuleScript)
local group = module.loadGroup("groupId")

local role = group:getRoleByRank("254") -- Usually admin role

group:updateUserRole("userId", "254") -- Uses user ID and rank ID
```
