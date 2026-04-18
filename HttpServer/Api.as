string HandleGetState(const string &in body)
{
    SimulationManager@ sim = GetSimulationManager();
    string json = "{";
    json += JsonString("gameState", GameStateToString(GetCurrentGameState()));

    if (sim !is null)
    {
        json += "," + JsonInt("raceTime", sim.RaceTime);
        json += "," + JsonString("raceTimeFormatted", Time::Format(sim.RaceTime));
        json += "," + JsonBool("inRace", sim.InRace);

        TM::PlayerInfo@ player = sim.PlayerInfo;
        if (player !is null)
        {
            json += "," + JsonUInt("speed", player.DisplaySpeed);
            json += "," + JsonUInt("checkpoints", player.CurCheckpointCount);
            json += "," + JsonUInt("curLap", player.CurLap);
            json += "," + JsonBool("finished", player.RaceFinished);
            json += "," + JsonUInt("bestTime", player.RaceBestTime);
        }

        TM::HmsDyna@ dyna = sim.Dyna;
        if (dyna !is null)
        {
            json += "," + JsonVec3("position", dyna.CurrentState.Location.Position);
            json += "," + JsonVec3("velocity", dyna.CurrentState.LinearSpeed);
        }

        TM::SceneVehicleCar@ car = sim.SceneVehicleCar;
        if (car !is null)
        {
            json += "," + JsonFloat("inputGas", car.InputGas);
            json += "," + JsonFloat("inputBrake", car.InputBrake);
            json += "," + JsonFloat("inputSteer", car.InputSteer);
            json += "," + JsonFloat("turboBoostFactor", car.TurboBoostFactor);
            json += "," + JsonVec3("localSpeed", car.CurrentLocalSpeed);
        }
    }

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

string HandleGetVariables(const string &in body)
{
    array<VariableInfo>@ vars = ListVariables();
    if (vars is null) return "[]";

    string json = "[";
    for (uint i = 0; i < vars.Length; i++)
    {
        if (i > 0) json += ",";
        string typeName = "unknown";
        if (vars[i].Type == VariableType::Double) typeName = "double";
        else if (vars[i].Type == VariableType::String) typeName = "string";
        else if (vars[i].Type == VariableType::Boolean) typeName = "bool";

        json += "{" + JsonString("name", vars[i].Name);
        json += "," + JsonString("type", typeName);

        if (vars[i].Type == VariableType::Double)
            json += "," + JsonFloat("value", float(GetVariableDouble(vars[i].Name)));
        else if (vars[i].Type == VariableType::String)
            json += "," + JsonString("value", GetVariableString(vars[i].Name));
        else if (vars[i].Type == VariableType::Boolean)
            json += "," + JsonBool("value", GetVariableBool(vars[i].Name));

        json += "}";
    }
    json += "]";
    return json;
}

string HandlePostCommand(const string &in body)
{
    if (body.Length == 0)
        return "{" + JsonBool("ok", false) + "," + JsonString("error", "empty command") + "}";

    ExecuteCommand(body);
    return "{" + JsonBool("ok", true) + "," + JsonString("command", body) + "}";
}

string HandlePostSetVar(const string &in body)
{
    string name = GetFormValue(body, "name");
    string value = GetFormValue(body, "value");

    if (name.Length == 0)
        return "{" + JsonBool("ok", false) + "," + JsonString("error", "missing name") + "}";

    array<VariableInfo>@ vars = ListVariables();
    VariableType varType = VariableType::String;
    bool found = false;
    if (vars !is null)
    {
        for (uint i = 0; i < vars.Length; i++)
        {
            if (vars[i].Name == name)
            {
                varType = vars[i].Type;
                found = true;
                break;
            }
        }
    }

    if (!found)
        return "{" + JsonBool("ok", false) + "," + JsonString("error", "variable not found") + "}";

    bool success = false;
    if (varType == VariableType::Double)
        success = SetVariable(name, double(Text::ParseFloat(value)));
    else if (varType == VariableType::Boolean)
        success = SetVariable(name, value == "true" || value == "1");
    else
        success = SetVariable(name, value);

    if (!success)
        return "{" + JsonBool("ok", false) + "," + JsonString("error", "failed to set") + "}";

    return "{" + JsonBool("ok", true) + "," + JsonString("name", name) + "," + JsonString("value", value) + "}";
}

string HandlePostRespawn(const string &in body)
{
    SimulationManager@ sim = GetSimulationManager();
    if (sim is null)
        return "{" + JsonBool("ok", false) + "," + JsonString("error", "not in race") + "}";

    sim.Respawn();
    return "{" + JsonBool("ok", true) + "}";
}

string HandlePostGiveUp(const string &in body)
{
    SimulationManager@ sim = GetSimulationManager();
    if (sim is null)
        return "{" + JsonBool("ok", false) + "," + JsonString("error", "not in race") + "}";

    sim.GiveUp();
    return "{" + JsonBool("ok", true) + "}";
}
