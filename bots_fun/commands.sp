public Action Command_JoinTeam(int client, const char[] command, int argc)
{
    if (argc > 0)
    {
        char argument[16];
        GetCmdArg(1, argument, sizeof(argument));

        if (StrContains(argument, "spec") == 0)
        {
            OnClientDisconnect(client);
            RCBot2_CreateBot("");
        }
    }
    return Plugin_Continue;
}

public Action Command_NavInfo(int client, int args)
{
    CReplyToCommand(client,
        "[{red}%s{default}]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota: {lightcyan}%d{default}",
        PLUGIN_NAME,
        RCBot2_IsWaypointAvailable() ? "RCBot2" : NavMesh_IsLoaded() ? "TFBot" : "Unsupported Map",
        RCBot2_IsWaypointAvailable() ? g_ConVarRCBotQuota.IntValue : g_ConVarTFBotQuota.IntValue);
    if (!RCBot2_IsWaypointAvailable() && NavMesh_IsLoaded())
        CReplyToCommand(client, "- {olive}Area Count{default}: {lightcyan}%d", NavMesh_GetNavAreaCount());

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