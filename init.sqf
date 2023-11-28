#include "celo_alarm_guard_system.sqf";

// You need to use array of minimal one parameter with array of units in alarm zone. Second array parameter is optional and is for unique name of alarm zone.
// Third parameter is optional code called after alarm is initialized and four parameter is another optional custom code for changing behaviour when alarm is called.
// Both of them have four parameters - string with name of alarm ("enemy"/"body"/"fired"), array of guard units, unit called alarm and target (enemy or body).
// returned is logic object. You can change some values on them with setVariable if you need change default coeficients.

// FIRST EXAMPLE - all default
[[x_1,x_2,x_3,x_4,x_5,x_6]] call celo_fnc_init_alarm_guard_system;

// SECOND EXAMPLE - using name for zone
[[e_1,e_2,e_3,e_4,e_5],"base_1"] call celo_fnc_init_alarm_guard_system;

// THIRD EXAMPLE - default with using name and "after alarm" function
[[f_1,f_2,f_3,f_4],"base_2",{
	alarm_base2 = true;	
}] call celo_fnc_init_alarm_guard_system;

// FOURTH EXAMPLE - using name, "after alarm" and custom "on alarm" function 
celo_base3_alarm = {
	alarm_base3 = true; 
};
celo_base3_reaction = {
	params ["_alarm_type","_guards","_caller",["_target",objNull]];

	{
		private _grp = group _x;
		for "_j" from count waypoints _grp - 1 to 0 step -1 do { deleteWaypoint [_grp, _j]; };

		private _wp = _grp addWaypoint getPos _x;
		_wp setWaypointType "GUARD";
		_wp setWaypointSpeed "FULL";
		_wp setWaypointBehaviour "COMBAT";
		_wp setWaypointCombatMode "RED";
		_wp setUnitPos "UP";

	} foreach _guards;

};
[[g_1,g_2,g_3],"base_3",celo_base3_alarm,celo_base3_reaction] call celo_fnc_init_alarm_guard_system;

// FIFTH EXAMPLE - 
private _fifth_base_logic = [[x_1,x_2,x_3,x_4,x_5,x_6]] call celo_fnc_init_alarm_guard_system;
_fifth_base_logic setVariable ["celo_ags_knowsAboutContactLimit",3];
_fifth_base_logic setVariable ["celo_ags_distanceSilencerLimit",50];
// or you can additionaly change "on alarm" or "after alarm" function 
_fifth_base_logic setVariable ["celo_ags_onAlarmFnc",{
  systemChat "ALARM!!!!";
}];
