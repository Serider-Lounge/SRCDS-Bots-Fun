/**
 * Returns the human client count in the server.
 *
 * @param inGameOnly    If false connecting players are also counted.
 * @return              Human client count in the server.
 */
stock int GetHumanClientCount(bool isAliveOnly=false)
{
    int count = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i)) continue;
        if (!IsClientInGame(i)) continue;
        if (IsFakeClient(i)) continue;
        if (IsClientObserver(i)) continue;
        if (GetClientTeam(i) < 2) continue; // Only RED/BLU teams (exclude unassigned/spectator/SourceTV/replay)
        if (isAliveOnly && !g_bIsAlive[i]) continue;

        count++;
    }

    return count;
}

/* ========[Rounds]======== */
/**
 * Checks how many alive humans remain in perma-death game modes.
 */
stock void CheckAliveHumans(int client)
{
    if (IsFakeClient(client) || IsClientObserver(client) || !IsPlayerAlive(client))
        return;

    if (GetHumanClientCount() < 1)
    {
        char teamUnassigned[8];
        IntToString(view_as<int>(TFTeam_Unassigned), teamUnassigned, sizeof(teamUnassigned));
        CheatCommand("mp_forcewin", teamUnassigned);
    }
    //CPrintToChat(client, "[{red}%s{default}] {olive}Remaining Humans{default}: {lightgreen}%d", PLUGIN_NAME, GetHumanClientCount();
}