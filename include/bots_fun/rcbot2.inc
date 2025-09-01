#undef REQUIRE_EXTENSIONS
#include <rcbot2> // https://github.com/APGRoboCop/rcbot2
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
stock void RCBot2_EnforceBotQuota(int client)
{
    GetConVarString(g_ConVarRCBotQuotaMode, g_strRCBotQuotaMode, sizeof(g_strRCBotQuotaMode));
    if (strcmp(g_strRCBotQuotaMode, "fill") == 0)
    {
        /* Counters */
        // RCBots
        int rcbot = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsRCBot2Client(i))
                rcbot++;
        }

        // Humans
        int humanCount = GetHumanClientCount(_, true);

        // Total Players
        int total = rcbot + humanCount;

        /* Enforce */
        int quota = g_ConVarRCBotQuota.IntValue;
        while (total < quota)
        {
            RCBot2_CreateBot("");
                total++;
        }

        while (total > quota)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsRCBot2Client(i) && GetClientTeam(i) == GetClientTeam(client))
                {
                    KickClient(i);
                    total--;
                    break;
                }
            }
        }

        /* Prints */
        CPrintToChat(client, "[{red}%s{default}] {unusual}RCBots{default}: {lightgreen}%d", PLUGIN_NAME, rcbot);
        CPrintToChat(client, "[{red}%s{default}] {olive}Humans{default}: {lightgreen}%d", PLUGIN_NAME, humanCount);
        CPrintToChat(client, "[{red}%s{default}] {unique}Total Players{default}: {lightgreen}%d", PLUGIN_NAME, total);
        CPrintToChat(client, "[{red}%s{default}] {common}Quota{default}: {lightgreen}%d", PLUGIN_NAME, quota);
    }
}