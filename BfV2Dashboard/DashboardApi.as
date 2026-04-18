string GetBfTargetTitle()
{
    string targetId = GetVariableString("bf_target");
    for (uint i = 0; i < evaluations.Length; i++)
    {
        if (evaluations[i].identifier == targetId)
            return evaluations[i].title;
    }
    return targetId;
}

string HandleGetBfStatus(const string &in body)
{
    string json = "{";
    json += JsonBool("running", bfRunning);
    json += "," + JsonString("phase", currentPhase);
    json += "," + JsonString("target", bfRunning ? currentTarget : GetBfTargetTitle());
    json += "," + JsonUInt("iterations", currentIterations);
    json += "," + JsonUInt("restarts", currentRestarts);
    json += "," + JsonFloat("iterationsPerSec", iterationsPerSecond);
    json += "," + JsonInt("sessionId", currentSessionId);

    uint64 elapsed = 0;
    if (bfRunning && bfStartTime > 0)
        elapsed = Time::Now - bfStartTime;
    json += "," + JsonUInt("elapsedMs", uint(elapsed));
    json += "}";
    return json;
}

string HandleGetBfLog(const string &in body)
{
    string json = "[";
    for (uint i = 0; i < logBuffer.Length; i++)
    {
        if (i > 0) json += ",";
        json += logBuffer[i];
    }
    json += "]";
    return json;
}

string HandleGetBfImprovements(const string &in body)
{
    string json = "[";
    for (uint i = 0; i < improvementLog.Length; i++)
    {
        if (i > 0) json += ",";
        json += improvementLog[i];
    }
    json += "]";
    return json;
}

string HandleGetBfSettings(const string &in body)
{
    string json = "{";
    json += JsonString("target", GetBfTargetTitle());
    json += "," + JsonInt("restartAfter", int(GetVariableDouble("bf_iterations_before_restart")));
    json += "," + JsonString("resultFolder", GetVariableString("bf_result_folder"));
    json += "," + JsonString("resultFilename", GetVariableString("bf_result_filename"));

    int slotCount = int(GetVariableDouble("bf_input_mod_count"));
    if (slotCount < 1) slotCount = 1;
    string slots = "[";
    for (int s = 0; s < slotCount; s++)
    {
        if (s > 0) slots += ",";
        string suffix = GetInputModVarSuffix(uint(s));
        string algoName = GetVariableString("bf_input_mod_algorithm" + suffix);
        bool enabled = (s == 0) ? true : GetVariableBool("bf_input_mod_enabled" + suffix);
        slots += "{" + JsonString("algorithm", algoName);
        slots += "," + JsonBool("enabled", enabled);
        slots += "," + JsonInt("modifyCount", int(GetVariableDouble("bf_modify_count" + suffix)));
        slots += "," + JsonInt("minTime", int(GetVariableDouble("bf_inputs_min_time" + suffix)));
        slots += "," + JsonInt("maxTime", int(GetVariableDouble("bf_inputs_max_time" + suffix)));
        slots += "}";
    }
    slots += "]";
    json += ",\"slots\":" + slots;

    json += "}";
    return json;
}

string HandleGetMap(const string &in body)
{
    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
    if (challenge is null)
        return "{" + JsonBool("loaded", false) + "}";

    string json = "{";
    json += JsonBool("loaded", true);
    json += "," + JsonStringDisplay("name", challenge.Name);
    json += "," + JsonString("uid", challenge.Uid);
    json += "," + JsonStringDisplay("author", challenge.Author);
    json += "}";
    return json;
}

string HandleGetBfSessions(const string &in body)
{
    string content = FileRead(DATA_FOLDER + "/sessions.txt");
    if (content.Length == 0) return "[]";

    array<string>@ lines = content.Split("\n");
    string json = "[";
    bool first = true;
    for (uint i = 0; i < lines.Length; i++)
    {
        if (lines[i].Length == 0) continue;
        array<string>@ parts = lines[i].Split("|");
        if (parts.Length < 4) continue;

        if (!first) json += ",";
        first = false;
        json += "{" + JsonString("id", parts[0]);
        json += "," + JsonString("target", parts[1]);
        json += "," + JsonString("startTime", parts[2]);
        json += "," + JsonString("map", parts[3]);
        json += "}";
    }
    json += "]";
    return json;
}

string HandleGetSessionLog(const string &in body)
{
    string id = GetFormValue(requestQuery, "id");
    if (id.Length == 0) return "[]";

    string content = FileRead(DATA_FOLDER + "/sessions/" + id + "/log.txt");
    if (content.Length == 0) return "[]";

    string json = "[";
    array<string>@ lines = content.Split("\n");
    bool first = true;
    for (uint i = 0; i < lines.Length; i++)
    {
        if (lines[i].Length == 0) continue;
        if (!first) json += ",";
        first = false;
        json += lines[i];
    }
    json += "]";
    return json;
}

string HandleGetSessionImp(const string &in body)
{
    string id = GetFormValue(requestQuery, "id");
    if (id.Length == 0) return "[]";

    string content = FileRead(DATA_FOLDER + "/sessions/" + id + "/improvements.txt");
    if (content.Length == 0) return "[]";

    string json = "[";
    array<string>@ lines = content.Split("\n");
    bool first = true;
    for (uint i = 0; i < lines.Length; i++)
    {
        if (lines[i].Length == 0) continue;
        if (!first) json += ",";
        first = false;
        json += lines[i];
    }
    json += "]";
    return json;
}
