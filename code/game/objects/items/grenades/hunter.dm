/obj/item/grenade/sunlight
	name = "Solar Grenade"
	desc = "An odd looking grenade."
	icon_state = "emp"
	inhand_icon_state = "emp"

/obj/item/grenade/sunlight/detonate()
	var/detonate_turf = get_turf(src)
	if(!detonate_turf)
		return
	do_sparks(rand(5, 9), FALSE, src)
	playsound(detonate_turf, 'sound/weapons/flashbang.ogg', 100, TRUE, 8, 0.9)
	for(var/mob/living/carbon/human/H in range(5, detonate_turf)) //Five tile range
		if(get_kindred_splat(H))
			to_chat(H, span_userdanger("The grenade erupts in a flash of burning light!"))
			H.apply_damage(9 TTRPG_DAMAGE, BURN)
			if(HAS_TRAIT(H, TRAIT_LIGHT_WEAKNESS))
				H.apply_damage(9 TTRPG_DAMAGE, BURN)
