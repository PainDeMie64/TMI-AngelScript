namespace StandardTriggerBf
{
    Trigger3D targetTrigger;
    int weight = 0;
    float k = 0.0f;
    bool base = false;
    int entryTick = -1;
    float speedAtEntry = 0.0f;
    float distBeforeEntry = 0.0f;
    vec3 prevTickPos = vec3(0, 0, 0);
    bool prevTickValid = false;
    bool entryDetected = false;
    int bestEntryTick = -1;
    float bestSpeedAtEntry = -1.0f;
    float bestDistBeforeEntry = 1e18f;
    bool isBetter(int time, float dist, float speed)
    {
        if (bestSpeedAtEntry < 0.0f)
            return true;
        if (weight == 100)
            return speed > bestSpeedAtEntry;
        if (time < bestEntryTick)
        {
            if (weight == 0)
                return true;
            float w = float(weight);
            float speedLoss = Math::Max(0.0f, bestSpeedAtEntry - speed);
            if (speedLoss <= 0.0f)
                return true;
            float timeBenefit = float(bestEntryTick - time);
            return timeBenefit * (100.0f - w) >= speedLoss * w;
        }
        if (time == bestEntryTick)
        {
            if (weight == 0)
                return dist < bestDistBeforeEntry;
            if (weight <= 50)
            {
                return (dist - k * speed) < (bestDistBeforeEntry - k * bestSpeedAtEntry);
            }
            else
            {
                return (speed - k * dist) > (bestSpeedAtEntry - k * bestDistBeforeEntry);
            }
        }
        if (time > bestEntryTick)
        {
            if (weight == 0)
                return false;
            float w = float(weight);
            float speedGain = Math::Max(0.0f, speed - bestSpeedAtEntry);
            if (speedGain <= 0.0f)
                return false;
            float timeLoss = float(time - bestEntryTick);
            return speedGain * w > timeLoss * (100.0f - w);
        }
        return false;
    }
    void RenderEvalSettings()
    {
        uint triggerIndex = uint(GetVariableDouble("bf_stdtrigger_trigger"));
        array<int> @triggerIds = GetTriggerIds();
        if (triggerIds.Length == 0)
        {
            UI::Text("No triggers found.");
            return;
        }
        if (triggerIndex >= triggerIds.Length)
        {
            triggerIndex = 0;
            SetVariable("bf_stdtrigger_trigger", 0);
        }
        Trigger3D selectedTrigger = GetTrigger(triggerIds[triggerIndex]);
        vec3 pos = selectedTrigger.Position;
        if (UI::BeginCombo("Target Trigger", (triggerIndex + 1) + ". Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")"))
        {
            for (uint i = 0; i < triggerIds.Length; i++)
            {
                Trigger3D trigger = GetTrigger(triggerIds[i]);
                pos = trigger.Position;
                string triggerName = (i + 1) + ". Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")";
                if (UI::Selectable(triggerName, triggerIndex == i))
                {
                    SetVariable("bf_stdtrigger_trigger", i);
                }
            }
            UI::EndCombo();
        }
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##stdtrigger_ratio_table", 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::PushItemWidth(300);
            UI::SliderIntVar("Ratio", "bf_stdtrigger_weight", 0, 100, "%d%%");
            if (!(GetVariableDouble("bf_stdtrigger_weight") < 1.0f || GetVariableDouble("bf_stdtrigger_weight") > 99.0f))
            {
                UI::SameLine();
                UI::Text("❔");
                if (UI::IsItemHovered())
                {
                    UI::BeginTooltip();
                    if (GetVariableDouble("bf_stdtrigger_weight") <= 50)
                    {
                        UI::Text("This ratio means gaining 1m is worth sacrificing speed until " + Text::FormatFloat(100 / GetVariableDouble("bf_stdtrigger_weight") - 1, "", 0, 3) + "m/s.");
                    }
                    else
                    {
                        UI::Text("This ratio means gaining 1m/s is worth sacrificing distance until " + Text::FormatFloat(100 / (100 - GetVariableDouble("bf_stdtrigger_weight")) - 1, "", 0, 3) + "m.");
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
        toolTip(300, {"The ratio slider determines which metric bruteforce should value more.",
                      "Setting the slider fully to the left side (0%) will just optimize how fast the vehicle gets to the trigger.",
                      "Setting the slider fully to the right side (100%) will instead optimize only vehicle speed when it enters the trigger."});
    }
    int lastRaceTime = -1;
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        if (raceTime < lastRaceTime)
        {
            entryTick = -1;
            speedAtEntry = 0.0f;
            distBeforeEntry = 0.0f;
            prevTickValid = false;
            entryDetected = false;
        }
        lastRaceTime = raceTime;
        vec3 carPos = simManager.Dyna.CurrentState.Location.Position;
        if (!entryDetected)
        {
            bool inTrigger = targetTrigger.ContainsPoint(carPos);
            if (inTrigger)
            {
                entryDetected = true;
                entryTick = raceTime;
                speedAtEntry = simManager.Dyna.CurrentState.LinearSpeed.Length();
                if (prevTickValid)
                {
                    distBeforeEntry = targetTrigger.Distance(prevTickPos);
                }
                else
                {
                    distBeforeEntry = targetTrigger.Distance(carPos);
                }
            }
            prevTickPos = carPos;
            prevTickValid = true;
        }
        if (!entryDetected)
            return resp;
        if (raceTime != entryTick)
            return resp;
        bool conditionsMet = GlobalConditionsMet(simManager);
        if (info.Phase == BFPhase::Initial)
        {
            if (conditionsMet)
            {
                bestEntryTick = entryTick;
                bestSpeedAtEntry = speedAtEntry;
                bestDistBeforeEntry = distBeforeEntry;
            }
            resp.Decision = BFEvaluationDecision::Accept;
            if (base)
            {
                base = false;
                if (conditionsMet)
                {
                    print("Base run: entry at " + Text::FormatFloat(entryTick / 1000.0, "", 0, 3)
                        + " s, speed " + Text::FormatFloat(speedAtEntry * 3.6, "", 0, 3)
                        + " km/h, dist before " + Text::FormatFloat(distBeforeEntry, "", 0, 6) + " m");
                    resp.ResultFileStartContent = "# Base: entry " + Text::FormatFloat(entryTick / 1000.0, "", 0, 3)
                        + " s, " + Text::FormatFloat(speedAtEntry * 3.6, "", 0, 3)
                        + " km/h, dist " + Text::FormatFloat(distBeforeEntry, "", 0, 6) + " m";
                }
                else
                {
                    print("Base run: entry at " + Text::FormatFloat(entryTick / 1000.0, "", 0, 3)
                        + " s but conditions not met. Search will require conditions.", Severity::Warning);
                    resp.ResultFileStartContent = "# Base: conditions not met";
                }
            }
        }
        else
        {
            if (!conditionsMet)
            {
                resp.Decision = BFEvaluationDecision::Reject;
                return resp;
            }
            if (isBetter(entryTick, distBeforeEntry, speedAtEntry))
            {
                print("Found better trigger: [time: " + Text::FormatFloat(entryTick / 1000.0, "", 0, 2)
                    + ", distance: " + Text::FormatFloat(distBeforeEntry, "", 0, 8)
                    + ", speed: " + Text::FormatFloat(speedAtEntry * 3.6, "", 0, 2) + "km/h]"
                    + " is better than [time: " + Text::FormatFloat(bestEntryTick / 1000.0, "", 0, 2)
                    + ", distance: " + Text::FormatFloat(bestDistBeforeEntry, "", 0, 8)
                    + ", speed: " + Text::FormatFloat(bestSpeedAtEntry * 3.6, "", 0, 2) + "km/h]"
                    + ", iterations: " + info.Iterations);
                bestEntryTick = entryTick;
                bestSpeedAtEntry = speedAtEntry;
                bestDistBeforeEntry = distBeforeEntry;
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Entry " + Text::FormatFloat(entryTick / 1000.0, "", 0, 3)
                    + " s, " + Text::FormatFloat(speedAtEntry * 3.6, "", 0, 3)
                    + " km/h, dist " + Text::FormatFloat(distBeforeEntry, "", 0, 6) + " m";
            }
            else
            {
                resp.Decision = BFEvaluationDecision::Reject;
            }
        }
        return resp;
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        weight = int(GetVariableDouble("bf_stdtrigger_weight"));
        if (weight <= 50)
        {
            k = float(weight) / (100.0f - float(weight));
        }
        else
        {
            k = (100.0f - float(weight)) / float(weight);
        }
        bestEntryTick = -1;
        bestSpeedAtEntry = -1.0f;
        bestDistBeforeEntry = 1e18f;
        base = true;
        lastRaceTime = -1;
        entryDetected = false;
        prevTickValid = false;
        int triggerIndex = int(GetVariableDouble("bf_stdtrigger_trigger"));
        array<int> @triggerIds = GetTriggerIds();
        if (triggerIds.Length > 0 && triggerIndex < int(triggerIds.Length))
        {
            targetTrigger = GetTrigger(triggerIds[triggerIndex]);
        }
        else
        {
            print("Error: Invalid trigger index selected for standard trigger BF.", Severity::Error);
        }
    }
    void Main()
    {
        RegisterVariable("bf_stdtrigger_trigger", 0);
        RegisterVariable("bf_stdtrigger_weight", 0);
        auto eval = RegisterBruteforceEval("standardtrigger", "Standard Trigger", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
