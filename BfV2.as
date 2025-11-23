PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Bruteforce V2";
    info.Author = "Skycrafter";
    info.Version = "1.0";
    info.Description = "Next generation bruteforce";
    return info;
}

void coption(string name, string currentId, string identifier){
    if(UI::Selectable(name, currentId == identifier)){
        SetVariable("bf_target", identifier);
    }
}

array<BruteforceEvaluation@> evaluations;
BruteforceEvaluation@ current;
BFEvaluationInfo info = BFEvaluationInfo();
float minSpeed = 0.0f;
int minCps = 0;
int restartIterations = 0;
string resultFolder = "";
int restartCount = 0;

void BruteforceV2Settings(){
    UI::Dummy(vec2(0,15));
    if(UI::CollapsingHeader("Behavior")){
        UI::Dummy(vec2(0,15)); // UI::Dummy(vec2(0,65)); to match built-in UI spacing
        UI::PushItemWidth(300);
        UI::InputTextVar("Filename used for saving results", "bf_result_filename");
        UI::Dummy(vec2(0,10));
        UI::InputIntVar("Iterations before restart", "bf_iterations_before_restart", 0);
        UI::TextDimmed("Setting this to 0 will disable restarts.");
        UI::Dummy(vec2(0,10));
        UI::InputTextVar("Result files folder", "bf_result_folder");
        UI::TextDimmed("Leave empty to use the root folder.");
        UI::Dummy(vec2(0,15));
                
    }

    if(UI::CollapsingHeader("Optimization")){
        @current = @GetBruteforceTarget();
        if(current is null){
            SetVariable("bf_target", evaluations[0].identifier);
            @current = @evaluations[0];
        }
        if(UI::BeginCombo("Optimization Target", current.title)){
            for(uint i = 0; i < evaluations.Length; i++){
                BruteforceEvaluation@ eval = evaluations[i];
                coption(eval.title, current.identifier, eval.identifier);
            }
            UI::EndCombo();
        }
        if(current.renderCallback !is null) current.renderCallback();
    }

    if(UI::CollapsingHeader("Conditions")){
        UI::PushItemWidth(160);
        UI::Dummy(vec2(0, 15));
        if(GetVariableDouble("bf_condition_speed") > 0.0f){
            UI::Text("Min. speed ");
        }else{
            UI::BeginDisabled();
            UI::Text("Min. speed ");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(18, 0));
        UI::SameLine();
        UI::InputFloatVar("##bf_condition_speed", "bf_condition_speed");
        if(GetVariableDouble("bf_condition_speed") < 0.0f){
            SetVariable("bf_condition_speed", 0.0f);
        }

        if(GetVariableDouble("bf_condition_cps") > 0.0f){
            UI::Text("Min. cps");
        }else{
            UI::BeginDisabled();
            UI::Text("Min. cps");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(39, 0));
        UI::SameLine();
        UI::InputIntVar("##bf_condition_cps", "bf_condition_cps");
        if(GetVariableDouble("bf_condition_cps") < 0.0f){
            SetVariable("bf_condition_cps", 0.0f);
        }
        UI::Dummy(vec2(0,15));
    }
    
    if(UI::CollapsingHeader("Input Modification")){
        UI::PushItemWidth(300);
        UI::InputIntVar("Input Modify Count", "bf_modify_count", 1);
        UI::TextDimmed("At most " + int(GetVariableDouble("bf_modify_count")) + " inputs will be changed each attempt.");

        UI::Dummy(vec2(0,15));

        UI::Text("Time frame in which inputs can be changed:");

        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(18,0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_min_time", "bf_inputs_min_time");
        UI::PopItemWidth();

        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(37,0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_max_time", "bf_inputs_max_time");
        UI::PopItemWidth();

        UI::TextDimmed("Limiting this time frame will make the bruteforcing process faster.");

        UI::Dummy(vec2(0,15));

        UI::PushItemWidth(300);
        int t = UI::SliderIntVar("Maximum Steering Difference", "bf_max_steer_diff", 0, 131072 );

        UI::TextDimmed(
            "Bruteforce will randomize a number between [-" + t + ", " + t
            + "] and add it to the current steering value."
        );

        UI::Dummy(vec2(0,15));


        int timediff = UI::InputTimeVar("Maximum Time Difference", "bf_max_time_diff");
        UI::PopItemWidth();

        UI::TextDimmed(
            "Bruteforce will randomize a number between [-" + timediff + ", " + timediff
            + "] and add it to the current time value."
        );

        UI::Dummy(vec2(0,15));

        // --- Fill Missing Steering Input ---
        UI::CheckboxVar("Fill Missing Steering Input", "bf_inputs_fill_steer");
        UI::TextDimmed(
            "Timestamps with no steering input changes will be filled with existing values "
            "resulting in more values that can be changed."
        );
    }
}

BruteforceEvaluation@ GetBruteforceTarget(){
    string current = GetVariableString("bf_target");
    for(uint i = 0; i < evaluations.Length; i++){
        BruteforceEvaluation@ eval = evaluations[i];
        if(eval.identifier == current){
            return eval;
        }
    }
    return null;
}

void Main(){
    RegisterValidationHandler("bfv2", "Bruteforce V2", BruteforceV2Settings);
    RegisterVariable("bf_iterations_before_restart", 0);
    RegisterVariable("bf_result_folder","");
    PreciseFinishBf::Main();
    PreciseTriggerBf::Main();
    SinglePointBf::Main();
    VelocityBf::Main();
}

BruteforceEvaluation@ RegisterBruteforceEval(const string&in identifier, const string&in title, OnBruteforceEvaluate@ callback, RenderBruteforceEvaluationSettings@ renderCallback = null){
    BruteforceEvaluation eval;
    eval.identifier = identifier;
    eval.title = title;
    @eval.callback = callback;
    @eval.renderCallback = renderCallback;
    evaluations.Add(eval);  
    return eval;
}

funcdef BFEvaluationResponseExplicitRewind@ OnBruteforceEvaluateExplicitRewind(SimulationManager@ simManager, const BFEvaluationInfo&in info);
funcdef void OnSimulationBeginCallback(SimulationManager@ simManager);

BruteforceEvaluation@ RegisterBruteforceEval(const string&in identifier, const string&in title, OnBruteforceEvaluateExplicitRewind@ callback, RenderBruteforceEvaluationSettings@ renderCallback = null){
    BruteforceEvaluation eval;
    eval.type = CallbackType::ExplicitRewind;
    eval.identifier = identifier;
    eval.title = title;
    @eval.explicitRewindCallback = callback;
    @eval.renderCallback = renderCallback;
    evaluations.Add(eval);  
    return eval;
}

enum CallbackType {
    Legacy,
    ExplicitRewind,
    FullControl,
}

class BruteforceEvaluation {
    string identifier;
    string title;
    OnBruteforceEvaluate@ callback;
    OnBruteforceEvaluateExplicitRewind@ explicitRewindCallback;
    RenderBruteforceEvaluationSettings@ renderCallback;
    CallbackType type = CallbackType::Legacy;
    OnSimulationBeginCallback@ onSimBegin = null;
}

enum BFEvaluationDecisionExplicitRewind {
    DoNothing,
    Accept, // Saves only, does not rewind
    AcceptAndRewind,
    RejectAndRewind, // Cannot reject without rewinding in ExplicitRewind
    RewindAndMutateInputs,
    RewindOnly,
    Stop,
}

class BFEvaluationResponseExplicitRewind {
    
    BFEvaluationDecisionExplicitRewind Decision;
    int RewindTime;
    string ResultFileStartContent;
}

/*

bool meetsConditions(float dist, float speed, int cps = 0) { // Speed in m/s
    return dist < distCondition && speed*3.6f > speedCondition && cps >= cpsCondition;
}*/
;
int inputCount=0;
int minInputsTime=0;
int maxInputsTime=0;
int maxSteerDiff=0;
int maxTimeDiff=0;
bool fillSteerInputs=false;

bool forceStop = false;

array<TM::InputEvent> bestInputEvents;
bool hasBestInputs = false;

array<TM::InputEvent> baseInputEvents;
bool hasBaseInputs = false;

void SaveBestInputs(SimulationManager@ simManager, bool printSaved = false)
{
    TM::InputEventBuffer@ buf = simManager.InputEvents;
    if (buf is null) return;

    bestInputEvents.Resize(0);
    for (uint i = 0; i < buf.Length; i++) {
        auto evt = buf[i];
        bestInputEvents.Add(evt);
        
        if(printSaved) {
            print("Saved Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
    hasBestInputs = true;
}

void SaveBaseInputs(SimulationManager@ simManager, bool printSaved = false)
{
    TM::InputEventBuffer@ buf = simManager.InputEvents;
    if (buf is null) return;

    baseInputEvents.Resize(0);
    for (uint i = 0; i < buf.Length; i++) {
        auto evt = buf[i];
        baseInputEvents.Add(evt);

        if(printSaved) {
            print("Saved Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
    hasBaseInputs = true;
}

void RestoreBestInputs(SimulationManager@ simManager, bool printRestored = false)
{
    if (!hasBestInputs) return;

    TM::InputEventBuffer@ buf = simManager.InputEvents;
    if (buf is null) return;

    buf.Clear();
    for (uint i = 0; i < bestInputEvents.Length; i++) {
        auto evt = bestInputEvents[i];
        buf.Add(evt);

        if(printRestored) {
            print("Restored Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
}

void RestoreBaseInputs(SimulationManager@ simManager, bool printRestored = false){
    if (!hasBaseInputs) return;

    TM::InputEventBuffer@ buf = simManager.InputEvents;
    if (buf is null) return;

    buf.Clear();
    for (uint i = 0; i < baseInputEvents.Length; i++) {
        auto evt = baseInputEvents[i];
        buf.Add(evt);

        if(printRestored) {
            print("Restored Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
}

bool GlobalConditionsMet(SimulationManager@ simManager) {
    float currentSpeed = simManager.Dyna.CurrentState.LinearSpeed.Length();
    int currentCps = simManager.PlayerInfo.CurCheckpointCount;
    return currentSpeed >= minSpeed && currentCps >= minCps;
}

SimulationState rewindState;
bool IsBfV2Active = false;

void OnSimulationBegin(SimulationManager@ simManager) {
    IsBfV2Active = GetVariableString("controller")=="bfv2";
    if (!IsBfV2Active) return;

    @current = @GetBruteforceTarget();
    if (current is null) {
        SetVariable("bf_target", evaluations[0].identifier);
        @current = @evaluations[0];
    }

    info.Iterations = 0;
    info.Phase = BFPhase::Initial;
    info.Rewinded = false;
    forceStop = false;
    restartCount = 0;

    // Input modification settings
    inputCount = int(GetVariableDouble("bf_modify_count"));
    minInputsTime = int(GetVariableDouble("bf_inputs_min_time"));
    maxInputsTime = int(GetVariableDouble("bf_inputs_max_time"));
    maxInputsTime = maxInputsTime == 0 ? simManager.EventsDuration : maxInputsTime;
    maxSteerDiff = int(GetVariableDouble("bf_max_steer_diff"));
    maxTimeDiff = int(GetVariableDouble("bf_max_time_diff"));
    fillSteerInputs = GetVariableBool("bf_inputs_fill_steer");
    
    // Conditions
    minSpeed = float(GetVariableDouble("bf_condition_speed"))/3.6f; // Convert from km/h to m/s
    minCps = int(GetVariableDouble("bf_condition_cps"));

    restartIterations = int(GetVariableDouble("bf_iterations_before_restart"));
    resultFolder = GetVariableString("bf_result_folder");

    print("Bruteforce V2 started with settings:");
    print(" - Target: " + current.title);
    print(" - Input Modify Count: " + inputCount);
    print(" - Input Modify Time Frame: From " + Time::Format(minInputsTime) + " to " + Time::Format(maxInputsTime));    
    print(" - Max Steering Difference: " + maxSteerDiff);
    print(" - Max Time Difference: " + Time::Format(maxTimeDiff));
    print(" - Fill Missing Steering Input: " + (fillSteerInputs ? "Yes" : "No"));   

    print("Conditions:");
    print(" - Min Speed: " + Text::FormatFloat(minSpeed*3.6f, "", 0, 2) + " km/h");
    print(" - Min CPs: " + minCps);

    print("Restarting every " + restartIterations + " Iterations");
    print("Storing results to folder: " + resultFolder);

    bestInputEvents.Clear();
    hasBestInputs = false;
    SaveBestInputs(simManager);
    SaveBaseInputs(simManager);

    if(current.onSimBegin !is null)
        current.onSimBegin(simManager);
}

int prevPrintedIteration = -1;

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled){
    if(!IsBfV2Active) return;
    if(forceStop || userCancelled) return;

    if (restartIterations > 0 && int(info.Iterations) >= restartIterations) {
        restartCount++;
        RestoreBestInputs(simManager);
        CommandList list();
        list.Content = simManager.InputEvents.ToCommandsText();
        string path="";
        if(resultFolder != ""){
            path = resultFolder + "/";
        }
        path+="pass" + (restartCount)+"_"+GetVariableString("bf_result_filename");
        list.Save(path)?print("Saved command list to: " + path):print("Failed to save command list to: " + path);

        RestoreBaseInputs(simManager, false);
        SaveBestInputs(simManager, false); 


        print("Restarting Bruteforce: Iteration limit reached (" + info.Iterations + ")");
        

        if(current.onSimBegin !is null) {
            current.onSimBegin(simManager);
        }

        info.Iterations = 0;
        info.Phase = BFPhase::Initial;
        info.Rewinded = false;

        simManager.RewindToState(rewindState);
        return;
    }

    if(prevPrintedIteration != int(info.Iterations) && info.Iterations % 100 == 0 && info.Iterations > 0){
        print("Bruteforce iteration: " + info.Iterations);
        prevPrintedIteration = info.Iterations;
    }

    int raceTime = simManager.RaceTime;

    if(current.type == CallbackType::FullControl){
        BFEvaluationResponse@ response = current.callback(simManager, info);
    }

    if(current.type == CallbackType::Legacy){
        BFEvaluationResponse@ response = current.callback(simManager, info);
        if(simManager.TickTime>simManager.RaceTime+10 && !info.Rewinded && response.Decision != BFEvaluationDecision::Accept){    
            simManager.RewindToState(rewindState);
            RestoreBestInputs(simManager);
            InputModification::MutateInputs(
                simManager.InputEvents,
                inputCount,
                minInputsTime,
                maxInputsTime,
                maxSteerDiff,
                maxTimeDiff,
                fillSteerInputs
            );
            info.Rewinded = true;
            info.Phase = BFPhase::Search;
            info.Iterations++;
            // print("Rewind due to no progress in time.");
            return;
        }
        info.Rewinded = false;
        if(info.Phase == BFPhase::Initial) {
            if(raceTime == minInputsTime-10){
                rewindState = simManager.SaveState();
            }
            if(response.Decision == BFEvaluationDecision::Stop){
                forceStop = true;
            }else{
                if(raceTime > int(simManager.EventsDuration) || response.Decision == BFEvaluationDecision::Accept){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    InputModification::MutateInputs(
                        simManager.InputEvents,
                        inputCount,
                        minInputsTime,
                        maxInputsTime,
                        maxSteerDiff,
                        maxTimeDiff,
                        fillSteerInputs
                    );
                    info.Rewinded = true;
                    info.Phase = BFPhase::Search;
                    info.Iterations++;
                    // print("Rewind from initial phase because :" + (response.Decision == BFEvaluationDecision::Accept ? " accepted improvement." : " exceeded duration."));
                    // print("Duration: " + Time::Format(simManager.EventsDuration) + ", Race Time: " + Time::Format(raceTime));
                }
            }
        }else{
            if(response.Decision == BFEvaluationDecision::DoNothing){
                if(raceTime > int(simManager.EventsDuration)){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    InputModification::MutateInputs(
                        simManager.InputEvents,
                        inputCount,
                        minInputsTime,
                        maxInputsTime,
                        maxSteerDiff,
                        maxTimeDiff,
                        fillSteerInputs
                    );
                    info.Rewinded = true;
                    info.Iterations++;
                    // print("Rewind from do nothing.");
                }
            } else if(response.Decision == BFEvaluationDecision::Accept){
                SaveBestInputs(simManager, false);
                CommandList list;
                RestoreBestInputs(simManager, false);
                list.Content = simManager.InputEvents.ToCommandsText();
                list.Save(GetVariableString("bf_result_filename"))?void:print("Failed to save improved inputs.");
                simManager.RewindToState(rewindState);
                RestoreBestInputs(simManager, false);
                info.Rewinded = true;
                info.Iterations++;
                info.Phase = BFPhase::Initial;
                // print("Rewind from improvement acceptance.");
            } else if(response.Decision == BFEvaluationDecision::Reject){
                simManager.RewindToState(rewindState);
                RestoreBestInputs(simManager);
                InputModification::MutateInputs(
                    simManager.InputEvents,
                    inputCount,
                    minInputsTime,
                    maxInputsTime,
                    maxSteerDiff,
                    maxTimeDiff,
                    fillSteerInputs
                );
                info.Rewinded = true;
                info.Iterations++;
                // print("Rewind from rejection.");
            } else if(response.Decision == BFEvaluationDecision::Stop){
                forceStop = true;
            }
        }
    } 
    if(current.type == CallbackType::ExplicitRewind){
        BFEvaluationResponseExplicitRewind response = current.explicitRewindCallback(simManager, info);
        if(simManager.TickTime>simManager.RaceTime+20 && (response.Decision != BFEvaluationDecisionExplicitRewind::Accept && response.Decision != BFEvaluationDecisionExplicitRewind::AcceptAndRewind)){    
            simManager.RewindToState(rewindState);
            RestoreBestInputs(simManager);
            InputModification::MutateInputs(
                simManager.InputEvents,
                inputCount,
                minInputsTime,
                maxInputsTime,
                maxSteerDiff,
                maxTimeDiff,
                fillSteerInputs
            );
            info.Rewinded = true;
            info.Phase = BFPhase::Search;
            info.Iterations++;
            return;
        }
        info.Rewinded = false;
        if(info.Phase == BFPhase::Initial) {
            if(raceTime == minInputsTime-10){
                rewindState = simManager.SaveState();
            }
            if(response.Decision == BFEvaluationDecisionExplicitRewind::Stop){
                forceStop = true;
            }else{
                if(raceTime > int(simManager.EventsDuration)+20 || response.Decision == BFEvaluationDecisionExplicitRewind::AcceptAndRewind){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    InputModification::MutateInputs(
                        simManager.InputEvents,
                        inputCount,
                        minInputsTime,
                        maxInputsTime,
                        maxSteerDiff,
                        maxTimeDiff,
                        fillSteerInputs
                    );
                    info.Rewinded = true;
                    info.Phase = BFPhase::Search;
                    info.Iterations++;
                    // print("Rewind from initial phase because :" + (response.Decision == BFEvaluationDecisionExplicitRewind::Accept ? " accepted improvement." : " exceeded duration."));
                    // print("Duration: " + Time::Format(simManager.EventsDuration) + ", Race Time: " + Time::Format(raceTime));
                }else if(response.Decision == BFEvaluationDecisionExplicitRewind::Accept){
                    // Do nothing, wait for next rewind
                }else if(response.Decision == BFEvaluationDecisionExplicitRewind::RewindAndMutateInputs){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    InputModification::MutateInputs(
                        simManager.InputEvents,
                        inputCount,
                        minInputsTime,
                        maxInputsTime,
                        maxSteerDiff,
                        maxTimeDiff,
                        fillSteerInputs
                    );
                    info.Phase = BFPhase::Search;
                    info.Rewinded = true;
                    info.Iterations++;
                }else if(response.Decision == BFEvaluationDecisionExplicitRewind::RejectAndRewind){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    InputModification::MutateInputs(
                        simManager.InputEvents,
                        inputCount,
                        minInputsTime,
                        maxInputsTime,
                        maxSteerDiff,
                        maxTimeDiff,
                        fillSteerInputs
                    );
                    info.Rewinded = true;
                    info.Iterations++;
                }else if(response.Decision == BFEvaluationDecisionExplicitRewind::RewindOnly){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    info.Rewinded = true;
                }
            }
        }else{
            if(response.Decision == BFEvaluationDecisionExplicitRewind::DoNothing){
                if(raceTime > int(simManager.EventsDuration)){
                    simManager.RewindToState(rewindState);
                    RestoreBestInputs(simManager);
                    InputModification::MutateInputs(
                        simManager.InputEvents,
                        inputCount,
                        minInputsTime,
                        maxInputsTime,
                        maxSteerDiff,
                        maxTimeDiff,
                        fillSteerInputs
                    );
                    info.Rewinded = true;
                    info.Iterations++;
                }
            } else if(response.Decision == BFEvaluationDecisionExplicitRewind::Accept){
                SaveBestInputs(simManager, false);
                CommandList list;
                RestoreBestInputs(simManager, false);
                list.Content = simManager.InputEvents.ToCommandsText();
                list.Save(GetVariableString("bf_result_filename"))?void:print("Failed to save improved inputs.");
            } else if(response.Decision == BFEvaluationDecisionExplicitRewind::AcceptAndRewind){
                SaveBestInputs(simManager, false);
                CommandList list;
                RestoreBestInputs(simManager, false);
                list.Content = simManager.InputEvents.ToCommandsText();
                list.Save(GetVariableString("bf_result_filename"))?void:print("Failed to save improved inputs.");
                simManager.RewindToState(rewindState);
                RestoreBestInputs(simManager, false);
                info.Rewinded = true;
                info.Phase = BFPhase::Initial;
                info.Iterations++;
            } else if(response.Decision == BFEvaluationDecisionExplicitRewind::RewindAndMutateInputs || response.Decision == BFEvaluationDecisionExplicitRewind::RejectAndRewind){
                simManager.RewindToState(rewindState);
                RestoreBestInputs(simManager);
                InputModification::MutateInputs(
                    simManager.InputEvents,
                    inputCount,
                    minInputsTime,
                    maxInputsTime,
                    maxSteerDiff,
                    maxTimeDiff,
                    fillSteerInputs
                );
                info.Rewinded = true;
                info.Iterations++;
                // print("Rewind and mutate inputs.");
            } else if(response.Decision == BFEvaluationDecisionExplicitRewind::RewindOnly){
                simManager.RewindToState(rewindState);
                RestoreBestInputs(simManager);
                info.Rewinded = true;
                info.Iterations++;
            } else if(response.Decision == BFEvaluationDecisionExplicitRewind::Stop){
                forceStop = true;
            }
        }
    }
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result) {
    if (!IsBfV2Active) return;
}

namespace PreciseFinishBf {
    void RenderEvalSettings(){}
    double bestTime = -1;
    int bestTimeMsImprecise = -1;

    BFEvaluationResponseExplicitRewind@ OnEvaluateExplicitRewind(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponseExplicitRewind();

        if (info.Phase == BFPhase::Initial) {
            double preciseTime;
            if (PreciseFinish::Compute(simManager, simManager.PlayerInfo.RaceFinished, preciseTime)) {
                if (!GlobalConditionsMet(simManager)) {
                    print("Base run finished, but conditions not met. Search will require meeting these conditions.", Severity::Warning);    
                }
                if(bestTime != -1 && preciseTime >= bestTime + 1e-7){
                    resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                    PreciseFinish::Reset();
                    return resp;
                }
                if(bestTime != -1) print("Precise finish time: " + Text::FormatFloat(preciseTime, "", 0, 9));
                else print("Base run finish time: " + Text::FormatFloat(preciseTime, "", 0, 9));
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime; 
                resp.Decision = BFEvaluationDecisionExplicitRewind::AcceptAndRewind;
                PreciseFinish::Reset();
            }
        } else {
            if(simManager.PlayerInfo.RaceFinished && raceTime < bestTimeMsImprecise){
               if (GlobalConditionsMet(simManager)) {
                    resp.Decision = BFEvaluationDecisionExplicitRewind::AcceptAndRewind;
                } else {
                    resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                }
                PreciseFinish::Reset();
                return resp;
            }
            
            if (raceTime > bestTimeMsImprecise + 50) {
                resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                // print("Rewind due to exceeding imprecise best time: " + Time::Format(bestTimeMsImprecise));
                PreciseFinish::Reset();
                return resp;
            }

            if (raceTime >= bestTimeMsImprecise) {
                double preciseTime;
                if (PreciseFinish::Compute(simManager, simManager.PlayerInfo.RaceFinished, preciseTime)) {
                    if(!GlobalConditionsMet(simManager)) {
                         resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                         PreciseFinish::Reset();
                         return resp;
                    }
                    if(preciseTime >= bestTime) {
                        resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                        PreciseFinish::Reset();
                    }else{
                        resp.Decision = BFEvaluationDecisionExplicitRewind::AcceptAndRewind;
                        PreciseFinish::Reset();    
                    }
                }
            }
        }

        return resp;
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;
    }

    void Main() {
        auto bfEval = RegisterBruteforceEval("precisefinish", "Precise Finish Time", OnEvaluateExplicitRewind, RenderEvalSettings);
        @bfEval.onSimBegin = @OnSimulationBegin;
    }
}
namespace PreciseFinish
{
    bool IsEstimating = false;
    uint64 CoeffMin = 0;
    uint64 CoeffMax = 18446744073709551615;
    SimulationState@ StateBeforeHit;
    SimulationState@ StateAtHit;
    int StateBeforeHitTime = -1;
    int StateAtHitTime = -1;
    bool done = false;
    double localResult = -1;
    
    uint Precision = 1;

    void Reset() {
        IsEstimating = false;
        CoeffMin = 0;
        CoeffMax = 18446744073709551615;
        @StateBeforeHit = null;
        @StateAtHit = null;
        StateAtHitTime = -1;
        StateBeforeHitTime = -1;
        localResult = -1;
        done = false;
    }

    bool Compute(SimulationManager@ sim, bool targetReached, double &out result) {
        if(done) {
            result = localResult;
            return true;
        }
        if (!IsEstimating) {
            if (targetReached) {
                IsEstimating = true;
                @StateAtHit = sim.SaveState();
                StateAtHitTime = sim.RaceTime;
                CoeffMin = 0;
                CoeffMax = 18446744073709551615;
                
                if (StateBeforeHit is null) {
                    result = double(sim.RaceTime) / 1000.0;
                    return true;
                }
            } else {
                @StateBeforeHit = sim.SaveState();
                StateBeforeHitTime = sim.RaceTime;
                return false;
            }
        } else {

            if (targetReached) {
                CoeffMax = CoeffMin + (CoeffMax - CoeffMin) / 2;
            } else {
                CoeffMin = CoeffMin + (CoeffMax - CoeffMin) / 2;
            }
        }
        
        
        if (CoeffMax - CoeffMin <= Precision) {
            IsEstimating = false;
        
            double baseTimeMs = double(StateBeforeHitTime); 
            
            uint64 currentCoeff = CoeffMin + (CoeffMax - CoeffMin) / 2;
            double percentage = currentCoeff / 18446744073709551615.0;
            
            result = (baseTimeMs / 1000.0) + (percentage / 100.0);
            
            if(StateAtHit !is null) {
                sim.RewindToState(StateAtHit);
            }else if (StateBeforeHit !is null) {
                sim.RewindToState(StateBeforeHit);
            }

            localResult = result;
            @StateBeforeHit = null;
            @StateAtHit = null;
            done = true;
            return true; 
        }
        
        sim.RewindToState(StateBeforeHit);
        
        uint64 currentCoeff = CoeffMin + (CoeffMax - CoeffMin) / 2;
        double percentage = currentCoeff / 18446744073709551615.0;
        
        sim.Dyna.CurrentState.LinearSpeed = sim.Dyna.CurrentState.LinearSpeed * percentage;
        sim.Dyna.CurrentState.AngularSpeed = sim.Dyna.CurrentState.AngularSpeed * percentage;
        
        return false;
    }
}
namespace PreciseTriggerBf {
    Trigger3D targetTrigger;
    double bestTime = -1;
    int bestTimeMsImprecise = -1;

    void RenderEvalSettings(){
        uint triggerIndex = uint(GetVariableDouble("bf_target_trigger"));
        array<int>@ triggerIds = GetTriggerIds();

        if (triggerIds.Length == 0) {
            UI::Text("No triggers found in map.");
            return;
        }

        if (triggerIndex >= triggerIds.Length) triggerIndex = 0;

        Trigger3D selectedTrigger = GetTriggerByIndex(triggerIds[triggerIndex]);
        vec3 pos = selectedTrigger.Position;
        
        if(UI::BeginCombo("Trigger Index", (triggerIndex+1)+". Position: ("+pos.x+", "+pos.y+", "+pos.z+")")){
            for(uint i = 0; i < triggerIds.Length; i++){
                Trigger3D trigger = GetTriggerByIndex(triggerIds[i]);
                pos = trigger.Position;
                string triggerName = (triggerIds[i]+1)+". Position: ("+pos.x+", "+pos.y+", "+pos.z+")";
                if(UI::Selectable(triggerName, triggerIndex == i)){
                    SetVariable("bf_target_trigger", i);
                }
            }
            UI::EndCombo();
        }
    }

    BFEvaluationResponseExplicitRewind@ OnEvaluateExplicitRewind(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponseExplicitRewind();

        bool inTrigger = targetTrigger.ContainsPoint(simManager.Dyna.CurrentState.Location.Position);

        if (info.Phase == BFPhase::Initial) {
            double preciseTime;
            if (PreciseFinish::Compute(simManager, inTrigger, preciseTime)) {
                if (!GlobalConditionsMet(simManager)) {
                    print("Base run hit trigger but conditions not met. Search will require meeting these conditions.", Severity::Warning);
                }
                if(bestTime != -1 && preciseTime >= bestTime + 1e-7){
                    resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                    PreciseFinish::Reset();
                    return resp;
                }
                if(bestTime != -1) print("Precise trigger time: " + Text::FormatFloat(preciseTime, "", 0, 9));
                else print("Base run trigger time: " + Text::FormatFloat(preciseTime, "", 0, 9));
                
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime; 
                resp.Decision = BFEvaluationDecisionExplicitRewind::AcceptAndRewind;
                PreciseFinish::Reset();
            }
        } else {
            if(inTrigger && raceTime < bestTimeMsImprecise){
                if (GlobalConditionsMet(simManager)) {
                    resp.Decision = BFEvaluationDecisionExplicitRewind::AcceptAndRewind;
                } else {
                    resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                }
                PreciseFinish::Reset();
                return resp;
            }
            
            if (raceTime > bestTimeMsImprecise + 50) {
                resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                PreciseFinish::Reset();
                return resp;
            }

            if (raceTime >= bestTimeMsImprecise) {
                double preciseTime;
                if (PreciseFinish::Compute(simManager, inTrigger, preciseTime)) {
                    if(!GlobalConditionsMet(simManager)) {
                         resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                         PreciseFinish::Reset();
                         return resp;
                    }
                    if(preciseTime >= bestTime) {
                        resp.Decision = BFEvaluationDecisionExplicitRewind::RejectAndRewind;
                        PreciseFinish::Reset();
                    } else {
                        resp.Decision = BFEvaluationDecisionExplicitRewind::AcceptAndRewind;
                        PreciseFinish::Reset();    
                    }
                }
            }
        }

        return resp;
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;

        int triggerIndex = int(GetVariableDouble("bf_target_trigger"));
        array<int>@ triggerIds = GetTriggerIds();
        
        if (triggerIds.Length > 0 && triggerIndex < int(triggerIds.Length)) {
            targetTrigger = GetTriggerByIndex(triggerIds[triggerIndex]);
        } else {
            print("Error: Invalid trigger index selected for bruteforce.", Severity::Error);
        }
    }

    void Main() {
        auto bfEval = RegisterBruteforceEval("precisetrigger", "Trigger", OnEvaluateExplicitRewind, RenderEvalSettings);
        @bfEval.onSimBegin = @OnSimulationBegin;
    }
}


namespace SinglePointBf {
    int minTime = 0;
    int maxTime = 0;
    float bestDist = 1e18f;
    float bestSpeed = 0.0f;
    int bestTime = 0;
    bool base = false;
    float currentBestDist = 1e18f;
    float currentBestSpeed = 0.0f;
    int currentBestTime = 0;
    bool isRunBetter = false;
    void RenderEvalSettings()
    {
        UI::SliderIntVar("Ratio", "bf_weight", 0, 100, "%d%%");
        if(!(GetVariableDouble("bf_weight") < 1.0f || GetVariableDouble("bf_weight") > 99.0f)){
            UI::SameLine();
            UI::Text("❔");
            if(UI::IsItemHovered()){
                UI::BeginTooltip();
                if(GetVariableDouble("bf_weight") <= 50){
                    UI::Text("This ratio means gaining 1m is worth sacrificing speed until " + Text::FormatFloat(100/GetVariableDouble("bf_weight")-1, "", 0, 3) + "m/s.");
                }else{
                    UI::Text("This ratio means gaining 1m/s is worth sacrificing distance until " + Text::FormatFloat(100/(100-GetVariableDouble("bf_weight"))-1, "", 0, 3) + "m.");
                }
                UI::EndTooltip();
            }
        }
        
        UI::Text("Distance");
        UI::SameLine();
        UI::Dummy(vec2(188, 0));
        UI::SameLine();
        UI::Text("Speed");
        UI::Dummy(vec2(0, 15));
        UI::TextDimmed("The ratio slider determines which metric bruteforce should value more.\nSetting the slider fully to the left side (0%) will just optimize how close the vehicle gets to the point.\nSetting the slider fully to the right side (100%) will instead optimize vehicle speed without taking the point into account.");
        UI::Dummy(vec2(0, 17));
        if(GetVariableDouble("bf_weight")<=99){
            UI::Dummy(vec2(9, 0));
            UI::SameLine();
            UI::Text("Target position:");
            UI::SameLine();
            UI::DragFloat3Var("##bf_target_point", "bf_target_point", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if(GetSimulationManager().InRace){
                UI::Dummy(vec2(0, 2));
                UI::Dummy(vec2(119, 0));
                UI::SameLine();
                if(GetCurrentCamera().NameId!=""){
                    if(UI::Button("    Copy from Vehicle Coordinates")){
                        SetVariable("bf_target_point", pos().ToString());
                    }
                }else{
                    if(UI::Button("    Copy from Camera Coordinates")){
                        SetVariable("bf_target_point", GetCurrentCamera().Location.Position.ToString());
                    }
                }
                
            }
            UI::Dummy(vec2(0, 17));
        }
        UI::Text("Time frame in which the distance and/or speed will be evaluated:");
        UI::Dummy(vec2(0, 0));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(17, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##bf_eval_min_time", "bf_eval_min_time");
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(36, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##bf_eval_max_time", "bf_eval_max_time");
        UI::Dummy(vec2(0, 0));
        UI::TextDimmed("Reducing the maximum evaluation time will make the bruteforcing process faster.");
        UI::Dummy(vec2(0, 1));


        UI::PushItemWidth(160);
        if(GetVariableDouble("bf_condition_distance") > 0.0f){
            UI::Text("Max. distance ");
        }else{
            UI::BeginDisabled();
            UI::Text("Max. distance ");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(0, 0));
        UI::SameLine();
        UI::InputFloatVar("##bf_condition_distance", "bf_condition_distance");
        if(GetVariableDouble("bf_condition_distance") < 0.0f){
            SetVariable("bf_condition_distance", 0.0f);
        }

        UI::Dummy(vec2(0, 0));
        if(GetVariableBool("bf_ignore_same_speed")){
            UI::Text("Ignore same speed improvements");
        }else{
            UI::BeginDisabled();
            UI::Text("Ignore same speed improvements");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(2, 0));
        UI::SameLine();
        UI::CheckboxVar("##bf_ignore_same_speed", "bf_ignore_same_speed");
        UI::TextDimmed("Ignoring same speed improvements is particularly useful for bruteforcing air trajectories, where a different rotation but same speed would get rejected, despite the car being seemingly closer to target. This avoids flooding inputs and preventing real distance gains.");
    }

        BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();

        bool isEvalTime = raceTime >= minTime && raceTime <= maxTime;
        bool isPastEvalTime = raceTime > maxTime;

        bool conditionsMet = GlobalConditionsMet(simManager);

        if (info.Phase == BFPhase::Initial) {
            if (isEvalTime) {
                float d = dist();
                float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();

                if(conditionsMet && isBetter(d, speed)){
                    bestDist = d;
                    bestSpeed = speed;
                    bestTime = raceTime;
                }
            }
            if(isPastEvalTime) {
                resp.Decision = BFEvaluationDecision::Accept;
                if(base){
                    base = false;
                    if(bestSpeed < 0.0f){
                        print("Base run: Invalid", Severity::Warning);
                    }else{
                        print("Base run: " + Text::FormatFloat(bestDist,"", 0, 9) + " m, " + Text::FormatFloat(bestSpeed*3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2));
                    }
                }
            }
        } else {
            if(isEvalTime){
                float d = dist();
                float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();

                if(conditionsMet && isBetter(d, speed)){
                    isRunBetter = true;
                }
            }

            if(isPastEvalTime){
                if(isRunBetter){
                    resp.Decision = BFEvaluationDecision::Accept;
                    base = true;
                }else{
                    resp.Decision = BFEvaluationDecision::Reject;
                }
                isRunBetter = false;
            }
        }

        return resp;
    }
    vec3 target();
    int weight = 0;
    float k = 0.0f;
    int ignoreSameSpeed = 0;
    float distCondition = 0.0f;

    bool meetsConditions(float dist) {
        return dist < distCondition;
    }

    bool isBetter(float dist, float speed) {
        if(meetsConditions(dist)){
            if(bestSpeed < 0.0f){
                return true;
            }
            if (weight <= 50) {
                return (dist - k * speed) < (bestDist - k * bestSpeed) && speed*ignoreSameSpeed != bestSpeed;
            } else {
                return (speed - k * dist) > (bestSpeed - k * bestDist);
            }
        }
        return false;
    }


    void OnSimulationBegin(SimulationManager@ simManager) {
        if (!(GetVariableString("bf_target") == bfid)) {
            return;
        }
        minTime = int(GetVariableDouble("bf_eval_min_time"));
        maxTime = int(GetVariableDouble("bf_eval_max_time"));
        bestSpeed = -1.0f;
        bestDist = -1.0f;
        bestTime = 0;
        weight = int(GetVariableDouble("bf_weight"));
        target = Text::ParseVec3(GetVariableString("bf_target_point"));
        if (weight <= 50) {
            k = float(weight) / (100.0f - float(weight));
        } else {
            k = (100.0f - float(weight)) / float(weight);
        }
        base = true;
        distCondition = GetVariableDouble("bf_condition_distance") > 0.0f ? GetVariableDouble("bf_condition_distance") : 1e18f;
        ignoreSameSpeed = GetVariableBool("bf_ignore_same_speed") ? 1 : 0;
    }

    float dist(){
        return Math::Distance(pos(), target);
    }

    vec3 pos() {
        return GetSimulationManager().Dyna.CurrentState.Location.Position;
    }

    string id = "betterpoint";
    string bfid = "betterpoint";
    void Main() {
        RegisterVariable("bf_condition_distance", 0.0f);
        RegisterVariable("bf_ignore_same_speed", false);
        RegisterVariable("bf_condition_cps", 0);
        auto eval = RegisterBruteforceEval(bfid, "Single point", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}

namespace VelocityBf {
    int minTime = 0;
    int maxTime = 0;
    vec3 targetVelocity = vec3(0,0,0);
    string currentVelocityType = "Global";
    void RenderEvalSettings(){

        UI::Dummy(vec2(0, 0));

        currentVelocityType = GetVariableString("bf_velocity_type");
        if(UI::BeginCombo("Velocity Type", currentVelocityType)){
            if(UI::Selectable("Global", currentVelocityType == "Global")){
                SetVariable("bf_velocity_type", "Global");
            }
            if(UI::Selectable("Trajectory", currentVelocityType == "Trajectory")){
                SetVariable("bf_velocity_type", "Trajectory");
            }
            UI::EndCombo();
        }

        if(currentVelocityType == "Trajectory"){
            UI::Dummy(vec2(0, 10));
            UI::Text("From:");
            UI::SameLine();
            UI::DragFloat3Var("##bf_velocity_from", "bf_velocity_from", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if(GetSimulationManager().InRace){
                UI::Dummy(vec2(0, 2));
                UI::Dummy(vec2(119, 0));
                UI::SameLine();
                if(GetCurrentCamera().NameId!=""){
                    if(UI::Button("Copy from Vehicle Coordinates##bf_velocity_from")){
                        SetVariable("bf_velocity_from", pos().ToString());
                    }
                }else{
                    if(UI::Button("Copy from Camera Coordinates##bf_velocity_from")){
                        SetVariable("bf_velocity_from", GetCurrentCamera().Location.Position.ToString());
                    }
                }
            }
            
            
            UI::Text("To:");
            UI::SameLine();
            UI::Dummy(vec2(11, 0));
            UI::SameLine();
            UI::DragFloat3Var("##bf_velocity_to", "bf_velocity_to", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if(GetSimulationManager().InRace){
                UI::Dummy(vec2(0, 2));
                UI::Dummy(vec2(119, 0));
                UI::SameLine();
                if(GetCurrentCamera().NameId!=""){
                    if(UI::Button("Copy from Vehicle Coordinates##bf_velocity_to")){
                        SetVariable("bf_velocity_to", pos().ToString());
                    }
                }else{
                    if(UI::Button("Copy from Camera Coordinates##bf_velocity_to")){
                        SetVariable("bf_velocity_to", GetCurrentCamera().Location.Position.ToString());
                    }
                }
            }
        }

        UI::Dummy(vec2(0, 10));
        UI::Text("Time frame in which the distance and/or speed will be evaluated:");
        UI::Dummy(vec2(0, 0));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(17, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##bf_eval_min_time", "bf_eval_min_time");
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(36, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##bf_eval_max_time", "bf_eval_max_time");
        UI::Dummy(vec2(0, 0));
        UI::TextDimmed("Reducing the maximum evaluation time will make the bruteforcing process faster.");
        UI::Dummy(vec2(0, 1));
    }

    vec3 pos() {
        return GetSimulationManager().Dyna.CurrentState.Location.Position;
    }

    float bestSpeed = -1.0f;
    int bestTime = 0;
    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();

        bool isEvalTime = raceTime >= minTime && raceTime <= maxTime;
        bool isPastEvalTime = raceTime > maxTime;

        bool conditionsMet = GlobalConditionsMet(simManager);

        if (info.Phase == BFPhase::Initial) {
            if (isEvalTime) {
                float v = computeVel(simManager);

                if(conditionsMet && v > bestSpeed){
                    bestSpeed = v;
                    bestTime = raceTime;
                }
            }
            if(isPastEvalTime) {
                resp.Decision = BFEvaluationDecision::Accept;
                if(bestSpeed < 0.0f){
                    print("Base run: Invalid", Severity::Warning);
                }else{
                    print("Base run: " + Text::FormatFloat(bestSpeed, "", 0, 9) + " m/s at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2));
                }
            }
        } else {
            if(isEvalTime){
                float v = computeVel(simManager);
                if(conditionsMet && v > bestSpeed){
                    resp.Decision = BFEvaluationDecision::Accept;
                }
            }

            if(isPastEvalTime && resp.Decision != BFEvaluationDecision::Accept){
                resp.Decision = BFEvaluationDecision::Reject;
            }
        }

        return resp;
    }

    float computeVel(SimulationManager@ simManager) {
        if(currentVelocityType == "Global"){
            return simManager.Dyna.CurrentState.LinearSpeed.Length();
        }else if(currentVelocityType == "Trajectory"){
            float denom = targetVelocity.Length();
            if(denom > 1e-7f){
                vec3 vel = simManager.Dyna.CurrentState.LinearSpeed;
                return Math::Dot(vel.Normalized(), targetVelocity) * vel.Length();
            }else{
                return -9e8f;
            }
        }else{
            print("Should not happen, please report to plugin dev", Severity::Error);
            return 0;
        }
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        bestSpeed = -1.0f;
        minTime = int(GetVariableDouble("bf_eval_min_time"));
        maxTime = int(GetVariableDouble("bf_eval_max_time"));
        targetVelocity = Text::ParseVec3(GetVariableString("bf_velocity_to")) - Text::ParseVec3(GetVariableString("bf_velocity_from"));
        targetVelocity = targetVelocity.Normalized();
    }

    void Main() {
        RegisterVariable("bf_velocity_type", "Global");
        RegisterVariable("bf_velocity_from", "0 0 0");
        RegisterVariable("bf_velocity_to", "0 0 0");
        auto eval = RegisterBruteforceEval("velocity", "Velocity", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}

namespace FinishBf {
    void RenderEvalSettings(){}
    int bestTime = -1;
    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;

        auto resp = BFEvaluationResponse();
        if (info.Phase == BFPhase::Initial) {
            if (simManager.PlayerInfo.RaceFinished) {
                print("Base run: " + Time::Format(raceTime));
                bestTime = raceTime;
                resp.Decision = BFEvaluationDecision::Accept;
            }
        } else if (simManager.PlayerInfo.RaceFinished) {
            if (raceTime < bestTime) {
                resp.Decision = BFEvaluationDecision::Accept;
                print("New time: " + Time::Format(raceTime));
                resp.ResultFileStartContent = "# Found better simple finish time: " + Time::Format(raceTime);
            }
        }

        return resp;
    }

    void Main() {
        RegisterVariable("bf_velocity_type", "Global");
        RegisterBruteforceEval("simplefinish", "Simple Finish Time", OnEvaluate, RenderEvalSettings);
    }
}

namespace InputModification {

    void SortBufferManual(TM::InputEventBuffer@ buffer) {
        if (buffer is null || buffer.Length < 2) return;

        array<TM::InputEvent> events;
        for(uint i = 0; i < buffer.Length; i++) {
            events.Add(buffer[i]);
        }

        for (uint i = 1; i < events.Length; i++) {
            TM::InputEvent key = events[i];
            int j = i - 1;

            while (j >= 0 && events[j].Time > key.Time) {
                events[j + 1] = events[j];
                j--;
            }
            events[j + 1] = key;
        }

        buffer.Clear();
        for(uint i = 0; i < events.Length; i++) {
            buffer.Add(events[i]);
        }
    }

    void MutateInputs(TM::InputEventBuffer@ buffer, int inputCount, int minTime, int maxTime, int maxSteerDiff, int maxTimeDiff, bool fillInputs){
        if (buffer is null) return;
        if (maxTime <= 0) return;

        if (fillInputs){
            FillInputs(buffer, maxTime);
        }

        int actualInputCount = Math::Rand(1, inputCount);
        array<int> indices;
        
        for(uint i = 0; i < buffer.Length; i++) {
            auto evt = buffer[i];
            
            if(int(evt.Time)-100010 < minTime) continue;

            indices.Add(i);
            
            if(int(evt.Time)-100010 > maxTime) break;
        }

        if(indices.Length == 0) {
            print("No inputs found in the specified time frame to modify.", Severity::Warning);
            return;
        }

        for (int i = 0; i < actualInputCount; i++) {
            int timeOffset = Math::Rand(-maxTimeDiff/10, maxTimeDiff/10)*10;
            int steerOffset = Math::Rand(-maxSteerDiff, maxSteerDiff);
            
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];

            evt.Time += timeOffset;

            if(evt.Time < 100010) {
                evt.Time = 100010;
            }

            if(int(evt.Time)-100010 < minTime) {
                evt.Time = 100010 + minTime;
            }

            if(int(evt.Time)-100010 > maxTime) {
                evt.Time = 100010 + maxTime;
            }

            if(evt.Value.EventIndex == buffer.EventIndices.SteerId) {
                evt.Value.Analog = evt.Value.Analog+steerOffset;
                if(evt.Value.Analog < -65536) {
                    evt.Value.Analog = -65536;
                }
                if(evt.Value.Analog > 65536) {
                    evt.Value.Analog = 65536;
                }
            }

            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer);
    }

    void FillInputs(TM::InputEventBuffer@ buffer, int maxTime)
    {
        if (buffer is null) return;
        if (maxTime <= 0) return;

        const int OFFSET = 100010;
        int absMaxTime = OFFSET + maxTime;

        auto indices = buffer.EventIndices;
        
        array<TM::InputEvent> steer;
        for (uint i = 0; i < buffer.Length; i++) {
            auto evt = buffer[i];
            if (int(evt.Time) > absMaxTime) break;

            if (evt.Value.EventIndex == indices.SteerId) {
                steer.Add(evt);
            }
        }

        int prevSteerState = 0;
        int prevSteerTime = -1;
        bool hasPrevSteer = true;
        uint k = 0;
        const uint steerLen = steer.Length;

        for (int t = 0; t <= maxTime; t += 10) {
            int absT = t + OFFSET;
            bool hadSteerAtT = false;

            while (k < steerLen && int(steer[k].Time) <= absT) {
                if (int(steer[k].Time) == absT) {
                    hadSteerAtT = true;
                }
                prevSteerState = int(steer[k].Value.Analog);
                prevSteerTime = int(steer[k].Time);
                hasPrevSteer = true;
                k++;
            }

            if (!hadSteerAtT && hasPrevSteer && absT > prevSteerTime) {
                buffer.Add(t, InputType::Steer, prevSteerState);
            }
        }
    }


}
void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target) {
    if (!(GetVariableString("controller")=="bfv2")) return;
    simManager.PreventSimulationFinish();
}