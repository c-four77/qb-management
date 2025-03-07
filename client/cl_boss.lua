local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = QBCore.Functions.GetPlayerData().job
local shownBossMenu = false
local DynamicMenuItems = {}

-- UTIL
local function CloseMenuFull()
    exports['qb-core']:HideText()
    shownBossMenu = false
end

local function AddBossMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

exports('AddBossMenuItem', AddBossMenuItem)

local function RemoveBossMenuItem(id)
    DynamicMenuItems[id] = nil
end

exports('RemoveBossMenuItem', RemoveBossMenuItem)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('qb-bossmenu:client:OpenMenu', function()
    if not PlayerJob.name or not PlayerJob.isboss then return end

    local bossMenu = {
        {
            title = Lang:t('body.manage'),
            description = Lang:t('body.managed'),
            icon = 'fa-solid fa-list',
            event = 'qb-bossmenu:client:employeelist',
        },
        {
            title = Lang:t('body.hire'),
            description = Lang:t('body.hired'),
            icon = 'fa-solid fa-hand-holding',
            event = 'qb-bossmenu:client:HireMenu',

        },
        {
            title = Lang:t('body.storage'),
            description = Lang:t('body.storaged'),
            icon = 'fa-solid fa-box-open',
            event = 'qb-bossmenu:client:Stash',
        },
        {
            title = Lang:t('body.outfits'),
            description = Lang:t('body.outfitsd'),
            icon = 'fa-solid fa-shirt',
            event = 'qb-bossmenu:client:Wardrobe',
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        bossMenu[#bossMenu + 1] = v
    end

    lib.registerContext({
        id = 'first_menu',
        title = Lang:t('headers.bsm') .. string.upper(PlayerJob.label),
        options = bossMenu
    })
    lib.showContext('first_menu')
end)

RegisterNetEvent('qb-bossmenu:client:employeelist', function()
    local EmployeesMenu = {}
    QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetEmployees', function(cb)
        for _, v in pairs(cb) do
            EmployeesMenu[#EmployeesMenu + 1] = {
                title = v.name,
                description = v.grade.name,
                icon = 'fa-solid fa-circle-user',
                event = 'qb-bossmenu:client:ManageEmployee',
                args = {
                    player = v,
                    work = PlayerJob
                }
            }
        end

        lib.registerContext({
            id = 'employees_menu',
            menu = 'first_menu',
            title = Lang:t('body.mempl') .. string.upper(PlayerJob.label),
            options = EmployeesMenu
        })
        lib.showContext('employees_menu')

    end, PlayerJob.name)
end)

RegisterNetEvent('qb-bossmenu:client:ManageEmployee', function(data)
    local EmployeeMenu = {}
    for k, v in pairs(QBCore.Shared.Jobs[data.work.name].grades) do
        EmployeeMenu[#EmployeeMenu + 1] = {
            title = v.name,
            description = Lang:t('body.grade') .. k,
            serverEvent = 'qb-bossmenu:server:GradeUpdate',
            icon = 'fa-solid fa-file-pen',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name
            }
        }
    end
    EmployeeMenu[#EmployeeMenu + 1] = {
        title = Lang:t('body.fireemp'),
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qb-bossmenu:server:FireEmployee',
        args = {
            data.player.empSource
        }
    }

    lib.registerContext({
        id = 'employee_menu',
        menu = 'first_menu',
        title = Lang:t('body.mngpl') .. data.player.name .. ' - ' .. string.upper(PlayerJob.label),
        options = EmployeeMenu
    })
    lib.showContext('employee_menu')
end)

RegisterNetEvent('qb-bossmenu:client:Stash', function()
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', 'boss_' .. PlayerJob.name, {
        maxweight = 4000000,
        slots = 25,
    })
    TriggerEvent('inventory:client:SetCurrentStash', 'boss_' .. PlayerJob.name)
end)

RegisterNetEvent('qb-bossmenu:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('qb-bossmenu:client:HireMenu', function()
    local HireMenu = {
        {
            header = Lang:t('body.hireemp') .. string.upper(PlayerJob.label),
            isMenuHeader = true,
            icon = 'fa-solid fa-circle-info',
        },
    }
    QBCore.Functions.TriggerCallback('qb-bossmenu:getplayers', function(players)
        for _, v in pairs(players) do
            if v and v ~= PlayerId() then
                HireMenu[#HireMenu + 1] = {
                    title = v.name,
                    description = Lang:t('body.cid') .. v.citizenid .. ' - ID: ' .. v.sourceplayer,
                    icon = 'fa-solid fa-user-check',
                    serverEvent = 'qb-bossmenu:server:HireEmployee',
                    args = {
                        v.sourceplayer
                    }
                }
            end
        end

        lib.registerContext({
            id = 'hire_menu',
            menu = 'first_menu',
            title = Lang:t('body.hireemp') .. string.upper(PlayerJob.label),
            options = HireMenu
        })
        lib.showContext('hire_menu')
    end)
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for job, zones in pairs(Config.BossMenuZones) do
            for index, data in ipairs(zones) do
                exports['qb-target']:AddBoxZone(job .. '-BossMenu-' .. index, data.coords, data.length, data.width, {
                    name = job .. '-BossMenu-' .. index,
                    heading = data.heading,
                    -- debugPoly = true,
                    minZ = data.minZ,
                    maxZ = data.maxZ,
                }, {
                    options = {
                        {
                            type = 'client',
                            event = 'qb-bossmenu:client:OpenMenu',
                            icon = 'fas fa-sign-in-alt',
                            label = Lang:t('target.label'),
                            canInteract = function() return job == PlayerJob.name and PlayerJob.isboss end,
                        },
                    },
                    distance = 2.5
                })
            end
        end
    else
        while true do
            local wait = 2500
            local pos = GetEntityCoords(PlayerPedId())
            local inRangeBoss = false
            local nearBossmenu = false
            if PlayerJob then
                wait = 0
                for k, menus in pairs(Config.BossMenus) do
                    for _, coords in ipairs(menus) do
                        if k == PlayerJob.name and PlayerJob.isboss then
                            if #(pos - coords) < 5.0 then
                                inRangeBoss = true
                                if #(pos - coords) <= 1.5 then
                                    nearBossmenu = true
                                    if not shownBossMenu then
                                        exports['qb-core']:DrawText(Lang:t('drawtext.label'), 'left')
                                        shownBossMenu = true
                                    end
                                    if IsControlJustReleased(0, 38) then
                                        exports['qb-core']:HideText()
                                        TriggerEvent('qb-bossmenu:client:OpenMenu')
                                    end
                                end

                                if not nearBossmenu and shownBossMenu then
                                    CloseMenuFull()
                                    shownBossMenu = false
                                end
                            end
                        end
                    end
                end
                if not inRangeBoss then
                    Wait(1500)
                    if shownBossMenu then
                        CloseMenuFull()
                        shownBossMenu = false
                    end
                end
            end
            Wait(wait)
        end
    end
end)
