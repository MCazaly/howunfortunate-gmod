-- How Unfortunate Client
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

    Fakas.HowUnfortunate.sizes = {
        deedee = {w = math.floor(math.min(ScrW(), ScrH()) / 2 + 0.5), h = math.floor(math.min(ScrW(), ScrH()) / 2 + 0.5)},
        challenger = {w = math.floor(ScrW() / 2 + 0.5), h = math.floor(ScrW() / 2 + 0.5)}
    }
    Fakas.HowUnfortunate.coordinates = {
        open = {  -- DeeDee's starting coordinates (bottom-right)
            x = ScrW() - Fakas.HowUnfortunate.sizes.deedee.w,
            y = ScrH() + Fakas.HowUnfortunate.sizes.deedee.h
        },
        close = {  -- DeeDee's destination coordinates (bottom-right off-screen)
            x = ScrW() - Fakas.HowUnfortunate.sizes.deedee.w,
            y = ScrH() - Fakas.HowUnfortunate.sizes.deedee.h
        },
        challenger = {  -- Where to display the challenger notification (centre)
            x = (ScrW() / 2) - (Fakas.HowUnfortunate.sizes.challenger.w / 2),
            y = (ScrH() / 2) - (Fakas.HowUnfortunate.sizes.challenger.h / 2)
        }
    }
    Fakas.HowUnfortunate.textures = {
        deedee = "fakas/howunfortunate/deedee.vtf",
        challenger = "fakas/howunfortunate/challenger.vtf"
    }
    Fakas.HowUnfortunate.sounds = {
        deedee = {"fakas/howunfortunate/deedee1.wav", "fakas/howunfortunate/deedee2.wav"},
        challenger = "fakas/howunfortunate/challenger.wav",
        fail = "fakas/howunfortunate/fail.wav"
    }

    Fakas.HowUnfortunate.draw_deedee = function()
        -- Display DeeDee on-screen and progress the animation.
        if Fakas.HowUnfortunate.timings.start == 0 then
            Fakas.HowUnfortunate.timings.start = CurTime()  -- Reset animation progress
        end
        Fakas.Lib.animate_image(Fakas.HowUnfortunate.textures.deedee, Fakas.HowUnfortunate.sizes.deedee, Fakas.HowUnfortunate.coordinates.open, Fakas.HowUnfortunate.coordinates.close, Fakas.HowUnfortunate.timings.start, Fakas.HowUnfortunate.timings.move)
    end

    Fakas.HowUnfortunate.drop_deedee = function()
        -- Move DeeDee back off-screen and progress the animation, dropping the image once it has completed.
        hook.Remove("HUDPaintBackground", "DrawDeeDee")

        if Fakas.HowUnfortunate.timings.start == 0 then
            Fakas.HowUnfortunate.timings.start = CurTime() -- Record the start time when the function is first called
        end
        local progress = Fakas.Lib.animate_image(Fakas.HowUnfortunate.textures.deedee, Fakas.HowUnfortunate.sizes.deedee, Fakas.HowUnfortunate.coordinates.close, Fakas.HowUnfortunate.coordinates.open, Fakas.HowUnfortunate.timings.start, Fakas.HowUnfortunate.timings.move)

        if progress == 1 then
            -- Destination reached, stop drawing DeeDee
            hook.Remove("HUDPaintBackground", "DropDeeDee")
        end
    end

    Fakas.HowUnfortunate.draw_challenger = function()
        -- Display the challenger notification on-screen.
        Fakas.Lib.draw_image(Fakas.HowUnfortunate.textures.challenger, Fakas.HowUnfortunate.sizes.challenger, Fakas.HowUnfortunate.coordinates.challenger)
    end

    Fakas.HowUnfortunate.show_deedee = function(sound)
        -- Display DeeDee on-screen and start the animation.
        Fakas.HowUnfortunate.timings.start = 0
        Fakas.Lib.play_delayed_sound(sound, Fakas.HowUnfortunate.timings.delay)
        hook.Add("HUDPaintBackground", "DrawDeeDee", Fakas.HowUnfortunate.draw_deedee)
    end

    Fakas.HowUnfortunate.hide_deedee = function()
        -- Start the animation to move DeeDee off-screen.
        Fakas.HowUnfortunate.timings.start = 0
        hook.Add("HUDPaintBackground", "DropDeeDee", Fakas.HowUnfortunate.drop_deedee)
    end

    Fakas.HowUnfortunate.show_challenger = function()
        -- Play the challenger sound and start displaying the notification on-screen.
        Fakas.Lib.play_sound(Fakas.HowUnfortunate.sounds.challenger)
        hook.Add("HUDPaint", "DrawChallenger", Fakas.HowUnfortunate.draw_challenger)
    end

    Fakas.HowUnfortunate.hide_challenger = function()
        -- Stop displaying the challenger notification.
        hook.Remove("HUDPaint", "DrawChallenger")
    end

    Fakas.HowUnfortunate.phase_1 = function()
        -- On-screen phase 1 - DeeDee appearance and speech.
        local deedee_sound = Fakas.Lib.random_member(Fakas.HowUnfortunate.sounds.deedee)
        Fakas.HowUnfortunate.show_deedee(deedee_sound)
    end

    Fakas.HowUnfortunate.phase_2 = function()
        -- On-screen phase 2 - Challenger notification and DeeDee exit.
        Fakas.HowUnfortunate.show_challenger()
        Fakas.HowUnfortunate.hide_deedee()
    end

    Fakas.HowUnfortunate.phase_3 = function()
        -- On-screen phase 3 - Drop challenger notification.
        Fakas.HowUnfortunate.hide_challenger()
    end

    Fakas.HowUnfortunate.phase_4 = function()
        -- On-screen phase 4 - Fail notification and DeeDee exit.
        Fakas.HowUnfortunate.hide_deedee()
        Fakas.Lib.play_sound(Fakas.HowUnfortunate.sounds.fail)
        chat.AddText(Color(255, 255, 255), "No challenger answered the call...")
    end

    -- Set up animation triggers from the server.
    net.Receive("Fakas.HowUnfortunate.phase_1", Fakas.HowUnfortunate.phase_1)
    net.Receive("Fakas.HowUnfortunate.phase_2", Fakas.HowUnfortunate.phase_2)
    net.Receive("Fakas.HowUnfortunate.phase_3", Fakas.HowUnfortunate.phase_3)
    net.Receive("Fakas.HowUnfortunate.phase_4", Fakas.HowUnfortunate.phase_4)
end
