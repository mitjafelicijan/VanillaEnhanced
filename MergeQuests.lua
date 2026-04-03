-- MergeQuests.lua
--
-- Usage:
--   lua MergeQuests.lua [reference_root] [output_file]
--
-- Defaults:
--   reference_root = Reference
--   output_file    = Data/QuestZoneData.lua
--
-- The script loads the relevant pfQuest reference databases, applies the
-- TurtleWoW shallow patch rules, then emits a compact English-only quest area
-- database that is easy to consume from a small addon.

local unpack = table.unpack or unpack

local REFERENCE_ROOT = arg and arg[1] or "Reference"
local OUTPUT_FILE = arg and arg[2] or "Data/QuestZoneData.lua"

local DROP_CHANCE_MIN = 0
local MIN_RECT_SIZE = 6
local RECT_PADDING = 2

local DATA_DBS = {
	"items",
	"quests",
	"quests-itemreq",
	"objects",
	"units",
	"zones",
	"areatrigger",
	"refloot",
}

local ENGLISH_DBS = {
	"quests",
	"zones",
}

pfDB = {}
for _, db in ipairs(DATA_DBS) do
	pfDB[db] = {}
end

local function file_exists(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end

	return false
end

local function path_join(...)
	local parts = { ... }
	return table.concat(parts, "/")
end

local function load_file(path, required)
	if not file_exists(path) then
		if required then
			error("Missing required file: " .. path)
		end

		return
	end

	local chunk, err = loadfile(path)
	if not chunk then
		error(string.format("Failed to load %s: %s", path, err or "unknown error"))
	end

	local ok, runtime_err = pcall(chunk)
	if not ok then
		error(string.format("Failed to execute %s: %s", path, runtime_err or "unknown error"))
	end
end

local function patch_table(base, diff)
	if not diff then
		return
	end

	for key, value in pairs(diff) do
		if type(value) == "string" and value == "_" then
			base[key] = nil
		else
			base[key] = value
		end
	end
end

local function round(value, decimals)
	local power = 10 ^ (decimals or 0)
	return math.floor(value * power + 0.5) / power
end

local function clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end

	return value
end

local function shallow_copy(tbl)
	local out = {}
	for key, value in pairs(tbl or {}) do
		out[key] = value
	end
	return out
end

local function load_reference_data(root)
	local base_db_root = path_join(root, "pfQuest-main", "db")
	local turtle_db_root = path_join(root, "pfQuest-turtle-main", "db")

	local base_files = {
		"items.lua",
		"quests.lua",
		"quests-itemreq.lua",
		"objects.lua",
		"units.lua",
		"zones.lua",
		"areatrigger.lua",
		"refloot.lua",
		path_join("enUS", "quests.lua"),
		path_join("enUS", "zones.lua"),
	}

	local turtle_files = {
		"items-turtle.lua",
		"quests-turtle.lua",
		"quests-itemreq-turtle.lua",
		"objects-turtle.lua",
		"units-turtle.lua",
		"zones-turtle.lua",
		"areatrigger-turtle.lua",
		"refloot-turtle.lua",
		path_join("enUS", "quests-turtle.lua"),
		path_join("enUS", "zones-turtle.lua"),
	}

	for _, relative_path in ipairs(base_files) do
		load_file(path_join(base_db_root, relative_path), true)
	end

	for _, relative_path in ipairs(turtle_files) do
		load_file(path_join(turtle_db_root, relative_path), false)
	end
end

local function apply_turtle_patches()
	for _, db in ipairs(DATA_DBS) do
		local bucket = pfDB[db]
		patch_table(bucket["data"], bucket["data-turtle"])
	end

	for _, db in ipairs(ENGLISH_DBS) do
		local bucket = pfDB[db]
		patch_table(bucket["enUS"], bucket["enUS-turtle"])
	end
end

local quests
local quest_names
local zones
local zone_names
local units
local objects
local items
local refloot
local areatrigger
local quest_itemreq

local used_maps = {}
local used_areas = {}

local function mark_map(map_id)
	if map_id and map_id > 0 then
		used_maps[map_id] = true
	end
end

local function mark_area(area_id)
	if area_id and area_id > 0 then
		used_areas[area_id] = true
	end
end

local function new_location_group()
	return {
		maps = {},
		area_set = {},
	}
end

local function merge_bounds(bucket, x1, y1, x2, y2)
	bucket.x1 = bucket.x1 and math.min(bucket.x1, x1) or x1
	bucket.y1 = bucket.y1 and math.min(bucket.y1, y1) or y1
	bucket.x2 = bucket.x2 and math.max(bucket.x2, x2) or x2
	bucket.y2 = bucket.y2 and math.max(bucket.y2, y2) or y2
end

local function add_point(group, map_id, x, y)
	if not map_id or map_id <= 0 or not x or not y then
		return
	end

	mark_map(map_id)

	local bucket = group.maps[map_id]
	if not bucket then
		bucket = { count = 0 }
		group.maps[map_id] = bucket
	end

	merge_bounds(bucket, x, y, x, y)
	bucket.count = bucket.count + 1
end

local function add_rect(group, map_id, x, y, width, height)
	if not map_id or map_id <= 0 or not x or not y or not width or not height then
		return
	end

	mark_map(map_id)

	local bucket = group.maps[map_id]
	if not bucket then
		bucket = { count = 0 }
		group.maps[map_id] = bucket
	end

	local half_width = width / 2
	local half_height = height / 2
	merge_bounds(bucket, x - half_width, y - half_height, x + half_width, y + half_height)
	bucket.count = bucket.count + 1
end

local function add_area(group, area_id)
	if not area_id or area_id <= 0 or group.area_set[area_id] then
		return
	end

	group.area_set[area_id] = true
	mark_area(area_id)

	local area = zones[area_id]
	if not area then
		return
	end

	local map_id, width, height, x, y = unpack(area)
	add_rect(group, map_id, x, y, width, height)
end

local function add_unit_coords(group, unit_id)
	local unit = units[unit_id]
	if not unit or not unit.coords then
		return
	end

	for _, coord in pairs(unit.coords) do
		local x, y, map_id = coord[1], coord[2], coord[3]
		add_point(group, map_id, x, y)
	end
end

local function add_object_coords(group, object_id)
	local object = objects[object_id]
	if not object or not object.coords then
		return
	end

	for _, coord in pairs(object.coords) do
		local x, y, map_id = coord[1], coord[2], coord[3]
		add_point(group, map_id, x, y)
	end
end

local function add_areatrigger_coords(group, trigger_id)
	local trigger = areatrigger[trigger_id]
	if not trigger or not trigger.coords then
		return
	end

	for _, coord in pairs(trigger.coords) do
		local x, y, map_id = coord[1], coord[2], coord[3]
		add_point(group, map_id, x, y)
	end
end

local function above_min_drop_chance(chance)
	return (tonumber(chance) or 0) >= DROP_CHANCE_MIN
end

local function add_item_sources(group, item_id)
	local item = items[item_id]
	if not item then
		return
	end

	if item.U then
		for unit_id, chance in pairs(item.U) do
			if above_min_drop_chance(chance) then
				add_unit_coords(group, unit_id)
			end
		end
	end

	if item.O then
		for object_id, chance in pairs(item.O) do
			local numeric_chance = tonumber(chance) or 0
			if numeric_chance > 0 and numeric_chance >= DROP_CHANCE_MIN then
				add_object_coords(group, object_id)
			end
		end
	end

	if item.R then
		for ref_id, chance in pairs(item.R) do
			if above_min_drop_chance(chance) and refloot[ref_id] then
				local ref = refloot[ref_id]

				if ref.U then
					for unit_id in pairs(ref.U) do
						add_unit_coords(group, unit_id)
					end
				end

				if ref.O then
					for object_id in pairs(ref.O) do
						add_object_coords(group, object_id)
					end
				end
			end
		end
	end

	if item.V then
		for unit_id in pairs(item.V) do
			add_unit_coords(group, unit_id)
		end
	end
end

local function add_item_requirement_targets(group, item_id)
	local requirement = quest_itemreq[item_id]
	if not requirement then
		return
	end

	for target_id in pairs(requirement) do
		local numeric_target = tonumber(target_id)
		if numeric_target then
			if numeric_target < 0 then
				add_object_coords(group, math.abs(numeric_target))
			elseif numeric_target > 0 then
				add_unit_coords(group, numeric_target)
			end
		end
	end
end

local function collect_units(group, ids)
	if not ids then
		return
	end

	for _, unit_id in pairs(ids) do
		add_unit_coords(group, unit_id)
	end
end

local function collect_objects(group, ids)
	if not ids then
		return
	end

	for _, object_id in pairs(ids) do
		add_object_coords(group, object_id)
	end
end

local function collect_areatriggers(group, ids)
	if not ids then
		return
	end

	for _, trigger_id in pairs(ids) do
		add_areatrigger_coords(group, trigger_id)
	end
end

local function collect_items(group, ids)
	if not ids then
		return
	end

	for _, item_id in pairs(ids) do
		add_item_sources(group, item_id)
	end
end

local function collect_item_requirements(group, ids)
	if not ids then
		return
	end

	for _, item_id in pairs(ids) do
		add_item_requirement_targets(group, item_id)
	end
end

local function collect_explicit_areas(group, ids)
	if not ids then
		return
	end

	for _, area_id in pairs(ids) do
		add_area(group, area_id)
	end
end

local function finalize_map_bucket(bucket)
	if not bucket.x1 or not bucket.y1 or not bucket.x2 or not bucket.y2 then
		return nil
	end

	local x1 = bucket.x1
	local y1 = bucket.y1
	local x2 = bucket.x2
	local y2 = bucket.y2

	local center_x = (x1 + x2) / 2
	local center_y = (y1 + y2) / 2
	local width = math.max((x2 - x1) + RECT_PADDING * 2, MIN_RECT_SIZE)
	local height = math.max((y2 - y1) + RECT_PADDING * 2, MIN_RECT_SIZE)

	x1 = clamp(center_x - width / 2, 0, 100)
	y1 = clamp(center_y - height / 2, 0, 100)
	x2 = clamp(center_x + width / 2, 0, 100)
	y2 = clamp(center_y + height / 2, 0, 100)

	width = x2 - x1
	height = y2 - y1
	center_x = x1 + width / 2
	center_y = y1 + height / 2

	return {
		x = round(center_x, 2),
		y = round(center_y, 2),
		width = round(width, 2),
		height = round(height, 2),
		count = bucket.count,
	}
end

local function sorted_keys(tbl)
	local keys = {}
	for key in pairs(tbl) do
		keys[#keys + 1] = key
	end

	table.sort(keys, function(left, right)
		local left_type = type(left)
		local right_type = type(right)

		if left_type == right_type then
			if left_type == "number" or left_type == "string" then
				return left < right
			end

			return tostring(left) < tostring(right)
		end

		if left_type == "number" then
			return true
		elseif right_type == "number" then
			return false
		end

		return left_type < right_type
	end)

	return keys
end

local function set_to_sorted_array(set)
	local values = {}
	for value in pairs(set or {}) do
		values[#values + 1] = value
	end
	table.sort(values)
	return values
end

local function finalize_group(group)
	local out = {}

	if next(group.maps) then
		out.maps = {}

		for map_id, bucket in pairs(group.maps) do
			local finalized = finalize_map_bucket(bucket)
			if finalized then
				out.maps[map_id] = finalized
			end
		end
	end

	if next(group.area_set) then
		out.areas = set_to_sorted_array(group.area_set)
	end

	if next(out) then
		return out
	end

	return nil
end

local function build_quest_entry(quest_id, quest)
	local objective = new_location_group()
	local turnin = new_location_group()
	local start = new_location_group()

	if quest["start"] then
		collect_units(start, quest["start"]["U"])
		collect_objects(start, quest["start"]["O"])
		collect_items(start, quest["start"]["I"])
	end

	if quest["end"] then
		collect_units(turnin, quest["end"]["U"])
		collect_objects(turnin, quest["end"]["O"])
	end

	if quest["obj"] then
	collect_units(objective, quest["obj"]["U"])
	collect_objects(objective, quest["obj"]["O"])
	collect_areatriggers(objective, quest["obj"]["A"])
	collect_items(objective, quest["obj"]["I"])
	collect_item_requirements(objective, quest["obj"]["IR"])
	collect_explicit_areas(objective, quest["obj"]["Z"])
end

	local objective_out = finalize_group(objective)
	local turnin_out = finalize_group(turnin)
	local start_out = finalize_group(start)

	if not objective_out and not turnin_out and not start_out then
		return nil
	end

	local faction = 3 -- 1: Alliance, 2: Horde, 3: Neutral
	local race = quest["race"] or 0
	if race > 0 then
		-- Alliance bits: 1, 4, 8, 64, 512 (Human, Dwarf, NightElf, Gnome, HighElf)
		-- Horde bits: 2, 16, 32, 128, 256 (Orc, Undead, Tauren, Troll, Goblin)
		local isAlliance = (race == 1 or race == 4 or race == 8 or race == 64 or race == 512 or race == 77 or race == 589)
		local isHorde = (race == 2 or race == 16 or race == 32 or race == 128 or race == 256 or race == 178 or race == 434)
		
		-- Fallback for combined masks
		if not isAlliance and not isHorde then
			if race % 2 == 1 or math.floor(race/4) % 2 == 1 or math.floor(race/8) % 2 == 1 or math.floor(race/64) % 2 == 1 or math.floor(race/512) % 2 == 1 then
				faction = 1
			elseif math.floor(race/2) % 2 == 1 or math.floor(race/16) % 2 == 1 or math.floor(race/32) % 2 == 1 or math.floor(race/128) % 2 == 1 or math.floor(race/256) % 2 == 1 then
				faction = 2
			end
		elseif isAlliance then
			faction = 1
		elseif isHorde then
			faction = 2
		end
	end

	local classReq = 0 -- 0: All, 1: Warrior, 2: Paladin, 3: Hunter, 4: Rogue, 5: Priest, 6: Shaman, 7: Mage, 8: Warlock, 9: Druid
	local classMask = quest["class"] or 0
	if classMask > 0 then
		if classMask == 1 then classReq = 1
		elseif classMask == 2 then classReq = 2
		elseif classMask == 4 then classReq = 3
		elseif classMask == 8 then classReq = 4
		elseif classMask == 16 then classReq = 5
		elseif classMask == 64 then classReq = 6
		elseif classMask == 128 then classReq = 7
		elseif classMask == 256 then classReq = 8
		elseif classMask == 1024 then classReq = 9
		end
	end

	local entry = {
		title = quest_names[quest_id] and quest_names[quest_id].T or nil,
		objText = quest_names[quest_id] and quest_names[quest_id].O or nil,
		lvl = quest["lvl"],
		min = quest["min"],
		faction = faction,
		class = classReq,
	}

if objective_out then
	entry.objective = objective_out
end

	if turnin_out then
		entry.turnin = turnin_out
	end

	if start_out then
		entry.available = start_out
	end

	return entry
end

local function build_output()
	quests = pfDB["quests"]["data"] or {}
	quest_names = pfDB["quests"]["enUS"] or {}
	zones = pfDB["zones"]["data"] or {}
	zone_names = pfDB["zones"]["enUS"] or {}
	units = pfDB["units"]["data"] or {}
	objects = pfDB["objects"]["data"] or {}
	items = pfDB["items"]["data"] or {}
	refloot = pfDB["refloot"]["data"] or {}
	areatrigger = pfDB["areatrigger"]["data"] or {}
	quest_itemreq = pfDB["quests-itemreq"]["data"] or {}

	local out = {
		meta = {
			generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			source = "pfQuest-main + pfQuest-turtle-main",
			english_only = true,
			rect_padding = RECT_PADDING,
			min_rect_size = MIN_RECT_SIZE,
			min_drop_chance = DROP_CHANCE_MIN,
		},
		maps = {},
		areas = {},
		quests = {},
	}

	for quest_id, quest in pairs(quests) do
		local entry = build_quest_entry(quest_id, quest)
		if entry then
			out.quests[quest_id] = entry
		end
	end

	for area_id in pairs(used_areas) do
		local area = zones[area_id]
		if area then
			local map_id, width, height, x, y = unpack(area)
			mark_map(map_id)
			out.areas[area_id] = {
				name = zone_names[area_id] or ("Area " .. area_id),
				map = map_id,
				x = round(x, 2),
				y = round(y, 2),
				width = round(width, 2),
				height = round(height, 2),
			}
		end
	end

	for map_id in pairs(used_maps) do
		out.maps[map_id] = zone_names[map_id] or ("Zone " .. map_id)
	end

	out.meta.quest_count = 0
	for _ in pairs(out.quests) do
		out.meta.quest_count = out.meta.quest_count + 1
	end

	out.meta.map_count = 0
	for _ in pairs(out.maps) do
		out.meta.map_count = out.meta.map_count + 1
	end

	out.meta.area_count = 0
	for _ in pairs(out.areas) do
		out.meta.area_count = out.meta.area_count + 1
	end

	return out
end

local function is_identifier(str)
	return type(str) == "string" and str:match("^[_%a][_%w]*$") ~= nil
end

local function serialize(value, indent)
	indent = indent or ""
	local value_type = type(value)

	if value_type == "nil" then
		return "nil"
	elseif value_type == "number" then
		return tostring(value)
	elseif value_type == "boolean" then
		return value and "true" or "false"
	elseif value_type == "string" then
		return string.format("%q", value)
	elseif value_type ~= "table" then
		error("Unsupported value type in serializer: " .. value_type)
	end

	local keys = sorted_keys(value)
	if #keys == 0 then
		return "{}"
	end

	local next_indent = indent .. "  "
	local chunks = { "{" }

	for _, key in ipairs(keys) do
		local key_repr
		if type(key) == "string" and is_identifier(key) then
			key_repr = key
		else
			key_repr = "[" .. serialize(key, next_indent) .. "]"
		end

		chunks[#chunks + 1] = string.format("\n%s%s = %s,", next_indent, key_repr, serialize(value[key], next_indent))
	end

	chunks[#chunks + 1] = "\n" .. indent .. "}"
	return table.concat(chunks)
end

local function write_output(path, data)
	local file, err = io.open(path, "w")
	if not file then
		error(string.format("Failed to open %s for writing: %s", path, err or "unknown error"))
	end

	file:write("-- Generated by MergeQuests.lua. Do not edit by hand.\n")
	file:write("-- Faction IDs: 1=Alliance, 2=Horde, 3=Neutral\n")
	file:write("-- Class IDs: 0=All, 1=Warrior, 2=Paladin, 3=Hunter, 4=Rogue, 5=Priest, 6=Shaman, 7=Mage, 8=Warlock, 9=Druid\n")
	file:write("QuestZoneData = ")
	file:write(serialize(data))
	file:write("\n")
	file:close()
end

local function main()
	load_reference_data(REFERENCE_ROOT)
	apply_turtle_patches()

	local output = build_output()
	write_output(OUTPUT_FILE, output)

	print(string.format(
		"Wrote %s with %d quests, %d maps, %d areas.",
		OUTPUT_FILE,
		output.meta.quest_count,
		output.meta.map_count,
		output.meta.area_count
	))
end

main()
