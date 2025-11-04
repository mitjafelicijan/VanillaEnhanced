### 12/04/2024 : 1.0.0
- First release

### 14/04/2024 : 1.1.0
- Fixed bug causing crash with SetMouseoverUnit
- CastSpellByName is now reverse compatible & can once again accept 1, 0, true, or false as OnSelf flags, in addition to the custom targeting by unit string.
- Added SelectionCircleStyle CVar.
- - "1" == [default classic style](https://github.com/balakethelock/SuperWoW/assets/111737968/5086467b-eb63-40aa-aec9-05d9848e8140)
- - "2" == [full circle style](https://github.com/balakethelock/SuperWoW/assets/111737968/6d6db191-bc61-44b0-81ac-54d614bf4db9)
- - "3" == [pointed circle style](https://github.com/balakethelock/SuperWoW/assets/111737968/be99853f-1754-47df-a6fa-818a52da2e71)
- - "4" == [facing classic style](https://github.com/balakethelock/SuperWoW/assets/111737968/550a443e-ea17-43b9-9d51-238672953b62)
- - If you want to use styles 2 or 3 you have to download the textures [here](https://github.com/balakethelock/SuperWoW/releases/tag/Patch)

### 02/05/2024 : 1.1.1
- Fixed bug with strings being turned to lowercase
- Added UncapSounds CVar. Set to "1" to remove the hardcoded soundchannels limit (you still have to set software sound channels to a high number if you want the max number of soundeffects played by the game)
- added new unit "mark1" to "mark8" that selects the corresponding target marker. explanation: UnitName("mark8") returns the name of the unit marked skull

### 05/09/2024 : 1.1.2
- Fixed UnitExists function (the invisible target bug)
- Fixed UnitBuff and UnitDebuff returning negative spell id.

### 09/10/2024 : 1.1.3
- Fixed some crashes with custom spells

### 07/11/2024 : 1.2
- Better compatibility with spell links of various addons. Now all spells use "enchant:" syntax for their hyperlinks. Update to latest SuperAPI for better support.
- New global variables SUPERWOW_STRING and SUPERWOW_VERSION give version info for addons.

### 22/11/2024 : 1.3
- Autoloot now works on enchanting & pick pocket.
- Added ImportFile and ExportFile functions to both FrameXML and GlueXML.

### 31/01/2025 : 1.4
- Fixed some unit signal events not always firing.
- Added LootSparkle CVar to show sparkles on lootable treasure.
- Reworked Raw GUID log. Raw Combat Log entries are now **always** accessible through the event RAW_COMBATLOG (arg1 = original event name, arg2 = text with GUID). This comes with removing the option to turn raw GUID mode on/off through LoggingCombat("RAW").
- Raw Combat Log also comes with its own separate txt file.
- lua function CombatLogAdd("text") now can accept a flag as 2nd argument to instead add the message to the raw log like so:
/run CombatLogAdd("hi world") --add the text to WoWCombatLog.txt
/run CombatLogAdd("hi world", 1) --add the text to WoWRawCombatLog.txt

### DD/MM/2025 : 2.0
- Code refactoring and performance boost.
- Split TrackUnit function to two separate functions, TrackUnit and UntrackUnit. UntrackUnit("all") can be used remove tracking from all units.
- Second Argument of function CastSpellByName can now accept "CLICK" to instantly cast reticle spells on mouseover location (bypassing targeting circle mode)
- Added UnitNameplate("unit") function that returns Nameplate frame.
- Added CanLootUnit("unit") function that returns whether a unit has loot inside.
- New ChatBubbleCvars: ChatBubbleRange (10-200 yards), ChatBubblesRaid, ChatBubblesBattleground, ChatBubblesWhisper, ChatBubblesCreatures
- Added NameplateRange CVar (10-80 yards). This takes precedance over all client modifications for Nameplate range.
- Added NameplateMotion CVar: 0 = Overlap. 1 = Default spread. 2 = Smart spread.
- Added HealingText CVar to toggle Floating Healing Text.
- Added CREATE_CHATBUBBLE event. arg1 = chatbubble frame, arg2 = unit GUID.
- Added CursorPosition() function that returns world XYZ coordinates of mouseover.
- Added GetWorldLocMapPosition(continent, x, y) that returns map XY coordinates from a world XYZ coordinate and continent index.
- Added GetMapPositionWorldLoc(continentIndex, zoneIndex, mapX, mapY) that returns world XYZ coordinates from map XY coordinates.
- Added GetMapBoundaries(continentIndex, zoneIndex) that returns left, right, top and bottom boundaries of a map.
- Added IsSwimming(), IsMounted(), isIndoors() functions to return the status of the player.
- Added GetSpeed() function to return runSpeed, swimSpeed of the player in yards per second (7 yards = 100% movement speed)