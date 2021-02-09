-->8
--objects

function make_game_object(kind,x,y,props)
	local obj={
		kind=kind,
		x=x,
		y=y,
		ox=0,
		oy=0,
		mov=nil,
		draw=function()
		end,
		update=function()
		end,
		is_expired=function()
			return false
		end,
		take_damage=function()
		end,
		start_walk=function(self,dx,dy)
			self.mov=mov_walk
			self.x+=dx
			self.y+=dy
			self.sox,self.soy=-dx*8,-dy*8
			self.ox,self.oy=self.sox,self.soy
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

function mov_walk(self)
	self.ox=self.sox*(1-self.t)
	self.oy=self.soy*(1-self.t)
end