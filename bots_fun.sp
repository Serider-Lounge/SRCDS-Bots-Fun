#include <bots_fun>

#include "bots_fun/commands.sp"
#include "bots_fun/configs.sp"
#include "bots_fun/convars.sp"
#include "bots_fun/events.sp"

/* ========[Forwards]======== */
public void OnPluginStart()
{
    /* ConVars */
    g_ConVarTFBotQuota = FindConVar("tf_bot_quota");

    g_ConVarPluginEnabled = CreateConVar("sm_bot_enabled", "1",
                                       "Toggle the plugin.",
                                        FCVAR_REPLICATED);
    HookConVarChange(g_ConVarPluginEnabled, ConVar_BotRatio);
    g_ConVarBotRatio = CreateConVar("sm_bot_ratio", "0.25",
                                  "Ratio of the bot quota to max players.",
                                  FCVAR_REPLICATED,
                                  true, 0.0, true, 1.0);
    HookConVarChange(g_ConVarBotRatio, ConVar_BotRatio);
    g_ConVarRCBotQuota = CreateConVar("rcbot_bot_quota", "0",
                                      "Determines the total number of rcbots in the game.",
                                      FCVAR_REPLICATED,
                                      true, 0.0, true, float(MAXPLAYERS));
    HookConVarChange(g_ConVarRCBotQuota, ConVar_RCBotQuota);
    g_ConVarRCBotQuotaMode = CreateConVar("rcbot_bot_quota_mode", "normal",
                                          "Determines the type of quota. Allowed values: 'normal', 'fill', and 'match'. If 'fill', the server will adjust bots to keep N players in the game, where N is bot_quota. If 'match', the server will maintain a 1:N ratio of humans to bots, where N is bot_quota.",
                                          FCVAR_REPLICATED);

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
    HookEvent("teamplay_suddendeath_begin", Event_RoundStart_Arena);
    HookEvent("arena_round_start", Event_RoundStart_Arena);
    HookEvent("teamplay_round_win", Event_RoundEnd);

    /* Commands */
    // Listeners
    AddCommandListener(Command_JoinTeam, "jointeam");

    // @everyone
    RegConsoleCmd("sm_nav_info", Command_NavInfo, "Display information about bot support.");
    
    // @admins
    RegAdminCmd("sm_nav_generate", Command_NavGenerate, ADMFLAG_CHEATS, "Generate navigation meshes.");
    RegAdminCmd("sm_nav_generate_incremental", Command_NavGenerateIncremental, ADMFLAG_CHEATS, "Generate navigation meshes incrementally.");
    //RegAdminCmd("sm_nav_copy", Command_NavCopy, ADMFLAG_CHEATS, "Steal a '.nav' file from another map.");
    //RegAdminCmd("sm_waypoint_copy", Command_WaypointCopy, ADMFLAG_CHEATS, "Steal a '.rcw' waypoint file from another map.");
}

public void OnConfigsExecuted()
{
    g_iBotQuota = RoundFloat(g_ConVarBotRatio.FloatValue * GetMaxHumanPlayers());

    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    // Check if the plugin is enabled (or if it's MVM)
    if (!g_ConVarPluginEnabled.BoolValue || IsGameMode("mann_vs_machine"))
    {
        SetConVarInt(g_ConVarRCBotQuota, 0);
        SetConVarInt(g_ConVarTFBotQuota, 0);

        RCBot2_KickAllBots();

        PrintToServer("[%s] Plugin has been disabled, kicking bots...", PLUGIN_NAME);
        return;
    }

    // Check for bot support
    if (RCBot2_IsWaypointAvailable()) // RCBot2
    {
        SetConVarInt(g_ConVarRCBotQuota, g_iBotQuota);
        SetConVarInt(g_ConVarTFBotQuota, 0);

        PrintToServer("[%s] RCBot2 waypoints detected, adding RCBot clients...", PLUGIN_NAME);
        PrintToServer("[%s] rcbot_bot_quota_interval: %d.", PLUGIN_NAME, rcbot_bot_quota_interval.IntValue);
        PrintToServer("[%s] ⚠ WARNING ⚠: Make sure to comment out 'rcbot_bot_quota_interval' in 'addons/rcbot2/config/config.ini'!.", PLUGIN_NAME);
    }
    else if (NavMesh_IsLoaded()) // TFBot
    {
        ConVar tf_bot_offense_must_push_time = FindConVar("tf_bot_offense_must_push_time");
        int oldPushTime = GetConVarInt(tf_bot_offense_must_push_time);

        SetConVarInt(g_ConVarRCBotQuota, 0);
        SetConVarInt(g_ConVarTFBotQuota, g_iBotQuota);
        SetConVarInt(FindConVar("tf_bot_offense_must_push_time"),
                    (IsGameMode("player_destruction") || 
                     IsGameMode("robot_destruction")) ? -1 : oldPushTime > -1 ? oldPushTime : 120);

        RCBot2_KickAllBots();

        PrintToServer("[%s] Valve Navigation Meshes detected, adding TFBot clients...", PLUGIN_NAME, g_iBotQuota);
        PrintToServer("[%s] g_ConVarTFBotQuota: %d.", PLUGIN_NAME, g_iBotQuota);
    }
    else // N/A
    {
        SetConVarInt(g_ConVarRCBotQuota, 0);
        SetConVarInt(g_ConVarTFBotQuota, 0);

        RCBot2_KickAllBots();

        PrintToServer("[%s] Bots are unsupported on this map.", PLUGIN_NAME);
    }
}

public void OnMapEnd()
{
    RCBot2_KickAllBots();
}

public void OnClientDisconnect(int client)
{
    CheckAliveHumans(client);
    RCBot2_EnforceBotQuota(client);
}