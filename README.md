# Nim for Atom

This is an Atom package for the Nim language that integrates with the Nim compiler and Nimsuggest.

## Features:
* Autocomplete
* Linting/Error Checking (on file save or on-the-fly)
* Jump-to-definition
* Syntax highlighting

## Installation
1. [Install Nim](http://nim-lang.org/download.html) or [build Nim from source](https://github.com/nim-lang/Nim)
2. [Install Nimble](https://github.com/nim-lang/nimble) (optional, needed for Nimsuggest)
3. [Install Nimsuggest](https://github.com/nim-lang/nimsuggest) (optional, highly recommended, improves autocomplete and jump-to-definition performance)
4. Install this package in Atom: `File` -> `Settings` (or `Edit` -> `Preferences`) -> `Install`, then search for `nim`

## Configuration
1. Go to the package settings in Atom: `File` -> `Settings` (or `Edit` -> `Preferences`) -> `Packages` -> `nim`
2. If `nim` and/or `nimsuggest` are not in your PATH, then set the paths for them.
3. (Optional) Set up the `Run Command` for your OS (at the bottom of the nim package settings, see instructions there).

## Important input
1. `Ctrl`-`Shift`-Click -> Jump to definition under cursor
2. `Ctrl`-`Shift`-B -> Build current file or the project it belongs to
2. `F5` -> Build and Run current file or the project it belongs to

## How Projects Work
Use `File` -> `Open Folder` to open the root folder for a Nim project.  You should have a main project `.nim` file, which is autodetected using the following steps:

1. Check for a `.nimble` file in the root folder.  If found, use the `bin` and (optionally) `srcDir` keys to determine the project file (only the first `bin` key will be used if multiple exist).
2. Find the first `.nim` file with a corresponding `.nimcfg`, `.nim.cfg`, or `.nims` file in the root folder.

If you have a main project, it will speed up autocompletions and jump-to-definition.  *However, keep in mind that a file must be included or imported either directly or indirectly by the main project file to be error checked.*

## Autocomplete
Now works for all symbols, not just after you press dot.  Supports fuzzy matching by using fuzzaldrin.  Doc strings are truncated to fit into one line, mouseover to read the whole thing.  Can be configured in settings to be on all the time, only after you press dot, or never.

## Linting/Error Checking
By default, it will check files when you save them.  You can also use on-the-fly checking by changing the value in settings.  This will slow things down.

Note that if you have a main project file, error checking only occurs for files directly or indirectly imported or included by the main project file.  So, if you don't see any errors and they should be there, be sure the file has been imported/included.

If there are a lot of errors/warnings when linting, Atom will slow down a lot.  This is because it creates every error/warning box instead of reusing them.  There is a pending issue for this in the Atom Linter package.

## Jump To Definition
Use Ctrl + Shift + Left Click to jump to the definition under the mouse cursor.

## Build and Run
Use `Ctrl`-`Shift`-B to build, which compiles the current file or its project.  If there are errors, they will show up normally.  These may be different that the linting errors (and probably are more accurate).  The status bar in the lower right will show if it was successful or failed.

Use `F5` to build and run the current file or its project.  If the build fails, it will not try to run anything.  Be sure you set up the `Run Command` first!

These commands can work on individual files or projects.  If you are editing a file that's not in a project, these commands will just build/run that file.  If it is part of a project, these commands will build/run the project root file.

## Notes
Sometimes the nim compiler or nimsuggest crashes, and you'll see the error notification.  It's not a big deal, and nimsuggest will auto-restart.  You can view full error dumps in the developer tools console (`Ctrl`-`Alt`-`i` or `Ctrl`-`Shift`-`i`).  This can be annoying when doing on-the-fly error checking, so it is disabled by default.

## Development
If you want to hack on this package, just:

1. Be sure you have node.js installed (I think Atom installs this, not sure)
2. Clone this repo
3. Be sure this package is not installed in Atom (uninstall if necessary)
4. `apm install` in repo root
5. `apm link` in repo root

Now you can edit the source directly in your repo clone and it will update any time you restart Atom.

## Credit

This originally started as a fork of https://github.com/zah/nim.atom/, but it has changed so much that I just created a new project.