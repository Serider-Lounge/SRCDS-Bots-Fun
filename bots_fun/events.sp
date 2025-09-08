/* ========[Clients]======== */
// post_inventory_application, teamplay_flag_event
public void Event_PlayerModelUpdate(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_ConVarRenameBots.BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsPlayerAlive(client) || !IsFakeClient(client))
        return;

    CreateTimer(0.100001, Timer_SetNameFromModel, client);
}

public Action Timer_SetNameFromModel(Handle timer, int client)
{
    char path[PLATFORM_MAX_PATH],
         botName[PLATFORM_MAX_PATH];

    GetClientModel(client, path, sizeof(path));

    if (GetBotName(path, botName, sizeof(botName)))
        SetClientName(client, botName);

    return Plugin_Stop;
}
// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsFakeClient(client))
        return;

    if (IsClientInGame(client))
        RCBot2_UpdateBotQuota(client);

    if (IsPermaDeathMode())
    {
        if (IsClientInGame(client) && !IsClientObserver(client))
            g_bIsAlive[client] = true;
        CheckAliveHumans(client);
    }
}

// player_death
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    bool isFeignDeath = (event.GetInt("death_flags") == 32);

    if (isFeignDeath)
        return;

    if (IsPermaDeathMode())
    {
        if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client))
            g_bIsAlive[client] = false;
        CheckAliveHumans(client);
    }
}
// player_connect, player_connect_client, player_disconnect, player_info
public Action Event_PlayerStatus(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = event.GetBool("bot");
    return Plugin_Changed;
}

/* ========[Rounds]======== */
// teamplay_round_start
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bWasBotStatusShown)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                FakeClientCommand(i, "sm_nav_info");
            }
        }
        g_bWasBotStatusShown = true;
    }
}
// teamplay_round_win
/*
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    RCBot2_KickAllBots(false);
}
*/