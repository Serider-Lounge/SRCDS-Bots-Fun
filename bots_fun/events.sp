/* ========[Clients]======== */
// post_inventory_application, teamplay_flag_event
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
// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsFakeClient(client))
        return;

    if (IsClientInGame(client))
        RCBot2_EnforceBotQuota(client);

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

    if (IsFakeClient(client))
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
    int client = -1;
    if (StrEqual(name, "player_disconnect"))
    {
        client = GetClientOfUserId(event.GetInt("userid"));
        if (client > 0 && client <= MaxClients)
            g_bIsAlive[client] = false;
    }
    event.BroadcastDisabled = event.GetBool("bot");
    return Plugin_Changed;
}

/* ========[Rounds]======== */
// arena_round_start, teamplay_suddendeath_begin
/*
public void Event_RoundStart_Arena(Event event, const char[] name, bool dontBroadcast)
{}
*/
// teamplay_round_win
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    RCBot2_KickAllBots();
}