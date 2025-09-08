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
 * Check if the current game mode is "perma-death" (i.e. no respawns).
 * 
 * @return True if the current game mode is Arena Mode or Sudden Death.
 */
stock bool IsPermaDeathMode()
{
    return g_ConVars[humans_only].BoolValue &&
           (IsGameMode("arena") || GameRules_GetProp("m_iRoundState") == 7);
}