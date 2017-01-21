--------------------------------------
--submarine destroyer mod for minetest
--------------------------------------
 destroyers = {}
--Helper functions

local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end


local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end


local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end


local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

--drops the water bombs
drop_depth_charge = function(pos, yaw, destroyer, driver,depth_charge_type)
	local pname = destroyer.driver:get_player_name()
	local inv = minetest.get_inventory({type="player", name=pname})
	if inv:contains_item("main", depth_charge_type) or minetest.setting_getbool("creative_mode") then
		if destroyer.reloaded then
			destroyer.reloaded = false
			inv:remove_item("main", depth_charge_type)
			local obj = minetest.env:add_entity(pos, depth_charge_type)
			obj:setyaw(yaw)
			minetest.after(0.9,function()
				destroyer.reloaded = true
			end)
		end
	end

end

--reloads the destroyer's water bombs
force_reload = function(destroyer)
	destroyer.reloaded = true
end

--attach player
local function attach(player, entity, view_offset, view_offset3rdprs, player_offset, player_rotation)
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
		{x = player_offset.x, y = player_offset.y, z = player_offset.z}, {x = player_rotation.x, y = player_rotation.y, z = player_rotation.z})
	player:set_nametag_attributes({
		color = {a = 0, r = 255, g = 255, b = 255}
	})
	default.player_attached[player:get_player_name()] = true
	player:set_eye_offset({x = view_offset.x, y = view_offset.y, z = view_offset.z},{x = view_offset3rdprs.x, y = view_offset3rdprs.y, z = view_offset3rdprs.z})
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

function destroyers:register_destroyer(name, prototype)

	local destroyer = {
		max_hp = 10,
		physical = true,
		collisionbox = prototype.collisionbox,
		visual = "mesh",
		visual_size = prototype.visual_size,
		mesh = prototype.model,
		textures = prototype.textures,
		view_offset = prototype.view_offset,
		view_offset3rdprs = prototype.view_offset3rdprs,
		player_offset = prototype.player_offset,
		player_rotation = prototype.player_rotation,
		driver = nil,
		v = 0,
		last_v = 0,
		removed = false,
		health = 10,
		soundMotor = nil,
		soundWaves = nil,
		soundloopWaves =130,
		readyToDrop = true,
		r3ckt = false,
		max_speed = prototype.max_speed,
		
	}


	function destroyer.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		if self.driver and clicker == self.driver then
			force_detach(clicker)
		elseif not self.driver then
			attach(clicker, self, self.view_offset, self.view_offset3rdprs, self.player_offset, self.player_rotation)
			self.soundMotor=minetest.sound_play({name="motor"},{object = self.object, gain = 2.0, max_hear_distance = 32, loop = true,})
		end
	end
	
	function destroyer.on_activate(self, staticdata, dtime_s)
		self.object:set_armor_groups({fleshy = 100})
		self.object:set_hp(2000)
		force_reload(self)
		if staticdata then
			self.v = tonumber(staticdata)
		end
		self.last_v = self.v
	end


	function destroyer.get_staticdata(self)
		return tostring(self.v)
	end


	function destroyer.on_punch(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then
			return
		end
		if self.driver and puncher == self.driver then
			force_detach(puncher)
			local inv = puncher:get_inventory()
			if not minetest.setting_getbool("creative_mode") or not inv:contains_item("main", "destroyer:"..name) then
				local leftover = inv:add_item("main", "destroyer:"..name)
				-- if no room in inventory add a replacement submarine to the world
				if not leftover:is_empty() then
					minetest.add_item(self.object:getpos(), leftover)
				end
			end
		elseif self.driver and not puncher == self.driver then
			self.object:set_hp(2000)
		elseif not self.driver then
			local inv = puncher:get_inventory()
			if not minetest.setting_getbool("creative_mode")
					or not inv:contains_item("main", "destroyer:"..name) then
					local leftover = inv:add_item("main", "destroyer:"..name)
				-- if no room in inventory add a replacement submarine to the world
				if not leftover:is_empty() then
					minetest.add_item(self.object:getpos(), leftover)
				end
			end
			self.r3ckt = true
			minetest.after(0.1, function()
				self.object:remove()
			end)
		end
	end


	function destroyer.on_step(self, dtime)
		self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
		if self.driver then
			local ctrl = self.driver:get_player_control()
			local yaw = self.object:getyaw()
			if ctrl.up then
				self.v = self.v + 0.05
			elseif ctrl.down then
				self.v = self.v - 0.05
			end
			if ctrl.left then
				if self.v < 0 then
					self.object:setyaw(yaw - (1 + dtime) * 0.015)
				else
					self.object:setyaw(yaw + (1 + dtime) * 0.015)
				end
			elseif ctrl.right then
				if self.v < 0 then
					self.object:setyaw(yaw + (1 + dtime) * 0.015)
				else
					self.object:setyaw(yaw - (1 + dtime) * 0.015)
				end
			end
			if ctrl.aux1 then
				if self.readyToDrop then
					self.readyToDrop = false
					drop_depth_charge(self.object:getpos(),self.object:getyaw(),self, self.driver,"destroyer:"..name.."_depth_charge")
					if not self.r3ckt then
						minetest.after(1, function()
							drop_depth_charge(self.object:getpos(),self.object:getyaw(),self, self.driver,"destroyer:"..name.."_depth_charge")
						end)
					end
					minetest.after(10, function()
						self.readyToDrop = true
					end)
				end
			end
		end
		local velo = self.object:getvelocity()
		if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
			self.object:setpos(self.object:getpos())
			return
		end
		local s = get_sign(self.v)
		self.v = self.v - 0.02 * s
		if s ~= get_sign(self.v) then
			self.object:setvelocity({x = 0, y = 0, z = 0})
			self.v = 0
			return
		end
		if math.abs(self.v) > self.max_speed then
			self.v = self.max_speed * get_sign(self.v)
		end

		local p = self.object:getpos()
		p.y = p.y - 0.5
		local new_velo
		local new_acce = {x = 0, y = 0, z = 0}
		if not is_water(p) then
			local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
			if (not nodedef) or nodedef.walkable then
				self.v = 0
				new_acce = {x = 0, y = 1, z = 0}
			else
				new_acce = {x = 0, y = -9.8, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:getyaw(),
				self.object:getvelocity().y)
			self.object:setpos(self.object:getpos())
		else
			p.y = p.y + 1
			if is_water(p) then
				local y = self.object:getvelocity().y
				if y >= 5 then
					y = 5
				elseif y < 0 then
					new_acce = {x = 0, y = 20, z = 0}
				else
					new_acce = {x = 0, y = 5, z = 0}
				end
				new_velo = get_velocity(self.v, self.object:getyaw(), y)
				self.object:setpos(self.object:getpos())
			else
				new_acce = {x = 0, y = 0, z = 0}
				if math.abs(self.object:getvelocity().y) < 1 then
					local pos = self.object:getpos()
					pos.y = math.floor(pos.y) + 0.5
					self.object:setpos(pos)
					new_velo = get_velocity(self.v, self.object:getyaw(), 0)
				else
					new_velo = get_velocity(self.v, self.object:getyaw(),
						self.object:getvelocity().y)
					self.object:setpos(self.object:getpos())
				end
			end
		end
		self.object:setvelocity(new_velo)
		self.object:setacceleration(new_acce)
		
		if math.abs(self.v) >= 0.1 then
			if self.soundloopWaves >= 40 then
				self.soundloopWaves = 0
				self.soundWaves = minetest.sound_play({name="waves"},{object = self.object, gain = 2.0, max_hear_distance = 32, loop = false,})
			elseif self.soundloopWaves < 40 then
				self.soundloopWaves = self.soundloopWaves + 10 * dtime
			end
		elseif math.abs(self.v) < 0.1 then
			self.soundWaves = minetest.sound_play({name="waves"},{object = self.object, gain = 2.0, max_hear_distance = 32, loop = false,})
			minetest.sound_stop(self.soundWaves)
			self.soundloopWaves = 40
		end
		
		--special health system for adding a wreck on destruction
		if self.object:get_hp() < 2000 then
			self.health = self.health - (2000 - self.object:get_hp())
			self.object:set_hp(2000)
			if self.health <= 0 then
				if not self.r3ckt then
					self.r3ckt = true
					local wreck = minetest.add_entity(self.object:getpos(), "destroyer:"..name .."_wreck")
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
						self.driver:set_eye_offset({x = self.view_offset.x, y = self.view_offset.y, z = self.view_offset.z},{x = self.view_offset3rdprs.x, y = self.view_offset3rdprs.y, z = self.view_offset3rdprs.z})
						self.driver:set_attach(wreck, "",
							{x = self.player_offset.x, y = self.player_offset.y, z = self.player_offset.z}, {x = self.player_rotation.x, y = self.player_rotation.y, z = self.player_rotation.z})
						default.player_attached[name] = true
						self.driver = nil
						minetest.sound_stop(self.soundMotor)
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
			if self.driver  then
				force_detach(self.driver)
			end
		end
	end
	
	minetest.register_entity("destroyer:"..name, destroyer)


	minetest.register_craftitem("destroyer:"..name, {
		description = prototype.item_description,
		inventory_image = prototype.destroyer_item_texture,
		wield_image = prototype.destroyer_item_texture,
		wield_scale = {x = 2, y = 2, z = 1},
		liquids_pointable = true,
		groups = {},
	
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end
			if not is_water(pointed_thing.under) then
				return itemstack
			end
			pointed_thing.under.y = pointed_thing.under.y + 0.5
			destroyer = minetest.add_entity(pointed_thing.under, "destroyer:"..name)
			if destroyer then
				destroyer:setyaw(placer:get_look_horizontal())
				if not minetest.setting_getbool("creative_mode") then
					itemstack:take_item()
				end
			end
			return itemstack
		end,
	})
	
	minetest.register_craft({
		output = "destroyer:"..name,
		recipe = prototype.destroyer_craft,
	})
	
	minetest.register_entity("destroyer:"..name.."_depth_charge",{
		hp_max = 10,
		physical = true,
		collide_with_objects = true,
		collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
		visual = "mesh",
		mesh = prototype.depth_charge_model,
		textures = prototype.depth_charge_textures,
		timer = 0, --the amount of steps after which the torpedo will become explosive; to prevent blowing up yourself
		sound = nil,
		
		
		on_activate = function(self, staticdata, dtime_s)
			self.object:set_armor_groups({immortal = 1})
			self.object:set_animation({x=1,y=110}, 30, 0)
			self.sound=minetest.sound_play({name="splash"},{object = self.object, gain = 4.0, max_hear_distance = 32, loop = false,})
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
			maxsize = 2,
			attached = self.object,
			texture = "bubble.png",
		})
			self.object:setvelocity({x = 0, y = -3, z = 0})
			self.object:setacceleration({x = 0, y = -0.9, z = 0})
			
			local pos = self.object:getpos()
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
				
				if not is_water({x = pos.x, y = pos.y - 1, z = pos.z}) then
					minetest.sound_stop(self.sound)
					tnt.boom(pos, {damage_radius=3,radius=1,ignore_protection=false})
					self.object:remove()
				end
				if not noboom then
					minetest.sound_stop(self.sound)
					tnt.boom(pos, {damage_radius=3,radius=1,ignore_protection=false})
					self.object:remove()
				end
			else
				self.timer = self.timer + 1
			end
			objects = {}
		end,
		
	})
	
	minetest.register_craftitem("destroyer:"..name.."_depth_charge",{
		description = prototype.depth_charge_item_name,
		inventory_image = prototype.depth_charge_item_texture,
		wield_image = prototype.depth_charge_item_texture,
		liquids_pointable = true,
		groups = {},
		
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end
			if not is_in_water(pointed_thing.under) then
				return itemstack
			end
			torpedo = minetest.add_entity(pointed_thing.under, "destroyer:"..name.."_depth_charge")
			torpedo:setyaw(placer:get_look_horizontal())
			return itemstack
		end,
	})

	minetest.register_craft({
		output = "destroyer:"..name.."depth_charge 4",
		recipe = prototype.depth_charge_craft,
	})
	
	minetest.register_entity("destroyer:"..name.."_wreck",{
		hp_max = 10,
		physical = true,
		collide_with_objects = true,
		collisionbox = prototype.wreck_collisionbox,
		visual = "mesh",
		visual_size = prototype.wreck_visual_size,
		mesh = prototype.wreck_model,
		textures = prototype.wreck_textures,
		
		on_rightclick = function(self, clicker)
			if not clicker or not clicker:is_player() then
				return
			end
			local name = clicker:get_player_name()
			local attach = clicker:get_attach()
			if attach then
				if attach:get_luaentity() == self then
					force_detach(clicker)
					self.attached = nil
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
			else
			self.object:set_hp(10)
			end
		end,
		
		on_step = function(self, dtime)
			local pos = self.object:getpos()
			local all_objects = minetest.get_objects_inside_radius(pos, 3)
			local _,object
			for _,object in ipairs(all_objects) do
				local attach = object:get_attach()
				if attach then
					if attach:get_luaentity() == self then
						self.attached = object
					end
				end
			end
			if self.object:getvelocity().y > -1.5 then
				self.object:setvelocity({x = 0, y = -1.5, z = 0})
			end
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