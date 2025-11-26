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
        int humanCount = 0;
        int navbotCount = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1) // Only count humans on a team
                humanCount++;
            if (NavBotManager.IsNavBot(i) && GetClientTeam(i) > 1) // Only count bots on a team
                navbotCount++;
        }

        int botsToAdd = quota - (humanCount + navbotCount);

        for (int i = 0; i < botsToAdd; i++)
        {
            if ((humanCount + navbotCount) >= quota)
                break;

            NavBot bot = NavBot();
            if (!bot.IsNull)
                navbotCount++;
        }

        int botsToKick = navbotCount - (quota - humanCount);
        while (botsToKick > 0)
        {
            bool kicked = false;
            for (int i = 1; i <= MaxClients; i++)
            {
                if (NavBotManager.IsNavBot(i) && !IsPlayerAlive(i) && GetClientTeam(i) > 1)
                {
                    KickClient(i);
                    navbotCount--;
                    botsToKick--;
                    kicked = true;
                    break;
                }
            }
            if (!kicked)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (NavBotManager.IsNavBot(i) && GetClientTeam(i) > 1)
                    {
                        KickClient(i);
                        navbotCount--;
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