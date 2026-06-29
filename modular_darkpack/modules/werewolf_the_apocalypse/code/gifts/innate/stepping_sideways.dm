/datum/action/cooldown/power/gift/stepping_sideways
	name = "Step Sideways"
	desc = "Enter the near Umbra through a reflective surface."
	button_icon_state = "call_of_the_wyld"
	rage_cost = 0
	check_flags = null
	innate_ability = TRUE
	var/static/list/special_reflective_surfaces = typecacheof(list(
		/obj/structure/window,
		/obj/structure/mirror,
		/obj/item/wallframe/mirror,
		/turf/open/water,
		/turf/open/floor/glass,
		/obj/item/shard,
		/obj/item/stack/sheet/glass,
	))

/datum/storyteller_roll/gift/stepping_sideways
	numerical = TRUE
	roll_output_type = ROLL_PRIVATE

/datum/action/cooldown/power/gift/stepping_sideways/IsAvailable(feedback)
	. = ..()
	var/turf/owner_turf = get_turf(owner)
	if(!is_reflection_nearby(get_turf(owner_turf)))
		to_chat(owner, span_warning("There's no reflective surfaces nearby!"))
		return FALSE

	if(owner_turf.is_blocked_turf(exclude_mobs = TRUE))
		to_chat(owner, span_warning("Something is blocking you from crossing the Gauntlet here!"))
		return FALSE

	if(HAS_TRAIT(owner, TRAIT_NO_SIDESTEPPING))
		to_chat(owner, span_warning("Reality flinches, you cannot cross the Gauntlet for a while!"))
		return FALSE

/datum/action/cooldown/power/gift/stepping_sideways/Activate()
	. = ..()

	var/datum/splat/werewolf/shifter/shifter = get_shifter_splat(owner)
	var/difficulty = owner.get_gauntlet_rating()
	var/successes = SSroll.storyteller_roll_datum(owner, roll_datum = /datum/storyteller_roll/gift/stepping_sideways, bonus = shifter.gnosis, difficulty = difficulty)

	if(successes < 0)
		to_chat(owner, span_bolddanger("You rapidly cross the gauntlet in a coruscating flash of light only to find yourself caught in a web!"))
	else if(successes == 0)
		to_chat(owner, span_danger("You attempt to cross the Gauntlet, but at the last moment you spot the Weaver's presence waiting for you! It won't be safe to attempt this again any time soon."))
		ADD_TRAIT(owner, TRAIT_NO_SIDESTEPPING, GIFT_TRAIT)
		addtimer(CALLBACK(src, PROC_REF(sidestepping_unlock)), 30 MINUTES)
	else if(successes == 1)
		to_chat(owner, span_warning("You begin to slowly cross the Gauntlet, although it is a great struggle!"))
		if(do_after(owner, 2.5 MINUTES))
			cross_gauntlet(owner)
		else to_chat(owner, span_warning("Your concentration is broken as you move!"))
	else if(successes == 2)
		to_chat(owner, span_warning("You begin to cross the Gauntlet, although it is somewhat difficult!"))
		if(do_after(owner, 15 SECONDS))
			cross_gauntlet(owner)
		else to_chat(owner, span_warning("Your concentration is broken as you move!"))
	else
		to_chat(owner, span_warning("You rapidly cross the gauntlet in a coruscating flash of light!"))
		cross_gauntlet(owner)
	return

/datum/action/cooldown/power/gift/stepping_sideways/proc/cross_gauntlet(var/mob/living/owner)
	if(HAS_TRAIT(owner, TRAIT_CURRENTLY_SIDESTEPPING))
		exit_umbra(owner)
	else
		enter_umbra(owner)

/datum/action/cooldown/power/gift/stepping_sideways/proc/enter_umbra(var/mob/living/owner)
	var/atom/nearby_reflection = is_reflection_nearby(owner)
	if(!nearby_reflection)
		to_chat(owner, span_warning("There are no reflective surfaces nearby to enter the mirror's realm!"))
		return

	owner.Beam(nearby_reflection, icon_state = "light_beam", time = 0.5 SECONDS)
	nearby_reflection.visible_message(span_warning("[nearby_reflection] begins to shimmer and shake slightly!"))
	if(!do_after(owner, 0.5 SECONDS, nearby_reflection, IGNORE_USER_LOC_CHANGE|IGNORE_INCAPACITATED, hidden = TRUE))
		return

	playsound(owner, 'sound/effects/magic/ethereal_enter.ogg', 50, TRUE, -1)
	owner.visible_message(
		span_boldwarning("[owner] phases out of reality, vanishing before your very eyes in a flash of coruscating lights!"),
		span_notice("You jump into the reflection coming off of [nearby_reflection], entering the Umbra."),
	)
	var/obj/item/organ/eyes/eyes = owner.get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		eyes.see_invisible = INVISIBILITY_REVENANT
	owner.update_sight()
	owner.invisibility = INVISIBILITY_REVENANT
	ADD_TRAIT(owner, TRAIT_CURRENTLY_SIDESTEPPING, GIFT_TRAIT)
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, GIFT_TRAIT)
	SEND_SIGNAL(owner, COMSIG_MASQUERADE_VIOLATION)
	owner.pass_flags |= (PASSDOORS | PASSTABLE | PASSSTRUCTURE) // Phase through doors & fences / tables / machines, dumpsters, barrels, lampposts

/datum/action/cooldown/power/gift/stepping_sideways/proc/exit_umbra(var/mob/living/owner)
	var/turf/phase_turf = get_turf(owner)
	var/atom/nearby_reflection = is_reflection_nearby(phase_turf)
	if(!nearby_reflection)
		to_chat(owner, span_warning("There are no reflective surfaces nearby to exit from the mirror's realm!"))
		return FALSE

	nearby_reflection.Beam(phase_turf, icon_state = "light_beam", time = 0.5 SECONDS)
	nearby_reflection.visible_message(span_warning("[nearby_reflection] begins to shimmer and shake slightly!"))
	if(!do_after(owner, 0.5 SECONDS, nearby_reflection, hidden = TRUE))
		return FALSE

	playsound(owner, 'sound/effects/magic/ethereal_exit.ogg', 50, TRUE, -1)
	owner.visible_message(
		span_boldwarning("[owner] phases into reality before your very eyes in a flash of coruscating lights!"),
		span_notice("You jump out of the reflection coming off of [nearby_reflection], exiting the Umbra."),
	)
	var/obj/item/organ/eyes/eyes = owner.get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		eyes.see_invisible = SEE_INVISIBLE_LIVING
	owner.update_sight()
	owner.invisibility = INVISIBILITY_NONE
	REMOVE_TRAIT(owner, TRAIT_CURRENTLY_SIDESTEPPING, GIFT_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, GIFT_TRAIT)
	SEND_SIGNAL(owner, COMSIG_MASQUERADE_VIOLATION)
	owner.pass_flags &= ~(PASSDOORS | PASSTABLE | PASSSTRUCTURE)

/datum/action/cooldown/power/gift/stepping_sideways/proc/sidestepping_unlock(atom/target)
	REMOVE_TRAIT(owner, TRAIT_NO_SIDESTEPPING, GIFT_TRAIT)
	to_chat(owner, span_warning("You feel ready to attempt to pass the Gauntlet again!"))

/**
 * Borrowed from base Heretic Mirrorwalk.
 * 
 * Goes through all nearby atoms in sight of the
 * passed caster and determines if they are "reflective"
 * for the purpose of us being able to utilize it to enter or exit.
 *
 * Returns an object reference to a "reflective" object in view if one was found,
 * or null if no object was found that was determined to be "reflective".
 */
/datum/action/cooldown/power/gift/stepping_sideways/proc/is_reflection_nearby(atom/caster)
	for(var/atom/thing as anything in view(2, caster))
		if(isitem(thing))
			var/obj/item/item_thing = thing
			if(item_thing.IsReflect())
				return thing

		if(ishuman(thing))
			var/mob/living/carbon/human/human_thing = thing
			if(human_thing.check_reflect())
				return thing

		if(isturf(thing))
			var/turf/turf_thing = thing
			if(turf_thing.turf_flags & NOJAUNT)
				continue
			if(turf_thing.flags_ricochet & RICOCHET_SHINY)
				return thing

		if(is_type_in_typecache(thing, special_reflective_surfaces))
			return thing

	return null
