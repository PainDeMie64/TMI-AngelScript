PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Bruteforce V2";
    info.Author = "Skycrafter";
    info.Version = "1.2";
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
