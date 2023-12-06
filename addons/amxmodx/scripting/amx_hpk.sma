/* AMX Mod X скрипт. 
*
*================================
* Название:  HPK
* Версия перевода: 1.0.0
* Автор перевода: MastaMan
* Источник: amx-server.blogspot.com
*================================
*
Команды:
amx_hpk <макс пинг> <кол-во проверок> <время между проверками> <время перед проверкой>

Переменные:
amx_hpk_ping - Максимальный пинг перед тем, как кто то будет кикнут. По умолчанию 200.
amx_hpk_check - Интервал в секундах, для проверки пинга. По умолчанию 12 секунд.
amx_hpk_tests - Количество проверок, перед тем как игрок с большим пингом будет кикнут. По умолчанию 5.
amx_hpk_delay - Время задержки, после подключения игрока на сервер для проверки пинга. По умолчанию 60 секунд.
amx_hpk_immunity - ВКЛ/ВЫКЛ иммунитет 
*****************************************************************************
*/ 

#include <amxmodx> 
#include <amxmisc>

new const PLUGIN[]  = "High Ping Kicker"
new const VERSION[] = "1.0"
new const AUTHOR[]  = "Shadow/Bo0m!"

// Feel free to change this flag
#define HPK_IMMUNE ADMIN_IMMUNITY

// PCvars
new hpk_ping, hpk_check, hpk_tests, hpk_delay, hpk_immunity

new g_Ping[33]
new g_Samples[33]

public plugin_init() {

	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_concmd("amx_hpk","cmdHpk",ADMIN_CVAR,"- configures high ping kicker")

	hpk_ping = register_cvar("amx_hpk_ping","120")
	hpk_check = register_cvar("amx_hpk_check","10")
	hpk_tests = register_cvar("amx_hpk_tests","3")
	hpk_delay = register_cvar("amx_hpk_delay","30")
	hpk_immunity = register_cvar("amx_hpk_immunity","1")

	if (get_pcvar_num(hpk_check) < 5) set_pcvar_num(hpk_check,5)
	if (get_pcvar_num(hpk_tests) < 3) set_pcvar_num(hpk_tests,3)
}

public client_disconnect(id) 
	remove_task(id)

public client_putinserver(id) {    
	g_Ping[id] = 0 
	g_Samples[id] = 0

	if ( !is_user_bot(id) ) 
	{
		new param[1]
		param[0] = id 
		set_task( 15.0 , "showWarn" , id , param , 1 )
    
		if (get_pcvar_num(hpk_delay) != 0) {
			set_task( float(get_pcvar_num(hpk_delay)), "taskSetting", id, param , 1)
		}
		else {	    
			set_task( float(get_pcvar_num(hpk_check)) , "checkPing" , id , param , 1 , "b" )
		}
	}
}

public showWarn(id)
	ChatColor(id, "^4[Server]^1 Игроки с пингом больше чем^4 %d^1, будут кикнуты!", get_cvar_num( "amx_hpk_ping" ) )

public taskSetting(param[]) {
	new name[32]
	get_user_name(param[0],name,31)
	set_task( float(get_pcvar_num(hpk_check)) , "checkPing" , param[0] , param , 1 , "b" )
}

kickPlayer(id) { 
	new name[32],authid[36]
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)
	ChatColor(id, "^4[Server]^1 Игрок^4 %s^1 кикнут из за высокого пинга",name)
	server_cmd("kick #%d ^"Извините, но ваш пинг слишком высокий, повторите попытку позже...^"",get_user_userid(id))
	log_amx("^"%s<%d><%s>^" кикнут из за высокого пинга (Средний пинг ^"%d^")", name,get_user_userid(id),authid,(g_Ping[id] / g_Samples[id]))
}

public checkPing(param[]) { 

	if (get_pcvar_num(hpk_tests) < 3)
		set_pcvar_num(hpk_tests,3)

	new id = param[ 0 ] 

	if ( get_user_flags(id) & HPK_IMMUNE && get_pcvar_num(hpk_immunity) == 1 ) {
		remove_task(id)
		ChatColor(id,  "^4[Server]^1 Проверка пинга отключена из-за иммунитета...")
		return PLUGIN_CONTINUE
	}

	new ping, loss

	get_user_ping(id,ping,loss) 

	g_Ping[ id ] += ping
	++g_Samples[ id ]

	if ( (g_Samples[ id ] > get_pcvar_num(hpk_tests)) && (g_Ping[id] / g_Samples[id] > get_pcvar_num(hpk_ping))  )    
		kickPlayer(id)

	return PLUGIN_CONTINUE
}

  
public cmdHpk(id,level,cid) {
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	if (read_argc() < 6) {
		ChatColor(id, "Использование: amx_hpk <макс пинг> <кол-во проверок> <время между проверками> <время перед проверкой> <1 для включения иммунитета|0 для отключения")
		ChatColor(id, "Текущие настройки:")
		console_print(id,"Макс. пинг: %d | Проверок пинга: %d | Частота проверок: %d | Начальная задерка: %d | Иммунитет: %d",get_pcvar_num(hpk_ping),get_pcvar_num(hpk_tests),get_pcvar_num(hpk_check),get_pcvar_num(hpk_delay),get_pcvar_num(hpk_immunity))
		return PLUGIN_HANDLED
	}

	new name[32], authid[36]
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	new ping_arg[5], check_arg[5], tests_arg[5], delay_arg[5], immune_arg[5]
	read_argv(1,ping_arg,4)
	read_argv(2,tests_arg,4)
	read_argv(3,check_arg,4)
	read_argv(4,delay_arg,4)
	read_argv(5,immune_arg,4)
  
	new ping = str_to_num(ping_arg)
	new tests = str_to_num(tests_arg)
	new check = str_to_num(check_arg)
	new delay = str_to_num(delay_arg)
	new immune = str_to_num(immune_arg)

	if ( check < 5 ) check = 5
	if ( tests < 3 ) tests = 3

	set_pcvar_num(hpk_ping,ping)
	set_pcvar_num(hpk_tests,tests)
	set_pcvar_num(hpk_check,check)
	set_pcvar_num(hpk_delay,delay)
	set_pcvar_num(hpk_immunity,immune)

	console_print(id,"Следующие параметры для НРК были установлены:")
	console_print(id,"Макс. пинг: %d | Проверок пинга: %d | Частота проверок: %d | Начальная задержка: %d | Иммунитет: %d",get_pcvar_num(hpk_ping),get_pcvar_num(hpk_tests),get_pcvar_num(hpk_check),get_pcvar_num(hpk_delay),get_pcvar_num(hpk_immunity))
	log_amx("^"%s<%d><%s>^" применил параметры - Макс. пинг: %d | Проверок пинга: %d | Частота проверок: %d | Начальная задержка: %d | Иммунитет: %d", name,get_user_userid(id),authid,get_pcvar_num(hpk_ping),get_pcvar_num(hpk_tests),get_pcvar_num(hpk_check),get_pcvar_num(hpk_delay),get_pcvar_num(hpk_immunity))

	return PLUGIN_HANDLED    
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
