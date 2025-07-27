# TMI-AngelScript
A place for all my plugins

## AutoStartTrick.as
This plugin is a bruteforcing tool that automatically detects the type of start on a map (e.g., booster, downhill) and then optimizes the initial inputs to achieve the maximum possible speed. It works by repeatedly running a simulation with slightly modified inputs and keeping the best results.

## BfShortcuts.as
This plugin provides a set of shortcuts and a user interface to speed up the configuration of bruteforcing tasks. It allows you to quickly set the start and end times for bruteforce evaluation and input modification to the current race time. It also includes a feature to automatically suggest a time frame for "point" bruteforcing by identifying the closest the car gets to a target position.

## BugHelper.as
This plugin helps with reproducing bugs by managing the game's random seed. It sets a new random seed when a replay is loaded and prints the seed at the start and end of simulations, ensuring that physics-based bugs can be reproduced consistently.

## CarLocationBf.as
This bruteforcing plugin allows you to define a target car position and orientation (yaw, pitch, and roll). It then attempts to find inputs that bring the car as close as possible to this target state. The plugin provides a visual representation of the target car's position and orientation in the world, and allows you to adjust a "K factor" to control the trade-off between positional and rotational accuracy.

## DefaultActions.as
This plugin allows you to automate actions at the start of each run. It can be configured to automatically fast-forward to a specific time in the run or load a saved state, which is useful for practicing specific sections of a track repeatedly.

## FrameAdvance.as
This is a fundamental tool-assisted speedrunning plugin that allows you to advance the game one frame at a time. This can be done via a UI button or a console command, enabling precise input timing and physics analysis.

## InputsLoa.as
This plugin allows you to load a sequence of inputs from a file and play them back. As soon as you do any manual input, the plugin hands control back to you. This is useful for taking over driving control whenever you want, on the fly.

## SinglePointBf.as
### This plugin is heavily inspired and copied from TrackMania Interface's own distance/speed target. However, it improves upon it by adding extra conditions and fixing a few bugs.
This bruteforcing plugin optimizes for two objectives: minimizing the distance to a target point and maximizing speed. A "ratio" slider allows you to control the trade-off between these two goals, making it useful for finding the fastest path to a specific point or optimizing a line for maximum exit speed.

## SkycrafterBf.as
This is a bruteforcing plugin with two main modes: "Distance to Target" and "Uberbug". The "Distance to Target" mode finds the fastest way to a checkpoint or finish line by calculating the minimum distance between the car and the waypoint's "trigger" (the part that tells the game you actually got the waypoint) polyhedron. The "Uberbug" mode is a mode made specifically to bruteforce uberbugs, including visualization of many results at once in the race.

## TriggerPlacing.as
This plugin provides an easy way to create 3D triggers. You define two opposite corners of a cuboid trigger using your camera position, and the plugin creates the trigger.