# [TF2/ANY?] Bots Fun (w/ [RCBot2](https://github.com/APGRoboCop/rcbot2) Support‼)
### Combine this with [<img src="https://avatars.githubusercontent.com/u/10157643" alt="@caxanga334" width="16" height="16" style="vertical-align:middle; border-radius:3px;"/> caxanga334](https://github.com/caxanga334)'s [Bot Auto-Balance](https://github.com/caxanga334/sm-plugins/actions) plugin‼
# Why?
### [@Heapons](https://github.com/Heapons)
We host a TF2 server with a **LOT** of maps and gamemodes, but here's the deal: they don't _all_ support bots.<br>
So what about the maps that _do_ support bots, then? Well, there were few issues such as:</br>
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

| Type                        | Result                |
|-----------------------------|-----------------------|
| Waypoint                    | Spawn RCbots.         |
| Valve Nav. Mesh             | Spawn TFBots.         |
| *No bot paths available...* | All bots are removed. |

The priority order is: **RCBot** > **TFBot** > ***None***.<br>
Bot join/leave messages don't show up in chat to prevent spam.<br>

> [!NOTE]
> In [Mann Vs. Machine](https://wiki.teamfortress.com/wiki/Mann_vs._Machine), the **RCBot** quota will use `tf_mvm_defenders_team_size`'s value instead of `sm_bot_ratio` or `rcbot_bot_quota`.

## Auto-Renaming
The bots will pick a name depending on their player model (e.g. `models/player/scout.mdl` → `Scout`).<br>
This is all configurable in [`addons/sourcemod/configs/bots_fun.cfg`](https://github.com/Serider-Lounge/SRCDS-Bots-Fun/blob/main/configs/bots_fun.cfg).<br>

## Arena Mode / Sudden Death
When all **humans** have died, the round ends pre-maturely so players won't have to sit and wait until bots are done.

## Commands
| Name                          | Description                                                               |
|-------------------------------|---------------------------------------------------------------------------|
| `sm_nav_info`                 | Displays information about bot support.                                   |
| `sm_nav_generate`             | Executes `nav_generate` without having to enable `sv_cheats`.             |
| `sm_nav_generate_incremental` | Executes `nav_generate_incremental` without having to enable `sv_cheats`. |

## ConVars
> ### `cfg/sourcemod/bots_fun.cfg`

| Name                   | Default   | Description                                                                                       |
|------------------------|-----------|---------------------------------------------------------------------------------------------------|
| `sm_bot_enabled`       | `1`       | Toggle the plugin.                                                                                |
| `sm_bot_ratio`         | `0.25`    | Ratio of bots to max players (0.0 – 1.0).                                                         |
| `rcbot_bot_quota`      | `0`       | Determines the total number of rcbots in the game.                                                |
| `rcbot_bot_quota_mode` | `normal`  | Type of quota: `normal` or `fill`.                                                                |
| `sm_bot_humans_only`   | `1`       | Whether to end the round prematurely if all human players are dead in Arena Mode or Sudden Death. |
| `sm_bot_rename_bots`   | `1`       | If enabled, bots will be renamed based on their player model.                                     |=
