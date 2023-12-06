#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <beams>
#include <fun>
#include <mycore>

#define TASK_PLANT			  15100

#define PLUGIN "SF TripMine"
#define VERSION "0.3.4"
#define AUTHOR "serfreeman1337"

#if AMXX_VERSION_NUM < 183
	#define message_begin_f(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin,%0,%1,%2,%3)
	#define write_coord_f(%0)		engfunc(EngFunc_WriteCoord,%0)
	
	#define Ham_CS_Player_ResetMaxSpeed	Ham_Item_PreFrame
	
	#include <dhudmessage>
	
	#define print_team_default DontChange
	#define print_team_grey Grey
	#define print_team_red Red
	#define print_team_blue Blue
#endif

#define SND_STOP		(1<<5)

#define CLASSNAME	"tripmine"		// tripmine classname

#define BEAM_SPRITERED		"sprites/laserr.spr"
#define BEAM_SPRITEBLUE		"sprites/laserb.spr"

#define TRIPMINE_PLANTSOUND	"weapons/mine_deploy.wav"	// plant sound
#define TRIPMINE_CHARGESOUND	"weapons/mine_charge.wav"	// charge sound
#define TRIPMINE_ACTIVESOUND	"weapons/mine_activate.wav"	// active sound
#define TRIPMINE_HITSOUND	"ambience/beamstart9.wav"	// hit sound

#define PLANTWAITTIME		0.1
#define POWERUPTIME		2.0
#define BEAM_WIDTH		15.0
#define BEAM_BRIGHT		255.0

#define PLANT_TIME		1.0				// tripmine plant time
#define PLANT_RADIUS		64.0				// default plant radius
#define LASER_LENGTH		8128.0				// maximum laser length

#define EV_TM_hOwner		EV_ENT_euser4
#define EV_TM_pBeam3		EV_ENT_euser3
#define EV_TM_pBeam2		EV_ENT_euser2
#define EV_TM_pBeam		EV_ENT_euser1
#define EV_TM_team		EV_INT_iuser4
#define EV_TM_plantTime		EV_FL_fuser4
#define EV_TM_mVecDir		EV_VEC_vuser4
#define EV_TM_mVecEnd3		EV_VEC_vuser3
#define EV_TM_mVecEnd2		EV_VEC_vuser2
#define EV_TM_mVecEnd		EV_VEC_vuser1

#define EV_TM_mineId		EV_INT_iuser3

#define CHAT_LABEL "Лазер"

new Float: g_laser_dwig[300]
new g_laser_stor[300]
new g_level[300]
new g_Metod_abgreid[300]
new g_Laser_kill[300] 
new g_laser_dwig_is[300]
new g_laser_gr_mera_id[33]
new g_laser_gr_mera_ent[300]

new  g_Cvar_helath, g_Cvar_helath2, g_Cvar_max_mine, g_Cvar_max_mine_vip, g_Cvar_cost, g_Cvar_cost2, g_Cvar_dmg, g_Cvar_metod
new g_Model_mine, TRIPMINE_MODEL[90]

new Float: g_menu_open[33]


#define ENTITY_REFERENCE	"func_breakable"

enum _:playerDataStruct {
	PD_MINE_ENT,
	Float:PD_NEXTPLANT_TIME,
	bool:PD_START_SET
}

new maxPlayers,expSpr
new playerData[33][playerDataStruct]
new HamHook:playerPostThink,thinkHooks

new BarTime

new g_IDEniti[33]

new g_tm_menu_one
new g_tm_menu_second
new g_tm_menu_third
new g_tm_menu_four
new g_tm_menu_five

public plugin_precache(){
	g_Model_mine = 0
	new iFile = fopen("addons/amxmodx/configs/nova/Lasermine.cfg", "rt");
	if(iFile){
		new szLineBuffer[600]
		while(!(feof(iFile))){
			fgets(iFile, szLineBuffer, charsmax(szLineBuffer));	   
			if(!(szLineBuffer[0]) || szLineBuffer[0] == ';' || szLineBuffer[0] == '#'){
				continue;
			}
			new Model[600], Imeil[600]
			parse(szLineBuffer, Imeil, charsmax(Imeil),Model, charsmax(Model));
			if(equal(Imeil, "mdl_tr_mine")){	
				g_Model_mine = 1
				formatex(TRIPMINE_MODEL, charsmax(TRIPMINE_MODEL), "%s", Model);
			}
		}
	}
	if(g_Model_mine == 0){
		formatex(TRIPMINE_MODEL, charsmax(TRIPMINE_MODEL), "models/laser_mine_1.mdl");
	}
	
	g_Cvar_helath = register_cvar("tm_mine_helath", "700.0")
	g_Cvar_helath2 = register_cvar("tm_mine_helath2", "1000.0")
	g_Cvar_max_mine = register_cvar("tm_max_mine", "3")
	g_Cvar_max_mine_vip = register_cvar("tm_max_mine_vip", "5")
	g_Cvar_cost = register_cvar("tm_mine_cost", "800")
	g_Cvar_cost2 = register_cvar("tm_mine_cost2", "1000")
	g_Cvar_dmg = register_cvar("tm_mine_dmg", "50.0")
	g_Cvar_metod = register_cvar("tm_mine_mode", "3")
	g_tm_menu_one = register_cvar("tm_menu1", "5")
	g_tm_menu_second = register_cvar("tm_menu2", "10")
	g_tm_menu_third = register_cvar("tm_menu3", "15")
	g_tm_menu_four = register_cvar("tm_menu4", "30")
	g_tm_menu_five = register_cvar("tm_menu5", "45")
	
	precache_model(TRIPMINE_MODEL)
	
	precache_sound(TRIPMINE_PLANTSOUND)
	precache_sound(TRIPMINE_CHARGESOUND)
	precache_sound(TRIPMINE_ACTIVESOUND)
	precache_sound(TRIPMINE_HITSOUND)
	precache_sound("debris/bustglass1.wav")
	precache_model(BEAM_SPRITERED)
	precache_model(BEAM_SPRITEBLUE)
	
	expSpr = precache_model("sprites/zerogxplode.spr")
}

public plugin_init(){
	register_plugin(PLUGIN,VERSION,AUTHOR)
	
	BarTime = get_user_msgid("BarTime")
	maxPlayers = get_maxplayers()
	
	register_concmd("+setlaser","SetLaser_CMD")
	register_concmd("-setlaser","SetLaser_DropCMD")
	
	register_forward(FM_CmdStart,"fm_cmdstart");
	register_think(CLASSNAME,"TripMine_Think")
	RegisterHam(Ham_TakeDamage,ENTITY_REFERENCE,"TripMine_Damage")
	RegisterHam(Ham_Killed,ENTITY_REFERENCE,"TripMine_Killed")
	register_touch(CLASSNAME, "player", "touch_player")
	
	register_logevent("RoundEnd",2,"1=Round_End")
	register_logevent("RoundEnd",2,"1=Round_Start")
	
	register_think("beam","Beam_Think")
}

public plugin_cfg() {
   new configsdir[128]
   get_localinfo("amxx_configsdir", configsdir, 127)
   server_cmd("exec %s/nova/Lasermine.cfg", configsdir)
   server_exec()
}

public plugin_natives(){
	register_native("lasermine_upgrade_choosed","upgrade_choosed")
}
new Float:g_fTime[33]
public fm_cmdstart(id, uc_handle, seed){
	if(!is_user_alive(id)) return
	fw_TraceLine_Post (id)
	new buttons = get_uc(uc_handle,UC_Buttons)
	
	if(g_fTime[id]>get_gametime()) return
	if(buttons & IN_USE){
		new target, body
		get_user_aiming(id, target, body, 128)
		
		static ClassName[32]
		pev(target, pev_classname, ClassName, charsmax(ClassName))
		if (equal(ClassName, CLASSNAME)){
			if( id != entity_get_edict(target,EV_TM_hOwner)) return
	
			g_fTime[id]=get_gametime()+0.5
			
			if(g_laser_dwig_is[target] == 0){
				g_laser_dwig_is[target] = 1
				return
			}
			if(g_laser_dwig_is[target] == 1){
				g_laser_dwig_is[target] = 0
				return
			}
		}
	}
}
public client_authorized( id ) {
	if(is_user_bot(id)) return
	g_laser_gr_mera_id[id] = get_pcvar_num(g_tm_menu_one)
}
public touch_player(ent, id){
	if(get_pcvar_num(g_Cvar_metod) == 1 || g_menu_open[id] > get_gametime() || g_level[ent] == 2 || get_user_team(id) != entity_get_int(ent,EV_TM_team)) return
	
	if(get_pcvar_num(g_Cvar_metod) == 2)
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H | ADMIN_LEVEL_C)) return
	}
	
	g_menu_open[id] = get_gametime() + 1.0
	
	new planterId
	planterId = entity_get_edict(ent,EV_TM_hOwner)
	
	if(id == planterId){
		if(get_user_flags(id) & get_user_flags(id) & ADMIN_LEVEL_H | ADMIN_LEVEL_C){
			g_IDEniti[id] = ent
			menu_lasermine_build(id)
		}
	}else{
		g_IDEniti[id] = ent
		menu_lasermine_build(id)
	}
}

public menu_lasermine_build(id) {
	
	new menu_name[128]
	formatex(menu_name, charsmax(menu_name), "\yПрокачка лазера ^nЦена: \w[\r%d$\w] ^nУгол: \w[\r%d°\w] ^n\dВыберите ось сканирования:^n", get_pcvar_num(g_Cvar_cost2), g_laser_gr_mera_id[id])
	new menu = menu_create(menu_name, "menu_lasermine_handle")
	
	menu_additem( menu, "\r[\yГоризонатально\r]", "1")
	menu_additem( menu, "\r[\yВертикально\r]", "2")
	menu_additem( menu, "\r[\yИзменить угол\r]", "3")
	
	menu_setprop( menu, MPROP_BACKNAME, "Назад") 
	menu_setprop( menu, MPROP_NEXTNAME, "Вперёд")
	menu_setprop( menu, MPROP_EXITNAME, "Выход")
	menu_display( id, menu, 0 )
	return PLUGIN_HANDLED
}

public menu_lasermine_handle(id, menu, item){
	if( item < 0 ) {
		return PLUGIN_CONTINUE
	}
	if(!is_valid_ent(g_IDEniti[id])) return PLUGIN_HANDLED
	new cmd[ 2 ]
	new access, callback
	menu_item_getinfo( menu, item, access, cmd,2, _, _, callback )
	new choice = str_to_num( cmd )
	
	
	switch(choice){
		case 1: {
			if(cs_get_user_money( id ) >= get_pcvar_num(g_Cvar_cost2)){
				notify_player(id, CHAT_LABEL, "Лазер установлен в режим")
				cs_set_user_money( id, cs_get_user_money( id ) - get_pcvar_num(g_Cvar_cost2) )
				g_level[g_IDEniti[id]] = 2
				g_Metod_abgreid[g_IDEniti[id]] = 1
				TripMine_MakeBeam2(g_IDEniti[id])
				TripMine_MakeBeam(g_IDEniti[id])
				
				g_laser_gr_mera_ent[g_IDEniti[id]] = g_laser_gr_mera_id[id]
				g_laser_dwig[g_IDEniti[id]] = float(g_laser_gr_mera_ent[g_IDEniti[id]])
				entity_set_float(g_IDEniti[id],EV_FL_health,get_pcvar_float(g_Cvar_helath2))
			}else{
				 notify_player(id, CHAT_LABEL, "У тебя не хватает денег! ^4(нужно %d$)", get_pcvar_num(g_Cvar_cost2))
			}
		}
		case 2:{
			if(cs_get_user_money( id ) >= get_pcvar_num(g_Cvar_cost2)){
				cs_set_user_money( id, cs_get_user_money( id ) - get_pcvar_num(g_Cvar_cost2) )
				g_level[g_IDEniti[id]] = 2 // уровень
				g_Metod_abgreid[g_IDEniti[id]] = 2
				TripMine_MakeBeam2(g_IDEniti[id])
				TripMine_MakeBeam(g_IDEniti[id])
				notify_player(id, CHAT_LABEL, "Лазер устоновлен в режим ")
				g_laser_gr_mera_ent[g_IDEniti[id]] = g_laser_gr_mera_id[id]
				g_laser_dwig[g_IDEniti[id]] = float(g_laser_gr_mera_ent[g_IDEniti[id]])
				entity_set_float(g_IDEniti[id],EV_FL_health,get_pcvar_float(g_Cvar_helath2))
			} else {
				 notify_player(id, CHAT_LABEL, "У тебя не хватает денег! ^4(нужно %d$)", get_pcvar_num(g_Cvar_cost2))
			}
		}
		case 3:{
			if(g_laser_gr_mera_id[id] == get_pcvar_num(g_tm_menu_one)){
				g_laser_gr_mera_id[id] = get_pcvar_num(g_tm_menu_second)
			}else if(g_laser_gr_mera_id[id] == get_pcvar_num(g_tm_menu_second)){
				g_laser_gr_mera_id[id] = get_pcvar_num(g_tm_menu_third)
			}else if(g_laser_gr_mera_id[id] == get_pcvar_num(g_tm_menu_third)){
				g_laser_gr_mera_id[id] = get_pcvar_num(g_tm_menu_four)
			}else if(g_laser_gr_mera_id[id] == get_pcvar_num(g_tm_menu_four)){
				g_laser_gr_mera_id[id] = get_pcvar_num(g_tm_menu_five)
			}else if(g_laser_gr_mera_id[id] == get_pcvar_num(g_tm_menu_five)){
				g_laser_gr_mera_id[id] = get_pcvar_num(g_tm_menu_one)
			}
			menu_lasermine_build(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public Beam_Think(ent){
	new mine = entity_get_edict(ent,EV_ENT_owner)
	
	if(!is_valid_ent(ent))
		UTIL_Remove(ent)
	
	if(is_valid_ent(mine) && entity_get_int(ent,EV_TM_mineId) != entity_get_int(mine,EV_TM_mineId))
		UTIL_Remove(ent)
	
	entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.05)
}

public RoundEnd(){
	new ent
	
	while((ent = find_ent_by_class(ent,CLASSNAME))){
		new beam = entity_get_edict(ent,EV_TM_pBeam)	  
		if(is_valid_ent(beam))
			remove_entity(beam)
			
		beam = entity_get_edict(ent,EV_TM_pBeam2)	
		if(is_valid_ent(beam))
			remove_entity(beam)
			
		beam = entity_get_edict(ent,EV_TM_pBeam3)  
		if(is_valid_ent(beam))
			remove_entity(beam)
			
		remove_entity(ent)
	}
}

public CreateLaserMine(PID[]){
	new id = PID[0]

	remove_task(TASK_PLANT + id)
	if(thinkHooks <= 0)
		DisableHamForward(playerPostThink)
	SetLaser_DropCMD(id)
}

public SetLaser_CMD(id){	
	if(get_user_flags(id) & get_user_flags(id) & ADMIN_LEVEL_H | ADMIN_LEVEL_C){
		if(GetPlayer_Mines(id) >= get_pcvar_num(g_Cvar_max_mine_vip)){ 
			playerData[id][PD_NEXTPLANT_TIME] =  _:(get_gametime() + PLANTWAITTIME)
			notify_player(id, CHAT_LABEL, "Установлено максимальное количество мин!")
			return PLUGIN_HANDLED
		}
	}else{
		if(GetPlayer_Mines(id) >= get_pcvar_num(g_Cvar_max_mine)){ 
			playerData[id][PD_NEXTPLANT_TIME] =  _:(get_gametime() + PLANTWAITTIME)
			notify_player(id, CHAT_LABEL, "Установлено максимальное количество мин!")
			return PLUGIN_HANDLED
		}
	}
	
	
	playerData[id][PD_START_SET] = true
	
	thinkHooks++
	
	new PID[1]
	PID[0] = id
	set_task(2.0, "CreateLaserMine", (TASK_PLANT + id), PID, 1)
	
	
	if(thinkHooks == 1){
		if(!playerPostThink)
			playerPostThink = RegisterHam(Ham_Player_PostThink,"player","Player_PostThink",true)
		
		else
			EnableHamForward(playerPostThink)
	}
	
	return PLUGIN_HANDLED
}

public SetLaser_DropCMD(id){
	if(!playerData[id][PD_START_SET])
		return PLUGIN_HANDLED
		
	thinkHooks--
	
	if(thinkHooks <= 0)
		DisableHamForward(playerPostThink)
		
	playerData[id][PD_START_SET] = false
	
	remove_task(TASK_PLANT + id)
	
	if(is_valid_ent(playerData[id][PD_MINE_ENT])){
		remove_entity(playerData[id][PD_MINE_ENT])
		Send_BarTime(id,0.0)
		playerData[id][PD_MINE_ENT] = FM_NULLENT
		playerData[id][PD_NEXTPLANT_TIME] =  _:(get_gametime() + PLANTWAITTIME)
	}
		
	return PLUGIN_HANDLED
}

public Player_PostThink(id){
	if(playerData[id][PD_START_SET])
		if(TripMine_PlantThink(id))
			TripMine_Plant(id,playerData[id][PD_MINE_ENT]) // plant mine
}

TripMine_Spawn(){
	new tm = create_entity(ENTITY_REFERENCE)
	
	entity_set_string(tm,EV_SZ_classname,CLASSNAME)
	
	// motor
	entity_set_int(tm,EV_INT_movetype,MOVETYPE_FLY)
	entity_set_int(tm,EV_INT_solid,SOLID_NOT)
	
	entity_set_model(tm,TRIPMINE_MODEL)
	entity_set_float(tm,EV_FL_frame,0.0)
	entity_set_int(tm,EV_INT_body,3)
	entity_set_int(tm,EV_INT_sequence,7)	// TRIPMINE_WORLD
	entity_set_float(tm,EV_FL_framerate,0.0)
	
	entity_set_size(tm,Float:{-4.0,-4.0,-4.0},Float:{4.0,4.0,4.0})
	
	return tm
}

GetPlayer_Mines(id){
	new ent,cnt
	
	while((ent = find_ent_by_class(ent,CLASSNAME))){
		if(id == entity_get_edict(ent,EV_TM_hOwner))
			cnt ++
	}
	
	return cnt
}

//
// Visual planting for tripmine
//	id - planter id
//	reset - stop planting
//
TripMine_PlantThink(id,bool:reset = false){
	if(playerData[id][PD_NEXTPLANT_TIME] > get_gametime())
		return false
		
	new ent = playerData[id][PD_MINE_ENT]
	
	if(!is_user_alive(id) || cs_get_user_money(id) - get_pcvar_num(g_Cvar_cost) < 0)
	{ // don't allow planting while running or dead
		if(is_valid_ent(ent)){
			remove_entity(ent)
			Send_BarTime(id,0.0)
		}
		notify_player(id, CHAT_LABEL, "У тебя не хватает денег! ^4(нужно %d$)",get_pcvar_num(g_Cvar_cost))
		
		playerData[id][PD_MINE_ENT] = FM_NULLENT
		SetLaser_DropCMD(id)
		return false
	}
	
	if(reset){ // destroy visal object
		if(is_valid_ent(ent)){
			remove_entity(ent)
			Send_BarTime(id,0.0)
			playerData[id][PD_MINE_ENT] = FM_NULLENT
			
			return true
		}
		
		return false
	}
	
	// make trace origin
	new Float:vecSrc[3],Float:vecAiming[3]
	entity_get_vector(id,EV_VEC_v_angle,vecSrc)
	engfunc(EngFunc_MakeVectors,vecSrc)
	
	entity_get_vector(id,EV_VEC_origin,vecSrc)
	entity_get_vector(id,EV_VEC_view_ofs,vecAiming)
	
	xs_vec_add(vecSrc,vecAiming,vecSrc)
	get_global_vector(GL_v_forward,vecAiming)
	
	xs_vec_mul_scalar(vecAiming,PLANT_RADIUS,vecAiming)
	xs_vec_add(vecSrc,vecAiming,vecAiming)
	
	new Float:flFraction
	engfunc(EngFunc_TraceLine,vecSrc,vecAiming,IGNORE_MISSILE|IGNORE_GLASS|IGNORE_MONSTERS,id,0)
	
	get_tr2(0,TR_flFraction,flFraction)
	
	if(flFraction < 1.0){ // valid trace
		new pHit
		
		new Float:vecEnd[3],bool:noUpdate
		get_tr2(0,TR_vecEndPos,vecEnd)
		
		while((pHit = find_ent_in_sphere(pHit,vecEnd,8.0))){ // don't allow plant mine close together with others
			if(pHit <= maxPlayers || pHit == ent)
				continue
				
			new classname[32]
			entity_get_string(pHit,EV_SZ_classname,classname,charsmax(classname))	
			
			if(strcmp(classname,CLASSNAME) == 0){
				noUpdate = true
				
				if(!is_valid_ent(ent))
					return false
			}
		}
		
		if(!is_valid_ent(ent)){	// create visal object
			ent =TripMine_Spawn()
		
			// set transparency
			entity_set_int(ent,EV_INT_rendermode,kRenderTransAdd)
			entity_set_float(ent,EV_FL_renderamt,255.0)
			
			new Float:plantTime = PLANT_TIME
			
			// set plant time
			entity_set_float(ent,EV_TM_plantTime,get_gametime() + plantTime)
			entity_set_float(id,EV_FL_maxspeed,1.0)
			
			// show plant progress
			Send_BarTime(id,plantTime)
			
			playerData[id][PD_MINE_ENT] = ent
		}
		
		if(!noUpdate){
			new Float:vecPlaneNormal[3],Float:angles[3]
			get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)
			vector_to_angle(vecPlaneNormal,angles)
			
			// calc ideal end pos
			xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
			xs_vec_add(vecEnd,vecPlaneNormal,vecEnd)
			
			// set origin and angles
			entity_set_origin(ent,vecEnd)
			entity_set_vector(ent,EV_VEC_angles,angles)
		}
		
		if(entity_get_float(ent,EV_TM_plantTime) < get_gametime()){
			new Float:m_vecDir[3],Float:angles[3]
			
			entity_get_vector(ent,EV_VEC_angles,angles)
			engfunc(EngFunc_MakeVectors,angles)
			get_global_vector(GL_v_forward,m_vecDir)
			
			m_vecDir[2] = -m_vecDir[2] // 󯬼묠ࡐﲱ馠㦰󞫠󬡭饬 ힺ���饠- 󬡢汵

			entity_set_vector(ent,EV_TM_mVecDir,m_vecDir)
			
			return true
		}
	}else{ // wrong origin
		if(is_valid_ent(ent)){
			remove_entity(ent)
			Send_BarTime(id,0.0)
			playerData[id][PD_MINE_ENT] = FM_NULLENT
		}
	}
		
	return false
}

//
// Plant mine
//
TripMine_Plant(id,ent){
	playerData[id][PD_MINE_ENT] = FM_NULLENT
	playerData[id][PD_NEXTPLANT_TIME] =  _:(get_gametime() + PLANTWAITTIME)
	
	entity_set_int(ent,EV_INT_rendermode,kRenderNormal)
	entity_set_float(ent,EV_FL_renderamt,0.0)
	
	entity_set_edict(ent,EV_TM_hOwner,id)
	entity_set_int(ent,EV_TM_team,get_user_team(id))
	
	emit_sound(ent,CHAN_VOICE,TRIPMINE_PLANTSOUND,1.0,ATTN_NORM,0,PITCH_NORM)
	emit_sound(ent,CHAN_BODY,TRIPMINE_CHARGESOUND,0.2,ATTN_NORM,0,PITCH_NORM)
	
	entity_set_float(ent,EV_TM_plantTime,get_gametime() + POWERUPTIME)
	entity_set_float(ent,EV_FL_nextthink,get_gametime() + POWERUPTIME)

	
	cs_set_user_money(id,cs_get_user_money(id) - get_pcvar_num(g_Cvar_cost))
	
	g_laser_dwig[ent] = 0.0
	g_laser_stor[ent] = 1
	g_level[ent] = 1
	g_laser_dwig_is[ent] = 0
	g_Metod_abgreid[ent] = 0
	g_Laser_kill[ent] = 0
	g_laser_gr_mera_ent[ent] = 0
	
	SetLaser_DropCMD(id)
	
	return true
}


public TripMine_Think(ent){
	if(entity_get_float(ent,EV_TM_plantTime)){ // check the possibility to activate
		new Float:m_vecDir[3]
		entity_get_vector(ent,EV_TM_mVecDir,m_vecDir)
	
		new Float:vecSrc[3],Float:vecEnd[3]
		
		entity_get_vector(ent,EV_VEC_origin,vecSrc)
		xs_vec_copy(vecSrc,vecEnd)
	
		xs_vec_mul_scalar(m_vecDir,8.0,m_vecDir)
		xs_vec_add(vecSrc,m_vecDir,vecSrc)
		
		entity_get_vector(ent,EV_TM_mVecDir,m_vecDir)
		xs_vec_mul_scalar(m_vecDir,32.0,m_vecDir)
		xs_vec_add(vecEnd,m_vecDir,vecEnd)
		
		engfunc(EngFunc_TraceLine,vecSrc,vecEnd,DONT_IGNORE_MONSTERS,ent,0)
		
		new Float:flFraction
		
		get_tr2(0,TR_flFraction,flFraction)
		
		if(flFraction == 1.0){
			get_tr2(0,TR_vecEndPos,vecEnd)
			
			new f
			// make sure that player will not stuck on mine
			while((f = find_ent_in_sphere(f,vecSrc,12.0))){
				if(f > maxPlayers)
					break
					
				entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1)
				return
			}
			
			emit_sound(ent,CHAN_BODY,TRIPMINE_CHARGESOUND,0.0,ATTN_NORM,SND_STOP,0)
			emit_sound(ent,CHAN_VOICE,TRIPMINE_ACTIVESOUND,0.5,ATTN_NORM,1,75)
			
			entity_set_int(ent,EV_TM_mineId,random(1337))
			TripMine_MakeBeam3(ent)
			
			entity_set_int(ent,EV_INT_solid,SOLID_BBOX)
			entity_set_float(ent,EV_TM_plantTime,0.0)
			
			entity_set_float(ent,EV_FL_takedamage,DAMAGE_YES)
			entity_set_float(ent,EV_FL_dmg,100.0)
			entity_set_float(ent,EV_FL_health,get_pcvar_float(g_Cvar_helath))
		}
	}
	
	new beam = entity_get_edict(ent,EV_TM_pBeam3)
	
	if(entity_get_float(ent,EV_FL_health) <= 0.0 && is_valid_ent(beam)){
		ExecuteHamB(Ham_Killed,ent,0,0)
		return
	}
	
	new id = entity_get_edict(ent,EV_TM_hOwner)
	
	if(!is_user_alive(id) || get_user_team(id) != entity_get_int(ent,EV_TM_team)){
		beam = entity_get_edict(ent,EV_TM_pBeam)
		if(is_valid_ent(beam))
			UTIL_Remove(beam)
		
		beam = entity_get_edict(ent,EV_TM_pBeam2)
		if(is_valid_ent(beam))
			UTIL_Remove(beam)
		beam = entity_get_edict(ent,EV_TM_pBeam3)
		if(is_valid_ent(beam))
			UTIL_Remove(beam)
		
		
		remove_entity(ent)
		
		return
	}
	if(is_valid_ent(beam)){
		new Float:vecSrc[3],Float:vecEnd[3], Float:vecEnd2[3]
		static Float:vAngle[3], Float:vForward[3]	
		pev(ent,pev_angles,vAngle)
		
		entity_get_vector(ent,EV_VEC_origin,vecSrc)
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)	 
		
		
		vecEnd[0] = vecSrc[0] + vForward[0] * 9999 
		vecEnd[1] = vecSrc[1] + vForward[1] * 9999
		vecEnd[2] = vecSrc[2] - vForward[2] * 9999
   
		new pHit,tr = create_tr2()
		engfunc(EngFunc_TraceLine,vecSrc,vecEnd,DONT_IGNORE_MONSTERS,ent,tr)
		
		pHit = get_tr2(tr,TR_pHit)
		get_tr2(tr,TR_vecEndPos,vecEnd2)
		
		Beam_SetStartPos(beam,vecEnd2) 
		
		message_begin_f(MSG_PVS,SVC_TEMPENTITY,vecEnd2,0)
		write_byte(TE_SPARKS)
		write_coord_f(vecEnd2[0])
		write_coord_f(vecEnd2[1])
		write_coord_f(vecEnd2[2])
		message_end()
		
		if(0 < pHit <= maxPlayers){
			new team = entity_get_int(ent,EV_TM_team)
			
			if(get_user_team(pHit) != team && entity_get_float(pHit,EV_FL_takedamage) != 0.0 && !IsInSphere (pHit)){
				if(get_user_health(pHit) <= get_pcvar_float(g_Cvar_dmg)){
					g_Laser_kill[ent]++
				}
				if(ExecuteHamB(Ham_TakeDamage,pHit,ent,entity_get_edict(ent,EV_TM_hOwner),get_pcvar_float(g_Cvar_dmg),16777216)){
					ExecuteHamB(Ham_TraceBleed,pHit,1337.0,Float:{0.0,0.0,0.0},tr,DMG_ENERGYBEAM)
				}else{
					emit_sound(pHit,CHAN_WEAPON,TRIPMINE_HITSOUND, 1.0, ATTN_NORM, 0, PITCH_NORM )
					entity_set_vector(pHit,EV_VEC_velocity,Float:{0.0,0.0,0.0})
				}
			}
		}
		
		free_tr2(tr)
	}
	
	beam = entity_get_edict(ent,EV_TM_pBeam)
	
	if(g_level[ent] == 2)
	{
		if(is_valid_ent(beam)){
			new Float:vecSrc[3],Float:vecEnd[3], Float:vecEnd2[3]
			static Float:vAngle[3], Float:vForward[3]	
			pev(ent,pev_angles,vAngle)	
			if(g_laser_dwig_is[ent] == 1)
			{
				if(g_laser_stor[ent] == 1){
					if(g_laser_dwig[ent] <= g_laser_gr_mera_ent[ent]){
						g_laser_dwig[ent]+= 0.5
					}else{
						g_laser_stor[ent] = 2
					}
				}else if(g_laser_stor[ent] == 2){
					if(g_laser_dwig[ent] >= -g_laser_gr_mera_ent[ent]){
						g_laser_dwig[ent]-=0.5
					}else{
						g_laser_stor[ent] = 1
					}
				}
			}
			if(g_Metod_abgreid[ent] == 2){
				vAngle[0]+=g_laser_dwig[ent]
			}else if(g_Metod_abgreid[ent] == 1){
				vAngle[1]+=g_laser_dwig[ent]
			}
			entity_get_vector(ent,EV_VEC_origin,vecSrc)
			angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)	 
			vecEnd[0] = vecSrc[0] + vForward[0] * 9999 
			vecEnd[1] = vecSrc[1] + vForward[1] * 9999
			vecEnd[2] = vecSrc[2] - vForward[2] * 9999
			
			new pHit,tr = create_tr2()
			engfunc(EngFunc_TraceLine,vecSrc,vecEnd,DONT_IGNORE_MONSTERS,ent,tr)
			
			pHit = get_tr2(tr,TR_pHit)
			get_tr2(tr,TR_vecEndPos,vecEnd2)
			
			Beam_SetStartPos(beam,vecEnd2) 
			
			message_begin_f(MSG_PVS,SVC_TEMPENTITY,vecEnd2,0)
			write_byte(TE_SPARKS)
			write_coord_f(vecEnd2[0])
			write_coord_f(vecEnd2[1])
			write_coord_f(vecEnd2[2])
			message_end()
			
			if(0 < pHit <= maxPlayers){
				new team = entity_get_int(ent,EV_TM_team)
				
				if(get_user_team(pHit) != team && entity_get_float(pHit,EV_FL_takedamage) != 0.0 && !IsInSphere (pHit)){
					if(get_user_health(pHit) <= get_pcvar_float(g_Cvar_dmg)){
						g_Laser_kill[ent]++
					}
					if(ExecuteHamB(Ham_TakeDamage,pHit,ent,entity_get_edict(ent,EV_TM_hOwner),get_pcvar_float(g_Cvar_dmg),16777216)){
						ExecuteHamB(Ham_TraceBleed,pHit,1337.0,Float:{0.0,0.0,0.0},tr,DMG_ENERGYBEAM)
					}else{
						emit_sound(pHit,CHAN_WEAPON,TRIPMINE_HITSOUND, 1.0, ATTN_NORM, 0, PITCH_NORM )
						entity_set_vector(pHit,EV_VEC_velocity,Float:{0.0,0.0,0.0})
					}
				}
			}
			
			free_tr2(tr)
		}
		beam = entity_get_edict(ent,EV_TM_pBeam2)
		if(is_valid_ent(beam)){
			new Float:vecSrc[3],Float:vecEnd[3], Float:vecEnd2[3]
			static Float:vAngle[3], Float:vForward[3]	
			pev(ent,pev_angles,vAngle)
			
			entity_get_vector(ent,EV_VEC_origin,vecSrc)
			entity_get_vector(ent,EV_TM_mVecEnd2,vecEnd)

			entity_get_vector(ent,EV_VEC_origin,vecSrc)
			if(g_Metod_abgreid[ent] == 2){
				vAngle[0]-=g_laser_dwig[ent]
			}else if(g_Metod_abgreid[ent] == 1){
				vAngle[1]-=g_laser_dwig[ent]
			}
			angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)	 
			vecEnd[0] = vecSrc[0] + vForward[0] * 9999
			vecEnd[1] = vecSrc[1] + vForward[1] * 9999
			vecEnd[2] = vecSrc[2] - vForward[2] * 9999
			
			
			new pHit,tr = create_tr2()
			engfunc(EngFunc_TraceLine,vecSrc,vecEnd,DONT_IGNORE_MONSTERS,ent,tr)
			
			pHit = get_tr2(tr,TR_pHit)
			get_tr2(tr,TR_vecEndPos,vecEnd2)
			
			Beam_SetStartPos(beam,vecEnd2) 
			
			message_begin_f(MSG_PVS,SVC_TEMPENTITY,vecEnd2,0)
			write_byte(TE_SPARKS)
			write_coord_f(vecEnd2[0])
			write_coord_f(vecEnd2[1])
			write_coord_f(vecEnd2[2])
			message_end()
			
			if(0 < pHit <= maxPlayers){
				new team = entity_get_int(ent,EV_TM_team)
				
				if(get_user_team(pHit) != team && entity_get_float(pHit,EV_FL_takedamage) != 0.0 && !IsInSphere (pHit)){
					if(get_user_health(pHit) <= get_pcvar_float(g_Cvar_dmg)){
						g_Laser_kill[ent]++
					}
					if(ExecuteHamB(Ham_TakeDamage,pHit,ent,entity_get_edict(ent,EV_TM_hOwner),get_pcvar_float(g_Cvar_dmg),16777216)){
						ExecuteHamB(Ham_TraceBleed,pHit,1337.0,Float:{0.0,0.0,0.0},tr,DMG_ENERGYBEAM)
					}else{
						emit_sound(pHit,CHAN_WEAPON,TRIPMINE_HITSOUND, 1.0, ATTN_NORM, 0, PITCH_NORM )
						entity_set_vector(pHit,EV_VEC_velocity,Float:{0.0,0.0,0.0})
					}
				}
			}
			free_tr2(tr)
		}
	}
	if(is_valid_ent(ent)){
		entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.05)
	}
}
new Float:taget_tim[33]
public fw_TraceLine_Post ( id ){
	if(taget_tim[id]<get_gametime())
	{
		taget_tim[id]=get_gametime()+0.5

		new ent, body
		get_user_aiming(id, ent, body, 128)
		static ClassName[32]
		pev(ent, pev_classname, ClassName, charsmax(ClassName))
		if (equal(ClassName, CLASSNAME)) 
		{
			if(is_valid_ent(ent))
			{
				if(get_user_team(id) == entity_get_int(ent,EV_TM_team))
				{
					new planterId,planterName[32],team = entity_get_int(ent,EV_TM_team)
						
					planterId = entity_get_edict(ent,EV_TM_hOwner)
					get_user_name(planterId,planterName,charsmax(planterName))
						
					new Float: Helath_max
					if(g_level[ent] == 1){
						Helath_max = get_pcvar_float(g_Cvar_helath)
					} else if(g_level[ent] == 2){
						Helath_max = get_pcvar_float(g_Cvar_helath2)
					}
						
					set_dhudmessage(team == 1 ? 255 : 0, 50, team == 2 ? 255 : 0, -1.0, 0.35, 0, 0.0, 0.55, 0.0, 0.0)
					show_dhudmessage(id,"Установил: %s^nЗдоровье: %.0f/%.0f^nУровень: %d^nУбийств: %d",planterName,entity_get_float(ent,EV_FL_health),Helath_max, g_level[ent], g_Laser_kill[ent])
					if(g_level[ent] == 2){
						if(id == planterId){
							set_dhudmessage(team == 1 ? 255 : 0, 50, team == 2 ? 255 : 0, -1.0, 0.35, 0, 0.0, 0.55, 0.0, 0.0)
							show_dhudmessage(id,"^n^n^n^n Для запуска лучей нажмите [E]")
						}
					}
				}
			}
		}
	}
}


//
// Tripmine damage
//
public TripMine_Damage(ent,inflictor,attacker){
	new classname[32]
	entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))
	
	if(strcmp(classname,CLASSNAME) != 0)
		return HAM_IGNORED
		
	entity_set_edict(ent,EV_ENT_dmg_inflictor,attacker)
	
	if(!(0 < attacker <= maxPlayers))
		return HAM_IGNORED
	
	if(entity_get_int(ent,EV_TM_team) == get_user_team(attacker) && entity_get_edict(ent,EV_TM_hOwner) != attacker) // block friendly fire
		return HAM_SUPERCEDE
		
	return HAM_IGNORED
}

//
// Tripmine detonate
//
public TripMine_Killed(ent){
	new classname[32]
	entity_get_string(ent,EV_SZ_classname,classname,charsmax(classname))
	
	if(strcmp(classname,CLASSNAME) != 0)
		return HAM_IGNORED
		
	new beam = entity_get_edict(ent,EV_TM_pBeam)
	if(is_valid_ent(beam))
		UTIL_Remove(beam)
		
	beam = entity_get_edict(ent,EV_TM_pBeam2)
	if(is_valid_ent(beam))
		UTIL_Remove(beam)
		
	beam = entity_get_edict(ent,EV_TM_pBeam3)
	if(is_valid_ent(beam))
		UTIL_Remove(beam)
		
	new Float:origin[3],Float:m_vecDir[3]
	entity_get_vector(ent,EV_VEC_origin,origin)
	entity_get_vector(ent,EV_TM_mVecDir,m_vecDir)
	
	xs_vec_mul_scalar(m_vecDir,8.0,m_vecDir)
	xs_vec_add(origin,m_vecDir,origin)
	
	message_begin_f(MSG_PVS,SVC_TEMPENTITY,origin,0)
	write_byte(TE_EXPLOSION)
	write_coord_f(origin[0])
	write_coord_f(origin[1])
	write_coord_f(origin[2])
	write_short(expSpr)
	write_byte(20)
	write_byte(15)
	write_byte(0)
	message_end()
	
	new killer = entity_get_edict(ent,EV_ENT_dmg_inflictor)
	new hOwner = entity_get_edict(ent,EV_TM_hOwner)
	
	if(!(0 < killer <= maxPlayers) || killer == entity_get_edict(ent,EV_TM_hOwner))
		notify_player(hOwner, CHAT_LABEL, "Ваша мина взорвалась!")
	else{
		new exploderName[32]
		get_user_name(killer,exploderName,charsmax(exploderName))
		
		notify_player(hOwner, CHAT_LABEL, "%s уничтожил вашу мину!",exploderName)
	}
	
	return HAM_IGNORED
}

//
// Create beam for tripmine
//
TripMine_MakeBeam(ent){
	new beam = Beam_Create(entity_get_int(ent,EV_TM_team) == 1 ? BEAM_SPRITERED : BEAM_SPRITEBLUE,BEAM_WIDTH)
	
	new Float:m_vecDir[3],Float:vecSrc[3],Float:vecOrigin[3]
	entity_get_vector(ent,EV_TM_mVecDir,m_vecDir)
	entity_get_vector(ent,EV_VEC_origin,vecSrc)
	xs_vec_copy(vecSrc,vecOrigin)
	xs_vec_mul_scalar(m_vecDir,LASER_LENGTH,m_vecDir)
	xs_vec_add(vecSrc,m_vecDir,vecSrc)
	
	Beam_PointsInit(beam,vecSrc,vecOrigin)
	Beam_SetScrollRate(beam,255.0)
	Beam_SetBrightness(beam,BEAM_BRIGHT)
	
	entity_set_edict(ent,EV_TM_pBeam,beam)
	entity_set_vector(ent,EV_TM_mVecEnd,vecSrc)
	entity_set_edict(beam,EV_ENT_owner,ent)
	
	entity_set_int(beam,EV_TM_mineId,entity_get_int(ent,EV_TM_mineId))
	
	entity_set_float(beam,EV_FL_nextthink,get_gametime() + 0.1)
}
TripMine_MakeBeam2(ent){
	new beam = Beam_Create(entity_get_int(ent,EV_TM_team) == 1 ? BEAM_SPRITERED : BEAM_SPRITEBLUE,BEAM_WIDTH)
	
	new Float:m_vecDir[3],Float:vecSrc[3],Float:vecOrigin[3]
	entity_get_vector(ent,EV_TM_mVecDir,m_vecDir)
	entity_get_vector(ent,EV_VEC_origin,vecSrc)
	xs_vec_copy(vecSrc,vecOrigin)
	xs_vec_mul_scalar(m_vecDir,LASER_LENGTH,m_vecDir)
	xs_vec_add(vecSrc,m_vecDir,vecSrc)
	
	Beam_PointsInit(beam,vecSrc,vecOrigin)
	Beam_SetScrollRate(beam,255.0)
	Beam_SetBrightness(beam,BEAM_BRIGHT)
	
	entity_set_edict(ent,EV_TM_pBeam2,beam)
	entity_set_vector(ent,EV_TM_mVecEnd2,vecSrc)
	entity_set_edict(beam,EV_ENT_owner,ent)
	
	entity_set_int(beam,EV_TM_mineId,entity_get_int(ent,EV_TM_mineId))
	
	entity_set_float(beam,EV_FL_nextthink,get_gametime() + 0.1)
}
TripMine_MakeBeam3(ent){
	new beam = Beam_Create(entity_get_int(ent,EV_TM_team) == 1 ? BEAM_SPRITERED : BEAM_SPRITEBLUE,BEAM_WIDTH)
	
	new Float:m_vecDir[3],Float:vecSrc[3],Float:vecOrigin[3]
	entity_get_vector(ent,EV_TM_mVecDir,m_vecDir)
	entity_get_vector(ent,EV_VEC_origin,vecSrc)
	xs_vec_copy(vecSrc,vecOrigin)
	xs_vec_mul_scalar(m_vecDir,LASER_LENGTH,m_vecDir)
	xs_vec_add(vecSrc,m_vecDir,vecSrc)
	
	Beam_PointsInit(beam,vecSrc,vecOrigin)
	Beam_SetScrollRate(beam,255.0)
	Beam_SetBrightness(beam,BEAM_BRIGHT)
	
	entity_set_edict(ent,EV_TM_pBeam3,beam)
	entity_set_vector(ent,EV_TM_mVecEnd3,vecSrc)
	entity_set_edict(beam,EV_ENT_owner,ent)
	
	entity_set_int(beam,EV_TM_mineId,entity_get_int(ent,EV_TM_mineId))
	
	entity_set_float(beam,EV_FL_nextthink,get_gametime() + 0.1)
}

Send_BarTime(player,Float:duration){
	message_begin(MSG_ONE,BarTime,.player = player)
	write_short(floatround(duration))
	message_end()
}


UTIL_Remove( pEntity ){
	if ( !pEntity )
		return;
		
	entity_set_int(pEntity,EV_INT_flags,entity_get_int(pEntity,EV_INT_flags) | FL_KILLME)
	//entity_set_string(pEntity,EV_SZ_targetname,"")
}

    
bool:IsInSphere ( id ){
	if ( !is_user_alive ( id ) )
		return false

	new ent = -1 
	while ( ( ent = engfunc ( EngFunc_FindEntityByString, ent, "classname", "campo_grenade_forze" ) ) > 0 )
	{
		new iOwner = pev ( ent, pev_owner )

		if ( cs_get_user_team ( id ) != cs_get_user_team ( iOwner ) )
			continue

		new Float:fOrigin[3]
		pev ( ent, pev_origin, fOrigin )
		new iPlayer = -1
		while ( ( iPlayer = engfunc ( EngFunc_FindEntityInSphere, iPlayer, fOrigin, 68.0 ) ) != 0 )
		{
			if ( iPlayer == id )
				return true
		}
	}
	return false
}