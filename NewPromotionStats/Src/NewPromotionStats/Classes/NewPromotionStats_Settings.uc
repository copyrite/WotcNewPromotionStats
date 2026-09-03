class NewPromotionStats_Settings extends UIScreenListener config(NewPromotionStats_Settings);

`include(NewPromotionStats/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(NewPromotionStats/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool CHECKBOX_VALUE;
var config int CONFIG_VERSION;

event OnInit(UIScreen Screen)
{
    if (MCM_API(Screen) != none)
    {
        `MCM_API_Register(Screen, ClientModCallback);
    }
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;

    LoadSavedSettings();

    Page = ConfigAPI.NewSettingsPage("Label");
    Page.SetPageTitle("Title");
    Page.SetSaveHandler(SaveButtonClicked);

    Group = Page.AddGroup('Group', "General Settings");

    Group.AddCheckbox('checkbox', "Example Checkbox", "Example Checkbox Tooltip", CHECKBOX_VALUE, CheckboxSaveHandler);
}

`MCM_CH_VersionChecker(class'NewPromotionStats_Settings_Defaults'.default.VERSION, CONFIG_VERSION)

simulated function LoadSavedSettings()
{
    CHECKBOX_VALUE = `MCM_CH_GetValue(class'NewPromotionStats_Settings_Defaults'.default.SETTING, CHECKBOX_VALUE);
}

`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandler, CHECKBOX_VALUE)

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}

defaultproperties
{
    ScreenClass = none;
}
