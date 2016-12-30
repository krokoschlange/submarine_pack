is_in_water = function(pos)
	node = minetest.get_node(pos).name
	return minetest.get_item_group(node, "water") ~= 0
end

minetest.register_entity("submarines:submarine",{
	hpmax = 10,
	physical = true,
	collide_with_objects = true,
	collisionbox = {-1,-1,-1, 1,1,1},
	visual = "mesh",
	mesh = "submarine_uv_new.obj",
	textures = {"submarine.png"},
	driver = nil,
	speed = 0,
	vspeed = 0,
	
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		local name = clicker:get_player_name()
		if self.driver and clicker == self.driver then
			self.driver = nil
			clicker:set_detach()
			default.player_attached[name] = false
			default.player_set_animation(clicker, "stand" , 30)
			local pos = clicker:getpos()
			pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
			minetest.after(0.1, function()
				clicker:setpos(pos)
			end)
		elseif not self.driver then
			local attach = clicker:get_attach()
			if attach and attach:get_luaentity() then
				local luaentity = attach:get_luaentity()
				if luaentity.driver then
					luaentity.driver = nil
				end
				clicker:set_detach()
			end
			self.driver = clicker
			clicker:set_attach(self.object, "",
				{x = 0, y = 4, z = 0}, {x = 0, y = 0, z = 0})
			default.player_attached[name] = true
			minetest.after(0.2, function()
				default.player_set_animation(clicker, "sit" , 30)
			end)
			clicker:set_look_horizontal(self.object:getyaw())
		end
	end,
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		if staticdata then
			self.v = tonumber(staticdata)
		end
		self.last_v = self.v
	end,
	
	get_staticdata = function(self)
		return tostring(self.v)
	end,
	
	on_punch = function(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then
			return
		end
		if self.driver and puncher == self.driver then
			self.driver = nil
			puncher:set_detach()
			default.player_attached[puncher:get_player_name()] = false
		end
		if not self.driver then
			self.removed = true
			local inv = puncher:get_inventory()
			if not minetest.setting_getbool("creative_mode")
					or not inv:contains_item("main", "submarines:submarine") then
				local leftover = inv:add_item("main", "submarines:submarine")
				-- if no room in inventory add a replacement submarine to the world
				if not leftover:is_empty() then
					minetest.add_item(self.object:getpos(), leftover)
				end
			end
			-- delay remove to ensure player is detached
			minetest.after(0.1, function()
				self.object:remove()
			end)
		end
	end,
	
	on_step = function(self, dtime)
		local yaw = self.object:getyaw()
		local pos = self.object:getpos()
		if self.driver then
			local ctrl = self.driver:get_player_control()
			
			
			if ctrl.up then
				self.speed = self.speed + 0.1
			elseif ctrl.down then
				self.speed = self.speed - 0.1
			end
			
			if ctrl.jump then
				self.vspeed = self.vspeed + 0.05
			elseif ctrl.sneak then
				self.vspeed = self.vspeed - 0.05
			end
			
			if ctrl.left then
				if self.speed >= 0 then
					yaw = yaw + 0.03
				else
					yaw = yaw - 0.03
				end
			elseif ctrl.right then
				if self.speed >= 0 then
					yaw = yaw - 0.03
				else
					yaw = yaw + 0.03
				end
			end
			if not ctrl.up then
				self.speed = self.speed * 0.9
			end
			if not ctrl.down then
				self.speed = self.speed * 0.9
			end
			if not ctrl.sneak then
				self.speed = self.speed * 0.9
			end
			if not ctrl.jump then
				self.vspeed = self.vspeed * 0.9
			end
			
			self.driver:set_breath(11)
		end
		
		if math.abs(self.speed ) < 0.09 then
			self.speed = 0
		end
		if math.abs(self.speed) > 4 then
			if self.speed < 0 then
				self.speed = -4
			else
				self.speed = 4
			end
		end
		
		if math.abs(self.vspeed ) < 0.04 then
			self.vspeed = 0
		end
		if math.abs(self.vspeed) > 2 then
			if self.vspeed < 0 then
				self.vspeed = -2
			else
				self.vspeed = 2
			end
		end
		
		if not is_in_water(self.object:getpos()) then
			if self.vspeed > 0 then
				self.vspeed = 0
			end
		end
		self.object:setyaw(yaw)
		self.object:setvelocity({x = -math.sin(yaw) * self.speed, y = self.vspeed, z = math.cos(yaw) * self.speed})
	end,
			
})

minetest.register_craftitem("submarines:submarine",{
	description = "Submarine",
	inventory_image = "submarine_inv.png",
	wield_image = "submarine_inv.png",
	liquids_pointable = true,
	groups = {},
	
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not is_in_water(pointed_thing.under) then
			return itemstack
		end
		submarine = minetest.add_entity(pointed_thing.under, "submarines:submarine")
		return itemstack
	end,
})

minetest.register_craft({
	output = "submarines:submarine",
	recipe = {
		{"default:steelblock", "default:steelblock", "default:steelblock"},
		{"default:steelblock", "default:mese",       "default:steelblock"},
		{"default:steelblock", "default:steelblock", "default:steelblock"},
	},
})




















