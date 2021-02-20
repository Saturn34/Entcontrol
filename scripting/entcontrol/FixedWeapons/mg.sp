/* 
	------------------------------------------------------------------------------------------
	EntControl::MG
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void InitFixedMG()
{
	PrecacheModel("models/Shells/shell_762nato.mdl");
	
	PrecacheSound("weapons/smg1/smg1_fire1.wav");
	PrecacheSound("player/pl_shell2.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_MG_Spawn
	------------------------------------------------------------------------------------------
*/
public void Fixed_MG_Spawn(int client)
{
	float vAimPos[3];
	if (GetPlayerEye(client, vAimPos))
		Fixed_Base_Spawn(client, Fixed_MG_OnTrigger, vAimPos);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_MG_Fire
	------------------------------------------------------------------------------------------
*/
public void Fixed_MG_Fire(int gun, int client, int target, float vGunPos[3], float vAimPos[3], float vAngle[3])
{
	if (target)
		MakeDamage(client, target, 25, DMG_BULLET, 1.0, vGunPos);
	
	float fDirection[3] = {-90.0, 0.0, 0.0};
	env_shooter(fDirection, 1.0, 0.1, fDirection, 200.0, 120.0, 120.0, vGunPos, "models/Shells/shell_762nato.mdl");
	
	EmitSoundToAll("weapons/smg1/smg1_fire1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vGunPos);
	EmitSoundToAll("player/pl_shell2.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vGunPos);
}

public void Fixed_MG_OnTrigger(const char[] output, int caller, int activator, float delay)
{
	if(activator > 0 && activator <= MaxClients)
	{
		char tmp[32];
		GetEntPropString(caller, Prop_Data, "m_iName", tmp, sizeof(tmp));
		Fixed_Base_Think(StringToInt(tmp), activator, Fixed_MG_Fire);
	}
}
