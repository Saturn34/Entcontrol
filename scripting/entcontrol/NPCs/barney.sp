/* put the line below after all of the includes!
#pragma newdecls required
*/

/* 
	------------------------------------------------------------------------------------------
	EntControl::Barney
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitBarney()
{
	PrecacheModel("models/barney.mdl");
	PrecacheModel("models/weapons/w_pistol.mdl");
	
	PrecacheSound("vo/npc/Barney/ba_laugh01.wav");
	PrecacheSound("vo/npc/Barney/ba_laugh02.wav");
	PrecacheSound("vo/npc/Barney/ba_oldtimes.wav");
	PrecacheSound("vo/npc/Barney/ba_pain09.wav");
	PrecacheSound("vo/npc/Barney/ba_no01.wav");
	PrecacheSound("vo/npc/Barney/ba_losttouch.wav");
	PrecacheSound("weapons/deagle/deagle-1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Barney
	------------------------------------------------------------------------------------------
*/
public Action Command_Barney(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float position[3];
	if (GetPlayerEye(client, position))
		Barney_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Barney_Spawn
	------------------------------------------------------------------------------------------
*/
public void Barney_Spawn(float position[3])
{
	int monster = BaseNPC_Spawn(position, "models/barney.mdl", BarneySeekThink, "npc_barney", "wave");
	
	SDKHook(monster, SDKHook_OnTakeDamage, BarneyDamageHook);
	
	CreateTimer(10.0, BarneyIdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	SDKHook(monster, SDKHook_Touch, Barney_Touch);
}

/* 
	------------------------------------------------------------------------------------------
	Barney_Touch
	------------------------------------------------------------------------------------------
*/
public Action Barney_Touch(int monster, int other)
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

			if (StrEqual("weapon_deagle", edictname) || StrEqual("func_buyzone", edictname))
			{
				int weapon = CreateEntityByName("prop_dynamic_ornament");
				DispatchKeyValue(weapon, "model", "models/weapons/w_pistol.mdl");
				DispatchKeyValue(weapon, "classname", "Deagle");
				DispatchSpawn(weapon);
				
				char entIndex[6];
				IntToString(weapon, entIndex, sizeof(entIndex)-1);
				
				DispatchKeyValue(monster_tmp, "targetname", entIndex);
				
				SetVariantString(entIndex);
				AcceptEntityInput(weapon, "SetParent");
				SetVariantString(entIndex);
				AcceptEntityInput(weapon, "SetAttached");
				
				BaseNPC_SetAnimation(monster, "pickup");
				
				if (StrEqual("weapon_deagle", edictname))
					RemoveEntity(other);
			}
			else if (StrEqual("func_breakable", edictname) || StrEqual("func_breakable_surf", edictname))
			{
				BaseNPC_SetAnimation(monster, "swing");
				
				BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_losttouch.wav");
				
				AcceptEntityInput(other, "Break");
			}
			else if (StrEqual(edictname, "prop_physics")
				|| StrEqual(edictname, "prop_physics_multiplayer")
				|| StrEqual(edictname, "func_physbox")
				|| StrEqual(edictname, "player")
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
				
				BaseNPC_SetAnimation(monster, "pickup");
			}
		}
	}

	return (Plugin_Continue);
}

/* 
	------------------------------------------------------------------------------------------
	BarneyAttackThink
	------------------------------------------------------------------------------------------
*/
public Action BarneySeekThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
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
			
			char weaponClass[32];
			GetEdictClassname(StringToInt(targetname), weaponClass, 16);
			
			if (distance < 120.0 && BaseNPC_CanSeeEachOther(monster, target))
			{				
				BaseNPC_SetAnimation(monster, "swing");
				
				BaseNPC_HurtPlayer(monster, target, 15, 120.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_laugh02.wav");
			}
			else if (distance < 800.0 && StrEqual(weaponClass, "Deagle") && BaseNPC_CanSeeEachOther(monster, target))
			{
				BaseNPC_SetAnimation(monster, "shootp1");
				
				BaseNPC_HurtPlayer(monster, target, 30, 800.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "weapons/deagle/deagle-1.wav", 0.5);
				
				BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_laugh01.wav");
				
				SetEntityMoveType(monster, MOVETYPE_NONE);
				
				// Muzzle
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				GetVectorAngles(vAngle, vAngle);

				GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vAngle, vAngle);
				ScaleVector(vAngle, 20.0);
				AddVectors(vEntPosition, vAngle, vEntPosition);

				vEntPosition[2] -= 50.0;
				TE_SetupGlowSprite(vEntPosition, gMuzzle1, 1.1, 1.25, 255);
				TE_SendToAll();
			}
			else if (!StrEqual(targetname, "") && !StrEqual(weaponClass, "Deagle"))
			{
				int prop = StringToInt(targetname);
				BaseNPC_SetAnimation(monster, "throw1");
				AcceptEntityInput(prop, "ClearParent");
	
				DispatchKeyValue(monster_tmp, "targetname", "");
				DispatchKeyValue(prop, "classname", "prop_physics_multiplayer");
				
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				NormalizeVector(vAngle, vAngle);
				ScaleVector(vAngle, 5000.0);

				TeleportEntity(prop, NULL_VECTOR, NULL_VECTOR, vAngle);
			}
			else
			{
				if (StrEqual(targetname, ""))
					BaseNPC_SetAnimation(monster, "run_all");
				else
					BaseNPC_SetAnimation(monster, "run_holding_all");
					
				SetEntityMoveType(monster, MOVETYPE_STEP);
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "idle_subtle");
		}
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	BarneyIdleThink
	------------------------------------------------------------------------------------------
*/
public Action BarneyIdleThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		float vEntPosition[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_oldtimes.wav");
		
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
public Action BarneyDamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "vo/npc/Barney/ba_pain09.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, BarneyDamageHook);

		BaseNPC_Death(monster, attacker);
		
		float position[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", position);
		BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_no01.wav");
		
		SDKUnhook(monster, SDKHook_Touch, Barney_Touch);
	}
	
	return (Plugin_Handled);
}
