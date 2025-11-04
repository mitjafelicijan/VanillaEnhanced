## VanillaTweaks:
SuperWoW is compatible with VanillaTweaks, though some features will overwrite each other.
- VanillaTweaks' hardcoded background sound and fov tweaks will be overwritten by SuperWoW's background sound and fov CVars (which can be changed ingame by typing /run SetCVar("cvarname", "newvalue").
- SuperWoW's autoloot mode lua function will be reversed by VanillaTweaks' reverse shift autoloot tweak.

## VanillaFixes:
The latest version of [VanillaFixes](https://github.com/hannesmann/vanillafixes) is automatically compatible with SuperWoW. Place `"SuperWoWhook.dll"` file in your game directory and launch the game from the VanillaFixes launcher.

## wowreeb launcher:
- Add this line to the <Realm> section of the wowreeb config file (editing the path appropriately):

`<DLL Path="path\to\SuperWoW\SuperWoWhook.dll" />`
- You can leave the <DLL /> tags for VfPatcher and/or nampower if you're using them, as SuperWoW won't conflict.