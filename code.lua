-- Deobfuscated from the MoonSec V3 wrapper in Untitled-1.txt.
-- MoonSec metadata/anti-tamper scaffolding was removed; this is the payload logic.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function ownedTycoons()
    local tycoons = {}
    local base = workspace["Tycoon Systems"]["Naval Base"].Tycoons

    for _, item in pairs(base:GetDescendants()) do
        if item.Name == "Owner"
            and item.Value == LocalPlayer
            and item.Parent
            and item.Parent.Parent
            and item.Parent.Parent.Name == "Tycoons" then
            table.insert(tycoons, item.Parent)
        end
    end

    return tycoons
end

local function enemyVehicleHitEvents()
    local remotes = {}

    for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
        if vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
            and vehicle:FindFirstChild("Body") then
            for _, item in pairs(vehicle.Body:GetDescendants()) do
                if item.Name == "HitEvent" then
                    table.insert(remotes, item)
                end
            end
        end
    end

    return remotes
end

local function backpackOrCharacterHitEvent()
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:FindFirstChild("HitEvent") then
            return item.HitEvent
        end
    end

    for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
        if item:FindFirstChild("HitEvent") then
            return item.HitEvent
        end
    end
end

function Cash()
    spawn(function()
        while _G.Cash do
            pcall(function()
                for _, tycoon in pairs(ownedTycoons()) do
                    local essentials = tycoon:WaitForChild("Essentials")
                    local args = { "manualpump", {} }

                    for _ = 1, 10 do
                        essentials.CollectorEvent:FireServer(unpack(args))
                    end

                    firetouchinterest(
                        LocalPlayer.Character.HumanoidRootPart,
                        essentials.Giver.GivePart,
                        0
                    )
                    wait()
                    firetouchinterest(
                        LocalPlayer.Character.HumanoidRootPart,
                        essentials.Giver.GivePart,
                        1
                    )
                    wait(1)
                end
            end)
            wait()
        end
    end)
end

function Button()
    spawn(function()
        while _G.Button do
            pcall(function()
                for _, tycoon in pairs(ownedTycoons()) do
                    for _, button in pairs(tycoon.Buttons:GetChildren()) do
                        if button:GetAttribute("IsPassId") == false then
                            firetouchinterest(
                                LocalPlayer.Character.HumanoidRootPart,
                                button.Head,
                                0
                            )
                            wait(0.2)
                            firetouchinterest(
                                LocalPlayer.Character.HumanoidRootPart,
                                button.Head,
                                1
                            )
                        end
                    end
                end
            end)
            wait()
        end
    end)
end

function Rebirth()
    spawn(function()
        while _G.Rebirth do
            wait()
            pcall(function()
                game:GetService("ReplicatedStorage")
                    ._ReplicationRemotes
                    .Server["ReplicatedStorage.Modules.TycoonGame.Tycoons.Utils:clientRequestRebirth"]
                    :InvokeServer(LocalPlayer)
                wait(3)
            end)
        end
    end)
end

function Vehicles()
    spawn(function()
        local hitEvents = enemyVehicleHitEvents()

        while _G.Vehicles do
            pcall(function()
                local root = LocalPlayer.Character.HumanoidRootPart
                local nearest
                local nearestDistance = 10000

                for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
                    if vehicle:GetAttribute("Enabled")
                        and vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
                        and vehicle:FindFirstChild("Body")
                        and vehicle.Body:FindFirstChild("Main") then
                        local main = vehicle.Body.Main
                        local distance = (main.CFrame.Position - root.Position).Magnitude

                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearest = vehicle
                        end
                    end
                end

                local main = nearest.Body.Main
                local args = {
                    main,
                    root,
                    {
                        Normal = Vector3.new(
                            -0.09811976552009583,
                            0.8896507024765015,
                            0.4459754526615143
                        ),
                        Position = root.Position,
                        Instance = main,
                        Material = Enum.Material.SmoothPlastic,
                        Id = 0,
                        Distance = nearestDistance,
                    },
                }

                for _, remote in ipairs(hitEvents) do
                    remote:FireServer(unpack(args))
                end
            end)
            wait()
        end
    end)
end

function all()
    spawn(function()
        local hitEvents = enemyVehicleHitEvents()

        while _G.all do
            pcall(function()
                local root = LocalPlayer.Character.HumanoidRootPart

                for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
                    if vehicle:GetAttribute("Enabled")
                        and vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
                        and vehicle:FindFirstChild("Body")
                        and vehicle.Body:FindFirstChild("Main") then
                        local main = vehicle.Body.Main
                        local distance = (main.Position - root.Position).Magnitude
                        local args = {
                            main,
                            root,
                            {
                                Normal = Vector3.new(
                                    -0.09811976552009583,
                                    0.8896507024765015,
                                    0.4459754526615143
                                ),
                                Position = Vector3.new(
                                    -10532.2041015625,
                                    2250.1744232177734,
                                    13033.7958984375
                                ),
                                Instance = main,
                                Material = Enum.Material.SmoothPlastic,
                                Id = 0,
                                Distance = distance,
                            },
                        }

                        for _, remote in ipairs(hitEvents) do
                            remote:FireServer(unpack(args))
                        end
                    end
                end
            end)
            wait()
        end
    end)
end

function Listening()
    spawn(function()
        local hitEvent = backpackOrCharacterHitEvent()

        pcall(function()
            if LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Sit = true
            end
        end)

        while _G.Listening do
            pcall(function()
                for _, post in pairs(workspace.ListeningPosts:GetChildren()) do
                    if post:GetAttribute("Health") > 0 then
                        local args = {
                            post,
                            {
                                Normal = vector.create(
                                    -0.09811976552009583,
                                    0.8896507024765015,
                                    0.4459754526615143
                                ),
                                Position = vector.create(
                                    -10532.2041015625,
                                    2250.1744232177734,
                                    13033.7958984375
                                ),
                                Instance = post.Main,
                                Material = Enum.Material.SmoothPlastic,
                                Id = 0,
                                Distance = 9999,
                            },
                        }

                        hitEvent:FireServer(unpack(args))
                    end
                end
            end)
            wait()
        end
    end)
end

local coreGui = game:GetService("CoreGui")
local existing = coreGui:FindFirstChild("ToraScript")
if existing then
    existing:Destroy()
end

local library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew"
))()

local window = library:CreateWindow("Navy Tycoon")

window:AddToggle({
    text = "Collect Cash",
    flag = "toggle",
    state = false,
    callback = function(state)
        _G.Cash = state
        print("Cash: " .. tostring(state))
        if state then
            Cash()
        end
    end,
})

window:AddToggle({
    text = "Auto Buttons",
    flag = "toggle",
    state = false,
    callback = function(state)
        _G.Button = state
        print("Button: " .. tostring(state))
        if state then
            Button()
        end
    end,
})

window:AddToggle({
    text = "Auto Rebirth",
    flag = "toggle",
    state = false,
    callback = function(state)
        _G.Rebirth = state
        print("Rebirth: " .. tostring(state))
        if state then
            Rebirth()
        end
    end,
})

window:AddToggle({
    text = "Destroy ListeningPosts",
    flag = "toggle",
    state = false,
    callback = function(state)
        _G.Listening = state
        print("Listening: " .. tostring(state))
        if state then
            Listening()
        end
    end,
})

window:AddToggle({
    text = "Attack Nearest Vehicles",
    flag = "toggle",
    state = false,
    callback = function(state)
        _G.Vehicles = state
        print("Vehicles: " .. tostring(state))
        if state then
            Vehicles()
        end
    end,
})

window:AddToggle({
    text = "Attack all Vehicles",
    flag = "toggle",
    state = false,
    callback = function(state)
        _G.all = state
        print("all: " .. tostring(state))
        if state then
            all()
        end
    end,
})

window:AddLabel({
    text = "YouTube: Tora IsMe",
})

window:Init()
