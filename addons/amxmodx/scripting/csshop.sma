/*
	ChangeLog:
	
	v1.0
	- First Release
	
	v1.5
	- Converted some things to fakemeta
	- Fixed some menus
	
	v2.0
	- Added more menus
	- Added more stocks
	
	v3.0
	- Fixed Menu bugs
	- Fixed Model reset
	- Added new Cvars
	- Added ML Support
	
	v3.5
	- Added cstrike module for the skins
	- Added customizable cfg with cvars
	
	v3.6   
	- Fixed rendering bug with the invisibility menu
	
	v3.7
	- Fixed some fakemeta & cstrike convertions
	
	v3.8
	- Added ML Translations

	v4.0
	- Replaced all with fakemeta and ham modules
	- Fixed a ML Bug
	- Fixed some stocks (thanks to Exolent)
		
	v4.0a
	- Added: is the user alive to open the menu ? 
	- is the plugin enabled to show the msg ?
		
	v4.0b
	- Changed: Ham_Spawn to Post hook (Thanks ConnorMcLeod)
	
	v4.2
	- Now the Fakemeta Utilities are included
	- Removed the Fakemeta Utilities stocks
	- Added one more menu (Speed menu)
	- Added more cvars
	- Updated Multi-Lingual Translations
	
	v4.5
	- The items can be disabled if you set the item cvar to 0
	- Now plugin supports Unlimited Money by Ramono
	- Huge update on the Multi-Lingual translations (sorry translators)
	
	v5.0
	- All Menus Updated using global variables to store the name-weapons-other data
	- CStrike and Fun Modules restored (efficiency > fakemeta conversions)
	
	------------------------------------------------------------------------
	
	Cvar List:
	
	// Main Cvars
	amx_shop_enable	1/0 - Enable / Disable CS Shop (Default: 1)
	amx_shop_msg	1/0 - Enable / Disable CS Shop Message (Default: 1)
	amx_shop_prefix	    - CS Shop Messages Prefix (Default: [CS Shop])
	
	// CT's Guns Menu
	amx_shop_ct	1/0 - Enable / Disable CT's Guns Menu (Default: 1)
	amx_shop_m4a1	    - M4A1 Cost (Default: 3100)
	amx_shop_bullpup    - BullPup Cost (Default: 3500)
	amx_shop_tmp	    - TMP Cost (Default: 1250)
	amx_shop_fiveseven  - Five Seven Cost (Default: 750)
	amx_shop_famas      - Famas Cost (Default: 2250)
	amx_shop_shield     - Shield Cost (Default: 2200)
	
	// T's Guns Menu
	amx_shop_t	1/0 - Enable / Disable T's Guns Menu (Default: 1)
	amx_shop_ak47	    - Ak 47 Cost (Default: 2500)
	amx_shop_sg552	    - Sg552 Cost (Default: 3500)
	amx_shop_mac10	    - Mac 10 Cost (Default: 1400)
	amx_shop_elites	    - Dual Elites Cost (Default: 800)
	amx_shop_galil      - Galil Cost (Default: 2000)
	
	// Invisibility Menu
	amx_shop_invis	1/0 - Enable / Disable Invisibility Menu (Default: 1)
	amx_shop_low	    - Low Invisibility Cost (still visible) (Default: 3000)
	amx_shop_medium     - Medium Invisibility Cost (semiclip) (Default: 6000)
	amx_shop_high	    - High Invisibility Cost (almost invisible) (Default: 12000)
		
	// Gravity Menu
	amx_shop_grav	1/0 - Enable / Disable Gravity Menu (Default: 1)
	amx_shop_g500	    - 500 Gravity Cost (Default: 1500)
	amx_shop_g400       - 400 Gravity Cost (Default: 3000)
	amx_shop_g300       - 300 Gravity Cost (Default: 4500)
	amx_shop_g200       - 200 Gravity Cost (Default: 6000)
		
	// Health Menu
	amx_shop_hp	1/0 - Enable / Disable Health Menu (Default: 1)
	amx_shop_15hp	    - +15 Health Cost (Default: 1500)
	amx_shop_35hp       - +35 Health Cost (Default: 3000)
	amx_shop_65hp       - +65 Health Cost (Default: 6000)
	amx_shop_95hp       - +95 Health Cost (Default: 7500)
	
	// Speed Menu
	amx_shop_speed 	1/0 - Enable / Disable Speed Menu (Default: 1)
	amx_shop_260speed   - 260 MaxSpeed Cost (Default: 3000)
	amx_shop_300speed   - 300 MaxSpeed Cost (Default: 6000)
	amx_shop_340speed   - 340 MaxSpeed Cost (Default: 9000)
	amx_shop_380speed   - 380 MaxSpeed Cost (Default: 12000)
	amx_shop_420speed   - 420 MaxSpeed Cost (Default: 15000)

	// Skins Menu
	amx_shop_skins 	1/0 - Enable / Disable Skins Menu (Default: 1)
	amx_shop_tskin	    - Terrorist Skin Cost (Default: 9000)
	amx_shop_ctskin	    - Counter-Terrorist Skin Cost (Default: 9000) 

	---------------------------------------------------------------------
	
	Credits:
	
	PvtSmithFSSF 	- Original idea, Principal Code
	VEN 		- Fakemeta Utilities
	Dr. Jan Itor 	- Gravity Menu help
	Minimiller 	- Lot of things
	MeRcyLeZZ 	- For his svc_bad and models tutorial (Tutorial Link)
	ConnorMcLeod 	- Little fix with user spawn ^.^
	XxAvalanchexX 	- Some code of the gungame colored print
	
	---------------------------------------------------------------------
	
	Plugin Thread: http://forums.alliedmods.net/showthread.php?t=78224
	Licensed under the GPL - http://www.gnu.org/copyleft/gpl.html
	
	---------------------------------------------------------------------
*/  

// Uncomment this to enable Unlimited Money support by Ramono
//#define UL_COMPAT

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#if defined UL_COMPAT
	#include <money_ul>
#endif

/*================================================================================
 [Defines & Variables]
=================================================================================*/

// Plugin Info
#define PLUGIN_NAME "CS Shop"
#define PLUGIN_VERS "5.0"
#define PLUGIN_AUTH "iNeedHelp" // Old Name :(

// Weapons BitSum (drop stocks)
#define PRIMARY_WEAPONS_BITSUM ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90))

// Max Players
#define MAX_PLAYERS	32

// Compatibility with Unlimited Money
#if defined UL_COMPAT
	#define get_user_money(%1) cs_get_user_money_ul(%1)
	#define set_user_money(%1,%2) cs_set_user_money_ul(%1,%2)
#else
	#define set_user_money(%1,%2) cs_set_user_money(%1,%2)
	#define get_user_money(%1) cs_get_user_money(%1)
#endif

// Pointers
new g_pGravityCvarPointer

// Main Cvars
new g_pCvarEnable
new g_pCvarMessage
new g_pCvarPrefix

// Menu Cvars
new g_pMenuEnableCvars[7]

new g_pCtGunsMenuCvars[6]
new g_pTeGunsMenuCvars[5]

new g_pInvisibilityMenuCvars[3]
new g_pGravityMenuCvars[4]
new g_pHealthMenuCvars[4]
new g_pSpeedMenuCvars[5]
new g_pSkinsMenuCvars[2]

// Menu vars
new g_iHasSpeed[MAX_PLAYERS+1] = { -1, ... }			
new bool:g_bHasCustomModel[MAX_PLAYERS+1] = { false, ... }	

// Menus Items
new g_szMainShopMenu[][] = 
{
	"Меню оружия CT",
	"Меню оружия Т",
	"Меню невидимости",
	"Меню гравитации",
	"Меню здоровья",
	"Меню скорости",
	"Меню скинов"
}

new g_szCTGunsMenu[][] =
{
	"M4A1",
	"Bullpup",
	"TMP",
	"Five Seven",
	"Famas",
	"Shield"
}

new g_szTGunsMenu[][] =
{
	"Ak 47",
	"Krieg 552",
	"Mac 10",
	"Dual Elites",
	"Galil"
}

new g_szInvisibilityMenu[][] =
{
	"Слабая",
	"Средняя",
	"Высокая"
}

new g_szGravityMenu[][] =
{
	"Грав. 500",
	"Грав.400",
	"Грав. 300",
	"Грав. 200"
}

new g_szHealthMenu[][] = 
{
	"Здоровье +15",
	"Здоровье +35",
	"Здоровье +65",
	"Здоровье +95"
}

new g_szSpeedMenu[][] =
{
	"Скорость 260",
	"Скорость 300",
	"Скорость 340",
	"Скорость 380",
	"Скорость 420"
}

new g_szSkinsMenu[][] =
{
	"Скин Т",
	"Скин CT"
}

// Menus Data
new g_szCTGunsWeapons[][] =
{
	"weapon_m4a1",
	"weapon_aug",
	"weapon_tmp",
	"weapon_fiveseven",
	"weapon_famas",
	"weapon_shield"
}

new g_szTGunsWeapons[][] =
{
	"weapon_ak47",
	"weapon_sg552",
	"weapon_mac10",
	"weapon_elite",
	"weapon_galil"
}

new g_szCTGunsAmmo[][] = { "556nato", "556nato", "9mm", "57mm", "556nato" }
new g_szTGunsAmmo[][] = { "762nato", "556nato", "45acp", "9mm", "556nato" }

new g_iCTGunsLoad[] = { 90, 90, 120, 100, 90 }
new g_iTGunsLoad[] = { 90, 90, 100, 120, 90 }

new g_iCTGunsMaxAmmo[] = { 90, 90, 120, 100, 90 }
new g_iTGunsMaxAmmo[] = { 90, 90, 100, 120, 90 }

new g_iInvisibilityLevel[] = { 150, 100, 25 }
new g_iHealthLevel[] = { 15, 35, 65, 95 }

new Float:g_flGravityLevel[] = { 500.0, 400.0, 300.0, 200.0 }
new Float:g_flSpeedLevel[] = { 260.0, 300.0, 340.0, 380.0, 420.0 }

new g_szSkinsName[][] = { "gign", "leet" }

// Message Hooks
new g_iMsgSayText

// Others
new const g_szShopFile[] = "shop.cfg";	// Shop file

/*================================================================================
 [Init]
=================================================================================*/

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH)
	
	// Multi-Lingual
	register_dictionary("shop.txt")
	
	// Commands
	register_clcmd("say /shop", "ClCmd_Say")
	register_clcmd("say_team /shop", "ClCmd_Say")
	
	// Ham Forwards
	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1)
	
	// FM Forwards
	register_forward(FM_SetClientKeyValue, "Fwd_SetClientKeyValue")
	
	// Events
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	// Variables....
	
	// Messages Hooks
	g_iMsgSayText			= get_user_msgid("SayText")
	
	// Cvars
	g_pGravityCvarPointer		= get_cvar_pointer("sv_gravity")
	
	g_pCvarEnable 			= register_cvar("amx_shop_enable", "1")
	g_pCvarMessage 			= register_cvar("amx_shop_msg", "1")
	g_pCvarPrefix			= register_cvar("amx_shop_prefix", "[CS Shop]")
	
	g_pMenuEnableCvars[0] 		= register_cvar("amx_shop_ct", "1")
	g_pCtGunsMenuCvars[0] 		= register_cvar("amx_shop_m4a1", "3100")
	g_pCtGunsMenuCvars[1] 		= register_cvar("amx_shop_bullpup", "3500")
	g_pCtGunsMenuCvars[2] 		= register_cvar("amx_shop_tmp", "1250")
	g_pCtGunsMenuCvars[3] 		= register_cvar("amx_shop_fiveseven", "750")
	g_pCtGunsMenuCvars[4] 		= register_cvar("amx_shop_famas", "2250")
	g_pCtGunsMenuCvars[5] 		= register_cvar("amx_shop_shield", "2200")
	
	g_pMenuEnableCvars[1] 		= register_cvar("amx_shop_t", "1")
	g_pTeGunsMenuCvars[0] 		= register_cvar("amx_shop_ak47", "2500")
	g_pTeGunsMenuCvars[1] 		= register_cvar("amx_shop_sg552", "3500")
	g_pTeGunsMenuCvars[2] 		= register_cvar("amx_shop_mac10", "1400")
	g_pTeGunsMenuCvars[3] 		= register_cvar("amx_shop_elites", "800")
	g_pTeGunsMenuCvars[4] 		= register_cvar("amx_shop_galil", "2000")
	
	g_pMenuEnableCvars[2] 		= register_cvar("amx_shop_invis", "1")
	g_pInvisibilityMenuCvars[0] 	= register_cvar("amx_shop_low", "3000")
	g_pInvisibilityMenuCvars[1] 	= register_cvar("amx_shop_medium", "6000")
	g_pInvisibilityMenuCvars[2] 	= register_cvar("amx_shop_high", "12000")
	
	g_pMenuEnableCvars[3] 		= register_cvar("amx_shop_grav", "1")
	g_pGravityMenuCvars[0] 		= register_cvar("amx_shop_g500", "1500")
	g_pGravityMenuCvars[1] 		= register_cvar("amx_shop_g400", "3000")
	g_pGravityMenuCvars[2] 		= register_cvar("amx_shop_g300", "4500")
	g_pGravityMenuCvars[3] 		= register_cvar("amx_shop_g200", "6000")
	
	g_pMenuEnableCvars[4] 		= register_cvar("amx_shop_hp", "1")
	g_pHealthMenuCvars[0] 		= register_cvar("amx_shop_15hp", "1500")
	g_pHealthMenuCvars[1] 		= register_cvar("amx_shop_35hp", "3000")
	g_pHealthMenuCvars[2] 		= register_cvar("amx_shop_65hp", "6000")
	g_pHealthMenuCvars[3] 		= register_cvar("amx_shop_95hp", "7500")
		
	g_pMenuEnableCvars[5] 		= register_cvar("amx_shop_speed", "1")
	g_pSpeedMenuCvars[0] 		= register_cvar("amx_shop_260speed", "3000")
	g_pSpeedMenuCvars[1] 		= register_cvar("amx_shop_300speed", "6000")
	g_pSpeedMenuCvars[2] 		= register_cvar("amx_shop_340speed", "9000")
	g_pSpeedMenuCvars[3] 		= register_cvar("amx_shop_380speed", "12000")
	g_pSpeedMenuCvars[4] 		= register_cvar("amx_shop_420speed", "15000")
	
	g_pMenuEnableCvars[6] 		= register_cvar("amx_shop_skins", "0")
	g_pSkinsMenuCvars[0] 		= register_cvar("amx_shop_tskin", "9000")
	g_pSkinsMenuCvars[1] 		= register_cvar("amx_shop_ctskin", "9000")
}

public plugin_precache()
{
	new sModels[128]
	
	for (new i = 0; i < sizeof(g_szSkinsName); i++)
	{
		format(sModels, sizeof(sModels)-1, "models/player/%s/%s.mdl", g_szSkinsName[i], g_szSkinsName[i])
		precache_model(sModels)
	}
}
		
public plugin_cfg()
{
	new ConfigsDir[64]
	get_localinfo("amxx_configsdir", ConfigsDir, charsmax(ConfigsDir))
	format(ConfigsDir, charsmax(ConfigsDir), "%s/%s", ConfigsDir, g_szShopFile)
	
	if (!file_exists(ConfigsDir))
	{
		server_print("CS Shop файл [%s] не найден!", ConfigsDir)
		return;
	}
	server_cmd("exec ^"%s^"", ConfigsDir)
}

/*================================================================================
 [Menus]
=================================================================================*/

public ClCmd_Say(id)
{
	if (!is_user_alive(id))
	{
		client_print_c(id, "%L", id, "SHOP_DEAD")
		return PLUGIN_HANDLED
	}
		
	if (!get_pcvar_num(g_pCvarEnable))
	{
		client_print_c(id, "%L", id, "SHOP_DISABLED")
		return PLUGIN_HANDLED
	}
	Create_Menu(id)
	return PLUGIN_HANDLED
}

Create_Menu(id)
{
	new Menu = menu_create("\rCS Shop меню", "MainMenu_Handler")
	new Items[32], Position[3]
	
	for (new i = 0; i < sizeof(g_szMainShopMenu); i++)
	{
		formatex(Items, charsmax(Items), "%s%s",  get_pcvar_num(g_pMenuEnableCvars[i]) ? "\w" : "\d", g_szMainShopMenu[i])
		num_to_str(i, Position, charsmax(Position))
		
		menu_additem(Menu, Items, Position)
	}
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, 0)		
}

public MainMenu_Handler(id, Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64];
	new Access, Callback;
	menu_item_getinfo(Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data);
	
	switch (Key)
	{
		case 0:
		{
			new Cts_Menu = menu_create("\rОружие CT", "CtMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szCTGunsMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pCtGunsMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pCtGunsMenuCvars[i]) > 0 ? "\w" : "\d", g_szCTGunsMenu[i], get_pcvar_num(g_pCtGunsMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Cts_Menu, Items, Position)
			}
				
			menu_setprop(Cts_Menu, MPROP_EXIT, MEXIT_ALL)
			
			if (!get_pcvar_num(g_pMenuEnableCvars[0]))
			{
				client_print_c(id, "%L", id, "SHOP_CT_OFF")
				return PLUGIN_HANDLED;
			}
			else	
				menu_display(id, Cts_Menu, 0)	
		}
		
		case 1:
		{
			new Ts_Menu = menu_create("\rОружие Т", "TeMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szTGunsMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pTeGunsMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pTeGunsMenuCvars[i]) > 0 ? "\w" : "\d", g_szTGunsMenu[i], get_pcvar_num(g_pTeGunsMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Ts_Menu, Items, Position)
			}
				
			menu_setprop(Ts_Menu, MPROP_EXIT, MEXIT_ALL)

			if (!get_pcvar_num(g_pMenuEnableCvars[1]))
			{
				client_print_c(id, "%L", id, "SHOP_T_OFF")
				return PLUGIN_HANDLED
			}
			else 
				menu_display(id, Ts_Menu, 0)
				
		}
		
		case 2:
		{
			new Inv_Menu = menu_create("\rМеню невидимости", "InvisibilityMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szInvisibilityMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pInvisibilityMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pInvisibilityMenuCvars[i]) > 0 ? "\w" : "\d", g_szInvisibilityMenu[i], get_pcvar_num(g_pInvisibilityMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Inv_Menu, Items, Position)
			}
				
			menu_setprop(Inv_Menu, MPROP_EXIT, MEXIT_ALL)
		
			if (!get_pcvar_num(g_pMenuEnableCvars[2]))
			{
				client_print_c(id, "%L", id, "SHOP_INVIS_OFF")
				return PLUGIN_HANDLED
			}
			else
				menu_display(id, Inv_Menu, 0)	
		}
		
		case 3:
		{
			new Grav_Menu = menu_create("\rМеню гравитации", "GravityMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szGravityMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pGravityMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pGravityMenuCvars[i]) > 0 ? "\w" : "\d", g_szGravityMenu[i], get_pcvar_num(g_pGravityMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Grav_Menu, Items, Position)
			}
				
			menu_setprop(Grav_Menu, MPROP_EXIT, MEXIT_ALL)
			
			if (!get_pcvar_num(g_pMenuEnableCvars[3]))
			{
				client_print_c(id, "%L", id, "SHOP_GRAV_OFF")
				return PLUGIN_HANDLED
			}
			else
				menu_display(id, Grav_Menu, 0)	
		}
		
		case 4:
		{
			new Hp_Menu = menu_create("\rМеню здоровья", "HealthMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szHealthMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pHealthMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pHealthMenuCvars[i]) > 0 ? "\w" : "\d", g_szHealthMenu[i], get_pcvar_num(g_pHealthMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Hp_Menu, Items, Position)
			}
				
			menu_setprop(Hp_Menu, MPROP_EXIT, MEXIT_ALL)
			
			if (!get_pcvar_num(g_pMenuEnableCvars[4]))
			{
				client_print_c(id, "%L", id, "SHOP_HEALTH_OFF")
				return PLUGIN_HANDLED
			}	
			else
				menu_display(id, Hp_Menu, 0)	
		}

		case 5:
		{
			new Speed_Menu = menu_create("\rМеню скорости", "SpeedMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szSpeedMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pSpeedMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pSpeedMenuCvars[i]) > 0 ? "\w" : "\d", g_szSpeedMenu[i], get_pcvar_num(g_pSpeedMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Speed_Menu, Items, Position)
			}		
			
			menu_setprop(Speed_Menu, MPROP_EXIT, MEXIT_ALL)
		
			if (!get_pcvar_num(g_pMenuEnableCvars[5]))
			{
				client_print_c(id, "%L", id, "SHOP_SPEED_OFF")
				return PLUGIN_HANDLED
			}	
			else
				menu_display(id, Speed_Menu, 0)	
		}
		
		case 6:
		{
			new Skins_Menu = menu_create("\yМеню скоростей", "SkinsMenu_Handler")
			new Items[32], PriceString[32], Position[3]
			
			for (new i = 0; i < sizeof(g_szSkinsMenu); i++)
			{
				formatex(PriceString, charsmax(PriceString), "- $%d", get_pcvar_num(g_pSkinsMenuCvars[i]))
				formatex(Items, charsmax(Items), "%s%s %s", get_pcvar_num(g_pSkinsMenuCvars[i]) > 0 ? "\w" : "\d", g_szSkinsMenu[i], get_pcvar_num(g_pSkinsMenuCvars[i]) > 0 ? PriceString : "") 
				
				num_to_str(i, Position, charsmax(Position))
				
				menu_additem(Skins_Menu, Items, Position)
			}		
			
			menu_setprop(Skins_Menu, MPROP_EXIT, MEXIT_ALL)
		
			if (!get_pcvar_num(g_pMenuEnableCvars[6]))
			{
				client_print_c(id, "%L", id, "SHOP_SKINS_OFF")
				return PLUGIN_HANDLED
			}
			else
				menu_display(id, Skins_Menu, 0)
		}
	}
	menu_destroy(Menu)
	return PLUGIN_HANDLED
}

public CtMenu_Handler(id, Cts_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Cts_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback;
	menu_item_getinfo(Cts_Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pCtGunsMenuCvars[Key])
			
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}
			
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szCTGunsMenu[Key])
				
		set_user_money(id, Money-Pcvar)
		
		if (equali(g_szCTGunsMenu[Key], "Five Seven"))
			secondary_wpn_drop(id)
		else
			primary_wpn_drop(id)
		
		give_item(id, g_szCTGunsWeapons[Key])	
		
		if (!equali(g_szCTGunsMenu[Key], "Shield"))
			ExecuteHamB(Ham_GiveAmmo, id, g_iCTGunsLoad[Key], g_szCTGunsAmmo[Key], g_iCTGunsMaxAmmo[Key])
	}
	menu_destroy(Cts_Menu)
	return PLUGIN_HANDLED
}

public TeMenu_Handler(id, Tts_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Tts_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback;
	menu_item_getinfo(Tts_Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pTeGunsMenuCvars[Key])
	
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}
	
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szTGunsMenu[Key])
		
		set_user_money(id, Money-Pcvar)
		
		if (equali(g_szTGunsMenu[Key], "Dual Elites"))
			secondary_wpn_drop(id)
		else
			primary_wpn_drop(id)
		
		give_item(id, g_szTGunsWeapons[Key])
		ExecuteHamB(Ham_GiveAmmo, id, g_iTGunsLoad[Key], g_szTGunsAmmo[Key], g_iTGunsMaxAmmo[Key])
	}
	menu_destroy(Tts_Menu)
	return PLUGIN_HANDLED
}

public InvisibilityMenu_Handler(id, Inv_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Inv_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback;
	menu_item_getinfo(Inv_Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pInvisibilityMenuCvars[Key])
			
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}
		
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szInvisibilityMenu[Key])
		
		set_user_money(id, Money-Pcvar)
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, g_iInvisibilityLevel[Key])
	}
	menu_destroy(Inv_Menu)
	return PLUGIN_HANDLED
}

public GravityMenu_Handler(id, Grav_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Grav_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback;
	menu_item_getinfo(Grav_Menu, item, Access, Data, 5, Name, 63, Callback)

	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pGravityMenuCvars[Key])
			
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}
			
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szGravityMenu[Key])
				
		set_user_money(id, Money-Pcvar)
		set_user_gravity(id, (g_flGravityLevel[Key] / get_pcvar_float(g_pGravityCvarPointer)))
	}
	menu_destroy(Grav_Menu)
	return PLUGIN_HANDLED
}                

public HealthMenu_Handler(id, Hp_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Hp_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback
	menu_item_getinfo(Hp_Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pHealthMenuCvars[Key])
	new Health = get_user_health(id)
			
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}
			
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szHealthMenu[Key])
				
		set_user_money(id, Money-Pcvar)
		set_user_health(id, Health+g_iHealthLevel[Key])	
	}
	menu_destroy(Hp_Menu)
	return PLUGIN_HANDLED
}                            

public SpeedMenu_Handler(id, Speed_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Speed_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback;
	menu_item_getinfo(Speed_Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pSpeedMenuCvars[Key])
			
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}
			
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		g_iHasSpeed[id] = Key
				
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szSpeedMenu[Key])
				
		set_user_money(id, Money-Pcvar)
		set_user_maxspeed(id, g_flSpeedLevel[Key])
	}
	menu_destroy(Speed_Menu)
	return PLUGIN_HANDLED
}                           

public SkinsMenu_Handler(id, Mdl_Menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(Mdl_Menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback
	menu_item_getinfo(Mdl_Menu, item, Access, Data, 5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	new Money = get_user_money(id)
	new Pcvar = get_pcvar_num(g_pSkinsMenuCvars[Key])
	
	new CsTeams:Team = cs_get_user_team(id)
			
	if (!Pcvar)
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_DISABLED")
		return PLUGIN_HANDLED
	}	
			
	switch (Team)
	{
		case CS_TEAM_T:
		{
			if (Key == 0)
			{
				client_print_c(id, "%L", id, "SHOP_ITEM_NOT")
				return PLUGIN_HANDLED
			}
		}
		
		case CS_TEAM_CT:
		{
			if (Key == 1)
			{
				client_print_c(id, "%L", id, "SHOP_ITEM_NOCT")
				return PLUGIN_HANDLED
			}
		}
	}
				
	if (Money < Pcvar)
		client_print_c(id, "%L", id, "SHOP_ITEM_MONEY")
	else
	{
		client_print_c(id, "%L", id, "SHOP_ITEM_BUY", g_szSkinsMenu[Key])
				
		set_user_money(id, Money-Pcvar)
		fm_set_user_model(id, g_szSkinsName[Key])
	}			
	menu_destroy(Mdl_Menu)
	return PLUGIN_HANDLED
}	
	
/*================================================================================
 [Forwards]
=================================================================================*/

public Fwd_PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		set_user_rendering(id)
		set_user_gravity(id, 1.0)
	
		if (g_bHasCustomModel[id])
			fm_reset_user_model(id)
	
		if (g_iHasSpeed[id])
		{
			set_user_maxspeed(id, 250.0)
			g_iHasSpeed[id] = -1
		}
		
		if (get_pcvar_num(g_pCvarEnable))
			if (get_pcvar_num(g_pCvarMessage))
				client_print_c(id, "%L", id, "SHOP_PRINT")
	}
}

public Fwd_SetClientKeyValue(id, const infobuffer[], const key[])
{   
	if (g_bHasCustomModel[id] && equal(key, "model"))
		return FMRES_SUPERCEDE
        
	return FMRES_IGNORED
}

public Event_CurWeapon(id)
{
	if (!is_user_alive(id))
		return
	
	switch (g_iHasSpeed[id])
	{
		case 0: set_user_maxspeed(id, 260.0)
		case 1: set_user_maxspeed(id, 300.0)
		case 2: set_user_maxspeed(id, 340.0)
		case 3: set_user_maxspeed(id, 380.0)
		case 4: set_user_maxspeed(id, 420.0)
	}
}

/*================================================================================
 [Stocks]
=================================================================================*/	
	
stock primary_wpn_drop(index)
{
	new weapons[32], num, Weapon
	get_user_weapons(index, weapons, num)
	
	for (new i = 0; i < num; i++) 
	{
		Weapon = weapons[i]
		
		if (PRIMARY_WEAPONS_BITSUM & (1<<Weapon))
		{
			static wname[32]
			get_weaponname(Weapon, wname, sizeof wname - 1)
			
			engclient_cmd(index, "drop", wname)
		}
	}
}

stock secondary_wpn_drop(index)
{
	new weapons[32], num, Weapon
	get_user_weapons(index, weapons, num)
	
	for (new i = 0; i < num; i++)
	{
		Weapon = weapons[i]
		
		if (!(PRIMARY_WEAPONS_BITSUM & (1<<Weapon)))
		{
			static wname[32]
			get_weaponname(Weapon, wname, sizeof wname - 1)
			
			engclient_cmd(index, "drop", wname)
		}
	}
}    

stock fm_set_user_model(index, const mdl[])
{
	engfunc(EngFunc_SetClientKeyValue, index, engfunc(EngFunc_GetInfoKeyBuffer, index), "model", mdl)
	g_bHasCustomModel[index] = true
}

stock fm_reset_user_model(index)
{
	g_bHasCustomModel[index] = false
	dllfunc(DLLFunc_ClientUserInfoChanged, index, engfunc(EngFunc_GetInfoKeyBuffer, index))
}

stock client_print_c(index, const Msg[], {Float, Sql, Result,_}:...) 
{
	if (!is_user_connected(index))
		return; 
	
	new Buffer[512], Buffer2[512], Prefix[32]
	get_pcvar_string(g_pCvarPrefix, Prefix, charsmax(Prefix))
	formatex(Buffer2, charsmax(Buffer2), "^x04%s ^x01%s", Prefix, Msg);
	vformat(Buffer, charsmax(Buffer), Buffer2, 3);
   
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayText, _, index);
	write_byte(index);
	write_string(Buffer);
	message_end();
}




