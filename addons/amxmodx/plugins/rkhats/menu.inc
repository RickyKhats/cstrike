
public menu_main_build(id) {
	new menu = menu_create( menu_name("Главное меню", id), "menu_main_handle" )
	
	menu_additem( menu, "\yПоставить...", "1" )
	menu_additem( menu, "\yМагазин...", "2" )
	menu_additem( menu, "\yЛичный кабинет", "3" )
	menu_additem( menu, "\yВыбрать оружие", "4" )
	
	menu_setprop( menu, MPROP_BACKNAME, "Назад" ) 
	menu_setprop( menu, MPROP_NEXTNAME, "Вперёд" )
	menu_setprop( menu, MPROP_EXITNAME, "Выход" )
	menu_display( id, menu, 0 )
}

public menu_main_handle( id, menu, item ) {
	if( item < 0 ) {
		return PLUGIN_CONTINUE
	}
	new cmd[ 2 ]
	new access, callback
	menu_item_getinfo( menu, item, access, cmd,2, _, _, callback )
	new choice = str_to_num( cmd )
	
	switch(choice){
		case 1:{
			menu_place_build(id)
		}
		case 2:{
			
		}
		case 3:{
			
		}
		case 4:{
			
		}
	}
	return PLUGIN_HANDLED
}

public menu_place_build(id){
	new menu = menu_create( menu_name("Поставить...", id), "menu_place_handle" )
	
	menu_additem( menu, "\yПушку [5000]", "1" )
	menu_additem( menu, "\yЛазер [800] ", "2" )
	menu_additem( menu, "\yКатушку [5000]", "3" )
	menu_additem( menu, "\yРаздатчик [3000]", "4" )
	
	menu_setprop( menu, MPROP_BACKNAME, "Назад" ) 
	menu_setprop( menu, MPROP_NEXTNAME, "Вперёд" )
	menu_setprop( menu, MPROP_EXITNAME, "Выход" )
	menu_display( id, menu, 0 )
}

public menu_place_handle( id, menu, item ) {
	if( item < 0 ) {
		return PLUGIN_CONTINUE
	}
	new cmd[ 2 ]
	new access, callback
	menu_item_getinfo( menu, item, access, cmd,2, _, _, callback )
	new choice = str_to_num( cmd )
	
	switch(choice){
		case 1:{
			client_cmd(id, "centry_place")
		}
		case 2:{
			client_cmd(id, "+setlaser")
		}
		case 3:{
			client_cmd(id, "tesla_place")
		}
		case 4:{
			client_cmd(id, "dispencer_place")

		}
	}
	
	
	return PLUGIN_HANDLED
}

public menu_name(menu[256], id){
	new user_name[128]
	new menu_name[256]
	get_user_name(id, user_name, charsmax(user_name))
	formatex(menu_name, charsmax(menu_name), "\w[\r%s\w] \w| \rツ \w| \rЗдравствуй, \y%s \w|", menu, user_name)
	return menu_name
}
