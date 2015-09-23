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

## How Projects Work
Use `File` -> `Open Folder` to open the root folder for a Nim project.  You should have a main project file, which is autodetected in the following order:

1. The `.nim` file with the same name as the `.nimble` file in the root folder.  For example, if you have a `something.nimble`, it will use `something.nim` if found.
2. `proj.nim`
3. The `.nim` file with the same name as the root folder.  For example, if the opened folder is `C:\something`, it will use `C:\something\something.nim` if found.

If you don't have a main project file, that's ok, but it won't use Nimsuggest, which means that autocomplete and jump-to-definition will be slower.  Also, it means that .nim.cfg settings will not propagate to included files.  And maybe other bad stuff.

## Autocomplete
Shows up after you press period.  Supports fuzzy matching by using fuzzaldrin.  Doc strings are truncated to fit into one line, mouseover to read the whole thing.

## Linting/Error Checking
By default, it will check files when you save them.  You can also use on-the-fly checking by changing the value in settings.  This will slow things down.

If there are a lot of errors/warnings when linting, Atom will slow down a lot.  This is because it creates every error/warning box instead of reusing them.  There is a pending issue for this in the Atom Linter package.

## Jump To Definition
Use Ctrl + Shift + Left Click to jump to the definition under the mouse cursor.

## Notes
Sometimes the nim compiler or nimsuggest crashes, and you'll see the error notification.  It's not a big deal, and nimsuggest will auto-restart.  You can view full error dumps in the developer tools console (`Ctrl`-`Alt`-`i` or `Ctrl`-`Shift`-`i`).  This can be annoying when doing on-the-fly error checking, so it is disabled by default.

## Credit

This originally started as a fork of https://github.com/zah/nim.atom/, but it has changed so much that I just created a new project.