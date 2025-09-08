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
        int humanCount = GetHumanClientCount();
        int rcbotCount = 0;
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsRCBot2Client(i))
                rcbotCount++;
        }

        int totalPlayers = humanCount + rcbotCount;

        if (totalPlayers < quota)
        {
            int botsToAdd = quota - totalPlayers;
            for (int i = 0; i < botsToAdd; i++)
            {
                RCBot2_CreateBot("");
            }
        }
        else if (totalPlayers > quota)
        {
            int botsToRemove = totalPlayers - quota;
            for (int i = 1; i <= MaxClients && botsToRemove > 0; i++)
            {
                if (IsRCBot2Client(i) && GetClientTeam(i) == GetClientTeam(client))
                {
                    KickClient(i);
                    botsToRemove--;
                }
            }
        }

        /* Prints */
        //CPrintToChat(client, "[{red}%s{default}] {unusual}RCBots{default}: {lightgreen}%d", PLUGIN_NAME, rcbotCount);
        //CPrintToChat(client, "[{red}%s{default}] {olive}Humans{default}: {lightgreen}%d", PLUGIN_NAME, humanCount);
        //CPrintToChat(client, "[{red}%s{default}] {unique}Total Players{default}: {lightgreen}%d", PLUGIN_NAME, totalPlayers);
        //CPrintToChat(client, "[{red}%s{default}] {common}Quota{default}: {lightgreen}%d", PLUGIN_NAME, quota);
    }
}