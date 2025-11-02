#include <bots_fun>

#include "bots_fun/commands.sp"
#include "bots_fun/configs.sp"
#include "bots_fun/convars.sp"
#include "bots_fun/events.sp"

// The rest is defined in <bots_fun>
#define PLUGIN_VERSION  "25w44a"
#define PLUGIN_AUTHOR   "Heapons"
#define PLUGIN_DESC     "Automatically manage bots."
#define PLUGIN_URL      "https://github.com/Serider-Lounge/SRCDS-Bots-Fun"

#define CVAR_NAV_GENERATE "Generate a Navigation Mesh for the current map and save it to disk."

/* ========[Forwards]======== */
public void OnPluginStart()
{
    /* ConVars */
    // tf_bot_quota
    g_ConVars[tf_bot_quota] = FindConVar("tf_bot_quota");
    // sm_navbot_quota_quantity
    g_ConVars[navbot_bot_quota] = FindConVar("sm_navbot_quota_quantity");
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
    g_ConVars[humans_only] = CreateConVar("sm_bot_humans_only", "1",
                                          "Whether to end the round prematurely if all human players are dead in Arena Mode or Sudden Death",
                                          FCVAR_REPLICATED, true, 0.0, true, 1.0);
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

    /* Commands */
    RegConsoleCmd("sm_nav_info", Command_NavInfo, "Display information about bot support.");
    RegConsoleCmd("sm_bot", Command_NavInfo, "Display information about bot support.");

    SetCommandFlags("nav_generate", GetCommandFlags("nav_generate") & ~FCVAR_CHEAT);
    SetCommandFlags("nav_generate_incremental", GetCommandFlags("nav_generate_incremental") & ~FCVAR_CHEAT);
}

public void OnConfigsExecuted()
{
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    if (StrContains(mapName, "workshop/") == 0)
    {
        strcopy(mapName, sizeof(mapName), mapName[9]);
    }

    int botQuota = TF2_IsGameMode("mann_vs_machine") ? GetConVarInt(FindConVar("tf_mvm_defenders_team_size")) : RoundFloat(g_ConVars[bot_ratio].FloatValue * GetMaxHumanPlayers());

    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    // Check if the plugin is enabled
    if (!g_ConVars[plugin_enabled].BoolValue)
    {
        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);
        SetConVarInt(g_ConVars[navbot_bot_quota], 0);

        PrintToServer("[%s] Map is unsupported, bots won't be playing.", PLUGIN_NAME);
        return;
    }

    // Check for bot support
    if (IsNavMeshLoaded()) // NavBot
    {
        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);

        SetConVarInt(g_ConVars[navbot_bot_quota], botQuota);
        SetConVarString(FindConVar("sm_navbot_quota_mode"), "fill");
        SetConVarBool(FindConVar("sm_navbot_tf_teammates_are_enemies"),
                      VScriptExists("ffa/ffa") ||
                      StrContains(mapName, "gg_") == 0 ||
                      FindConVar("mp_friendlyfire").BoolValue);

        PrintToServer("[%s] NavBot Navigation Meshes detected, adding NavBot clients...", PLUGIN_NAME);
        PrintToServer("[%s] sm_navbot_quota_quantity: %d.", PLUGIN_NAME, g_ConVars[navbot_bot_quota].IntValue);
    }
    else if (RCBot2_IsWaypointAvailable()) // RCBot2
    {
        SetConVarInt(g_ConVars[rcbot_bot_quota], botQuota);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);
        SetConVarInt(g_ConVars[navbot_bot_quota], 0);

        PrintToServer("[%s] RCBot2 waypoints detected, adding RCBot clients...", PLUGIN_NAME);
        PrintToServer("[%s] rcbot_bot_quota: %d.", PLUGIN_NAME, g_ConVars[rcbot_bot_quota].IntValue);
    }
    else if (NavMesh_IsLoaded() && !TF2_IsGameMode("mann_vs_machine")) // TFBot
    {
        ConVar tf_bot_offense_must_push_time = FindConVar("tf_bot_offense_must_push_time");
        int oldPushTime = GetConVarInt(tf_bot_offense_must_push_time);

        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], botQuota);
        SetConVarInt(FindConVar("tf_bot_offense_must_push_time"),
                    (TF2_IsGameMode("player_destruction") || 
                     TF2_IsGameMode("robot_destruction")) ? -1 : oldPushTime > -1 ? oldPushTime : 120);

        PrintToServer("[%s] Valve Navigation Meshes detected, adding TFBot clients...", PLUGIN_NAME, botQuota);
        PrintToServer("[%s] tf_bot_quota: %d.", PLUGIN_NAME, botQuota);
    }
    else // N/A
    {
        SetConVarInt(g_ConVars[rcbot_bot_quota], 0);
        SetConVarInt(g_ConVars[tf_bot_quota], 0);
        SetConVarInt(g_ConVars[navbot_bot_quota], 0);

        PrintToServer("[%s] Bots are unsupported on this map.", PLUGIN_NAME);
    }
}

public void OnClientDisconnect(int client)
{
    if (!IsFakeClient(client) && RCBot2_IsWaypointAvailable())
        RCBot2_UpdateBotQuota(client);
}