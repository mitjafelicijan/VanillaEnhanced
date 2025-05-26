[x] CONTROLS
======================================================

    [x] Mouse sensitivity (Slider)
        MOUSE_SENSITIVITY
        OPTION_TOOLTIP_MOUSE_SENSITIVITY
        > SET mouseSpeed "0.5" (0.5-1.5)
    
    [x] Invert mouse (Checkbox)
        INVERT_MOUSE
        OPTION_TOOLTIP_INVERT_MOUSE
        > SET mouseInvertPitch "1"

    [x] Sticky targeting (Checkbox)
        GAMEFIELD_DESELECT_TEXT
        OPTION_TOOLTIP_GAMEFIELD_DESELECT
        > SET deselectOnClick "0"

    [x] Attack on assist (Checkbox)
        ASSIST_ATTACK
        OPTION_TOOLTIP_ASSIST_ATTACK
        > SET assistAttack "1"

    [x] Auto clear AFK (Checkbox)
        CLEAR_AFK
        OPTION_TOOLTIP_CLEAR_AFK
        > SET autoClearAFK "0"

    [x] Block Trades (Checkbox)
        BLOCK_TRADES
        OPTION_TOOLTIP_BLOCK_TRADES
        > SET BlockTrades "1"

    [x] Auto self cast (Checkbox)
        AUTO_SELF_CAST_TEXT
        OPTION_TOOLTIP_AUTO_SELF_CAST
        > SET autoSelfCast "1"

    [x] Loot at cursor (Checkbox)
        LOOT_AT_WINDOW_CURSOR_TEXT
        OPTION_TOOLTIP_LOOT_AT_WINDOW_CURSOR
        > LOOT_WINDOW_AT_CURSOR = "0"

    [x] Click to move (Checkbox) -> Not adding this!
        CLICK_TO_MOVE
        OPTION_TOOLTIP_CLICK_TO_MOVE
        > SET AutoInteract "1"
        
        [x] Click to move camera style (Dropdown)
            CLICK_CAMERA_STYLE
            OPTION_TOOLTIP_CLICK_CAMERA_STYLE
            > Smart: Not set (unset cameraSmoothTrackingStyle)
            > Locked: SET cameraSmoothTrackingStyle "2"
            > Never: SET cameraSmoothTrackingStyle "0"

    [x] Block auction house
    [x] Block grouping


[x] DISPLAY
======================================================

    [x] Enhanced tooltips (Checkbox)
        USE_UBERTOOLTIPS
        OPTION_TOOLTIP_USE_UBERTOOLTIPS
        > SET UberTooltips "0"

    [x] Show loading screen tips (Checkbox)
        SHOW_TIPOFTHEDAY_TEXT
        OPTION_TOOLTIP_SHOW_TIPOFTHEDAY
        > SET showGameTips 4"0"

    [x] Show detailed tooltips (Checkbox)
        SHOW_NEWBIE_TIPS_TEXT
        OPTION_TOOLTIP_SHOW_NEWBIE_TIPS
        > SHOW_NEWBIE_TIPS = "0"

    [x] Status bar text (Checkbox)
        STATUS_BAR_TEXT
        OPTION_TOOLTIP_STATUS_BAR
        > SET statusBarText "1"
    
    [x] Player names (Checkbox)
        SHOW_PLAYER_NAMES
        OPTION_TOOLTIP_SHOW_PLAYER_NAMES
        > SET UnitNamePlayer "0"
        
        [x] Player guild names (Checkbox)
            SHOW_GUILD_NAMES
            OPTION_TOOLTIP_SHOW_GUILD_NAMES
            > SET UnitNamePlayerGuild "0"
        
        [x] Player titles (Checkbox)
            SHOW_PLAYER_TITLES
            OPTION_TOOLTIP_SHOW_PLAYER_TITLES
            > SET UnitNamePlayerPVPTitle "0"

    [x] NPC names (Checkbox)
        SHOW_NPC_NAMES
        OPTION_TOOLTIP_SHOW_NPC_NAMES
        > SET UnitNameNPC "1"
    
    [x] My own name (Checkbox)
        SHOW_OWN_NAME
        OPTION_TOOLTIP_SHOW_OWN_NAME
        > SET UnitNameOwn "1"

    [x] Show cloak (Checkbox)
        SHOW_CLOAK
        OPTION_TOOLTIP_SHOW_CLOAK
        > ShowCloak(false)

    [x] Show helm (Checkbox)
        SHOW_HELM
        OPTION_TOOLTIP_SHOW_HELM
        > ShowHelm(true)

    [x] Buff durations (Checkbox)
        SHOW_BUFF_DURATION_TEXT
        OPTION_TOOLTIP_SHOW_BUFF_DURATION
        > SHOW_BUFF_DURATIONS = "1"

    [x] Instant quest text (Checkbox)
        SHOW_QUEST_FADING_TEXT
        OPTION_TOOLTIP_SHOW_QUEST_FADING
        > QUEST_FADING_DISABLE = "1"

    [x] Hide zone objective tracker (Checkbox)
        HIDE_OUTDOOR_WORLD_STATE_TEXT
        OPTION_TOOLTIP_HIDE_OUTDOOR_WORLD_STATE
        > HIDE_OUTDOOR_WORLD_STATE = "0"

    [x] Automatic quest tracking (Checkbox)
        AUTO_QUEST_WATCH_TEXT
        OPTION_TOOLTIP_AUTO_QUEST_WATCH
        > AUTO_QUEST_WATCH = "1"
    
    [/] Enemy nameplates (DOES NOT WORK)
        MISSING
        MISSING
        > NAMEPLATES_ON

    [/] Friendly nameplates (DOES NOT WORK)
        MISSING
        MISSING
        > FRIENDNAMEPLATES_ON
    
    NOTE: Nameplates scaling module should be here instead of Modules.


[x] CAMERA
======================================================

    [x] Camera folowing style (Dropdown)
        CAMERA_FOLLOWING_STYLE
        OPTION_TOOLTIP_CAMERA1 = "Set the camera to stay where placed, except when your character is moving.";
        OPTION_TOOLTIP_CAMERA2 = "Set the camera to always prefer being behind your character.";
        OPTION_TOOLTIP_CAMERA3 = "Set the camera to stay where set, and never auto-adjust.";
        > Smart: Not set (unset cameraSmoothStyle)
        > Always: SET cameraSmoothStyle "2"
        > Never: SET cameraSmoothStyle "0"
        
        [x] Auto-Follow Speed (Slider)
            AUTO_FOLLOW_SPEED
            OPTION_TOOLTIP_AUTO_FOLLOW_SPEED
            > SET cameraYawSmoothSpeed "90" (90-270)

    [x] Follow terrain (Checkbox)
        FOLLOW_TERRAIN
        OPTION_TOOLTIP_FOLLOW_TERRAIN
        > SET cameraTerrainTilt "1"

    [x] Head bob (Check https://www.youtube.com/watch?v=daze59lSxaU&list=PLV2pwP80QXZIUpIW3S29333g58Q24TV-_&t=681sbox)
        HEAD_BOB
        OPTION_TOOLTIP_HEAD_BOB
        > SET cameraBobbing "1"

    [x] Water collision (Checkbox)
        WATER_COLLISION
        OPTION_TOOLTIP_WATER_COLLISION
        > SET cameraWaterCollision "1"

    [x] Smart pivot collision (Checkbox)
        SMART_PIVOT
        OPTION_TOOLTIP_SMART_PIVOT
        > SET cameraPivot "1"

    [x] Mouse look speed (Slider)
        MOUSE_LOOK_SPEED
        OPTION_TOOLTIP_MOUSE_LOOK_SPEED
        > SET cameraYawMoveSpeed "180" (90-270)

    [/] Max camera distance (Slider) - replaced by my module
        NOTE: This should be replaced with Module I already have.
        MAX_FOLLOW_DIST
        OPTION_TOOLTIP_MAX_FOLLOW_DIST
        > SET cameraDistanceMaxFactor "1"
        > Use module for this!



[x] COMBAT
======================================================

    * target of target goes to combat

    [x] Show target of target (checkbox)
        SHOW_TARGET_OF_TARGET_TEXT
        OPTION_TOOLTIP_SHOW_TARGET_OF_TARGET
        > SHOW_TARGET_OF_TARGET = "0"

        + Dropdown
            > Raid: SHOW_TARGET_OF_TARGET_STATE = 1
            > Party: SHOW_TARGET_OF_TARGET_STATE = 2
            > Solo: SHOW_TARGET_OF_TARGET_STATE = 3
            > Raid & Party: SHOW_TARGET_OF_TARGET_STATE = 4
            > Always: SHOW_TARGET_OF_TARGET_STATE = 5
    
    [x] Floating combat text


[x] ACTION BARS
======================================================

    [x] Lock action bars (Checkbox)
        LOCK_ACTIONBAR_TEXT
        OPTION_TOOLTIP_LOCK_ACTIONBAR
        > LOCK_ACTIONBAR = "0"

    [x] Always show actionbars (Checkbox)
        ALWAYS_SHOW_MULTIBARS_TEXT
        OPTION_TOOLTIP_ALWAYS_SHOW_MULTIBARS
        > ALWAYS_SHOW_MULTIBARS = "0"
    
    [x] Show actionbars (Checkbox)
        SHOW_MULTIBAR1_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR1
        SHOW_MULTIBAR2_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR2
        SHOW_MULTIBAR3_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR3
        SHOW_MULTIBAR4_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR4
        
        SHOW_MULTI_ACTIONBAR_1 = true
        SHOW_MULTI_ACTIONBAR_2 = true
        SHOW_MULTI_ACTIONBAR_3 = true
        SHOW_MULTI_ACTIONBAR_4 = true
        MultiActionBar_Update()
        MultiActionBar_ShowAllGrids()
        MultiActionBar_HideAllGrids()
    


[x] CHAT & SOCIAL
======================================================

    [x] Simple chat (Checkbox)
        SIMPLE_CHAT_TEXT
        OPTION_TOOLTIP_SIMPLE_CHAT
        > SIMPLE_CHAT = "1"

    [x] Lock chat settings (Checkbox)
        CHAT_LOCKED_TEXT
        OPTION_TOOLTIP_CHAT_LOCKED
        > CHAT_LOCKED = "1"

    [x] Guild member alert (Checkbox)
        GUILDMEMBER_ALERT
        OPTION_TOOLTIP_GUILDMEMBER_ALERT
        > SET guildMemberNotify "1"

    [x] Remove chat hover delay (Checkbox)
        REMOVE_CHAT_DELAY_TEXT
        OPTION_TOOLTIP_REMOVE_CHAT_DELAY
        > REMOVE_CHAT_DELAY = "1"

    [x] Show chat bubbles (Checkbox)
        CHAT_BUBBLES_TEXT
        OPTION_TOOLTIP_CHAT_BUBBLES
        > SET ChatBubbles "1"

    [x] Show party chat bubbles (Checkbox)
        PARTY_CHAT_BUBBLES_TEXT
        OPTION_TOOLTIP_PARTY_CHAT_BUBBLES
        > SET ChatBubblesParty "1"

    [x] Detailed loot information (Checkbox)
        SHOW_LOOT_SPAM
        OPTION_TOOLTIP_SHOW_LOOT_SPAM
        > SET showLootSpam "1"

    [x] Disable spam filter (Checkbox)
        DISABLE_SPAM_FILTER
        OPTION_TOOLTIP_DISABLE_SPAM_FILTER
        > SET spamFilter "1"

    [x] Profanity filter (Checkbox)
        PROFANITY_FILTER
        OPTION_TOOLTIP_PROFANITY_FILTER
        > SET profanityFilter "0"


[x] RAID & PARTY
======================================================

    * raid frames go here
    
    [x] Hide party interface in raid (checkbox)
        HIDE_PARTY_INTERFACE_TEXT
        OPTION_TOOLTIP_HIDE_PARTY_INTERFACE
        > HIDE_PARTY_INTERFACE = "1"
    
    [x] Show party background (Checkbox)
        SHOW_PARTY_BACKGROUND_TEXT
        OPTION_TOOLTIP_SHOW_PARTY_BACKGROUND
        > SHOW_PARTY_BACKGROUND = "1"

    [x] Show part memebers pets (checkbox)
        SHOW_PARTY_PETS_TEXT
        OPTION_TOOLTIP_SHOW_PARTY_PETS
        > SHOW_PARTY_PETS = "1"

    [x] Show dispellable debuffs (checkbox)
        SHOW_DISPELLABLE_DEBUFFS_TEXT
        OPTION_TOOLTIP_SHOW_DISPELLABLE_DEBUFFS
        > SHOW_DISPELLABLE_DEBUFFS = "1"

    [x] Show castable buffs (checkbox)
        SHOW_CASTABLE_BUFFS_TEXT
        OPTION_TOOLTIP_SHOW_CASTABLE_BUFFS
        > SHOW_CASTABLE_BUFFS = "1"



SUPERWOW
======================================================

 - New CVar "BackgroundSound" to enable or disable background sound while tabbed out (default = "0", can be "0" or "1")
 - New CVar "UncapSounds". set to "1" to remove the hardcoded soundchannels limit. If you want true uncapped sound experience you still have accompany this CVAR with setting "SoundSoftwareChannels" and "SoundMaxHardwareChannels" to a high number (either by lua function, config.wtf edit or using VanillaTweaks)
 - New CVar "FoV" to set camera field of view (default = "1.57", can be any value from "0.1" to "3.14")
 - New CVar "SelectionCircleStyle" to set a different appearance for the target circle.
 - New CVar "LootSparkle" to toggle Sparkling effect on lootable treasure.

OTHER HELPERS
======================================================

ResetTutorials();
ClearTutorials();
TutorialsEnabled()
TutorialFrame_HideAllAlerts()

UIOptionsCheckButtonTemplate
UIDropDownMenuTemplate
HideUIPanel(UIOptionsFrame);
