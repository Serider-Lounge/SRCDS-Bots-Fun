#include <sourcemod>
#include <tf2_stocks>
#include <multicolors>

#define PLUGIN_NAME     "Bots Fun"
#define PLUGIN_CONFIG   "addons/sourcemod/configs/bots_fun.cfg"

ConVar g_ConVarPluginEnabled,
       g_ConVarBotRatio,
       g_ConVarRCBotQuota,
       g_ConVarRCBotQuotaMode,
       g_ConVarTFBotQuota,
       g_ConVarHumansOnly,
       g_ConVarRenameBots,
       rcbot_bot_quota_interval;

int g_iBotQuota;

bool g_bIsAlive[MAXPLAYERS + 1];

char g_strRCBotQuotaMode[16];

Handle g_hConfigTrie = INVALID_HANDLE;

/*
enum FlagEvent
{
    TF_FLAGEVENT_PICKUP = 0,
    TF_FLAGEVENT_CAPTURE,
    TF_FLAGEVENT_DEFEND,
    TF_FLAGEVENT_DROPPED
};
*/

#include <bots_fun/clients>
#include <bots_fun/console>
#include <bots_fun/gamemodes>
#include <bots_fun/navmesh>
#include <bots_fun/rcbot2>