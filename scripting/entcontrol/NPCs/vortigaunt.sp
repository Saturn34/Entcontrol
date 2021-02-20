/* 
	------------------------------------------------------------------------------------------
	EntControl::Vortigaunt
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

int gVortigauntBeam;

public void InitVortigaunt()
{
	PrecacheModel("models/vortigaunt.mdl");
	PrecacheSound("npc/vort/attack_shoot.wav");
	PrecacheSound("npc/vort/claw_swing2.wav");
	PrecacheSound("npc/vort/health_charge.wav");
	PrecacheSound("npc/antlion_guard/angry2.wav");
	
	gVortigauntBeam = PrecacheModel("materials/sprites/laser.vmt");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Vortigaunt
	------------------------------------------------------------------------------------------
*/
public Action Command_Vortigaunt(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	float position[3];
	if (GetPlayerEye(client, position))
		Vortigaunt_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong entity"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Vortigaunt_Spawn
	------------------------------------------------------------------------------------------
*/
public void Vortigaunt_Spawn(float position[3])
{
	// Spawn
	int monster = BaseNPC_Spawn(position, "models/vortigaunt.mdl", VortigauntSeekThink, "npc_vortigaunt", "Idle01");

	SDKHook(monster, SDKHook_OnTakeDamage, VortigauntDamageHook);

	CreateTimer(5.0, VortigauntShootThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/* 
	------------------------------------------------------------------------------------------
	VortigauntSeekThink
	------------------------------------------------------------------------------------------
*/
public Action VortigauntSeekThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		float vClientPosition[3];
		float vEntPosition[3];
		
		int target = BaseNPC_GetTarget(monster);
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			
			if ((GetVectorDistance(vClientPosition, vEntPosition, false) < 120) && BaseNPC_CanSeeEachOther(monster, target))
			{
				VortigauntAttack1(monster, target, vClientPosition, vEntPosition);
			}
			else
			{
				BaseNPC_SetAnimation(monster, "Run_all");
			}
		}
		else
		{
			EmitSoundToAll("npc/vort/health_charge.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
			BaseNPC_SetAnimation(monster, "Idle01");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	VortigauntShootThink
	------------------------------------------------------------------------------------------
*/
public Action VortigauntShootThink(Handle timer, any monsterRef)
{
	int monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		int target = BaseNPC_GetTarget(monster);
		if (target > 0)
		{
			float vClientPosition[3];
			float vEntPosition[3];
			
			GetClientEyePosition(target, vClientPosition);
			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
			vEntPosition[2] += 60.0;
			
			if (GetVectorDistance(vClientPosition, vEntPosition, false) > 120)
			{
				if (BaseNPC_CanSeeEachOther(monster, target))
				{
					VortigauntAttack2(monster, target, vClientPosition, vEntPosition);
				}
			}
		}
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	VortigauntShoot
	------------------------------------------------------------------------------------------
*/
public Action VortigauntShoot(Handle timer, Handle data)
{
	int monster, target;
	float vClientPosition[3];
	float vEntPosition[3];
	
	ResetPack(data);
	monster = EntRefToEntIndex(ReadPackCell(data));
	target = ReadPackCell(data);
	vEntPosition[0] = ReadPackFloat(data);
	vEntPosition[1] = ReadPackFloat(data);
	vEntPosition[2] = ReadPackFloat(data);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		if (BaseNPC_CanSeeEachOther(monster, target))
		{
			GetClientEyePosition(target, vClientPosition);
			
			EmitSoundToAll("npc/vort/attack_shoot.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
			MakeDamage(fakeClient, target, 21, DMG_BULLET, 100.0, vClientPosition);
			
			TE_SetupBeamPoints(vEntPosition, vClientPosition, gVortigauntBeam, 0, 0, 0, 0.5, 5.0, 10.0, 0, 25.0, {100, 255, 100, 255}, 20 );
			TE_SendToAll();
			
			TE_SetupBeamPoints(vEntPosition, vClientPosition, gVortigauntBeam, 0, 0, 0, 0.5, 4.0, 5.0, 0, 15.0, {150, 255, 150, 255}, 10 );
			TE_SendToAll();
		}
		
		SetEntityMoveType(monster, MOVETYPE_STEP);
		
		BaseNPC_SetAnimation(monster, "Run_all");
	}
}

/* 
	------------------------------------------------------------------------------------------
	VortigauntAttack1
	Attack1 -> Melee
	------------------------------------------------------------------------------------------
*/
public void VortigauntAttack1(int monster, int target, float vClientPosition[3], float vEntPosition[3])
{
	MakeDamage(fakeClient, target, 57, DMG_BULLET, 100.0, vClientPosition);
	
	EmitSoundToAll("npc/vort/claw_swing2.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);

	BaseNPC_SetAnimation(monster, "MeleeHigh1");
}

/* 
	------------------------------------------------------------------------------------------
	VortigauntAttack2
	Attack2 -> Shoot
	------------------------------------------------------------------------------------------
*/
public void VortigauntAttack2(int monster, int target, float vClientPosition[3], float vEntPosition[3])
{
	float vAngle[3];

	BaseNPC_SetAnimation(monster, "zapattack1");

	MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
	//NormalizeVector(vAngle, vAngle);
	GetVectorAngles(vAngle, vAngle);

	TeleportEntity(monster, NULL_VECTOR, vAngle, NULL_VECTOR);

	vEntPosition[2] -= 20.0;
	TE_SetupBeamRingPoint(vEntPosition, 0.0, 30.0, gVortigauntBeam, gVortigauntBeam, 0, 0, 0.5, 10.0, 25.0, {100, 255, 100, 255}, 20, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vEntPosition, 0.0, 50.0, gVortigauntBeam, gVortigauntBeam, 0, 0, 1.4, 10.0, 25.0, {200, 255, 100, 255}, 20, 0);
	TE_SendToAll();

	// Light
	int light = CreateEntityByName("light_dynamic");

	DispatchKeyValue(light, "_light", "100 255 100 255");
	DispatchKeyValue(light, "brightness", "3");
	DispatchKeyValueFloat(light, "spotlight_radius", 100.0);
	DispatchKeyValueFloat(light, "distance", 100.0);
	DispatchKeyValue(light, "style", "6");

	// SetEntityMoveType(light, MOVETYPE_NOCLIP); 
	DispatchSpawn(light);
	AcceptEntityInput(light, "TurnOn");

	TeleportEntity(light, vEntPosition, NULL_VECTOR, NULL_VECTOR);

	KillEntity(light, 1.5);

	SetEntityMoveType(monster, MOVETYPE_NONE);

	Handle data;
	CreateDataTimer(1.5, VortigauntShoot, data, TIMER_FLAG_NO_MAPCHANGE);	
	WritePackCell(data, EntIndexToEntRef(monster));
	WritePackCell(data, target);
	WritePackFloat(data, vEntPosition[0]);
	WritePackFloat(data, vEntPosition[1]);
	WritePackFloat(data, vEntPosition[2]);
}

/* 
	------------------------------------------------------------------------------------------
	VortigauntDamageHook
	------------------------------------------------------------------------------------------
*/
public Action VortigauntDamageHook(int monster, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/antlion_guard/angry2.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, VortigauntDamageHook);
		BaseNPC_Death(monster, attacker);
	}
	else
	{
		float vClientPosition[3];
		float vEntPosition[3];
		
		if (attacker > 0)
		{
			GetClientEyePosition(attacker, vClientPosition);
			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
			
			if (GetVectorDistance(vClientPosition, vEntPosition, false) < 120)
				VortigauntAttack1(monster, attacker, vClientPosition, vEntPosition);
		}
	}
	
	return (Plugin_Handled);
}
