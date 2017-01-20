submarines:register_submarine("submarine",{
	----------submarine
	model = "submarine_new_new.b3d",
	textures = {"submarine.png","submarine.png","default_steel_block.png","gui_hotbar_edit.png","cross.png"},
	max_speed = 4, -- maximum speed
	max_vspeed = 2, -- maximum vertical speed
	submarine_item_description = "Submarine",
	submarine_item_texture = "submarine_inv.png",
	submarine_craft = {
		{"default:steelblock", "default:steelblock", "default:steelblock"},
		{"default:steelblock", "default:mese",       "default:steelblock"},
		{"default:steelblock", "default:steelblock", "default:steelblock"},
	},
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
	wreck_model = "submarine_wreck_new.b3d",
	wreck_textures = {"submarine_wreck.png","submarine_wreck.png","default_steel_block.png","gui_hotbar_edit.png","crack.png"},
	items_you_get_back = "default:steelblock 8",
})