/* ========[Clients]======== */
// post_inventory_application, teamplay_flag_event
public void Event_PlayerModelUpdate(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_ConVars[rename_bots].BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsPlayerAlive(client) || !IsFakeClient(client))
        return;

    CreateTimer(0.100001, Timer_SetNameFromModel, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetNameFromModel(Handle timer, int client)
{
    char path[PLATFORM_MAX_PATH],
         name[PLATFORM_MAX_PATH];

    GetClientModel(client, path, sizeof(path));

    if (GetBotName(path, name, sizeof(name)))
        SetClientName(client, name);

    return Plugin_Stop;
}
// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsFakeClient(client) || IsClientObserver(client))
    {
        return;
    }
}

// player_death
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_ConVars[humans_only].BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsFakeClient(client) || event.GetInt("death_flags") & 32) // Feign Death (Dead Ringer)
        return;

    if (TF2_IsPermaDeathMode() && GetAliveHumansCount() == 0)
    {
        ServerCommand("sm_kick @bots");
    }
}

// player_connect, player_connect_client, player_disconnect, player_info
public Action Event_PlayerStatus(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client == 0) return Plugin_Changed;

    event.BroadcastDisabled = event.GetBool("bot");

    if (!IsFakeClient(client))
    {
        if (NavBotNavMesh.IsLoaded()) NavBot_UpdateBotQuota();
        else if (RCBot2_IsWaypointAvailable()) RCBot2_UpdateBotQuota();
    }

    return Plugin_Changed;
}

/* ========[Rounds]======== */
// Waiting For Players
public void TF2_OnWaitingForPlayersStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        Command_NavInfo(i, 0);
    }
}