#include "script_component.hpp"
/*
 * Author: nkenny
 * Aggressive Attacker script
 *
 * Arguments:
 * 0: Group performing action, either unit <OBJECT> or group <GROUP>
 * 1: Range of tracking, default is 500 meters <NUMBER>
 * 2: Delay of cycle, default 15 seconds <NUMBER>
 * 3: Area the AI Camps in, default [] <ARRAY>
 * 4: Center Position, if no position or Empty Array is given it uses the Group as Center and updates the position every Cycle, default [] <ARRAY>
 * 5: Only Players, default true <BOOL>
 *
 * Return Value:
 * none
 *
 * Example:
 * [bob, 500] spawn lambs_wp_fnc_taskRush;
 *
 * Public: No
*/
if (canSuspend) exitWith {
    [FUNC(taskRush), _this] call CBA_fnc_directCall;
};
// functions ---

private _fnc_rushOrders = {
    params ["_group", "_target"];

    private _distance = (leader _group) distance2D _target;
    // Helicopters -- supress it!
    if ((_distance < 200) && {vehicle _target isKindOf "Air"}) exitWith {
        {
            _x commandSuppressiveFire _target;
            true
        } count (units _group);
    };

    // Tank -- hide or ready AT
    if ((_distance < 80) && {(vehicle _target) isKindOf "Tank"}) exitWith {
        {
            if !(secondaryWeapon _x isEqualTo "") then {
                _x setUnitPos "MIDDLE";
                _x selectWeapon (secondaryWeapon _x);
            } else {
                _x setUnitPos "DOWN";
                _x commandSuppressiveFire _target;
            };
            true
        } count (units _group);
        _group enableGunLights "forceOff";
    };

    // Default -- run for it!
    {
        _x setUnitPos "UP";
        _x doMove (getPosATL _target);
        //_x forceSpeed ([_x, _target] call EFUNC(danger,assaultSpeed));
        true
    } count (units _group);
    _group enableGunLights "forceOn";
};
// functions end ---

// init
params ["_group", ["_radius", 500], ["_cycle", 15], ["_area", [], [[]]], ["_pos", [], [[]]], ["_onlyPlayers", true]];

// sort grp
if (!local _group) exitWith {false};
if (_group isEqualType objNull) then { _group = group _group; };

// orders
_group setSpeedMode "FULL";
//_group setFormation "DIAMOND";
_group enableAttack false;
{
    _x disableAI "AUTOCOMBAT";
    doStop _x;
    true
} count (units _group);

[{
    params ["_args","_handle"];
    _args params ["_group","_radius","_cycle","_area","_pos","_onlyPlayers","_fnc_rushOrders"];
    if !(local _group) exitWith {
        // remove handle
        _handle call CBA_fnc_removePerFrameHandler;

        // call on remote client
        [_group,_radius,_cycle,_area,_pos,_onlyPlayers] remoteExecCall [QFUNC(taskRush), leader _group];

        // debug
        if (EGVAR(danger,debug_functions)) then {format ["%1 taskRush: %2 moved to remote client", side _group, groupID _group] call EFUNC(danger,debugLog);};
    };
    if !(simulationEnabled (leader _group)) exitWith {false};

    // find
    private _target = [_group, _radius, _area, _pos, _onlyPlayers] call FUNC(findClosestTarget);

    // act
    if (!isNull _target) then  {
        [_group, _target] call _fnc_rushOrders;
        if (EGVAR(danger,debug_functions)) then { format ["%1 taskRush: %2 targets %3 at %4M", side _group, groupID _group, name _target, floor (leader _group distance2D _target)] call EFUNC(danger,debugLog); };
    };

    // end
    if ((units _group) findIf {_x call EFUNC(danger,isAlive)} == -1) exitWith {
        _handle call CBA_fnc_removePerFrameHandler;
    };
}, _cycle, [_group,_radius,_cycle,_area,_pos,_onlyPlayers,_fnc_rushOrders]] call CBA_fnc_addPerFrameHandler;
// end
true
