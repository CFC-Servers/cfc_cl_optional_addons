CFC_ClientAddonLoader = CFC_ClientAddonLoader or {}
CFC_ClientAddonLoader.allowedAddons = CFC_ClientAddonLoader.allowedAddons or {}
local allowedAddons = CFC_ClientAddonLoader.allowedAddons

allowedAddons["888392108"] = true -- Dark UI https://steamcommunity.com/sharedfiles/filedetails/?id=888392108
allowedAddons["246363312"] = true -- Cookie Clicker https://steamcommunity.com/sharedfiles/filedetails/?id=246363312
allowedAddons["1621144907"] = true -- Prop info hud https://steamcommunity.com/sharedfiles/filedetails/?id=2573011318

local function mountAddon( id )
    steamworks.DownloadUGC( id, function( name )
        local success, files = game.MountGMA( name )
        if not success then
            print( "[CL ADDON LOADER] Failed mounting gma", id, name )
        end

        for _, filename in pairs( files ) do
            local isAutorun = string.match( filename, "^lua/autorun/.*%.lua" )
            local isServer = string.StartWith( filename, "lua/autorun/server" )
            if isAutorun and not isServer then
                print( "[CL ADDON LOADER] filename, running: ", filename )

                local code = file.Read( filename, "WORKSHOP" )
                RunString( code, "CFC_ClAddonLoader_" .. id )
            end
        end
    end)
end

CFC_ClientAddonLoader.enabledAddons = CFC_ClientAddonLoader.enabledAddons or {}
local enabledAddons = CFC_ClientAddonLoader.enabledAddons

function CFC_ClientAddonLoader.enableAddon( id )
    if not allowedAddons[id] then return end
    mountAddon( id )
    enabledAddons[id] = true
end

function CFC_ClientAddonLoader.disableAddon( id )
    enabledAddons[id] = nil
end

function CFC_ClientAddonLoader.saveEnabledAddons()
    local f = file.Open( "cfc_enabled_clientside_addons.json", "w", "DATA" )
    for id in pairs( enabledAddons ) do
        f:Write( id .. "\n" )
    end
    f:Close()
end

function CFC_ClientAddonLoader.loadEnabledAddons()
    local data = file.Read( "cfc_enabled_clientside_addons.json", "DATA" )
    if data == nil then return end
    local lines = string.Split( data, "\n" )
    for _, line in pairs( lines ) do
        local id = string.Trim( line )
        local allowed = allowedAddons[id] and #id > 0
        if allowed then
            CFC_ClientAddonLoader.enableAddon( id )
        end
    end
end

hook.Add( "Think", "CFC_ClAddonLoader_LoadAddons", function()
    hook.Remove( "Think", "CFC_ClAddonLoader_LoadAddons" )
    CFC_ClientAddonLoader.loadEnabledAddons()
end )
