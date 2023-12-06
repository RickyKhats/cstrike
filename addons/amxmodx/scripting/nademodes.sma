#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <xs>
#include <csx>

#define PLUGIN "Nade Modes"
#define VERSION "5.9"
#define AUTHOR "Nomexous & OT"


/*
Version 3.0
 - Initial release.
 
Version 3.1
 - Changing an item on the second page will rebuild the menu and display on the second page.

Version 4
 - Improve to the trip grenade and sounds

Version 5
 - Full grenade support + satchel charge mode

Version 5.2
 - Automatic save system + team bug fix

Version 5.5
 - Nade choose system

Version 5.7
 - New menu system

Version 5.8
 - Added compatibility with Biohazzard/Zombie Plague Mod. The nades will be removed when a player is turned into a zombie

Version 5.9
 - Added new cvar for teamplay the plugin won't follow friendlyfire anymore, bot support
*/

#define ACTIVATE "weapons/mine_activate.wav"
#define DEPLOY "weapons/mine_deploy.wav"
#define CHARGE "weapons/mine_charge.wav"
#define GEIGER "player/geiger1.wav"

#define	GRENADE_EXPLOSIVE 0
#define	GRENADE_FLASHBANG 1
#define	GRENADE_SMOKEGREN 2

// Enums! First time I've ever used them. These should make the code infinitely easier to read.

enum NadeType
{
	NADE_DUD = -1,
	NADE_NORMAL,
	NADE_PROXIMITY,
	NADE_IMPACT,
	NADE_TRIP,
	NADE_MOTION,
}

enum TripNadeMode
{
	TRIP_NOT_ATTACHED = 0,
	TRIP_ATTACHED,
	TRIP_WAITING,
	TRIP_SCANNING,
	TRIP_SHOULD_DETONATE
}

enum TripNadeAction
{
	TRIP_ACTION_INITIALIZE,
	TRIP_ACTION_WAIT,
	TRIP_ACTION_SCAN,
	TRIP_ACTION_DETONATE
}

enum Option
{
	OPTION_ENABLE_NADE_MODES,
	OPTION_BOT_ALLOW,
	OPTION_NADES_IN_EFFECT,
	OPTION_ENABLE_SECONDARY_EX,
	OPTION_ENABLE_INFINITE_GRENADES,
	OPTION_ENABLE_INFINITE_FLASHES,
	OPTION_ENABLE_INFINITE_SMOKES,
	OPTION_SUPPRESS_FITH,
	OPTION_DISPLAY_MODE_ON_DRAW,
	OPTION_PLAY_SOUNDS,
	OPTION_RESET_MODE_ON_THROW,
	OPTION_RESOURCE_USE,
	OPTION_TEAM_PLAY,
	OPTION_AFFECT_OWNER,
	
	OPTION_TRIP_G_REACT,
	OPTION_TRIP_F_REACT,
	OPTION_TRIP_S_REACT,
	
	OPTION_PROXIMITY_ENABLED,
	OPTION_IMPACT_ENABLED,
	OPTION_TRIP_ENABLED,
	OPTION_MOTION_ENABLED,
	OPTION_SATCHEL_ENABLED,
	
	OPTION_TRIP_ARM_TIME,
	OPTION_MOTION_ARM_TIME,
	OPTION_SATCHEL_ARM_TIME,
	OPTION_PROXIMITY_ARM_TIME,
	OPTION_TRIP_FLY_SPEED,
	OPTION_TRIP_DETECT_DISTANCE,
	OPTION_PROXIMITY_RADIUS,
	OPTION_MOTION_RADIUS
}

new option_type[Option]
new option_value[Option][100]

// 1 - means toggle that means that the cvar can have 2 values
// 2 - more cell values
// 3 - more float values

new const NADE_MODEL[][] = 
{
	"models/w_hegrenade.mdl",
	"models/w_flashbang.mdl",
	"models/w_smokegrenade.mdl"
}

new const NADE_BIT[] =
{
	(1<<0),
	(1<<1),
	(1<<2)
}

new const CFG_FILE_NAME[] = "nade_modes.cfg"
new CFG_FILE[300]

new NadeType:mode[33][3]

new settingsmenu

new pcvars[Option]

new beampoint
new shockwave

new callbacks[2]

new modetext[][] = { "Нормальная", "Дистанционная", "Мнгновенная", "Лазерная", "Мина", "Тупость" }

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("nademodes_version", VERSION)
	
	register_clcmd("amx_nade_mode_menu", "conjure_menu", ADMIN_SLAY, "Shows settings menu for grenade modes.")
	register_clcmd("amx_nmm", "conjure_menu", ADMIN_SLAY, "Shows settings menu for grenade modes.")
	
	register_clcmd("say /nadehelp","conjure_help",-1,"Shows help for grenade modes.")
	register_clcmd("say_team /nadehelp","conjure_help",-1,"Shows help for grenade modes.")
	
	// Wow, enums are useful. So are arrays. Imagine having a unique variable for every one of these options.
	
	// Integer PCVARs
	register_option(OPTION_ENABLE_NADE_MODES,"nademodes_enable","1")
	register_option(OPTION_NADES_IN_EFFECT,"nademodes_nades_in_effect","7", 0, 0.0, 2)
	register_option(OPTION_ENABLE_SECONDARY_EX,"nademodes_enable_secondary_explosions", "0")
	register_option(OPTION_SUPPRESS_FITH,"nademodes_suppress_fire_in_the_hole", "0")
	register_option(OPTION_DISPLAY_MODE_ON_DRAW,"nademodes_display_mode_on_draw", "1")
	register_option(OPTION_PLAY_SOUNDS,"nademodes_play_grenade_sounds", "1")
	register_option(OPTION_RESET_MODE_ON_THROW,"nademodes_reset_mode_on_throw", "0")
	register_option(OPTION_RESOURCE_USE,"nademodes_effects","1")
	register_option(OPTION_BOT_ALLOW,"nademodes_bot_support","1")
	
	register_option(OPTION_PROXIMITY_ENABLED,"nademodes_proximity_enabled", "1")
	register_option(OPTION_IMPACT_ENABLED,"nademodes_impact_enabled", "1")
	register_option(OPTION_TRIP_ENABLED,"nademodes_trip_enabled", "1")
	register_option(OPTION_MOTION_ENABLED,"nademodes_motion_enabled", "1")
	register_option(OPTION_SATCHEL_ENABLED,"nademodes_satchel_enabled","1")
	
	register_option(OPTION_ENABLE_INFINITE_GRENADES,"nademodes_infinite_grenades", "0")
	register_option(OPTION_ENABLE_INFINITE_FLASHES,"nademodes_infinite_flashes", "0")
	register_option(OPTION_ENABLE_INFINITE_SMOKES,"nademodes_infinite_smokes", "0")
	
	register_option(OPTION_TRIP_G_REACT,"nademodes_grenade_react","1")
	register_option(OPTION_TRIP_F_REACT,"nademodes_flash_react","1")
	register_option(OPTION_TRIP_S_REACT,"nademodes_smoke_react","1")
	
	register_option(OPTION_AFFECT_OWNER,"nademodes_affect_owner","1")
	register_option(OPTION_TEAM_PLAY,"nademodes_team_play","1")
	
	// Float PCVARs
	register_option(OPTION_TRIP_ARM_TIME,"nademodes_trip_grenade_arm_time", "3.0", 0, 0.0, 3)
	register_option(OPTION_PROXIMITY_ARM_TIME,"nademodes_proximity_arm_time", "2.0", 0, 0.0, 3)
	register_option(OPTION_MOTION_ARM_TIME,"nademodes_motion_arm_time", "2.0", 0, 0.0, 3)
	register_option(OPTION_SATCHEL_ARM_TIME,"nademodes_satchel_arm_time", "2.0", 0, 0.0, 3)
	register_option(OPTION_TRIP_FLY_SPEED,"nademodes_trip_grenade_fly_speed", "400.0", 0, 0.0, 3)
	register_option(OPTION_TRIP_DETECT_DISTANCE,"nademodes_trip_grenade_detection_limit", "8712.0", 0, 0.0, 3)
	register_option(OPTION_PROXIMITY_RADIUS,"nademodes_proximity_radius", "150.0", 0, 0.0, 3)
	register_option(OPTION_MOTION_RADIUS,"nademodes_motion_radius", "200.0", 0, 0.0, 3)
	
	// Option Values
	register_option_value(OPTION_NADES_IN_EFFECT,"0;1;2;3;4;5;6;7")
	register_option_value(OPTION_TRIP_ARM_TIME, "2.5;3.0;3.5;4.0;4.5")
	register_option_value(OPTION_PROXIMITY_ARM_TIME, "1.0;1.5;2.0;2.5;3.0")
	register_option_value(OPTION_MOTION_ARM_TIME, "1.0;1.5;2.0;2.5;3.0")
	register_option_value(OPTION_SATCHEL_ARM_TIME, "1.0;1.5;2.0;2.5;3.0")
	register_option_value(OPTION_TRIP_FLY_SPEED, "350.0;400.0;450.0;500.0;550.0;600.0")
	register_option_value(OPTION_TRIP_DETECT_DISTANCE,"400.0;700.0;1000.0;4000.0;8712.0")
	register_option_value(OPTION_PROXIMITY_RADIUS, "100.0;125.0;150.0;175.0")
	register_option_value(OPTION_MOTION_RADIUS, "175.0;200.0;225.0")
	
	register_event("CurWeapon", "armnade", "b", "1=1")
	
	register_message(get_user_msgid("SendAudio"), "fith_audio")
	register_message(get_user_msgid("TextMsg"), "fith_text")
	
	register_dictionary("nademodes.txt")
	
	callbacks[0] = menu_makecallback("callback_disabled")
	callbacks[1] = menu_makecallback("callback_enabled")
	
	AddMenuItem("Nade Mode Menu","amx_nmm",ADMIN_CFG,PLUGIN)
	
	new config[200]
	get_configsdir(config,199)
	format(CFG_FILE,299,"%s/%s",config,CFG_FILE_NAME)
	
	exec_cfg()
	
	update_forward_registration()
}

register_option(Option:option, const name[300], const string[], flags = 0, Float:value = 0.0, type = 1)
{
	pcvars[option] = register_cvar(name, string, flags, value)
	option_type[option] = type
}

register_option_value(Option:option, values[100])
{
	if (option_type[option] == 1)
		return
	
	option_value[option] = values
}

public client_disconnect(id)
{
	mode[id][0] = NADE_NORMAL
	mode[id][1] = NADE_NORMAL
	mode[id][2] = NADE_NORMAL
	
	new strtype[11] = "classname", ent = -1;
	new classname[30] = "grenade"
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) == id) 
	{
		if(is_grenade(ent) && get_grenade_type(ent) != NADE_NORMAL)
			engfunc(EngFunc_RemoveEntity,ent)
	}
}

public exec_cfg()
{
	if(file_exists(CFG_FILE))
		server_cmd("exec %s",CFG_FILE)
}

public save_cfg()
{
	new file[2000]
	
	format(file,1999,"echo [Nade Modes] Executing config file ...^n")
	
	format(file,1999,"%snademodes_enable %d^n",file,get_option(OPTION_ENABLE_NADE_MODES))
	format(file,1999,"%snademodes_nades_in_effect %d^n",file,get_option(OPTION_NADES_IN_EFFECT))
	
	format(file,1999,"%snademodes_enable_secondary_explosions %d^n",file,get_option(OPTION_ENABLE_SECONDARY_EX))
	format(file,1999,"%snademodes_display_mode_on_draw %d^n",file,get_option(OPTION_DISPLAY_MODE_ON_DRAW))
	format(file,1999,"%snademodes_reset_mode_on_throw %d^n",file,get_option(OPTION_RESET_MODE_ON_THROW))
	
	format(file,1999,"%snademodes_effects %d^n",file,get_option(OPTION_RESOURCE_USE))
	format(file,1999,"%snademodes_play_grenade_sounds %d^n",file,get_option(OPTION_PLAY_SOUNDS))
	format(file,1999,"%snademodes_suppress_fire_in_the_hole %d^n",file,get_option(OPTION_SUPPRESS_FITH))
	format(file,1999,"%snademodes_bot_support %d^n",file,get_option(OPTION_BOT_ALLOW))
	
	format(file,1999,"%snademodes_affect_owner %d^n",file,get_option(OPTION_AFFECT_OWNER))
	format(file,1999,"%snademodes_team_play %d^n",file,get_option(OPTION_TEAM_PLAY))
	
	format(file,1999,"%snademodes_infinite_grenades %d^n",file,get_option(OPTION_ENABLE_INFINITE_GRENADES))
	format(file,1999,"%snademodes_infinite_flashes %d^n",file,get_option(OPTION_ENABLE_INFINITE_FLASHES))
	format(file,1999,"%snademodes_infinite_smokes %d^n",file,get_option(OPTION_ENABLE_INFINITE_SMOKES))
	
	format(file,1999,"%snademodes_grenade_react %d^n",file,get_option(OPTION_TRIP_G_REACT))
	format(file,1999,"%snademodes_flash_react %d^n",file,get_option(OPTION_TRIP_F_REACT))
	format(file,1999,"%snademodes_smoke_react %d^n",file,get_option(OPTION_TRIP_S_REACT))
	
	format(file,1999,"%snademodes_proximity_enabled %d^n",file,get_option(OPTION_PROXIMITY_ENABLED))
	format(file,1999,"%snademodes_impact_enabled %d^n",file,get_option(OPTION_IMPACT_ENABLED))
	format(file,1999,"%snademodes_trip_enabled %d^n",file,get_option(OPTION_TRIP_ENABLED))
	format(file,1999,"%snademodes_motion_enabled %d^n",file,get_option(OPTION_MOTION_ENABLED))
	format(file,1999,"%snademodes_satchel_enabled %d^n",file,get_option(OPTION_SATCHEL_ENABLED))
	
	format(file,1999,"%snademodes_trip_grenade_arm_time %f^n",file,get_option_float(OPTION_TRIP_ARM_TIME))
	format(file,1999,"%snademodes_proximity_arm_time %f^n", file, get_option_float(OPTION_PROXIMITY_ARM_TIME))
	format(file,1999,"%snademodes_motion_arm_time %f^n", file, get_option_float(OPTION_MOTION_ARM_TIME))
	format(file,1999,"%snademodes_satchel_arm_time %f^n", file, get_option_float(OPTION_SATCHEL_ARM_TIME))
	format(file,1999,"%snademodes_trip_grenade_fly_speed %f^n",file,get_option_float(OPTION_TRIP_FLY_SPEED))
	format(file,1999,"%snademodes_trip_grenade_detection_limit %f^n",file,get_option_float(OPTION_TRIP_DETECT_DISTANCE))
	format(file,1999,"%snademodes_proximity_radius %f^n",file,get_option_float(OPTION_PROXIMITY_RADIUS))
	format(file,1999,"%snademodes_motion_radius %f^n",file,get_option_float(OPTION_MOTION_RADIUS))
	
	format(file,1999,"%secho [Nade Modes] Settings loaded from config file",file)
	
	delete_file(CFG_FILE)
	write_file(CFG_FILE,file)
}

public plugin_end()
{
	save_cfg()
}

public conjure_help(id)
{
	new Help_File[3000];
	
	format(Help_File,2999,"%L",id,"NADE_HTML")
	
	delete_file("nmm.htm")
	write_file("nmm.htm",Help_File)
	show_motd(id, "nmm.htm", "Mega-Nade Mod");
	
	return PLUGIN_HANDLED;
}

public client_connect(id)
{
	mode[id][0] = NADE_NORMAL
	mode[id][1] = NADE_NORMAL
	mode[id][2] = NADE_NORMAL
}

public fith_audio(msg_id, msg_dest, entity)
{
	if (!get_option(OPTION_SUPPRESS_FITH) || !get_option(OPTION_ENABLE_INFINITE_GRENADES)) return PLUGIN_CONTINUE
	
	new string[18]
	get_msg_arg_string(2, string, 17)
	
	if (equal(string, "%!MRAD_FIREINHOLE")) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public fith_text(msg_id, msg_dest, entity)
{
	if (!get_option(OPTION_SUPPRESS_FITH) || !get_option(OPTION_ENABLE_INFINITE_GRENADES)) return PLUGIN_CONTINUE
	
	static string[18]
	
	if (get_msg_args() == 5) // CS
	{
		get_msg_arg_string(5, string, 17)
	}
	else if (get_msg_args() == 6) // CZ
	{
		get_msg_arg_string(6, string, 17)
	}
	else
	{
		return PLUGIN_CONTINUE
	}
	
	return (equal(string, "#Fire_in_the_hole")) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public armnade(id)
{
	new weapon = read_data(2)
	new NADE_TYPE
	
	switch (weapon)
	{
		case CSW_HEGRENADE: NADE_TYPE = GRENADE_EXPLOSIVE
		case CSW_SMOKEGRENADE: NADE_TYPE = GRENADE_SMOKEGREN
		case CSW_FLASHBANG: NADE_TYPE = GRENADE_FLASHBANG
		default: return PLUGIN_CONTINUE
	}
	
	if (get_option(OPTION_ENABLE_INFINITE_GRENADES))
	{
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1000)
	}
	
	if (get_option(OPTION_ENABLE_INFINITE_FLASHES))
	{
		cs_set_user_bpammo(id, CSW_FLASHBANG, 1000)
	}
	
	if (get_option(OPTION_ENABLE_INFINITE_SMOKES))
	{
		cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 1000)
	}
	
	if (get_option(OPTION_DISPLAY_MODE_ON_DRAW) && grenade_can_be_used(NADE_TYPE))
	{
		client_print(id, print_center, "mode: %s", modetext[_:mode[id][NADE_TYPE]])
	}
	
	if (get_option(OPTION_ENABLE_NADE_MODES) && !is_mode_enabled(mode[id][NADE_TYPE]))
	{
		changemode(id,NADE_TYPE)
	}
	
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	beampoint = engfunc(EngFunc_PrecacheModel,"sprites/laserbeam.spr")
	shockwave = engfunc(EngFunc_PrecacheModel,"sprites/shockwave.spr")
	precache_sound(ACTIVATE)
	precache_sound(CHARGE)
	precache_sound(DEPLOY)
	precache_sound(GEIGER)
}

public update_forward_registration()
{
	static fid[4] = { 0, ... }
	
	if (get_option(OPTION_ENABLE_NADE_MODES) && !fid[0] && !fid[1] && !fid[2])
	{
		fid[0] = register_forward(FM_CmdStart, "fw_cmdstart")
		fid[1] = register_forward(FM_Think, "fw_think")
		fid[2] = register_forward(FM_Touch, "fw_touch")
	}
	
	if (!get_option(OPTION_ENABLE_NADE_MODES) && fid[0] && fid[1] && fid[2])
	{
		unregister_forward(FM_CmdStart, fid[0])
		unregister_forward(FM_Think, fid[1])
		unregister_forward(FM_Touch, fid[2])
		
		fid[0] = 0
		fid[1] = 0
		fid[2] = 0
	}
	
	if (get_option(OPTION_ENABLE_SECONDARY_EX) && !fid[3])
	{
		fid[3] = register_forward(FM_EmitSound, "fw_emitsound")
	}
	
	if (!get_option(OPTION_ENABLE_SECONDARY_EX) && fid[3])
	{
		unregister_forward(FM_EmitSound, fid[3])
		fid[3] = 0
	}
}

public conjure_menu(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
	{
		gmm(id)
	}
	return PLUGIN_HANDLED
}

stock gmm(id, page = 0)
{
	settingsmenu = menu_create("Nade Modes Settings Menu", "menu_handler")
	
	add_option_toggle(OPTION_ENABLE_NADE_MODES, "Enable nade modes", "Yes", "No")
	
	if (!get_option(OPTION_ENABLE_NADE_MODES))
	{
		menu_display(id, settingsmenu, 0)
		return PLUGIN_CONTINUE
	}
	
	add_nade_option(OPTION_NADES_IN_EFFECT,"Affected nades")
	add_option_toggle(OPTION_BOT_ALLOW,"Allow bots to use the moded nades", "Yes", "No") 
	add_option_toggle(OPTION_DISPLAY_MODE_ON_DRAW, "Display mode on draw", "Yes", "No")
	add_option_toggle(OPTION_RESET_MODE_ON_THROW, "Reset mode on throw", "Yes", "No")
	add_option_toggle(OPTION_RESOURCE_USE,"Enable plugin effects","Yes","No")
	add_option_toggle(OPTION_PLAY_SOUNDS, "Grenade sounds", "On", "Off")
	add_option_toggle(OPTION_SUPPRESS_FITH, "Suppress ^"Fire in the hole!^"", "Yes", "No")
	add_option_toggle(OPTION_AFFECT_OWNER,"Traps can be activated by owner","Yes", "No")
	add_option_toggle(OPTION_TEAM_PLAY,"Team play (teammates will not be affected by nades)", "Yes", "No")
	
	add_option_toggle(OPTION_ENABLE_SECONDARY_EX, "Secondary explosions", "Enabled", "Disabled")
	
	add_option_toggle(OPTION_ENABLE_INFINITE_GRENADES, "Infinite grenades", "Yes", "No")
	add_option_toggle(OPTION_ENABLE_INFINITE_FLASHES, "Infinite flashes", "Yes", "No")
	add_option_toggle(OPTION_ENABLE_INFINITE_SMOKES, "Infinite smokes", "Yes", "No")
	
	add_option_toggle(OPTION_TRIP_G_REACT, "Trip grenade react method", "Boom", "Fly")
	add_option_toggle(OPTION_TRIP_F_REACT, "Trip flash react method", "Boom", "Fly")
	add_option_toggle(OPTION_TRIP_S_REACT, "Trip smoke react method", "Boom", "Fly")
	
	add_option_toggle(OPTION_PROXIMITY_ENABLED, "Enable proximity grenades", "Yes", "No")
	add_option_toggle(OPTION_IMPACT_ENABLED, "Enable impact grenades", "Yes", "No")
	add_option_toggle(OPTION_TRIP_ENABLED, "Enable trip grenades", "Yes", "No")
	add_option_toggle(OPTION_MOTION_ENABLED, "Enable motion sensor grenades", "Yes", "No")
	add_option_toggle(OPTION_SATCHEL_ENABLED, "Enable satchel charge grenades", "Yes", "No")
	
	add_float_option(OPTION_TRIP_ARM_TIME,"Trip grenade arm time","seconds")
	add_float_option(OPTION_PROXIMITY_ARM_TIME,"Proximity arm time","seconds")
	add_float_option(OPTION_MOTION_ARM_TIME,"Motion sensor arm time","seconds")
	add_float_option(OPTION_SATCHEL_ARM_TIME,"Satchel charge arm time","seconds")
	add_float_option(OPTION_TRIP_DETECT_DISTANCE,"Trip grenade detection distance","units")
	add_float_option(OPTION_PROXIMITY_RADIUS,"Proximity detection radius","units")
	add_float_option(OPTION_MOTION_RADIUS,"Motion sensor detection radius","units")
	
	menu_display(id, settingsmenu, page)
	return PLUGIN_CONTINUE
}

stock add_option_toggle(Option:control_option, const basetext[], const yestext[], const notext[], Option:displayif = Option:-1)
{
	new cmd[3], itemtext[100]
	num_to_str(_:control_option, cmd, 2)
	format(itemtext, 99, "%s: %s%s", basetext, (get_option(control_option) ? "\y" : "\r" ), (get_option(control_option) ? yestext : notext))
	menu_additem(settingsmenu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_nade_option(Option:control_option, const basetext[])
{
	new cmd[3], itemtext[100]
	num_to_str(_:control_option, cmd, 2)
	format(itemtext, 99, "%s:%s%s%s%s", basetext, (get_option(control_option) ? "\y" : " \rNone" ), ((get_option(control_option) & NADE_BIT[GRENADE_EXPLOSIVE]) ? " He" : ""), ((get_option(control_option) & NADE_BIT[GRENADE_FLASHBANG]) ? " Flash" : ""), ((get_option(control_option) & NADE_BIT[GRENADE_SMOKEGREN]) ? " Smoke" : ""))
	menu_additem(settingsmenu, itemtext, cmd, _, _)
}

stock add_float_option(Option:control_option, const basetext[], const unit[])
{
	new cmd[3], itemtext[100]
	new value[20]
	float_to_str(get_option_float(control_option),value,19)
	format(value,19,"%0.2f",get_option_float(control_option))
	
	num_to_str(_:control_option, cmd, 2)
	format(itemtext, 99, "%s: \y%s \r%s", basetext, value, unit)
	menu_additem(settingsmenu, itemtext, cmd, _, _)
}

public callback_disabled(id, menu, item)
{
	return ITEM_DISABLED
}

public callback_enabled(id, menu, item)
{
	return ITEM_ENABLED
}

public menu_handler(id, menu, item)
{
	new access, info[5], callback
	menu_item_getinfo(menu, item, access, info, 4, _, _, callback)
	
	if (item < 0)
	{
		update_forward_registration()
		save_cfg()
		return PLUGIN_HANDLED
	}
	
	new cvar = str_to_num(info)
	
	switch (option_type[Option:cvar])
	{
		case 1:
		{
			toggle_option(Option:cvar)
		}
		case 2:
		{
			new value_string[100]
			format(value_string,99,"%s;",option_value[Option:cvar])
			
			new values[20][10]
			new true_value[20]
			
			new last = 0,newpos = 0, k = 0;
			
			for (new i=0;i<100;i++)
			{
				if(equal(value_string[i],";",1))
				{
					newpos = i
				}
				
				if (newpos > last)
				{					
					for (new j=last;j<newpos;j++)
					{
						format(values[k],9,"%s%s",values[k],value_string[j])
					}
					
					last = newpos + 1
					k++
				}
			}
			
			new bool:ok=false
			new counter = 0
			
			for (new i=0;i<k;i++)
			{
				counter++
				
				true_value[i] = str_to_num(values[i])
				
				if (ok == true)
				{
					set_pcvar_num(pcvars[Option:cvar],true_value[i])
					counter = 0
					break
				}
				
				if (true_value[i] == get_option(Option:cvar))
					ok = true
			}
			
			if (counter == k)
				set_pcvar_num(pcvars[Option:cvar],true_value[0])
		}
		case 3:
		{
			new value_string_float[100]
			format(value_string_float,99,"%s;",option_value[Option:cvar])
			
			new values_float[20][10]
			new Float:true_value_float[20]
			
			new last = 0,newpos = 0, k = 0;
			
			for (new i=0;i<100;i++)
			{
				if(equal(value_string_float[i],";",1))
				{
					newpos = i
				}
				
				if (newpos > last)
				{					
					for (new j=last;j<newpos;j++)
					{
						format(values_float[k],9,"%s%s",values_float[k],value_string_float[j])
					}
					
					last = newpos + 1
					k++
				}
			}
			
			new bool:ok=false
			new counter = 0
			
			for (new i=0;i<k;i++)
			{
				counter++
				
				true_value_float[i] = str_to_float(values_float[i])
				
				if (ok == true)
				{
					set_pcvar_float(pcvars[Option:cvar],true_value_float[i])
					counter = 0
					break
				}
				
				if (true_value_float[i] == get_option_float(Option:cvar))
					ok = true
			}
			
			if (counter == k)
				set_pcvar_float(pcvars[Option:cvar],true_value_float[0])
		}
	}
	
	menu_destroy(menu)
	update_forward_registration()
	gmm(id, floatround(float(item)/7.0,floatround_floor))
	save_cfg()
	return PLUGIN_HANDLED
}

public grenade_throw(id, grenade, weapon)
{
	new NADE_TYPE
	
	switch (weapon)
	{
		case CSW_HEGRENADE: NADE_TYPE = GRENADE_EXPLOSIVE
		case CSW_SMOKEGRENADE: NADE_TYPE = GRENADE_SMOKEGREN
		case CSW_FLASHBANG: NADE_TYPE = GRENADE_FLASHBANG
	}
	
	if (get_option(OPTION_ENABLE_NADE_MODES) && is_user_bot(id) && get_option(OPTION_BOT_ALLOW))
	{
		new NadeType:random_vec[4] = { NADE_NORMAL, NADE_IMPACT, NADE_MOTION, NADE_PROXIMITY }
		new NadeType:decision = random_vec[random_num(0,3)]
		
		mode[id][NADE_TYPE] = decision
		
		if (is_mode_enabled(mode[id][NADE_TYPE]))
			set_grenade_type(grenade, mode[id][NADE_TYPE])
		else
		{
			mode[id][NADE_TYPE] = NADE_NORMAL
			set_grenade_type(grenade, mode[id][NADE_TYPE])
		}
		
		return PLUGIN_HANDLED
	}
	
	if (get_option(OPTION_ENABLE_NADE_MODES) && is_mode_enabled(mode[id][NADE_TYPE]) && grenade_can_be_used(NADE_TYPE))
	{
		set_grenade_type(grenade, mode[id][NADE_TYPE])
	}
	
	if (get_option(OPTION_RESET_MODE_ON_THROW))
	{
		mode[id][NADE_TYPE] = NADE_NORMAL
	}
	
	return PLUGIN_HANDLED
}

public fw_think(ent)
{
	if (!is_grenade(ent)) return FMRES_IGNORED
	
	static i, Float:origin[3], Float:porigin[3], trace = 0, Float:fraction
	
	switch (get_grenade_type(ent))
	{
		case NADE_DUD:
		{
			return FMRES_SUPERCEDE
		}
		
		case NADE_NORMAL:
		{
			return FMRES_IGNORED
		}
		
		case NADE_PROXIMITY:
		{
			if (!allow_grenade_explode(ent)) return FMRES_IGNORED
			
			new Float:timeline
			pev(ent,pev_fuser4,timeline)
			pev(ent,pev_origin,origin)
			
			if (timeline <= get_gametime() && get_option(OPTION_RESOURCE_USE))
			{						
				set_pev(ent,pev_fuser4,get_gametime() + 2.0)
				if (!get_option(OPTION_TEAM_PLAY))
					show_ring(origin,get_option_float(OPTION_PROXIMITY_RADIUS) * 1.5 * 7 / 5, 5)
				else
				{
					new owner = pev(ent,pev_owner)
					new team = _:cs_get_user_team(owner)
					switch (team)
					{
						case CS_TEAM_T: show_ring(origin,get_option_float(OPTION_PROXIMITY_RADIUS) * 1.5 * 7 / 5, 5, 255, 0, 0)
						case CS_TEAM_CT: show_ring(origin,get_option_float(OPTION_PROXIMITY_RADIUS) * 1.5 * 7 / 5, 5, 0, 0, 255)
						default: show_ring(origin,get_option_float(OPTION_PROXIMITY_RADIUS) * 1.5 * 7 / 5, 5)
					}
				}
			}
			
			i = -1
			pev(ent, pev_origin, origin)
			new owner = pev(ent,pev_owner)
			while ((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_option_float(OPTION_PROXIMITY_RADIUS))))
			{
				if (is_user_alive(i))
				{					
					if (get_option(OPTION_AFFECT_OWNER) && i == owner)
					{
						make_explode(ent)
						return FMRES_IGNORED
					}
					if (!get_option(OPTION_TEAM_PLAY))
					{
						make_explode(ent)
						return FMRES_IGNORED
					}
					else
					{
						if (_:cs_get_user_team(i) != _:cs_get_user_team(owner))
						{
							make_explode(ent)
							return FMRES_IGNORED
						}
					}
				}
			}
			return FMRES_IGNORED
		}
		
		case NADE_TRIP:
		{
			switch (get_trip_grenade_mode(ent))
			{
				case TRIP_NOT_ATTACHED:
				{
					return FMRES_IGNORED
				}
				
				case TRIP_ATTACHED:
				{
					trip_grenade_action(ent, TRIP_ACTION_INITIALIZE)
					return FMRES_IGNORED
				}
				
				case TRIP_WAITING:
				{
					trip_grenade_action(ent, TRIP_ACTION_WAIT)
					return FMRES_IGNORED
				}
				
				case TRIP_SCANNING:
				{
					trip_grenade_action(ent, TRIP_ACTION_SCAN)					
					return FMRES_IGNORED
				}
				
				case TRIP_SHOULD_DETONATE:
				{
					trip_grenade_action(ent, TRIP_ACTION_DETONATE)
					return FMRES_IGNORED
				}
			}
		}
		
		case NADE_MOTION:
		{
			if (!allow_grenade_explode(ent)) return FMRES_IGNORED
			
			pev(ent, pev_origin, origin)
			i = -1
			
			static Float:v[3], Float:velocity
			new owner = pev(ent,pev_owner)
			
			while ((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_option_float(OPTION_MOTION_RADIUS))))
			{
				if (is_user_alive(i))
				{
					new Float:timeline
					pev(ent,pev_fuser4,timeline)
					
					pev(i, pev_origin, porigin)
					engfunc(EngFunc_TraceLine, origin, porigin, IGNORE_MONSTERS, 0, trace)
					
					get_tr2(trace, TR_flFraction, fraction)
					if (fraction < 1.0) return FMRES_IGNORED
					
					pev(i, pev_velocity, v)
					velocity = xs_vec_len(v)
					
					if (timeline <= get_gametime() && get_option(OPTION_RESOURCE_USE) && velocity != 0.0)
					{						
						set_pev(ent,pev_fuser4,get_gametime() + 0.1)
						
						if (!get_option(OPTION_TEAM_PLAY))
							show_ring(origin,get_option_float(OPTION_MOTION_RADIUS) * (222.50 / 24.0),1)
						else
						{
							new owner = pev(ent,pev_owner)
							new team = _:cs_get_user_team(owner)
							switch (team)
							{
								case CS_TEAM_T: show_ring(origin,get_option_float(OPTION_MOTION_RADIUS) * (222.50 / 24.0),1,255,0,0)
								case CS_TEAM_CT: show_ring(origin,get_option_float(OPTION_MOTION_RADIUS) * (222.50 / 24.0),1,0,0,255)
								default: show_ring(origin,get_option_float(OPTION_MOTION_RADIUS) * (222.50 / 24.0),1)
							}
						}
					}
					
					if (velocity > 200.0)
					{
						if (get_option(OPTION_AFFECT_OWNER) && i == owner)
						{
							make_explode(ent)
							return FMRES_IGNORED
						}
						if (!get_option(OPTION_TEAM_PLAY))
						{
							make_explode(ent)
							return FMRES_IGNORED
						}
						else
						{
							if (_:cs_get_user_team(i) != _:cs_get_user_team(owner))
							{
								make_explode(ent)
								return FMRES_IGNORED
							}
						}
						
						play_sound(ent, GEIGER)
					}
					else if (velocity == 0.0)
					{
						return FMRES_IGNORED
					}
					else
					{
						play_sound(ent, GEIGER)
					}
				}
			}
			return FMRES_IGNORED
}

public fw_cmdstart(id, uc_handle, seed)
{
	static bool:key[33] = { false, ... }
	
	if (!is_user_alive(id)) return FMRES_IGNORED
	
	static buttons
	buttons = get_uc(uc_handle, UC_Buttons)
	
	if ((buttons & IN_ATTACK2))
	{
		if (!key[id])
		{
			#if AMXX_VERSION_NUM < 180
			static dummy
			switch (get_user_weapon(id, dummy, dummy))
			{
				case CSW_HEGRENADE: changemode(id,GRENADE_EXPLOSIVE)
				case CSW_FLASHBANG: changemode(id,GRENADE_FLASHBANG)
				case CSW_SMOKEGRENADE: changemode(id,GRENADE_SMOKEGREN)
			}
			#endif
			
			#if AMXX_VERSION_NUM >= 180
			switch (get_user_weapon(id))
			{
				case CSW_HEGRENADE: changemode(id,GRENADE_EXPLOSIVE)
				case CSW_FLASHBANG: changemode(id,GRENADE_FLASHBANG)
				case CSW_SMOKEGRENADE: changemode(id,GRENADE_SMOKEGREN)
			}
			#endif
		}
		key[id] = true
	}
	else
	{
		key[id] = false
	}
	return FMRES_IGNORED
}

public is_mode_enabled(NadeType:type)
{
	switch (type)
	{
		case NADE_NORMAL:
		{
			return 1
		}
		
		case NADE_PROXIMITY:
		{
			return get_option(OPTION_PROXIMITY_ENABLED)
		}
		
		case NADE_IMPACT:
		{
			return get_option(OPTION_IMPACT_ENABLED)
		}
		
		case NADE_TRIP:
		{
			return get_option(OPTION_TRIP_ENABLED)
		}
		
		case NADE_MOTION:
		{
			return get_option(OPTION_MOTION_ENABLED)
		}
		
		case NADE_SATCHEL:
		{
			return get_option(OPTION_SATCHEL_ENABLED)
		}
	}
	return 1
}

public changemode(id,NADE_TYPE)
{
	if (cs_get_user_shield(id))
	{
		return
	}
	
	if (!(grenade_can_be_used(NADE_TYPE)))
	{
		return
	}
	
	if (!is_mode_enabled(++mode[id][NADE_TYPE]))
	{
		changemode(id,NADE_TYPE)
		return
	}
	
	switch (mode[id][NADE_TYPE])
	{
		case NADE_NORMAL:
		{
			client_print(id, print_center, "Режим гранаты - Обычный")
		}
		
		case NADE_PROXIMITY:
		{
			client_print(id, print_center, "Режим гранаты - Радиус")
		}
		
		case NADE_IMPACT:
		{
			client_print(id, print_center, "Режим гранаты - Ударная")
		}
		
		case NADE_TRIP:
		{
			client_print(id, print_center, "Mode - Trip laser")
		}
		
		case NADE_MOTION:
		{
			client_print(id, print_center, "Mode - Motion sensor")
		}
		
		default:
		{
			mode[id][NADE_TYPE] = NADE_NORMAL
			client_print(id, print_center, "Mode - Normal")
		}
	}
}

// Draw the line for the grenade.
stock draw_line_from_entity(entid, Float:end[3], staytime, R = 0, G = 214, B = 198)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_BEAMENTPOINT)
	write_short(entid)	// start entity
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(staytime)
	write_byte(10)
	write_byte(1)
	write_byte(R)
	write_byte(G)
	write_byte(B)
	write_byte(127)
	write_byte(1)
	message_end()	
}

stock clear_line(entid)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(entid)
	message_end();
}

stock show_ring(Float:origin[3], Float:addict, staytime, R = 0, G = 214, B = 198, speed = 0)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(21) // TE_BEAMCYLINDER //21
	engfunc(EngFunc_WriteCoord,origin[0]) // start X
	engfunc(EngFunc_WriteCoord,origin[1]) // start Y
	engfunc(EngFunc_WriteCoord,origin[2]) // start Z
	engfunc(EngFunc_WriteCoord,0.0) // something X
	engfunc(EngFunc_WriteCoord,0.0) // something Y
	engfunc(EngFunc_WriteCoord,addict) // something Z
	write_short(shockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(staytime) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(R) // red
	write_byte(G) // green
	write_byte(B) // blue
	write_byte(100) // brightness
	write_byte(speed) // speed
	message_end()
}

/*stock draw_spark(ent)
{
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	message_end()	
}*/

/* From HLSDK:
SOLID_NOT          0     No interaction with other objects
SOLID_TRIGGER      1     Touch on edge, but not blocking
SOLID_BBOX         2     Touch on edge, block
SOLID_SLIDEBOX     3     Touch on edge, but not an onground
SOLID_BSP          4     BSP clip, touch on edge, block
*/
public bool:is_solid(ent)
{
	// Here we account for ent = 0, where 0 means it's part of the map (and therefore is solid)
	return ( ent ? ( (pev(ent, pev_solid) > SOLID_TRIGGER) ? true : false ) : true )
}

public bool:is_attachable_surface(entity)
{
	static Float:velocity[3]
	
	if (pev_valid(entity))
	{
		if (!is_solid(entity)) return false // This is for func_breakables. The entity technically exists, but isn't solid.
		pev(entity, pev_velocity, velocity) // This is for func_doors. The grenade touches the door, causing it to move.
		return (xs_vec_equal(velocity, Float:{0.0, 0.0, 0.0}) ? true : false)
	}
	return true
}

public bool:is_grenade(ent)
{
	if (!pev_valid(ent)) return false
	
	static classname[32]
	static model[32]
	pev(ent, pev_classname, classname, 31)
	pev(ent, pev_model, model, 31)
	
	if (!equal(classname, "grenade")) return false
	
	for (new i=0;i<3;i++)
	{
		if (equal(NADE_MODEL[i],model))
			return true
	}
	
	return false
}

public set_grenade_type(grenade, NadeType:g_type)
{
	if (!pev_valid(grenade)) return
	
	switch (g_type)
	{
		case NADE_DUD:
		{
			set_pev(grenade, pev_movetype, MOVETYPE_BOUNCE)
			set_pev(grenade, pev_velocity, Float:{0.0, 0.0, 0.0})
			set_pev(grenade, pev_iuser1, _:NADE_DUD)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
		
		case NADE_NORMAL:
		{
			set_pev(grenade, pev_iuser1, _:NADE_NORMAL)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
		
		case NADE_PROXIMITY:
		{
			delay_explosion(grenade)
			set_grenade_allow_explode(grenade, get_option_float(OPTION_PROXIMITY_ARM_TIME))
			
			set_pev(grenade, pev_iuser1, _:NADE_PROXIMITY)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
		
		case NADE_IMPACT:
		{
			delay_explosion(grenade)
			set_pev(grenade, pev_movetype, MOVETYPE_BOUNCE)
			set_pev(grenade, pev_iuser1, _:NADE_IMPACT)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
		
		// I don't recommend setting a grenade to trip if it was another type in the first place.
		case NADE_TRIP:
		{
			delay_explosion(grenade)
			set_pev(grenade, pev_iuser1, _:NADE_TRIP)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
		
		case NADE_MOTION:
		{
			delay_explosion(grenade)
			set_grenade_allow_explode(grenade, get_option_float(OPTION_MOTION_ARM_TIME))
			
			set_pev(grenade, pev_iuser1, _:NADE_MOTION)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
		
		case NADE_SATCHEL:
		{
			delay_explosion(grenade)
			set_grenade_allow_explode(grenade,  get_option_float(OPTION_SATCHEL_ARM_TIME))
			
			set_pev(grenade, pev_iuser1, _:NADE_SATCHEL)
			set_pev(grenade, pev_iuser2, 0)
			set_pev(grenade, pev_iuser3, 0)
			set_pev(grenade, pev_iuser4, 0)
			
			set_pev(grenade, pev_vuser1, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser2, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser3, {0.0, 0.0, 0.0})
			set_pev(grenade, pev_vuser4, {0.0, 0.0, 0.0})
		}
	}
}

public NadeType:get_grenade_type(grenade)
{
	return NadeType:pev(grenade, pev_iuser1)
}

// General grenade stuff
public set_grenade_allow_explode(grenade, Float:seconds)
{
	static Float:gtime
	global_get(glb_time, gtime)
	set_pev(grenade, pev_fuser2, gtime + seconds)
}

public allow_grenade_explode(grenade)
{
	static Float:gtime, Float:dtime
	global_get(glb_time, gtime)
	pev(grenade, pev_fuser2, dtime)
	return (gtime < dtime) ? false : true
}

// Trip laser grenade stuff
public TripNadeMode:get_trip_grenade_mode(trip_grenade)
{
	return TripNadeMode:pev(trip_grenade, pev_iuser3)
}

public set_trip_grenade_mode(trip_grenade, TripNadeMode:mode)
{
	set_pev(trip_grenade, pev_iuser3, _:mode)
}

public set_trip_grenade_end_origin(trip_grenade, Float:end[3])
{
	set_pev(trip_grenade, pev_vuser1, end)
}

public get_trip_grenade_end_origin(trip_grenade, Float:end[3])
{
	pev(trip_grenade, pev_vuser1, end)
}

public set_trip_grenade_fly_velocity(trip_grenade, Float:fly[3])
{
	set_pev(trip_grenade, pev_vuser2,  fly)
}

public get_trip_grenade_fly_velocity(trip_grenade, Float:fly[3])
{
	pev(trip_grenade, pev_vuser2, fly)
}

public set_trip_grenade_attached_to(trip_grenade, entity_index)
{
	set_pev(trip_grenade, pev_iuser4, entity_index)
}

public get_trip_grenade_attached_to(trip_grenade)
{
	return pev(trip_grenade, pev_iuser4)
}

public set_trip_grenade_arm_time(trip_grenade, Float:seconds)
{
	new Float:gtime
	global_get(glb_time, gtime)
	set_pev(trip_grenade, pev_fuser1, gtime+seconds)
}

public Float:get_trip_grenade_arm_time(trip_grenade)
{
	new Float:time
	pev(trip_grenade, pev_fuser1, time)
	return time
}

public trip_grenade_action(trip_grenade, TripNadeAction:action)
{
	static hit, Float:origin[3], Float:point[3], trace = 0, Float:fraction, Float:normal[3], Float:temp[3], Float:end[3], Float:fly[3]
	
	pev(trip_grenade, pev_origin, origin)
	
	switch (action)
	{
		case TRIP_ACTION_INITIALIZE:
		{
			static loop[6][2] = { {2, 1}, {2, -1}, {0, 1}, {0, -1}, {1, 1}, {1, -1} }
			// Search in order:  +Z axis -Z axis +X axis -X axis  +Y axis -Y axis
			
			for (new i; i < 6; i++)
			{
				xs_vec_copy(origin, point)
				
				point[loop[i][0]] = origin[loop[i][0]] + (2.0 * float(loop[i][1]))
				
				engfunc(EngFunc_TraceLine, origin, point, IGNORE_MONSTERS, trip_grenade, trace)
				
				get_tr2(trace, TR_flFraction, fraction)
				
				if (fraction < 1.0)
				{
					hit = get_tr2(trace, TR_pHit)
					
					if (!is_attachable_surface(hit))
					{
						set_grenade_type(trip_grenade, NADE_DUD)
						return
					}
					
					get_tr2(trace, TR_vecPlaneNormal, normal)
					
					set_trip_grenade_attached_to(trip_grenade, hit)
					
					// Calculate and store fly velocity.
					xs_vec_mul_scalar(normal, get_option_float(OPTION_TRIP_FLY_SPEED), temp)
					set_trip_grenade_fly_velocity(trip_grenade, temp)
					
					// Calculate and store endpoint.
					xs_vec_mul_scalar(normal, get_option_float(OPTION_TRIP_DETECT_DISTANCE), temp)
					xs_vec_add(temp, origin, end)
					
					// Trace to it
					engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, trip_grenade, trace)
					get_tr2(trace, TR_flFraction, fraction)
					
					// Final endpoint with no possible wall collision
					xs_vec_mul_scalar(normal, (get_option_float(OPTION_TRIP_DETECT_DISTANCE) * fraction), temp)
					xs_vec_add(temp, origin, end)
					set_trip_grenade_end_origin(trip_grenade, end)
					
					set_trip_grenade_arm_time(trip_grenade, get_option_float(OPTION_TRIP_ARM_TIME))
					
					play_sound(trip_grenade, DEPLOY)
					
					set_pev(trip_grenade, pev_velocity, Float:{0.0, 0.0, 0.0})
					
					set_pev(trip_grenade, pev_sequence, 0) // Otherwise, grenade might make wierd motions.
					
					set_trip_grenade_mode(trip_grenade, TRIP_WAITING)
					
					set_task(0.1,"trip_activation",trip_grenade)
					
					return
				}
			}
			
			// If we reach here, we have serious problems. This means that the grenade hit something like a func_breakable
			// that disappeared before the scan was able to take place. Now, the grenade is floating in mid air. So we just
			// kaboom it!!!
			
			set_grenade_type(trip_grenade, NADE_NORMAL)
			make_explode(trip_grenade)
		}
		
		case TRIP_ACTION_WAIT:
		{
			if (!is_attachable_surface(get_trip_grenade_attached_to(trip_grenade)))
			{
				set_grenade_type(trip_grenade, NADE_DUD)
				return
			}
			
			static Float:gtime
			global_get(glb_time, gtime)
			if (gtime > get_trip_grenade_arm_time(trip_grenade))
			{
				set_trip_grenade_mode(trip_grenade, TRIP_SCANNING)
				play_sound(trip_grenade, ACTIVATE)
			}
		}
		
		case TRIP_ACTION_SCAN:
		{
			if (!is_attachable_surface(get_trip_grenade_attached_to(trip_grenade)))
			{
				set_grenade_type(trip_grenade, NADE_DUD)
				return
			}
			
			
			new Float:timeline
			pev(trip_grenade,pev_fuser4,timeline)
			
			if (timeline <= get_gametime() && get_option(OPTION_RESOURCE_USE))
			{
				new Float:end[3]
				get_trip_grenade_end_origin(trip_grenade,end)
				
				set_pev(trip_grenade,pev_fuser4,get_gametime() + 1.1)
				if (!get_option(OPTION_TEAM_PLAY))
					draw_line_from_entity(trip_grenade, end, 11, 0, 214, 198)
				else
				{
					new owner = pev(trip_grenade,pev_owner)
					new team = _:cs_get_user_team(owner)
					switch (team)
					{
						case CS_TEAM_T: draw_line_from_entity(trip_grenade, end,11 , 255, 0, 0)
						case CS_TEAM_CT: draw_line_from_entity(trip_grenade, end, 11, 0, 0, 255)
						default: draw_line_from_entity(trip_grenade, end, 11, 0, 214, 198)
					}
				}
			}
			
			get_trip_grenade_end_origin(trip_grenade, end)
			engfunc(EngFunc_TraceLine, end, origin, DONT_IGNORE_MONSTERS, 0, trace)
			
			if (is_user_alive(get_tr2(trace, TR_pHit)))
			{
				new target = get_tr2(trace, TR_pHit)
				new owner  = pev(trip_grenade,pev_owner)
				
				if (get_option(OPTION_AFFECT_OWNER) && owner == target)
					set_trip_grenade_mode(trip_grenade, TRIP_SHOULD_DETONATE)
				
				if (!get_option(OPTION_TEAM_PLAY))
				{
					set_trip_grenade_mode(trip_grenade, TRIP_SHOULD_DETONATE)
				}
				else
				{
					if (_:cs_get_user_team(owner) != _:cs_get_user_team(target))
						set_trip_grenade_mode(trip_grenade, TRIP_SHOULD_DETONATE)
				}
			}
		}
		
		case TRIP_ACTION_DETONATE:
		{
			new mode = get_trip_grenade_react_method(trip_grenade)
			clear_line(trip_grenade)
			play_sound(trip_grenade, ACTIVATE)
			
			if (mode == 0)
			{
				get_trip_grenade_fly_velocity(trip_grenade, fly)
				get_trip_grenade_end_origin(trip_grenade, end)
				set_pev(trip_grenade, pev_velocity, fly) // Send the grenade on its way.
				set_grenade_type(trip_grenade, NADE_IMPACT) // Kaboom!
			}
			else
			{
				make_explode(trip_grenade)
			}
		}
	}
}

public play_sound(ent, const sound[])
{
	if (!get_option(OPTION_PLAY_SOUNDS)) return
	
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, sound, 1.0, ATTN_STATIC, 0, PITCH_NORM)
}

public delay_explosion(grenade)
{
	static Float:gtime
	global_get(glb_time, gtime)
	set_pev(grenade, pev_dmgtime, gtime + 60000.0)
}

public make_explode(grenade)
{
	set_pev(grenade, pev_dmgtime, 0.0)
}

public get_option(Option:option)
{
	return (get_pcvar_num(pcvars[OPTION_ENABLE_NADE_MODES]) ? get_pcvar_num(pcvars[option]) : 0)
}

public toggle_option(Option:option)
{
	set_pcvar_num(pcvars[option], !get_option(option))
}

public Float:get_option_float(Option:option)
{
	return get_pcvar_float(pcvars[option])
}

public set_option_float(Option:option, Float:set_to)
{
	set_pcvar_float(pcvars[option], set_to)
}

public get_grenade_race(grenade)
{	
	static model[32]
	pev(grenade,pev_model,model,31)
	
	if (equal(model,NADE_MODEL[GRENADE_EXPLOSIVE])) return GRENADE_EXPLOSIVE
	if (equal(model,NADE_MODEL[GRENADE_FLASHBANG])) return GRENADE_FLASHBANG
	if (equal(model,NADE_MODEL[GRENADE_SMOKEGREN])) return GRENADE_SMOKEGREN
	
	return -1
}

public get_trip_grenade_react_method(grenade)
{
	new grenade_race = get_grenade_race(grenade)
	
	switch (grenade_race)
	{
		case GRENADE_EXPLOSIVE: return get_option(OPTION_TRIP_G_REACT)
		case GRENADE_FLASHBANG: return get_option(OPTION_TRIP_F_REACT)
		case GRENADE_SMOKEGREN: return get_option(OPTION_TRIP_S_REACT)
	}
	
	return FMRES_IGNORED
}

public trip_activation(ent)
{
	play_sound(ent,CHARGE)
}

bool:grenade_can_be_used(nade_type)
{
	if (get_option(OPTION_NADES_IN_EFFECT) & NADE_BIT[nade_type]) return true
	return false
}

public zp_user_humanized_pre(id)
{
	mode[id][0] = NADE_NORMAL
	mode[id][1] = NADE_NORMAL
	mode[id][2] = NADE_NORMAL
	
	new strtype[11] = "classname", ent = -1;
	new classname[30] = "grenade"
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) == id) 
	{
		if(is_grenade(ent) && get_grenade_type(ent) != NADE_NORMAL)
			engfunc(EngFunc_RemoveEntity,ent)
	}
	
	return PLUGIN_CONTINUE
}

public event_infect(id, attacker)
{
	mode[id][0] = NADE_NORMAL
	mode[id][1] = NADE_NORMAL
	mode[id][2] = NADE_NORMAL
	
	new strtype[11] = "classname", ent = -1;
	new classname[30] = "grenade"
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) == id) 
	{
		if(is_grenade(ent) && get_grenade_type(ent) != NADE_NORMAL)
			engfunc(EngFunc_RemoveEntity,ent)
	}
	
	return PLUGIN_CONTINUE
}