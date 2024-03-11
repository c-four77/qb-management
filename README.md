# qb-management

New qb-bossmenu / qb-gangmenu converted into one resource using ox_lib, with SQL support for society funds!

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-smallresources](https://github.com/qbcore-framework/qb-smallresources) (For the Logs)
- [ox_lib](https://github.com/overextended/ox_lib/releases)
- [qb-inventory](https://github.com/qbcore-framework/qb-inventory)
- [qb-clothing](https://github.com/qbcore-framework/qb-clothing)

# if using **illenium-appearance** 

- head to illenium-appearance/client/management/qb.lua replace with the one below

```lua

if not Config.BossManagedOutfits then return end

if not Management.IsQB() then return end

function Management.AddItems()
    local menuItem = {
        title = _L("outfitManagement.title"),
        icon = "fa-solid fa-shirt",
        event = "illenium-appearance:client:OutfitManagementMenu",
        args = {}
    }
    menuItem.description = _L("outfitManagement.jobText")
    menuItem.args.type = "Job"
    Management.ItemIDs.Boss = exports[Management.ResourceName]:AddBossMenuItem(menuItem)

    menuItem.description = _L("outfitManagement.gangText")
    menuItem.args.type = "Gang"
    Management.ItemIDs.Gang = exports[Management.ResourceName]:AddGangMenuItem(menuItem)
end

```

## Installation
### Manual
- Download the script and put it in the `[qb]` directory.
- IF NEW SERVER: Import `qb-management.sql` in your database
- IF EXISTING SERVER: Import `qb-management_upgrade.sql` in your database
- Edit config.lua with coords
- Restart Script / Server

## ATTENTION
### YOU NEED TO CREATE A ROW IN DATABASE WITH NAME OF SOCIETY IN MANAGEMENT_FUNDS TABLE IF YOU HAVE CUSTOM JOBS / GANGS
![database](https://i.imgur.com/6cd3NLU.png)

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>

