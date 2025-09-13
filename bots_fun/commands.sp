public Action Command_NavInfo(int client, int args)
{
    char botType[16];
    int botQuota;

    if (IsNavMeshLoaded()) // NavBot
    {
        strcopy(botType, sizeof(botType), "NavBot");
        botQuota = FindConVar("sm_navbot_quota_quantity").IntValue;
    }
    else if (RCBot2_IsWaypointAvailable()) // RCBot2
    {
        strcopy(botType, sizeof(botType), "RCBot2");
        botQuota = g_ConVars[rcbot_bot_quota].IntValue;
    }
    else if (NavMesh_IsLoaded()) // TFBot
    {
        strcopy(botType, sizeof(botType), "TFBot");
        botQuota = g_ConVars[tf_bot_quota].IntValue;
        CReplyToCommand(client,
            "[{red}%s{default}]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota: {lightcyan}%d{default}\n- {olive}Area Count{default}: {lightcyan}%d",
            PLUGIN_NAME,
            botType,
            botQuota,
            NavMesh_GetNavAreaCount());
        return Plugin_Handled;
    }
    else // Unsupported
    {
        strcopy(botType, sizeof(botType), "Unsupported Map");
    }

    CReplyToCommand(client,
        "[{red}%s{default}]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota: {lightcyan}%d{default}",
        PLUGIN_NAME,
        botType,
        botQuota);

    return Plugin_Handled;
}

public Action Command_NavGenerate(int client, int args)
{
    CheatCommand("nav_generate");

    CReplyToCommand(client, "[%s] Generating navigation meshes...", PLUGIN_NAME);
    return Plugin_Handled;
}

public Action Command_NavGenerateIncremental(int client, int args)
{
    CheatCommand("nav_generate_incremental");

    CReplyToCommand(client, "[{red}%s{default}] Generating navigation meshes incrementally...", PLUGIN_NAME);
    return Plugin_Handled;
}