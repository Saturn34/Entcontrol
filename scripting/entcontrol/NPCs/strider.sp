/* 
	------------------------------------------------------------------------------------------
	EntControl::Strider
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitStrider()
{
	PrecacheModel("models/Combine_Strider.mdl");
}

/*
	------------------------------------------------------------------------------------------
	Command_Strider
	------------------------------------------------------------------------------------------
*/
public Action Command_Strider(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float position[3];
    	
	if(GetPlayerEye(client, position))
		Strider_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Strider_Spawn
	------------------------------------------------------------------------------------------
*/
public void Strider_Spawn(float position[3])
{
	// Spawn
	int monster = BaseNPC_Spawn(position, "models/Combine_Strider.mdl", StriderThink, "npc_strider", "default");
	
	SDKHook(monster, SDKHook_OnTakeDamage, StriderDamageHook);
	//MakeDamage(fakeClient, target, damage, DMG_ACID, 1.0, NULL_FLOAT_VECTOR);
	BaseNPC_SetAnimation(monster, "physflinch1");
}

/* 
	------------------------------------------------------------------------------------------
	StriderAttackThink
	------------------------------------------------------------------------------------------
*/
public Action StriderThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEdict(monster) && IsValidEntity(monster))
	{
		float vEntPosition[3];
		float angles[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		// Bottom
		angles[0] = 90.0;
		angles[1] = 0.0;
		angles[2] = 0.0;
		Handle traceBottom = TR_TraceRayFilterEx(vEntPosition, angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterWall);

		if(TR_DidHit(traceBottom))
		{
			TR_GetEndPosition(vEntPosition, traceBottom);
			
			vEntPosition[2] += 250.0;
			TeleportEntity(monster, NULL_VECTOR, NULL_VECTOR, vEntPosition);
		}

		CloseHandle(traceBottom);
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	StriderDamageHook
	------------------------------------------------------------------------------------------
*/
public Action StriderDamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	char soundfile[32];
	Format(soundfile, sizeof(soundfile), "npc/strider/strider_pain%i.wav", GetRandomInt(1, 6));
	
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), soundfile))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, StriderDamageHook);
		
		BaseNPC_PlaySound(monster, "npc/strider/strider_die1.wav");
	}
	
	return (Plugin_Handled);
}
