local floor, sub = clonefunction(floor), clonefunction(sub) -- since all of these will be called post execution, they can then be hooked by an anti http spy for anylisis (such as hooking the returned values of os.clock and doing something similar to __add=function(self, other)if other == tick() ^ 2 then plr:Kick("detected") end)
local clock, tick = clonefunction(os.clock), clonefunction(tick)
local round = clonefunction(math.round)

-- pretty skidded, cba

local base = round(clock() + tick() ^ 2) -- since this is being called initially, its a lot harder to detect

local random = {}
local function seedgen()
	return round(base * tick())
end

local original = seedgen

local rng = function(seed)
	local a = base
	local c = 12345
	seed = (a * seed + c) % (2 ^ 31)
	local d = seed / (2 ^ 31)

	return function(min, max)
		min = min or 0
		max = max or 1
		if min > max then
			min, max = max, min
		end
		return d * (max - min) + min
	end
end

local calls = 0
local gen = rng(seedgen())
function random.int(min, max)
	gen = rng(seedgen())
	return floor(gen(min, max))
end

function random.string(len)
	local chars = "abcdefghijklmnopqrstuvxwyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local r = ""
	for i = 1, len do
		local n = random.int(1, #chars)
		r = r .. sub(chars, n, n)
	end
	return r
end

function random.setseed(seed)
	if seed then
		seedgen = function()
			return seed
		end
	else
		seedgen = original
	end
end

return random