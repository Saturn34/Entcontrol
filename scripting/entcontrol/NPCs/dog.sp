/* 
	------------------------------------------------------------------------------------------
	EntControl::Dog
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitDog()
{
	PrecacheModel("models/dog.mdl");
	
	PrecacheSound("npc/dog/dog_angry1.wav");
	PrecacheSound("npc/dog/dog_alarmed1.wav");
	PrecacheSound("npc/dog/dog_scared1.wav");
	PrecacheSound("npc/dog/dog_drop_gate1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Dog
	------------------------------------------------------------------------------------------
*/
public Action Command_Dog(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float position[3];
	if (GetPlayerEye(client, position))
		Dog_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Dog_Spawn
	------------------------------------------------------------------------------------------
*/
public void Dog_Spawn(float position[3])
{
	int monster = BaseNPC_Spawn(position, "models/dog.mdl", Dog_SeekThink, "npc_dog", "idle01");
	
	SDKHook(monster, SDKHook_OnTakeDamage, Dog_DamageHook);
	
	CreateTimer(10.0, Dog_IdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	SDKHook(monster, SDKHook_Touch, Dog_Touch);
}

/* 
	------------------------------------------------------------------------------------------
	Dog_Touch
	------------------------------------------------------------------------------------------
*/
public Action Dog_Touch(int monster, int other)
{
	if (other)
	{
		char tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		int monster_tmp = StringToInt(tmp);
			
		char targetname[32];
		GetEntPropString(monster_tmp, Prop_Data, "m_iName", targetname, sizeof(targetname));
		
		if (StrEqual(targetname, ""))
		{
			char edictname[32];
			GetEdictClassname(other, edictname, 32);

			if (StrEqual(edictname, "prop_physics")
				|| StrEqual(edictname, "prop_physics_multiplayer")
				|| StrEqual(edictname, "func_physbox")
				/*|| StrEqual(edictname, "player")*/
				|| StrEqual(edictname, "phys_magnet"))
			{
				char entIndex[6];
				IntToString(other, entIndex, sizeof(entIndex)-1);
				
				DispatchKeyValue(monster_tmp, "targetname", entIndex);
				DispatchKeyValue(other, "classname", entIndex);
				
				IntToString(monster_tmp, entIndex, sizeof(entIndex)-1);
				SetVariantString(entIndex);
				AcceptEntityInput(other, "SetParent");
				SetVariantString(entIndex);
				AcceptEntityInput(other, "SetAttached");
				
				BaseNPC_SetAnimation(monster, "fetch_front");
			}
		}
	}

	return (Plugin_Continue);
}

/* 
	------------------------------------------------------------------------------------------
	DogAttackThink
	------------------------------------------------------------------------------------------
*/
public Action Dog_SeekThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEdict(monster) && IsValidEntity(monster))
	{
		char tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		int monster_tmp = StringToInt(tmp);
		
		int target = BaseNPC_GetTarget(monster);
		float vClientPosition[3];
		float vEntPosition[3];
		float vAngle[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			
			char targetname[32];
			GetEntPropString(monster_tmp, Prop_Data, "m_iName", targetname, sizeof(targetname));
			float distance = GetVectorDistance(vClientPosition, vEntPosition, false);
			
			if (!StrEqual(targetname, ""))
			{
				int prop = StringToInt(targetname);
				BaseNPC_SetAnimation(monster, "throw", 1.43);
				AcceptEntityInput(prop, "ClearParent");
	
				DispatchKeyValue(monster_tmp, "targetname", "");
				DispatchKeyValue(prop, "classname", "prop_physics_multiplayer");
				
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				NormalizeVector(vAngle, vAngle);
				ScaleVector(vAngle, 10000.0);

				TeleportEntity(prop, NULL_VECTOR, NULL_VECTOR, vAngle);
			}
			else if (distance < 120.0 && BaseNPC_CanSeeEachOther(monster, target))
			{				
				BaseNPC_SetAnimation(monster, "pound", 3.6);
				
				BaseNPC_HurtPlayer(monster, target, 80, 120.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "npc/dog/dog_drop_gate1.wav");
			}
			else if (GetRandomInt(0, 4) == 1)
			{
				int entity = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(entity, "model", "models/props_wasteland/rockgranite03b.mdl"); // models/props_wasteland/rockgranite03b.mdl
				DispatchKeyValue(entity, "physdamagescale", "10000.0");
				DispatchSpawn(entity);
				
				TeleportEntity(entity, vEntPosition, NULL_VECTOR, NULL_VECTOR);
				
				char entIndex[6];
				IntToString(entity, entIndex, sizeof(entIndex)-1);
				
				DispatchKeyValue(monster_tmp, "targetname", entIndex);
				DispatchKeyValue(entity, "classname", entIndex);
				
				IntToString(monster_tmp, entIndex, sizeof(entIndex)-1);
				SetVariantString(entIndex);
				AcceptEntityInput(entity, "SetParent");
				SetVariantString(entIndex);
				AcceptEntityInput(entity, "SetAttached");
				
				BaseNPC_SetAnimation(monster, "fetch_front");
			}
			else
			{
				if (StrEqual(targetname, ""))
					BaseNPC_SetAnimation(monster, "run_all", 0.95);
					
				SetEntityMoveType(monster, MOVETYPE_STEP);
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "idle01");
		}
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	DogIdleThink
	------------------------------------------------------------------------------------------
*/
public Action Dog_IdleThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		float vEntPosition[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		BaseNPC_PlaySound(monster, "npc/dog/dog_scared1.wav");
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	HeadCrabDamageHook
	------------------------------------------------------------------------------------------
*/
public Action Dog_DamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/dog/dog_angry1.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, Dog_DamageHook);
		SDKUnhook(monster, SDKHook_Touch, Dog_Touch);

		BaseNPC_Death(monster, attacker);
		
		BaseNPC_PlaySound(monster, "npc/dog/dog_alarmed1.wav");
	}
	
	return (Plugin_Handled);
}
