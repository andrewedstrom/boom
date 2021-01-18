pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- boom
-- by andrew edstrom

-- explosion effects adapted from manbomber
-- by Max Pellegrino and Dominik Leiser
-- https://www.lexaloffle.com/bbs/?pid=86298#p

-- todo
-- bombs explode
-- limit bombs
-- better bomb explosions

local upd -- current update function
local t
local p
local game_objects

function _init()
	game_objects={}
	p=make_player()
	upd=update_game
	t=0
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
end
-->8
--player
local dirx={-1,1,0,0}
local diry={0,0,-1,1}

function make_player()
 return make_game_object("player",1,1,{
		t=1,
		d=3, -- direction
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
				self.t=min(self.t+0.15,1)

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
				if btnp(i) then
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
					end
				end
			end
		end,
		draw=function(self)
			palt(0, false)
			palt(4, true)
			local sprite=self.dir_sprs[self.d+1]+flr(t/8)%4+1
			spr(sprite,self.x*8+self.ox,self.y*8+self.oy)
			pal()
		end
	})
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
-->8
--bombs

function make_bomb(x,y)
	make_game_object("bomb", x, y, {
		ani={88, 89},
		ttl=180,
		update=function(self)
			self.ttl-=1
			if self.ttl == 0 then
				explode(x,y,1) --todo make bigger
			end
		end,
		is_expired=function(self)
			return self.ttl <= 0
		end,
		draw=function(self)
			palt(0,false)
			palt(4,true)
			local sprite=89
			if self.ttl < 50 then
				sprite=self.ani[flr(t/7)%2+1]
			end

			spr(sprite,x*8,y*8)
			pal()
		end
	})
end

function explode(x,y,range)
	local lc,uc,rc,dc = true,true,true,true --continue flags
	--center
	new_explosion_cell("center",x,y)
	local destx,desty,res
	for i=1,range do
		local is_end = i==range
	 --left
	 if lc then
	 	destx,desty=x-1,y
	 	res = explode_at(destx,desty)
	 	if res > 0 then 
		 	new_explosion_cell("horiz",destx,desty,is_end,true,false)
			end
			lc = res > 1
		end	
		--right
		if rc then
			destx,desty=x+1,y
			res = explode_at(destx,desty)
	 	if res > 0 then 
				new_explosion_cell("horiz",destx,desty,is_end,false,false)
			end
			rc = res > 1
		end
		--up
		if uc then
			destx,desty=x,y-1
			res = explode_at(destx,desty)
	 	if res > 0 then 
				new_explosion_cell("vert",destx,desty,is_end,false,false)
			end
			uc = res > 1
		end
		--down
		if dc then
			destx,desty=x,y+1
			res = explode_at(destx,desty)
	 	if res > 0 then 
				new_explosion_cell("vert",destx,desty,is_end,false,true)
			end
			dc = res > 1
		end
	end
end

function explode_at(x,y)
	local cell = mget(x,y)
	if fget(cell,1) then
		--hit something that can break	
		
		-- todo blow it up!
		return 1
	elseif fget(cell,0) then
		-- hit something that can't be broken
		return 0
	end
	-- haven't hit anything
	return 2
end

function new_explosion_cell(direc,x,y,is_end,flipx,flipy)
	local center_ani={1,2,3,4,3,2,1}
	local horiz_ani={33,34,35,36,35,34,33}
	local vert_ani={49,50,51,52,51,50,49}
	local ani = center_ani
	if direc == "horiz" then
		ani = horiz_ani
	elseif direc== "vert" then
		ani = vert_ani
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
__gfx__
0000000000a77a0009a77a9089a77a9889a77a9889a77a9889a77a0000a77a0000077a0000000000000000000000000000000000000000000000000000000000
000000000a777a009a777a00977777779a7777a989a77a988aa77a9000a77a0000077a0000000000000000000000000000000000000000000000000000000000
00700700a777777aa77777aaa777777aa777777a89a77a9809a77a9800a77a0000a77a0000000000000000000000000000000000000000000000000000000000
000770007777777777777777777777777777777789a77a9809a77a9809a77a0000a77a0000000000000000000000000000000000000000000000000000000000
000770007777777777777777777777777777777789a77a9809a77aa809a77a0000a77a0000000000000000000000000000000000000000000000000000000000
00700700a777777aa77777aaa7777779a777777a89a77a9889a77a9009a77a9000077a0000000000000000000000000000000000000000000000000000000000
0000000000a777a097a77a00977777779a7777a989a77a980aa77a900aa77a9000a77a0000000000000000000000000000000000000000000000000000000000
0000000000a77a0009a77a9089a77a9889a77a9889a77a9809a77a980aa77a9000a77a0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000888008888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000009990999a999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaa0aaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000999aa9a9999a9999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088000800888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088008000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000009999000a9999000999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaa00000aaaaa900aaaaa980aaaaa9800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077777a0077777a9077777a9877777a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077777000777770007777700077777a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aa0000aaaaa9007aaaa988aaaaa9880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000900090009a999800999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088888000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000080800000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009000000890800008998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a0000009a0900009a0980089aa9800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000007700009a77a9089a77a9889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000077a0009a77a0009a77a9889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a77a0009a77a0009a77a9889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a7700009a77a0089a77aa889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a7700000a77a908aa7779889a77a980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43333334433333344333333443333334433333340000000044444444000000000000000000000000000000000000000000000000000000000000000000000000
43311334433113344331133443311334433113340000000044566544000000000000000000000000000000000000000000000000000000000000000000000000
331331333313313333133133331331333313313300000000465565d4000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333333333333333333333333333333000000004dd65dd4000000000000000000000000000000000000000000000000000000000000000000000000
41333314413333144133331441333314413333140000000045d665d4000000000000000000000000000000000000000000000000000000000000000000000000
33111133331111343311113343111133331111330000000045ddddd4000000000000000000000000000000000000000000000000000000000000000000000000
9433334949333554943333494553339494333349000000004455dd44000000000000000000000000000000000000000000000000000000000000000000000000
4dd44dd444d4454444d4454444544d4444544d440000000044444442000000000000000000000000000000000000000000000000000000000000000000000000
43333334433333344333333443333334433333340000000044444444444444444444448844448984000000000000000000000000000000000000000000000000
43066034430660344306603443066034430660340000000044444444444444444444559844445a94000a90000000000000000000000000000000000000000000
36066063360660633606606336066063360660630000000044444444444a9444440050444440504400aaa9000000000000000000000000000000000000000000
3666666336666663366666633666666336666663000000004444444444aaa944407600044407600400aaa9000000000000000000000000000000000000000000
4136631441366314413663144136631441366314000000004444444444aaa944406000044406000400aaa9000000000000000000000000000000000000000000
3311113393111133331111333311113933111133000000004444444444aaa9444000000444000004000a90000000000000000000000000000000000000000000
943333494dd333949433334949333dd4943333490000000044444444444a94444000000444400044000000000000000000000000000000000000000000000000
44d44d4444d4454444d4454444544d4444544d440000000044444442444444424400004444444444000000000000000000000000000000000000000000000000
4333334443333344433333444333334443333344000000004444444444eee444444ee444444ee444000000000000000000000000000000000000000000000000
460663444606634446066344460663444606634400000000442ee244444ee4e44444e4e444444444000000000000000000000000000000000000000000000000
4606633446066334460663344606633446066334000000004e2ee2e4ee4444eeee44444eee44444e000000000000000000000000000000000000000000000000
4666333446663334466633344666333446663334000000004e222224ee42224e4442424444444444000000000000000000000000000000000000000000000000
33333144333331443333314433333144333331440000000042eeee24224eee4e424e4e4442444e44000000000000000000000000000000000000000000000000
441113444411134444111344441113444411134400000000422ee224e2444442e4444442444444e4000000000000000000000000000000000000000000000000
443934444d3395444439354445933d4444393d4400000000442eee44444eee44444e444444444444000000000000000000000000000000000000000000000000
4ddd444444d4544444dd54444454d4444455d4440000000044444442442ee242442e4242442e4242000000000000000000000000000000000000000000000000
44333334443333344433333444333334443333340000000044444990499494940444444400000000044449999494949000000000000000000000000000000000
44366064443660644436606444366064443660640000000099994440499494940949999994949494909944449494940400000000000000000000000000000000
43366064433660644336606443366064433660640000000044444990499494940449999994944444440449999494404400000000000000000000000000000000
43336664433366644333666443336664433366640000000099944440499444940944444444444994999044444444099400000000000000000000000000000000
44133333441333334413333344133333441333330000000044444490499444440444499949444994444404994940499400000000000000000000000000000000
44311144443111444431114444311144443111440000000099999440444449490994444449494994999990444909499400000000000000000000000000000000
44439344445933d44453934444d3395444d393440000000099999490494949490444999949494994999994094049499400000000000000000000000000000000
4444ddd444454d444445dd44444d4544444d55440000000044444440000000000994444449494994444444400949499400000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000301010100000000000000000000000001010101010101010000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
7a77777777777777777777777777777b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656565656665666565656566656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656466646564666465646664656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656565656665666566657565656667800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656466646564656465646664656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7666575656565656566656565666667800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656465646664656465646664656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656565666565666565756665656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7666465646664656465646664666577800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7666565666565656666656565666667800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656466646574656466646664656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656565656665666565656565666667800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7666466646564656466646564656567800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656566656566656565656665656667800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7656465646564666466646564666667800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b79797979797979797979797979797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000227501b75019050180001a000007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
