
local checkboxes = {}

local function populatePanel( form )
    -- make  checkboxes
    for id, _ in pairs( CFC_ClientAddonLoader.allowedAddons ) do
        
        local checkbox = form:CheckBox( "Name loading" )
        checkbox.addonId = id
        checkbox:Dock( FILL )
        checkbox:SetChecked( CFC_ClientAddonLoader.enabledAddons[id] == true )
        steamworks.FileInfo( id, function( result ) 
            checkbox.Label:SetText( string.format("%s : %s", result.title, id) )
            checkbox.Label:SizeToContents()
            
        end )
        
        table.insert(checkboxes, checkbox)
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
makeForm()

hook.Add( "AddToolMenuCategories", "CFC_HTTP_ListManager", function()
    spawnmenu.AddToolCategory( "Options", "OptionalAddons", "Optional Addons" )
end )
hook.Add( "PopulateToolMenu", "CFC_HTTP_ListManager", function()
    spawnmenu.AddToolMenuOption( "Options", "OptionalAddons", "optional_addons", "OptionalAddons", "", "", function( panel )
        populatePanel( panel )
    end )
end )