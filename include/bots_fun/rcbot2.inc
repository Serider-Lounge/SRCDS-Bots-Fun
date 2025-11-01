/**
 * https://github.com/APGRoboCop/rcbot2
 */
#undef REQUIRE_EXTENSIONS
#include <rcbot2>
#define REQUIRE_EXTENSIONS

/**
 * In fill mode, enforce rcbot quota.
 */
stock void RCBot2_UpdateBotQuota(int client)
{
    GetConVarString(g_ConVars[rcbot_bot_quota_mode], g_RCBotQuotaMode, sizeof(g_RCBotQuotaMode));
    if (strcmp(g_RCBotQuotaMode, "fill") == 0)
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
            ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : ""); // Add RCBots this way instead due to a bug where 'rcbot_change_classes' isn't respected.
            rcbotCount++;
            if ((humanCount + rcbotCount) == quota) break;
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
    }
}