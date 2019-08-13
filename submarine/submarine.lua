submarines:register_submarine("submarine",{
	----------submarine
	model = "submarine_new.b3d",
	textures = {"submarine.png","submarine.png","default_steel_block.png","gui_hotbar_edit.png","cross.png"},
	visual_size = {x = 0.8, y = 0.8},
	collisionbox = {-1,-1,-1, 1,1,1},
	max_speed = 4, -- maximum speed
	max_vspeed = 2, -- maximum vertical speed
	submarine_item_description = "Submarine",
	submarine_item_texture = "submarine_inv.png",
	submarine_craft = {
		{"default:steelblock", "default:steelblock", "default:steelblock"},
		{"default:steelblock", "default:mese",       "default:steelblock"},
		{"default:steelblock", "default:steelblock", "default:steelblock"},
	},
	view_offset = {x=0, y=-6, z=0},
	view_offset3rdprs = {x=0, y=0, z=0},
	player_offset = {x = 0, y = 12, z = 0},
	player_rotation = {x = 0, y = 0, z = 0},
	----------torpedo
	torpedo_model = "torpedo.b3d",
	torpedo_textures = {"submarine.png","submarine.png"},
	torpedo_item_name = "Torpedo",
	torpedo_item_texture = "torpedo_inv.png",
	torpedo_craft = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"   },
		{"boats:boat"       ,"tnt:tnt"          ,"fire:flint_and_steel"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"   },
	},
	----------wreck
	wreck_model = "submarine_wreck.b3d",
	wreck_textures = {"submarine_wreck.png","submarine_wreck.png","default_steel_block.png","gui_hotbar_edit.png","crack.png"},
	items_you_get_back = "default:steelblock 8",
})
