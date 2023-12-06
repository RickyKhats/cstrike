#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <mycore>



const MAX_FLAGS_STRING_LEN = 32;
const ENT_DISPENSER_KEY = 0xAC0DE;
const Float: ENT_DISPENSER_SHIFT_AXIS = 15.0;
new const ENT_CLASS_DEFAULT[] = "func_breakable";
#define CLASSNAME "dispenser"
#define CHAT_LABEL "Раздатчик"
new const ENT_DISP_MODEL[] = "models/dispenser/dispenser_broken_trash.mdl";
new const Float: ENT_DISP_MINSIZE[] = { -10.0, -10.0, 0.0 };
new const Float: ENT_DISP_MAXSIZE[] = { 7.0, 15.0, 55.0 };
new const ENT_DISP_SKIN_LIST_TT[] = { 4, 5, 6, 7 };
new const ENT_DISP_SKIN_LIST_CT[] = { 0, 1, 2, 3 };
new const ENT_DISP_SKIN_BODY_STATE[] = { 100, 75, 50, 25 };
new const RELATIONS_DISP_SPR[] = "sprites/dispenser/dispenser.spr";
new const SET_DISP_SOUND[] = "dispenser/dispenser.wav";

enum any: DispLvlStruct {
	DISP_LVL_ONE,
	DISP_LVL_TWO,
	DISP_LVL_THREE,
	DISP_LVL_FOUR,
};

enum any: CvarStruct {
	CVAR_DISP_BUY_COST[DispLvlStruct],
	CVAR_DISP_BUY_FLAGS_ONE[MAX_FLAGS_STRING_LEN+1],
	CVAR_DISP_BUY_FLAGS_TWO[MAX_FLAGS_STRING_LEN+1],
	CVAR_DISP_BUY_FLAGS_THREE[MAX_FLAGS_STRING_LEN+1],
	CVAR_DISP_BUY_FLAGS_FOUR[MAX_FLAGS_STRING_LEN+1],
	CVAR_DISP_BUY_FLAG[DispLvlStruct],
	Float: CVAR_DISP_RADIUS[DispLvlStruct],
	Float: CVAR_DISP_PERIOD[DispLvlStruct],
	Float: CVAR_DISP_HEALTH[DispLvlStruct],
	Float: CVAR_DISP_ADD_HP[DispLvlStruct],
	Float: CVAR_DISP_MAX_HP[DispLvlStruct],
	Float: CVAR_DISP_ADD_AP[DispLvlStruct],
	Float: CVAR_DISP_MAX_AP[DispLvlStruct],
	CVAR_DISP_ADD_MONEY,
	Float: CVAR_DISP_PERIOD_MONEY,
	CVAR_DISP_LIMIT_VALUE_PLAYER,
	CVAR_DISP_LIMIT_VALUE_VIP,
	CVAR_DISP_LIMIT_FLAGS_VIP[MAX_FLAGS_STRING_LEN+1],
	CVAR_DISP_LIMIT_FLAG_VIP,
	CVAR_DISP_DISCOUNT_VIP,
	CVAR_DISP_REMOVE_KILL,
	CVAR_DISP_DESTROY_AWARD,
	Float: CVAR_DISP_DESTROY_DMG,
	CVAR_DISP_PERCENT_BAD_STATE,
	CVAR_DISP_REPAIR_COST,
};

enum any: ResStruct {
	SPRITE_RELATIONS,
	SPRITE_EXPLOSION,
	SPRITE_SMOKE
};

new
	g_eCvar[CvarStruct],
	g_eResource[ResStruct],
	g_iDispenserCount[MAX_PLAYERS+1];

public plugin_precache() {
	precache_model(ENT_DISP_MODEL);

	g_eResource[SPRITE_RELATIONS] = precache_model(RELATIONS_DISP_SPR);
	g_eResource[SPRITE_EXPLOSION] = precache_model("sprites/dexplo.spr");
	g_eResource[SPRITE_SMOKE] = precache_model("sprites/black_smoke4.spr");

	// Звуки из стандартной папки valve/sound/debris. - привязываны к объекту func_breakable, требует прекеша
	precache_sound("debris/metal1.wav");
	precache_sound("debris/metal2.wav");
	precache_sound("debris/metal3.wav");
	precache_sound("debris/bustglass1.wav");
	precache_sound("debris/bustglass2.wav");
	precache_sound("debris/bustglass3.wav");	

	precache_sound(SET_DISP_SOUND);
}

public client_disconnected(pPlayer) {
	@remove_dispenser_by_owner(pPlayer);
}
	
public plugin_init() {
	register_plugin("[ReAPI] Dispenser", "0.5a", "6u3oH");

	@cvars_attach();

	register_clcmd("say /dispenser", "@dispenser_create");
	register_clcmd("say_team /dispenser", "@dispenser_create");
	register_clcmd("say /disp", "@dispenser_create");
	register_clcmd("say_team /disp", "@dispenser_create");
	register_clcmd("dispencer_place", "@dispenser_create");
	register_clcmd("disp_create", "@dispenser_create");
	register_clcmd("say /disp_remove", "@dispenser_remove");
	register_clcmd("say_team /disp_remove", "@dispenser_remove");
	register_clcmd("dispenser_remove", "@dispenser_remove");

	RegisterHam(Ham_TakeDamage, ENT_CLASS_DEFAULT, "@Ham_TakeDamage_Pre");
}

@dispenser_create(id) {
	if(!is_user_alive(id))
	{
		notify_player(id, CHAT_LABEL, "Доступно только для живых");
		return;
	}

	new iFlags, bool: bIsDiscount, iCost; 

	iFlags = get_user_flags(id);
	bIsDiscount = iFlags & g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP] == g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP];
	iCost = g_eCvar[CVAR_DISP_BUY_COST][DISP_LVL_ONE];

	if(bIsDiscount)
	{
		if(g_iDispenserCount[id] >= g_eCvar[CVAR_DISP_LIMIT_VALUE_VIP])
		{
			notify_player(id, CHAT_LABEL, "Вы поставили максимальное количество");
			return;
		}
	}
	else
	{
		if(g_iDispenserCount[id] >= g_eCvar[CVAR_DISP_LIMIT_VALUE_PLAYER])
		{
			notify_player(id, CHAT_LABEL, "Вы поставили максимальное количество");
			return;
		}
	}

	if(iFlags & g_eCvar[CVAR_DISP_BUY_FLAG][DISP_LVL_ONE] != g_eCvar[CVAR_DISP_BUY_FLAG][DISP_LVL_ONE])
	{
		notify_player(id, CHAT_LABEL, "У вас нет доступа к установке");
		return;
	}

	if(get_user_money(id) < iCost)
	{
		notify_player(id, CHAT_LABEL, "Для покупки требуется:^3 %i$ \n", iCost);
		return;
	}

	new Float: origin[3];
	get_origin_front(id, origin, 70.0);
	origin[2] += floatabs(ENT_DISP_MINSIZE[2]);

	if(!is_hull_vacant(origin, HULL_HUMAN, 0))
	{
		notify_player(id, CHAT_LABEL, "Недостаточно места для установки");
		return;
	}

	new entity = create_entity(ENT_CLASS_DEFAULT);

	engfunc(EngFunc_SetModel, entity, ENT_DISP_MODEL);
	engfunc(EngFunc_SetOrigin, entity, origin);
	engfunc(EngFunc_SetSize, entity, ENT_DISP_MINSIZE, ENT_DISP_MAXSIZE);

	set_entvar(entity, var_classname, CLASSNAME);
	set_entvar(entity, var_movetype, MOVETYPE_TOSS);
	set_entvar(entity, var_solid, SOLID_BBOX);
	set_entvar(entity, var_takedamage, DAMAGE_YES);
	set_entvar(entity, var_nextthink, get_gametime() + Float: g_eCvar[CVAR_DISP_PERIOD][DISP_LVL_ONE]);

	dispenser_set_owner(entity, id);
	dispenser_set_lvl(entity, DISP_LVL_ONE);
	dispenser_set_key(entity, ENT_DISPENSER_KEY);
	@dispenser_update_settings(id, entity, DISP_LVL_ONE);
	@dispenser_menu_create(entity, id);
	@dispenser_set_body_state(entity, Float: g_eCvar[CVAR_DISP_HEALTH][DISP_LVL_ONE]);

	SetThink(entity, "@dispenser_think");
	SetTouch(entity, "@dispenser_touch");

	g_iDispenserCount[id]++;
	decrease_user_money(id, -iCost)
	notify_player(id, CHAT_LABEL, "Установка прошла успешно");
}

@dispenser_remove(id) {
	if(!is_user_alive(id))
	{
		notify_player(id, CHAT_LABEL, "Доступно только для живых");
		return;
	}

	new entity;
	entity = get_ent_aiming(id, 8192.0);

	if(is_nullent(entity) || dispenser_get_key(entity) != ENT_DISPENSER_KEY)
	{
		notify_player(id, CHAT_LABEL, "Раздатчик не найден");
		return;
	}

	if(dispenser_get_owner(entity) != id)
	{
		notify_player(id, CHAT_LABEL, "Это не ваш раздатчик");
		return;
	}

	new level, bool: bIsDiscount, iCost;

	level = dispenser_get_lvl(entity);

	for(new i; i < level; i++)
	{
		iCost += g_eCvar[CVAR_DISP_BUY_COST][level];

		if(bIsDiscount)
			iCost -= g_eCvar[CVAR_DISP_DISCOUNT_VIP] * g_eCvar[CVAR_DISP_BUY_COST][DISP_LVL_ONE] / 100;
	}

	iCost *= 0.5;

	increase_user_money(id, iCost);
	notify_player(id, CHAT_LABEL, "Вы убрали свой раздатчик");

	@remove_ent_dispenser(entity);
	g_iDispenserCount[id]--;
}

@CSGameRules_CleanUpMap_Post() {
	for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++)
		if(is_user_connected(pPlayer))
			@remove_dispenser_by_owner(pPlayer);
}

@CBasePlayer_Killed_Post(victim, attacker, eInfclictor) {
	@remove_dispenser_by_owner(victim);
}

@Ham_TakeDamage_Pre(entity, eInfclictor, attacker, Float: damage, iDmgBits) {
	if(is_nullent(entity) || dispenser_get_key(entity) != ENT_DISPENSER_KEY)
		return HAM_IGNORED;

	new owner, Float: fHealth, iTeamOwner
	
	owner = dispenser_get_owner(entity)
	fHealth = Float: get_entvar(entity, var_health)
	iTeamOwner = cs_get_user_team(owner)
	if(is_user_connected(attacker) && attacker != owner && iTeamOwner == cs_get_user_team(attacker))
		SetHamParamFloat(4, (damage = 0.0));

	@dispenser_set_body_state(entity, fHealth);

	if(fHealth > damage)
		return HAM_IGNORED;

	new Float: origin[3], victim, level;

	get_entvar(entity, var_origin, origin);
	set_msg_explosion(origin, g_eResource[SPRITE_EXPLOSION]);

	level = dispenser_get_lvl(entity);
	victim = FM_NULLENT;

	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, Float: g_eCvar[CVAR_DISP_RADIUS][level])))
	{
		if(!is_user_alive(victim) || !is_player_vis_disp(victim, entity, origin))
			continue;

		ExecuteHamB(Ham_TakeDamage, victim, entity, entity, Float: g_eCvar[CVAR_DISP_DESTROY_DMG], DMG_GENERIC);
	}

	@dispenser_create_fake_gibs(origin, level, iTeamOwner);

	if(is_user_connected(attacker))
	{		
		new owner = dispenser_get_owner(entity);

		if(attacker == owner)
			notify_player(owner, CHAT_LABEL,"Вы уничтожили свой раздатчик");
		else
		{
			if(g_eCvar[CVAR_DISP_DESTROY_AWARD])
			{
				notify_player(attacker, CHAT_LABEL, "Вы уничтожили раздатчик^4 %n^1 (^3+%i$^1)", owner, g_eCvar[CVAR_DISP_DESTROY_AWARD]);
				increase_user_money(attacker, g_eCvar[CVAR_DISP_DESTROY_AWARD]);
			}

			notify_player(owner, CHAT_LABEL, "%n ^1уничтожил ваш раздатчик", attacker);
		}

		g_iDispenserCount[owner]--;
		@remove_ent_dispenser(entity);

		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

@dispenser_think(entity) {
	static 	level,
		iTeamOwner,
		pPlayer,
		owner,
		Float: origin[3],
		Float: fGameTime,
		Float: fDispHealth,
		Float: fPlayerHealth,
		Float: fPlayerArmor,
		bool: bIsAddMoney,
		bool: bIsShowRelations;

	get_entvar(entity, var_origin, origin);
	origin[2] += ENT_DISPENSER_SHIFT_AXIS;

	owner = dispenser_get_owner(entity);
	iTeamOwner = cs_get_user_team(owner);
	level = dispenser_get_lvl(entity);
	fGameTime = get_gametime();
	fDispHealth = Float: get_entvar(entity, var_health);
	bIsAddMoney = false;

	if(level == DISP_LVL_FOUR && get_entvar(entity, var_fuser1) < fGameTime)
	{
		bIsAddMoney = true;
		set_entvar(entity, var_fuser1, fGameTime + Float: g_eCvar[CVAR_DISP_PERIOD_MONEY]);
	}

	if(fDispHealth < get_entvar(entity, var_fuser3) && get_entvar(entity, var_fuser2) < fGameTime)
	{
		set_msg_smoke(origin, g_eResource[SPRITE_SMOKE], ENT_DISPENSER_SHIFT_AXIS);
		set_entvar(entity, var_fuser2, fGameTime + 1.0);
	}

	pPlayer = FM_NULLENT;
	while((pPlayer = engfunc(EngFunc_FindEntityInSphere, pPlayer, origin, Float: g_eCvar[CVAR_DISP_RADIUS][level]))) {
		if(!is_user_alive(pPlayer) || iTeamOwner != cs_get_user_team(pPlayer) || !is_player_vis_disp(pPlayer, entity, origin)) {
			continue;
		}
		
		bIsShowRelations = false;

		fPlayerHealth = Float: get_entvar(pPlayer, var_health);
		fPlayerArmor = Float: get_entvar(pPlayer, var_armorvalue);

		if(fPlayerHealth < Float: g_eCvar[CVAR_DISP_MAX_HP][level])
		{
			bIsShowRelations = true;
			set_entvar(pPlayer, var_health, floatclamp(fPlayerHealth + Float: g_eCvar[CVAR_DISP_ADD_HP][level], fPlayerHealth, Float: g_eCvar[CVAR_DISP_MAX_HP][level]));
		}

		if(fPlayerArmor < Float: g_eCvar[CVAR_DISP_MAX_AP][level])
		{
			bIsShowRelations = true;
			set_entvar(pPlayer, var_armorvalue, floatclamp(fPlayerArmor + g_eCvar[CVAR_DISP_ADD_AP][level], fPlayerArmor , Float: g_eCvar[CVAR_DISP_MAX_AP][level]));
		}

		if(bIsShowRelations)
		{
			switch(iTeamOwner)
			{
				case TEAM_TERRORIST: set_msg_beamentpoint(pPlayer, origin, g_eResource[SPRITE_RELATIONS], 255, 0, 0);
				case TEAM_CT: set_msg_beamentpoint(pPlayer, origin, g_eResource[SPRITE_RELATIONS], 0, 0, 255);
			}
		}

		if(bIsAddMoney)
			increase_user_money(pPlayer, g_eCvar[CVAR_DISP_ADD_MONEY]);

		if(get_ent_aiming(pPlayer, Float: g_eCvar[CVAR_DISP_RADIUS][level]) == entity)
		{
			set_hudmessage(0, 255, 0, -1.0, 0.6, .holdtime = Float: g_eCvar[CVAR_DISP_PERIOD][level]);
			show_hudmessage(pPlayer, "Раздатчик ^nУровень: %i ^nВладелец: %n^nЗдоровье: %..1f", level+1, owner, fDispHealth);
		}
	}

	set_entvar(entity, var_nextthink, fGameTime + Float: g_eCvar[CVAR_DISP_PERIOD][level]);
}

@dispenser_touch(entity, pPlayer) {
	if(!is_user_alive(pPlayer))
		return;

	static Float: fGameTime, Float: fNextTime[MAX_PLAYERS+1];
	fGameTime = get_gametime();

	if(fNextTime[pPlayer] - fGameTime > 0)
		return;

	fNextTime[pPlayer] = fGameTime + 1.0;

	if(cs_get_user_team(dispenser_get_owner(entity)) != cs_get_user_team(pPlayer))
		return;

	@dispenser_menu_select(entity, pPlayer);
}

@dispenser_update_settings(owner, entity, level) {
	switch(cs_get_user_team(owner))
	{
		case CS_TEAM_T: set_entvar(entity, var_skin, ENT_DISP_SKIN_LIST_TT[level]);
		case CS_TEAM_CT: set_entvar(entity, var_skin, ENT_DISP_SKIN_LIST_CT[level]);
	}

	set_entvar(entity, var_health, Float: g_eCvar[CVAR_DISP_HEALTH][level]);
	set_entvar(entity, var_fuser3,  g_eCvar[CVAR_DISP_PERCENT_BAD_STATE] * Float: g_eCvar[CVAR_DISP_HEALTH][level] / 100);

	dispenser_set_lvl(entity, level);
	emit_sound(entity, CHAN_AUTO, SET_DISP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

@dispenser_set_body_state(entity, Float: fHealth) {
	new iBody, level;

	iBody = NULLENT;
	level = dispenser_get_lvl(entity);

	for(new i; i < sizeof(ENT_DISP_SKIN_BODY_STATE); i++)
	{
		if(fHealth >= ENT_DISP_SKIN_BODY_STATE[i] * Float: g_eCvar[CVAR_DISP_HEALTH][level] / 100.0)
		{
			iBody = i;
			break;
		}
	}

	if(iBody != NULLENT)
		set_entvar(entity, var_body, iBody);
}

@remove_dispenser_by_owner(pPlayer) {
	new entity = NULLENT;
	while((entity = find_ent_by_class(entity, CLASSNAME)))
		if(!is_nullent(entity) && dispenser_get_owner(entity) == pPlayer)
			@remove_ent_dispenser(entity);

	g_iDispenserCount[pPlayer] = 0;
}

@dispenser_menu_create(entity, pPlayer) {
	new iDispMenu, sParam[1];

	sParam[0] = entity;
	iDispMenu = menu_create("\yДействия с раздатчиком?", "@dispenser_menu_select_handler");

	menu_additem(iDispMenu, "", sParam[0]);
	menu_additem(iDispMenu, "", sParam[0]);

	menu_addblank(iDispMenu);
	menu_addblank(iDispMenu);
	menu_addblank(iDispMenu);
	menu_addblank(iDispMenu);
	menu_addblank(iDispMenu);
	menu_addblank(iDispMenu);
	menu_addblank(iDispMenu);

	menu_additem(iDispMenu, "\wВыход");

	menu_setprop(iDispMenu, MPROP_PERPAGE, 0);
	menu_setprop(iDispMenu, MPROP_NUMBER_COLOR, "\y");
	menu_setprop(iDispMenu, MPROP_EXIT, MEXIT_NEVER);

	dispenser_set_menu(entity, iDispMenu);
}

@dispenser_menu_select(entity, pPlayer) {
	static iCurMenu, iDispMenu;

	player_menu_info(pPlayer, iDispMenu, iCurMenu);
	iDispMenu = dispenser_get_menu(entity);

	if(iDispMenu == iCurMenu)
		return;

	new iFlags, level;

	iFlags = get_user_flags(pPlayer);
	level = dispenser_get_lvl(entity);

	if(level < DISP_LVL_FOUR && get_user_flags(pPlayer) & g_eCvar[CVAR_DISP_BUY_FLAG][level] == g_eCvar[CVAR_DISP_BUY_FLAG][level])
	{
		new iCost = g_eCvar[CVAR_DISP_BUY_COST][level];

		if(iFlags & g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP] == g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP])
			iCost -= g_eCvar[CVAR_DISP_DISCOUNT_VIP] * g_eCvar[CVAR_DISP_BUY_COST][level] / 100;

		menu_item_setname(iDispMenu, 0, fmt("\wУлучшение \y[%i$]", iCost));
	}
	else
		menu_item_setname(iDispMenu, 0, "\dУлучшение");

	if(Float: get_entvar(entity, var_health) < Float: g_eCvar[CVAR_DISP_HEALTH][level])
		menu_item_setname(iDispMenu, 1, fmt("\wРемонт \y[%i$]", g_eCvar[CVAR_DISP_REPAIR_COST]));
	else
		menu_item_setname(iDispMenu, 1, "\dРемонт");

	menu_display(pPlayer, iDispMenu);
}

@dispenser_menu_select_handler(pPlayer, iMenu, iItem) {
	new sParam[1], entity;

	menu_item_getinfo(iMenu, iItem, .info = sParam, .infolen = sizeof(sParam));
	entity = sParam[0];

	if(is_nullent(entity))
		return;

	switch(iItem)
	{
		case 0:
		{
			new iFlags, level;

			iFlags = get_user_flags(pPlayer);
			level = dispenser_get_lvl(entity);

			if(level == DISP_LVL_FOUR)
				return;

			if(get_user_flags(pPlayer) & g_eCvar[CVAR_DISP_BUY_FLAG][level] != g_eCvar[CVAR_DISP_BUY_FLAG][level])
			{
				client_print_color(pPlayer, print_team_grey, "У вас нет доступа к улучшению");
				return;
			}

			new iCost = g_eCvar[CVAR_DISP_BUY_COST][level+1];

			if(iFlags & g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP] == g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP])
				iCost -= g_eCvar[CVAR_DISP_DISCOUNT_VIP] * g_eCvar[CVAR_DISP_BUY_COST][level+1] / 100;

			if(get_user_money(pPlayer) < iCost)
			{
				client_print_color(pPlayer, print_team_grey, "Для улучшения требуется:^3 %i$", iCost);
				return;
			}

			@dispenser_update_settings(pPlayer, entity, level+1);
			@dispenser_set_body_state(entity, Float: g_eCvar[CVAR_DISP_HEALTH][level+1]);

			decrease_user_money(pPlayer, iCost);
			client_print_color(pPlayer, print_team_grey, "Вы улучшили раздатчик до^3 %i-го уровня", ++level+1);
		}

		case 1:
		{
			new level = dispenser_get_lvl(entity);

			if(Float: get_entvar(entity, var_health) == Float: g_eCvar[CVAR_DISP_HEALTH][level])
				return;

			if(get_user_money(pPlayer) < g_eCvar[CVAR_DISP_REPAIR_COST])
			{
				client_print_color(pPlayer, print_team_grey, "Для ремонта требуется:^3 %i$", g_eCvar[CVAR_DISP_REPAIR_COST]);
				return;
			}

			set_entvar(entity, var_health, Float: g_eCvar[CVAR_DISP_HEALTH][level]);
			emit_sound(entity, CHAN_AUTO, SET_DISP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			decrease_user_money(pPlayer, g_eCvar[CVAR_DISP_REPAIR_COST]);
			client_print_color(pPlayer, print_team_grey, "Вы произвели ремонт раздатчика");

			@dispenser_set_body_state(entity, Float: g_eCvar[CVAR_DISP_HEALTH][level]);
		}

		default: return;
	}
}

@dispenser_create_fake_gibs(Float: origin[3], level, iTeamOwner) {
	new entity;
	entity = rg_create_entity("func_wall");

	engfunc(EngFunc_SetOrigin, entity, origin);
	engfunc(EngFunc_SetModel, entity, ENT_DISP_MODEL);
	engfunc(EngFunc_SetSize, entity, Float: { -0.1, -0.1, -0.1 }, Float: { 0.1, 0.1, 0.1 });

	set_entvar(entity, var_classname, "dispenser_fake_gibs");
	set_entvar(entity, var_solid, SOLID_TRIGGER);
	set_entvar(entity, var_movetype, MOVETYPE_TOSS);
	set_entvar(entity, var_body, 4);
	set_entvar(entity, var_nextthink, get_gametime() + 3.0);

	SetThink(entity, "@remove_dispenser_fake_gibs");
}

@remove_dispenser_fake_gibs(entity) {
	set_entvar(entity, var_flags, FL_KILLME);
}

@remove_ent_dispenser(entity) {
	if(~get_entvar(entity, var_flags) & FL_KILLME)
	{
		static iOldMenu, iCurMenu, iDispMenu;
		iDispMenu = dispenser_get_menu(entity);
	
		for(new pPlayer; pPlayer <= MaxClients; pPlayer++)
		{
			if(!is_user_connected(pPlayer))
				continue;
	
			player_menu_info(pPlayer, iOldMenu, iCurMenu);
	
			if(iDispMenu == iCurMenu)
			{
				if(iCurMenu == iDispMenu)
				{
					menu_cancel(pPlayer);
					show_menu(pPlayer, 0, "^n", 1);
				}
			}
		}
	
		menu_destroy(iDispMenu);
	}

	set_entvar(entity, var_flags, FL_KILLME);
	set_entvar(entity, var_nextthink, -1.0);
}

public plugin_natives() {
	register_native("dispencer_place", "native_dispenser_create");
	register_native("dispenser_remove", "native_dispenser_remove");
	register_native("dispenser_get_lvl", "native_dispenser_get_lvl");
	register_native("is_ent_dispenser", "native_is_ent_dispenser");
	register_native("get_user_dispenser_count", "native_get_user_dispenser_count");
	register_native("dispenser_remove_by_owner", "native_dispenser_remove_by_owner");
}

public native_dispenser_create(){
	enum _: { arg_player_index = 1 };

	@dispenser_create(get_param(arg_player_index));
}

public native_dispenser_remove(){
	enum _: { arg_player_index = 1 };

	@dispenser_remove(get_param(arg_player_index));
}

public native_dispenser_get_lvl() {
	enum _: { arg_ent_index = 1 };

	return dispenser_get_lvl(get_param(arg_ent_index));
}

public native_is_ent_dispenser() {
	enum _: { arg_ent_index = 1 };

	return dispenser_get_key(get_param(arg_ent_index) == ENT_DISPENSER_KEY);
}

public native_get_user_dispenser_count() {
	enum _: { arg_player_index = 1 };

	return g_iDispenserCount[get_param(arg_player_index)];
}

public native_dispenser_remove_by_owner() {
	enum _: { arg_player_index = 1 };

	@remove_dispenser_by_owner(get_param(arg_player_index));
}

@cvars_attach() {
	bind_pcvar_num(
		create_cvar(
			"dispenser_buy_cost", "1500", FCVAR_SERVER,
			.description = "Стоимость покупки раздатчика",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_COST][DISP_LVL_ONE]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_up_lvl_2_cost", "1000", FCVAR_SERVER,
			.description = "Стоимость улучшения раздатчика до 2-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_COST][DISP_LVL_TWO]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_up_lvl_3_cost", "1500", FCVAR_SERVER,
			.description = "Стоимость улучшения раздатчика до 3-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_COST][DISP_LVL_THREE]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_up_lvl_4_cost", "4000", FCVAR_SERVER,
			.description = "Стоимость улучшения раздатчика до 4-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_COST][DISP_LVL_FOUR]
	);

	bind_pcvar_string(
		create_cvar(
			"dispenser_buy_flags", "", FCVAR_SERVER,
			.description = "Флаги для доступа к покупке раздатчика^nОставьте поле пустым, если проверка не флаги не нужна",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_FLAGS_ONE], MAX_FLAGS_STRING_LEN
	);

	bind_pcvar_string(
		create_cvar(
			"dispenser_up_lvl_2_flags", "", FCVAR_SERVER,
			.description = "Флаги для доступа к улучшению раздатчика до 2-го уровня^nОставьте поле пустым, если проверка не флаги не нужна",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_FLAGS_TWO], MAX_FLAGS_STRING_LEN
	);

	bind_pcvar_string(
		create_cvar(
			"dispenser_up_lvl_3_flags", "", FCVAR_SERVER,
			.description = "Флаги для доступа к улучшению раздатчика до 3-го уровня^nОставьте поле пустым, если проверка не флаги не нужна",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_FLAGS_THREE], MAX_FLAGS_STRING_LEN
	);

	bind_pcvar_string(
		create_cvar(
			"dispenser_up_lvl_4_flags", "t", FCVAR_SERVER,
			.description = "Флаги для доступа к улучшению раздатчика до 4-го уровня^nОставьте поле пустым, если проверка не флаги не нужна",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_BUY_FLAGS_FOUR], MAX_FLAGS_STRING_LEN
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_radius_lvl_1", "500.0", FCVAR_SERVER,
			.description = "Радиус, в котором будет действовать раздатчик на 1-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_RADIUS][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_radius_lvl_2", "600.0", FCVAR_SERVER,
			.description = "Радиус, в котором будет действовать раздатчик на 2-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_RADIUS][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_radius_lvl_3", "700.0", FCVAR_SERVER,
			.description = "Радиус, в котором будет действовать раздатчик на 3-ем уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_RADIUS][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_radius_lvl_4", "800.0", FCVAR_SERVER,
			.description = "Радиус, в котором будет действовать раздатчик на 4-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_RADIUS][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_period_lvl_1", "0.5", FCVAR_SERVER,
			.description = "Периодичность работы раздатчика на 1-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_PERIOD][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_period_lvl_2", "0.5", FCVAR_SERVER,
			.description = "Периодичность работы раздатчика на 2-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_PERIOD][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_period_lvl_3", "0.4", FCVAR_SERVER,
			.description = "Периодичность работы раздатчика на 3-ем уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_PERIOD][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_period_lvl_4", "0.3", FCVAR_SERVER,
			.description = "Периодичность работы раздатчика на 4-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_PERIOD][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_health_lvl_1", "1500.0", FCVAR_SERVER,
			.description = "Здоровье раздатчика на 1-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_HEALTH][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_health_lvl_2", "2000.0", FCVAR_SERVER,
			.description = "Здоровье раздатчика на 2-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_HEALTH][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_health_lvl_3", "2250.0", FCVAR_SERVER,
			.description = "Здоровье раздатчика на 3-ем уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_HEALTH][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_health_lvl_4", "2500.0", FCVAR_SERVER,
			.description = "Здоровье раздатчика на 4-ом уровне",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_HEALTH][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_hp_lvl_1", "5.0", FCVAR_SERVER,
			.description = "Сколько здоровья пополняет раздатчик на 1-ом уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_HP][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_hp_lvl_2", "6.0", FCVAR_SERVER,
			.description = "Сколько здоровья пополняет раздатчик на 2-ом уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_HP][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_hp_lvl_3", "7.0", FCVAR_SERVER,
			.description = "Сколько здоровья пополняет раздатчик на 3-ем уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_HP][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_hp_lvl_4", "8.0", FCVAR_SERVER,
			.description = "Сколько здоровья пополняет раздатчик на 4-ом уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_HP][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_hp_lvl_1", "100.0", FCVAR_SERVER,
			.description = "Порог пополняемого здоровья раздатчиком 1-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_HP][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_hp_lvl_2", "150.0", FCVAR_SERVER,
			.description = "Порог пополняемого здоровья раздатчиком 2-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_HP][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_hp_lvl_3", "200.0", FCVAR_SERVER,
			.description = "Порог пополняемого здоровья раздатчиком 3-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_HP][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_hp_lvl_4", "255.0", FCVAR_SERVER,
			.description = "Порог пополняемого здоровья раздатчиком 4-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_HP][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_ap_lvl_1", "5.0", FCVAR_SERVER,
			.description = "Сколько брони пополняет раздатчик на 1-ом уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_AP][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_ap_lvl_2", "6.0", FCVAR_SERVER,
			.description = "Сколько брони пополняет раздатчик на 2-ом уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_AP][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_ap_lvl_3", "7.0", FCVAR_SERVER,
			.description = "Сколько здоровья пополняет раздатчик на 3-ем уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_AP][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_add_ap_lvl_4", "8.0", FCVAR_SERVER,
			.description = "Сколько брони пополняет раздатчик на 4-ом уровне за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_ADD_AP][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_ap_lvl_1", "150.0", FCVAR_SERVER,
			.description = "Порог пополняемой брони раздатчиком 1-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_AP][DISP_LVL_ONE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_ap_lvl_2", "200.0", FCVAR_SERVER,
			.description = "Порог пополняемой брони раздатчиком 2-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_AP][DISP_LVL_TWO]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_ap_lvl_3", "255.0", FCVAR_SERVER,
			.description = "Порог пополняемой брони раздатчиком 3-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_AP][DISP_LVL_THREE]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_max_ap_lvl_4", "255.0", FCVAR_SERVER,
			.description = "Порог пополняемой брони раздатчиком 4-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_MAX_AP][DISP_LVL_FOUR]
	);

	bind_pcvar_float(
		create_cvar(
			"dispenser_period_add_money_lvl_4", "15.0", FCVAR_SERVER,
			.description = "Периодичность выдачи денег раздатчиком 4-го уровня",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DISP_PERIOD_MONEY]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_add_money_lvl_4", "500", FCVAR_SERVER,
			.description = "Выдаваемое количество денег за период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_ADD_MONEY]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_limit_count_player", "1", FCVAR_SERVER,
			.description = "Сколько раздатчиков может ставить обычный игрок",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_LIMIT_VALUE_PLAYER]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_limit_count_vip", "2", FCVAR_SERVER,
			.description = "Сколько раздатчиков может ставить VIP игрок",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_LIMIT_VALUE_VIP]
	);

	bind_pcvar_string(
		create_cvar(
			"dispenser_limit_flags_player", "t", FCVAR_SERVER,
			.description = "Флаги для доступа к увеличенному количеству раздатчиков и скидке",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_LIMIT_FLAGS_VIP], MAX_FLAGS_STRING_LEN
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_discount_vip", "25", FCVAR_SERVER,
			.description = "Постоянная скидка для VIP игрока при покупке и прокачке раздатчика в процентах",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 100.0
		), g_eCvar[CVAR_DISP_DISCOUNT_VIP]
	);
	
	bind_pcvar_num(
		create_cvar(
			"dispenser_remove_after_kill", "1", FCVAR_SERVER,
			.description = "Уничтожать раздатчик после смерти владельца?^n0 - нет, 1 - да",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 1.0
		), g_eCvar[CVAR_DISP_REMOVE_KILL]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_destroy_award", "1000", FCVAR_SERVER,
			.description = "Награда за уничтожение раздатчика ($)^nУстановите 0, чтобы отключить награду",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_DESTROY_AWARD]
	);
	
	bind_pcvar_float(
		create_cvar(
			"dispenser_destroy_damage", "150.0", FCVAR_SERVER,
			.description = "Максимальный урон, который наносит раздатчик при взрыве",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_DESTROY_DMG]
	);

	bind_pcvar_num(
		create_cvar(
			"dispenser_percent_bad_state", "15", FCVAR_SERVER,
			.description = "Процент здоровья раздатчик, при котором он начнёт дымится (в процентах)",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 100.0
		), g_eCvar[CVAR_DISP_PERCENT_BAD_STATE]
	);	

	bind_pcvar_num(
		create_cvar(
			"dispenser_repair_cost", "1000", FCVAR_SERVER,
			.description = "Фиксированная стоимость ремонта раздатчика",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DISP_REPAIR_COST]
	);
	
	AutoExecConfig(true);
}

public OnConfigsExecuted() {
	g_eCvar[CVAR_DISP_BUY_FLAG][DISP_LVL_ONE] = read_flags(g_eCvar[CVAR_DISP_BUY_FLAGS_ONE]);
	g_eCvar[CVAR_DISP_BUY_FLAG][DISP_LVL_TWO] = read_flags(g_eCvar[CVAR_DISP_BUY_FLAGS_TWO]);
	g_eCvar[CVAR_DISP_BUY_FLAG][DISP_LVL_THREE] = read_flags(g_eCvar[CVAR_DISP_BUY_FLAGS_THREE]);
	g_eCvar[CVAR_DISP_BUY_FLAG][DISP_LVL_FOUR] = read_flags(g_eCvar[CVAR_DISP_BUY_FLAGS_FOUR]);
	g_eCvar[CVAR_DISP_LIMIT_FLAG_VIP] = read_flags(g_eCvar[CVAR_DISP_LIMIT_FLAGS_VIP]);
}

stock dispenser_get_owner(entity) return get_entvar(entity, var_iuser3);
stock dispenser_set_owner(entity, owner) set_entvar(entity, var_iuser3, owner);
stock dispenser_get_lvl(entity) return get_entvar(entity, var_euser2);
stock dispenser_set_lvl(entity, level) set_entvar(entity, var_euser2, level);
stock dispenser_get_key(entity) return get_entvar(entity, var_euser3);
stock dispenser_set_key(entity, iKey) set_entvar(entity, var_euser3, iKey);
stock dispenser_get_menu(entity) return get_entvar(entity, var_euser4);
stock dispenser_set_menu(entity, iKey) set_entvar(entity, var_euser4, iKey);

stock get_ent_aiming(pPlayer, Float: fDist) {
	static Float: origin[3], Float: fDest[3];

	get_entvar(pPlayer, var_origin, origin);
	get_entvar(pPlayer, var_view_ofs, fDest);

	xs_vec_add(origin, fDest, origin);

	get_entvar(pPlayer, var_v_angle, fDest);
	engfunc(EngFunc_MakeVectors, fDest);
	global_get(glb_v_forward, fDest);

	xs_vec_mul_scalar(fDest, fDist, fDest);
	xs_vec_add(origin, fDest, fDest);

	engfunc(EngFunc_TraceLine, origin, fDest, DONT_IGNORE_MONSTERS, pPlayer, 0);
	return get_tr2(0, TR_pHit);
}

stock bool: is_player_vis_disp(pPlayer, eEntDisp, Float: fOriginDisp[3]) {
	static Float: fOriginStart[3], Float: fOriginDest[3], Float: fFlFraction;

	get_entvar(pPlayer, var_origin, fOriginStart);
	get_entvar(pPlayer, var_view_ofs, fOriginDest);
	xs_vec_add(fOriginStart, fOriginDest, fOriginStart);

	fOriginDisp[2] += ENT_DISPENSER_SHIFT_AXIS;

	engfunc(EngFunc_TraceLine, fOriginStart, fOriginDisp, IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_flFraction, fFlFraction);

	if(fFlFraction == 1.0 || get_tr2(0, TR_pHit) == eEntDisp)
		return true;

	return false;
}

stock set_msg_beamentpoint(pPlayer, Float: origin[3], iIndexSprite, iRed, iGreen, iBlue) {
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(pPlayer);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(iIndexSprite);
	write_byte(0);
	write_byte(1);
	write_byte(10);
	write_byte(20);
	write_byte(0);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(2000);
	write_byte(50);
	message_end();
}

stock set_msg_explosion(Float: origin[3], iSprite) {
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(iSprite);
	write_byte(30);
	write_byte(10);
	write_byte(TE_EXPLFLAG_NONE);
	message_end(); 
}

stock set_msg_smoke(Float: origin[3], iSprite, Float: fShift) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + fShift);
	write_short(iSprite);
	write_byte(10);
	write_byte(30);
	message_end();
}

stock get_origin_front(pPlayer, Float: fOriginEnd[3], Float: fDist) {
	static Float: fOriginStart[3];

	get_entvar(pPlayer, var_origin, fOriginStart);
	get_entvar(pPlayer, var_v_angle, fOriginEnd);

	fOriginEnd[0] = 0.0;

	engfunc(EngFunc_MakeVectors, fOriginEnd);
	global_get(glb_v_forward, fOriginEnd);

	xs_vec_mul_scalar(fOriginEnd, fDist, fOriginEnd);
	xs_vec_add(fOriginStart, fOriginEnd, fOriginEnd);

	engfunc(EngFunc_TraceLine, fOriginStart, fOriginEnd, DONT_IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, fOriginEnd);
}

stock bool: is_hull_vacant(Float: origin[3], iHull, entity) {
	engfunc(EngFunc_TraceHull, origin, origin, DONT_IGNORE_MONSTERS, iHull, entity, 0);
 
	return !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen);
}