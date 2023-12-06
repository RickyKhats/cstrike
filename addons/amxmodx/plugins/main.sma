#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
#include <mycore>

#include "rkhats/defines"
#include "rkhats/natives"
#include "rkhats/cvars"
#include "rkhats/modules"


public plugin_init() {
	register_plugin("Scarface CGCSDM Mode System", "1.0", "Ricky_Khats")
	
	register_concmd("nightvision", "menu_main_build", ADMIN_ALL, "Open Main Menu")
	register_concmd("prefix", "load_prefixes", ADMIN_ALL, "Open Main Menu")
	
	amx_gamename = register_cvar("amx_gamename", "Free Vip")
	register_forward(FM_GetGameDescription, "GameDesc")
	register_event("CurWeapon", "event_weapon_changed", "be", "1=1")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
}

public GameDesc(){ 
	static gamename[32]
	get_pcvar_string(amx_gamename, gamename, 31)
	forward_return(FMV_STRING, gamename)
	return FMRES_SUPERCEDE
}

public plugin_precache() {
	
}

public client_authorized( id ) {
	
}
public client_disconnected( id ) {
	
}

public event_round_start( id ) {
	
}
public event_weapon_changed( id ) {
	
}