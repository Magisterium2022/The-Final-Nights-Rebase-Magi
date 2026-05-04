
// Level 5: Slimegirl tzimisce

/datum/discipline/vicissitude
	name = "Vicissitude"
	desc = {"It is widely known as Tzimisce art of flesh and bone shaping. Violates Masquerade.
● Malleable Visage: Passive
●● Fleshcrafting: Passive
●●● Bonecrafting: Strength + Medicine (difficulty 7)
●●●● Horrid Form: Passive
●●●●● Bloodform: Passive"} // TFN EDIT CHANGE - ORIGINAL: desc = "It is widely known as Tzimisce art of flesh and bone shaping. Violates Masquerade."
	icon_state = "vicissitude"
	clan_restricted = TRUE
	power_type = /datum/discipline_power/vicissitude

/datum/discipline_power/vicissitude
	name = "Vicissitude power name"
	desc = "Vicissitude power description"

	var/datum/action/cooldown/mob_cooldown/shapeshift/shapeshift_ability

/datum/discipline_power/vicissitude/post_gain()
	if(!shapeshift_ability)
		shapeshift_ability = new(owner)
	shapeshift_ability.Grant(owner)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/discipline_power/vicissitude/malleable_visage
	name = "Malleable Visage"
	desc = "Shapeshift yourself."

	level = 1
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_FREE_HAND
	target_type = NONE
	cooldown_length = 1 TURNS
	vitae_cost = 1
	toggled = FALSE

/datum/discipline_power/vicissitude/malleable_visage/activate(atom/target)
	. = ..()
	shapeshift_ability.Activate(owner)
	return TRUE

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/discipline_power/vicissitude/fleshcrafting
	name = "Fleshcrafting"
	desc = "Shapeshift yourself or others."

	level = 2
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_FREE_HAND | DISC_CHECK_IMMOBILE
	target_type = TARGET_SELF | TARGET_HUMAN
	vitae_cost = 1
	range = 1
	toggled = FALSE
	cooldown_length = 1 TURNS

/datum/discipline_power/vicissitude/fleshcrafting/activate(atom/movable/target)
	. = ..()
	shapeshift_ability.Activate(target)
	return TRUE

/datum/discipline_power/vicissitude/fleshcrafting/post_gain()
	. = ..()
	var/obj/item/organ/cyberimp/arm/toolkit/surgery/vicissitude/surgery_implant = new()
	surgery_implant.Insert(owner)
	RegisterSignal(owner, COMSIG_LIVING_OPERATING_ON, PROC_REF(add_surgery))

/datum/discipline_power/vicissitude/fleshcrafting/Destroy(force)
	UnregisterSignal(owner, COMSIG_LIVING_OPERATING_ON)
	return ..()

/datum/discipline_power/vicissitude/fleshcrafting/proc/add_surgery(datum/source, atom/movable/operating_on, list/possible_operations)
	SIGNAL_HANDLER

	var/static/list/tzimisce_operations
	if(!length(tzimisce_operations))
		tzimisce_operations = list()
		tzimisce_operations += /datum/surgery_operation/basic/tend_wounds/combo/upgraded/master
		tzimisce_operations += /datum/surgery_operation/limb/add_plastic
		tzimisce_operations += typesof(/datum/surgery_operation/limb/bioware)
		tzimisce_operations += typesof(/datum/surgery_operation/organ/brainwash)
		tzimisce_operations += typesof(/datum/surgery_operation/organ/lobotomy)
		tzimisce_operations += typesof(/datum/surgery_operation/organ/pacify)
		tzimisce_operations += /datum/surgery_operation/organ/eye_color_surgery
		tzimisce_operations += /datum/surgery_operation/limb/sex_change
		tzimisce_operations += /datum/surgery_operation/limb/height_change
		tzimisce_operations += /datum/surgery_operation/limb/modify_hair
		tzimisce_operations += /datum/surgery_operation/limb/modify_skin

	possible_operations |= tzimisce_operations

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/discipline_power/vicissitude/bonecrafting
	name = "Bonecrafting"
	desc = "Forcefully injure a body or grow claws."

	level = 3
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_FREE_HAND | DISC_CHECK_IMMOBILE
	target_type =  TARGET_SELF | TARGET_MOB
	vitae_cost = 1
	range = 1
	toggled = FALSE
	aggravating = TRUE
	hostile = TRUE
	violates_masquerade = TRUE
	activate_sound = 'modular_darkpack/modules/powers/sounds/vicissitude.ogg'
	cooldown_length = 1 TURNS

/datum/discipline_power/vicissitude/bonecrafting/activate(mob/living/target)
	. = ..()

	var/roll = SSroll.storyteller_roll((owner.st_get_stat(STAT_STRENGTH) + owner.st_get_stat(STAT_MEDICINE)), 7, owner, target, TRUE)

	if(owner.combat_mode)
		if(target.stat >= HARD_CRIT)
			if(target.stat != DEAD)
				target.death()
			var/obj/item/bodypart/arm/right/r_arm = target.get_bodypart(BODY_ZONE_R_ARM)
			var/obj/item/bodypart/arm/left/l_arm = target.get_bodypart(BODY_ZONE_L_ARM)
			var/obj/item/bodypart/leg/right/r_leg = target.get_bodypart(BODY_ZONE_R_LEG)
			var/obj/item/bodypart/leg/left/l_leg = target.get_bodypart(BODY_ZONE_L_LEG)
			r_arm?.drop_limb()
			l_arm?.drop_limb()
			r_leg?.drop_limb()
			l_leg?.drop_limb()
			new /obj/item/stack/sheet/meat/twenty(target.loc)
			new /obj/item/guts(target.loc)
			new /obj/item/spine(target.loc)
			qdel(target)
		else
			target.emote("scream")
			target.apply_damage(roll LETHAL_TTRPG_DAMAGE, BRUTE, BODY_ZONE_CHEST)
			if(roll >= 5)
				target.visible_message(span_danger("[target]'s rib cage curves inwards grotesquely!"), span_danger("Your feel your ribcages curve inwards and pierce your heart!"))
				target.adjust_blood_pool(-(round(target.bloodpool * 0.5))) // A vampire who scores five or more successes on the roll (...) cause the affected vampire to lose half his blood points.
	else
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/limb = tgui_input_list(owner, "Which arm should grow claws?", "Choice", list("Left", "Right"))
			if(!limb)
				return FALSE
			H.bonecrafting_modification(limb, target, roll)

/mob/living/carbon/human/proc/bonecrafting_modification(chosen_limb, mob/living/carbon/human/target, roll)
	switch(chosen_limb)
		if("Left")
			var/obj/item/held_item = target.get_held_items_for_side(LEFT_HANDS)
			if(held_item == /obj/item/bonecrafting_claws)
				target.visible_message(span_danger("[target]'s claws retracts back into their [chosen_limb] hand!"))
				for(var/obj/item/bonecrafting_claws/claws in target.get_held_items_for_side(LEFT_HANDS))
					qdel(claws)
					return
			dropItemToGround(held_item, force = TRUE)
			target.apply_damage(max(0, (5 - roll)) LETHAL_TTRPG_DAMAGE, BRUTE, BODY_ZONE_L_ARM)
			target.visible_message(span_danger("[target] sprouts hideous bone claws from their [chosen_limb] hand!"))
			target.put_in_l_hand(new /obj/item/gangrel_claws)
		if("Right")
			var/obj/item/held_item = target.get_held_items_for_side(RIGHT_HANDS)
			if(held_item == /obj/item/bonecrafting_claws)
				target.visible_message(span_danger("[target]'s claws retracts back into their [chosen_limb] hand!"))
				for(var/obj/item/bonecrafting_claws/claws in target.get_held_items_for_side(RIGHT_HANDS))
					qdel(claws)
					return
			dropItemToGround(held_item, force = TRUE)
			target.apply_damage(max(0, (5 - roll)) LETHAL_TTRPG_DAMAGE, BRUTE, BODY_ZONE_R_ARM)
			target.visible_message(span_danger("[target] sprouts hideous bone claws from their [chosen_limb] hand!"))
			target.put_in_r_hand(new /obj/item/gangrel_claws)

/obj/item/bonecrafting_claws
	name = "claws"
	desc = "Don't cut yourself accidentally."
	icon_state = "gangrel"
	icon = 'modular_darkpack/modules/weapons/icons/weapons.dmi'
	lefthand_file = 'modular_darkpack/modules/deprecated/icons/lefthand.dmi'
	righthand_file = 'modular_darkpack/modules/deprecated/icons/righthand.dmi'
	hitsound = 'sound/items/weapons/slash.ogg'
	force = 1 TTRPG_DAMAGE
	damtype = BRUTE
	sharpness = SHARP_EDGED
	item_flags = DROPDEL
	masquerade_violating = TRUE
	obj_flags = NONE

/obj/item/bonecrafting_claws/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, INNATE_TRAIT)

/obj/item/bonecrafting_claws/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	force = ((user.st_get_stat(STAT_STRENGTH) + 1) * 5) //Half TTRPG damage per hit.

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/discipline_power/vicissitude/horrid_form
	name = "Horrid Form"
	desc = "Force yourself to become something truly monstrous."

	level = 4
	violates_masquerade = TRUE
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_FREE_HAND | DISC_CHECK_IMMOBILE
	target_type = NONE
	vitae_cost = 2
	aggravating = TRUE
	cooldown_length = 1 TURNS
	activate_sound = 'modular_darkpack/modules/powers/sounds/vicissitude.ogg'
	var/datum/action/cooldown/spell/shapeshift/zulo/zulo_form

/datum/discipline_power/vicissitude/horrid_form/pre_activation_checks()
	. = ..()
	owner.do_jitter_animation(1 TURNS)
	if(!do_after(owner, 1 TURNS, owner))
		return FALSE
	return TRUE

/datum/discipline_power/vicissitude/horrid_form/activate()
	. = ..()
	if(!zulo_form)
		zulo_form = new(owner)
		zulo_form.Grant(owner)
	zulo_form.Activate(owner)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/discipline_power/vicissitude/bloodform
	name = "Bloodform"
	desc = "Liquify into a shifting mass of sentient Vitae."

	level = 5
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_FREE_HAND
	target_type = NONE
	violates_masquerade = TRUE
	cooldown_length = 1 TURNS
	toggled = TRUE
	activate_sound = 'modular_darkpack/modules/powers/sounds/vicissitude.ogg'

/datum/discipline_power/vicissitude/bloodform/pre_activation_checks()
	. = ..()
	owner.do_jitter_animation(1 TURNS)
	if(!do_after(owner, 1 TURNS, owner))
		return FALSE
	return TRUE

/datum/discipline_power/vicissitude/bloodform/activate()
	. = ..()
	owner.set_species(mrace = /datum/species/tzimisce_blood_form, icon_update = TRUE, pref_load = TRUE, replace_missing = FALSE)

/datum/discipline_power/vicissitude/bloodform/deactivate()
	. = ..()
	owner.do_jitter_animation(1 TURNS)
	if(!do_after(owner, 1 TURNS, owner))
		return FALSE
	owner.set_species(mrace = /datum/species/human, icon_update = TRUE, pref_load = TRUE, replace_missing = FALSE)
	return TRUE
