# Alarm Guard System for Arma 3

Whole system is using one function **celo_fnc_init_alarm_guard_system**.
You can create default waypoints for all units/guards in zone. Alarm is initialized when one of guards is in contact with enemy or when he hears a shot (without silencer) or he sees dead body (only from guards).

For init you need to use array of minimal one parameter with array of units in alarm zone. Second array parameter is optional and is for unique name of alarm zone (created random). 
Third parameter is optional code called after alarm is initialized and four parameter is another optional custom code for changing behaviour when alarm is called.
Both of them have four parameters - string with name of alarm ("enemy"/"body"/"fired"), array of guard units, unit called alarm and target (enemy or body).
Returned is logic object. You can change some values on them with setVariable if you need change default coeficients.

### FIRST EXAMPLE - all default
```sqf
[[x_1,x_2,x_3,x_4,x_5,x_6]] call celo_fnc_init_alarm_guard_system;
```

### SECOND EXAMPLE - using name for zone
```sqf
[[e_1,e_2,e_3,e_4,e_5],"base_1"] call celo_fnc_init_alarm_guard_system;
```

### THIRD EXAMPLE - default with using name and "after alarm" function
```sqf
celo_test2 = {
	alarm_base2 = true;	
};
[[f_1,f_2,f_3,f_4],"base_2",celo_test2] call celo_fnc_init_alarm_guard_system;
```

### FOURTH EXAMPLE - using name, "after alarm" and custom "on alarm" function 
```sqf
celo_reaction3 = {
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
[[g_1,g_2,g_3],"base_3",{ alarm_base3 = true; },celo_reaction3] call celo_fnc_init_alarm_guard_system;
```

### FIFTH EXAMPLE - changing variables after init
```sqf
private _fifth_base_logic = [[e_1,e_2,e_3,e_4,e_5]] call celo_fnc_init_alarm_guard_system;
_fifth_base_logic setVariable ["celo_ags_knowsAboutContactLimit",3];
_fifth_base_logic setVariable ["celo_ags_distanceSilencerLimit",70];
// or you can additionaly change "on alarm" or "after alarm" function 
celo_reaction_on_alarm = {
	systemChat "ALARM!!!!";	
};
_fifth_base_logic setVariable ["celo_ags_onAlarmFncName",celo_reaction_on_alarm];
```
