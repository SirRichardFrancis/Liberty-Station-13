#define TURRET_PRIORITY_TARGET 2
#define TURRET_SECONDARY_TARGET 1
#define TURRET_NOT_TARGET 0

/obj/machinery/porta_turret/excelsior
	icon = 'icons/obj/machines/excelsior/turret.dmi'
	desc = "A fully automated anti infantry platform. Fires 7.62mm rounds."
	icon_state = "turret_legs"
	density = TRUE
	lethal = TRUE
	raised = TRUE
	check_id = FALSE
	circuit = /obj/item/circuitboard/excelsior_turret
	installation = null
	var/turret_caliber = CAL_RIFLE
	var/obj/item/ammo_magazine/ammo_box = /obj/item/ammo_magazine/ammobox/rifle_75
	var/ammo = 0 // number of bullets left.
	var/ammo_max = 160
	var/working_range = 30 // how far this turret operates from excelsior teleporter
	health = 300
	maxHealth = 300
	auto_repair = 1
	shot_delay = 0.3

/obj/machinery/porta_turret/excelsior/preloaded
	ammo = 160

/obj/machinery/porta_turret/excelsior/proc/has_power_source_nearby()
	for (var/a in excelsior_teleporters)
		if (dist3D(src, a) <= working_range) //The turret and teleporter can be on a different zlevel
			return TRUE
	return FALSE

/obj/machinery/porta_turret/excelsior/examine(mob/user)
	if(!..(user, 2))
		return
	to_chat(user, "There [(ammo == 1) ? "is" : "are"] [ammo] round\s left!")
	if(!has_power_source_nearby())
		to_chat(user, "Seems to be powered down. No excelsior teleporter found nearby.")

/obj/machinery/porta_turret/excelsior/Initialize()
	. = ..()
	update_icon()

/obj/machinery/porta_turret/excelsior/setup()
	var/obj/item/ammo_casing/AM = initial(ammo_box.ammo_type)
	projectile = initial(AM.projectile_type)
	eprojectile = projectile
	shot_sound = 'sound/weapons/guns/fire/ltrifle_fire.ogg'
	eshot_sound = 'sound/weapons/guns/fire/ltrifle_fire.ogg'

/obj/machinery/porta_turret/excelsior/nano_ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = NANOUI_FOCUS)
	var/data[0]
	data["access"] = !isLocked(user)
	data["locked"] = locked
	data["enabled"] = enabled

	var/settings[0]
	settings[++settings.len] = list("category" = "Neutralize All Non-Synthetics", "setting" = "check_synth", "value" = check_synth)
	settings[++settings.len] = list("category" = "Check Weapon Authorization", "setting" = "check_weapons", "value" = check_weapons)
	settings[++settings.len] = list("category" = "Check Security Records", "setting" = "check_records", "value" = check_records)
	settings[++settings.len] = list("category" = "Check Arrest Status", "setting" = "check_arrest", "value" = check_arrest)
	settings[++settings.len] = list("category" = "Check Access Authorization", "setting" = "check_access", "value" = check_access)
	settings[++settings.len] = list("category" = "Check misc. Lifeforms", "setting" = "check_anomalies", "value" = check_anomalies)
	settings[++settings.len] = list("category" = "Check ID. Check for a present ID", "setting" = "check_id", "value" = check_id)
	data["settings"] = settings


	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "turret_control.tmpl", "Turret Controls", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/porta_turret/excelsior/HasController()
	return FALSE

/obj/machinery/porta_turret/excelsior/attackby(obj/item/ammo_magazine/I, mob/user)
	if(istype(I, ammo_box) && I.stored_ammo.len)
		if(ammo >= ammo_max)
			to_chat(user, SPAN_NOTICE("You cannot load more than [ammo_max] ammo."))
			return

		var/transfered_ammo = 0
		for(var/obj/item/ammo_casing/AC in I.stored_ammo)
			I.stored_ammo -= AC
			qdel(AC)
			ammo++
			transfered_ammo++
			if(ammo == ammo_max)
				break
		to_chat(user, SPAN_NOTICE("You loaded [transfered_ammo] bullets into [src]. It now contains [ammo] ammo."))
		I.update_icon()
	else
		..()

/obj/machinery/porta_turret/excelsior/Process()
	if(!has_power_source_nearby())
		disabled = TRUE
		popDown()
		return
	if(anchored)
		disabled = FALSE
	..()

/obj/machinery/porta_turret/excelsior/assess_living(mob/living/L)
	if(!istype(L))
		return TURRET_NOT_TARGET

	if(L.invisibility >= INVISIBILITY_LEVEL_ONE)
		return TURRET_NOT_TARGET

	if(get_dist(src, L) > 7)
		return TURRET_NOT_TARGET

	if(!check_trajectory(L, src))
		return TURRET_NOT_TARGET

	if(emagged)		// If emagged not even the dead get a rest
		return L.stat ? TURRET_SECONDARY_TARGET : TURRET_PRIORITY_TARGET

	if(L.stat == DEAD)
		return TURRET_NOT_TARGET

	if(L.faction == "excelsior") //Dont target colony pets if were allied with them
		return TURRET_NOT_TARGET

	if(check_id)
		var/id = L.GetIdCard()
		if(id && istype(id, /obj/item/card/id))
			return TURRET_NOT_TARGET
		else
			return TURRET_SECONDARY_TARGET

	if(L.lying)
		return TURRET_SECONDARY_TARGET

	return TURRET_PRIORITY_TARGET	//if the perp has passed all previous tests, congrats, it is now a "shoot-me!" nominee

/obj/machinery/porta_turret/excelsior/tryToShootAt()
	if(!ammo)
		return FALSE
	..()

// this turret has no cover, it is always raised
/obj/machinery/porta_turret/excelsior/popUp()
	raised = TRUE

/obj/machinery/porta_turret/excelsior/popDown()
	last_target = null
	raised = TRUE

/obj/machinery/porta_turret/excelsior/update_icon()
	cut_overlays()

	if(!(stat & BROKEN))
		add_overlay(image("turret_gun"))

/obj/machinery/porta_turret/excelsior/launch_projectile()
	ammo--
	..()


//Guild brand auto turrets.
/obj/machinery/porta_turret/Union
	icon = 'icons/obj/machines/excelsior/turret.dmi'
	name = "Union turret"
	desc = "A fully automated battery powered self-repairing anti-wildlife armored turret platform built by the Terra-Therma Union. It features a three round burst fire automatic and an integrated \
	non-sapient automated artificial-intelligence diagnostic repair system. In other words, the fanciest bit of forging the guild can make. Fires 6.5mm rounds and holds up to 200."
	icon_state = "turret_legs_terra"
	density = TRUE
	lethal = TRUE
	raised = TRUE
	colony_allied_turret = TRUE
	check_id = TRUE
	circuit = /obj/item/circuitboard/artificer_turret
	installation = null
	var/obj/item/ammo_magazine/ammo_box = /obj/item/ammo_magazine/ammobox/light_rifle_257 //This is used for preloading
	var/turret_caliber = CAL_SRIFLE
	var/ammo = 0 // number of bullets left.
	var/ammo_max = 200
	var/obj/item/cell/large/cell = null
	health = 175//to compensate the damage nerf now has a bit more of health and legs with extra armor and size
	auto_repair = 1
	shot_delay = 3
	use_power = 1
	idle_power_usage = 1
	active_power_usage = 1

/obj/machinery/porta_turret/Union/auto_use_power()
	if(disabled)
		return

/obj/machinery/porta_turret/Union/powered(chan=1)
	if (cell?.check_charge(1))
		cell.charge = cell.charge - 1
		return TRUE
	return FALSE

/obj/machinery/porta_turret/Union/use_power(amount, chan=1, autocalled)
	return cell?.checked_use(amount)

/obj/machinery/porta_turret/Union/examine(mob/user)
	if(!..(user, 2))
		return
	to_chat(user, "There [(ammo == 1) ? "is" : "are"] [ammo] round\s left!")
	if(!powered())
		to_chat(user, "Seems to be powered down. The battery must be dead.")

/obj/machinery/porta_turret/Union/Initialize()
	. = ..()
	update_icon()

/obj/machinery/porta_turret/Union/setup()
	var/obj/item/ammo_casing/AM = initial(ammo_box.ammo_type)
	projectile = initial(AM.projectile_type)
	eprojectile = projectile
	shot_sound = 'sound/weapons/guns/fire/carbine.ogg'
	eshot_sound = 'sound/weapons/guns/fire/carbine.ogg'

/obj/machinery/porta_turret/Union/isLocked(mob/user)
	if(ishuman(user))
		return 0
	return 1

/obj/machinery/porta_turret/Union/nano_ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = NANOUI_FOCUS)
	var/data[0]
	data["access"] = !isLocked(user)
	data["locked"] = locked
	data["enabled"] = enabled
	data["cell"] = cell ? capitalize(cell.name) : null
	data["cellCharge"] = cell ? cell.charge : 0
	data["cellMaxCharge"] = cell ? cell.maxcharge : 1

	var/settings[0]
	settings[++settings.len] = list("category" = "Neutralize All Non-Synthetics", "setting" = "check_synth", "value" = check_synth)
	settings[++settings.len] = list("category" = "Check Weapon Authorization", "setting" = "check_weapons", "value" = check_weapons)
	settings[++settings.len] = list("category" = "Check Security Records", "setting" = "check_records", "value" = check_records)
	settings[++settings.len] = list("category" = "Check Arrest Status", "setting" = "check_arrest", "value" = check_arrest)
	settings[++settings.len] = list("category" = "Check Access Authorization", "setting" = "check_access", "value" = check_access)
	settings[++settings.len] = list("category" = "Check misc. Lifeforms", "setting" = "check_anomalies", "value" = check_anomalies)
	settings[++settings.len] = list("category" = "Check misc. Alliement To Local PI Systems", "setting" = "colony_allied_turret", "value" = colony_allied_turret)
	settings[++settings.len] = list("category" = "Check ID. Check for a present ID", "setting" = "check_id", "value" = check_id)
	data["settings"] = settings


	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "turret_control_artificer.tmpl", "Turret Controls", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/porta_turret/Union/Topic(href, href_list)
	if(href_list["command"] == "eject_cell")
		cell.forceMove(src.loc)
		cell = null
		return 1
	.=..()

/obj/machinery/porta_turret/Union/HasController()
	return FALSE

/obj/machinery/porta_turret/Union/attackby(obj/item/I, mob/user)
	if (user.a_intent == I_HELP)
		if(stat & BROKEN)
			if(QUALITY_PRYING in I.tool_qualities)
				//If the turret is destroyed, you can remove it with a crowbar to
				//try and salvage its components
				to_chat(user, SPAN_NOTICE("You begin prying the metal coverings off."))
				if(do_after(user, 20, src))
					if(prob(70))
						to_chat(user, SPAN_NOTICE("You remove the turret and salvage some components."))
						if(prob(50))
							new /obj/item/circuitboard/artificer_turret(loc)
						if(prob(50))
							new /obj/item/stack/material/steel(loc, rand(1,4))
						if(prob(50))
							new /obj/item/device/assembly/prox_sensor(loc)
					else
						to_chat(user, SPAN_NOTICE("You remove the turret but did not manage to salvage anything."))
					qdel(src) // qdel
				return TRUE //No whacking the turret with tools on help intent

		else if(QUALITY_BOLT_TURNING in I.tool_qualities)
			if(enabled)
				to_chat(user, SPAN_WARNING("You cannot unsecure an active turret!"))
				return TRUE //No whacking the turret with tools on help intent
			if(!anchored && isinspace())
				to_chat(user, SPAN_WARNING("Cannot secure turrets in space!"))
				return TRUE //No whacking the turret with tools on help intent

			user.visible_message( \
					"<span class='warning'>[user] begins [anchored ? "un" : ""]securing the turret.</span>", \
					"<span class='notice'>You begin [anchored ? "un" : ""]securing the turret.</span>" \
				)

			if(do_after(user, 50, src))
				//This code handles moving the turret around. After all, it's a portable turret!
				if(!anchored)
					playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
					anchored = TRUE
					update_icon()
					to_chat(user, SPAN_NOTICE("You secure the exterior bolts on the turret."))
					if(disabled)
						spawn(200)
							disabled = FALSE
				else if(anchored)
					if(disabled)
						to_chat(user, SPAN_NOTICE("The turret is still recalibrating. Wait some time before trying to move it."))
						return
					playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
					anchored = 0
					disabled = TRUE
					to_chat(user, SPAN_NOTICE("You unsecure the exterior bolts on the turret."))
					update_icon()
			wrenching = 0
			return TRUE //No whacking the turret with tools on help intent

		else if(istype(I, /obj/item/cell/large))
			if(cell)
				to_chat(user, "<span class='notice'>\the [src] already has a cell.</span>")
			else
				user.unEquip(I)
				I.forceMove(src)
				cell = I
				to_chat(user, "<span class='notice'>You install a cell in \the [src].</span>")
			return TRUE //No whacking the turret with cells on help intent

		else if(istype(I, /obj/item/ammo_magazine))
			return load_ammo(I, user)
	else
		..()

/obj/machinery/porta_turret/Union/proc/load_ammo(obj/item/ammo_magazine/I, mob/user)
	var/obj/item/ammo_magazine/A = I

	if(A.caliber != turret_caliber)
		to_chat(user, SPAN_NOTICE("This turret does not use this caliber!"))
		return TRUE

	if(ammo >= ammo_max)
		to_chat(user, SPAN_NOTICE("You cannot load more than [ammo_max] ammo."))
		return TRUE //No whacking the turret with ammo boxes on help intent

	var/transfered_ammo = 0
	for(var/obj/item/ammo_casing/AC in A.stored_ammo)
		A.stored_ammo -= AC
		qdel(AC)
		ammo++
		transfered_ammo++
		if(ammo == ammo_max)
			break
	to_chat(user, SPAN_NOTICE("You loaded [transfered_ammo] bullets into [src]. It now contains [ammo] ammo."))
	return TRUE //No whacking the turret with ammo boxes on help intent

/obj/machinery/porta_turret/Union/Process()
	if(!powered())
		disabled = TRUE
		popDown()
		return
	if(anchored)
		disabled = FALSE
	..()

/obj/machinery/porta_turret/Union/assess_living(mob/living/L)
	if(!istype(L))
		return TURRET_NOT_TARGET

	if(L.invisibility >= INVISIBILITY_LEVEL_ONE)
		return TURRET_NOT_TARGET

	if(get_dist(src, L) > 7)
		return TURRET_NOT_TARGET

	if(!check_trajectory(L, src))
		return TURRET_NOT_TARGET

	if(L.stat == DEAD)
		return TURRET_NOT_TARGET

	if(check_id)
		var/id = L.GetIdCard()
		if(id && istype(id, /obj/item/card/id))
			return TURRET_NOT_TARGET
		else
			return TURRET_SECONDARY_TARGET

	if(!emagged && colony_allied_turret && L.colony_friend) //Dont target colony pets if were allied with them
		return TURRET_NOT_TARGET

	if(emagged)	// If emagged not even the dead get a rest
		return TURRET_PRIORITY_TARGET

	if(L.faction == "neutral")
		return TURRET_NOT_TARGET

	if(L.lying)
		return TURRET_SECONDARY_TARGET

	return TURRET_PRIORITY_TARGET	//if the perp has passed all previous tests, congrats, it is now a "shoot-me!" nominee

/obj/machinery/porta_turret/Union/tryToShootAt()
	if(!ammo)
		return FALSE
	..()

/obj/machinery/porta_turret/Union/shootAt(var/mob/living/target)
	var/turf/T = get_turf(src)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return

	if(!raised) //the turret has to be raised in order to fire - makes sense, right?
		return

	launch_projectile(target)
	sleep(shot_delay)
	launch_projectile(target)
	sleep(shot_delay)
	launch_projectile(target)

// this turret has no cover, it is always raised
/obj/machinery/porta_turret/Union/popUp()
	raised = TRUE

/obj/machinery/porta_turret/Union/popDown()
	last_target = null
	raised = TRUE

/obj/machinery/porta_turret/Union/update_icon()
	cut_overlays()

	if(!(stat & BROKEN))
		add_overlay(image("turret_carbine_union"))

/obj/machinery/porta_turret/Union/launch_projectile()
	ammo--
	..()

/obj/machinery/porta_turret/Union/opifex
	name = "opifex scrap turret"
	desc = "A fully automated battery powered anti-wildlife turret designed by the opifex. It features a three round burst barrel and isn't as sturdy nor as functional as other turrets. Fires 7.62mm rounds and holds only a measly 30 rounds."
	circuit = /obj/item/circuitboard/artificer_turret/opifex
	ammo_max = 30
	health = 75

/obj/machinery/porta_turret/Union/opifex/attackby(obj/item/I, mob/user)
	if (user.a_intent != I_HURT)
		if(stat & BROKEN)
			if(QUALITY_PRYING in I.tool_qualities)
				//If the turret is destroyed, you can remove it with a crowbar to
				//try and salvage its components
				to_chat(user, SPAN_NOTICE("You begin prying the metal coverings off."))
				if(do_after(user, 20, src))
					if(prob(70))
						to_chat(user, SPAN_NOTICE("You remove the turret and salvage some components."))
						if(prob(50))
							new /obj/item/circuitboard/artificer_turret/opifex(loc)
						if(prob(50))
							new /obj/item/stack/material/steel(loc, rand(1,4))
						if(prob(50))
							new /obj/item/device/assembly/prox_sensor(loc)
					else
						to_chat(user, SPAN_NOTICE("You remove the turret but did not manage to salvage anything."))
					qdel(src) // qdel

		else if(QUALITY_BOLT_TURNING in I.tool_qualities)
			if(enabled)
				to_chat(user, SPAN_WARNING("You cannot unsecure an active turret!"))
				return
			if(!anchored && isinspace())
				to_chat(user, SPAN_WARNING("Cannot secure turrets in space!"))
				return

			user.visible_message( \
					"<span class='warning'>[user] begins [anchored ? "un" : ""]securing the turret.</span>", \
					"<span class='notice'>You begin [anchored ? "un" : ""]securing the turret.</span>" \
				)

			if(do_after(user, 50, src))
				//This code handles moving the turret around. After all, it's a portable turret!
				if(!anchored)
					playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
					anchored = TRUE
					update_icon()
					to_chat(user, SPAN_NOTICE("You secure the exterior bolts on the turret."))
					if(disabled)
						spawn(200)
							disabled = FALSE
				else if(anchored)
					if(disabled)
						to_chat(user, SPAN_NOTICE("The turret is still recalibrating. Wait some time before trying to move it."))
						return
					playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
					anchored = 0
					disabled = TRUE
					to_chat(user, SPAN_NOTICE("You unsecure the exterior bolts on the turret."))
					update_icon()
			wrenching = 0

		else if(istype(I, /obj/item/cell/large))
			if(cell)
				to_chat(user, "<span class='notice'>\the [src] already has a cell.</span>")
			else
				user.unEquip(I)
				I.forceMove(src)
				cell = I
				to_chat(user, "<span class='notice'>You install a cell in \the [src].</span>")

		else if(istype(I, ammo_box) && I?:stored_ammo?:len)
			var/obj/item/ammo_magazine/A = I
			if(ammo >= ammo_max)
				to_chat(user, SPAN_NOTICE("You cannot load more than [ammo_max] ammo."))
				return

			var/transfered_ammo = 0
			for(var/obj/item/ammo_casing/AC in A.stored_ammo)
				A.stored_ammo -= AC
				qdel(AC)
				ammo++
				transfered_ammo++
				if(ammo == ammo_max)
					break
			to_chat(user, SPAN_NOTICE("You loaded [transfered_ammo] bullets into [src]. It now contains [ammo] ammo."))

	else
		..()

/obj/machinery/porta_turret/Union/opifex/update_icon()
	cut_overlays()

	if(!(stat & BROKEN))
		add_overlay(image("turret_gun_opi"))

#undef TURRET_PRIORITY_TARGET
#undef TURRET_SECONDARY_TARGET
#undef TURRET_NOT_TARGET
