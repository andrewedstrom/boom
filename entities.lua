-->8
-- items and enemies

function make_coin(x, y)
	make_game_object(
		"coin",
		x,
		y,
		{
			collected = false,
			is_expired = function(self)
				return self.collected
			end,
			update = function(self)
				if self.x == p.x and self.y == p.y then
					sfx(4)
					self.collected = true
				end
			end,
			draw = function(self)
				spr(animate(90), x * 8, y * 8)
			end
		}
	)
end

function make_enemy(x, y)
	return make_game_object(
		"enemy",
		x,
		y,
		{
			t = 1, -- transition progress
			d = 3, -- direction
			lives = 3,
			health = 8,
			ox = 0,
			oy = 0,
			death_timer = 0,
			shot_timer = 0, --cooldown b/t shots
			shot_cooldown = 70,
			dying = false,
			lifetime = 120,
			dir_sprs = {160, 176, 128, 144},
			update = function(self)
				if self.dying then
					self.death_timer = self.death_timer + 1
					return
				end
				self.shot_timer = self.shot_timer - 1

				if self.t < 1 then
					-- transitioning b/t tiles
					self.t = min(self.t + 0.05, 1)
					self:mov()
				else
					self:choose_dir()
				end
				if self.x == p.x and self.y == p.y then
					p:take_damage()
				end
			end,
			take_damage = function(self)
				self.dying = true
			end,
			is_expired = function(self)
				return self.death_timer > self.lifetime
			end,
			choose_dir = function(self)
				if squares[self.x][self.y] and self.shot_timer <= 0 then
					-- shoot
					local d = 3
					if p.x < self.x then
						--left
						d = 0
					elseif p.x > self.x then
						--right
						d = 1
					elseif p.y < self.y then
						d = 2
					end
					make_bullet(self.x, self.y, d)
					self.shot_timer = self.shot_cooldown
				end

				local cand, same_dir_di, i = {}
				for i = 0, 3 do
					local dx, dy = dirx[i + 1], diry[i + 1]

					local destx, desty = self.x + dx, self.y + dy
					if not tile_is_wall(destx, desty) then
						-- passable
						local di = {d = i, dx = dx, dy = dy}
						add(cand, di)
						if i == self.d then
							same_dir_di = di
						end
					end
				end

				local di = rnd(cand)
				if #cand == 2 and same_dir_di then
					-- if only two directions
					-- and you can keep going in the current direction
					-- then continue in the same direction
					di = same_dir_di
				end

				self.d = di.d
				self.t = 0
				self:start_walk(di.dx, di.dy)
			end,
			draw = function(self)
				palt(0, false)
				palt(4, true)
				pal(9,11)

				local sprite = animate(self.dir_sprs[self.d + 1])
				if self.dying then
					sprite = 132 + flr(t / 8) % 2
				end
				spr(sprite, self.x * 8 + self.ox, self.y * 8 + self.oy)
				pal()
			end
		}
	)
end

function make_bullet(x, y, direc)
	make_game_object(
		"bullet",
		x,
		y,
		{
			d = direc,
			speed = 0.6,
			hit = false,
			is_expired = function(self)
				return self.hit
			end,
			update = function(self)
				local dx, dy = dirx[self.d + 1], diry[self.d + 1]
				self.ox = self.ox + dx * self.speed
				self.oy = self.oy + dy * self.speed

				if abs(self.ox) >= 8 or abs(self.oy) >= 8 then
					--advance one tile
					self.ox = 0
					self.oy = 0
					self.x = self.x + dx
					self.y = self.y + dy

					--check for collision
					if tile_is_wall(self.x, self.y) then
						self.hit = true
					end

					if self.x == p.x and self.y == p.y then
						p:take_damage()
						self.hit = true
					end
				end
			end,
			draw = function(self)
				sprite = 125
				if self.d >= 2 then
					sprite = 126
				end
				spr(sprite, self.x * 8 + self.ox, self.y * 8 + self.oy)
			end
		}
	)
end
