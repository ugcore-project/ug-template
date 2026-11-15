---
name: ug-core-api
description: Reference of the ug-core and ug-lib APIs a UgCore resource can call - namespaces, functions, enums, events, hooks, statebags and error codes. Use when you need to know what exists before writing code against UgCore.
---

# ug-core and ug-lib API

This is a map, not the contract. Before calling a function, read its LuaLS annotations in the source
(`../ug-core`, `../ug-lib`) or the docs at https://ugcore.urging.ch. Never invent a function that is not listed in
the source. When this list and the source differ, the source wins: update this file.

## Calling conventions

- Mutating functions return `ok, value, errorCode` or `ok, errorCode`. Check `ok` every time.
- Error codes are `UgCore.Enums.Errors`: `InvalidArgs`, `NotFound`, `NotLoaded`, `RateLimited`, `NoPermission`,
  `InsufficientFunds`, `InsufficientItems`, `CannotCarry`, `Timeout`, `InternalError`.
- Wrong usage (a bad argument type, an unknown option) raises with a message that points to your line.
- Module namespaces exist only when the owner enabled the module. A disabled one raises when touched. Check
  `UgCore.Modules.IsEnabled('<module>')` before using an optional module.
- Read-heavy player data (job, gang, duty, death state, loaded) comes from statebags, not exports. Exports copy tables
  on every call.

## UgCore: core (always there)

| Namespace | Side | Functions |
| --- | --- | --- |
| `Enums` | both | `Lifecycle`, `Events.<Group>`, `Hooks.<Group>`, `Errors`, `Violations`, `ViolationWeights`, `StateBags`, `GlobalState`, `DeathState`, `BodyRegion`, `DamageCategory`, plus module groups |
| `Lifecycle` | both | `GetState`, `IsReady`, `HasReached`, `On(state, fn)` (sticky), `Await(state, timeout?)` |
| `Events` | both | `On(name, fn) -> id`, `Once`, `Off(id)`, `Emit(name, ...)`. Local, same side only. Your events MUST start with your resource name. |
| `Config` | both | `Get(name, key?)` deep copy. Clients see `client` and `shared` values only. |
| `Logger` | both | `Debug`, `Info`, `Warn`, `Error`, with `%` format arguments. Debug shows when `core.debug` is on. |
| `Version` | both | `Get`, `IsAtLeast(min)`, `Require(min)` |
| `Modules` | both | `IsEnabled(name)`, `GetEnabled()`, `Require(name)` |
| `Schema` | both | `String`, `Number`, `Integer`, `Boolean`, `Vector2/3/4`, `Enum`, `Array`, `Map`, `Object`, `Optional`, `Define`, `Validate`, `Check` |
| `RateLimit` | server | `Create({ max, per })`, then `limiter:Consume(key) -> allowed, retryAfter`, `Reset`, `Prune`, `Clear` |
| `Guard` | server | `Flag(source, violation, detail?)`, `GetScore(source)`, `IsNear(source, coords, maxDistance)` |
| `Callback` | both | Server: `Register(name, options, fn)`, `Unregister`, `Await(source, fullName, { schema, timeout? }, ...)`, `Trigger`. Client: `Await(fullName, ...) -> ok, value, errorCode`, `Trigger`, `Register`, `Unregister`. |
| `Network` | both | Server: `Register(name, options, fn)`, `TriggerClient(source, fullName, ...)`, `TriggerClients(fullName, ...)`. Client: `Register(name, fn)`, `TriggerServer(fullName, ...)`. |
| `Hooks` | server | `Register(hookName, fn, { priority? }) -> id`, `Unregister(id)`. Return `false` to cancel, a table to replace the payload. |

Callback and net event options: `schema` (required), `rate` (required), `requirePlayer`, `requireAlive`, `permission`.

## UgCore: modules

Required modules are always on. The rest are enabled by the owner in ug-core's `config/modules.lua`.

| Module | Namespace | Server | Client |
| --- | --- | --- | --- |
| identity (required) | `Identity` | `GetIdentifiers`, `GetPrimary`, `IsBanned`, `Ban`, `Unban` | |
| players (required) | `Players` / `LocalPlayer` | `Get`, `GetAll`, `GetByIdentifier`, `GetByCharacterId`, `GetMetadata`, `SetMetadata`, `Kick`, `GetDeathState`, `IsDead`, `IsDowned`, `GetInjuries`, `GetCauseOfDeath`, `ClearInjuries`, `Down`, `Kill`, `Revive`, `Respawn` | `GetData`, `IsLoaded`, `GetMetadata`, `GetDeathState`, `IsDead`, `IsDowned`, `GetInjuries` |
| permissions (required) | `Permissions` | `Has`, `Grant`, `Revoke`, `GetAll`, `AddGroup`, `RemoveGroup`, `IsInGroup`, `GetGroups`, `GetGroupDefinition`, `GetWeight`, `CanTarget` | |
| characters | `Characters` | `Create`, `Delete`, `Load`, `Unload`, `GetAll`, `GetActive`, `GetPosition` | |
| accounts | `Accounts` | `GetBalance`, `GetAll`, `Add`, `Remove`, `Set`, `Transfer`, `GetLedger` | `GetBalance`, `GetAll` |
| jobs | `Jobs` | `Get`, `Set`, `SetGrade`, `SetDuty`, `IsOnDuty`, `Exists`, `GetDefinition` | `Get`, `IsOnDuty` |
| gangs | `Gangs` | `Get`, `Set`, `SetGrade`, `Exists`, `GetDefinition` | `Get` |
| sessions | `Sessions` | `Create`, `Destroy`, `Join`, `Leave`, `Get`, `GetMembers`, `GetSession` | |
| commands | `Commands` | `Register(name, options, fn)`, `GetAll`, `CanUse` | |
| needs | `Needs` | `Get`, `GetAll`, `Set`, `Add`, `Remove`, `Reset` | `Get`, `GetAll` |
| items | `Items` | `Register`, `RegisterUse`, `Exists`, `Get`, `GetAll`, `IsUsable` | `Exists`, `Get`, `GetAll` |
| inventory | `Inventory` | `AddItem`, `RemoveItem`, `RemoveFromSlot`, `HasItem`, `Count`, `CanCarry`, `GetItems`, `GetSlot`, `SetMetadata`, `Move`, `Use`, `Open`, `Close`, `GetOpen`, `Clear`, `Load`, `RegisterStash`, `GetStash`, `GetStashId`, `CreateDrop`, `GetDrops`, `Get`, `GetSource`, `GetLog`, `SetPersistent` | `Open`, `Close`, `GetItems`, `GetSlot`, `GetSlots`, `Count`, `HasItem`, `GetWeight`, `GetMaxWeight`, `GetOther`, `Move`, `MoveBetween`, `Use`, `Give`, `Drop`, `GetDrops`, `IsLoaded`, `Refresh` |
| shops | `Shops` | `Register`, `Get`, `GetAll`, `Buy`, `Restock` | `GetAll`, `Open`, `Buy` |
| weapons | `Weapons` | `Equip`, `Unequip`, `GetEquipped`, `Reload`, `Unload`, `Attach`, `Detach`, `Repair`, `GetBySerial`, `GetDefinition`, `IsWeapon` | `Equip`, `Unequip`, `GetEquipped`, `Reload`, `Unload`, `Attach`, `Detach` |
| locale | `Locale` | `Get`, `GetCode` | |

## Events (`UgCore.Enums.Events.<Group>.<Key>`)

Listen with `UgCore.Events.On(UgCore.Enums.Events.Accounts.Changed, fn)`. ug-core drops `ug-core:*` events that
another resource tried to fake.

- `Lifecycle`: `Changed`, `Ready`, `Stopping`
- `Players`: `Loaded`, `Injured`, `Downed`, `Died`, `Revived`, `Respawned`, `DeathStateChanged`
- `Guard`: `Flagged`
- `Characters`: `Created`, `Deleted`, `Loaded`, `Unloaded`
- `Accounts`: `Changed`
- `Jobs`: `Changed`, `DutyChanged`. `Gangs`: `Changed`
- `Permissions`: `GroupAdded`, `GroupRemoved`
- `Sessions`: `Created`, `Destroyed`, `Joined`, `Left`
- `Needs`: `Changed`. `Commands`: `Failed`
- `Items`: `Used`. `Inventory`: `ItemAdded`, `ItemRemoved`, `Changed`, `Opened`, `Closed`
- `Shops`: `Purchased`. `Weapons`: `Equipped`, `Unequipped`, `Broken`

## Hooks (`UgCore.Enums.Hooks.<Group>.<Key>`, server)

Before-the-fact, cancellable. Validate nothing you did not change; ug-core re-validates changed fields.

- `Players`: `BeforeDown`, `BeforeBleedout`, `BeforeRespawn`, `BeforeRevive`
- `Guard`: `BeforeAction` (an anticheat MAY soften or cancel kicks)
- `Characters`: `BeforeCreate`, `BeforeDelete`
- `Accounts`: `BeforeAdd`, `BeforeRemove`, `BeforeTransfer`
- `Jobs`: `BeforeSet`. `Gangs`: `BeforeSet`
- `Permissions`: `BeforeGroupAdd`, `BeforeGroupRemove`
- `Sessions`: `BeforeJoin`
- `Items`: `BeforeUse`. `Inventory`: `BeforeAdd`, `BeforeRemove`, `BeforeMove`, `BeforeOpen`, `BeforeClearOnRespawn`
- `Shops`: `BeforePurchase`. `Weapons`: `BeforeEquip`

## Statebags and GlobalState (read-only for you)

Player statebags, `UgCore.Enums.StateBags`: `Loaded`, `Player` (`{ name, characterId }`), `Metadata`, `DeathState`,
`Injuries`, `Job`, `Gang`, `Session`, `Groups`. Read with `Player(source).state[key]` on the server,
`LocalPlayer.state[key]` on the client.

GlobalState, `UgCore.Enums.GlobalState`: `Config`, `Modules`, `Items`, `Drops`, `Shops`.

## Violations (`UgCore.Enums.Violations`)

`InvalidPayload` (5), `RateLimited` (1), `ConcurrencyExceeded` (2), `UnknownCallback` (3), `NotLoaded` (2),
`NoPermission` (3), `OutOfRange` (5), `InvalidDeathState` (5). Weights in parentheses. Scores decay; owners set the warn,
kick and ban thresholds.

## UgLib

Shared, in your runtime:

- `Math`: `Clamp`, `Round`, `Lerp`, `InverseLerp`, `Remap`, `Distance2D`, `PointInPolygon`, `RotationToDirection`
- `Table`: `DeepCopy`, `Merge`, `Count`, `Contains`, `Keys`, `Values`, `Map`, `Filter`, `Find`, `Equals`, `Freeze`
- `String`: `Trim`, `Split`, `StartsWith`, `EndsWith`, `Capitalize`, `Truncate`, `Random`, `Distance`, `Suggest`
- `Format`: `Number`, `Money`, `Duration`, `Distance`, `Clock`, `Plural`
- `Async`: `WaitFor`, `Timeout`, `Debounce`, `Throttle`
- `Locale`: `Create(options?) -> translate(key, vars?)`, `GetCode`
- `Version`: `Get`, `IsAtLeast`, `Require`

Client, in your runtime:

- `Point`: `Create({ coords, distance, onEnter?, onExit?, nearby?, data? })`, `Remove`
- `Zone`: `Sphere`, `Box`, `Poly`, `Remove`, `GetAll`
- `Keybind`: `Register({ name, label, defaultKey?, onPressed?, onReleased?, disableWhileUi? })`, `Remove`, `SetEnabled`, `IsPressed`, `GetKey`
- `Npc`: `Create`, `Remove`, `GetPed`, `Clear`
- `Entity`: `GetClosestPed/Vehicle/Object/Player`, `GetNearbyPeds/Vehicles/Objects/Players`
- `Streaming`: `Model`, `AnimDict`, `AnimSet`, `PtfxAsset`, `TextureDict`, `ScaleformMovie`, `Release`
- `Animation`: `Play`, `Scenario`, `Stop`, `AttachProp`, `RemoveProp`, `DetachProps`
- `Cache`: `Get`, `On`, `Off`. `Raycast`: `FromCoords`, `FromCamera`. `Screen`: `WorldToScreen`, `GetResolution`, `GetAspectRatio`. `Draw`: `Text3D`, `Text2D`, `Marker`

Client UI, through the import (ug-lib's page):

- `Notify`: `Show({ message, title?, type?, duration?, icon?, id? }) -> id`, `Update`, `Dismiss`, `DismissAll`
- `TextUI`: `Show({ text, icon?, key?, position? })`, `Hide`, `IsShown`
- `Progress`: `Start`, `Cancel`, `IsActive`. `SkillCheck`: `Start`, `Cancel`, `IsActive`
- `Dialog`: `Alert`, `Confirm`, `Input`. `Context`: `Register`, `Open`, `Close`, `GetOpen`
- `Menu`: `Register`, `Open`, `Close`, `GetOpen`, `SetItem`. `Radial`: `Open`, `AddItem`, `RemoveItem`, `ClearItems`, `SetEnabled`
- `Clipboard`: `Copy`. `Ui`: `CloseAll`, `IsOpen`, `OpenSettings`

Prefer ug-lib UI over your own page for notifications, prompts, progress bars, dialogs and menus: players get one look
everywhere. Build a page only for screens ug-lib does not cover.

## Docs

- https://ugcore.urging.ch/api/overview
- https://ugcore.urging.ch/reference/error-codes
- https://ugcore.urging.ch/reference/events
- https://ugcore.urging.ch/reference/hooks
- https://ugcore.urging.ch/reference/statebags
- https://ugcore.urging.ch/api/enums
- https://ugcore.urging.ch/ug-lib/introduction
