/* put the line below after all of the includes!
#pragma newdecls required
*/

/* 
	------------------------------------------------------------------------------------------
	EntControl::Rocket
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------

	------------------------------------------------------------------------------------------
	Fixed_Rocket_Spawn
	------------------------------------------------------------------------------------------
*/
public void Fixed_Rocket_Spawn(int client)
{
	float vAimPos[3];
	if (GetPlayerEye(client, vAimPos))
		Fixed_Base_Spawn(client, Fixed_Rocket_OnTrigger, vAimPos);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Rocket_Fire
	------------------------------------------------------------------------------------------
*/
public void Fixed_Rocket_Fire(int gun, int client, int target, float vGunPos[3], float vAimPos[3], float vAngle[3])
{
	Projectile(true, client, vGunPos, vAngle, "models/weapons/w_missile_launch.mdl", gRocketSpeed, gRocketDamage, "weapons/rpg/rocketfire1.wav", true);
}

public void Fixed_Rocket_OnTrigger(const char[] output, int caller, int activator, float delay)
{
	if(activator > 0 && activator <= MaxClients)
	{
		char tmp[32];
		GetEntPropString(caller, Prop_Data, "m_iName", tmp, sizeof(tmp));
		Fixed_Base_Think(StringToInt(tmp), activator, Fixed_Rocket_Fire);
	}
}
