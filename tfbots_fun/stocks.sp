// CLIENTS
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

// GAMEMODES
/**
 * This function is used to check for VScript-based game modes.
 * @param  path Game mode's core VScript file (without .nut)
 * @return      True if the file is present 
 */
stock bool isVScript(const char[] path)
{
    char filePath[PLATFORM_MAX_PATH];
    Format(filePath, sizeof(filePath), "scripts/vscripts/%s.nut", path);
    File file = OpenFile(filePath, "r", true);

    if (file != null)
    {
        CloseHandle(file);
        return true;
    }
    return false;
}

/**
 * This function is used to check for game mode logic entities.
 * @param  gamemode tf_logic_<gamemode> (e.g., "player_destruction" for "tf_logic_player_destruction")
 * @return          True if the entity is found
 */
stock bool isGameMode(const char[] gamemode)
{
    char entity[64];
    Format(entity, sizeof(entity), "tf_logic_%s", gamemode);
    return FindEntityByClassname(-1, entity) != -1;
}