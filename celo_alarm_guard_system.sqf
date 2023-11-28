celo_fnc_init_alarm_guard_system = {
	params [["_guards",[]],["_base_name",""],["_afterAlarmFnc",objNull],["_onAlarmFnc",objNull]];

	_logicCenter = createCenter sideLogic;
	_logicGroup = createGroup _logicCenter;
	_base_logic = _logicGroup createUnit ["Logic", [0,0,0], [], 0, "NONE"];

	if (_base_name == "") then {
		private _system_time = systemTime;
		_base_name = "celo_ags_base_"+(str floor random [1000,3000,5000])+"_"+(str (_system_time#4))+(str (_system_time#5))+(str (_system_time#6));
	};
	missionNamespace setVariable [_base_name,_base_logic];	
	
	_base_logic setVariable ["celo_ags_base_name",_base_name];
	_base_logic setVariable ["celo_ags_guards",_guards];
	_base_logic setVariable ["celo_ags_afterAlarmFnc",_afterAlarmFnc];
	_base_logic setVariable ["celo_ags_onAlarmFnc",_onAlarmFnc];
	// default config
	_base_logic setVariable ["celo_ags_knowsAboutContactLimit",2.5];
	_base_logic setVariable ["celo_ags_knowsAboutBodyLimit",3];
	_base_logic setVariable ["celo_ags_distanceSilencerLimit",10];
	_base_logic setVariable ["celo_ags_bodyObjectName","I_TargetSoldier"];
	// internal
	_base_logic setVariable ["celo_ags_bodies",[]];

	{

		_x setVariable ["celo_ags_base_logic",_base_logic];

		(group _x) addEventHandler ["knowsAboutChanged", {
			scopeName "handler";
			params ["_group","_targetUnit","_newKnowsAbout","_oldKnowsAbout"];

			private _bodies = _logic getVariable "celo_ags_bodies";
			private _limit_body = _logic getVariable "celo_ags_knowsAboutBodyLimit";

			if (_targetUnit in _bodies && _newKnowsAbout > _limit_body) then {
				[_targetUnit,_main_unit] spawn {
					params ["_targetUnit","_guard"];

					_guard setBehaviour (_guard getVariable ["celo_ags_wp_behaviour","DANGER"]);					
					(group _guard) removeAllEventHandlers "knowsAboutChanged";
					sleep 3;
					if (alive _guard) then {
						private _base_name = (_guard getVariable "celo_ags_base_logic") getVariable "celo_ags_base_name";
						[missionNamespace, _base_name+"_alarm", ["body",_guard,_targetUnit]] call BIS_fnc_callScriptedEventHandler;
					};
				};		
				false breakOut "handler";
			};

			private _type = (_targetUnit call BIS_fnc_objectType)#0;
			if (!(_type in ["Soldier","Vehicle"])) exitWith {};
			if ([side _targetUnit,side _group] call BIS_fnc_sideIsFriendly) exitWith {};

			private _main_unit = (units _group)#0;

			private _logic = (_main_unit getVariable "celo_ags_base_logic");
			private _limit_contact = _logic getVariable "celo_ags_knowsAboutContactLimit";

			if (_newKnowsAbout > _limit_contact) then {

				[_targetUnit,_main_unit,_logic] spawn {
					params ["_targetUnit","_guard","_logic"];
					_guard setBehaviour (_guard getVariable ["celo_ags_wp_behaviour","DANGER"]);
					(group _guard) removeAllEventHandlers "knowsAboutChanged";
					sleep 3;
					if (alive _guard) then {
						private _base_name = _logic getVariable "celo_ags_base_name";
						[missionNamespace, _base_name+"_alarm", ["enemy",_guard,_targetUnit]] call BIS_fnc_callScriptedEventHandler;
					};
				};

			};

		}];

		_x addEventHandler ["Killed",{
			params ["_unit", "_killer"];			
			_logic = _unit getVariable "celo_ags_base_logic";
			_bodyObjectName = _logic getVariable "celo_ags_bodyObjectName";
			_bodies = _logic getVariable "celo_ags_bodies";
			_body = _bodyObjectName createVehicle getPos _unit;
			_bodies pushBack _body;
			_logic setVariable ["bodies",_bodies];
			_unit removeAllEventHandlers "Killed";
		}];		

		_x addEventHandler ["FiredNear",{
			params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];

			if (_weapon == "Throw" || !alive _unit) exitWith {};

			_logic = _unit getVariable "celo_ags_base_logic";

			private _distance_limit = _logic getVariable "celo_ags_distanceSilencerLimit";

			if ((_firer weaponAccessories _weapon)#0 !="" && (_unit distance _firer > _distance_limit) ) exitWith {}; // has silencer and is far

			[_unit] spawn {
					params ["_guard"];
					_guard setBehaviour (_guard getVariable ["celo_ags_wp_behaviour","COMBAT"]);	

					sleep 2;
					if (alive _guard) then {
						private _base_name = (_guard getVariable "celo_ags_base_logic") getVariable "celo_ags_base_name";
						[missionNamespace, _base_name+"_alarm", ["fired",_guard]] call BIS_fnc_callScriptedEventHandler;
					};
			};
		}];

	} foreach _guards;

	[missionNamespace, _base_name+"_alarm", { 

		params ["_alarm_type","_guard",["_enemy",objNull]];
		private _base_logic = _guard getVariable "celo_ags_base_logic";
		private _guards = _base_logic getVariable "celo_ags_guards";
		private _onAlarmFnc = _base_logic getVariable "celo_ags_onAlarmFnc";

		if (typeName _onAlarmFnc == "CODE") then {
			[_alarm_type,_guards,_guard,_enemy] call _onAlarmFnc;

		} else {

			// default behaviour
			{
				private _grp = group _x;
				for "_j" from count waypoints _grp - 1 to 0 step -1 do { deleteWaypoint [_grp, _j]; };

				private _wp = _grp addWaypoint [(_x getVariable ["celo_ags_wp_pos",getPos (if (isNull _enemy) then { _enemy } else { _x })]),count waypoints _grp];
				_wp setWaypointType (_x getVariable ["celo_ags_wp_type","MOVE"]);
				_wp setWaypointSpeed (_x getVariable ["celo_ags_wp_speed","FULL"]);
				_wp setWaypointBehaviour (_x getVariable ["celo_ags_wp_behaviour","COMBAT"]);
				_wp setWaypointCombatMode (_x getVariable ["celo_ags_wp_combat_mode","RED"]);

				private _unit_pos = _x getVariable ["celo_ags_wp_unit_pos","MIDDLE"];
				if (_unit_pos in ["DOWN","UP","MIDDLE","AUTO"]) then {
					{_x setUnitPos _unit_pos} foreach units _grp;
				};
			} foreach _guards;
		};

		{
			_x removeAllEventHandlers "FiredNear";
			_x removeAllEventHandlers "Killed";
			(group _x) removeAllEventHandlers "knowsAboutChanged";
		} foreach _guards;

		[missionNamespace, _base_name+"_alarm"] call BIS_fnc_removeAllScriptedEventHandlers;

		private _afterAlarmFnc = _base_logic getVariable "celo_ags_afterAlarmFnc";

		if (typeName _afterAlarmFnc == "CODE") then {
			[_alarm_type,_guards,_guard,_enemy] call _afterAlarmFnc;
		};


	}] call BIS_fnc_addScriptedEventHandler;

	_base_logic
	
};
