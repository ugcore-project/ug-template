--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Every magic value lives here. Error codes come from UgCore.Enums.Errors, never from strings.

---@class UgTemplate.Enums
UgTemplate.Enums = {}

---Events this resource emits through UgCore.Events. Names MUST start with the resource name.
---@enum UgTemplateEvent
UgTemplate.Enums.Events = {
    -- (source, pointIndex, amount) on the server, after the reward was paid.
    Claimed = 'ug-template:Claimed',
}

---Server callbacks, without the `ug-template:` prefix ug-core adds.
---@enum UgTemplateCallback
UgTemplate.Enums.Callbacks = {
    Status = 'Status',
    Claim = 'Claim',
}

---Messages Lua sends to the page. MUST match web/src/types/protocol.ts.
---@enum UgTemplateNuiAction
UgTemplate.Enums.NuiAction = {
    Config = 'config',
    Open = 'open',
    Result = 'result',
    Close = 'close',
}

---Callbacks the page posts. MUST match web/src/types/protocol.ts.
---@enum UgTemplateNuiCallback
UgTemplate.Enums.NuiCallback = {
    Ready = 'ready',
    Claim = 'claim',
    Close = 'close',
}
