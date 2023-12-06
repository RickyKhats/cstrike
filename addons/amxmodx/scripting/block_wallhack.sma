/*	Formatright © 2009, OT

	Block Wallhack is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Migraine; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

/*  [Plugin Link]
	https://forums.alliedmods.net/showthread.php?t=100886
*/

/*  [Changelog]
- 4.5 - texture check now isn't made that often (less crash risk!), added texture check autodisable cfg, added a new method to ignore entities that are transparent (100% efficient), reupdated the weapon headpoint
- 4.2 - added bitsum remember system, smooth check is made now by FRAME_CONSTANT (1/48), changed alive/dead recognision system (less resource use!)
- 4.1 - fixed plugin_init problem!
- 4.0 - all bugs fixed, added texture check , everything tweaked and tuned!
- 3.0 - removed Engine module (another method), improved smooth engine, removed , fixed flashing bug, target check now works both ways (if you are seen the player will be shown!)
- 2.5 - removed HamSandWich module (useless), improved smooth check, corpse remove bug fixed, optimized the code a little bit.
- 2.4 - bug fix release (weapon index out of bounds fix, reconnect bug fix (with CSDM), made the ent check not so sensitive (not so many blind-spots)
- 2.2 - bug fix release (index out of bounds & weapon confusion bug)
- 2.1 - removed a bugged feature (block_dead cvar), added smooth cvar
- 2.0 - more customizable, less cpu usage (50% TESTED!), weapons grenades check added, bug fixes
- 1.5 - removed some checks, optimized it a bit, added weapon head-point check
- 1.0 - initial release 
*/

/*  [Credits]
- joaquimandrade - for pointing out the plugin flaws!
- ShlumPF* - for small improvements (initial v1.0)
- turshija - for some small suggestions.
- h010c - for tests and benchmarks, anti-soundhack tests and code samples
- hlstriker - for finding the way to detect semi-transparent textures!
- .Owyn. - bug reports
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN	"Block WallHack"
#define AUTHOR	""
#define VERSION	"4.5"

#define MAX_PLAYERS							32
// Uncomment this if you want to see what the plugin actually checks, the plugin will not block any wallhack in test mode!!!
//#define point_test
//#define ignore_bots
//#define target_check

#define GENERAL_X_Y_SORROUNDING 			18.5 		// 16.0
#define CONSTANT_Z_CROUCH_UP 				31.25 		// 32.0
#define CONSTANT_Z_CROUCH_DOWN 				17.5 		// 16.0
#define CONSTANT_Z_STANDUP_UP 				34.0 		// 36.0
#define CONSTANT_Z_STANDUP_DOWN 			35.25 		// 36.0

#define GENERAL_X_Y_SORROUNDING_HALF		9.25 		// 8.0
#define GENERAL_X_Y_SORROUNDING_HALF2		12.0 		// 8.0
#define CONSTANT_Z_CROUCH_UP_HALF 			15.5 		// 16.0
#define CONSTANT_Z_CROUCH_DOWN_HALF			8.75 		// 8.0
#define CONSTANT_Z_STANDUP_UP_HALF			17.0 		// 18.0
#define CONSTANT_Z_STANDUP_DOWN_HALF		17.5 		// 18.0

#define ANGLE_COS_HEIGHT_CHECK				0.7071		// cos(45  degrees)

#define FRAME_OFFSET_CONSTANT				0.0208

new const Float:weapon_edge_point[CSW_P90+1] =
{
    0.00, // nothing
    32.8, // p228 
    0.00, // shield
    38.9, // scout
    0.00, // hegrenade
    31.2, // xm1014
    0.00, // c4
    26.0, // mac10
    32.9, // aug
    0.00, // smokegrenade
    23.5, // elite
    32.7, // fiveseven  
    27.0, // ump45
    40.0, // sg550   
    26.5, // galil
    32.6, // famas    
    38.9, // usp ( without silencer 23.5 )
    32.6, // glock     
    39.5, // awp     
    30.4, // mp5        
    30.5, // m249
    30.1, // m3    
    41.4, // m4a1 ( without silencer 32.6 )
    39.2, // tmp         
    42.2, // g3sg1      
    0.00, // flashbang
    34.1, // deagle  
    34.0, // sg552   
    24.8, // ak47       
    0.00, // knife
    25.4  // p90
}

new const Float:vec_multi_lateral[] = 
{
	GENERAL_X_Y_SORROUNDING,
	-GENERAL_X_Y_SORROUNDING,
	GENERAL_X_Y_SORROUNDING_HALF2,
	-GENERAL_X_Y_SORROUNDING_HALF
}

new const Float:vec_add_height_crouch[] =
{
	CONSTANT_Z_CROUCH_UP,
	-CONSTANT_Z_CROUCH_DOWN,
	CONSTANT_Z_CROUCH_UP_HALF,
	-CONSTANT_Z_CROUCH_DOWN_HALF
}

new const Float:vec_add_height_standup[] =
{
	CONSTANT_Z_STANDUP_UP,
	-CONSTANT_Z_STANDUP_DOWN,
	CONSTANT_Z_STANDUP_UP_HALF,
	-CONSTANT_Z_STANDUP_DOWN_HALF
}

new g_cl_team[MAX_PLAYERS + 1]
new g_cl_weapon[MAX_PLAYERS + 1]
new g_cl_viewent[MAX_PLAYERS + 1]
new bs_cl_alive, bs_cl_ducking, bs_cl_connect, bs_cl_bot, bs_cl_announce

#define add_bot_property(%1)						bs_cl_bot |= (1<<(%1 - 1))
#define del_bot_property(%1)						bs_cl_bot &= ~(1<<(%1 - 1))
#define has_bot_property(%1)						(bs_cl_bot & (1<<(%1 - 1)))
#define add_connect_property(%1)					bs_cl_connect |= (1<<(%1 - 1))
#define del_connect_property(%1)					bs_cl_connect &= ~(1<<(%1 - 1))
#define has_connect_property(%1)					(bs_cl_connect & (1<<(%1 - 1)))
#define add_duck_property(%1)						bs_cl_ducking |= (1<<(%1 - 1))
#define del_duck_property(%1)						bs_cl_ducking &= ~(1<<(%1 - 1))
#define has_duck_property(%1)						(bs_cl_ducking & (1<<(%1 - 1)))
#define add_alive_property(%1)						bs_cl_alive |= (1<<(%1 - 1))
#define del_alive_property(%1)						bs_cl_alive &= ~(1<<(%1 - 1))
#define has_alive_property(%1)						(bs_cl_alive & (1<<(%1 - 1)))
#define add_alive_property(%1)						bs_cl_alive |= (1<<(%1 - 1))
#define del_alive_property(%1)						bs_cl_alive &= ~(1<<(%1 - 1))
#define has_alive_property(%1)						(bs_cl_alive & (1<<(%1 - 1)))
#define add_announced(%1)							bs_cl_announce |= (1<<(%1 - 1))
#define del_announced(%1)							bs_cl_announce &= ~(1<<(%1 - 1))
#define has_been_announced(%1)						(bs_cl_announce & (1<<(%1 - 1)))

new bs_cl_targets[MAX_PLAYERS + 1]
new bs_cl_seen_by[MAX_PLAYERS + 1]
new bs_cl_smooth[MAX_PLAYERS + 1] = {~0, ...} // ~0 = -4294967295

// %0 is the player that targets, is seen by , can smooth
#define add_targeted_player(%0,%1)					bs_cl_targets[%0] |= (1<<(%1 - 1))
#define del_targeted_player(%0,%1)					bs_cl_targets[%0] &= ~(1<<(%1 - 1))
#define player_targets_user(%0,%1)					(bs_cl_targets[%0] & (1<<(%1 - 1)))
#define add_seen_by_player(%0,%1)					bs_cl_seen_by[%0] |= (1<<(%1 - 1))
#define del_seen_by_player(%0,%1)					bs_cl_seen_by[%0] &= ~(1<<(%1 - 1))
#define is_user_seen_by(%0,%1)						(bs_cl_seen_by[%0] & (1<<(%1 - 1)))
#define enable_smooth_between(%0,%1)				bs_cl_smooth[%0] |= (1<<(%1 - 1))
#define disable_smooth_between(%0,%1)				bs_cl_smooth[%0] &= ~(1<<(%1 - 1))
#define can_use_smooth_between(%0,%1)				(bs_cl_smooth[%0] & (1<<(%1 - 1)))


new pcv_on_off
new pcv_ignore_team
new pcv_blockents
new pcv_fov_check
new pcv_tg_check
new pcv_engine_pvs
new pcv_smooth
new pcv_texture

new pcg_on_off
new pcg_ignore
new pcg_blockents
new pcg_fov_check
new pcg_tg_check
new pcg_engine_pvs
new pcg_smooth
new pcg_texture

new thdl

new g_maxplayers

stock spr_bomb
stock beampoint

// These bitsums allow 2048 entities storage. I think that it is enough :P.
new bs_array_transp[64]				// BitSum, This is equal to 64*32 bools (good for quick search)
new bs_array_solid[64]				// BitSum, This is equal to 64*32 bools (good for quick search)

#define add_transparent_ent(%1) 	bs_array_transp[((%1 - 1) / 32)] |= (1<<((%1 - 1) % 32))
#define del_transparent_ent(%1) 	bs_array_transp[((%1 - 1) / 32)] &= ~(1<<((%1 - 1) % 32))
#define  is_transparent_ent(%1)		(bs_array_transp[((%1 - 1) / 32)] & (1<<((%1 - 1) % 32)))
#define add_solid_ent(%1) 			bs_array_solid[((%1 - 1) / 32)] |= (1<<((%1 - 1) % 32))
#define del_solid_ent(%1) 			bs_array_solid[((%1 - 1) / 32)] &= ~(1<<((%1 - 1) % 32))
#define  is_solid_ent(%1)			(bs_array_solid[((%1 - 1) / 32)] & (1<<((%1 - 1) % 32)))

new CFG_FILE[300]
new const CFG_NAME[] = "wb_mapign.cfg"
new bool:g_donttexture = false

public plugin_precache()
{
	spr_bomb = precache_model("sprites/ledglow.spr")
	beampoint = precache_model("sprites/laserbeam.spr")
	
	register_forward(FM_Spawn, "fw_spawn", 1)
}

public fw_spawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	static rendermode, Float:renderamt
	
	rendermode = pev(ent, pev_rendermode)
	pev(ent, pev_renderamt, renderamt)
	
	if (((rendermode == kRenderTransColor || rendermode == kRenderGlow || rendermode == kRenderTransTexture) && renderamt < 255.0) || (rendermode == kRenderTransAdd))
	{
		add_transparent_ent(ent)
		
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("wallblocker_version", VERSION, FCVAR_SPONLY | FCVAR_SERVER)
	register_cvar("wallblocker_author" , AUTHOR , FCVAR_SPONLY | FCVAR_SERVER)
	
	pcv_on_off     = register_cvar("wallblocker_enable",       "1", FCVAR_SPONLY | FCVAR_SERVER)
	pcv_ignore_team = register_cvar("wallblocker_ignore_team",   "1")
	pcv_blockents  = register_cvar("wallblocker_block_ents",   "1")
	pcv_fov_check  = register_cvar("wallblocker_fov_check",    "1")
	pcv_tg_check   = register_cvar("wallblocker_target_check", "1")
	pcv_engine_pvs = register_cvar("wallblocker_engine_check", "1")
	pcv_smooth	   = register_cvar("wallblocker_smooth_check", "1")
	pcv_texture    = register_cvar("wallblocker_textureallow", "1")
	
	register_forward(FM_AddToFullPack, 	"fw_addtofullpack" 	, 0)
	register_forward(FM_PlayerPreThink,	"fw_prethink"	   	, 0)
	register_forward(FM_TraceLine,		"pfw_traceline"		, 1)
	register_forward(FM_SetView, 		"fw_setview")
	
	RegisterHam(Ham_Spawn, "player", "fw_alive_handle", 1)
	RegisterHam(Ham_Killed, "player", "fw_alive_handle", 1)
	
	RegisterHam(Ham_Blocked, "func_wall", "fw_stuck")
	RegisterHam(Ham_Blocked, "func_ladder", "fw_stuck")
	
	register_clcmd("wallblocker", "cmd_version_show")
	
	register_event("CurWeapon", "event_active_weapon", "be")
	
	register_message(get_user_msgid("ClCorpse"), "message_clcorpse")
	
	thdl = create_tr2()
	
	g_maxplayers = get_maxplayers()
	
	for (new i=1;i<=g_maxplayers;i++)
	{
		add_solid_ent(i)
		g_cl_viewent[i] = i
	}
	
	new maxents = global_get(glb_maxEntities)
	
	for (new i=1;i<maxents;i++)
	{
		if (is_transparent_ent(i))
		{
			//set_pev(i, pev_solid, SOLID_BBOX)
		}
	}
	
	get_configsdir(CFG_FILE, charsmax(CFG_FILE))
	format(CFG_FILE, charsmax(CFG_FILE),"%s/%s", CFG_FILE, CFG_NAME)
	
	new mapname[40]
	get_mapname(mapname, charsmax(mapname))
	
	if (!file_exists(CFG_FILE))
	{
		g_donttexture = false
	}
	else
	{
		new pf = fopen(CFG_FILE, "r"), line[40]
		
		while (!feof(pf))
		{
			fgets(pf, line, charsmax(line))
			
			if (line[0] == ';' || line[0] == '/')
				continue
			
			if (equal(line, mapname) && validate_map(mapname))
			{
				g_donttexture = true
				break
			}
		}
		
		fclose(pf)
	}
	
}

public fw_stuck(stuckent, id)
{
	if (is_transparent_ent(stuckent) && 1 <= id <= g_maxplayers)
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_setview(id, attachent)
{
	g_cl_viewent[id] = attachent
	
	return FMRES_IGNORED
}

public message_clcorpse(msg_id, msg_dest, entity)
{
	if (!has_connect_property(get_msg_arg_int(12)))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public plugin_end()
{
	free_tr2(thdl)
}

public client_connect(id)
{
	del_alive_property(id)
	del_connect_property(id)
}

public client_putinserver(id)
{
#if defined ignore_bots
	del_bot_property(id)
#else
	if (is_user_bot(id))
		add_bot_property(id)
	else
		del_bot_property(id)
#endif
	
	add_connect_property(id)
	del_announced(id)
}

public cmd_version_show(id)
{
	client_print(id, print_console, "На этом сервере установлен WallBlocker v%s",VERSION)
}

public client_disconnect(id)
{
	del_bot_property(id)
	del_alive_property(id)
	del_connect_property(id)
	del_announced(id)
}

public event_active_weapon(id)
{
	pcg_ignore 	   = get_pcvar_num(pcv_ignore_team)
	pcg_on_off	   = get_pcvar_num(pcv_on_off)
	pcg_blockents  = get_pcvar_num(pcv_blockents)
	pcg_fov_check  = get_pcvar_num(pcv_fov_check)
	pcg_tg_check   = get_pcvar_num(pcv_tg_check)
	pcg_engine_pvs = get_pcvar_num(pcv_engine_pvs)
	pcg_smooth 	   = get_pcvar_num(pcv_smooth)
	pcg_texture	   = get_pcvar_num(pcv_texture)
	
	if (read_data(1) == 1)
	{
		g_cl_weapon[id] = read_data(2)
		
		if (g_cl_weapon[id] < CSW_P228 || g_cl_weapon[id] > CSW_P90)
		{
			g_cl_weapon[id] = CSW_KNIFE
		}
		
		g_cl_team[id] = _:cs_get_user_team(id)
	}
	
	return PLUGIN_CONTINUE
}

public fw_alive_handle(id)
{
	if (!is_user_alive(id))
	{
		del_alive_property(id)
	}
	else
	{
		if (!has_bot_property(id) && !has_been_announced(id))
		{
			add_announced(id)
			// Please let the cheaters know that they are screwed! Do not erase this from the plugin! 
			ChatColor(id, "^4[Server] ^1На этом сервере установлен ^4WallBlocker v%s ^1",VERSION)
		}
		
		add_alive_property(id)
		reset_plugin_client_status(id)
	}
}

public fw_prethink(id)
{
	if (!pcg_on_off)
		return FMRES_IGNORED
	
	if (!has_connect_property(id))
		return FMRES_IGNORED
	
	if (has_alive_property(id))
	{
		if (pev(id, pev_flags) & FL_DUCKING)
		{
			add_duck_property(id)
		}
		else
		{
			del_duck_property(id)
		}
	}
	
	return FMRES_IGNORED
}
public fw_addtofullpack(es, e, ent, host, flags, player, set)
{
	if (!pcg_on_off)
		return FMRES_IGNORED
	
	if (!has_connect_property(host))
		return FMRES_IGNORED
	
	if (!has_alive_property(host))
		return FMRES_IGNORED
	
	if (has_bot_property(host) || g_cl_team[host] == _:CS_TEAM_SPECTATOR || g_cl_team[host] == _:CS_TEAM_UNASSIGNED)
		return FMRES_IGNORED
	
	if (!player && !pcg_blockents)
	{
		return FMRES_IGNORED
	}
	
	if (!player && pcg_blockents)
	{
		if (!pev_valid(ent))
			return FMRES_IGNORED
		
		if (pev(ent, pev_owner) == host)
			return FMRES_IGNORED
		
		static class_name[10]
		pev(ent, pev_classname, class_name, charsmax(class_name))
		
		if (!equal(class_name, "grenade"))
		{
			if (!equal(class_name, "g_cl_weaponbox"))
			{
				return FMRES_IGNORED
			}
		}
		
		if (pcg_engine_pvs && g_cl_viewent[host] == host)
		{
			if (!engfunc(EngFunc_CheckVisibility, ent, set))
			{
				// the ent cannot be seen so we block the send channel
				forward_return(FMV_CELL, 0)
				return FMRES_SUPERCEDE
			}
		}
		
		static Float:origin[3], Float:end[3], Float:plane_vec[3], Float:normal[3]
		
		if ( g_cl_viewent[host] == host )
			pev(host, pev_origin, origin)
		else
			pev(g_cl_viewent[host], pev_origin, origin)
		
		if (pcg_fov_check)
		{
			pev(host, pev_v_angle, normal)
			angle_vector(normal,ANGLEVECTOR_FORWARD, normal)
			
			pev(ent, pev_origin, end)
			xs_vec_sub(end, origin, plane_vec)
			xs_vec_mul_scalar(plane_vec,  (1.0/xs_vec_len(plane_vec)), plane_vec)
			
			if (xs_vec_dot(plane_vec, normal) < 0)
			{
				forward_return(FMV_CELL, 0)
				return FMRES_SUPERCEDE
			}
			
			if (g_cl_viewent[host] == host)
			{
				pev(host, pev_view_ofs, plane_vec)
				xs_vec_add(plane_vec, origin, origin)
			}
		}
		else
		{
			if (g_cl_viewent[host] == host)
			{
				pev(host, pev_view_ofs, end)
				
				xs_vec_add(end, origin, origin)
			}
			
			pev(ent, pev_origin, end)
		}
		
		if (is_point_almost_visible(origin, end, ent))
			return FMRES_IGNORED
		
#if defined point_test
		return FMRES_IGNORED
#else
		// the player cannot be seen so we block the send channel
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
#endif
	}
	
	if (!has_alive_property(ent))
		return FMRES_IGNORED
	
	if (pcg_ignore && g_cl_team[ent] == g_cl_team[host])
		return FMRES_IGNORED
	
	if (host != ent)
	{
		if (pcg_tg_check)
		{
			if (is_user_seen_by(host, ent))
			{
				del_targeted_player(host, ent)
				del_seen_by_player(host, ent)
				disable_smooth_between(host, ent)
				
				return FMRES_IGNORED
			}
			
			if (player_targets_user(host, ent))
			{
				del_targeted_player(host, ent)
				del_seen_by_player(host, ent)
				disable_smooth_between(host, ent)
				
				return FMRES_IGNORED
			}
		}
		
		if (pcg_engine_pvs && g_cl_viewent[host] == host)
		{
			if (!engfunc(EngFunc_CheckVisibility, ent, set))
			{
				// the ent cannot be seen so we block the send channel
				enable_smooth_between(host, ent)
				
				forward_return(FMV_CELL, 0)
				return FMRES_SUPERCEDE
			}
		}
		
		static Float:origin[3], Float:start[3], Float:end[3], Float:addict[3], Float:plane_vec[3], Float:normal[3], ignore_ent
		
		ignore_ent = host
		
		if (g_cl_viewent[host] == host)
			pev(host, pev_origin, origin)
		else
			pev(g_cl_viewent[host], pev_origin, origin)
		
		if (pcg_fov_check)
		{
			pev(host, pev_v_angle, normal)
			angle_vector(normal, ANGLEVECTOR_FORWARD, normal)
			
			pev(ent, pev_origin, end)
			xs_vec_sub(end, origin, plane_vec)
			xs_vec_mul_scalar(plane_vec,  (1.0 / xs_vec_len(plane_vec)), plane_vec)
			
			if (xs_vec_dot(plane_vec, normal) < 0)
			{
				enable_smooth_between(host, ent)
				
				forward_return(FMV_CELL, 0)
				return FMRES_SUPERCEDE
			}
			
			if (g_cl_viewent[host] == host)
			{
				pev(host, pev_view_ofs, start)
				xs_vec_add(start, origin, start)
			}
			else
			{
				start = origin
			}
			
			if (pcg_smooth && can_use_smooth_between(host, ent))
			{
				pev(host, pev_velocity, origin)
				
				if (!xs_vec_equal(origin, Float:{0.0, 0.0, 0.0}))
				{
					xs_vec_mul_scalar(origin, FRAME_OFFSET_CONSTANT, origin)
					
					xs_vec_add(start, origin, start)
				}
				
				pev(ent, pev_velocity, origin)
				
				if (!xs_vec_equal(origin, Float:{0.0, 0.0, 0.0}))
				{
					xs_vec_mul_scalar(origin, FRAME_OFFSET_CONSTANT, origin)
					
					xs_vec_add(origin, end, origin)
				}
				else
				{
					origin = end
				}
			}
			else
			{
				origin = end
			}
		}
		else
		{
			if (g_cl_viewent[host] == host)
			{
				pev(host, pev_view_ofs, start)
				xs_vec_add(start, origin, start)
			}
			else
			{
				start = origin
			}
			
			pev(ent, pev_origin, end)
			
			if (pcg_smooth && can_use_smooth_between(host, ent))
			{
				pev(host, pev_velocity, origin)
				
				if (!xs_vec_equal(origin, Float:{0.0, 0.0, 0.0}))
				{
					xs_vec_mul_scalar(origin, FRAME_OFFSET_CONSTANT, origin)
					
					xs_vec_add(start, origin, start)
				}
				
				pev(ent, pev_velocity, origin)
				
				if (!xs_vec_equal(origin, Float:{0.0, 0.0, 0.0}))
				{
					xs_vec_mul_scalar(origin, FRAME_OFFSET_CONSTANT, origin)
					
					xs_vec_add(origin, end, origin)
				}
				else
				{
					origin = end
				}
			}
			else
			{
				origin = end
			}
		}
		
		xs_vec_sub(start, origin, normal)
		
		// If origin is visible don't do anything
		if (pcg_texture)
		{
			if (is_point_visible_texture(start, origin, ignore_ent))
			{
				disable_smooth_between(host, ent)
				return FMRES_IGNORED
			}
		}
		else
		{
			if (is_point_visible(start, origin, ignore_ent))
			{
				disable_smooth_between(host, ent)
				return FMRES_IGNORED
			}
		}
		
		pev(ent, pev_view_ofs, end)
		xs_vec_add(end, origin, end)
		
		// If eye origin is visible don't do anything
		if (is_point_visible(start, end, ignore_ent))
		{
			disable_smooth_between(host, ent)
			return FMRES_IGNORED
		}
		
		// Check g_cl_weapon point
		if (weapon_edge_point[g_cl_weapon[ent]] != 0.00)
		{
			pev(ent, pev_v_angle, addict)
			angle_vector(addict, ANGLEVECTOR_FORWARD, addict)
			xs_vec_mul_scalar(addict, weapon_edge_point[g_cl_weapon[ent]], addict)
			xs_vec_add(end, addict, end)
			
			// If g_cl_weapon head is visible don't do anything
			if (is_point_visible(start, end, ignore_ent))
			{
				disable_smooth_between(host, ent)
				return FMRES_IGNORED
			}
		}
		
		// We use this to obtain the plain.
		xs_vec_mul_scalar(normal, 1.0/(xs_vec_len(normal)), normal)
		vector_to_angle(normal, plane_vec)
		angle_vector(plane_vec, ANGLEVECTOR_RIGHT, plane_vec)
		
		if (floatabs(normal[2]) <= ANGLE_COS_HEIGHT_CHECK)
		{
			if (has_duck_property(ent))
			{
				for (new i=0;i<4;i++)
				{
					if (i<2)
					{
						for (new j=0;j<2;j++)
						{
							xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
							addict[2] = vec_add_height_crouch[j]
							xs_vec_add(origin, addict, end)
							
							if (is_point_visible(start, end, ignore_ent))
							{
								disable_smooth_between(host, ent)
								return FMRES_IGNORED
							}
						}
					}
					else
					{
						for (new j=2;j<4;j++)
						{
							xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
							addict[2] = vec_add_height_crouch[j]
							xs_vec_add(origin, addict, end)
							
							if (is_point_visible(start, end, ignore_ent))
							{
								disable_smooth_between(host, ent)
								return FMRES_IGNORED
							}
						}
					}
				}
			}
			else
			{
				for (new i=0;i<4;i++)
				{
					if (i<2)
					{
						for (new j=0;j<2;j++)
						{
							xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
							addict[2] = vec_add_height_standup[j]
							xs_vec_add(origin, addict, end)
							
							if (is_point_visible(start, end, ignore_ent))
							{
								disable_smooth_between(host, ent)
								return FMRES_IGNORED
							}
						}
					}
					else
					{
						for (new j=2;j<4;j++)
						{
							xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
							addict[2] = vec_add_height_standup[j]
							xs_vec_add(origin, addict, end)
							
							if (is_point_visible(start, end, ignore_ent))
							{
								disable_smooth_between(host, ent)
								return FMRES_IGNORED
							}
						}
					}
				}
			}
		}
		else
		{
			if (normal[2] > 0.0)
			{
				normal[2] = 0.0
				xs_vec_mul_scalar(normal, 1/(xs_vec_len(normal)), normal)
				
				if (has_duck_property(ent))
				{
					for (new i=0;i<4;i++)
					{
						if (i<2)
						{
							for (new j=0;j<2;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_crouch[j]
								xs_vec_add(origin, addict, end)
								xs_vec_mul_scalar(normal, (j == 0) ? (-GENERAL_X_Y_SORROUNDING) : (GENERAL_X_Y_SORROUNDING), addict)
								xs_vec_add(end, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
						else
						{
							for (new j=2;j<4;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_crouch[j]
								xs_vec_add(origin, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
					}
				}
				else
				{
					for (new i=0;i<4;i++)
					{
						if (i<2)
						{
							for (new j=0;j<2;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_standup[j]
								xs_vec_add(origin, addict, end)
								xs_vec_mul_scalar(normal, (j == 0) ? (-GENERAL_X_Y_SORROUNDING) : (GENERAL_X_Y_SORROUNDING), addict)
								xs_vec_add(end, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
						else
						{
							for (new j=2;j<4;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_standup[j]
								xs_vec_add(origin, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
					}
				}
			}
			else
			{
				normal[2] = 0.0
				xs_vec_mul_scalar(normal, 1/(xs_vec_len(normal)), normal)
				
				if (has_duck_property(ent))
				{
					for (new i=0;i<4;i++)
					{
						if (i<2)
						{
							for (new j=0;j<2;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_crouch[j]
								xs_vec_add(origin, addict, end)
								xs_vec_mul_scalar(normal, (j == 0) ? GENERAL_X_Y_SORROUNDING : (-GENERAL_X_Y_SORROUNDING), addict)
								xs_vec_add(end, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
						else
						{
							for (new j=2;j<4;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_crouch[j]
								xs_vec_add(origin, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
					}
				}
				else
				{
					for (new i=0;i<4;i++)
					{
						if (i<2)
						{
							for (new j=0;j<2;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_standup[j]
								xs_vec_add(origin, addict, end)
								xs_vec_mul_scalar(normal, (j == 0) ? GENERAL_X_Y_SORROUNDING : (-GENERAL_X_Y_SORROUNDING), addict)
								xs_vec_add(end, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
						else
						{
							for (new j=2;j<4;j++)
							{
								xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
								addict[2] = vec_add_height_standup[j]
								xs_vec_add(origin, addict, end)
								
								if (is_point_visible(start, end, ignore_ent))
								{
									disable_smooth_between(host, ent)
									return FMRES_IGNORED
								}
							}
						}
					}
				}
			}
		}
		
#if defined point_test
		return FMRES_IGNORED
#else
		enable_smooth_between(host, ent)
	
		// the player cannot be seen so we block the send channel
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
#endif
	}
	
	return FMRES_IGNORED
}

public pfw_traceline(const Float:start[3], const Float:end[3], cond, id, tr)
{
	if (!pcg_on_off)
		return FMRES_IGNORED
	
	if (id <= 0 || id > g_maxplayers)
		return FMRES_IGNORED
	
	if (!has_connect_property(id))
		return FMRES_IGNORED
	
	new target = get_tr(TR_pHit)
	
	if (!has_alive_property(id))
	{
		bs_cl_targets[id] = 0
	}
	else if (is_user_alive(target))
	{
		add_targeted_player(id, target)
	}
	
	if (pcg_tg_check)
	{
		if (1 <= target <= g_maxplayers)
			add_seen_by_player(target, id)
		
#if defined target_check
		
		new name[32], bs = see_by[id], string[400]
		new i=0
		
		if (1 <= target[id] <= g_maxplayers)
		{
			get_user_name(target[id], name, charsmax(name))
			client_print(id, print_chat, "SEE: %s", name)
		}
		
		format(string, charsmax(string), "")
		
		while (bs != 0)
		{
			if ( bs & (1<<i) )
			{
				get_user_name((i+1), name, charsmax(name))
				format(string, charsmax(string), "%s%s ", string, name)
				bs &= ~(1<<i)
			}
			
			i++
		}
		
		client_print(id, print_chat, "SEE BY: %s", string)
#endif
	}
	
	return FMRES_IGNORED
}

#if !defined point_test
bool:is_point_visible(const Float:start[3], const Float:point[3], ignore_ent)
{
	engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)

	static Float:fraction
	get_tr2(thdl, TR_flFraction, fraction)
	
	return (fraction == 1.0)
}

bool:is_point_visible_texture(const Float:start[3], const Float:point[3], ignore_ent)
{
	engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
	
	static ent
	ent = get_tr2(thdl, TR_pHit)

	static Float:fraction
	get_tr2(thdl, TR_flFraction, fraction)
	
	if (fraction != 1.0 && ent > g_maxplayers && !g_donttexture)
	{
		if (!is_transparent_ent(ent) && !is_solid_ent(ent))
		{
			static texture_name[2]
			static Float:vec[3]
			xs_vec_sub(point, start, vec)
			xs_vec_mul_scalar(vec, (5000.0 / xs_vec_len(vec)), vec)
			xs_vec_add(start, vec, vec)
			
			engfunc(EngFunc_TraceTexture, ent, start, vec, texture_name, charsmax(texture_name))
			
			if (equal(texture_name, "{"))
			{
				add_transparent_ent(ent)
				
				set_pev(ent, pev_solid, SOLID_BBOX)
				
				static players[32], num, id, Float:origin[3]
				get_players(players, num, "a")
				
				for (new i=0;i<num;i++)
				{
					id = players[i]
					
					if ( pev(id,pev_groundentity) == ent )
					{
						pev(id, pev_origin, origin)
						
						origin[2] += 1.0
						
						set_pev(id, pev_origin, origin)
					}
				}
				
				ignore_ent = ent
				
				engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
				
				get_tr2(thdl, TR_flFraction, fraction)
				
				return (fraction == 1.0)
			}
			else
			{
				add_solid_ent(ent)
				return (fraction == 1.0)
			}
		}
		else
		{
			if (is_solid_ent(ent))
			{
				return (fraction == 1.0)
			}
			else
			{
				ignore_ent = ent
				engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
				get_tr2(thdl, TR_flFraction, fraction)
				return (fraction == 1.0)
			}
		}
	}
	
	return (fraction == 1.0)
}


bool:is_point_almost_visible(const Float:start[3], const Float:point[3], ignore_ent)
{
	engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
	
	static Float:fraction
	get_tr2(thdl, TR_flFraction, fraction)
	
	return (fraction >= 0.9)
}
#else

bool:is_point_visible(const Float:start[3], const Float:point[3], ignore_ent)
{
	bomb_led(point)
	return false
}


bool:is_point_almost_visible(const Float:start[3], const Float:point[3], ignore_ent)
{
	bomb_led(point)
	return false
}
#endif

stock bool:validate_map(mapname[])
{
	if ( is_map_valid(mapname) )
	{
		return true;
	}
	// If the is_map_valid check failed, check the end of the string
	new len = strlen(mapname) - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if (len < 0)
	{
		return false;
	}
	if ( equali(mapname[len], ".bsp") )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname[len] = '^0';
		
		// recheck
		if ( is_map_valid(mapname) )
		{
			return true;
		}
	}
	
	return false;
}

reset_plugin_client_status(id)
{
	bs_cl_seen_by[id] = 0
	bs_cl_targets[id] = 0
	bs_cl_smooth[id] = ~0
}

stock xs_vec_add(const Float:in1[], const Float:in2[], Float:out[])
{
	out[0] = in1[0] + in2[0];
	out[1] = in1[1] + in2[1];
	out[2] = in1[2] + in2[2];
}

stock xs_vec_sub(const Float:in1[], const Float:in2[], Float:out[])
{
	out[0] = in1[0] - in2[0];
	out[1] = in1[1] - in2[1];
	out[2] = in1[2] - in2[2];
}

stock xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}

stock Float:xs_vec_len(const Float:vec[3])
{
	return floatsqroot(vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2]);
}

stock Float:xs_vec_dot(const Float:vec[], const Float:vec2[])
{
	return (vec[0]*vec2[0] + vec[1]*vec2[1] + vec[2]*vec2[2])
}

bool:xs_vec_equal(const Float:vec1[], const Float:vec2[])
{
	return (vec1[0] == vec2[0]) && (vec1[1] == vec2[1]) && (vec1[2] == vec2[2]);
}

stock bomb_led(const Float:point[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GLOWSPRITE)
	engfunc(EngFunc_WriteCoord, point[0])
	engfunc(EngFunc_WriteCoord, point[1])
	engfunc(EngFunc_WriteCoord, point[2])
	write_short(spr_bomb)
	write_byte(1)
	write_byte(3)
	write_byte(255)
	message_end()
}

stock draw_line(const Float:start[3], const Float:end[3])
{
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, Float:{0.0,0.0,0.0}, 0)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(25)
	write_byte(10)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(127)
	write_byte(1)
	message_end()	
}
stock ChatColor(const id, const input[], any:...)
{
    new count = 1, players[32]
    static msg[191]
    vformat(msg, 190, input, 3)
    
    replace_all(msg, 190, "!g", "^4")
    replace_all(msg, 190, "!y", "^1")
    replace_all(msg, 190, "!team", "^3")
    replace_all(msg, 190, "!team2", "^0")
    
    if (id) players[0] = id; else get_players(players, count, "ch")
    {
        for (new i = 0; i < count; i++)
        {
            if (is_user_connected(players[i]))
            {
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                write_byte(players[i]);
                write_string(msg);
                message_end();
            }
        }
    }
} 