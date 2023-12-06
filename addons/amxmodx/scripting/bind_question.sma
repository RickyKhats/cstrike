/* 
Версия 0.2
Автор - TBicTep
91.211.117.148:27058 - cs)Fun Public[47/48] (24/7)
*/

#include <amxmodx>

new g_BindMenu, g_ChatAnonce
new BIND_LANG_TMP[128]
public plugin_init()
{
	register_dictionary("bind_question.txt")
	
	register_plugin("Bind Question","0.3","TBicTep");
	register_clcmd("say /bindhelp", "BindHelp")
	register_clcmd("bindhelp", "BindHelp")
	register_clcmd("bindmenu", "BindMenu")
	register_clcmd("say /bindmenu", "BindMenu")
	
	g_BindMenu = register_cvar( "bind_skip_menu", "10" );
	g_ChatAnonce = register_cvar("bind_chat_anonce","180");
	
	new iChatAnonce = get_pcvar_num( g_ChatAnonce )
	if( iChatAnonce != 0 )
	{
	set_task (float(iChatAnonce), "chat_anonce", 0, "", 0, "b")
	}
}
public client_putinserver(id)
{
	new iSkipMenu = get_pcvar_num( g_BindMenu )
	if( iSkipMenu != 0 )
		set_task( float(iSkipMenu),"BindMenu",id);
}
public BindMenu(id)
{
	if(is_user_connected(id))
	{
		formatex(BIND_LANG_TMP, 127, "%L", id, "MENUTITLE")
		new menu = menu_create(BIND_LANG_TMP,"BindFuncMenu")
		
		formatex(BIND_LANG_TMP, 127, "%L", id, "REPLYYES")
		menu_additem(menu,BIND_LANG_TMP,"1")
		formatex(BIND_LANG_TMP, 127, "%L", id, "REPLYNO")
		menu_additem(menu,BIND_LANG_TMP,"2")
		formatex(BIND_LANG_TMP, 127, "%L", id, "REPLYVIEW")
		menu_additem(menu,BIND_LANG_TMP,"3")
	
		menu_setprop(menu,MPROP_NUMBER_COLOR,"\w")
		menu_setprop(menu,MPROP_EXIT,-1)
		menu_display(id,menu)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
}
public BindFuncMenu(id,menu,item)
{
	if(item==MENU_EXIT)
	{
		return PLUGIN_HANDLED
	}
	
	new data[6],iName[64],access,callback
	menu_item_getinfo(menu,item,access,data,charsmax(data),iName,charsmax(iName),callback)
	
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			new File=fopen("/addons/amxmodx/configs/bind_file.txt","r");
			if (File)
			{
				new Text[512];
				new Bindkey[32];
				new Command[32];
		
				while (!feof(File))
				{
					fgets(File,Text,sizeof(Text)-1);
			
					trim(Text);
			
					// comment
					if (Text[0]==';') 
					{
						continue;
					}
					Bindkey[0]=0;
					Command[0]=0;			
			
					// not enough parameters
					if (parse(Text,Bindkey,sizeof(Bindkey)-1,Command,sizeof(Command)-1) < 2)
					{
						continue;
					}
					client_cmd(id,"bind ^"%s^" ^"%s^"",Bindkey, Command);
				}
				ChatColor(id, "^4[Server] ^1Кнопки привязаны")
				fclose(File);
				return PLUGIN_HANDLED
			}
			return PLUGIN_HANDLED
		}
		case 2:
		{
			return PLUGIN_HANDLED
		}
		case 3:
		{
			client_cmd(id,"say /bindhelp");
		}
	}
	return PLUGIN_HANDLED
}
public BindHelp(id)
{
	new motd[2048], len;
	len = formatex(motd,2047,"<html><meta charset=UTF-8><style>body{background:#F2F2F2;font-family:Arial}th{background:#175D8B;color:#FFF;padding:7px;text-align:left}td{padding:3px;border-bottom:1px #BFBDBD solid}table{color:#153B7C;background:#F4F4F4;font-size:11px;border:1px solid #BFBDBD}h2,h3{color:#153B7C}#c{background:#ECECEC}img{height:8px;background:#54D143;margin:0 3px}#r{height:8px;background:#C80B0F}#clr{background:none;color:#175D8B;font-size:20px;border:0}</style>");
	len += formatex(motd[len],2047-len,"<body><table width=80%% border=0 align=center cellpadding=0 cellspacing=1>");
	len += formatex(motd[len],2047-len,"<tr><th>%L<th>",id,"BINDKEY");
	len += formatex(motd[len],2047-len,"%L<th>",id,"BINDCOMM");
	len += formatex(motd[len],2047-len,"%L</tr>",id,"DESCRIPTION");
	
	new File=fopen("/addons/amxmodx/configs/bind_file.txt","r");
	
	if (File)
	{
		new Text[512];
		new Bindkey[32];
		new Command[32];
		new Description[120];
		
		while (!feof(File))
		{
			fgets(File,Text,sizeof(Text)-1);
			
			trim(Text);
			
			// comment
			if (Text[0]==';') 
			{
				continue;
			}
			Bindkey[0]=0;
			Command[0]=0;			
			Description[0]=0;			
			
			// not enough parameters
			if (parse(Text,Bindkey,sizeof(Bindkey)-1,Command,sizeof(Command)-1,Description,sizeof(Description)-1) < 2)
			{
				continue;
			}
			
			len += formatex(motd[len],2047-len,"<tr><td>%s<td>%s<td>%s&nbsp;</tr>", Bindkey, Command, Description);
		}
		
		fclose(File);
	}
	len += formatex(motd[len],2047-len,"</table></body></html>");
	show_motd(id ,motd,"bind key");
}
public chat_anonce (id)
{
	formatex(BIND_LANG_TMP, 127, "%L", id, "BINDANONCE")
	client_print(0,print_chat,"%s", BIND_LANG_TMP)
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