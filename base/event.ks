@lazyglobal off.

local events is lexicon().
local sub_dlg is lexicon().

local update_dlg is {
    parameter id.
    
    local cl is events[id]:values.
    local code is "".
    local dlgs is list().
    for c in cl {
        if(code:length + c:length > 0.9*volume(0):freespace) {
            dlgs:add(make_dlg(code)).
            set code to "".
        }
        set code to code + char(10) + c.
    }
    dlgs:add(make_dlg(code)).
    set sub_dlg[id] to dlgs.
}.

local str_fn is instroot + "/run/events".
if(exists(str_fn)) {
    set events to readjson(str_fn).
    for e in events:keys {
        update_dlg(e).
    }
}

global event is {
    parameter id.
    if(not events:has(id)) {
        events:add(id, lexicon()).
        sub_dlg:add(id, list()).
        writejson(events, str_fn).
    }
    return lexicon(
        "sub", {
            parameter sid, code.
            events[id]:add(sid, code).
            update_dlg(id).
            writejson(events, str_fn).
        },
        "unsub", {
            parameter sid.
            events[id]:remove(sid).
            update_dlg(id).
            writejson(events, str_fn).
        },
        "trigger", {
            sub_dlg["id"]().
        }
    ).
}.