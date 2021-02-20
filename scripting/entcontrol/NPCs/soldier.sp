/* put the line below after all of the includes!
#pragma newdecls required
*/

/* 
	------------------------------------------------------------------------------------------
	EntControl::Soldier
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitSoldier()
{
	PrecacheModel("models/combine_soldier.mdl");
	PrecacheModel("models/weapons/w_shotgun.mdl");
	
	PrecacheSound("npc/combine_soldier/vo/overwatchrequestreinforcement.wav");
	PrecacheSound("npc/combine_soldier/pain1.wav");
	PrecacheSound("npc/combine_soldier/die1.wav");
	PrecacheSound("npc/soldier/claw_strike1.wav");
}

/*
	------------------------------------------------------------------------------------------
	Command_Soldier
	------------------------------------------------------------------------------------------
*/
public Action Command_Soldier(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float position[3];
    	
	if(GetPlayerEye(client, position))
		Soldier_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/*
	------------------------------------------------------------------------------------------
	Soldier_Spawn
	------------------------------------------------------------------------------------------
*/
public Action Soldier_Spawn(float position[3])
{
	// Spawn
	int monster = BaseNPC_Spawn(position, "models/combine_soldier.mdl", SoldierSeekThink, "npc_soldier", "CrouchIdle");

	SDKHook(monster, SDKHook_OnTakeDamage, SoldierDamageHook);
	
	CreateTimer(10.0, SoldierIdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	
	char tmp[32];
	GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
	int monster_tmp = StringToInt(tmp);
	
	int weapon = CreateEntityByName("prop_dynamic_ornament");
	DispatchKeyValue(weapon, "model", "models/weapons/w_shotgun.mdl");
	DispatchKeyValue(weapon, "classname", "shotgun");
	DispatchSpawn(weapon);
	

	char entIndex[6];
	IntToString(weapon, entIndex, sizeof(entIndex)-1);
	
	DispatchKeyValue(monster_tmp, "targetname", entIndex);
	
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetParent");
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetAttached");
}

/* 
	------------------------------------------------------------------------------------------
	SoldierAttackThink
	------------------------------------------------------------------------------------------
*/
public Action SoldierSeekThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		int target = BaseNPC_GetTarget(monster);
		float vClientPosition[3];
		float vEntPosition[3];
		float vAngle[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			vEntPosition[2] += 20.0;
			if (GetVectorDistance(vClientPosition, vEntPosition, false) < 800.0 && BaseNPC_CanSeeEachOther(monster, target))
			{
				vClientPosition[2] -= 10.0;
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				//NormalizeVector(vAngle, vAngle);
				GetVectorAngles(vAngle, vAngle);

				Projectile(false, BaseNPC_GetOwner(monster), vEntPosition, vAngle, "models/Effects/combineball.mdl", gPlasmaSpeed, gPlasmaDamage, "weapons/Irifle/irifle_fire2.wav", true, view_as<float>({0.4, 1.0, 1.0}));
				
				BaseNPC_SetAnimation(monster, "shootSGc");
				SetEntityMoveType(monster, MOVETYPE_NONE);
			}
			else
			{
				BaseNPC_SetAnimation(monster, "Crouch_RunALL");
				SetEntityMoveType(monster, MOVETYPE_STEP);
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "CrouchIdle");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}


/* 
	------------------------------------------------------------------------------------------
	SoldierIdleThink
	------------------------------------------------------------------------------------------
*/
public Action SoldierIdleThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		BaseNPC_PlaySound(monster, "npc/combine_soldier/vo/overwatchrequestreinforcement.wav");
		
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
public Action SoldierDamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/combine_soldier/pain1.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, SoldierDamageHook);

		BaseNPC_Death(monster, attacker);
		
		BaseNPC_PlaySound(monster, "npc/combine_soldier/die1.wav");
	}
	
	return (Plugin_Handled);
}
