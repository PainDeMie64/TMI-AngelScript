namespace PreciseTriggerBf
{
    Trigger3D targetTrigger;
    double bestTime = -1;
    int bestTimeMsImprecise = -1;
    bool conditionsMetBeforeCompute = false;
    void RenderEvalSettings()
    {
        uint triggerIndex = uint(GetVariableDouble("bf_target_trigger"));
        array<int> @triggerIds = GetTriggerIds();
        if (triggerIds.Length == 0)
        {
            UI::Text("No triggers found.");
            return;
        }
        if (triggerIndex >= triggerIds.Length)
        {
            triggerIndex = 0;
            SetVariable("bf_target_trigger", 0);
        }
        Trigger3D selectedTrigger = GetTrigger(triggerIds[triggerIndex]);
        vec3 pos = selectedTrigger.Position;
        if (UI::BeginCombo("Trigger Index", (triggerIndex + 1) + ". Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")"))
        {
            for (uint i = 0; i < triggerIds.Length; i++)
            {
                Trigger3D trigger = GetTrigger(triggerIds[i]);
                pos = trigger.Position;
                string triggerName = (i + 1) + ". Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")";
                if (UI::Selectable(triggerName, triggerIndex == i))
                {
                    SetVariable("bf_target_trigger", i);
                }
            }
            UI::EndCombo();
        }
    }
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        bool inTrigger = targetTrigger.ContainsPoint(simManager.Dyna.CurrentState.Location.Position);
        if (info.Phase == BFPhase::Search && !PreciseFinish::IsEstimating && bestTimeMsImprecise != -1)
        {
            if (inTrigger && raceTime < bestTimeMsImprecise)
            {
                if (GlobalConditionsMet(simManager))
                {
                    resp.Decision = BFEvaluationDecision::Accept;
                }
                else
                {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
                PreciseFinish::Reset();
                return resp;
            }
            if (raceTime > bestTimeMsImprecise + 50)
            {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
        }
        double preciseTime;
        if (inTrigger && !PreciseFinish::IsEstimating)
        {
            conditionsMetBeforeCompute = GlobalConditionsMet(simManager);
        }
        bool calculationDone = PreciseFinish::Compute(simManager, inTrigger, preciseTime);
        if (!calculationDone)
        {
            return resp;
        }
        if (!conditionsMetBeforeCompute)
        {
            if (info.Phase == BFPhase::Initial)
            {
                print("Base run hit trigger but conditions not met. Search will require meeting these conditions.", Severity::Warning);
            }
            else
            {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
        }
        if (info.Phase == BFPhase::Initial)
        {
            if (bestTime != -1 && preciseTime >= bestTime + 1e-7)
            {
                resp.Decision = BFEvaluationDecision::Reject;
                PreciseFinish::Reset();
                return resp;
            }
            if (bestTime != -1)
                print("Precise trigger time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            else
                print("Base run trigger time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            bestTime = preciseTime;
            bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
            resp.Decision = BFEvaluationDecision::Accept;
            resp.ResultFileStartContent = "# Precise Trigger Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
        }
        else
        {
            if (preciseTime < bestTime)
            {
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Precise Trigger Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            }
            else
            {
                resp.Decision = BFEvaluationDecision::Reject;
            }
        }
        PreciseFinish::Reset();
        return resp;
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;
        int triggerIndex = int(GetVariableDouble("bf_target_trigger"));
        array<int> @triggerIds = GetTriggerIds();
        if (triggerIds.Length > 0 && triggerIndex < int(triggerIds.Length))
        {
            targetTrigger = GetTrigger(triggerIds[triggerIndex]);
        }
        else
        {
            print("Error: Invalid trigger index selected for bruteforce.", Severity::Error);
        }
    }
    void Main()
    {
        auto bfEval = RegisterBruteforceEval("precisetrigger", "Trigger", OnEvaluate, RenderEvalSettings);
        @bfEval.onSimBegin = @OnSimulationBegin;
    }
}
