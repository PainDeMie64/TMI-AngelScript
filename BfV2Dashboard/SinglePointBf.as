namespace SinglePointBf
{
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
    float shiftThreshold = 0.0f;
    bool shifted = false;
    void RenderEvalSettings()
    {
        if (UI::BeginTable("##ratio_table", 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::PushItemWidth(300);
            UI::SliderIntVar("Ratio", "bf_weight", 0, 100, "%d%%");
            if (!(GetVariableDouble("bf_weight") < 1.0f || GetVariableDouble("bf_weight") > 99.0f))
            {
                UI::SameLine();
                UI::Text("❔");
                if (UI::IsItemHovered())
                {
                    UI::BeginTooltip();
                    if (GetVariableDouble("bf_weight") <= 50)
                    {
                        UI::Text("This ratio means gaining 1m is worth sacrificing speed until " + Text::FormatFloat(100 / GetVariableDouble("bf_weight") - 1, "", 0, 3) + "m/s.");
                    }
                    else
                    {
                        UI::Text("This ratio means gaining 1m/s is worth sacrificing distance until " + Text::FormatFloat(100 / (100 - GetVariableDouble("bf_weight")) - 1, "", 0, 3) + "m.");
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
        if (GetVariableDouble("bf_weight") <= 99)
        {
            UI::Dummy(vec2(9, 0));
            UI::SameLine();
            UI::Text("Target position:");
            UI::SameLine();
            UI::DragFloat3Var("##bf_target_point", "bf_target_point", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if (GetSimulationManager().InRace)
            {
                UI::Dummy(vec2(0, 5));
                UI::Dummy(vec2(119, 0));
                UI::SameLine();
                if (GetCurrentCamera().NameId != "")
                {
                    if (UI::Button("    Copy from Vehicle Coordinates"))
                    {
                        SetVariable("bf_target_point", pos().ToString());
                    }
                }
                else
                {
                    if (UI::Button("    Copy from Camera Coordinates"))
                    {
                        SetVariable("bf_target_point", GetCurrentCamera().Location.Position.ToString());
                    }
                }
            }
            UI::Dummy(vec2(0, 2));
        }
        if (UI::BeginTable("##time_table", 1))
        {
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
        UI::InputFloatVar("Shift threshold##bf_singlepoint_shift", "bf_singlepoint_shift_threshold");
        if (GetVariableDouble("bf_singlepoint_shift_threshold") < 0.0f)
        {
            SetVariable("bf_singlepoint_shift_threshold", 0.0f);
        }
        toolTip(300, {"When the car gets within this distance of the target, shift the evaluation window earlier.", "Set to 0 to disable. Works similarly to Distance to Finish's shift feature."});
        UI::Dummy(vec2(0, 0));
        UI::PushItemWidth(160);
        if (GetVariableDouble("bf_condition_distance") > 0.0f)
        {
            UI::Text("Max. distance ");
        }
        else
        {
            UI::BeginDisabled();
            UI::Text("Max. distance ");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(-2, 0));
        UI::SameLine();
        UI::InputFloatVar("##bf_condition_distance", "bf_condition_distance");
        if (GetVariableDouble("bf_condition_distance") < 0.0f)
        {
            SetVariable("bf_condition_distance", 0.0f);
        }
        UI::Dummy(vec2(0, 0));
        if (UI::BeginTable("##ignore_speed_table", 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            if (GetVariableBool("bf_ignore_same_speed"))
            {
                UI::Text("Ignore same speed improvements");
            }
            else
            {
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
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        bool isEvalTime = raceTime >= minTime && raceTime <= maxTime;
        bool isPastEvalTime = raceTime > maxTime;
        bool conditionsMet = GlobalConditionsMet(simManager);
        if (info.Phase == BFPhase::Initial)
        {
            if (isEvalTime)
            {
                float d = dist();
                float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();
                if (conditionsMet && isBetter(d, speed))
                {
                    bestDist = d;
                    bestSpeed = speed;
                    bestTime = raceTime;
                }
            }
            if (isPastEvalTime)
            {
                resp.Decision = BFEvaluationDecision::Accept;
                if (base)
                {
                    base = false;
                    if (bestSpeed < 0.0f)
                    {
                        print("Base run: Invalid", Severity::Warning);
                        resp.ResultFileStartContent = "# Base run: Invalid";
                    }
                    else
                    {
                        print("Base run: " + Text::FormatFloat(bestDist, "", 0, 9) + " m, " + Text::FormatFloat(bestSpeed * 3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(bestTime / 1000.0, "", 0, 2));
                        resp.ResultFileStartContent = "# Base run: " + Text::FormatFloat(bestDist, "", 0, 9) + " m, " + Text::FormatFloat(bestSpeed * 3.6, "", 0, 9) + " km/h at " + Text::FormatFloat(bestTime / 1000.0, "", 0, 2);
                    }
                }
            }
        }
        else
        {
            if (isEvalTime)
            {
                float d = dist();
                float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();
                if (conditionsMet && isBetter(d, speed))
                {
                    isRunBetter = true;
                }
                if (shiftThreshold > 0 && !shifted && d < shiftThreshold)
                {
                    CommandList shiftSave();
                    shiftSave.Content = simManager.InputEvents.ToCommandsText();
                    print("");
                    print("Single point within " + Text::FormatFloat(shiftThreshold, "", 0, 3) + "m at " + raceTime + "ms, shifting evaluation earlier...", Severity::Warning);
                    print("File saved: " + shiftSave.Save(GetVariableString("bf_result_filename").Split(".")[0] + "_restart" + restartCount + "_shift.txt"));
                    maxTime = raceTime - 10;
                    if (minTime > maxTime)
                    {
                        minTime = maxTime;
                    }
                    bestDist = 1e18f;
                    bestSpeed = -1.0f;
                    bestTime = 0;
                    base = true;
                    shifted = true;
                    isRunBetter = false;
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                }
            }
            if (isPastEvalTime)
            {
                if (isRunBetter)
                {
                    resp.Decision = BFEvaluationDecision::Accept;
                    base = true;
                }
                else
                {
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
    bool meetsConditions(float dist)
    {
        return dist < distCondition && GlobalConditionsMet(GetSimulationManager());
    }
    bool isBetter(float dist, float speed)
    {
        if (meetsConditions(dist))
        {
            if (bestSpeed < 0.0f)
            {
                return true;
            }
            if (weight <= 50)
            {
                return (dist - k * speed) < (bestDist - k * bestSpeed) && speed * ignoreSameSpeed != bestSpeed;
            }
            else
            {
                return (speed - k * dist) > (bestSpeed - k * bestDist);
            }
        }
        return false;
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        if (!(GetVariableString("bf_target") == bfid))
        {
            return;
        }
        minTime = int(GetVariableDouble("bf_eval_min_time"));
        maxTime = int(GetVariableDouble("bf_eval_max_time"));
        maxTime = ResolveMaxTime(maxTime, int(simManager.EventsDuration));
        bestSpeed = -1.0f;
        bestDist = 1e18f;
        bestTime = 0;
        weight = int(GetVariableDouble("bf_weight"));
        target = Text::ParseVec3(GetVariableString("bf_target_point"));
        if (weight <= 50)
        {
            k = float(weight) / (100.0f - float(weight));
        }
        else
        {
            k = (100.0f - float(weight)) / float(weight);
        }
        base = true;
        distCondition = GetVariableDouble("bf_condition_distance") > 0.0f ? GetVariableDouble("bf_condition_distance") : 1e18f;
        ignoreSameSpeed = GetVariableBool("bf_ignore_same_speed") ? 1 : 0;
        shiftThreshold = float(GetVariableDouble("bf_singlepoint_shift_threshold"));
        shifted = false;
    }
    float dist()
    {
        return Math::Distance(pos(), target);
    }
    vec3 pos()
    {
        return GetSimulationManager().Dyna.CurrentState.Location.Position;
    }
    string id = "betterpoint";
    string bfid = "betterpoint";
    void Main()
    {
        RegisterVariable("bf_condition_distance", 0.0f);
        RegisterVariable("bf_ignore_same_speed", false);
        RegisterVariable("bf_condition_cps", 0);
        RegisterVariable("bf_singlepoint_shift_threshold", 0.0f);
        auto eval = RegisterBruteforceEval(bfid, "Single point", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
