
#define PLUGIN 	"AFK Manager"
#define AUTHOR 	"Leon McVeran"
#define VERSION 	"v1.4d"
#define PDATE 	"19th May 2010"

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>

#define KICK_IMMUNITY 		ADMIN_BAN

#define TASK_AFK_CHECK 		142500
#define FREQ_AFK_CHECK 		5.0
#define MAX_WARN 		3

static const OFFSET_LINUX = 5
new const m_iJoiningState = 125

new bool:g_bSpec[33]
new Float:g_fLastActivity[33]
new g_iAFKCheck
new g_iAFKTime[33]
new g_iDropBomb
new g_iKickTime
new g_iMaxPlayers
new g_iMinPlayers
new g_iTransferTime
new g_iWarn[33]
new g_vOrigin[33][3]

new CVAR_afk_drop_bomb
new CVAR_afk_check
new CVAR_afk_transfer_time
new CVAR_afk_kick_time
new CVAR_afk_kick_players

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("afk_manager.txt")

	register_logevent("event_round_end", 2, "0=World triggered", "1=Round_End")
	register_logevent("event_round_start", 2, "0=World triggered", "1=Round_Start")

	// Support der alten Menüs
	register_clcmd("jointeam", "cmd_jointeam") // new menu
	register_menucmd(register_menuid("Team_Select", 1), 511, "cmd_jointeam") // old menu

	register_clcmd("joinclass", "cmd_joinclass") // new menu
	register_menucmd(register_menuid("Terrorist_Select", 1), 511, "cmd_joinclass") // old menu
	register_menucmd(register_menuid("CT_Select", 1), 511, "cmd_joinclass") // old menu

	CVAR_afk_check = register_cvar("afk_check", "1")
	CVAR_afk_drop_bomb = register_cvar("afk_drop_bomb", "2")
	CVAR_afk_transfer_time = register_cvar("afk_transfer_time", "9")
	CVAR_afk_kick_time = register_cvar("afk_kick_time", "24")
	CVAR_afk_kick_players = register_cvar("afk_kick_players", "16")
}

public plugin_cfg(){
	g_iMaxPlayers = get_maxplayers()
}

public client_connect(id){

	// Spieler als Spectator entmarkieren
	g_bSpec[id] = false

	// Positionen zurücksetzen
	g_vOrigin[id] = {0, 0, 0}

	// Counter zurücksetzen
	g_iAFKTime[id] = 0
	g_iWarn[id] = 0
}

public event_round_start(){

	// AFK Check eingeschaltet
	g_iAFKCheck = get_pcvar_num(CVAR_afk_check)
	if (g_iAFKCheck){

		// Spawn-Positionen aktualisieren
		new iPlayers[32], pNum
		get_players(iPlayers, pNum, "a")
		for (new p = 0; p < pNum; p++){
			get_user_origin(iPlayers[p], g_vOrigin[iPlayers[p]])
		}

		// Loop anlegen falls nicht vorhanden
		if (!task_exists(TASK_AFK_CHECK)) set_task(FREQ_AFK_CHECK, "func_afk_check", TASK_AFK_CHECK, _, _, "b")

		// Kick und Transferzeiten festlegen
		if (get_pcvar_num(CVAR_afk_transfer_time) < 6) set_pcvar_num(CVAR_afk_transfer_time, 6)
		if (get_pcvar_num(CVAR_afk_kick_time) < 6) set_pcvar_num(CVAR_afk_kick_time, 6)
		g_iDropBomb = get_pcvar_num(CVAR_afk_drop_bomb)
		g_iTransferTime = get_pcvar_num(CVAR_afk_transfer_time)
		g_iKickTime = get_pcvar_num(CVAR_afk_kick_time)
		g_iMinPlayers = get_pcvar_num(CVAR_afk_kick_players)
	}

	// AFK Check ausgeschaltet
	else{

		// Loop löschen falls vorhanden
		if (task_exists(TASK_AFK_CHECK)) remove_task(TASK_AFK_CHECK)
	}


}

public cmd_jointeam(id){

	// Spieler als Spectator markieren, sonst kann man den Kick umgehen, indem man keiner Klasse joined.
	g_bSpec[id] = true
}

public cmd_joinclass(id){

	// Spieler als Spectator entmarkieren
	g_bSpec[id] = false

	// Positionen zurücksetzen
	g_vOrigin[id] = {0, 0, 0}

	// Counter zurücksetzen
	g_iAFKTime[id] = 0
	g_iWarn[id] = 0
}

public event_round_end(){

	// Check darf nicht durchgeführt werden
	g_iAFKCheck = 0
}

public func_afk_check(taskid){
	if (g_iAFKCheck){
		new CsTeams:eTeam

		// Alle Spieler überprüfen
		for (new id = 1; id <= g_iMaxPlayers; id++){

			// Bots nicht überprüfen
			if (is_user_bot(id)) continue

			// AFK Funktionen für Specs
			if (is_user_connected(id) && !is_user_hltv(id)){
				eTeam = cs_get_user_team(id)
				if (eTeam == CS_TEAM_SPECTATOR || eTeam == CS_TEAM_UNASSIGNED || g_bSpec[id]){

					// Counter erhöhen
					g_iAFKTime[id]++

					// Spec-Kick
					if (g_iAFKTime[id] >= g_iKickTime - MAX_WARN){
						func_kick_player(id)
					}
				}
			}

			// AFK Funktionen für lebende Spieler
			if (is_user_alive(id)){

				// Positionen überprüfen
				if (g_iAFKCheck == 1){
					new vOrigin[3]
					get_user_origin(id, vOrigin)

					if (g_vOrigin[id][0] != vOrigin[0] || g_vOrigin[id][1] != vOrigin[1]){
						g_vOrigin[id][0] = vOrigin[0]
						g_vOrigin[id][1] = vOrigin[1]
						g_vOrigin[id][2] = vOrigin[2]
						g_iAFKTime[id] = 0
						g_iWarn[id] = 0
					}
					else{
						g_iAFKTime[id]++
					}
				}

				// Letzte Aktivität ermitteln
				else{
					new Float:fLastActivity
					fLastActivity = cs_get_user_lastactivity(id)

					if (fLastActivity != g_fLastActivity[id]){
						g_fLastActivity[id] = fLastActivity
						g_iAFKTime[id] = 0
						g_iWarn[id] = 0
					}
					else{
						g_iAFKTime[id] = floatround((get_gametime() - fLastActivity) / FREQ_AFK_CHECK)
					}
				}

				// Bombentransfer
				if (g_iDropBomb && g_iAFKTime[id] >= 3){
					if (g_iDropBomb == 1){
						if (pev(id, pev_weapons) & (1 << CSW_C4)) engclient_cmd(id, "drop", "weapon_c4")
					}
					else{
						func_transfer_bomb(id)
					}
				}

				// Spec-Switch
				if (g_iAFKTime[id] >= g_iTransferTime - MAX_WARN){
					func_transfer_player(id)
				}
			}
		}
	}
}

public func_transfer_bomb(id){

	// Abbrechen wenn der Spieler keine Bombe hat
	if (!(pev(id, pev_weapons) & (1 << CSW_C4))) return

	// Ermittle alle lebenden Terroristen
	new iPlayers[32], pNum
	get_players(iPlayers, pNum, "ae", "TERRORIST")

	// Abbrechen falls weniger als 2 Terroristen leben
	if (pNum < 2) return

	// Finde den nächsten Terroristen der nicht AFK ist
	new vCarrier[3], vRecipient[3], iRecipient, iDistance, iMinDistance = 999999
	get_user_origin(id, vCarrier)
	for (new p = 0; p < pNum; p++){
		if (g_iAFKTime[iPlayers[p]] < 2){
			get_user_origin(iPlayers[p], vRecipient)
			iDistance = get_distance(vCarrier, vRecipient)
			if (iDistance < iMinDistance){
				iMinDistance = iDistance
				iRecipient = iPlayers[p]
			}
		}
	}

	// Abbrechen wenn alle Terroristen AFK sind
	if (!iRecipient) return

	// Bombe transferieren
	engclient_cmd(id, "drop", "weapon_c4")
	new iC4 = engfunc(EngFunc_FindEntityByString, -1, "classname", "weapon_c4")
	if (pev_valid(iC4)){
		new iBackpack = pev(iC4, pev_owner)
		if (iBackpack > g_iMaxPlayers){
			set_pev(iBackpack, pev_flags, pev(iBackpack, pev_flags) | FL_ONGROUND)
			dllfunc(DLLFunc_Touch, iBackpack, iRecipient)
		}
	}

	// Nachrichten anzeigen
	new szRecipient[32], szMsg[128]
	get_user_name(iRecipient, szRecipient, 31)
	set_hudmessage(255, 255, 0, -1.0, 0.8, 0, 3.0, 6.0, 0.1, 0.2, -1)
	for (new p = 0; p < pNum; p++){
		if (iPlayers[p] != iRecipient){
			format(szMsg, 127, "%L", iPlayers[p], "AFK_TRANSFER_BOMB", szRecipient)
			show_hudmessage(iPlayers[p], "%s", szMsg)
		}
	}
	format(szMsg, 127, "%L", iRecipient, "AFK_GOT_BOMB")
	show_hudmessage(iRecipient, szMsg)
}

public func_transfer_player(id){

	// Warnung anzeigen, wenn nicht schon max-mal verwarnt
	if (g_iWarn[id] < MAX_WARN){
		ChatColor(id, "^4[Server]^1 %L", LANG_PLAYER, "AFK_TRANSFER_WARN", floatround(FREQ_AFK_CHECK) * (MAX_WARN - g_iWarn[id]))
		g_iWarn[id]++
		return
	}

	// Eigentlich sollte die Bombe schon transferiert worden sein
	if (pev(id, pev_weapons) & (1 << CSW_C4)){
		engclient_cmd(id, "drop", "weapon_c4")
	}

	// Spieler tranferieren
	if (is_user_alive(id)) user_silentkill(id)

	// Allow players to choose a team more than one time per round (Thanks ConnorMcLeod)
	// I use this method caused of some issue with deathmatch (Player will be respawned as T or CT)
	set_pdata_int(id, m_iJoiningState, get_pdata_int(id, m_iJoiningState, OFFSET_LINUX) & ~(1<<8), OFFSET_LINUX)
	engclient_cmd(id, "jointeam", "6")
	set_pdata_int(id, m_iJoiningState, get_pdata_int(id, m_iJoiningState, OFFSET_LINUX) & ~(1<<8), OFFSET_LINUX)
	//cs_set_user_team(id, CS_TEAM_SPECTATOR)
	//cs_reset_user_model(id)

	// Positionen zurücksetzen
	g_vOrigin[id] = {0, 0, 0}

	// Counter zurücksetzen
	g_iAFKTime[id] = 0
	g_iWarn[id] = 0

	// Nachrichten anzeigen
	new szName[32]
	get_user_name(id, szName, 31)
	ChatColor(id, "^4[Server]^1 %L", LANG_PLAYER, "AFK_TRANSFER_PLAYER", szName)
}

public func_kick_player(id){

	// Abbrechen wenn es sich um einen Admin handelt
	if (get_user_flags(id) & KICK_IMMUNITY) return

	// Anzahl der  aktuellen Spieler ermitteln
	new iCurrentPlayers = get_playersnum(1)

	// Sind noch Plätze frei?
	if (iCurrentPlayers < g_iMinPlayers || !g_iMinPlayers) return

	// Warnung anzeigen, wenn nicht schon max-mal verwarnt
	if (g_iWarn[id] < MAX_WARN){
		ChatColor(id, "^4[Server]^1 %L", LANG_PLAYER, "AFK_KICK_WARN", floatround(FREQ_AFK_CHECK) * (MAX_WARN - g_iWarn[id]))
		g_iWarn[id]++
		return
	}

	// Spieler kicken
	new szMsg[192]
	format(szMsg, 191, "%L", id, "AFK_KICK_REASON")
	server_cmd("kick #%d ^"%s^"", get_user_userid(id), szMsg)

	// Nachrichten anzeigen
	new szName[32]
	get_user_name(id, szName, 31)
	ChatColor(id, "^4[Server]^1 %L", LANG_PLAYER, "AFK_KICK_PLAYER", szName)
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