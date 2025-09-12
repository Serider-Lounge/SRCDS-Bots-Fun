/**
 * https://github.com/APGRoboCop/rcbot2
 */
#undef REQUIRE_EXTENSIONS
#include <rcbot2>
#define REQUIRE_EXTENSIONS

/**
 * Kick all RCBot2 clients.
 */
stock void RCBot2_KickAllBots(bool rejoin=true)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsRCBot2Client(i))
        {
            KickClient(i);
            if (rejoin) RCBot2_CreateBot("");
        }
    }
}

/**
 * In fill mode, enforce bot quota.
 */
stock void RCBot2_UpdateBotQuota(int client)
{
    GetConVarString(g_ConVars[rcbot_bot_quota_mode], g_strRCBotQuotaMode, sizeof(g_strRCBotQuotaMode));
    if (strcmp(g_strRCBotQuotaMode, "fill") == 0)
    {
        int quota = g_ConVars[rcbot_bot_quota].IntValue;
        int humanCount = 0;
        int rcbotCount = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientObserver(i))
                humanCount++;

            if (IsRCBot2Client(i))
                rcbotCount++;
        }
        
        while ((humanCount + rcbotCount) < quota)
        {
            //RCBot2_CreateBot("");
            ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : ""); // Add RCBots this way instead due to a bug where 'rcbot_change_classes' isn't respected.
            rcbotCount++;
            if ((humanCount + rcbotCount) == quota)
            break;
        }

        while ((humanCount + rcbotCount) > quota)
        {
            bool kicked = false;
            for (int i = 1; i <= MaxClients; i++)
            {
            if (IsRCBot2Client(i) && GetClientTeam(i) == GetClientTeam(client))
            {
                KickClient(i);
                rcbotCount--;
                kicked = true;
                break;
            }
            }
            if (!kicked) break;
        }

        /* Prints */
        //CPrintToChat(client, "[{red}%s{default}] {unusual}RCBots{default}: {lightgreen}%d", PLUGIN_NAME, rcbotCount);
        //CPrintToChat(client, "[{red}%s{default}] {olive}Humans{default}: {lightgreen}%d", PLUGIN_NAME, humanCount);
        //CPrintToChat(client, "[{red}%s{default}] {unique}Total Players{default}: {lightgreen}%d", PLUGIN_NAME, totalPlayers);
        //CPrintToChat(client, "[{red}%s{default}] {common}Quota{default}: {lightgreen}%d", PLUGIN_NAME, quota);
    }
}