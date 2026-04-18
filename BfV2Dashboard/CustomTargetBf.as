namespace CustomTargetBf
{
    class TargetDirective
    {
        int type; // 0=min, 1=max, 2=target
        float targetValue; // only used when type==2
        Scripting::FloatGetter @getter;
        string sourceExpr; // original expression text for display
    }
    array<TargetDirective @> directives;
    array<float> bestScores;
    array<float> currentScores;
    int minTime = 0;
    int maxTime = 0;
    bool base = false;
    string lastCompiledScript = "";
    bool compilationError = false;
    bool scriptEmpty = true;
    float ComputeScore(TargetDirective @dir, float value)
    {
        if (dir.type == 0)
            return -value;
        if (dir.type == 1)
            return value;
        // type == 2: target
        return -Math::Abs(value - dir.targetValue);
    }
    string FormatScoreAsValue(TargetDirective @dir, float score)
    {
        if (dir.type == 0)
            return Text::FormatFloat(-score, "", 0, 5);
        if (dir.type == 1)
            return Text::FormatFloat(score, "", 0, 5);
        // type == 2: show distance from target
        return Text::FormatFloat(-score, "", 0, 5) + " from " + Text::FormatFloat(dir.targetValue, "", 0, 3);
    }
    array<TargetDirective @>@ CompileTargetScript(array<string> &in lines)
    {
        array<TargetDirective @> result;
        for (uint i = 0; i < lines.Length; i++)
        {
            string line = lines[i];
            // Remove leading/trailing whitespace manually
            while (line.Length > 0 && (line[0] == 32 || line[0] == 9))
                line = line.Substr(1);
            while (line.Length > 0 && (line[line.Length - 1] == 32 || line[line.Length - 1] == 9))
                line = line.Substr(0, line.Length - 1);
            if (line == "" || line[0] == 35) // skip empty lines and comments (#)
                continue;
            string lower = Scripting::ToLower(line);
            TargetDirective @dir = TargetDirective();
            if (Scripting::StartsWith(lower, "min "))
            {
                dir.type = 0;
                dir.targetValue = 0;
                string exprStr = line.Substr(4);
                dir.sourceExpr = exprStr;
                string cleaned = Scripting::CleanSource(exprStr);
                if (cleaned == "")
                    return null;
                Scripting::FloatGetter @g = Scripting::ParseExpression(cleaned);
                if (g is null)
                    return null;
                @dir.getter = g;
            }
            else if (Scripting::StartsWith(lower, "max "))
            {
                dir.type = 1;
                dir.targetValue = 0;
                string exprStr = line.Substr(4);
                dir.sourceExpr = exprStr;
                string cleaned = Scripting::CleanSource(exprStr);
                if (cleaned == "")
                    return null;
                Scripting::FloatGetter @g = Scripting::ParseExpression(cleaned);
                if (g is null)
                    return null;
                @dir.getter = g;
            }
            else if (Scripting::StartsWith(lower, "target "))
            {
                string rest = line.Substr(7);
                // Remove leading whitespace
                while (rest.Length > 0 && (rest[0] == 32 || rest[0] == 9))
                    rest = rest.Substr(1);
                // Extract the numeric target value (first token)
                int spaceIdx = -1;
                for (uint c = 0; c < rest.Length; c++)
                {
                    if (rest[c] == 32 || rest[c] == 9)
                    {
                        spaceIdx = int(c);
                        break;
                    }
                }
                if (spaceIdx == -1)
                    return null; // no expression after target value
                string valStr = rest.Substr(0, spaceIdx);
                string exprStr = rest.Substr(spaceIdx + 1);
                // Remove leading whitespace from expression
                while (exprStr.Length > 0 && (exprStr[0] == 32 || exprStr[0] == 9))
                    exprStr = exprStr.Substr(1);
                dir.type = 2;
                dir.targetValue = Text::ParseFloat(valStr);
                dir.sourceExpr = exprStr;
                string cleaned = Scripting::CleanSource(exprStr);
                if (cleaned == "")
                    return null;
                Scripting::FloatGetter @g = Scripting::ParseExpression(cleaned);
                if (g is null)
                    return null;
                @dir.getter = g;
            }
            else
            {
                return null; // unknown directive
            }
            result.Add(dir);
        }
        return result;
    }
    void RenderEvalSettings()
    {
        UI::Dummy(vec2(0, 2));
        string lines = Replace(GetVariableString("bf_customtarget_script"), ":", "\n");
        int currentHeight = int(GetVariableDouble("bf_customtarget_script_height"));
        UI::PushItemWidth(245);
        if (UI::InputTextMultiline("##bf_customtarget_script", lines, vec2(0, currentHeight)))
        {
            SetVariable("bf_customtarget_script", Replace(lines, "\n", ":"));
        }
        UI::SameLine();
        if (UI::Button("^##customtarget_script_up"))
        {
            if (currentHeight < 42)
                currentHeight = 42;
            SetVariable("bf_customtarget_script_height", currentHeight - 17);
        }
        UI::SameLine();
        if (UI::Button("v##customtarget_script_down"))
        {
            SetVariable("bf_customtarget_script_height", currentHeight + 17);
        }
        UI::SameLine();
        UI::Text("Target script");
        UI::PopItemWidth();
        if (lines != lastCompiledScript)
        {
            lastCompiledScript = lines;
            array<string> parts = lines.Split("\n");
            // Check if all lines are empty/comments
            scriptEmpty = true;
            for (uint i = 0; i < parts.Length; i++)
            {
                string cleaned = Scripting::CleanSource(parts[i]);
                if (cleaned != "" && cleaned[0] != 35)
                {
                    scriptEmpty = false;
                    break;
                }
            }
            if (scriptEmpty)
            {
                directives.Resize(0);
                compilationError = false;
            }
            else
            {
                auto @result = CompileTargetScript(parts);
                if (result is null)
                {
                    compilationError = true;
                    directives.Resize(0);
                }
                else
                {
                    compilationError = false;
                    directives = result;
                }
            }
        }
        if (compilationError)
        {
            UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
            UI::Text("Script has errors! Script has errors!");
            UI::Text("Script has errors! Script has errors!");
            UI::Text("Script has errors! Script has errors!");
            UI::PopStyleColor();
        }
        else if (scriptEmpty)
        {
            UI::TextDimmed("No target script set.");
        }
        else
        {
            UI::TextDimmed("Script compiled: " + directives.Length + " directive(s).");
        }
        UI::Dummy(vec2(0, 5));
        UI::Text("Evaluation time frame:");
        UI::Dummy(vec2(0, 0));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(17, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##bf_customtarget_eval_min_time", "bf_customtarget_eval_min_time");
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(36, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##bf_customtarget_eval_max_time", "bf_customtarget_eval_max_time");
        UI::Dummy(vec2(0, 0));
        UI::TextDimmed("Reducing the maximum evaluation time will make the bruteforcing process faster.");
        UI::Dummy(vec2(0, 2));
        toolTip(350, {
            "Each line defines an optimization directive:",
            "  min EXPRESSION  - minimize the value",
            "  max EXPRESSION  - maximize the value",
            "  target VALUE EXPRESSION - get as close to VALUE as possible",
            "",
            "Examples:",
            "  max car.speed",
            "  min car.y",
            "  target 500 car.x",
            "  max kmh(car.speed)",
            "  min distance(car.pos, (100,50,200))",
            "",
            "Multiple lines combine with Pareto logic:",
            "a run is better if it improves at least one",
            "objective without worsening any other."
        });
    }
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        if (directives.Length == 0)
        {
            if (raceTime > maxTime && maxTime > 0)
            {
                if (info.Phase == BFPhase::Initial)
                    resp.Decision = BFEvaluationDecision::Accept;
                else
                    resp.Decision = BFEvaluationDecision::Reject;
            }
            return resp;
        }
        bool isEvalTime = raceTime >= minTime && raceTime <= maxTime;
        bool isPastEvalTime = raceTime > maxTime;
        bool conditionsMet = GlobalConditionsMet(simManager);
        if (isEvalTime && conditionsMet)
        {
            for (uint i = 0; i < directives.Length; i++)
            {
                float value = directives[i].getter(simManager);
                float score = ComputeScore(directives[i], value);
                if (score > currentScores[i])
                    currentScores[i] = score;
            }
        }
        if (isPastEvalTime)
        {
            if (info.Phase == BFPhase::Initial)
            {
                for (uint i = 0; i < directives.Length; i++)
                {
                    bestScores[i] = currentScores[i];
                }
                resp.Decision = BFEvaluationDecision::Accept;
                if (base)
                {
                    base = false;
                    string summary = "Base run:";
                    for (uint i = 0; i < directives.Length; i++)
                    {
                        string dirType = "";
                        if (directives[i].type == 0) dirType = "min";
                        else if (directives[i].type == 1) dirType = "max";
                        else dirType = "target " + Text::FormatFloat(directives[i].targetValue, "", 0, 3);
                        summary += " [" + dirType + " " + directives[i].sourceExpr + "=" + FormatScoreAsValue(directives[i], bestScores[i]) + "]";
                    }
                    print(summary);
                    resp.ResultFileStartContent = "# " + summary;
                }
            }
            else
            {
                // Pareto comparison: accept if at least one is strictly better
                // and none are worse
                bool anyBetter = false;
                bool anyWorse = false;
                for (uint i = 0; i < directives.Length; i++)
                {
                    if (currentScores[i] > bestScores[i])
                        anyBetter = true;
                    else if (currentScores[i] < bestScores[i])
                        anyWorse = true;
                }
                if (anyBetter && !anyWorse)
                {
                    for (uint i = 0; i < directives.Length; i++)
                    {
                        bestScores[i] = currentScores[i];
                    }
                    resp.Decision = BFEvaluationDecision::Accept;
                    string summary = "Improved:";
                    for (uint i = 0; i < directives.Length; i++)
                    {
                        string dirType = "";
                        if (directives[i].type == 0) dirType = "min";
                        else if (directives[i].type == 1) dirType = "max";
                        else dirType = "target " + Text::FormatFloat(directives[i].targetValue, "", 0, 3);
                        summary += " [" + dirType + " " + directives[i].sourceExpr + "=" + FormatScoreAsValue(directives[i], bestScores[i]) + "]";
                    }
                    print(summary);
                    resp.ResultFileStartContent = "# " + summary;
                }
                else
                {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
            }
            // Reset current scores for the next iteration
            for (uint i = 0; i < currentScores.Length; i++)
            {
                currentScores[i] = -1e18f;
            }
        }
        return resp;
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        minTime = int(GetVariableDouble("bf_customtarget_eval_min_time"));
        maxTime = int(GetVariableDouble("bf_customtarget_eval_max_time"));
        maxTime = ResolveMaxTime(maxTime, int(simManager.EventsDuration));
        base = true;
        // Recompile script from variable in case it changed
        string scriptText = Replace(GetVariableString("bf_customtarget_script"), ":", "\n");
        array<string> parts = scriptText.Split("\n");
        scriptEmpty = true;
        for (uint i = 0; i < parts.Length; i++)
        {
            string cleaned = Scripting::CleanSource(parts[i]);
            if (cleaned != "" && cleaned[0] != 35)
            {
                scriptEmpty = false;
                break;
            }
        }
        if (!scriptEmpty)
        {
            auto @result = CompileTargetScript(parts);
            if (result !is null)
            {
                directives = result;
                compilationError = false;
            }
        }
        // Initialize score arrays
        bestScores.Resize(directives.Length);
        currentScores.Resize(directives.Length);
        for (uint i = 0; i < directives.Length; i++)
        {
            bestScores[i] = -1e18f;
            currentScores[i] = -1e18f;
        }
    }
    void Main()
    {
        RegisterVariable("bf_customtarget_script", "");
        RegisterVariable("bf_customtarget_script_height", 60);
        RegisterVariable("bf_customtarget_eval_min_time", 0);
        RegisterVariable("bf_customtarget_eval_max_time", 0);
        auto eval = RegisterBruteforceEval("customtarget", "Custom Target", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
