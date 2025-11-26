public void LoadPluginConfig()
{
    if (g_hConfigTrie != INVALID_HANDLE)
    {
        CloseHandle(g_hConfigTrie);
    }
    g_hConfigTrie = CreateTrie();

    KeyValues kv = new KeyValues("Config");
    if (!kv.ImportFromFile(PLUGIN_CONFIG))
    {
        PrintToServer("[%s] Failed to load 'bots_fun.cfg'", PLUGIN_NAME);
        delete kv;
        return;
    }

    if (kv.JumpToKey("Bot Names"))
    {
        if (kv.GotoFirstSubKey(false))
        {
            do
            {
                char model[64], botName[128];
                kv.GetSectionName(model, sizeof(model));
                kv.GetString(NULL_STRING, botName, sizeof(botName), "");
                if (model[0] && botName[0])
                {
                    SetTrieString(g_hConfigTrie, model, botName, true);
                }
            } while (kv.GotoNextKey(false));
            kv.GoBack();
        }
    }
    delete kv;
}

public bool GetBotName(const char[] path, char[] buffer, int maxlen)
{
    if (g_hConfigTrie == INVALID_HANDLE)
        return false;

    char mdl[PLATFORM_MAX_PATH];
    Regex regex = new Regex("[^/\\\\]+(?=\\.[^./\\\\]+$)", PCRE_CASELESS);
    if (!regex)
        return false;

    if (regex.Match(path) > 0)
    {
        regex.GetSubString(0, mdl, sizeof(mdl));
    }
    else
    {
        delete regex;
        return false;
    }
    delete regex;

    return GetTrieString(g_hConfigTrie, mdl, buffer, maxlen);
}