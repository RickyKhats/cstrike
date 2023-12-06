#if defined _cstrike2_included
  #endinput
#endif
#define _cstrike2_included

#include <fakemeta>

#define EXTRAOFFSET_WEAPONS			4 // weapon offsets are obviously only 4 steps higher on Linux!
#define ACTUAL_EXTRA_OFFSET			20

#define OFFSET_ARMORTYPE			112
#define OFFSET_TEAM				114
#define OFFSET_CSMONEY			115
#define OFFSET_PRIMARYWEAPON		116
#define OFFSET_LASTACTIVITY		124
#define OFFSET_INTERNALMODEL		126
#define OFFSET_NVGOGGLES			129
#define OFFSET_DEFUSE_PLANT		193
#define OFFSET_VIP				209
#define OFFSET_TK				216 // 040926
#define OFFSET_HOSTAGEKILLS		217
#define OFFSET_MAPZONE			235
#define OFFSET_ISDRIVING			350 // 040926
#define OFFSET_STATIONARY		362 // 040927 (363 works also!)
#define OFFSET_ZOOMTYPE			363

#define OFFSET_AWM_AMMO			377 // 041029: All of these *_AMMO:s were changed -5
#define OFFSET_SCOUT_AMMO		378
#define OFFSET_PARA_AMMO			379
#define OFFSET_FAMAS_AMMO		380
#define OFFSET_M3_AMMO			381
#define OFFSET_USP_AMMO			382
#define OFFSET_FIVESEVEN_AMMO		383
#define OFFSET_DEAGLE_AMMO		384
#define OFFSET_P228_AMMO			385
#define OFFSET_GLOCK_AMMO		386
#define OFFSET_FLASH_AMMO		387
#define OFFSET_HE_AMMO			388
#define OFFSET_SMOKE_AMMO		389
#define OFFSET_C4_AMMO			390

#define OFFSET_CSDEATHS			444 // 040926
#define OFFSET_SHIELD			510
// "weapon_*" entities
#define OFFSET_WEAPONTYPE		43 //+ EXTRA_OFFSET_WEAPONS
#define OFFSET_CLIPAMMO			51 //+ EXTRA_OFFSET_WEAPONS
#define OFFSET_SILENCER_FIREMODE	74 //+ EXTRA_OFFSET_WEAPONS
// "hostage_entity" entities
#define OFFSET_HOSTAGEFOLLOW		86
#define OFFSET_HOSTAGE_NEXTUSE	100
#define OFFSET_HOSTAGE_LASTUSE	483
#define OFFSET_HOSTAGEID			487
// "armoury_entity"
#define OFFSET_ARMOURY_TYPE		34 //+ EXTRA_OFFSET_WEAPONS
// C4 offsets
#define OFFSET_C4_EXPLODE_TIME	100
#define OFFSET_C4_DEFUSING		0x181 //+ ACTUAL_EXTRA_OFFSET

// These are used with armoury_entity:s.
#define CSA_MP5NAVY						0
#define CSA_TMP							1
#define CSA_P90							2
#define CSA_MAC10						3
#define CSA_AK47						4
#define CSA_SG552						5
#define CSA_M4A1						6
#define CSA_AUG							7
#define CSA_SCOUT						8
#define CSA_G3SG1						9
#define CSA_AWP							10
#define CSA_M3							11
#define CSA_XM1014						12
#define CSA_M249						13
#define CSA_FLASHBANG					14
#define CSA_HEGRENADE					15
#define CSA_VEST						16
#define CSA_VESTHELM					17
#define CSA_SMOKEGRENADE				18

#define M4A1_SILENCED					(1<<2)
#define M4A1_ATTACHSILENCEANIM			6
#define M4A1_DETACHSILENCEANIM			13
#define USP_SILENCED					(1<<0)
#define USP_ATTACHSILENCEANIM			7
#define USP_DETACHSILENCEANIM			15

#define GLOCK_SEMIAUTOMATIC				0
#define GLOCK_BURSTMODE					2
#define FAMAS_AUTOMATIC					0
#define FAMAS_BURSTMODE					16

#define PLAYER_IS_VIP					(1<<8)

#define PLAYER_IN_BUYZONE				(1<<0)

#define TEAM_UNASSIGNED					0
#define TEAM_T							1
#define TEAM_CT							2
#define TEAM_SPECTATOR					3

#define CAN_PLANT_BOMB					(1<<8) // 256
#define HAS_DEFUSE_KIT					(1<<16) // 65536

#define DEFUSER_COLOUR_R				0
#define DEFUSER_COLOUR_G				160
#define DEFUSER_COLOUR_B				0

#define HAS_NVGOGGLES					(1<<0)
#define HAS_SHIELD					(1<<24)

#define SCOREATTRIB_NOTHING				0
#define SCOREATTRIB_DEAD				1
#define SCOREATTRIB_BOMB				2 // t only
#define SCOREATTRIB_VIP					4 // ct only

/*#define CS_ARMOR_NONE					0
#define CS_ARMOR_KEVLAR					1
#define CS_ARMOR_ ASSAULTSUIT			2*/

#define CS_FIRST_ZOOM					0x28
#define CS_SECOND_AWP_ZOOM				0xA
#define CS_SECOND_NONAWP_ZOOM			0xF
#define CS_AUGSG552_ZOOM				0x37
#define CS_NO_ZOOM						0x5A

enum CS_Internal_Models {
	CS_DONTCHANGE = 0,
	CS_CT_URBAN = 1,
	CS_T_TERROR = 2,
	CS_T_LEET = 3,
	CS_T_ARCTIC = 4,
	CS_CT_GSG9 = 5,
	CS_CT_GIGN = 6,
	CS_CT_SAS = 7,
	CS_T_GUERILLA = 8,
	CS_CT_VIP = 9,
	CZ_T_MILITIA = 10,
	CZ_CT_SPETSNAZ = 11
};

enum CsTeams {
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T = 1,
	CS_TEAM_CT = 2,
	CS_TEAM_SPECTATOR = 3
};

enum CsArmorType {
	CS_ARMOR_NONE = 0, // no armor
	CS_ARMOR_KEVLAR = 1, // armor
	CS_ARMOR_VESTHELM = 2 // armor and helmet
};

enum
{
	CS_RESET_ZOOM = 0,
	CS_SET_NO_ZOOM,
	CS_SET_FIRST_ZOOM,
	CS_SET_SECOND_ZOOM,
	CS_SET_AUGSG552_ZOOM,
};

stock bool:is_player(id)
{
	new classname[32]
	pev(id, pev_classname, classname, 31)
	if(strcmp(classname, "player") != 0 )
		return false
	return true
}

stock cs_set_user_money(index, money, flash = 1)
{
	set_pdata_int(index, OFFSET_CSMONEY, money)
	message_begin(MSG_ONE, get_user_msgid("Money"), _, index)
	write_long(money)
	write_byte(flash ? 1 : 0)
	message_end()
}

stock cs_get_user_money(index)
{
	return get_pdata_int(index, OFFSET_CSMONEY)
}

stock cs_get_user_deaths(id)
{
	return get_pdata_int(id, OFFSET_CSDEATHS)
}

stock cs_set_user_frags(id, newfrags)
{
	new deaths = get_pdata_int(id, OFFSET_CSDEATHS)
	
	set_pev(id, pev_frags, float(newfrags))
	
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(id)
	write_short(newfrags)
	write_short(deaths)
	write_short(0)
	write_short(get_pdata_int(id, OFFSET_TEAM))
	message_end()
}

stock cs_set_user_deaths(id, newdeaths)
{
	new Float:frags
	pev(id, pev_frags, frags)

	set_pdata_int(id, OFFSET_CSDEATHS, newdeaths)

	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(id)
	write_short(floatround(frags))
	write_short(newdeaths)
	write_short(0)
	write_short(get_pdata_int(id, OFFSET_TEAM))
	message_end()
}

stock cs_get_hostage_id(hostage_id)
{
	new classname[32]
	pev(hostage_id, pev_classname, classname, 31)

	if(strcmp(classname, "hostage_entity") != 0)
		return 0

	return get_pdata_int(hostage_id, OFFSET_HOSTAGEID)
}

stock cs_get_weapon_silen(ent)
{
	new weapontype, silencemode
	weapontype = get_pdata_int(ent, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
	silencemode = get_pdata_int(ent, OFFSET_SILENCER_FIREMODE, EXTRAOFFSET_WEAPONS)
	switch(weapontype) {
		case CSW_USP:
			if(silencemode & USP_SILENCED)
				return 1
		case CSW_M4A1:
			if(silencemode & M4A1_SILENCED)
				return 1
	}
	return 0
}

stock cs_get_weapon_id(weapon_id)
{
	return get_pdata_int(weapon_id, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
}

stock cs_set_weapon_silen(weapon_id, silence=1, draw_animation=1)
{
	new weapontype, silencemode, owner
	weapontype = get_pdata_int(weapon_id, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
	silencemode = get_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, EXTRAOFFSET_WEAPONS)

	switch(weapontype)
	{
		case CSW_M4A1: {
		if(silence == 1) {
			if(!(silencemode & M4A1_SILENCED)) {
				silencemode |= M4A1_SILENCED
				set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, silencemode, EXTRAOFFSET_WEAPONS)
				owner = pev(weapon_id, pev_owner)
				if(draw_animation && is_player(owner))
					set_pev(owner, pev_weaponanim, M4A1_ATTACHSILENCEANIM)
			}
		}
		else if(silencemode & M4A1_SILENCED) {
			silencemode &= ~M4A1_SILENCED
			set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, silencemode, EXTRAOFFSET_WEAPONS)
			owner = pev(weapon_id, pev_owner)
			if(draw_animation && is_player(owner))
				set_pev(owner, pev_weaponanim, M4A1_DETACHSILENCEANIM)
		}
	}
	case CSW_USP: {
		if(silence == 1) {
			if(!(silencemode & USP_SILENCED)) {
				silencemode |= USP_SILENCED
				set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, silencemode, EXTRAOFFSET_WEAPONS)
				owner = pev(weapon_id, pev_owner)
				if(draw_animation && is_player(owner))
					set_pev(owner, pev_weaponanim, USP_ATTACHSILENCEANIM)
			}
		}
		else if(silencemode & USP_SILENCED) {
			silencemode &= ~USP_SILENCED
			set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, silencemode, EXTRAOFFSET_WEAPONS)
			owner = pev(weapon_id, pev_owner)
			if(draw_animation && is_player(owner))
				set_pev(owner, pev_weaponanim, USP_DETACHSILENCEANIM)
		}
	}
	default:
		return 0
	}
	return 1
}

stock cs_get_weapon_burst(ent)
{
	new weapontype, firemode
	weapontype = get_pdata_int(ent, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
	firemode = get_pdata_int(ent, OFFSET_SILENCER_FIREMODE, EXTRAOFFSET_WEAPONS)
	switch(weapontype)
	{
		case CSW_GLOCK18:
			if(firemode == GLOCK_BURSTMODE)
				return 1
		case CSW_FAMAS:
			if(firemode == FAMAS_BURSTMODE)
				return 1
	}
	return 0
}

stock cs_set_weapon_burst(weapon_id, burstmode=1)
{
	new weapontype = get_pdata_int(weapon_id, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
	new firemode = get_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, EXTRAOFFSET_WEAPONS)
	new previousMode = firemode

	switch (weapontype)
	{
		case CSW_GLOCK18: {
			if(burstmode) {
				if (previousMode != GLOCK_BURSTMODE) {
					firemode = GLOCK_BURSTMODE
					set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, firemode, EXTRAOFFSET_WEAPONS)

					new owner = pev(weapon_id, pev_owner)
					if(is_player(owner)) {
						message_begin(MSG_ONE, get_user_msgid("TextMsg"), _, owner)
						write_byte(4)
						write_string("#Switch_To_BurstFire")
						message_end()
					}
				}
			}
			else if (previousMode != GLOCK_SEMIAUTOMATIC) {
				firemode = GLOCK_SEMIAUTOMATIC
				set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, firemode, EXTRAOFFSET_WEAPONS)

				new owner = pev(weapon_id, pev_owner)
				if(is_player(owner)) {
					message_begin(MSG_ONE, get_user_msgid("TextMsg"), _, owner)
					write_byte(4)
					write_string("#Switch_To_SemiAuto")
					message_end()
				}
			}
		}
		case CSW_FAMAS: {
			if (burstmode) {
				if (previousMode != FAMAS_BURSTMODE) {
					firemode = FAMAS_BURSTMODE
					set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, firemode, EXTRAOFFSET_WEAPONS)

					new owner = pev(weapon_id, pev_owner)
					if(is_player(owner)) {
						message_begin(MSG_ONE, get_user_msgid("TextMsg"), _, owner)
						write_byte(4)
						write_string("#Switch_To_BurstFire")
						message_end()
					}
				}
			}
			else if (previousMode != FAMAS_AUTOMATIC) {
				firemode = FAMAS_AUTOMATIC
				set_pdata_int(weapon_id, OFFSET_SILENCER_FIREMODE, firemode, EXTRAOFFSET_WEAPONS)

				new owner = pev(weapon_id, pev_owner)
				if(is_player(owner)) {
					message_begin(MSG_ONE, get_user_msgid("TextMsg"), _, owner)
					write_byte(4)
					write_string("#Switch_To_FullAuto")
					message_end()
				}
			}
		}
		default:
			return 0
	}
	return 1
}

stock cs_get_user_armor(id, &CsArmorType:armortype)
{
	switch(get_pdata_int(id, OFFSET_ARMORTYPE))
	{
		case 0: armortype = CS_ARMOR_NONE
		case 1: armortype = CS_ARMOR_KEVLAR
		case 2: armortype = CS_ARMOR_VESTHELM
	}
	return floatround(pev(id, pev_armorvalue)))
}

stock cs_set_user_armor(id, armorvalue, CsArmorType:armortype)
{
	switch(armortype) {
		case CS_ARMOR_NONE: set_pdata_int(id, OFFSET_ARMORTYPE, 0)
		case CS_ARMOR_KEVLAR: set_pdata_int(id, OFFSET_ARMORTYPE, 1)
		case CS_ARMOR_VESTHELM: set_pdata_int(id, OFFSET_ARMORTYPE, 2)
	}
	set_pev(id, pev_armorvalue, float(armorvalue))
	if(armortype == CS_ARMOR_KEVLAR || armortype == CS_ARMOR_VESTHELM)
	{
		message_begin(MSG_ONE, get_user_msgid("ArmorType"), _, id)
		write_byte((armortype == CS_ARMOR_VESTHELM) ? 1 : 0)
		message_end()
	}
}

stock cs_get_user_vip(id)
{
	if(get_pdata_int(id, OFFSET_VIP) & PLAYER_IS_VIP)
		return 1
	return 0
}

stock cs_set_user_vip(id, vip=1, model=1, scoreboard=1)
{
	if(vip == 1)
	{
		set_pdata_int(id, OFFSET_VIP, get_pdata_int(id, OFFSET_VIP) | PLAYER_IS_VIP)
		if(model == 1) {
			set_pdata_int(id, OFFSET_INTERNALMODEL, CS_CT_VIP)
			dllfunc(DLLFunc_ClientUserInfoChanged, id)
		}
		if(scoreboard == 1)
		{
			message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"))
			write_byte(id)
			write_byte(SCOREATTRIB_VIP)
			message_end()
		}
	}
	else
	{
		set_pdata_int(id, OFFSET_VIP, get_pdata_int(id, OFFSET_VIP) & ~PLAYER_IS_VIP)

		if(model == 1)
		{
			new CS_Internal_Models:CTmodels[4] = {CS_CT_URBAN, CS_CT_GSG9, CS_CT_GIGN, CS_CT_SAS/*, CZ_CT_SPETSNAZ*/}
			new CS_Internal_Models:ct_model = CTmodels[random_num(0, 3)]
			set_pdata_int(id, OFFSET_INTERNALMODEL, CTenum[randnum])
			dllfunc(DLLFunc_ClientUserInfoChanged, id)
		}

		if(scoreboard == 1)
		{
			new scoreattrib, Float:health
			pev(id, pev_health, health)
			if(pev(id, pev_deadflag) == DEAD_NO && health > 0.0)
				scoreattrib = SCOREATTRIB_NOTHING
			else
				scoreattrib = SCOREATTRIB_DEAD
			message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"))
			write_byte(id)
			write_byte(scoreattrib)
			message_end()
		}
	}
	return 1
}

stock CsTeams:cs_get_user_team(id, &{CS_Internal_Models,_}:model = CS_DONTCHANGE)
{
	model = CS_Internal_Models:get_pdata_int(id, OFFSET_INTERNALMODEL)

	return CsTeams:get_pdata_int(id, OFFSET_TEAM)
}

stock cs_set_user_team(id, {CsTeams,_}:team, {CS_Internal_Models,_}:model = CS_DONTCHANGE)
{
	switch(team)
	{
		case CS_TEAM_T: set_pdata_int(id, OFFSET_TEAM, 1)
		case CS_TEAM_CT: set_pdata_int(id, OFFSET_TEAM, 2)
		case CS_TEAM_SPECTATOR: set_pdata_int(id, OFFSET_TEAM, 3)
	}

	if(model)
	{
		switch(model)
		{
			case CS_CT_URBAN:set_pdata_int(id, OFFSET_INTERNALMODEL, 1)
			case CS_T_TERROR:set_pdata_int(id, OFFSET_INTERNALMODEL, 2)
			case CS_T_LEET:set_pdata_int(id, OFFSET_INTERNALMODEL, 3)
			case CS_T_ARCTIC:set_pdata_int(id, OFFSET_INTERNALMODEL, 4)
			case CS_CT_GSG9:set_pdata_int(id, OFFSET_INTERNALMODEL, 5)
			case CS_CT_GIGN:set_pdata_int(id, OFFSET_INTERNALMODEL, 6)
			case CS_CT_SAS:set_pdata_int(id, OFFSET_INTERNALMODEL, 7)
			case CS_T_GUERILLA:set_pdata_int(id, OFFSET_INTERNALMODEL, 8)
			case CS_CT_VIP:set_pdata_int(id, OFFSET_INTERNALMODEL, 9)
			case CZ_T_MILITIA:set_pdata_int(id, OFFSET_INTERNALMODEL, 10)
			case CZ_CT_SPETSNAZ:set_pdata_int(id, OFFSET_INTERNALMODEL, 11)
		}
	}

	dllfunc(DLLFunc_ClientUserInfoChanged, id)

	new teaminfo[11]
	switch(team)
	{
		case TEAM_UNASSIGNED: 
		{
			formatex(teaminfo, 10, "UNASSIGNED")
		}
		case TEAM_T: 
		{
			formatex(teaminfo, 10, "TERRORIST")
		}
		case TEAM_CT: 
		{
			formatex(teaminfo, 10, "CT")
		}
		case TEAM_SPECTATOR:
		{
			formatex(teaminfo, 10, "SPECTATOR")
		}
	}
	
	message_begin(MSG_ALL, get_user_msgid("TeamInfo"))
	write_byte(id)
	write_string(teaminfo)
	message_end()

	/*if (params[2] == 1)
		MF_SetPlayerTeamInfo(params[1], params[2], "TERRORIST");
	else if (params[2] == 2)
		MF_SetPlayerTeamInfo(params[1], params[2], "CT");
	else
		MF_SetPlayerTeamInfo(params[1], params[2], NULL);
	*/
}

stock cs_get_user_buyzone(id)
{
	if(get_pdata_int(id, OFFSET_MAPZONE) & PLAYER_IN_BUYZONE)
		return 1
	return 0
}

stock cs_get_user_mapzones(id) {
	return get_pdata_int(id, OFFSET_MAPZONE)
}

stock cs_get_user_plant(id)
{
	if(get_pdata_int(id, OFFSET_DEFUSE_PLANT) & CAN_PLANT_BOMB)
		return 1
	return 0
}

stock cs_set_user_plant(id, plant=1, showbombicon=1)
{
	new plantskill = get_pdata_int(id, OFFSET_DEFUSE_PLANT)

	if(plant)
	{
		plantskill |= CAN_PLANT_BOMB
		set_pdata_int(id, OFFSET_DEFUSE_PLANT, plantskill)
		if(showbombicon)
		{
			message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id)
			write_byte(1)
			write_string("c4")
			write_byte(DEFUSER_COLOUR_R)
			write_byte(DEFUSER_COLOUR_G)
			write_byte(DEFUSER_COLOUR_B)
			message_end()
		}
	}
	else
	{
		plantskill &= ~CAN_PLANT_BOMB
		set_pdata_int(id, OFFSET_DEFUSE_PLANT, plantskill)
		message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id)
		write_byte(0)
		write_string("c4")
		message_end()
	}
}

stock cs_get_user_defuse(id)
{
	if(get_pdata_int(id, OFFSET_DEFUSE_PLANT) & HAS_DEFUSE_KIT)
		return 1
	return 0
}

stock cs_set_user_defuse(id, defusekit=1, r=DEFUSER_COLOUR_R, g=DEFUSER_COLOUR_G, b=DEFUSER_COLOUR_B, icon[]="defuser", flash=0)
{
	new defuse = get_pdata_int(id, OFFSET_DEFUSE_PLANT)

	if(defusekit)
	{
		new colour[3] = {DEFUSER_COLOUR_R, DEFUSER_COLOUR_G, DEFUSER_COLOUR_B}
		if(r != -1) colour[0] = r
		if(g != -1) colour[1] = g
		if(b != -1) colour[2] = b
    
    		set_pev(id, pev_body, 1)

		defuse |= HAS_DEFUSE_KIT
		set_pdata_int(id, OFFSET_DEFUSE_PLANT, defuse)
		message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id)
		write_byte((flash == 1) ? 2 : 1)
		write_string(icon[0] ? icon : "defuser")
		write_byte(colour[0])
		write_byte(colour[1])
		write_byte(colour[2])
		message_end()
	}
	else
	{
		defuse &= ~HAS_DEFUSE_KIT
		set_pdata_int(id, OFFSET_DEFUSE_PLANT, defuse)
		message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id)
		write_byte(0)
		write_string("defuser")
		message_end()
		set_pev(id, pev_body, 0)
	}
}

stock cs_get_user_bpammo(id, weapon) {

	new offset

	switch (weapon) {
		case CSW_AWP:
			offset = OFFSET_AWM_AMMO

		case CSW_SCOUT,
			CSW_AK47,
			CSW_G3SG1:
			offset = OFFSET_SCOUT_AMMO

		case CSW_M249:
			offset = OFFSET_PARA_AMMO

		case CSW_FAMAS,
			CSW_M4A1,
			CSW_AUG,
			CSW_SG550,
			CSW_GALI,
			CSW_SG552:
			offset = OFFSET_FAMAS_AMMO

		case CSW_M3,
			CSW_XM1014:
			offset = OFFSET_M3_AMMO

		case CSW_USP,
			CSW_UMP45,
			CSW_MAC10:
			offset = OFFSET_USP_AMMO

		case CSW_FIVESEVEN,
			CSW_P90:
			offset = OFFSET_FIVESEVEN_AMMO

		case CSW_DEAGLE:
			offset = OFFSET_DEAGLE_AMMO

		case CSW_P228:
			offset = OFFSET_P228_AMMO

		case CSW_GLOCK18,
			CSW_MP5NAVY,
			CSW_TMP,
			CSW_ELITE:
			offset = OFFSET_GLOCK_AMMO

		case CSW_FLASHBANG:
			offset = OFFSET_FLASH_AMMO

		case CSW_HEGRENADE:
			offset = OFFSET_HE_AMMO

		case CSW_SMOKEGRENADE:
			offset = OFFSET_SMOKE_AMMO

		case CSW_C4:
			offset = OFFSET_C4_AMMO

		default:return 0
	}
	return get_pdata_int(id, offset)
}

stock cs_set_user_bpammo(id, weapon, amount) {

	new offset

	switch (weapon) {
		case CSW_AWP:
			offset = OFFSET_AWM_AMMO

		case CSW_SCOUT,
			CSW_AK47,
			CSW_G3SG1:
			offset = OFFSET_SCOUT_AMMO

		case CSW_M249:
			offset = OFFSET_PARA_AMMO

		case CSW_FAMAS,
			CSW_M4A1,
			CSW_AUG,
			CSW_SG550,
			CSW_GALI,
			CSW_SG552:
			offset = OFFSET_FAMAS_AMMO

		case CSW_M3,
			CSW_XM1014:
			offset = OFFSET_M3_AMMO

		case CSW_USP,
			CSW_UMP45,
			CSW_MAC10:
			offset = OFFSET_USP_AMMO

		case CSW_FIVESEVEN,
			CSW_P90:
			offset = OFFSET_FIVESEVEN_AMMO

		case CSW_DEAGLE:
			offset = OFFSET_DEAGLE_AMMO

		case CSW_P228:
			offset = OFFSET_P228_AMMO

		case CSW_GLOCK18,
			CSW_MP5NAVY,
			CSW_TMP,
			CSW_ELITE:
			offset = OFFSET_GLOCK_AMMO

		case CSW_FLASHBANG:
			offset = OFFSET_FLASH_AMMO

		case CSW_HEGRENADE:
			offset = OFFSET_HE_AMMO

		case CSW_SMOKEGRENADE:
			offset = OFFSET_SMOKE_AMMO

		case CSW_C4:
			offset = OFFSET_C4_AMMO

		default:return 0
	}
	set_pdata_int(id, offset, amount)

	return 1
}

stock cs_get_user_nvg(id)
{
	if(get_pdata_int(id, OFFSET_NVGOGGLES) & HAS_NVGOGGLES)
		return 1
	return 0
}

stock cs_set_user_nvg(id, nvgoggles=1)
{
	new defusekit = get_pdata_int(id, OFFSET_NVGOGGLES)

	if(nvgoggles)
	{
		if (defusekit & HAS_NVGOGGLES)
		{
			message_begin(MSG_ONE, get_user_msgid("TextMsg"), _, id)
			write_byte(4)
			write_string("#Already_Have_One")
			message_end()
		}
		else
		{
			defusekit |= HAS_NVGOGGLES
			set_pdata_int(id, OFFSET_NVGOGGLES, defusekit)
		}
	}
	else
	{
		defusekit &= ~HAS_NVGOGGLES
		set_pdata_int(id, OFFSET_NVGOGGLES, defusekit)
	}
}

stock cs_get_user_model(id, model[], len)
{
	new buffer = engfunc(EngFunc_GetInfoKeyBuffer, id)
	engfunc(EngFunc_InfoKeyValue, buffer, "model", model, len)
}

stock cs_get_hostage_foll(hostage_id)
{
	return get_pdata_int(hostage_id, OFFSET_HOSTAGEFOLLOW)
}

stock cs_set_hostage_foll(hostage_id, followedid=0)
{
	new classname[32]
	pev(hostage_id, pev_classname, classname, 31)
	if(strcmp(classname, "hostage_entity") != 0)
		return 0

	if(followedid == 0)
	{
		set_pdata_int(hostage_id, OFFSET_HOSTAGEFOLLOW, 0)
		return 1
	}

	set_pdata_int(hostage_id, OFFSET_HOSTAGEFOLLOW, followedid)
	return 1
}

stock cs_get_weapon_ammo(weapon_id)
{
	return get_pdata_int(weapon_id, OFFSET_CLIPAMMO, EXTRAOFFSET_WEAPONS)
}

stock cs_set_weapon_ammo(weapon_id, newammo)
{
	set_pdata_int(weapon_id, OFFSET_CLIPAMMO, newammo, EXTRAOFFSET_WEAPONS)
}

stock cs_get_user_hasprim(id)
{
	return get_pdata_int(id, OFFSET_PRIMARYWEAPON)
}

stock cs_get_user_tked(id)
{
	return get_pdata_int(id, OFFSET_TK)
}

stock cs_set_user_tked(id, tk=1, subtract=1)
{
	if(tk)
		set_pdata_int(id, OFFSET_TK, 1)
	else
		set_pdata_int(id, OFFSET_TK, 0)

	if(subtract)
	{
		new frags
		pev(id, pev_frags, frags)
		pev(id, pev_frags, frags - float(subtract))

		message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
		write_byte(id)
		write_short(floatround(frags))
		write_short(get_pdata_int(id, OFFSET_CSDEATHS))
		write_short(0)
		write_short(get_pdata_int(id, OFFSET_TEAM))
		message_end()
	}
}

stock cs_get_user_driving(id)
{
	return get_pdata_int(id, OFFSET_ISDRIVING)
}

stock cs_get_user_stationary(id)
{
	return get_pdata_int(id, OFFSET_STATIONARY)
}

stock cs_get_user_shield(id)
{
	if (get_pdata_int(id, OFFSET_SHIELD) & HAS_SHIELD)
		return 1
	return 0
}

stock cs_user_spawn(id) {
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	dllfunc(DLLFunc_Spawn, id)
	set_pev(id, pev_iuser1, 0)
}

stock cs_get_armoury_type(ent_id)
{
	new classname[32]
	pev(ent_id, pev_classname, classname, 31)
	if(strcmp(classname, "armoury_entity") != 0)
		return 0

	new weapontype = get_pdata_int(ent_id, OFFSET_ARMOURY_TYPE, EXTRAOFFSET_WEAPONS)

	new weapontype_out
	switch(weapontype)
	{
		case CSA_MP5NAVY:       weapontype_out = CSW_MP5NAVY
		case CSA_TMP:           weapontype_out = CSW_TMP
		case CSA_P90:           weapontype_out = CSW_P90
		case CSA_MAC10:         weapontype_out = CSW_MAC10
		case CSA_AK47:          weapontype_out = CSW_AK47
		case CSA_SG552:         weapontype_out = CSW_SG552
		case CSA_M4A1:          weapontype_out = CSW_M4A1
		case CSA_AUG:           weapontype_out = CSW_AUG
		case CSA_SCOUT:         weapontype_out = CSW_SCOUT
		case CSA_G3SG1:         weapontype_out = CSW_G3SG1
		case CSA_AWP:           weapontype_out = CSW_AWP
		case CSA_M3:            weapontype_out = CSW_M3
		case CSA_XM1014:        weapontype_out = CSW_XM1014
		case CSA_M249:          weapontype_out = CSW_M249
		case CSA_FLASHBANG:     weapontype_out = CSW_FLASHBANG
		case CSA_HEGRENADE:     weapontype_out = CSW_HEGRENADE
		case CSA_VEST:          weapontype_out = CSW_VEST
		case CSA_VESTHELM:      weapontype_out = CSW_VESTHELM
		case CSA_SMOKEGRENADE:  weapontype_out = CSW_SMOKEGRENADE
		default: return 0
	}
	return weapontype_out
}

stock cs_set_armoury_type(ent_id, type)
{
	new classname[32]
	pev(ent_id, pev_classname, classname, 31)
	if(strcmp(classname, "armoury_entity") != 0)
		return 0

	new weapontype
	switch(type)
	{
		case CSW_MP5NAVY:       weapontype = CSA_MP5NAVY
		case CSW_TMP:           weapontype = CSA_TMP
		case CSW_P90:           weapontype = CSA_P90
		case CSW_MAC10:         weapontype = CSA_MAC10
		case CSW_AK47:          weapontype = CSA_AK47
		case CSW_SG552:         weapontype = CSA_SG552
		case CSW_M4A1:          weapontype = CSA_M4A1
		case CSW_AUG:           weapontype = CSA_AUG
		case CSW_SCOUT:         weapontype = CSA_SCOUT
		case CSW_G3SG1:         weapontype = CSA_G3SG1
		case CSW_AWP:           weapontype = CSA_AWP
		case CSW_M3:            weapontype = CSA_M3
		case CSW_XM1014:        weapontype = CSA_XM1014
		case CSW_M249:          weapontype = CSA_M249
		case CSW_FLASHBANG:     weapontype = CSA_FLASHBANG
		case CSW_HEGRENADE:     weapontype = CSA_HEGRENADE
		case CSW_VEST:          weapontype = CSA_VEST
		case CSW_VESTHELM:      weapontype = CSA_VESTHELM
		case CSW_SMOKEGRENADE:  weapontype = CSA_SMOKEGRENADE
		default:return 0
	}

	set_pdata_int(ent_id, OFFSET_ARMOURY_TYPE, weapontype, EXTRAOFFSET_WEAPONS)

	return 1
}

stock cs_get_user_zoom(id)
{
	new value = get_pdata_int(id, OFFSET_ZOOMTYPE)
	switch (value)
	{
		case CS_NO_ZOOM:
			return CS_SET_NO_ZOOM
		case CS_FIRST_ZOOM:
			return CS_SET_FIRST_ZOOM
		case CS_SECOND_AWP_ZOOM,
			CS_SECOND_NONAWP_ZOOM:
			return CS_SET_SECOND_ZOOM
		case CS_AUGSG552_ZOOM:
			return CS_SET_AUGSG552_ZOOM
	}
	return 0
}

stock cs_get_user_submodel(id)
{
	return pev(id, pev_body)
}

stock cs_set_user_submodel(id, value)
{
	set_pev(id, pev_body, value)
}

stock Float:cs_get_user_lastactivity(id)
{
	return Float:get_pdata_float(id, OFFSET_LASTACTIVITY)
}

stock cs_set_user_lastactivity(id, Float:value)
{
	set_pdata_float(id, OFFSET_LASTACTIVITY, value)
}

stock cs_get_user_hostagekills(id)
{
	return get_user_pdata(id, OFFSET_HOSTAGEKILLS)
}

stock cs_set_user_hostagekills(id, value)
{
	set_user_pdata(id, OFFSET_HOSTAGEKILLS, value)
}

stock Float:cs_get_hostage_lastuse(hostage_id)
{
	new classname[32]
	pev(hostage_id, pev_classname, classname, 31)

	if(strcmp(classname, "hostage_entity") != 0)
		return 0

	return Float:get_pdata_float(hostage_id, OFFSET_HOSTAGE_LASTUSE)
}

stock Float:cs_set_hostage_lastuse(hostage_id, Float:value)
{
	new classname[32]
	pev(hostage_id, pev_classname, classname, 31)

	if(strcmp(classname, "hostage_entity") != 0)
		return 0

	set_pdata_float(hostage_id, OFFSET_HOSTAGE_LASTUSE, value)
}

stock Float:cs_get_hostage_nextuse(hostage_id)
{
	new classname[32]
	pev(hostage_id, pev_classname, classname, 31)

	if(strcmp(classname, "hostage_entity") != 0)
		return 0

	return Float:get_pdata_float(hostage_id, OFFSET_HOSTAGE_NEXTUSE)
}

stock cs_set_hostage_nextuse(hostage_id, Float:value)
{
	new classname[32]
	pev(hostage_id, pev_classname, classname, 31)

	if(strcmp(classname, "hostage_entity") != 0)
		return 0

	set_pdata_float(hostage_id, OFFSET_HOSTAGE_NEXTUSE, value)
}

stock Float:cs_get_c4_explode_time(c4_id)
{
	new classname[32]
	pev(c4_id, pev_classname, classname, 31)

	if(strcmp(classname, "grenade") != 0)
		return 0

	if(!(get_pdata_int(c4_id, 96) & (1<<8)))
		return 0

	return Float:get_pdata_float(c4_id, OFFSET_C4_EXPLODE_TIME)
}

stock cs_set_c4_defusing(c4_id, Float:value)
{
	new classname[32]
	pev(c4_id, pev_classname, classname, 31)

	if(strcmp(classname, "grenade") != 0)
		return 0

	if(!(get_pdata_int(c4_id, 96) & (1<<8)))
		return 0	

	set_pdata_float(c4_id, OFFSET_C4_EXPLODE_TIME, value)
	return 1
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
