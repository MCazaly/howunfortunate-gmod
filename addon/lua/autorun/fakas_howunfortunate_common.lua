-- How Unfortunate Common
if Fakas == nil then
    Fakas = {}
end
if Fakas.HowUnfortunate == nil then
    Fakas.HowUnfortunate = {}
end

if engine.ActiveGamemode() == "terrortown" then
    if Fakas == nil then
        Fakas = {}
        Fakas.HowUnfortunate = {}
    end

	Fakas.HowUnfortunate.timings = {
	    move = 1.5,  -- How long it takes DeeDee to move
	    delay = 1  -- How long to wait after displaying DeeDee before playing her sound
	}
end
