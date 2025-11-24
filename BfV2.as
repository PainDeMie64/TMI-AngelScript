PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Bruteforce V2";
    info.Author = "Skycrafter";
    info.Version = "1.3";
    info.Description = "Next generation bruteforce";
    return info;
}

void coption(string name, string currentId, string identifier){
    if(UI::Selectable(name, currentId == identifier)){
        SetVariable("bf_target", identifier);
    }
}

void toolTip(int width, array<string> args){
    if(UI::IsItemHovered()){
        UI::SetNextWindowSize(vec2(width, -1));
        UI::BeginTooltip(); 
        for(uint i = 0; i < args.Length; i++){
            UI::TextDimmed(args[i]);
        }
        UI::EndTooltip();    
    }
}

array<BruteforceEvaluation@> evaluations;
BruteforceEvaluation@ current;
BFEvaluationInfo info = BFEvaluationInfo();
float minSpeed = 0.0f;
int minCps = 0;
Trigger3D conditionTrigger;
bool hasConditionTrigger = false;
Trigger3D targetTrigger;
int restartIterations = 0;
string resultFolder = "";
int restartCount = 0;
Scripting::ConditionCallback@ standardCondition;
Scripting::ConditionCallback@ restartCondition;
string linesRestartCondition="#DUJ12E3F 4G5H6I7J8K9L0M";
string linesStandardCondition="416782R3021C7B 1467 1";

void BruteforceV2Settings(){
    UI::Dummy(vec2(0,15));
    UI::PushStyleColor(UI::Col::Header, vec4(1,0,0,0.3));
    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(1,0,0,0.4));
    UI::PushStyleColor(UI::Col::HeaderActive, vec4(1,0,0,0.5));
    UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,0.3));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(1,0,0,0.4));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(1,0,0,0.5));
    UI::PushStyleColor(UI::Col::PopupBg, vec4(0,0,0,0.8));
    UI::PushStyleColor(UI::Col::Border, vec4(1,0,0.2, 1));
    if(UI::CollapsingHeader("Behavior")){
        UI::Dummy(vec2(0,2));
        UI::PushItemWidth(300);
        UI::InputTextVar("Filename used for saving results", "bf_result_filename");

        toolTip(300, {
            "Use {i} in the filename if you enabled the auto restart. It will be replaced by the restart number when saving inputs. If not present, the filename will be prefixed with 'passX_' where X is the number of restarts done so far. Example:",
            "'best_run_{i}.txt' will produce files like 'best_run_1.txt', 'best_run_2.txt', etc. for every restart."
        });
        
        UI::Dummy(vec2(0,2));
        UI::InputIntVar("Iterations before restart", "bf_iterations_before_restart", 0);
        toolTip(300,{"After this many iterations, the bruteforce process will restart from the beginning, with the base run's inputs. This can help escape local minima. Set to 0 to disable restarts."});
        UI::Dummy(vec2(0,2));
        UI::InputTextVar("Result files folder", "bf_result_folder");
        toolTip(300,{"Folder where the result files will be saved. Leave empty to use the root folder. Example:",
            "'results' will save files in "+GetVariableString("scripts_folder")+"\\results\\"
        });
        UI::Dummy(vec2(0,2));
        string lines = GetVariableString("bf_restart_condition_script");
        int currentHeight = int(GetVariableDouble("bf_restart_condition_script_height"));
        string t;
        UI::PushItemWidth(245);
        if(UI::InputTextMultiline("##bf_restart_condition_script", lines, vec2(0, currentHeight))){
            SetVariable("bf_restart_condition_script", lines);
        }
        UI::SameLine();
        if(UI::Button("^")){
            if(currentHeight < 42) currentHeight = 42;
            SetVariable("bf_restart_condition_script_height", currentHeight - 17);
        }
        UI::SameLine();
        if(UI::Button("v")){
            SetVariable("bf_restart_condition_script_height", currentHeight + 17);
        }

        UI::SameLine();
        UI::Text("Condition script for restart");
        UI::PopItemWidth();
        
        if(lines != linesRestartCondition){
            linesRestartCondition = lines;
            Scripting::ConditionCallback@ callback = Scripting::CompileMulti(lines.Split("\n"));
            @restartCondition = @callback;
        }

        if(restartCondition is null){
            bool isEmpty = true;
            array<string> parts = lines.Split("\n");
            for(uint i=0; i<parts.Length; i++) {
                if(Scripting::CleanSource(parts[i]) != "") {
                    isEmpty = false;
                    break;
                }
            }
            if(!isEmpty){
                UI::PushStyleColor(UI::Col::Text, vec4(1,0,0,1));
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::PopStyleColor();
            } else {
                UI::TextDimmed("No restart condition set.");
            }
        }else{
            UI::TextDimmed("Script compiled successfully.");
        }
    }

    if(UI::CollapsingHeader("Optimization")){
        UI::Dummy(vec2(0, 2));
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
        UI::Dummy(vec2(0, 2));
    }

    if(UI::CollapsingHeader("Conditions")){
        UI::PushItemWidth(160);
        UI::Dummy(vec2(0, 2));
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
        UI::Dummy(vec2(0,2));

        if(int(GetVariableDouble("bf_condition_trigger")) > 0){
            UI::Text("Trigger");
        }else{
            UI::BeginDisabled();
            UI::Text("Trigger");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(48, 0));
        UI::SameLine();
        uint triggerIndex = uint(GetVariableDouble("bf_condition_trigger"));
        array<int>@ triggerIds = GetTriggerIds();

        if (triggerIndex > triggerIds.Length) triggerIndex = 0;

        string currentName = "None";
        if(triggerIndex > 0){
            Trigger3D selectedTrigger = GetTrigger(triggerIds[triggerIndex-1]);
            vec3 pos = selectedTrigger.Position;
            currentName = triggerIndex+". Position: ("+pos.x+", "+pos.y+", "+pos.z+")";
        }

        if(UI::BeginCombo("##bf_condition_trigger", currentName)){
            if(UI::Selectable("None", triggerIndex == 0)){
                SetVariable("bf_condition_trigger", 0);
            }
            for(uint i = 0; i < triggerIds.Length; i++){
                Trigger3D trigger = GetTrigger(triggerIds[i]);
                vec3 pos = trigger.Position;
                string triggerName = (i+1)+". Position: ("+pos.x+", "+pos.y+", "+pos.z+")";
                if(UI::Selectable(triggerName, triggerIndex == i+1)){
                    SetVariable("bf_condition_trigger", i+1);
                }
            }
            UI::EndCombo();
        }

        string lines = GetVariableString("bf_condition_script");
        int currentHeight = int(GetVariableDouble("bf_condition_script_height"));
        string t;
        UI::PushItemWidth(245);
        if(UI::InputTextMultiline("##bf_condition_script", lines, vec2(0, currentHeight))){
            SetVariable("bf_condition_script", lines);
        }
        UI::SameLine();
        if(UI::Button("^")){
            if(currentHeight < 42) currentHeight = 42;
            SetVariable("bf_condition_script_height", currentHeight - 17);
        }
        UI::SameLine();
        if(UI::Button("v")){
            SetVariable("bf_condition_script_height", currentHeight + 17);
        }
        UI::SameLine();
        UI::Text("Condition script");

        UI::PopItemWidth();

        if(lines != linesStandardCondition){
            linesStandardCondition = lines;
            Scripting::ConditionCallback@ callback = Scripting::CompileMulti(lines.Split("\n"));
            @standardCondition = @callback;
        }

        if(standardCondition is null){
            bool isEmpty = true;
            array<string> parts = lines.Split("\n");
            for(uint i=0; i<parts.Length; i++) {
                if(Scripting::CleanSource(parts[i]) != "") {
                    isEmpty = false;
                    break;
                }
            }
            if(!isEmpty){
                UI::PushStyleColor(UI::Col::Text, vec4(1,0,0,1));
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::PopStyleColor();
            } else {
                UI::TextDimmed("No conditions set.");
            }
        }else{
            UI::TextDimmed("Script compiled successfully.");
        }
        UI::Dummy(vec2(0,2));
    }
    
    if(UI::CollapsingHeader("Input Modification")){
        UI::PushItemWidth(300);
        UI::Dummy(vec2(0, 2));
        UI::InputIntVar("Input Modify Count", "bf_modify_count", 1);
        toolTip(300,
            {"At most " + int(GetVariableDouble("bf_modify_count")) + " inputs will be changed each attempt."});

        UI::Dummy(vec2(0,0));


        if(UI::BeginTable("##hack_for_the_tooltip_to_show_while_hovering_anything_of_the_below", 1)){
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
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
            UI::EndDisabled();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which inputs can be changed", "Limiting this time frame will make the bruteforcing process faster."});

        UI::Dummy(vec2(0,0));

        UI::PushItemWidth(300);
        int t = UI::SliderIntVar("Maximum Steering Difference", "bf_max_steer_diff", 0, 131072 );

        toolTip(300,{
            "Bruteforce will randomize a number between [-" + t + ", " + t
            + "] and add it to the current steering value."
        });

        UI::Dummy(vec2(0,2));


        int timediff = UI::InputTimeVar("Maximum Time Difference", "bf_max_time_diff");
        UI::PopItemWidth();

        toolTip(300,{
            "Bruteforce will randomize a number between [-" + timediff + ", " + timediff
            + "] milliseconds and add it to the current time value."
        });

        // --- Fill Missing Steering Input ---
        UI::CheckboxVar("Fill Missing Steering Input", "bf_inputs_fill_steer");
        toolTip(300, {
            "Timestamps with no steering input changes will be filled with existing values "
            "resulting in more values that can be changed."
        });
    }
    UI::PopStyleColor(8);
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
    RegisterVariable("bf_result_folder", "");
    RegisterVariable("bf_condition_script", "");
    RegisterVariable("bf_condition_script_height", 26);
    RegisterVariable("bf_restart_condition_script", "");
    RegisterVariable("bf_restart_condition_script_height", 26);
    RegisterVariable("bf_condition_trigger",0);
    PreciseFinishBf::Main();
    PreciseCheckpointBf::Main();
    PreciseTriggerBf::Main();
    SinglePointBf::Main();
    VelocityBf::Main();
    SkyBf::Main();
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

funcdef void OnSimulationBeginCallback(SimulationManager@ simManager);

enum CallbackType {
    Legacy,
    FullControl,
}

class BruteforceEvaluation {
    string identifier;
    string title;
    OnBruteforceEvaluate@ callback;
    RenderBruteforceEvaluationSettings@ renderCallback;
    CallbackType type = CallbackType::Legacy;
    OnSimulationBeginCallback@ onSimBegin = null;
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
    bool triggerCondition = !hasConditionTrigger || conditionTrigger.ContainsPoint(simManager.Dyna.CurrentState.Location.Position);
    return currentSpeed >= minSpeed && currentCps >= minCps && triggerCondition && (standardCondition is null || standardCondition(simManager));
}

SimulationState rewindState;
bool rewindStateAssigned = false;
array<int> CheckpointStates;
bool IsBfV2Active = false;
bool running = false;
array<string> restartInfos;
string ResultFileStartContent = "";

void OnSimulationBegin(SimulationManager@ simManager) {
    InputModification::cachedStartIndex = -1;
    IsBfV2Active = GetVariableString("controller")=="bfv2";
    if (!IsBfV2Active) return;
    
    @current = @GetBruteforceTarget();
    if (current is null) {
        SetVariable("bf_target", evaluations[0].identifier);
        @current = @evaluations[0];
    }

    simManager.RemoveStateValidation();

    info.Iterations = 0;
    info.Phase = BFPhase::Initial;
    info.Rewinded = false;
    forceStop = false;
    restartCount = 0;
    rewindStateAssigned = false;
    running = true;
    CheckpointStates=simManager.PlayerInfo.CheckpointStates; 
    restartInfos.Clear();

    InputModification::cachedStartIndex = -1;
    InputModification::cachedMinTime = -1;

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

    int triggerIndex = int(GetVariableDouble("bf_condition_trigger"));
    hasConditionTrigger = false;
    if(triggerIndex > 0){
        array<int>@ triggerIds = GetTriggerIds();
        if(triggerIndex <= int(triggerIds.Length)){
             conditionTrigger = GetTrigger(triggerIds[triggerIndex-1]);
             hasConditionTrigger = true;
        }
    }

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


void OnSimulationStep(SimulationManager@ simManager, bool userCancelled){
    if(!IsBfV2Active) return;
    if(forceStop || userCancelled) return;
    bool r1 = restartIterations > 0 && int(info.Iterations) >= restartIterations;
    bool r2 = restartCondition !is null && restartCondition(simManager);
    if (r1 || r2) {
        restartCount++;
        RestoreBestInputs(simManager);
        CommandList list();
        list.Content = simManager.InputEvents.ToCommandsText();
        
        string filename=GetVariableString("bf_result_filename");
        string fullpath="";
        if(resultFolder != ""){
            fullpath = resultFolder + "/";
        }

        int indexPos = filename.FindLast("{i}");
        if(indexPos != -1){
            filename.Erase(indexPos, 3);
            filename.Insert(indexPos, Text::FormatInt(restartCount));
        }else{
            filename="pass" + (restartCount)+"_"+filename;
        }
        fullpath += filename;
        list.Save(fullpath)?print("Saved command list to: " + fullpath):print("Failed to save command list to: " + fullpath);

        RestoreBaseInputs(simManager, false);
        SaveBestInputs(simManager, false); 

        print("Restarting Bruteforce for reasons: ");
        if(r1) print("- Reached max iterations before restart: " + restartIterations);
        if(r2) print("- Restart condition script returned true.");
        restartInfos.Add(ResultFileStartContent);
        ResultFileStartContent = "";
        print("Total restarts so far: " + restartCount);
        for(uint i = 0 ; i < restartInfos.Length; i++){
            print("- Restart N " + (i+1) + ": \"" + restartInfos[i] + "\"");
        }

        if(current.onSimBegin !is null) {
            current.onSimBegin(simManager);
        }

        info.Iterations = 0;
        info.Phase = BFPhase::Initial;
        info.Rewinded = false;

        simManager.RewindToState(rewindState);
        return;
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
            ResultFileStartContent = response.ResultFileStartContent;
            // print("Rewind due to no progress in time.");
            return;
        }
        info.Rewinded = false;
        if(info.Phase == BFPhase::Initial) {
            if(raceTime == minInputsTime-10 && !rewindStateAssigned){
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
                    ResultFileStartContent = response.ResultFileStartContent;
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
                ResultFileStartContent = response.ResultFileStartContent;
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
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result) {
    if (!IsBfV2Active) return;
    for(uint i = 0 ; i < restartInfos.Length; i++){
        print("- Restart N " + (i+1) + ": \"" + restartInfos[i] + "\"");
    }
    running = false;
}

namespace PreciseFinishBf {
    void RenderEvalSettings(){}
    
    double bestTime = -1;
    int bestTimeMsImprecise = -1;

    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        auto resp = BFEvaluationResponse();
        int raceTime = simManager.RaceTime;
        resp.Decision = BFEvaluationDecision::DoNothing;

        // Fast Rejection
        if (info.Phase == BFPhase::Search && !PreciseFinish::IsEstimating && bestTimeMsImprecise != -1) {
            if (raceTime > bestTimeMsImprecise + 50) {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
            
            if (simManager.PlayerInfo.RaceFinished && raceTime < bestTimeMsImprecise) {
                 if (GlobalConditionsMet(simManager)) {
                     resp.Decision = BFEvaluationDecision::Accept;
                 } else {
                     resp.Decision = BFEvaluationDecision::Reject;
                 }
                 PreciseFinish::Reset();
                 return resp;
            }
        }

        // Precise Computation
        double preciseTime;
        
        bool calculationFinished = PreciseFinish::Compute(simManager, simManager.PlayerInfo.RaceFinished, preciseTime);

        if (!calculationFinished) {
            return resp;
        }
       if (!GlobalConditionsMet(simManager)) {
            if (info.Phase == BFPhase::Initial) {
                print("Base run finished, but conditions not met. Search will require meeting these conditions.", Severity::Warning);    
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
        }

        if (info.Phase == BFPhase::Initial) {
            if(bestTime != -1 && preciseTime >= bestTime + 1e-7){
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }

            if(bestTime != -1) print("Precise finish time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            else print("Base run finish time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            
            bestTime = preciseTime;
            bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime; 
            
            resp.Decision = BFEvaluationDecision::Accept;
            resp.ResultFileStartContent = "# Precise Finish Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            PreciseFinish::Reset();

        } else {
            if (preciseTime < bestTime) {
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
                
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Precise Finish Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
            }
            PreciseFinish::Reset();
        }

        return resp;
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;
    }

    void Main() {
        auto bfEval = RegisterBruteforceEval("precisefinish", "Precise Finish Time", OnEvaluate, RenderEvalSettings);
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
            UI::Text("No triggers found.");
            return;
        }

        if (triggerIndex >= triggerIds.Length) triggerIndex = 0;

        Trigger3D selectedTrigger = GetTrigger(triggerIds[triggerIndex]);
        vec3 pos = selectedTrigger.Position;

        if(UI::BeginCombo("Trigger Index", (triggerIndex+1)+". Position: ("+pos.x+", "+pos.y+", "+pos.z+")")){
            for(uint i = 0; i < triggerIds.Length; i++){
                Trigger3D trigger = GetTrigger(triggerIds[i]);
                pos = trigger.Position;
                string triggerName = (i+1)+". Position: ("+pos.x+", "+pos.y+", "+pos.z+")";
                if(UI::Selectable(triggerName, triggerIndex == i)){
                    SetVariable("bf_target_trigger", i);
                }
            }
            UI::EndCombo();
        }
    }

    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();

        resp.Decision = BFEvaluationDecision::DoNothing;

        bool inTrigger = targetTrigger.ContainsPoint(simManager.Dyna.CurrentState.Location.Position);

        if (info.Phase == BFPhase::Search && !PreciseFinish::IsEstimating && bestTimeMsImprecise != -1) {

            if(inTrigger && raceTime < bestTimeMsImprecise){
                if (GlobalConditionsMet(simManager)) {
                    resp.Decision = BFEvaluationDecision::Accept;
                } else {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
                PreciseFinish::Reset();
                return resp;
            }

            if (raceTime > bestTimeMsImprecise + 50) {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
        }

        double preciseTime;

        bool calculationDone = PreciseFinish::Compute(simManager, inTrigger, preciseTime);

        if (!calculationDone) {
            return resp; 
        }

        if(!GlobalConditionsMet(simManager)) {
            if (info.Phase == BFPhase::Initial) {
                 print("Base run hit trigger but conditions not met. Search will require meeting these conditions.", Severity::Warning);
            } else {
                 resp.Decision = BFEvaluationDecision::Reject;
                 PreciseFinish::Reset();
                 return resp;
            }
        }

        if (info.Phase == BFPhase::Initial) {

            if(bestTime != -1 && preciseTime >= bestTime + 1e-7){
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }

            if(bestTime != -1) print("Precise trigger time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            else print("Base run trigger time: " + Text::FormatFloat(preciseTime, "", 0, 9));

            bestTime = preciseTime;
            bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime; 

            resp.Decision = BFEvaluationDecision::Accept;
            resp.ResultFileStartContent = "# Precise Trigger Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";

        } else {

            if(preciseTime < bestTime) {

                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;

                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Precise Trigger Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            } else {

                resp.Decision = BFEvaluationDecision::Reject;
            }
        }

        PreciseFinish::Reset();
        return resp;
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;

        int triggerIndex = int(GetVariableDouble("bf_target_trigger"));
        array<int>@ triggerIds = GetTriggerIds();

        if (triggerIds.Length > 0 && triggerIndex < int(triggerIds.Length)) {
            targetTrigger = GetTrigger(triggerIds[triggerIndex]);
        } else {
            print("Error: Invalid trigger index selected for bruteforce.", Severity::Error);
        }
    }

    void Main() {

        auto bfEval = RegisterBruteforceEval("precisetrigger", "Trigger", OnEvaluate, RenderEvalSettings);
        @bfEval.onSimBegin = @OnSimulationBegin;
    }
}
namespace PreciseCheckpointBf {
    int targetCp;
    double bestTime = -1;
    int bestTimeMsImprecise = -1;

    void RenderEvalSettings(){
        targetCp = UI::InputIntVar("Target Checkpoint Index", "bf_target_cp");
    }

    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();

        resp.Decision = BFEvaluationDecision::DoNothing;

        bool hasCp = int(simManager.PlayerInfo.CurCheckpointCount) >= targetCp;

        if (info.Phase == BFPhase::Search && !PreciseFinish::IsEstimating && bestTimeMsImprecise != -1) {

            if(hasCp && raceTime < bestTimeMsImprecise){
                if (GlobalConditionsMet(simManager)) {
                    resp.Decision = BFEvaluationDecision::Accept;
                } else {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
                PreciseFinish::Reset();
                return resp;
            }

            if (raceTime > bestTimeMsImprecise + 50) {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
        }

        double preciseTime;

        bool calculationDone = PreciseFinish::Compute(simManager, hasCp, preciseTime);

        if (!calculationDone) {
            return resp; 
        }

        if(!GlobalConditionsMet(simManager)) {
            if (info.Phase == BFPhase::Initial) {
                 print("Base run hit checkpoint but conditions not met. Search will require meeting these conditions.", Severity::Warning);
            } else {
                 resp.Decision = BFEvaluationDecision::Reject;
                 PreciseFinish::Reset();
                 return resp;
            }
        }

        if (info.Phase == BFPhase::Initial) {

            if(bestTime != -1 && preciseTime >= bestTime + 1e-7){
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }

            if(bestTime != -1) print("Precise checkpoint time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            else print("Base run checkpoint time: " + Text::FormatFloat(preciseTime, "", 0, 9));

            bestTime = preciseTime;
            bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime; 

            resp.Decision = BFEvaluationDecision::Accept;
            resp.ResultFileStartContent = "# Precise Checkpoint Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";

        } else {

            if(preciseTime < bestTime) {

                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;

                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Precise Checkpoint Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            } else {

                resp.Decision = BFEvaluationDecision::Reject;
            }
        }

        PreciseFinish::Reset();
        return resp;
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;
        targetCp = int(GetVariableDouble("bf_target_cp"));
    }

    void Main() {

        auto bfEval = RegisterBruteforceEval("precisecheckpoint", "Checkpoint", OnEvaluate, RenderEvalSettings);
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
        if(UI::BeginTable("##ratio_table", 1)){
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::PushItemWidth(300);
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
            UI::EndTable();
        }

        toolTip(300, {"The ratio slider determines which metric bruteforce should value more.\nSetting the slider fully to the left side (0%) will just optimize how close the vehicle gets to the point.\nSetting the slider fully to the right side (100%) will instead optimize vehicle speed without taking the point into account."});
        
        UI::Dummy(vec2(0, 2));
        if(GetVariableDouble("bf_weight")<=99){
            UI::Dummy(vec2(9, 0));
            UI::SameLine();
            UI::Text("Target position:");
            UI::SameLine();
            UI::DragFloat3Var("##bf_target_point", "bf_target_point", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if(GetSimulationManager().InRace){
                UI::Dummy(vec2(0, 5));
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
            UI::Dummy(vec2(0, 2));
        }
        if(UI::BeginTable("##time_table", 1)){
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
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
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which the distance and/or speed will be evaluated.", "Reducing the maximum evaluation time will make the bruteforcing process faster."});
        UI::Dummy(vec2(0, 0));


        UI::PushItemWidth(160);
        if(GetVariableDouble("bf_condition_distance") > 0.0f){
            UI::Text("Max. distance ");
        }else{
            UI::BeginDisabled();
            UI::Text("Max. distance ");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(-2, 0));
        UI::SameLine();
        UI::InputFloatVar("##bf_condition_distance", "bf_condition_distance");
        if(GetVariableDouble("bf_condition_distance") < 0.0f){
            SetVariable("bf_condition_distance", 0.0f);
        }

        UI::Dummy(vec2(0, 0));
        
        if(UI::BeginTable("##ignore_speed_table", 1)){
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
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
            UI::EndTable();
        }
        toolTip(300, {"Ignoring same speed improvements is particularly useful for bruteforcing air trajectories, where a different rotation but same speed would get rejected, despite the car being seemingly closer to target. This avoids flooding inputs and preventing real distance gains."});
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
                        resp.ResultFileStartContent = "# Base run: Invalid";
                    }else{
                        print("Base run: " + Text::FormatFloat(bestDist,"", 0, 9) + " m, " + Text::FormatFloat(bestSpeed*3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2));
                        resp.ResultFileStartContent = "# Base run: " + Text::FormatFloat(bestDist,"", 0, 9) + " m, " + Text::FormatFloat(bestSpeed*3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2);
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
                    resp.ResultFileStartContent = "# Base run: Invalid";
                }else{
                    print("Base run: " + Text::FormatFloat(bestSpeed, "", 0, 9) + " m/s at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2));
                    resp.ResultFileStartContent = "# Base run: " + Text::FormatFloat(bestSpeed, "", 0, 9) + " m/s at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2);
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

namespace InputModification {
    int cachedStartIndex = -1;
    int cachedMinTime = -1;

    void SortBufferManual(TM::InputEventBuffer@ buffer, int startIndex = -1) {
        if (buffer is null || buffer.Length < 2) return;

        uint startCopy = 0;
        if(startIndex != -1) {
            startCopy = startIndex + 1;
        }
        
        if(startCopy >= buffer.Length) return;

        array<TM::InputEvent> events;
        for(uint i = startCopy; i < buffer.Length; i++) {
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

        for(uint i = 0; i < events.Length; i++) {
            buffer[startCopy + i] = events[i];
        }
    }

    void MutateInputs(TM::InputEventBuffer@ buffer, int inputCount, int minTime, int maxTime, int maxSteerDiff, int maxTimeDiff, bool fillInputs){ // 100000 is the start of the events in the game's memory. 100010 is the first possible event. We substract those values for human readability.
        if (buffer is null) return;
        if (maxTime <= 0) return;

        if (fillInputs){
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if(buffer.Length != lenBefore) cachedStartIndex = -1;
        }

        if(minTime != cachedMinTime){
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }

        int actualInputCount = Math::Rand(1, inputCount);
        array<int> indices;
        
        uint start = 0;
        if(cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length)){
            start = cachedStartIndex;
        }

        for(uint i = start; i < buffer.Length; i++) {
            auto evt = buffer[i];
            
            if(int(evt.Time)-100010 < minTime) {
                cachedStartIndex = i;
                continue;
            }

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
        SortBufferManual(buffer, cachedStartIndex);
    }

    void FillInputs(TM::InputEventBuffer@ buffer, int maxTime, int minIndex)
    {
        if (buffer is null) return;
        if (maxTime <= 0) return;

        const int OFFSET = 100010;
        int absMaxTime = OFFSET + maxTime;

        auto indices = buffer.EventIndices;
        
        array<TM::InputEvent> steer;
        
        int startIndex = 0;
        int prevSteerState = 0;
        int prevSteerTime = -1;
        bool hasPrevSteer = true;

        if(minIndex > 0 && minIndex < int(buffer.Length)){
            startIndex = minIndex;
            for(int i = minIndex - 1; i >= 0; i--) {
                if(buffer[i].Value.EventIndex == indices.SteerId) {
                    prevSteerState = int(buffer[i].Value.Analog);
                    prevSteerTime = int(buffer[i].Time);
                    break;
                }
            }
        }

        for (uint i = startIndex; i < buffer.Length; i++) {
            auto evt = buffer[i];
            if (int(evt.Time) > absMaxTime) break;

            if (evt.Value.EventIndex == indices.SteerId) {
                steer.Add(evt);
            }
        }

        uint k = 0;
        const uint steerLen = steer.Length;

        int loopStartTime = 0;
        if (startIndex > 0 && startIndex < int(buffer.Length)) {
             loopStartTime = int(buffer[startIndex].Time) - OFFSET;
             loopStartTime = (loopStartTime / 10) * 10;
             if (loopStartTime < 0) loopStartTime = 0;
        }

        for (int t = loopStartTime; t <= maxTime; t += 10) {
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
    if(running) simManager.PreventSimulationFinish();
}


namespace Scripting
{
    // --- Helpers ---
    
    bool StartsWith(const string &in str, const string &in prefix) {
        if (str.Length < prefix.Length) return false;
        return str.Substr(0, prefix.Length) == prefix;
    }

    bool EndsWith(const string &in str, const string &in suffix) {
        if (str.Length < suffix.Length) return false;
        return str.Substr(str.Length - suffix.Length) == suffix;
    }

    string ToLower(const string &in input) {
        string output = input; 
        for(uint i = 0; i < output.Length; i++) {
            uint8 c = output[i];
            if (c >= 65 && c <= 90) output[i] = c + 32;
        }
        return output;
    }

    // --- Delegates ---
    funcdef bool ConditionCallback(SimulationManager@ sim);
    funcdef float FloatGetter(SimulationManager@ sim);
    funcdef vec3 Vec3Getter(SimulationManager@ sim);

    // --- Data Getters (Leaf Nodes) ---

    float GetCarX(SimulationManager@ sim) { return sim.Dyna.CurrentState.Location.Position.x; }
    float GetCarY(SimulationManager@ sim) { return sim.Dyna.CurrentState.Location.Position.y; }
    float GetCarZ(SimulationManager@ sim) { return sim.Dyna.CurrentState.Location.Position.z; }
    float GetCarVelX(SimulationManager@ sim) { return sim.Dyna.CurrentState.LinearSpeed.x; }
    float GetCarVelY(SimulationManager@ sim) { return sim.Dyna.CurrentState.LinearSpeed.y; }
    float GetCarVelZ(SimulationManager@ sim) { return sim.Dyna.CurrentState.LinearSpeed.z; }
    float GetCarSpeed(SimulationManager@ sim) { return sim.Dyna.CurrentState.LinearSpeed.Length(); }
    
    vec3 GetCarPos(SimulationManager@ sim) { return sim.Dyna.CurrentState.Location.Position; }
    vec3 GetCarVel(SimulationManager@ sim) { return sim.Dyna.CurrentState.LinearSpeed; }

    class ConstantFloat {
        float val;
        ConstantFloat(float v) { val = v; }
        float Get(SimulationManager@ sim) { return val; }
    }

    class ConstantVec3 {
        vec3 val;
        ConstantVec3(vec3 v) { val = v; }
        vec3 Get(SimulationManager@ sim) { return val; }
    }

    class VarFloat {
        string name;
        VarFloat(const string &in n) { name = n; }
        float Get(SimulationManager@ sim) { return float(GetVariableDouble(name)); }
    }

    class VarVec3 {
        string name;
        VarVec3(const string &in n) { name = n; }
        vec3 Get(SimulationManager@ sim) { return Text::ParseVec3(GetVariableString(name)); }
    }

    // --- Operations ---

    class MathOp {
        FloatGetter@ left;
        FloatGetter@ right;
        string op; 

        MathOp(FloatGetter@ l, FloatGetter@ r, const string &in o) {
            @left = l; @right = r; op = o;
        }

        float Get(SimulationManager@ sim) {
            float l = left(sim);
            float r = right(sim);
            if (op == "+") return l + r;
            if (op == "-") return l - r;
            if (op == "*") return l * r;
            if (op == "/") return r != 0.0f ? l / r : 0.0f;
            return 0.0f;
        }
    }

    class FunctionKmh {
        FloatGetter@ arg;
        FunctionKmh(FloatGetter@ a) { @arg = a; }
        float Get(SimulationManager@ sim) { return arg(sim) * 3.6f; }
    }

    class FunctionDistance {
        Vec3Getter@ p1;
        Vec3Getter@ p2;
        FunctionDistance(Vec3Getter@ a, Vec3Getter@ b) { @p1 = a; @p2 = b; }
        float Get(SimulationManager@ sim) { return Math::Distance(p1(sim), p2(sim)); }
    }

    enum CmpOp { Gt, Lt, GtEq, LtEq, Eq }

    class Comparison {
        FloatGetter@ left;
        FloatGetter@ right;
        CmpOp op;

        Comparison(FloatGetter@ l, FloatGetter@ r, CmpOp o) {
            @left = l; @right = r; op = o;
        }

        bool Evaluate(SimulationManager@ sim) {
            float l = left(sim);
            float r = right(sim);
            switch(op) {
                case CmpOp::Gt:   return l > r;
                case CmpOp::Lt:   return l < r;
                case CmpOp::GtEq: return l >= r;
                case CmpOp::LtEq: return l <= r;
                case CmpOp::Eq:   return l == r;
            }
            return false;
        }
    }

    // --- Parser ---

    string CleanSource(const string &in input) {
        string output = "";
        string temp = " ";
        bool insideQuote = false;
        for(uint i = 0; i < input.Length; i++) {
            uint8 c = input[i];
            if (c == 34) insideQuote = !insideQuote; 
            if (insideQuote || c != 32) {
                temp[0] = c;
                output += temp;
            }
        }
        return output;
    }

    int FindTopLevel(const string &in code, const string &in target, int start = 0) {
        int depth = 0;
        int targetLen = target.Length;
        for(uint i = start; i < code.Length; i++) {
            uint8 c = code[i];
            if (c == 40) depth++; 
            else if (c == 41) depth--;
            else if (depth == 0) {
                if (code.Substr(i, targetLen) == target) return i;
            }
        }
        return -1;
    }

    ConditionCallback@ Compile(const string &in source) {
        string code = CleanSource(source);
        if (code == "") return null;

        CmpOp op;
        int idx = -1;
        int len = 1;

        if ((idx = FindTopLevel(code, ">=")) != -1) { op = CmpOp::GtEq; len = 2; }
        else if ((idx = FindTopLevel(code, "<=")) != -1) { op = CmpOp::LtEq; len = 2; }
        else if ((idx = FindTopLevel(code, ">")) != -1)  { op = CmpOp::Gt; }
        else if ((idx = FindTopLevel(code, "<")) != -1)  { op = CmpOp::Lt; }
        else if ((idx = FindTopLevel(code, "=")) != -1)  { op = CmpOp::Eq; }

        if (idx == -1) {
            // print("Script Error: No comparison operator in '" + source + "'");
            return null;
        }

        string lhs = code.Substr(0, idx);
        string rhs = code.Substr(idx + len);

        FloatGetter@ leftGetter = ParseExpression(lhs);
        FloatGetter@ rightGetter = ParseExpression(rhs);

        if (leftGetter is null || rightGetter is null) return null;

        Comparison@ comp = Comparison(leftGetter, rightGetter, op);
        return ConditionCallback(comp.Evaluate);
    }

    class MultiCondition {
        array<ConditionCallback@> conditions;

        void Add(ConditionCallback@ cb) {
            conditions.Add(cb);
        }

        bool Evaluate(SimulationManager@ sim) {
            for(uint i = 0; i < conditions.Length; i++) {
                if(!conditions[i](sim)) return false;
            }
            return true;
        }
    }

    ConditionCallback@ CompileMulti(const array<string> &in sources) {
        MultiCondition@ multi = MultiCondition();
        for(uint i = 0; i < sources.Length; i++) {
            string s = sources[i];
            if (CleanSource(s) == "") continue;
            
            ConditionCallback@ cb = Compile(s);
            if (cb is null) return null;
            multi.Add(cb);
        }
        if (multi.conditions.Length == 0) return null;
        return ConditionCallback(multi.Evaluate);
    }

    FloatGetter@ ParseExpression(const string &in code) {
        int idx = -1;
        string opStr = "";
        int depth = 0;

        // Reverse search for + or -
        for(int i = int(code.Length) - 1; i >= 0; i--) {
            if(code[i] == 41) depth++;
            else if(code[i] == 40) depth--;
            else if(depth == 0) {
                if(code[i] == 43) { idx = i; opStr = "+"; break; }
                if(code[i] == 45 && i > 0) { idx = i; opStr = "-"; break; }
            }
        }

        if (idx != -1) {
            FloatGetter@ left = ParseExpression(code.Substr(0, idx));
            FloatGetter@ right = ParseTerm(code.Substr(idx + 1));
            if (left is null || right is null) return null;
            MathOp@ math = MathOp(left, right, opStr);
            return FloatGetter(math.Get);
        }
        return ParseTerm(code);
    }

    FloatGetter@ ParseTerm(const string &in code) {
        int idx = -1;
        string opStr = "";
        int depth = 0;
        
        for(int i = int(code.Length) - 1; i >= 0; i--) {
            if(code[i] == 41) depth++;
            else if(code[i] == 40) depth--;
            else if(depth == 0) {
                if(code[i] == 42) { idx = i; opStr = "*"; break; }
                if(code[i] == 47) { idx = i; opStr = "/"; break; }
            }
        }

        if (idx != -1) {
            FloatGetter@ left = ParseTerm(code.Substr(0, idx));
            FloatGetter@ right = ParseFactor(code.Substr(idx + 1));
            if (left is null || right is null) return null;
            MathOp@ math = MathOp(left, right, opStr);
            return FloatGetter(math.Get);
        }
        return ParseFactor(code);
    }

    FloatGetter@ ParseFactor(const string &in input) {
        string t = input;
        string lower = ToLower(t);

        if (StartsWith(t, "(") && EndsWith(t, ")")) {
            return ParseExpression(t.Substr(1, t.Length - 2));
        }

        if (StartsWith(lower, "kmh(") && EndsWith(t, ")")) {
            string argStr = t.Substr(4, t.Length - 5);
            FloatGetter@ arg = ParseExpression(argStr);
            if (arg is null) return null;
            FunctionKmh@ fn = FunctionKmh(arg);
            return FloatGetter(fn.Get);
        }

        if (StartsWith(lower, "distance(") && EndsWith(t, ")")) {
            string content = t.Substr(9, t.Length - 10);
            int commaIdx = FindTopLevel(content, ",");
            if (commaIdx == -1) return null;

            string arg1 = content.Substr(0, commaIdx);
            string arg2 = content.Substr(commaIdx + 1);

            Vec3Getter@ v1 = ParseVec3(arg1);
            Vec3Getter@ v2 = ParseVec3(arg2);
            if (v1 is null || v2 is null) return null;
            FunctionDistance@ fn = FunctionDistance(v1, v2);
            return FloatGetter(fn.Get);
        }

        if (StartsWith(lower, "variable(") && EndsWith(t, ")")) {
            string content = t.Substr(9, t.Length - 10); 
            if (StartsWith(content, "\"") && EndsWith(content, "\"")) {
                content = content.Substr(1, content.Length - 2);
            }
            VarFloat@ v = VarFloat(content);
            return FloatGetter(v.Get);
        }

        if (lower == "car.position.x" || lower == "car.x") return GetCarX;
        if (lower == "car.position.y" || lower == "car.y") return GetCarY;
        if (lower == "car.position.z" || lower == "car.z") return GetCarZ;
        if (lower == "car.velocity.x" || lower == "car.vel.x") return GetCarVelX;
        if (lower == "car.velocity.y" || lower == "car.vel.y") return GetCarVelY;
        if (lower == "car.velocity.z" || lower == "car.vel.z") return GetCarVelZ;
        if (lower == "car.speed") return GetCarSpeed;

        if (lower.Length > 0 && lower.FindFirstNotOf("0123456789.-") == -1) {
            ConstantFloat@ c = ConstantFloat(Text::ParseFloat(lower));
            return FloatGetter(c.Get);
        }

        // print("Script Error: Unknown float term '" + t + "'");
        return null;
    }

    Vec3Getter@ ParseVec3(const string &in input) {
        string t = input;
        string lower = ToLower(t);

        if (StartsWith(t, "(") && EndsWith(t, ")")) {
            string content = t.Substr(1, t.Length - 2);
            array<string> parts = content.Split(",");
            if (parts.Length == 3) {
                vec3 v(Text::ParseFloat(parts[0]), Text::ParseFloat(parts[1]), Text::ParseFloat(parts[2]));
                ConstantVec3@ c = ConstantVec3(v);
                return Vec3Getter(c.Get);
            }
        }

        if (StartsWith(lower, "variable(") && EndsWith(t, ")")) {
            string content = t.Substr(9, t.Length - 10); 
            if (StartsWith(content, "\"") && EndsWith(content, "\"")) {
                content = content.Substr(1, content.Length - 2);
            }
            VarVec3@ v = VarVec3(content);
            return Vec3Getter(v.Get);
        }

        if (lower == "car.position" || lower == "car.pos") return GetCarPos;
        if (lower == "car.velocity" || lower == "car.vel") return GetCarVel;

        // print("Script Error: Unknown vec3 term '" + t + "'");
        return null;
    }
}

namespace SkyBf {
    Polyhedron g_finishPoly;
    Polyhedron g_roadCheckpointPoly;
    Polyhedron g_roadCheckpointUpPoly;
    Polyhedron g_roadCheckpointDownPoly;
    Polyhedron g_roadCheckpointLeftPoly;
    Polyhedron g_roadCheckpointRightPoly;
    Polyhedron g_platformCheckpointPoly;
    Polyhedron g_platformCheckpointUpPoly;
    Polyhedron g_platformCheckpointDownPoly;
    Polyhedron g_platformCheckpointLeftPoly;
    Polyhedron g_platformCheckpointRightPoly;
    Polyhedron g_roadDirtHighCheckpointPoly;
    Polyhedron g_roadDirtCheckpointPoly;
    Polyhedron g_grassCheckpointPoly;
    Polyhedron g_ringHCheckpointPoly;
    Polyhedron g_ringVCheckpointPoly;
    dictionary g_triggerPolyhedrons;
    void InitializeTriggerData() {
        g_finishPoly = Polyhedron(
            {vec3(3.0, 1.0, 12.205891), vec3(3.0, 1.0, 11.79281), vec3(30.0, 1.0, 11.79281), vec3(30.0, 1.0, 12.205891), vec3(30.0, 1.9485588, 12.205891), vec3(26.664326, 5.083612, 12.205891), vec3(19.401665, 7.814228, 12.205891), vec3(12.598329, 7.814228, 12.205891), vec3(5.325968, 5.0799665, 12.205891), vec3(3.0, 2.889081, 12.205891), vec3(30.0, 1.9485588, 11.79281), vec3(3.0, 2.889081, 11.792811), vec3(5.325968, 5.0799665, 11.79281), vec3(12.598328, 7.814228, 11.79281), vec3(19.401665, 7.814228, 11.79281), vec3(26.664326, 5.083612, 11.79281)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_roadCheckpointPoly = Polyhedron(
            {vec3(3.0, 1.0, 16.20654), vec3(3.0, 1.0, 15.793459), vec3(30.0, 1.0, 15.793459), vec3(30.0, 1.0, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(3.0, 2.8890808, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(3.0, 2.8890808, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_roadCheckpointUpPoly = Polyhedron(
            {vec3(3.0, 5.305454, 16.20654), vec3(3.0, 5.205257, 15.79346), vec3(30.0, 5.205257, 15.793459), vec3(30.0, 5.305454, 16.20654), vec3(30.0, 6.0024333, 16.20654), vec3(26.664326, 9.137486, 16.20654), vec3(19.401665, 11.868102, 16.20654), vec3(12.598328, 11.868102, 16.20654), vec3(5.325968, 9.133841, 16.20654), vec3(3.0, 6.942955, 16.20654), vec3(30.0, 5.9022365, 15.793459), vec3(3.0, 6.842759, 15.79346), vec3(5.325968, 9.033645, 15.79346), vec3(12.598328, 11.767906, 15.79346), vec3(19.401665, 11.767906, 15.793459), vec3(26.664326, 9.03729, 15.793459)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_roadCheckpointDownPoly = Polyhedron(
            {vec3(29.133787, 5.305454, 15.793457), vec3(29.133787, 5.205257, 16.206537), vec3(2.1337872, 5.205257, 16.206541), vec3(2.1337872, 5.305454, 15.793461), vec3(2.1337872, 6.0024333, 15.793461), vec3(5.4694614, 9.137486, 15.793461), vec3(12.732122, 11.868102, 15.793459), vec3(19.53546, 11.868102, 15.793458), vec3(26.80782, 9.133841, 15.793457), vec3(29.133787, 6.942955, 15.793457), vec3(2.1337872, 5.9022365, 16.206541), vec3(29.133787, 6.842759, 16.206537), vec3(26.80782, 9.033645, 16.206537), vec3(19.53546, 11.767906, 16.206537), vec3(12.732122, 11.767906, 16.20654), vec3(5.4694605, 9.03729, 16.206541)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_roadCheckpointLeftPoly = Polyhedron(
            {vec3(3.0, 8.565392, 16.20654), vec3(3.0, 8.565392, 15.793459), vec3(30.0, 1.7613418, 15.793459), vec3(30.0, 1.7613418, 16.20654), vec3(30.0, 2.7099004, 16.20654), vec3(26.664326, 6.6855497, 16.20654), vec3(19.401665, 11.24637, 16.20654), vec3(12.598328, 12.960824, 16.20654), vec3(5.325968, 12.05921, 16.20654), vec3(3.0, 10.454473, 16.20654), vec3(30.0, 2.7099004, 15.793459), vec3(3.0, 10.454473, 15.793459), vec3(5.325968, 12.05921, 15.793459), vec3(12.598328, 12.960824, 15.793459), vec3(19.401665, 11.24637, 15.793459), vec3(26.664326, 6.6855497, 15.793459)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_roadCheckpointRightPoly = Polyhedron(
            {vec3(29.0, 8.512752, 16.20654), vec3(2.0, 1.7087021, 16.20654), vec3(2.0, 1.7087021, 15.793459), vec3(29.0, 8.512752, 15.793458), vec3(26.674032, 12.00657, 16.206537), vec3(19.401672, 12.908184, 16.206537), vec3(12.598335, 11.19373, 16.206537), vec3(29.0, 10.401833, 16.20654), vec3(5.3356743, 6.6329103, 16.20654), vec3(2.0, 2.657261, 16.20654), vec3(2.0, 2.657261, 15.793459), vec3(5.3356743, 6.6329103, 15.793458), vec3(12.598335, 11.19373, 15.793458), vec3(19.401672, 12.908184, 15.793458), vec3(26.674032, 12.00657, 15.793458), vec3(29.0, 10.401833, 15.793458)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {7,4,6}, {6,8,9}, {6,9,1}, {7,6,1}, {0,7,1}, {2,1,9}, {9,10,2}, {10,11,12}, {12,13,14}, {14,15,3}, {12,14,3}, {10,12,3}, {2,10,3}, {0,3,15}, {15,7,0}, {6,5,13}, {13,12,6}, {8,6,12}, {12,11,8}, {14,13,5}, {5,4,14}, {15,14,4}, {4,7,15}, {9,8,11}, {11,10,9}}
        );
        g_platformCheckpointPoly = Polyhedron(
            {vec3(30.179214, 7.9320526, 16.09842), vec3(28.640587, 9.741932, 16.09842), vec3(26.304703, 11.035336, 16.09842), vec3(22.725918, 12.514831, 16.09842), vec3(18.33589, 13.464806, 16.09842), vec3(13.664118, 13.464806, 16.09842), vec3(9.274088, 12.514832, 16.09842), vec3(5.695303, 11.035337, 16.09842), vec3(3.359416, 9.741935, 16.09842), vec3(1.8207855, 7.9320536, 16.09842), vec3(3.359416, 9.741935, 15.658419), vec3(1.8207855, 7.9320545, 15.658419), vec3(5.695303, 11.035337, 15.658419), vec3(9.274088, 12.514832, 15.658419), vec3(13.664118, 13.464806, 15.658419), vec3(18.33589, 13.464806, 15.658419), vec3(22.725918, 12.51483, 15.658419), vec3(26.304703, 11.035336, 15.658419), vec3(28.640587, 9.741932, 15.658419), vec3(30.179214, 7.9320536, 15.658419)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
        );
        g_platformCheckpointUpPoly = Polyhedron(
            {vec3(30.179218, 15.981263, 16.09842), vec3(28.64059, 17.791142, 16.09842), vec3(26.304707, 19.084545, 16.09842), vec3(22.725922, 20.56404, 16.09842), vec3(18.33589, 21.514013, 16.098421), vec3(13.664118, 21.514013, 16.098421), vec3(9.274088, 20.564041, 16.098421), vec3(5.695304, 19.084547, 16.09842), vec3(3.359417, 17.791147, 16.09842), vec3(1.8207862, 15.981263, 16.09842), vec3(3.3594167, 17.571144, 15.658419), vec3(1.8207862, 15.761264, 15.658419), vec3(5.695303, 18.864546, 15.658415), vec3(9.274088, 20.34404, 15.658419), vec3(13.664118, 21.294012, 15.658419), vec3(18.33589, 21.294014, 15.658419), vec3(22.725918, 20.344038, 15.658417), vec3(26.304703, 18.864544, 15.658417), vec3(28.640587, 17.571142, 15.658417), vec3(30.179214, 15.761261, 15.658419)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
        );
        g_platformCheckpointDownPoly = Polyhedron(
            {vec3(30.179218, 15.882843, 16.09842), vec3(28.64059, 17.692722, 16.09842), vec3(26.304707, 18.986124, 16.09842), vec3(22.725922, 20.465622, 16.09842), vec3(18.33589, 21.415592, 16.098421), vec3(13.664118, 21.415594, 16.098421), vec3(9.274087, 20.465622, 16.098421), vec3(5.6953034, 18.986126, 16.09842), vec3(3.3594165, 17.692722, 16.09842), vec3(1.8207858, 15.882844, 16.09842), vec3(3.3594162, 17.912724, 15.658421), vec3(1.8207858, 16.102846, 15.658419), vec3(5.695303, 19.206125, 15.658421), vec3(9.274087, 20.68562, 15.658421), vec3(13.664118, 21.635593, 15.658421), vec3(18.33589, 21.635593, 15.658421), vec3(22.725918, 20.68562, 15.658421), vec3(26.304703, 19.206125, 15.658421), vec3(28.640587, 17.912722, 15.658421), vec3(30.179214, 16.102844, 15.658422)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
        );
        g_platformCheckpointLeftPoly = Polyhedron(
            {vec3(30.179218, 8.842444, 16.09842), vec3(28.64059, 11.421638, 16.09842), vec3(26.304707, 13.882984, 16.09842), vec3(22.725922, 17.15187, 16.09842), vec3(18.33589, 20.29686, 16.098423), vec3(13.664118, 22.632746, 16.098423), vec3(9.274087, 23.877789, 16.098421), vec3(5.6953034, 24.187687, 16.098421), vec3(3.3594165, 24.062225, 16.09842), vec3(1.8207858, 23.02166, 16.09842), vec3(3.3594162, 24.062225, 15.658421), vec3(1.8207858, 23.021664, 15.658422), vec3(5.695303, 24.187685, 15.658421), vec3(9.274087, 23.877785, 15.658422), vec3(13.664118, 22.632746, 15.658422), vec3(18.33589, 20.29686, 15.658422), vec3(22.725918, 17.151869, 15.658421), vec3(26.304703, 13.882983, 15.658421), vec3(28.640587, 11.421638, 15.658421), vec3(30.179214, 8.842445, 15.658422)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
        );
        g_platformCheckpointRightPoly = Polyhedron(
            {vec3(30.179218, 23.02166, 16.09842), vec3(28.64059, 24.062227, 16.09842), vec3(26.304707, 24.187685, 16.09842), vec3(22.725922, 23.877789, 16.09842), vec3(18.33589, 22.632751, 16.098421), vec3(13.664118, 20.296865, 16.098421), vec3(9.274087, 17.151875, 16.098421), vec3(5.6953034, 13.882988, 16.09842), vec3(3.3594165, 11.421643, 16.09842), vec3(1.8207858, 8.842446, 16.09842), vec3(3.3594162, 11.421643, 15.658421), vec3(1.8207858, 8.842446, 15.658419), vec3(5.695303, 13.882988, 15.658421), vec3(9.274087, 17.151875, 15.658421), vec3(13.664118, 20.296864, 15.658421), vec3(18.33589, 22.63275, 15.658421), vec3(22.725918, 23.877785, 15.658421), vec3(26.304703, 24.187685, 15.658421), vec3(28.640587, 24.062225, 15.658421), vec3(30.179214, 23.02166, 15.658422)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
        );
        g_roadDirtHighCheckpointPoly = Polyhedron(
            {vec3(3.7928343, -0.09202623, 16.20654), vec3(3.7928343, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 16.20654), vec3(28.268883, 1.1523709, 16.20654), vec3(25.85778, 3.959106, 16.20654), vec3(19.401665, 7.2270656, 16.20654), vec3(12.598328, 7.2270656, 16.20654), vec3(6.1362143, 3.8242507, 16.20654), vec3(3.7928343, 1.1458168, 16.20654), vec3(28.268883, 1.1523709, 15.793459), vec3(3.7928343, 1.1458168, 15.793459), vec3(6.1362143, 3.8242507, 15.793459), vec3(12.598328, 7.2270656, 15.793459), vec3(19.401665, 7.2270656, 15.793459), vec3(25.85778, 3.959106, 15.793459)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_roadDirtCheckpointPoly = Polyhedron(
            {vec3(2.063568, -1.1490858, 16.20654), vec3(2.063568, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 16.20654), vec3(30.0, 3.4846723, 16.20654), vec3(26.664326, 6.291407, 16.20654), vec3(19.401665, 8.890814, 16.20654), vec3(12.598328, 8.890814, 16.20654), vec3(5.325968, 6.156552, 16.20654), vec3(2.063568, 3.478118, 16.20654), vec3(30.0, 3.4846723, 15.793459), vec3(2.063568, 3.478118, 15.793459), vec3(5.325968, 6.156552, 15.793459), vec3(12.598328, 8.890814, 15.793459), vec3(19.401665, 8.890814, 15.793459), vec3(26.664326, 6.291407, 15.793459)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_grassCheckpointPoly = Polyhedron(
            {vec3(3.0, -0.32810664, 16.20654), vec3(3.0, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(2.2881927, 1.4034786, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(2.2881927, 1.4034786, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)},
            {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
        );
        g_ringHCheckpointPoly = Polyhedron(
            {vec3(26.156471, 3.7799995, 24.192066), vec3(22.629168, 3.7799993, 27.151827), vec3(18.302288, 3.779999, 28.726685), vec3(13.69772, 3.779999, 28.726685), vec3(9.370839, 3.7799993, 27.15183), vec3(5.843534, 3.7799995, 24.192072), vec3(3.541249, 3.7799997, 20.2044), vec3(2.7416735, 3.7800002, 15.669784), vec3(3.5412476, 3.7800007, 11.135169), vec3(5.843531, 3.780001, 7.147495), vec3(9.370835, 3.7800012, 4.187733), vec3(13.697715, 3.7800014, 2.6128778), vec3(18.302284, 3.7800014, 2.6128778), vec3(22.629164, 3.7800012, 4.187733), vec3(26.156467, 3.780001, 7.147493), vec3(28.458754, 3.7800007, 11.135166), vec3(29.258327, 3.7800002, 15.669782), vec3(28.458754, 3.7799997, 20.204391), vec3(28.458754, 4.2200007, 11.135166), vec3(29.258327, 4.2200003, 15.669782), vec3(26.156467, 4.2200007, 7.147493), vec3(22.629164, 4.220001, 4.187733), vec3(18.302284, 4.220001, 2.612878), vec3(13.697715, 4.220001, 2.6128778), vec3(9.370835, 4.220001, 4.187733), vec3(5.843531, 4.2200007, 7.147495), vec3(3.5412476, 4.2200007, 11.135169), vec3(2.7416735, 4.2200003, 15.669784), vec3(3.541249, 4.22, 20.2044), vec3(5.843534, 4.2199993, 24.192074), vec3(9.370839, 4.2199993, 27.151833), vec3(13.69772, 4.219999, 28.726686), vec3(18.302288, 4.219999, 28.726685), vec3(22.629168, 4.2199993, 27.151829), vec3(26.156471, 4.2199993, 24.192068), vec3(28.458754, 4.22, 20.204393)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {2,4,6}, {6,7,8}, {8,9,10}, {6,8,10}, {10,11,12}, {12,13,14}, {10,12,14}, {6,10,14}, {2,6,14}, {14,15,16}, {2,14,16}, {0,2,16}, {17,0,16}, {16,15,18}, {18,19,16}, {15,14,20}, {20,18,15}, {14,13,21}, {21,20,14}, {13,12,22}, {22,21,13}, {12,11,23}, {23,22,12}, {11,10,24}, {24,23,11}, {10,9,25}, {25,24,10}, {9,8,26}, {26,25,9}, {8,7,27}, {27,26,8}, {7,6,28}, {28,27,7}, {6,5,29}, {29,28,6}, {5,4,30}, {30,29,5}, {4,3,31}, {31,30,4}, {3,2,32}, {32,31,3}, {2,1,33}, {33,32,2}, {1,0,34}, {34,33,1}, {0,17,35}, {35,34,0}, {17,16,19}, {19,35,17}, {19,18,20}, {20,21,22}, {22,23,24}, {20,22,24}, {24,25,26}, {26,27,28}, {24,26,28}, {28,29,30}, {30,31,32}, {28,30,32}, {24,28,32}, {20,24,32}, {32,33,34}, {20,32,34}, {19,20,34}, {35,19,34}}
        );
        g_ringVCheckpointPoly = Polyhedron(
            {vec3(26.156471, 24.522285, 16.09842), vec3(22.629168, 27.482046, 16.09842), vec3(18.302288, 29.056904, 16.09842), vec3(13.697719, 29.056904, 16.09842), vec3(9.370839, 27.48205, 16.09842), vec3(5.8435335, 24.522291, 16.09842), vec3(3.5412483, 20.534618, 16.09842), vec3(2.7416725, 16.000002, 16.09842), vec3(3.5412464, 11.465387, 16.09842), vec3(5.8435307, 7.4777126, 16.09842), vec3(9.370834, 4.517952, 16.09842), vec3(13.697714, 2.9430962, 16.09842), vec3(18.302284, 2.9430962, 16.09842), vec3(22.629164, 4.517951, 16.09842), vec3(26.156467, 7.4777107, 16.09842), vec3(28.458752, 11.4653845, 16.09842), vec3(29.258327, 16.0, 16.09842), vec3(28.458754, 20.53461, 16.09842), vec3(28.458752, 11.4653845, 15.658419), vec3(29.258327, 16.0, 15.658419), vec3(26.156467, 7.4777107, 15.658419), vec3(22.629164, 4.517951, 15.658419), vec3(18.302284, 2.9430962, 15.658419), vec3(13.697714, 2.9430962, 15.658419), vec3(9.370834, 4.517952, 15.658419), vec3(5.8435307, 7.4777126, 15.658419), vec3(3.5412464, 11.465387, 15.658419), vec3(2.7416725, 16.000002, 15.658419), vec3(3.5412483, 20.534618, 15.65842), vec3(5.8435335, 24.522291, 15.65842), vec3(9.370839, 27.48205, 15.65842), vec3(13.697719, 29.056904, 15.65842), vec3(18.302288, 29.056904, 15.65842), vec3(22.629168, 27.482046, 15.65842), vec3(26.156471, 24.522285, 15.65842), vec3(28.458754, 20.53461, 15.65842)},
            {{0,1,2}, {2,3,4}, {4,5,6}, {2,4,6}, {6,7,8}, {8,9,10}, {6,8,10}, {10,11,12}, {12,13,14}, {10,12,14}, {6,10,14}, {2,6,14}, {14,15,16}, {2,14,16}, {0,2,16}, {17,0,16}, {16,15,18}, {18,19,16}, {15,14,20}, {20,18,15}, {14,13,21}, {21,20,14}, {13,12,22}, {22,21,13}, {12,11,23}, {23,22,12}, {11,10,24}, {24,23,11}, {10,9,25}, {25,24,10}, {9,8,26}, {26,25,9}, {8,7,27}, {27,26,8}, {7,6,28}, {28,27,7}, {6,5,29}, {29,28,6}, {5,4,30}, {30,29,5}, {4,3,31}, {31,30,4}, {3,2,32}, {32,31,3}, {2,1,33}, {33,32,2}, {1,0,34}, {34,33,1}, {0,17,35}, {35,34,0}, {17,16,19}, {19,35,17}, {19,18,20}, {20,21,22}, {22,23,24}, {20,22,24}, {24,25,26}, {26,27,28}, {24,26,28}, {28,29,30}, {30,31,32}, {28,30,32}, {24,28,32}, {20,24,32}, {32,33,34}, {20,32,34}, {19,20,34}, {35,19,34}}
        );
        g_triggerPolyhedrons["StadiumRoadMainCheckpoint"] = @g_roadCheckpointPoly;
        g_triggerPolyhedrons["StadiumGrassCheckpoint"] = @g_grassCheckpointPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointUp"] = @g_roadCheckpointUpPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointDown"] = @g_roadCheckpointDownPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointLeft"] = @g_roadCheckpointLeftPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointRight"] = @g_roadCheckpointRightPoly;
        g_triggerPolyhedrons["StadiumCheckpointRingV"] = @g_ringVCheckpointPoly;
        g_triggerPolyhedrons["StadiumCheckpointRingHRoad"] = @g_ringHCheckpointPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpoint"] = @g_platformCheckpointPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointUp"] = @g_platformCheckpointUpPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointDown"] = @g_platformCheckpointDownPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointLeft"] = @g_platformCheckpointLeftPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointRight"] = @g_platformCheckpointRightPoly;
        g_triggerPolyhedrons["StadiumRoadDirtHighCheckpoint"] = @g_roadDirtHighCheckpointPoly;
        g_triggerPolyhedrons["StadiumRoadDirtCheckpoint"] = @g_roadDirtCheckpointPoly;
        g_triggerPolyhedrons["StadiumRoadMainFinishLine"] = @g_finishPoly;

    }
    array<Ellipsoid> g_carEllipsoids;
    array<Polyhedron@> g_worldCheckpointPolys;
    array<AABB> g_worldCheckpointAABBs;
    array<string> g_worldCheckpointNames;
    array<Polyhedron@> g_worldFinishPolys;
    array<AABB> g_worldFinishAABBs;

    uint64 g_totalOnEvaluateTime = 0;
    uint64 g_totalCalcMinCarDistTime = 0;
    uint64 g_totalVertexTransformTime = 0;
    uint64 g_totalClosestPointPolyTime = 0;
    uint64 g_onEvaluateCallCount = 0;

    const string g_distPluginPrefix = "dist_bf";
    const string g_uberPluginPrefix = "uber_bf";
    int g_bfTargetType = -1;
    int g_bfTargetCpIndex = -1;
    float g_bestBfDistance = 1e18f;
    string g_cachedChallengeUid = "";
    void CacheCheckpointData() {
        TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
        if (challenge is null) {
            print("Error: Could not get current challenge for caching.", Severity::Error);
            g_cachedChallengeUid = "";
            g_worldCheckpointPolys.Clear();
            g_worldCheckpointAABBs.Clear();
            g_worldCheckpointNames.Clear();
            g_worldFinishPolys.Clear();
            g_worldFinishAABBs.Clear();
            return;
        }
        if (challenge.Uid == g_cachedChallengeUid) {
            return;
        }

        g_cachedChallengeUid = challenge.Uid;
        g_worldCheckpointPolys.Clear();
        g_worldCheckpointAABBs.Clear();
        g_worldCheckpointNames.Clear();
        g_worldFinishPolys.Clear();
        g_worldFinishAABBs.Clear();
        array<TM::GameCtnBlock@> blocks = challenge.Blocks;
        if (blocks is null) {
            print("Error: Could not get challenge blocks.", Severity::Error);
            return;
        }

        for (uint i = 0; i < blocks.Length; i++) {
            TM::GameCtnBlock@ block = blocks[i];
            if (block !is null && block.WayPointType == TM::WayPointType::Checkpoint) {
                Polyhedron@ basePoly = Polyhedron();
                if (g_triggerPolyhedrons.Get(block.Name, basePoly)) {
                    if (basePoly !is null) {
                        Polyhedron worldPoly = TransformPolyhedronToWorld(basePoly, block);
                        AABB worldAABB = CalculatePolyhedronAABB(worldPoly);
                        g_worldCheckpointPolys.Add(worldPoly);
                        g_worldCheckpointAABBs.Add(worldAABB);
                        g_worldCheckpointNames.Add(block.Name);
                    } else {
                        print("Warning: Null polyhedron found in dictionary for block: " + block.Name, Severity::Warning);
                    }
                } else {
                    print("Warning: No trigger polyhedron defined for checkpoint block: " + block.Name, Severity::Warning);
                }
            }
            else if (block.WayPointType == TM::WayPointType::Finish) {
                Polyhedron@ basePoly = Polyhedron();
                if (g_triggerPolyhedrons.Get(block.Name, basePoly)) {
                    if (basePoly !is null) {
                        Polyhedron worldPoly = TransformPolyhedronToWorld(basePoly, block);
                        AABB worldAABB = CalculatePolyhedronAABB(worldPoly);
                        g_worldFinishPolys.Add(worldPoly);
                        g_worldFinishAABBs.Add(worldAABB);
                    } else {
                        print("Warning: Null polyhedron found in dictionary for block: " + block.Name, Severity::Warning);
                    }
                } else {
                    print("Warning: No trigger polyhedron defined for finish block: " + block.Name, Severity::Warning);
                }
            }
        }

    }

    namespace Drawing {
        int counter=0;
        const vec2 padFix = vec2(-8, -8);
        bool dimensionsInitialized = false;

        const array<string> NUMBER_PATTERNS = {
            "111101101101111", // 0
            "010110010010111", // 1
            "111001111100111", // 2
            "111001111001111", // 3
            "101101111001001", // 4
            "111100111001111", // 5
            "111100111101111", // 6
            "111001010010010", // 7
            "111101111101111", // 8
            "111101111001111"  // 9
        };

        void square(int x, int y, uint dimension){
            string title = "##Window for pixel" + counter++;

            UI::SetNextWindowPos(vec2(x-dimension/2, y-dimension/2) + padFix);
            UI::SetNextWindowSize(vec2(dimension+12, dimension+12));

            UI::Begin(title,
                UI::WindowFlags::NoBackground
                | UI::WindowFlags::NoDecoration
                | UI::WindowFlags::NoInputs
                | UI::WindowFlags::NoMouseInputs
                | UI::WindowFlags::NoNavInputs
                | UI::WindowFlags::NoFocusOnAppearing
                | UI::WindowFlags::NoBringToFrontOnFocus
                | UI::WindowFlags::NoNavFocus
            );

            UI::Button(title, vec2(float(dimension), float(dimension)));

            UI::End();
        }

        void number(int x, int y, uint dimension, uint numberValue) {
            if (dimension == 0) return;

            string digits = "" + numberValue;
            if (digits.Length == 0) digits = "0";

            uint cellSize = dimension;
            int digitWidth = int(cellSize) * 3;
            int digitSpacing = int(cellSize);
            int totalWidth = int(digits.Length) * digitWidth;
            if (digits.Length > 1) {
                totalWidth += (int(digits.Length) - 1) * digitSpacing;
            }
            int totalHeight = int(cellSize) * 5;

            int startX = x - totalWidth / 2;
            int startY = y - totalHeight / 2;

            for (uint i = 0; i < digits.Length; ++i) {
                int digitIndex = digits[i] - '0';
                if (digitIndex < 0 || digitIndex >= int(NUMBER_PATTERNS.Length)) continue;

                string pattern = NUMBER_PATTERNS[digitIndex];
                int digitX = startX + int(i) * (digitWidth + digitSpacing);

                for (uint row = 0; row < 5; ++row) {
                    for (uint col = 0; col < 3; ++col) {
                        uint patternIndex = row * 3 + col;
                        if (patternIndex >= pattern.Length) continue;
                        if (pattern[patternIndex] != '1') continue;

                        float centerX = float(digitX) + (float(col) + 0.5f) * float(cellSize);
                        float centerY = float(startY) + (float(row) + 0.5f) * float(cellSize);
                        square(int(Math::Round(centerX)), int(Math::Round(centerY)), cellSize);
                    }
                }
            }
        }


        dictionary dimensionsMapping;
        void InitializeDimensions() {
            if (dimensionsInitialized) return;
            dimensionsMapping = dictionary();
            dimensionsMapping.Set("1228800", vec2(640,480));
            dimensionsMapping.Set("1920000", vec2(800,600));
            dimensionsMapping.Set("4915200", vec2(1280,960));
            dimensionsMapping.Set("8294400", vec2(1920,1080));
            dimensionsMapping.Set("14745600", vec2(2560,1440));
            dimensionsMapping.Set("33177600", vec2(3840, 2160));
            dimensionsInitialized = true;
        }

        int screenWidth=1920;
        int screenHeight=1080;

        uint64 timeOfLastCapture=0;
        uint64 captureInterval=2000;

        vec3 lastCamPos=vec3(0,0,0);
        mat3 lastCamRot=mat3();
        vec2 lastScreenPos=vec2(0,0);
        void UpdateScreenSize() {
            InitializeDimensions();
            uint64 currentTime = Time::Now;
            if(currentTime - timeOfLastCapture <= captureInterval){
                return;
            }
            timeOfLastCapture = currentTime;
            array<uint8>@ screenshot = Graphics::CaptureScreenshot(vec2(0,0));
            string key = screenshot.Length + "";
            if(!dimensionsMapping.Exists(key)){
                return;
            }
            vec2 dim;
            dimensionsMapping.Get(key,dim);
            screenWidth=int(dim.x);
            screenHeight=int(dim.y);
        }

        void BeginFrame() {
            counter = 0;
            UpdateScreenSize();
        }

        vec2 GetScreenSize() {
            return vec2(float(screenWidth), float(screenHeight));
        }

        void Draw(SimulationManager@ simManager){
            BeginFrame();

            TM::GameCamera@ gameCamera = GetCurrentCamera();
            vec3 camPos = gameCamera.Location.Position;
            mat3 camRot = gameCamera.Location.Rotation;
            float camFov = gameCamera.Fov; // Varies between 70 and 90 degrees
            UpdateScreenSize();

            vec2 screenPos;
            if(camPos == lastCamPos && camRot.x==lastCamRot.x && camRot.y==lastCamRot.y && camRot.z==lastCamRot.z){
                screenPos = lastScreenPos;
            } else {
                screenPos = WorldToScreen(vec3(0,0,0), camPos, camRot, camFov, vec2(screenWidth,screenHeight));
                lastScreenPos = screenPos;
            }
            lastCamPos = camPos;
            lastCamRot = camRot;
            lastScreenPos = screenPos;

            vec3 rgb=HSVToRGB(GetRainbowHue(), 1.0f, 1.0f);
            vec4 rainbowColor = vec4(rgb.x, rgb.y, rgb.z, 1.0f);
            UI::PushStyleColor(UI::Col::Button, rainbowColor);
            number(int(screenPos.x),int(screenPos.y),30, int(Math::Round(camFov)));
            UI::PopStyleColor(1);
            
        }

        vec2 WorldToScreen(vec3 worldPos, vec3 camPos, mat3 camRot, float camFov, vec2 screenSize){
            vec3 dir = worldPos - camPos;

            camRot.Transpose();
            vec3 localDir = matTimesVec(camRot, dir);

            if (localDir.z <= 0) return vec2(-1, -1);

            float fovRad      = camFov * (3.14159265 / 180.0);
            float aspectRatio = screenSize.x / screenSize.y;
            float tanHalfFov  = Math::Tan(fovRad * 0.5);

            float ndcX = -(localDir.x / localDir.z) / (tanHalfFov * aspectRatio);
            float ndcY =  (localDir.y / localDir.z) /  tanHalfFov;

            float screenX = (ndcX * 0.5 + 0.5) * screenSize.x;
            float screenY = (-ndcY * 0.5 + 0.5) * screenSize.y;

            return vec2(screenX, screenY);
        }


        vec3 matTimesVec(mat3 m, vec3 v){
            return vec3(
                m.x.x*v.x + m.x.y*v.y + m.x.z*v.z,
                m.y.x*v.x + m.y.y*v.y + m.y.z*v.z,
                m.z.x*v.x + m.z.y*v.y + m.z.z*v.z
            );
        }

        float GetRainbowHue() {
            float t = float(Time::Now % 6000) / 6000.0f;
            return t * 360.0f;
        }

        vec3 HSVToRGB(float h, float s, float v) {
            while (h < 0.0f) h += 360.0f;
            while (h >= 360.0f) h -= 360.0f;

            float hPrime = h / 60.0f;
            float hFloor = Math::Floor(hPrime);
            int segment = int(hFloor) % 6;
            if (segment < 0) segment += 6;
            float f = hPrime - hFloor;

            float p = v * (1.0f - s);
            float q = v * (1.0f - f * s);
            float t = v * (1.0f - (1.0f - f) * s);

            if (segment == 0) return vec3(v, t, p);
            if (segment == 1) return vec3(q, v, p);
            if (segment == 2) return vec3(p, v, t);
            if (segment == 3) return vec3(p, q, v);
            if (segment == 4) return vec3(t, p, v);
            return vec3(v, p, q);
        }

    }


    void RenderBruteforceEvaluationSettingssss() {
        g_bfTargetType = int(GetVariableDouble(g_distPluginPrefix + "_target_type"));
        g_bfTargetCpIndex = int(GetVariableDouble(g_distPluginPrefix + "_target_cp_index"));
        bool typeChanged = false;
        UI::Text("Optimize for minimum distance to:");
        bool isCpSelected = (g_bfTargetType == 0);
        UI::BeginDisabled(isCpSelected);
        if (UI::Button("Checkpoint Index##TargetBtn")) {
            g_bfTargetType = 0;
            typeChanged = true;
        }
        UI::EndDisabled();
        bool isFinishSelected = (g_bfTargetType == 1);
        UI::BeginDisabled(isFinishSelected);
        if (UI::Button("Finish Line##TargetBtn")) {
            g_bfTargetType = 1;
            typeChanged = true;
        }
        UI::EndDisabled();
        UI::Separator();
        if (g_bfTargetType == 0) {
            UI::Text("Target Checkpoint Settings:");
            UI::Dummy(vec2(0, 5));
            UI::CheckboxVar("Show Checkpoint Numbers", g_distPluginPrefix + "_show_cp_numbers");
            UI::PushItemWidth(120);
            UI::InputIntVar("Target Index##CPIndex", g_distPluginPrefix + "_target_cp_index", 1);
            UI::PopItemWidth();
            int potentiallyUpdatedIndex = int(GetVariableDouble(g_distPluginPrefix + "_target_cp_index"));
            int clampedIndex = Math::Max(0, potentiallyUpdatedIndex);
            if (clampedIndex != g_bfTargetCpIndex || clampedIndex != potentiallyUpdatedIndex) {
                g_bfTargetCpIndex = clampedIndex;
                SetVariable(g_distPluginPrefix + "_target_cp_index", g_bfTargetCpIndex);
            } else {
                g_bfTargetCpIndex = clampedIndex;
            }
            string rangeText = "Valid range: 0 to " + (g_worldCheckpointPolys.Length > 0 ? g_worldCheckpointPolys.Length - 1 : 0);
            UI::TextDimmed(rangeText);
            if (g_bfTargetCpIndex >= 0 && g_bfTargetCpIndex < int(g_worldCheckpointNames.Length)) {
                UI::Text("Selected: ");
                UI::SameLine();
                UI::BeginDisabled();
                UI::Text(g_worldCheckpointNames[g_bfTargetCpIndex]);
                UI::EndDisabled();
            } else if (g_worldCheckpointPolys.Length > 0) {
                UI::TextDimmed("Error: Index is out of bounds!");
            } else {
                UI::TextDimmed("No checkpoint data cached.");
            }
        } else {
            UI::Text("Target Finish Settings:");
            UI::Dummy(vec2(0, 5));
            UI::CheckboxVar("Shift finish eval after reached", g_distPluginPrefix + "_shift_finish_eval");
            UI::Dummy(vec2(0, 5));
            UI::BeginDisabled();
            UI::TextWrapped("The bruteforce will optimize towards the closest point on any finish line block surface.");
            UI::EndDisabled();
        }
        if (typeChanged) {
            SetVariable(g_distPluginPrefix + "_target_type", g_bfTargetType);
        }
        UI::Separator();
        string bestDistText = "Current Best Distance Found: ";
        if (g_bestBfDistance > 1e17f) {
            bestDistText += "N/A";
        } else {
            bestDistText += Text::FormatFloat(g_bestBfDistance, "", 0, 4) + " m";
        }
        UI::Text(bestDistText);
        UI::Dummy(vec2(0, 5));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(30, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing1", g_distPluginPrefix + "_bf_time_from");
        UI::PopItemWidth();
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(49, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing2", g_distPluginPrefix + "_bf_time_to");
        UI::PopItemWidth();
        UI::Text("Trigger constraint");
        UI::SameLine();
        UI::Dummy(vec2(-11, 0));
        UI::SameLine();
        UI::PushItemWidth(110);
        int triggerId=UI::InputIntVar("##Nothing3", g_distPluginPrefix + "_constraint_trigger_index", 1);
        UI::PopItemWidth();
        UI::TextDimmed("0 to disable, 1 or more for the trigger index (see Triggers tab)");
        if (triggerId < 0) {
            triggerId = 0;
            SetVariable(g_distPluginPrefix + "_constraint_trigger_index", triggerId);
        }
    }
    vec3 ProjectPointOnPlane(const vec3&in point, const vec3&in planeNormal, const vec3&in planePoint) {
        float distance = Math::Dot(point - planePoint, planeNormal);
        return point - planeNormal * distance;
    }
    float PointToSegmentDistanceSq(const vec3&in p, const vec3&in a, const vec3&in b, vec3&out projection) {
        vec3 ab = b - a;
        vec3 ap = p - a;
        float abLenSq = Math::Dot(ab, ab);
        if (abLenSq < 1e-6f) {
            projection = a;
            return DistanceSq(p, a);
        }
        float t = Math::Dot(ap, ab) / abLenSq;
        t = Math::Clamp(t, 0.0f, 1.0f);
        projection = a + ab * t;
        return DistanceSq(p, projection);
    }
    float DistanceSq(const vec3&in p1, const vec3&in p2) {
        vec3 diff = p1 - p2;
        return Math::Dot(diff, diff);
    }

    bool IsPointInsideTriangle(const vec3&in point, const vec3&in v0, const vec3&in v1, const vec3&in v2, const vec3&in planeNormal) {
        vec3 edge0 = v1 - v0;
        vec3 edge1 = v2 - v1;
        vec3 edge2 = v0 - v2;
        vec3 p0 = point - v0;
        vec3 p1 = point - v1;
        vec3 p2 = point - v2;
        vec3 edgePlaneNormal0 = Cross(edge0, planeNormal);
        if (Math::Dot(p0, edgePlaneNormal0) > 1e-6f) return false;
        vec3 edgePlaneNormal1 = Cross(edge1, planeNormal);
        if (Math::Dot(p1, edgePlaneNormal1) > 1e-6f) return false;
        vec3 edgePlaneNormal2 = Cross(edge2, planeNormal);
        if (Math::Dot(p2, edgePlaneNormal2) > 1e-6f) return false;
        return true;
    }
    AABB CalculatePolyhedronAABB(const Polyhedron&in poly) {
        AABB box;
        if (poly.vertices.Length == 0) return box;
        for (uint i = 0; i < poly.vertices.Length; ++i) {
            box.Add(poly.vertices[i]);
        }
        return box;
    }
    Polyhedron CreateAABBPolyhedron(const vec3&in center, const vec3&in size) {
        vec3 halfSize = size * 0.5f;
        vec3 min = center - halfSize;
        vec3 max = center + halfSize;
        array<vec3> vertices = {
            vec3(min.x, min.y, min.z),
            vec3(max.x, min.y, min.z),
            vec3(max.x, max.y, min.z),
            vec3(min.x, max.y, min.z),
            vec3(min.x, min.y, max.z),
            vec3(max.x, min.y, max.z),
            vec3(max.x, max.y, max.z),
            vec3(min.x, max.y, max.z)
        };
        array<array<int>> faces = {
            {0, 3, 2, 1},
            {4, 5, 6, 7},
            {0, 1, 5, 4},
            {0, 4, 7, 3},
            {1, 2, 6, 5},
            {0, 1, 2, 3},
            {4, 5, 6, 7},
            {0, 1, 5, 4},
            {3, 7, 6, 2}
        };
        faces = {
            {0, 3, 2, 1},
            {4, 5, 6, 7},
            {0, 4, 7, 3},
            {1, 2, 6, 5},
            {0, 1, 5, 4},
            {3, 7, 6, 2}
        };
        return Polyhedron(vertices, faces);
    }
    Polyhedron TransformPolyhedronToWorld(const Polyhedron&in basePoly, const TM::GameCtnBlock@ block) {
        Polyhedron worldPoly;

        vec3 blockOriginWorld = vec3(block.Coord.x * 32.0f, block.Coord.y * 8.0f, block.Coord.z * 32.0f);
        GmVec3 centerOffsetLocal = GmVec3(16.0f, 4.0f, 16.0f);
        GmVec3 blockCenterWorld = GmVec3(blockOriginWorld) + centerOffsetLocal;

        GmMat3 blockRotationMat;
        float angleRad = 0.0f;
        if (block.Dir == TM::CardinalDir::East) {
            angleRad = Math::ToRad(-90.0f);
        } else if (block.Dir == TM::CardinalDir::South) {
            angleRad = Math::ToRad(180.0f);
        } else if (block.Dir == TM::CardinalDir::West) {
            angleRad = Math::ToRad(90.0f);
        }
        if (angleRad != 0.0f) {
            blockRotationMat.RotateY(angleRad);
        }

        worldPoly.vertices.Resize(basePoly.vertices.Length);
        for (uint i = 0; i < basePoly.vertices.Length; ++i) {
            GmVec3 baseVertexLocal = GmVec3(basePoly.vertices[i]);
            GmVec3 vertexRelativeToCenterLocal = baseVertexLocal - centerOffsetLocal;
            GmVec3 rotatedRelativeVertex = blockRotationMat.Transform(vertexRelativeToCenterLocal);
            GmVec3 finalWorldVertex = rotatedRelativeVertex + blockCenterWorld;
            worldPoly.vertices[i] = finalWorldVertex.ToVec3();
        }

        worldPoly.faces = basePoly.faces;
        worldPoly.uniqueEdges = basePoly.uniqueEdges;

        worldPoly.precomputedFaces.Resize(basePoly.precomputedFaces.Length);
        for (uint i = 0; i < basePoly.precomputedFaces.Length; ++i) {
            const PrecomputedFace@ basePface = basePoly.precomputedFaces[i];
            PrecomputedFace@ worldPface = worldPoly.precomputedFaces[i];

            worldPface.vertexIndices = basePface.vertexIndices;

            GmVec3 localPlanePoint = basePface.planePoint;
            GmVec3 pointRelativeToCenter = localPlanePoint - centerOffsetLocal;
            GmVec3 rotatedRelativePoint = blockRotationMat.Transform(pointRelativeToCenter);
            worldPface.planePoint = rotatedRelativePoint + blockCenterWorld;

            worldPface.normal = blockRotationMat.Transform(basePface.normal);
        }

        return worldPoly;
    }

    float g_currentWindowMinDistance = 1e18f;
    bool g_windowResultProcessed = false;
    int g_lastProcessedRaceTime = -1;
    int bfTimeFrom = 0;
    int bfTimeTo = 0;
    AABB triggerIdToAABB(int id) {
        int index = id-1;
        if (index<0){
            return AABB(vec3(-1e18f, -1e18f, -1e18f), vec3(1e18f, 1e18f, 1e18f));
        }
        array<int> triggerIds = GetTriggerIds();
        bool canExist = index <= int(triggerIds.Length);
        if(!canExist){
            print("BF Evaluate: Trigger index " + index + " not found.", Severity::Error);
            return AABB(vec3(1e18f, 1e18f, 1e18f), vec3(-1e18f, -1e18f, -1e18f));
        }
        Trigger3D trigger = GetTriggerByIndex(index);
        return AABB(trigger.Position, trigger.Position + trigger.Size);;
    }
    Polyhedron g_targetCpPoly;
    AABB g_targetCpAABB;
    bool g_bfConfigIsValid = false;
    string g_bfTargetDescription = "Invalid Target";

    Polyhedron g_clippedtargetCpPoly;
    AABB@ g_clippedtargetCpAABB;
    array<Polyhedron@> g_worldClippedFinishPolys;
    array<AABB> g_worldClippedFinishAABBs;

    void OnDistSimulationBegin(SimulationManager@ simManager){
        
        if(!(GetVariableString("controller")=="bfv2")){
            g_bfConfigIsValid = false;
            return;
        }
        g_isNewBFEvaluationRun=true;
        g_simEndProcessed = false;
        g_isEarlyStop=false;
        g_forceAccept = false;
        g_bfPhase = BFPhase::Initial;

        TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
        if (challenge !is null && challenge.Uid != g_cachedChallengeUid) {
            CacheCheckpointData();
        }
        g_bfConfigIsValid = false;
        bfTimeFrom = int(GetVariableDouble(g_distPluginPrefix + "_bf_time_from"));
        bfTimeTo = int(GetVariableDouble(g_distPluginPrefix + "_bf_time_to"));
        g_bfTargetType = int(GetVariableDouble(g_distPluginPrefix + "_target_type"));

        if (g_bfTargetType == 0) {
            g_bfTargetCpIndex = int(GetVariableDouble(g_distPluginPrefix + "_target_cp_index"));
            if (g_bfTargetCpIndex < 0 || g_bfTargetCpIndex >= int(g_worldCheckpointPolys.Length)) {
                print("BF Init Error: Target CP index " + g_bfTargetCpIndex + " is out of bounds (0-" + (g_worldCheckpointPolys.Length) + ").", Severity::Error);
            } else {
                g_targetCpPoly = g_worldCheckpointPolys[g_bfTargetCpIndex];
                if (g_targetCpPoly is null) {
                    print("BF Init Error: Target CP polyhedron at index " + g_bfTargetCpIndex + " is null.", Severity::Error);
                } else {
                    g_targetCpAABB = g_worldCheckpointAABBs[g_bfTargetCpIndex];
                    g_bfTargetDescription = "CP Index " + g_bfTargetCpIndex;
                    if (g_bfTargetCpIndex >= 0 && g_bfTargetCpIndex < int(g_worldCheckpointNames.Length)) {
                        g_bfTargetDescription += " (" + g_worldCheckpointNames[g_bfTargetCpIndex] + ")";
                    }
                    g_bfConfigIsValid = true;
                }
            }
        } else if (g_bfTargetType == 1) {
            if (g_worldFinishPolys.IsEmpty()) {
                print("BF Init Error: No finish blocks cached for this map. Cannot evaluate distance.", Severity::Error);
            } else {
                g_bfTargetDescription = "Finish Line";
                if (g_worldFinishPolys.Length > 1) {
                    g_bfTargetDescription += " (Closest of " + g_worldFinishPolys.Length + ")";
                }
                g_bfConfigIsValid = true;
            }
        } else {
            print("BF Init Error: Invalid target type specified: " + g_bfTargetType, Severity::Error);
        }

        if (g_bfConfigIsValid) {

            g_bestBfDistance = 1e18f;
            g_currentWindowMinDistance = 1e18f;
            g_windowResultProcessed = true;
            g_lastProcessedRaceTime = -1;

            g_totalOnEvaluateTime = 0;
            g_totalCalcMinCarDistTime = 0;
            g_totalVertexTransformTime = 0;
            g_totalClosestPointPolyTime = 0;
            g_onEvaluateCallCount = 0;

            AABB triggerAABB = triggerIdToAABB(int(GetVariableDouble(g_distPluginPrefix + "_constraint_trigger_index")));
            if (g_bfTargetType == 0) {
                g_clippedtargetCpPoly = ClipPolyhedronByAABB(g_targetCpPoly, triggerAABB);
                g_targetCpAABB = triggerAABB;
            } else if (g_bfTargetType == 1) {
                g_worldClippedFinishPolys.Resize(0);
                g_worldClippedFinishAABBs.Resize(0);
                for (uint i = 0; i < g_worldFinishPolys.Length; ++i) {
                    const Polyhedron@ targetPoly = g_worldFinishPolys[i];
                    if (targetPoly is null) continue;
                    const AABB targetAABB = g_worldFinishAABBs[i];
                    log("Trigger AABB: " + triggerAABB.ToString());
                    Polyhedron clippedPoly = ClipPolyhedronByAABB(targetPoly, triggerAABB);
                    g_worldClippedFinishPolys.Add(clippedPoly);
                    g_worldClippedFinishAABBs.Add(targetAABB);
                }
            }
        } else {
            print("BF Initialization failed. Evaluation will be stopped.");
        }
    }

    void OnSimulationBegin(SimulationManager@ simManager) {
        if(GetVariableString("bf_target")==g_bruteforceDistanceTargetIdentifier){
            OnDistSimulationBegin(simManager);
        }else if(GetVariableString("bf_target")==g_uberbugTargetIdentifier){
            OnUberSimulationBegin(simManager);
        }
    }

    bool g_simEndProcessed = false;

    void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result){
        if(GetVariableString("bf_target") != g_bruteforceDistanceTargetIdentifier || GetVariableString("controller") != "bruteforce"){
            return;
        }
        if(!g_simEndProcessed){
            g_simEndProcessed = true;
            if (g_bfConfigIsValid && g_isEarlyStop){
                g_earlyStopCommandList.Save(GetVariableString("bf_result_filename"));
            }

            print("\n--- Bruteforce Performance Report ---");
            if (g_onEvaluateCallCount == 0) {
                print("No evaluations were run.");
                print("-------------------------------------\n");
                return;
            }

            print("Total evaluations: " + g_onEvaluateCallCount);
            print("Total time in OnEvaluate: " + g_totalOnEvaluateTime + " ms");
            float avgOnEvaluate = float(g_totalOnEvaluateTime) / g_onEvaluateCallCount;
            print("  -> Average per evaluation: " + Text::FormatFloat(avgOnEvaluate, "", 0, 4) + " ms");

            if (g_totalOnEvaluateTime > 0) {
                print("\nBreakdown of OnEvaluate time:");
                uint64 totalMeasuredInside = g_totalCalcMinCarDistTime;
                uint64 overhead = g_totalOnEvaluateTime > totalMeasuredInside ? g_totalOnEvaluateTime - totalMeasuredInside : 0;

                print("  - CalculateMinCarDistanceToPoly: " + g_totalCalcMinCarDistTime + " ms (" + Text::FormatFloat(100.0f * g_totalCalcMinCarDistTime / g_totalOnEvaluateTime, "", 0, 1) + "%)");
                print("  - OnEvaluate Overhead: " + overhead + " ms (" + Text::FormatFloat(100.0f * overhead / g_totalOnEvaluateTime, "", 0, 1) + "%)");

                if (g_totalCalcMinCarDistTime > 0) {
                    print("\nBreakdown of CalculateMinCarDistanceToPoly time:");
                    uint64 totalCalcDistBreakdown = g_totalVertexTransformTime + g_totalClosestPointPolyTime;
                    uint64 calcDistOverhead = g_totalCalcMinCarDistTime > totalCalcDistBreakdown ? g_totalCalcMinCarDistTime - totalCalcDistBreakdown : 0;

                    print("    - Vertex Transformations: " + g_totalVertexTransformTime + " ms (" + Text::FormatFloat(100.0f * g_totalVertexTransformTime / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                    print("    - Polygon Closest Point Checks: " + g_totalClosestPointPolyTime + " ms (" + Text::FormatFloat(100.0f * g_totalClosestPointPolyTime / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                    print("    - Other (internal logic): " + calcDistOverhead + " ms (" + Text::FormatFloat(100.0f * calcDistOverhead / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                }
            }

            print("-------------------------------------\n");
        }
    }

    class BFResultPrinter {

        int COL_ITER     = 10;
        int COL_PHASE    = 12;
        int COL_TARGET   = 30;
        int COL_WINDOW   = 18;
        int COL_DIST     = 18;
        int COL_IMPROVE  = 18;
        int precision = 8;

        bool headerPrinted = false;

        private string PadString(const string &in str, int width, bool alignRight = false) {
            int len = str.Length;
            if (len >= width) {

                return str.Substr(0, width);
            }
            int padding = width - len;
            string padStr = "";
            for (int i = 0; i < padding; ++i) {
                padStr += " ";
            }
            if (alignRight) {
                return padStr + str;
            } else {
                return str + padStr;
            }
        }

        void PrintHeader(const string &in targetDesc, int timeFrom, int timeTo) {
            string title = "Bruteforce Evaluation Results";
            string targetInfo = "Target: " + targetDesc + " | Window: [" + timeFrom + "-" + timeTo + "] ms";

            string header = PadString("Iteration", COL_ITER) + " | " +
                            PadString("Phase", COL_PHASE) + " | " +

                            PadString("Min Distance", COL_DIST, true) + " | " +
                            PadString("Improvement", COL_IMPROVE, true);

            int totalWidth = header.Length;
            string separator = "";
            for (int i = 0; i < totalWidth; ++i) {
                separator += "-";
            }

            print("");
            print(title);
            print(targetInfo);
            print(separator);
            print(header);
            print(separator);
            headerPrinted = true;
        }

        void PrintRow(int iteration, const string &in phase, float distance, float improvement = -1.0f) {

            string iterStr = Text::FormatInt(iteration);
            string phaseStr = phase;
            string distStr = Text::FormatFloat(distance, "", 0, precision) + " m";
            string improveStr = (improvement >= 0.0f) ? (Text::FormatFloat(improvement, "", 0, precision) + " m") : "N/A";

            string row = PadString(iterStr, COL_ITER, true) + " | " +
                        PadString(phaseStr, COL_PHASE) + " | " +

                        PadString(distStr, COL_DIST, true) + " | " +
                        PadString(improveStr, COL_IMPROVE, true);

            print(row);
        }

        void PrintInitialResult(int iteration, const string &in targetDesc, int timeFrom, int timeTo, float distance) {

            if (!headerPrinted) {
                PrintHeader(targetDesc, timeFrom, timeTo);
            }
            PrintRow(iteration, "Initial", distance, -1.0f);
        }

        void PrintImprovedResult(int iteration, float newDistance, float improvement) {

            if (!headerPrinted) {

                print("BFResultPrinter Warning: Header not printed before improved result!", Severity::Warning);

            }
            PrintRow(iteration, "Improvement", newDistance, improvement);
        }

        void PrintTargetAchieved() {
            if (!headerPrinted) {
                print("BFResultPrinter Warning: Header not printed before target achievement!", Severity::Warning);
            }

            array<string> celebration = {
                "|------------------------------------------------------|",
                "|                                                      |",
                "|                   CONGRATULATIONS!                   |",
                "|                                                      |",
                "|   /$$$$$$  /$$   /$$ /$$     /$$ /$$$$$$$  /$$$$$$$$ |",
                "|  /$$__  $$| $$  /$$/|  $$   /$$/| $$__  $$| $$_____/ |",
                "| | $$  \\__/| $$ /$$/  \\  $$ /$$/ | $$  \\ $$| $$       |",
                "| |  $$$$$$ | $$$$$/    \\  $$$$/  | $$$$$$$ | $$$$$    |",
                "|  \\____  $$| $$  $$     \\  $$/   | $$__  $$| $$__/    |",
                "|  /$$  \\ $$| $$\\  $$     | $$    | $$  \\ $$| $$       |",
                "| |  $$$$$$/| $$ \\  $$    | $$    | $$$$$$$/| $$       |",
                "|  \\______/ |__/  \\__/    |__/    |_______/ |__/       |",
                "|                                                      |",
                "|                Mission accomplished!                 |",
                "|                                                      |",
                "|------------------------------------------------------|"
            };

            print("\n");
            for (uint i = 0; i < celebration.Length; ++i) {
                string leftPadding = "     ";
                string text = leftPadding + celebration[i];
                print(text, Severity::Success);
            }
            print("\n");
        }

        void Reset() {
            headerPrinted = false;
        }
    }

    BFResultPrinter g_bfPrinter;
    bool g_isNewBFEvaluationRun = false;
    CommandList g_earlyStopCommandList;
    bool g_isEarlyStop = false;
    bool g_forceAccept = false;
    BFPhase g_bfPhase = BFPhase::Initial;

    void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target){
        int raceTime = simManager.RaceTime;
        if(!(GetVariableString("bf_target") == g_bruteforceDistanceTargetIdentifier && GetVariableString("controller") == "bruteforce")){
            return;
        }
        if(current==target && raceTime <= bfTimeTo && g_bfPhase == BFPhase::Search){
            if(GetVariableBool(g_distPluginPrefix + "_shift_finish_eval")){
                CommandList finish();
                finish.Content = simManager.InputEvents.ToCommandsText();
                g_bfPrinter.PrintTargetAchieved();
                print("");
                print("Finish reached at " + (raceTime) + "ms (or before), shifting finish evaluation earlier...", Severity::Warning);
                print("File saved: " + finish.Save(GetVariableString("bf_result_filename").Split(".")[0] + "_restart"+restartCount+"_bestfin.txt"));
                bfTimeTo = raceTime-10;
                if(bfTimeFrom > bfTimeTo) {
                    bfTimeFrom = bfTimeTo;
                }
                g_bestBfDistance = 1e18f;
                g_currentWindowMinDistance = 1e18f;
                g_windowResultProcessed = false;
                g_forceAccept = true;
            }else{
                g_isEarlyStop = true;
                g_forceAccept = true;
            }
        }
        if(raceTime < bfTimeFrom || raceTime >= bfTimeTo){
            return;
        }
    }
    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info) {
        uint64 onEvaluateStartTime = Time::get_Now();
        BFEvaluationResponse@ resp = OnEvaluate_Inner(simManager, info);
        g_onEvaluateCallCount++;
        g_totalOnEvaluateTime += (Time::get_Now() - onEvaluateStartTime);
        return resp;
    }
    BFEvaluationResponse@ OnEvaluate_Inner(SimulationManager@ simManager, const BFEvaluationInfo&in info) {
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        if (!g_bfConfigIsValid) {
            resp.Decision = BFEvaluationDecision::Stop;
            return resp;
        }

        int raceTime = simManager.RaceTime;
        g_bfPhase = info.Phase;

        if (raceTime < g_lastProcessedRaceTime) {
            g_currentWindowMinDistance = 1e18f;
            g_windowResultProcessed = false;
        }
        g_lastProcessedRaceTime = raceTime;

        TM::PlayerInfo@ playerInfo = simManager.PlayerInfo;

        bool isInWindow = (raceTime >= bfTimeFrom && raceTime < bfTimeTo);
        bool isDecisionTime = (raceTime == bfTimeTo);

        bool shouldCalculateDistance = isInWindow || (isDecisionTime && !g_windowResultProcessed);
        float currentTickDistance = 1e18f;

        if (shouldCalculateDistance) {
            g_windowResultProcessed = false;

            GmIso4 carWorldTransform = GmIso4(simManager.Dyna.CurrentState.Location);
            vec3 carPosition = carWorldTransform.m_Position.ToVec3(); 

            if (g_bfTargetType == 0) {
                const Polyhedron@ targetPoly;
                const AABB targetAABB = g_targetCpAABB;
                int constraintTriggerIndex = int(GetVariableDouble(g_distPluginPrefix + "_constraint_trigger_index"));
                bool constraintIsActive = (constraintTriggerIndex > 0);
                if (constraintIsActive) {
                    @targetPoly = g_clippedtargetCpPoly;
                } else {
                    @targetPoly = g_targetCpPoly;
                }

                bool needsAccurateDistance = targetAABB.Contains(carPosition, 15);
                if (needsAccurateDistance) {
                    currentTickDistance = CalculateMinCarDistanceToPoly(carWorldTransform, targetPoly);
                } else {
                    currentTickDistance = Math::Max(0.0f, targetAABB.DistanceToPoint(carPosition));
                }
            } else {
                float minDistToAnyFinish = 1e18f;
                for (uint i = 0; i < g_worldClippedFinishPolys.Length; ++i) {
                const Polyhedron@ targetPoly = g_worldClippedFinishPolys[i];
                    if (targetPoly is null || targetPoly.faces.Length == 0) continue;
                    const AABB targetAABB = g_worldClippedFinishAABBs[i];

                    bool needsAccurateDistance = targetAABB.Contains(carPosition, 15);
                    float distToThisFinish = 1e18f;
                    if (needsAccurateDistance) {
                        distToThisFinish = CalculateMinCarDistanceToPoly(carWorldTransform, targetPoly);
                    } else {
                        distToThisFinish = Math::Max(0.0f, targetAABB.DistanceToPoint(carPosition));
                    }
                    minDistToAnyFinish = Math::Min(minDistToAnyFinish, distToThisFinish);
                }
                currentTickDistance = minDistToAnyFinish;
            }
            g_currentWindowMinDistance = Math::Min(g_currentWindowMinDistance, currentTickDistance);
        }

        if (isDecisionTime && !g_windowResultProcessed) {
            g_windowResultProcessed = true;
            if(g_bfTargetType == 1 && playerInfo.RaceFinished && !GetVariableBool(g_distPluginPrefix + "_shift_finish_eval")){
                g_isEarlyStop = true;
            }
            if (g_isEarlyStop) {
                g_earlyStopCommandList.Content = simManager.InputEvents.ToCommandsText();
                resp.Decision = BFEvaluationDecision::Stop;
                g_bfPrinter.PrintTargetAchieved();
                return resp;
            }

            float finalMinDistance = g_currentWindowMinDistance;

            if (finalMinDistance == 1e18f) {
                if (shouldCalculateDistance) {
                    finalMinDistance = currentTickDistance;
                } else {
                    print("BF Evaluate: Warning - Could not determine minimum distance at decision time " + raceTime + "ms.", Severity::Warning);
                }
            }

            string targetDesc = g_bfTargetDescription;

            if (info.Phase == BFPhase::Initial) {
                g_bestBfDistance = finalMinDistance;
                resp.Decision = BFEvaluationDecision::Accept;
                if(g_isNewBFEvaluationRun){
                    g_bfPrinter.Reset();
                    g_isNewBFEvaluationRun = false;
                    g_bfPrinter.PrintInitialResult(info.Iterations, targetDesc, bfTimeFrom, bfTimeTo, g_bestBfDistance);

                    resp.ResultFileStartContent = "# Baseline min distance to " + targetDesc + " [" + bfTimeFrom + "-" + bfTimeTo + "ms]: " + Text::FormatFloat(g_bestBfDistance, "", 0, 6) + " m";
                }
            } else {
                if(finalMinDistance == 0.0f){
                    resp.Decision= BFEvaluationDecision::DoNothing;
                    return resp;
                }
                if (finalMinDistance < g_bestBfDistance) {
                    float oldBest = g_bestBfDistance;
                    g_bestBfDistance = finalMinDistance;
                    resp.Decision = BFEvaluationDecision::Accept;
                    g_bfPrinter.PrintImprovedResult(info.Iterations, g_bestBfDistance, oldBest - g_bestBfDistance);

                    resp.ResultFileStartContent = "# Found closer state to " + targetDesc + " [" + bfTimeFrom + "-" + bfTimeTo + "ms]: " + Text::FormatFloat(g_bestBfDistance, "", 0, 6) + " m at iteration " + info.Iterations;
                } else {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
            }

            g_currentWindowMinDistance = 1e18f;

            return resp;
        }
        if(g_forceAccept && info.Phase == BFPhase::Search){
            if(GetVariableBool(g_distPluginPrefix + "_shift_finish_eval")){
                
                g_isNewBFEvaluationRun = true;
            }
            g_forceAccept = false;
            resp.Decision = BFEvaluationDecision::Accept;
        }
        if(raceTime > bfTimeTo+10){
            resp.Decision = BFEvaluationDecision::Reject;
        }
        return resp;
    }
    string g_bruteforceDistanceTargetIdentifier = "distance_target";
    string g_uberbugTargetIdentifier = "uberbug_target";
    void Main()
    {
        log("Skycrafter Bruteforce Targets v2 loaded.");
        InitializeTriggerData();
        InitializeCarEllipsoids();

        RegisterVariable(g_distPluginPrefix + "_target_type", 0);
        RegisterVariable(g_distPluginPrefix + "_target_cp_index", 0);
        RegisterVariable(g_distPluginPrefix + "_show_cp_numbers", false);
        RegisterVariable(g_distPluginPrefix + "_bf_time_from", 0);
        RegisterVariable(g_distPluginPrefix + "_bf_time_to", 0);
        RegisterVariable(g_distPluginPrefix + "_constraint_trigger_index", -1);
        RegisterVariable(g_distPluginPrefix + "_shift_finish_eval", true);
        auto eval1 = RegisterBruteforceEval(
            g_bruteforceDistanceTargetIdentifier,
            "Distance to Target (CP/Finish)",
            OnEvaluate,
            RenderBruteforceEvaluationSettingssss
        );
        @eval1.onSimBegin = @OnSimulationBegin;
        
        RegisterVariable(g_uberPluginPrefix + "_uberbug_threshold", 0.8);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_mode", "Find");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_show_visualization", false);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_amount", 10);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_result_file", "uber{i}.txt");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_min_speed", 300.0f);
        RegisterVariable(g_uberPluginPrefix + "_bf_time_from", 0);
        RegisterVariable(g_uberPluginPrefix + "_bf_time_to", 0);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_viz_follow_race", false);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_point1", "0,0,0");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_point2", "0,0,0");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_show_trajectory", false);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_find_mode", "Single");
        RegisterVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        RegisterVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        currentUberMode = GetVariableString(g_uberPluginPrefix + "_uberbug_mode");
        currentFindMode = GetVariableString(g_uberPluginPrefix + "_uberbug_find_mode");
        auto eval2=RegisterBruteforceEval(
            g_uberbugTargetIdentifier,
            "Uberbug",
            OnEvaluateUberbug,
            RenderBruteforceEvaluationSettingsUberbug
        );
        @eval2.onSimBegin = @OnSimulationBegin;
        RegisterSettingsPage("Uberbug BF", UberbugPageSettings);

        RegisterCustomCommand("clear_uberbugs", "Clear all stored uberbugs", OnClearUberbugs);

        string trajectoryTriggerCache = GetVariableString(g_uberPluginPrefix + "_trajectory_trigger_cache");
        string cachedTriggers = GetVariableString(g_uberPluginPrefix + "_uberbugs_trigger_cache");
    }

    void DistRender(){
        if(!GetVariableBool(g_distPluginPrefix + "_show_cp_numbers")){
            return;
        }

        SimulationManager@ simManager = GetSimulationManager();
        if(simManager is null || !simManager.InRace) {
            return;
        }

        TM::GameCamera@ gameCamera = GetCurrentCamera();
        if(gameCamera is null) {
            return;
        }

        Drawing::BeginFrame();
        vec3 camPos = gameCamera.Location.Position;
        mat3 camRot = gameCamera.Location.Rotation;
        float camFov = gameCamera.Fov;
        vec2 screenSize = Drawing::GetScreenSize();

        vec3 rainbow = Drawing::HSVToRGB(Drawing::GetRainbowHue(), 1.0f, 1.0f);
        UI::PushStyleColor(UI::Col::Button, vec4(rainbow.x, rainbow.y, rainbow.z, 1.0f));
        for(uint i = 0; i < g_worldCheckpointAABBs.Length; i++) {
            vec3 center = g_worldCheckpointAABBs[i].Center();
            vec2 screenPos = Drawing::WorldToScreen(center, camPos, camRot, camFov, screenSize);
            Drawing::number(int(Math::Round(screenPos.x)), int(Math::Round(screenPos.y)), 14, i);
        }
        UI::PopStyleColor(1);
    }

    void Render()
    {
        DistRender();
        UberRender();   
    }
    class GmVec3 {
        float x = 0.0f;
        float y = 0.0f;
        float z = 0.0f;
        GmVec3() {}
        GmVec3(float num) {
            this.x = num;
            this.y = num;
            this.z = num;
        }
        GmVec3(float x, float y, float z) {
            this.x = x;
            this.y = y;
            this.z = z;
        }
        GmVec3(const GmVec3&in other) {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
        }
        GmVec3(const vec3&in other) {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
        }
        vec3 ToVec3() const {
            return vec3(x, y, z);
        }
        void Mult(const GmMat3&in M) {
            float _x = x * M.x.x + y * M.x.y + z * M.x.z;
            float _y = x * M.y.x + y * M.y.y + z * M.y.z;
            float _z = x * M.z.x + y * M.z.y + z * M.z.z;
            x = _x;
            y = _y;
            z = _z;
        }
        void Mult(const GmIso4&in T) {
            Mult(T.m_Rotation);
            x += T.m_Position.x;
            y += T.m_Position.y;
            z += T.m_Position.z;
        }
        void MultTranspose(const GmMat3&in M) {
            float _x = x * M.x.x + y * M.y.x + z * M.z.x;
            float _y = x * M.x.y + y * M.y.y + z * M.z.y;
            float _z = x * M.x.z + y * M.y.z + z * M.z.z;
            x = _x;
            y = _y;
            z = _z;
        }
        float LengthSquared() const {
            return x*x + y*y + z*z;
        }
        float Length() const {
            return Math::Sqrt(LengthSquared());
        }
        void Normalize() {
            float len = Length();
            if (len > 1e-6f) {
                x /= len;
                y /= len;
                z /= len;
            }
        }
        GmVec3 Normalized() const {
            GmVec3 result = this;
            result.Normalize();
            return result;
        }
        GmVec3 opAdd(const GmVec3&in other) const {
            return GmVec3(x + other.x, y + other.y, z + other.z);
        }
        GmVec3 opSub(const GmVec3&in other) const {
            return GmVec3(x - other.x, y - other.y, z - other.z);
        }
        GmVec3 opMul(float scalar) const {
            return GmVec3(x * scalar, y * scalar, z * scalar);
        }
        GmVec3 opDiv(float scalar) const {
            return GmVec3(x / scalar, y / scalar, z / scalar);
        }
        GmVec3 opNeg() const {
            return GmVec3(-x, -y, -z);
        }
        void opAddAssign(const GmVec3&in other) {
            x += other.x; y += other.y; z += other.z;
        }
        void opSubAssign(const GmVec3&in other) {
            x -= other.x; y -= other.y; z -= other.z;
        }
        void opMulAssign(float scalar) {
            x *= scalar; y *= scalar; z *= scalar;
        }
        void opDivAssign(float scalar) {
            x /= scalar; y /= scalar; z /= scalar;
        }
        GmVec3 opMul_Elementwise(const GmVec3&in other) const {
            return GmVec3(x * other.x, y * other.y, z * other.z);
        }
        GmVec3 opDiv_Elementwise(const GmVec3&in other) const {
            return GmVec3(x / other.x, y / other.y, z / other.z);
        }
    }
    class GmMat3 {
        GmVec3 x;
        GmVec3 y;
        GmVec3 z;
        GmMat3() { SetIdentity(); }
        GmMat3(const GmMat3&in other) {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
        }
        GmMat3(const GmVec3&in x, const GmVec3&in y, const GmVec3&in z) {
            this.x = x;
            this.y = y;
            this.z = z;
        }
        GmMat3(const mat3&in other) {
            this.x.x = other.x.x;
            this.x.y = other.y.x;
            this.x.z = other.z.x;
            this.y.x = other.x.y;
            this.y.y = other.y.y;
            this.y.z = other.z.y;
            this.z.x = other.x.z;
            this.z.y = other.y.z;
            this.z.z = other.z.z;
        }
        mat3 ToMat3() const {
            mat3 m;
            m.x.x = this.x.x; m.x.y = this.y.x; m.x.z = this.z.x;
            m.y.x = this.x.y; m.y.y = this.y.y; m.y.z = this.z.y;
            m.z.x = this.x.z; m.z.y = this.y.z; m.z.z = this.z.z;
            return m;
        }
        void SetIdentity() {
            x = GmVec3(1.0f, 0.0f, 0.0f);
            y = GmVec3(0.0f, 1.0f, 0.0f);
            z = GmVec3(0.0f, 0.0f, 1.0f);
        }
        void Mult(const GmMat3&in other) {
            GmMat3 result;
            result.x.x = x.x * other.x.x + y.x * other.x.y + z.x * other.x.z;
            result.x.y = x.y * other.x.x + y.y * other.x.y + z.y * other.x.z;
            result.x.z = x.z * other.x.x + y.z * other.x.y + z.z * other.x.z;
            result.y.x = x.x * other.y.x + y.x * other.y.y + z.x * other.y.z;
            result.y.y = x.y * other.y.x + y.y * other.y.y + z.y * other.y.z;
            result.y.z = x.z * other.y.x + y.z * other.y.y + z.z * other.y.z;
            result.z.x = x.x * other.z.x + y.x * other.z.y + z.x * other.z.z;
            result.z.y = x.y * other.z.x + y.y * other.z.y + z.y * other.z.z;
            result.z.z = x.z * other.z.x + y.z * other.z.y + z.z * other.z.z;
            this = result;
        }
        GmMat3 opMul(const GmMat3&in other) const {
            GmMat3 result = this;
            result.Mult(other);
            return result;
        }
        GmVec3 Transform(const GmVec3&in v) const {
            return GmVec3(
                x.x * v.x + y.x * v.y + z.x * v.z,
                x.y * v.x + y.y * v.y + z.y * v.z,
                x.z * v.x + y.z * v.y + z.z * v.z
            );
        }
        GmVec3 opMul(const GmVec3&in v) const {
            return Transform(v);
        }
        GmVec3 TransformTranspose(const GmVec3&in v) const {
            return GmVec3(
                x.x * v.x + x.y * v.y + x.z * v.z,
                y.x * v.x + y.y * v.y + y.z * v.z,
                z.x * v.x + z.y * v.y + z.z * v.z
            );
        }
        void RotateX(float rad) {
            float s = Math::Sin(rad);
            float c = Math::Cos(rad);
            GmMat3 rotMat(
                GmVec3(1, 0, 0),
                GmVec3(0, c, s),
                GmVec3(0,-s, c)
            );
            Mult(rotMat);
        }
        void RotateY(float rad) {
            float s = Math::Sin(rad);
            float c = Math::Cos(rad);
            GmMat3 rotMat(
                GmVec3(c, 0,-s),
                GmVec3(0, 1, 0),
                GmVec3(s, 0, c)
            );
            Mult(rotMat);
        }
        void RotateZ(float rad) {
            float s = Math::Sin(rad);
            float c = Math::Cos(rad);
            GmMat3 rotMat(
                GmVec3(c, s, 0),
                GmVec3(-s,c, 0),
                GmVec3(0, 0, 1)
            );
            Mult(rotMat);
        }
        float Determinant() const {
            return x.x * (y.y * z.z - y.z * z.y)
                - y.x * (x.y * z.z - x.z * z.y)
                + z.x * (x.y * y.z - x.z * y.y);
        }
        GmMat3 Inverse() const {
            GmMat3 inv;
            float det = Determinant();
            if (Math::Abs(det) < 1e-6f) {
                print("Warning: GmMat3::Inverse() called on singular matrix. Returning identity.", Severity::Warning);
                return inv;
            }
            float invDet = 1.0f / det;
            inv.x.x = (y.y * z.z - y.z * z.y) * invDet;
            inv.y.x = (y.z * z.x - y.x * z.z) * invDet;
            inv.z.x = (y.x * z.y - y.y * z.x) * invDet;
            inv.x.y = (x.z * z.y - x.y * z.z) * invDet;
            inv.y.y = (x.x * z.z - x.z * z.x) * invDet;
            inv.z.y = (x.y * z.x - x.x * z.y) * invDet;
            inv.x.z = (x.y * y.z - x.z * y.y) * invDet;
            inv.y.z = (x.z * y.x - x.x * y.z) * invDet;
            inv.z.z = (x.x * y.y - x.y * y.x) * invDet;
            return inv;
        }
        GmMat3 Transposed() const {
            GmMat3 result;
            result.x.x = x.x; result.y.x = x.y; result.z.x = x.z;
            result.x.y = y.x; result.y.y = y.y; result.z.y = y.z;
            result.x.z = z.x; result.y.z = z.y; result.z.z = z.z;
            return result;
        }
    }
    class GmIso4 {
        GmMat3 m_Rotation;
        GmVec3 m_Position;
        GmIso4() {}
        GmIso4(const GmIso4&in other) {
            this.m_Rotation = other.m_Rotation;
            this.m_Position = other.m_Position;
        }
        GmIso4(const GmMat3&in rotation, const GmVec3&in position) {
            this.m_Rotation = rotation;
            this.m_Position = position;
        }
        GmIso4(const iso4&in other) {
            this.m_Rotation = GmMat3(other.Rotation);
            this.m_Position = GmVec3(other.Position);
        }
        iso4 ToIso4() const {
            iso4 result;
            result.Rotation = m_Rotation.ToMat3();
            result.Position = m_Position.ToVec3();
            return result;
        }
        void Mult(const GmIso4&in other) {
            m_Position = m_Rotation.Transform(other.m_Position) + m_Position;
            m_Rotation.Mult(other.m_Rotation);
        }
        GmIso4 opMul(const GmIso4&in other) const {
            GmIso4 result = this;
            result.Mult(other);
            return result;
        }
        GmVec3 Transform(const GmVec3&in p) const {
            return m_Rotation.Transform(p) + m_Position;
        }
        GmVec3 opMul(const GmVec3&in p) const {
            return Transform(p);
        }
        GmVec3 TransformDirection(const GmVec3&in d) const {
            return m_Rotation.Transform(d);
        }
        GmIso4 Inverse() const {
            GmMat3 invRot = m_Rotation.Inverse();
            GmVec3 invPos = invRot.Transform(-m_Position);
            return GmIso4(invRot, invPos);
        }
    }
    class AABB {
        vec3 min = vec3(1e9, 1e9, 1e9);
        vec3 max = vec3(-1e9, -1e9, -1e9);
        AABB() {}
        AABB(const vec3&in min, const vec3&in max) {
            this.min = min;
            this.max = max;
        }
        void Add(const vec3&in p) {
            min.x = Math::Min(min.x, p.x);
            min.y = Math::Min(min.y, p.y);
            min.z = Math::Min(min.z, p.z);
            max.x = Math::Max(max.x, p.x);
            max.y = Math::Max(max.y, p.y);
            max.z = Math::Max(max.z, p.z);
        }
        void Add(const AABB&in other) {
            Add(other.min);
            Add(other.max);
        }
        vec3 Center() const {
            return (min + max) * 0.5f;
        }
        vec3 Size() const {
            return max - min;
        }
        bool Contains(const vec3&in p, float margin = 1e-6f) const {
            return (p.x >= min.x - margin && p.x <= max.x + margin &&
                    p.y >= min.y - margin && p.y <= max.y + margin &&
                    p.z >= min.z - margin && p.z <= max.z + margin);
        }
        float DistanceToPoint(const vec3&in p) const {
            float dx = Math::Max(min.x - p.x, 0.0f) + Math::Max(p.x - max.x, 0.0f);
            float dy = Math::Max(min.y - p.y, 0.0f) + Math::Max(p.y - max.y, 0.0f);
            float dz = Math::Max(min.z - p.z, 0.0f) + Math::Max(p.z - max.z, 0.0f);
            return Math::Sqrt(dx*dx + dy*dy + dz*dz);
        }
        AABB Intersect(const AABB& other) const {
            vec3 intersectMin = vec3(
                Math::Max(min.x, other.min.x),
                Math::Max(min.y, other.min.y),
                Math::Max(min.z, other.min.z)
            );
            vec3 intersectMax = vec3(
                Math::Min(max.x, other.max.x),
                Math::Min(max.y, other.max.y),
                Math::Min(max.z, other.max.z)
            );
            return AABB(intersectMin, intersectMax);
        }
        bool IsValid() const {
            return min.x <= max.x && min.y <= max.y && min.z <= max.z;
        }
        bool intersectsSegment(const vec3&in p0, const vec3&in p1) const {
            vec3 d = p1 - p0;
            float tmin = 0.0f;
            float tmax = 1.0f;
            for (int i = 0; i < 3; ++i) {
                if (Math::Abs(d[i]) < 1e-6f) {
                    if (p0[i] < min[i] || p0[i] > max[i]) return false;
                } else {
                    float ood = 1.0f / d[i];
                    float t1 = (min[i] - p0[i]) * ood;
                    float t2 = (max[i] - p0[i]) * ood;
                    if (t1 > t2) {
                        float temp = t1;
                        t1 = t2;
                        t2 = temp;
                    }
                    tmin = Math::Max(tmin, t1);
                    tmax = Math::Min(tmax, t2);
                    if (tmin > tmax) return false;
                }
            }
            return true;
        }
        bool testAxis(const vec3&in v0, const vec3&in v1, const vec3&in v2, const vec3&in edge, const vec3&in boxHalf, const int axis) {
            float p, minTri, maxTri, rad;
            if (axis == 0) {
                p = v0.z * edge.y - v0.y * edge.z;
                minTri = p; maxTri = p;
                p = v1.z * edge.y - v1.y * edge.z;
                minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
                p = v2.z * edge.y - v2.y * edge.z;
                minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
                rad = Math::Abs(edge.y) * boxHalf.z + Math::Abs(edge.z) * boxHalf.y;
            } else if (axis == 1) {
                p = v0.x * edge.z - v0.z * edge.x;
                minTri = p; maxTri = p;
                p = v1.x * edge.z - v1.z * edge.x;
                minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
                p = v2.x * edge.z - v2.z * edge.x;
                minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
                rad = Math::Abs(edge.x) * boxHalf.z + Math::Abs(edge.z) * boxHalf.x;
            } else {
                p = v0.y * edge.x - v0.x * edge.y;
                minTri = p; maxTri = p;
                p = v1.y * edge.x - v1.x * edge.y;
                minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
                p = v2.y * edge.x - v2.x * edge.y;
                minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
                rad = Math::Abs(edge.x) * boxHalf.y + Math::Abs(edge.y) * boxHalf.x;
            }
            return !(minTri > rad || maxTri < -rad);
        }
        bool intersectsTriangle(const vec3&in p0, const vec3&in p1, const vec3&in p2) const {

            vec3 boxCenter = (min + max) * 0.5f;
            vec3 boxHalf = (max - min) * 0.5f;

            vec3 v0 = p0 - boxCenter;
            vec3 v1 = p1 - boxCenter;
            vec3 v2 = p2 - boxCenter;

            vec3 e0 = v1 - v0;
            vec3 e1 = v2 - v1;
            vec3 e2 = v0 - v2;

            if (!testAxis(v0, v1, v2, e0, boxHalf, 0)) return false;
            if (!testAxis(v0, v1, v2, e0, boxHalf, 1)) return false;
            if (!testAxis(v0, v1, v2, e0, boxHalf, 2)) return false;
            if (!testAxis(v0, v1, v2, e1, boxHalf, 0)) return false;
            if (!testAxis(v0, v1, v2, e1, boxHalf, 1)) return false;
            if (!testAxis(v0, v1, v2, e1, boxHalf, 2)) return false;
            if (!testAxis(v0, v1, v2, e2, boxHalf, 0)) return false;
            if (!testAxis(v0, v1, v2, e2, boxHalf, 1)) return false;
            if (!testAxis(v0, v1, v2, e2, boxHalf, 2)) return false;

            for (int i = 0; i < 3; i++) {
                float triMin = Math::Min(v0[i], Math::Min(v1[i], v2[i]));
                float triMax = Math::Max(v0[i], Math::Max(v1[i], v2[i]));
                if (triMin > boxHalf[i] || triMax < -boxHalf[i])
                    return false;
            }

            vec3 normal = Cross(e0, e1);

            float rad = boxHalf.x * Math::Abs(normal.x) + boxHalf.y * Math::Abs(normal.y) + boxHalf.z * Math::Abs(normal.z);

            float triProj0 = Math::Dot(normal, v0);
            float triProj1 = Math::Dot(normal, v1);
            float triProj2 = Math::Dot(normal, v2);
            float triMin = Math::Min(triProj0, Math::Min(triProj1, triProj2));
            float triMax = Math::Max(triProj0, Math::Max(triProj1, triProj2));
            if (triMin > rad || triMax < -rad)
                return false;

            return true;
        }

        string ToString() {
            return "AABB(min: " + min.x + ", " + min.y + ", " + min.z +
                ", max: " + max.x + ", " + max.y + ", " + max.z + ")";
        }
    }

    class Edge {
        int v0;
        int v1;
        Edge() {
            v0 = -1;
            v1 = -1;
        }
        Edge(int i0 = -1, int i1 = -1) {

            if (i0 < i1) {
                v0 = i0;
                v1 = i1;
            } else {
                v0 = i1;
                v1 = i0;
            }
        }
        bool opEquals(const Edge&in other) const {
            return v0 == other.v0 && v1 == other.v1;
        }
        bool opLess(const Edge&in other) const {
            if (v0 < other.v0) return true;
            if (v0 > other.v0) return false;
            return v1 < other.v1;
        }
    }

    class SortableVertex {
        float angle;
        int index;

        int opCmp(const SortableVertex&in other) const {
            if (angle < other.angle) return -1;
            if (angle > other.angle) return 1;
            return 0;
        }
    };

    class PrecomputedFace {
        array<int> vertexIndices;
        GmVec3 normal;
        GmVec3 planePoint; 
    }

    class Polyhedron {
        array<vec3> vertices;
        array<array<int>> faces;
        array<PrecomputedFace> precomputedFaces; 
        array<Edge> uniqueEdges;
        vec3 BoundingSphereCenter;
        float BoundingSphereRadius;

        Polyhedron() {
            BoundingSphereRadius = 0.0f;}

        Polyhedron(const array<vec3>&in in_vertices, const array<array<int>>&in triangleFaces) {
            this.vertices = in_vertices;

            if (vertices.IsEmpty() || triangleFaces.IsEmpty()) {
                return;
            }

            uint numTriangles = triangleFaces.Length;
            array<array<int>> newFaceIndices;
            array<PrecomputedFace> newPrecomputedFaces; 

            dictionary edgeToGlobalFaces;
            array<vec3> faceNormals(numTriangles);

            for (uint i = 0; i < numTriangles; ++i) {
                const array<int>@ face_idxs = triangleFaces[i];
                if (face_idxs.Length != 3) {
                    print("Error: Input face " + i + " is not a triangle. Simplification requires a triangle mesh.", Severity::Error);
                    return;
                }

                vec3 edge1 = vertices[face_idxs[1]] - vertices[face_idxs[0]];
                vec3 edge2 = vertices[face_idxs[2]] - vertices[face_idxs[0]];
                faceNormals[i] = Cross(edge1, edge2).Normalized();

                for (uint j = 0; j < 3; ++j) {
                    Edge e(face_idxs[j], face_idxs[(j + 1) % 3]);
                    string edgeKey = e.v0 + "_" + e.v1;

                    array<int>@ faceList;
                    if (!edgeToGlobalFaces.Get(edgeKey, @faceList)) {
                        edgeToGlobalFaces.Set(edgeKey, array<int> = {int(i)});
                    } else {
                        faceList.Add(i);
                    }
                }
            }

            array<bool> processedFaces(numTriangles); 
            const float COPLANAR_TOLERANCE = 0.9999f;

            for (uint i = 0; i < numTriangles; ++i) {
                if (processedFaces[i]) continue;

                array<int> componentQueue = {int(i)};
                array<int> componentFaces = {int(i)};
                processedFaces[i] = true;
                uint head = 0;
                const vec3 referenceNormal = faceNormals[i];

                while (head < componentQueue.Length) {
                    int currentIdx = componentQueue[head++];
                    const array<int>@ currentFace = triangleFaces[currentIdx];

                    for (uint j = 0; j < 3; ++j) {
                        Edge e(currentFace[j], currentFace[(j + 1) % 3]);
                        string edgeKey = e.v0 + "_" + e.v1;

                        array<int>@ neighborFaces;
                        if(edgeToGlobalFaces.Get(edgeKey, @neighborFaces)) {
                            for (uint k = 0; k < neighborFaces.Length; ++k) {
                                int neighborIdx = neighborFaces[k];
                                if (!processedFaces[neighborIdx] && Math::Dot(referenceNormal, faceNormals[neighborIdx]) > COPLANAR_TOLERANCE) {
                                    processedFaces[neighborIdx] = true;
                                    componentFaces.Add(neighborIdx);
                                    componentQueue.Add(neighborIdx);
                                }
                            }
                        }
                    }
                }

                dictionary boundaryEdges;
                dictionary vertToBoundaryEdges;

                for(uint c_idx = 0; c_idx < componentFaces.Length; ++c_idx) {
                    int triFaceIdx = componentFaces[c_idx];
                    const array<int>@ triVerts = triangleFaces[triFaceIdx];
                    for (uint v_idx = 0; v_idx < 3; ++v_idx) {
                        Edge e(triVerts[v_idx], triVerts[(v_idx+1)%3]);
                        string edgeKey = e.v0 + "_" + e.v1;

                        array<int>@ globalFaces;
                        edgeToGlobalFaces.Get(edgeKey, @globalFaces);

                        int sharedCoplanarFaces = 0;
                        for(uint g_idx = 0; g_idx < globalFaces.Length; ++g_idx) {
                            if(componentFaces.Find(globalFaces[g_idx]) != -1) {
                                sharedCoplanarFaces++;
                            }
                        }

                        if(sharedCoplanarFaces == 1) {
                            if (!boundaryEdges.Exists(edgeKey)) {
                                boundaryEdges.Set(edgeKey, e);

                                array<Edge>@ v0_edges;
                                if (!vertToBoundaryEdges.Get(""+e.v0, @v0_edges)) {
                                    @v0_edges = array<Edge>();
                                    vertToBoundaryEdges.Set(""+e.v0, @v0_edges);
                                }
                                v0_edges.Add(e);

                                array<Edge>@ v1_edges;
                                if (!vertToBoundaryEdges.Get(""+e.v1, @v1_edges)) {
                                    @v1_edges = array<Edge>();
                                    vertToBoundaryEdges.Set(""+e.v1, @v1_edges);
                                }
                                v1_edges.Add(e);
                            }
                        }
                    }
                }

                array<string>@ boundaryEdgeKeys = boundaryEdges.GetKeys();
                if (boundaryEdgeKeys.Length < 3) continue;

                array<int> sortedIndices;
                Edge startEdge;
                boundaryEdges.Get(boundaryEdgeKeys[0], startEdge);

                sortedIndices.Add(startEdge.v0);
                sortedIndices.Add(startEdge.v1);

                dictionary usedEdgeKeys;
                usedEdgeKeys.Set(boundaryEdgeKeys[0], true);

                int currentVert = startEdge.v1;
                int startVert = startEdge.v0;

                while(currentVert != startVert && sortedIndices.Length <= boundaryEdgeKeys.Length) {
                    array<Edge>@ connectedEdges;
                    vertToBoundaryEdges.Get(""+currentVert, @connectedEdges);

                    bool foundNext = false;
                    for(uint edge_idx = 0; edge_idx < connectedEdges.Length; ++edge_idx) {
                        Edge nextEdge = connectedEdges[edge_idx];
                        string nextEdgeKey = nextEdge.v0 + "_" + nextEdge.v1;

                        if (!usedEdgeKeys.Exists(nextEdgeKey)) {
                            usedEdgeKeys.Set(nextEdgeKey, true);

                            currentVert = (nextEdge.v0 == currentVert) ? nextEdge.v1 : nextEdge.v0;
                            sortedIndices.Add(currentVert);
                            foundNext = true;
                            break;
                        }
                    }
                    if (!foundNext) {

                        print("Error: Could not find next edge in chain for merged face.", Severity::Error);
                        break;
                    }
                }

                if(sortedIndices.Length > 0 && sortedIndices[sortedIndices.Length-1] == startVert) {
                    sortedIndices.RemoveAt(sortedIndices.Length - 1);
                }

                if (sortedIndices.Length < 3) continue;

                newFaceIndices.Add(sortedIndices);

                PrecomputedFace pface;
                pface.vertexIndices = sortedIndices;
                pface.normal = GmVec3(referenceNormal);
                pface.planePoint = GmVec3(vertices[sortedIndices[0]]);
                newPrecomputedFaces.Add(pface);
            }

            this.faces = newFaceIndices;
            this.precomputedFaces = newPrecomputedFaces; 

            if (this.precomputedFaces.IsEmpty()) {

            } else {

                GmVec3 centroid(0,0,0);
                for(uint i = 0; i < this.vertices.Length; ++i) {
                    centroid += GmVec3(this.vertices[i]);
                }
                if (this.vertices.Length > 0) {
                    centroid /= float(this.vertices.Length);
                }

                for (uint i = 0; i < this.precomputedFaces.Length; ++i) {

                    PrecomputedFace@ pface = this.precomputedFaces[i];

                    if (pface.vertexIndices.Length < 3) continue;

                    GmVec3 v0 = GmVec3(this.vertices[pface.vertexIndices[0]]);
                    GmVec3 v1 = GmVec3(this.vertices[pface.vertexIndices[1]]);
                    GmVec3 v2 = GmVec3(this.vertices[pface.vertexIndices[2]]);
                    GmVec3 correct_normal = Cross(v1 - v0, v2 - v0).Normalized();

                    GmVec3 face_to_center = centroid - v0;
                    if (GmDot(correct_normal, face_to_center) > 0.0f) {
                        correct_normal = -correct_normal; 
                    }

                    pface.normal = correct_normal;

                    pface.planePoint = v0;
                }
            }

            if (vertices.IsEmpty() || this.faces.IsEmpty()) return;

            uint numFaces = this.faces.Length;
            array<Edge> allEdgesTemp;
            for (uint i = 0; i < numFaces; ++i) {
                const array<int>@ faceIndices = this.faces[i];
                uint faceVertCount = faceIndices.Length;
                if (faceVertCount < 2) continue;
                for(uint v_idx = 0; v_idx < faceVertCount; ++v_idx) {
                    int i0 = faceIndices[v_idx];
                    int i1 = faceIndices[(v_idx + 1) % faceVertCount];
                    allEdgesTemp.Add(Edge(i0, i1));
                }
            }

            if (!allEdgesTemp.IsEmpty()) {
                allEdgesTemp.SortAsc();
                uniqueEdges.Add(allEdgesTemp[0]);
                for (uint i = 1; i < allEdgesTemp.Length; ++i) {
                    if (!(allEdgesTemp[i] == uniqueEdges[uniqueEdges.Length - 1])) {
                        uniqueEdges.Add(allEdgesTemp[i]);
                    }
                }
            }

            if (!this.vertices.IsEmpty()) {

                vec3 center(0,0,0);
                for (uint i = 0; i < this.vertices.Length; ++i) {
                    center += this.vertices[i];
                }
                center /= float(this.vertices.Length);
                this.BoundingSphereCenter = center;

                float maxRadiusSq = 0.0f;
                for (uint i = 0; i < this.vertices.Length; ++i) {
                    float distSq = (this.vertices[i] - this.BoundingSphereCenter).LengthSquared();
                    if (distSq > maxRadiusSq) {
                        maxRadiusSq = distSq;
                    }
                }
                this.BoundingSphereRadius = Math::Sqrt(maxRadiusSq);
            } else {
                this.BoundingSphereCenter = vec3(0,0,0);
                this.BoundingSphereRadius = 0.0f;
            }
        }

        bool GetFaceVertices(uint faceIndex, array<vec3>&out faceVerts) const {
            if (faceIndex >= faces.Length) return false;
            const array<int>@ indices = faces[faceIndex];
            faceVerts.Resize(indices.Length);
            for(uint i = 0; i < indices.Length; ++i) {
                int vertexIndex = indices[i];
                if (vertexIndex < 0 || vertexIndex >= int(vertices.Length)) return false;
                faceVerts[i] = vertices[vertexIndex];
            }
            return true;
        }

        GmVec3 GetClosestPoint(const GmVec3&in p) const {
            if (precomputedFaces.IsEmpty()) {
                if (vertices.IsEmpty()) return p;

                GmVec3 closest_v(vertices[0].x, vertices[0].y, vertices[0].z);
                float min_dist_sq = (p - closest_v).LengthSquared();
                for (uint i = 1; i < vertices.Length; ++i) {
                    GmVec3 current_v(vertices[i].x, vertices[i].y, vertices[i].z);
                    float dist_sq = (p - current_v).LengthSquared();
                    if (dist_sq < min_dist_sq) {
                        min_dist_sq = dist_sq;
                        closest_v = current_v;
                    }
                }
                return closest_v;
            }

            GmVec3 closest_point_overall;
            float min_dist_sq = 1e18f;
            bool first_face = true;

            for (uint i = 0; i < precomputedFaces.Length; ++i) {
                const PrecomputedFace@ face = precomputedFaces[i];

                GmVec3 projectedPoint = p - face.normal * GmDot(p - face.planePoint, face.normal);

                bool isInside = true;
                for (uint j = 0; j < face.vertexIndices.Length; ++j) {
                    GmVec3 v_start = GmVec3(vertices[face.vertexIndices[j]]);
                    GmVec3 v_end = GmVec3(vertices[face.vertexIndices[(j + 1) % face.vertexIndices.Length]]);
                    GmVec3 edge = v_end - v_start;
                    GmVec3 to_point = projectedPoint - v_start;

                    if (GmDot(Cross(edge, to_point), face.normal) < -EPSILON) {
                        isInside = false;
                        break;
                    }
                }

                GmVec3 point_on_face;
                if (isInside) {
                    point_on_face = projectedPoint;
                } else {
                    GmVec3 v_last = GmVec3(vertices[face.vertexIndices[face.vertexIndices.Length - 1]]);
                    GmVec3 v_first = GmVec3(vertices[face.vertexIndices[0]]);
                    point_on_face = closest_point_on_segment(p, v_last, v_first);
                    float min_edge_dist_sq = (p - point_on_face).LengthSquared();

                    for (uint j = 0; j < face.vertexIndices.Length - 1; ++j) {
                        GmVec3 v_start = GmVec3(vertices[face.vertexIndices[j]]);
                        GmVec3 v_end = GmVec3(vertices[face.vertexIndices[j + 1]]);
                        GmVec3 edge_point = closest_point_on_segment(p, v_start, v_end);
                        float dist_sq = (p - edge_point).LengthSquared();
                        if (dist_sq < min_edge_dist_sq) {
                            min_edge_dist_sq = dist_sq;
                            point_on_face = edge_point;
                        }
                    }
                }

                float dist_sq = (p - point_on_face).LengthSquared();
                if (first_face || dist_sq < min_dist_sq) {
                    min_dist_sq = dist_sq;
                    closest_point_overall = point_on_face;
                    first_face = false;
                }
            }
            return closest_point_overall;
        }

        bool GetFaceNormal(uint faceIndex, GmVec3&out normal) const {

            if (faceIndex >= precomputedFaces.Length) return false;
            normal = precomputedFaces[faceIndex].normal;
            return true;
        }
    };

    class Ellipsoid {
        GmVec3 center;
        GmVec3 radii;
        GmMat3 rotation;
        Ellipsoid() {
            center = GmVec3(0,0,0);
            radii = GmVec3(1,1,1);
        }
        Ellipsoid(const GmVec3&in center, const GmVec3&in radii, const GmMat3&in rotation) {
            this.center = center;
            this.radii = radii;
            this.rotation = rotation;
        }
        Ellipsoid(const vec3&in center, const vec3&in radii, const mat3&in rotation) {
            this.center = GmVec3(center);
            this.radii = GmVec3(radii);
            this.rotation = GmMat3(rotation);
        }

    }
    array<iso4> currentRunStates;
    array<string> runStatesResultFiles;
    array<iso4> initialRunStates;
    int maxDur = 0;
    float viztime = 0;

    bool runAccepted = false;
    bool stop = false;
    float bestProj = 0.0f;

    BFEvaluationResponse@ OnEvaluateUberbug(SimulationManager@ simManager, const BFEvaluationInfo&in info){
        BFEvaluationResponse@ resp = BFEvaluationResponse();
        auto phase = info.Phase;
        int raceTime = simManager.RaceTime;
        bool isEvalTime = raceTime >= GetVariableDouble(g_uberPluginPrefix + "_bf_time_from") && 
                            raceTime <= GetVariableDouble(g_uberPluginPrefix + "_bf_time_to");
        bool isLastTick = raceTime == GetVariableDouble(g_uberPluginPrefix + "_bf_time_to");
        bool isPastEvalTime = raceTime > GetVariableDouble(g_uberPluginPrefix + "_bf_time_to");
        if(currentUberMode != "Find"){
            resp.Decision == BFEvaluationDecision::Stop;
            print("Uberbug evaluation is not implemented for mode: " + currentUberMode);
            return resp;

        }
        if (phase == BFPhase::Initial){
            if(raceTime>=0){
                initialRunStates.InsertAt(raceTime/10, simManager.Dyna.CurrentState.Location);
            }
            if(isEvalTime && isUberbug(simManager)){
                if(currentFindMode == "Single"){
                    print("Base run already contained a uberbug at time " + Text::FormatInt(raceTime) + ".");
                    resp.Decision == BFEvaluationDecision::Stop;
                }
            }
            if(isPastEvalTime){
                currentRunStates= initialRunStates;
            }
        }else{
            if(raceTime>=0 && currentFindMode == "Collect many"){
                currentRunStates.RemoveAt(raceTime/10);
                currentRunStates.InsertAt(raceTime/10, simManager.Dyna.CurrentState.Location);
            }
            if(isEvalTime && isUberbug(simManager) && !runAccepted){
                if(currentFindMode == "Collect many"){
                    totalAmountCollected++;
                    runStatesResultFiles.Add(SaveCurrentInputs(simManager));
                    runAccepted = true;
                    print("Collected uberbug at time " + Text::FormatInt(raceTime) + ".", Severity::Success);
                    if(totalAmountCollected >= GetVariableDouble(g_uberPluginPrefix + "_uberbug_amount")){
                        stop = true;
                    }
                }else if(currentFindMode == "Single"){
                    print("Found a uberbug at time " + Text::FormatInt(raceTime) + ". Stopping evaluation.", Severity::Success);
                    SaveCurrentInputs(simManager);
                    resp.Decision = BFEvaluationDecision::Stop;
                    return resp;
                }else if(currentFindMode == "Keep best"){
                    vec3 desiredTraj = Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point2")) - 
                        Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point1"));
                    vec3 uberTraj = simManager.Dyna.CurrentState.LinearSpeed;
                    float length = uberTraj.Length();
                    if(length > 1000.0f){
                        uberTraj = uberTraj.Normalized() * 1000.0f;
                    }
                    float k = Math::Acos(Math::Dot(uberTraj.Normalized(), desiredTraj.Normalized()))/3.14159f * 180.0f;
                    if(k < bestProj){
                        bestProj = k;
                        SaveCurrentInputs(simManager);
                        print("Found a better uberbug at time " + Text::FormatInt(raceTime) + ". " + Text::FormatFloat(bestProj,"",0,9) + " degrees away from trajectory", Severity::Success);
                        resp.Decision = BFEvaluationDecision::Reject;
                    }
                }
            }
            if(isPastEvalTime && !runAccepted){
                resp.Decision = BFEvaluationDecision::Reject;
                currentRunStates=initialRunStates;
            }
        }
        if(raceTime >= int(simManager.EventsDuration) && runAccepted){
            uberbugStates.Add(currentRunStates);
            currentRunStates=initialRunStates;
            runAccepted = false;
            resp.Decision = BFEvaluationDecision::Reject;
            if(stop){
                resp.Decision = BFEvaluationDecision::Stop;
                print("Collected enough uberbugs, stopping evaluation.", Severity::Warning);
            }
        }
        return resp;
    }

    string SaveCurrentInputs(SimulationManager@ simManager) {
        string filename = currentFindMode == "Collect many" ? 
            GetVariableString(g_uberPluginPrefix + "_uberbug_result_file") 
                                    : 
            GetVariableString("bf_result_filename");
        int i = totalAmountCollected;
        int indexPos = filename.FindLast("{i}");
        CommandList inputs();
        inputs.Content = simManager.InputEvents.ToCommandsText();
        if(indexPos != -1){
            filename.Erase(indexPos, 3);
            filename.Insert(indexPos, Text::FormatInt(i));
        }
        if(inputs.Save(filename)){
            print("Saved inputs to " + filename, Severity::Success);
        }else{
            print("Failed to save inputs to " + filename, Severity::Error);
        } 
        return filename;
    }

    bool isUberbug(SimulationManager@ simManager){
        vec3 speed = simManager.Dyna.CurrentState.LinearSpeed;
        vec3 previousSpeed = simManager.Dyna.PreviousState.LinearSpeed;
        return Math::Dot(speed.Normalized(), previousSpeed.Normalized()) <= GetVariableDouble(g_uberPluginPrefix + "_uberbug_threshold") && speed.Length()*3.6f >= GetVariableDouble(g_uberPluginPrefix + "_uberbug_min_speed");
    }

    vec3 GetUberbugTrajectory(SimulationManager@ simManager) {
        vec3 pos = simManager.Dyna.CurrentState.Location.Position;
        vec3 prevPos = simManager.Dyna.PreviousState.Location.Position;
        return (pos - prevPos);
    }

    int totalAmountCollected = 0;

    void OnUberSimulationBegin(SimulationManager@ simManager) {
        if(GetVariableString("controller") != "bfv2"){
            return;
        }
        string cachedTriggerIds = GetVariableString(g_uberPluginPrefix + "_uberbugs_trigger_cache");
        if (g_uberbugDrawTriggerIds.Length == 0 && cachedTriggerIds != "") {
            array<string> ids = cachedTriggerIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i) {
                g_uberbugDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        }
        for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i) {
            RemoveTrigger(g_uberbugDrawTriggerIds[i]);
        }
        
        string cachedTrajIds = GetVariableString(g_uberPluginPrefix + "_trajectory_trigger_cache");
        if (g_trajectoryDrawTriggerIds.Length == 0 && cachedTrajIds != "") {
            array<string> ids = cachedTrajIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i) {
                g_trajectoryDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        }
        for(uint i = 0; i < g_trajectoryDrawTriggerIds.Length; ++i) {
            RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
        }
        totalAmountCollected = 0;
        uberbugStates = array<array<iso4>>();
        currentRunStates.Clear();
        initialRunStates.Clear();
        runStatesResultFiles.Clear();
        runAccepted = false;
        maxDur = int(simManager.EventsDuration);
        stop = false;
        closestInputFile="";
        bestProj = 1e18f;
        g_uberbugDrawTriggerIds.Clear();
        SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
    }

    string currentUberMode = "Find";
    string currentFindMode = "Single";

    array<array<iso4>> uberbugStates;

    void RenderBruteforceEvaluationSettingsUberbug() {

        SimulationManager@ simManager = GetSimulationManager();
        TM::GameCamera@ cam = GetCurrentCamera();

        UI::Dummy(vec2(0, 5));
        UI::PushItemWidth(231);
        
        if(UI::BeginCombo("Mode", currentUberMode)) {
            if(UI::Selectable("Find", currentUberMode == "Find")) {
                currentUberMode = "Find";
                SetVariable(g_uberPluginPrefix + "_uberbug_mode", currentUberMode);
            }
            if(UI::Selectable("Optimize", currentUberMode == "Optimize")) {
                currentUberMode = "Optimize";
                SetVariable(g_uberPluginPrefix + "_uberbug_mode", currentUberMode);
            }
            UI::EndCombo();
        }
        UI::Dummy(vec2(0, 1));
        if(currentUberMode == "Find"){
            UI::Dummy(vec2(0, 1));
            if(UI::BeginCombo("Find mode", currentFindMode)){
                if(UI::Selectable("Single", currentFindMode == "Single")) {
                    currentFindMode = "Single";
                    SetVariable(g_uberPluginPrefix + "_uberbug_find_mode", currentFindMode);
                }
                if(UI::Selectable("Collect many", currentFindMode == "Collect many")) {
                    currentFindMode = "Collect many";
                    SetVariable(g_uberPluginPrefix + "_uberbug_find_mode", currentFindMode);
                }
                if(UI::Selectable("Keep best", currentFindMode == "Keep best")) {
                    currentFindMode = "Keep best";
                    SetVariable(g_uberPluginPrefix + "_uberbug_find_mode", currentFindMode);
                }
                UI::EndCombo();
            }
            UI::Dummy(vec2(0, 1));
            if(currentFindMode == "Collect many"){
                
                    UI::InputIntVar("Amount", g_uberPluginPrefix + "_uberbug_amount", 10);
                    UI::Dummy(vec2(0, 1));
                    UI::InputTextVar("Result file", g_uberPluginPrefix + "_uberbug_result_file");
                    UI::TextDimmed("This is the file where the uberbugs will be saved. {i} will be replaced with the uberbug number, starting from 1.");
                    UI::Dummy(vec2(0, 1));
            }
            if(currentFindMode == "Keep best"){
                UI::Dummy(vec2(0, 1));
                UI::DragFloat3Var("Point 1", g_uberPluginPrefix + "_uberbug_point1", 0.1f, 0.0f, 0.0f, "%.3f");
                if(simManager.InRace){
                    UI::SameLine();
                    if(UI::Button("Copy cam position")){
                        SetVariable(g_uberPluginPrefix + "_uberbug_point1", cam.Location.Position.ToString());
                    }
                }
                UI::Dummy(vec2(0, 1));
                UI::DragFloat3Var("Point 2", g_uberPluginPrefix + "_uberbug_point2", 0.1f, 0.0f, 0.0f, "%.3f");
                if(simManager.InRace){
                    UI::SameLine();
                    if(UI::Button("Copy cam position##")){
                        SetVariable(g_uberPluginPrefix + "_uberbug_point2", cam.Location.Position.ToString());
                    }
                }
                UI::Dummy(vec2(0, 1));
            }
        }
        if(currentUberMode == "Optimize"){
            UI::Text("THIS MODE IS NOT IMPLEMENTED YET");
            UI::Dummy(vec2(0, 1));
        }
        UI::Separator();
        UI::Dummy(vec2(0, 5));
        UI::InputFloatVar("Threshold", g_uberPluginPrefix + "_uberbug_threshold", 0.05f);
        UI::PopItemWidth();
        UI::TextDimmed("This is the maximum value for which a dot product is considered valid for a uberbug. If you have no idea what this means, leave it at default (0.8). Decrease slightly if you are getting false positives.");
        UI::Dummy(vec2(0, 5));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(30, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing1", g_uberPluginPrefix + "_bf_time_from");
        UI::PopItemWidth();
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(49, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing2", g_uberPluginPrefix + "_bf_time_to");
        UI::Dummy(vec2(0, 5));
        UI::PushItemWidth(231);
        UI::InputFloatVar("Min. speed", g_uberPluginPrefix + "_uberbug_min_speed", 10.0f);
        UI::PopItemWidth();
    }

    void OnRunStep(SimulationManager@ simManager) {
        int raceTime = simManager.RaceTime;
        if (!simManager.InRace || simManager.RaceTime < 0) {
            return;
        }
        TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
        if (challenge !is null && challenge.Uid != g_cachedChallengeUid) {
            CacheCheckpointData();
            if (challenge.Uid != g_cachedChallengeUid) return;
        }
    }
    uint64 last_ubertriggers_update = 0;

    array<int> g_uberbugDrawTriggerIds;
    array<int> g_trajectoryDrawTriggerIds;

    int prevTime = -1;

    vec3 prev1();
    vec3 prev2();

    void drawTrajectory(vec3 p1, vec3 p2){

        TM::GameState gameState = GetCurrentGameState();
        string cachedTriggerIds = GetVariableString(g_uberPluginPrefix + "_trajectory_trigger_cache");
        if (g_trajectoryDrawTriggerIds.Length == 0 && cachedTriggerIds != "") {
            array<string> ids = cachedTriggerIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i) {
                g_trajectoryDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        }
        if(!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_trajectory") || gameState != TM::GameState::LocalRace) {
            for(uint i = 0; i < g_trajectoryDrawTriggerIds.Length; i++) {
                RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
            }
            g_trajectoryDrawTriggerIds.Clear();
            return;
        }
        if(p1 == prev1 && p2 == prev2){
            if(g_trajectoryDrawTriggerIds.Length != 0) {
                return;
            }
        }
        prev1 = p1;
        prev2 = p2;
        for(uint i = 0; i < g_trajectoryDrawTriggerIds.Length; i++) {
            RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
        }
        g_trajectoryDrawTriggerIds.Clear();
        SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        vec3 dir = (p2 - p1).Normalized();
        float s = 0.4f;
        float spacing = 5.0f;
        vec3 size = vec3(s, s, s);
        vec3 max();
        vec3 min();
        max = p2;
        min = p1;
        string cache="";
        while(Math::Dot(max - min, dir) > 0){
            int id = SetTrigger(Trigger3D(min - size, size));
            g_trajectoryDrawTriggerIds.Add(id);
            min += dir * s * spacing;
            cache += Text::FormatInt(id) + ",";
        }
        if(cache.Length > 0) {
            cache.Erase(cache.Length - 1, 1);
            SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", cache);
        }
    }

    uint64 startTime = 0;

    void UberRender(){
        if(GetCurrentGameState() == TM::GameState::StartUp){
            startTime = Time::get_Now();
            return;
        }
        if(Time::get_Now() - startTime < 2000){
            return;
        }
        SimulationManager@ simManager = GetSimulationManager();
        int raceTime = simManager.RaceTime;
        if(GetVariableBool(g_uberPluginPrefix + "_uberbug_viz_follow_race")) {
            drawUberTriggers(raceTime);
        }else{
            drawUberTriggers(int(viztime*1000));
        }
        drawTrajectory(
            Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point1")),
            Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point2"))
        );
    }

    void drawUberTriggers(int time){
        
        TM::GameState gameState = GetCurrentGameState();

        string cachedTriggerIds = GetVariableString(g_uberPluginPrefix + "_uberbugs_trigger_cache");
        if (g_uberbugDrawTriggerIds.Length == 0 && cachedTriggerIds != "") {
            array<string> ids = cachedTriggerIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i) {
                g_uberbugDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        }

        if(!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_visualization") || gameState != TM::GameState::LocalRace) {
            for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; i++) {
                RemoveTrigger(g_uberbugDrawTriggerIds[i]);
            }
            g_uberbugDrawTriggerIds.Clear();
            return;
        }

        if(time == prevTime){
            if(!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_visualization")) {
                for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i) {
                    RemoveTrigger(g_uberbugDrawTriggerIds[i]);
                }
                g_uberbugDrawTriggerIds.Clear();
            }else if(g_uberbugDrawTriggerIds.Length != 0) {
                return;
            }
        }
        prevTime = time;
        if(!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_visualization")) {
                for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i) {
                    RemoveTrigger(g_uberbugDrawTriggerIds[i]);
                }
                g_uberbugDrawTriggerIds.Clear();
                return;
        }
        for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i) {
            RemoveTrigger(g_uberbugDrawTriggerIds[i]);
        }
        g_uberbugDrawTriggerIds.Clear();
        auto simManager = GetSimulationManager();
        if (simManager is null || !simManager.InRace) { return; }
        if(time < 0) {
            return;
        }
        if(uberbugStates.Length == 0) {
            return;
        }
        for(uint i = 0; i < uberbugStates.Length; ++i) {
            try{
                iso4 carTransform = uberbugStates[i][time/10];
                vec3 carWorldPos = carTransform.Position;
                mat3 carWorldRot = carTransform.Rotation;

                vec3 aabbMin, aabbSize;
                int id;

                vec3 mainBodyLocalHalfExtents(1.5f / 2.0f, 0.45 / 2.0f, 3.0f / 2.0f); 
                vec3 mainBodyLocalOffset(0.0f, 0.0f, 0.0f); 

                CalculateRotatedAABB(mainBodyLocalOffset, mainBodyLocalHalfExtents, carWorldPos, carWorldRot, aabbMin, aabbSize);
                id = SetTrigger(Trigger3D(aabbMin, aabbSize));
                g_uberbugDrawTriggerIds.Add(id);

                vec3 backPartLocalHalfExtents(0.6f / 2.0f, 0.5f / 2.0f, 0.6f / 2.0f); 
                vec3 backPartLocalOffset(0.0f, 0.4f, -0.8f); 

                CalculateRotatedAABB(backPartLocalOffset, backPartLocalHalfExtents, carWorldPos, carWorldRot, aabbMin, aabbSize);
                id = SetTrigger(Trigger3D(aabbMin, aabbSize));
                g_uberbugDrawTriggerIds.Add(id);

                vec3 topPartLocalHalfExtents(0.3f / 2.0f, 0.35f / 2.0f, 0.7f / 2.0f); 
                vec3 topPartLocalOffset(0.0f, 0.4f, 0.0f); 

                CalculateRotatedAABB(topPartLocalOffset, topPartLocalHalfExtents, carWorldPos, carWorldRot, aabbMin, aabbSize);
                id = SetTrigger(Trigger3D(aabbMin, aabbSize));
                g_uberbugDrawTriggerIds.Add(id);
            }catch{
                continue;
            }
        }
        string cache = "";
        for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i) {
            cache += Text::FormatInt(g_uberbugDrawTriggerIds[i]) + ",";
        }
        if(cache.Length > 0) {
            cache.Erase(cache.Length - 1, 1);
        }
        SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", cache);
    }

    string closestInputFile = "";

    void UberbugPageSettings(){
        UI::CheckboxVar("Show uberbugs visualization", g_uberPluginPrefix + "_uberbug_show_visualization");
        UI::Dummy(vec2(0, 1));
        if(!UI::CheckboxVar("Follow race", g_uberPluginPrefix + "_uberbug_viz_follow_race")){
            viztime=UI::SliderFloat("Time", viztime, 0, maxDur/1000.0f, "%.2f");
        }
        if(GetSimulationManager().InRace && uberbugStates.Length > 0 && UI::Button("Get inputs from closest car")){
            TM::GameCamera@ cam = GetCurrentCamera();
            vec3 position = cam.Location.Position;
            closestInputFile = "";
            float bestDist = 1e18f;
            int time = 0;
            if(GetVariableBool(g_uberPluginPrefix + "_uberbug_viz_follow_race")){
                time= GetSimulationManager().RaceTime;
            }else{
                time = int(viztime * 1000);
            }
            for(uint i = 0 ; i < uberbugStates.Length; i++){
                float d=Math::Distance(uberbugStates[i][time/10].Position, position);
                if(d < bestDist){
                    bestDist = d;
                    closestInputFile = runStatesResultFiles[i];
                }
            }
        }
        if(closestInputFile != ""){
            UI::Dummy(vec2(0, 1));
            UI::Text("Closest inputs found: " + closestInputFile);
            UI::Dummy(vec2(0, 1));
            if(UI::Button("Load inputs")){
                CommandList list(closestInputFile);
                list.Process();
                SetCurrentCommandList(list);
            }
            try{
                array<VariableInfo>@ vars = ListVariables();
                bool hasLoa = false;
                for(uint i = 0; i < vars.Length; ++i) {
                    if(vars[i].Name == "plugin_inputsloa_enabled") {
                        hasLoa = GetVariableBool("plugin_inputsloa_enabled");
                        break;
                    }
                }
                if(hasLoa){
                    if(UI::Button("Loa inputs")){
                        ExecuteCommand("loa " + closestInputFile);
                    }
                }
            }catch{}
        }
        UI::Dummy(vec2(0, 1));
        UI::CheckboxVar("Show trajectory preview", g_uberPluginPrefix + "_uberbug_show_trajectory");

    }

    void OnClearUberbugs(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
        
        for(uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i) {
            RemoveTrigger(g_uberbugDrawTriggerIds[i]);
        }
        g_uberbugDrawTriggerIds.Clear();
        SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        uberbugStates.Clear();
    }

    vec3 Mat3MultVec3(const mat3&in M, const vec3&in v) {
        return vec3(
            M.x.x * v.x + M.x.y * v.y + M.x.z * v.z, 
            M.y.x * v.x + M.y.y * v.y + M.y.z * v.z, 
            M.z.x * v.x + M.z.y * v.y + M.z.z * v.z  
        );
    }

    void CalculateRotatedAABB(
        const vec3&in localCenterOffset,    
        const vec3&in localHalfExtents,     
        const vec3&in carWorldPosition,     
        const mat3&in carWorldRotation,     
        vec3&out out_aabbMin,               
        vec3&out out_aabbSize               
    ) {

        vec3 worldBoxCenter = carWorldPosition + Mat3MultVec3(carWorldRotation, localCenterOffset);

        vec3 newGlobalHalfExtents;
        newGlobalHalfExtents.x = Math::Abs(carWorldRotation.x.x * localHalfExtents.x) + 
                                Math::Abs(carWorldRotation.y.x * localHalfExtents.y) + 
                                Math::Abs(carWorldRotation.z.x * localHalfExtents.z);
        newGlobalHalfExtents.y = Math::Abs(carWorldRotation.x.y * localHalfExtents.x) + 
                                Math::Abs(carWorldRotation.y.y * localHalfExtents.y) + 
                                Math::Abs(carWorldRotation.z.y * localHalfExtents.z);
        newGlobalHalfExtents.z = Math::Abs(carWorldRotation.x.z * localHalfExtents.x) + 
                                Math::Abs(carWorldRotation.y.z * localHalfExtents.y) + 
                                Math::Abs(carWorldRotation.z.z * localHalfExtents.z);

        out_aabbMin = worldBoxCenter - newGlobalHalfExtents;
        out_aabbSize = newGlobalHalfExtents * 2.0f;
    }
    array<vec3> g_polyVertsInCarSpace;
    array<vec3> g_transformedVertices;

    vec3 Normalize(vec3 v) {
        float magnitude = v.Length();
        if (magnitude > 1e-6f) {
            return v / magnitude;
        }
        return vec3(0,0,0);
    }

    vec3 Cross(vec3 a, vec3 b) {
        return vec3(a.y * b.z - a.z * b.y,
                    a.z * b.x - a.x * b.z,
                    a.x * b.y - a.y * b.x);
    }

    GmVec3 Cross(const GmVec3&in a, const GmVec3&in b) {
        return GmVec3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        );
    }

    const float EPSILON = 1e-6f;

    GmIso4 GetCarEllipsoidLocationByIndex(SimulationManager@ simM, const GmIso4&in carLocation, uint index) {
        if (index >= 8) {
            print("Error: Invalid ellipsoid index requested: " + index + ". Must be 0-7.", Severity::Error);
            return GmIso4();
        }
        if (index >= 4 && g_carEllipsoids.Length <= index) {
            print("Error: g_carEllipsoids array not initialized correctly for index " + index, Severity::Error);
            return GmIso4();
        }
        auto simManager = GetSimulationManager();
        GmIso4 worldTransform;
        if (index <= 3) {
            GmVec3 wheelSurfaceLocalPos;
            switch(index) {
                case 0: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.FrontLeft.SurfaceHandler.Location.Position); break;
                case 1: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.FrontRight.SurfaceHandler.Location.Position); break;
                case 2: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.BackLeft.SurfaceHandler.Location.Position); break;
                case 3: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.BackRight.SurfaceHandler.Location.Position); break;
                default:
                    print("Error: Unexpected index in wheel section: " + index, Severity::Error);
                    return GmIso4();
            }
            worldTransform.m_Rotation = carLocation.m_Rotation;
            GmVec3 worldSpaceOffset = carLocation.m_Rotation.Transform(wheelSurfaceLocalPos);
            worldTransform.m_Position = carLocation.m_Position + worldSpaceOffset;
        }
        else {
            const GmVec3@ localPositionOffset = g_carEllipsoids[index].center;
            const GmMat3@ localRotation = g_carEllipsoids[index].rotation;
            worldTransform.m_Rotation = carLocation.m_Rotation * localRotation;
            GmVec3 worldSpaceOffset = carLocation.m_Rotation.Transform(localPositionOffset);
            worldTransform.m_Position = carLocation.m_Position + worldSpaceOffset;
        }
        return worldTransform;
    }

    void InitializeCarEllipsoids() {
        g_carEllipsoids.Clear();
        const array<GmVec3> radii = {
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.439118f, 0.362f, 1.901528f),
            GmVec3(0.968297f, 0.362741f, 1.682276f),
            GmVec3(1.020922f, 0.515218f, 1.038007f),
            GmVec3(0.384841f, 0.905323f, 0.283418f)
        };
        const array<GmVec3> localPositions = {
            GmVec3(0.863012f, 0.3525f, 1.782089f),
            GmVec3(-0.863012f, 0.3525f, 1.782089f),
            GmVec3(0.885002f, 0.352504f, -1.205502f),
            GmVec3(-0.885002f, 0.352504f, -1.205502f),
            GmVec3(0.0f, 0.471253f, 0.219106f),
            GmVec3(0.0f, 0.448782f, -0.20792f),
            GmVec3(0.0f, 0.652812f, -0.89763f),
            GmVec3(-0.015532f, 0.363252f, 1.75357f)
        };
        array<GmMat3> localRotations;
        localRotations.Resize(8);
        localRotations[4].RotateX(Math::ToRad(3.4160502f));
        localRotations[5].RotateX(Math::ToRad(2.6202483f));
        localRotations[6].RotateX(Math::ToRad(2.6874702f));
        localRotations[7].RotateY(Math::ToRad(90.0f));
        localRotations[7].RotateX(Math::ToRad(90.0f));
        localRotations[7].RotateZ(Math::ToRad(-180.0f));
        for (uint i = 0; i < 8; ++i) {
            g_carEllipsoids.Add(Ellipsoid(localPositions[i], radii[i], localRotations[i]));
        }
    }

    float GmDot(const GmVec3&in a, const GmVec3&in b) {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    GmVec3 GmScale(const GmVec3&in a, const GmVec3&in b) {
        return GmVec3(a.x * b.x, a.y * b.y, a.z * b.z);
    }

    vec3 FindClosestPointOnPolyToOrigin_Native(const array<vec3>&in transformedVertices, const Polyhedron&in originalPoly) {
        if (transformedVertices.IsEmpty()) return vec3(0, 0, 0);

        vec3 centroid(0,0,0);
        for(uint i = 0; i < transformedVertices.Length; ++i) {
            centroid += transformedVertices[i];
        }
        if (!transformedVertices.IsEmpty()) {
            centroid /= float(transformedVertices.Length);
        }

        float max_dist = -1e18f;
        int best_face_index = -1;

        for (uint i = 0; i < originalPoly.precomputedFaces.Length; ++i) {
            const PrecomputedFace@ face_info = originalPoly.precomputedFaces[i];
            if (face_info.vertexIndices.Length < 3) continue;

            const vec3 v0 = transformedVertices[face_info.vertexIndices[0]];
            const vec3 v1 = transformedVertices[face_info.vertexIndices[1]];
            const vec3 v2 = transformedVertices[face_info.vertexIndices[2]];

            vec3 face_normal = Cross(v1 - v0, v2 - v0).Normalized();

            if (Math::Dot(face_normal, centroid - v0) > 0.0f) {

                face_normal = face_normal * -1.0f;
            }

            float dist = -Math::Dot(v0, face_normal);

            if (dist > max_dist) {
                max_dist = dist;
                best_face_index = i;
            }
        }

        if (best_face_index == -1) {
            float min_dist_sq = 1e18f;
            vec3 closest_point;
            for (uint i = 0; i < transformedVertices.Length; i++) {
                float dist_sq = transformedVertices[i].LengthSquared();
                if (dist_sq < min_dist_sq) {
                    min_dist_sq = dist_sq;
                    closest_point = transformedVertices[i];
                }
            }
            return closest_point;
        }

        const PrecomputedFace@ best_face = originalPoly.precomputedFaces[best_face_index];
        const array<int>@ vertexIndices = best_face.vertexIndices;

        const vec3 v0 = transformedVertices[vertexIndices[0]];
        const vec3 v1 = transformedVertices[vertexIndices[1]];
        const vec3 v2 = transformedVertices[vertexIndices[2]];
        vec3 best_face_normal = Cross(v1 - v0, v2 - v0).Normalized();
        if (Math::Dot(best_face_normal, centroid - v0) > 0.0f) {

            best_face_normal = best_face_normal * -1.0f;
        }

        vec3 projectedPoint = best_face_normal * -Math::Dot(v0, best_face_normal);

        bool isInside = true;
        for (uint j = 0; j < vertexIndices.Length; ++j) {
            const vec3 v_start = transformedVertices[vertexIndices[j]];
            const vec3 v_end = transformedVertices[vertexIndices[(j + 1) % vertexIndices.Length]];
            vec3 edge = v_end - v_start;
            vec3 to_point = projectedPoint - v_start;

            if (Math::Dot(Cross(edge, to_point), best_face_normal) < -EPSILON) {
                isInside = false;
                break;
            }
        }

        if (isInside) {
            return projectedPoint;
        } else {
            float min_dist_sq = 1e18f;
            vec3 closest_point_on_edge;
            for (uint j = 0; j < vertexIndices.Length; j++) {
                const vec3 vA = transformedVertices[vertexIndices[j]];
                const vec3 vB = transformedVertices[vertexIndices[(j + 1) % vertexIndices.Length]];
                vec3 point_on_edge = closest_point_on_segment_from_origin_native(vA, vB);
                float dist_sq = point_on_edge.LengthSquared();
                if (dist_sq < min_dist_sq) {
                    min_dist_sq = dist_sq;
                    closest_point_on_edge = point_on_edge;
                }
            }
            return closest_point_on_edge;
        }
    }

    vec3 GetClosestPointOnTransformedPolyhedron(const array<vec3>&in transformedVertices, const Polyhedron&in originalPoly) {
        uint64 polyCheckStartTime = Time::get_Now();

        vec3 closestPoint = FindClosestPointOnPolyToOrigin_Native(transformedVertices, originalPoly);
        g_totalClosestPointPolyTime += (Time::get_Now() - polyCheckStartTime); 
        return closestPoint;
    }

    float CalculateMinCarDistanceToPoly_Inner(const GmIso4&in carWorldTransformGm, const Polyhedron@ targetPoly) {
        if (targetPoly is null || targetPoly.vertices.IsEmpty()) {
            return 1e18f;
        }

        auto simManager = GetSimulationManager();
        float minDistanceSqOverall = 1e18f;

        iso4 carWorldTransform = carWorldTransformGm.ToIso4();

        mat3 carInvRotation = carWorldTransform.Rotation;

        g_polyVertsInCarSpace.Resize(targetPoly.vertices.Length);
        for (uint i = 0; i < targetPoly.vertices.Length; ++i) {
            vec3 v_rel_world = targetPoly.vertices[i] - carWorldTransform.Position;

            g_polyVertsInCarSpace[i] = vec3(
                carInvRotation.x.x * v_rel_world.x + carInvRotation.y.x * v_rel_world.y + carInvRotation.z.x * v_rel_world.z,
                carInvRotation.x.y * v_rel_world.x + carInvRotation.y.y * v_rel_world.y + carInvRotation.z.y * v_rel_world.z,
                carInvRotation.x.z * v_rel_world.x + carInvRotation.y.z * v_rel_world.y + carInvRotation.z.z * v_rel_world.z
            );
        }

        g_transformedVertices.Resize(targetPoly.vertices.Length);

        for (uint ellipsoidIndex = 0; ellipsoidIndex < g_carEllipsoids.Length; ++ellipsoidIndex) {
            const Ellipsoid@ baseEllipsoid = g_carEllipsoids[ellipsoidIndex];
            vec3 localPosition = baseEllipsoid.center.ToVec3();
            vec3 invRadii(1.0f / baseEllipsoid.radii.x, 1.0f / baseEllipsoid.radii.y, 1.0f / baseEllipsoid.radii.z);

            if (ellipsoidIndex <= 3) { 
                iso4 wheelSurfaceLocation;
                switch(ellipsoidIndex) {
                    case 0: wheelSurfaceLocation = simManager.Wheels.FrontLeft.SurfaceHandler.Location; break;
                    case 1: wheelSurfaceLocation = simManager.Wheels.FrontRight.SurfaceHandler.Location; break;
                    case 2: wheelSurfaceLocation = simManager.Wheels.BackLeft.SurfaceHandler.Location; break;
                    case 3: wheelSurfaceLocation = simManager.Wheels.BackRight.SurfaceHandler.Location; break;
                }
                localPosition = wheelSurfaceLocation.Position;

                for(uint i = 0; i < g_polyVertsInCarSpace.Length; ++i) {
                    g_transformedVertices[i] = Scale(g_polyVertsInCarSpace[i] - localPosition, invRadii);
                }
            } else { 

                mat3 localInvRotation = baseEllipsoid.rotation.ToMat3();

                for(uint i = 0; i < g_polyVertsInCarSpace.Length; ++i) {
                    vec3 v_relative_to_ellipsoid = g_polyVertsInCarSpace[i] - localPosition;

                    vec3 v_rotated = vec3(
                        localInvRotation.x.x * v_relative_to_ellipsoid.x + localInvRotation.y.x * v_relative_to_ellipsoid.y + localInvRotation.z.x * v_relative_to_ellipsoid.z,
                        localInvRotation.x.y * v_relative_to_ellipsoid.x + localInvRotation.y.y * v_relative_to_ellipsoid.y + localInvRotation.z.y * v_relative_to_ellipsoid.z,
                        localInvRotation.x.z * v_relative_to_ellipsoid.x + localInvRotation.y.z * v_relative_to_ellipsoid.y + localInvRotation.z.z * v_relative_to_ellipsoid.z
                    );
                    g_transformedVertices[i] = Scale(v_rotated, invRadii);
                }
            }

            vec3 p_poly_transformed = GetClosestPointOnTransformedPolyhedron(g_transformedVertices, targetPoly);

            if (p_poly_transformed.LengthSquared() < 1.0f - EPSILON) {
                return 0.0f; 
            }

            vec3 p_sphere_transformed = p_poly_transformed.Normalized();

            vec3 p_poly_carspace, p_sphere_carspace;

            vec3 p_poly_unscaled = Scale(p_poly_transformed, baseEllipsoid.radii.ToVec3());
            vec3 p_sphere_unscaled = Scale(p_sphere_transformed, baseEllipsoid.radii.ToVec3());

            if (ellipsoidIndex <= 3) { 
                p_poly_carspace = p_poly_unscaled + localPosition;
                p_sphere_carspace = p_sphere_unscaled + localPosition;
            } else { 

                mat3 localForwardRotation = baseEllipsoid.rotation.ToMat3();
                localForwardRotation.Transpose();

                p_poly_carspace = vec3(
                    localForwardRotation.x.x * p_poly_unscaled.x + localForwardRotation.y.x * p_poly_unscaled.y + localForwardRotation.z.x * p_poly_unscaled.z,
                    localForwardRotation.x.y * p_poly_unscaled.x + localForwardRotation.y.y * p_poly_unscaled.y + localForwardRotation.z.y * p_poly_unscaled.z,
                    localForwardRotation.x.z * p_poly_unscaled.x + localForwardRotation.y.z * p_poly_unscaled.y + localForwardRotation.z.z * p_poly_unscaled.z
                ) + localPosition;
                p_sphere_carspace = vec3(
                    localForwardRotation.x.x * p_sphere_unscaled.x + localForwardRotation.y.x * p_sphere_unscaled.y + localForwardRotation.z.x * p_sphere_unscaled.z,
                    localForwardRotation.x.y * p_sphere_unscaled.x + localForwardRotation.y.y * p_sphere_unscaled.y + localForwardRotation.z.y * p_sphere_unscaled.z,
                    localForwardRotation.x.z * p_sphere_unscaled.x + localForwardRotation.y.z * p_sphere_unscaled.y + localForwardRotation.z.z * p_sphere_unscaled.z
                ) + localPosition;
            }

            float distanceSq = (p_poly_carspace - p_sphere_carspace).LengthSquared();
            if (distanceSq < minDistanceSqOverall) {
                minDistanceSqOverall = distanceSq;
            }
        }

        return Math::Sqrt(minDistanceSqOverall);
    }

    float CalculateMinCarDistanceToPoly(const GmIso4&in carWorldTransform, const Polyhedron@ targetPoly) {
        uint64 funcStartTime = Time::get_Now();
        float result = CalculateMinCarDistanceToPoly_Inner(carWorldTransform, targetPoly);
        g_totalCalcMinCarDistTime += (Time::get_Now() - funcStartTime);
        return result;
    }

    Polyhedron ClipPolyhedronByPlane(const Polyhedron& in poly, const vec3& in clipPlaneNormal, const vec3& in clipPlanePoint)
    {
        if (poly.vertices.IsEmpty()) return poly;

        array<vec3> newVertices;
        array<array<int>> newFaces;
        dictionary vertexMap; 

        array<float> vertexDists(poly.vertices.Length);
        for (uint i = 0; i < poly.vertices.Length; i++) {
            vertexDists[i] = Math::Dot(poly.vertices[i] - clipPlanePoint, clipPlaneNormal);
        }

        for (uint faceIdx = 0; faceIdx < poly.faces.Length; faceIdx++) {
            const array<int>@ face = poly.faces[faceIdx];
            if (face.Length < 3) continue;

            array<int> newPolygonIndices; 

            for (uint i = 0; i < face.Length; i++) {
                int currOriginalIdx = face[i];
                int nextOriginalIdx = face[(i + 1) % face.Length];

                float currDist = vertexDists[currOriginalIdx];
                float nextDist = vertexDists[nextOriginalIdx];

                if (currDist <= EPSILON) {
                    string key = "" + currOriginalIdx;
                    int newIdx;
                    if (!vertexMap.Get(key, newIdx)) {
                        newIdx = newVertices.Length;
                        vertexMap.Set(key, newIdx);
                        newVertices.Add(poly.vertices[currOriginalIdx]);
                    }

                    if (newPolygonIndices.IsEmpty() || newPolygonIndices[newPolygonIndices.Length-1] != newIdx) {
                        newPolygonIndices.Add(newIdx);
                    }
                }

                if ((currDist > 0 && nextDist < 0) || (currDist < 0 && nextDist > 0)) {
                    float t = currDist / (currDist - nextDist);
                    vec3 intersectionPoint = poly.vertices[currOriginalIdx] + (poly.vertices[nextOriginalIdx] - poly.vertices[currOriginalIdx]) * t;

                    int newIdx = newVertices.Length;
                    newVertices.Add(intersectionPoint);

                    if (newPolygonIndices.IsEmpty() || newPolygonIndices[newPolygonIndices.Length-1] != newIdx) {
                        newPolygonIndices.Add(newIdx);
                    }
                }
            }

            if (newPolygonIndices.Length >= 3) {
                for (uint i = 1; i < newPolygonIndices.Length - 1; i++) {
                    array<int> newTriangle = {
                        newPolygonIndices[0],
                        newPolygonIndices[i],
                        newPolygonIndices[i + 1]
                    };
                    newFaces.Add(newTriangle);
                }
            }
        }

        Polyhedron clippedPoly(newVertices, newFaces);
        return clippedPoly;
    }

    Polyhedron ClipPolyhedronByAABB(const Polyhedron& in poly, const AABB& in box)
    {
        Polyhedron clippedPoly = poly;

        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(-1, 0, 0), box.min); 
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 1, 0, 0), box.max); 
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0,-1, 0), box.min); 
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0, 1, 0), box.max); 
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0, 0,-1), box.min); 
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0, 0, 1), box.max); 

        return clippedPoly;
    }

    vec3 Scale(const vec3&in a, const vec3&in b) {
        return vec3(a.x * b.x, a.y * b.y, a.z * b.z);
    }

    vec3 closest_point_on_segment_from_origin_native(const vec3&in a, const vec3&in b) {
        vec3 ab = b - a;

        float ab_len_sq = ab.LengthSquared();
        if (ab_len_sq < 1e-12f) { 
            return a;
        }

        float t = -Math::Dot(a, ab) / ab_len_sq;

        t = Math::Clamp(t, 0.0f, 1.0f);
        return a + ab * t;
    }

    GmVec3 closest_point_on_segment(const GmVec3&in p, const GmVec3&in a, const GmVec3&in b) {
        GmVec3 ab = b - a;
        float ab_len_sq = ab.LengthSquared();
        if (ab_len_sq < EPSILON * EPSILON) {
            return a;
        }
        float t = GmDot(p - a, ab) / ab_len_sq;
        t = Math::Max(0.0f, Math::Min(1.0f, t));
        return a + ab * t;
    }

    string vec3tostring(const vec3&in v) {
        return "x: " + v.x + ", y: " + v.y + ", z: " + v.z;
    }

}
