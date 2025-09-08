public Action Command_NavInfo(int client, int args)
{
    CReplyToCommand(client,
        "[{red}%s{default}]:\n- {olive}Bot Type{default}: {lightcyan}%s\n- {olive}Quota: {lightcyan}%d{default}",
        PLUGIN_NAME,
        RCBot2_IsWaypointAvailable() ? "RCBot2" : NavMesh_IsLoaded() ? "TFBot" : "Unsupported Map",
        RCBot2_IsWaypointAvailable() ? g_ConVars[rcbot_bot_quota].IntValue : g_ConVars[tf_bot_quota].IntValue);
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