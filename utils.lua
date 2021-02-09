-->8
--utils

function centered_print(message, x, y, col)
	print(message, x - #message * 2, y, col or 7)
end

function noop()
end

function tile_is_wall(x, y)
	return fget(mget(x, y), 0)
end

function blankmap()
	local ret, x, y = {}
	for x = starting_x, starting_x + xmax do
		ret[x] = {}
		for y = starting_y, starting_y + ymax do
			ret[x][y] = false
		end
	end
	return ret
end

function update_squares(x, y)
	squares = blankmap()

	--continue flags
	local lc, uc, rc, dc = true, true, true, true
	local candx, candy
	for i = 1, ymax do
		--left
		if lc then
			candx, candy = x - i, y
			lc = los_continues(candx, candy)
		end
		--right
		if rc then
			candx, candy = x + i, y
			rc = los_continues(candx, candy)
		end
		--up
		if uc then
			candx, candy = x, y - i
			uc = los_continues(candx, candy)
		end
		--down
		if dc then
			candx, candy = x, y + i
			dc = los_continues(candx, candy)
		end

		if not (lc or uc or rc or dc) then
			return
		end
	end
end

--line of sight
function los_continues(x, y)
	local is_wall = tile_is_wall(x, y)
	if not is_wall then
		-- can see player from here
		squares[x][y] = true
	end

	return not is_wall
end
