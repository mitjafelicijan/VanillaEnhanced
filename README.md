# Vanilla Enhanced

Preserves the original Vanilla UI with modern enhancements and quality-of-life improvements.
Compatible with World of Warcraft Client v1.12.

## Installation

- First download the addon. Make sure you remove `-master` from folder name and copy to `Interface/AddOns` directory.
- Copy everything from directory `Other/Launcher` to the root of WoW directory.
- Use `SuperWoWlauncher.exe` as launcher for the game (it will enable superwow).
- To fix sound issues on Linux: 
	- In Lutris: Configure > Runner options > DLL Overrides: `dsound=n,b`
- Enable DXVK with setting environmental variables:
	- In Lutris: Configure > System options > Environment variables:
	```
	DXVK_CONFIG=dxvk.conf
	DXVK_FRAME_RATE=120
	DXVK_HUD=full
	```
- If you want to change certain sounds copy `Sound` directory to WoW root to disable fizzle noise and gun sounds.
- Copy `Other/Patches/patch-O.mpq` to `Data` directory in WoW directory if you want to get raid visuals. 

> [!IMPORTANT]
> This was tested on a clean 1.12 client.
> None of the additional tweaks are enabled by default. You must enable them manually to avoid conflicts with existing addons.
> Some modules require [SuperWoW](https://github.com/balakethetlock/SuperWoW) to function correctly.

### Additional instructions for Void Linux

```
sudo xbps-install -S vulkan-loader-32bit gnutls-32bit
echo '/usr/lib32' | sudo tee /etc/ld.so.conf.d/lib32.conf
sudo ldconfig
lutris -d 2>&1 | grep -i -E 'i386|vulkan|gnutls' 
```

## Feature Descriptions

### UI Enhancements
- **Big Player Frame**: Enhances player and target unit frames with larger health bars and optional class-colored status bars.
- **Compact Action Bars**: A complete UI overhaul that stacks action bars vertically, repositions bags/micro-menu buttons, and removes Blizzard art for a cleaner look.
- **Compact Raid and Party Frames**: Modernized health-bar-style frames with heal prediction, range detection, and debuff highlighting.
- **Mini Player & Power Frames**: Standalone, combat-only frames for tracking player health, power (Mana/Rage/Energy), and combo points near the center of the screen.
- **Mana Bar Color & Ticks**: Changes the mana bar to white for better visibility and adds a "spark" to track the 2-second regeneration cycle.
- **Enhanced Aura Buttons**: Expands the player buff frame to support up to 32 buffs and 16 debuffs with countdown timers and stack counts.
- **Minimap Clock & Stopwatch**: Adds local/server time to the minimap and a built-in stopwatch feature.
- **Align Grid**: Draws a reference grid (Ctrl+Alt+Shift) to help you align UI elements perfectly.
- **Casting Bar Position**: Moves the standard player casting bar higher up on the screen for better visibility.
- **Chat Enhancements**: Enables mouse wheel scrolling in chat windows and arrow key navigation in the edit box.
- **Compare Tooltip**: Shows equipped item comparison tooltips when holding Shift.
- **Last Message Only**: Filters the red error text area to show only the most recent message, preventing spam.
- **Low Health Warning**: Displays a red screen pulse animation when player health drops below 35%.
- **Rested XP Tooltip**: Displays exact XP numbers and rested percentage directly on the XP bar when hovered.

### Combat & Gameplay
- **Extended Macros**: Overhauls the 1.12 macro system to support modern syntax including `#showtooltip`, conditional logic `[help,harm,@mouseover]`, and `/castsequence` with resets. Requires SuperWoW.
- **Target Casting Bar**: Displays the name and progress of the spell your current target is casting directly on their unit frame.
- **Cooldown Timers**: Adds numerical countdowns and icon desaturation to abilities and items on cooldown.
- **Nameplate Enhancements**: Adds combo points, scaling based on UI settings, and threat-based coloring (green when you have aggro) to nameplates.
- **Out of Range Indicator**: Colors action button icons red when your target is out of range for that specific spell.
- **Combat Cursor**: Adds a high-visibility background trail to the cursor during combat (or toggle via `/cursor`).
- **Hunter Target Distance**: A specialized indicator for Hunters showing Melee, Ranged, Deadzone, or Out of Range status.
- **Druid Specifics**: Smart rotation macro (`/dob`), mana bar visibility while shapeshifted, and form-switch spam protection (prevents toggling off forms).
- **Maintain Hunter Aspects**: Prevents accidental toggling off of Aspects when spamming the key.
- **Pull & Break Timer**: Compatible with BigWigs to show countdown bars for raid pulls and breaks.
- **Simple DPS Meter**: A simple and lightweight damage and heal meter.

### Automation & Quality of Life
- **Auction Enhancements**: Adds a "Post" tab to the AH with automated stack splitting, price scanning, and bulk posting.
- **Auto Roll**: Automatically rolls on items based on config (ZG coins, MC cores, Green items, etc.).
- **Auto Loot/Repair/Sell**: Automates looting (via Shift), gear repairs at merchants, and selling of junk (grey) items.
- **Mailbox Enhancements**: Remembers the last recipient and adds Shift+Click to quickly take items and delete mail.
- **Bag & Item Tools**: Adds a search box to the backpack, shows free slot counts, displays item levels/rarity on gear icons.
- **Bank Bags**: Allows you to view a snapshot of your bank contents even when you are not at a bank.
- **Consumables Panel**: A dedicated 6x6 grid that automatically finds and displays all consumable items in your bags.
- **Trinket Manager**: A small frame for managing equipped trinkets and relics, including cooldown tracking and easy usage.
- **Outfit Manager**: Integrated into the character pane, this tool allows you to save, rename, and quickly swap between different equipment sets.

### World & Map
- **Travel Journal**: Allows you to place custom pins and notes on the world map (Ctrl+Click) to track your discoveries.
- **Max Camera Zoom**: Increases the maximum distance you can zoom out (toggleable with `/mz`).

### Utility & Challenges
- **Bulletin Board**: Automatically parses chat channels for LFG/LFM messages and lists them in a filterable UI categorized by dungeon.
- **Extended Commands**: Adds modern slash commands like `/rl` (reload), `/use`, `/dismount`, and `/cancelform`.
- **Solo Self Found**: A challenge mode module that blocks grouping, trading, and auction house usage.
- **Hide UI Elements**: Specialized modules to hide Lua errors and specific Minimap buttons (BGF, LFT, EBC).

## Extended Macros (Modern Syntax)

The **Extended Macros** module allows you to use Retail/Classic-style macro syntax in the 1.12 client. It supports dynamic icons on action bars using `#show` and `#showtooltip` directives, and complex conditional logic.

### Supported Conditions
| Condition | Description |
| :--- | :--- |
| `help` / `harm` | Unit is friendly / hostile. |
| `exists` / `dead` | Unit exists / is dead. |
| `combat` | You are in combat. |
| `stealth` | You are stealthed or in Prowl/Shadowform. |
| `mounted` | You are on a mount. |
| `pet` | You have a pet active. |
| `group` / `group:party` | You are in a party or raid. |
| `group:raid` | You are specifically in a raid. |
| `mod:shift/ctrl/alt` | Specific modifier key is held. |
| `mod` | Any modifier key is held. |
| `form:n` / `stance:n` | You are in a specific shapeshift form or warrior stance. |
| `@unit` / `target=unit`| Directs the action at a specific unit (e.g., `@mouseover`, `@player`). |
| `no[condition]` | Inverts specific conditions (`nodead`, `nocombat`, `noexists`, `nostealth`, `nopet`, `nomounted`, `nogroup`). |

### Examples

#### 1. Smart Healing (Mouseover)
Priority: Mouseover (if friendly & alive) > Target (if friendly & alive) > Self.
```lua
#showtooltip Lesser Heal
/cast [@mouseover,help,nodead][help,nodead][@player] Lesser Heal
```

#### 2. Combat Utility
Casts Charge in combat, otherwise Intercept. Automatically starts attacking.
```lua
#showtooltip
/cast [combat] Intercept; Charge
/startattack
```

#### 3. Shaman Totem Sequence
Drops totems in order, resets to the first totem after 5 seconds of inactivity, if you change targets, or if you leave/enter combat.
```lua
#showtooltip
/castsequence reset=5/target/combat Stoneskin Totem, Mana Spring Totem, Grace of Air Totem
```

#### 4. Warrior Stance Swap
Casts Overpower if in Battle Stance, otherwise swaps to Battle Stance.
```lua
#showtooltip Overpower
/cast [stance:1] Overpower; Battle Stance
```

#### 5. Combined Modifier Macro
Casts Flash Heal normally, but Greater Heal if Shift is held.
```lua
#showtooltip
/cast [mod:shift] Greater Heal; Flash Heal
```

#### 6. Group Utility
Uses Arcane Intellect on target normally, but Arcane Brilliance if in a party or raid.
```lua
#showtooltip
/cast [group] Arcane Brilliance; Arcane Intellect
```

## Slash Commands (Extended Commands)

| Command | Aliases | Description |
| :--- | :--- | :--- |
| `/rl` | `/reload`, `/reloadui` | Reloads the game interface. |
| `/rp [arg]` | `/raidpullout` | Manages raid pullout frames (`show`, `hide`, `reload`). |
| `/reset` | `/resetinstances` | Resets all active instances. |
| `/dismount` | | Automatically finds and cancels your mount aura. |
| `/cancelform` | | Cancels Druid forms, Priest Shadowform, or Shaman Spirit Wolf. |
| `/bearform` | | Enters Druid Bear Form. |
| `/aquaticform` | | Enters Druid Aquatic Form. |
| `/catform` | | Enters Druid Cat Form. |
| `/travelform` | | Enters Druid Travel Form. |
| `/use [item]` | | Searches bags for an item by name and uses it. |
| `/equip [item]` | | Searches bags for an item by name and equips it. |
| `/equipslot [id] [item]` | | Equips an item by name into a specific slot ID. |
| `/feedpet [food]` | | Feeds the specified food to your hunter pet. |
| `/cleartarget` | | Clears your current selection. |
| `/targetlasttarget` | | Re-targets your previous selection. |
| `/targetmouseoverunit`| | Targets the unit currently under your mouse. |
| `/startattack` | | Starts auto-attacking the current target. |
| `/stopattack` | | Stops auto-attacking. |
| `/stopcasting` | | Interrupts your current spell cast. |
| `/petattack` | | Orders your pet to attack your target. |
| `/petfollow` | | Orders your pet to follow you. |
| `/petpassive` | | Sets your pet to passive mode. |
| `/petdefensive`| | Sets your pet to defensive mode. |
| `/petaggressive`| | Sets your pet to aggressive mode. |
| `/meter`| | Toggles simple DPS and Healing meter. |

#### Equip Slot IDs
| ID | Slot | ID | Slot | ID | Slot | ID | Slot |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Head | 2 | Neck | 3 | Shoulder | 5 | Chest |
| 6 | Waist | 7 | Legs | 8 | Feet | 9 | Wrist |
| 10 | Hands | 11 | Finger 1 | 12 | Finger 2 | 13 | Trinket 1 |
| 14 | Trinket 2 | 15 | Back | 16 | Main Hand | 17 | Off Hand |
| 18 | Ranged | | | | | | |

## UI Preview

The addon introduces a TBC-style Interface Options panel accessible via the main menu.

![Screenshots](Promo/Screens.gif)

### Compact Action Bars
![Compact Action Bars](Promo/CompactActionBars.jpg)

### Mini Player Frame
![MiniPlayerFrame](Promo/MiniPlayerFrame.jpg)

## Manual Tweaks

### Game Sounds
The `Other/Sound` directory contains overrides for internal game sounds (e.g., Gun sounds, Error sounds). To install, copy the `Sound` directory to your WoW root folder.

```
WoW/
  WoW.exe
  Sound/
    Item/
      Weapons/
        Gun/     -> Replaces gun sounds.
    Spells/
      Fizzle/    -> Mutes error sounds.
```

### AOE MPQ

![Raid Visuals](Promo/RaidVisuals.png)

Copy `GameAssets/Data/patch-O.mpq` to the `Data` folder in your WoW directory. This patch adds visual indicators (circles) around mobs during AOE.

https://github.com/MarcelineVQ/twow-raid-visuals

### Auto-login MPQ

Copy `GameAssets/Data/patch-Y.mpq` to the `Data` folder in your WoW directory. This patch adds auto login option to login screen.

https://github.com/Haaxor1689/turtle-autologin
