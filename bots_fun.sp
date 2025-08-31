#undef REQUIRE_EXTENSIONS
#include <rcbot2> // https://github.com/APGRoboCop/rcbot2
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <tf2_stocks>
#include <serider/navmesh>
#include <multicolors>

#include "bots_fun/stocks.sp"

#define PLUGIN_NAME   "Bots Fun" // For now, just Team Fortress 2.
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
ConVar g_ConVarPluginEnabled,
       g_ConVarBotRatio,
       g_ConVarRCBotQuota,
       g_ConVarRCBotQuotaMode,
       rcbot_bot_quota_interval,
       tf_bot_quota;

int iBotQuota,
    iAliveHumans;

bool bIsAlive[MAXPLAYERS + 1];

Handle g_hConfigTrie = INVALID_HANDLE;

/* ========[Forwards]======== */
public void OnPluginStart()
{
    /* ConVars */
    rcbot_bot_quota_interval = FindConVar("rcbot_bot_quota_interval");
    tf_bot_quota = FindConVar("tf_bot_quota");

    g_ConVarPluginEnabled = CreateConVar("sm_bot_enabled", "1",
                                       "Toggle the plugin.",
                                        FCVAR_REPLICATED);
    HookConVarChange(g_ConVarPluginEnabled, ConVar_BotRatio);
    g_ConVarBotRatio = CreateConVar("sm_bot_ratio", "0.25",
                                  "Ratio of 'tf_bot_quota' to max players.",
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
    iBotQuota = RoundFloat(g_ConVarBotRatio.FloatValue * GetMaxHumanPlayers());

    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    // Check if the plugin is enabled (or if it's MVM)
    if (!g_ConVarPluginEnabled.BoolValue || IsGameMode("mann_vs_machine"))
    {
        //SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(g_ConVarRCBotQuota, 0);
        SetConVarInt(tf_bot_quota, 0);

        KickRCBots();

        PrintToServer("[%s] Plugin has been disabled, kicking bots...", PLUGIN_NAME);
        return;
    }

    // Check for bot support
    if (RCBot2_IsWaypointAvailable())
    {
        //SetConVarInt(rcbot_bot_quota_interval, 1);
        SetConVarInt(g_ConVarRCBotQuota, iBotQuota);
        SetConVarInt(tf_bot_quota, 0);

        PrintToServer("[%s] RCBot2 waypoints detected, adding RCBot clients...", PLUGIN_NAME);
        PrintToServer("[%s] rcbot_bot_quota_interval: %d.", PLUGIN_NAME, rcbot_bot_quota_interval.IntValue);
        PrintToServer("[%s] ⚠ WARNING ⚠: Make sure to comment out 'rcbot_bot_quota_interval' in 'addons/rcbot2/config/config.ini'!.", PLUGIN_NAME);
    }
    else if (NavMesh_IsLoaded())
    {
        ConVar tf_bot_offense_must_push_time = FindConVar("tf_bot_offense_must_push_time");
        int oldPushTime = GetConVarInt(tf_bot_offense_must_push_time);

        //SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(g_ConVarRCBotQuota, 0);
        SetConVarInt(tf_bot_quota, iBotQuota);
        SetConVarInt(FindConVar("tf_bot_offense_must_push_time"),
                    (IsGameMode("player_destruction") || 
                     IsGameMode("robot_destruction")) ? -1 : oldPushTime > -1 ? oldPushTime : 120);

        KickRCBots();

        PrintToServer("[%s] Valve Navigation Meshes detected, adding TFBot clients...", PLUGIN_NAME, iBotQuota);
        PrintToServer("[%s] tf_bot_quota: %d.", PLUGIN_NAME, iBotQuota);
    }
    else
    {
        //SetConVarInt(rcbot_bot_quota_interval, 0);
        SetConVarInt(g_ConVarRCBotQuota, 0);
        SetConVarInt(tf_bot_quota, 0);

        KickRCBots();

        PrintToServer("[%s] Bots are unsupported on this map.", PLUGIN_NAME);
    }
}

public void OnMapEnd()
{
    KickRCBots();
}

public void OnClientDisconnect(int client)
{
    if (IsPermaDeathMode())
    {
        if (IsFakeClient(client)) return;

        if (bIsAlive[client])
        {
            iAliveHumans--;
            if (iAliveHumans < 0)
                iAliveHumans = 0;
            else if (iAliveHumans < 1)
            {
                char teamUnassigned[8];
                IntToString(view_as<int>(TFTeam_Unassigned), teamUnassigned, sizeof(teamUnassigned));
                CheatCommand("mp_forcewin", teamUnassigned);
            }
        }
        bIsAlive[client] = false;

        //CPrintToChatAll("[%s] Player {unique}%N{default} died! Alive Humans: %d", PREFIX_DEBUG, client, iAliveHumans);
    }

    char strRCBotQuotaMode[16];
    GetConVarString(g_ConVarRCBotQuotaMode, strRCBotQuotaMode, sizeof(strRCBotQuotaMode));
    if (!IsFakeClient(client) && StrEqual(strRCBotQuotaMode, "fill"))
    {
        RCBot2_CreateBot("");
    }
}

/* ========[ConVars]======== */
public void ConVar_BotRatio(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

public void ConVar_RCBotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
    //int oldQuota = StringToInt(oldValue);
    int newQuota = StringToInt(newValue);

    int currentRCBots = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && IsRCBot2Client(i))
        {
            currentRCBots++;
        }
    }

    int toAdd = newQuota - currentRCBots;
    if (toAdd > 0)
    {
        for (int i = 0; i < toAdd; i++)
        {
            RCBot2_CreateBot("");
        }
    }
    else if (toAdd < 0)
    {
        int toRemove = -toAdd;
        for (int i = 1; i <= MaxClients && toRemove > 0; i++)
        {
            if (IsClientInGame(i) && IsFakeClient(i) && IsRCBot2Client(i))
            {
                KickClient(i);
                toRemove--;
            }
        }
    }
}

/* ========[Events]======== */
// Clients
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

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsPermaDeathMode())
    {
        if (IsFakeClient(client)) return;

        if (!bIsAlive[client] && IsPlayerAlive(client))
        {
            iAliveHumans++;
        }
        bIsAlive[client] = IsPlayerAlive(client);

        //CPrintToChatAll("[%s] Player {unique}%N{default} spawned! Alive Humans: %d", PREFIX_DEBUG, client, iAliveHumans);
    }

    char strRCBotQuotaMode[16];
    GetConVarString(g_ConVarRCBotQuotaMode, strRCBotQuotaMode, sizeof(strRCBotQuotaMode));
    if (!IsFakeClient(client) && StrEqual(strRCBotQuotaMode, "fill"))
    {
        int iClientTeam = GetClientTeam(client);
        if (iClientTeam > 1)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsFakeClient(i) && IsRCBot2Client(i) && GetClientTeam(i) == iClientTeam)
                {
                    KickClient(i);
                    break;
                }
            }
        }
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    OnClientDisconnect(client);
}

public Action Event_PlayerStatus(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = event.GetBool("bot");
    return Plugin_Changed;
}

// Rounds
public void Event_RoundStart_Arena(Event event, const char[] name, bool dontBroadcast)
{
    iAliveHumans = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        bIsAlive[i] = IsClientInGame(i) &&
                      IsPlayerAlive(i) &&
                      !IsFakeClient(i);
        if (bIsAlive[i])
            iAliveHumans++;
    }
    //CPrintToChatAll("[%s] Round started! Alive Humans: %d", PREFIX_DEBUG, iAliveHumans);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    KickRCBots();
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