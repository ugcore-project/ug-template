--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Claim points in the world, through ug-lib: a prompt when close, the interact key opens the panel.

---@class UgTemplate.Internal.Points
local Points = {}
UgTemplate.Internal.Points = Points

local Panel = UgTemplate.Internal.Panel

---@type integer? the point the player stands at
local current = nil

---@param settings table the owner config
function Points.Create(settings)
    local label = UgLib.Locale.Create()

    for index, point in ipairs(settings.points) do
        UgLib.Point.Create({
            coords = point.coords,
            distance = settings.distance,
            data = index,
            nearby = function()
                if current ~= index then
                    current = index
                    UgLib.TextUI.Show({ text = label('prompt', { label = point.label }), key = settings.interactKey })
                end
            end,
            onExit = function()
                if current == index then
                    current = nil
                    UgLib.TextUI.Hide()
                    Panel.Close()
                end
            end,
        })
    end

    UgLib.Keybind.Register({
        name = 'interact',
        label = label('keybind.interact'),
        defaultKey = settings.interactKey,
        onPressed = function()
            if current and not Panel.IsOpen() then
                Panel.Open(current)
            end
        end,
    })
end

---@return integer?
function Points.Current()
    return current
end
