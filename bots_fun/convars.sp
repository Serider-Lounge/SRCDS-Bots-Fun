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
            //RCBot2_CreateBot("");
            ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : ""); // Add RCBots this way instead due to a bug where 'rcbot_change_classes' isn't respected.
        }
    }
}