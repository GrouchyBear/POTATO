#include "script_component.hpp"

if (isServer) then {
    [QGVAR(registerObjects), LINKFUNC(registerObjects)] call CBA_fnc_addEventHandler;
    [QGVAR(addActionToObject_server), {
        params ["_side", "_object"];
        TRACE_2("addActionToObject_server",_side,_object);
        private _jipID = [QGVAR(addActionToObject), _this] call CBA_fnc_globalEventJIP;
        [_jipID, _object] call CBA_fnc_removeGlobalEventJIP; // idealy this function should be called on the server
    }] call CBA_fnc_addEventHandler;

    // ** Potato specific Events **
    // Can only use fority durring safe start, might make this a setting if people want to build mid-mission
    ["potato_safeStartOn", {
        missionNamespace setVariable [QGVAR(fortifyAllowed), true, true];
    }] call CBA_fnc_addEventHandler;
    ["potato_safeStartOff", {
        missionNamespace setVariable [QGVAR(fortifyAllowed), false, true];
    }] call CBA_fnc_addEventHandler;
};

if (!hasInterface) exitWith {};

GVAR(isPlacing) = PLACE_CANCEL;
["ace_interactMenuOpened", {GVAR(isPlacing) = PLACE_CANCEL;}] call CBA_fnc_addEventHandler;

GVAR(objectRotationX) = 0;
GVAR(objectRotationY) = 0;
GVAR(objectRotationZ) = 0;

// Register CBA Chat command for admins (Example: #ace-fortify west small 200)
["ace-fortify", LINKFUNC(handleChatCommand), "admin"] call CBA_fnc_registerChatCommand;

[QGVAR(sideBudgetHint), {
    params ["_side"];
    if (_side isEqualTo side group ace_player) then {
        private _budget = [_side] call FUNC(getBudget);
        TRACE_2("sideBudgetHint",_side,_budget);
        [format ["%1 $%2", localize LSTRING(Budget), _budget]] call ACEFUNC(common,displayTextStructured);
    };
}] call CBA_fnc_addEventHandler;

[QGVAR(addActionToObject), {
    params ["_side", "_object"];
    TRACE_2("addActionToObject EH",_side,_object);
    if (isNull _object) exitWith {};
    if (_side isEqualTo side group ace_player) then {
        private _budget = [_side] call FUNC(getBudget);
        private _cost = [_side, typeOf _object] call FUNC(getCost);
        private _text = [format ["Remove Object +$%1", _cost], "Remove Object"] select (_budget == -1);

        // Remove object action
        private _removeAction = [
            QGVAR(removeObject),
            _text,
            "",
            {
                params ["_target", "", "_params"];
                TRACE_2("deleting placed object",_target,_params);
                deleteVehicle _target;
                _params call FUNC(updateBudget);
            },
            {missionNamespace getVariable [QGVAR(fortifyAllowed), true]},
            {},
            [_side, _cost],
            {[0, 0, 0]},
            5
        ] call ACEFUNC(interact_menu,createAction);

        [_object, 0, [], _removeAction] call ACEFUNC(interact_menu,addActionToObject);
    };
}] call CBA_fnc_addEventHandler;
