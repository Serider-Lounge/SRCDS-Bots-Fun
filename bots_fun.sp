#include <bots_fun>

#include "bots_fun/commands.sp"
#include "bots_fun/configs.sp"
#include "bots_fun/convars.sp"
#include "bots_fun/events.sp"

// The rest is defined in <bots_fun>
#define PLUGIN_VERSION  "25w37c"
#define PLUGIN_AUTHOR   "Heapons"
#define PLUGIN_DESC     "Automatically manage bots (+ RCBot2 support)."
#define PLUGIN_URL      "https://github.com/Serider-Lounge/SRCDS-Bots-Fun"

/* ========[Forwards]======== */
public void OnPluginStart()
{
    /* ConVars */
    // tf_bot_quota
    g_ConVars[tf_bot_quota] = FindConVar("tf_bot_quota");
    // sm_bot_enabled
    g_ConVars[plugin_enabled] = CreateConVar("sm_bot_enabled", "1",
                                             "Toggle the plugin.",
                                             FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_ConVars[plugin_enabled], ConVar_BotRatio);
    // sm_bot_ratio
    g_ConVars[bot_ratio] = CreateConVar("sm_bot_ratio", "0.25",
                                        "Ratio of the bot quota to max players.",
                                        FCVAR_REPLICATED,
                                        true, 0.0, true, 1.0);
    HookConVarChange(g_ConVars[bot_ratio], ConVar_BotRatio);
    // rcbot_bot_quota
    g_ConVars[rcbot_bot_quota] = CreateConVar("rcbot_bot_quota", "0",
                                              "Determines the total number of rcbots in the game.",
                                              FCVAR_REPLICATED,
                                              true, 0.0, true, float(MAXPLAYERS));
    HookConVarChange(g_ConVars[rcbot_bot_quota], ConVar_RCBotQuota);
    // rcbot_bot_quota_mode
    g_ConVars[rcbot_bot_quota_mode] = CreateConVar("rcbot_bot_quota_mode", "normal",
                                                   "Determines the type of quota. Allowed values: 'normal', 'fill'. If 'fill', the server will adjust bots to keep N players in the game, where N is bot_quota.",
                                                   FCVAR_REPLICATED);
    // sm_bot_humans_only
    /*
    g_ConVars[humans_only] = CreateConVar("sm_bot_humans_only", "1",
                                          "Whether to end the round prematurely if all human players are dead in Arena Mode or Sudden Death",
                                          FCVAR_REPLICATED, true, 0.0, true, 1.0);
    */
    // sm_bot_rename_bots
    g_ConVars[rename_bots] = CreateConVar("sm_bot_rename_bots", "1",
                                          "If enabled, bots will be renamed based on their player model.",
                                          FCVAR_REPLICATED, true, 0.0, true, 1.0);

    /* Configs */
    AutoExecConfig(true, "bots_fun");
    LoadPluginConfig();

    /* Events */
    // Players
    HookEvent("post_inventory_application", Event_PlayerModelUpdate);
    HookEvent("teamplay_flag_event", Event_PlayerModelUpdate);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_connect", Event_PlayerStatus, EventHookMode_Pre);
    HookEvent("player_connect_client", Event_PlayerStatus, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerStatus, EventHookMode_Pre);
    HookEvent("player_info", Event_PlayerStatus, EventHookMode_Pre);
    // Rounds
    HookEvent("teamplay_round_start", Event_RoundStart);
    //HookEvent("teamplay_round_win", Event_RoundEnd);

    // @everyone
    RegConsoleCmd("sm_nav_info", Command_NavInfo, "Display information about bot support.");
    
    // @admins
    RegAdminCmd("sm_nav_generate", Command_NavGenerate, ADMFLAG_CHEATS, "Generate navigation meshes.");
    RegAdminCmd("sm_nav_generate_incremental", Command_NavGenerateIncremental, ADMFLAG_CHEATS, "Generate navigation meshes incrementally.");
}

public void OnConfigsExecuted()
{
    g_bWasBotStatusShown = false;

    g_iBotQuota = RoundFloat(g_ConVars[bot_ratio].FloatValue * GetMaxHumanPlayers());

    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    // Check if the plugin is enabled
    if (!g_ConVars[plugin_enabled].BoolValue)
    {
        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);

        RCBot2_KickAllBots();

        PrintToServer("[%s] Map is unsupported, bots won't be playing.", PLUGIN_NAME);
        return;
    }

    // Check for bot support
    if (RCBot2_IsWaypointAvailable()) // RCBot2
    {
        int TFMVMDefendersTeamSize = GetConVarInt(FindConVar("tf_mvm_defenders_team_size"));

        SetConVarInt(g_ConVars[rcbot_bot_quota],
                     IsGameMode("mann_vs_machine") ? TFMVMDefendersTeamSize : g_iBotQuota);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);

        PrintToServer("[%s] RCBot2 waypoints detected, adding RCBot clients...", PLUGIN_NAME);
        PrintToServer("[%s] rcbot_bot_quota: %d.", PLUGIN_NAME, g_ConVars[rcbot_bot_quota].IntValue);
    }
    else if (NavMesh_IsLoaded() && !IsGameMode("mann_vs_machine")) // TFBot
    {
        ConVar tf_bot_offense_must_push_time = FindConVar("tf_bot_offense_must_push_time");
        int oldPushTime = GetConVarInt(tf_bot_offense_must_push_time);

        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], g_iBotQuota);
        SetConVarInt(FindConVar("tf_bot_offense_must_push_time"),
                    (IsGameMode("player_destruction") || 
                     IsGameMode("robot_destruction")) ? -1 : oldPushTime > -1 ? oldPushTime : 120);

        RCBot2_KickAllBots();

        PrintToServer("[%s] Valve Navigation Meshes detected, adding TFBot clients...", PLUGIN_NAME, g_iBotQuota);
        PrintToServer("[%s] tf_bot_quota: %d.", PLUGIN_NAME, g_iBotQuota);
    }
    else // N/A
    {
        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);

        RCBot2_KickAllBots();

        PrintToServer("[%s] Bots are unsupported on this map.", PLUGIN_NAME);
    }
}

public void OnClientDisconnect(int client)
{
    if (IsPermaDeathMode())
        CheckAliveHumans(client);
    
    if (!IsFakeClient(client) && RCBot2_IsWaypointAvailable())
        RCBot2_UpdateBotQuota(client);
}