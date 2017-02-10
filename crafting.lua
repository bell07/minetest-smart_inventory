local cache = smart_inventory.cache

local function on_item_select(state, itemdef, recipe)
	if itemdef then
		state:get("info1"):setText(itemdef.description)
		state:get("info2"):setText("("..itemdef.name..")")
		state:get("info3"):setText("")
		if recipe.type ~="normal" then
			state:get("cr_type"):setText(recipe.type)
		else
			state:get("cr_type"):setText("")
		end
		state:get("craft_preview"):setCraft(recipe)
	else
		state:get("info1"):setText("")
		state:get("info2"):setText("")
		state:get("info3"):setText("")
		state:get("cr_type"):setText("")
		state:get("craft_preview"):setCraft(nil)
	end
end

local function update_craftable_list(state)
	state.param.craftable_list = {}
	state.param.group_list_labels = {}
	local player = state.location.rootState.location.player
	local craftable = cache:get_recipes_craftable(player)
	local duplicate_index_tmp = {}
	local group_list = {}
	for recipe, _ in pairs(craftable) do
		local def = minetest.registered_items[recipe.output]
		if not def then
			recipe.output:gsub("[^%s]+", function(z)
				if minetest.registered_items[z] then
					def = minetest.registered_items[z]
				end
			end)
		end
		if def then
			if duplicate_index_tmp[def] then
				table.insert(duplicate_index_tmp[def].recipes, recipe)
			else
				local entry = {
					itemdef=def,
					recipes = {},
					-- buttons_grid related
					item = def.name,
					is_button = true
				}
				duplicate_index_tmp[def] = entry
				for group, _ in pairs(def.groups) do
					if group_list[group] then
						group_list[group] = group_list[group] + 1
					else
						group_list[group] = 1
					end
				end

				if not state.param.selected_group or
						state.param.selected_group == "all" or
						def.groups[state.param.selected_group] then
					table.insert(entry.recipes, recipe)
					table.insert(state.param.craftable_list, entry)
				end
			end
		end
	end
	table.sort(state.param.craftable_list, function(a,b)
		return a.item < b.item
	end)
	local grid = state:get("buttons_grid")
	grid:setList(state.param.craftable_list)

	-- set group dropdown list

	local dropdown = state:get("groups")
	dropdown:clearItems()
	local group_tmp = {}
	for group, count in pairs(group_list) do
		if count > 1 then
			table.insert(group_tmp, {group = group, label = group.." ("..count..")"})
		end
	end
	table.sort(group_tmp, function(a,b)
		return a.label < b.label
	end)

	dropdown:addItem("all")
	for _, group in ipairs(group_tmp) do
		state.param.group_list_labels[group.label] = group.group
		dropdown:addItem(group.label)
	end
end

local function crafting_callback(state)
	local player = state.location.rootState.location.player
	--Inventorys / left site
	state:inventory(0.7, 6, 8, 4,"main")
	state:inventory(0.7, 0.5, 3, 3,"craft")
	state:inventory(4.1, 2.5, 1, 1,"craftpreview")
	state:background(0.6, 0.1, 4.6, 3.8, "img1", "menu_bg.png")

	local grid = smart_inventory.smartfs_elements.buttons_grid(state, 9, 5.5, 10 , 5, "buttons_grid")
	grid:onClick(function(self, state, index, player)
		local listentry = state.param.craftable_list[index]
		on_item_select(state, listentry.itemdef, listentry.recipes[1]) --TODO: recipes paging
	end)

	local group_dropdown = state:dropdown(5, 5, 4, 0.5, "groups")
	group_dropdown:onSelect(function(self, state, field, player)
		state.param.selected_group = state.param.group_list_labels[field]
		--TODO: BUG in case the list content is changed the formspec send the old id's, resulting the dropdown does not work
		--print("group selected", state.param.selected_group, field, dump(state.param.group_list_labels), dump(self.data.items))
		update_craftable_list(state)
	end)
	group_dropdown:setIsHidden(true) --not usable :(

	local refresh_button = state:button(17, 4.3, 2, 0.5, "refresh", "Refresh")
	refresh_button:onClick(function(self, state, player)
		update_craftable_list(state)
	end)

	-- preview part
	state:label(10.5,0.5,"info1", "")
	state:label(10.5,1.0,"info2", "")
	state:label(10.5,1.5,"info3", "")
	state:background(5.4, 0.1, 3.5, 3.8, "craft_img1", "menu_bg.png")
	state:background(9.0, 0.1, 10, 3.8, "craft_img2", "minimap_overlay_square.png")
	smart_inventory.smartfs_elements.craft_preview(state, 5.5, 0.5, "craft_preview")
	state:label(5.7,3,"cr_type", "")

	-- initial values
	update_craftable_list(state)
end

smart_inventory.register_page({
	name = "crafting",
	icon = "inventory_btn.png",
	smartfs_callback = crafting_callback,
	sequence = 10,
	on_button_click = update_craftable_list
})
