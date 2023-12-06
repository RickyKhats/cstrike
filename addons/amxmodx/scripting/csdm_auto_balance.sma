#include < amxmodx >
#include < cstrike >
// #include < csdm >
#include <hamsandwich>

#define BALANCE_IMMUNITY ADMIN_IMMUNITY

/*
	csdm_auto_balance
		- 0: Disabled
		- 1: Enabled
		- 2: Enabled, obey immunity
*/

new bool:g_bConnected[ 33 ], bool:g_bImmunity[ 33 ], CsTeams:g_iNewTeam[ 33 ];
new g_pCvar, g_iMaxPlayers, g_iMsgScreenFade, g_iPlayers//, g_iMsgSayText

public plugin_init( ) {
	register_plugin( "CSDM Auto Balance", "1.0", "xPaw" );
	
	g_pCvar = register_cvar( "csdm_auto_balance", "2" );
	
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
	// g_iMsgSayText    = get_user_msgid( "SayText" );
	g_iMaxPlayers    = get_maxplayers( );
}

public client_authorized( id )
	g_bImmunity[ id ] = bool:( get_user_flags( id ) & BALANCE_IMMUNITY );

public client_putinserver( id ) {
	g_bConnected[ id ] = true; // bool:!is_user_bot( id );
	g_iPlayers++;
}

public client_disconnect( id ) {
	g_iNewTeam[ id ]   = CS_TEAM_UNASSIGNED;
	g_bImmunity[ id ]  = false;
	g_bConnected[ id ] = false;
	g_iPlayers--;
}

public csdm_PostDeath( iKiller, id, bHeadShot, const szWeapon[ ] ) {
	if( g_iPlayers < 4 || iKiller == id || !g_bConnected[ id ] )
		return;
	
	set_task(0.3, "transfer_task", id)
}

public transfer_task(id)
{
	new iCvar = get_pcvar_num( g_pCvar );
	
	if( iCvar <= 0 || iCvar == 2 && g_bImmunity[ id ] )
	return;
	
	new iPlayers[ 2 ];
	
	for( new i = 1; i <= g_iMaxPlayers; i++ ) {
		if( !g_bConnected[ i ] )
		continue;
		
		switch( cs_get_user_team( i ) ) {
			case CS_TEAM_T: iPlayers[ 0 ]++;
			case CS_TEAM_CT: iPlayers[ 1 ]++;
		}
	}
	
	new CsTeams:iCheck, iDifference = iPlayers[ 1 ] - iPlayers[ 0 ];
	
	if( iDifference > 0 )
	iCheck = CS_TEAM_T;
	else if( iDifference < 0 )
	iCheck = CS_TEAM_CT;
	else
	return;
	
	if(!is_user_connected(id)) return;
	if( abs( iDifference ) < 2 || cs_get_user_team( id ) == iCheck )
	return;
	
	cs_set_user_team( id, iCheck );
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	g_iNewTeam[ id ] = iCheck;
	ExecuteHamB( Ham_CS_RoundRespawn, id );
}
public csdm_PostSpawn( id, bool:bFake ) {
	new CsTeams:iNewTeam = g_iNewTeam[ id ];
	
	if( iNewTeam > CS_TEAM_UNASSIGNED ) {
		g_iNewTeam[ id ] = CS_TEAM_UNASSIGNED;
		
		set_hudmessage( 0, 127, 255, 0.42, 0.53, 2, 6.0, 4.0, 0.1, 0.2, -1 );
		show_hudmessage( id, "Вы были перемещены за команду %s!", iNewTeam == CS_TEAM_T ? "Террористов" : "Контр-Террористов" );
		
		UTIL_ScreenFade( id, iNewTeam == CS_TEAM_T ? 175 : 0, 0, iNewTeam == CS_TEAM_CT ? 175 : 0 );
	}
}

/* UTIL_GreenPrintAll( const iSender, const Message[ ], any:... ) {
	new szMessage[ 192 ];
	vformat( szMessage, 191, Message, 3 );
	
	message_begin( MSG_BROADCAST, g_iMsgSayText );
	write_byte( iSender );
	write_string( szMessage );
	message_end( );
} */

UTIL_ScreenFade( const id, const iRed, const iGreen, const iBlue ) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, id );
	write_short( 2000 );
	write_short( 2000 );
	write_short( 0 );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( 175 );
	message_end( );
}