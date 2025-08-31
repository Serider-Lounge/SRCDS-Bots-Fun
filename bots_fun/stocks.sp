/**
 * Kick all RCBot2 clients.
 */
stock void KickRCBots()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsRCBot2Client(i))
        {
            KickClient(i);
        }
    }
}

/**
 * This function is used to check for game mode logic entities.
 * 
 * @param  gamemode tf_logic_<gamemode> (e.g., "player_destruction" for "tf_logic_player_destruction")
 * @return          True if the entity is found
 */
stock bool IsGameMode(const char[] gamemode)
{
    char entity[64];
    Format(entity, sizeof(entity), "tf_logic_%s", gamemode);
    return FindEntityByClassname(-1, entity) != -1;
}

/**
 * Execute a cheat command without having to enable sv_cheats.
 * 
 * @param command Console command
 * @param args    Arguments (Optional)
 * @note          For some reason, the command's original flags cannot be restored without a delay (whence the timer)
 */
stock void CheatCommand(const char[] command, const char[] args = "")
{
    int oldFlags = GetCommandFlags(command);

    if (oldFlags != INVALID_FCVAR_FLAGS)
    {
        if (SetCommandFlags(command, oldFlags & ~FCVAR_CHEAT))
        {
            char fullCommand[256];
            
            if (args[0] != '\0')
                Format(fullCommand, sizeof(fullCommand), "%s %s", command, args);
            else
                strcopy(fullCommand, sizeof(fullCommand), command);

            ServerCommand(fullCommand);

            DataPack pack = new DataPack();

            pack.WriteString(command);
            pack.WriteCell(oldFlags);

            CreateTimer(0.1, Timer_CheatCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_CheatCommand(Handle timer, any data)
{
    DataPack pack = view_as<DataPack>(data);

    pack.Reset();
    char command[256];

    pack.ReadString(command, sizeof(command));
    int oldFlags = pack.ReadCell();

    SetCommandFlags(command, oldFlags);

    delete pack;
    return Plugin_Stop;
}

/**
 * Returns the human client count in the server.
 *
 * @param inGameOnly    If false connecting players are also counted.
 * @return              Human client count in the server.
 */
stock int GetHumanClientCount(bool inGameOnly=true)
{
    int botCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsFakeClient(i))
            botCount++;
    }

    return GetClientCount(inGameOnly) - botCount;
}

/**
 * Check if the current game mode is "perma-death" (i.e. Arena Mode, Versus Saxton Hale, ...).
 * 
 * @return True if the current game mode is Arena Mode or Sudden Death.
 */
stock bool IsPermaDeathMode()
{
    return IsGameMode("arena") || GameRules_GetProp("m_iRoundState") == 7;
}