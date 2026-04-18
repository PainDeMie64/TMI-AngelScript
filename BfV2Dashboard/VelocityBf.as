namespace VelocityBf
{
    int minTime = 0;
    int maxTime = 0;
    vec3 targetVelocity = vec3(0, 0, 0);
    string currentVelocityType = "Global";
    void RenderEvalSettings()
    {
        UI::Dummy(vec2(0, 0));
        currentVelocityType = GetVariableString("bf_velocity_type");
        if (UI::BeginCombo("Velocity Type", currentVelocityType))
        {
            if (UI::Selectable("Global", currentVelocityType == "Global"))
            {
                SetVariable("bf_velocity_type", "Global");
            }
            if (UI::Selectable("Trajectory", currentVelocityType == "Trajectory"))
            {
                SetVariable("bf_velocity_type", "Trajectory");
            }
            UI::EndCombo();
        }
        if (currentVelocityType == "Trajectory")
        {
            UI::Dummy(vec2(0, 10));
            UI::Text("From:");
            UI::SameLine();
            UI::DragFloat3Var("##bf_velocity_from", "bf_velocity_from", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if (GetSimulationManager().InRace)
            {
                UI::Dummy(vec2(0, 2));
                UI::Dummy(vec2(119, 0));
                UI::SameLine();
                if (GetCurrentCamera().NameId != "")
                {
                    if (UI::Button("Copy from Vehicle Coordinates##bf_velocity_from"))
                    {
                        SetVariable("bf_velocity_from", pos().ToString());
                    }
                }
                else
                {
                    if (UI::Button("Copy from Camera Coordinates##bf_velocity_from"))
                    {
                        SetVariable("bf_velocity_from", GetCurrentCamera().Location.Position.ToString());
                    }
                }
            }
            UI::Text("To:");
            UI::SameLine();
            UI::Dummy(vec2(11, 0));
            UI::SameLine();
            UI::DragFloat3Var("##bf_velocity_to", "bf_velocity_to", 0.1f, -100000.0f, 100000.0f, "%.3f");
            if (GetSimulationManager().InRace)
            {
                UI::Dummy(vec2(0, 2));
                UI::Dummy(vec2(119, 0));
                UI::SameLine();
                if (GetCurrentCamera().NameId != "")
                {
                    if (UI::Button("Copy from Vehicle Coordinates##bf_velocity_to"))
                    {
                        SetVariable("bf_velocity_to", pos().ToString());
                    }
                }
                else
                {
                    if (UI::Button("Copy from Camera Coordinates##bf_velocity_to"))
                    {
                        SetVariable("bf_velocity_to", GetCurrentCamera().Location.Position.ToString());
                    }
                }
            }
        }
        UI::Dummy(vec2(0, 10));
        float val = GetVariableDouble("bf_velocity_min_percent");
        string valText = Text::FormatFloat(val * 100.0f, "", 0, 1) + "%% Minimum matching velocity";
        UI::SliderFloatVar("##bf_velocity_min_percent", "bf_velocity_min_percent", -1.0f, 1.0f, valText);
        toolTip(300, {"Minimum percentage of the car's velocity that must match the target trajectory.", "A negative value means the velocity can be in the opposite direction.", "-100% minimum means any velocity is accepted, as it tells bruteforce the minimum it can accept is going in the complete opposite direction."});
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
    vec3 pos()
    {
        return GetSimulationManager().Dyna.CurrentState.Location.Position;
    }
    float bestSpeed = -1e18f;
    int bestTime = 0;
    float bestMatchingPercnt = 0.0f;
    float matchingPercnt = 0.0f;
    float minMatchingPercnt = -1.0f;
    VelocityType bfVelocityType;
    enum VelocityType
    {
        Global,
        Trajectory
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
                float v = computeVel(simManager);
                if (bfVelocityType == VelocityType::Trajectory)
                {
                    if (conditionsMet && v > bestSpeed && matchingPercnt >= minMatchingPercnt)
                    {
                        bestSpeed = v;
                        bestTime = raceTime;
                        bestMatchingPercnt = matchingPercnt;
                    }
                }
                else if (conditionsMet && v > bestSpeed)
                {
                    bestSpeed = v;
                    bestTime = raceTime;
                    bestMatchingPercnt = matchingPercnt;
                }
            }
            if (isPastEvalTime)
            {
                resp.Decision = BFEvaluationDecision::Accept;
                if (bestSpeed == -1e18f)
                {
                    print("Base run: Invalid", Severity::Warning);
                    resp.ResultFileStartContent = "# Base run: Invalid";
                }
                else
                {
                    if (bfVelocityType == VelocityType::Global)
                    {
                        string t = "Base run: " + Text::FormatFloat(bestSpeed, "", 0, 3) + " m/s at " + Text::FormatFloat(bestTime / 1000.0, "", 0, 2);
                        resp.ResultFileStartContent = "# " + t;
                        print(t);
                    }
                    else
                    {
                        string t = "Base run: " + Text::FormatFloat(bestSpeed, "", 0, 3) + " m/s along trajectory at " + Text::FormatFloat(bestTime / 1000.0, "", 0, 2) + " (" + Text::FormatFloat(bestMatchingPercnt * 100.0f, "", 0, 2) + "% of global velocity matching trajectory)";
                        resp.ResultFileStartContent = "# " + t;
                        print(t);
                    }
                }
            }
        }
        else
        {
            if (isEvalTime)
            {
                float v = computeVel(simManager);
                if (bfVelocityType == VelocityType::Trajectory)
                {
                    if (conditionsMet && v > bestSpeed && matchingPercnt >= minMatchingPercnt)
                    {
                        bestSpeed = v;
                        bestTime = raceTime;
                        bestMatchingPercnt = matchingPercnt;
                        resp.Decision = BFEvaluationDecision::Accept;
                    }
                }
                else if (conditionsMet && v > bestSpeed)
                {
                    bestSpeed = v;
                    bestTime = raceTime;
                    bestMatchingPercnt = matchingPercnt;
                    resp.Decision = BFEvaluationDecision::Accept;
                }
            }
            if (isPastEvalTime && resp.Decision != BFEvaluationDecision::Accept)
            {
                resp.Decision = BFEvaluationDecision::Reject;
            }
        }
        return resp;
    }
    float computeVel(SimulationManager @simManager)
    {
        if (bfVelocityType == VelocityType::Global)
        {
            return simManager.Dyna.CurrentState.LinearSpeed.Length();
        }
        else if (bfVelocityType == VelocityType::Trajectory)
        {
            float denom = targetVelocity.Length();
            if (denom > 1e-7f)
            {
                vec3 vel = simManager.Dyna.CurrentState.LinearSpeed;
                matchingPercnt = Math::Dot(vel.Normalized(), targetVelocity);
                return matchingPercnt * vel.Length();
            }
            else
            {
                return -9e8f;
            }
        }
        else
        {
            print("Should not happen, please report to plugin dev", Severity::Error);
            return 0;
        }
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        bestSpeed = -1e18f;
        minTime = int(GetVariableDouble("bf_eval_min_time"));
        maxTime = int(GetVariableDouble("bf_eval_max_time"));
        maxTime = ResolveMaxTime(maxTime, int(simManager.EventsDuration));
        targetVelocity = Text::ParseVec3(GetVariableString("bf_velocity_to")) - Text::ParseVec3(GetVariableString("bf_velocity_from"));
        targetVelocity = targetVelocity.Normalized();
        if (GetVariableString("bf_velocity_type") == "Global")
        {
            bfVelocityType = VelocityType::Global;
            minMatchingPercnt = -1.0f;
        }
        else
        {
            bfVelocityType = VelocityType::Trajectory;
            minMatchingPercnt = GetVariableDouble("bf_velocity_min_percent");
        }
        bestMatchingPercnt = 0.0f;
        matchingPercnt = 0.0f;
    }
    void Main()
    {
        RegisterVariable("bf_velocity_type", "Global");
        RegisterVariable("bf_velocity_from", "0 0 0");
        RegisterVariable("bf_velocity_to", "0 0 0");
        RegisterVariable("bf_velocity_min_percent", -1.0f);
        auto eval = RegisterBruteforceEval("velocity", "Velocity", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
