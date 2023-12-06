#define MAX_PREFIXES 64
#define MAX_PREFIX_SIZE 24

new prefixes[MAX_PLAYERS][MAX_PREFIXES][MAX_PREFIX_SIZE]

public load_prefixes(id){
	chat_print(id, "start loading prefixes...")
	new file
	new buffer[128], prefix_user_identificator[32], prefix_flag[16], prefix[MAX_PREFIX_SIZE]
	file = fopen("addons/amxmodx/configs/starface/prefixes.ini", "rt")
	new prefixId = 0
	new user_identificator[32]
	while(!feof(file)) {
		fgets(file, buffer, charsmax(buffer))
		trim(buffer)
		chat_print(id, "continue")
		remove_quotes(buffer)
		parse(buffer, prefix_user_identificator, charsmax(prefix_user_identificator), prefix_flag, charsmax(prefix_flag), prefix, charsmax(prefix))
		if(equal(prefix_flag, "nickname")) {
			get_user_name(id, user_identificator, charsmax(user_identificator))
			if(equal(prefix_user_identificator, user_identificator)) {
					prefixes[id][prefixId] = prefix
					prefixId++
					chat_print(id, prefix)
				}
		} else if(equal(prefix_flag, "ip")) {
			get_user_ip(id, user_identificator, charsmax(user_identificator))
			if(equal(prefix_user_identificator, user_identificator)) {
					prefixes[id][prefixId] = prefix
					prefixId++
					chat_print(id, prefix)
				}
		} else if(equal(prefix_flag, "steamid")) {
			get_user_authid(id, user_identificator, 32)
			if(equal(prefix_user_identificator,user_identificator)) { 
					prefixes[id][prefixId] = prefix
					prefixId++
					chat_print(id, prefix)
				}
		} else if(equal(prefix_flag, "flag")) {
			if(get_user_flags(id) == read_flags(prefix_user_identificator))
				{
					prefixes[id][prefixId] = prefix
					prefixId++
					chat_print(id, prefix)
				}
		}
	}
	fclose(file); // Закрываем файл
}

stock prefixes_user_disconnected(id){
	for(int i =0; i< MAX_PREFIXES; i++){
		prefixes[id][i] = ""
	}
}
public ct_message_format(id)
{   
    new name[33];
    get_user_name(id, name, 31)
   
    if(equali(name, "Ник игрока"))
    {
        ct_add_to_msg(CT_MSGPOS_PREFIX, "^x04[твой префикс]")
    }
    if(get_user_flags(id) & ADMIN_RCON)
    {
        ct_add_to_msg(CT_MSGPOS_PREFIX, "^x04[^x01Гл.Админ^x04]")
    }
    else if(get_user_flags(id) & ADMIN_IMMUNITY)
    {
        ct_add_to_msg(CT_MSGPOS_PREFIX, "^x04[^x01Смотритель^x04]")
    }
    else if(get_user_flags(id) & ADMIN_BAN)
    {
        ct_add_to_msg(CT_MSGPOS_PREFIX, "^x04[^x01Админ^x04]")
    }
    else if(get_user_flags(id) & ADMIN_LEVEL_G)
    {
        ct_add_to_msg(CT_MSGPOS_PREFIX, "^x04[^x01Вип^x04]")
    }
    else
    {
        ct_add_to_msg(CT_MSGPOS_PREFIX, "^x01[^x04Игрок^x01]")
    }
}