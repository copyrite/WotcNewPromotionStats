class NewPromotionStats_MCMScreen extends Object config(NewPromotionStats_Settings);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;

`include(NewPromotionStats\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoIndexDropdownVars(ShowStatCurrent);
`MCM_API_AutoCheckboxVars(ShowStatDelta);
`MCM_API_AutoCheckboxVars(ShowEquipmentBonus);

`include(NewPromotionStats\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoIndexDropdownFns(ShowStatCurrent);
`MCM_API_AutoCheckboxFns(ShowStatDelta);
`MCM_API_AutoCheckboxFns(ShowEquipmentBonus);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);

	//Uncomment to enable reset
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);
	`MCM_API_AutoAddIndexDropdown(Group, ShowStatCurrent);
	`MCM_API_AutoAddCheckbox(Group, ShowStatDelta);
	`MCM_API_AutoAddCheckbox(Group, ShowEquipmentBonus);

	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	ShowStatCurrent = `GETMCMVAR(ShowStatCurrent);
	ShowStatDelta = `GETMCMVAR(ShowStatDelta);
	ShowEquipmentBonus = `GETMCMVAR(ShowEquipmentBonus);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoIndexReset(ShowStatCurrent);
	`MCM_API_AutoReset(ShowStatDelta);
	`MCM_API_AutoReset(ShowEquipmentBonus);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}
