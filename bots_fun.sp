#undef REQUIRE_EXTENSIONS
#include <rcbot2> // https://github.com/APGRoboCop/rcbot2
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <tf2_stocks>
#include <serider/navmesh>
#include <multicolors>
#include <keyvalues>
#include <string>

#include "bots_fun/stocks.sp"

#define PLUGIN_NAME   "Bots Fun"
#define PLUGIN_CONFIG "addons/sourcemod/configs/bots_fun.cfg"
#define PREFIX       "{red}Bots Fun{default}"
#define PREFIX_DEBUG "{red}Bots Fun{default} | {ghostwhite}Debug{default}"
/*
enum FlagEvent
{
    TF_FLAGEVENT_PICKUP = 0,
    TF_FLAGEVENT_CAPTURE,
    TF_FLAGEVENT_DEFEND,
    TF_FLAGEVENT_DROPPED
};
*/
ConVar gcvar_PluginEnabled,
       gcvar_BotRatio,
       rcbot_bot_quota_interval,
       tf_bot_quota;

int BotQuota;

//bool bIsAlive[MAXPLAYERS + 1];

Handle g_hConfigTrie = INVALID_HANDLE;

/* ========[Forwards]======== */
public void OnPluginStart()
{
    /* ConVars */
    rcbot_bot_quota_interval = FindConVar("rcbot_bot_quota_interval");
    tf_bot_quota = FindConVar("tf_bot_quota");

    gcvar_PluginEnabled = CreateConVar("sm_bot_enabled", "1",
                                       "Toggle the plugin.",
                                        FCVAR_REPLICATED);
    HookConVarChange(gcvar_PluginEnabled, ConVar_BotRatio);
    gcvar_BotRatio = CreateConVar("sm_bot_ratio", "0.25",
                                  "Ratio of 'tf_bot_quota' to max players.",
                                  FCVAR_REPLICATED,
                                  true, 0.0, true, 1.0);
    HookConVarChange(gcvar_BotRatio, ConVar_BotRatio);
    
    BotQuota = RoundFloat(gcvar_BotRatio.FloatValue * GetMaxHumanPlayers());

    /* Configs */
    AutoExecConfig(true, "bots_fun");
    LoadPluginConfig();

    /* Events */
    HookEvent("post_inventory_application", Event_PlayerModelUpdate);
    HookEvent("teamplay_flag_event", Event_PlayerModelUpdate);
    HookEvent("teamplay_suddendeath_begin", Event_RoundStart_Arena);
    HookEvent("arena_round_start", Event_RoundStart_Arena);
    HookEvent("teamplay_round_win", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);

    /* Commands */
    RegConsoleCmd("sm_nav_info", Command_NavInfo, "Display information about bot support.");
    
    RegAdminCmd("sm_nav_generate", Command_NavGenerate, ADMFLAG_CHEATS, "Generate navigation meshes.");
    RegAdminCmd("sm_nav_generate_incremental", Command_NavGenerateIncremental, ADMFLAG_CHEATS, "Generate navigation meshes incrementally.");
    //RegAdminCmd("sm_nav_copy", Command_NavCopy, ADMFLAG_CHEATS, "Steal a '.nav' file from another map.");
    //RegAdminCmd("sm_waypoint_copy", Command_WaypointCopy, ADMFLAG_CHEATS, "Steal a '.rcw' waypoint file from another map.");
}

public void OnConfigsExecuted()
{
    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    // Check if the plugin is enabled (or if it's MVM)
    if (!gcvar_PluginEnabled.BoolValue || IsGameMode("mann_vs_machine"))
    {
        SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(tf_bot_quota, 0);

        KickRCBots();

        PrintToServer("[%s] Plugin has been disabled, kicking bots...", PLUGIN_NAME);
        return;
    }

    // Check for bot support
    if (RCBot2_IsWaypointAvailable())
    {
        SetConVarInt(rcbot_bot_quota_interval, 1);
        SetConVarInt(tf_bot_quota, 0);

        PrintToServer("[%s] RCBot2 waypoints detected, adding RCBot clients...", PLUGIN_NAME);
        PrintToServer("[%s] rcbot_bot_quota_interval: %d.", PLUGIN_NAME, rcbot_bot_quota_interval.IntValue);
        PrintToServer("[%s] ⚠ WARNING ⚠: Make sure to comment out 'rcbot_bot_quota_interval' in 'addons/rcbot2/config/config.ini'!.", PLUGIN_NAME);
    }
    else if (NavMesh_IsLoaded())
    {
        ConVar tf_bot_offense_must_push_time = FindConVar("tf_bot_offense_must_push_time");
        int oldPushTime = GetConVarInt(tf_bot_offense_must_push_time);

        SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(tf_bot_quota, BotQuota);
        SetConVarInt(FindConVar("tf_bot_offense_must_push_time"),
                    (IsGameMode("player_destruction") || 
                     IsGameMode("robot_destruction")) ? -1 : oldPushTime > -1 ? oldPushTime : 120);

        KickRCBots();

        PrintToServer("[%s] Valve Navigation Meshes detected, adding TFBot clients...", PLUGIN_NAME, BotQuota);
        PrintToServer("[%s] tf_bot_quota: %d.", PLUGIN_NAME, BotQuota);
    }
    else
    {
        SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(tf_bot_quota, 0);

        KickRCBots();

        PrintToServer("[%s] Bots are unsupported on this map.", PLUGIN_NAME);
    }
}

public void OnMapEnd()
{
    KickRCBots();
}

/* ========[ConVars]======== */
public void ConVar_BotRatio(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/* ========[Events]======== */
public void Event_PlayerModelUpdate(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    if (!IsPlayerAlive(client) ||
        !IsFakeClient(client)) return;

    CreateTimer(0.100001, Timer_SetNameFromModel, userid);
}

public Action Timer_SetNameFromModel(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    char path[PLATFORM_MAX_PATH],
         botName[PLATFORM_MAX_PATH];

    GetClientModel(client, path, sizeof(path));

    if (GetBotName(path, botName, sizeof(botName)))
    {
        SetClientName(client, botName);
        return Plugin_Stop;
    }

    return Plugin_Stop;
}

public void Event_RoundStart_Arena(Event event, const char[] name, bool dontBroadcast)
{
    /*
    for (int i = 1; i <= MaxClients; i++)
    {
        bIsAlive[i] = IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i);
    }
    */
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    KickRCBots();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    /*
    int client = GetClientOfUserId(event.GetInt("userid"));
    bIsAlive[client] = IsPermaDeathMode() && !IsFakeClient(client);
    */
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    /*
    int client = GetClientOfUserId(event.GetInt("userid"));
    OnClientDisconnect(client);
    */
}

/* ========[Forwards]======== */
public void OnClientDisconnect(int client)
{
    /*
    if (IsPermaDeathMode() && !IsFakeClient(client))
    {
        bIsAlive[client] = false;

        for (int i = 1; i <= MaxClients; i++)
        {
            char unassigned[8];

            if (bIsAlive[i])
            {
                return;
            }
        }

        IntToString(view_as<int>(TFTeam_Unassigned), unassigned, sizeof(unassigned));
        CheatCommand("mp_forcewin", unassigned);
    }
    */
}

/* ========[Commands]======== */
public Action Command_NavInfo(int client, int args)
{
    CReplyToCommand(client,
        "[%s]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota: {lightcyan}%d{default}\n- {olive}Area Count{default}: {lightcyan}%d",
        PREFIX_DEBUG,
        RCBot2_IsWaypointAvailable() ? "RCBot2" : NavMesh_IsLoaded() ? "TFBot" : "Unsupported Map",
        RCBot2_IsWaypointAvailable() ? rcbot_bot_quota_interval.IntValue : tf_bot_quota.IntValue,
        NavMesh_GetNavAreaCount());

    return Plugin_Handled;
}

public Action Command_NavGenerate(int client, int args)
{
    CheatCommand("nav_generate");

    CReplyToCommand(client, "[%s] Generating navigation meshes...", PREFIX_DEBUG);
    return Plugin_Handled;
}

public Action Command_NavGenerateIncremental(int client, int args)
{
    CheatCommand("nav_generate_incremental");

    CReplyToCommand(client, "[%s] Generating navigation meshes incrementally...", PREFIX_DEBUG);
    return Plugin_Handled;
}

/* ========[configs/bots_fun.cfg]======== */
void LoadPluginConfig()
{
    if (g_hConfigTrie != INVALID_HANDLE)
    {
        CloseHandle(g_hConfigTrie);
    }
    g_hConfigTrie = CreateTrie();

    KeyValues kv = new KeyValues("Config");
    if (!kv.ImportFromFile(PLUGIN_CONFIG))
    {
        PrintToServer("[%s] Failed to load 'bots_fun.cfg'", PLUGIN_NAME);
        delete kv;
        return;
    }

    if (kv.JumpToKey("Bot Names"))
    {
        if (kv.GotoFirstSubKey(false))
        {
            do
            {
                char model[64], botName[128];
                kv.GetSectionName(model, sizeof(model));
                kv.GetString(NULL_STRING, botName, sizeof(botName), "");
                if (model[0] && botName[0])
                {
                    SetTrieString(g_hConfigTrie, model, botName, true);
                }
            } while (kv.GotoNextKey(false));
            kv.GoBack();
        }
    }
    delete kv;
}

bool GetBotName(const char[] path, char[] buffer, int maxlen)
{
    if (g_hConfigTrie == INVALID_HANDLE)
        return false;

    char mdl[PLATFORM_MAX_PATH];
    int len = strlen(path);
    int start = len - 1;

    while (start >= 0 && path[start] != '/' && path[start] != '\\')
        start--;
    start++;
    int end = len - 1;

    while (end > start && path[end] != '.')
        end--;
    if (end > start)
    {
        strcopy(mdl, sizeof(mdl), path[start]);
        mdl[end - start] = '\0';
    }
    else
    {
        strcopy(mdl, sizeof(mdl), path[start]);
    }

    return GetTrieString(g_hConfigTrie, mdl, buffer, maxlen);
}