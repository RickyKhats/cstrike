#include <amxmodx>
#include <fun>

#define PLUGIN_VERSION "1.0c"

new health_add
new health_hs_add
new health_max

new nKiller
new nKiller_hp
new nHp_add
new nHp_max

public plugin_init()
{
   register_plugin("Vampire", PLUGIN_VERSION, "Shalfey")

   health_add = register_cvar("amx_vampire_hp", "20")
   health_hs_add = register_cvar("amx_vampire_hp_hs", "40")
   health_max = register_cvar("amx_vampire_max_hp", "250")

   register_event("DeathMsg", "hook_death", "a", "1>0") 	
}

public hook_death()
{
   // Killer id
   nKiller = read_data(1)

   if ( (read_data(3) == 1) && (read_data(5) == 0) )
   {
      nHp_add = get_pcvar_num (health_hs_add)
   }
   else
      nHp_add = get_pcvar_num (health_add)

   nHp_max = get_pcvar_num (health_max)

   // Updating Killer HP
   nKiller_hp = get_user_health(nKiller)
   nKiller_hp += nHp_add

   // Maximum HP check
   if (nKiller_hp > nHp_max) nKiller_hp = nHp_max

   set_user_health(nKiller, nKiller_hp)

   // Screen fading
   message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, nKiller)
   write_short(1<<10)
   write_short(1<<10)
   write_short(0x0000)
   write_byte(0)
   write_byte(0)
   write_byte(200)
   write_byte(75)
   message_end()
   
} 
