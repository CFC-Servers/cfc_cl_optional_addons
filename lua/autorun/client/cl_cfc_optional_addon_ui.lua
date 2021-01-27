
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
