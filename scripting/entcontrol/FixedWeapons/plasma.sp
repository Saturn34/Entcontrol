/* 
	------------------------------------------------------------------------------------------
	EntControl::Plasma
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------

	------------------------------------------------------------------------------------------
	Fixed_Plasma_Spawn
	------------------------------------------------------------------------------------------
*/
public void Fixed_Plasma_Spawn(int client)
{
	float vAimPos[3];
	if (GetPlayerEye(client, vAimPos))
		Fixed_Base_Spawn(client, Fixed_Plasma_OnTrigger, vAimPos);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Plasma_Fire
	------------------------------------------------------------------------------------------
*/
public void Fixed_Plasma_Fire(int gun, int client, int target, float vGunPos[3], float vAimPos[3], float vAngle[3])
{
	Projectile(true, client, vGunPos, vAngle, "models/Effects/combineball.mdl", gPlasmaSpeed, gPlasmaDamage, "weapons/Irifle/irifle_fire2.wav", true, view_as<float>({0.4, 1.0, 1.0}));
}

public void Fixed_Plasma_OnTrigger(const char[] output, int caller, int activator, float delay)
{
	if(activator > 0 && activator <= MaxClients)
	{
		char tmp[32];
		GetEntPropString(caller, Prop_Data, "m_iName", tmp, sizeof(tmp));
		Fixed_Base_Think(StringToInt(tmp), activator, Fixed_Plasma_Fire);
	}
}
