public void ConVar_BotRatio(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

public void ConVar_RCBotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
    int value = StringToInt(newValue);

    int rcbotCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsRCBot2Client(i))
        {
            rcbotCount++;
        }
    }

    if (value < rcbotCount)
    {
        for (int i = 1; i <= MaxClients && rcbotCount > value; i++)
        {
            if (IsRCBot2Client(i))
            {
                KickClient(i);
                rcbotCount--;
            }
        }
    }
    else if (value > rcbotCount)
    {
        for (int i = rcbotCount; i < value; i++)
        {
            ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : ""); // Add RCBots this way instead due to a bug where 'rcbot_change_classes' isn't respected.
        }
    }
}

public void ConVar_NavBotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
    int value = StringToInt(newValue);

    int navbotCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (NavBotManager.IsNavBot(i))
        {
            navbotCount++;
        }
    }

    if (value < navbotCount)
    {
        for (int i = 1; i <= MaxClients && navbotCount > value; i++)
        {
            if (NavBotManager.IsNavBot(i))
            {
                KickClient(i);
                navbotCount--;
            }
        }
    }
    else if (value > navbotCount)
    {
        for (int i = navbotCount; i < value; i++)
        {
            NavBot();
        }
    }
}