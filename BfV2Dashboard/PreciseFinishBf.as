namespace PreciseFinishBf
{
    void RenderEvalSettings() {}
    double bestTime = -1;
    int bestTimeMsImprecise = -1;
    bool conditionsMetBeforeCompute = false;
    bool baseRunFinished = true;
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        auto resp = BFEvaluationResponse();
        int raceTime = simManager.RaceTime;
        resp.Decision = BFEvaluationDecision::DoNothing;
        if (info.Phase == BFPhase::Search && !PreciseFinish::IsEstimating)
        {
            if (!baseRunFinished)
            {
                // All-or-nothing mode: no best time to compare against yet
                if (!simManager.PlayerInfo.RaceFinished && raceTime > int(simManager.EventsDuration))
                {
                    resp.Decision = BFEvaluationDecision::Reject;
                    return resp;
                }
                // If finished, fall through to compute precise time below
            }
            else if (bestTimeMsImprecise != -1)
            {
                if (raceTime > bestTimeMsImprecise + 50)
                {
                    resp.Decision = BFEvaluationDecision::Reject;
                    PreciseFinish::Reset();
                    return resp;
                }
                if (simManager.PlayerInfo.RaceFinished && raceTime < bestTimeMsImprecise)
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
            }
        }
        bool targetReached = simManager.PlayerInfo.RaceFinished;
        if (targetReached && !PreciseFinish::IsEstimating)
        {
            conditionsMetBeforeCompute = GlobalConditionsMet(simManager);
        }
        double preciseTime;
        bool calculationFinished = PreciseFinish::Compute(simManager, targetReached, preciseTime);
        if (!calculationFinished)
        {
            // Base run did not finish: accept to let BF proceed to Search phase
            if (info.Phase == BFPhase::Initial && !targetReached && !PreciseFinish::IsEstimating && raceTime > int(simManager.EventsDuration))
            {
                baseRunFinished = false;
                bestTime = -1;
                bestTimeMsImprecise = -1;
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Base run: Did not finish. Searching for any finish.";
                print("Base run did not finish. Bruteforce will search for any finish.", Severity::Warning);
                return resp;
            }
            return resp;
        }
        if (!conditionsMetBeforeCompute)
        {
            if (info.Phase == BFPhase::Initial)
            {
                print("Base run finished, but conditions not met. Search will require meeting these conditions.", Severity::Warning);
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
                print("Precise finish time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            else
                print("Base run finish time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            bestTime = preciseTime;
            bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
            resp.Decision = BFEvaluationDecision::Accept;
            resp.ResultFileStartContent = "# Precise Finish Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            PreciseFinish::Reset();
        }
        else
        {
            if (!baseRunFinished)
            {
                // First finish found in all-or-nothing mode
                baseRunFinished = true;
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# First finish found! Precise Finish Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
                print("First finish found! Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s", Severity::Success);
            }
            else if (preciseTime < bestTime)
            {
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Precise Finish Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
            }
            else
            {
                resp.Decision = BFEvaluationDecision::Reject;
            }
            PreciseFinish::Reset();
        }
        return resp;
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        PreciseFinish::Reset();
        bestTime = -1;
        bestTimeMsImprecise = -1;
        baseRunFinished = true;
    }
    void Main()
    {
        auto bfEval = RegisterBruteforceEval("precisefinish", "Precise Finish Time", OnEvaluate, RenderEvalSettings);
        @bfEval.onSimBegin = @OnSimulationBegin;
    }
}
