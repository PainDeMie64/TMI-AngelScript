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

void BruteforceV2Settings(){
    UI::Dummy(vec2(0,15));
    if(UI::CollapsingHeader("Behavior")){
        UI::Dummy(vec2(0,15)); // UI::Dummy(vec2(0,65)); to match built-in UI spacing
        UI::PushItemWidth(300);
        UI::InputTextVar("Filename used for saving results", "bf_result_filename");
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

    UI::CollapsingHeader("Conditions");
    
    if(UI::CollapsingHeader("Input Modification")){
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
        UI::Dummy(vec2(36,0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_max_time", "bf_inputs_max_time");
        UI::PopItemWidth();

        UI::TextDimmed("Limiting this time frame will make the bruteforcing process faster.");

        UI::Dummy(vec2(0,15));

        UI::PushItemWidth(320);
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
    FinishBf::Main();
}

void RegisterBruteforceEval(const string&in identifier, const string&in title, OnBruteforceEvaluate@ callback, RenderBruteforceEvaluationSettings@ renderCallback = null){
    BruteforceEvaluation eval;
    eval.identifier = identifier;
    eval.title = title;
    @eval.callback = callback;
    @eval.renderCallback = renderCallback;
    evaluations.Add(eval);   
}

class BruteforceEvaluation {
    string identifier;
    string title;
    OnBruteforceEvaluate@ callback;
    RenderBruteforceEvaluationSettings@ renderCallback;
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
array<InputCommand>@ baseInputs;
array<InputCommand>@ currentInputs;

bool forceStop = false;

array<TM::InputEvent> bestInputEvents;
bool hasBestInputs = false;

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


SimulationState rewindState;

void OnSimulationBegin(SimulationManager@ simManager) {
    if (!(GetVariableString("controller")=="bfv2")) return;
    simManager.RemoveStateValidation();

    @current = @GetBruteforceTarget();
    if (current is null) {
        SetVariable("bf_target", evaluations[0].identifier);
        @current = @evaluations[0];
    }

    info.Iterations = 0;
    info.Phase = BFPhase::Initial;
    info.Rewinded = false;
    forceStop = false;

    inputCount = int(GetVariableDouble("bf_modify_count"));
    minInputsTime = int(GetVariableDouble("bf_inputs_min_time"));
    maxInputsTime = int(GetVariableDouble("bf_inputs_max_time"));
    maxSteerDiff = int(GetVariableDouble("bf_max_steer_diff"));
    maxTimeDiff = int(GetVariableDouble("bf_max_time_diff"));
    fillSteerInputs = GetVariableBool("bf_inputs_fill_steer");

    bestInputEvents.Resize(0);
    hasBestInputs = false;
    SaveBestInputs(simManager);

    print("Bruteforce V2 started with target: " + GetVariableString("bf_target"));
}

int prevTime = -1;

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled){
    if (!(GetVariableString("controller")=="bfv2")) return;
    if(forceStop || userCancelled) return;



    int raceTime = simManager.RaceTime;
    BFEvaluationResponse@ response = current.callback(simManager, info);


    if(simManager.RaceTime == prevTime && !info.Rewinded && response.Decision != BFEvaluationDecision::Accept){    
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
        // print("Rewind due to no progress in time.");
        return;
    }
    prevTime = simManager.RaceTime;
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
                // print("Rewind from do nothing.");
            }
        } else if(response.Decision == BFEvaluationDecision::Accept){
            SaveBestInputs(simManager, false);
            CommandList list;
            RestoreBestInputs(simManager, false);
            list.Content = simManager.InputEvents.ToCommandsText();
            print(list.Save(GetVariableString("bf_result_filename"))? "Saved improved inputs to " + GetVariableString("bf_result_filename") : "Failed to save improved inputs.");   
            simManager.RewindToState(rewindState);
            RestoreBestInputs(simManager, false);
            info.Rewinded = true;
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
            // print("Rewind from rejection.");
        } else if(response.Decision == BFEvaluationDecision::Stop){
            forceStop = true;
        }
    }
}    

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result) {
    if (!(GetVariableString("controller")=="bfv2")) return;
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

