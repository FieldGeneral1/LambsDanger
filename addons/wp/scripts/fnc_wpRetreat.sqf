#include "script_component.hpp"
/*
 * Author: nkenny
 * Creates a Forced retreat WP on target location
 *
 * Arguments:
 * 0: Unit
 * 1: Unit position
 *
 * Return Value:
 * none
 *
*/

// init
params ["_group", "_pos"];


// prepare troops ~ pre-set for raid!
[leader _group, 99, 170] call EFUNC(danger,leaderModeUpdate);

// group
_group setVariable [QEGVAR(danger,disableGroupAI), true];
_group setSpeedMode "FULL";

// individual units
{
    _x enableAI "MOVE";
    _x enableAI "PATH";
} foreach units _group;

// low level move order
_group move _pos;

// execute script
[_group, _pos, true, 25, 3, true] call FUNC(taskAssault);

waitUntil {sleep 1; _group getVariable [QGVAR(taskAssaultMembers), []] isEqualTo []};
// end
true
