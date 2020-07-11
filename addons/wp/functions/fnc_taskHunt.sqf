#include "script_component.hpp"
/*
 * Author: nkenny
 * Tracker script
 *        Slower more deliberate tracking and attacking script
 *        Spawns flares to coordinate
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
 * [bob, 500] spawn lambs_wp_fnc_taskHunt;
 *
 * Public: Yes
*/
if (canSuspend) exitWith {
    [FUNC(taskHunt), _this] call CBA_fnc_directCall;
};
// 1. FIND TRACKER
params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_radius", TASK_HUNT_SIZE, [0]],
    ["_cycle", TASK_HUNT_CYCLETIME, [0]],
    ["_area", [], [[]]],
    ["_pos", [], [[]]],
    ["_onlyPlayers", TASK_HUNT_PLAYERSONLY, [false]]
];

// sort grp
if (!local _group) exitWith {false};
if (_group isEqualType objNull) then { _group = group _group; };

// 2. SET GROUP BEHAVIOR
_group setbehaviour "SAFE";
_group setSpeedMode "LIMITED";
_group enableAttack false;

// FUNCTIONS -------------------------------------------------------------

// FLARE SCRIPT
private _fnc_flare = {
    params ["_leader"];
    private _shootflare = "F_20mm_Red" createvehicle (_leader ModelToWorld [0, 0, 200]);
    _shootflare setVelocity [0, 0, -10];
};

// 3. DO THE HUNT SCRIPT! ---------------------------------------------------

[{
    params ["_args","_handle"];
    _args params ["_group","_radius","_cycle","_area","_pos","_onlyPlayers","_fnc_flare"];
    if !(local _group) exitWith {
        // remove handle
        _handle call CBA_fnc_removePerFrameHandler;

        // call on remote client
        [_group,_radius,_cycle,_area,_pos,_onlyPlayers] remoteExecCall [QFUNC(taskHunt), leader _group];

        // debug
        if (EGVAR(main,debug_functions)) then {format ["%1 taskHunt: %2 moved to remote client", side _group, groupID _group] call EFUNC(main,debugLog);};
    };
    if !(simulationEnabled (leader _group)) exitWith {false};

    // find
    private _target = [_group, _radius, _area, _pos, _onlyPlayers] call FUNC(findClosestTarget);

    // settings
    private _combat = (behaviour (leader _group)) isEqualTo "COMBAT";
    private _onFoot = (isNull objectParent (leader _group));

    // give orders
    if (!isNull _target) then {
        _group move (_target getPos [random (linearConversion [50, 1000, (leader _group) distance _target, 25, 300, true]), random 360]);
        _group setFormDir ((leader _group) getDir _target);
        _group setSpeedMode "NORMAL";
        _group enableGunLights "forceOn";
        _group enableIRLasers true;

        // debug
        if (EGVAR(main,debug_functions)) then {format ["%1 taskHunt: %2 targets %3 at %4M", side _group, groupID _group, name _target, floor (leader _group distance _target)] call EFUNC(main,debugLog);};

        // flare
        if (!_combat && {_onFoot} && {RND(0.8)}) then { [leader _group] call _fnc_flare; };

        // suppress nearby buildings
        if (_combat && {(nearestBuilding _target distance2d _target < 25)}) then {
            {
                [_x, getPosASL _target] call EFUNC(danger,suppress);
                true
            } count units _group;
        };
    };
    if ((units _group) findIf {_x call EFUNC(main,isAlive)} == -1) exitWith {
        _handle call CBA_fnc_removePerFrameHandler;
    };
}, _cycle, [_group,_radius,_cycle,_area,_pos,_onlyPlayers,_fnc_flare]] call CBA_fnc_addPerFrameHandler;

// end
true
