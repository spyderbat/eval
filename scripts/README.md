# Eval Management Scripts

## Structure

Each script (install, access, update, and uninstall) first sources the prelude. This runs startup checks and loads configuration values. Then, they run their tasks. At the end of any script where configuration values are changed, the `saveconfig` function is run to save values to a file.

In general, only shell native or very common commands are assumed. Helm and kubectl are checked for in the prelude.

### Configuration Values

The values entered on the command line when first installing the eval systems are saved to `scripts/.config`. This file is a bash file containing variable assignments, and is loaded at startup by each script. These configuration values should be checked or confirmed before continuing to make sure the details are still correct.
