--------------------------------------
--submarine mod by krokoschlange,
--mostly based of PilzAdam's boats mod
--in the minetest_game 0.4.15
--------------------------------------


--checks for water in position pos
is_in_water = function(pos)
	local node = minetest.get_node(pos).name
	return minetest.get_item_group(node, "water") ~= 0
end

--launches the torpedo
shoot_torpedo = function(pos, yaw, launcher_submarine)
	local pname = launcher_submarine.driver:get_player_name()
	local inv = minetest.get_inventory({type="player", name=pname})
	if inv:contains_item("main", "submarines:torpedo") or minetest.setting_getbool("creative_mode") then
		if launcher_submarine.reloaded then
			inv:remove_item("main", "submarines:torpedo")
			launcher_submarine.reloaded = false
			local obj = minetest.env:add_entity(pos, "submarines:torpedo")
			obj:setyaw(yaw)
			minetest.after(2,function()
				launcher_submarine.reloaded = true
			end)
		end
	end
end

--reloads the submarine's torpedo
force_reload = function(launcher_submarine)
	launcher_submarine.reloaded = true
end


--------------------------------------------------------------------
--functions from D00Med's vehicles mod to detach players

local function force_detach(player)
	local attached_to = player:get_attach()
	if attached_to and attached_to:get_luaentity() then
		local entity = attached_to:get_luaentity()
		if entity.driver then
			if entity ~= nil then entity.driver = nil end
		end
		player:set_detach()
	end
	default.player_attached[player:get_player_name()] = false
	player:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
end

minetest.register_on_leaveplayer(function(player)
	force_detach(player)
end)

minetest.register_on_shutdown(function()
    local players = minetest.get_connected_players()
	for i = 1,#players do
		force_detach(players[i])
	end
end)

minetest.register_on_dieplayer(function(player)
	force_detach(player)
	return true
end)

--------------------------------------------------------------------

minetest.register_entity("submarines:submarine",{
	hp_max = 10,
	physical = true,
	collide_with_objects = true,
	collisionbox = {-1,-1,-1, 1,1,1},
	visual = "mesh",
	mesh = "submarine_new.b3d",
	textures = {"submarine.png","submarine.png"},
	driver = nil,
	speed = 0, --speed of the submarine
	vspeed = 0, --vertical speed of the submarine
	health = 2000,
	old_speed = 0,
	animation = 0,
	soundPing = nil,
	ping_sound_volume = minetest.setting_get("submarine_sonar_ping_volume") or 2.0,
	soundMotor = nil,
	
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		local name = clicker:get_player_name()
		if self.driver and clicker == self.driver then
			minetest.sound_stop(self.soundPing)
			minetest.sound_stop(self.soundMotor)
			self.driver = nil
			clicker:set_detach()
			default.player_attached[name] = false
			default.player_set_animation(clicker, "stand" , 30)
			clicker:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
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
			clicker:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
			minetest.after(0.2, function()
				default.player_set_animation(clicker, "sit" , 30)
			end)
			clicker:set_look_horizontal(self.object:getyaw())
			
			self.soundPing=minetest.sound_play({name="Sonar_Ping_with_Noise"},{object = self.object, gain = self.ping_sound_volume, max_hear_distance = 32, loop = true,})
			self.soundMotor=minetest.sound_play({name="motor"},{object = self.object, gain = 2.0, max_hear_distance = 32, loop = true,})
		end
	end,
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({fleshy = 100})
		force_reload(self)
		if staticdata then
			self.v = tonumber(staticdata)
		end
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
			
			--controls
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
			
			--torpedo launch
			if ctrl.aux1 then
				shoot_torpedo(self.object:getpos(),self.object:getyaw(),self)
			end
			
			--resistance
			if not ctrl.up and not ctrl.down then
				self.speed = self.speed * 0.9
			end
			if not ctrl.sneak and not ctrl.jump then
				self.vspeed = self.vspeed * 0.9
			end
			
			--prevent drowning
			self.driver:set_breath(11)
		end
		
		--resistance even if there is no driver
		if not self.driver then
			self.speed = self.speed * 0.9
			self.vspeed = self.vspeed * 0.9
		end
		--minimum and maximum speed
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
		
		--do not let the submarine be a helicopter
		if not is_in_water(self.object:getpos()) then
			if self.vspeed > 0 then
				self.vspeed = 0
			end
		end
		
		--setyaw and setvelocity functions
		self.object:setyaw(yaw)
		self.object:setvelocity({x = -math.sin(yaw) * self.speed, y = self.vspeed, z = math.cos(yaw) * self.speed})
		
		--add visual effects
		if self.animation >= self.old_speed * 12.5 then
			self.object:set_animation({x=1, y=20}, self.speed * 12.5, 0)
			self.old_speed = math.abs(self.speed)
			self.animation = 0
		else
			self.animation = self.animation + 1
		end
		
		if math.abs(self.speed) > 0 then
			minetest.add_particlespawner({
			amount = 1,
			time = 0.1,
			minpos = {x = 0, y = 0, z = 0},
			maxpos = {x = 0, y = 0, z = 0},
			minvel = {x = -0.2, y = 0, z = -0.2},
			maxvel = {x = 0.3, y = 0.3, z = 0.3},
			minacc = {x = 0, y = 0.1, z = 0},
			maxacc = {x = 0, y = 0.3, z = 0},
			minexptime = 1,
			maxexptime = 2.5,
			minsize = 1,
			maxsize = 4,
			attached = self.object,
			texture = "bubble.png",
		})
		end
		
		if self.vspeed < 0 then
			minetest.add_particlespawner({
			amount = 1,
			time = 0.1,
			minpos = {x = 0, y = 0, z = 0},
			maxpos = {x = 0, y = 0, z = 0},
			minvel = {x = -0.2, y = 0, z = -0.2},
			maxvel = {x = 0.3, y = 0.3, z = 0.3},
			minacc = {x = 0, y = 0.1, z = 0},
			maxacc = {x = 0, y = 0.3, z = 0},
			minexptime = 1,
			maxexptime = 2.5,
			minsize = 1,
			maxsize = 4,
			attached = self.object,
			texture = "bubble.png",
		})
		end
		
		--special health system for dropping a submarine item on destruction
		if self.object:get_hp() < 2000 then
			self.health = self.health - (2000 - self.object:get_hp())
			self.object:set_hp(2000)
			if self.health <= 0 then
				if self.driver then
					force_detach(self.driver)
					self.driver = nil
				end
				local wreck = minetest.add_entity(self.object:getpos(), "submarines:wreck")
				wreck:setyaw(self.object:getyaw())
				minetest.add_particle({
					pos = pos,
					velocity = {x = 0, y = 0, z = 0},
					acceleration = {x = 0, y = 0, z = 0},
					expirationtime = 0.9,
					size = 20,
					collisiondetection = false,
					vertical = false,
					texture = "tnt_boom.png",
				})
				self.object:remove()
				
			end
		end
		if self.object:get_hp() == 0 then
			if not self.driver  then
				force_detach(self.driver)
			end
		end
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
		submarine:setyaw(placer:get_look_horizontal())
			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
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



minetest.register_entity("submarines:torpedo",{
	hp_max = 10,
	physical = true,
	collide_with_objects = true,
	collisionbox = {-1,-1,-1, 1,1,1},
	visual = "mesh",
	mesh = "torpedo.b3d",
	textures = {"submarine.png","submarine.png"},
	speed = 6, --set this to whatever you want; changes the speed of the torpedo
	timer = 0, --the amount of steps after which the torpedo will become explosive; to prevent blowing up yourself
	sound = nil,
	
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		self.object:set_animation({x=1,y=20}, 100, 0)
		self.sound=minetest.sound_play({name="torpedo_launch"},{object = self.object, gain = 4.0, max_hear_distance = 32, loop = false,})
		minetest.after(2,function()
			self.sound=minetest.sound_play({name="torpedo"},{object = self.object, gain = 4.0, max_hear_distance = 32, loop = true,})
		end)
	end,
	
	on_step = function(self, dtime)
		minetest.add_particlespawner({
		amount = 1,
		time = 0.1,
		minpos = {x = 0, y = 0, z = 0},
		maxpos = {x = 0, y = 0, z = 0},
		minvel = {x = -0.2, y = 0, z = -0.2},
		maxvel = {x = 0.2, y = 0.3, z = 0.2},
		minacc = {x = 0, y = 0.1, z = 0},
		maxacc = {x = 0, y = 0.3, z = 0},
		minexptime = 1,
		maxexptime = 2.5,
		minsize = 1,
		maxsize = 4,
		attached = self.object,
		texture = "bubble.png",
	})
		self.object:setvelocity({x = -math.sin(self.object:getyaw()) * self.speed, y = 0, z = math.cos(self.object:getyaw()) * self.speed})
		
		local pos = self.object:getpos()
		local nodes = minetest.find_node_near(pos, 2, {"default:dirt", "default:sand", "default:stone", "default:clay"}) --the torpedo will explode if there are these nodes
		local all_objects = minetest.get_objects_inside_radius(pos, 3)
		local objects = {} --list of objects in a radius of 3; if there are any except for itself it explodes
		local _,object
		if self.timer > 30 then
			for _,object in ipairs(all_objects) do
				local myself = object == self.object
				if not myself then
					table.insert(objects, object)
				end
			end
			local noboom = next(objects) == nil
			
			if nodes then
				minetest.sound_stop(self.sound)
				tnt.boom(pos, {damage_radius=4,radius=1,ignore_protection=false})
				self.object:remove()
			end
			if not noboom then
				minetest.sound_stop(self.sound)
				tnt.boom(pos, {damage_radius=4,radius=1,ignore_protection=false})
				self.object:remove()
			end
		else
			self.timer = self.timer + 1
		end
		objects = {}
	end,
	
})


minetest.register_craftitem("submarines:torpedo",{
	description = "Torpedo",
	inventory_image = "torpedo_inv.png",
	wield_image = "torpedo_inv.png",
	liquids_pointable = true,
	groups = {},
	
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not is_in_water(pointed_thing.under) then
			return itemstack
		end
		torpedo = minetest.add_entity(pointed_thing.under, "submarines:torpedo")
		torpedo:setyaw(placer:get_look_horizontal())
		return itemstack
	end,
})

minetest.register_craft({
	output = "submarines:torpedo 2",
	recipe = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"   },
		{"boats:boat"       ,"tnt:tnt"          ,"fire:flint_and_steel"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"   },
	},
})

minetest.register_entity("submarines:wreck",{
	hp_max = 10,
	physical = true,
	collide_with_objects = true,
	collisionbox = {-1,-1,-1, 1,1,1},
	visual = "mesh",
	mesh = "submarine_wreck.b3d",
	textures = {"submarine_wreck.png","submarine_wreck.png"},
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		self.object:setvelocity({x = 0, y = -1.5, z = 0})
		self.object:setacceleration({x = 0, y = -0.1, z = 0})
		minetest.add_particlespawner({
		amount = 200,
		time = 0.1,
		minpos = {x = -0.5, y = -0.5, z = -0.5},
		maxpos = {x = 0.5, y = 0.5, z = 0.5},
		minvel = {x = -1, y = -1, z = -1},
		maxvel = {x = 1, y = 1, z = 1},
		minacc = {x = -0.5, y = -0.5, z = -0.5},
		maxacc = {x = 0.5, y = 0.5, z = 0.5},
		minexptime = 2,
		maxexptime = 2.5,
		minsize = 1,
		maxsize = 4,
		attached = self.object,
		texture = "submarine_particle.png",
		})
		minetest.add_particlespawner({
		amount = 200,
		time = 0.1,
		minpos = {x = -0.5, y = -0.5, z = -0.5},
		maxpos = {x = 0.5, y = 0.5, z = 0.5},
		minvel = {x = -1, y = -1, z = -1},
		maxvel = {x = 1, y = 1, z = 1},
		minacc = {x = -0.5, y = -0.5, z = -0.5},
		maxacc = {x = 0.5, y = 0.5, z = 0.5},
		minexptime = 2,
		maxexptime = 2.5,
		minsize = 1,
		maxsize = 4,
		attached = self.object,
		texture = "submarine_burst.png",
		})
	end,
	
	on_punch = function(self, puncher)
		if puncher:is_player() then
			local inv = puncher:get_inventory()
			if not minetest.setting_getbool("creative_mode")
					or not inv:contains_item("main", "default:steelblock") then
				local leftover = inv:add_item("main", "default:steelblock 8")
				-- if no room in inventory add a replacement submarine to the world
				if not leftover:is_empty() then
					minetest.add_item(self.object:getpos(), leftover)
				end
			end
			self.object:remove()
		end
	end,
	
	on_step = function(self, dtime)
		minetest.add_particlespawner({
		amount = 1,
		time = 0.1,
		minpos = {x = 0, y = 0, z = 0},
		maxpos = {x = 0, y = 0, z = 0},
		minvel = {x = -0.2, y = 0, z = -0.2},
		maxvel = {x = 0.2, y = 0.3, z = 0.2},
		minacc = {x = 0, y = 0.1, z = 0},
		maxacc = {x = 0, y = 0.3, z = 0},
		minexptime = 3,
		maxexptime = 3.5,
		minsize = 1,
		maxsize = 2,
		attached = self.object,
		texture = "bubble.png",
		})
	end
})








