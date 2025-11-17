extends Node
class_name customFunctions

###
## here, you can write custom logic to attach to BuHSpawner.gd
## just create a function, and call then call it from BuHSpawner.gd using CUSTOM.<yourfunction>
## it is better than writing custom logic in BuHSpawner.gd
## because your code would be overwritten at each plugin update
###

func bullet_collide_body(body_rid:RID,body:Node,body_shape_index:int,local_shape_index:int,shared_area:Area2D, B:Dictionary, b:RID) -> void:
	## you can use B["props"]["damage"] to get the bullet's damage
	## you can use B["props"]["<your custom data name>"] to get the bullet's custom data
	
	print("DEBUG: bullet_collide_body called with body: ", body.name, " groups: ", body.get_groups())
	
	# Handle player damage
	if body.is_in_group("Player"):
		print("DEBUG: Player collision detected!")
		
		# Check if player has active parry shield
		if body.has_method("is_parrying") and body.is_parrying():
			print("DEBUG: Bullet blocked by parry shield!")
			# Bullet is blocked, destroy it without dealing damage
			Spawning.delete_bullet(b)
			return
		
		var damage = B["props"].get("damage", 1.0)
		print("DEBUG: Bullet damage: ", damage)
		if body.has_method("take_damage"):
			print("DEBUG: Calling take_damage on player")
			body.take_damage(damage)
		else:
			print("DEBUG: Player does not have take_damage method!")
	else:
		print("DEBUG: Body is not in Player group")


func bullet_collide_area(area_rid:RID,area:Area2D,area_shape_index:int,local_shape_index:int,shared_area:Area2D) -> void:
	## you can use B["props"]["damage"] to get the bullet's damage
	## you can use B["props"]["<your custom data name>"] to get the bullet's custom data
	
	############## uncomment if you want to use the standard behavior below ##############
	#var rid = Spawning.shape_rids.get(shared_area.name, {}).get(local_shape_index)
	#if not Spawning.poolBullets.has(rid): return
	#var B = Spawning.poolBullets[rid]
	
	############## emit signal
#	Spawning.bullet_collided_area.emit(area,area_shape_index,B,local_shape_index,shared_area)
	
	############## uncomment to manage trigger collisions with area collisions
#	if B["trig_types"].has("TrigCol"):
#		B["trig_collider"] = area
#		B["trig_container"].checkTriggers(B, rid)
	pass
