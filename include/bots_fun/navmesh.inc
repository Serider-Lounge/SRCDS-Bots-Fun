#include <sdktools>

/**
 * Get the amount of navigation areas.
 * 
 * @return Store NavMesh.GetNavAreaCount()'s output
 */
stock int NavMesh_GetNavAreaCount()
{
    int ent = CreateEntityByName("info_target");

    SetVariantString("NetProps.SetPropInt(self, \"m_spawnflags\", NavMesh.GetNavAreaCount())");
    AcceptEntityInput(ent, "RunScriptCode");

    int areaCount = GetEntProp(ent, Prop_Data, "m_spawnflags");
        
    RemoveEntity(ent);
    return areaCount;
}

/**
 * Check if navigation meshes are present.
 * 
 * @return True if GetNavAreaCount() > 0
 */
stock bool NavMesh_IsLoaded()
{
    return NavMesh_GetNavAreaCount() > 0;
}

/**
 * Check if <mapname>.nav exists.
 * 
 * @return True if <mapname>.nav is present
 */
stock bool NavMesh_FileExists()
{
    char mapName[PLATFORM_MAX_PATH];
    GetCurrentMap(mapName, sizeof(mapName));
    
    char navPath[PLATFORM_MAX_PATH];
    Format(navPath, sizeof(navPath), "maps/%s.nav", mapName);

    Handle file = OpenFile(navPath, "r", true);

    bool fileExists = (file != INVALID_HANDLE);
    CloseHandle(file);

    return fileExists;
}