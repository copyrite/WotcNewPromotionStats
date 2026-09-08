class UIHeroPromotionStats extends UIPanel config(NewPromotionStats);

struct StatsPositionProfile
{
	var name ProfileName;
	var bool IgnoreWoundedIfTall;

	var Vector2D Healthy;
	var Vector2D GravelyWounded;

	structdefaultproperties
	{
		IgnoreWoundedIfTall = true
	}
};

struct StatsDisplayMapping
{
	var name ScreenClass;
	var name PositionProfile;
};

var config array<StatsPositionProfile> PositionProfiles;
var config array<StatsDisplayMapping> DisplayMappings;

var config array<ECharStatType> StatsToShow;
var config array<ECharStatType> StatsWithCurrent;

var config int ShowStatCurrent;
var config bool ShowStatDelta;
var config bool ShowEquipmentBonus;

var UIPanel BG;
var UIX2PanelHeader Header;
var UIStatList StatsList;

var protectedwrite StateObjectReference UnitRef;
var protectedwrite name PositionProfile;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	SetWidth(240);

	BG = Spawn(class'UIPanel', self);
	BG.InitPanel('BG', class'UIUtilities_Controls'.const.MC_X2Background);
	BG.SetWidth(Width);

	Header = Spawn(class'UIX2PanelHeader', self);
	Header.InitPanelHeader('Header', "Stats");
	Header.SetHeaderWidth(Width - 20);
	Header.SetPosition(10, 10);

	StatsList = Spawn(class'UIStatList', self);
	StatsList.InitStatList('StatsList');
	StatsList.Width = Width;
	StatsList.PADDING_LEFT = 10;
	StatsList.PADDING_RIGHT = 10;
	StatsList.SetY(50);

	return self;
}

simulated function OnScreenStackChanged()
{
	FetchUnitFromTopmostArmory();
	FetchCurrentPositionProfile();

	if (UnitRef.ObjectID == 0 || PositionProfile == '')
	{
		Hide();
	}
	else
	{
		StatsList.RefreshData(GetStats(), false);
		
		BG.SetHeight(StatsList.Y + StatsList.Height + 20);
		UpdatePositionFromProfile();

		AnimateIn();
		Show();
	}
}

simulated protected function FetchUnitFromTopmostArmory()
{
	local UIScreen CurrentScreen;
	local UIArmory Armory;

	UnitRef.ObjectID = 0;

	foreach `SCREENSTACK.Screens(CurrentScreen)
	{
		Armory = UIArmory(CurrentScreen);

		if (Armory != none)
		{
			UnitRef = Armory.UnitReference;
			break;
		}
	}
}

simulated protected function FetchCurrentPositionProfile()
{
	local StatsDisplayMapping Mapping;
	local UIScreen CurrentScreen;
	local name ClassName;
	local int i;

	CurrentScreen = `SCREENSTACK.GetCurrentScreen();

	foreach DisplayMappings(Mapping)
	{
		if (CurrentScreen.IsA(Mapping.ScreenClass))
		{
			PositionProfile = Mapping.PositionProfile;

			if (PositionProfiles.Find('ProfileName', PositionProfile) == INDEX_NONE)
			{
				`RedScreen("UIHeroPromotionStats mapping for" @ Mapping.ScreenClass @ "uses" @ PositionProfile @ "which does not exist");
				PositionProfile = '';
			}

			return;
		}
	}

	PositionProfile = '';
}

simulated protected function UpdatePositionFromProfile()
{
	local StatsPositionProfile Profile;
	local XComGameState_Unit Unit;
	local Vector2D Position;

	Profile = PositionProfiles[PositionProfiles.Find('ProfileName', PositionProfile)];
	Unit = GetUnit();

	// Better check: try Pawn.GetHeadLocation(), and compare it to the Pawn.Location
	if (!Unit.IsGravelyInjured() || (Profile.IgnoreWoundedIfTall && Unit.GetMyTemplate().UnitHeight > 2))
	{
		Position = Profile.Healthy;
	}
	else
	{
		Position = Profile.GravelyWounded;
	}

	SetPosition(Position.X, Position.Y);
}

////////////
/// Data ///
////////////

simulated function array<UISummary_ItemStat> GetStats()
{
	local array<UISummary_ItemStat> Stats;
	local ECharStatType Stat;
	local UISummary_ItemStat StatsEntry;
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if (Unit == none)
	{
		Stats.Length = 0;
		return Stats;
	}

	foreach default.StatsToShow(Stat)
	{
		switch (Stat)
		{
			case eStat_ArmorMitigation:
				StatsEntry.Label = class'UISoldierHeader'.default.m_strArmorLabel;
				break;
			default:
				StatsEntry.Label = class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[Stat];
		}

		StatsEntry.Value = FormatStat(Stat);

		switch (Stat)
		{
			case eStat_HP:
				StatsEntry.ValueState = EUIState(Unit.GetStatusUIState());
				break;
			case eStat_Will:
				StatsEntry.ValueState = Unit.GetMentalStateUIState();
				break;
			default:
				StatsEntry.ValueState = eUIState_Normal;
		}

		Stats.AddItem(StatsEntry);
	}


	return Stats;
}

simulated function int GetStatCurrent(ECharStatType Stat)
{
	local XComGameState_Unit Unit;

	Unit = GetUnit();

	return int(Unit.GetCurrentStat(Stat)) + Unit.GetUIStatFromAbilities(Stat);
}

simulated function int GetStatMax(ECharStatType Stat)
{
	return GetUnit().GetMaxStat(Stat);
}

simulated function int GetStatDelta(ECharStatType Stat)
{
	local int BaseStat, UnitStat, ProgressedStat, Rank, i, j;
	local array<SoldierClassStatType> StatProgression;

	UnitStat = GetStatMax(Stat);
	BaseStat = int(GetUnit().GetMyTemplate().CharacterBaseStats[Stat]);
	ProgressedStat = BaseStat;
	Rank = GetUnit().GetRank();

	for (i = 0; i < Rank; i++)
	{
		StatProgression = GetUnit().GetSoldierClassTemplate().GetStatProgression(i);
		for (j = 0; j < StatProgression.Length; j++)
		{
			if (StatProgression[j].StatType == Stat)
			{
				ProgressedStat += StatProgression[j].StatAmount;
			}
		}
	}

	return UnitStat - ProgressedStat;
}

simulated function string FormatStat(ECharStatType Stat)
{
	return FormatStatCurrent(Stat) $ string(GetStatMax(Stat)) $ FormatStatDelta(Stat) $ FormatEquipmentBonus(Stat);
}

simulated function string FormatStatCurrent(ECharStatType Stat)
{
	local int Current;

	Current = GetStatCurrent(Stat);

	// Never show
	if (default.ShowStatCurrent == 0)
	{
		return "";
	}

	// Don't show if not specific current
	if (default.StatsWithCurrent.Find(Stat) == INDEX_NONE)
	{
		return "";
	}

	// Always show
	if (default.ShowStatCurrent == 1)
	{
		return Current $ "/";
	}

	// Show if different
	if (Current != GetStatMax(Stat))
	{
		return Current $ "/";
	}

	return "";

}

simulated function string FormatStatDelta(ECharStatType Stat)
{
	local int Delta;

	if (!default.ShowStatDelta)
	{
		return "";
	}

	Delta = GetStatDelta(Stat);

	if (Delta == 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText("(+0)", eUIState_Normal);
	}

	if (Delta >= 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText("(+" $ Delta $ ")", eUIState_Good);
	}

	return class'UIUtilities_Text'.static.GetColoredText("(" $ Delta $ ")", eUIState_Bad);
}

simulated function string FormatEquipmentBonus(ECharStatType Stat)
{
	local int Bonus;

	if (!default.ShowEquipmentBonus)
	{
		return "";
	}

	Bonus = GetUnit().GetUIStatFromInventory(Stat);

	if (Bonus > 0)
	{
		 return class'UIUtilities_Text'.static.GetColoredText("+" $ string(Bonus), eUIState_Good);
	}

	if (Bonus < 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText(string(Bonus), eUIState_Bad);
	}

	return "";
}

simulated function XComGameState_Unit GetUnit()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

/////////////////
/// Animation ///
/////////////////

simulated function AnimateIn(optional float Delay = 0)
{
	local TUIStatList_Item StatItem;

	BG.AnimateIn(Delay + class'UIUtilities'.const.INTRO_ANIMATION_TIME);
	Delay += class'UIUtilities'.const.INTRO_ANIMATION_TIME;

	Header.AnimateIn(Delay + class'UIUtilities'.const.INTRO_ANIMATION_TIME);
	Delay += class'UIUtilities'.const.INTRO_ANIMATION_TIME;

	foreach StatsList.Items(StatItem)
	{
		StatItem.BG.AnimateIn(Delay + class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX);
		StatItem.Label.AnimateIn(Delay + class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX);
		StatItem.Value.AnimateIn(Delay + class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX);

		Delay += class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX;
	}
}

defaultproperties
{
	MCName = "HeroPromotionStats"
	bAnimateOnInit = false;
}