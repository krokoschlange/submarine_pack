destroyers:register_destroyer("destroyer",{
	----------submarine
	model = "destroyer.b3d",
	textures = {"submarine.png","submarine.png","submarine.png","default_wood.png","submarine.png","gui_hotbar_edit.png","default_steel_block.png","submarine.png"},
	visual_size = {x=0.5, y=0.5},
	collisionbox = {-1, -0.5, -1, 1, 0.3, 1},
	max_speed = 4, -- maximum speed
	destroyer_item_description = "Destroyer",
	destroyer_item_texture = "destroyer_inv.png",
	destroyer_craft = {
		{"",           "",           ""          },
		{"default:steelblock", "default:mese",           "default:steelblock"},
		{"default:steelblock", "default:steelblock", "default:steelblock"},
	},
	view_offset = {x=0, y=-2, z=0},
	view_offset3rdprs = {x=0, y=0, z=0},
	player_offset = {x = 0, y = 28, z = 0},
	player_rotation = {x = 0, y = 0, z = 0},
	----------depth_charge
	depth_charge_model = "depth_charge.b3d",
	depth_charge_textures = {"submarine.png"},
	depth_charge_item_name = "Depth charge",
	depth_charge_item_texture = "depth_charge_inv.png",
	depth_charge_craft = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		{"default:steel_ingot","tnt:tnt"            ,"default:steel_ingot"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
	},
	----------wreck
	wreck_model = "destroyer_wreck.b3d",
	wreck_visual_size = {x = 0.5, y = 0.5},
	wreck_collisionbox = {-1,-0.2,-1, 1,1,1},
	wreck_textures = {"submarine_wreck.png","submarine_wreck.png","submarine_wreck.png","default_wood.png","submarine_wreck.png","gui_hotbar_edit.png","default_steel_block.png","submarine_wreck.png"},
	items_you_get_back = "default:steelblock 5",
})