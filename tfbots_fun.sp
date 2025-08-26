#undef REQUIRE_EXTENSIONS
#include <rcbot2>
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <serider/navmesh>

#define PREFIX  "[TFBots Fun]"
#define PREFIX_DEBUG "[TFBots Fun | DEBUG]"

#define VSCRIPT_VSH "vssaxtonhale/vsh"
#define VSCRIPT_ZI  "infection/infection"

ConVar g_TFBotRatio,
       rcbot_bot_quota_interval,
       tf_bot_quota;

int TFBotQuota;

public void OnPluginStart()
{
    rcbot_bot_quota_interval = FindConVar("rcbot_bot_quota_interval");
    tf_bot_quota = FindConVar("tf_bot_quota");

    g_TFBotRatio = CreateConVar("sm_tf_bot_ratio", "0.25", "", FCVAR_REPLICATED, true, 0.00, true, 1.00);
    HookConVarChange(g_TFBotRatio, OnConVarChanged);

    AutoExecConfig(true, "tfbots_fun");

    RegConsoleCmd("sm_nav_info", Command_NavInfo, "Retrieve NavMesh/RCBot2 information.");
}

public void OnConfigsExecuted()
{
    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    if (RCBot2_IsWaypointAvailable())
    {
        SetConVarInt(rcbot_bot_quota_interval, 1);
        SetConVarInt(tf_bot_quota, 0);

        PrintToServer("%s RCBot2 waypoints detected, adding RCBot clients...", PREFIX_DEBUG);
        PrintToServer("%s rcbot_bot_quota_interval: %d.", PREFIX_DEBUG, rcbot_bot_quota_interval.IntValue);
        PrintToServer("%s /!\\ WARNING /!\\: Make sure to comment out 'rcbot_bot_quota_interval' in 'addons/rcbot2/config/config.ini'!.", PREFIX_DEBUG);
    }
    else if (NavMesh_IsLoaded() && !isGameMode("mann_vs_machine"))
    {
        TFBotQuota = RoundFloat(g_TFBotRatio.FloatValue * GetMaxHumanPlayers());
        int TFBotOffenseMustPushTime_Backup = GetConVarInt(FindConVar("tf_bot_offense_must_push_time"));

        SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(tf_bot_quota, TFBotQuota);
        SetConVarInt(FindConVar("tf_bot_offense_must_push_time"),
                    (isVScript(VSCRIPT_VSH) ||
                     isVScript(VSCRIPT_ZI) ||
                     isGameMode("robot_destruction")) ? 0 : TFBotOffenseMustPushTime_Backup > 0 ? TFBotOffenseMustPushTime_Backup : 120);

        KickRCBots();

        PrintToServer("%s Valve Navigation Meshes detected, adding TFBot clients...", PREFIX_DEBUG, TFBotQuota);
        PrintToServer("%s tf_bot_quota: %d.", PREFIX_DEBUG, TFBotQuota);
    }
    else
    {
        SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(tf_bot_quota, 0);

        KickRCBots();

        PrintToServer("%s Bots are unsupported on this map.", PREFIX_DEBUG);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
    PrintToServer("%s rcbot_bot_quota_interval: %d.", PREFIX_DEBUG, rcbot_bot_quota_interval.IntValue);
}

public Action Command_NavInfo(int client, int args)
{
    ReplyToCommand(client, "%s\n- Type: %s\n- Quota: %d (%s)\n- Area Count: %d",
                   PREFIX_DEBUG,
                   RCBot2_IsWaypointAvailable() ? "RCBot2" : NavMesh_IsLoaded() ? "TFBot" : "N/A",
                   RCBot2_IsWaypointAvailable() ? rcbot_bot_quota_interval.IntValue : tf_bot_quota.IntValue,
                   RCBot2_IsWaypointAvailable() ? "rcbot_bot_quota_interval" : NavMesh_IsLoaded() ? "tf_bot_quota" : "N/A",
                   NavMesh_GetNavAreaCount());

    return Plugin_Handled;
}

#include "tfbots_fun/stocks.sp"