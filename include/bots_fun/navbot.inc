#undef REQUIRE_EXTENSIONS
#include <navbot>

/**
 * In fill mode, enforce navbot quota.
 */
stock void NavBot_UpdateBotQuota()
{
    GetConVarString(g_ConVars[navbot_bot_quota_mode], g_NavBotQuotaMode, sizeof(g_NavBotQuotaMode));
    if (strcmp(g_NavBotQuotaMode, "fill") == 0)
    {
        int quota = g_ConVars[navbot_bot_quota].IntValue;
        int humans = 0;
        int navbots = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
                humans++;
            if (NavBotManager.IsNavBot(i) && GetClientTeam(i) > 1)
                navbots++;
        }

        int desiredBots = quota - humans;
        while (navbots <= desiredBots)
        {
            ServerCommand("sm_navbot_add");
        }

        for (int i = 1; i <= MaxClients && navbots > desiredBots; i++)
        {
            if (NavBotManager.IsNavBot(i) && GetClientTeam(i) > 1)
            {
                KickClient(i);
                navbots--;
            }
        }
    }
}