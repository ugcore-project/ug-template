--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

local H = dofile('tests/helpers.lua')

---@param name string
---@return table?
local function keybind(name)
    for _, options in ipairs(H.Keybinds) do
        if options.name == name then
            return options
        end
    end

    return nil
end

---Boots the client and walks into the first point.
local function atFirstPoint()
    H.Reset()
    H.Respond.Status = function(index)
        return { ok = true, amount = index * 100, waitMs = 0 }
    end
    H.LoadClient()
    H.Points[1].nearby()
end

---@return boolean
local function focused()
    local calls = H.CallsOf('SetNuiFocus')

    return #calls > 0 and calls[#calls].args[1] == true
end

print('client')

H.Test('boot creates a point per config entry and a keybind', function()
    H.Reset()

    local lines = H.LoadClient()

    H.ExpectLine(lines, '[ug-template] Ready: 2 point(s).')
    H.Equal(#H.Points, 2)
    H.Equal(H.Points[1].distance, 2.0)
    H.Equal(keybind('interact').defaultKey, 'E')
    H.Equal(H.LastPage('config').labels.claim, 'Claim')
end)

H.Test('waits for the server config', function()
    H.Reset()
    H.Load('client')

    H.Equal(#H.Points, 0)
    H.Advance(60000)
    H.Equal(#H.Points, 0)
end)

H.Test('the prompt shows near a point, the key opens the panel', function()
    atFirstPoint()

    H.Equal(H.TextUI, { text = 'label:prompt:Legion Square stash', key = 'E' })

    keybind('interact').onPressed()

    H.Equal(H.Requests[1], { name = 'Status', args = { 1 } })
    H.Equal(H.LastPage('open'), { point = 1, label = 'Legion Square stash', amount = 100, waitMs = 0 })
    H.Assert(focused(), 'cursor on')
end)

H.Test('a claim sends the point and shows the server answer', function()
    atFirstPoint()
    keybind('interact').onPressed()
    H.Respond.Claim = function()
        return { ok = true, amount = 250, waitMs = 600000 }
    end

    H.Equal(H.PostNui('claim', { point = 1 }).ok, true)
    H.Equal(H.Requests[2], { name = 'Claim', args = { 1 } })
    H.Equal(H.LastPage('result'), { ok = true, amount = 250, waitMs = 600000 })
end)

H.Test('forged page bodies are refused', function()
    atFirstPoint()
    keybind('interact').onPressed()

    H.Equal(H.PostNui('claim', { point = 2 }).ok, true, 'well formed, but not the open point')
    H.Equal(#H.Requests, 1, 'so nothing was asked')

    for _, body in ipairs({ H.Any('x'), { point = 'one' }, { point = 1.5 }, { point = 0 }, { point = 999 } }) do
        H.Equal(H.PostNui('claim', body).ok, false)
    end
end)

H.Test('server errors reach the page as codes', function()
    atFirstPoint()
    keybind('interact').onPressed()

    -- No answer: ug-core's timeout.
    H.PostNui('claim', { point = 1 })
    H.Equal(H.LastPage('result'), { ok = false, error = UgCore.Enums.Errors.Timeout })
end)

H.Test('leaving the point or Escape closes the panel and frees the cursor', function()
    atFirstPoint()
    keybind('interact').onPressed()

    H.Equal(H.PostNui('close', {}).ok, true)
    H.Equal(H.LastPage('close'), false)
    H.Assert(not focused(), 'cursor off')

    keybind('interact').onPressed()
    H.Points[1].onExit()
    H.Assert(not focused(), 'cursor off after leaving')
    H.Equal(H.TextUI, nil)
end)

H.Test('page callbacks are rate limited', function()
    atFirstPoint()

    local accepted = 0

    for _ = 1, 15 do
        if H.PostNui('close', {}).ok then
            accepted = accepted + 1
        end
    end

    H.Equal(accepted, 10)
    H.Advance(1000)
    H.Assert(H.PostNui('close', {}).ok, 'a new second has a new budget')
end)

H.Done()
