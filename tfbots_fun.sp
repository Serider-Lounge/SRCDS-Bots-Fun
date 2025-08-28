#undef REQUIRE_EXTENSIONS
#include <rcbot2> // https://github.com/APGRoboCop/rcbot2
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <tf2_stocks>
#include <serider/navmesh>
#include <multicolors>

#include "tfbots_fun/stocks.sp"

#define PLUGIN_NAME   "TFBots Fun"
#define PREFIX       "{red}TFBots Fun{default}"
#define PREFIX_DEBUG "{red}TFBots Fun{default} | {lightyellow}Debug{default}"
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

/* ========[Core]======== */
public void OnPluginStart()
{
    // ConVars
    rcbot_bot_quota_interval = FindConVar("rcbot_bot_quota_interval");
    tf_bot_quota = FindConVar("tf_bot_quota");

    gcvar_PluginEnabled = CreateConVar("sm_tfbot_fun_enabled", "1",
                                       "Toggle the plugin.",
                                        FCVAR_REPLICATED);
    HookConVarChange(gcvar_PluginEnabled, ConVar_BotRatio);
    gcvar_BotRatio = CreateConVar("sm_tf_bot_ratio", "0.25",
                                  "Ratio of 'tf_bot_quota' to max players.",
                                  FCVAR_REPLICATED,
                                  true, 0.0, true, 1.0);
    HookConVarChange(gcvar_BotRatio, ConVar_BotRatio);
    
    BotQuota = RoundFloat(gcvar_BotRatio.FloatValue * GetMaxHumanPlayers());

    AutoExecConfig(true, "tfbots_fun");

    // Events
    HookEvent("post_inventory_application", Event_PlayerModelUpdate);
    HookEvent("teamplay_flag_event", Event_PlayerModelUpdate);

    // Commands
    RegConsoleCmd("sm_nav_info", Command_NavInfo, "Display information about bot support.");
    
    RegAdminCmd("sm_nav_generate", Command_NavGenerate, ADMFLAG_CHEATS, "Generate navigation meshes.");
    RegAdminCmd("sm_nav_generate_incremental", Command_NavGenerateIncremental, ADMFLAG_CHEATS, "Generate navigation meshes incrementally.");
}

public void OnConfigsExecuted()
{
    SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");

    // Check if the plugin is enabled
    if (!gcvar_PluginEnabled.BoolValue && IsGameMode("mann_vs_machine"))
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

/* ========[ConVars]======== */
public void ConVar_BotRatio(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/* ========[Events]======== */
/* player_spawn */
public void Event_PlayerModelUpdate(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    if (!IsPlayerAlive(client) ||
        !IsFakeClient(client)) return;

    CreateTimer(0.01, Timer_SetNameFromModel, userid);
}

public Action Timer_SetNameFromModel(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    // TO-DO: Move these to a config file, but I have no idea how to implement it (yet?).
    // - Heapons
    static const char classes[][2][32] = {
        {"scout", "Scout"},
        {"soldier", "Soldier"},
        {"pyro", "Pyro"},
        {"demo", "Demoman"},
        {"heavy", "Heavy Weapons Guy"},
        {"engineer", "Engineer"},
        {"medic", "Medic"},
        {"sniper", "Sniper"},
        {"spy", "Spy"},
        {"civilian", "Civilian"},
        {"merc", "Mercenary"},
        {"saxton_hale", "Saxton Hale"},
        {"mecha_hale", "Mecha Hale"},
        {"hell_hale", "Saxton Hell"},
        {"sentry_buster", "Sentry Buster"},
        {"skeleton_sniper", "Skeleton"},
        {"giant_shako", "Demopan"},
        {"epic/scout", "Epic Scout"},
        {"gaben", "Gabe Newell"},
        {"gentlespy", "Gentlespy"},
        {"graymann", "Gray Mann"},
        {"ninjaspy", "Ninja Spy"},
        {"seeman", "Seeman"},
        {"seeldier", "Seeldier"},
        {"cbs", "Christian Brutal Sniper"},
        {"easter_demo", "Easter Demo"},
        {"hhh_jr", "HHH Jr."},
        {"headless_hatman", "Horseless Headless Horseman"},
        {"vagineer", "Vagineer"},
        {"merasmus", "Merasmus"},
        {"saxtron", "Saxtron H413"},
        {"infected/hoomer", "Boomer"},
        {"infected/coomer", "Charger"},
        {"infected/hank", "Tank"},
        {"infected/scunter", "Hunter"},
        {"infected/spyro", "Spitter"},
        {"infected/wanker", "Smoker"},
        {"infected/sock", "Jockey"},
        {"infected/benic", "Screamer"},
        {"mobster", "Mobster"},
        {"julius", "Julius"},
        {"pauling", "Ms. Pauling"},
        {"bot_worker", "Worker"}
    };

    char model[PLATFORM_MAX_PATH];
    GetClientModel(client, model, sizeof(model));

    for (int i = 0; i < sizeof(classes); i++)
    {
        if (StrContains(model, classes[i][0], false) != -1)
        {
            SetClientName(client, classes[i][1]);
            break;
        }
    }
    return Plugin_Stop;
}

/* ========[Commands]======== */
public Action Command_NavInfo(int client, int args)
{
    CReplyToCommand(client, "[%s]:\n- {olive}Type{default}: {lightcyan}%s\n- {olive}Quota: {lightcyan}%d{default} ({lightcyan}%s{default})\n- {olive}Area Count{default}: {lightcyan}%d",
                    PREFIX_DEBUG,
                    RCBot2_IsWaypointAvailable() ? "RCBot2" : NavMesh_IsLoaded() ? "TFBot" : "N/A",
                    RCBot2_IsWaypointAvailable() ? rcbot_bot_quota_interval.IntValue : tf_bot_quota.IntValue,
                    RCBot2_IsWaypointAvailable() ? "rcbot_bot_quota_interval" : NavMesh_IsLoaded() ? "tf_bot_quota" : "N/A",
                    NavMesh_GetNavAreaCount());

    return Plugin_Handled;
}

public Action Command_NavGenerate(int client, int args)
{
    ServerCommand("sv_cheats 1; nav_generate; sv_cheats 0");

    CReplyToCommand(client, "[%s] Generating navigation meshes...", PREFIX_DEBUG);
    return Plugin_Handled;
}

public Action Command_NavGenerateIncremental(int client, int args)
{
    ServerCommand("sv_cheats 1; nav_generate_incremental; sv_cheats 0");

    CReplyToCommand(client, "[%s] Generating navigation meshes incrementally...", PREFIX_DEBUG);
    return Plugin_Handled;
}