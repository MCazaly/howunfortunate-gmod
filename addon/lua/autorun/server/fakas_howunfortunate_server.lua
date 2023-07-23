-- How Unfortunate Server
if Fakas == nil then
    Fakas = {}
end
if Fakas.HowUnfortunate == nil then
    Fakas.HowUnfortunate = {}
end

if engine.ActiveGamemode() == "terrortown" then  -- Only ever set up in TTT
    if Fakas == nil then
        Fakas = {}
        Fakas.HowUnfortunate = {}
    end

    Fakas.HowUnfortunate.running = false  -- Track the running state of How Unfortunate

    Fakas.HowUnfortunate.get_candidates = function()
        -- Get a list of valid spawning candidates
        local PLAYER = 1
        local NPC = 2
        local candidates = {}
        local options = {}
        local players = Fakas.HowUnfortunate.get_dead_players()
        local npcs = Fakas.HowUnfortunate.get_npcs()
        
        if next(players) ~= nil then
            -- At least one dead player is available
            table.insert(options, PLAYER)
        end
        if next(npcs) ~= nil and Fakas.Lib.navmesh.exists() then
            -- The current map has a navmesh and at least one NPC is available
            table.insert(options, NPC)
        end

        if next(options) == nil then
            -- No options available, probably someone was revived or disconnected - exit early
            return candidates
        end

        -- Randomly select from available modes (player and/or NPC)
        if Fakas.Lib.random_member(options) == PLAYER then
            -- Populate the candidates table with spawners for all available dead players
            for _, ply in ipairs(players) do
                table.insert(candidates, function()
                    Fakas.HowUnfortunate.spawn_antagonist(ply)
                end)
            end
        else
            for _, npc in ipairs(npcs) do
                -- Populate the candidates table with spawners for all available NPCs
                table.insert(candidates, function()
                    Fakas.HowUnfortunate.spawn_npc(npc)
                end)
            end
        end

        return candidates
    end

    Fakas.HowUnfortunate.get_dead_players = function()
        -- Get a list of all dead players
        local players = {}
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() and not ply:Alive() then
                table.insert(players, ply)
            end
        end
        return players
    end

    Fakas.HowUnfortunate.get_npcs = function()
        -- Get a list of all configured spawnable NPCs
        local classes = Fakas.Lib.get_list("fakas_howunfortunate_npcs") 
        local npcs = {}
        for _, class in ipairs(classes) do
            local npc = ents.Create(class)  -- An entity we can spawn
            if npc ~= nil then
                table.insert(npcs, npc)
            end
        end
        return npcs
    end

    Fakas.HowUnfortunate.get_antagonists = function()
        -- Get a list of all configured spawnable roles
        local antagonists = {}
        for _, antagonist in ipairs(Fakas.Lib.get_list("fakas_howunfortunate_roles")) do
            if antagonist.Base ~= "ttt_role_base" then
                table.insert(antagonists, antagonist)
            end
        end
        return antagonists
    end

    Fakas.HowUnfortunate.spawn_antagonist = function(ply)
        -- Spawn a player as a randomly selected role
        local antagonists = Fakas.HowUnfortunate.get_antagonists()
        local role = roles.GetByName(Fakas.Lib.random_member(antagonists))
        if IsValid(ply) then
            ply:SpawnForRound(false)
            ply:SetRole(role.index)
            ply:SetDefaultCredits()
            SendFullStateUpdate()
        end
    end

    Fakas.HowUnfortunate.spawn_npc = function(npc)
        -- Spawn an NPC at a random nav area on the map
        local areas = navmesh.GetAllNavAreas()
        local position = Fakas.Lib.random_member(areas):GetCenter()
        npc:SetPos(position)
        npc:Spawn()
        npc:Activate()
    end

    Fakas.HowUnfortunate.spawn_candidate = function()
        -- Get a list of suitable candidates for spawning and then execute the relevant function
        local candidates = Fakas.HowUnfortunate.get_candidates()
        if next(candidates) ~= nil then
            Fakas.Lib.random_member(candidates)()
            return true  -- Spawn was successful
        end
        return false  -- We couldn't spawn for some reason, did someone disconnect?
    end

    Fakas.HowUnfortunate.toggle_status = function()
        -- Toggle the running status, indicating whether or not the event is currently active
        Fakas.HowUnfortunate.running = not Fakas.HowUnfortunate.running
    end

    Fakas.HowUnfortunate.run = function()
        -- Activate the event, playing animations and sounds on clients and triggering spawning.
        Fakas.HowUnfortunate.toggle_status()  -- Prevent proc from triggering the event while we're already running
        Fakas.Lib.net.send("Fakas.HowUnfortunate.phase_1")  -- Trigger DeeDee's animation and speech

        timer.Simple(14, function() 
            -- After 14 seconds, try to spawn a candidate and play a suitable notification
            if GetRoundState() == ROUND_ACTIVE and Fakas.HowUnfortunate.spawn_candidate() then
                -- Success! Play the challenger notification and hide DeeDee
                Fakas.Lib.net.send("Fakas.HowUnfortunate.phase_2")
                timer.Simple(3, function() 
                    Fakas.Lib.net.send("Fakas.HowUnfortunate.phase_3")
                end)
            else
                -- Something went wrong, play the fail notification and hide DeeDee
                Fakas.Lib.net.send("Fakas.HowUnfortunate.phase_4")
            end
        end)
        -- 20 seconds after we start the event, allow proc to trigger it again
        timer.Simple(20, Fakas.HowUnfortunate.toggle_status)
    end

    Fakas.HowUnfortunate.proc = function()
        -- Check for activation requirements, rolling a random check if they are, then triggering the event if it passes.
        local enabled = GetConVar("fakas_howunfortunate_enabled"):GetBool()
        local chance = GetConVar("fakas_howunfortunate_random"):GetFloat()
        local remaining = GetGlobalFloat("ttt_round_end") - CurTime() -- Time left in the round

        -- Conditions:
        -- How Unfortunate is enabled.
        -- A round is running.
        -- At least 80 seconds left in the round.
        -- The event is not already running.
        -- At least one candidate is available.
        -- The random check passes.
        if enabled and GetRoundState() == ROUND_ACTIVE and remaining > 80 and not Fakas.HowUnfortunate.running and next(Fakas.HowUnfortunate.get_candidates()) ~= nil and math.random() <= chance then
            Fakas.HowUnfortunate.run()
        end
    end

    Fakas.HowUnfortunate.setup = function()
        -- Prepare How Unfortunate to run on the server
        local fcvars = {FCVAR_NOTIFY, FCVAR_LUA_SERVER}

        -- Set up server ConVars
        CreateConVar("fakas_howunfortunate_enabled", "1", fcvars, "Activate How Unfortunate for TTT2", 0, 1)
        CreateConVar("fakas_howunfortunate_random", "0.0003", fcvars, "Chance out of 1 each second to trigger How Unfortunate", 0, 1)
        CreateConVar("fakas_howunfortunate_npcs", "npc_fakas", fcvars, "Comma-separated list of NPCs that How Unfortunate can spawn", nil, nil)
        CreateConVar("fakas_howunfortunate_roles", "necromancer,jackal,jester,lootgoblin,infected", fcvars, "Comma-separated list of roles that How Unfortunate can respawn dead players as", nil, nil)
        -- TODO: CreateConVar("fakas_howunfortunate_npcs_canwin", "npc_fakas")

        -- Set up network triggers for the client
        util.AddNetworkString("Fakas.HowUnfortunate.phase_1")
        util.AddNetworkString("Fakas.HowUnfortunate.phase_2")
        util.AddNetworkString("Fakas.HowUnfortunate.phase_3")
        util.AddNetworkString("Fakas.HowUnfortunate.phase_4")

        -- Set up console commands
        concommand.Add("fakas_howunfortunate_run", function(_, _, _, _)
            Fakas.HowUnfortunate.run()
        end)

        -- Every second, evaluate trigger conditions and try running the event
        timer.Create("Fakas.HowUnfortunate.proc", 1, 0, Fakas.HowUnfortunate.proc)
    end

    Fakas.HowUnfortunate.setup()
end
