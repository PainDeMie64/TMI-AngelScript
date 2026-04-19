// --- Dashboard tracking ---
uint64 bfStartTime = 0;
uint64 lastIterationTime = 0;
float iterationsPerSecond = 0.0f;
uint iterationsAtLastCalc = 0;

array<string> logBuffer;
const uint MAX_LOG_ENTRIES = 200;

array<string> improvementLog;
const uint MAX_IMPROVEMENTS = 100;

string currentPhase = "Idle";
string currentTarget = "";
uint currentIterations = 0;
uint currentRestarts = 0;
bool bfRunning = false;
uint64 lastPollTime = 0;

int currentSessionId = 0;
const string DATA_FOLDER = "BfV2Dashboard";

string SessionPath(const string &in filename)
{
    return DATA_FOLDER + "/sessions/" + Text::FormatInt(currentSessionId) + "/" + filename;
}

void StartSession()
{
    string sessionsContent = FileRead(DATA_FOLDER + "/sessions.txt");
    int maxId = 0;
    if (sessionsContent.Length > 0)
    {
        array<string>@ lines = sessionsContent.Split("\n");
        for (uint i = 0; i < lines.Length; i++)
        {
            if (lines[i].Length == 0) continue;
            array<string>@ parts = lines[i].Split("|");
            if (parts.Length >= 1)
            {
                int id = int(Text::ParseInt(parts[0]));
                if (id > maxId) maxId = id;
            }
        }
    }
    currentSessionId = maxId + 1;

    string mapName = "";
    TM::GameCtnChallenge@ ch = GetCurrentChallenge();
    if (ch !is null) mapName = ch.Name;

    string sessionLine = Text::FormatInt(currentSessionId) + "|" + currentTarget + "|" + Text::FormatUInt(Time::Now) + "|" + mapName;
    FileAppendLine(DATA_FOLDER + "/sessions.txt", sessionLine);

    logBuffer.Resize(0);
    improvementLog.Resize(0);
}

void DashboardLog(const string &in message)
{
    float secSinceStart = 0.0f;
    if (bfStartTime > 0)
        secSinceStart = float(Time::Now - bfStartTime) / 1000.0f;
    string entry = "{";
    entry += JsonFloat("t", secSinceStart);
    entry += "," + JsonString("msg", message);
    entry += "}";
    logBuffer.Add(entry);
    if (logBuffer.Length > MAX_LOG_ENTRIES)
        logBuffer.RemoveAt(0);
    if (currentSessionId > 0)
        FileAppendLine(SessionPath("log.txt"), entry);
}

void DashboardImprovement(const string &in evalName, const string &in details)
{
    float secSinceStart = 0.0f;
    if (bfStartTime > 0)
        secSinceStart = float(Time::Now - bfStartTime) / 1000.0f;
    string entry = "{";
    entry += JsonFloat("t", secSinceStart);
    entry += "," + JsonString("eval", evalName);
    entry += "," + JsonString("details", details);
    entry += "," + JsonUInt("iteration", currentIterations);
    entry += "," + JsonUInt("restart", currentRestarts);
    entry += "}";
    improvementLog.Add(entry);
    if (improvementLog.Length > MAX_IMPROVEMENTS)
        improvementLog.RemoveAt(0);
    if (currentSessionId > 0)
        FileAppendLine(SessionPath("improvements.txt"), entry);
}

void RefreshInputModSettings(SimulationManager@ simManager)
{
    int savedCount = int(GetVariableDouble("bf_input_mod_count"));
    if (savedCount < 1) savedCount = 1;
    while (int(g_inputModSettings.Length) < savedCount)
    {
        InputModificationSettings @s = InputModificationSettings();
        g_inputModSettings.Add(s);
    }
    while (int(g_inputModSettings.Length) > savedCount)
        g_inputModSettings.RemoveAt(g_inputModSettings.Length - 1);
    for (uint im = 0; im < g_inputModSettings.Length; im++)
    {
        string varSuffix = GetInputModVarSuffix(im);
        InputModificationSettings @s = g_inputModSettings[im];
        s.inputCount = int(GetVariableDouble("bf_modify_count" + varSuffix));
        s.minInputsTime = int(GetVariableDouble("bf_inputs_min_time" + varSuffix));
        s.maxInputsTime = int(GetVariableDouble("bf_inputs_max_time" + varSuffix));
        s.maxSteerDiff = int(GetVariableDouble("bf_max_steer_diff" + varSuffix));
        s.maxTimeDiff = int(GetVariableDouble("bf_max_time_diff" + varSuffix));
        s.fillSteerInputs = GetVariableBool("bf_inputs_fill_steer" + varSuffix);
        s.enabled = (im == 0) || GetVariableBool("bf_input_mod_enabled" + varSuffix);
        s.maxInputsTime = ResolveMaxTime(s.maxInputsTime, int(simManager.EventsDuration));
        string algoId = GetVariableString("bf_input_mod_algorithm" + varSuffix);
        s.algorithmIndex = GetInputModAlgorithmIndex(algoId);
        int ed = int(simManager.EventsDuration);
        if (algoId == "advanced_basic")
        {
            if (int(GetVariableDouble("bf_adv_steer_max_time" + varSuffix)) == 0)
                SetVariable("bf_adv_steer_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_adv_accel_max_time" + varSuffix)) == 0)
                SetVariable("bf_adv_accel_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_adv_brake_max_time" + varSuffix)) == 0)
                SetVariable("bf_adv_brake_max_time" + varSuffix, ed);
        }
        else if (algoId == "advanced_range")
        {
            if (int(GetVariableDouble("bf_advr_steer_max_time" + varSuffix)) == 0)
                SetVariable("bf_advr_steer_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_advr_accel_max_time" + varSuffix)) == 0)
                SetVariable("bf_advr_accel_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_advr_brake_max_time" + varSuffix)) == 0)
                SetVariable("bf_advr_brake_max_time" + varSuffix, ed);
        }
    }
    if (g_inputModSettings.Length > 0)
    {
        inputCount = g_inputModSettings[0].inputCount;
        minInputsTime = g_inputModSettings[0].minInputsTime;
        maxInputsTime = g_inputModSettings[0].maxInputsTime;
        maxSteerDiff = g_inputModSettings[0].maxSteerDiff;
        maxTimeDiff = g_inputModSettings[0].maxTimeDiff;
        fillSteerInputs = g_inputModSettings[0].fillSteerInputs;
    }
    leastMinInputsTime = 1000000000;
    for (uint lm = 0; lm < g_inputModSettings.Length; lm++)
    {
        if (g_inputModSettings[lm].enabled && g_inputModSettings[lm].minInputsTime < leastMinInputsTime)
            leastMinInputsTime = g_inputModSettings[lm].minInputsTime;
    }
}

class InputModificationAlgorithm
{
    string identifier;
    string name;
    InputModAlgorithmCallback @mutateCallback;
    InputModAlgorithmUICallback @renderUICallback;
    InputModificationAlgorithm() {}
    InputModificationAlgorithm(const string &in id, const string &in displayName, InputModAlgorithmCallback @mutate, InputModAlgorithmUICallback @renderUI)
    {
        identifier = id;
        name = displayName;
        @mutateCallback = @mutate;
        @renderUICallback = @renderUI;
    }
}
array<InputModificationAlgorithm@> g_inputModAlgorithms;
void RegisterInputModAlgorithm(const string &in identifier, const string &in name, InputModAlgorithmCallback @mutateCallback, InputModAlgorithmUICallback @renderUICallback)
{
    InputModificationAlgorithm @algo = InputModificationAlgorithm(identifier, name, mutateCallback, renderUICallback);
    g_inputModAlgorithms.Add(algo);
}
int GetInputModAlgorithmIndex(const string &in identifier)
{
    for (uint i = 0; i < g_inputModAlgorithms.Length; i++)
    {
        if (g_inputModAlgorithms[i].identifier == identifier)
            return int(i);
    }
    return 0; 
}
InputModificationAlgorithm@ GetInputModAlgorithm(int index)
{
    if (index >= 0 && index < int(g_inputModAlgorithms.Length))
        return g_inputModAlgorithms[index];
    if (g_inputModAlgorithms.Length > 0)
        return g_inputModAlgorithms[0];
    return null;
}
InputModificationAlgorithm@ GetInputModAlgorithmByIdentifier(const string &in identifier)
{
    for (uint i = 0; i < g_inputModAlgorithms.Length; i++)
    {
        if (g_inputModAlgorithms[i].identifier == identifier)
            return g_inputModAlgorithms[i];
    }
    if (g_inputModAlgorithms.Length > 0)
        return g_inputModAlgorithms[0];
    return null;
}
void BasicAlgorithm_Mutate(TM::InputEventBuffer @buffer, InputModificationSettings @settings, uint settingsIndex)
{
    InputModification::MutateInputs(
        buffer,
        settings.inputCount,
        settings.minInputsTime,
        settings.maxInputsTime,
        settings.maxSteerDiff,
        settings.maxTimeDiff,
        settings.fillSteerInputs);
}
void BasicAlgorithm_RenderUI(InputModificationSettings @settings, uint settingsIndex, const string &in suffix, const string &in varSuffix)
{
    UI::InputIntVar("Input Modify Count" + suffix, "bf_modify_count" + varSuffix, 1);
    toolTip(300,
            {"At most " + int(GetVariableDouble("bf_modify_count" + varSuffix)) + " inputs will be changed each attempt."});
    UI::Dummy(vec2(0, 0));
    if (UI::BeginTable("##hack_for_the_tooltip" + suffix, 1))
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(18, 0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_min_time" + suffix, "bf_inputs_min_time" + varSuffix);
        UI::PopItemWidth();
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(37, 0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_max_time" + suffix, "bf_inputs_max_time" + varSuffix);
        UI::PopItemWidth();
        UI::EndTable();
    }
    toolTip(300, {"Time frame in which inputs can be changed", "Limiting this time frame will make the bruteforcing process faster."});
    UI::Dummy(vec2(0, 0));
    UI::PushItemWidth(300);
    int t = UI::SliderIntVar("Maximum Steering Difference" + suffix, "bf_max_steer_diff" + varSuffix, 0, 131072);
    toolTip(300, {"Bruteforce will randomize a number between [-" + t + ", " + t + "] and add it to the current steering value."});
    UI::Dummy(vec2(0, 2));
    int timediff = UI::InputTimeVar("Maximum Time Difference" + suffix, "bf_max_time_diff" + varSuffix);
    UI::PopItemWidth();
    toolTip(300, {"Bruteforce will randomize a number between [-" + timediff + ", " + timediff + "] milliseconds and add it to the current time value."});
    UI::CheckboxVar("Fill Missing Steering Input" + suffix, "bf_inputs_fill_steer" + varSuffix);
    toolTip(300, {"Timestamps with no steering input changes will be filled with existing values "
                  "resulting in more values that can be changed."});
}
void AdvancedBasicAlgorithm_Mutate(TM::InputEventBuffer @buffer, InputModificationSettings @settings, uint settingsIndex)
{
    string varSuffix = GetInputModVarSuffix(settingsIndex);
    int steerCount = int(GetVariableDouble("bf_adv_steer_modify_count" + varSuffix));
    int steerMinTime = int(GetVariableDouble("bf_adv_steer_min_time" + varSuffix));
    int steerMaxTime = int(GetVariableDouble("bf_adv_steer_max_time" + varSuffix));
    int steerMaxDiff = int(GetVariableDouble("bf_adv_steer_max_diff" + varSuffix));
    int steerMaxTimeDiff = int(GetVariableDouble("bf_adv_steer_max_time_diff" + varSuffix));
    bool steerFill = GetVariableBool("bf_adv_steer_fill" + varSuffix);
    if (steerCount > 0)
    {
        InputModification::MutateInputsByType(buffer, int(buffer.EventIndices.SteerId), steerCount, steerMinTime, steerMaxTime, steerMaxDiff, steerMaxTimeDiff, steerFill, false);
    }
    int accelCount = int(GetVariableDouble("bf_adv_accel_modify_count" + varSuffix));
    int accelMinTime = int(GetVariableDouble("bf_adv_accel_min_time" + varSuffix));
    int accelMaxTime = int(GetVariableDouble("bf_adv_accel_max_time" + varSuffix));
    int accelMaxTimeDiff = int(GetVariableDouble("bf_adv_accel_max_time_diff" + varSuffix));
    if (accelCount > 0)
    {
        InputModification::MutateInputsByType(buffer, int(buffer.EventIndices.AccelerateId), accelCount, accelMinTime, accelMaxTime, 0, accelMaxTimeDiff, false, true);
    }
    int brakeCount = int(GetVariableDouble("bf_adv_brake_modify_count" + varSuffix));
    int brakeMinTime = int(GetVariableDouble("bf_adv_brake_min_time" + varSuffix));
    int brakeMaxTime = int(GetVariableDouble("bf_adv_brake_max_time" + varSuffix));
    int brakeMaxTimeDiff = int(GetVariableDouble("bf_adv_brake_max_time_diff" + varSuffix));
    if (brakeCount > 0)
    {
        InputModification::MutateInputsByType(buffer, int(buffer.EventIndices.BrakeId), brakeCount, brakeMinTime, brakeMaxTime, 0, brakeMaxTimeDiff, false, true);
    }
}
void AdvancedBasicAlgorithm_RenderUI(InputModificationSettings @settings, uint settingsIndex, const string &in suffix, const string &in varSuffix)
{
    UI::PushID("adv_basic_" + settingsIndex);
    UI::PushItemWidth(300);
    if (UI::CollapsingHeader("Steering Settings" + suffix))
    {
        UI::InputIntVar("Modify Count (Steer)", "bf_adv_steer_modify_count" + varSuffix, 1);
        toolTip(300, {"Number of steering inputs to modify each attempt."});
        UI::Dummy(vec2(0, 0));
        if (UI::BeginTable("##adv_steer_time" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("From");
            UI::SameLine();
            UI::Dummy(vec2(18, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_adv_steer_min_time" + suffix, "bf_adv_steer_min_time" + varSuffix);
            UI::PopItemWidth();
            UI::Text("To");
            UI::SameLine();
            UI::Dummy(vec2(37, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_adv_steer_max_time" + suffix, "bf_adv_steer_max_time" + varSuffix);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which steering inputs can be changed."});
        UI::Dummy(vec2(0, 0));
        UI::PushItemWidth(300);
        int t = UI::SliderIntVar("Max Steering Difference (Steer)", "bf_adv_steer_max_diff" + varSuffix, 0, 131072);
        toolTip(300, {"Randomize between [-" + t + ", " + t + "] and add to current steering."});
        UI::Dummy(vec2(0, 2));
        int td = UI::InputTimeVar("Max Time Diff (Steer)", "bf_adv_steer_max_time_diff" + varSuffix);
        UI::PopItemWidth();
        toolTip(300, {"Randomize between [-" + td + ", " + td + "] ms and add to input time."});
        UI::CheckboxVar("Fill Missing Steering (Steer)", "bf_adv_steer_fill" + varSuffix);
        toolTip(300, {"Fill timestamps with no steering changes with existing values."});
    }
    UI::Dummy(vec2(0, 2));
    if (UI::CollapsingHeader("Acceleration Settings" + suffix))
    {
        UI::InputIntVar("Modify Count (Accel)", "bf_adv_accel_modify_count" + varSuffix, 1);
        toolTip(300, {"Number of acceleration inputs to modify (toggle on/off) each attempt."});
        UI::Dummy(vec2(0, 0));
        if (UI::BeginTable("##adv_accel_time" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("From");
            UI::SameLine();
            UI::Dummy(vec2(18, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_adv_accel_min_time" + suffix, "bf_adv_accel_min_time" + varSuffix);
            UI::PopItemWidth();
            UI::Text("To");
            UI::SameLine();
            UI::Dummy(vec2(37, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_adv_accel_max_time" + suffix, "bf_adv_accel_max_time" + varSuffix);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which acceleration inputs can be changed."});
        UI::Dummy(vec2(0, 2));
        UI::PushItemWidth(300);
        int td = UI::InputTimeVar("Max Time Diff (Accel)", "bf_adv_accel_max_time_diff" + varSuffix);
        UI::PopItemWidth();
        toolTip(300, {"Randomize between [-" + td + ", " + td + "] ms and add to input time."});
    }
    UI::Dummy(vec2(0, 2));
    if (UI::CollapsingHeader("Brake Settings" + suffix))
    {
        UI::InputIntVar("Modify Count (Brake)", "bf_adv_brake_modify_count" + varSuffix, 1);
        toolTip(300, {"Number of brake inputs to modify (toggle on/off) each attempt."});
        UI::Dummy(vec2(0, 0));
        if (UI::BeginTable("##adv_brake_time" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("From");
            UI::SameLine();
            UI::Dummy(vec2(18, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_adv_brake_min_time" + suffix, "bf_adv_brake_min_time" + varSuffix);
            UI::PopItemWidth();
            UI::Text("To");
            UI::SameLine();
            UI::Dummy(vec2(37, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_adv_brake_max_time" + suffix, "bf_adv_brake_max_time" + varSuffix);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which brake inputs can be changed."});
        UI::Dummy(vec2(0, 2));
        UI::PushItemWidth(300);
        int td = UI::InputTimeVar("Max Time Diff (Brake)", "bf_adv_brake_max_time_diff" + varSuffix);
        UI::PopItemWidth();
        toolTip(300, {"Randomize between [-" + td + ", " + td + "] ms and add to input time."});
    }
    UI::PopItemWidth();
    UI::PopID();
}
void AdvancedRangeAlgorithm_Mutate(TM::InputEventBuffer @buffer, InputModificationSettings @settings, uint settingsIndex)
{
    string varSuffix = GetInputModVarSuffix(settingsIndex);
    int steerMinCount = int(GetVariableDouble("bf_advr_steer_min_input_count" + varSuffix));
    int steerMaxCount = int(GetVariableDouble("bf_advr_steer_max_input_count" + varSuffix));
    int steerMinTime = int(GetVariableDouble("bf_advr_steer_min_time" + varSuffix));
    int steerMaxTime = int(GetVariableDouble("bf_advr_steer_max_time" + varSuffix));
    int steerMinSteer = int(GetVariableDouble("bf_advr_steer_min_steer" + varSuffix));
    int steerMaxSteer = int(GetVariableDouble("bf_advr_steer_max_steer" + varSuffix));
    int steerMinTimeDiff = int(GetVariableDouble("bf_advr_steer_min_time_diff" + varSuffix));
    int steerMaxTimeDiff = int(GetVariableDouble("bf_advr_steer_max_time_diff" + varSuffix));
    bool steerFill = GetVariableBool("bf_advr_steer_fill" + varSuffix);
    if (steerMinCount > 0 || steerMaxCount > 0)
    {
        InputModification::MutateInputsRangeByType(buffer, int(buffer.EventIndices.SteerId), steerMinCount, steerMaxCount, steerMinTime, steerMaxTime, steerMinSteer, steerMaxSteer, steerMinTimeDiff, steerMaxTimeDiff, steerFill, false);
    }
    int accelMinCount = int(GetVariableDouble("bf_advr_accel_min_input_count" + varSuffix));
    int accelMaxCount = int(GetVariableDouble("bf_advr_accel_max_input_count" + varSuffix));
    int accelMinTime = int(GetVariableDouble("bf_advr_accel_min_time" + varSuffix));
    int accelMaxTime = int(GetVariableDouble("bf_advr_accel_max_time" + varSuffix));
    int accelMinTimeDiff = int(GetVariableDouble("bf_advr_accel_min_time_diff" + varSuffix));
    int accelMaxTimeDiff = int(GetVariableDouble("bf_advr_accel_max_time_diff" + varSuffix));
    if (accelMinCount > 0 || accelMaxCount > 0)
    {
        InputModification::MutateInputsRangeByType(buffer, int(buffer.EventIndices.AccelerateId), accelMinCount, accelMaxCount, accelMinTime, accelMaxTime, 0, 0, accelMinTimeDiff, accelMaxTimeDiff, false, true);
    }
    int brakeMinCount = int(GetVariableDouble("bf_advr_brake_min_input_count" + varSuffix));
    int brakeMaxCount = int(GetVariableDouble("bf_advr_brake_max_input_count" + varSuffix));
    int brakeMinTime = int(GetVariableDouble("bf_advr_brake_min_time" + varSuffix));
    int brakeMaxTime = int(GetVariableDouble("bf_advr_brake_max_time" + varSuffix));
    int brakeMinTimeDiff = int(GetVariableDouble("bf_advr_brake_min_time_diff" + varSuffix));
    int brakeMaxTimeDiff = int(GetVariableDouble("bf_advr_brake_max_time_diff" + varSuffix));
    if (brakeMinCount > 0 || brakeMaxCount > 0)
    {
        InputModification::MutateInputsRangeByType(buffer, int(buffer.EventIndices.BrakeId), brakeMinCount, brakeMaxCount, brakeMinTime, brakeMaxTime, 0, 0, brakeMinTimeDiff, brakeMaxTimeDiff, false, true);
    }
}
void AdvancedRangeAlgorithm_RenderUI(InputModificationSettings @settings, uint settingsIndex, const string &in suffix, const string &in varSuffix)
{
    UI::PushID("adv_range_" + settingsIndex);
    UI::PushItemWidth(300);
    if (UI::CollapsingHeader("Steering Settings" + suffix))
    {
        if (UI::BeginTable("##advr_steer_count" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Min Input Count");
            UI::SameLine();
            UI::Dummy(vec2(35, 0));
            UI::SameLine();
            UI::Text("Max Input Count");
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_steer_min_input_count" + suffix, "bf_advr_steer_min_input_count" + varSuffix, 1);
            UI::PopItemWidth();
            UI::SameLine();
            UI::Dummy(vec2(0, 0));
            UI::SameLine();
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_steer_max_input_count" + suffix, "bf_advr_steer_max_input_count" + varSuffix, 1);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Number of steering inputs to modify, randomly chosen between min and max."});
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_steer_time" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("From");
            UI::SameLine();
            UI::Dummy(vec2(18, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_advr_steer_min_time" + suffix, "bf_advr_steer_min_time" + varSuffix);
            UI::PopItemWidth();
            UI::Text("To");
            UI::SameLine();
            UI::Dummy(vec2(37, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_advr_steer_max_time" + suffix, "bf_advr_steer_max_time" + varSuffix);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which steering inputs can be changed."});
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_steer_range" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Steering Value Range");
            UI::Text("Min");
            UI::SameLine();
            UI::Dummy(vec2(117, 0));
            UI::SameLine();
            UI::Text("Max");
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_steer_min_steer" + suffix, "bf_advr_steer_min_steer" + varSuffix, 1);
            UI::PopItemWidth();
            UI::SameLine();
            UI::Dummy(vec2(0, 0));
            UI::SameLine();
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_steer_max_steer" + suffix, "bf_advr_steer_max_steer" + varSuffix, 1);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Steering will be set to a random value between min and max.",
                      "Valid range is [-65536, 65536].",
                      "This OVERWRITES the existing steering value."});
        int minSteer = int(GetVariableDouble("bf_advr_steer_min_steer" + varSuffix));
        int maxSteer = int(GetVariableDouble("bf_advr_steer_max_steer" + varSuffix));
        if (minSteer < -65536) SetVariable("bf_advr_steer_min_steer" + varSuffix, -65536);
        if (maxSteer > 65536) SetVariable("bf_advr_steer_max_steer" + varSuffix, 65536);
        if (minSteer > maxSteer) SetVariable("bf_advr_steer_min_steer" + varSuffix, maxSteer);
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_steer_timediff" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Time Difference Range");
            UI::Text("Min");
            UI::SameLine();
            UI::Dummy(vec2(117, 0));
            UI::SameLine();
            UI::Text("Max");
            UI::Dummy(vec2(110, 0));
            UI::SameLine();
            UI::PushItemWidth(182);
            UI::InputTimeVar("##bf_advr_steer_max_time_diff" + suffix, "bf_advr_steer_max_time_diff" + varSuffix);
            UI::SameLine();
            UI::Dummy(vec2(-355, 0));
            UI::SameLine();
            UI::PushItemWidth(182);
            UI::InputTimeVar("##bf_advr_steer_min_time_diff" + suffix, "bf_advr_steer_min_time_diff" + varSuffix);
            UI::PopItemWidth();
            UI::SameLine();
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time offset randomly chosen between min and max."});
        UI::Dummy(vec2(0, 2));
        UI::CheckboxVar("Fill Missing Steering (Steer)", "bf_advr_steer_fill" + varSuffix);
        toolTip(300, {"Fill timestamps with no steering changes with existing values."});
    }
    UI::Dummy(vec2(0, 2));
    if (UI::CollapsingHeader("Acceleration Settings" + suffix))
    {
        if (UI::BeginTable("##advr_accel_count" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Min Input Count");
            UI::SameLine();
            UI::Dummy(vec2(35, 0));
            UI::SameLine();
            UI::Text("Max Input Count");
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_accel_min_input_count" + suffix, "bf_advr_accel_min_input_count" + varSuffix, 1);
            UI::PopItemWidth();
            UI::SameLine();
            UI::Dummy(vec2(0, 0));
            UI::SameLine();
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_accel_max_input_count" + suffix, "bf_advr_accel_max_input_count" + varSuffix, 1);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Number of acceleration inputs to modify (toggle on/off), randomly chosen between min and max."});
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_accel_time" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("From");
            UI::SameLine();
            UI::Dummy(vec2(18, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_advr_accel_min_time" + suffix, "bf_advr_accel_min_time" + varSuffix);
            UI::PopItemWidth();
            UI::Text("To");
            UI::SameLine();
            UI::Dummy(vec2(37, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_advr_accel_max_time" + suffix, "bf_advr_accel_max_time" + varSuffix);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which acceleration inputs can be changed."});
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_accel_timediff" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Time Difference Range");
            UI::Text("Min");
            UI::SameLine();
            UI::Dummy(vec2(117, 0));
            UI::SameLine();
            UI::Text("Max");
            UI::Dummy(vec2(110, 0));
            UI::SameLine();
            UI::PushItemWidth(182);
            UI::InputTimeVar("##bf_advr_accel_max_time_diff" + suffix, "bf_advr_accel_max_time_diff" + varSuffix);
            UI::SameLine();
            UI::Dummy(vec2(-355, 0));
            UI::SameLine();
            UI::PushItemWidth(182);
            UI::InputTimeVar("##bf_advr_accel_min_time_diff" + suffix, "bf_advr_accel_min_time_diff" + varSuffix);
            UI::PopItemWidth();
            UI::SameLine();
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time offset randomly chosen between min and max."});
    }
    UI::Dummy(vec2(0, 2));
    if (UI::CollapsingHeader("Brake Settings" + suffix))
    {
        if (UI::BeginTable("##advr_brake_count" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Min Input Count");
            UI::SameLine();
            UI::Dummy(vec2(35, 0));
            UI::SameLine();
            UI::Text("Max Input Count");
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_brake_min_input_count" + suffix, "bf_advr_brake_min_input_count" + varSuffix, 1);
            UI::PopItemWidth();
            UI::SameLine();
            UI::Dummy(vec2(0, 0));
            UI::SameLine();
            UI::PushItemWidth(142);
            UI::InputIntVar("##bf_advr_brake_max_input_count" + suffix, "bf_advr_brake_max_input_count" + varSuffix, 1);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Number of brake inputs to modify (toggle on/off), randomly chosen between min and max."});
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_brake_time" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("From");
            UI::SameLine();
            UI::Dummy(vec2(18, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_advr_brake_min_time" + suffix, "bf_advr_brake_min_time" + varSuffix);
            UI::PopItemWidth();
            UI::Text("To");
            UI::SameLine();
            UI::Dummy(vec2(37, 0));
            UI::SameLine();
            UI::PushItemWidth(195);
            UI::InputTimeVar("##bf_advr_brake_max_time" + suffix, "bf_advr_brake_max_time" + varSuffix);
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time frame in which brake inputs can be changed."});
        UI::Dummy(vec2(0, 2));
        if (UI::BeginTable("##advr_brake_timediff" + suffix, 1))
        {
            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            UI::Text("Time Difference Range");
            UI::Text("Min");
            UI::SameLine();
            UI::Dummy(vec2(117, 0));
            UI::SameLine();
            UI::Text("Max");
            UI::Dummy(vec2(110, 0));
            UI::SameLine();
            UI::PushItemWidth(182);
            UI::InputTimeVar("##bf_advr_brake_max_time_diff" + suffix, "bf_advr_brake_max_time_diff" + varSuffix);
            UI::SameLine();
            UI::Dummy(vec2(-355, 0));
            UI::SameLine();
            UI::PushItemWidth(182);
            UI::InputTimeVar("##bf_advr_brake_min_time_diff" + suffix, "bf_advr_brake_min_time_diff" + varSuffix);
            UI::PopItemWidth();
            UI::SameLine();
            UI::PopItemWidth();
            UI::EndTable();
        }
        toolTip(300, {"Time offset randomly chosen between min and max."});
    }
    UI::PopItemWidth();
    UI::PopID();
}
void InitializeInputModAlgorithms()
{
    if (g_inputModAlgorithms.Length == 0)
    {
        RegisterInputModAlgorithm("basic", "Basic", BasicAlgorithm_Mutate, BasicAlgorithm_RenderUI);
        RegisterInputModAlgorithm("range", "Range", RangeAlgorithm_Mutate, RangeAlgorithm_RenderUI);
        RegisterInputModAlgorithm("advanced_basic", "Advanced Basic", AdvancedBasicAlgorithm_Mutate, AdvancedBasicAlgorithm_RenderUI);
        RegisterInputModAlgorithm("advanced_range", "Advanced Range", AdvancedRangeAlgorithm_Mutate, AdvancedRangeAlgorithm_RenderUI);
    }
}
void RangeAlgorithm_Mutate(TM::InputEventBuffer @buffer, InputModificationSettings @settings, uint settingsIndex)
{
    string varSuffix = GetInputModVarSuffix(settingsIndex);
    int minInputCount = int(GetVariableDouble("bf_range_min_input_count" + varSuffix));
    int maxInputCount = int(GetVariableDouble("bf_range_max_input_count" + varSuffix));
    int minSteer = int(GetVariableDouble("bf_range_min_steer" + varSuffix));
    int maxSteer = int(GetVariableDouble("bf_range_max_steer" + varSuffix));
    int minTimeDiff = int(GetVariableDouble("bf_range_min_time_diff" + varSuffix));
    int maxTimeDiff = int(GetVariableDouble("bf_range_max_time_diff" + varSuffix));
    bool fillInputs = GetVariableBool("bf_range_fill_steer" + varSuffix);
    InputModification::MutateInputsRange(
        buffer,
        minInputCount,
        maxInputCount,
        settings.minInputsTime,
        settings.maxInputsTime,
        minSteer,
        maxSteer,
        minTimeDiff,
        maxTimeDiff,
        fillInputs);
}
void RangeAlgorithm_RenderUI(InputModificationSettings @settings, uint settingsIndex, const string &in suffix, const string &in varSuffix)
{
    if (UI::BeginTable("##input_count_range" + suffix, 1))
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text("Min Input Count");
        UI::SameLine();
        UI::Dummy(vec2(35, 0));
        UI::SameLine();
        UI::Text("Max Input Count");
        UI::PushItemWidth(142);
        UI::InputIntVar("##bf_range_min_input_count" + suffix, "bf_range_min_input_count" + varSuffix, 1);
        UI::PopItemWidth();
        UI::SameLine();
        UI::Dummy(vec2(0, 0));
        UI::SameLine();
        UI::PushItemWidth(142);
        UI::InputIntVar("##bf_range_max_input_count" + suffix, "bf_range_max_input_count" + varSuffix, 1);
        UI::PopItemWidth();
        UI::EndTable();
    }
    toolTip(300, {"Number of inputs to modify will be randomly chosen between min and max."});
    UI::Dummy(vec2(0, 2));
    if (UI::BeginTable("##hack_for_the_tooltip_range" + suffix, 1))
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(18, 0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_min_time" + suffix, "bf_inputs_min_time" + varSuffix);
        UI::PopItemWidth();
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(37, 0));
        UI::SameLine();
        UI::PushItemWidth(195);
        UI::InputTimeVar("##bf_inputs_max_time" + suffix, "bf_inputs_max_time" + varSuffix);
        UI::PopItemWidth();
        UI::EndTable();
    }
    toolTip(300, {"Time frame in which inputs can be changed."});
    UI::Dummy(vec2(0, 2));
    if (UI::BeginTable("##steer_range" + suffix, 1))
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text("Steering Value Range");
        UI::Text("Min");
        UI::SameLine();
        UI::Dummy(vec2(117, 0));
        UI::SameLine();
        UI::Text("Max");
        UI::PushItemWidth(142);
        UI::InputIntVar("##bf_range_min_steer" + suffix, "bf_range_min_steer" + varSuffix, 1);
        UI::PopItemWidth();
        UI::SameLine();
        UI::Dummy(vec2(0, 0));
        UI::SameLine();
        UI::PushItemWidth(142);
        UI::InputIntVar("##bf_range_max_steer" + suffix, "bf_range_max_steer" + varSuffix, 1);
        UI::PopItemWidth();
        UI::EndTable();
    }
    toolTip(300, {"Steering will be set to a random value between min and max.", 
                  "Valid range is [-65536, 65536].", 
                  "This OVERWRITES the existing steering value."});
    int minSteer = int(GetVariableDouble("bf_range_min_steer" + varSuffix));
    int maxSteer = int(GetVariableDouble("bf_range_max_steer" + varSuffix));
    if (minSteer < -65536) SetVariable("bf_range_min_steer" + varSuffix, -65536);
    if (maxSteer > 65536) SetVariable("bf_range_max_steer" + varSuffix, 65536);
    if (minSteer > maxSteer) SetVariable("bf_range_min_steer" + varSuffix, maxSteer);
    UI::Dummy(vec2(0, 2));
    if (UI::BeginTable("##time_diff_range" + suffix, 1))
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text("Time Difference Range");
        UI::Text("Min");
        UI::SameLine();
        UI::Dummy(vec2(117, 0));
        UI::SameLine();
        UI::Text("Max");
        UI::Dummy(vec2(110, 0));
        UI::SameLine();
        UI::PushItemWidth(182);
        UI::InputTimeVar("##bf_range_max_time_diff" + suffix, "bf_range_max_time_diff" + varSuffix);
        UI::SameLine();
        UI::Dummy(vec2(-355, 0));
        UI::SameLine();
        UI::PushItemWidth(182);
        UI::InputTimeVar("##bf_range_min_time_diff" + suffix, "bf_range_min_time_diff" + varSuffix);
        UI::PopItemWidth();
        UI::SameLine();
        UI::PopItemWidth();
        UI::EndTable();
    }
    toolTip(300, {"Time offset will be randomly chosen between min and max.", 
                  "Can be negative (shift earlier) or positive (shift later)."});
    UI::Dummy(vec2(0, 2));
    UI::CheckboxVar("Fill Missing Steering Input" + suffix, "bf_range_fill_steer" + varSuffix);
    toolTip(300, {"Timestamps with no steering input changes will be filled with existing values "
                  "resulting in more values that can be changed."});
}
class InputModificationSettings
{
    bool enabled = true;
    int inputCount = 0;
    int minInputsTime = 0;
    int maxInputsTime = 0;
    int maxSteerDiff = 0;
    int maxTimeDiff = 0;
    bool fillSteerInputs = false;
    int algorithmIndex = 0; 
    InputModificationSettings() {}
    InputModificationSettings(int count, int minTime, int maxTime, int steerDiff, int timeDiff, bool fill)
    {
        inputCount = count;
        minInputsTime = minTime;
        maxInputsTime = maxTime;
        maxSteerDiff = steerDiff;
        maxTimeDiff = timeDiff;
        fillSteerInputs = fill;
        algorithmIndex = 0;
    }
    InputModificationAlgorithm@ GetAlgorithm()
    {
        return GetInputModAlgorithm(algorithmIndex);
    }
}
array<InputModificationSettings@> g_inputModSettings;
void AddInputModificationSettings()
{
    InputModificationSettings @settings = InputModificationSettings();
    uint newIndex = g_inputModSettings.Length;
    string newSuffix = GetInputModVarSuffix(newIndex);
    if (g_inputModSettings.Length > 0)
    {
        string lastSuffix = GetInputModVarSuffix(newIndex - 1);
        SetVariable("bf_modify_count" + newSuffix, GetVariableDouble("bf_modify_count" + lastSuffix));
        SetVariable("bf_inputs_min_time" + newSuffix, GetVariableDouble("bf_inputs_min_time" + lastSuffix));
        SetVariable("bf_inputs_max_time" + newSuffix, GetVariableDouble("bf_inputs_max_time" + lastSuffix));
        SetVariable("bf_max_steer_diff" + newSuffix, GetVariableDouble("bf_max_steer_diff" + lastSuffix));
        SetVariable("bf_max_time_diff" + newSuffix, GetVariableDouble("bf_max_time_diff" + lastSuffix));
        SetVariable("bf_inputs_fill_steer" + newSuffix, GetVariableBool("bf_inputs_fill_steer" + lastSuffix));
        SetVariable("bf_input_mod_algorithm" + newSuffix, GetVariableString("bf_input_mod_algorithm" + lastSuffix));
        SetVariable("bf_range_min_input_count" + newSuffix, GetVariableDouble("bf_range_min_input_count" + lastSuffix));
        SetVariable("bf_range_max_input_count" + newSuffix, GetVariableDouble("bf_range_max_input_count" + lastSuffix));
        SetVariable("bf_range_min_steer" + newSuffix, GetVariableDouble("bf_range_min_steer" + lastSuffix));
        SetVariable("bf_range_max_steer" + newSuffix, GetVariableDouble("bf_range_max_steer" + lastSuffix));
        SetVariable("bf_range_min_time_diff" + newSuffix, GetVariableDouble("bf_range_min_time_diff" + lastSuffix));
        SetVariable("bf_range_max_time_diff" + newSuffix, GetVariableDouble("bf_range_max_time_diff" + lastSuffix));
        SetVariable("bf_range_fill_steer" + newSuffix, GetVariableBool("bf_range_fill_steer" + lastSuffix));
        SetVariable("bf_adv_steer_modify_count" + newSuffix, GetVariableDouble("bf_adv_steer_modify_count" + lastSuffix));
        SetVariable("bf_adv_steer_min_time" + newSuffix, GetVariableDouble("bf_adv_steer_min_time" + lastSuffix));
        SetVariable("bf_adv_steer_max_time" + newSuffix, GetVariableDouble("bf_adv_steer_max_time" + lastSuffix));
        SetVariable("bf_adv_steer_max_diff" + newSuffix, GetVariableDouble("bf_adv_steer_max_diff" + lastSuffix));
        SetVariable("bf_adv_steer_max_time_diff" + newSuffix, GetVariableDouble("bf_adv_steer_max_time_diff" + lastSuffix));
        SetVariable("bf_adv_steer_fill" + newSuffix, GetVariableBool("bf_adv_steer_fill" + lastSuffix));
        SetVariable("bf_adv_accel_modify_count" + newSuffix, GetVariableDouble("bf_adv_accel_modify_count" + lastSuffix));
        SetVariable("bf_adv_accel_min_time" + newSuffix, GetVariableDouble("bf_adv_accel_min_time" + lastSuffix));
        SetVariable("bf_adv_accel_max_time" + newSuffix, GetVariableDouble("bf_adv_accel_max_time" + lastSuffix));
        SetVariable("bf_adv_accel_max_time_diff" + newSuffix, GetVariableDouble("bf_adv_accel_max_time_diff" + lastSuffix));
        SetVariable("bf_adv_brake_modify_count" + newSuffix, GetVariableDouble("bf_adv_brake_modify_count" + lastSuffix));
        SetVariable("bf_adv_brake_min_time" + newSuffix, GetVariableDouble("bf_adv_brake_min_time" + lastSuffix));
        SetVariable("bf_adv_brake_max_time" + newSuffix, GetVariableDouble("bf_adv_brake_max_time" + lastSuffix));
        SetVariable("bf_adv_brake_max_time_diff" + newSuffix, GetVariableDouble("bf_adv_brake_max_time_diff" + lastSuffix));
        SetVariable("bf_advr_steer_min_input_count" + newSuffix, GetVariableDouble("bf_advr_steer_min_input_count" + lastSuffix));
        SetVariable("bf_advr_steer_max_input_count" + newSuffix, GetVariableDouble("bf_advr_steer_max_input_count" + lastSuffix));
        SetVariable("bf_advr_steer_min_time" + newSuffix, GetVariableDouble("bf_advr_steer_min_time" + lastSuffix));
        SetVariable("bf_advr_steer_max_time" + newSuffix, GetVariableDouble("bf_advr_steer_max_time" + lastSuffix));
        SetVariable("bf_advr_steer_min_steer" + newSuffix, GetVariableDouble("bf_advr_steer_min_steer" + lastSuffix));
        SetVariable("bf_advr_steer_max_steer" + newSuffix, GetVariableDouble("bf_advr_steer_max_steer" + lastSuffix));
        SetVariable("bf_advr_steer_min_time_diff" + newSuffix, GetVariableDouble("bf_advr_steer_min_time_diff" + lastSuffix));
        SetVariable("bf_advr_steer_max_time_diff" + newSuffix, GetVariableDouble("bf_advr_steer_max_time_diff" + lastSuffix));
        SetVariable("bf_advr_steer_fill" + newSuffix, GetVariableBool("bf_advr_steer_fill" + lastSuffix));
        SetVariable("bf_advr_accel_min_input_count" + newSuffix, GetVariableDouble("bf_advr_accel_min_input_count" + lastSuffix));
        SetVariable("bf_advr_accel_max_input_count" + newSuffix, GetVariableDouble("bf_advr_accel_max_input_count" + lastSuffix));
        SetVariable("bf_advr_accel_min_time" + newSuffix, GetVariableDouble("bf_advr_accel_min_time" + lastSuffix));
        SetVariable("bf_advr_accel_max_time" + newSuffix, GetVariableDouble("bf_advr_accel_max_time" + lastSuffix));
        SetVariable("bf_advr_accel_min_time_diff" + newSuffix, GetVariableDouble("bf_advr_accel_min_time_diff" + lastSuffix));
        SetVariable("bf_advr_accel_max_time_diff" + newSuffix, GetVariableDouble("bf_advr_accel_max_time_diff" + lastSuffix));
        SetVariable("bf_advr_brake_min_input_count" + newSuffix, GetVariableDouble("bf_advr_brake_min_input_count" + lastSuffix));
        SetVariable("bf_advr_brake_max_input_count" + newSuffix, GetVariableDouble("bf_advr_brake_max_input_count" + lastSuffix));
        SetVariable("bf_advr_brake_min_time" + newSuffix, GetVariableDouble("bf_advr_brake_min_time" + lastSuffix));
        SetVariable("bf_advr_brake_max_time" + newSuffix, GetVariableDouble("bf_advr_brake_max_time" + lastSuffix));
        SetVariable("bf_advr_brake_min_time_diff" + newSuffix, GetVariableDouble("bf_advr_brake_min_time_diff" + lastSuffix));
        SetVariable("bf_advr_brake_max_time_diff" + newSuffix, GetVariableDouble("bf_advr_brake_max_time_diff" + lastSuffix));
        if (newIndex > 0)
            SetVariable("bf_input_mod_enabled" + newSuffix, true);
    }
    g_inputModSettings.Add(settings);
    SetVariable("bf_input_mod_count", int(g_inputModSettings.Length));
}
string GetInputModVarSuffix(uint index)
{
    return (index == 0) ? "" : ("_" + index);
}
void RemoveInputModificationSettings(uint index)
{
    if (index < g_inputModSettings.Length && g_inputModSettings.Length > 1)
    {
        for (uint i = index; i < g_inputModSettings.Length - 1; i++)
        {
            string srcSuffix = GetInputModVarSuffix(i + 1);
            string dstSuffix = GetInputModVarSuffix(i);
            SetVariable("bf_modify_count" + dstSuffix, GetVariableDouble("bf_modify_count" + srcSuffix));
            SetVariable("bf_inputs_min_time" + dstSuffix, GetVariableDouble("bf_inputs_min_time" + srcSuffix));
            SetVariable("bf_inputs_max_time" + dstSuffix, GetVariableDouble("bf_inputs_max_time" + srcSuffix));
            SetVariable("bf_max_steer_diff" + dstSuffix, GetVariableDouble("bf_max_steer_diff" + srcSuffix));
            SetVariable("bf_max_time_diff" + dstSuffix, GetVariableDouble("bf_max_time_diff" + srcSuffix));
            SetVariable("bf_inputs_fill_steer" + dstSuffix, GetVariableBool("bf_inputs_fill_steer" + srcSuffix));
            SetVariable("bf_input_mod_algorithm" + dstSuffix, GetVariableString("bf_input_mod_algorithm" + srcSuffix));
            SetVariable("bf_range_min_input_count" + dstSuffix, GetVariableDouble("bf_range_min_input_count" + srcSuffix));
            SetVariable("bf_range_max_input_count" + dstSuffix, GetVariableDouble("bf_range_max_input_count" + srcSuffix));
            SetVariable("bf_range_min_steer" + dstSuffix, GetVariableDouble("bf_range_min_steer" + srcSuffix));
            SetVariable("bf_range_max_steer" + dstSuffix, GetVariableDouble("bf_range_max_steer" + srcSuffix));
            SetVariable("bf_range_min_time_diff" + dstSuffix, GetVariableDouble("bf_range_min_time_diff" + srcSuffix));
            SetVariable("bf_range_max_time_diff" + dstSuffix, GetVariableDouble("bf_range_max_time_diff" + srcSuffix));
            SetVariable("bf_range_fill_steer" + dstSuffix, GetVariableBool("bf_range_fill_steer" + srcSuffix));
            SetVariable("bf_adv_steer_modify_count" + dstSuffix, GetVariableDouble("bf_adv_steer_modify_count" + srcSuffix));
            SetVariable("bf_adv_steer_min_time" + dstSuffix, GetVariableDouble("bf_adv_steer_min_time" + srcSuffix));
            SetVariable("bf_adv_steer_max_time" + dstSuffix, GetVariableDouble("bf_adv_steer_max_time" + srcSuffix));
            SetVariable("bf_adv_steer_max_diff" + dstSuffix, GetVariableDouble("bf_adv_steer_max_diff" + srcSuffix));
            SetVariable("bf_adv_steer_max_time_diff" + dstSuffix, GetVariableDouble("bf_adv_steer_max_time_diff" + srcSuffix));
            SetVariable("bf_adv_steer_fill" + dstSuffix, GetVariableBool("bf_adv_steer_fill" + srcSuffix));
            SetVariable("bf_adv_accel_modify_count" + dstSuffix, GetVariableDouble("bf_adv_accel_modify_count" + srcSuffix));
            SetVariable("bf_adv_accel_min_time" + dstSuffix, GetVariableDouble("bf_adv_accel_min_time" + srcSuffix));
            SetVariable("bf_adv_accel_max_time" + dstSuffix, GetVariableDouble("bf_adv_accel_max_time" + srcSuffix));
            SetVariable("bf_adv_accel_max_time_diff" + dstSuffix, GetVariableDouble("bf_adv_accel_max_time_diff" + srcSuffix));
            SetVariable("bf_adv_brake_modify_count" + dstSuffix, GetVariableDouble("bf_adv_brake_modify_count" + srcSuffix));
            SetVariable("bf_adv_brake_min_time" + dstSuffix, GetVariableDouble("bf_adv_brake_min_time" + srcSuffix));
            SetVariable("bf_adv_brake_max_time" + dstSuffix, GetVariableDouble("bf_adv_brake_max_time" + srcSuffix));
            SetVariable("bf_adv_brake_max_time_diff" + dstSuffix, GetVariableDouble("bf_adv_brake_max_time_diff" + srcSuffix));
            SetVariable("bf_advr_steer_min_input_count" + dstSuffix, GetVariableDouble("bf_advr_steer_min_input_count" + srcSuffix));
            SetVariable("bf_advr_steer_max_input_count" + dstSuffix, GetVariableDouble("bf_advr_steer_max_input_count" + srcSuffix));
            SetVariable("bf_advr_steer_min_time" + dstSuffix, GetVariableDouble("bf_advr_steer_min_time" + srcSuffix));
            SetVariable("bf_advr_steer_max_time" + dstSuffix, GetVariableDouble("bf_advr_steer_max_time" + srcSuffix));
            SetVariable("bf_advr_steer_min_steer" + dstSuffix, GetVariableDouble("bf_advr_steer_min_steer" + srcSuffix));
            SetVariable("bf_advr_steer_max_steer" + dstSuffix, GetVariableDouble("bf_advr_steer_max_steer" + srcSuffix));
            SetVariable("bf_advr_steer_min_time_diff" + dstSuffix, GetVariableDouble("bf_advr_steer_min_time_diff" + srcSuffix));
            SetVariable("bf_advr_steer_max_time_diff" + dstSuffix, GetVariableDouble("bf_advr_steer_max_time_diff" + srcSuffix));
            SetVariable("bf_advr_steer_fill" + dstSuffix, GetVariableBool("bf_advr_steer_fill" + srcSuffix));
            SetVariable("bf_advr_accel_min_input_count" + dstSuffix, GetVariableDouble("bf_advr_accel_min_input_count" + srcSuffix));
            SetVariable("bf_advr_accel_max_input_count" + dstSuffix, GetVariableDouble("bf_advr_accel_max_input_count" + srcSuffix));
            SetVariable("bf_advr_accel_min_time" + dstSuffix, GetVariableDouble("bf_advr_accel_min_time" + srcSuffix));
            SetVariable("bf_advr_accel_max_time" + dstSuffix, GetVariableDouble("bf_advr_accel_max_time" + srcSuffix));
            SetVariable("bf_advr_accel_min_time_diff" + dstSuffix, GetVariableDouble("bf_advr_accel_min_time_diff" + srcSuffix));
            SetVariable("bf_advr_accel_max_time_diff" + dstSuffix, GetVariableDouble("bf_advr_accel_max_time_diff" + srcSuffix));
            SetVariable("bf_advr_brake_min_input_count" + dstSuffix, GetVariableDouble("bf_advr_brake_min_input_count" + srcSuffix));
            SetVariable("bf_advr_brake_max_input_count" + dstSuffix, GetVariableDouble("bf_advr_brake_max_input_count" + srcSuffix));
            SetVariable("bf_advr_brake_min_time" + dstSuffix, GetVariableDouble("bf_advr_brake_min_time" + srcSuffix));
            SetVariable("bf_advr_brake_max_time" + dstSuffix, GetVariableDouble("bf_advr_brake_max_time" + srcSuffix));
            SetVariable("bf_advr_brake_min_time_diff" + dstSuffix, GetVariableDouble("bf_advr_brake_min_time_diff" + srcSuffix));
            SetVariable("bf_advr_brake_max_time_diff" + dstSuffix, GetVariableDouble("bf_advr_brake_max_time_diff" + srcSuffix));
            if (i > 0)
                SetVariable("bf_input_mod_enabled" + dstSuffix, GetVariableBool("bf_input_mod_enabled" + srcSuffix));
        }
        g_inputModSettings.RemoveAt(index);
        SetVariable("bf_input_mod_count", int(g_inputModSettings.Length));
    }
}
void MutateAllInputs(TM::InputEventBuffer @buffer)
{
    InputModification::g_earliestMutationTime = 2147483647;
    for (uint im = 0; im < g_inputModSettings.Length; im++)
    {
        InputModificationSettings @settings = g_inputModSettings[im];
        if (!settings.enabled)
            continue;
        InputModificationAlgorithm @algo = settings.GetAlgorithm();
        if (algo !is null && algo.mutateCallback !is null)
        {
            algo.mutateCallback(buffer, settings, im);
        }
    }
}
int inputCount = 0;
int minInputsTime = 0;
int maxInputsTime = 0;
int maxSteerDiff = 0;
int maxTimeDiff = 0;
bool fillSteerInputs = false;
bool forceStop = false;
int leastMinInputsTime = 0;
array<TM::InputEvent> bestInputEvents;
bool hasBestInputs = false;
array<TM::InputEvent> baseInputEvents;
bool hasBaseInputs = false;
void SaveBestInputs(SimulationManager @simManager, bool printSaved = false)
{
    TM::InputEventBuffer @buf = simManager.InputEvents;
    if (buf is null)
        return;
    bestInputEvents.Resize(0);
    for (uint i = 0; i < buf.Length; i++)
    {
        auto evt = buf[i];
        bestInputEvents.Add(evt);
        if (printSaved)
        {
            print("Saved Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
    hasBestInputs = true;
}
void SaveBaseInputs(SimulationManager @simManager, bool printSaved = false)
{
    TM::InputEventBuffer @buf = simManager.InputEvents;
    if (buf is null)
        return;
    baseInputEvents.Resize(0);
    for (uint i = 0; i < buf.Length; i++)
    {
        auto evt = buf[i];
        baseInputEvents.Add(evt);
        if (printSaved)
        {
            print("Saved Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
    hasBaseInputs = true;
}
void RestoreBestInputs(SimulationManager @simManager, bool printRestored = false)
{
    if (!hasBestInputs)
        return;
    TM::InputEventBuffer @buf = simManager.InputEvents;
    if (buf is null)
        return;
    buf.Clear();
    for (uint i = 0; i < bestInputEvents.Length; i++)
    {
        auto evt = bestInputEvents[i];
        buf.Add(evt);
        if (printRestored)
        {
            print("Restored Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
}
void RestoreBaseInputs(SimulationManager @simManager, bool printRestored = false)
{
    if (!hasBaseInputs)
        return;
    TM::InputEventBuffer @buf = simManager.InputEvents;
    if (buf is null)
        return;
    buf.Clear();
    for (uint i = 0; i < baseInputEvents.Length; i++)
    {
        auto evt = baseInputEvents[i];
        buf.Add(evt);
        if (printRestored)
        {
            print("Restored Input: Time=" + evt.Time + " | Index=" + evt.Value.EventIndex + " | Analog=" + evt.Value.Analog);
        }
    }
}
bool GlobalConditionsMet(SimulationManager @simManager)
{
    float currentSpeed = simManager.Dyna.CurrentState.LinearSpeed.Length();
    int currentCps = simManager.PlayerInfo.CurCheckpointCount;
    bool triggerCondition = !hasConditionTrigger || conditionTrigger.ContainsPoint(simManager.Dyna.CurrentState.Location.Position);
    return currentSpeed >= minSpeed && currentCps >= minCps && triggerCondition && (standardCondition is null || standardCondition(simManager));
}
SimulationState rewindState;
bool rewindStateAssigned = false;
array<SimulationState@> simStateCache;
array<int> simStateTimes;
SimulationState@ FindNearestCachedState(int earliestMutationTime)
{
    int target = earliestMutationTime - 10;
    for (int i = int(simStateTimes.Length) - 1; i >= 0; i--)
    {
        if (simStateTimes[i] <= target)
            return simStateCache[i];
    }
    return rewindState;
}
array<int> CheckpointStates;
bool IsBfV2Active = false;
bool running = false;
array<string> restartInfos;
string ResultFileStartContent = "";
void OnSimulationBegin(SimulationManager @simManager)
{
    InitializeInputModAlgorithms();
    InputModification::cachedStartIndex = -1;
    IsBfV2Active = GetVariableString("controller") == "bfv2";
    if (IsBfV2Active)
    {
        bfStartTime = Time::Now;
        bfRunning = true;
        currentIterations = 0;
        currentRestarts = 0;
        lastIterationTime = 0;
        iterationsPerSecond = 0.0f;
        iterationsAtLastCalc = 0;
    }
    if (!IsBfV2Active)
        return;
    @current = @GetBruteforceTarget();
    if (current is null)
    {
        SetVariable("bf_target", evaluations[0].identifier);
        @current = @evaluations[0];
    }
    currentTarget = current.title;
    currentPhase = "Initial";
    StartSession();
    DashboardLog("BF started: " + currentTarget);
    simManager.RemoveStateValidation();
    info.Iterations = 0;
    info.Phase = BFPhase::Initial;
    info.Rewinded = false;
    forceStop = false;
    restartCount = 0;
    rewindStateAssigned = false;
    simStateCache.Clear();
    simStateTimes.Clear();
    running = true;
    CheckpointStates = simManager.PlayerInfo.CheckpointStates;
    restartInfos.Clear();
    uint64 now = Time::Now;
    lastImprovementTime = now;
    lastRestartTime = now;
    InputModification::cachedStartIndex = -1;
    InputModification::cachedMinTime = -1;
    int savedCount = int(GetVariableDouble("bf_input_mod_count"));
    if (savedCount < 1) savedCount = 1;
    while (int(g_inputModSettings.Length) < savedCount)
    {
        InputModificationSettings @settings = InputModificationSettings();
        g_inputModSettings.Add(settings);
    }
    while (int(g_inputModSettings.Length) > savedCount)
    {
        g_inputModSettings.RemoveAt(g_inputModSettings.Length - 1);
    }
    for (uint im = 0; im < g_inputModSettings.Length; im++)
    {
        string varSuffix = GetInputModVarSuffix(im);
        InputModificationSettings @settings = g_inputModSettings[im];
        settings.inputCount = int(GetVariableDouble("bf_modify_count" + varSuffix));
        settings.minInputsTime = int(GetVariableDouble("bf_inputs_min_time" + varSuffix));
        settings.maxInputsTime = int(GetVariableDouble("bf_inputs_max_time" + varSuffix));
        settings.maxSteerDiff = int(GetVariableDouble("bf_max_steer_diff" + varSuffix));
        settings.maxTimeDiff = int(GetVariableDouble("bf_max_time_diff" + varSuffix));
        settings.fillSteerInputs = GetVariableBool("bf_inputs_fill_steer" + varSuffix);
        settings.enabled = (im == 0) || GetVariableBool("bf_input_mod_enabled" + varSuffix);
        string savedAlgoId = GetVariableString("bf_input_mod_algorithm" + varSuffix);
        if (savedAlgoId == "") savedAlgoId = "basic";
        settings.algorithmIndex = GetInputModAlgorithmIndex(savedAlgoId);
        settings.maxInputsTime = ResolveMaxTime(settings.maxInputsTime, int(simManager.EventsDuration));
        // Fix maxTime==0 for advanced algorithm variables
        string algoId_fix = GetVariableString("bf_input_mod_algorithm" + varSuffix);
        int ed = int(simManager.EventsDuration);
        if (algoId_fix == "advanced_basic")
        {
            if (int(GetVariableDouble("bf_adv_steer_max_time" + varSuffix)) == 0)
                SetVariable("bf_adv_steer_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_adv_accel_max_time" + varSuffix)) == 0)
                SetVariable("bf_adv_accel_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_adv_brake_max_time" + varSuffix)) == 0)
                SetVariable("bf_adv_brake_max_time" + varSuffix, ed);
        }
        else if (algoId_fix == "advanced_range")
        {
            if (int(GetVariableDouble("bf_advr_steer_max_time" + varSuffix)) == 0)
                SetVariable("bf_advr_steer_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_advr_accel_max_time" + varSuffix)) == 0)
                SetVariable("bf_advr_accel_max_time" + varSuffix, ed);
            if (int(GetVariableDouble("bf_advr_brake_max_time" + varSuffix)) == 0)
                SetVariable("bf_advr_brake_max_time" + varSuffix, ed);
        }
    }
    if (g_inputModSettings.Length > 0)
    {
        inputCount = g_inputModSettings[0].inputCount;
        minInputsTime = g_inputModSettings[0].minInputsTime;
        maxInputsTime = g_inputModSettings[0].maxInputsTime;
        maxSteerDiff = g_inputModSettings[0].maxSteerDiff;
        maxTimeDiff = g_inputModSettings[0].maxTimeDiff;
        fillSteerInputs = g_inputModSettings[0].fillSteerInputs;
    }
    leastMinInputsTime = 1000000000;
    for (uint i = 0; i < g_inputModSettings.Length; i++) {
        InputModificationSettings@ s = g_inputModSettings[i];
        if (s.enabled && s.minInputsTime < leastMinInputsTime)
            leastMinInputsTime = s.minInputsTime;
    }
    minSpeed = float(GetVariableDouble("bf_condition_speed")) / 3.6f; 
    minCps = int(GetVariableDouble("bf_condition_cps"));
    int triggerIndex = int(GetVariableDouble("bf_condition_trigger"));
    hasConditionTrigger = false;
    if (triggerIndex > 0)
    {
        array<int> @triggerIds = GetTriggerIds();
        if (triggerIndex <= int(triggerIds.Length))
        {
            conditionTrigger = GetTrigger(triggerIds[triggerIndex - 1]);
            hasConditionTrigger = true;
        }
    }
    restartIterations = int(GetVariableDouble("bf_iterations_before_restart"));
    resultFolder = GetVariableString("bf_result_folder");
    print("Bruteforce V2 started with settings:");
    print(" - Target: " + current.title);
    for (uint im = 0; im < g_inputModSettings.Length; im++)
    {
        InputModificationSettings @settings = g_inputModSettings[im];
        string enabledStr = settings.enabled ? "" : " [DISABLED]";
        InputModificationAlgorithm @algo = settings.GetAlgorithm();
        string algoName = (algo !is null) ? algo.name : "Unknown";
        print(" - Input Modification #" + (im + 1) + enabledStr + " (" + algoName + "):");
        string varSuffix = GetInputModVarSuffix(im);
        if (algo !is null && algo.identifier == "range")
        {
            int minInputCount = int(GetVariableDouble("bf_range_min_input_count" + varSuffix));
            int maxInputCount = int(GetVariableDouble("bf_range_max_input_count" + varSuffix));
            int minSteer = int(GetVariableDouble("bf_range_min_steer" + varSuffix));
            int maxSteer = int(GetVariableDouble("bf_range_max_steer" + varSuffix));
            int minTimeDiff = int(GetVariableDouble("bf_range_min_time_diff" + varSuffix));
            int maxTimeDiff = int(GetVariableDouble("bf_range_max_time_diff" + varSuffix));
            bool fillInputs = GetVariableBool("bf_range_fill_steer" + varSuffix);
            print("   - Input Count Range: " + minInputCount + " to " + maxInputCount);
            print("   - Time Frame: From " + Time::Format(settings.minInputsTime) + " to " + Time::Format(settings.maxInputsTime));
            print("   - Steering Value Range: " + minSteer + " to " + maxSteer);
            print("   - Time Diff Range: " + Time::Format(minTimeDiff) + " to " + Time::Format(maxTimeDiff));
            print("   - Fill Steer: " + (fillInputs ? "Yes" : "No"));
        }
        else if (algo !is null && algo.identifier == "advanced_basic")
        {
            print("   [Steering]");
            print("     - Modify Count: " + int(GetVariableDouble("bf_adv_steer_modify_count" + varSuffix)));
            print("     - Time Frame: From " + Time::Format(int(GetVariableDouble("bf_adv_steer_min_time" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_adv_steer_max_time" + varSuffix))));
            print("     - Max Steer Diff: " + int(GetVariableDouble("bf_adv_steer_max_diff" + varSuffix)));
            print("     - Max Time Diff: " + Time::Format(int(GetVariableDouble("bf_adv_steer_max_time_diff" + varSuffix))));
            print("     - Fill Steer: " + (GetVariableBool("bf_adv_steer_fill" + varSuffix) ? "Yes" : "No"));
            print("   [Acceleration]");
            print("     - Modify Count: " + int(GetVariableDouble("bf_adv_accel_modify_count" + varSuffix)));
            print("     - Time Frame: From " + Time::Format(int(GetVariableDouble("bf_adv_accel_min_time" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_adv_accel_max_time" + varSuffix))));
            print("     - Max Time Diff: " + Time::Format(int(GetVariableDouble("bf_adv_accel_max_time_diff" + varSuffix))));
            print("   [Brake]");
            print("     - Modify Count: " + int(GetVariableDouble("bf_adv_brake_modify_count" + varSuffix)));
            print("     - Time Frame: From " + Time::Format(int(GetVariableDouble("bf_adv_brake_min_time" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_adv_brake_max_time" + varSuffix))));
            print("     - Max Time Diff: " + Time::Format(int(GetVariableDouble("bf_adv_brake_max_time_diff" + varSuffix))));
        }
        else if (algo !is null && algo.identifier == "advanced_range")
        {
            print("   [Steering]");
            print("     - Input Count Range: " + int(GetVariableDouble("bf_advr_steer_min_input_count" + varSuffix)) + " to " + int(GetVariableDouble("bf_advr_steer_max_input_count" + varSuffix)));
            print("     - Time Frame: From " + Time::Format(int(GetVariableDouble("bf_advr_steer_min_time" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_advr_steer_max_time" + varSuffix))));
            print("     - Steer Range: " + int(GetVariableDouble("bf_advr_steer_min_steer" + varSuffix)) + " to " + int(GetVariableDouble("bf_advr_steer_max_steer" + varSuffix)));
            print("     - Time Diff Range: " + Time::Format(int(GetVariableDouble("bf_advr_steer_min_time_diff" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_advr_steer_max_time_diff" + varSuffix))));
            print("     - Fill Steer: " + (GetVariableBool("bf_advr_steer_fill" + varSuffix) ? "Yes" : "No"));
            print("   [Acceleration]");
            print("     - Input Count Range: " + int(GetVariableDouble("bf_advr_accel_min_input_count" + varSuffix)) + " to " + int(GetVariableDouble("bf_advr_accel_max_input_count" + varSuffix)));
            print("     - Time Frame: From " + Time::Format(int(GetVariableDouble("bf_advr_accel_min_time" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_advr_accel_max_time" + varSuffix))));
            print("     - Time Diff Range: " + Time::Format(int(GetVariableDouble("bf_advr_accel_min_time_diff" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_advr_accel_max_time_diff" + varSuffix))));
            print("   [Brake]");
            print("     - Input Count Range: " + int(GetVariableDouble("bf_advr_brake_min_input_count" + varSuffix)) + " to " + int(GetVariableDouble("bf_advr_brake_max_input_count" + varSuffix)));
            print("     - Time Frame: From " + Time::Format(int(GetVariableDouble("bf_advr_brake_min_time" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_advr_brake_max_time" + varSuffix))));
            print("     - Time Diff Range: " + Time::Format(int(GetVariableDouble("bf_advr_brake_min_time_diff" + varSuffix))) + " to " + Time::Format(int(GetVariableDouble("bf_advr_brake_max_time_diff" + varSuffix))));
        }
        else
        {
            print("   - Modify Count: " + settings.inputCount);
            print("   - Time Frame: From " + Time::Format(settings.minInputsTime) + " to " + Time::Format(settings.maxInputsTime));
            print("   - Max Steering Diff: " + settings.maxSteerDiff);
            print("   - Max Time Diff: " + Time::Format(settings.maxTimeDiff));
            print("   - Fill Steer: " + (settings.fillSteerInputs ? "Yes" : "No"));
        }
    }
    print("Conditions:");
    print(" - Min Speed: " + Text::FormatFloat(minSpeed * 3.6f, "", 0, 2) + " km/h");
    print(" - Min CPs: " + minCps);
    print("Restarting every " + restartIterations + " Iterations");
    print("Storing results to folder: " + resultFolder);
    SetConsoleWindowTitle("BfV2 - " + current.title + " starting...");
    bestInputEvents.Clear();
    hasBestInputs = false;
    SaveBestInputs(simManager);
    SaveBaseInputs(simManager);
    if (current.onSimBegin !is null)
        current.onSimBegin(simManager);
}
void OnSimulationStep(SimulationManager @simManager, bool userCancelled)
{
    if (!IsBfV2Active)
        return;
    if (forceStop || userCancelled)
        return;
    if (current !is null && current.onRunStep !is null)
        current.onRunStep(simManager);
    bool r1 = restartIterations > 0 && int(info.Iterations) >= restartIterations;
    bool r2 = restartCondition !is null && restartCondition(simManager);
    uint64 now = Time::Now;
    if (r1 || r2)
    {
        restartCount++;
        currentRestarts = uint(restartCount);
        DashboardLog("Restart #" + Text::FormatInt(restartCount));
        RestoreBestInputs(simManager);
        CommandList list();
        list.Content = simManager.InputEvents.ToCommandsText();
        string filename = GetVariableString("bf_result_filename");
        string fullpath = "";
        if (resultFolder != "")
        {
            fullpath = resultFolder + "/";
        }
        int indexPos = filename.FindLast("{i}");
        if (indexPos != -1)
        {
            filename.Erase(indexPos, 3);
            filename.Insert(indexPos, Text::FormatInt(restartCount));
        }
        else
        {
            filename = "pass" + (restartCount) + "_" + filename;
        }
        fullpath += filename;
        list.Save(fullpath) ? print("Saved command list to: " + fullpath) : print("Failed to save command list to: " + fullpath);
        RestoreBaseInputs(simManager, false);
        SaveBestInputs(simManager, false);
        SetConsoleWindowTitle("BfV2 - " + current.title  + " | Restarts: " + restartCount + " | restarting...");
        print("Restarting Bruteforce for reasons: ");
        if (r1)
            print("- Reached max iterations before restart: " + restartIterations);
        if (r2)
            print("- Restart condition script returned true.");
        restartInfos.Add(ResultFileStartContent);
        ResultFileStartContent = "";
        print("Total restarts so far: " + restartCount);
        array<uint> sortedIndices(restartInfos.Length);
        for (uint i = 0; i < restartInfos.Length; i++)
            sortedIndices[i] = i;
        for (uint i = 0; i < sortedIndices.Length; i++)
        {
            for (uint j = i + 1; j < sortedIndices.Length; j++)
            {
                if (restartInfos[sortedIndices[j]] < restartInfos[sortedIndices[i]])
                {
                    uint temp = sortedIndices[i];
                    sortedIndices[i] = sortedIndices[j];
                    sortedIndices[j] = temp;
                }
            }
        }
        for (uint i = 0; i < sortedIndices.Length; i++)
        {
            uint idx = sortedIndices[i];
            print("- Restart N " + (idx + 1) + ": \"" + restartInfos[idx] + "\"");
        }
        int savedCount = int(GetVariableDouble("bf_input_mod_count"));
        if (savedCount < 1) savedCount = 1;
        while (int(g_inputModSettings.Length) < savedCount)
        {
            InputModificationSettings @settings = InputModificationSettings();
            g_inputModSettings.Add(settings);
        }
        while (int(g_inputModSettings.Length) > savedCount)
        {
            g_inputModSettings.RemoveAt(g_inputModSettings.Length - 1);
        }
        for (uint im = 0; im < g_inputModSettings.Length; im++)
        {
            string varSuffix = GetInputModVarSuffix(im);
            InputModificationSettings @settings = g_inputModSettings[im];
            settings.inputCount = int(GetVariableDouble("bf_modify_count" + varSuffix));
            settings.minInputsTime = int(GetVariableDouble("bf_inputs_min_time" + varSuffix));
            settings.maxInputsTime = int(GetVariableDouble("bf_inputs_max_time" + varSuffix));
            settings.maxSteerDiff = int(GetVariableDouble("bf_max_steer_diff" + varSuffix));
            settings.maxTimeDiff = int(GetVariableDouble("bf_max_time_diff" + varSuffix));
            settings.fillSteerInputs = GetVariableBool("bf_inputs_fill_steer" + varSuffix);
            settings.enabled = (im == 0) || GetVariableBool("bf_input_mod_enabled" + varSuffix);
            settings.maxInputsTime = ResolveMaxTime(settings.maxInputsTime, int(simManager.EventsDuration));
            // Fix maxTime==0 for advanced algorithm variables on restart
            string algoId_fix = GetVariableString("bf_input_mod_algorithm" + varSuffix);
            int ed = int(simManager.EventsDuration);
            if (algoId_fix == "advanced_basic")
            {
                if (int(GetVariableDouble("bf_adv_steer_max_time" + varSuffix)) == 0)
                    SetVariable("bf_adv_steer_max_time" + varSuffix, ed);
                if (int(GetVariableDouble("bf_adv_accel_max_time" + varSuffix)) == 0)
                    SetVariable("bf_adv_accel_max_time" + varSuffix, ed);
                if (int(GetVariableDouble("bf_adv_brake_max_time" + varSuffix)) == 0)
                    SetVariable("bf_adv_brake_max_time" + varSuffix, ed);
            }
            else if (algoId_fix == "advanced_range")
            {
                if (int(GetVariableDouble("bf_advr_steer_max_time" + varSuffix)) == 0)
                    SetVariable("bf_advr_steer_max_time" + varSuffix, ed);
                if (int(GetVariableDouble("bf_advr_accel_max_time" + varSuffix)) == 0)
                    SetVariable("bf_advr_accel_max_time" + varSuffix, ed);
                if (int(GetVariableDouble("bf_advr_brake_max_time" + varSuffix)) == 0)
                    SetVariable("bf_advr_brake_max_time" + varSuffix, ed);
            }
        }
        if (g_inputModSettings.Length > 0)
        {
            inputCount = g_inputModSettings[0].inputCount;
            minInputsTime = g_inputModSettings[0].minInputsTime;
            maxInputsTime = g_inputModSettings[0].maxInputsTime;
            maxSteerDiff = g_inputModSettings[0].maxSteerDiff;
            maxTimeDiff = g_inputModSettings[0].maxTimeDiff;
            fillSteerInputs = g_inputModSettings[0].fillSteerInputs;
        }
        if (current.onSimBegin !is null)
        {
            current.onSimBegin(simManager);
        }
        info.Iterations = 0;
        info.Phase = BFPhase::Initial;
        currentPhase = "Initial";
        currentIterations = 0;
        info.Rewinded = false;
        lastRestartTime = now;
        lastImprovementTime = now;
        simStateCache.Clear();
        simStateTimes.Clear();
        simManager.RewindToState(rewindState);
        return;
    }
    uint64 pollNow = Time::Now;
    if (pollNow - lastPollTime >= 100)
    {
        PollServer();
        lastPollTime = pollNow;
    }
    if(now - lastWindowTitleUpdateTime > 1000)
    {
        lastWindowTitleUpdateTime = now;
        if (now > lastIterationTime && lastIterationTime > 0)
        {
            float elapsedCalc = float(now - lastIterationTime) / 1000.0f;
            if (elapsedCalc > 0.0f)
                iterationsPerSecond = float(info.Iterations - iterationsAtLastCalc) / elapsedCalc;
        }
        lastIterationTime = now;
        iterationsAtLastCalc = info.Iterations;
        float elapsedSeconds = (now - lastRestartTime) / 1000.0f;
        if (elapsedSeconds > 0)
        {
            float iterPerSec = info.Iterations / elapsedSeconds;
            SetConsoleWindowTitle("BfV2 - " + current.title + " | Restarts: " + restartCount + " | Iterations: " + info.Iterations + " | Iterations/second: " + Text::FormatFloat(iterPerSec, "", 0, 2));
        }else{
            SetConsoleWindowTitle("BfV2 - " + current.title + " | Restarts: " + restartCount + " | Iterations: " + info.Iterations);
        }
    }
    // Mid-BF hot-swap: detect target change
    bool settingsChanged = false;
    string liveTargetId = GetVariableString("bf_target");
    if (liveTargetId != current.identifier)
    {
        @current = @GetBruteforceTarget();
        if (current is null)
        {
            SetVariable("bf_target", evaluations[0].identifier);
            @current = @evaluations[0];
        }
        currentTarget = current.title;
        if (current.onSimBegin !is null)
            current.onSimBegin(simManager);
        DashboardLog("Target switched to: " + currentTarget);
        settingsChanged = true;
    }
    // Re-read input mod settings every second (covers Apply changes)
    if (now - lastWindowTitleUpdateTime < 50)
    {
        int savedCount = int(GetVariableDouble("bf_input_mod_count"));
        if (savedCount < 1) savedCount = 1;
        while (int(g_inputModSettings.Length) < savedCount)
        {
            InputModificationSettings @s = InputModificationSettings();
            g_inputModSettings.Add(s);
        }
        while (int(g_inputModSettings.Length) > savedCount)
        {
            g_inputModSettings.RemoveAt(g_inputModSettings.Length - 1);
            settingsChanged = true;
        }
        for (uint im = 0; im < g_inputModSettings.Length; im++)
        {
            string varSuffix = GetInputModVarSuffix(im);
            InputModificationSettings @s = g_inputModSettings[im];
            int newInputCount = int(GetVariableDouble("bf_modify_count" + varSuffix));
            int newMinTime = int(GetVariableDouble("bf_inputs_min_time" + varSuffix));
            int newMaxTime = ResolveMaxTime(int(GetVariableDouble("bf_inputs_max_time" + varSuffix)), int(simManager.EventsDuration));
            int newMaxSteerDiff = int(GetVariableDouble("bf_max_steer_diff" + varSuffix));
            int newMaxTimeDiff = int(GetVariableDouble("bf_max_time_diff" + varSuffix));
            bool newFill = GetVariableBool("bf_inputs_fill_steer" + varSuffix);
            bool newEnabled = (im == 0) || GetVariableBool("bf_input_mod_enabled" + varSuffix);
            int newAlgoIdx = GetInputModAlgorithmIndex(GetVariableString("bf_input_mod_algorithm" + varSuffix));
            if (s.inputCount != newInputCount || s.minInputsTime != newMinTime || s.maxInputsTime != newMaxTime
                || s.maxSteerDiff != newMaxSteerDiff || s.maxTimeDiff != newMaxTimeDiff
                || s.fillSteerInputs != newFill || s.enabled != newEnabled || s.algorithmIndex != newAlgoIdx)
                settingsChanged = true;
            s.inputCount = newInputCount;
            s.minInputsTime = newMinTime;
            s.maxInputsTime = newMaxTime;
            s.maxSteerDiff = newMaxSteerDiff;
            s.maxTimeDiff = newMaxTimeDiff;
            s.fillSteerInputs = newFill;
            s.enabled = newEnabled;
            s.algorithmIndex = newAlgoIdx;
        }
        if (g_inputModSettings.Length > 0)
        {
            inputCount = g_inputModSettings[0].inputCount;
            minInputsTime = g_inputModSettings[0].minInputsTime;
            maxInputsTime = g_inputModSettings[0].maxInputsTime;
            maxSteerDiff = g_inputModSettings[0].maxSteerDiff;
            maxTimeDiff = g_inputModSettings[0].maxTimeDiff;
            fillSteerInputs = g_inputModSettings[0].fillSteerInputs;
        }
        leastMinInputsTime = 1000000000;
        for (uint lm = 0; lm < g_inputModSettings.Length; lm++)
        {
            if (g_inputModSettings[lm].enabled && g_inputModSettings[lm].minInputsTime < leastMinInputsTime)
                leastMinInputsTime = g_inputModSettings[lm].minInputsTime;
        }
    }
    if (settingsChanged)
    {
        RestoreBestInputs(simManager);
        simStateCache.Clear();
        simStateTimes.Clear();
        simManager.RewindToState(rewindState);
        info.Phase = BFPhase::Initial;
        info.Rewinded = false;
        currentPhase = "Initial";
        return;
    }
    int raceTime = simManager.RaceTime;
    if (current.type == CallbackType::FullControl)
    {
        BFEvaluationResponse @response = current.callback(simManager, info);
    }
    if (current.type == CallbackType::Legacy)
    {
        if (info.Phase == BFPhase::Initial)
        {
            lastImprovementTime = Time::Now;
        }
        BFEvaluationResponse @response = current.callback(simManager, info);
        if (PreciseFinish::IsEstimating)
            return;
        if (simManager.TickTime > simManager.RaceTime + 10 && !info.Rewinded && response.Decision != BFEvaluationDecision::Accept)
        {
            RestoreBestInputs(simManager);
            MutateAllInputs(simManager.InputEvents);
            simManager.RewindToState(FindNearestCachedState(InputModification::g_earliestMutationTime));
            info.Rewinded = true;
            info.Phase = BFPhase::Search;
            info.Iterations++;
            currentIterations = info.Iterations;
            currentPhase = "Search";
            ResultFileStartContent = response.ResultFileStartContent == "" ? ResultFileStartContent : response.ResultFileStartContent;
            return;
        }
        info.Rewinded = false;
        if (info.Phase == BFPhase::Initial)
        {
            if (raceTime >= leastMinInputsTime - 10)
            {
                if (!rewindStateAssigned)
                {
                    rewindState = simManager.SaveState();
                    rewindStateAssigned = true;
                }
                simStateTimes.Add(raceTime);
                simStateCache.Add(simManager.SaveState());
            }
            if (response.Decision == BFEvaluationDecision::Stop)
            {
                forceStop = true;
            }
            else
            {
                if (raceTime > int(simManager.EventsDuration) + 50 || response.Decision == BFEvaluationDecision::Accept)
                {
                    RestoreBestInputs(simManager);
                    MutateAllInputs(simManager.InputEvents);
                    simManager.RewindToState(FindNearestCachedState(InputModification::g_earliestMutationTime));
                    info.Rewinded = true;
                    info.Phase = BFPhase::Search;
                    info.Iterations++;
                    currentIterations = info.Iterations;
                    currentPhase = "Search";
                    ResultFileStartContent = response.ResultFileStartContent == "" ? ResultFileStartContent : response.ResultFileStartContent;
                }
            }
        }
        else
        {
            if (response.Decision == BFEvaluationDecision::DoNothing)
            {
                if (raceTime > int(simManager.EventsDuration))
                {
                    RestoreBestInputs(simManager);
                    MutateAllInputs(simManager.InputEvents);
                    simManager.RewindToState(FindNearestCachedState(InputModification::g_earliestMutationTime));
                    info.Rewinded = true;
                    info.Iterations++;
                    currentIterations = info.Iterations;
                }
            }
            else if (response.Decision == BFEvaluationDecision::Accept)
            {
                SaveBestInputs(simManager, false);
                CommandList list;
                RestoreBestInputs(simManager, false);
                list.Content = simManager.InputEvents.ToCommandsText();
                list.Save(GetVariableString("bf_result_filename")) ? void : print("Failed to save improved inputs.");
                for (uint im = 0; im < g_inputModSettings.Length; im++)
                {
                    InputModificationSettings @settings = g_inputModSettings[im];
                    if (raceTime < settings.maxInputsTime)
                    {
                        settings.maxInputsTime = raceTime;
                    }
                }
                if (g_inputModSettings.Length > 0)
                    maxInputsTime = g_inputModSettings[0].maxInputsTime;
                simStateCache.Clear();
                simStateTimes.Clear();
                simManager.RewindToState(rewindState);
                RestoreBestInputs(simManager, false);
                info.Rewinded = true;
                info.Iterations++;
                currentIterations = info.Iterations;
                info.Phase = BFPhase::Initial;
                currentPhase = "Initial";
                ResultFileStartContent = response.ResultFileStartContent == "" ? ResultFileStartContent : response.ResultFileStartContent;
                DashboardImprovement(currentTarget, ResultFileStartContent);
                DashboardLog("Improvement found at iteration " + Text::FormatUInt(info.Iterations));
            }
            else if (response.Decision == BFEvaluationDecision::Reject)
            {
                RestoreBestInputs(simManager);
                MutateAllInputs(simManager.InputEvents);
                simManager.RewindToState(FindNearestCachedState(InputModification::g_earliestMutationTime));
                info.Rewinded = true;
                info.Iterations++;
                currentIterations = info.Iterations;
                currentPhase = "Search";
            }
            else if (response.Decision == BFEvaluationDecision::Stop)
            {
                forceStop = true;
            }
        }
    }
}
void OnSimulationEnd(SimulationManager @simManager, SimulationResult result)
{
    if (!IsBfV2Active)
        return;
    array<uint> sortedIndices(restartInfos.Length);
    for (uint i = 0; i < restartInfos.Length; i++)
        sortedIndices[i] = i;
    for (uint i = 0; i < sortedIndices.Length; i++)
    {
        for (uint j = i + 1; j < sortedIndices.Length; j++)
        {
            if (restartInfos[sortedIndices[j]] < restartInfos[sortedIndices[i]])
            {
                uint temp = sortedIndices[i];
                sortedIndices[i] = sortedIndices[j];
                sortedIndices[j] = temp;
            }
        }
    }
    for (uint i = 0; i < sortedIndices.Length; i++)
    {
        uint idx = sortedIndices[i];
        print("- Restart N " + (idx + 1) + ": \"" + restartInfos[idx] + "\"");
    }
    if (current.onSimEnd !is null)
        current.onSimEnd(simManager, result);
    running = false;
    bfRunning = false;
    currentPhase = "Idle";
    DashboardLog("BF ended");
}
string Replace(const string &in text, const string &in charFrom, const string &in charTo)
{
    if (charFrom.IsEmpty() || charFrom == charTo)
        return text;
    const uint lenText = text.Length;
    const uint lenFrom = charFrom.Length;
    const uint lenTo = charTo.Length;
    uint count = 0;
    uint searchStart = 0;
    int pos = text.FindFirst(charFrom, searchStart);
    while (pos != -1)
    {
        count++;
        uint uPos = uint(pos);
        searchStart = uPos + lenFrom;
        if (searchStart >= lenText)
            break;
        pos = text.FindFirst(charFrom, searchStart);
    }
    if (count == 0)
        return text;
    int64 diff = int64(lenTo) - int64(lenFrom);
    int64 newLen64 = int64(lenText) + diff * int64(count);
    if (newLen64 < 0)
        newLen64 = 0;
    uint newLen = uint(newLen64);
    string result;
    result.Resize(newLen);
    uint src = 0;
    uint dst = 0;
    while (true)
    {
        int found = text.FindFirst(charFrom, src);
        if (found == -1)
        {
            while (src < lenText)
            {
                result[dst] = text[src];
                dst++;
                src++;
            }
            break;
        }
        uint uFound = uint(found);
        while (src < uFound)
        {
            result[dst] = text[src];
            dst++;
            src++;
        }
        for (uint i = 0; i < lenTo; i++)
        {
            result[dst] = charTo[i];
            dst++;
        }
        src += lenFrom;
        if (src >= lenText)
            break;
    }
    return result;
}
void OnCheckpointCountChanged(SimulationManager @simManager, int curr, int target)
{
    if(GetCurrentGameState() == TM::GameState::LocalRace)
        return;
    if (!(GetVariableString("controller") == "bfv2"))
        return;
    if (running)
        simManager.PreventSimulationFinish();
    if (current.onCheckpointCountChanged !is null)
        current.onCheckpointCountChanged(simManager, curr, target);
}
void OnRunStep(SimulationManager@ simManager){
    if(current !is null && current.onRunStep !is null)
        current.onRunStep(simManager);
}
