/**
 * Returns the human client count in the server.
 *
 * @param inGameOnly    If false connecting players are also counted.
 * @return              Human client count in the server.
 */
stock int GetHumanClientCount(bool inGameOnly=true, bool isAliveOnly=false)
{
    int count = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i) ||
            IsFakeClient(i) ||
            (inGameOnly && !IsClientInGame(i)) ||
            (isAliveOnly && (!IsPlayerAlive(i) || IsClientObserver(i)))) continue;

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
    if (IsFakeClient(client) || IsClientObserver(client))
        return;

    int aliveHumans = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bIsAlive[i])
            aliveHumans++;
    }

    if (aliveHumans < 1)
    {
        char teamUnassigned[8];
        IntToString(view_as<int>(TFTeam_Unassigned), teamUnassigned, sizeof(teamUnassigned));
        CheatCommand("mp_forcewin", teamUnassigned);
    }
    //CPrintToChat(client, "[{red}%s{default}] {olive}Remaining Humans{default}: {lightgreen}%d", PLUGIN_NAME, aliveHumans);  
}