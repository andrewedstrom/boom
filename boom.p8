pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- boom
-- by andrew edstrom

-- based on the original boom
-- by factor software (federico filipponi)
-- see https://obscuritory.com/arcade/boom/

-- explosion graphics adapted from manbomber
-- by Max Pellegrino and Dominik Leiser
-- https://www.lexaloffle.com/bbs/?pid=86298#p

local upd -- current update function
local t
local p
local game_objects

function _init()
	game_objects={}
	p=make_player()
	upd=update_game
	t=0
	make_coin(4,5)
	make_coin(7,10)
	make_coin(11,7)
	make_coin(12,3)
	make_coin(16,8)
	music(0,0,7)
	sfx(5)
end

function _update60()
	t+=1
	upd()
end

function update_game()
	for obj in all(game_objects) do
		if obj:is_expired() then
			del(game_objects, obj)
		else
			obj:update()
		end
	end
	p:update()
end

function _draw()
	cls()
	map()
	for obj in all(game_objects) do
		obj:draw()
	end
	p:draw()
	draw_hud()
end
-->8
--player

local dirx={-1,1,0,0}
local diry={0,0,-1,1}

function make_player()
 return make_game_object("player",3,1,{
		t=1, -- transition progress
		d=3, -- direction
		lives=3,
		health=8,
		ox=0,
		oy=0,
		mov=nil, -- movement function
		dir_sprs={96,112,64,80},
		input_buff=-1,
		update=function(self)
			if btnp(4) or btnp(5) then
				make_bomb(self.x,self.y)
			end
			if self.t < 1 then
			 -- transitioning b/t tiles
				self.t=min(self.t+0.05,1)
				self:mov()
			else
				self:handle_input()
			end
		end,
		mov_walk=function(self)
				self.ox=self.sox*(1-self.t)
				self.oy=self.soy*(1-self.t)
		end,
		mov_bump=function(self)
			local mult=self.t
			if mult > 0.5 then
				mult=1-mult
			end
			self.ox=self.sox*mult
			self.oy=self.soy*mult
		end,
		handle_input=function(self)
			for i=0,3 do
				if btn(i) then
					self.d=i
					local dx,dy=dirx[i+1],diry[i+1]

					local destx,desty=self.x+dx,self.y+dy
					local tile=mget(destx,desty)
				 self.t=0
					if fget(tile, 0) then
						-- impassable
						sfx(0)
						self.mov=self.mov_bump
						self.sox,self.soy=dx*8,dy*8
						self.ox,self.oy=0,0
					else
						self.mov=self.mov_walk
						self.x+=dx
						self.y+=dy
						self.sox,self.soy=-dx*8,-dy*8
						self.ox,self.oy=self.sox,self.soy
						return
					end
				end
			end
		end,
		draw=function(self)
			palt(0, false)
			palt(4, true)
			local sprite = self.dir_sprs[self.d+1]
			if self.t < 1 then
				sprite=animate(sprite+1)
			end
			spr(sprite,self.x*8+self.ox,self.y*8+self.oy)
			pal()
		end,
		take_damage=function(self)
			self.health-=1
			sfx(14)
			if self.health <= 0 then
				self.lives -= 1
				self.health = 8
				if self.lives < 0 then
					-- game over but for now
					self.lives = 0
				end
			end
		end
	})
end

function draw_hud()
	local lives=10+p.lives
	spr(lives,8,8)

	for i=1,p.health do
		local s=i%2==0 and 29 or 28
		local x=(i-1)%2
		local y=3+flr((i-1)/2)
		spr(s,x*8,y*8)
	end
end
-->8
--objects

function make_game_object(kind,x,y,props)
	local obj={
		kind=kind,
		x=x,
		y=y,
		draw=function()
		end,
		update=function()
		end,
		is_expired=function()
			return false
		end
	}

 -- add aditional object properties
 for k,v in pairs(props) do
 	obj[k] = v
 end

 add(game_objects, obj)
 return obj
end

--four frame animations
function animate(start)
	return start+flr(t/8)%4
end

function foreach_game_object_of_kind(kind, callback)
	local obj
	for obj in all(game_objects) do
		if obj.kind == kind then
			callback(obj)
		end
	end
end
-->8
--bombs

function make_bomb(x,y)
	if bomb_at(x,y) then return end
	sfx(3)
	make_game_object("bomb", x, y, {
		ani={86, 87},
		ttl=180,
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
			explode(x,y,3,self.channel)
		end,
		is_expired=function(self)
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

			spr(sprite,x*8,y*8)
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
	explode_at(x,y)
	new_explosion_cell("center",x,y)
	local destx,desty,res
	for i=1,range do
		local is_end = i==range
	 --left
	 if lc then
	 	destx,desty=x-i,y
	 	res = explode_at(destx,desty)
	 	if res > 0 then
		 	new_explosion_cell("horiz",destx,desty,is_end or res==1,true,false)
			end
			lc = res > 1
		end
		--right
		if rc then
			destx,desty=x+i,y
			res = explode_at(destx,desty)
	 	if res > 0 then
				new_explosion_cell("horiz",destx,desty,is_end or res==1,false,false)
			end
			rc = res > 1
		end
		--up
		if uc then
			destx,desty=x,y-i
			res = explode_at(destx,desty)
	 	if res > 0 then
				new_explosion_cell("vert",destx,desty,is_end or res==1,false,false)
			end
			uc = res > 1
		end
		--down
		if dc then
			destx,desty=x,y+i
			res = explode_at(destx,desty)
	 	if res > 0 then
				new_explosion_cell("vert",destx,desty,is_end or res==1,false,true)
			end
			dc = res > 1
		end
	end
end

function explode_at(x,y)
	local bomb=bomb_at(x,y)
	if bomb then
		bomb:explode()
		return 0
	end

	if p.x == x and p.y == y then
		p:take_damage()
	end

	local cell = mget(x,y)
	if fget(cell,1) then
		--hit something that can break
		map_destruction(x,y,cell)
		return 1
	elseif fget(cell,0) then
		-- hit something that can't be broken
		return 0
	end
	-- haven't hit anything
	return 2
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
-->8
-- items

function make_coin(x,y)
	make_game_object("coin",x,y,{
		collected=false,
		is_expired=function(self)
			return self.collected
		end,
		update=function(self)
			if self.x == p.x and self.y==p.y then
				sfx(4)
				self.collected=true
			end
		end,
		draw=function(self)
			spr(animate(90),x*8,y*8)
		end,
	})
end

-->8
-- enemies
__gfx__
0000000000a77a0009a77a9089a77a9889a77a9889a77a9889a77a0000a77a0000077a00cdd333333ddddddc3ddddddc3ddddddc3ddddddccccccccccccccccc
000000000a777a009a777a00977777779a7777a989a77a988aa77a9000a77a0000077a00cdd306603dd777dc3dd77ddc3dd777dc3dd777dccddddddddddddddc
00700700a777777aa77777aaa777777aa777777a89a77a9809a77a9800a77a0000a77a00cd36066063d7d7dc63dd7ddc63ddd7dc63dd77dccddddddddddddddc
000770007777777777777777777777777777777789a77a9809a77a9809a77a0000a77a00cd36666663d7d7dc63dd7ddc63d7dddc63ddd7dccddddddddddddddc
000770007777777777777777777777777777777789a77a9809a77aa809a77a0000a77a00cdd136631dd777dc1dd777dc1dd777dc1dd777dccddddddddddddddc
00700700a777777aa77777aaa7777779a777777a89a77a9889a77a9009a77a9000077a00cddd1111dddddddcdddddddcdddddddcdddddddccddddddddddddddc
0000000000a777a097a77a00977777779a7777a989a77a980aa77a900aa77a9000a77a00cddddddddddddddcdddddddcdddddddcdddddddccddddddddddddddc
0000000000a77a0009a77a9089a77a9889a77a9889a77a9809a77a980aa77a9000a77a00cddddddddddddddcdddddddcdddddddcdddddddccddddddddddddddc
000000000000000000000000008880088888888800000000000000000000000000000000000000000000000000000000cddddddddddddddccddddddddddddddc
0000000000000000000009990999a9999999999900000000000000000000000000000000000000000000000000000000cdd8d8dddd8d8ddccddddddddddddddc
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000cd8e888dd8e888dccddddddddddddddc
000000007777777777777777777777777777777700000000000000000000000000000000000000000000000000000000cd88882dd88882dccddddddddddddddc
000000007777777777777777777777777777777700000000000000000000000000000000000000000000000000000000cdd882dddd882ddccddddddddddddddc
0000000000aaa0aaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000cddd2dddddd2dddccddddddddddddddc
0000000000000000000999aa9a9999a99999999900000000000000000000000000000000000000000000000000000000cddddddddddddddccddddddddddddddc
000000000000000000000000880008008888888800000000000000000000000000000000000000000000000000000000cddddddddddddddccddddddddddddddc
000000000000000000000000880080008888800000000000000000000000000000000000000000000000000000000000cddddddddddddddccddddddddddddddc
000000000000000009999000a99990009999980000000000000000000000000000000000000000000000000000000000cdd1d1dddd1d1ddccddddddddddddddc
00000000aaa00000aaaaa900aaaaa980aaaaa98000000000000000000000000000000000000000000000000000000000cd16161dd16161dccddddddddddddddc
0000000077777a0077777a9077777a9877777a9800000000000000000000000000000000000000000000000000000000cd16661dd16661dccddddddddddddddc
0000000077777000777770007777700077777a9000000000000000000000000000000000000000000000000000000000cdd161dddd161ddccddddddddddddddc
0000000000aa0000aaaaa9007aaaa988aaaaa98800000000000000000000000000000000000000000000000000000000cddd1dddddd1dddccddddddddddddddc
0000000000000000900090009a9998009999980000000000000000000000000000000000000000000000000000000000cddddddddddddddccddddddddddddddc
000000000000000000000000888880008888800000000000000000000000000000000000000000000000000000000000cddddddddddddddccccccccccccccccc
00000000000000000000000000080800000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009000000890800008998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a0000009a0900009a0980089aa9800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000007700009a77a9089a77a9889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000077a0009a77a0009a77a9889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a77a0009a77a0009a77a9889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a7700009a77a0089a77aa889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a7700000a77a908aa7779889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43333334433333344333333443333334433333344444444400000000000000000000000000000000000000000000000000000000000000000000000000000000
433113344331133443311334433113344331133444666d4400000000000000000000000000000000000000000000000000000000000000000000000000000000
3313313333133133331331333313313333133133466666d400000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333334dd666d400000000000000000000000000000000000000000000000000000000000000000000000000000000
413333144133331441333314413333144133331445d665d400000000000000000000000000000000000000000000000000000000000000000000000000000000
331111333311113433111133431111333311113345ddddd400000000000000000000000000000000000000000000000000000000000000000000000000000000
94333349493335549433334945533394943333494455dd4400000000000000000000000000000000000000000000000000000000000000000000000000000000
44d44d4444d4454444d4454444544d4444544d444444444200000000000000000000000000000000000000000000000000000000000000000000000000000000
43333334433333344333333443333334433333344444444444444484444489840000000000000000000000000000000000000000000000000000000000000000
4306603443066034430660344306603443066034444444444444559844445a940000000000000000000af000000a7f0000aaa700009aa0000000000000000000
360660633606606336066063360660633606606344444444440050444440584400000000000000000007900000a77a900a99777009a99a000000000000000000
36666663366666633666666336666663366666634444444440760004440760040000000000000000000a900000779a900a9777a009a99a000000000000000000
41366314413663144136631441366314413663144444444440600004440600040000000000000000000a900000799a900a7779a009a997000000000000000000
33111133931111333311113333111139331111334444444440000004440000040000000000000000000a900000a99a90077799a009a9f7000000000000000000
943333494dd333949433334949333dd4943333494444444440000004444000440000000000000000000a9000000aa900007aaa00009770000000000000000000
44d44d4444d4454444d4454444544d4444544d444444444244000044444444440000000000000000000000000000000000000000000000000000000000000000
43333344433333444333334443333344433333444444444444eee444444ee444444ee444444ee444000000000000000000000000000000000000000000000000
4606634446066344460663444606634446066344442ee244444ee4e44444e4e44444444444444444000000000000000000000000000000000000000000000000
46066334460663344606633446066334460663344e2ee2e4ee4444eeee44444eee44444eee44444e000000000000000000000000000000000000000000000000
46663334466633344666333446663334466633344e222224ee42224e444242444444444444444444000000000000000000000000000000000000000000000000
333331443333314433333144333331443333314442eeee24224eee4e424e4e4442444e4442444e44000000000000000000000000000000000000000000000000
4411134444111344441113444411134444111344422ee224e2444442e4444442444444e4444444e4000000000000000000000000000000000000000000000000
443934444d3395444439354445933d4444393d44442eee44444eee44444e44444444444444444444000000000000000000000000000000000000000000000000
4ddd444444d4544444dd54444454d4444455d44444444442442ee242442e4242442e4242442e4242000000000000000000000000000000000000000000000000
44333334443333344433333444333334443333340494949004444990499494940444444400000000044449999494949004444999000000000000000000000000
44366064443660644436606444366064443660640494940409994440499494940949999994949494909944449494940400994444000000000000000000000000
43366064433660644336606443366064433660640494404404444990499494940449999994944444440449999494404404044999000000000000000000000000
43336664433366644333666443336664433366640444099409944440499444940944444444444994999044444444099409904444000000000000000000000000
44133333441333334413333344133333441333330940499404444490499444440444499949444994444404994940499404440499000000000000000000000000
44311144443111444431114444311144443111440909499409999440444449490994444449494994999990444909499409999044000000000000000000000000
44439344445933d44453934444d3395444d393440049499409999490494949490444999949494994999994094049499409999409000000000000000000000000
4444ddd444454d444445dd44444d4544444d55440949499404444440000000000994444449494994444444400949499404444440000000000000000000000000
49999999499999994999999949999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999994499999944999999449999994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999994499999944999999449999994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
499999f4499999f4499999f4499999f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4ffffff44ffffff44ffffff44ffffff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000004f000000440000004f0000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f000554440000444550004444000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44d4454444d4454444544d4444544d44000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999994999999949999999499999994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4fffff944fffff944fffff944fffff94000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000004400000044000000440000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400f00f4400f00f4400f00f4400f00f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4fff77f44fff77f44fff77f44fff77f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66000004660000046600000f66000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4dd00f444f0000f44f000dd44f0000f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44d4454444d4454444544d4444544d44000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999994999999949999999499999994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4fffff944fffff944fffff944fffff94000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000094400000944000009440000094000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40ffff9440ffff9440ffff9440ffff94000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
477fff94477fff94477fff94477fff94000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66000044660000446600004466000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d00f544440f054445f00d44440f0d44000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44d4544444dd54444454d4444455d444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999999499999994999999949999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49fffff449fffff449fffff449fffff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49000004490000044900000449000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49ffff0449ffff0449ffff0449ffff04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49fff77449fff77449fff77449fff774000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44000666440006664400066644000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44500fd444500f4444d00f5444d00f44000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44454d444445dd44444d4544444d5544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
001b010302000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000000100000000000000000000000000000000000000000000000000000000000000030101010100000000000000000000000101010101010101010000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0e0f7c7777777777777777777777777b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090a765555555565556555555555657800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f765545654555456545554565457800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d765555555565556555655555557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d765545654555455545554565457800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d766555555555555555655555557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d765545554565455545554565457800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2e2f765555556555556555555565557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f766545554565455545554565457800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f766555556555555565655555557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f765545654555455545654565457800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f765555555565556555555555557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f766545654555455545654555457800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f765555655555655555555565557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f765555555555555555555555557800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2e2f757979797979797979797979797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000227501b75019050180001a000007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00020000336712d67129671266712366121661206611f6611e6511d6511d6511b6511a66119661186611766116651166511565114641136411264111631106311063111621116211162111611106110f6110f611
0005061f246212d6332820208602096120761201612036120761208612096120b612016120361201612076120861204612076120a612086120161203612016120261204612076120661207612006120161200000
00050100246212d6332820208602096020760201602036020760208602096020b602016020360201602076020860204602076020a602086020160203602016023570204602076020660207602006020160200000
0104000024050240502b0502b0402b0302b0202b01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000018716035161d716075161f7160a516227260c526247260f526297361153629736165362b746185462e7461b5462e7461f556307562255630766275663375629546357462b526377262e5063770630506
000c00200c0430000300003000030c0430000300003000030c0430000300003000030c0330000300003000030c0330000300003000030c0330000300003000030c0330000300003000030c033000030000300003
000c00200c0430000300003000030c0030000300003000030c0430000300003000030c0030000300003000030c0330000300003000030c0030000300003000030c0330000300003000030c003000030000300003
010c000004132000020413200102001020010204132001020713200102041320010207132001020b132001020010200102071320010209132001020713200000091320000000000000000b132000000713200000
010c000004132000020413200102001020010204132001020713200102041320010207132001020b13200102001020010207132001020c13200102071320000009132000000b1320000009132000000b13200000
010c0000000050000500005000050000500005000050000500005000050000500005000050000500005000051704500005130450000510045000050c045000051005500005000050000500005000050000500005
010c0000000050000500005000050000500005000050000500005000050000500005000050000500005000051704500005130450000510045000050e045000050d04500005000050000000000000000000000000
011800001074000700137300070017740007001373000700197501a75019740007001575000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
011800001f750007001e750007001c740007001a74000700187401773015730177401875017740157400070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01030000217532c7522a7522c7532e753257030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703
010200002c7532e752317522d7422f732307322e73300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 07084344
00 07094a44
00 07084344
00 07094344
01 06080b44
00 06090a44
00 06080c4c
00 06090d4d
00 06080c44
02 06090d44
