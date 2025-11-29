public void ConVar_BotRatio(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

public void ConVar_RCBotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
    int value = StringToInt(newValue);

    int rcbots = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsRCBot2Client(i))
        {
            rcbots++;
        }
    }

    for (int i = 1; i <= MaxClients && rcbots > value; i++)
    {
        if (IsRCBot2Client(i))
        {
            KickClient(i);
            rcbots--;
        }
    }

    for (int i = rcbots; i < value; i++)
    {
        ServerCommand("rcbot%s addbot", IsDedicatedServer() ? "d" : "");
    }
}

public void ConVar_NavBotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
    int value = StringToInt(newValue);

    int navbots = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (NavBotManager.IsNavBot(i))
        {
            navbots++;
        }
    }

    for (int i = 1; i <= MaxClients && navbots > value; i++)
    {
        if (NavBotManager.IsNavBot(i))
        {
            KickClient(i);
            navbots--;
        }
    }

    for (int i = navbots; i < value; i++)
    {
        ServerCommand("sm_navbot_add");
    }
}