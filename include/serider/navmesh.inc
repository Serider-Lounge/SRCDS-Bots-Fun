#include <sdktools>

/**
 * Get the amount of navigation areas.
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
 * @param  strip_workshop_prefix Whether to strip "workshop/" from the start of the map name
 * @return                       True if GetNavAreaCount() > 0 or <mapname>.nav is present
 */
stock bool NavMesh_IsLoaded(bool strip_workshop_prefix=true)
{
    char mapName[PLATFORM_MAX_PATH];
    GetCurrentMap(mapName, sizeof(mapName));
    if (strip_workshop_prefix && StrContains(mapName, "workshop/", false) == 0)
        strcopy(mapName, sizeof(mapName), mapName[9]);

    char navPath[PLATFORM_MAX_PATH];
    Format(navPath, sizeof(navPath), "maps/%s.nav", mapName);

    Handle navFile = OpenFile(navPath, "r", true);

    bool navFileExists = (navFile != INVALID_HANDLE);
    CloseHandle(navFile);

    return NavMesh_GetNavAreaCount() > 0 ||
           navFileExists;
}