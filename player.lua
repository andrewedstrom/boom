-->8
--player

function make_player(x,y)
	return make_game_object("player",x,y,{
		   t=1, -- transition progress
		   d=3, -- direction
		   lives=3,
		   health=8,
		   invincible=-1,
		   bombs=3,
		   mov=nil, -- movement function
		   dir_sprs={96,112,64,80},
		   update=function(self)
			   self.invincible-= 1

			   if btnp(4) or btnp(5) then
				   if self.bombs > 0 then
					   make_bomb()
				   end
			   end
			   if self.t < 1 then
				-- transitioning b/t tiles
				   self.t=min(self.t+0.1,1)
				   self:mov()
			   else
				   self:handle_input()
			   end
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
			   local i
			   for i=0,3 do
				   if btn(i) then
					   self.d=i
					   local dx,dy=dirx[i+1],diry[i+1]

					   local destx,desty=self.x+dx,self.y+dy
					self.t=0
					   if tile_is_wall(destx,desty) then
						   -- impassable
						   sfx(0)
						   self.mov=self.mov_bump
						   self.sox,self.soy=dx*8,dy*8
						   self.ox,self.oy=0,0
					   else
						   self:start_walk(dx,dy)
						   update_squares(self.x,self.y)
						   return
					   end
				   end
			   end
		   end,
		   draw=function(self)
			   local sprite = self.dir_sprs[self.d+1]
			   if self.t < 1 then
				   sprite=animate(sprite+1)
			   end
			   if self.invincible > 0 and t%3==0 then
				   return
			   end
			   palt(0, false)
			   palt(4, true)
			   spr(sprite,self.x*8+self.ox,self.y*8+self.oy)
			   pal()
		   end,
		   take_damage=function(self)
			   if self.invincible > 0 then
				   return
			   end
			   self.health-=1
			   self.invincible = 90
			   sfx(16)
			   if self.health <= 0 then
				   self.lives -= 1
				   if self.lives < 0 then
					   upd=noop
					   drw=draw_game_over
					   --todo probably unnecessary
					   self.lives=0
				   else
					   self.health = 8
				   end
			   end
		   end
	   })
   end

   function draw_hud()
	   camera()
	   palt(0,false)
	   map(0,0,0,0,2,16) --sidebar base

	   local lives=10+p.lives
	   spr(lives,8,8)

	   for i=1,p.health do
		   local s=i%2==0 and 29 or 28
		   local x=(i-1)%2
		   local y=3+flr((i-1)/2)
		   spr(s,x*8,y*8)
	   end

	   --print('mem:'..stat(0), 1, 110, 7)
	   --print('cpu:'..stat(1), 1, 120, 7)
	   pal()
   end