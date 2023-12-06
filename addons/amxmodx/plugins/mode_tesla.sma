#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < fakemeta_util >
#include < cstrike >
#include < engine >
#include < hamsandwich >
#include < xs >
#include <mycore>

#pragma tabsize 0  

#define PLUGIN_VERSION		"1.0.3"
#define BREAK_COMPUTER		6

#define CHAT_LABEL		"Тесла"
#define ACCESS          ADMIN_PASSWORD
#define ADMIN_ACCESS    ADMIN_LEVEL_D

#define is_valid_player(%1) ( 1 <= %1 <= gMaxPlayers )


new const gDamageSounds[ ][ ] = 
{
	"debris/metal1.wav",
	"debris/metal2.wav",
	"debris/metal3.wav"
};

new const gDispenserClassnameTesla[ ] = "Tesla";

new const gDispenserActive[ ] = "nova/dispenser.wav";
new const gDispenserMdlTesla [ ] = "models/tesla_coil2.mdl";
new const gMetalGibsMdl[ ] = "models/computergibs.mdl";
new const gHealingSprite[ ] = "sprites/nova/tok.spr"
new const gExploSprite[ ] = "sprites/dispexplo.spr";

new g_energi[33]
new gHealingBeam;
new gExploSpr;
new gMetalGibs;
new gMaxPlayers;

new gDispenserCost;
new gCvarDispenserHealth;
new g_iPlayerDispenser[33]
new Float:gDispenserOrigin[ MAX_PLAYERS ][ 3 ];
new gBeamcolor[ MAX_PLAYERS ][ 3 ];

new bool:bDispenserdd[ MAX_PLAYERS ];

new g_cvar_TEsla_destone

public plugin_init() {
	register_plugin( "Tesla", PLUGIN_VERSION, "NOVA" );
	
	register_event( "TextMsg", "EVENT_TextMsg", "a", "2&#Game_C", "2&#Game_w", "2&#Game_will_restart_in" );
	register_logevent( "LOG_RoundEnd", 2, "1=Round_End" );
	
	RegisterHam( Ham_TakeDamage, "func_breakable", "bacon_TakeDamage", 1 );
	RegisterHam( Ham_TakeDamage, "func_breakable", "bacon_TakeDamagePre", 0 );
	
	register_think( gDispenserClassnameTesla, "DispenserThink2" );
	register_clcmd( "tesla_place", "CommandTeslaBuild" );
	register_forward ( FM_TraceLine, "fw_TraceLine_Post", 1 )
	
	gDispenserCost = register_cvar( "tesla_cost", "5000" );
	gCvarDispenserHealth = register_cvar( "tesla_health", "5000" );
	g_cvar_TEsla_destone = register_cvar( "tesla_destone", "5000" );
	
	
	gMaxPlayers = get_maxplayers( );
}

public plugin_natives(){
	register_native("tesla_place", "CommandTeslaBuild")
}

public plugin_cfg() {	
	new configsdir[128]
	get_localinfo("amxx_configsdir", configsdir, 127)
	server_cmd("exec %s/nova/tesla.cfg", configsdir)
	server_exec()
}

public client_connect( id ) {
	bDispenserdd[ id ] = false;
}

public client_disconnected( id ) {
	BreakAllPlayerDispensers(id)
}

public detonate_disp(id) {
	BreakAllPlayerDispensers(id)
	g_iPlayerDispenser[id] = 0
}

public plugin_precache( ) {	
	gHealingBeam = precache_model( gHealingSprite );
	gExploSpr = precache_model( gExploSprite );
	gMetalGibs = precache_model( gMetalGibsMdl );
	
	
	precache_model( gDispenserMdlTesla )
	precache_sound( gDispenserActive );
	
	new i;
	for( i = 0; i < sizeof gDamageSounds; i++ )
	{
		precache_sound( gDamageSounds[ i ] );
	}
}


public fw_TraceLine_Post ( Float:v1[3], Float:v2[3], noMonsters, id ) {
	if ( !is_valid_player ( id ) || is_user_bot ( id ) || !is_user_alive ( id ) )
	return FMRES_IGNORED

	new iHitEnt = get_tr ( TR_pHit )

	if ( iHitEnt <= gMaxPlayers || !pev_valid ( iHitEnt ) )
	return FMRES_IGNORED

	new sClassname[32]
	pev ( iHitEnt, pev_classname, sClassname, charsmax ( sClassname ) )

	if ( !equal ( sClassname, gDispenserClassnameTesla ) )
	return FMRES_IGNORED

	new iTeam = pev ( iHitEnt, pev_iuser4 )

	if ( _:cs_get_user_team ( id ) != iTeam )
	return FMRES_IGNORED

	new iHealth = pev ( iHitEnt, pev_health )

	if ( iHealth <= 0 )
	return FMRES_IGNORED

	new iOwner = pev ( iHitEnt, pev_iuser2 )

	if ( !is_user_connected ( iOwner ) )
	return FMRES_IGNORED

	new sName[33]
	get_user_name ( iOwner, sName, charsmax ( sName ) )
	

	set_dhudmessage ( 255, 255, 255, -1.0, -1.0, 0, 0.0, 0.6, 0.0, 0.0 )
	show_dhudmessage ( id, "Установил: %s^nЗдоровье: %d/%d^nЭнергия: %d", sName, iHealth, get_pcvar_num( gCvarDispenserHealth ), g_energi[iOwner] )	

	return FMRES_IGNORED
}

public bacon_TakeDamagePre( ent, idinflictor, idattacker, Float:damage, damagebits ) {
	new szClassname[ 32 ];
	pev( ent, pev_classname, szClassname, charsmax( szClassname ) );
	
	if( equal( szClassname, gDispenserClassnameTesla ) )
	{
		new iOwner = pev( ent, pev_iuser2 );

		if(!is_user_connected(iOwner) || 1 > iOwner > 32 || !is_user_connected(idattacker) || 1 > idattacker > 32)
			return HAM_SUPERCEDE
		
		if(cs_get_user_team(iOwner)==cs_get_user_team(idattacker) && idattacker != iOwner)
			return HAM_SUPERCEDE
	}
	return HAM_IGNORED	
}

public bacon_TakeDamage( ent, idinflictor, idattacker, Float:damage, damagebits ) {
	new szClassname[ 32 ];
	pev( ent, pev_classname, szClassname, charsmax( szClassname ) );
	
	if( equal( szClassname, gDispenserClassnameTesla ) )
	{
		new iOwner = pev( ent, pev_iuser2 );

		if(!is_user_connected(iOwner) || 1 > iOwner > 32 || !is_user_connected(idattacker) || 1 > idattacker > 32)
			return HAM_SUPERCEDE
		
		if(cs_get_user_team(iOwner)==cs_get_user_team(idattacker) && idattacker != iOwner)
			return HAM_SUPERCEDE
		
		if( pev( ent, pev_health ) <= 0.0 )
		{
			new szName[ 32 ];
			get_user_name( idattacker, szName, charsmax( szName ) );

			new Float:flOrigin[ 3 ];
			pev( ent, pev_origin, flOrigin );
				
			UTIL_BreakModel( flOrigin, gMetalGibs, BREAK_COMPUTER ); 
			set_pev( ent, pev_flags, pev( ent, pev_flags ) | FL_KILLME ); 

			if( idattacker == iOwner )
			{
				notify_player(iOwner, CHAT_LABEL, "Вы уничтожили собственную ^4Катушку!")
			} else {
				notify_player(iOwner, CHAT_LABEL,"^4%s ^3уничтожил вашу ^4Катушку!", szName)
				set_user_money(idattacker, get_user_money(idattacker) + get_pcvar_num(g_cvar_TEsla_destone))
			}

			client_cmd( iOwner, "speak ^"vox/bizwarn computer destroyed^"" );
			bDispenserdd[ iOwner ] = false;
		}
		
		emit_sound( ent, CHAN_STATIC, gDamageSounds[ random_num( 0, charsmax( gDamageSounds ) ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );	
	}
	return HAM_IGNORED
}

public CommandTeslaBuild( id ) {
	
	if( !is_user_alive( id ))
	{
		return PLUGIN_CONTINUE;
	}
	
	if( !( pev( id, pev_flags ) & FL_ONGROUND ) )
	{
		notify_player(id, CHAT_LABEL,"Вы можете построить Катушку только на земле^4!")
		return PLUGIN_HANDLED;
	}

	if( bDispenserdd[ id ] == true )
	{
		notify_player(id, CHAT_LABEL,"Вы уже построили ^4Катушку!")
		return PLUGIN_HANDLED;
	}

	new iMoney = get_user_money( id );
	new iCost = get_pcvar_num( gDispenserCost );
	
	if( iMoney < iCost )
	{
		notify_player(id, CHAT_LABEL,"Не хватает средств для постройки Катушки... ^4Нужно (%d$)", iCost )
		return PLUGIN_HANDLED;
	}

	new Float:playerOrigin[3]
	entity_get_vector(id, EV_VEC_origin, playerOrigin)
	
  	new Float:vNewOrigin[3]
	new Float:vTraceDirection[3]
	new Float:vTraceEnd[3]
	new Float:vTraceResult[3]
	velocity_by_aim(id, 64, vTraceDirection) // get a velocity in the directino player is aiming, with a multiplier of 64...
	vTraceEnd[0] = vTraceDirection[0] + playerOrigin[0] // find the new max end position
	vTraceEnd[1] = vTraceDirection[1] + playerOrigin[1]
	vTraceEnd[2] = vTraceDirection[2] + playerOrigin[2]
	trace_line(id, playerOrigin, vTraceEnd, vTraceResult) // trace, something can be in the way, use hitpoint from vTraceResult as new origin, if nothing's in the way it should be same as vTraceEnd
	vNewOrigin[0] = vTraceResult[0]// just copy the new result position to new origin
	vNewOrigin[1] = vTraceResult[1]// just copy the new result position to new origin
	vNewOrigin[2] = playerOrigin[2] // always build in the same height as player.
	
	if (CreateDispanser(vNewOrigin, id))
	{
		set_user_money(id, get_user_money(id) - iCost)
		g_energi[id] = 10000000000000000
	}
	else
	{
		notify_player(id, CHAT_LABEL,"Здесь не получается установить ^4Катушку!")
	}
	
	return PLUGIN_HANDLED;
	
}


stock bool:CreateDispanser(Float:origin[3], creator)  {
	if (point_contents(origin) != CONTENTS_EMPTY || TraceCheckCollides(origin, 35.0)) 
	{
		return false
	}
	
	origin[2] = origin[2] + 60
	
	new Float:hitPoint[3], Float:originDown[3]
	originDown = origin
	originDown[2] = -5000.0 // dunno the lowest possible height...
	trace_line(0, origin, originDown, hitPoint)
	new Float:baDistanceFromGround = vector_distance(origin, hitPoint)
	
	new Float:difference = 80.0 - baDistanceFromGround
	if (difference < -1 * 80.0 || difference > 80.0) return false
	
	new iEntity = create_entity( "func_breakable" );
	
	
	
	if( !pev_valid( iEntity ) )
		 return false
	
	set_pev( iEntity, pev_classname, gDispenserClassnameTesla );
	engfunc( EngFunc_SetModel, iEntity, gDispenserMdlTesla );
	engfunc( EngFunc_SetSize, iEntity, Float:{ -20.0, -10.0, -50.0 }, Float:{ 20.0, 10.0, -5.0 } );
	set_pev( iEntity, pev_origin, origin );
	set_pev( iEntity, pev_solid, SOLID_SLIDEBOX );
	set_pev( iEntity, pev_movetype, MOVETYPE_FLY );
	set_pev( iEntity, pev_health, float(get_pcvar_num( gCvarDispenserHealth )) );
	set_pev( iEntity, pev_takedamage, 2.0 );
	set_pev( iEntity, pev_iuser2, creator );
	set_pev( iEntity, pev_iuser4, get_user_team(creator) );
	set_pev( iEntity, pev_nextthink, get_gametime( ) + 0.1 );
	engfunc( EngFunc_DropToFloor, iEntity );	
	
	gDispenserOrigin[ creator ][ 0 ] = origin[ 0 ];
	gDispenserOrigin[ creator ][ 1 ] = origin[ 1 ];
	gDispenserOrigin[ creator ][ 2 ] = origin[ 2 ];
	
	bDispenserdd[ creator ] = true;
	
	switch( cs_get_user_team( creator ) )
	{
		case CS_TEAM_T:
		{
			gBeamcolor[ creator ][ 0 ] = 255, gBeamcolor[ creator ][ 1 ] = 0, gBeamcolor[ creator ][ 2 ] = 0; 			
			/* set_rendering( iEntity, kRenderFxGlowShell, gBeamcolor[ creator ][ 0 ], gBeamcolor[ creator ][ 1 ], gBeamcolor[ creator ][ 2 ], kRenderNormal, 3 ); */
		}
		
		case CS_TEAM_CT:
		{
			gBeamcolor[ creator ][ 0 ] = 255, gBeamcolor[ creator ][ 1 ] = 0, gBeamcolor[ creator ][ 2 ] = 0; 	
			/* set_rendering( iEntity, kRenderFxGlowShell, gBeamcolor[ creator ][ 0 ], gBeamcolor[ creator ][ 1 ], gBeamcolor[ creator ][ 2 ], kRenderNormal, 3 ); */
		}
	} 
	
	emit_sound( iEntity, CHAN_STATIC, gDispenserActive, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	
	return true;
}

public DispenserThink2( iEnt ) {
	if( pev_valid( iEnt ) )
	{
		new iOwner = pev( iEnt, pev_iuser2 ), ent
		
		if(g_energi[iOwner] <= 0)
		{
			return PLUGIN_CONTINUE;
		}
	
	
	
		while((ent = find_ent_by_class(ent,"sentry")) != 0)
		{
			if(pev(ent, pev_team) == get_user_team( iOwner ))
			{
				new Float:entorigin[3]
				pev( ent, pev_origin, entorigin )
			
				if(UTIL_IsVisible( ent, iEnt ) && get_distance_f( gDispenserOrigin[ iOwner ], entorigin )  <=  900.0 )
				{
					if(pev(ent, pev_health) < 8000.0)
					{
						set_pev(ent, pev_health, pev(ent, pev_health) + 50.0)
						g_energi[iOwner] = g_energi[iOwner] - 50
					
						new Float:flAngles[ 3 ];
						pev( iEnt, pev_angles, flAngles );
						flAngles[ 1 ] += 1.0;
						set_pev( iEnt, pev_angles, flAngles );
					
						sprite_tokkk(iEnt, ent)
					
					}
				}
			}
		}
		
		while((ent = find_ent_by_class(ent,"NiceDispenserHpArm")) != 0)
		{
			new owner_disp = pev( ent, pev_iuser2 )
			
			if(get_user_team( iOwner ) == get_user_team(owner_disp))
			{
				new Float:entorigin[3]
				pev( ent, pev_origin, entorigin )
				
				if(UTIL_IsVisible( ent, iEnt ) && get_distance_f( gDispenserOrigin[ iOwner ], entorigin )  <=  900.0 )
				{
					if(pev(ent, pev_health) < 2000.0)
					{
						set_pev(ent, pev_health, pev(ent, pev_health) + 50.0)
						g_energi[iOwner] = g_energi[iOwner] - 50
					
						new Float:flAngles[ 3 ];
						pev( iEnt, pev_angles, flAngles );
						flAngles[ 1 ] += 1.0;
						set_pev( iEnt, pev_angles, flAngles );
					
						sprite_tokkk(iEnt, ent)
					}
				}
			}
		}
		
		while((ent = find_ent_by_class(ent,"Laser_Fence")) != 0)
		{		
			if(get_user_team(iOwner) == pev(ent, pev_iuser1))
			{
				new Float:entorigin[3]
				pev( ent, pev_origin, entorigin )
				
				if(UTIL_IsVisible( ent, iEnt ) && get_distance_f( gDispenserOrigin[ iOwner ], entorigin )  <=  900.0 )
				{
					if(pev(ent, pev_health) < 1000.0)
					{
						set_pev(ent, pev_health, pev(ent, pev_health) + 50.0)
						g_energi[iOwner] = g_energi[iOwner] - 50
					
						new Float:flAngles[ 3 ];
						pev( iEnt, pev_angles, flAngles );
						flAngles[ 1 ] += 1.0;
						set_pev( iEnt, pev_angles, flAngles );
					
						sprite_tokkk(iEnt, ent)
					}
				}
			}
		}
		
		while((ent = find_ent_by_class(ent,"NiceDispenserMoney")) != 0)
		{
			new owner_disp = pev( ent, pev_iuser2 )
			
			if(get_user_team(iOwner) == get_user_team(owner_disp))
			{
				new Float:entorigin[3]
				pev( ent, pev_origin, entorigin )
				
				if(UTIL_IsVisible( ent, iEnt ) && get_distance_f( gDispenserOrigin[ iOwner ], entorigin )  <=  900.0 )
				{
					if(pev(ent, pev_health) < 1000.0)
					{
						set_pev(ent, pev_health, pev(ent, pev_health) + 50.0)
						g_energi[iOwner] = g_energi[iOwner] - 50
					
						new Float:flAngles[ 3 ];
						pev( iEnt, pev_angles, flAngles );
						flAngles[ 1 ] += 1.0;
						set_pev( iEnt, pev_angles, flAngles );
					
						sprite_tokkk(iEnt, ent)
					}
				}
			}
		}
		
		if(get_user_team(iOwner) != pev( iEnt, pev_iuser4))
		{
			BreakAllPlayerDispensers(iOwner);
			return PLUGIN_CONTINUE;
		}
		
		if(get_user_team(iOwner) != pev( iEnt, pev_iuser4))
		{
			BreakAllPlayerDispensers(iOwner);
			g_iPlayerDispenser[iOwner] = 0
			return PLUGIN_CONTINUE;
		}
	
		set_pev( iEnt, pev_nextthink, get_gametime( ) + 0.1 );
	}
	return PLUGIN_CONTINUE;
}


public EVENT_TextMsg( ){
	UTIL_DestroyDispensers( );
}

public LOG_RoundEnd( ) {
	UTIL_DestroyDispensers( );
}


/* 		
	~~~~~~~~~~~~~~~~~~~~~~~
		Stocks
	~~~~~~~~~~~~~~~~~~~~~~~
*/


stock UTIL_DestroyDispensers( ) {
	new iEnt = FM_NULLENT;
	
	while( ( iEnt = find_ent_by_class( iEnt, gDispenserClassnameTesla ) ) )
	{
		new iOwner = pev( iEnt, pev_iuser2 );
		
		bDispenserdd[ iOwner ] = false;
		set_pev( iEnt, pev_flags, pev( iEnt, pev_flags ) | FL_KILLME );
	}
}

stock UTIL_BreakModel( Float:flOrigin[ 3 ], model, flags ) {
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0 );
	write_byte( TE_BREAKMODEL ); 
	engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
	write_coord( 16 );
	write_coord( 16 );
	write_coord( 16 );
	write_coord( random_num( -20, 20 ) );
	write_coord( random_num( -20, 20 ) );
	write_coord( 10 );
	write_byte( 10 );
	write_short( model );
	write_byte( 10 );
	write_byte( 9 );
	write_byte( flags );
	message_end( );
	
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0 );
	write_byte(TE_SPRITE)
	engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
	write_short( gExploSpr )
	write_byte( 15 )
	write_byte( 50 )
	message_end()
}  

stock UTIL_BeamEnts( Float:flStart[ 3 ], Float:flEnd[ 3 ], r, g, b, sprite,  width ,  ampl ) {
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flStart );
	write_byte( TE_BEAMPOINTS );
	engfunc( EngFunc_WriteCoord, flStart[ 0 ] );
	engfunc( EngFunc_WriteCoord, flStart[ 1 ] );
	engfunc( EngFunc_WriteCoord, flStart[ 2 ] );
	engfunc( EngFunc_WriteCoord, flEnd[ 0 ] );
	engfunc( EngFunc_WriteCoord, flEnd[ 1 ] );
	engfunc( EngFunc_WriteCoord, flEnd[ 2 ] );
	write_short( sprite );
	write_byte( 5 );
	write_byte( 2 );
	write_byte( 1 );
	write_byte( width );
	write_byte( ampl );
	write_byte( r );
	write_byte( g );
	write_byte( b );
	write_byte( 130 );
	write_byte( 30 ); 
	message_end( );
}
 
stock bool:UTIL_IsVisible( index, entity, ignoremonsters = 0 ) {
	new Float:flStart[ 3 ], Float:flDest[ 3 ];
	pev( index, pev_origin, flStart );
	pev( index, pev_view_ofs, flDest );

	xs_vec_add( flStart, flDest, flStart );
    
	pev( entity, pev_origin, flDest );
	engfunc( EngFunc_TraceLine, flStart, flDest, ignoremonsters, index, 0 );
    
	new Float:flFraction;
	get_tr2( 0, TR_flFraction, flFraction );
	
	if( flFraction == 1.0 || get_tr2( 0, TR_pHit) == entity )
	{
		return true;
	}
    
	return false;
}


public BreakAllPlayerDispensers(id) {
	static ent = -1
	
	while ((ent = find_ent_by_class(ent,  gDispenserClassnameTesla)))  
	{  
		if(pev( ent, pev_iuser2 ) != id)  
			continue  
		
		if(pev_valid(ent)) 
		{
			new Float:flOrigin[ 3 ];
			pev( ent, pev_origin, flOrigin );
			
			UTIL_BreakModel( flOrigin, gMetalGibs, BREAK_COMPUTER ); 
			set_pev( ent, pev_flags, pev( ent, pev_flags ) | FL_KILLME ); 
		}
	}  
	
	bDispenserdd[ id ] = false;
} 


bool:TraceCheckCollides(Float:origin[3], const Float:BOUNDS) {
	new Float:traceEnds[8][3], Float:traceHit[3], hitEnt
	traceEnds[0][0] = origin[0] - BOUNDS
	traceEnds[0][1] = origin[1] - BOUNDS
	traceEnds[0][2] = origin[2] - BOUNDS
	traceEnds[1][0] = origin[0] - BOUNDS
	traceEnds[1][1] = origin[1] - BOUNDS
	traceEnds[1][2] = origin[2] + BOUNDS
	traceEnds[2][0] = origin[0] + BOUNDS
	traceEnds[2][1] = origin[1] - BOUNDS
	traceEnds[2][2] = origin[2] + BOUNDS
	traceEnds[3][0] = origin[0] + BOUNDS
	traceEnds[3][1] = origin[1] - BOUNDS
	traceEnds[3][2] = origin[2] - BOUNDS
	traceEnds[4][0] = origin[0] - BOUNDS
	traceEnds[4][1] = origin[1] + BOUNDS
	traceEnds[4][2] = origin[2] - BOUNDS
	traceEnds[5][0] = origin[0] - BOUNDS
	traceEnds[5][1] = origin[1] + BOUNDS
	traceEnds[5][2] = origin[2] + BOUNDS
	traceEnds[6][0] = origin[0] + BOUNDS
	traceEnds[6][1] = origin[1] + BOUNDS
	traceEnds[6][2] = origin[2] + BOUNDS
	traceEnds[7][0] = origin[0] + BOUNDS
	traceEnds[7][1] = origin[1] + BOUNDS
	traceEnds[7][2] = origin[2] - BOUNDS

	for (new i = 0; i < 8; i++) {
		if (point_contents(traceEnds[i]) != CONTENTS_EMPTY)
			return true

		hitEnt = trace_line(0, origin, traceEnds[i], traceHit)
		if (hitEnt != 0)
			return true
		for (new j = 0; j < 3; j++) {
			if (traceEnds[i][j] != traceHit[j])
				return true
		}
	}

	return false
}


public sprite_tokkk(iEnt, ent) {
	new Float:entorigin[3]
	pev( iEnt, pev_origin, entorigin )
	

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS)
	write_short(ent)
	write_short(iEnt)
	write_short(gHealingBeam) 
	write_byte(1) // 
	write_byte(10) // 
	write_byte(1) // 
	write_byte(30) // 
	write_byte(600) // 
	write_byte(random_num(50, 255)) /
	write_byte(random_num(50, 255)) 
	write_byte(50) // Blue
	write_byte(255) // brightness
	write_byte(30) // scroll speed in 0.1's
	message_end()
/*
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMENTPOINT);
    write_short(ent);             //Индекс entity
    write_coord(entorigin[0]);          //Конечная точка x
    write_coord(entorigin[1]);         //Конечная точка y
    write_coord(entorigin[2]);          //Конечная точка z
    write_short(gHealingBeam);         //Индекс спрайта 
    write_byte(0)                 //Стартовый кадр
    write_byte(10);                 //Скорость анимации
    write_byte(1);                //Врмея существования
    write_byte(30);    //Толщина луча
    write_byte(600);  //Искажение 
    write_byte(random_num(50, 255));    //Цвет красный
    write_byte(random_num(50, 255));        //Цвеи зеленый
    write_byte(50);        //Цвет синий
    write_byte(255);            //Яркость
    write_byte(30);                //...
    message_end();
	*/
}


