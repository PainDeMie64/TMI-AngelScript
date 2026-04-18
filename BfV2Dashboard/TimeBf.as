namespace TimeBf
{
    int minTime = 0;
    int bestTime = -1;
    bool base = false;
    void RenderEvalSettings()
    {
        UI::PushItemWidth(200);
        UI::Text("Minimum Time");
        UI::SameLine();
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        UI::InputTimeVar("##timebf_min_time", "timebf_min_time");
        UI::PopItemWidth();
        toolTip(300, {"Optional minimum time threshold. Only times at or after this point will be considered. Set to 0 to disable."});
    }
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        bool conditionsMet = GlobalConditionsMet(simManager);
        bool isPastMinTime = raceTime >= minTime;
        if (info.Phase == BFPhase::Initial)
        {
            if (conditionsMet && isPastMinTime)
            {
                if (bestTime == -1 || raceTime < bestTime)
                {
                    bestTime = raceTime;
                    resp.Decision = BFEvaluationDecision::Accept;
                    if (base)
                    {
                        base = false;
                        print("Base run time: " + Text::FormatFloat(bestTime / 1000.0, "", 0, 3) + " s");
                        resp.ResultFileStartContent = "# Base run time: " + Text::FormatFloat(bestTime / 1000.0, "", 0, 3) + " s";
                    }
                }
            }
        }
        else
        {
            if (conditionsMet && isPastMinTime && raceTime < bestTime)
            {
                bestTime = raceTime;
                resp.Decision = BFEvaluationDecision::Accept;
                print("New best time: " + Text::FormatFloat(bestTime / 1000.0, "", 0, 3) + " s");
                resp.ResultFileStartContent = "# Best time: " + Text::FormatFloat(bestTime / 1000.0, "", 0, 3) + " s";
            }
        }
        return resp;
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        minTime = int(GetVariableDouble("timebf_min_time"));
        bestTime = -1;
        base = true;
    }
    void Main()
    {
        RegisterVariable("timebf_min_time", 0);
        auto eval = RegisterBruteforceEval("time", "Time", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
