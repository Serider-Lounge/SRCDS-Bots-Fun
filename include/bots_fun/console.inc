/**
 * Execute a cheat command without having to enable sv_cheats.
 * 
 * @param command Console command
 * @param args    Arguments (Optional)
 * @note          For some reason, the command's original flags cannot be restored without a delay (whence the timer)
 */
stock void CheatCommand(const char[] command, const char[] args="")
{
    int oldFlags = GetCommandFlags(command);

    if (oldFlags != INVALID_FCVAR_FLAGS)
    {
        if (SetCommandFlags(command, oldFlags & ~FCVAR_CHEAT))
        {
            char fullCommand[256];
            
            if (args[0] != '\0')
                Format(fullCommand, sizeof(fullCommand), "%s %s", command, args);
            else
                strcopy(fullCommand, sizeof(fullCommand), command);

            ServerCommand(fullCommand);

            DataPack pack = new DataPack();

            pack.WriteString(command);
            pack.WriteCell(oldFlags);

            CreateTimer(0.1, Timer_CheatCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_CheatCommand(Handle timer, any data)
{
    DataPack pack = view_as<DataPack>(data);

    pack.Reset();
    char command[256];

    pack.ReadString(command, sizeof(command));
    int oldFlags = pack.ReadCell();

    SetCommandFlags(command, oldFlags);

    delete pack;
    return Plugin_Stop;
}