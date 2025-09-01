# [TF2/ANY?] Bots Fun ([RCBot2](https://github.com/APGRoboCop/rcbot2) Support‼)
# Why?

I host a TF2 server with a **LOT** of maps and gamemodes, but here's the deal: they don't _all_ support bots.<br>
So what about the maps that _did_ support bots, then? Well, there were a few issues:<br>

- I had to manually set `tf_bot_quota` and `tf_bot_quota_mode fill` whenever needed.
  - And remove bots on maps that do not support bots, so they don't needlessly take up player slots (because they'd just be standing still).
- I don't always know whether a map supports bots or not.
- **TFBots** kind of suck— they do the job, but they're only supported in a handful of gamemodes, and they're a bit too dumb for my own liking as well.
- I found out about [*RCBot2*](https://github.com/APGRoboCop/rcbot2), but I don't want to manually alternate between **RCBots** and **TFBots** depending on whether waypoints or navmeshes are available.

> [!NOTE]
> Despite the integration of [*RCBot2*](https://github.com/APGRoboCop/rcbot2), this has primarily been made for, and tested in, [*Team Fortress 2*](https://store.steampowered.com/app/440/Team_Fortress_2).
> ###### There might be support for other games, but no promise.

# So, what does this plugin do?
## Auto-Joining
This plugin automatically adds/removes bots for you depending on the map. Here's a table to explain this better:

| File Type                                                        | Result                |
|------------------------------------------------------------------|-----------------------|
| `addons/rcbot2/waypoints/<modname>/<mapname>.rcw` (Waypoint)     | Spawn RCbots.         |
| `maps/<mapname>.nav` (Nav. Mesh)                                 | Spawn TFBots.         |
| *No bot paths available...*                                      | All bots are removed. |

The priority order is: **RCBot** > **TFBot** > ***None***.<br>
Bot join/leave messages don't show up in chat to prevent spam.<br>

> [!NOTE]
> In [Mann Vs. Machine](https://wiki.teamfortress.com/wiki/Mann_vs._Machine), the **RCBot** quota will use `tf_mvm_defenders_team_size`'s value and won't go past `10`. I'll make this configurable in the future— but now, I'm too lazy to implement it xd.

## Auto-Renaming
The bots will pick a name depending on their player model (e.g. `models/player/scout.mdl` → `Scout`).<br>
This is all configurable in [`addons/sourcemod/configs/bots_fun.cfg`](https://github.com/Serider-Lounge/SRCDS-Bots-Fun/blob/main/configs/bots_fun.cfg).<br>

## Commands
| Name                        | Description                                                      |
|-----------------------------|------------------------------------------------------------------|
| `sm_nav_info`               | Displays information about bot support.                          |
| `sm_nav_generate`           | Executes `nav_generate` without having to enable `sv_cheats`.    |
| `sm_nav_generate_incremental` | Executes `nav_generate_incremental` without having to enable `sv_cheats`. |

## ConVars
> ### `cfg/sourcemod/bots_fun.cfg`

| Name                | Default   | Description                                         |
|---------------------|-----------|-----------------------------------------------------|
| `sm_bot_enabled`    | `1`       | Toggle the plugin.                                  |
| `sm_bot_ratio`      | `0.25`    | Ratio of bots to max players (0.0 – 1.0).           |
| `rcbot_bot_quota`   | `0`       | Determines the total number of rcbots in the game.  |
| `rcbot_bot_quota_mode` | `normal` | Type of quota: `normal` or `fill`.                  |
