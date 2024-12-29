CFC_ClientAddonLoader = CFC_ClientAddonLoader or {}
CFC_ClientAddonLoader.allowedAddons = CFC_ClientAddonLoader.allowedAddons or {}
local allowedAddons = CFC_ClientAddonLoader.allowedAddons

allowedAddons["888392108"] = true -- Dark UI https://steamcommunity.com/sharedfiles/filedetails/?id=888392108
allowedAddons["246363312"] = true -- Cookie Clicker https://steamcommunity.com/sharedfiles/filedetails/?id=246363312
allowedAddons["1621144907"] = true -- Prop info hud https://steamcommunity.com/sharedfiles/filedetails/?id=2573011318
allowedAddons["1452363997"] = true -- compass https://steamcommunity.com/sharedfiles/filedetails/?id=1452363997
allowedAddons["1805621283"] = true -- dynamic 3d hud https://steamcommunity.com/sharedfiles/filedetails/?id=1805621283
allowedAddons["2954934766"] = true -- Half-Life 2 Customizable HUD https://steamcommunity.com/sharedfiles/filedetails/?id=2954934766
allowedAddons["3393341038"] = true -- Overhead Chat Bubbles https://steamcommunity.com/sharedfiles/filedetails/?id=3393341038

local function mountAddon( id )
    if HotLoad then
        return HotLoad.LoadAddon( id )
    end
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
                RunString( code, "CFC_ClAddonLoader_" .. id .. ".lua" )
            end
        end
    end )
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

-- UI
local checkboxes = {}

local function populatePanel( form )
    -- make checkboxes
    for id in pairs( CFC_ClientAddonLoader.allowedAddons ) do
        local checkbox = form:CheckBox( "N/A" )
        checkbox.addonId = id
        checkbox:SetChecked( CFC_ClientAddonLoader.enabledAddons[id] == true )

        steamworks.FileInfo( id, function( result )
            checkbox.Label:SetText( string.format( "%s : %s", result.title, id ) )
            checkbox.Label:SizeToContents()
        end )
        table.insert( checkboxes, checkbox )
    end

    -- make apply button
    local button = form:Button( "Apply" )
    function button:DoClick()
        for _, checkbox in pairs( checkboxes ) do
            if checkbox:GetChecked() then
                CFC_ClientAddonLoader.enableAddon( checkbox.addonId )
            else
                CFC_ClientAddonLoader.disableAddon( checkbox.addonId )
            end
        end
        CFC_ClientAddonLoader.saveEnabledAddons()
    end

    form:Help( "* Restart is required when disabling addons" )
end

hook.Add( "AddToolMenuCategories", "CFC_OptionalAddons_AddMenuCategory", function()
    spawnmenu.AddToolCategory( "Options", "OptionalAddons", "Optional Addons" )
end )

hook.Add( "PopulateToolMenu", "CFC_OptionalAddons_CreateOptionsMenu", function()
    spawnmenu.AddToolMenuOption( "Options", "OptionalAddons", "optional_addons", "OptionalAddons", "", "", function( panel )
        populatePanel( panel )
    end )
end )
