--------------------------------------
--submarine mod by krokoschlange,
--mostly based of PilzAdam's boats mod
--in the minetest_game 0.4.15
--------------------------------------
submarines = {}

--------------------------------------------------------------------
--checks for water in position pos
is_in_water = function(pos)
	local node = minetest.get_node(pos).name
	return minetest.get_item_group(node, "water") ~= 0
end

--launches the torpedo
shoot_torpedo = function(pos, yaw, launcher_submarine, torpedo_type)
	local pname = launcher_submarine.driver:get_player_name()
	local inv = minetest.get_inventory({type="player", name=pname})
	if inv:contains_item("main", torpedo_type) or minetest.setting_getbool("creative_mode") then
		if launcher_submarine.reloaded then
			inv:remove_item("main", torpedo_type)
			launcher_submarine.reloaded = false
			local obj = minetest.env:add_entity(pos, torpedo_type)
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

--attach player
local function attach(player, entity)
	local attach = player:get_attach()
	if attach and attach:get_luaentity() then
		local luaentity = attach:get_luaentity()
		if luaentity.driver then
			luaentity.driver = nil
		end
		player:set_detach()
	end
	entity.driver = player
	player:set_attach(entity.object, "",
		{x = 0, y = 12, z = 0}, {x = 0, y = 0, z = 0})
	player:set_nametag_attributes({
		color = {a = 0, r = 255, g = 255, b = 255}
	})
	default.player_attached[player:get_player_name()] = true
	player:set_eye_offset({x=0, y=-6, z=0}, {x=0, y=0, z=0})
	minetest.after(0.2, function()
		default.player_set_animation(player, "sit" , 30)
	end)
	player:set_look_horizontal(entity.object:getyaw())
end
--------------------------------------------------------------------
--------------------------------------------------------------------
--functions from D00Med's vehicles mod to detach players

local function force_detach(player)
	local attached_to = player:get_attach()
	if attached_to and attached_to:get_luaentity() then
		local entity = attached_to:get_luaentity()
		if entity.driver then
			if entity ~= nil then 
				entity.driver = nil
				minetest.sound_stop(entity.soundPing)
				minetest.sound_stop(entity.soundMotor)
			end
		end
		player:set_detach()
		player:set_nametag_attributes({
			color = {a = 255, r = 255, g = 255, b = 255}
		})
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
--------------------------------------------------------------------

function submarines:register_submarine(name, prototype)
	minetest.register_entity("submarines:"..name, {
		hp_max = 10,
		physical = true,
		collide_with_objects = true,
		collisionbox = {-1,-1,-1, 1,1,1},
		visual = "mesh",
		visual_size = {x = 0.8, y = 0.8},
		mesh = prototype.model,
		textures = prototype.textures,
		driver = nil,
		speed = 0, --speed of the submarine
		vspeed = 0, --vertical speed of the submarine
		max_speed = prototype.max_speed or 6,
		max_vspeed = prototype.max_vspeed or 4,
		health = 2000,
		old_speed = 0,
		animation = 0,
		soundPing = nil,
		ping_sound_volume = minetest.setting_get("submarine_sonar_ping_volume") or 2.0,
		soundMotor = nil,
		r3ckt = false,
		
		on_rightclick = function(self, clicker)
			if not clicker or not clicker:is_player() then
				return
			end
			if self.driver and clicker == self.driver then
				force_detach(clicker)
			elseif not self.driver then
				attach(clicker, self)
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
				force_detach(puncher)
			else
				self.object:set_hp(2000)
			end
			if not self.driver then
				self.r3ckt = true
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
					shoot_torpedo(self.object:getpos(), self.object:getyaw(), self, "submarines:"..name.."_torpedo")
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
			if math.abs(self.speed) > self.max_speed then
				if self.speed < 0 then
					self.speed = self.max_speed * -1
				else
					self.speed = self.max_speed
				end
			end
			
			if math.abs(self.vspeed ) < 0.04 then
				self.vspeed = 0
			end
			if math.abs(self.vspeed) > self.max_vspeed then
				if self.vspeed < 0 then
					self.vspeed = self.max_vspeed * -1
				else
					self.vspeed = self.max_vspeed
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
					if not self.r3ckt then
						self.r3ckt = true
						local wreck = minetest.add_entity(self.object:getpos(), "submarines:"..name .."wreck")
						wreck:setyaw(self.object:getyaw())
						if self.driver then
							local name = self.driver:get_player_name()
							local attached_to = self.driver:get_attach()
							if attached_to and attached_to:get_luaentity() then
								self.driver:set_detach()
								self.driver:set_nametag_attributes({
									color = {a = 255, r = 255, g = 255, b = 255}
								})
							end
							self.driver:set_eye_offset({x=0, y=-6, z=0}, {x=0, y=0, z=0})
							self.driver:set_attach(wreck, "",
								{x = 0, y = 12, z = 0}, {x = 0, y = 0, z = 0})
							default.player_attached[name] = true
							self.driver = nil
							minetest.sound_stop(self.soundMotor)
							minetest.sound_stop(self.soundPing)
						end
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
						minetest.after(0.2,function()
							self.object:remove()
						end)
					end
				end
			end
			if self.object:get_hp() == 0 then
				if not self.driver  then
					force_detach(self.driver)
				end
			end
		end,
	})
	
	minetest.register_craftitem("submarines:"..name,{
		description = prototype.submarine_item_description,
		inventory_image = prototype.submarine_item_texture,
		wield_image = prototype.submarine_item_texture,
		liquids_pointable = true,
		groups = {},
		
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end
			if not is_in_water(pointed_thing.under) then
				return itemstack
			end
			submarine = minetest.add_entity(pointed_thing.under, "submarines:"..name)
			submarine:setyaw(placer:get_look_horizontal())
				if not minetest.setting_getbool("creative_mode") then
					itemstack:take_item()
				end
			return itemstack
		end,
	})

	minetest.register_craft({
		output = "submarines:"..name,
		recipe = prototype.submarine_craft,
	})
	
	--------------------------------------------------------------------
	--------------------------------------------------------------------

	minetest.register_entity("submarines:"..name.."_torpedo",{
		hp_max = 10,
		physical = true,
		collide_with_objects = true,
		collisionbox = {-1,-1,-1, 1,1,1},
		visual = "mesh",
		mesh = prototype.torpedo_model,
		textures = prototype.torpedo_textures,
		speed = 6, --set this to whatever you want; changes the speed of the torpedo
		timer = 0, --the amount of steps after which the torpedo will become explosive; to prevent blowing up yourself
		sound = nil,
		exploded = false,
		
		
		on_activate = function(self, staticdata, dtime_s)
			self.object:set_armor_groups({immortal = 1})
			self.object:set_animation({x=1,y=20}, 100, 0)
			self.sound=minetest.sound_play({name="torpedo_launch"},{object = self.object, gain = 4.0, max_hear_distance = 32, loop = false,})
			if not self.exploded then
				self.sound=minetest.sound_play({name="torpedo"},{object = self.object, gain = 4.0, max_hear_distance = 32, loop = false,})
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
			local _, object
			if self.timer > 30 then
				for _,object in ipairs(all_objects) do
					local myself = object == self.object
					if not myself then
						table.insert(objects, object)
					end
				end
				local noboom = next(objects) == nil
				
				if nodes or not noboom then
					if not exploded then
						tnt.boom(pos, {damage_radius=4,radius=1,ignore_protection=false})
						minetest.sound_stop(self.sound)
						self.exploded = true
						minetest.after(0.2,function()
							self.object:remove()
						end)
					end
				end
			else
				self.timer = self.timer + 1
			end
			objects = {}
		end,
	})
	
	minetest.register_craftitem("submarines:torpedo",{
		description = prototype.torpedo_item_name,
		inventory_image = prototype.torpedo_item_texture,
		wield_image = prototype.torpedo_item_texture,
		liquids_pointable = true,
		groups = {},
		
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end
			if not is_in_water(pointed_thing.under) then
				return itemstack
			end
			torpedo = minetest.add_entity(pointed_thing.under, "submarines:"..name.."torpedo")
			torpedo:setyaw(placer:get_look_horizontal())
			return itemstack
		end,
	})

	minetest.register_craft({
		output = "submarines:torpedo 2",
		recipe = prototype.torpedo_craft,
	})
	
	--------------------------------------------------------------------
	--------------------------------------------------------------------

	
	minetest.register_entity("submarines:"..name.."_wreck",{
		hp_max = 10,
		physical = true,
		collide_with_objects = true,
		collisionbox = {-1,-1,-1, 1,1,1},
		visual = "mesh",
		mesh = prototype.wreck_model,
		textures = prototype.wreck_textures,
		attached = nil,
		
		on_rightclick = function(self, clicker)
			if not clicker or not clicker:is_player() then
				return
			end
			local name = clicker:get_player_name()
			local attach = clicker:get_attach()
			if attach then
				if attach:get_luaentity() == self then
					force_detach(clicker)
					self.attach = nil
				end
			end
		end,
		
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
			local all_objects = minetest.get_objects_inside_radius(pos, 3)
			local _, object
			for _,object in ipairs(all_objects) do
				local attach = object:get_attach()
				if attach then
					if attach:get_luaentity() == self then
						self.attached = object:get_luaentity()
					end
				end
			end
		end,
		on_punch = function(self, puncher)
			if not self.attached then
				if puncher:is_player() then
					local inv = puncher:get_inventory()
					if not minetest.setting_getbool("creative_mode")
							or not inv:contains_item("main", prototype.items_you_get_back) then
						local leftover = inv:add_item("main", prototype.items_you_get_back)
						-- if no room in inventory add a replacement submarine to the world
						if not leftover:is_empty() then
							minetest.add_item(self.object:getpos(), leftover)
						end
					end
					local attach = puncher:get_attach()
					if attach then
						if attach:get_luaentity() == self then
							default.player_set_animation(puncher, "stand", 30)
						end
					end
					self.object:remove()
				end
			end
		end,
		
		on_step = function(self, dtime)
			self.object:setvelocity({x = 0, y = self.object:getvelocity().y, z = 0})
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
end
