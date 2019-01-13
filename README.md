# KMOS
The Kerbal Modular Operating System - a framework for Kerboscript, in Kerboscript!
**It is still very WIP, usage not yet recommended!**

## Core Features
- Cooperative Multitasking: have multiple scripts repeating - even multiple instances of the same script are possible!
- State Persistence: KMOS automaticly loads the last known state, especially the constellation of tasks, on reboot
- Setup Automation: Includes dependency resolution!

## Installation
- Clone this repository into a folder insider your kOS Archive, e.g. say `kmos`.
- From a kOS terminal, run `$SRCROOT/configure`, i.e. `0:/kmos/configure`.

## Setup Automation
- Set `kmos` as the core boot script
- The Setup-Automation parses it's arguments from the core tag:
  - If it starts with `@`, everything between that and the first `:` is used as the `instroot`, i.e. the root directory to set up in.
  - Everything from the instroot's `:`, or the start if the tag doesn't start with `@` to the next `:`, or end of tag, is used as the `setupid`, i.e. what to set up
  - If the setupid starts with `!`, that is removed and `instdbg` is set to true to instruct setting up the debug version
  - If there is nothing after the setupid, the tag is left as-is. Otherwise, everything up to and including the setupid's `:` is removed.
- KMOS runs a script `$SRCROOT/setup/$setupid` to instruct the setup. It has access to several globals:
  - the variables `instroot`, `setupid` and `instdbg` as mentioned above
  - the variable `srcroot` corresponding to the root folder of your KMOS archive installation
  - the function `install(<component>)` to install a KMOS Component
  - the function `init(<scriptname>)` to set the initialization script to the script found at `$SRCROOT/init/$scriptname`. This must be called at least once.
  - the function `instfile(<src>,<dest>)` to install a specific file or folder. Both `$src` and `$dest` must be complete paths. This detects .ks scripts and compiles them if appropriate.
- If `instdbg` is false, every script installed is first compiled instead. If the compiled version is actually smaller, that is used. Otherwise, the script is used as-is. If `instdbg` is true, all scripts are installed as-is.
- a KMOS Component is either a Module, a Cmd or a Library
- the initialization script is run when KMOS starts and finds no persisted state, i.e. after the setup, and if you reboot KMOS (different from a kOS reboot, across which state is persisted)
  
## Modules
A module is a collection of scripts to manage an ongoing task. It is defined by a folder `$SRCROOT/mod/$modulename` and may include the following scripts:
 - `exec`: this is run when a new task with this module is started, but not when it is restored upon kOS reboot
 - `run`: this is run both when a new task with this module is started and when it is restored upon kOS reboot
 - `stop`: this is run when a task with this module is stopped
 - `loop`: this is run when the task loops

All scripts are passed two parameters. The first is the persistent task data, a lexicon with the following entries by the scheduler:
 - `pid`: the task's index
 - `mod`: the module name
 - `args`: the list of additional arguments passed to `kmos["start"]`
 - `state`: the current state of the task, primarily for internal use
 - `interval`: the interval at which `loop` is called
 - `last`: the timestamp `loop` was last called

The second parameter is another lexicon with non-persistent task data. The scheduler does not use this, but module scripts should use it to pass non-serializable data acrosse calls. Keep in mind that this is not persisted across kOS reboots - use a `run` script to reconstruct it from persistent data!

A module directory may also contain file called `dep`, specifying dependencies with one entry per line.

## Cmd
A cmd is a simple script which is run blocking. It is defined by being a script `$SRCROOT/cmd/$cmdname` and may be accompanied by a file `$SRCROOT/cmd/$cmdname.dep` specifying dependencies with one entry per line.

## Library
A library is a script which is not used directly, but only as a dependency of other scripts. It is defined by being a script `$SRCROOT/lib/$libname` and may be accompanied by a file `$SRCROOT/$libname.dep` specifying dependencies with one entry per line.

## Scheduler
The task scheduler's interface is contained in a global lexicon `kmos`. It has the following entries:
- `verbose`: bool that defines if the scheduler prints output.
- `start(<mod>, <args>)`: starts a task of `$mod` with the additional arguments `$args`.
- `stop(<pid>)`: stops the task identified by `$pid`.
- `cmd(<cmd>, <args>)`: runs `$cmd` with the additional arguments `$args`. The arguments are expected to be a list, which is unrolled into the corresponding amount of parameters.
- `exec(<id>, <args>)`: determines whether `$id` is a Cmd or Module and does `start` or `cmd` appropriatly.
- `exit()`: stops all tasks, resulting in KMOS exiting to the kOS Shell.
- `reboot()`: clears the persistent state and reboots kOS, resulting in KMOS reinitializing.
- `wait(<waiter>,<waitee>)`: makes the task `$waiter` wait until `$waitee` stops. A single task cannot wait for multiple other tasks - the first wait to be completed will re-enable the task.
- `unwait(<waiter>,<waitee>,<rstate>)`: makes the task `$waiter` no longer wait for `$waitee` and restores it's state to `$rstate`.

## Events
The global function `event(<id>)` returns the interface to the event identified by `$id`. An event is created by the first call to `event` with it's id. The interface is a lexicon with the following entries:
- `sub(<sid>,<code>)`: when the event is triggered, execute `$code`. `$sid` identifies the code for removal via `unsub`.
- `unsub(<sid>)`: remove the code identified by `$sid` from the event.
- `trigger`: execute all code currently subscribed to the event.

## Coreutils
The following global functions are additionally provided by KMOS:
- `getTmpFn()`: returns the next temporary filename. It is an absolute path to a file guaranteed to not yet exist. Temporary files should be deleted when no longer used, if possible. All temporary files are cleared on kOS reboot!
- `var2code(<x>)`: returns a kerboscript representation of `$x`. As this falls back to temporary json files for unknown types, it *does not work acroess kOS reboots!*
- `make_dlg(<code>)`: creates a delegate for execution of `$code`.
- `eval(<expr>)`: returns the result of executing `$expr`. It must be a single kerboscript expression, not one or multiple statements!
- `exec(<code>)`: shortcut for `return make_dlg($code)().`
