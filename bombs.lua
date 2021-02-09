-->8
--bombs

function make_bomb(p)
	if bomb_at(p.x,p.y) then return end
	p.bombs-=1
	sfx(3)
	make_game_object("bomb", p.x, p.y, {
		ani={86, 87},
		ttl=180,
		parent=p,
		channel=channel,
		update=function(self)
			self.ttl-=1
			if self.ttl == 0 then
				self:explode()
			end
		end,
		explode=function(self)
			self.ttl=0
			del(game_objects, self)
			self.parent.bombs += 1
			explode(self.x,self.y,3,self.channel)
		end,
		is_expired=function(self)
			-- since we're deleting from
			-- game_objects manually,
			-- this is pointless
			return self.ttl <= 0
		end,
		draw=function(self)
			palt(0,false)
			palt(4,true)
			local interval=10
			if self.ttl < 50 then
				interval=4
			end
			sprite=self.ani[flr(t/interval)%2+1]

			spr(sprite,self.x*8,self.y*8)
			pal()
		end
	})
end

-- todo move into bomb obj
function explode(x,y,range,sfx_channel)
	-- play explosion sound
	sfx(1)
	local lc,uc,rc,dc = true,true,true,true --continue flags
	--center
	explode_at("center",x,y,false,false,false)
	local destx,desty
	for i=1,range do
		local is_end = i == range
		--left
		if lc then
			destx,desty=x-i,y
			lc = explode_at("horiz",destx,desty,is_end,true,false)
		end
		--right
		if rc then
			destx,desty=x+i,y
			rc = explode_at("horiz",destx,desty,is_end,false,false)
		end
		--up
		if uc then
			destx,desty=x,y-i
			uc = explode_at("vert",destx,desty,is_end,false,false)
		end
		--down
		if dc then
			destx,desty=x,y+i
			dc = explode_at("vert",destx,desty,is_end,false,true)
		end
	end
end

function explode_at(direc,x,y,is_end,flipx,flipy)
	local bomb=bomb_at(x,y)
	if bomb then
		bomb:explode()
		return 0
	end

	local cell = mget(x,y)
	local can_break = fget(cell,1)
	if tile_is_wall(x,y) and not can_break then
		return false
	end

	local broke_something = false
	if can_break then
		--hit something that can break
		map_destruction(x,y,cell)
		broke_something=true
	end

	new_explosion_cell(direc,x,y,is_end or broke_something,flipx,flipy)

	return not broke_something
end

function map_destruction(x,y,map_tile)
	local ani
	if map_tile == 101 then
		-- purple boulder
		ani={101,102,103,104,85}
	end
	make_game_object("destruction",x,y,{
		ani=ani,
		t=0,
		lifetime=50,
		update=function(self)
			local frame_len=self.lifetime/#self.ani
			mset(x,y,self.ani[flr(self.t/frame_len)+1])
			self.t+=1
		end,
		is_expired=function(self)
			return self.t >= self.lifetime
		end
	})
end

function new_explosion_cell(direc,x,y,is_end,flipx,flipy)
	local center_ani={1,2,3,4,3,2,1}
	local horiz_ani={17,18,19,20,19,18,17}
	local end_horiz_ani={33,34,35,36,35,34,33}
	local vert_ani={8,7,6,5,6,7,8}
	local end_vert_ani={49,50,51,52,51,50,49}
	local ani = center_ani
	if direc == "horiz" then
		ani = is_end and end_horiz_ani or horiz_ani
	elseif direc== "vert" then
		ani = is_end and end_vert_ani or vert_ani
	end
	make_game_object("explosion",x,y,{
		t=0,
		lifetime=30,
		ani=ani,
		flipx=flipx,
		flipy=flipy,
		is_expired=function(self)
			return self.t >= self.lifetime
		end,
		update= function(self)
			self.t+=1

			if p.x == x and p.y == y then
				p:take_damage()
			end

			foreach_game_object_of_kind("enemy", function(e)
				if e.x==x and e.y==y then
					e:take_damage()
				end
			end)
		end,
		draw = function(self)
			local frame_len=self.lifetime/#self.ani
			local sprite = self.ani[flr(self.t/frame_len)+1]
			spr(sprite,self.x*8,self.y*8,1,1,self.flipx,self.flipy)
		end
	})
end

function bomb_at(x,y)
	local res
	foreach_game_object_of_kind("bomb", function(b)
		if b.x == x and b.y == y then
			res=b
		end
	end)
	return res
end