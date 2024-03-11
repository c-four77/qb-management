local QBCore = exports['qb-core']:GetCoreObject()
local PlayerGang = QBCore.Functions.GetPlayerData().gang
local shownGangMenu = false
local DynamicMenuItems = {}

-- UTIL
local function CloseMenuFullGang()
    exports['qb-core']:HideText()
    shownGangMenu = false
end

--//Events
AddEventHandler('onResourceStart', function(resource) --if you restart the resource
    if resource == GetCurrentResourceName() then
        Wait(200)
        PlayerGang = QBCore.Functions.GetPlayerData().gang
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerGang = QBCore.Functions.GetPlayerData().gang
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(InfoGang)
    PlayerGang = InfoGang
end)

RegisterNetEvent('qb-gangmenu:client:Stash', function()
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', 'boss_' .. PlayerGang.name, {
        maxweight = 4000000,
        slots = 100,
    })
    TriggerEvent('inventory:client:SetCurrentStash', 'boss_' .. PlayerGang.name)
end)

RegisterNetEvent('qb-gangmenu:client:Warbobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

local function AddGangMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

exports('AddGangMenuItem', AddGangMenuItem)

local function RemoveGangMenuItem(id)
    DynamicMenuItems[id] = nil
end

exports('RemoveGangMenuItem', RemoveGangMenuItem)

RegisterNetEvent('qb-gangmenu:client:OpenMenu', function()
    shownGangMenu = true
    local gangMenu = {

        {
            title = Lang:t('bodygang.manage'),
            description = Lang:t('bodygang.managed'),
            icon = 'fa-solid fa-list',
            event = 'qb-gangmenu:client:ManageGang',
        },
        {
            title = Lang:t('bodygang.hire'),
            description = Lang:t('bodygang.hired'),
            icon = 'fa-solid fa-hand-holding',
            event = 'qb-gangmenu:client:HireMembers',
        },
        {
            title = Lang:t('bodygang.storage'),
            description = Lang:t('bodygang.storaged'),
            icon = 'fa-solid fa-box-open',
            event = 'qb-gangmenu:client:Stash',
        },
        {
            title = Lang:t('bodygang.outfits'),
            description = Lang:t('bodygang.outfitsd'),
            icon = 'fa-solid fa-shirt',
            event = 'qb-gangmenu:client:Warbobe',
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        gangMenu[#gangMenu + 1] = v
    end

    lib.registerContext({
        id = 'gangs_first_menu',
        title = Lang:t('headersgang.bsm') .. string.upper(PlayerGang.label),
        options = gangMenu
    })
    lib.showContext('gangs_first_menu')

end)

RegisterNetEvent('qb-gangmenu:client:ManageGang', function()
    local gangMembersMenu = {}

    QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetEmployees', function(cb)
        for _, v in pairs(cb) do
            gangMembersMenu[#gangMembersMenu + 1] = {
                title = v.name,
                description = v.grade.name,
                icon = 'fa-solid fa-circle-user',
                event = 'qb-gangmenu:lient:ManageMember',
                args = {
                    player = v,
                    work = PlayerGang
                }
            }
        end

        lib.registerContext({
            id = 'gang_members_menu',
            menu = 'open_menu',
            title = Lang:t('bodygang.mempl') .. string.upper(PlayerGang.label),
            options = gangMembersMenu
        })
        lib.showContext('gang_members_menu')

    end, PlayerGang.name)
end)

RegisterNetEvent('qb-gangmenu:lient:ManageMember', function(data)
    local memberMenu = {}

    for k, v in pairs(QBCore.Shared.Gangs[data.work.name].grades) do
        memberMenu[#memberMenu + 1] = {
            title = v.name,
            description = Lang:t('bodygang.grade') .. k,
            serverEvent = 'qb-gangmenu:server:GradeUpdate',
            icon = 'fa-solid fa-file-pen',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name
            }
        }
    end
    memberMenu[#memberMenu + 1] = {
        title = Lang:t('bodygang.fireemp'),
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qb-gangmenu:server:FireMember',
        args = {
            data.player.empSource
        }
    }

    lib.registerContext({
        id = 'member_menu',
        menu = 'open_menu',
        title = Lang:t('bodygang.mngpl') .. data.player.name .. ' - ' .. string.upper(PlayerGang.label),
        options = memberMenu
    })
    lib.showContext('member_menu')

end)

RegisterNetEvent('qb-gangmenu:client:HireMembers', function()
    local hireMembersMenu = {}

    QBCore.Functions.TriggerCallback('qb-gangmenu:getplayers', function(players)
        for _, v in pairs(players) do
            if v and v ~= PlayerId() then

                hireMembersMenu[#hireMembersMenu + 1] = {
                    title = v.name,
                    description = Lang:t('bodygang.cid') .. v.citizenid .. ' - ID: ' .. v.sourceplayer,
                    icon = 'fa-solid fa-user-check',
                    serverEvent = 'qb-gangmenu:server:HireMember',
                    args = v.sourceplayer
                }
            end
        end

        lib.registerContext({
            id = 'hire_member_menu',
            menu = 'open_menu',
            title = Lang:t('bodygang.hireemp') .. string.upper(PlayerGang.label),
            options = hireMembersMenu
        })
        lib.showContext('hire_member_menu')
    
    end)
end)

-- MAIN THREAD

CreateThread(function()
    if Config.UseTarget then
        for gang, zones in pairs(Config.GangMenuZones) do
            for index, data in ipairs(zones) do
                exports['qb-target']:AddBoxZone(gang .. '-GangMenu' .. index, data.coords, data.length, data.width, {
                    name = gang .. '-GangMenu' .. index,
                    heading = data.heading,
                    -- debugPoly = true,
                    minZ = data.minZ,
                    maxZ = data.maxZ,
                }, {
                    options = {
                        {
                            type = 'client',
                            event = 'qb-gangmenu:client:OpenMenu',
                            icon = 'fas fa-sign-in-alt',
                            label = Lang:t('targetgang.label'),
                            canInteract = function() return gang == PlayerGang.name and PlayerGang.isboss end,
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
            local inRangeGang = false
            local nearGangmenu = false
            if PlayerGang then
                wait = 0
                for k, menus in pairs(Config.GangMenus) do
                    for _, coords in ipairs(menus) do
                        if k == PlayerGang.name and PlayerGang.isboss then
                            if #(pos - coords) < 5.0 then
                                inRangeGang = true
                                if #(pos - coords) <= 1.5 then
                                    nearGangmenu = true
                                    if not shownGangMenu then
                                        exports['qb-core']:DrawText(Lang:t('drawtextgang.label'), 'left')
                                        shownGangMenu = true
                                    end

                                    if IsControlJustReleased(0, 38) then
                                        exports['qb-core']:HideText()
                                        TriggerEvent('qb-gangmenu:client:OpenMenu')
                                    end
                                end

                                if not nearGangmenu and shownGangMenu then
                                    CloseMenuFullGang()
                                    shownGangMenu = false
                                end
                            end
                        end
                    end
                end
                if not inRangeGang then
                    Wait(1500)
                    if shownGangMenu then
                        CloseMenuFullGang()
                        shownGangMenu = false
                    end
                end
            end
            Wait(wait)
        end
    end
end)
