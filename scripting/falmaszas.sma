#include <amxmodx>
#include <fun>
#include <fakemeta_util>

#define PLUGIN "WALLCLIMB"
#define VERSION "1.0"
#define AUTHOR "s1mpla"

#define STR_T           33

new bool:g_hasWallClimb[33]
new Float:g_wallorigin[32][3]

//*ColorChat Inc*//
enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	new message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	new team, ColorChange, index, MSG_Type;
	
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	static bool:saytext_used;
	static get_user_msgid_saytext;
	if(!saytext_used)
	{
		get_user_msgid_saytext = get_user_msgid("SayText");
		saytext_used = true;
	}
	message_begin(type, get_user_msgid_saytext, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	static bool:teaminfo_used;
	static get_user_msgid_teaminfo;
	if(!teaminfo_used)
	{
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
		teaminfo_used = true;
	}
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
			return i;
	}

	return -1;
}
//**PLUGIN**//
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_Touch, 		"fwd_touch");
	register_forward(FM_PlayerPreThink, 	"fwd_playerprethink");
	register_cvar("wallclimb_cost", "10");
	register_clcmd("say /bwc", "buy_wallclimb");	
	register_event("DeathMsg", "death", "a");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	set_task(300.0, "hirdetes")
}	

public client_disconnected(id)
{
    g_hasWallClimb[id] = false
}

public death()
{
    g_hasWallClimb[read_data(2)] = false
}

public event_round_start()
{
    for (new i = 1; i <= 32; i++)
        g_hasWallClimb[i] = false
}

public fwd_touch(id, world)
{
	if(!is_user_alive(id) || !g_hasWallClimb[id] || !pev_valid(id))
		return FMRES_IGNORED

	new player = STR_T
	if (!player)
		return FMRES_IGNORED
		
	new classname[STR_T]
	pev(world, pev_classname, classname, (STR_T))
	
	if(equal(classname, "worldspawn") || equal(classname, "func_wall") || equal(classname, "func_breakable"))
		pev(id, pev_origin, g_wallorigin[id])

	return FMRES_IGNORED
}

public wallclimb(id, button)
{
    static Float:origin[3]
    pev(id, pev_origin, origin)

    if (get_distance_f(origin, g_wallorigin[id]) > 25.0)
        return FMRES_IGNORED

    if (fm_get_entity_flags(id) & FL_ONGROUND)
    {
        if (!g_hasWallClimb[id])
            return FMRES_IGNORED 
    }
        if (button & IN_FORWARD)
        {
	static Float:velocity[3]
	velocity_by_aim(id, 240, velocity)
	fm_set_user_velocity(id, velocity)
	}
	else if (button & IN_BACK)
	{
	static Float:velocity[3]
	velocity_by_aim(id, -240, velocity)
	fm_set_user_velocity(id, velocity)
	}
	else if (button & IN_MOVELEFT)
	{
	static Float:velocity[3]
	velocity_by_aim(id, 240, velocity)
	fm_set_user_velocity(id, velocity)
	}
	else if (button & IN_MOVERIGHT)
	{
	static Float:velocity[3]
	velocity_by_aim(id, -240, velocity)
	fm_set_user_velocity(id, velocity)
	}
	return FMRES_IGNORED
}
	

public fwd_playerprethink(id) 
{
	if(!g_hasWallClimb[id]) 
		return FMRES_IGNORED
		
	
	new button = fm_get_user_button(id)
	
	if((button & IN_USE)) //
	wallclimb(id, button)

	return FMRES_IGNORED
}
public  buy_wallclimb(id)
{     
	if (!is_user_alive(id)) {
	ColorChat(id, GREEN, "^3[^4WallClimb^3]^1Nem vagy életben, így nem veheted meg a ^3WallClimb ^1képességet.")
	return;
	}
	if (g_hasWallClimb[id]) {
	ColorChat(id, GREEN, "sad")
	return;
	}
	new koltseg = get_cvar_num("wallclimb_cost")
	new Health = get_user_health (id);
	if(Health >= koltseg)
	{
		set_user_health(id,Health-koltseg)
		g_hasWallClimb[id] = true
		ColorChat(id, GREEN, "^3[^4WallClimb^3]^1Sikeresen megvetted a ^3WallClimb ^1képességet, most már tudsz a falon mászni")
		ColorChat(id, GREEN, "^3[^4WallClimb^3]^1Használathoz nyomd meg a ^3használ ^1gombot miközben neki ^3ugrasz ^1a falnak.")

	}
	else
	{
		ColorChat(id, GREEN, "^3[^4WallClimb^3]^1Nincs elég ^3HP-d, ^1hogy megvedd:^3WallClimb")
	}
} 
public hirdetes(id)
{
	ColorChat(id, GREEN, "^3[^4WallClimb^3]^1WallClimb képesség vásárlásához használd a ^4/bwc ^1parancsot.")
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
