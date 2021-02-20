/* put the line below after all of the includes!
#pragma newdecls required
*/

/* 
	------------------------------------------------------------------------------------------
	EntControl::Police
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitPolice()
{
	PrecacheModel("models/police.mdl");
	PrecacheModel("models/weapons/w_stunbato.mdl");
	
	PrecacheSound("npc/metropolice/vo/freeman.wav");
	PrecacheSound("npc/metropolice/pain1.wav");
	PrecacheSound("npc/metropolice/die1.wav");
	PrecacheSound("weapons/stunstick/stunstick_impact1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Police
	------------------------------------------------------------------------------------------
*/
public Action Command_Police(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float position[3];
	if(GetPlayerEye(client, position))
		Police_Spawn(position, client);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Police_Spawn
	------------------------------------------------------------------------------------------
*/
stock void Police_Spawn(float position[3], int owner = 0)
{
	// Spawn
	int monster = BaseNPC_Spawn(position, "models/police.mdl", PoliceSeekThink, "npc_police", "Idle_Baton");
	
	SDKHook(monster, SDKHook_OnTakeDamage, PoliceDamageHook);
	
	CreateTimer(10.0, PoliceIdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	if (owner)
		BaseNPC_SetOwner(monster, owner);
	
	char tmp[32];
	GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
	int monster_tmp = StringToInt(tmp);
	
	int weapon = CreateEntityByName("prop_dynamic_ornament");
	DispatchKeyValue(weapon, "model", "models/weapons/w_stunbaton.mdl");
	DispatchKeyValue(weapon, "classname", "stunstick");
	DispatchSpawn(weapon);
	
	char entIndex[6];
	IntToString(EntIndexToEntRef(weapon), entIndex, sizeof(entIndex)-1);
	DispatchKeyValue(monster_tmp, "targetname", entIndex);
	
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetParent");
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetAttached");
}

/* 
	------------------------------------------------------------------------------------------
	PoliceAttackThink
	------------------------------------------------------------------------------------------
*/
public Action PoliceSeekThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		int target = BaseNPC_GetTarget(monster);
		float vClientPosition[3];
		float vEntPosition[3];

		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			if ((GetVectorDistance(vClientPosition, vEntPosition, false) < 120.0))
			{
				BaseNPC_SetAnimation(monster, "swing");
				
				BaseNPC_HurtPlayer(monster, target, 30, 120.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "weapons/stunstick/stunstick_impact1.wav");
			}
			else
			{
				BaseNPC_SetAnimation(monster, "walk_hold_baton_angry");
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "Idle_Baton");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}


/* 
	------------------------------------------------------------------------------------------
	PoliceIdleThink
	------------------------------------------------------------------------------------------
*/
public Action PoliceIdleThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		BaseNPC_PlaySound(monster, "npc/metropolice/vo/freeman.wav");
		
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
public Action PoliceDamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/metropolice/pain1.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, PoliceDamageHook);

		BaseNPC_Death(monster, attacker);

		BaseNPC_PlaySound(monster, "npc/metropolice/die1.wav");
	}
	
	return (Plugin_Handled);
}
