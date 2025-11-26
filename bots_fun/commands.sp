public Action Command_NavInfo(int client, int args)
{
    char botType[16];
    int botQuota;

    if (NavBotNavMesh.IsLoaded()) // NavBot
    {
        strcopy(botType, sizeof(botType), "NavBot");
        botQuota = g_ConVars[navbot_bot_quota].IntValue;
    }
    else if (RCBot2_IsWaypointAvailable()) // RCBot2
    {
        strcopy(botType, sizeof(botType), "RCBot2");
        botQuota = g_ConVars[rcbot_bot_quota].IntValue;
    }
    else if (NavMesh.IsLoaded()) // TFBot
    {
        strcopy(botType, sizeof(botType), "TFBot");
        botQuota = g_ConVars[tf_bot_quota].IntValue;
        CReplyToCommand(client,
            "[{red}%s{default}]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota{default}: {lightcyan}%d{default}\n- {olive}Area Count{default}: {lightcyan}%d",
            PLUGIN_NAME,
            botType,
            botQuota,
            NavMesh.GetNavAreaCount());
        return Plugin_Handled;
    }
    else // Unsupported
    {
        strcopy(botType, sizeof(botType), "Unsupported Map");
    }

    CReplyToCommand(client,
                    "[{red}%s{default}]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota{default}: {lightcyan}%d{default}",
                    PLUGIN_NAME,
                    botType,
                    botQuota);

    return Plugin_Handled;
}

public Action Command_NavGenerate(int client, int args)
{
    if (!IsClientAdmin(client, ADMFLAG_CHEATS))
    {
        return Plugin_Handled;
    }

    if (NavMesh.IsLoaded())
    {
        g_ConVars[bot_ratio].FloatValue = 0.0;
        for (int i = 0; i <= MaxClients; i++)
        {
            if (IsFakeClient(i))
            {
                KickClient(i);
            }
        }
        SetCommandFlags("nav_generate", GetCommandFlags("nav_generate") & ~FCVAR_CHEAT);
        ServerCommand("nav_generate");
        CShowActivity(client, "[{red}%s{default}]: Generating Navigation Mesh... (Area Count: {lightgreen}%d{default})", PLUGIN_NAME, NavMesh.GetNavAreaCount());
    }
    else
    {
        CShowActivity(client, "[{red}%s{default}]: This map does not have any Navigation Mesh.", PLUGIN_NAME);
    }
    return Plugin_Handled;
}

public Action Command_NavGenerateIncremental(int client, int args)
{
    if (!IsClientAdmin(client, ADMFLAG_CHEATS))
    {
        return Plugin_Handled;
    }

    if (NavMesh.IsLoaded())
    {
        g_ConVars[bot_ratio].FloatValue = 0.0;
        for (int i = 0; i <= MaxClients; i++)
        {
            if (IsFakeClient(i))
            {
                KickClient(i);
            }
        }
        SetCommandFlags("nav_generate_incremental", GetCommandFlags("nav_generate_incremental") & ~FCVAR_CHEAT);
        ServerCommand("nav_generate_incremental");
        CShowActivity(client, "[{red}%s{default}]: Generating Navigation Mesh incrementally... (Area Count: {lightgreen}%d{default})", PLUGIN_NAME, NavMesh.GetNavAreaCount());
    }
    else
    {
        CShowActivity(client, "[{red}%s{default}]: This map does not have any Navigation Mesh.", PLUGIN_NAME);
    }
    return Plugin_Handled;
}

/* ==[Stocks]== */
bool IsClientAdmin(int client, int flags)
{
    return client == 0 || GetUserFlagBits(client) & flags;
}