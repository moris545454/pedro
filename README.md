# FiveM Pet Companion

Simple FiveM pet companion script with basic commands.

## Installation
1. Drop this resource folder into your server resources directory.
2. Add `ensure pedro` (or the folder name) to your `server.cfg`.

## Commands
- `/pet spawn [model]` - spawn pet (defaults to shepherd).
- `/pet follow` - pet follows you.
- `/pet stay` - pet stays.
- `/pet dismiss` - remove pet.
- `/pet ui` - open the pet control UI.
- `/pet feed` - restore hunger.
- `/pet heal` - restore pet health.
- `/pet rename [name]` - rename your pet.
- `/pet whistle` - recall pet to your location.
- `/pet play` - boost affection at the cost of stamina.
- `/pet trick [sit|bark|beg]` - perform a trick.

## Allowed models
Configured in `config.lua` under `Config.AllowedModels`.

## Pet progression
Stats and XP/level settings live in `config.lua` (`StatDecayIntervalMs`, `XPPerAction`, `LevelThresholds`, etc.).
