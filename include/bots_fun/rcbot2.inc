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
        int humans = 0;
        int rcbots = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
                humans++;
            if (IsRCBot2Client(i) && GetClientTeam(i) > 1)
                rcbots++;
        }

        int desiredBots = quota - humans;
        while (rcbots <= desiredBots)
        {
            ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : "");
            rcbots++;
        }

        for (int i = 1; i <= MaxClients && rcbots > desiredBots; i++)
        {
            if (IsRCBot2Client(i) && GetClientTeam(i) > 1)
            {
                KickClient(i);
                rcbots--;
            }
        }
    }
}