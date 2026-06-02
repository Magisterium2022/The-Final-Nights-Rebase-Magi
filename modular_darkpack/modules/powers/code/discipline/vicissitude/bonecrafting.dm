/mob/living/carbon/human/proc/bonecrafting_modification(chosen_limb, mob/living/carbon/human/target, roll)
	switch(chosen_limb)
		if("left")
			var/obj/item/held_item = target.get_held_items_for_side(LEFT_HANDS)
			for(var/obj/item/I in target.get_held_items_for_side(LEFT_HANDS, all = TRUE)) //Covers edge cases with multiple limbs
				if(istype(I, /obj/item/bonecrafting_claws))
					target.visible_message(span_danger("[target]'s claws retracts back into their [chosen_limb] hand!"))
					qdel(I)
					return
			dropItemToGround(held_item, force = TRUE)
			target.apply_damage(max(0, (5 - roll)) LETHAL_TTRPG_DAMAGE, BRUTE, BODY_ZONE_L_ARM)
			target.visible_message(span_danger("[target] sprouts hideous bone claws from their [chosen_limb] hand!"))
			target.put_in_l_hand(new /obj/item/bonecrafting_claws)
		if("right")
			var/obj/item/held_item = target.get_held_items_for_side(RIGHT_HANDS)
			for(var/obj/item/I in target.get_held_items_for_side(RIGHT_HANDS, all = TRUE))
				if(istype(I, /obj/item/bonecrafting_claws))
					target.visible_message(span_danger("[target]'s claws retracts back into their [chosen_limb] hand!"))
					qdel(I)
					return
			dropItemToGround(held_item, force = TRUE)
			target.apply_damage(max(0, (5 - roll)) LETHAL_TTRPG_DAMAGE, BRUTE, BODY_ZONE_R_ARM)
			target.visible_message(span_danger("[target] sprouts hideous bone claws from their [chosen_limb] hand!"))
			target.put_in_r_hand(new /obj/item/bonecrafting_claws)

/obj/item/bonecrafting_claws
	name = "bone claws"
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
