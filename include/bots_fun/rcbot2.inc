/**
 * https://github.com/APGRoboCop/rcbot2
 */
#undef REQUIRE_EXTENSIONS
#include <rcbot2>

/**
 * In fill mode, enforce rcbot quota.
 */
stock void RCBot2_UpdateBotQuota()
{
    GetConVarString(g_ConVars[rcbot_bot_quota_mode], g_RCBotQuotaMode, sizeof(g_RCBotQuotaMode));
    if (strcmp(g_RCBotQuotaMode, "fill") == 0)
    {
        int quota = g_ConVars[rcbot_bot_quota].IntValue;
        int humanCount = 0;
        int rcbotCount = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1) // Only count humans on a team
                humanCount++;
            if (IsRCBot2Client(i) && GetClientTeam(i) > 1) // Only count bots on a team
                rcbotCount++;
        }

        int botsToAdd = quota - (humanCount + rcbotCount);

        for (int i = 0; i < botsToAdd; i++)
        {
            if ((humanCount + rcbotCount) >= quota)
                break;
            ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : "");
            rcbotCount++;
        }

        int botsToKick = rcbotCount - (quota - humanCount);
        while (botsToKick > 0)
        {
            bool kicked = false;
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsRCBot2Client(i) && !IsPlayerAlive(i) && GetClientTeam(i) > 1)
                {
                    KickClient(i);
                    rcbotCount--;
                    botsToKick--;
                    kicked = true;
                    break;
                }
            }
            if (!kicked)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsRCBot2Client(i) && GetClientTeam(i) > 1)
                    {
                        KickClient(i);
                        rcbotCount--;
                        botsToKick--;
                        kicked = true;
                        break;
                    }
                }
            }
            if (!kicked) break;
        }
    }
}