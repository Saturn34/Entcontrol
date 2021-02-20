/* 
	------------------------------------------------------------------------------------------
	EntControl::AntLion
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitAntlion()
{
	PrecacheModel("models/antlion.mdl");
	PrecacheSound("npc/antlion/attack_double3.wav");
	PrecacheSound("npc/antlion/idle3.wav");
	PrecacheSound("npc/antlion/distract1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_AntLion
	------------------------------------------------------------------------------------------
*/
public Action Command_AntLion(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float vPosition[3];
	if(GetPlayerEye(client, vPosition))
		AntLion_Spawn(vPosition);
	else
		PrintHintText(client, "%t", "Wrong entity"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	AntLion_Spawn
	------------------------------------------------------------------------------------------
*/
public void AntLion_Spawn(float vPosition[3])
{
	// Spawn
	int monster = BaseNPC_Spawn(vPosition, "models/antlion.mdl", AntLion_SeekThink, "npc_antlion");

	SDKHook(monster, SDKHook_OnTakeDamage, AntLion_DamageHook);
}

/* 
	------------------------------------------------------------------------------------------
	AntLion_SeekThink
	------------------------------------------------------------------------------------------
*/
public Action AntLion_SeekThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && BaseNPC_IsAlive(monster))
	{
		int target = BaseNPC_GetTarget(monster);
		
		if (target > 0)
		{
			float vClientPosition[3];
			float vEntPosition[3];
			GetClientEyePosition(target, vClientPosition);
			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
	
			if ((GetVectorDistance(vClientPosition, vEntPosition, false) < 120.0) && BaseNPC_CanSeeEachOther(monster, target))
			{
				BaseNPC_HurtPlayer(monster, target, 57);
				BaseNPC_PlaySound(monster, "npc/antlion/attack_double3.wav");
				BaseNPC_SetAnimation(monster, "attack2", 1.7);
				
				/*
				new Float:vReturn[3];
				MakeVectorFromPoints(vEntPosition, vClientPosition, vReturn);
				GetVectorAngles(vReturn, vReturn);
				NormalizeVector(vReturn, vReturn);
				ScaleVector(vReturn, 3000.0);
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vReturn);
				*/
			}
			else
			{
				BaseNPC_SetAnimation(monster, "walk_all");
			}
		}
		else
		{
			BaseNPC_PlaySound(monster, "npc/antlion/idle3.wav");
			BaseNPC_SetAnimation(monster, "idle");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	AntLion_DamageHook
	------------------------------------------------------------------------------------------
*/
public Action AntLion_DamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/antlion/attack_double3.wav"))
		SDKUnhook(monster, SDKHook_OnTakeDamage, AntLion_DamageHook);
	
	return (Plugin_Handled);
}
