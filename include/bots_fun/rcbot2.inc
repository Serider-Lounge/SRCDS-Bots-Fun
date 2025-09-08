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
    GetConVarString(g_ConVarRCBotQuotaMode, g_strRCBotQuotaMode, sizeof(g_strRCBotQuotaMode));
    if (strcmp(g_strRCBotQuotaMode, "fill") == 0)
    {
        int quota = g_ConVarRCBotQuota.IntValue;
        int humanCount = GetHumanClientCount(false); // Count all in-game humans
        int rcbotCount = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsRCBot2Client(i))
                rcbotCount++;
        }

        while ((humanCount + rcbotCount) < quota)
        {
            RCBot2_CreateBot("");
            rcbotCount++;
            if ((humanCount + rcbotCount) == quota)
                break;
        }

        int clientTeam = GetClientTeam(client);
        int tries = 0; // Prevent infinite loop
        while ((humanCount + rcbotCount) > quota && tries < MaxClients)
        {
            bool kicked = false;
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsRCBot2Client(i) && GetClientTeam(i) == clientTeam)
                {
                    KickClient(i);
                    rcbotCount--;
                    kicked = true;
                    break;
                }
            }
            tries++;
            if (!kicked) break; // No more bots to kick from this team
        }

        /* Prints */
        //CPrintToChat(client, "[{red}%s{default}] {unusual}RCBots{default}: {lightgreen}%d", PLUGIN_NAME, rcbotCount);
        //CPrintToChat(client, "[{red}%s{default}] {olive}Humans{default}: {lightgreen}%d", PLUGIN_NAME, humanCount);
        //CPrintToChat(client, "[{red}%s{default}] {unique}Total Players{default}: {lightgreen}%d", PLUGIN_NAME, totalPlayers);
        //CPrintToChat(client, "[{red}%s{default}] {common}Quota{default}: {lightgreen}%d", PLUGIN_NAME, quota);
    }
}