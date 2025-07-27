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
        UI::DragFloat3Var("##e", "bf_target_point", 0.0f, -100000.0f, 100000.0f, "%.3f");
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
    UI::InputTimeVar("##Nothinqefgg1", "bf_eval_min_time");
    UI::Text("To");
    UI::SameLine();
    UI::Dummy(vec2(36, 0));
    UI::SameLine();
    UI::PushItemWidth(200);
    UI::InputTimeVar("##Nothingsdfggrtzetgrz2", "bf_eval_max_time");
    UI::Dummy(vec2(0, 0));
    UI::TextDimmed("Reducing the maximum evaluation time will make the bruteforcing process faster.");
    UI::Dummy(vec2(0, 1));

    if(UI::CollapsingHeader("Advanced")){
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
        UI::InputFloatVar("##iujhqdf", "bf_condition_speed");
        if(GetVariableDouble("bf_condition_speed") < 0.0f){
            SetVariable("bf_condition_speed", 0.0f);
        }

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
        UI::InputFloatVar("##iujheqdf2", "bf_condition_distance");
        if(GetVariableDouble("bf_condition_distance") < 0.0f){
            SetVariable("bf_condition_distance", 0.0f);
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
        UI::InputIntVar("##iujheq2", "bf_condition_cps");
        if(GetVariableDouble("bf_condition_cps") < 0.0f){
            SetVariable("bf_condition_cps", 0.0f);
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
        UI::CheckboxVar("##qdifbhj", "bf_ignore_same_speed");

        UI::TextDimmed("Ignoring same speed improvements is particularly useful for bruteforcing air trajectories, where a different rotation but same speed would get rejected, despite the car being seemingly closer to target. This avoids flooding inputs and preventing real distance gains.");
    }
}

float bestDist = 1e18f;
float bestSpeed = 0.0f;
int bestTime = 0;
bool base = false;
bool improvedYet = false;
float currentBestDist = 1e18f;
float currentBestSpeed = 0.0f;
int currentBestTime = 0;
bool isRunBetter = false;
BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    int raceTime = simManager.RaceTime;

    auto resp = BFEvaluationResponse();

    bool isEvalTime = raceTime >= int(GetVariableDouble("bf_eval_min_time")) && raceTime <= int(GetVariableDouble("bf_eval_max_time"));
    bool isPastEvalTime = raceTime > int(GetVariableDouble("bf_eval_max_time"));

    if (info.Phase == BFPhase::Initial) {
        if (isEvalTime) {
            float d = dist();
            float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();
            int cps = simManager.PlayerInfo.CurCheckpointCount;
            if(isBetter(d, speed, cps)){
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
                    print("Base run: -1.000000000 m, -1.000000000 km/h at invalid");
                }else{
                    print("Base run: " + Text::FormatFloat(bestDist,"", 0, 9) + " m, " + Text::FormatFloat(bestSpeed*3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2));
                }
            }
        }
    } else {

        if(isEvalTime){
            float d = dist();
            float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();
            int cps = simManager.PlayerInfo.CurCheckpointCount;

            if(isBetter(d, speed, cps)){
                bool isBestInThisRun;
                if (!isRunBetter) {
                    isBestInThisRun = true;
                } else {
                    if (weight <= 50) {
                        isBestInThisRun = (d - k * speed) < (currentBestDist - k * currentBestSpeed);
                    } else {
                        isBestInThisRun = (speed - k * d) > (currentBestSpeed - k * currentBestSpeed);
                    }
                }

                if (isBestInThisRun) {
                    currentBestDist = d;
                    currentBestSpeed = speed;
                    currentBestTime = raceTime;
                }
                isRunBetter = true;
            }
        }

        if(isPastEvalTime){
            if(isRunBetter){
                string text = "Found better distance/speed: " + Text::FormatFloat(currentBestDist, "", 0, 9) + " m, " + Text::FormatFloat(currentBestSpeed*3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(currentBestTime/1000.0, "", 0, 2) + ", iterations: " + info.Iterations;
                print(text, Severity::Success);
                resp.ResultFileStartContent ="# " + text;
                resp.Decision = BFEvaluationDecision::Accept;
                improvedYet = false;
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
float speedCondition = 0.0f;
float distCondition = 0.0f;
int cpsCondition = 0;

bool meetsConditions(float dist, float speed, int cps = 0) {
    return dist < distCondition && speed > speedCondition/3.6f && cps >= cpsCondition;
}

bool isBetter(float dist, float speed, int cps) {
    if(meetsConditions(dist, speed, cps)){
        if(!improvedYet){
            improvedYet = true;
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
    if (!(GetVariableString("bf_target") == bfid && GetVariableString("controller") == "bruteforce")) {
        return;
    }
    bestSpeed = -1.0f;
    bestDist = -1.0f;
    bestTime = 0;
    improvedYet = false;
    weight = int(GetVariableDouble("bf_weight"));
    target = Text::ParseVec3(GetVariableString("bf_target_point"));
    if (weight <= 50) {
        k = float(weight) / (100.0f - float(weight));
    } else {
        k = (100.0f - float(weight)) / float(weight);
    }
    base = true;
    speedCondition = GetVariableDouble("bf_condition_speed");
    distCondition = GetVariableDouble("bf_condition_distance") > 0.0f ? GetVariableDouble("bf_condition_distance") : 1e18f;
    ignoreSameSpeed = GetVariableBool("bf_ignore_same_speed") ? 1 : 0;
    cpsCondition = int(GetVariableDouble("bf_condition_cps"));
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
    RegisterBruteforceEvaluation(bfid, "Single point (better)", OnEvaluate, RenderEvalSettings);
    RegisterVariable("bf_condition_distance", 0.0f);
    RegisterVariable("bf_ignore_same_speed", false);
    RegisterVariable("bf_condition_cps", 0);
}
PluginInfo@ GetPluginInfo() {
    auto info = PluginInfo();
    info.Name = "Single point BF";
    info.Author = "Skycrafter";
    info.Version = "1.0.0";
    info.Description = "Better single point bruteforce eval.";
    return info;
}
