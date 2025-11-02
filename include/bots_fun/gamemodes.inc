/**
 * This function is used to check for game mode logic entities.
 * 
 * @param  gamemode tf_logic_<gamemode> (e.g., "player_destruction" for "tf_logic_player_destruction")
 * @return          True if the entity is found
 */
stock bool TF2_IsGameMode(const char[] gamemode)
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
stock bool TF2_IsPermaDeathMode()
{
    return g_ConVars[humans_only].BoolValue &&
           (TF2_IsGameMode("arena") || GameRules_GetProp("m_iRoundState") == 7);
}

/**
 * Check if the game mode is VScript-based.
 * This prevents the plugin from interfering with VScript equivalents of VIP mode.
 * @param		path		Name of the vscript file
 * @return 					True if the vscript file exists
 */
stock bool VScriptExists(char path[PLATFORM_MAX_PATH]) {
	Format(path, sizeof(path), "scripts/vscripts/%s.nut", path);
	File file = OpenFile(path, "r", true);
	if (file != null) {
		CloseHandle(file);
		return true;
	}
	return false;
}