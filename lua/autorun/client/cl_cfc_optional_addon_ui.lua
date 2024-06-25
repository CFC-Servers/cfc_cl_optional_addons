CFC_ClientAddonLoader = CFC_ClientAddonLoader or {}
CFC_ClientAddonLoader.allowedAddons = CFC_ClientAddonLoader.allowedAddons or {}
local allowedAddons = CFC_ClientAddonLoader.allowedAddons

allowedAddons["888392108"] = true -- Dark UI https://steamcommunity.com/sharedfiles/filedetails/?id=888392108
allowedAddons["246363312"] = true -- Cookie Clicker https://steamcommunity.com/sharedfiles/filedetails/?id=246363312
allowedAddons["1621144907"] = true -- Prop info hud https://steamcommunity.com/sharedfiles/filedetails/?id=2573011318
allowedAddons["1452363997"] = true -- compass https://steamcommunity.com/sharedfiles/filedetails/?id=1452363997
allowedAddons["1805621283"] = true -- dynamic 3d hud https://steamcommunity.com/sharedfiles/filedetails/?id=1805621283

__CFCLoaderLocalPath = ""

local function normalizePath(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        if part == ".." then
            table.remove(parts)
        elseif part ~= "." then
            table.insert(parts, part)
        end
    end
    return table.concat(parts, "/")
end

local function removeLayer( fileName )
    for i = #fileName - 1, 1, -1 do
        if fileName[i] == "/" or fileName[i] == "\\" then return string.sub( fileName, 1, i ) end
    end
end

local oldInclude = oldInclude or include
include = function( fileName )
    -- print( "including " .. fileName )
    local info = debug.getinfo( 2 )
    if string.StartsWith( info.short_src, "CFC_ClAddonLoader" ) then
        -- TODO: Make sure that the bit below actually handles .. correctly
        local isTraversing = fileName:find( "%.%." ) ~= nil
        if isTraversing then
            local addonDirectory = debug.getinfo( 2, "S" ).source:sub( 2 )
            addonDirectory = addonDirectory:gsub( "[^/]+/", "", 3 )
            addonDirectory = addonDirectory:gsub( "/[^/]+$", "" )
            fileName = normalizePath( string.format( "%s/%s", addonDirectory, fileName ) )
        end
        -- print( __CFCLoaderLocalPath )
        local code = file.Read( fileName, "WORKSHOP" )
        if code then
            print( "[CL ADDON LOADER] filename, including: ", fileName )
            local oldPath = __CFCLoaderLocalPath
            __CFCLoaderLocalPath = removeLayer( fileName )
            RunString( code, "CFC_ClAddonLoader_" .. fileName )
            __CFCLoaderLocalPath = oldPath
            return
        end
        fileName = __CFCLoaderLocalPath .. fileName
        code = file.Read( fileName, "WORKSHOP" )
        if code then
            print( "[CL ADDON LOADER] filename, including: ", fileName )
            local oldPath = __CFCLoaderLocalPath
            __CFCLoaderLocalPath = removeLayer( fileName )
            RunString( code, "CFC_ClAddonLoader_" .. fileName )
            __CFCLoaderLocalPath = oldPath
            return
        end
        print( "[CL ADDON LOADER] Failed including " .. fileName )
    else
        oldInclude( fileName )
    end
end

local function validFile( filename )
    if !string.StartsWith( filename, "lua/autorun/" ) then return false end
    local paths = string.Split( filename, "/" )
    return paths[ 3 ] != "client" and !paths[ 4 ] or paths[ 3 ] == "client" and !paths[ 5 ] -- Make sure that files outside of /autorun/ and /autorun/client/ don't get executed (including subdirectories!)
end

local function mountAddon( id )
    steamworks.DownloadUGC( id, function( name )
        local success, files = game.MountGMA( name )
        if not success then
            print( "[CL ADDON LOADER] Failed mounting gma", id, name )
        end

        for _, filename in pairs( files ) do
            if validFile( filename ) then
                print( "[CL ADDON LOADER] filename, running: ", filename )

                __CFCLoaderLocalPath = "lua/autorun/"
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
    spawnmenu.AddToolMenuOption( "Options", "OptionalAddons", "optional_addons", "Optional Addons", "", "", function( panel )
        populatePanel( panel )
    end )
end )
