# BfV2 Bruteforce Plugin Documentation

This document explains how to create a bruteforce evaluation target (optimization goal) for the BfV2 plugin.

## Overview

The BfV2 plugin works by:
1. Loading a base run (from validated replay)
2. Running the simulation with the base inputs (Initial phase)
3. Mutating inputs and re-running to find improvements (Search phase)
4. Repeating until stopped or target decides to stop.

## Core Concepts

### BFPhase (Bruteforce Phase)

- **`BFPhase::Initial`** - The first run with the original/best inputs. Used to establish a baseline. Also used to measure the new baseline upon improvement.
- **`BFPhase::Search`** - Subsequent runs with mutated inputs, searching for improvements.

### BFEvaluationDecision

The decision your evaluation callback returns:

| Decision | Description |
|----------|-------------|
| `DoNothing` | Continue simulation, no decision yet |
| `Accept` | This run is better than the current best - save it |
| `Reject` | This run is worse - discard and try again |
| `Stop` | Stop the entire bruteforce process |

### BFEvaluationInfo

Information passed to your callback:

```angelscript
class BFEvaluationInfo {
    int Iterations;      // Number of iterations completed
    BFPhase Phase;       // Current phase (Initial or Search)
    bool Rewinded;       // Whether the target manually rewound and the bf logic shouldn't do its own default rewind.
}
```

### BFEvaluationResponse

What your callback returns:

```angelscript
class BFEvaluationResponse {
    BFEvaluationDecision Decision;     // Your decision
    string ResultFileStartContent;      // Comment to add at top of saved file. Will be the displayed information upon restarts.
}
```

## Simulation Callbacks

### OnSimulationBegin

Called once when the simulation starts. Use this to:
- Initialize variables
- Read settings from UI variables
- Reset state from previous runs

```angelscript
void OnSimulationBegin(SimulationManager @simManager)
{
    // Read settings
    myVariable = int(GetVariableDouble("my_setting"));
    
    // Reset state
    bestValue = -1;
    isFirstRun = true;
}
```

### OnSimulationStep (OnRunStep)

Called every simulation tick (10ms). This is where you evaluate the current state and make decisions.

The main evaluation callback signature:
```angelscript
BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
```

### OnSimulationEnd

Called when the simulation ends. Useful for cleanup or final logging.

## Creating a Bruteforce Target

### 1. Create a Namespace

Each target lives in its own namespace:

```angelscript
namespace MyTargetBf
{
    // Variables, functions, and Main() go here
}
```

### 2. Define State Variables

```angelscript
namespace MyTargetBf
{
    int bestValue = -1;      // Track the best result found
    bool isFirstRun = true;  // Track if this is the initial phase
    int mySetting = 0;       // Settings from UI
}
```

### 3. Implement RenderEvalSettings (Optional)

UI for target-specific settings:

```angelscript
void RenderEvalSettings()
{
    UI::PushItemWidth(200);
    UI::InputIntVar("My Setting", "mytarget_setting");
    UI::PopItemWidth();
    toolTip(300, {"Description of what this setting does."});
}
```

### 4. Implement OnSimulationBegin

Initialize state when simulation starts:

```angelscript
void OnSimulationBegin(SimulationManager @simManager)
{
    // Read settings from UI variables
    mySetting = int(GetVariableDouble("mytarget_setting"));
    
    // Reset tracking variables
    bestValue = -1;
    isFirstRun = true;
}
```

### 5. Implement OnEvaluate

The core evaluation logic:

```angelscript
BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
{
    auto resp = BFEvaluationResponse();
    resp.Decision = BFEvaluationDecision::DoNothing;
    
    int currentValue = /* calculate current value */;
    bool conditionsMet = GlobalConditionsMet(simManager);
    
    if (info.Phase == BFPhase::Initial)
    {
        // First run - establish baseline
        if (conditionsMet && currentValue > bestValue)
        {
            bestValue = currentValue;
            resp.Decision = BFEvaluationDecision::Accept;
            
            if (isFirstRun)
            {
                isFirstRun = false;
                print("Base run value: " + bestValue);
                resp.ResultFileStartContent = "# Base run value: " + bestValue;
            }
        }
    }
    else // BFPhase::Search
    {
        // Subsequent runs - look for improvements
        if (conditionsMet && currentValue > bestValue)
        {
            bestValue = currentValue;
            resp.Decision = BFEvaluationDecision::Accept;
            print("New best: " + bestValue);
            resp.ResultFileStartContent = "# Best value: " + bestValue;
        }
        // Note: Rejection happens automatically if you don't Accept
        // You can explicitly Reject to stop the current run early
    }
    
    return resp;
}
```

### 6. Implement Main

Register your target:

```angelscript
void Main()
{
    // Register any settings variables
    RegisterVariable("mytarget_setting", 0);
    
    // Register the bruteforce evaluation target
    auto eval = RegisterBruteforceEval(
        "mytarget",           // Unique identifier
        "My Target",          // Display name in dropdown
        OnEvaluate,           // Evaluation callback
        RenderEvalSettings    // Settings UI callback (optional, can be null)
    );
    
    // Attach lifecycle callbacks
    @eval.onSimBegin = @OnSimulationBegin;
    // @eval.onSimEnd = @OnSimulationEnd;     // Optional
    // @eval.onRunStep = @OnRunStep;          // Optional
    // @eval.onRender = @OnRender;            // Optional - for visual overlays
}
```

### 7. Register in Plugin Main

Add your target's `Main()` call to the plugin's `Main()`:

```angelscript
void Main()
{
    // ... existing registrations ...
    MyTargetBf::Main();
}
```

## Global Conditions

Always use `GlobalConditionsMet(simManager)` to check if global conditions are satisfied:
- Minimum speed
- Minimum checkpoints
- Trigger zones
- Custom condition scripts

```angelscript
bool conditionsMet = GlobalConditionsMet(simManager);
if (conditionsMet && /* your specific conditions */)
{
    resp.Decision = BFEvaluationDecision::Accept;
}
```

## Complete Example: Simple Time Target

```angelscript
namespace TimeBf
{
    int minTime = 0;
    int bestTime = -1;
    bool isFirstRun = false;

    void RenderEvalSettings()
    {
        UI::PushItemWidth(200);
        UI::Text("Minimum Time");
        UI::SameLine();
        UI::InputTimeVar("##timebf_min_time", "timebf_min_time");
        UI::PopItemWidth();
    }

    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;

        bool conditionsMet = GlobalConditionsMet(simManager);
        bool isPastMinTime = raceTime >= minTime;

        if (info.Phase == BFPhase::Initial)
        {
            if (conditionsMet && isPastMinTime)
            {
                if (bestTime == -1 || raceTime < bestTime)
                {
                    bestTime = raceTime;
                    resp.Decision = BFEvaluationDecision::Accept;
                    if (isFirstRun)
                    {
                        isFirstRun = false;
                        print("Base run time: " + (bestTime / 1000.0) + " s");
                        resp.ResultFileStartContent = "# Base time: " + (bestTime / 1000.0) + " s";
                    }
                }
            }
        }
        else
        {
            if (conditionsMet && isPastMinTime && raceTime < bestTime)
            {
                bestTime = raceTime;
                resp.Decision = BFEvaluationDecision::Accept;
                print("New best: " + (bestTime / 1000.0) + " s");
                resp.ResultFileStartContent = "# Best time: " + (bestTime / 1000.0) + " s";
            }
        }

        return resp;
    }

    void OnSimulationBegin(SimulationManager @simManager)
    {
        minTime = int(GetVariableDouble("timebf_min_time"));
        bestTime = -1;
        isFirstRun = true;
    }

    void Main()
    {
        RegisterVariable("timebf_min_time", 0);
        auto eval = RegisterBruteforceEval("time", "Time", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
```

## Key Points

1. **Always return `DoNothing` by default** - Only return `Accept`/`Reject` when you've made a final decision for the run.

2. **Use `GlobalConditionsMet()`** - Ensures your target respects the global conditions (speed, CPs, triggers, scripts).

3. **Reset state in `OnSimulationBegin`** - Each new simulation should start fresh.

4. **Handle both phases** - Initial establishes baseline, Search looks for improvements.

5. **Set `ResultFileStartContent`** - Adds helpful comments to saved input files.

6. **Early rejection is optional but efficient** - If you know a run can't improve, return `Reject` early to save time.
