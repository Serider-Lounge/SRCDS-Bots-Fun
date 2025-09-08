#include <sourcemod>
#include <tf2_stocks>
#include <multicolors>

#define PLUGIN_NAME     "Bots Fun"
#define PLUGIN_CONFIG   "addons/sourcemod/configs/bots_fun.cfg"

enum
{
    // Built-in
    tf_bot_quota,

    // Plugin
    plugin_enabled,
    bot_ratio,
    rcbot_bot_quota,
    rcbot_bot_quota_mode,
    humans_only,
    rename_bots,
    
    // Constants
    MAXCONVARS
}

ConVar g_ConVars[MAXCONVARS];

int g_iBotQuota;

bool g_bIsAlive[MAXPLAYERS + 1],
     g_bWasBotStatusShown;

char g_strRCBotQuotaMode[16];

Handle g_hConfigTrie = INVALID_HANDLE;

#include <bots_fun/clients>
#include <bots_fun/console>
#include <bots_fun/gamemodes>
#include <bots_fun/navmesh>
#include <bots_fun/rcbot2>