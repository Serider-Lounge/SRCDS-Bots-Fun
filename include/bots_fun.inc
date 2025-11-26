#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#include <multicolors>

#define PLUGIN_NAME     "Bots Fun"
#define PLUGIN_CONFIG   "addons/sourcemod/configs/bots_fun.cfg"

enum
{
    // External
    tf_bot_quota,
    navbot_bot_quota,

    // Plugin
    plugin_enabled,
    bot_ratio,
    rcbot_bot_quota,
    rcbot_bot_quota_mode,
    humans_only,
    rename_bots,
    
    MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];
char g_RCBotQuotaMode[16];
Handle g_hConfigTrie;

stock int GetAliveHumansCount()
{
    int count;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i))
            continue;

        if(IsFakeClient(i) || !IsPlayerAlive(i))
            continue;
        
        count++;
    }

    return count - 1;
}

#include <bots_fun/gamemodes>
#include <bots_fun/navmesh>
#undef REQUIRE_EXTENSIONS
#include <bots_fun/rcbot2>