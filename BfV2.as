void coption(string name, string currentId, string identifier)
{
    if (UI::Selectable(name, currentId == identifier))
    {
        SetVariable("bf_target", identifier);
    }
}
void toolTip(int width, array<string> args)
{
    if (UI::IsItemHovered())
    {
        UI::SetNextWindowSize(vec2(width, -1));
        UI::BeginTooltip();
        for (uint i = 0; i < args.Length; i++)
        {
            UI::TextDimmed(args[i]);
        }
        UI::EndTooltip();
    }
}
string ReplaceI(const string&in str, int i){
    return str.Substr(0, str.FindFirst("{i}")) + i + str.Substr(str.FindFirst("{i}") + 3);
}
void SaveReplay(string name){
    CommandList saveReplayCmd;
    saveReplayCmd.Content="save_replay " + name;
    saveReplayCmd.Process(CommandListProcessOption::ExecuteImmediately);
}
int ResolveMaxTime(int maxTime, int eventsDuration)
{
    return maxTime == 0 ? eventsDuration : maxTime;
}
array<BruteforceEvaluation @> evaluations;
BruteforceEvaluation @current;
BFEvaluationInfo info = BFEvaluationInfo();
float minSpeed = 0.0f;
int minCps = 0;
Trigger3D conditionTrigger;
bool hasConditionTrigger = false;
Trigger3D targetTrigger;
int restartIterations = 0;
string resultFolder = "";
int restartCount = 0;
uint64 lastImprovementTime = 0;
uint64 lastRestartTime = 0;
uint64 lastWindowTitleUpdateTime = 0;
Scripting::ConditionCallback @standardCondition;
Scripting::ConditionCallback @restartCondition;
string linesRestartCondition = "#DUJ12E3F 4G5H6I7J8K9L0M";
string linesStandardCondition = "416782R3021C7B 1467 1";
void BruteforceV2Settings()
{
    UI::Dummy(vec2(0, 15));
    UI::PushStyleColor(UI::Col::Header, vec4(1, 0, 0, 0.3));
    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(1, 0, 0, 0.4));
    UI::PushStyleColor(UI::Col::HeaderActive, vec4(1, 0, 0, 0.5));
    UI::PushStyleColor(UI::Col::Button, vec4(1, 0, 0, 0.3));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(1, 0, 0, 0.4));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(1, 0, 0, 0.5));
    UI::PushStyleColor(UI::Col::PopupBg, vec4(0, 0, 0, 0.8));
    UI::PushStyleColor(UI::Col::Border, vec4(1, 0, 0.2, 1));
    if (UI::CollapsingHeader("Behavior"))
    {
        UI::Dummy(vec2(0, 2));
        UI::PushItemWidth(300);
        UI::InputTextVar("Filename used for saving results", "bf_result_filename");
        toolTip(300, {"Use {i} in the filename if you enabled the auto restart. It will be replaced by the restart number when saving inputs. If not present, the filename will be prefixed with 'passX_' where X is the number of restarts done so far. Example:",
                      "'best_run_{i}.txt' will produce files like 'best_run_1.txt', 'best_run_2.txt', etc. for every restart."});
        UI::Dummy(vec2(0, 2));
        UI::InputIntVar("Iterations before restart", "bf_iterations_before_restart", 0);
        toolTip(300, {"After this many iterations, the bruteforce process will restart from the beginning, with the base run's inputs. This can help escape local minima. Set to 0 to disable restarts."});
        UI::Dummy(vec2(0, 2));
        UI::InputTextVar("Result files folder", "bf_result_folder");
        toolTip(300, {"Folder where the result files will be saved. Leave empty to use the root folder. Example:",
                      "'results' will save files in " + GetVariableString("scripts_folder") + "\\results\\"});
        UI::Dummy(vec2(0, 2));
        string lines = Replace(GetVariableString("bf_restart_condition_script"), ":", "\n");
        int currentHeight = int(GetVariableDouble("bf_restart_condition_script_height"));
        string t;
        UI::PushItemWidth(245);
        if (UI::InputTextMultiline("##bf_restart_condition_script", lines, vec2(0, currentHeight)))
        {
            SetVariable("bf_restart_condition_script", Replace(lines, "\n", ":"));
        }
        UI::SameLine();
        if (UI::Button("^"))
        {
            if (currentHeight < 42)
                currentHeight = 42;
            SetVariable("bf_restart_condition_script_height", currentHeight - 17);
        }
        UI::SameLine();
        if (UI::Button("v"))
        {
            SetVariable("bf_restart_condition_script_height", currentHeight + 17);
        }
        UI::SameLine();
        UI::Text("Condition script for restart");
        UI::PopItemWidth();
        if (lines != linesRestartCondition)
        {
            linesRestartCondition = lines;
            Scripting::ConditionCallback @callback = Scripting::CompileMulti(lines.Split("\n"));
            @restartCondition = @callback;
        }
        if (restartCondition is null)
        {
            bool isEmpty = true;
            array<string> parts = lines.Split("\n");
            for (uint i = 0; i < parts.Length; i++)
            {
                if (Scripting::CleanSource(parts[i]) != "")
                {
                    isEmpty = false;
                    break;
                }
            }
            if (!isEmpty)
            {
                UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::PopStyleColor();
            }
            else
            {
                UI::TextDimmed("No restart condition set.");
            }
        }
        else
        {
            UI::TextDimmed("Script compiled successfully.");
        }
    }
    if (UI::CollapsingHeader("Optimization"))
    {
        UI::Dummy(vec2(0, 2));
        @current = @GetBruteforceTarget();
        if (current is null)
        {
            SetVariable("bf_target", evaluations[0].identifier);
            @current = @evaluations[0];
        }
        if (UI::BeginCombo("Optimization Target", current.title))
        {
            for (uint i = 0; i < evaluations.Length; i++)
            {
                BruteforceEvaluation @eval = evaluations[i];
                coption(eval.title, current.identifier, eval.identifier);
            }
            UI::EndCombo();
        }
        if (current.renderCallback !is null)
            current.renderCallback();
        UI::Dummy(vec2(0, 2));
    }
    if (UI::CollapsingHeader("Conditions"))
    {
        UI::PushItemWidth(160);
        UI::Dummy(vec2(0, 2));
        if (GetVariableDouble("bf_condition_speed") > 0.0f)
        {
            UI::Text("Min. speed ");
        }
        else
        {
            UI::BeginDisabled();
            UI::Text("Min. speed ");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(18, 0));
        UI::SameLine();
        UI::InputFloatVar("##bf_condition_speed", "bf_condition_speed");
        if (GetVariableDouble("bf_condition_speed") < 0.0f)
        {
            SetVariable("bf_condition_speed", 0.0f);
        }
        if (GetVariableDouble("bf_condition_cps") > 0.0f)
        {
            UI::Text("Min. cps");
        }
        else
        {
            UI::BeginDisabled();
            UI::Text("Min. cps");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(39, 0));
        UI::SameLine();
        UI::InputIntVar("##bf_condition_cps", "bf_condition_cps");
        if (GetVariableDouble("bf_condition_cps") < 0.0f)
        {
            SetVariable("bf_condition_cps", 0.0f);
        }
        UI::Dummy(vec2(0, 2));
        if (int(GetVariableDouble("bf_condition_trigger")) > 0)
        {
            UI::Text("Trigger");
        }
        else
        {
            UI::BeginDisabled();
            UI::Text("Trigger");
            UI::EndDisabled();
        }
        UI::SameLine();
        UI::Dummy(vec2(48, 0));
        UI::SameLine();
        uint triggerIndex = uint(GetVariableDouble("bf_condition_trigger"));
        array<int> @triggerIds = GetTriggerIds();
        if (triggerIndex > triggerIds.Length)
            triggerIndex = 0;
        string currentName = "None";
        if (triggerIndex > 0)
        {
            Trigger3D selectedTrigger = GetTrigger(triggerIds[triggerIndex - 1]);
            vec3 pos = selectedTrigger.Position;
            currentName = triggerIndex + ". Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")";
        }
        if (UI::BeginCombo("##bf_condition_trigger", currentName))
        {
            if (UI::Selectable("None", triggerIndex == 0))
            {
                SetVariable("bf_condition_trigger", 0);
            }
            for (uint i = 0; i < triggerIds.Length; i++)
            {
                Trigger3D trigger = GetTrigger(triggerIds[i]);
                vec3 pos = trigger.Position;
                string triggerName = (i + 1) + ". Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")";
                if (UI::Selectable(triggerName, triggerIndex == i + 1))
                {
                    SetVariable("bf_condition_trigger", i + 1);
                }
            }
            UI::EndCombo();
        }
        string lines = Replace(GetVariableString("bf_condition_script"), ":", "\n");
        int currentHeight = int(GetVariableDouble("bf_condition_script_height"));
        string t;
        UI::PushItemWidth(245);
        if (UI::InputTextMultiline("##bf_condition_script", lines, vec2(0, currentHeight)))
        {
            SetVariable("bf_condition_script", Replace(lines, "\n", ":"));
        }
        UI::SameLine();
        if (UI::Button("^##condition_script_up"))
        {
            if (currentHeight < 42)
                currentHeight = 42;
            SetVariable("bf_condition_script_height", currentHeight - 17);
        }
        UI::SameLine();
        if (UI::Button("v##condition_script_down"))
        {
            SetVariable("bf_condition_script_height", currentHeight + 17);
        }
        UI::SameLine();
        UI::Text("Condition script");
        UI::PopItemWidth();
        if (lines != linesStandardCondition)
        {
            linesStandardCondition = lines;
            Scripting::ConditionCallback @callback = Scripting::CompileMulti(lines.Split("\n"));
            @standardCondition = @callback;
        }
        if (standardCondition is null)
        {
            bool isEmpty = true;
            array<string> parts = lines.Split("\n");
            for (uint i = 0; i < parts.Length; i++)
            {
                if (Scripting::CleanSource(parts[i]) != "")
                {
                    isEmpty = false;
                    break;
                }
            }
            if (!isEmpty)
            {
                UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::Text("Script has errors! Script has errors!");
                UI::PopStyleColor();
            }
            else
            {
                UI::TextDimmed("No conditions set.");
            }
        }
        else
        {
            UI::TextDimmed("Script compiled successfully.");
        }
        UI::Dummy(vec2(0, 2));
    }
    UI::Dummy(vec2(0, 3));
    UI::Separator();
    UI::Dummy(vec2(0, 3));
    InitializeInputModAlgorithms();
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
        if (im > 0)
        {
            RegisterVariable("bf_modify_count" + varSuffix, 0);
            RegisterVariable("bf_inputs_min_time" + varSuffix, 0);
            RegisterVariable("bf_inputs_max_time" + varSuffix, 0);
            RegisterVariable("bf_max_steer_diff" + varSuffix, 0);
            RegisterVariable("bf_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_inputs_fill_steer" + varSuffix, false);
            RegisterVariable("bf_input_mod_enabled" + varSuffix, true);
            RegisterVariable("bf_input_mod_algorithm" + varSuffix, "basic");
            RegisterVariable("bf_range_min_input_count" + varSuffix, 1);
            RegisterVariable("bf_range_max_input_count" + varSuffix, 1);
            RegisterVariable("bf_range_min_steer" + varSuffix, -65536);
            RegisterVariable("bf_range_max_steer" + varSuffix, 65536);
            RegisterVariable("bf_range_min_time_diff" + varSuffix, 0);
            RegisterVariable("bf_range_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_range_fill_steer" + varSuffix, false);
            RegisterVariable("bf_adv_steer_modify_count" + varSuffix, 0);
            RegisterVariable("bf_adv_steer_min_time" + varSuffix, 0);
            RegisterVariable("bf_adv_steer_max_time" + varSuffix, 0);
            RegisterVariable("bf_adv_steer_max_diff" + varSuffix, 0);
            RegisterVariable("bf_adv_steer_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_adv_steer_fill" + varSuffix, false);
            RegisterVariable("bf_adv_accel_modify_count" + varSuffix, 0);
            RegisterVariable("bf_adv_accel_min_time" + varSuffix, 0);
            RegisterVariable("bf_adv_accel_max_time" + varSuffix, 0);
            RegisterVariable("bf_adv_accel_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_adv_brake_modify_count" + varSuffix, 0);
            RegisterVariable("bf_adv_brake_min_time" + varSuffix, 0);
            RegisterVariable("bf_adv_brake_max_time" + varSuffix, 0);
            RegisterVariable("bf_adv_brake_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_advr_steer_min_input_count" + varSuffix, 1);
            RegisterVariable("bf_advr_steer_max_input_count" + varSuffix, 1);
            RegisterVariable("bf_advr_steer_min_time" + varSuffix, 0);
            RegisterVariable("bf_advr_steer_max_time" + varSuffix, 0);
            RegisterVariable("bf_advr_steer_min_steer" + varSuffix, -65536);
            RegisterVariable("bf_advr_steer_max_steer" + varSuffix, 65536);
            RegisterVariable("bf_advr_steer_min_time_diff" + varSuffix, 0);
            RegisterVariable("bf_advr_steer_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_advr_steer_fill" + varSuffix, false);
            RegisterVariable("bf_advr_accel_min_input_count" + varSuffix, 1);
            RegisterVariable("bf_advr_accel_max_input_count" + varSuffix, 1);
            RegisterVariable("bf_advr_accel_min_time" + varSuffix, 0);
            RegisterVariable("bf_advr_accel_max_time" + varSuffix, 0);
            RegisterVariable("bf_advr_accel_min_time_diff" + varSuffix, 0);
            RegisterVariable("bf_advr_accel_max_time_diff" + varSuffix, 0);
            RegisterVariable("bf_advr_brake_min_input_count" + varSuffix, 1);
            RegisterVariable("bf_advr_brake_max_input_count" + varSuffix, 1);
            RegisterVariable("bf_advr_brake_min_time" + varSuffix, 0);
            RegisterVariable("bf_advr_brake_max_time" + varSuffix, 0);
            RegisterVariable("bf_advr_brake_min_time_diff" + varSuffix, 0);
            RegisterVariable("bf_advr_brake_max_time_diff" + varSuffix, 0);
        }
    }
    for (uint im = 0; im < g_inputModSettings.Length; im++)
    {
        string varSuffix = GetInputModVarSuffix(im);
        string savedAlgoId = GetVariableString("bf_input_mod_algorithm" + varSuffix);
        if (savedAlgoId == "") savedAlgoId = "basic";
        g_inputModSettings[im].algorithmIndex = GetInputModAlgorithmIndex(savedAlgoId);
    }
    for (uint im = 0; im < g_inputModSettings.Length; im++)
    {
        string suffix = "##inputmod" + im;
        string varSuffix = GetInputModVarSuffix(im);
        if (im == 0)
        {
            if (UI::Button("+" + suffix, vec2(0, 0)))
            {
                AddInputModificationSettings();
            }
        }
        else
        {
            if (UI::Button("-" + suffix, vec2(0, 0)))
            {
                RemoveInputModificationSettings(im);
                break; 
            }
        }
        UI::SameLine();
        UI::Dummy(vec2(-13, 0));
        UI::SameLine();
        if (UI::CollapsingHeader("Input Modification #" + (im + 1) + suffix))
        {
            UI::PushItemWidth(300);
            UI::Dummy(vec2(0, 2));
            if (im > 0)
            {
                UI::CheckboxVar("Enabled" + suffix, "bf_input_mod_enabled" + varSuffix);
                UI::Dummy(vec2(0, 2));
            }
            InputModificationSettings @settings = g_inputModSettings[im];
            InputModificationAlgorithm @currentAlgo = settings.GetAlgorithm();
            string currentAlgoName = (currentAlgo !is null) ? currentAlgo.name : "Unknown";
            if (UI::BeginCombo("Algorithm" + suffix, currentAlgoName))
            {
                for (uint algoIdx = 0; algoIdx < g_inputModAlgorithms.Length; algoIdx++)
                {
                    InputModificationAlgorithm @algo = g_inputModAlgorithms[algoIdx];
                    bool isSelected = (settings.algorithmIndex == int(algoIdx));
                    if (UI::Selectable(algo.name, isSelected))
                    {
                        settings.algorithmIndex = int(algoIdx);
                        SetVariable("bf_input_mod_algorithm" + varSuffix, algo.identifier);
                    }
                }
                UI::EndCombo();
            }
            toolTip(300, {"Select the input modification algorithm to use for this settings block."});
            UI::Dummy(vec2(0, 2));
            if (currentAlgo !is null && currentAlgo.renderUICallback !is null)
            {
                currentAlgo.renderUICallback(settings, im, suffix, varSuffix);
            }
        }
    }
    UI::PopStyleColor(8);
}
BruteforceEvaluation @GetBruteforceTarget()
{
    string current = GetVariableString("bf_target");
    for (uint i = 0; i < evaluations.Length; i++)
    {
        BruteforceEvaluation @eval = evaluations[i];
        if (eval.identifier == current)
        {
            return eval;
        }
    }
    return null;
}
BruteforceEvaluation @RegisterBruteforceEval(const string &in identifier, const string &in title, OnBruteforceEvaluate @callback, RenderBruteforceEvaluationSettings @renderCallback = null)
{
    BruteforceEvaluation eval;
    eval.identifier = identifier;
    eval.title = title;
    @eval.callback = callback;
    @eval.renderCallback = renderCallback;
    evaluations.Add(eval);
    return eval;
}
funcdef void OnSimulationBeginCallback(SimulationManager @simManager);
funcdef void OnSimulationEndCallback(SimulationManager @simManager, SimulationResult result);
funcdef void OnCheckpointCountChangedCallback(SimulationManager @simManager, int current, int target);
funcdef void OnRunStepCallback(SimulationManager @simManager);
funcdef void OnRenderCallback();
enum CallbackType
{
    Legacy,
    FullControl,
}
class BruteforceEvaluation
{
    string identifier;
    string title;
    OnBruteforceEvaluate @callback;
    RenderBruteforceEvaluationSettings @renderCallback;
    CallbackType type = CallbackType::Legacy;
    OnSimulationBeginCallback @onSimBegin = null;
    OnSimulationEndCallback @onSimEnd = null;
    OnCheckpointCountChangedCallback @onCheckpointCountChanged = null;
    OnRunStepCallback @onRunStep = null;
    OnRenderCallback @onRender = null;
}
;
funcdef void InputModAlgorithmCallback(TM::InputEventBuffer @buffer, InputModificationSettings @settings, uint settingsIndex);
funcdef void InputModAlgorithmUICallback(InputModificationSettings @settings, uint settingsIndex, const string &in suffix, const string &in varSuffix);
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
namespace CarLocationBf {
    uint64 g_lastTriggerUpdateTime = 0;
    array<int> g_ellipsoidVisualTriggerIds;
    string id = "clbf";
    array<array<vec3>> voxels;
    array<string> data = {"# X Y Z\n-1.20000000 0.30000000 -1.50000000\n-1.20000000 0.30000000 -1.20000000\n-1.20000000 0.60000000 -1.20000000\n-0.90000000 0.00000000 -1.50000000\n-0.90000000 0.00000000 -1.20000000\n-0.90000000 0.00000000 -0.90000000\n-0.90000000 0.00000000 1.50000000\n-0.90000000 0.00000000 1.80000000\n-0.90000000 0.00000000 2.10000000\n-0.90000000 0.30000000 -1.50000000\n-0.90000000 0.30000000 -0.90000000\n-0.90000000 0.30000000 -0.60000000\n-0.90000000 0.30000000 -0.30000000\n-0.90000000 0.30000000 0.00000000\n-0.90000000 0.30000000 0.30000000\n-0.90000000 0.30000000 0.60000000\n-0.90000000 0.30000000 0.90000000\n-0.90000000 0.30000000 1.50000000\n-0.90000000 0.30000000 1.80000000\n-0.90000000 0.30000000 2.10000000\n-0.90000000 0.60000000 -1.50000000\n-0.90000000 0.60000000 -0.90000000\n-0.90000000 0.60000000 -0.60000000\n-0.90000000 0.60000000 -0.30000000\n-0.90000000 0.60000000 0.00000000\n-0.90000000 0.60000000 0.30000000\n-0.90000000 0.60000000 0.60000000\n-0.90000000 0.60000000 0.90000000\n-0.90000000 0.60000000 1.50000000\n-0.90000000 0.60000000 1.80000000\n-0.90000000 0.60000000 2.10000000\n-0.90000000 0.90000000 -1.50000000\n-0.90000000 0.90000000 -1.20000000\n-0.90000000 0.90000000 -0.90000000\n-0.90000000 0.90000000 -0.60000000\n-0.90000000 0.90000000 -0.30000000\n-0.60000000 0.00000000 -1.20000000\n-0.60000000 0.00000000 -0.60000000\n-0.60000000 0.00000000 -0.30000000\n-0.60000000 0.00000000 0.00000000\n-0.60000000 0.00000000 0.30000000\n-0.60000000 0.00000000 0.60000000\n-0.60000000 0.00000000 1.50000000\n-0.60000000 0.00000000 1.80000000\n-0.60000000 0.30000000 -1.80000000\n-0.60000000 0.30000000 -1.50000000\n-0.60000000 0.30000000 -0.90000000\n-0.60000000 0.30000000 0.90000000\n-0.60000000 0.30000000 1.20000000\n-0.60000000 0.30000000 2.10000000\n-0.60000000 0.60000000 -1.80000000\n-0.60000000 0.60000000 0.30000000\n-0.60000000 0.60000000 0.60000000\n-0.60000000 0.60000000 0.90000000\n-0.60000000 0.60000000 1.20000000\n-0.60000000 0.60000000 1.50000000\n-0.60000000 0.60000000 1.80000000\n-0.60000000 0.60000000 2.10000000\n-0.60000000 0.90000000 -1.80000000\n-0.60000000 0.90000000 -0.30000000\n-0.60000000 0.90000000 0.00000000\n-0.60000000 1.20000000 -1.50000000\n-0.60000000 1.20000000 -1.20000000\n-0.60000000 1.20000000 -0.90000000\n-0.60000000 1.20000000 -0.60000000\n-0.30000000 0.00000000 -0.90000000\n-0.30000000 0.00000000 -0.60000000\n-0.30000000 0.00000000 -0.30000000\n-0.30000000 0.00000000 0.00000000\n-0.30000000 0.00000000 0.30000000\n-0.30000000 0.00000000 0.60000000\n-0.30000000 0.00000000 0.90000000\n-0.30000000 0.00000000 1.20000000\n-0.30000000 0.00000000 1.50000000\n-0.30000000 0.00000000 1.80000000\n-0.30000000 0.00000000 2.10000000\n-0.30000000 0.30000000 -1.80000000\n-0.30000000 0.30000000 -1.50000000\n-0.30000000 0.30000000 -1.20000000\n-0.30000000 0.30000000 2.10000000\n-0.30000000 0.60000000 -1.80000000\n-0.30000000 0.60000000 1.20000000\n-0.30000000 0.60000000 1.50000000\n-0.30000000 0.60000000 1.80000000\n-0.30000000 0.60000000 2.10000000\n-0.30000000 0.90000000 -1.80000000\n-0.30000000 0.90000000 0.00000000\n-0.30000000 0.90000000 0.30000000\n-0.30000000 0.90000000 0.60000000\n-0.30000000 0.90000000 0.90000000\n-0.30000000 1.20000000 -1.50000000\n-0.30000000 1.20000000 -1.20000000\n-0.30000000 1.20000000 -0.90000000\n-0.30000000 1.20000000 -0.60000000\n-0.30000000 1.20000000 -0.30000000\n0.00000000 0.00000000 -0.90000000\n0.00000000 0.00000000 -0.60000000\n0.00000000 0.00000000 -0.30000000\n0.00000000 0.00000000 0.00000000\n0.00000000 0.00000000 0.30000000\n0.00000000 0.00000000 0.60000000\n0.00000000 0.00000000 0.90000000\n0.00000000 0.00000000 1.20000000\n0.00000000 0.00000000 1.50000000\n0.00000000 0.00000000 1.80000000\n0.00000000 0.00000000 2.10000000\n0.00000000 0.30000000 -1.80000000\n0.00000000 0.30000000 -1.50000000\n0.00000000 0.30000000 -1.20000000\n0.00000000 0.30000000 2.10000000\n0.00000000 0.60000000 -1.80000000\n0.00000000 0.60000000 1.20000000\n0.00000000 0.60000000 1.50000000\n0.00000000 0.60000000 1.80000000\n0.00000000 0.60000000 2.10000000\n0.00000000 0.90000000 -1.80000000\n0.00000000 0.90000000 0.00000000\n0.00000000 0.90000000 0.30000000\n0.00000000 0.90000000 0.60000000\n0.00000000 0.90000000 0.90000000\n0.00000000 1.20000000 -1.50000000\n0.00000000 1.20000000 -1.20000000\n0.00000000 1.20000000 -0.90000000\n0.00000000 1.20000000 -0.60000000\n0.00000000 1.20000000 -0.30000000\n0.30000000 0.00000000 -0.90000000\n0.30000000 0.00000000 -0.60000000\n0.30000000 0.00000000 -0.30000000\n0.30000000 0.00000000 0.00000000\n0.30000000 0.00000000 0.30000000\n0.30000000 0.00000000 0.60000000\n0.30000000 0.00000000 0.90000000\n0.30000000 0.00000000 1.20000000\n0.30000000 0.00000000 1.50000000\n0.30000000 0.00000000 1.80000000\n0.30000000 0.00000000 2.10000000\n0.30000000 0.30000000 -1.80000000\n0.30000000 0.30000000 -1.50000000\n0.30000000 0.30000000 -1.20000000\n0.30000000 0.30000000 2.10000000\n0.30000000 0.60000000 -1.80000000\n0.30000000 0.60000000 1.20000000\n0.30000000 0.60000000 1.50000000\n0.30000000 0.60000000 1.80000000\n0.30000000 0.60000000 2.10000000\n0.30000000 0.90000000 -1.80000000\n0.30000000 0.90000000 0.00000000\n0.30000000 0.90000000 0.30000000\n0.30000000 0.90000000 0.60000000\n0.30000000 0.90000000 0.90000000\n0.30000000 1.20000000 -1.50000000\n0.30000000 1.20000000 -1.20000000\n0.30000000 1.20000000 -0.90000000\n0.30000000 1.20000000 -0.60000000\n0.30000000 1.20000000 -0.30000000\n0.60000000 0.00000000 -1.20000000\n0.60000000 0.00000000 -0.60000000\n0.60000000 0.00000000 -0.30000000\n0.60000000 0.00000000 0.00000000\n0.60000000 0.00000000 0.30000000\n0.60000000 0.00000000 0.60000000\n0.60000000 0.00000000 1.50000000\n0.60000000 0.00000000 1.80000000\n0.60000000 0.30000000 -1.80000000\n0.60000000 0.30000000 -1.50000000\n0.60000000 0.30000000 -0.90000000\n0.60000000 0.30000000 0.90000000\n0.60000000 0.30000000 1.20000000\n0.60000000 0.30000000 2.10000000\n0.60000000 0.60000000 -1.80000000\n0.60000000 0.60000000 0.30000000\n0.60000000 0.60000000 0.60000000\n0.60000000 0.60000000 0.90000000\n0.60000000 0.60000000 1.20000000\n0.60000000 0.60000000 1.50000000\n0.60000000 0.60000000 1.80000000\n0.60000000 0.60000000 2.10000000\n0.60000000 0.90000000 -1.80000000\n0.60000000 0.90000000 -0.30000000\n0.60000000 0.90000000 0.00000000\n0.60000000 1.20000000 -1.50000000\n0.60000000 1.20000000 -1.20000000\n0.60000000 1.20000000 -0.90000000\n0.60000000 1.20000000 -0.60000000\n0.90000000 0.00000000 -1.50000000\n0.90000000 0.00000000 -1.20000000\n0.90000000 0.00000000 -0.90000000\n0.90000000 0.00000000 1.50000000\n0.90000000 0.00000000 1.80000000\n0.90000000 0.00000000 2.10000000\n0.90000000 0.30000000 -1.50000000\n0.90000000 0.30000000 -0.90000000\n0.90000000 0.30000000 -0.60000000\n0.90000000 0.30000000 -0.30000000\n0.90000000 0.30000000 0.00000000\n0.90000000 0.30000000 0.30000000\n0.90000000 0.30000000 0.60000000\n0.90000000 0.30000000 0.90000000\n0.90000000 0.30000000 1.50000000\n0.90000000 0.30000000 1.80000000\n0.90000000 0.30000000 2.10000000\n0.90000000 0.60000000 -1.50000000\n0.90000000 0.60000000 -0.90000000\n0.90000000 0.60000000 -0.60000000\n0.90000000 0.60000000 -0.30000000\n0.90000000 0.60000000 0.00000000\n0.90000000 0.60000000 0.30000000\n0.90000000 0.60000000 0.60000000\n0.90000000 0.60000000 0.90000000\n0.90000000 0.60000000 1.50000000\n0.90000000 0.60000000 1.80000000\n0.90000000 0.60000000 2.10000000\n0.90000000 0.90000000 -1.50000000\n0.90000000 0.90000000 -1.20000000\n0.90000000 0.90000000 -0.90000000\n0.90000000 0.90000000 -0.60000000\n0.90000000 0.90000000 -0.30000000\n1.20000000 0.30000000 -1.50000000\n1.20000000 0.30000000 -1.20000000\n1.20000000 0.60000000 -1.20000000",    "# X Y Z\n-1.00000000 0.00000000 -1.40000000\n-1.00000000 0.00000000 -1.20000000\n-1.00000000 0.00000000 -1.00000000\n-1.00000000 0.00000000 1.60000000\n-1.00000000 0.00000000 1.80000000\n-1.00000000 0.00000000 2.00000000\n-1.00000000 0.20000000 -1.60000000\n-1.00000000 0.20000000 -1.40000000\n-1.00000000 0.20000000 -1.20000000\n-1.00000000 0.20000000 -1.00000000\n-1.00000000 0.20000000 -0.80000000\n-1.00000000 0.20000000 1.40000000\n-1.00000000 0.20000000 1.60000000\n-1.00000000 0.20000000 1.80000000\n-1.00000000 0.20000000 2.00000000\n-1.00000000 0.20000000 2.20000000\n-1.00000000 0.40000000 -1.60000000\n-1.00000000 0.40000000 -1.40000000\n-1.00000000 0.40000000 -1.20000000\n-1.00000000 0.40000000 -1.00000000\n-1.00000000 0.40000000 -0.80000000\n-1.00000000 0.40000000 -0.60000000\n-1.00000000 0.40000000 -0.40000000\n-1.00000000 0.40000000 -0.20000000\n-1.00000000 0.40000000 0.00000000\n-1.00000000 0.40000000 0.20000000\n-1.00000000 0.40000000 0.40000000\n-1.00000000 0.40000000 1.40000000\n-1.00000000 0.40000000 1.60000000\n-1.00000000 0.40000000 1.80000000\n-1.00000000 0.40000000 2.00000000\n-1.00000000 0.40000000 2.20000000\n-1.00000000 0.60000000 -1.60000000\n-1.00000000 0.60000000 -1.40000000\n-1.00000000 0.60000000 -1.20000000\n-1.00000000 0.60000000 -1.00000000\n-1.00000000 0.60000000 -0.80000000\n-1.00000000 0.60000000 -0.60000000\n-1.00000000 0.60000000 -0.40000000\n-1.00000000 0.60000000 -0.20000000\n-1.00000000 0.60000000 0.00000000\n-1.00000000 0.60000000 0.20000000\n-1.00000000 0.60000000 1.40000000\n-1.00000000 0.60000000 1.60000000\n-1.00000000 0.60000000 1.80000000\n-1.00000000 0.60000000 2.00000000\n-1.00000000 0.80000000 -1.40000000\n-1.00000000 0.80000000 -1.20000000\n-1.00000000 0.80000000 -1.00000000\n-1.00000000 0.80000000 -0.80000000\n-1.00000000 0.80000000 -0.60000000\n-1.00000000 0.80000000 -0.40000000\n-1.00000000 0.80000000 1.80000000\n-0.80000000 0.00000000 -1.40000000\n-0.80000000 0.00000000 -1.20000000\n-0.80000000 0.00000000 -1.00000000\n-0.80000000 0.00000000 1.60000000\n-0.80000000 0.00000000 1.80000000\n-0.80000000 0.00000000 2.00000000\n-0.80000000 0.20000000 -1.60000000\n-0.80000000 0.20000000 -0.80000000\n-0.80000000 0.20000000 -0.60000000\n-0.80000000 0.20000000 -0.40000000\n-0.80000000 0.20000000 -0.20000000\n-0.80000000 0.20000000 0.00000000\n-0.80000000 0.20000000 0.20000000\n-0.80000000 0.20000000 0.40000000\n-0.80000000 0.20000000 0.60000000\n-0.80000000 0.20000000 0.80000000\n-0.80000000 0.20000000 1.40000000\n-0.80000000 0.20000000 2.20000000\n-0.80000000 0.40000000 -1.60000000\n-0.80000000 0.40000000 0.60000000\n-0.80000000 0.40000000 0.80000000\n-0.80000000 0.40000000 1.00000000\n-0.80000000 0.40000000 1.40000000\n-0.80000000 0.40000000 2.20000000\n-0.80000000 0.60000000 -1.60000000\n-0.80000000 0.60000000 0.00000000\n-0.80000000 0.60000000 0.20000000\n-0.80000000 0.60000000 0.40000000\n-0.80000000 0.60000000 0.60000000\n-0.80000000 0.60000000 0.80000000\n-0.80000000 0.60000000 1.40000000\n-0.80000000 0.60000000 1.60000000\n-0.80000000 0.60000000 2.00000000\n-0.80000000 0.80000000 -1.60000000\n-0.80000000 0.80000000 -0.20000000\n-0.80000000 0.80000000 1.80000000\n-0.80000000 1.00000000 -1.40000000\n-0.80000000 1.00000000 -1.20000000\n-0.80000000 1.00000000 -1.00000000\n-0.80000000 1.00000000 -0.80000000\n-0.80000000 1.00000000 -0.60000000\n-0.80000000 1.00000000 -0.40000000\n-0.60000000 0.20000000 -1.40000000\n-0.60000000 0.20000000 -1.20000000\n-0.60000000 0.20000000 -1.00000000\n-0.60000000 0.20000000 -0.80000000\n-0.60000000 0.20000000 -0.60000000\n-0.60000000 0.20000000 -0.40000000\n-0.60000000 0.20000000 -0.20000000\n-0.60000000 0.20000000 0.00000000\n-0.60000000 0.20000000 0.20000000\n-0.60000000 0.20000000 0.40000000\n-0.60000000 0.20000000 0.60000000\n-0.60000000 0.20000000 0.80000000\n-0.60000000 0.20000000 1.00000000\n-0.60000000 0.20000000 1.20000000\n-0.60000000 0.20000000 1.40000000\n-0.60000000 0.20000000 1.60000000\n-0.60000000 0.20000000 1.80000000\n-0.60000000 0.20000000 2.00000000\n-0.60000000 0.40000000 -1.60000000\n-0.60000000 0.40000000 1.20000000\n-0.60000000 0.40000000 1.40000000\n-0.60000000 0.40000000 2.00000000\n-0.60000000 0.60000000 -1.80000000\n-0.60000000 0.60000000 0.60000000\n-0.60000000 0.60000000 0.80000000\n-0.60000000 0.60000000 1.00000000\n-0.60000000 0.60000000 1.60000000\n-0.60000000 0.60000000 1.80000000\n-0.60000000 0.60000000 2.00000000\n-0.60000000 0.80000000 -1.80000000\n-0.60000000 0.80000000 0.00000000\n-0.60000000 0.80000000 0.20000000\n-0.60000000 0.80000000 0.40000000\n-0.60000000 1.00000000 -1.60000000\n-0.60000000 1.00000000 -1.40000000\n-0.60000000 1.00000000 -1.20000000\n-0.60000000 1.00000000 -1.00000000\n-0.60000000 1.00000000 -0.80000000\n-0.60000000 1.00000000 -0.60000000\n-0.60000000 1.00000000 -0.40000000\n-0.60000000 1.00000000 -0.20000000\n-0.40000000 0.00000000 0.00000000\n-0.40000000 0.00000000 0.20000000\n-0.40000000 0.00000000 1.80000000\n-0.40000000 0.20000000 -1.40000000\n-0.40000000 0.20000000 -1.20000000\n-0.40000000 0.20000000 -1.00000000\n-0.40000000 0.20000000 -0.80000000\n-0.40000000 0.20000000 -0.60000000\n-0.40000000 0.20000000 -0.40000000\n-0.40000000 0.20000000 -0.20000000\n-0.40000000 0.20000000 0.40000000\n-0.40000000 0.20000000 0.60000000\n-0.40000000 0.20000000 0.80000000\n-0.40000000 0.20000000 1.00000000\n-0.40000000 0.20000000 1.20000000\n-0.40000000 0.20000000 1.40000000\n-0.40000000 0.20000000 1.60000000\n-0.40000000 0.20000000 2.00000000\n-0.40000000 0.40000000 -1.80000000\n-0.40000000 0.40000000 -1.60000000\n-0.40000000 0.40000000 2.20000000\n-0.40000000 0.60000000 -1.80000000\n-0.40000000 0.60000000 0.80000000\n-0.40000000 0.60000000 1.00000000\n-0.40000000 0.60000000 1.20000000\n-0.40000000 0.60000000 1.40000000\n-0.40000000 0.60000000 1.60000000\n-0.40000000 0.60000000 1.80000000\n-0.40000000 0.60000000 2.00000000\n-0.40000000 0.80000000 -1.80000000\n-0.40000000 0.80000000 0.00000000\n-0.40000000 0.80000000 0.20000000\n-0.40000000 0.80000000 0.40000000\n-0.40000000 0.80000000 0.60000000\n-0.40000000 1.00000000 -1.80000000\n-0.40000000 1.00000000 -1.60000000\n-0.40000000 1.00000000 -0.40000000\n-0.40000000 1.00000000 -0.20000000\n-0.40000000 1.20000000 -1.40000000\n-0.40000000 1.20000000 -1.20000000\n-0.40000000 1.20000000 -1.00000000\n-0.40000000 1.20000000 -0.80000000\n-0.40000000 1.20000000 -0.60000000\n-0.20000000 0.00000000 -0.40000000\n-0.20000000 0.00000000 -0.20000000\n-0.20000000 0.00000000 0.00000000\n-0.20000000 0.00000000 0.20000000\n-0.20000000 0.00000000 0.40000000\n-0.20000000 0.00000000 0.60000000\n-0.20000000 0.00000000 1.60000000\n-0.20000000 0.00000000 1.80000000\n-0.20000000 0.20000000 -1.60000000\n-0.20000000 0.20000000 -1.40000000\n-0.20000000 0.20000000 -1.20000000\n-0.20000000 0.20000000 -1.00000000\n-0.20000000 0.20000000 -0.80000000\n-0.20000000 0.20000000 -0.60000000\n-0.20000000 0.20000000 0.80000000\n-0.20000000 0.20000000 1.00000000\n-0.20000000 0.20000000 1.20000000\n-0.20000000 0.20000000 1.40000000\n-0.20000000 0.20000000 2.00000000\n-0.20000000 0.20000000 2.20000000\n-0.20000000 0.40000000 -1.80000000\n-0.20000000 0.40000000 2.20000000\n-0.20000000 0.60000000 -2.00000000\n-0.20000000 0.60000000 1.40000000\n-0.20000000 0.60000000 1.60000000\n-0.20000000 0.60000000 1.80000000\n-0.20000000 0.60000000 2.00000000\n-0.20000000 0.80000000 -2.00000000\n-0.20000000 0.80000000 0.20000000\n-0.20000000 0.80000000 0.40000000\n-0.20000000 0.80000000 0.60000000\n-0.20000000 0.80000000 0.80000000\n-0.20000000 0.80000000 1.00000000\n-0.20000000 0.80000000 1.20000000\n-0.20000000 1.00000000 -1.80000000\n-0.20000000 1.00000000 -1.60000000\n-0.20000000 1.00000000 -0.20000000\n-0.20000000 1.00000000 0.00000000\n-0.20000000 1.20000000 -1.40000000\n-0.20000000 1.20000000 -1.20000000\n-0.20000000 1.20000000 -1.00000000\n-0.20000000 1.20000000 -0.80000000\n-0.20000000 1.20000000 -0.60000000\n-0.20000000 1.20000000 -0.40000000\n0.00000000 0.00000000 -0.40000000\n0.00000000 0.00000000 -0.20000000\n0.00000000 0.00000000 0.00000000\n0.00000000 0.00000000 0.20000000\n0.00000000 0.00000000 0.40000000\n0.00000000 0.00000000 0.60000000\n0.00000000 0.00000000 0.80000000\n0.00000000 0.00000000 1.00000000\n0.00000000 0.00000000 1.60000000\n0.00000000 0.00000000 1.80000000\n0.00000000 0.20000000 -1.60000000\n0.00000000 0.20000000 -1.40000000\n0.00000000 0.20000000 -1.20000000\n0.00000000 0.20000000 -1.00000000\n0.00000000 0.20000000 -0.80000000\n0.00000000 0.20000000 -0.60000000\n0.00000000 0.20000000 1.20000000\n0.00000000 0.20000000 1.40000000\n0.00000000 0.20000000 2.00000000\n0.00000000 0.20000000 2.20000000\n0.00000000 0.40000000 -1.80000000\n0.00000000 0.40000000 2.20000000\n0.00000000 0.60000000 -2.00000000\n0.00000000 0.60000000 1.40000000\n0.00000000 0.60000000 1.60000000\n0.00000000 0.60000000 1.80000000\n0.00000000 0.60000000 2.00000000\n0.00000000 0.80000000 -2.00000000\n0.00000000 0.80000000 0.20000000\n0.00000000 0.80000000 0.40000000\n0.00000000 0.80000000 0.60000000\n0.00000000 0.80000000 0.80000000\n0.00000000 0.80000000 1.00000000\n0.00000000 0.80000000 1.20000000\n0.00000000 1.00000000 -1.80000000\n0.00000000 1.00000000 -1.60000000\n0.00000000 1.00000000 -0.20000000\n0.00000000 1.00000000 0.00000000\n0.00000000 1.20000000 -1.40000000\n0.00000000 1.20000000 -1.20000000\n0.00000000 1.20000000 -1.00000000\n0.00000000 1.20000000 -0.80000000\n0.00000000 1.20000000 -0.60000000\n0.00000000 1.20000000 -0.40000000\n0.20000000 0.00000000 -0.40000000\n0.20000000 0.00000000 -0.20000000\n0.20000000 0.00000000 0.00000000\n0.20000000 0.00000000 0.20000000\n0.20000000 0.00000000 0.40000000\n0.20000000 0.00000000 0.60000000\n0.20000000 0.00000000 1.60000000\n0.20000000 0.00000000 1.80000000\n0.20000000 0.20000000 -1.60000000\n0.20000000 0.20000000 -1.40000000\n0.20000000 0.20000000 -1.20000000\n0.20000000 0.20000000 -1.00000000\n0.20000000 0.20000000 -0.80000000\n0.20000000 0.20000000 -0.60000000\n0.20000000 0.20000000 0.80000000\n0.20000000 0.20000000 1.00000000\n0.20000000 0.20000000 1.20000000\n0.20000000 0.20000000 1.40000000\n0.20000000 0.20000000 2.00000000\n0.20000000 0.20000000 2.20000000\n0.20000000 0.40000000 -1.80000000\n0.20000000 0.40000000 2.20000000\n0.20000000 0.60000000 -2.00000000\n0.20000000 0.60000000 1.40000000\n0.20000000 0.60000000 1.60000000\n0.20000000 0.60000000 1.80000000\n0.20000000 0.60000000 2.00000000\n0.20000000 0.80000000 -2.00000000\n0.20000000 0.80000000 0.20000000\n0.20000000 0.80000000 0.40000000\n0.20000000 0.80000000 0.60000000\n0.20000000 0.80000000 0.80000000\n0.20000000 0.80000000 1.00000000\n0.20000000 0.80000000 1.20000000\n0.20000000 1.00000000 -1.80000000\n0.20000000 1.00000000 -1.60000000\n0.20000000 1.00000000 -0.20000000\n0.20000000 1.00000000 0.00000000\n0.20000000 1.20000000 -1.40000000\n0.20000000 1.20000000 -1.20000000\n0.20000000 1.20000000 -1.00000000\n0.20000000 1.20000000 -0.80000000\n0.20000000 1.20000000 -0.60000000\n0.20000000 1.20000000 -0.40000000\n0.40000000 0.00000000 0.00000000\n0.40000000 0.00000000 0.20000000\n0.40000000 0.00000000 1.80000000\n0.40000000 0.20000000 -1.40000000\n0.40000000 0.20000000 -1.20000000\n0.40000000 0.20000000 -1.00000000\n0.40000000 0.20000000 -0.80000000\n0.40000000 0.20000000 -0.60000000\n0.40000000 0.20000000 -0.40000000\n0.40000000 0.20000000 -0.20000000\n0.40000000 0.20000000 0.40000000\n0.40000000 0.20000000 0.60000000\n0.40000000 0.20000000 0.80000000\n0.40000000 0.20000000 1.00000000\n0.40000000 0.20000000 1.20000000\n0.40000000 0.20000000 1.40000000\n0.40000000 0.20000000 1.60000000\n0.40000000 0.20000000 2.00000000\n0.40000000 0.40000000 -1.80000000\n0.40000000 0.40000000 -1.60000000\n0.40000000 0.40000000 2.20000000\n0.40000000 0.60000000 -1.80000000\n0.40000000 0.60000000 0.80000000\n0.40000000 0.60000000 1.00000000\n0.40000000 0.60000000 1.20000000\n0.40000000 0.60000000 1.40000000\n0.40000000 0.60000000 1.60000000\n0.40000000 0.60000000 1.80000000\n0.40000000 0.60000000 2.00000000\n0.40000000 0.80000000 -1.80000000\n0.40000000 0.80000000 0.00000000\n0.40000000 0.80000000 0.20000000\n0.40000000 0.80000000 0.40000000\n0.40000000 0.80000000 0.60000000\n0.40000000 1.00000000 -1.80000000\n0.40000000 1.00000000 -1.60000000\n0.40000000 1.00000000 -0.40000000\n0.40000000 1.00000000 -0.20000000\n0.40000000 1.20000000 -1.40000000\n0.40000000 1.20000000 -1.20000000\n0.40000000 1.20000000 -1.00000000\n0.40000000 1.20000000 -0.80000000\n0.40000000 1.20000000 -0.60000000\n0.60000000 0.20000000 -1.40000000\n0.60000000 0.20000000 -1.20000000\n0.60000000 0.20000000 -1.00000000\n0.60000000 0.20000000 -0.80000000\n0.60000000 0.20000000 -0.60000000\n0.60000000 0.20000000 -0.40000000\n0.60000000 0.20000000 -0.20000000\n0.60000000 0.20000000 0.00000000\n0.60000000 0.20000000 0.20000000\n0.60000000 0.20000000 0.40000000\n0.60000000 0.20000000 0.60000000\n0.60000000 0.20000000 0.80000000\n0.60000000 0.20000000 1.00000000\n0.60000000 0.20000000 1.20000000\n0.60000000 0.20000000 1.40000000\n0.60000000 0.20000000 1.60000000\n0.60000000 0.20000000 1.80000000\n0.60000000 0.20000000 2.00000000\n0.60000000 0.40000000 -1.60000000\n0.60000000 0.40000000 1.20000000\n0.60000000 0.40000000 2.00000000\n0.60000000 0.60000000 -1.80000000\n0.60000000 0.60000000 0.60000000\n0.60000000 0.60000000 0.80000000\n0.60000000 0.60000000 1.00000000\n0.60000000 0.60000000 1.40000000\n0.60000000 0.60000000 1.60000000\n0.60000000 0.60000000 1.80000000\n0.60000000 0.60000000 2.00000000\n0.60000000 0.80000000 -1.80000000\n0.60000000 0.80000000 0.00000000\n0.60000000 0.80000000 0.20000000\n0.60000000 0.80000000 0.40000000\n0.60000000 1.00000000 -1.60000000\n0.60000000 1.00000000 -1.40000000\n0.60000000 1.00000000 -1.20000000\n0.60000000 1.00000000 -1.00000000\n0.60000000 1.00000000 -0.80000000\n0.60000000 1.00000000 -0.60000000\n0.60000000 1.00000000 -0.40000000\n0.60000000 1.00000000 -0.20000000\n0.80000000 0.00000000 -1.40000000\n0.80000000 0.00000000 -1.20000000\n0.80000000 0.00000000 -1.00000000\n0.80000000 0.00000000 1.60000000\n0.80000000 0.00000000 1.80000000\n0.80000000 0.00000000 2.00000000\n0.80000000 0.20000000 -1.60000000\n0.80000000 0.20000000 -0.80000000\n0.80000000 0.20000000 -0.60000000\n0.80000000 0.20000000 -0.40000000\n0.80000000 0.20000000 -0.20000000\n0.80000000 0.20000000 0.00000000\n0.80000000 0.20000000 0.20000000\n0.80000000 0.20000000 0.40000000\n0.80000000 0.20000000 0.60000000\n0.80000000 0.20000000 0.80000000\n0.80000000 0.20000000 1.40000000\n0.80000000 0.20000000 2.20000000\n0.80000000 0.40000000 -1.60000000\n0.80000000 0.40000000 0.60000000\n0.80000000 0.40000000 0.80000000\n0.80000000 0.40000000 1.00000000\n0.80000000 0.40000000 1.40000000\n0.80000000 0.40000000 2.20000000\n0.80000000 0.60000000 -1.60000000\n0.80000000 0.60000000 0.00000000\n0.80000000 0.60000000 0.20000000\n0.80000000 0.60000000 0.40000000\n0.80000000 0.60000000 0.60000000\n0.80000000 0.60000000 0.80000000\n0.80000000 0.60000000 1.40000000\n0.80000000 0.60000000 1.60000000\n0.80000000 0.60000000 2.00000000\n0.80000000 0.80000000 -1.60000000\n0.80000000 0.80000000 -0.20000000\n0.80000000 0.80000000 1.80000000\n0.80000000 1.00000000 -1.40000000\n0.80000000 1.00000000 -1.20000000\n0.80000000 1.00000000 -1.00000000\n0.80000000 1.00000000 -0.80000000\n0.80000000 1.00000000 -0.60000000\n0.80000000 1.00000000 -0.40000000\n1.00000000 0.00000000 -1.40000000\n1.00000000 0.00000000 -1.20000000\n1.00000000 0.00000000 -1.00000000\n1.00000000 0.00000000 1.60000000\n1.00000000 0.00000000 1.80000000\n1.00000000 0.00000000 2.00000000\n1.00000000 0.20000000 -1.60000000\n1.00000000 0.20000000 -1.40000000\n1.00000000 0.20000000 -1.20000000\n1.00000000 0.20000000 -1.00000000\n1.00000000 0.20000000 -0.80000000\n1.00000000 0.20000000 1.40000000\n1.00000000 0.20000000 1.60000000\n1.00000000 0.20000000 1.80000000\n1.00000000 0.20000000 2.00000000\n1.00000000 0.20000000 2.20000000\n1.00000000 0.40000000 -1.60000000\n1.00000000 0.40000000 -1.40000000\n1.00000000 0.40000000 -1.20000000\n1.00000000 0.40000000 -1.00000000\n1.00000000 0.40000000 -0.80000000\n1.00000000 0.40000000 -0.60000000\n1.00000000 0.40000000 -0.40000000\n1.00000000 0.40000000 -0.20000000\n1.00000000 0.40000000 0.00000000\n1.00000000 0.40000000 0.20000000\n1.00000000 0.40000000 0.40000000\n1.00000000 0.40000000 1.40000000\n1.00000000 0.40000000 1.60000000\n1.00000000 0.40000000 1.80000000\n1.00000000 0.40000000 2.00000000\n1.00000000 0.40000000 2.20000000\n1.00000000 0.60000000 -1.60000000\n1.00000000 0.60000000 -1.40000000\n1.00000000 0.60000000 -1.20000000\n1.00000000 0.60000000 -1.00000000\n1.00000000 0.60000000 -0.80000000\n1.00000000 0.60000000 -0.60000000\n1.00000000 0.60000000 -0.40000000\n1.00000000 0.60000000 -0.20000000\n1.00000000 0.60000000 0.00000000\n1.00000000 0.60000000 0.20000000\n1.00000000 0.60000000 1.40000000\n1.00000000 0.60000000 1.60000000\n1.00000000 0.60000000 1.80000000\n1.00000000 0.60000000 2.00000000\n1.00000000 0.80000000 -1.40000000\n1.00000000 0.80000000 -1.20000000\n1.00000000 0.80000000 -1.00000000\n1.00000000 0.80000000 -0.80000000\n1.00000000 0.80000000 -0.60000000\n1.00000000 0.80000000 -0.40000000\n1.00000000 0.80000000 1.80000000",    "# X Y Z\n-1.10000000 0.20000000 -1.30000000\n-1.10000000 0.20000000 -1.20000000\n-1.10000000 0.20000000 -1.10000000\n-1.10000000 0.30000000 -1.30000000\n-1.10000000 0.30000000 -1.20000000\n-1.10000000 0.30000000 -1.10000000\n-1.10000000 0.40000000 -1.40000000\n-1.10000000 0.40000000 -1.30000000\n-1.10000000 0.40000000 -1.20000000\n-1.10000000 0.40000000 -1.10000000\n-1.10000000 0.50000000 -1.30000000\n-1.10000000 0.50000000 -1.20000000\n-1.10000000 0.50000000 -1.10000000\n-1.00000000 0.00000000 -1.30000000\n-1.00000000 0.00000000 -1.20000000\n-1.00000000 0.00000000 -1.10000000\n-1.00000000 0.00000000 1.70000000\n-1.00000000 0.00000000 1.80000000\n-1.00000000 0.10000000 -1.40000000\n-1.00000000 0.10000000 -1.30000000\n-1.00000000 0.10000000 -1.20000000\n-1.00000000 0.10000000 -1.10000000\n-1.00000000 0.10000000 -1.00000000\n-1.00000000 0.10000000 1.50000000\n-1.00000000 0.10000000 1.60000000\n-1.00000000 0.10000000 1.70000000\n-1.00000000 0.10000000 1.80000000\n-1.00000000 0.10000000 1.90000000\n-1.00000000 0.10000000 2.00000000\n-1.00000000 0.20000000 -1.50000000\n-1.00000000 0.20000000 -1.40000000\n-1.00000000 0.20000000 -1.00000000\n-1.00000000 0.20000000 -0.90000000\n-1.00000000 0.20000000 1.50000000\n-1.00000000 0.20000000 1.60000000\n-1.00000000 0.20000000 1.70000000\n-1.00000000 0.20000000 1.80000000\n-1.00000000 0.20000000 1.90000000\n-1.00000000 0.20000000 2.00000000\n-1.00000000 0.20000000 2.10000000\n-1.00000000 0.30000000 -1.50000000\n-1.00000000 0.30000000 -1.40000000\n-1.00000000 0.30000000 -1.00000000\n-1.00000000 0.30000000 -0.90000000\n-1.00000000 0.30000000 1.50000000\n-1.00000000 0.30000000 1.60000000\n-1.00000000 0.30000000 1.70000000\n-1.00000000 0.30000000 1.80000000\n-1.00000000 0.30000000 1.90000000\n-1.00000000 0.30000000 2.00000000\n-1.00000000 0.30000000 2.10000000\n-1.00000000 0.40000000 -1.50000000\n-1.00000000 0.40000000 -1.00000000\n-1.00000000 0.40000000 -0.90000000\n-1.00000000 0.40000000 -0.50000000\n-1.00000000 0.40000000 -0.40000000\n-1.00000000 0.40000000 -0.30000000\n-1.00000000 0.40000000 -0.20000000\n-1.00000000 0.40000000 -0.10000000\n-1.00000000 0.40000000 0.00000000\n-1.00000000 0.40000000 0.10000000\n-1.00000000 0.40000000 1.50000000\n-1.00000000 0.40000000 1.60000000\n-1.00000000 0.40000000 1.70000000\n-1.00000000 0.40000000 1.80000000\n-1.00000000 0.40000000 1.90000000\n-1.00000000 0.40000000 2.00000000\n-1.00000000 0.40000000 2.10000000\n-1.00000000 0.50000000 -1.50000000\n-1.00000000 0.50000000 -1.40000000\n-1.00000000 0.50000000 -1.00000000\n-1.00000000 0.50000000 -0.90000000\n-1.00000000 0.50000000 -0.80000000\n-1.00000000 0.50000000 -0.70000000\n-1.00000000 0.50000000 -0.60000000\n-1.00000000 0.50000000 -0.50000000\n-1.00000000 0.50000000 -0.40000000\n-1.00000000 0.50000000 -0.30000000\n-1.00000000 0.50000000 -0.20000000\n-1.00000000 0.50000000 -0.10000000\n-1.00000000 0.50000000 0.00000000\n-1.00000000 0.50000000 0.10000000\n-1.00000000 0.50000000 1.50000000\n-1.00000000 0.50000000 1.60000000\n-1.00000000 0.50000000 1.70000000\n-1.00000000 0.50000000 1.80000000\n-1.00000000 0.50000000 1.90000000\n-1.00000000 0.50000000 2.00000000\n-1.00000000 0.50000000 2.10000000\n-1.00000000 0.60000000 -1.50000000\n-1.00000000 0.60000000 -1.40000000\n-1.00000000 0.60000000 -1.30000000\n-1.00000000 0.60000000 -1.20000000\n-1.00000000 0.60000000 -1.10000000\n-1.00000000 0.60000000 -1.00000000\n-1.00000000 0.60000000 -0.90000000\n-1.00000000 0.60000000 -0.80000000\n-1.00000000 0.60000000 -0.70000000\n-1.00000000 0.60000000 -0.60000000\n-1.00000000 0.60000000 -0.50000000\n-1.00000000 0.60000000 1.50000000\n-1.00000000 0.60000000 1.60000000\n-1.00000000 0.60000000 1.70000000\n-1.00000000 0.60000000 1.80000000\n-1.00000000 0.60000000 1.90000000\n-1.00000000 0.60000000 2.00000000\n-1.00000000 0.70000000 -1.30000000\n-1.00000000 0.70000000 -1.20000000\n-1.00000000 0.70000000 -1.10000000\n-1.00000000 0.70000000 -1.00000000\n-1.00000000 0.70000000 -0.90000000\n-1.00000000 0.70000000 -0.80000000\n-1.00000000 0.70000000 -0.70000000\n-1.00000000 0.70000000 -0.60000000\n-1.00000000 0.70000000 -0.50000000\n-1.00000000 0.70000000 1.70000000\n-1.00000000 0.70000000 1.80000000\n-1.00000000 0.70000000 1.90000000\n-1.00000000 0.80000000 -1.20000000\n-1.00000000 0.80000000 -1.10000000\n-1.00000000 0.80000000 -1.00000000\n-1.00000000 0.80000000 -0.90000000\n-1.00000000 0.80000000 -0.80000000\n-1.00000000 0.80000000 -0.70000000\n-1.00000000 0.80000000 -0.60000000\n-0.90000000 0.00000000 -1.40000000\n-0.90000000 0.00000000 -1.30000000\n-0.90000000 0.00000000 -1.20000000\n-0.90000000 0.00000000 -1.10000000\n-0.90000000 0.00000000 -1.00000000\n-0.90000000 0.00000000 1.60000000\n-0.90000000 0.00000000 1.70000000\n-0.90000000 0.00000000 1.80000000\n-0.90000000 0.00000000 1.90000000\n-0.90000000 0.00000000 2.00000000\n-0.90000000 0.10000000 -1.50000000\n-0.90000000 0.10000000 -0.90000000\n-0.90000000 0.10000000 1.50000000\n-0.90000000 0.10000000 2.10000000\n-0.90000000 0.20000000 -1.60000000\n-0.90000000 0.20000000 -0.90000000\n-0.90000000 0.20000000 1.40000000\n-0.90000000 0.20000000 2.10000000\n-0.90000000 0.30000000 -1.60000000\n-0.90000000 0.30000000 -0.80000000\n-0.90000000 0.30000000 -0.70000000\n-0.90000000 0.30000000 -0.60000000\n-0.90000000 0.30000000 -0.50000000\n-0.90000000 0.30000000 -0.40000000\n-0.90000000 0.30000000 -0.30000000\n-0.90000000 0.30000000 -0.20000000\n-0.90000000 0.30000000 -0.10000000\n-0.90000000 0.30000000 0.00000000\n-0.90000000 0.30000000 0.10000000\n-0.90000000 0.30000000 0.20000000\n-0.90000000 0.30000000 0.30000000\n-0.90000000 0.30000000 0.40000000\n-0.90000000 0.30000000 0.50000000\n-0.90000000 0.30000000 1.40000000\n-0.90000000 0.30000000 2.10000000\n-0.90000000 0.40000000 -1.60000000\n-0.90000000 0.40000000 -0.80000000\n-0.90000000 0.40000000 -0.70000000\n-0.90000000 0.40000000 -0.60000000\n-0.90000000 0.40000000 0.20000000\n-0.90000000 0.40000000 0.30000000\n-0.90000000 0.40000000 0.40000000\n-0.90000000 0.40000000 0.50000000\n-0.90000000 0.40000000 0.60000000\n-0.90000000 0.40000000 1.40000000\n-0.90000000 0.40000000 2.10000000\n-0.90000000 0.50000000 -1.60000000\n-0.90000000 0.50000000 0.20000000\n-0.90000000 0.50000000 0.30000000\n-0.90000000 0.50000000 0.40000000\n-0.90000000 0.50000000 0.50000000\n-0.90000000 0.50000000 1.40000000\n-0.90000000 0.50000000 2.10000000\n-0.90000000 0.60000000 -1.50000000\n-0.90000000 0.60000000 -0.40000000\n-0.90000000 0.60000000 -0.30000000\n-0.90000000 0.60000000 -0.20000000\n-0.90000000 0.60000000 -0.10000000\n-0.90000000 0.60000000 0.00000000\n-0.90000000 0.60000000 0.10000000\n-0.90000000 0.60000000 0.20000000\n-0.90000000 0.60000000 0.30000000\n-0.90000000 0.60000000 1.50000000\n-0.90000000 0.60000000 2.10000000\n-0.90000000 0.70000000 -1.50000000\n-0.90000000 0.70000000 -1.40000000\n-0.90000000 0.70000000 -0.40000000\n-0.90000000 0.70000000 -0.30000000\n-0.90000000 0.70000000 1.60000000\n-0.90000000 0.70000000 1.70000000\n-0.90000000 0.70000000 1.80000000\n-0.90000000 0.70000000 1.90000000\n-0.90000000 0.70000000 2.00000000\n-0.90000000 0.80000000 -1.40000000\n-0.90000000 0.80000000 -1.30000000\n-0.90000000 0.80000000 -0.50000000\n-0.90000000 0.80000000 -0.40000000\n-0.90000000 0.90000000 -1.30000000\n-0.90000000 0.90000000 -1.20000000\n-0.90000000 0.90000000 -1.10000000\n-0.90000000 0.90000000 -1.00000000\n-0.90000000 0.90000000 -0.90000000\n-0.90000000 0.90000000 -0.80000000\n-0.90000000 0.90000000 -0.70000000\n-0.90000000 0.90000000 -0.60000000\n-0.90000000 0.90000000 -0.50000000\n-0.80000000 0.00000000 -1.40000000\n-0.80000000 0.00000000 -1.30000000\n-0.80000000 0.00000000 -1.20000000\n-0.80000000 0.00000000 -1.10000000\n-0.80000000 0.00000000 -1.00000000\n-0.80000000 0.00000000 1.60000000\n-0.80000000 0.00000000 1.70000000\n-0.80000000 0.00000000 1.80000000\n-0.80000000 0.00000000 1.90000000\n-0.80000000 0.00000000 2.00000000\n-0.80000000 0.10000000 -1.50000000\n-0.80000000 0.10000000 -1.40000000\n-0.80000000 0.10000000 -1.00000000\n-0.80000000 0.10000000 -0.90000000\n-0.80000000 0.10000000 1.50000000\n-0.80000000 0.10000000 2.00000000\n-0.80000000 0.10000000 2.10000000\n-0.80000000 0.20000000 -1.50000000\n-0.80000000 0.20000000 -0.90000000\n-0.80000000 0.20000000 -0.60000000\n-0.80000000 0.20000000 -0.50000000\n-0.80000000 0.20000000 -0.40000000\n-0.80000000 0.20000000 -0.30000000\n-0.80000000 0.20000000 -0.20000000\n-0.80000000 0.20000000 -0.10000000\n-0.80000000 0.20000000 0.00000000\n-0.80000000 0.20000000 0.10000000\n-0.80000000 0.20000000 0.20000000\n-0.80000000 0.20000000 0.30000000\n-0.80000000 0.20000000 0.40000000\n-0.80000000 0.20000000 0.50000000\n-0.80000000 0.20000000 1.40000000\n-0.80000000 0.20000000 2.10000000\n-0.80000000 0.30000000 -1.60000000\n-0.80000000 0.30000000 -1.50000000\n-0.80000000 0.30000000 -0.80000000\n-0.80000000 0.30000000 -0.70000000\n-0.80000000 0.30000000 0.60000000\n-0.80000000 0.30000000 0.70000000\n-0.80000000 0.30000000 0.80000000\n-0.80000000 0.30000000 1.40000000\n-0.80000000 0.30000000 2.10000000\n-0.80000000 0.40000000 -1.60000000\n-0.80000000 0.40000000 0.70000000\n-0.80000000 0.40000000 0.80000000\n-0.80000000 0.40000000 1.40000000\n-0.80000000 0.40000000 2.10000000\n-0.80000000 0.50000000 -1.50000000\n-0.80000000 0.50000000 0.60000000\n-0.80000000 0.50000000 0.70000000\n-0.80000000 0.50000000 0.80000000\n-0.80000000 0.50000000 1.40000000\n-0.80000000 0.50000000 2.10000000\n-0.80000000 0.60000000 -1.60000000\n-0.80000000 0.60000000 0.20000000\n-0.80000000 0.60000000 0.30000000\n-0.80000000 0.60000000 0.40000000\n-0.80000000 0.60000000 0.50000000\n-0.80000000 0.60000000 0.60000000\n-0.80000000 0.60000000 1.50000000\n-0.80000000 0.60000000 2.00000000\n-0.80000000 0.60000000 2.10000000\n-0.80000000 0.70000000 -1.60000000\n-0.80000000 0.70000000 -0.20000000\n-0.80000000 0.70000000 -0.10000000\n-0.80000000 0.70000000 0.00000000\n-0.80000000 0.70000000 0.10000000\n-0.80000000 0.70000000 1.60000000\n-0.80000000 0.70000000 1.70000000\n-0.80000000 0.70000000 1.80000000\n-0.80000000 0.70000000 1.90000000\n-0.80000000 0.70000000 2.00000000\n-0.80000000 0.80000000 -1.60000000\n-0.80000000 0.80000000 -1.50000000\n-0.80000000 0.80000000 -0.30000000\n-0.80000000 0.90000000 -1.50000000\n-0.80000000 0.90000000 -1.40000000\n-0.80000000 0.90000000 -0.50000000\n-0.80000000 0.90000000 -0.40000000\n-0.80000000 1.00000000 -1.30000000\n-0.80000000 1.00000000 -1.20000000\n-0.80000000 1.00000000 -1.10000000\n-0.80000000 1.00000000 -1.00000000\n-0.80000000 1.00000000 -0.90000000\n-0.80000000 1.00000000 -0.80000000\n-0.80000000 1.00000000 -0.70000000\n-0.80000000 1.00000000 -0.60000000\n-0.70000000 0.10000000 -1.30000000\n-0.70000000 0.10000000 -1.20000000\n-0.70000000 0.10000000 -1.10000000\n-0.70000000 0.10000000 1.60000000\n-0.70000000 0.10000000 1.70000000\n-0.70000000 0.10000000 1.80000000\n-0.70000000 0.10000000 1.90000000\n-0.70000000 0.20000000 -1.40000000\n-0.70000000 0.20000000 -1.30000000\n-0.70000000 0.20000000 -1.20000000\n-0.70000000 0.20000000 -1.00000000\n-0.70000000 0.20000000 -0.90000000\n-0.70000000 0.20000000 -0.80000000\n-0.70000000 0.20000000 -0.70000000\n-0.70000000 0.20000000 -0.60000000\n-0.70000000 0.20000000 -0.50000000\n-0.70000000 0.20000000 -0.40000000\n-0.70000000 0.20000000 -0.30000000\n-0.70000000 0.20000000 -0.20000000\n-0.70000000 0.20000000 -0.10000000\n-0.70000000 0.20000000 0.00000000\n-0.70000000 0.20000000 0.10000000\n-0.70000000 0.20000000 0.20000000\n-0.70000000 0.20000000 0.30000000\n-0.70000000 0.20000000 0.40000000\n-0.70000000 0.20000000 0.50000000\n-0.70000000 0.20000000 0.60000000\n-0.70000000 0.20000000 0.70000000\n-0.70000000 0.20000000 0.80000000\n-0.70000000 0.20000000 1.50000000\n-0.70000000 0.20000000 2.00000000\n-0.70000000 0.30000000 -1.40000000\n-0.70000000 0.30000000 0.90000000\n-0.70000000 0.30000000 1.00000000\n-0.70000000 0.30000000 1.50000000\n-0.70000000 0.30000000 2.10000000\n-0.70000000 0.40000000 -1.50000000\n-0.70000000 0.40000000 0.90000000\n-0.70000000 0.40000000 1.00000000\n-0.70000000 0.40000000 1.50000000\n-0.70000000 0.40000000 2.10000000\n-0.70000000 0.50000000 -1.60000000\n-0.70000000 0.50000000 0.90000000\n-0.70000000 0.50000000 1.00000000\n-0.70000000 0.50000000 1.50000000\n-0.70000000 0.50000000 2.00000000\n-0.70000000 0.60000000 -1.70000000\n-0.70000000 0.60000000 0.50000000\n-0.70000000 0.60000000 0.60000000\n-0.70000000 0.60000000 0.70000000\n-0.70000000 0.60000000 0.80000000\n-0.70000000 0.60000000 1.60000000\n-0.70000000 0.60000000 1.70000000\n-0.70000000 0.60000000 1.80000000\n-0.70000000 0.60000000 1.90000000\n-0.70000000 0.70000000 -1.70000000\n-0.70000000 0.70000000 -0.10000000\n-0.70000000 0.70000000 0.00000000\n-0.70000000 0.70000000 0.10000000\n-0.70000000 0.70000000 0.20000000\n-0.70000000 0.70000000 0.30000000\n-0.70000000 0.70000000 0.40000000\n-0.70000000 0.80000000 -1.70000000\n-0.70000000 0.80000000 -0.20000000\n-0.70000000 0.90000000 -1.60000000\n-0.70000000 0.90000000 -1.50000000\n-0.70000000 0.90000000 -0.30000000\n-0.70000000 1.00000000 -1.40000000\n-0.70000000 1.00000000 -1.30000000\n-0.70000000 1.00000000 -1.20000000\n-0.70000000 1.00000000 -1.10000000\n-0.70000000 1.00000000 -0.90000000\n-0.70000000 1.00000000 -0.80000000\n-0.70000000 1.00000000 -0.70000000\n-0.70000000 1.00000000 -0.60000000\n-0.70000000 1.00000000 -0.50000000\n-0.70000000 1.00000000 -0.40000000\n-0.70000000 1.10000000 -1.00000000\n-0.60000000 0.10000000 -0.10000000\n-0.60000000 0.10000000 0.00000000\n-0.60000000 0.10000000 0.10000000\n-0.60000000 0.10000000 0.20000000\n-0.60000000 0.10000000 0.30000000\n-0.60000000 0.10000000 1.70000000\n-0.60000000 0.10000000 1.80000000\n-0.60000000 0.20000000 -1.10000000\n-0.60000000 0.20000000 -1.00000000\n-0.60000000 0.20000000 -0.90000000\n-0.60000000 0.20000000 -0.80000000\n-0.60000000 0.20000000 -0.70000000\n-0.60000000 0.20000000 -0.60000000\n-0.60000000 0.20000000 -0.50000000\n-0.60000000 0.20000000 -0.40000000\n-0.60000000 0.20000000 -0.30000000\n-0.60000000 0.20000000 -0.20000000\n-0.60000000 0.20000000 0.40000000\n-0.60000000 0.20000000 0.50000000\n-0.60000000 0.20000000 0.60000000\n-0.60000000 0.20000000 0.70000000\n-0.60000000 0.20000000 0.80000000\n-0.60000000 0.20000000 0.90000000\n-0.60000000 0.20000000 1.00000000\n-0.60000000 0.20000000 1.50000000\n-0.60000000 0.20000000 1.60000000\n-0.60000000 0.20000000 1.90000000\n-0.60000000 0.20000000 2.00000000\n-0.60000000 0.30000000 -1.40000000\n-0.60000000 0.30000000 -1.30000000\n-0.60000000 0.30000000 -1.20000000\n-0.60000000 0.30000000 1.10000000\n-0.60000000 0.30000000 1.20000000\n-0.60000000 0.30000000 1.50000000\n-0.60000000 0.30000000 2.00000000\n-0.60000000 0.40000000 -1.60000000\n-0.60000000 0.40000000 -1.50000000\n-0.60000000 0.40000000 1.10000000\n-0.60000000 0.40000000 1.20000000\n-0.60000000 0.40000000 1.50000000\n-0.60000000 0.40000000 2.00000000\n-0.60000000 0.50000000 -1.70000000\n-0.60000000 0.50000000 1.00000000\n-0.60000000 0.50000000 1.10000000\n-0.60000000 0.50000000 1.50000000\n-0.60000000 0.50000000 2.00000000\n-0.60000000 0.60000000 -1.80000000\n-0.60000000 0.60000000 0.70000000\n-0.60000000 0.60000000 0.80000000\n-0.60000000 0.60000000 0.90000000\n-0.60000000 0.60000000 1.60000000\n-0.60000000 0.60000000 1.70000000\n-0.60000000 0.60000000 1.80000000\n-0.60000000 0.60000000 1.90000000\n-0.60000000 0.70000000 -1.80000000\n-0.60000000 0.70000000 0.00000000\n-0.60000000 0.70000000 0.10000000\n-0.60000000 0.70000000 0.20000000\n-0.60000000 0.70000000 0.30000000\n-0.60000000 0.70000000 0.40000000\n-0.60000000 0.70000000 0.50000000\n-0.60000000 0.70000000 0.60000000\n-0.60000000 0.80000000 -1.70000000\n-0.60000000 0.80000000 -0.10000000\n-0.60000000 0.90000000 -1.70000000\n-0.60000000 0.90000000 -0.20000000\n-0.60000000 1.00000000 -1.60000000\n-0.60000000 1.00000000 -1.50000000\n-0.60000000 1.00000000 -1.40000000\n-0.60000000 1.00000000 -0.60000000\n-0.60000000 1.00000000 -0.50000000\n-0.60000000 1.00000000 -0.40000000\n-0.60000000 1.00000000 -0.30000000\n-0.60000000 1.10000000 -1.30000000\n-0.60000000 1.10000000 -1.20000000\n-0.60000000 1.10000000 -1.10000000\n-0.60000000 1.10000000 -1.00000000\n-0.60000000 1.10000000 -0.90000000\n-0.60000000 1.10000000 -0.80000000\n-0.60000000 1.10000000 -0.70000000\n-0.50000000 0.10000000 -0.50000000\n-0.50000000 0.10000000 -0.40000000\n-0.50000000 0.10000000 -0.30000000\n-0.50000000 0.10000000 -0.20000000\n-0.50000000 0.10000000 -0.10000000\n-0.50000000 0.10000000 0.00000000\n-0.50000000 0.10000000 0.10000000\n-0.50000000 0.10000000 0.20000000\n-0.50000000 0.10000000 0.30000000\n-0.50000000 0.10000000 0.40000000\n-0.50000000 0.10000000 0.50000000\n-0.50000000 0.10000000 0.60000000\n-0.50000000 0.10000000 1.60000000\n-0.50000000 0.10000000 1.70000000\n-0.50000000 0.10000000 1.80000000\n-0.50000000 0.10000000 1.90000000\n-0.50000000 0.20000000 -1.30000000\n-0.50000000 0.20000000 -1.20000000\n-0.50000000 0.20000000 -1.10000000\n-0.50000000 0.20000000 -1.00000000\n-0.50000000 0.20000000 -0.90000000\n-0.50000000 0.20000000 -0.80000000\n-0.50000000 0.20000000 -0.70000000\n-0.50000000 0.20000000 -0.60000000\n-0.50000000 0.20000000 0.70000000\n-0.50000000 0.20000000 0.80000000\n-0.50000000 0.20000000 0.90000000\n-0.50000000 0.20000000 1.00000000\n-0.50000000 0.20000000 1.10000000\n-0.50000000 0.20000000 1.50000000\n-0.50000000 0.20000000 2.00000000\n-0.50000000 0.30000000 -1.50000000\n-0.50000000 0.30000000 -1.40000000\n-0.50000000 0.30000000 1.20000000\n-0.50000000 0.30000000 1.30000000\n-0.50000000 0.30000000 1.40000000\n-0.50000000 0.30000000 2.10000000\n-0.50000000 0.40000000 -1.70000000\n-0.50000000 0.40000000 -1.60000000\n-0.50000000 0.40000000 1.30000000\n-0.50000000 0.40000000 1.40000000\n-0.50000000 0.40000000 2.10000000\n-0.50000000 0.50000000 -1.80000000\n-0.50000000 0.50000000 1.20000000\n-0.50000000 0.50000000 1.50000000\n-0.50000000 0.50000000 2.10000000\n-0.50000000 0.60000000 -1.80000000\n-0.50000000 0.60000000 0.80000000\n-0.50000000 0.60000000 0.90000000\n-0.50000000 0.60000000 1.00000000\n-0.50000000 0.60000000 1.10000000\n-0.50000000 0.60000000 1.60000000\n-0.50000000 0.60000000 1.70000000\n-0.50000000 0.60000000 1.80000000\n-0.50000000 0.60000000 1.90000000\n-0.50000000 0.60000000 2.00000000\n-0.50000000 0.70000000 -1.80000000\n-0.50000000 0.70000000 0.20000000\n-0.50000000 0.70000000 0.30000000\n-0.50000000 0.70000000 0.40000000\n-0.50000000 0.70000000 0.50000000\n-0.50000000 0.70000000 0.60000000\n-0.50000000 0.70000000 0.70000000\n-0.50000000 0.80000000 -1.80000000\n-0.50000000 0.80000000 0.00000000\n-0.50000000 0.80000000 0.10000000\n-0.50000000 0.90000000 -1.70000000\n-0.50000000 0.90000000 -0.20000000\n-0.50000000 0.90000000 -0.10000000\n-0.50000000 1.00000000 -1.60000000\n-0.50000000 1.00000000 -1.50000000\n-0.50000000 1.00000000 -0.40000000\n-0.50000000 1.00000000 -0.30000000\n-0.50000000 1.10000000 -1.40000000\n-0.50000000 1.10000000 -1.30000000\n-0.50000000 1.10000000 -1.20000000\n-0.50000000 1.10000000 -1.10000000\n-0.50000000 1.10000000 -1.00000000\n-0.50000000 1.10000000 -0.90000000\n-0.50000000 1.10000000 -0.80000000\n-0.50000000 1.10000000 -0.70000000\n-0.50000000 1.10000000 -0.60000000\n-0.50000000 1.10000000 -0.50000000\n-0.40000000 0.10000000 -0.70000000\n-0.40000000 0.10000000 -0.60000000\n-0.40000000 0.10000000 -0.50000000\n-0.40000000 0.10000000 -0.40000000\n-0.40000000 0.10000000 -0.30000000\n-0.40000000 0.10000000 -0.20000000\n-0.40000000 0.10000000 -0.10000000\n-0.40000000 0.10000000 0.00000000\n-0.40000000 0.10000000 0.10000000\n-0.40000000 0.10000000 0.20000000\n-0.40000000 0.10000000 0.30000000\n-0.40000000 0.10000000 0.40000000\n-0.40000000 0.10000000 0.50000000\n-0.40000000 0.10000000 0.60000000\n-0.40000000 0.10000000 0.70000000\n-0.40000000 0.10000000 0.80000000\n-0.40000000 0.10000000 1.60000000\n-0.40000000 0.10000000 1.70000000\n-0.40000000 0.10000000 1.80000000\n-0.40000000 0.10000000 1.90000000\n-0.40000000 0.20000000 -1.40000000\n-0.40000000 0.20000000 -1.30000000\n-0.40000000 0.20000000 -1.20000000\n-0.40000000 0.20000000 -1.10000000\n-0.40000000 0.20000000 -1.00000000\n-0.40000000 0.20000000 -0.90000000\n-0.40000000 0.20000000 -0.80000000\n-0.40000000 0.20000000 0.90000000\n-0.40000000 0.20000000 1.00000000\n-0.40000000 0.20000000 1.10000000\n-0.40000000 0.20000000 1.20000000\n-0.40000000 0.20000000 1.40000000\n-0.40000000 0.20000000 1.50000000\n-0.40000000 0.20000000 2.00000000\n-0.40000000 0.20000000 2.10000000\n-0.40000000 0.30000000 -1.60000000\n-0.40000000 0.30000000 -1.50000000\n-0.40000000 0.30000000 1.30000000\n-0.40000000 0.30000000 2.10000000\n-0.40000000 0.40000000 -1.70000000\n-0.40000000 0.40000000 2.10000000\n-0.40000000 0.50000000 -1.80000000\n-0.40000000 0.50000000 1.30000000\n-0.40000000 0.50000000 1.40000000\n-0.40000000 0.50000000 2.10000000\n-0.40000000 0.60000000 -1.90000000\n-0.40000000 0.60000000 0.90000000\n-0.40000000 0.60000000 1.00000000\n-0.40000000 0.60000000 1.10000000\n-0.40000000 0.60000000 1.20000000\n-0.40000000 0.60000000 1.50000000\n-0.40000000 0.60000000 1.60000000\n-0.40000000 0.60000000 1.70000000\n-0.40000000 0.60000000 1.80000000\n-0.40000000 0.60000000 1.90000000\n-0.40000000 0.60000000 2.00000000\n-0.40000000 0.70000000 -1.90000000\n-0.40000000 0.70000000 0.30000000\n-0.40000000 0.70000000 0.40000000\n-0.40000000 0.70000000 0.50000000\n-0.40000000 0.70000000 0.60000000\n-0.40000000 0.70000000 0.70000000\n-0.40000000 0.70000000 0.80000000\n-0.40000000 0.80000000 -1.80000000\n-0.40000000 0.80000000 0.00000000\n-0.40000000 0.80000000 0.10000000\n-0.40000000 0.80000000 0.20000000\n-0.40000000 0.90000000 -1.80000000\n-0.40000000 0.90000000 -0.10000000\n-0.40000000 1.00000000 -1.70000000\n-0.40000000 1.00000000 -1.60000000\n-0.40000000 1.00000000 -0.30000000\n-0.40000000 1.00000000 -0.20000000\n-0.40000000 1.10000000 -1.50000000\n-0.40000000 1.10000000 -1.40000000\n-0.40000000 1.10000000 -1.30000000\n-0.40000000 1.10000000 -1.20000000\n-0.40000000 1.10000000 -1.10000000\n-0.40000000 1.10000000 -1.00000000\n-0.40000000 1.10000000 -0.90000000\n-0.40000000 1.10000000 -0.80000000\n-0.40000000 1.10000000 -0.70000000\n-0.40000000 1.10000000 -0.60000000\n-0.40000000 1.10000000 -0.50000000\n-0.40000000 1.10000000 -0.40000000\n-0.30000000 0.10000000 -0.80000000\n-0.30000000 0.10000000 -0.70000000\n-0.30000000 0.10000000 -0.60000000\n-0.30000000 0.10000000 -0.50000000\n-0.30000000 0.10000000 -0.40000000\n-0.30000000 0.10000000 -0.30000000\n-0.30000000 0.10000000 -0.20000000\n-0.30000000 0.10000000 -0.10000000\n-0.30000000 0.10000000 0.00000000\n-0.30000000 0.10000000 0.10000000\n-0.30000000 0.10000000 0.20000000\n-0.30000000 0.10000000 0.30000000\n-0.30000000 0.10000000 0.40000000\n-0.30000000 0.10000000 0.50000000\n-0.30000000 0.10000000 0.60000000\n-0.30000000 0.10000000 0.70000000\n-0.30000000 0.10000000 0.80000000\n-0.30000000 0.10000000 0.90000000\n-0.30000000 0.10000000 1.50000000\n-0.30000000 0.10000000 1.60000000\n-0.30000000 0.10000000 1.70000000\n-0.30000000 0.10000000 1.80000000\n-0.30000000 0.10000000 1.90000000\n-0.30000000 0.10000000 2.00000000\n-0.30000000 0.20000000 -1.40000000\n-0.30000000 0.20000000 -1.30000000\n-0.30000000 0.20000000 -1.20000000\n-0.30000000 0.20000000 -1.10000000\n-0.30000000 0.20000000 -1.00000000\n-0.30000000 0.20000000 -0.90000000\n-0.30000000 0.20000000 1.00000000\n-0.30000000 0.20000000 1.10000000\n-0.30000000 0.20000000 1.20000000\n-0.30000000 0.20000000 1.30000000\n-0.30000000 0.20000000 1.40000000\n-0.30000000 0.20000000 2.10000000\n-0.30000000 0.30000000 -1.60000000\n-0.30000000 0.30000000 -1.50000000\n-0.30000000 0.30000000 2.10000000\n-0.30000000 0.40000000 -1.80000000\n-0.30000000 0.40000000 -1.70000000\n-0.30000000 0.40000000 2.10000000\n-0.30000000 0.50000000 -1.90000000\n-0.30000000 0.50000000 2.10000000\n-0.30000000 0.60000000 -1.90000000\n-0.30000000 0.60000000 1.20000000\n-0.30000000 0.60000000 1.30000000\n-0.30000000 0.60000000 1.40000000\n-0.30000000 0.60000000 1.50000000\n-0.30000000 0.60000000 1.60000000\n-0.30000000 0.60000000 1.70000000\n-0.30000000 0.60000000 1.80000000\n-0.30000000 0.60000000 1.90000000\n-0.30000000 0.60000000 2.00000000\n-0.30000000 0.70000000 -1.90000000\n-0.30000000 0.70000000 0.50000000\n-0.30000000 0.70000000 0.60000000\n-0.30000000 0.70000000 0.70000000\n-0.30000000 0.70000000 0.80000000\n-0.30000000 0.70000000 0.90000000\n-0.30000000 0.70000000 1.00000000\n-0.30000000 0.70000000 1.10000000\n-0.30000000 0.80000000 -1.90000000\n-0.30000000 0.80000000 0.10000000\n-0.30000000 0.80000000 0.20000000\n-0.30000000 0.80000000 0.30000000\n-0.30000000 0.80000000 0.40000000\n-0.30000000 0.90000000 -1.80000000\n-0.30000000 0.90000000 0.00000000\n-0.30000000 1.00000000 -1.70000000\n-0.30000000 1.00000000 -1.60000000\n-0.30000000 1.00000000 -0.30000000\n-0.30000000 1.00000000 -0.20000000\n-0.30000000 1.00000000 -0.10000000\n-0.30000000 1.10000000 -1.50000000\n-0.30000000 1.10000000 -1.40000000\n-0.30000000 1.10000000 -1.30000000\n-0.30000000 1.10000000 -1.20000000\n-0.30000000 1.10000000 -0.80000000\n-0.30000000 1.10000000 -0.70000000\n-0.30000000 1.10000000 -0.60000000\n-0.30000000 1.10000000 -0.50000000\n-0.30000000 1.10000000 -0.40000000\n-0.30000000 1.20000000 -1.10000000\n-0.30000000 1.20000000 -1.00000000\n-0.30000000 1.20000000 -0.90000000\n-0.20000000 0.10000000 -1.00000000\n-0.20000000 0.10000000 -0.90000000\n-0.20000000 0.10000000 -0.80000000\n-0.20000000 0.10000000 -0.70000000\n-0.20000000 0.10000000 -0.60000000\n-0.20000000 0.10000000 -0.50000000\n-0.20000000 0.10000000 -0.40000000\n-0.20000000 0.10000000 -0.30000000\n-0.20000000 0.10000000 -0.20000000\n-0.20000000 0.10000000 -0.10000000\n-0.20000000 0.10000000 0.00000000\n-0.20000000 0.10000000 0.10000000\n-0.20000000 0.10000000 0.20000000\n-0.20000000 0.10000000 0.30000000\n-0.20000000 0.10000000 0.40000000\n-0.20000000 0.10000000 0.50000000\n-0.20000000 0.10000000 0.60000000\n-0.20000000 0.10000000 0.70000000\n-0.20000000 0.10000000 0.80000000\n-0.20000000 0.10000000 0.90000000\n-0.20000000 0.10000000 1.00000000\n-0.20000000 0.10000000 1.10000000\n-0.20000000 0.10000000 1.20000000\n-0.20000000 0.10000000 1.30000000\n-0.20000000 0.10000000 1.40000000\n-0.20000000 0.10000000 1.50000000\n-0.20000000 0.10000000 1.60000000\n-0.20000000 0.10000000 1.70000000\n-0.20000000 0.10000000 1.80000000\n-0.20000000 0.10000000 1.90000000\n-0.20000000 0.10000000 2.00000000\n-0.20000000 0.20000000 -1.50000000\n-0.20000000 0.20000000 -1.40000000\n-0.20000000 0.20000000 -1.30000000\n-0.20000000 0.20000000 -1.20000000\n-0.20000000 0.20000000 -1.10000000\n-0.20000000 0.20000000 2.10000000\n-0.20000000 0.30000000 -1.70000000\n-0.20000000 0.30000000 -1.60000000\n-0.20000000 0.30000000 2.10000000\n-0.20000000 0.40000000 -1.80000000\n-0.20000000 0.40000000 2.10000000\n-0.20000000 0.50000000 -1.90000000\n-0.20000000 0.50000000 2.10000000\n-0.20000000 0.60000000 -1.90000000\n-0.20000000 0.60000000 1.50000000\n-0.20000000 0.60000000 1.60000000\n-0.20000000 0.60000000 1.70000000\n-0.20000000 0.60000000 1.80000000\n-0.20000000 0.60000000 1.90000000\n-0.20000000 0.60000000 2.00000000\n-0.20000000 0.70000000 -1.90000000\n-0.20000000 0.70000000 0.90000000\n-0.20000000 0.70000000 1.00000000\n-0.20000000 0.70000000 1.10000000\n-0.20000000 0.70000000 1.20000000\n-0.20000000 0.70000000 1.30000000\n-0.20000000 0.70000000 1.40000000\n-0.20000000 0.80000000 -1.90000000\n-0.20000000 0.80000000 0.10000000\n-0.20000000 0.80000000 0.20000000\n-0.20000000 0.80000000 0.30000000\n-0.20000000 0.80000000 0.40000000\n-0.20000000 0.80000000 0.50000000\n-0.20000000 0.80000000 0.60000000\n-0.20000000 0.80000000 0.70000000\n-0.20000000 0.80000000 0.80000000\n-0.20000000 0.90000000 -1.90000000\n-0.20000000 0.90000000 0.00000000\n-0.20000000 1.00000000 -1.80000000\n-0.20000000 1.00000000 -1.70000000\n-0.20000000 1.00000000 -0.20000000\n-0.20000000 1.00000000 -0.10000000\n-0.20000000 1.10000000 -1.60000000\n-0.20000000 1.10000000 -1.50000000\n-0.20000000 1.10000000 -1.40000000\n-0.20000000 1.10000000 -1.30000000\n-0.20000000 1.10000000 -1.20000000\n-0.20000000 1.10000000 -0.70000000\n-0.20000000 1.10000000 -0.60000000\n-0.20000000 1.10000000 -0.50000000\n-0.20000000 1.10000000 -0.40000000\n-0.20000000 1.10000000 -0.30000000\n-0.20000000 1.20000000 -1.10000000\n-0.20000000 1.20000000 -1.00000000\n-0.20000000 1.20000000 -0.90000000\n-0.20000000 1.20000000 -0.80000000\n-0.10000000 0.10000000 -1.00000000\n-0.10000000 0.10000000 -0.90000000\n-0.10000000 0.10000000 -0.80000000\n-0.10000000 0.10000000 -0.70000000\n-0.10000000 0.10000000 -0.60000000\n-0.10000000 0.10000000 -0.50000000\n-0.10000000 0.10000000 -0.40000000\n-0.10000000 0.10000000 -0.30000000\n-0.10000000 0.10000000 -0.20000000\n-0.10000000 0.10000000 -0.10000000\n-0.10000000 0.10000000 0.00000000\n-0.10000000 0.10000000 0.10000000\n-0.10000000 0.10000000 0.20000000\n-0.10000000 0.10000000 0.30000000\n-0.10000000 0.10000000 0.40000000\n-0.10000000 0.10000000 0.50000000\n-0.10000000 0.10000000 0.60000000\n-0.10000000 0.10000000 0.70000000\n-0.10000000 0.10000000 0.80000000\n-0.10000000 0.10000000 0.90000000\n-0.10000000 0.10000000 1.00000000\n-0.10000000 0.10000000 1.10000000\n-0.10000000 0.10000000 1.20000000\n-0.10000000 0.10000000 1.30000000\n-0.10000000 0.10000000 1.40000000\n-0.10000000 0.10000000 1.50000000\n-0.10000000 0.10000000 1.60000000\n-0.10000000 0.10000000 1.70000000\n-0.10000000 0.10000000 1.80000000\n-0.10000000 0.10000000 1.90000000\n-0.10000000 0.10000000 2.00000000\n-0.10000000 0.20000000 -1.50000000\n-0.10000000 0.20000000 -1.40000000\n-0.10000000 0.20000000 -1.30000000\n-0.10000000 0.20000000 -1.20000000\n-0.10000000 0.20000000 -1.10000000\n-0.10000000 0.20000000 2.10000000\n-0.10000000 0.30000000 -1.70000000\n-0.10000000 0.30000000 -1.60000000\n-0.10000000 0.30000000 2.10000000\n-0.10000000 0.40000000 -1.80000000\n-0.10000000 0.40000000 2.10000000\n-0.10000000 0.50000000 -1.90000000\n-0.10000000 0.50000000 2.10000000\n-0.10000000 0.60000000 -1.90000000\n-0.10000000 0.60000000 1.60000000\n-0.10000000 0.60000000 1.70000000\n-0.10000000 0.60000000 1.80000000\n-0.10000000 0.60000000 1.90000000\n-0.10000000 0.60000000 2.00000000\n-0.10000000 0.70000000 -1.90000000\n-0.10000000 0.70000000 1.10000000\n-0.10000000 0.70000000 1.20000000\n-0.10000000 0.70000000 1.30000000\n-0.10000000 0.70000000 1.40000000\n-0.10000000 0.70000000 1.50000000\n-0.10000000 0.80000000 -1.90000000\n-0.10000000 0.80000000 0.10000000\n-0.10000000 0.80000000 0.20000000\n-0.10000000 0.80000000 0.30000000\n-0.10000000 0.80000000 0.40000000\n-0.10000000 0.80000000 0.50000000\n-0.10000000 0.80000000 0.60000000\n-0.10000000 0.80000000 0.70000000\n-0.10000000 0.80000000 0.80000000\n-0.10000000 0.80000000 0.90000000\n-0.10000000 0.80000000 1.00000000\n-0.10000000 0.90000000 -1.90000000\n-0.10000000 0.90000000 0.00000000\n-0.10000000 1.00000000 -1.80000000\n-0.10000000 1.00000000 -1.70000000\n-0.10000000 1.00000000 -0.20000000\n-0.10000000 1.00000000 -0.10000000\n-0.10000000 1.10000000 -1.60000000\n-0.10000000 1.10000000 -1.50000000\n-0.10000000 1.10000000 -1.40000000\n-0.10000000 1.10000000 -1.30000000\n-0.10000000 1.10000000 -0.60000000\n-0.10000000 1.10000000 -0.50000000\n-0.10000000 1.10000000 -0.40000000\n-0.10000000 1.10000000 -0.30000000\n-0.10000000 1.20000000 -1.20000000\n-0.10000000 1.20000000 -1.10000000\n-0.10000000 1.20000000 -1.00000000\n-0.10000000 1.20000000 -0.90000000\n-0.10000000 1.20000000 -0.80000000\n-0.10000000 1.20000000 -0.70000000\n0.00000000 0.10000000 -1.00000000\n0.00000000 0.10000000 -0.90000000\n0.00000000 0.10000000 -0.80000000\n0.00000000 0.10000000 -0.70000000\n0.00000000 0.10000000 -0.60000000\n0.00000000 0.10000000 -0.50000000\n0.00000000 0.10000000 -0.40000000\n0.00000000 0.10000000 -0.30000000\n0.00000000 0.10000000 -0.20000000\n0.00000000 0.10000000 -0.10000000\n0.00000000 0.10000000 0.00000000\n0.00000000 0.10000000 0.10000000\n0.00000000 0.10000000 0.20000000\n0.00000000 0.10000000 0.30000000\n0.00000000 0.10000000 0.40000000\n0.00000000 0.10000000 0.50000000\n0.00000000 0.10000000 0.60000000\n0.00000000 0.10000000 0.70000000\n0.00000000 0.10000000 0.80000000\n0.00000000 0.10000000 0.90000000\n0.00000000 0.10000000 1.00000000\n0.00000000 0.10000000 1.10000000\n0.00000000 0.10000000 1.20000000\n0.00000000 0.10000000 1.30000000\n0.00000000 0.10000000 1.40000000\n0.00000000 0.10000000 1.50000000\n0.00000000 0.10000000 1.60000000\n0.00000000 0.10000000 1.70000000\n0.00000000 0.10000000 1.80000000\n0.00000000 0.10000000 1.90000000\n0.00000000 0.10000000 2.00000000\n0.00000000 0.20000000 -1.50000000\n0.00000000 0.20000000 -1.40000000\n0.00000000 0.20000000 -1.30000000\n0.00000000 0.20000000 -1.20000000\n0.00000000 0.20000000 -1.10000000\n0.00000000 0.20000000 2.10000000\n0.00000000 0.30000000 -1.70000000\n0.00000000 0.30000000 -1.60000000\n0.00000000 0.30000000 2.10000000\n0.00000000 0.40000000 -1.90000000\n0.00000000 0.40000000 -1.80000000\n0.00000000 0.40000000 2.10000000\n0.00000000 0.50000000 -1.90000000\n0.00000000 0.50000000 2.10000000\n0.00000000 0.60000000 -1.90000000\n0.00000000 0.60000000 1.60000000\n0.00000000 0.60000000 1.70000000\n0.00000000 0.60000000 1.80000000\n0.00000000 0.60000000 1.90000000\n0.00000000 0.60000000 2.00000000\n0.00000000 0.70000000 -1.90000000\n0.00000000 0.70000000 1.10000000\n0.00000000 0.70000000 1.20000000\n0.00000000 0.70000000 1.30000000\n0.00000000 0.70000000 1.40000000\n0.00000000 0.70000000 1.50000000\n0.00000000 0.80000000 -1.90000000\n0.00000000 0.80000000 0.10000000\n0.00000000 0.80000000 0.20000000\n0.00000000 0.80000000 0.30000000\n0.00000000 0.80000000 0.40000000\n0.00000000 0.80000000 0.50000000\n0.00000000 0.80000000 0.60000000\n0.00000000 0.80000000 0.70000000\n0.00000000 0.80000000 0.80000000\n0.00000000 0.80000000 0.90000000\n0.00000000 0.80000000 1.00000000\n0.00000000 0.90000000 -1.90000000\n0.00000000 0.90000000 0.00000000\n0.00000000 1.00000000 -1.80000000\n0.00000000 1.00000000 -1.70000000\n0.00000000 1.00000000 -0.20000000\n0.00000000 1.00000000 -0.10000000\n0.00000000 1.10000000 -1.60000000\n0.00000000 1.10000000 -1.50000000\n0.00000000 1.10000000 -1.40000000\n0.00000000 1.10000000 -1.30000000\n0.00000000 1.10000000 -0.60000000\n0.00000000 1.10000000 -0.50000000\n0.00000000 1.10000000 -0.40000000\n0.00000000 1.10000000 -0.30000000\n0.00000000 1.20000000 -1.20000000\n0.00000000 1.20000000 -1.10000000\n0.00000000 1.20000000 -1.00000000\n0.00000000 1.20000000 -0.90000000\n0.00000000 1.20000000 -0.80000000\n0.00000000 1.20000000 -0.70000000\n0.10000000 0.10000000 -1.00000000\n0.10000000 0.10000000 -0.90000000\n0.10000000 0.10000000 -0.80000000\n0.10000000 0.10000000 -0.70000000\n0.10000000 0.10000000 -0.60000000\n0.10000000 0.10000000 -0.50000000\n0.10000000 0.10000000 -0.40000000\n0.10000000 0.10000000 -0.30000000\n0.10000000 0.10000000 -0.20000000\n0.10000000 0.10000000 -0.10000000\n0.10000000 0.10000000 0.00000000\n0.10000000 0.10000000 0.10000000\n0.10000000 0.10000000 0.20000000\n0.10000000 0.10000000 0.30000000\n0.10000000 0.10000000 0.40000000\n0.10000000 0.10000000 0.50000000\n0.10000000 0.10000000 0.60000000\n0.10000000 0.10000000 0.70000000\n0.10000000 0.10000000 0.80000000\n0.10000000 0.10000000 0.90000000\n0.10000000 0.10000000 1.00000000\n0.10000000 0.10000000 1.10000000\n0.10000000 0.10000000 1.20000000\n0.10000000 0.10000000 1.30000000\n0.10000000 0.10000000 1.40000000\n0.10000000 0.10000000 1.50000000\n0.10000000 0.10000000 1.60000000\n0.10000000 0.10000000 1.70000000\n0.10000000 0.10000000 1.80000000\n0.10000000 0.10000000 1.90000000\n0.10000000 0.10000000 2.00000000\n0.10000000 0.20000000 -1.50000000\n0.10000000 0.20000000 -1.40000000\n0.10000000 0.20000000 -1.30000000\n0.10000000 0.20000000 -1.20000000\n0.10000000 0.20000000 -1.10000000\n0.10000000 0.20000000 2.10000000\n0.10000000 0.30000000 -1.70000000\n0.10000000 0.30000000 -1.60000000\n0.10000000 0.30000000 2.10000000\n0.10000000 0.40000000 -1.80000000\n0.10000000 0.40000000 2.10000000\n0.10000000 0.50000000 -1.90000000\n0.10000000 0.50000000 2.10000000\n0.10000000 0.60000000 -1.90000000\n0.10000000 0.60000000 1.60000000\n0.10000000 0.60000000 1.70000000\n0.10000000 0.60000000 1.80000000\n0.10000000 0.60000000 1.90000000\n0.10000000 0.60000000 2.00000000\n0.10000000 0.70000000 -1.90000000\n0.10000000 0.70000000 1.10000000\n0.10000000 0.70000000 1.20000000\n0.10000000 0.70000000 1.30000000\n0.10000000 0.70000000 1.40000000\n0.10000000 0.70000000 1.50000000\n0.10000000 0.80000000 -1.90000000\n0.10000000 0.80000000 0.10000000\n0.10000000 0.80000000 0.20000000\n0.10000000 0.80000000 0.30000000\n0.10000000 0.80000000 0.40000000\n0.10000000 0.80000000 0.50000000\n0.10000000 0.80000000 0.60000000\n0.10000000 0.80000000 0.70000000\n0.10000000 0.80000000 0.80000000\n0.10000000 0.80000000 0.90000000\n0.10000000 0.80000000 1.00000000\n0.10000000 0.90000000 -1.90000000\n0.10000000 0.90000000 0.00000000\n0.10000000 1.00000000 -1.80000000\n0.10000000 1.00000000 -1.70000000\n0.10000000 1.00000000 -0.20000000\n0.10000000 1.00000000 -0.10000000\n0.10000000 1.10000000 -1.60000000\n0.10000000 1.10000000 -1.50000000\n0.10000000 1.10000000 -1.40000000\n0.10000000 1.10000000 -1.30000000\n0.10000000 1.10000000 -0.60000000\n0.10000000 1.10000000 -0.50000000\n0.10000000 1.10000000 -0.40000000\n0.10000000 1.10000000 -0.30000000\n0.10000000 1.20000000 -1.20000000\n0.10000000 1.20000000 -1.10000000\n0.10000000 1.20000000 -1.00000000\n0.10000000 1.20000000 -0.90000000\n0.10000000 1.20000000 -0.80000000\n0.10000000 1.20000000 -0.70000000\n0.20000000 0.10000000 -1.00000000\n0.20000000 0.10000000 -0.90000000\n0.20000000 0.10000000 -0.80000000\n0.20000000 0.10000000 -0.70000000\n0.20000000 0.10000000 -0.60000000\n0.20000000 0.10000000 -0.50000000\n0.20000000 0.10000000 -0.40000000\n0.20000000 0.10000000 -0.30000000\n0.20000000 0.10000000 -0.20000000\n0.20000000 0.10000000 -0.10000000\n0.20000000 0.10000000 0.00000000\n0.20000000 0.10000000 0.10000000\n0.20000000 0.10000000 0.20000000\n0.20000000 0.10000000 0.30000000\n0.20000000 0.10000000 0.40000000\n0.20000000 0.10000000 0.50000000\n0.20000000 0.10000000 0.60000000\n0.20000000 0.10000000 0.70000000\n0.20000000 0.10000000 0.80000000\n0.20000000 0.10000000 0.90000000\n0.20000000 0.10000000 1.00000000\n0.20000000 0.10000000 1.10000000\n0.20000000 0.10000000 1.20000000\n0.20000000 0.10000000 1.30000000\n0.20000000 0.10000000 1.40000000\n0.20000000 0.10000000 1.50000000\n0.20000000 0.10000000 1.60000000\n0.20000000 0.10000000 1.70000000\n0.20000000 0.10000000 1.80000000\n0.20000000 0.10000000 1.90000000\n0.20000000 0.10000000 2.00000000\n0.20000000 0.20000000 -1.50000000\n0.20000000 0.20000000 -1.40000000\n0.20000000 0.20000000 -1.30000000\n0.20000000 0.20000000 -1.20000000\n0.20000000 0.20000000 -1.10000000\n0.20000000 0.20000000 2.10000000\n0.20000000 0.30000000 -1.70000000\n0.20000000 0.30000000 -1.60000000\n0.20000000 0.30000000 2.10000000\n0.20000000 0.40000000 -1.80000000\n0.20000000 0.40000000 2.10000000\n0.20000000 0.50000000 -1.90000000\n0.20000000 0.50000000 2.10000000\n0.20000000 0.60000000 -1.90000000\n0.20000000 0.60000000 1.50000000\n0.20000000 0.60000000 1.60000000\n0.20000000 0.60000000 1.70000000\n0.20000000 0.60000000 1.80000000\n0.20000000 0.60000000 1.90000000\n0.20000000 0.60000000 2.00000000\n0.20000000 0.70000000 -1.90000000\n0.20000000 0.70000000 0.90000000\n0.20000000 0.70000000 1.00000000\n0.20000000 0.70000000 1.10000000\n0.20000000 0.70000000 1.20000000\n0.20000000 0.70000000 1.30000000\n0.20000000 0.70000000 1.40000000\n0.20000000 0.80000000 -1.90000000\n0.20000000 0.80000000 0.10000000\n0.20000000 0.80000000 0.20000000\n0.20000000 0.80000000 0.30000000\n0.20000000 0.80000000 0.40000000\n0.20000000 0.80000000 0.50000000\n0.20000000 0.80000000 0.60000000\n0.20000000 0.80000000 0.70000000\n0.20000000 0.80000000 0.80000000\n0.20000000 0.90000000 -1.90000000\n0.20000000 0.90000000 0.00000000\n0.20000000 1.00000000 -1.80000000\n0.20000000 1.00000000 -1.70000000\n0.20000000 1.00000000 -0.20000000\n0.20000000 1.00000000 -0.10000000\n0.20000000 1.10000000 -1.60000000\n0.20000000 1.10000000 -1.50000000\n0.20000000 1.10000000 -1.40000000\n0.20000000 1.10000000 -1.30000000\n0.20000000 1.10000000 -1.20000000\n0.20000000 1.10000000 -0.70000000\n0.20000000 1.10000000 -0.60000000\n0.20000000 1.10000000 -0.50000000\n0.20000000 1.10000000 -0.40000000\n0.20000000 1.10000000 -0.30000000\n0.20000000 1.20000000 -1.10000000\n0.20000000 1.20000000 -1.00000000\n0.20000000 1.20000000 -0.90000000\n0.20000000 1.20000000 -0.80000000\n0.30000000 0.10000000 -0.80000000\n0.30000000 0.10000000 -0.70000000\n0.30000000 0.10000000 -0.60000000\n0.30000000 0.10000000 -0.50000000\n0.30000000 0.10000000 -0.40000000\n0.30000000 0.10000000 -0.30000000\n0.30000000 0.10000000 -0.20000000\n0.30000000 0.10000000 -0.10000000\n0.30000000 0.10000000 0.00000000\n0.30000000 0.10000000 0.10000000\n0.30000000 0.10000000 0.20000000\n0.30000000 0.10000000 0.30000000\n0.30000000 0.10000000 0.40000000\n0.30000000 0.10000000 0.50000000\n0.30000000 0.10000000 0.60000000\n0.30000000 0.10000000 0.70000000\n0.30000000 0.10000000 0.80000000\n0.30000000 0.10000000 0.90000000\n0.30000000 0.10000000 1.50000000\n0.30000000 0.10000000 1.60000000\n0.30000000 0.10000000 1.70000000\n0.30000000 0.10000000 1.80000000\n0.30000000 0.10000000 1.90000000\n0.30000000 0.10000000 2.00000000\n0.30000000 0.20000000 -1.40000000\n0.30000000 0.20000000 -1.30000000\n0.30000000 0.20000000 -1.20000000\n0.30000000 0.20000000 -1.10000000\n0.30000000 0.20000000 -1.00000000\n0.30000000 0.20000000 -0.90000000\n0.30000000 0.20000000 1.00000000\n0.30000000 0.20000000 1.10000000\n0.30000000 0.20000000 1.20000000\n0.30000000 0.20000000 1.30000000\n0.30000000 0.20000000 1.40000000\n0.30000000 0.20000000 2.10000000\n0.30000000 0.30000000 -1.60000000\n0.30000000 0.30000000 -1.50000000\n0.30000000 0.30000000 2.10000000\n0.30000000 0.40000000 -1.80000000\n0.30000000 0.40000000 -1.70000000\n0.30000000 0.40000000 2.10000000\n0.30000000 0.50000000 -1.90000000\n0.30000000 0.50000000 2.10000000\n0.30000000 0.60000000 -1.90000000\n0.30000000 0.60000000 1.20000000\n0.30000000 0.60000000 1.30000000\n0.30000000 0.60000000 1.40000000\n0.30000000 0.60000000 1.50000000\n0.30000000 0.60000000 1.60000000\n0.30000000 0.60000000 1.70000000\n0.30000000 0.60000000 1.80000000\n0.30000000 0.60000000 1.90000000\n0.30000000 0.60000000 2.00000000\n0.30000000 0.70000000 -1.90000000\n0.30000000 0.70000000 0.50000000\n0.30000000 0.70000000 0.60000000\n0.30000000 0.70000000 0.70000000\n0.30000000 0.70000000 0.80000000\n0.30000000 0.70000000 0.90000000\n0.30000000 0.70000000 1.00000000\n0.30000000 0.70000000 1.10000000\n0.30000000 0.80000000 -1.90000000\n0.30000000 0.80000000 0.10000000\n0.30000000 0.80000000 0.20000000\n0.30000000 0.80000000 0.30000000\n0.30000000 0.80000000 0.40000000\n0.30000000 0.90000000 -1.80000000\n0.30000000 0.90000000 0.00000000\n0.30000000 1.00000000 -1.70000000\n0.30000000 1.00000000 -1.60000000\n0.30000000 1.00000000 -0.30000000\n0.30000000 1.00000000 -0.20000000\n0.30000000 1.00000000 -0.10000000\n0.30000000 1.10000000 -1.50000000\n0.30000000 1.10000000 -1.40000000\n0.30000000 1.10000000 -1.30000000\n0.30000000 1.10000000 -1.20000000\n0.30000000 1.10000000 -0.80000000\n0.30000000 1.10000000 -0.70000000\n0.30000000 1.10000000 -0.60000000\n0.30000000 1.10000000 -0.50000000\n0.30000000 1.10000000 -0.40000000\n0.30000000 1.20000000 -1.10000000\n0.30000000 1.20000000 -1.00000000\n0.30000000 1.20000000 -0.90000000\n0.40000000 0.10000000 -0.70000000\n0.40000000 0.10000000 -0.60000000\n0.40000000 0.10000000 -0.50000000\n0.40000000 0.10000000 -0.40000000\n0.40000000 0.10000000 -0.30000000\n0.40000000 0.10000000 -0.20000000\n0.40000000 0.10000000 -0.10000000\n0.40000000 0.10000000 0.00000000\n0.40000000 0.10000000 0.10000000\n0.40000000 0.10000000 0.20000000\n0.40000000 0.10000000 0.30000000\n0.40000000 0.10000000 0.40000000\n0.40000000 0.10000000 0.50000000\n0.40000000 0.10000000 0.60000000\n0.40000000 0.10000000 0.70000000\n0.40000000 0.10000000 0.80000000\n0.40000000 0.10000000 1.60000000\n0.40000000 0.10000000 1.70000000\n0.40000000 0.10000000 1.80000000\n0.40000000 0.10000000 1.90000000\n0.40000000 0.20000000 -1.40000000\n0.40000000 0.20000000 -1.30000000\n0.40000000 0.20000000 -1.20000000\n0.40000000 0.20000000 -1.10000000\n0.40000000 0.20000000 -1.00000000\n0.40000000 0.20000000 -0.90000000\n0.40000000 0.20000000 -0.80000000\n0.40000000 0.20000000 0.90000000\n0.40000000 0.20000000 1.00000000\n0.40000000 0.20000000 1.10000000\n0.40000000 0.20000000 1.20000000\n0.40000000 0.20000000 1.40000000\n0.40000000 0.20000000 1.50000000\n0.40000000 0.20000000 2.00000000\n0.40000000 0.20000000 2.10000000\n0.40000000 0.30000000 -1.60000000\n0.40000000 0.30000000 -1.50000000\n0.40000000 0.30000000 1.30000000\n0.40000000 0.30000000 2.10000000\n0.40000000 0.40000000 -1.70000000\n0.40000000 0.40000000 2.10000000\n0.40000000 0.50000000 -1.80000000\n0.40000000 0.50000000 1.30000000\n0.40000000 0.50000000 1.40000000\n0.40000000 0.50000000 2.10000000\n0.40000000 0.60000000 -1.90000000\n0.40000000 0.60000000 0.90000000\n0.40000000 0.60000000 1.00000000\n0.40000000 0.60000000 1.10000000\n0.40000000 0.60000000 1.20000000\n0.40000000 0.60000000 1.50000000\n0.40000000 0.60000000 1.60000000\n0.40000000 0.60000000 1.70000000\n0.40000000 0.60000000 1.80000000\n0.40000000 0.60000000 1.90000000\n0.40000000 0.60000000 2.00000000\n0.40000000 0.70000000 -1.90000000\n0.40000000 0.70000000 0.30000000\n0.40000000 0.70000000 0.40000000\n0.40000000 0.70000000 0.50000000\n0.40000000 0.70000000 0.60000000\n0.40000000 0.70000000 0.70000000\n0.40000000 0.70000000 0.80000000\n0.40000000 0.80000000 -1.80000000\n0.40000000 0.80000000 0.00000000\n0.40000000 0.80000000 0.10000000\n0.40000000 0.80000000 0.20000000\n0.40000000 0.90000000 -1.80000000\n0.40000000 0.90000000 -0.10000000\n0.40000000 1.00000000 -1.70000000\n0.40000000 1.00000000 -1.60000000\n0.40000000 1.00000000 -0.30000000\n0.40000000 1.00000000 -0.20000000\n0.40000000 1.10000000 -1.50000000\n0.40000000 1.10000000 -1.40000000\n0.40000000 1.10000000 -1.30000000\n0.40000000 1.10000000 -1.20000000\n0.40000000 1.10000000 -1.10000000\n0.40000000 1.10000000 -1.00000000\n0.40000000 1.10000000 -0.90000000\n0.40000000 1.10000000 -0.80000000\n0.40000000 1.10000000 -0.70000000\n0.40000000 1.10000000 -0.60000000\n0.40000000 1.10000000 -0.50000000\n0.40000000 1.10000000 -0.40000000\n0.50000000 0.10000000 -0.50000000\n0.50000000 0.10000000 -0.40000000\n0.50000000 0.10000000 -0.30000000\n0.50000000 0.10000000 -0.20000000\n0.50000000 0.10000000 -0.10000000\n0.50000000 0.10000000 0.00000000\n0.50000000 0.10000000 0.10000000\n0.50000000 0.10000000 0.20000000\n0.50000000 0.10000000 0.30000000\n0.50000000 0.10000000 0.40000000\n0.50000000 0.10000000 0.50000000\n0.50000000 0.10000000 0.60000000\n0.50000000 0.10000000 1.60000000\n0.50000000 0.10000000 1.70000000\n0.50000000 0.10000000 1.80000000\n0.50000000 0.10000000 1.90000000\n0.50000000 0.20000000 -1.30000000\n0.50000000 0.20000000 -1.20000000\n0.50000000 0.20000000 -1.10000000\n0.50000000 0.20000000 -1.00000000\n0.50000000 0.20000000 -0.90000000\n0.50000000 0.20000000 -0.80000000\n0.50000000 0.20000000 -0.70000000\n0.50000000 0.20000000 -0.60000000\n0.50000000 0.20000000 0.70000000\n0.50000000 0.20000000 0.80000000\n0.50000000 0.20000000 0.90000000\n0.50000000 0.20000000 1.00000000\n0.50000000 0.20000000 1.10000000\n0.50000000 0.20000000 1.50000000\n0.50000000 0.20000000 2.00000000\n0.50000000 0.20000000 2.10000000\n0.50000000 0.30000000 -1.50000000\n0.50000000 0.30000000 -1.40000000\n0.50000000 0.30000000 1.20000000\n0.50000000 0.30000000 1.30000000\n0.50000000 0.30000000 1.40000000\n0.50000000 0.30000000 2.10000000\n0.50000000 0.40000000 -1.70000000\n0.50000000 0.40000000 -1.60000000\n0.50000000 0.40000000 1.30000000\n0.50000000 0.40000000 1.40000000\n0.50000000 0.40000000 2.10000000\n0.50000000 0.50000000 -1.80000000\n0.50000000 0.50000000 1.20000000\n0.50000000 0.50000000 1.40000000\n0.50000000 0.50000000 2.10000000\n0.50000000 0.60000000 -1.80000000\n0.50000000 0.60000000 0.80000000\n0.50000000 0.60000000 0.90000000\n0.50000000 0.60000000 1.00000000\n0.50000000 0.60000000 1.10000000\n0.50000000 0.60000000 1.50000000\n0.50000000 0.60000000 1.60000000\n0.50000000 0.60000000 1.70000000\n0.50000000 0.60000000 1.80000000\n0.50000000 0.60000000 1.90000000\n0.50000000 0.60000000 2.00000000\n0.50000000 0.70000000 -1.80000000\n0.50000000 0.70000000 0.20000000\n0.50000000 0.70000000 0.30000000\n0.50000000 0.70000000 0.40000000\n0.50000000 0.70000000 0.50000000\n0.50000000 0.70000000 0.60000000\n0.50000000 0.70000000 0.70000000\n0.50000000 0.80000000 -1.80000000\n0.50000000 0.80000000 0.00000000\n0.50000000 0.80000000 0.10000000\n0.50000000 0.90000000 -1.70000000\n0.50000000 0.90000000 -0.20000000\n0.50000000 0.90000000 -0.10000000\n0.50000000 1.00000000 -1.60000000\n0.50000000 1.00000000 -1.50000000\n0.50000000 1.00000000 -0.40000000\n0.50000000 1.00000000 -0.30000000\n0.50000000 1.10000000 -1.40000000\n0.50000000 1.10000000 -1.30000000\n0.50000000 1.10000000 -1.20000000\n0.50000000 1.10000000 -1.10000000\n0.50000000 1.10000000 -1.00000000\n0.50000000 1.10000000 -0.90000000\n0.50000000 1.10000000 -0.80000000\n0.50000000 1.10000000 -0.70000000\n0.50000000 1.10000000 -0.60000000\n0.50000000 1.10000000 -0.50000000\n0.60000000 0.10000000 -0.10000000\n0.60000000 0.10000000 0.00000000\n0.60000000 0.10000000 0.10000000\n0.60000000 0.10000000 0.20000000\n0.60000000 0.10000000 0.30000000\n0.60000000 0.10000000 1.70000000\n0.60000000 0.10000000 1.80000000\n0.60000000 0.20000000 -1.10000000\n0.60000000 0.20000000 -1.00000000\n0.60000000 0.20000000 -0.90000000\n0.60000000 0.20000000 -0.80000000\n0.60000000 0.20000000 -0.70000000\n0.60000000 0.20000000 -0.60000000\n0.60000000 0.20000000 -0.50000000\n0.60000000 0.20000000 -0.40000000\n0.60000000 0.20000000 -0.30000000\n0.60000000 0.20000000 -0.20000000\n0.60000000 0.20000000 0.40000000\n0.60000000 0.20000000 0.50000000\n0.60000000 0.20000000 0.60000000\n0.60000000 0.20000000 0.70000000\n0.60000000 0.20000000 0.80000000\n0.60000000 0.20000000 0.90000000\n0.60000000 0.20000000 1.00000000\n0.60000000 0.20000000 1.50000000\n0.60000000 0.20000000 1.60000000\n0.60000000 0.20000000 1.90000000\n0.60000000 0.20000000 2.00000000\n0.60000000 0.30000000 -1.40000000\n0.60000000 0.30000000 -1.30000000\n0.60000000 0.30000000 -1.20000000\n0.60000000 0.30000000 1.10000000\n0.60000000 0.30000000 1.20000000\n0.60000000 0.30000000 1.50000000\n0.60000000 0.30000000 2.10000000\n0.60000000 0.40000000 -1.60000000\n0.60000000 0.40000000 -1.50000000\n0.60000000 0.40000000 1.10000000\n0.60000000 0.40000000 1.20000000\n0.60000000 0.40000000 1.50000000\n0.60000000 0.40000000 2.10000000\n0.60000000 0.50000000 -1.70000000\n0.60000000 0.50000000 1.00000000\n0.60000000 0.50000000 1.10000000\n0.60000000 0.50000000 1.50000000\n0.60000000 0.50000000 2.00000000\n0.60000000 0.60000000 -1.80000000\n0.60000000 0.60000000 0.70000000\n0.60000000 0.60000000 0.80000000\n0.60000000 0.60000000 0.90000000\n0.60000000 0.60000000 1.60000000\n0.60000000 0.60000000 1.70000000\n0.60000000 0.60000000 1.80000000\n0.60000000 0.60000000 1.90000000\n0.60000000 0.70000000 -1.80000000\n0.60000000 0.70000000 0.00000000\n0.60000000 0.70000000 0.10000000\n0.60000000 0.70000000 0.20000000\n0.60000000 0.70000000 0.30000000\n0.60000000 0.70000000 0.40000000\n0.60000000 0.70000000 0.50000000\n0.60000000 0.70000000 0.60000000\n0.60000000 0.80000000 -1.70000000\n0.60000000 0.80000000 -0.10000000\n0.60000000 0.90000000 -1.70000000\n0.60000000 0.90000000 -0.20000000\n0.60000000 1.00000000 -1.60000000\n0.60000000 1.00000000 -1.50000000\n0.60000000 1.00000000 -1.40000000\n0.60000000 1.00000000 -0.60000000\n0.60000000 1.00000000 -0.50000000\n0.60000000 1.00000000 -0.40000000\n0.60000000 1.00000000 -0.30000000\n0.60000000 1.10000000 -1.30000000\n0.60000000 1.10000000 -1.20000000\n0.60000000 1.10000000 -1.10000000\n0.60000000 1.10000000 -1.00000000\n0.60000000 1.10000000 -0.90000000\n0.60000000 1.10000000 -0.80000000\n0.60000000 1.10000000 -0.70000000\n0.70000000 0.10000000 -1.30000000\n0.70000000 0.10000000 -1.20000000\n0.70000000 0.10000000 -1.10000000\n0.70000000 0.10000000 1.60000000\n0.70000000 0.10000000 1.70000000\n0.70000000 0.10000000 1.80000000\n0.70000000 0.10000000 1.90000000\n0.70000000 0.20000000 -1.40000000\n0.70000000 0.20000000 -1.30000000\n0.70000000 0.20000000 -1.20000000\n0.70000000 0.20000000 -1.00000000\n0.70000000 0.20000000 -0.90000000\n0.70000000 0.20000000 -0.80000000\n0.70000000 0.20000000 -0.70000000\n0.70000000 0.20000000 -0.60000000\n0.70000000 0.20000000 -0.50000000\n0.70000000 0.20000000 -0.40000000\n0.70000000 0.20000000 -0.30000000\n0.70000000 0.20000000 -0.20000000\n0.70000000 0.20000000 -0.10000000\n0.70000000 0.20000000 0.00000000\n0.70000000 0.20000000 0.10000000\n0.70000000 0.20000000 0.20000000\n0.70000000 0.20000000 0.30000000\n0.70000000 0.20000000 0.40000000\n0.70000000 0.20000000 0.50000000\n0.70000000 0.20000000 0.60000000\n0.70000000 0.20000000 0.70000000\n0.70000000 0.20000000 0.80000000\n0.70000000 0.20000000 1.50000000\n0.70000000 0.20000000 2.00000000\n0.70000000 0.30000000 -1.40000000\n0.70000000 0.30000000 0.90000000\n0.70000000 0.30000000 1.00000000\n0.70000000 0.30000000 1.50000000\n0.70000000 0.30000000 2.10000000\n0.70000000 0.40000000 -1.50000000\n0.70000000 0.40000000 0.90000000\n0.70000000 0.40000000 1.00000000\n0.70000000 0.40000000 1.50000000\n0.70000000 0.40000000 2.10000000\n0.70000000 0.50000000 -1.60000000\n0.70000000 0.50000000 0.90000000\n0.70000000 0.50000000 1.00000000\n0.70000000 0.50000000 1.50000000\n0.70000000 0.50000000 2.00000000\n0.70000000 0.60000000 -1.70000000\n0.70000000 0.60000000 0.50000000\n0.70000000 0.60000000 0.60000000\n0.70000000 0.60000000 0.70000000\n0.70000000 0.60000000 0.80000000\n0.70000000 0.60000000 1.60000000\n0.70000000 0.60000000 1.70000000\n0.70000000 0.60000000 1.80000000\n0.70000000 0.60000000 1.90000000\n0.70000000 0.70000000 -1.70000000\n0.70000000 0.70000000 -0.10000000\n0.70000000 0.70000000 0.00000000\n0.70000000 0.70000000 0.10000000\n0.70000000 0.70000000 0.20000000\n0.70000000 0.70000000 0.30000000\n0.70000000 0.70000000 0.40000000\n0.70000000 0.80000000 -1.70000000\n0.70000000 0.80000000 -0.20000000\n0.70000000 0.90000000 -1.60000000\n0.70000000 0.90000000 -1.50000000\n0.70000000 0.90000000 -0.30000000\n0.70000000 1.00000000 -1.40000000\n0.70000000 1.00000000 -1.30000000\n0.70000000 1.00000000 -1.20000000\n0.70000000 1.00000000 -1.10000000\n0.70000000 1.00000000 -0.90000000\n0.70000000 1.00000000 -0.80000000\n0.70000000 1.00000000 -0.70000000\n0.70000000 1.00000000 -0.60000000\n0.70000000 1.00000000 -0.50000000\n0.70000000 1.00000000 -0.40000000\n0.70000000 1.10000000 -1.00000000\n0.80000000 0.00000000 -1.40000000\n0.80000000 0.00000000 -1.30000000\n0.80000000 0.00000000 -1.20000000\n0.80000000 0.00000000 -1.10000000\n0.80000000 0.00000000 -1.00000000\n0.80000000 0.00000000 1.60000000\n0.80000000 0.00000000 1.70000000\n0.80000000 0.00000000 1.80000000\n0.80000000 0.00000000 1.90000000\n0.80000000 0.00000000 2.00000000\n0.80000000 0.10000000 -1.50000000\n0.80000000 0.10000000 -1.40000000\n0.80000000 0.10000000 -1.00000000\n0.80000000 0.10000000 -0.90000000\n0.80000000 0.10000000 1.50000000\n0.80000000 0.10000000 2.00000000\n0.80000000 0.10000000 2.10000000\n0.80000000 0.20000000 -1.50000000\n0.80000000 0.20000000 -0.90000000\n0.80000000 0.20000000 -0.60000000\n0.80000000 0.20000000 -0.50000000\n0.80000000 0.20000000 -0.40000000\n0.80000000 0.20000000 -0.30000000\n0.80000000 0.20000000 -0.20000000\n0.80000000 0.20000000 -0.10000000\n0.80000000 0.20000000 0.00000000\n0.80000000 0.20000000 0.10000000\n0.80000000 0.20000000 0.20000000\n0.80000000 0.20000000 0.30000000\n0.80000000 0.20000000 0.40000000\n0.80000000 0.20000000 0.50000000\n0.80000000 0.20000000 1.40000000\n0.80000000 0.20000000 2.10000000\n0.80000000 0.30000000 -1.60000000\n0.80000000 0.30000000 -1.50000000\n0.80000000 0.30000000 -0.80000000\n0.80000000 0.30000000 -0.70000000\n0.80000000 0.30000000 0.60000000\n0.80000000 0.30000000 0.70000000\n0.80000000 0.30000000 0.80000000\n0.80000000 0.30000000 1.40000000\n0.80000000 0.30000000 2.10000000\n0.80000000 0.40000000 -1.60000000\n0.80000000 0.40000000 0.70000000\n0.80000000 0.40000000 0.80000000\n0.80000000 0.40000000 1.40000000\n0.80000000 0.40000000 2.10000000\n0.80000000 0.50000000 -1.50000000\n0.80000000 0.50000000 0.60000000\n0.80000000 0.50000000 0.70000000\n0.80000000 0.50000000 0.80000000\n0.80000000 0.50000000 1.40000000\n0.80000000 0.50000000 2.10000000\n0.80000000 0.60000000 -1.60000000\n0.80000000 0.60000000 0.20000000\n0.80000000 0.60000000 0.30000000\n0.80000000 0.60000000 0.40000000\n0.80000000 0.60000000 0.50000000\n0.80000000 0.60000000 0.60000000\n0.80000000 0.60000000 1.50000000\n0.80000000 0.60000000 2.00000000\n0.80000000 0.60000000 2.10000000\n0.80000000 0.70000000 -1.60000000\n0.80000000 0.70000000 -0.20000000\n0.80000000 0.70000000 -0.10000000\n0.80000000 0.70000000 0.00000000\n0.80000000 0.70000000 0.10000000\n0.80000000 0.70000000 1.60000000\n0.80000000 0.70000000 1.70000000\n0.80000000 0.70000000 1.80000000\n0.80000000 0.70000000 1.90000000\n0.80000000 0.70000000 2.00000000\n0.80000000 0.80000000 -1.60000000\n0.80000000 0.80000000 -1.50000000\n0.80000000 0.80000000 -0.30000000\n0.80000000 0.90000000 -1.50000000\n0.80000000 0.90000000 -1.40000000\n0.80000000 0.90000000 -0.50000000\n0.80000000 0.90000000 -0.40000000\n0.80000000 1.00000000 -1.30000000\n0.80000000 1.00000000 -1.20000000\n0.80000000 1.00000000 -1.10000000\n0.80000000 1.00000000 -1.00000000\n0.80000000 1.00000000 -0.90000000\n0.80000000 1.00000000 -0.80000000\n0.80000000 1.00000000 -0.70000000\n0.80000000 1.00000000 -0.60000000\n0.90000000 0.00000000 -1.40000000\n0.90000000 0.00000000 -1.30000000\n0.90000000 0.00000000 -1.20000000\n0.90000000 0.00000000 -1.10000000\n0.90000000 0.00000000 -1.00000000\n0.90000000 0.00000000 1.60000000\n0.90000000 0.00000000 1.70000000\n0.90000000 0.00000000 1.80000000\n0.90000000 0.00000000 1.90000000\n0.90000000 0.00000000 2.00000000\n0.90000000 0.10000000 -1.50000000\n0.90000000 0.10000000 -0.90000000\n0.90000000 0.10000000 1.50000000\n0.90000000 0.10000000 2.10000000\n0.90000000 0.20000000 -1.60000000\n0.90000000 0.20000000 -0.90000000\n0.90000000 0.20000000 1.40000000\n0.90000000 0.20000000 2.10000000\n0.90000000 0.30000000 -1.60000000\n0.90000000 0.30000000 -0.80000000\n0.90000000 0.30000000 -0.70000000\n0.90000000 0.30000000 -0.60000000\n0.90000000 0.30000000 -0.50000000\n0.90000000 0.30000000 -0.40000000\n0.90000000 0.30000000 -0.30000000\n0.90000000 0.30000000 -0.20000000\n0.90000000 0.30000000 -0.10000000\n0.90000000 0.30000000 0.00000000\n0.90000000 0.30000000 0.10000000\n0.90000000 0.30000000 0.20000000\n0.90000000 0.30000000 0.30000000\n0.90000000 0.30000000 0.40000000\n0.90000000 0.30000000 0.50000000\n0.90000000 0.30000000 1.40000000\n0.90000000 0.30000000 2.10000000\n0.90000000 0.40000000 -1.60000000\n0.90000000 0.40000000 -0.80000000\n0.90000000 0.40000000 -0.70000000\n0.90000000 0.40000000 -0.60000000\n0.90000000 0.40000000 0.20000000\n0.90000000 0.40000000 0.30000000\n0.90000000 0.40000000 0.40000000\n0.90000000 0.40000000 0.50000000\n0.90000000 0.40000000 0.60000000\n0.90000000 0.40000000 1.40000000\n0.90000000 0.40000000 2.10000000\n0.90000000 0.50000000 -1.60000000\n0.90000000 0.50000000 0.20000000\n0.90000000 0.50000000 0.30000000\n0.90000000 0.50000000 0.40000000\n0.90000000 0.50000000 0.50000000\n0.90000000 0.50000000 1.40000000\n0.90000000 0.50000000 2.10000000\n0.90000000 0.60000000 -1.50000000\n0.90000000 0.60000000 -0.40000000\n0.90000000 0.60000000 -0.30000000\n0.90000000 0.60000000 -0.20000000\n0.90000000 0.60000000 -0.10000000\n0.90000000 0.60000000 0.00000000\n0.90000000 0.60000000 0.10000000\n0.90000000 0.60000000 0.20000000\n0.90000000 0.60000000 0.30000000\n0.90000000 0.60000000 1.50000000\n0.90000000 0.60000000 2.10000000\n0.90000000 0.70000000 -1.50000000\n0.90000000 0.70000000 -1.40000000\n0.90000000 0.70000000 -0.40000000\n0.90000000 0.70000000 -0.30000000\n0.90000000 0.70000000 1.60000000\n0.90000000 0.70000000 1.70000000\n0.90000000 0.70000000 1.80000000\n0.90000000 0.70000000 1.90000000\n0.90000000 0.70000000 2.00000000\n0.90000000 0.80000000 -1.40000000\n0.90000000 0.80000000 -1.30000000\n0.90000000 0.80000000 -0.50000000\n0.90000000 0.80000000 -0.40000000\n0.90000000 0.90000000 -1.30000000\n0.90000000 0.90000000 -1.20000000\n0.90000000 0.90000000 -1.10000000\n0.90000000 0.90000000 -1.00000000\n0.90000000 0.90000000 -0.90000000\n0.90000000 0.90000000 -0.80000000\n0.90000000 0.90000000 -0.70000000\n0.90000000 0.90000000 -0.60000000\n0.90000000 0.90000000 -0.50000000\n1.00000000 0.00000000 -1.30000000\n1.00000000 0.00000000 -1.20000000\n1.00000000 0.00000000 -1.10000000\n1.00000000 0.00000000 1.70000000\n1.00000000 0.00000000 1.80000000\n1.00000000 0.10000000 -1.40000000\n1.00000000 0.10000000 -1.30000000\n1.00000000 0.10000000 -1.20000000\n1.00000000 0.10000000 -1.10000000\n1.00000000 0.10000000 -1.00000000\n1.00000000 0.10000000 1.50000000\n1.00000000 0.10000000 1.60000000\n1.00000000 0.10000000 1.70000000\n1.00000000 0.10000000 1.80000000\n1.00000000 0.10000000 1.90000000\n1.00000000 0.10000000 2.00000000\n1.00000000 0.20000000 -1.50000000\n1.00000000 0.20000000 -1.40000000\n1.00000000 0.20000000 -1.00000000\n1.00000000 0.20000000 -0.90000000\n1.00000000 0.20000000 1.50000000\n1.00000000 0.20000000 1.60000000\n1.00000000 0.20000000 1.70000000\n1.00000000 0.20000000 1.80000000\n1.00000000 0.20000000 1.90000000\n1.00000000 0.20000000 2.00000000\n1.00000000 0.20000000 2.10000000\n1.00000000 0.30000000 -1.50000000\n1.00000000 0.30000000 -1.40000000\n1.00000000 0.30000000 -1.00000000\n1.00000000 0.30000000 -0.90000000\n1.00000000 0.30000000 1.50000000\n1.00000000 0.30000000 1.60000000\n1.00000000 0.30000000 1.70000000\n1.00000000 0.30000000 1.80000000\n1.00000000 0.30000000 1.90000000\n1.00000000 0.30000000 2.00000000\n1.00000000 0.30000000 2.10000000\n1.00000000 0.40000000 -1.50000000\n1.00000000 0.40000000 -1.00000000\n1.00000000 0.40000000 -0.90000000\n1.00000000 0.40000000 -0.50000000\n1.00000000 0.40000000 -0.40000000\n1.00000000 0.40000000 -0.30000000\n1.00000000 0.40000000 -0.20000000\n1.00000000 0.40000000 -0.10000000\n1.00000000 0.40000000 0.00000000\n1.00000000 0.40000000 0.10000000\n1.00000000 0.40000000 1.50000000\n1.00000000 0.40000000 1.60000000\n1.00000000 0.40000000 1.70000000\n1.00000000 0.40000000 1.80000000\n1.00000000 0.40000000 1.90000000\n1.00000000 0.40000000 2.00000000\n1.00000000 0.40000000 2.10000000\n1.00000000 0.50000000 -1.50000000\n1.00000000 0.50000000 -1.40000000\n1.00000000 0.50000000 -1.00000000\n1.00000000 0.50000000 -0.90000000\n1.00000000 0.50000000 -0.80000000\n1.00000000 0.50000000 -0.70000000\n1.00000000 0.50000000 -0.60000000\n1.00000000 0.50000000 -0.50000000\n1.00000000 0.50000000 -0.40000000\n1.00000000 0.50000000 -0.30000000\n1.00000000 0.50000000 -0.20000000\n1.00000000 0.50000000 -0.10000000\n1.00000000 0.50000000 0.00000000\n1.00000000 0.50000000 0.10000000\n1.00000000 0.50000000 1.50000000\n1.00000000 0.50000000 1.60000000\n1.00000000 0.50000000 1.70000000\n1.00000000 0.50000000 1.80000000\n1.00000000 0.50000000 1.90000000\n1.00000000 0.50000000 2.00000000\n1.00000000 0.50000000 2.10000000\n1.00000000 0.60000000 -1.50000000\n1.00000000 0.60000000 -1.40000000\n1.00000000 0.60000000 -1.30000000\n1.00000000 0.60000000 -1.20000000\n1.00000000 0.60000000 -1.10000000\n1.00000000 0.60000000 -1.00000000\n1.00000000 0.60000000 -0.90000000\n1.00000000 0.60000000 -0.80000000\n1.00000000 0.60000000 -0.70000000\n1.00000000 0.60000000 -0.60000000\n1.00000000 0.60000000 -0.50000000\n1.00000000 0.60000000 1.50000000\n1.00000000 0.60000000 1.60000000\n1.00000000 0.60000000 1.70000000\n1.00000000 0.60000000 1.80000000\n1.00000000 0.60000000 1.90000000\n1.00000000 0.60000000 2.00000000\n1.00000000 0.70000000 -1.30000000\n1.00000000 0.70000000 -1.20000000\n1.00000000 0.70000000 -1.10000000\n1.00000000 0.70000000 -1.00000000\n1.00000000 0.70000000 -0.90000000\n1.00000000 0.70000000 -0.80000000\n1.00000000 0.70000000 -0.70000000\n1.00000000 0.70000000 -0.60000000\n1.00000000 0.70000000 -0.50000000\n1.00000000 0.70000000 1.70000000\n1.00000000 0.70000000 1.80000000\n1.00000000 0.70000000 1.90000000\n1.00000000 0.80000000 -1.20000000\n1.00000000 0.80000000 -1.10000000\n1.00000000 0.80000000 -1.00000000\n1.00000000 0.80000000 -0.90000000\n1.00000000 0.80000000 -0.80000000\n1.00000000 0.80000000 -0.70000000\n1.00000000 0.80000000 -0.60000000\n1.10000000 0.20000000 -1.30000000\n1.10000000 0.20000000 -1.20000000\n1.10000000 0.20000000 -1.10000000\n1.10000000 0.30000000 -1.30000000\n1.10000000 0.30000000 -1.20000000\n1.10000000 0.30000000 -1.10000000\n1.10000000 0.40000000 -1.40000000\n1.10000000 0.40000000 -1.30000000\n1.10000000 0.40000000 -1.20000000\n1.10000000 0.40000000 -1.10000000\n1.10000000 0.50000000 -1.30000000\n1.10000000 0.50000000 -1.20000000\n1.10000000 0.50000000 -1.10000000",    "# X Y Z\n-1.05000000 0.15000000 -1.35000000\n-1.05000000 0.15000000 -1.30000000\n-1.05000000 0.15000000 -1.25000000\n-1.05000000 0.15000000 -1.20000000\n-1.05000000 0.15000000 -1.15000000\n-1.05000000 0.15000000 -1.10000000\n-1.05000000 0.20000000 -1.40000000\n-1.05000000 0.20000000 -1.35000000\n-1.05000000 0.20000000 -1.30000000\n-1.05000000 0.20000000 -1.25000000\n-1.05000000 0.20000000 -1.20000000\n-1.05000000 0.20000000 -1.15000000\n-1.05000000 0.20000000 -1.10000000\n-1.05000000 0.20000000 -1.05000000\n-1.05000000 0.20000000 -1.00000000\n-1.05000000 0.20000000 1.70000000\n-1.05000000 0.20000000 1.75000000\n-1.05000000 0.20000000 1.80000000\n-1.05000000 0.20000000 1.85000000\n-1.05000000 0.25000000 -1.40000000\n-1.05000000 0.25000000 -1.35000000\n-1.05000000 0.25000000 -1.30000000\n-1.05000000 0.25000000 -1.25000000\n-1.05000000 0.25000000 -1.20000000\n-1.05000000 0.25000000 -1.15000000\n-1.05000000 0.25000000 -1.10000000\n-1.05000000 0.25000000 -1.05000000\n-1.05000000 0.25000000 -1.00000000\n-1.05000000 0.25000000 1.65000000\n-1.05000000 0.25000000 1.70000000\n-1.05000000 0.25000000 1.75000000\n-1.05000000 0.25000000 1.80000000\n-1.05000000 0.25000000 1.85000000\n-1.05000000 0.25000000 1.90000000\n-1.05000000 0.30000000 -1.45000000\n-1.05000000 0.30000000 -1.40000000\n-1.05000000 0.30000000 -1.35000000\n-1.05000000 0.30000000 -1.30000000\n-1.05000000 0.30000000 -1.25000000\n-1.05000000 0.30000000 -1.20000000\n-1.05000000 0.30000000 -1.15000000\n-1.05000000 0.30000000 -1.10000000\n-1.05000000 0.30000000 -1.05000000\n-1.05000000 0.30000000 -1.00000000\n-1.05000000 0.30000000 1.65000000\n-1.05000000 0.30000000 1.70000000\n-1.05000000 0.30000000 1.75000000\n-1.05000000 0.30000000 1.80000000\n-1.05000000 0.30000000 1.85000000\n-1.05000000 0.30000000 1.90000000\n-1.05000000 0.30000000 1.95000000\n-1.05000000 0.35000000 -1.45000000\n-1.05000000 0.35000000 -1.40000000\n-1.05000000 0.35000000 -1.35000000\n-1.05000000 0.35000000 -1.30000000\n-1.05000000 0.35000000 -1.25000000\n-1.05000000 0.35000000 -1.20000000\n-1.05000000 0.35000000 -1.15000000\n-1.05000000 0.35000000 -1.10000000\n-1.05000000 0.35000000 -1.05000000\n-1.05000000 0.35000000 -1.00000000\n-1.05000000 0.35000000 1.60000000\n-1.05000000 0.35000000 1.65000000\n-1.05000000 0.35000000 1.70000000\n-1.05000000 0.35000000 1.75000000\n-1.05000000 0.35000000 1.80000000\n-1.05000000 0.35000000 1.85000000\n-1.05000000 0.35000000 1.90000000\n-1.05000000 0.35000000 1.95000000\n-1.05000000 0.40000000 -1.45000000\n-1.05000000 0.40000000 -1.40000000\n-1.05000000 0.40000000 -1.35000000\n-1.05000000 0.40000000 -1.30000000\n-1.05000000 0.40000000 -1.25000000\n-1.05000000 0.40000000 -1.20000000\n-1.05000000 0.40000000 -1.15000000\n-1.05000000 0.40000000 -1.10000000\n-1.05000000 0.40000000 -1.05000000\n-1.05000000 0.40000000 -1.00000000\n-1.05000000 0.40000000 1.65000000\n-1.05000000 0.40000000 1.70000000\n-1.05000000 0.40000000 1.75000000\n-1.05000000 0.40000000 1.80000000\n-1.05000000 0.40000000 1.85000000\n-1.05000000 0.40000000 1.90000000\n-1.05000000 0.40000000 1.95000000\n-1.05000000 0.45000000 -1.40000000\n-1.05000000 0.45000000 -1.35000000\n-1.05000000 0.45000000 -1.30000000\n-1.05000000 0.45000000 -1.25000000\n-1.05000000 0.45000000 -1.20000000\n-1.05000000 0.45000000 -1.15000000\n-1.05000000 0.45000000 -1.10000000\n-1.05000000 0.45000000 -1.05000000\n-1.05000000 0.45000000 -1.00000000\n-1.05000000 0.45000000 1.65000000\n-1.05000000 0.45000000 1.70000000\n-1.05000000 0.45000000 1.75000000\n-1.05000000 0.45000000 1.80000000\n-1.05000000 0.45000000 1.85000000\n-1.05000000 0.45000000 1.90000000\n-1.05000000 0.50000000 -1.40000000\n-1.05000000 0.50000000 -1.35000000\n-1.05000000 0.50000000 -1.30000000\n-1.05000000 0.50000000 -1.25000000\n-1.05000000 0.50000000 -1.20000000\n-1.05000000 0.50000000 -1.15000000\n-1.05000000 0.50000000 -1.10000000\n-1.05000000 0.50000000 -1.05000000\n-1.05000000 0.50000000 -1.00000000\n-1.05000000 0.50000000 1.70000000\n-1.05000000 0.50000000 1.75000000\n-1.05000000 0.50000000 1.80000000\n-1.05000000 0.50000000 1.85000000\n-1.05000000 0.55000000 -1.35000000\n-1.05000000 0.55000000 -1.30000000\n-1.05000000 0.55000000 -1.25000000\n-1.05000000 0.55000000 -1.20000000\n-1.05000000 0.55000000 -1.15000000\n-1.05000000 0.55000000 -1.10000000\n-1.05000000 0.55000000 -1.05000000\n-1.05000000 0.60000000 -1.25000000\n-1.05000000 0.60000000 -1.20000000\n-1.05000000 0.60000000 -1.15000000\n-1.00000000 0.05000000 -1.35000000\n-1.00000000 0.05000000 -1.30000000\n-1.00000000 0.05000000 -1.25000000\n-1.00000000 0.05000000 -1.20000000\n-1.00000000 0.05000000 -1.15000000\n-1.00000000 0.05000000 -1.10000000\n-1.00000000 0.05000000 -1.05000000\n-1.00000000 0.05000000 1.75000000\n-1.00000000 0.05000000 1.80000000\n-1.00000000 0.10000000 -1.40000000\n-1.00000000 0.10000000 -1.35000000\n-1.00000000 0.10000000 -1.30000000\n-1.00000000 0.10000000 -1.25000000\n-1.00000000 0.10000000 -1.20000000\n-1.00000000 0.10000000 -1.15000000\n-1.00000000 0.10000000 -1.10000000\n-1.00000000 0.10000000 -1.05000000\n-1.00000000 0.10000000 -1.00000000\n-1.00000000 0.10000000 1.60000000\n-1.00000000 0.10000000 1.65000000\n-1.00000000 0.10000000 1.70000000\n-1.00000000 0.10000000 1.75000000\n-1.00000000 0.10000000 1.80000000\n-1.00000000 0.10000000 1.85000000\n-1.00000000 0.10000000 1.90000000\n-1.00000000 0.10000000 1.95000000\n-1.00000000 0.15000000 -1.45000000\n-1.00000000 0.15000000 -1.40000000\n-1.00000000 0.15000000 -1.05000000\n-1.00000000 0.15000000 -1.00000000\n-1.00000000 0.15000000 -0.95000000\n-1.00000000 0.15000000 1.55000000\n-1.00000000 0.15000000 1.60000000\n-1.00000000 0.15000000 1.65000000\n-1.00000000 0.15000000 1.70000000\n-1.00000000 0.15000000 1.75000000\n-1.00000000 0.15000000 1.80000000\n-1.00000000 0.15000000 1.85000000\n-1.00000000 0.15000000 1.90000000\n-1.00000000 0.15000000 1.95000000\n-1.00000000 0.15000000 2.00000000\n-1.00000000 0.20000000 -1.50000000\n-1.00000000 0.20000000 -1.45000000\n-1.00000000 0.20000000 -0.95000000\n-1.00000000 0.20000000 1.55000000\n-1.00000000 0.20000000 1.60000000\n-1.00000000 0.20000000 1.65000000\n-1.00000000 0.20000000 1.90000000\n-1.00000000 0.20000000 1.95000000\n-1.00000000 0.20000000 2.00000000\n-1.00000000 0.20000000 2.05000000\n-1.00000000 0.25000000 -1.50000000\n-1.00000000 0.25000000 -1.45000000\n-1.00000000 0.25000000 -0.95000000\n-1.00000000 0.25000000 -0.90000000\n-1.00000000 0.25000000 1.50000000\n-1.00000000 0.25000000 1.55000000\n-1.00000000 0.25000000 1.60000000\n-1.00000000 0.25000000 1.95000000\n-1.00000000 0.25000000 2.00000000\n-1.00000000 0.25000000 2.05000000\n-1.00000000 0.30000000 -1.50000000\n-1.00000000 0.30000000 -0.95000000\n-1.00000000 0.30000000 -0.90000000\n-1.00000000 0.30000000 1.50000000\n-1.00000000 0.30000000 1.55000000\n-1.00000000 0.30000000 1.60000000\n-1.00000000 0.30000000 2.00000000\n-1.00000000 0.30000000 2.05000000\n-1.00000000 0.35000000 -1.50000000\n-1.00000000 0.35000000 -0.95000000\n-1.00000000 0.35000000 -0.90000000\n-1.00000000 0.35000000 1.50000000\n-1.00000000 0.35000000 1.55000000\n-1.00000000 0.35000000 2.00000000\n-1.00000000 0.35000000 2.05000000\n-1.00000000 0.40000000 -1.50000000\n-1.00000000 0.40000000 -0.95000000\n-1.00000000 0.40000000 -0.90000000\n-1.00000000 0.40000000 1.50000000\n-1.00000000 0.40000000 1.55000000\n-1.00000000 0.40000000 1.60000000\n-1.00000000 0.40000000 2.00000000\n-1.00000000 0.40000000 2.05000000\n-1.00000000 0.45000000 -1.50000000\n-1.00000000 0.45000000 -1.45000000\n-1.00000000 0.45000000 -0.95000000\n-1.00000000 0.45000000 -0.90000000\n-1.00000000 0.45000000 1.50000000\n-1.00000000 0.45000000 1.55000000\n-1.00000000 0.45000000 1.60000000\n-1.00000000 0.45000000 1.95000000\n-1.00000000 0.45000000 2.00000000\n-1.00000000 0.45000000 2.05000000\n-1.00000000 0.50000000 -1.50000000\n-1.00000000 0.50000000 -1.45000000\n-1.00000000 0.50000000 -0.95000000\n-1.00000000 0.50000000 -0.90000000\n-1.00000000 0.50000000 -0.85000000\n-1.00000000 0.50000000 -0.80000000\n-1.00000000 0.50000000 -0.75000000\n-1.00000000 0.50000000 1.55000000\n-1.00000000 0.50000000 1.60000000\n-1.00000000 0.50000000 1.65000000\n-1.00000000 0.50000000 1.90000000\n-1.00000000 0.50000000 1.95000000\n-1.00000000 0.50000000 2.00000000\n-1.00000000 0.50000000 2.05000000\n-1.00000000 0.55000000 -1.45000000\n-1.00000000 0.55000000 -1.40000000\n-1.00000000 0.55000000 -1.00000000\n-1.00000000 0.55000000 -0.95000000\n-1.00000000 0.55000000 -0.90000000\n-1.00000000 0.55000000 -0.85000000\n-1.00000000 0.55000000 -0.80000000\n-1.00000000 0.55000000 -0.75000000\n-1.00000000 0.55000000 -0.70000000\n-1.00000000 0.55000000 -0.65000000\n-1.00000000 0.55000000 1.55000000\n-1.00000000 0.55000000 1.60000000\n-1.00000000 0.55000000 1.65000000\n-1.00000000 0.55000000 1.70000000\n-1.00000000 0.55000000 1.75000000\n-1.00000000 0.55000000 1.80000000\n-1.00000000 0.55000000 1.85000000\n-1.00000000 0.55000000 1.90000000\n-1.00000000 0.55000000 1.95000000\n-1.00000000 0.55000000 2.00000000\n-1.00000000 0.60000000 -1.40000000\n-1.00000000 0.60000000 -1.35000000\n-1.00000000 0.60000000 -1.30000000\n-1.00000000 0.60000000 -1.10000000\n-1.00000000 0.60000000 -1.05000000\n-1.00000000 0.60000000 -1.00000000\n-1.00000000 0.60000000 -0.95000000\n-1.00000000 0.60000000 -0.90000000\n-1.00000000 0.60000000 -0.85000000\n-1.00000000 0.60000000 -0.80000000\n-1.00000000 0.60000000 -0.75000000\n-1.00000000 0.60000000 -0.70000000\n-1.00000000 0.60000000 -0.65000000\n-1.00000000 0.60000000 -0.60000000\n-1.00000000 0.60000000 1.60000000\n-1.00000000 0.60000000 1.65000000\n-1.00000000 0.60000000 1.70000000\n-1.00000000 0.60000000 1.75000000\n-1.00000000 0.60000000 1.80000000\n-1.00000000 0.60000000 1.85000000\n-1.00000000 0.60000000 1.90000000\n-1.00000000 0.60000000 1.95000000\n-1.00000000 0.65000000 -1.35000000\n-1.00000000 0.65000000 -1.30000000\n-1.00000000 0.65000000 -1.25000000\n-1.00000000 0.65000000 -1.20000000\n-1.00000000 0.65000000 -1.15000000\n-1.00000000 0.65000000 -1.10000000\n-1.00000000 0.65000000 -1.05000000\n-1.00000000 0.65000000 -1.00000000\n-1.00000000 0.65000000 -0.95000000\n-1.00000000 0.65000000 -0.90000000\n-1.00000000 0.65000000 -0.85000000\n-1.00000000 0.65000000 -0.80000000\n-1.00000000 0.65000000 -0.75000000\n-1.00000000 0.65000000 -0.70000000\n-1.00000000 0.65000000 -0.65000000\n-1.00000000 0.65000000 -0.60000000\n-1.00000000 0.65000000 1.70000000\n-1.00000000 0.65000000 1.75000000\n-1.00000000 0.65000000 1.80000000\n-1.00000000 0.65000000 1.85000000\n-1.00000000 0.70000000 -1.20000000\n-1.00000000 0.70000000 -1.15000000\n-1.00000000 0.70000000 -1.10000000\n-1.00000000 0.70000000 -1.05000000\n-1.00000000 0.70000000 -1.00000000\n-1.00000000 0.70000000 -0.95000000\n-1.00000000 0.70000000 -0.90000000\n-1.00000000 0.70000000 -0.85000000\n-1.00000000 0.70000000 -0.80000000\n-1.00000000 0.70000000 -0.75000000\n-1.00000000 0.70000000 -0.70000000\n-1.00000000 0.70000000 -0.65000000\n-1.00000000 0.70000000 -0.60000000\n-1.00000000 0.75000000 -1.15000000\n-1.00000000 0.75000000 -1.10000000\n-1.00000000 0.75000000 -1.05000000\n-1.00000000 0.75000000 -1.00000000\n-1.00000000 0.75000000 -0.95000000\n-1.00000000 0.75000000 -0.90000000\n-1.00000000 0.75000000 -0.85000000\n-1.00000000 0.75000000 -0.80000000\n-1.00000000 0.75000000 -0.75000000\n-1.00000000 0.75000000 -0.70000000\n-1.00000000 0.75000000 -0.65000000\n-1.00000000 0.80000000 -1.10000000\n-1.00000000 0.80000000 -1.05000000\n-1.00000000 0.80000000 -1.00000000\n-1.00000000 0.80000000 -0.95000000\n-1.00000000 0.80000000 -0.90000000\n-1.00000000 0.80000000 -0.85000000\n-1.00000000 0.80000000 -0.80000000\n-1.00000000 0.80000000 -0.75000000\n-0.95000000 0.00000000 -1.35000000\n-0.95000000 0.00000000 -1.30000000\n-0.95000000 0.00000000 -1.25000000\n-0.95000000 0.00000000 -1.20000000\n-0.95000000 0.00000000 -1.15000000\n-0.95000000 0.00000000 -1.10000000\n-0.95000000 0.00000000 1.70000000\n-0.95000000 0.00000000 1.75000000\n-0.95000000 0.00000000 1.80000000\n-0.95000000 0.00000000 1.85000000\n-0.95000000 0.05000000 -1.40000000\n-0.95000000 0.05000000 -1.05000000\n-0.95000000 0.05000000 -1.00000000\n-0.95000000 0.05000000 1.60000000\n-0.95000000 0.05000000 1.65000000\n-0.95000000 0.05000000 1.70000000\n-0.95000000 0.05000000 1.85000000\n-0.95000000 0.05000000 1.90000000\n-0.95000000 0.05000000 1.95000000\n-0.95000000 0.10000000 -1.45000000\n-0.95000000 0.10000000 -0.95000000\n-0.95000000 0.10000000 1.55000000\n-0.95000000 0.10000000 2.00000000\n-0.95000000 0.10000000 2.05000000\n-0.95000000 0.15000000 -1.50000000\n-0.95000000 0.15000000 -0.90000000\n-0.95000000 0.15000000 1.50000000\n-0.95000000 0.15000000 2.05000000\n-0.95000000 0.20000000 -1.55000000\n-0.95000000 0.20000000 -0.90000000\n-0.95000000 0.20000000 1.45000000\n-0.95000000 0.20000000 1.50000000\n-0.95000000 0.20000000 2.10000000\n-0.95000000 0.25000000 -1.55000000\n-0.95000000 0.25000000 -0.85000000\n-0.95000000 0.25000000 1.45000000\n-0.95000000 0.25000000 2.10000000\n-0.95000000 0.30000000 -1.55000000\n-0.95000000 0.30000000 -0.85000000\n-0.95000000 0.30000000 1.45000000\n-0.95000000 0.30000000 2.10000000\n-0.95000000 0.35000000 -1.55000000\n-0.95000000 0.35000000 -0.85000000\n-0.95000000 0.35000000 -0.50000000\n-0.95000000 0.35000000 -0.45000000\n-0.95000000 0.35000000 -0.40000000\n-0.95000000 0.35000000 -0.35000000\n-0.95000000 0.35000000 -0.30000000\n-0.95000000 0.35000000 -0.25000000\n-0.95000000 0.35000000 -0.20000000\n-0.95000000 0.35000000 -0.15000000\n-0.95000000 0.35000000 -0.10000000\n-0.95000000 0.35000000 -0.05000000\n-0.95000000 0.35000000 0.00000000\n-0.95000000 0.35000000 0.05000000\n-0.95000000 0.35000000 0.10000000\n-0.95000000 0.35000000 0.15000000\n-0.95000000 0.35000000 0.20000000\n-0.95000000 0.35000000 1.45000000\n-0.95000000 0.35000000 2.10000000\n-0.95000000 0.40000000 -1.55000000\n-0.95000000 0.40000000 -0.85000000\n-0.95000000 0.40000000 -0.65000000\n-0.95000000 0.40000000 -0.60000000\n-0.95000000 0.40000000 -0.55000000\n-0.95000000 0.40000000 -0.50000000\n-0.95000000 0.40000000 -0.45000000\n-0.95000000 0.40000000 -0.40000000\n-0.95000000 0.40000000 -0.35000000\n-0.95000000 0.40000000 -0.30000000\n-0.95000000 0.40000000 -0.25000000\n-0.95000000 0.40000000 -0.20000000\n-0.95000000 0.40000000 -0.15000000\n-0.95000000 0.40000000 -0.10000000\n-0.95000000 0.40000000 -0.05000000\n-0.95000000 0.40000000 0.00000000\n-0.95000000 0.40000000 0.05000000\n-0.95000000 0.40000000 0.10000000\n-0.95000000 0.40000000 0.15000000\n-0.95000000 0.40000000 0.20000000\n-0.95000000 0.40000000 0.25000000\n-0.95000000 0.40000000 0.30000000\n-0.95000000 0.40000000 1.45000000\n-0.95000000 0.40000000 2.10000000\n-0.95000000 0.45000000 -1.55000000\n-0.95000000 0.45000000 -0.85000000\n-0.95000000 0.45000000 -0.80000000\n-0.95000000 0.45000000 -0.75000000\n-0.95000000 0.45000000 -0.70000000\n-0.95000000 0.45000000 -0.65000000\n-0.95000000 0.45000000 -0.60000000\n-0.95000000 0.45000000 -0.55000000\n-0.95000000 0.45000000 -0.50000000\n-0.95000000 0.45000000 -0.45000000\n-0.95000000 0.45000000 -0.40000000\n-0.95000000 0.45000000 -0.35000000\n-0.95000000 0.45000000 -0.30000000\n-0.95000000 0.45000000 -0.25000000\n-0.95000000 0.45000000 -0.20000000\n-0.95000000 0.45000000 -0.15000000\n-0.95000000 0.45000000 -0.10000000\n-0.95000000 0.45000000 -0.05000000\n-0.95000000 0.45000000 0.00000000\n-0.95000000 0.45000000 0.05000000\n-0.95000000 0.45000000 0.10000000\n-0.95000000 0.45000000 0.15000000\n-0.95000000 0.45000000 0.20000000\n-0.95000000 0.45000000 0.25000000\n-0.95000000 0.45000000 0.30000000\n-0.95000000 0.45000000 1.45000000\n-0.95000000 0.45000000 2.10000000\n-0.95000000 0.50000000 -1.55000000\n-0.95000000 0.50000000 -0.70000000\n-0.95000000 0.50000000 -0.65000000\n-0.95000000 0.50000000 -0.60000000\n-0.95000000 0.50000000 -0.55000000\n-0.95000000 0.50000000 -0.50000000\n-0.95000000 0.50000000 -0.45000000\n-0.95000000 0.50000000 -0.40000000\n-0.95000000 0.50000000 -0.35000000\n-0.95000000 0.50000000 -0.30000000\n-0.95000000 0.50000000 -0.25000000\n-0.95000000 0.50000000 -0.20000000\n-0.95000000 0.50000000 -0.15000000\n-0.95000000 0.50000000 -0.10000000\n-0.95000000 0.50000000 -0.05000000\n-0.95000000 0.50000000 0.00000000\n-0.95000000 0.50000000 0.05000000\n-0.95000000 0.50000000 0.10000000\n-0.95000000 0.50000000 0.15000000\n-0.95000000 0.50000000 0.20000000\n-0.95000000 0.50000000 0.25000000\n-0.95000000 0.50000000 1.45000000\n-0.95000000 0.50000000 1.50000000\n-0.95000000 0.50000000 2.10000000\n-0.95000000 0.55000000 -1.50000000\n-0.95000000 0.55000000 -0.60000000\n-0.95000000 0.55000000 -0.55000000\n-0.95000000 0.55000000 -0.50000000\n-0.95000000 0.55000000 -0.45000000\n-0.95000000 0.55000000 -0.40000000\n-0.95000000 0.55000000 -0.35000000\n-0.95000000 0.55000000 -0.30000000\n-0.95000000 0.55000000 -0.25000000\n-0.95000000 0.55000000 -0.20000000\n-0.95000000 0.55000000 -0.15000000\n-0.95000000 0.55000000 -0.10000000\n-0.95000000 0.55000000 -0.05000000\n-0.95000000 0.55000000 0.00000000\n-0.95000000 0.55000000 0.05000000\n-0.95000000 0.55000000 1.50000000\n-0.95000000 0.55000000 2.05000000\n-0.95000000 0.60000000 -1.45000000\n-0.95000000 0.60000000 -0.55000000\n-0.95000000 0.60000000 -0.50000000\n-0.95000000 0.60000000 -0.45000000\n-0.95000000 0.60000000 1.55000000\n-0.95000000 0.60000000 2.00000000\n-0.95000000 0.60000000 2.05000000\n-0.95000000 0.65000000 -1.40000000\n-0.95000000 0.65000000 -0.55000000\n-0.95000000 0.65000000 -0.50000000\n-0.95000000 0.65000000 -0.45000000\n-0.95000000 0.65000000 1.60000000\n-0.95000000 0.65000000 1.65000000\n-0.95000000 0.65000000 1.90000000\n-0.95000000 0.65000000 1.95000000\n-0.95000000 0.65000000 2.00000000\n-0.95000000 0.70000000 -1.35000000\n-0.95000000 0.70000000 -1.30000000\n-0.95000000 0.70000000 -1.25000000\n-0.95000000 0.70000000 -0.55000000\n-0.95000000 0.70000000 -0.50000000\n-0.95000000 0.70000000 1.70000000\n-0.95000000 0.70000000 1.75000000\n-0.95000000 0.70000000 1.80000000\n-0.95000000 0.70000000 1.85000000\n-0.95000000 0.70000000 1.90000000\n-0.95000000 0.75000000 -1.30000000\n-0.95000000 0.75000000 -1.25000000\n-0.95000000 0.75000000 -1.20000000\n-0.95000000 0.75000000 -0.60000000\n-0.95000000 0.75000000 -0.55000000\n-0.95000000 0.75000000 -0.50000000\n-0.95000000 0.80000000 -1.25000000\n-0.95000000 0.80000000 -1.20000000\n-0.95000000 0.80000000 -1.15000000\n-0.95000000 0.80000000 -0.70000000\n-0.95000000 0.80000000 -0.65000000\n-0.95000000 0.80000000 -0.60000000\n-0.95000000 0.85000000 -1.20000000\n-0.95000000 0.85000000 -1.15000000\n-0.95000000 0.85000000 -1.10000000\n-0.95000000 0.85000000 -1.05000000\n-0.95000000 0.85000000 -1.00000000\n-0.95000000 0.85000000 -0.95000000\n-0.95000000 0.85000000 -0.90000000\n-0.95000000 0.85000000 -0.85000000\n-0.95000000 0.85000000 -0.80000000\n-0.95000000 0.85000000 -0.75000000\n-0.95000000 0.85000000 -0.70000000\n-0.90000000 0.00000000 -1.35000000\n-0.90000000 0.00000000 -1.30000000\n-0.90000000 0.00000000 -1.25000000\n-0.90000000 0.00000000 -1.20000000\n-0.90000000 0.00000000 -1.15000000\n-0.90000000 0.00000000 -1.10000000\n-0.90000000 0.00000000 -1.05000000\n-0.90000000 0.00000000 1.65000000\n-0.90000000 0.00000000 1.70000000\n-0.90000000 0.00000000 1.75000000\n-0.90000000 0.00000000 1.80000000\n-0.90000000 0.00000000 1.85000000\n-0.90000000 0.00000000 1.90000000\n-0.90000000 0.00000000 1.95000000\n-0.90000000 0.05000000 -1.45000000\n-0.90000000 0.05000000 -1.40000000\n-0.90000000 0.05000000 -1.00000000\n-0.90000000 0.05000000 1.55000000\n-0.90000000 0.05000000 1.60000000\n-0.90000000 0.05000000 2.00000000\n-0.90000000 0.10000000 -1.50000000\n-0.90000000 0.10000000 -0.95000000\n-0.90000000 0.10000000 1.50000000\n-0.90000000 0.10000000 2.05000000\n-0.90000000 0.15000000 -1.50000000\n-0.90000000 0.15000000 -0.90000000\n-0.90000000 0.15000000 1.45000000\n-0.90000000 0.15000000 2.10000000\n-0.90000000 0.20000000 -1.55000000\n-0.90000000 0.20000000 -0.85000000\n-0.90000000 0.20000000 1.45000000\n-0.90000000 0.20000000 2.10000000\n-0.90000000 0.25000000 -1.55000000\n-0.90000000 0.25000000 -0.85000000\n-0.90000000 0.25000000 1.45000000\n-0.90000000 0.25000000 2.15000000\n-0.90000000 0.30000000 -1.55000000\n-0.90000000 0.30000000 -0.85000000\n-0.90000000 0.30000000 -0.50000000\n-0.90000000 0.30000000 -0.45000000\n-0.90000000 0.30000000 -0.40000000\n-0.90000000 0.30000000 -0.35000000\n-0.90000000 0.30000000 -0.30000000\n-0.90000000 0.30000000 -0.25000000\n-0.90000000 0.30000000 -0.20000000\n-0.90000000 0.30000000 -0.15000000\n-0.90000000 0.30000000 -0.10000000\n-0.90000000 0.30000000 -0.05000000\n-0.90000000 0.30000000 0.00000000\n-0.90000000 0.30000000 0.05000000\n-0.90000000 0.30000000 0.10000000\n-0.90000000 0.30000000 0.15000000\n-0.90000000 0.30000000 0.20000000\n-0.90000000 0.30000000 0.25000000\n-0.90000000 0.30000000 0.30000000\n-0.90000000 0.30000000 0.35000000\n-0.90000000 0.30000000 1.40000000\n-0.90000000 0.30000000 2.15000000\n-0.90000000 0.35000000 -1.55000000\n-0.90000000 0.35000000 -0.85000000\n-0.90000000 0.35000000 -0.75000000\n-0.90000000 0.35000000 -0.70000000\n-0.90000000 0.35000000 -0.65000000\n-0.90000000 0.35000000 -0.60000000\n-0.90000000 0.35000000 -0.55000000\n-0.90000000 0.35000000 0.25000000\n-0.90000000 0.35000000 0.30000000\n-0.90000000 0.35000000 0.35000000\n-0.90000000 0.35000000 0.40000000\n-0.90000000 0.35000000 0.45000000\n-0.90000000 0.35000000 1.40000000\n-0.90000000 0.35000000 2.15000000\n-0.90000000 0.40000000 -1.55000000\n-0.90000000 0.40000000 -0.80000000\n-0.90000000 0.40000000 -0.75000000\n-0.90000000 0.40000000 -0.70000000\n-0.90000000 0.40000000 0.35000000\n-0.90000000 0.40000000 0.40000000\n-0.90000000 0.40000000 0.45000000\n-0.90000000 0.40000000 0.50000000\n-0.90000000 0.40000000 1.40000000\n-0.90000000 0.40000000 2.15000000\n-0.90000000 0.45000000 -1.55000000\n-0.90000000 0.45000000 0.35000000\n-0.90000000 0.45000000 0.40000000\n-0.90000000 0.45000000 0.45000000\n-0.90000000 0.45000000 0.50000000\n-0.90000000 0.45000000 1.45000000\n-0.90000000 0.45000000 2.15000000\n-0.90000000 0.50000000 -1.55000000\n-0.90000000 0.50000000 0.30000000\n-0.90000000 0.50000000 0.35000000\n-0.90000000 0.50000000 0.40000000\n-0.90000000 0.50000000 0.45000000\n-0.90000000 0.50000000 1.45000000\n-0.90000000 0.50000000 2.10000000\n-0.90000000 0.55000000 -1.50000000\n-0.90000000 0.55000000 0.10000000\n-0.90000000 0.55000000 0.15000000\n-0.90000000 0.55000000 0.20000000\n-0.90000000 0.55000000 0.25000000\n-0.90000000 0.55000000 0.30000000\n-0.90000000 0.55000000 0.35000000\n-0.90000000 0.55000000 1.45000000\n-0.90000000 0.55000000 2.10000000\n-0.90000000 0.60000000 -1.50000000\n-0.90000000 0.60000000 -0.40000000\n-0.90000000 0.60000000 -0.35000000\n-0.90000000 0.60000000 -0.30000000\n-0.90000000 0.60000000 -0.25000000\n-0.90000000 0.60000000 -0.20000000\n-0.90000000 0.60000000 -0.15000000\n-0.90000000 0.60000000 -0.10000000\n-0.90000000 0.60000000 -0.05000000\n-0.90000000 0.60000000 0.00000000\n-0.90000000 0.60000000 0.05000000\n-0.90000000 0.60000000 0.10000000\n-0.90000000 0.60000000 1.50000000\n-0.90000000 0.60000000 2.05000000\n-0.90000000 0.65000000 -1.45000000\n-0.90000000 0.65000000 -0.40000000\n-0.90000000 0.65000000 -0.35000000\n-0.90000000 0.65000000 1.55000000\n-0.90000000 0.65000000 1.60000000\n-0.90000000 0.65000000 2.00000000\n-0.90000000 0.70000000 -1.45000000\n-0.90000000 0.70000000 -1.40000000\n-0.90000000 0.70000000 -0.45000000\n-0.90000000 0.70000000 -0.40000000\n-0.90000000 0.70000000 1.65000000\n-0.90000000 0.70000000 1.70000000\n-0.90000000 0.70000000 1.75000000\n-0.90000000 0.70000000 1.80000000\n-0.90000000 0.70000000 1.85000000\n-0.90000000 0.70000000 1.90000000\n-0.90000000 0.70000000 1.95000000\n-0.90000000 0.75000000 -1.40000000\n-0.90000000 0.75000000 -1.35000000\n-0.90000000 0.75000000 -0.45000000\n-0.90000000 0.75000000 -0.40000000\n-0.90000000 0.80000000 -1.35000000\n-0.90000000 0.80000000 -1.30000000\n-0.90000000 0.80000000 -0.55000000\n-0.90000000 0.80000000 -0.50000000\n-0.90000000 0.80000000 -0.45000000\n-0.90000000 0.85000000 -1.30000000\n-0.90000000 0.85000000 -1.25000000\n-0.90000000 0.85000000 -0.65000000\n-0.90000000 0.85000000 -0.60000000\n-0.90000000 0.85000000 -0.55000000\n-0.90000000 0.90000000 -1.20000000\n-0.90000000 0.90000000 -1.15000000\n-0.90000000 0.90000000 -1.10000000\n-0.90000000 0.90000000 -1.05000000\n-0.90000000 0.90000000 -1.00000000\n-0.90000000 0.90000000 -0.95000000\n-0.90000000 0.90000000 -0.90000000\n-0.90000000 0.90000000 -0.85000000\n-0.90000000 0.90000000 -0.80000000\n-0.90000000 0.90000000 -0.75000000\n-0.90000000 0.90000000 -0.70000000\n-0.90000000 0.90000000 -0.65000000\n-0.85000000 0.00000000 -1.35000000\n-0.85000000 0.00000000 -1.30000000\n-0.85000000 0.00000000 -1.25000000\n-0.85000000 0.00000000 -1.20000000\n-0.85000000 0.00000000 -1.15000000\n-0.85000000 0.00000000 -1.10000000\n-0.85000000 0.00000000 -1.05000000\n-0.85000000 0.00000000 1.65000000\n-0.85000000 0.00000000 1.70000000\n-0.85000000 0.00000000 1.75000000\n-0.85000000 0.00000000 1.80000000\n-0.85000000 0.00000000 1.85000000\n-0.85000000 0.00000000 1.90000000\n-0.85000000 0.00000000 1.95000000\n-0.85000000 0.05000000 -1.45000000\n-0.85000000 0.05000000 -1.40000000\n-0.85000000 0.05000000 -1.00000000\n-0.85000000 0.05000000 1.55000000\n-0.85000000 0.05000000 1.60000000\n-0.85000000 0.05000000 2.00000000\n-0.85000000 0.10000000 -1.50000000\n-0.85000000 0.10000000 -0.95000000\n-0.85000000 0.10000000 1.50000000\n-0.85000000 0.10000000 2.05000000\n-0.85000000 0.15000000 -1.50000000\n-0.85000000 0.15000000 -0.90000000\n-0.85000000 0.15000000 1.45000000\n-0.85000000 0.15000000 2.10000000\n-0.85000000 0.20000000 -1.55000000\n-0.85000000 0.20000000 -0.85000000\n-0.85000000 0.20000000 1.45000000\n-0.85000000 0.20000000 2.10000000\n-0.85000000 0.25000000 -1.55000000\n-0.85000000 0.25000000 -0.85000000\n-0.85000000 0.25000000 -0.40000000\n-0.85000000 0.25000000 -0.35000000\n-0.85000000 0.25000000 -0.30000000\n-0.85000000 0.25000000 -0.25000000\n-0.85000000 0.25000000 -0.20000000\n-0.85000000 0.25000000 -0.15000000\n-0.85000000 0.25000000 -0.10000000\n-0.85000000 0.25000000 -0.05000000\n-0.85000000 0.25000000 0.00000000\n-0.85000000 0.25000000 0.05000000\n-0.85000000 0.25000000 0.10000000\n-0.85000000 0.25000000 0.15000000\n-0.85000000 0.25000000 0.20000000\n-0.85000000 0.25000000 0.25000000\n-0.85000000 0.25000000 0.30000000\n-0.85000000 0.25000000 1.45000000\n-0.85000000 0.25000000 2.15000000\n-0.85000000 0.30000000 -1.55000000\n-0.85000000 0.30000000 -0.85000000\n-0.85000000 0.30000000 -0.75000000\n-0.85000000 0.30000000 -0.70000000\n-0.85000000 0.30000000 -0.65000000\n-0.85000000 0.30000000 -0.60000000\n-0.85000000 0.30000000 -0.55000000\n-0.85000000 0.30000000 -0.50000000\n-0.85000000 0.30000000 -0.45000000\n-0.85000000 0.30000000 0.35000000\n-0.85000000 0.30000000 0.40000000\n-0.85000000 0.30000000 0.45000000\n-0.85000000 0.30000000 0.50000000\n-0.85000000 0.30000000 0.55000000\n-0.85000000 0.30000000 1.40000000\n-0.85000000 0.30000000 2.15000000\n-0.85000000 0.35000000 -1.55000000\n-0.85000000 0.35000000 -0.80000000\n-0.85000000 0.35000000 0.50000000\n-0.85000000 0.35000000 0.55000000\n-0.85000000 0.35000000 0.60000000\n-0.85000000 0.35000000 0.65000000\n-0.85000000 0.35000000 1.40000000\n-0.85000000 0.35000000 2.15000000\n-0.85000000 0.40000000 -1.55000000\n-0.85000000 0.40000000 0.55000000\n-0.85000000 0.40000000 0.60000000\n-0.85000000 0.40000000 0.65000000\n-0.85000000 0.40000000 1.40000000\n-0.85000000 0.40000000 2.15000000\n-0.85000000 0.45000000 -1.55000000\n-0.85000000 0.45000000 0.55000000\n-0.85000000 0.45000000 0.60000000\n-0.85000000 0.45000000 0.65000000\n-0.85000000 0.45000000 1.45000000\n-0.85000000 0.45000000 2.15000000\n-0.85000000 0.50000000 -1.55000000\n-0.85000000 0.50000000 0.50000000\n-0.85000000 0.50000000 0.55000000\n-0.85000000 0.50000000 0.60000000\n-0.85000000 0.50000000 1.45000000\n-0.85000000 0.50000000 2.10000000\n-0.85000000 0.55000000 -1.50000000\n-0.85000000 0.55000000 0.35000000\n-0.85000000 0.55000000 0.40000000\n-0.85000000 0.55000000 0.45000000\n-0.85000000 0.55000000 0.50000000\n-0.85000000 0.55000000 1.45000000\n-0.85000000 0.55000000 2.10000000\n-0.85000000 0.60000000 -1.50000000\n-0.85000000 0.60000000 0.00000000\n-0.85000000 0.60000000 0.05000000\n-0.85000000 0.60000000 0.10000000\n-0.85000000 0.60000000 0.15000000\n-0.85000000 0.60000000 0.20000000\n-0.85000000 0.60000000 0.25000000\n-0.85000000 0.60000000 0.30000000\n-0.85000000 0.60000000 1.50000000\n-0.85000000 0.60000000 2.05000000\n-0.85000000 0.65000000 -1.50000000\n-0.85000000 0.65000000 -0.30000000\n-0.85000000 0.65000000 -0.25000000\n-0.85000000 0.65000000 -0.20000000\n-0.85000000 0.65000000 -0.15000000\n-0.85000000 0.65000000 -0.10000000\n-0.85000000 0.65000000 -0.05000000\n-0.85000000 0.65000000 1.55000000\n-0.85000000 0.65000000 2.00000000\n-0.85000000 0.70000000 -1.50000000\n-0.85000000 0.70000000 -0.35000000\n-0.85000000 0.70000000 -0.30000000\n-0.85000000 0.70000000 1.60000000\n-0.85000000 0.70000000 1.65000000\n-0.85000000 0.70000000 1.70000000\n-0.85000000 0.70000000 1.75000000\n-0.85000000 0.70000000 1.80000000\n-0.85000000 0.70000000 1.85000000\n-0.85000000 0.70000000 1.90000000\n-0.85000000 0.70000000 1.95000000\n-0.85000000 0.75000000 -1.50000000\n-0.85000000 0.75000000 -1.45000000\n-0.85000000 0.75000000 -0.35000000\n-0.85000000 0.75000000 -0.30000000\n-0.85000000 0.80000000 -1.45000000\n-0.85000000 0.80000000 -1.40000000\n-0.85000000 0.80000000 -0.40000000\n-0.85000000 0.85000000 -1.40000000\n-0.85000000 0.85000000 -1.35000000\n-0.85000000 0.85000000 -0.50000000\n-0.85000000 0.85000000 -0.45000000\n-0.85000000 0.90000000 -1.30000000\n-0.85000000 0.90000000 -1.25000000\n-0.85000000 0.90000000 -0.65000000\n-0.85000000 0.90000000 -0.60000000\n-0.85000000 0.90000000 -0.55000000\n-0.85000000 0.95000000 -1.20000000\n-0.85000000 0.95000000 -1.15000000\n-0.85000000 0.95000000 -1.10000000\n-0.85000000 0.95000000 -1.05000000\n-0.85000000 0.95000000 -1.00000000\n-0.85000000 0.95000000 -0.95000000\n-0.85000000 0.95000000 -0.90000000\n-0.85000000 0.95000000 -0.85000000\n-0.85000000 0.95000000 -0.80000000\n-0.85000000 0.95000000 -0.75000000\n-0.85000000 0.95000000 -0.70000000\n-0.80000000 0.00000000 -1.30000000\n-0.80000000 0.00000000 -1.25000000\n-0.80000000 0.00000000 -1.20000000\n-0.80000000 0.00000000 -1.15000000\n-0.80000000 0.00000000 1.65000000\n-0.80000000 0.00000000 1.70000000\n-0.80000000 0.00000000 1.75000000\n-0.80000000 0.00000000 1.80000000\n-0.80000000 0.00000000 1.85000000\n-0.80000000 0.00000000 1.90000000\n-0.80000000 0.05000000 -1.40000000\n-0.80000000 0.05000000 -1.35000000\n-0.80000000 0.05000000 -1.10000000\n-0.80000000 0.05000000 -1.05000000\n-0.80000000 0.05000000 -1.00000000\n-0.80000000 0.05000000 1.55000000\n-0.80000000 0.05000000 1.60000000\n-0.80000000 0.05000000 1.95000000\n-0.80000000 0.05000000 2.00000000\n-0.80000000 0.10000000 -1.45000000\n-0.80000000 0.10000000 -1.40000000\n-0.80000000 0.10000000 -1.00000000\n-0.80000000 0.10000000 -0.95000000\n-0.80000000 0.10000000 1.50000000\n-0.80000000 0.10000000 2.05000000\n-0.80000000 0.15000000 -1.50000000\n-0.80000000 0.15000000 -1.45000000\n-0.80000000 0.15000000 -0.95000000\n-0.80000000 0.15000000 -0.90000000\n-0.80000000 0.15000000 1.50000000\n-0.80000000 0.15000000 2.10000000\n-0.80000000 0.20000000 -1.50000000\n-0.80000000 0.20000000 -0.90000000\n-0.80000000 0.20000000 1.45000000\n-0.80000000 0.20000000 2.10000000\n-0.80000000 0.25000000 -1.55000000\n-0.80000000 0.25000000 -0.90000000\n-0.80000000 0.25000000 -0.65000000\n-0.80000000 0.25000000 -0.60000000\n-0.80000000 0.25000000 -0.55000000\n-0.80000000 0.25000000 -0.50000000\n-0.80000000 0.25000000 -0.45000000\n-0.80000000 0.25000000 -0.40000000\n-0.80000000 0.25000000 -0.35000000\n-0.80000000 0.25000000 -0.30000000\n-0.80000000 0.25000000 -0.25000000\n-0.80000000 0.25000000 -0.20000000\n-0.80000000 0.25000000 -0.15000000\n-0.80000000 0.25000000 -0.10000000\n-0.80000000 0.25000000 -0.05000000\n-0.80000000 0.25000000 0.00000000\n-0.80000000 0.25000000 0.05000000\n-0.80000000 0.25000000 0.10000000\n-0.80000000 0.25000000 0.15000000\n-0.80000000 0.25000000 0.20000000\n-0.80000000 0.25000000 0.25000000\n-0.80000000 0.25000000 0.30000000\n-0.80000000 0.25000000 0.35000000\n-0.80000000 0.25000000 0.40000000\n-0.80000000 0.25000000 0.45000000\n-0.80000000 0.25000000 0.50000000\n-0.80000000 0.25000000 0.55000000\n-0.80000000 0.25000000 1.45000000\n-0.80000000 0.25000000 2.15000000\n-0.80000000 0.30000000 -1.55000000\n-0.80000000 0.30000000 -0.85000000\n-0.80000000 0.30000000 -0.80000000\n-0.80000000 0.30000000 -0.75000000\n-0.80000000 0.30000000 -0.70000000\n-0.80000000 0.30000000 0.60000000\n-0.80000000 0.30000000 0.65000000\n-0.80000000 0.30000000 0.70000000\n-0.80000000 0.30000000 1.45000000\n-0.80000000 0.30000000 2.15000000\n-0.80000000 0.35000000 -1.55000000\n-0.80000000 0.35000000 0.70000000\n-0.80000000 0.35000000 0.75000000\n-0.80000000 0.35000000 0.80000000\n-0.80000000 0.35000000 1.45000000\n-0.80000000 0.35000000 2.15000000\n-0.80000000 0.40000000 -1.55000000\n-0.80000000 0.40000000 0.70000000\n-0.80000000 0.40000000 0.75000000\n-0.80000000 0.40000000 0.80000000\n-0.80000000 0.40000000 1.45000000\n-0.80000000 0.40000000 2.15000000\n-0.80000000 0.45000000 -1.55000000\n-0.80000000 0.45000000 0.70000000\n-0.80000000 0.45000000 0.75000000\n-0.80000000 0.45000000 0.80000000\n-0.80000000 0.45000000 1.45000000\n-0.80000000 0.45000000 2.15000000\n-0.80000000 0.50000000 -1.50000000\n-0.80000000 0.50000000 0.65000000\n-0.80000000 0.50000000 0.70000000\n-0.80000000 0.50000000 0.75000000\n-0.80000000 0.50000000 1.45000000\n-0.80000000 0.50000000 2.10000000\n-0.80000000 0.55000000 -1.55000000\n-0.80000000 0.55000000 0.55000000\n-0.80000000 0.55000000 0.60000000\n-0.80000000 0.55000000 0.65000000\n-0.80000000 0.55000000 1.45000000\n-0.80000000 0.55000000 2.10000000\n-0.80000000 0.60000000 -1.55000000\n-0.80000000 0.60000000 0.25000000\n-0.80000000 0.60000000 0.30000000\n-0.80000000 0.60000000 0.35000000\n-0.80000000 0.60000000 0.40000000\n-0.80000000 0.60000000 0.45000000\n-0.80000000 0.60000000 0.50000000\n-0.80000000 0.60000000 1.50000000\n-0.80000000 0.60000000 2.05000000\n-0.80000000 0.65000000 -1.55000000\n-0.80000000 0.65000000 -0.20000000\n-0.80000000 0.65000000 -0.15000000\n-0.80000000 0.65000000 -0.10000000\n-0.80000000 0.65000000 -0.05000000\n-0.80000000 0.65000000 0.00000000\n-0.80000000 0.65000000 0.05000000\n-0.80000000 0.65000000 0.10000000\n-0.80000000 0.65000000 0.15000000\n-0.80000000 0.65000000 0.20000000\n-0.80000000 0.65000000 1.55000000\n-0.80000000 0.65000000 1.60000000\n-0.80000000 0.65000000 1.95000000\n-0.80000000 0.65000000 2.00000000\n-0.80000000 0.70000000 -1.55000000\n-0.80000000 0.70000000 -0.25000000\n-0.80000000 0.70000000 1.65000000\n-0.80000000 0.70000000 1.70000000\n-0.80000000 0.70000000 1.75000000\n-0.80000000 0.70000000 1.80000000\n-0.80000000 0.70000000 1.85000000\n-0.80000000 0.70000000 1.90000000\n-0.80000000 0.75000000 -1.55000000\n-0.80000000 0.75000000 -0.25000000\n-0.80000000 0.80000000 -1.55000000\n-0.80000000 0.80000000 -1.50000000\n-0.80000000 0.80000000 -0.35000000\n-0.80000000 0.80000000 -0.30000000\n-0.80000000 0.85000000 -1.50000000\n-0.80000000 0.85000000 -1.45000000\n-0.80000000 0.85000000 -0.40000000\n-0.80000000 0.85000000 -0.35000000\n-0.80000000 0.90000000 -1.40000000\n-0.80000000 0.90000000 -1.35000000\n-0.80000000 0.90000000 -0.50000000\n-0.80000000 0.90000000 -0.45000000\n-0.80000000 0.95000000 -1.30000000\n-0.80000000 0.95000000 -1.25000000\n-0.80000000 0.95000000 -1.20000000\n-0.80000000 0.95000000 -1.15000000\n-0.80000000 0.95000000 -1.10000000\n-0.80000000 0.95000000 -0.75000000\n-0.80000000 0.95000000 -0.70000000\n-0.80000000 0.95000000 -0.65000000\n-0.80000000 0.95000000 -0.60000000\n-0.80000000 0.95000000 -0.55000000\n-0.80000000 1.00000000 -1.05000000\n-0.80000000 1.00000000 -1.00000000\n-0.80000000 1.00000000 -0.95000000\n-0.80000000 1.00000000 -0.90000000\n-0.80000000 1.00000000 -0.85000000\n-0.80000000 1.00000000 -0.80000000\n-0.75000000 0.05000000 -1.30000000\n-0.75000000 0.05000000 -1.25000000\n-0.75000000 0.05000000 -1.20000000\n-0.75000000 0.05000000 -1.15000000\n-0.75000000 0.05000000 1.65000000\n-0.75000000 0.05000000 1.70000000\n-0.75000000 0.05000000 1.75000000\n-0.75000000 0.05000000 1.80000000\n-0.75000000 0.05000000 1.85000000\n-0.75000000 0.05000000 1.90000000\n-0.75000000 0.10000000 -1.35000000\n-0.75000000 0.10000000 -1.30000000\n-0.75000000 0.10000000 -1.25000000\n-0.75000000 0.10000000 -1.20000000\n-0.75000000 0.10000000 -1.15000000\n-0.75000000 0.10000000 -1.10000000\n-0.75000000 0.10000000 -1.05000000\n-0.75000000 0.10000000 1.55000000\n-0.75000000 0.10000000 1.60000000\n-0.75000000 0.10000000 1.65000000\n-0.75000000 0.10000000 1.70000000\n-0.75000000 0.10000000 1.85000000\n-0.75000000 0.10000000 1.90000000\n-0.75000000 0.10000000 1.95000000\n-0.75000000 0.10000000 2.00000000\n-0.75000000 0.15000000 -1.40000000\n-0.75000000 0.15000000 -1.35000000\n-0.75000000 0.15000000 -1.30000000\n-0.75000000 0.15000000 -1.25000000\n-0.75000000 0.15000000 -1.20000000\n-0.75000000 0.15000000 -1.15000000\n-0.75000000 0.15000000 -1.10000000\n-0.75000000 0.15000000 -1.05000000\n-0.75000000 0.15000000 -1.00000000\n-0.75000000 0.15000000 1.55000000\n-0.75000000 0.15000000 1.60000000\n-0.75000000 0.15000000 1.95000000\n-0.75000000 0.15000000 2.00000000\n-0.75000000 0.15000000 2.05000000\n-0.75000000 0.20000000 -1.45000000\n-0.75000000 0.20000000 -1.40000000\n-0.75000000 0.20000000 -1.35000000\n-0.75000000 0.20000000 -1.05000000\n-0.75000000 0.20000000 -1.00000000\n-0.75000000 0.20000000 -0.95000000\n-0.75000000 0.20000000 -0.45000000\n-0.75000000 0.20000000 -0.40000000\n-0.75000000 0.20000000 -0.35000000\n-0.75000000 0.20000000 -0.30000000\n-0.75000000 0.20000000 -0.25000000\n-0.75000000 0.20000000 -0.20000000\n-0.75000000 0.20000000 -0.15000000\n-0.75000000 0.20000000 -0.10000000\n-0.75000000 0.20000000 -0.05000000\n-0.75000000 0.20000000 0.00000000\n-0.75000000 0.20000000 0.05000000\n-0.75000000 0.20000000 0.10000000\n-0.75000000 0.20000000 0.15000000\n-0.75000000 0.20000000 0.20000000\n-0.75000000 0.20000000 0.25000000\n-0.75000000 0.20000000 0.30000000\n-0.75000000 0.20000000 0.35000000\n-0.75000000 0.20000000 0.40000000\n-0.75000000 0.20000000 0.45000000\n-0.75000000 0.20000000 1.50000000\n-0.75000000 0.20000000 1.55000000\n-0.75000000 0.20000000 2.00000000\n-0.75000000 0.20000000 2.05000000\n-0.75000000 0.25000000 -1.50000000\n-0.75000000 0.25000000 -1.45000000\n-0.75000000 0.25000000 -1.40000000\n-0.75000000 0.25000000 -0.95000000\n-0.75000000 0.25000000 -0.80000000\n-0.75000000 0.25000000 -0.75000000\n-0.75000000 0.25000000 -0.70000000\n-0.75000000 0.25000000 -0.65000000\n-0.75000000 0.25000000 -0.60000000\n-0.75000000 0.25000000 -0.55000000\n-0.75000000 0.25000000 -0.50000000\n-0.75000000 0.25000000 0.50000000\n-0.75000000 0.25000000 0.55000000\n-0.75000000 0.25000000 0.60000000\n-0.75000000 0.25000000 0.65000000\n-0.75000000 0.25000000 0.70000000\n-0.75000000 0.25000000 1.50000000\n-0.75000000 0.25000000 2.05000000\n-0.75000000 0.25000000 2.10000000\n-0.75000000 0.30000000 -1.50000000\n-0.75000000 0.30000000 -1.45000000\n-0.75000000 0.30000000 -1.40000000\n-0.75000000 0.30000000 -0.90000000\n-0.75000000 0.30000000 -0.85000000\n-0.75000000 0.30000000 0.75000000\n-0.75000000 0.30000000 0.80000000\n-0.75000000 0.30000000 0.85000000\n-0.75000000 0.30000000 1.45000000\n-0.75000000 0.30000000 2.05000000\n-0.75000000 0.30000000 2.10000000\n-0.75000000 0.35000000 -1.50000000\n-0.75000000 0.35000000 -1.45000000\n-0.75000000 0.35000000 -1.40000000\n-0.75000000 0.35000000 0.85000000\n-0.75000000 0.35000000 0.90000000\n-0.75000000 0.35000000 1.45000000\n-0.75000000 0.35000000 2.05000000\n-0.75000000 0.35000000 2.10000000\n-0.75000000 0.40000000 -1.50000000\n-0.75000000 0.40000000 0.85000000\n-0.75000000 0.40000000 0.90000000\n-0.75000000 0.40000000 1.45000000\n-0.75000000 0.40000000 2.05000000\n-0.75000000 0.40000000 2.10000000\n-0.75000000 0.45000000 -1.50000000\n-0.75000000 0.45000000 0.85000000\n-0.75000000 0.45000000 0.90000000\n-0.75000000 0.45000000 1.50000000\n-0.75000000 0.45000000 2.05000000\n-0.75000000 0.45000000 2.10000000\n-0.75000000 0.50000000 -1.55000000\n-0.75000000 0.50000000 0.80000000\n-0.75000000 0.50000000 0.85000000\n-0.75000000 0.50000000 1.50000000\n-0.75000000 0.50000000 2.00000000\n-0.75000000 0.50000000 2.05000000\n-0.75000000 0.55000000 -1.60000000\n-0.75000000 0.55000000 0.65000000\n-0.75000000 0.55000000 0.70000000\n-0.75000000 0.55000000 0.75000000\n-0.75000000 0.55000000 1.50000000\n-0.75000000 0.55000000 1.55000000\n-0.75000000 0.55000000 1.60000000\n-0.75000000 0.55000000 1.95000000\n-0.75000000 0.55000000 2.00000000\n-0.75000000 0.55000000 2.05000000\n-0.75000000 0.60000000 -1.60000000\n-0.75000000 0.60000000 0.45000000\n-0.75000000 0.60000000 0.50000000\n-0.75000000 0.60000000 0.55000000\n-0.75000000 0.60000000 0.60000000\n-0.75000000 0.60000000 1.55000000\n-0.75000000 0.60000000 1.60000000\n-0.75000000 0.60000000 1.65000000\n-0.75000000 0.60000000 1.70000000\n-0.75000000 0.60000000 1.85000000\n-0.75000000 0.60000000 1.90000000\n-0.75000000 0.60000000 1.95000000\n-0.75000000 0.60000000 2.00000000\n-0.75000000 0.65000000 -1.60000000\n-0.75000000 0.65000000 0.05000000\n-0.75000000 0.65000000 0.10000000\n-0.75000000 0.65000000 0.15000000\n-0.75000000 0.65000000 0.20000000\n-0.75000000 0.65000000 0.25000000\n-0.75000000 0.65000000 0.30000000\n-0.75000000 0.65000000 0.35000000\n-0.75000000 0.65000000 0.40000000\n-0.75000000 0.65000000 1.65000000\n-0.75000000 0.65000000 1.70000000\n-0.75000000 0.65000000 1.75000000\n-0.75000000 0.65000000 1.80000000\n-0.75000000 0.65000000 1.85000000\n-0.75000000 0.65000000 1.90000000\n-0.75000000 0.65000000 1.95000000\n-0.75000000 0.70000000 -1.60000000\n-0.75000000 0.70000000 -0.20000000\n-0.75000000 0.70000000 -0.15000000\n-0.75000000 0.70000000 -0.10000000\n-0.75000000 0.70000000 -0.05000000\n-0.75000000 0.70000000 0.00000000\n-0.75000000 0.75000000 -1.60000000\n-0.75000000 0.75000000 -0.20000000\n-0.75000000 0.80000000 -1.60000000\n-0.75000000 0.80000000 -0.25000000\n-0.75000000 0.85000000 -1.55000000\n-0.75000000 0.85000000 -0.35000000\n-0.75000000 0.85000000 -0.30000000\n-0.75000000 0.90000000 -1.50000000\n-0.75000000 0.90000000 -1.45000000\n-0.75000000 0.90000000 -0.45000000\n-0.75000000 0.90000000 -0.40000000\n-0.75000000 0.95000000 -1.40000000\n-0.75000000 0.95000000 -1.35000000\n-0.75000000 0.95000000 -1.30000000\n-0.75000000 0.95000000 -0.60000000\n-0.75000000 0.95000000 -0.55000000\n-0.75000000 0.95000000 -0.50000000\n-0.75000000 1.00000000 -1.25000000\n-0.75000000 1.00000000 -1.20000000\n-0.75000000 1.00000000 -1.15000000\n-0.75000000 1.00000000 -1.10000000\n-0.75000000 1.00000000 -1.05000000\n-0.75000000 1.00000000 -1.00000000\n-0.75000000 1.00000000 -0.95000000\n-0.75000000 1.00000000 -0.90000000\n-0.75000000 1.00000000 -0.85000000\n-0.75000000 1.00000000 -0.80000000\n-0.75000000 1.00000000 -0.75000000\n-0.75000000 1.00000000 -0.70000000\n-0.75000000 1.00000000 -0.65000000\n-0.70000000 0.10000000 1.75000000\n-0.70000000 0.10000000 1.80000000\n-0.70000000 0.15000000 1.65000000\n-0.70000000 0.15000000 1.70000000\n-0.70000000 0.15000000 1.85000000\n-0.70000000 0.15000000 1.90000000\n-0.70000000 0.20000000 -1.30000000\n-0.70000000 0.20000000 -1.25000000\n-0.70000000 0.20000000 -1.20000000\n-0.70000000 0.20000000 -1.15000000\n-0.70000000 0.20000000 -1.10000000\n-0.70000000 0.20000000 -0.60000000\n-0.70000000 0.20000000 -0.55000000\n-0.70000000 0.20000000 -0.50000000\n-0.70000000 0.20000000 -0.45000000\n-0.70000000 0.20000000 -0.40000000\n-0.70000000 0.20000000 -0.35000000\n-0.70000000 0.20000000 -0.30000000\n-0.70000000 0.20000000 -0.25000000\n-0.70000000 0.20000000 -0.20000000\n-0.70000000 0.20000000 -0.15000000\n-0.70000000 0.20000000 -0.10000000\n-0.70000000 0.20000000 -0.05000000\n-0.70000000 0.20000000 0.00000000\n-0.70000000 0.20000000 0.05000000\n-0.70000000 0.20000000 0.10000000\n-0.70000000 0.20000000 0.15000000\n-0.70000000 0.20000000 0.20000000\n-0.70000000 0.20000000 0.25000000\n-0.70000000 0.20000000 0.30000000\n-0.70000000 0.20000000 0.35000000\n-0.70000000 0.20000000 0.40000000\n-0.70000000 0.20000000 0.45000000\n-0.70000000 0.20000000 0.50000000\n-0.70000000 0.20000000 0.55000000\n-0.70000000 0.20000000 0.60000000\n-0.70000000 0.20000000 1.60000000\n-0.70000000 0.20000000 1.95000000\n-0.70000000 0.25000000 -1.35000000\n-0.70000000 0.25000000 -1.30000000\n-0.70000000 0.25000000 -1.25000000\n-0.70000000 0.25000000 -1.20000000\n-0.70000000 0.25000000 -1.15000000\n-0.70000000 0.25000000 -1.05000000\n-0.70000000 0.25000000 -1.00000000\n-0.70000000 0.25000000 -0.95000000\n-0.70000000 0.25000000 -0.90000000\n-0.70000000 0.25000000 -0.85000000\n-0.70000000 0.25000000 -0.80000000\n-0.70000000 0.25000000 -0.75000000\n-0.70000000 0.25000000 -0.70000000\n-0.70000000 0.25000000 -0.65000000\n-0.70000000 0.25000000 0.65000000\n-0.70000000 0.25000000 0.70000000\n-0.70000000 0.25000000 0.75000000\n-0.70000000 0.25000000 0.80000000\n-0.70000000 0.25000000 0.85000000\n-0.70000000 0.25000000 1.55000000\n-0.70000000 0.25000000 2.00000000\n-0.70000000 0.30000000 -1.35000000\n-0.70000000 0.30000000 0.90000000\n-0.70000000 0.30000000 0.95000000\n-0.70000000 0.30000000 1.50000000\n-0.70000000 0.30000000 2.00000000\n-0.70000000 0.35000000 -1.35000000\n-0.70000000 0.35000000 0.95000000\n-0.70000000 0.35000000 1.00000000\n-0.70000000 0.35000000 1.50000000\n-0.70000000 0.35000000 2.00000000\n-0.70000000 0.40000000 -1.50000000\n-0.70000000 0.40000000 -1.45000000\n-0.70000000 0.40000000 -1.40000000\n-0.70000000 0.40000000 0.95000000\n-0.70000000 0.40000000 1.00000000\n-0.70000000 0.40000000 1.50000000\n-0.70000000 0.40000000 2.00000000\n-0.70000000 0.45000000 -1.55000000\n-0.70000000 0.45000000 0.95000000\n-0.70000000 0.45000000 1.00000000\n-0.70000000 0.45000000 1.55000000\n-0.70000000 0.45000000 2.00000000\n-0.70000000 0.50000000 -1.60000000\n-0.70000000 0.50000000 0.90000000\n-0.70000000 0.50000000 1.55000000\n-0.70000000 0.50000000 1.60000000\n-0.70000000 0.50000000 1.95000000\n-0.70000000 0.55000000 -1.65000000\n-0.70000000 0.55000000 0.75000000\n-0.70000000 0.55000000 0.80000000\n-0.70000000 0.55000000 0.85000000\n-0.70000000 0.55000000 1.65000000\n-0.70000000 0.55000000 1.70000000\n-0.70000000 0.55000000 1.85000000\n-0.70000000 0.55000000 1.90000000\n-0.70000000 0.60000000 -1.65000000\n-0.70000000 0.60000000 0.55000000\n-0.70000000 0.60000000 0.60000000\n-0.70000000 0.60000000 0.65000000\n-0.70000000 0.60000000 0.70000000\n-0.70000000 0.60000000 1.75000000\n-0.70000000 0.60000000 1.80000000\n-0.70000000 0.65000000 -1.65000000\n-0.70000000 0.65000000 0.25000000\n-0.70000000 0.65000000 0.30000000\n-0.70000000 0.65000000 0.35000000\n-0.70000000 0.65000000 0.40000000\n-0.70000000 0.65000000 0.45000000\n-0.70000000 0.65000000 0.50000000\n-0.70000000 0.70000000 -1.65000000\n-0.70000000 0.70000000 -0.10000000\n-0.70000000 0.70000000 -0.05000000\n-0.70000000 0.70000000 0.00000000\n-0.70000000 0.70000000 0.05000000\n-0.70000000 0.70000000 0.10000000\n-0.70000000 0.70000000 0.15000000\n-0.70000000 0.70000000 0.20000000\n-0.70000000 0.75000000 -1.65000000\n-0.70000000 0.75000000 -0.15000000\n-0.70000000 0.80000000 -1.65000000\n-0.70000000 0.80000000 -0.20000000\n-0.70000000 0.85000000 -1.60000000\n-0.70000000 0.85000000 -0.25000000\n-0.70000000 0.90000000 -1.55000000\n-0.70000000 0.90000000 -1.50000000\n-0.70000000 0.90000000 -0.35000000\n-0.70000000 0.90000000 -0.30000000\n-0.70000000 0.95000000 -1.45000000\n-0.70000000 0.95000000 -1.40000000\n-0.70000000 0.95000000 -0.50000000\n-0.70000000 0.95000000 -0.45000000\n-0.70000000 0.95000000 -0.40000000\n-0.70000000 1.00000000 -1.35000000\n-0.70000000 1.00000000 -1.30000000\n-0.70000000 1.00000000 -1.25000000\n-0.70000000 1.00000000 -1.20000000\n-0.70000000 1.00000000 -0.75000000\n-0.70000000 1.00000000 -0.70000000\n-0.70000000 1.00000000 -0.65000000\n-0.70000000 1.00000000 -0.60000000\n-0.70000000 1.00000000 -0.55000000\n-0.70000000 1.05000000 -1.15000000\n-0.70000000 1.05000000 -1.10000000\n-0.70000000 1.05000000 -1.05000000\n-0.70000000 1.05000000 -1.00000000\n-0.70000000 1.05000000 -0.95000000\n-0.70000000 1.05000000 -0.90000000\n-0.70000000 1.05000000 -0.85000000\n-0.70000000 1.05000000 -0.80000000\n-0.65000000 0.15000000 -0.25000000\n-0.65000000 0.15000000 -0.20000000\n-0.65000000 0.15000000 -0.15000000\n-0.65000000 0.15000000 -0.10000000\n-0.65000000 0.15000000 -0.05000000\n-0.65000000 0.15000000 0.00000000\n-0.65000000 0.15000000 0.05000000\n-0.65000000 0.15000000 0.10000000\n-0.65000000 0.15000000 0.15000000\n-0.65000000 0.15000000 0.20000000\n-0.65000000 0.15000000 0.25000000\n-0.65000000 0.15000000 0.30000000\n-0.65000000 0.15000000 0.35000000\n-0.65000000 0.15000000 1.70000000\n-0.65000000 0.15000000 1.75000000\n-0.65000000 0.15000000 1.80000000\n-0.65000000 0.20000000 -0.75000000\n-0.65000000 0.20000000 -0.70000000\n-0.65000000 0.20000000 -0.65000000\n-0.65000000 0.20000000 -0.60000000\n-0.65000000 0.20000000 -0.55000000\n-0.65000000 0.20000000 -0.50000000\n-0.65000000 0.20000000 -0.45000000\n-0.65000000 0.20000000 -0.40000000\n-0.65000000 0.20000000 -0.35000000\n-0.65000000 0.20000000 -0.30000000\n-0.65000000 0.20000000 0.40000000\n-0.65000000 0.20000000 0.45000000\n-0.65000000 0.20000000 0.50000000\n-0.65000000 0.20000000 0.55000000\n-0.65000000 0.20000000 0.60000000\n-0.65000000 0.20000000 0.65000000\n-0.65000000 0.20000000 0.70000000\n-0.65000000 0.20000000 0.75000000\n-0.65000000 0.20000000 1.60000000\n-0.65000000 0.20000000 1.65000000\n-0.65000000 0.20000000 1.85000000\n-0.65000000 0.20000000 1.90000000\n-0.65000000 0.20000000 1.95000000\n-0.65000000 0.25000000 -1.10000000\n-0.65000000 0.25000000 -1.05000000\n-0.65000000 0.25000000 -1.00000000\n-0.65000000 0.25000000 -0.95000000\n-0.65000000 0.25000000 -0.90000000\n-0.65000000 0.25000000 -0.85000000\n-0.65000000 0.25000000 -0.80000000\n-0.65000000 0.25000000 0.80000000\n-0.65000000 0.25000000 0.85000000\n-0.65000000 0.25000000 0.90000000\n-0.65000000 0.25000000 1.50000000\n-0.65000000 0.25000000 1.55000000\n-0.65000000 0.25000000 2.00000000\n-0.65000000 0.30000000 -1.35000000\n-0.65000000 0.30000000 -1.30000000\n-0.65000000 0.30000000 -1.25000000\n-0.65000000 0.30000000 -1.20000000\n-0.65000000 0.30000000 -1.15000000\n-0.65000000 0.30000000 0.95000000\n-0.65000000 0.30000000 1.00000000\n-0.65000000 0.30000000 1.05000000\n-0.65000000 0.30000000 1.50000000\n-0.65000000 0.30000000 2.00000000\n-0.65000000 0.35000000 -1.45000000\n-0.65000000 0.35000000 -1.40000000\n-0.65000000 0.35000000 1.05000000\n-0.65000000 0.35000000 1.50000000\n-0.65000000 0.35000000 2.00000000\n-0.65000000 0.40000000 -1.55000000\n-0.65000000 0.40000000 -1.50000000\n-0.65000000 0.40000000 1.05000000\n-0.65000000 0.40000000 1.50000000\n-0.65000000 0.40000000 2.00000000\n-0.65000000 0.45000000 -1.60000000\n-0.65000000 0.45000000 1.05000000\n-0.65000000 0.45000000 1.50000000\n-0.65000000 0.45000000 2.00000000\n-0.65000000 0.50000000 -1.65000000\n-0.65000000 0.50000000 0.95000000\n-0.65000000 0.50000000 1.00000000\n-0.65000000 0.50000000 1.55000000\n-0.65000000 0.50000000 1.95000000\n-0.65000000 0.55000000 -1.70000000\n-0.65000000 0.55000000 0.85000000\n-0.65000000 0.55000000 0.90000000\n-0.65000000 0.55000000 1.60000000\n-0.65000000 0.55000000 1.65000000\n-0.65000000 0.55000000 1.70000000\n-0.65000000 0.55000000 1.75000000\n-0.65000000 0.55000000 1.80000000\n-0.65000000 0.55000000 1.85000000\n-0.65000000 0.55000000 1.90000000\n-0.65000000 0.60000000 -1.70000000\n-0.65000000 0.60000000 0.65000000\n-0.65000000 0.60000000 0.70000000\n-0.65000000 0.60000000 0.75000000\n-0.65000000 0.60000000 0.80000000\n-0.65000000 0.65000000 -1.70000000\n-0.65000000 0.65000000 0.40000000\n-0.65000000 0.65000000 0.45000000\n-0.65000000 0.65000000 0.50000000\n-0.65000000 0.65000000 0.55000000\n-0.65000000 0.65000000 0.60000000\n-0.65000000 0.70000000 -1.70000000\n-0.65000000 0.70000000 -0.05000000\n-0.65000000 0.70000000 0.00000000\n-0.65000000 0.70000000 0.05000000\n-0.65000000 0.70000000 0.10000000\n-0.65000000 0.70000000 0.15000000\n-0.65000000 0.70000000 0.20000000\n-0.65000000 0.70000000 0.25000000\n-0.65000000 0.70000000 0.30000000\n-0.65000000 0.70000000 0.35000000\n-0.65000000 0.75000000 -1.70000000\n-0.65000000 0.75000000 -0.10000000\n-0.65000000 0.80000000 -1.70000000\n-0.65000000 0.80000000 -0.15000000\n-0.65000000 0.85000000 -1.65000000\n-0.65000000 0.85000000 -0.20000000\n-0.65000000 0.90000000 -1.60000000\n-0.65000000 0.90000000 -0.30000000\n-0.65000000 0.90000000 -0.25000000\n-0.65000000 0.95000000 -1.55000000\n-0.65000000 0.95000000 -1.50000000\n-0.65000000 0.95000000 -1.45000000\n-0.65000000 0.95000000 -0.40000000\n-0.65000000 0.95000000 -0.35000000\n-0.65000000 1.00000000 -1.40000000\n-0.65000000 1.00000000 -1.35000000\n-0.65000000 1.00000000 -1.30000000\n-0.65000000 1.00000000 -0.60000000\n-0.65000000 1.00000000 -0.55000000\n-0.65000000 1.00000000 -0.50000000\n-0.65000000 1.00000000 -0.45000000\n-0.65000000 1.05000000 -1.25000000\n-0.65000000 1.05000000 -1.20000000\n-0.65000000 1.05000000 -1.15000000\n-0.65000000 1.05000000 -1.10000000\n-0.65000000 1.05000000 -1.05000000\n-0.65000000 1.05000000 -1.00000000\n-0.65000000 1.05000000 -0.95000000\n-0.65000000 1.05000000 -0.90000000\n-0.65000000 1.05000000 -0.85000000\n-0.65000000 1.05000000 -0.80000000\n-0.65000000 1.05000000 -0.75000000\n-0.65000000 1.05000000 -0.70000000\n-0.65000000 1.05000000 -0.65000000\n-0.60000000 0.15000000 -0.45000000\n-0.60000000 0.15000000 -0.40000000\n-0.60000000 0.15000000 -0.35000000\n-0.60000000 0.15000000 -0.30000000\n-0.60000000 0.15000000 -0.25000000\n-0.60000000 0.15000000 -0.20000000\n-0.60000000 0.15000000 -0.15000000\n-0.60000000 0.15000000 -0.10000000\n-0.60000000 0.15000000 -0.05000000\n-0.60000000 0.15000000 0.00000000\n-0.60000000 0.15000000 0.05000000\n-0.60000000 0.15000000 0.10000000\n-0.60000000 0.15000000 0.15000000\n-0.60000000 0.15000000 0.20000000\n-0.60000000 0.15000000 0.25000000\n-0.60000000 0.15000000 0.30000000\n-0.60000000 0.15000000 0.35000000\n-0.60000000 0.15000000 0.40000000\n-0.60000000 0.15000000 0.45000000\n-0.60000000 0.15000000 0.50000000\n-0.60000000 0.15000000 0.55000000\n-0.60000000 0.15000000 1.60000000\n-0.60000000 0.15000000 1.65000000\n-0.60000000 0.15000000 1.70000000\n-0.60000000 0.15000000 1.75000000\n-0.60000000 0.15000000 1.80000000\n-0.60000000 0.15000000 1.85000000\n-0.60000000 0.15000000 1.90000000\n-0.60000000 0.20000000 -0.85000000\n-0.60000000 0.20000000 -0.80000000\n-0.60000000 0.20000000 -0.75000000\n-0.60000000 0.20000000 -0.70000000\n-0.60000000 0.20000000 -0.65000000\n-0.60000000 0.20000000 -0.60000000\n-0.60000000 0.20000000 -0.55000000\n-0.60000000 0.20000000 -0.50000000\n-0.60000000 0.20000000 0.60000000\n-0.60000000 0.20000000 0.65000000\n-0.60000000 0.20000000 0.70000000\n-0.60000000 0.20000000 0.75000000\n-0.60000000 0.20000000 0.80000000\n-0.60000000 0.20000000 0.85000000\n-0.60000000 0.20000000 1.55000000\n-0.60000000 0.20000000 1.95000000\n-0.60000000 0.25000000 -1.20000000\n-0.60000000 0.25000000 -1.15000000\n-0.60000000 0.25000000 -1.10000000\n-0.60000000 0.25000000 -1.05000000\n-0.60000000 0.25000000 -1.00000000\n-0.60000000 0.25000000 -0.95000000\n-0.60000000 0.25000000 -0.90000000\n-0.60000000 0.25000000 0.90000000\n-0.60000000 0.25000000 0.95000000\n-0.60000000 0.25000000 1.00000000\n-0.60000000 0.25000000 1.50000000\n-0.60000000 0.25000000 2.00000000\n-0.60000000 0.30000000 -1.40000000\n-0.60000000 0.30000000 -1.35000000\n-0.60000000 0.30000000 -1.30000000\n-0.60000000 0.30000000 -1.25000000\n-0.60000000 0.30000000 1.05000000\n-0.60000000 0.30000000 1.10000000\n-0.60000000 0.30000000 1.45000000\n-0.60000000 0.30000000 2.05000000\n-0.60000000 0.35000000 -1.50000000\n-0.60000000 0.35000000 -1.45000000\n-0.60000000 0.35000000 1.10000000\n-0.60000000 0.35000000 1.15000000\n-0.60000000 0.35000000 1.45000000\n-0.60000000 0.35000000 2.05000000\n-0.60000000 0.40000000 -1.60000000\n-0.60000000 0.40000000 -1.55000000\n-0.60000000 0.40000000 1.10000000\n-0.60000000 0.40000000 1.15000000\n-0.60000000 0.40000000 1.45000000\n-0.60000000 0.40000000 2.05000000\n-0.60000000 0.45000000 -1.65000000\n-0.60000000 0.45000000 1.10000000\n-0.60000000 0.45000000 1.50000000\n-0.60000000 0.45000000 2.00000000\n-0.60000000 0.50000000 -1.70000000\n-0.60000000 0.50000000 1.05000000\n-0.60000000 0.50000000 1.10000000\n-0.60000000 0.50000000 1.50000000\n-0.60000000 0.50000000 2.00000000\n-0.60000000 0.55000000 -1.70000000\n-0.60000000 0.55000000 0.90000000\n-0.60000000 0.55000000 0.95000000\n-0.60000000 0.55000000 1.00000000\n-0.60000000 0.55000000 1.55000000\n-0.60000000 0.55000000 1.60000000\n-0.60000000 0.55000000 1.65000000\n-0.60000000 0.55000000 1.70000000\n-0.60000000 0.55000000 1.75000000\n-0.60000000 0.55000000 1.80000000\n-0.60000000 0.55000000 1.85000000\n-0.60000000 0.55000000 1.90000000\n-0.60000000 0.55000000 1.95000000\n-0.60000000 0.60000000 -1.75000000\n-0.60000000 0.60000000 0.75000000\n-0.60000000 0.60000000 0.80000000\n-0.60000000 0.60000000 0.85000000\n-0.60000000 0.65000000 -1.75000000\n-0.60000000 0.65000000 0.50000000\n-0.60000000 0.65000000 0.55000000\n-0.60000000 0.65000000 0.60000000\n-0.60000000 0.65000000 0.65000000\n-0.60000000 0.65000000 0.70000000\n-0.60000000 0.70000000 -1.75000000\n-0.60000000 0.70000000 0.05000000\n-0.60000000 0.70000000 0.10000000\n-0.60000000 0.70000000 0.15000000\n-0.60000000 0.70000000 0.20000000\n-0.60000000 0.70000000 0.25000000\n-0.60000000 0.70000000 0.30000000\n-0.60000000 0.70000000 0.35000000\n-0.60000000 0.70000000 0.40000000\n-0.60000000 0.70000000 0.45000000\n-0.60000000 0.75000000 -1.75000000\n-0.60000000 0.75000000 -0.05000000\n-0.60000000 0.75000000 0.00000000\n-0.60000000 0.80000000 -1.75000000\n-0.60000000 0.80000000 -0.10000000\n-0.60000000 0.85000000 -1.70000000\n-0.60000000 0.85000000 -0.15000000\n-0.60000000 0.90000000 -1.65000000\n-0.60000000 0.90000000 -0.25000000\n-0.60000000 0.90000000 -0.20000000\n-0.60000000 0.95000000 -1.60000000\n-0.60000000 0.95000000 -1.55000000\n-0.60000000 0.95000000 -0.35000000\n-0.60000000 0.95000000 -0.30000000\n-0.60000000 1.00000000 -1.50000000\n-0.60000000 1.00000000 -1.45000000\n-0.60000000 1.00000000 -1.40000000\n-0.60000000 1.00000000 -0.50000000\n-0.60000000 1.00000000 -0.45000000\n-0.60000000 1.00000000 -0.40000000\n-0.60000000 1.05000000 -1.35000000\n-0.60000000 1.05000000 -1.30000000\n-0.60000000 1.05000000 -1.25000000\n-0.60000000 1.05000000 -1.20000000\n-0.60000000 1.05000000 -1.15000000\n-0.60000000 1.05000000 -1.10000000\n-0.60000000 1.05000000 -0.85000000\n-0.60000000 1.05000000 -0.80000000\n-0.60000000 1.05000000 -0.75000000\n-0.60000000 1.05000000 -0.70000000\n-0.60000000 1.05000000 -0.65000000\n-0.60000000 1.05000000 -0.60000000\n-0.60000000 1.05000000 -0.55000000\n-0.60000000 1.10000000 -1.05000000\n-0.60000000 1.10000000 -1.00000000\n-0.60000000 1.10000000 -0.95000000\n-0.60000000 1.10000000 -0.90000000\n-0.55000000 0.15000000 -0.60000000\n-0.55000000 0.15000000 -0.55000000\n-0.55000000 0.15000000 -0.50000000\n-0.55000000 0.15000000 -0.45000000\n-0.55000000 0.15000000 -0.40000000\n-0.55000000 0.15000000 -0.35000000\n-0.55000000 0.15000000 -0.30000000\n-0.55000000 0.15000000 -0.25000000\n-0.55000000 0.15000000 -0.20000000\n-0.55000000 0.15000000 -0.15000000\n-0.55000000 0.15000000 -0.10000000\n-0.55000000 0.15000000 -0.05000000\n-0.55000000 0.15000000 0.00000000\n-0.55000000 0.15000000 0.05000000\n-0.55000000 0.15000000 0.10000000\n-0.55000000 0.15000000 0.15000000\n-0.55000000 0.15000000 0.20000000\n-0.55000000 0.15000000 0.25000000\n-0.55000000 0.15000000 0.30000000\n-0.55000000 0.15000000 0.35000000\n-0.55000000 0.15000000 0.40000000\n-0.55000000 0.15000000 0.45000000\n-0.55000000 0.15000000 0.50000000\n-0.55000000 0.15000000 0.55000000\n-0.55000000 0.15000000 0.60000000\n-0.55000000 0.15000000 0.65000000\n-0.55000000 0.15000000 1.60000000\n-0.55000000 0.15000000 1.65000000\n-0.55000000 0.15000000 1.70000000\n-0.55000000 0.15000000 1.75000000\n-0.55000000 0.15000000 1.80000000\n-0.55000000 0.15000000 1.85000000\n-0.55000000 0.15000000 1.90000000\n-0.55000000 0.20000000 -1.05000000\n-0.55000000 0.20000000 -1.00000000\n-0.55000000 0.20000000 -0.95000000\n-0.55000000 0.20000000 -0.90000000\n-0.55000000 0.20000000 -0.85000000\n-0.55000000 0.20000000 -0.80000000\n-0.55000000 0.20000000 -0.75000000\n-0.55000000 0.20000000 -0.70000000\n-0.55000000 0.20000000 -0.65000000\n-0.55000000 0.20000000 0.70000000\n-0.55000000 0.20000000 0.75000000\n-0.55000000 0.20000000 0.80000000\n-0.55000000 0.20000000 0.85000000\n-0.55000000 0.20000000 0.90000000\n-0.55000000 0.20000000 0.95000000\n-0.55000000 0.20000000 1.50000000\n-0.55000000 0.20000000 1.55000000\n-0.55000000 0.20000000 1.95000000\n-0.55000000 0.20000000 2.00000000\n-0.55000000 0.25000000 -1.30000000\n-0.55000000 0.25000000 -1.25000000\n-0.55000000 0.25000000 -1.20000000\n-0.55000000 0.25000000 -1.15000000\n-0.55000000 0.25000000 -1.10000000\n-0.55000000 0.25000000 1.00000000\n-0.55000000 0.25000000 1.05000000\n-0.55000000 0.25000000 1.10000000\n-0.55000000 0.25000000 1.45000000\n-0.55000000 0.25000000 2.05000000\n-0.55000000 0.30000000 -1.45000000\n-0.55000000 0.30000000 -1.40000000\n-0.55000000 0.30000000 -1.35000000\n-0.55000000 0.30000000 1.15000000\n-0.55000000 0.30000000 1.45000000\n-0.55000000 0.30000000 2.05000000\n-0.55000000 0.35000000 -1.55000000\n-0.55000000 0.35000000 -1.50000000\n-0.55000000 0.35000000 1.20000000\n-0.55000000 0.35000000 1.45000000\n-0.55000000 0.35000000 2.05000000\n-0.55000000 0.40000000 -1.60000000\n-0.55000000 0.40000000 1.20000000\n-0.55000000 0.40000000 1.45000000\n-0.55000000 0.40000000 2.05000000\n-0.55000000 0.45000000 -1.65000000\n-0.55000000 0.45000000 1.15000000\n-0.55000000 0.45000000 1.20000000\n-0.55000000 0.45000000 1.45000000\n-0.55000000 0.45000000 2.05000000\n-0.55000000 0.50000000 -1.70000000\n-0.55000000 0.50000000 1.10000000\n-0.55000000 0.50000000 1.15000000\n-0.55000000 0.50000000 1.50000000\n-0.55000000 0.50000000 2.00000000\n-0.55000000 0.55000000 -1.75000000\n-0.55000000 0.55000000 0.95000000\n-0.55000000 0.55000000 1.00000000\n-0.55000000 0.55000000 1.05000000\n-0.55000000 0.55000000 1.55000000\n-0.55000000 0.55000000 1.60000000\n-0.55000000 0.55000000 1.90000000\n-0.55000000 0.55000000 1.95000000\n-0.55000000 0.60000000 -1.75000000\n-0.55000000 0.60000000 0.80000000\n-0.55000000 0.60000000 0.85000000\n-0.55000000 0.60000000 0.90000000\n-0.55000000 0.60000000 1.65000000\n-0.55000000 0.60000000 1.70000000\n-0.55000000 0.60000000 1.75000000\n-0.55000000 0.60000000 1.80000000\n-0.55000000 0.60000000 1.85000000\n-0.55000000 0.65000000 -1.80000000\n-0.55000000 0.65000000 0.55000000\n-0.55000000 0.65000000 0.60000000\n-0.55000000 0.65000000 0.65000000\n-0.55000000 0.65000000 0.70000000\n-0.55000000 0.65000000 0.75000000\n-0.55000000 0.70000000 -1.80000000\n-0.55000000 0.70000000 0.20000000\n-0.55000000 0.70000000 0.25000000\n-0.55000000 0.70000000 0.30000000\n-0.55000000 0.70000000 0.35000000\n-0.55000000 0.70000000 0.40000000\n-0.55000000 0.70000000 0.45000000\n-0.55000000 0.70000000 0.50000000\n-0.55000000 0.75000000 -1.80000000\n-0.55000000 0.75000000 0.00000000\n-0.55000000 0.75000000 0.05000000\n-0.55000000 0.75000000 0.10000000\n-0.55000000 0.75000000 0.15000000\n-0.55000000 0.80000000 -1.75000000\n-0.55000000 0.80000000 -0.05000000\n-0.55000000 0.85000000 -1.75000000\n-0.55000000 0.85000000 -0.10000000\n-0.55000000 0.90000000 -1.70000000\n-0.55000000 0.90000000 -1.65000000\n-0.55000000 0.90000000 -0.20000000\n-0.55000000 0.90000000 -0.15000000\n-0.55000000 0.95000000 -1.60000000\n-0.55000000 0.95000000 -0.30000000\n-0.55000000 0.95000000 -0.25000000\n-0.55000000 1.00000000 -1.55000000\n-0.55000000 1.00000000 -1.50000000\n-0.55000000 1.00000000 -1.45000000\n-0.55000000 1.00000000 -0.45000000\n-0.55000000 1.00000000 -0.40000000\n-0.55000000 1.00000000 -0.35000000\n-0.55000000 1.05000000 -1.40000000\n-0.55000000 1.05000000 -1.35000000\n-0.55000000 1.05000000 -1.30000000\n-0.55000000 1.05000000 -1.25000000\n-0.55000000 1.05000000 -0.65000000\n-0.55000000 1.05000000 -0.60000000\n-0.55000000 1.05000000 -0.55000000\n-0.55000000 1.05000000 -0.50000000\n-0.55000000 1.10000000 -1.20000000\n-0.55000000 1.10000000 -1.15000000\n-0.55000000 1.10000000 -1.10000000\n-0.55000000 1.10000000 -1.05000000\n-0.55000000 1.10000000 -1.00000000\n-0.55000000 1.10000000 -0.95000000\n-0.55000000 1.10000000 -0.90000000\n-0.55000000 1.10000000 -0.85000000\n-0.55000000 1.10000000 -0.80000000\n-0.55000000 1.10000000 -0.75000000\n-0.55000000 1.10000000 -0.70000000\n-0.50000000 0.15000000 -0.70000000\n-0.50000000 0.15000000 -0.65000000\n-0.50000000 0.15000000 -0.60000000\n-0.50000000 0.15000000 -0.55000000\n-0.50000000 0.15000000 -0.50000000\n-0.50000000 0.15000000 -0.45000000\n-0.50000000 0.15000000 -0.40000000\n-0.50000000 0.15000000 -0.35000000\n-0.50000000 0.15000000 -0.30000000\n-0.50000000 0.15000000 -0.25000000\n-0.50000000 0.15000000 -0.20000000\n-0.50000000 0.15000000 -0.15000000\n-0.50000000 0.15000000 -0.10000000\n-0.50000000 0.15000000 -0.05000000\n-0.50000000 0.15000000 0.00000000\n-0.50000000 0.15000000 0.05000000\n-0.50000000 0.15000000 0.10000000\n-0.50000000 0.15000000 0.15000000\n-0.50000000 0.15000000 0.20000000\n-0.50000000 0.15000000 0.25000000\n-0.50000000 0.15000000 0.30000000\n-0.50000000 0.15000000 0.35000000\n-0.50000000 0.15000000 0.40000000\n-0.50000000 0.15000000 0.45000000\n-0.50000000 0.15000000 0.50000000\n-0.50000000 0.15000000 0.55000000\n-0.50000000 0.15000000 0.60000000\n-0.50000000 0.15000000 0.65000000\n-0.50000000 0.15000000 0.70000000\n-0.50000000 0.15000000 0.75000000\n-0.50000000 0.15000000 0.80000000\n-0.50000000 0.15000000 1.55000000\n-0.50000000 0.15000000 1.60000000\n-0.50000000 0.15000000 1.65000000\n-0.50000000 0.15000000 1.70000000\n-0.50000000 0.15000000 1.75000000\n-0.50000000 0.15000000 1.80000000\n-0.50000000 0.15000000 1.85000000\n-0.50000000 0.15000000 1.90000000\n-0.50000000 0.15000000 1.95000000\n-0.50000000 0.20000000 -1.15000000\n-0.50000000 0.20000000 -1.10000000\n-0.50000000 0.20000000 -1.05000000\n-0.50000000 0.20000000 -1.00000000\n-0.50000000 0.20000000 -0.95000000\n-0.50000000 0.20000000 -0.90000000\n-0.50000000 0.20000000 -0.85000000\n-0.50000000 0.20000000 -0.80000000\n-0.50000000 0.20000000 -0.75000000\n-0.50000000 0.20000000 0.85000000\n-0.50000000 0.20000000 0.90000000\n-0.50000000 0.20000000 0.95000000\n-0.50000000 0.20000000 1.00000000\n-0.50000000 0.20000000 1.50000000\n-0.50000000 0.20000000 2.00000000\n-0.50000000 0.25000000 -1.35000000\n-0.50000000 0.25000000 -1.30000000\n-0.50000000 0.25000000 -1.25000000\n-0.50000000 0.25000000 -1.20000000\n-0.50000000 0.25000000 1.05000000\n-0.50000000 0.25000000 1.10000000\n-0.50000000 0.25000000 1.15000000\n-0.50000000 0.25000000 1.45000000\n-0.50000000 0.25000000 2.05000000\n-0.50000000 0.30000000 -1.50000000\n-0.50000000 0.30000000 -1.45000000\n-0.50000000 0.30000000 -1.40000000\n-0.50000000 0.30000000 1.20000000\n-0.50000000 0.30000000 1.45000000\n-0.50000000 0.30000000 2.05000000\n-0.50000000 0.35000000 -1.55000000\n-0.50000000 0.35000000 1.25000000\n-0.50000000 0.35000000 1.45000000\n-0.50000000 0.35000000 2.05000000\n-0.50000000 0.40000000 -1.65000000\n-0.50000000 0.40000000 -1.60000000\n-0.50000000 0.40000000 1.25000000\n-0.50000000 0.40000000 1.45000000\n-0.50000000 0.40000000 2.05000000\n-0.50000000 0.45000000 -1.70000000\n-0.50000000 0.45000000 1.25000000\n-0.50000000 0.45000000 1.45000000\n-0.50000000 0.45000000 2.05000000\n-0.50000000 0.50000000 -1.75000000\n-0.50000000 0.50000000 1.15000000\n-0.50000000 0.50000000 1.20000000\n-0.50000000 0.50000000 1.45000000\n-0.50000000 0.50000000 2.05000000\n-0.50000000 0.55000000 -1.80000000\n-0.50000000 0.55000000 1.05000000\n-0.50000000 0.55000000 1.10000000\n-0.50000000 0.55000000 1.50000000\n-0.50000000 0.55000000 1.55000000\n-0.50000000 0.55000000 1.95000000\n-0.50000000 0.55000000 2.00000000\n-0.50000000 0.60000000 -1.80000000\n-0.50000000 0.60000000 0.85000000\n-0.50000000 0.60000000 0.90000000\n-0.50000000 0.60000000 0.95000000\n-0.50000000 0.60000000 1.00000000\n-0.50000000 0.60000000 1.60000000\n-0.50000000 0.60000000 1.65000000\n-0.50000000 0.60000000 1.70000000\n-0.50000000 0.60000000 1.75000000\n-0.50000000 0.60000000 1.80000000\n-0.50000000 0.60000000 1.85000000\n-0.50000000 0.60000000 1.90000000\n-0.50000000 0.65000000 -1.80000000\n-0.50000000 0.65000000 0.65000000\n-0.50000000 0.65000000 0.70000000\n-0.50000000 0.65000000 0.75000000\n-0.50000000 0.65000000 0.80000000\n-0.50000000 0.70000000 -1.80000000\n-0.50000000 0.70000000 0.30000000\n-0.50000000 0.70000000 0.35000000\n-0.50000000 0.70000000 0.40000000\n-0.50000000 0.70000000 0.45000000\n-0.50000000 0.70000000 0.50000000\n-0.50000000 0.70000000 0.55000000\n-0.50000000 0.70000000 0.60000000\n-0.50000000 0.75000000 -1.80000000\n-0.50000000 0.75000000 0.00000000\n-0.50000000 0.75000000 0.05000000\n-0.50000000 0.75000000 0.10000000\n-0.50000000 0.75000000 0.15000000\n-0.50000000 0.75000000 0.20000000\n-0.50000000 0.75000000 0.25000000\n-0.50000000 0.80000000 -1.80000000\n-0.50000000 0.80000000 -0.05000000\n-0.50000000 0.85000000 -1.75000000\n-0.50000000 0.85000000 -0.10000000\n-0.50000000 0.90000000 -1.70000000\n-0.50000000 0.90000000 -0.15000000\n-0.50000000 0.95000000 -1.65000000\n-0.50000000 0.95000000 -0.25000000\n-0.50000000 0.95000000 -0.20000000\n-0.50000000 1.00000000 -1.60000000\n-0.50000000 1.00000000 -1.55000000\n-0.50000000 1.00000000 -1.50000000\n-0.50000000 1.00000000 -0.40000000\n-0.50000000 1.00000000 -0.35000000\n-0.50000000 1.00000000 -0.30000000\n-0.50000000 1.05000000 -1.45000000\n-0.50000000 1.05000000 -1.40000000\n-0.50000000 1.05000000 -1.35000000\n-0.50000000 1.05000000 -0.55000000\n-0.50000000 1.05000000 -0.50000000\n-0.50000000 1.05000000 -0.45000000\n-0.50000000 1.10000000 -1.30000000\n-0.50000000 1.10000000 -1.25000000\n-0.50000000 1.10000000 -1.20000000\n-0.50000000 1.10000000 -1.15000000\n-0.50000000 1.10000000 -1.10000000\n-0.50000000 1.10000000 -1.05000000\n-0.50000000 1.10000000 -1.00000000\n-0.50000000 1.10000000 -0.95000000\n-0.50000000 1.10000000 -0.90000000\n-0.50000000 1.10000000 -0.85000000\n-0.50000000 1.10000000 -0.80000000\n-0.50000000 1.10000000 -0.75000000\n-0.50000000 1.10000000 -0.70000000\n-0.50000000 1.10000000 -0.65000000\n-0.50000000 1.10000000 -0.60000000\n-0.45000000 0.10000000 -0.20000000\n-0.45000000 0.10000000 -0.15000000\n-0.45000000 0.10000000 -0.10000000\n-0.45000000 0.10000000 -0.05000000\n-0.45000000 0.10000000 0.00000000\n-0.45000000 0.10000000 0.05000000\n-0.45000000 0.10000000 0.10000000\n-0.45000000 0.10000000 0.15000000\n-0.45000000 0.10000000 0.20000000\n-0.45000000 0.10000000 0.25000000\n-0.45000000 0.10000000 0.30000000\n-0.45000000 0.10000000 0.35000000\n-0.45000000 0.10000000 0.40000000\n-0.45000000 0.10000000 1.65000000\n-0.45000000 0.10000000 1.70000000\n-0.45000000 0.10000000 1.75000000\n-0.45000000 0.10000000 1.80000000\n-0.45000000 0.10000000 1.85000000\n-0.45000000 0.15000000 -0.80000000\n-0.45000000 0.15000000 -0.75000000\n-0.45000000 0.15000000 -0.70000000\n-0.45000000 0.15000000 -0.65000000\n-0.45000000 0.15000000 -0.60000000\n-0.45000000 0.15000000 -0.55000000\n-0.45000000 0.15000000 -0.50000000\n-0.45000000 0.15000000 -0.45000000\n-0.45000000 0.15000000 -0.40000000\n-0.45000000 0.15000000 -0.35000000\n-0.45000000 0.15000000 -0.30000000\n-0.45000000 0.15000000 -0.25000000\n-0.45000000 0.15000000 0.45000000\n-0.45000000 0.15000000 0.50000000\n-0.45000000 0.15000000 0.55000000\n-0.45000000 0.15000000 0.60000000\n-0.45000000 0.15000000 0.65000000\n-0.45000000 0.15000000 0.70000000\n-0.45000000 0.15000000 0.75000000\n-0.45000000 0.15000000 0.80000000\n-0.45000000 0.15000000 0.85000000\n-0.45000000 0.15000000 1.55000000\n-0.45000000 0.15000000 1.60000000\n-0.45000000 0.15000000 1.90000000\n-0.45000000 0.15000000 1.95000000\n-0.45000000 0.20000000 -1.20000000\n-0.45000000 0.20000000 -1.15000000\n-0.45000000 0.20000000 -1.10000000\n-0.45000000 0.20000000 -1.05000000\n-0.45000000 0.20000000 -1.00000000\n-0.45000000 0.20000000 -0.95000000\n-0.45000000 0.20000000 -0.90000000\n-0.45000000 0.20000000 -0.85000000\n-0.45000000 0.20000000 0.90000000\n-0.45000000 0.20000000 0.95000000\n-0.45000000 0.20000000 1.00000000\n-0.45000000 0.20000000 1.05000000\n-0.45000000 0.20000000 1.10000000\n-0.45000000 0.20000000 1.50000000\n-0.45000000 0.20000000 2.00000000\n-0.45000000 0.20000000 2.05000000\n-0.45000000 0.25000000 -1.40000000\n-0.45000000 0.25000000 -1.35000000\n-0.45000000 0.25000000 -1.30000000\n-0.45000000 0.25000000 -1.25000000\n-0.45000000 0.25000000 1.15000000\n-0.45000000 0.25000000 1.20000000\n-0.45000000 0.25000000 1.45000000\n-0.45000000 0.25000000 2.05000000\n-0.45000000 0.30000000 -1.50000000\n-0.45000000 0.30000000 -1.45000000\n-0.45000000 0.30000000 1.25000000\n-0.45000000 0.30000000 1.40000000\n-0.45000000 0.30000000 2.10000000\n-0.45000000 0.35000000 -1.60000000\n-0.45000000 0.35000000 -1.55000000\n-0.45000000 0.35000000 1.30000000\n-0.45000000 0.35000000 1.40000000\n-0.45000000 0.35000000 2.10000000\n-0.45000000 0.40000000 -1.65000000\n-0.45000000 0.40000000 1.30000000\n-0.45000000 0.40000000 1.40000000\n-0.45000000 0.40000000 2.10000000\n-0.45000000 0.45000000 -1.75000000\n-0.45000000 0.45000000 -1.70000000\n-0.45000000 0.45000000 1.30000000\n-0.45000000 0.45000000 1.45000000\n-0.45000000 0.45000000 2.10000000\n-0.45000000 0.50000000 -1.80000000\n-0.45000000 0.50000000 1.20000000\n-0.45000000 0.50000000 1.25000000\n-0.45000000 0.50000000 1.45000000\n-0.45000000 0.50000000 2.05000000\n-0.45000000 0.55000000 -1.80000000\n-0.45000000 0.55000000 1.10000000\n-0.45000000 0.55000000 1.15000000\n-0.45000000 0.55000000 1.50000000\n-0.45000000 0.55000000 1.55000000\n-0.45000000 0.55000000 1.95000000\n-0.45000000 0.55000000 2.00000000\n-0.45000000 0.60000000 -1.80000000\n-0.45000000 0.60000000 0.90000000\n-0.45000000 0.60000000 0.95000000\n-0.45000000 0.60000000 1.00000000\n-0.45000000 0.60000000 1.05000000\n-0.45000000 0.60000000 1.60000000\n-0.45000000 0.60000000 1.65000000\n-0.45000000 0.60000000 1.70000000\n-0.45000000 0.60000000 1.75000000\n-0.45000000 0.60000000 1.80000000\n-0.45000000 0.60000000 1.85000000\n-0.45000000 0.60000000 1.90000000\n-0.45000000 0.65000000 -1.85000000\n-0.45000000 0.65000000 0.70000000\n-0.45000000 0.65000000 0.75000000\n-0.45000000 0.65000000 0.80000000\n-0.45000000 0.65000000 0.85000000\n-0.45000000 0.70000000 -1.85000000\n-0.45000000 0.70000000 0.40000000\n-0.45000000 0.70000000 0.45000000\n-0.45000000 0.70000000 0.50000000\n-0.45000000 0.70000000 0.55000000\n-0.45000000 0.70000000 0.60000000\n-0.45000000 0.70000000 0.65000000\n-0.45000000 0.75000000 -1.85000000\n-0.45000000 0.75000000 0.05000000\n-0.45000000 0.75000000 0.10000000\n-0.45000000 0.75000000 0.15000000\n-0.45000000 0.75000000 0.20000000\n-0.45000000 0.75000000 0.25000000\n-0.45000000 0.75000000 0.30000000\n-0.45000000 0.75000000 0.35000000\n-0.45000000 0.80000000 -1.80000000\n-0.45000000 0.80000000 0.00000000\n-0.45000000 0.85000000 -1.80000000\n-0.45000000 0.85000000 -0.05000000\n-0.45000000 0.90000000 -1.75000000\n-0.45000000 0.90000000 -0.15000000\n-0.45000000 0.90000000 -0.10000000\n-0.45000000 0.95000000 -1.70000000\n-0.45000000 0.95000000 -0.20000000\n-0.45000000 1.00000000 -1.65000000\n-0.45000000 1.00000000 -1.60000000\n-0.45000000 1.00000000 -1.55000000\n-0.45000000 1.00000000 -0.35000000\n-0.45000000 1.00000000 -0.30000000\n-0.45000000 1.00000000 -0.25000000\n-0.45000000 1.05000000 -1.50000000\n-0.45000000 1.05000000 -1.45000000\n-0.45000000 1.05000000 -1.40000000\n-0.45000000 1.05000000 -0.50000000\n-0.45000000 1.05000000 -0.45000000\n-0.45000000 1.05000000 -0.40000000\n-0.45000000 1.10000000 -1.35000000\n-0.45000000 1.10000000 -1.30000000\n-0.45000000 1.10000000 -1.25000000\n-0.45000000 1.10000000 -1.20000000\n-0.45000000 1.10000000 -1.15000000\n-0.45000000 1.10000000 -1.10000000\n-0.45000000 1.10000000 -1.05000000\n-0.45000000 1.10000000 -1.00000000\n-0.45000000 1.10000000 -0.95000000\n-0.45000000 1.10000000 -0.90000000\n-0.45000000 1.10000000 -0.85000000\n-0.45000000 1.10000000 -0.80000000\n-0.45000000 1.10000000 -0.75000000\n-0.45000000 1.10000000 -0.70000000\n-0.45000000 1.10000000 -0.65000000\n-0.45000000 1.10000000 -0.60000000\n-0.45000000 1.10000000 -0.55000000\n-0.40000000 0.10000000 -0.40000000\n-0.40000000 0.10000000 -0.35000000\n-0.40000000 0.10000000 -0.30000000\n-0.40000000 0.10000000 -0.25000000\n-0.40000000 0.10000000 -0.20000000\n-0.40000000 0.10000000 -0.15000000\n-0.40000000 0.10000000 -0.10000000\n-0.40000000 0.10000000 -0.05000000\n-0.40000000 0.10000000 0.00000000\n-0.40000000 0.10000000 0.05000000\n-0.40000000 0.10000000 0.10000000\n-0.40000000 0.10000000 0.15000000\n-0.40000000 0.10000000 0.20000000\n-0.40000000 0.10000000 0.25000000\n-0.40000000 0.10000000 0.30000000\n-0.40000000 0.10000000 0.35000000\n-0.40000000 0.10000000 0.40000000\n-0.40000000 0.10000000 0.45000000\n-0.40000000 0.10000000 0.50000000\n-0.40000000 0.10000000 0.55000000\n-0.40000000 0.10000000 1.65000000\n-0.40000000 0.10000000 1.70000000\n-0.40000000 0.10000000 1.75000000\n-0.40000000 0.10000000 1.80000000\n-0.40000000 0.10000000 1.85000000\n-0.40000000 0.10000000 1.90000000\n-0.40000000 0.15000000 -0.90000000\n-0.40000000 0.15000000 -0.85000000\n-0.40000000 0.15000000 -0.80000000\n-0.40000000 0.15000000 -0.75000000\n-0.40000000 0.15000000 -0.70000000\n-0.40000000 0.15000000 -0.65000000\n-0.40000000 0.15000000 -0.60000000\n-0.40000000 0.15000000 -0.55000000\n-0.40000000 0.15000000 -0.50000000\n-0.40000000 0.15000000 -0.45000000\n-0.40000000 0.15000000 0.60000000\n-0.40000000 0.15000000 0.65000000\n-0.40000000 0.15000000 0.70000000\n-0.40000000 0.15000000 0.75000000\n-0.40000000 0.15000000 0.80000000\n-0.40000000 0.15000000 0.85000000\n-0.40000000 0.15000000 0.90000000\n-0.40000000 0.15000000 0.95000000\n-0.40000000 0.15000000 1.50000000\n-0.40000000 0.15000000 1.55000000\n-0.40000000 0.15000000 1.60000000\n-0.40000000 0.15000000 1.95000000\n-0.40000000 0.15000000 2.00000000\n-0.40000000 0.20000000 -1.25000000\n-0.40000000 0.20000000 -1.20000000\n-0.40000000 0.20000000 -1.15000000\n-0.40000000 0.20000000 -1.10000000\n-0.40000000 0.20000000 -1.05000000\n-0.40000000 0.20000000 -1.00000000\n-0.40000000 0.20000000 -0.95000000\n-0.40000000 0.20000000 1.00000000\n-0.40000000 0.20000000 1.05000000\n-0.40000000 0.20000000 1.10000000\n-0.40000000 0.20000000 1.45000000\n-0.40000000 0.20000000 2.05000000\n-0.40000000 0.25000000 -1.40000000\n-0.40000000 0.25000000 -1.35000000\n-0.40000000 0.25000000 -1.30000000\n-0.40000000 0.25000000 1.15000000\n-0.40000000 0.25000000 1.20000000\n-0.40000000 0.25000000 1.25000000\n-0.40000000 0.25000000 1.45000000\n-0.40000000 0.25000000 2.10000000\n-0.40000000 0.30000000 -1.55000000\n-0.40000000 0.30000000 -1.50000000\n-0.40000000 0.30000000 -1.45000000\n-0.40000000 0.30000000 1.30000000\n-0.40000000 0.30000000 1.40000000\n-0.40000000 0.30000000 2.10000000\n-0.40000000 0.35000000 -1.60000000\n-0.40000000 0.35000000 1.35000000\n-0.40000000 0.35000000 2.10000000\n-0.40000000 0.40000000 -1.70000000\n-0.40000000 0.40000000 -1.65000000\n-0.40000000 0.40000000 1.35000000\n-0.40000000 0.40000000 2.10000000\n-0.40000000 0.45000000 -1.75000000\n-0.40000000 0.45000000 1.30000000\n-0.40000000 0.45000000 1.40000000\n-0.40000000 0.45000000 2.10000000\n-0.40000000 0.50000000 -1.80000000\n-0.40000000 0.50000000 1.25000000\n-0.40000000 0.50000000 1.30000000\n-0.40000000 0.50000000 1.45000000\n-0.40000000 0.50000000 2.05000000\n-0.40000000 0.55000000 -1.85000000\n-0.40000000 0.55000000 1.10000000\n-0.40000000 0.55000000 1.15000000\n-0.40000000 0.55000000 1.20000000\n-0.40000000 0.55000000 1.50000000\n-0.40000000 0.55000000 2.00000000\n-0.40000000 0.60000000 -1.85000000\n-0.40000000 0.60000000 0.95000000\n-0.40000000 0.60000000 1.00000000\n-0.40000000 0.60000000 1.05000000\n-0.40000000 0.60000000 1.55000000\n-0.40000000 0.60000000 1.60000000\n-0.40000000 0.60000000 1.65000000\n-0.40000000 0.60000000 1.70000000\n-0.40000000 0.60000000 1.75000000\n-0.40000000 0.60000000 1.80000000\n-0.40000000 0.60000000 1.85000000\n-0.40000000 0.60000000 1.90000000\n-0.40000000 0.60000000 1.95000000\n-0.40000000 0.65000000 -1.85000000\n-0.40000000 0.65000000 0.75000000\n-0.40000000 0.65000000 0.80000000\n-0.40000000 0.65000000 0.85000000\n-0.40000000 0.65000000 0.90000000\n-0.40000000 0.70000000 -1.85000000\n-0.40000000 0.70000000 0.45000000\n-0.40000000 0.70000000 0.50000000\n-0.40000000 0.70000000 0.55000000\n-0.40000000 0.70000000 0.60000000\n-0.40000000 0.70000000 0.65000000\n-0.40000000 0.70000000 0.70000000\n-0.40000000 0.75000000 -1.85000000\n-0.40000000 0.75000000 0.05000000\n-0.40000000 0.75000000 0.10000000\n-0.40000000 0.75000000 0.15000000\n-0.40000000 0.75000000 0.20000000\n-0.40000000 0.75000000 0.25000000\n-0.40000000 0.75000000 0.30000000\n-0.40000000 0.75000000 0.35000000\n-0.40000000 0.75000000 0.40000000\n-0.40000000 0.80000000 -1.85000000\n-0.40000000 0.80000000 0.00000000\n-0.40000000 0.85000000 -1.80000000\n-0.40000000 0.85000000 -0.05000000\n-0.40000000 0.90000000 -1.75000000\n-0.40000000 0.90000000 -0.10000000\n-0.40000000 0.95000000 -1.70000000\n-0.40000000 0.95000000 -0.20000000\n-0.40000000 0.95000000 -0.15000000\n-0.40000000 1.00000000 -1.65000000\n-0.40000000 1.00000000 -1.60000000\n-0.40000000 1.00000000 -0.30000000\n-0.40000000 1.00000000 -0.25000000\n-0.40000000 1.05000000 -1.55000000\n-0.40000000 1.05000000 -1.50000000\n-0.40000000 1.05000000 -1.45000000\n-0.40000000 1.05000000 -0.45000000\n-0.40000000 1.05000000 -0.40000000\n-0.40000000 1.05000000 -0.35000000\n-0.40000000 1.10000000 -1.40000000\n-0.40000000 1.10000000 -1.35000000\n-0.40000000 1.10000000 -1.30000000\n-0.40000000 1.10000000 -1.25000000\n-0.40000000 1.10000000 -1.20000000\n-0.40000000 1.10000000 -0.80000000\n-0.40000000 1.10000000 -0.75000000\n-0.40000000 1.10000000 -0.70000000\n-0.40000000 1.10000000 -0.65000000\n-0.40000000 1.10000000 -0.60000000\n-0.40000000 1.10000000 -0.55000000\n-0.40000000 1.10000000 -0.50000000\n-0.40000000 1.15000000 -1.15000000\n-0.40000000 1.15000000 -1.10000000\n-0.40000000 1.15000000 -1.05000000\n-0.40000000 1.15000000 -1.00000000\n-0.40000000 1.15000000 -0.95000000\n-0.40000000 1.15000000 -0.90000000\n-0.40000000 1.15000000 -0.85000000\n-0.35000000 0.10000000 -0.50000000\n-0.35000000 0.10000000 -0.45000000\n-0.35000000 0.10000000 -0.40000000\n-0.35000000 0.10000000 -0.35000000\n-0.35000000 0.10000000 -0.30000000\n-0.35000000 0.10000000 -0.25000000\n-0.35000000 0.10000000 -0.20000000\n-0.35000000 0.10000000 -0.15000000\n-0.35000000 0.10000000 -0.10000000\n-0.35000000 0.10000000 -0.05000000\n-0.35000000 0.10000000 0.00000000\n-0.35000000 0.10000000 0.05000000\n-0.35000000 0.10000000 0.10000000\n-0.35000000 0.10000000 0.15000000\n-0.35000000 0.10000000 0.20000000\n-0.35000000 0.10000000 0.25000000\n-0.35000000 0.10000000 0.30000000\n-0.35000000 0.10000000 0.35000000\n-0.35000000 0.10000000 0.40000000\n-0.35000000 0.10000000 0.45000000\n-0.35000000 0.10000000 0.50000000\n-0.35000000 0.10000000 0.55000000\n-0.35000000 0.10000000 0.60000000\n-0.35000000 0.10000000 0.65000000\n-0.35000000 0.10000000 1.60000000\n-0.35000000 0.10000000 1.65000000\n-0.35000000 0.10000000 1.70000000\n-0.35000000 0.10000000 1.75000000\n-0.35000000 0.10000000 1.80000000\n-0.35000000 0.10000000 1.85000000\n-0.35000000 0.10000000 1.90000000\n-0.35000000 0.15000000 -1.05000000\n-0.35000000 0.15000000 -1.00000000\n-0.35000000 0.15000000 -0.95000000\n-0.35000000 0.15000000 -0.90000000\n-0.35000000 0.15000000 -0.85000000\n-0.35000000 0.15000000 -0.80000000\n-0.35000000 0.15000000 -0.75000000\n-0.35000000 0.15000000 -0.70000000\n-0.35000000 0.15000000 -0.65000000\n-0.35000000 0.15000000 -0.60000000\n-0.35000000 0.15000000 -0.55000000\n-0.35000000 0.15000000 0.70000000\n-0.35000000 0.15000000 0.75000000\n-0.35000000 0.15000000 0.80000000\n-0.35000000 0.15000000 0.85000000\n-0.35000000 0.15000000 0.90000000\n-0.35000000 0.15000000 0.95000000\n-0.35000000 0.15000000 1.00000000\n-0.35000000 0.15000000 1.50000000\n-0.35000000 0.15000000 1.55000000\n-0.35000000 0.15000000 1.95000000\n-0.35000000 0.15000000 2.00000000\n-0.35000000 0.20000000 -1.30000000\n-0.35000000 0.20000000 -1.25000000\n-0.35000000 0.20000000 -1.20000000\n-0.35000000 0.20000000 -1.15000000\n-0.35000000 0.20000000 -1.10000000\n-0.35000000 0.20000000 1.05000000\n-0.35000000 0.20000000 1.10000000\n-0.35000000 0.20000000 1.15000000\n-0.35000000 0.20000000 1.45000000\n-0.35000000 0.20000000 2.05000000\n-0.35000000 0.25000000 -1.45000000\n-0.35000000 0.25000000 -1.40000000\n-0.35000000 0.25000000 -1.35000000\n-0.35000000 0.25000000 1.20000000\n-0.35000000 0.25000000 1.25000000\n-0.35000000 0.25000000 1.30000000\n-0.35000000 0.25000000 1.40000000\n-0.35000000 0.25000000 2.10000000\n-0.35000000 0.30000000 -1.55000000\n-0.35000000 0.30000000 -1.50000000\n-0.35000000 0.30000000 1.35000000\n-0.35000000 0.30000000 2.10000000\n-0.35000000 0.35000000 -1.65000000\n-0.35000000 0.35000000 -1.60000000\n-0.35000000 0.35000000 2.10000000\n-0.35000000 0.40000000 -1.75000000\n-0.35000000 0.40000000 -1.70000000\n-0.35000000 0.40000000 2.10000000\n-0.35000000 0.45000000 -1.80000000\n-0.35000000 0.45000000 1.35000000\n-0.35000000 0.45000000 2.10000000\n-0.35000000 0.50000000 -1.80000000\n-0.35000000 0.50000000 1.35000000\n-0.35000000 0.50000000 1.40000000\n-0.35000000 0.50000000 2.05000000\n-0.35000000 0.55000000 -1.85000000\n-0.35000000 0.55000000 1.20000000\n-0.35000000 0.55000000 1.25000000\n-0.35000000 0.55000000 1.30000000\n-0.35000000 0.55000000 1.35000000\n-0.35000000 0.55000000 1.45000000\n-0.35000000 0.55000000 1.50000000\n-0.35000000 0.55000000 2.00000000\n-0.35000000 0.55000000 2.05000000\n-0.35000000 0.60000000 -1.85000000\n-0.35000000 0.60000000 1.00000000\n-0.35000000 0.60000000 1.05000000\n-0.35000000 0.60000000 1.10000000\n-0.35000000 0.60000000 1.15000000\n-0.35000000 0.60000000 1.55000000\n-0.35000000 0.60000000 1.60000000\n-0.35000000 0.60000000 1.65000000\n-0.35000000 0.60000000 1.70000000\n-0.35000000 0.60000000 1.80000000\n-0.35000000 0.60000000 1.85000000\n-0.35000000 0.60000000 1.90000000\n-0.35000000 0.60000000 1.95000000\n-0.35000000 0.65000000 -1.90000000\n-0.35000000 0.65000000 0.80000000\n-0.35000000 0.65000000 0.85000000\n-0.35000000 0.65000000 0.90000000\n-0.35000000 0.65000000 0.95000000\n-0.35000000 0.65000000 1.75000000\n-0.35000000 0.70000000 -1.90000000\n-0.35000000 0.70000000 0.50000000\n-0.35000000 0.70000000 0.55000000\n-0.35000000 0.70000000 0.60000000\n-0.35000000 0.70000000 0.65000000\n-0.35000000 0.70000000 0.70000000\n-0.35000000 0.70000000 0.75000000\n-0.35000000 0.75000000 -1.85000000\n-0.35000000 0.75000000 0.10000000\n-0.35000000 0.75000000 0.15000000\n-0.35000000 0.75000000 0.20000000\n-0.35000000 0.75000000 0.25000000\n-0.35000000 0.75000000 0.30000000\n-0.35000000 0.75000000 0.35000000\n-0.35000000 0.75000000 0.40000000\n-0.35000000 0.75000000 0.45000000\n-0.35000000 0.80000000 -1.85000000\n-0.35000000 0.80000000 0.05000000\n-0.35000000 0.85000000 -1.85000000\n-0.35000000 0.85000000 0.00000000\n-0.35000000 0.90000000 -1.80000000\n-0.35000000 0.90000000 -0.10000000\n-0.35000000 0.90000000 -0.05000000\n-0.35000000 0.95000000 -1.75000000\n-0.35000000 0.95000000 -1.70000000\n-0.35000000 0.95000000 -0.15000000\n-0.35000000 1.00000000 -1.65000000\n-0.35000000 1.00000000 -1.60000000\n-0.35000000 1.00000000 -0.30000000\n-0.35000000 1.00000000 -0.25000000\n-0.35000000 1.00000000 -0.20000000\n-0.35000000 1.05000000 -1.55000000\n-0.35000000 1.05000000 -1.50000000\n-0.35000000 1.05000000 -0.45000000\n-0.35000000 1.05000000 -0.40000000\n-0.35000000 1.05000000 -0.35000000\n-0.35000000 1.10000000 -1.45000000\n-0.35000000 1.10000000 -1.40000000\n-0.35000000 1.10000000 -1.35000000\n-0.35000000 1.10000000 -1.30000000\n-0.35000000 1.10000000 -1.25000000\n-0.35000000 1.10000000 -0.70000000\n-0.35000000 1.10000000 -0.65000000\n-0.35000000 1.10000000 -0.60000000\n-0.35000000 1.10000000 -0.55000000\n-0.35000000 1.10000000 -0.50000000\n-0.35000000 1.15000000 -1.20000000\n-0.35000000 1.15000000 -1.15000000\n-0.35000000 1.15000000 -1.10000000\n-0.35000000 1.15000000 -1.05000000\n-0.35000000 1.15000000 -1.00000000\n-0.35000000 1.15000000 -0.95000000\n-0.35000000 1.15000000 -0.90000000\n-0.35000000 1.15000000 -0.85000000\n-0.35000000 1.15000000 -0.80000000\n-0.35000000 1.15000000 -0.75000000\n-0.30000000 0.10000000 -0.55000000\n-0.30000000 0.10000000 -0.50000000\n-0.30000000 0.10000000 -0.45000000\n-0.30000000 0.10000000 -0.40000000\n-0.30000000 0.10000000 -0.35000000\n-0.30000000 0.10000000 -0.30000000\n-0.30000000 0.10000000 -0.25000000\n-0.30000000 0.10000000 -0.20000000\n-0.30000000 0.10000000 -0.15000000\n-0.30000000 0.10000000 -0.10000000\n-0.30000000 0.10000000 -0.05000000\n-0.30000000 0.10000000 0.00000000\n-0.30000000 0.10000000 0.05000000\n-0.30000000 0.10000000 0.10000000\n-0.30000000 0.10000000 0.15000000\n-0.30000000 0.10000000 0.20000000\n-0.30000000 0.10000000 0.25000000\n-0.30000000 0.10000000 0.30000000\n-0.30000000 0.10000000 0.35000000\n-0.30000000 0.10000000 0.40000000\n-0.30000000 0.10000000 0.45000000\n-0.30000000 0.10000000 0.50000000\n-0.30000000 0.10000000 0.55000000\n-0.30000000 0.10000000 0.60000000\n-0.30000000 0.10000000 0.65000000\n-0.30000000 0.10000000 0.70000000\n-0.30000000 0.10000000 1.60000000\n-0.30000000 0.10000000 1.65000000\n-0.30000000 0.10000000 1.70000000\n-0.30000000 0.10000000 1.75000000\n-0.30000000 0.10000000 1.80000000\n-0.30000000 0.10000000 1.85000000\n-0.30000000 0.10000000 1.90000000\n-0.30000000 0.15000000 -1.10000000\n-0.30000000 0.15000000 -1.05000000\n-0.30000000 0.15000000 -1.00000000\n-0.30000000 0.15000000 -0.95000000\n-0.30000000 0.15000000 -0.90000000\n-0.30000000 0.15000000 -0.85000000\n-0.30000000 0.15000000 -0.80000000\n-0.30000000 0.15000000 -0.75000000\n-0.30000000 0.15000000 -0.70000000\n-0.30000000 0.15000000 -0.65000000\n-0.30000000 0.15000000 -0.60000000\n-0.30000000 0.15000000 0.75000000\n-0.30000000 0.15000000 0.80000000\n-0.30000000 0.15000000 0.85000000\n-0.30000000 0.15000000 0.90000000\n-0.30000000 0.15000000 0.95000000\n-0.30000000 0.15000000 1.00000000\n-0.30000000 0.15000000 1.50000000\n-0.30000000 0.15000000 1.55000000\n-0.30000000 0.15000000 1.95000000\n-0.30000000 0.15000000 2.00000000\n-0.30000000 0.20000000 -1.35000000\n-0.30000000 0.20000000 -1.30000000\n-0.30000000 0.20000000 -1.25000000\n-0.30000000 0.20000000 -1.20000000\n-0.30000000 0.20000000 -1.15000000\n-0.30000000 0.20000000 1.05000000\n-0.30000000 0.20000000 1.10000000\n-0.30000000 0.20000000 1.15000000\n-0.30000000 0.20000000 1.20000000\n-0.30000000 0.20000000 1.25000000\n-0.30000000 0.20000000 1.30000000\n-0.30000000 0.20000000 1.35000000\n-0.30000000 0.20000000 1.45000000\n-0.30000000 0.20000000 2.05000000\n-0.30000000 0.25000000 -1.45000000\n-0.30000000 0.25000000 -1.40000000\n-0.30000000 0.25000000 1.35000000\n-0.30000000 0.25000000 1.40000000\n-0.30000000 0.25000000 2.10000000\n-0.30000000 0.30000000 -1.60000000\n-0.30000000 0.30000000 -1.55000000\n-0.30000000 0.30000000 -1.50000000\n-0.30000000 0.30000000 2.10000000\n-0.30000000 0.35000000 -1.70000000\n-0.30000000 0.35000000 -1.65000000\n-0.30000000 0.35000000 2.10000000\n-0.30000000 0.40000000 -1.75000000\n-0.30000000 0.40000000 2.10000000\n-0.30000000 0.45000000 -1.80000000\n-0.30000000 0.45000000 2.10000000\n-0.30000000 0.50000000 -1.85000000\n-0.30000000 0.50000000 2.10000000\n-0.30000000 0.55000000 -1.85000000\n-0.30000000 0.55000000 1.40000000\n-0.30000000 0.55000000 1.45000000\n-0.30000000 0.55000000 1.50000000\n-0.30000000 0.55000000 2.00000000\n-0.30000000 0.55000000 2.05000000\n-0.30000000 0.60000000 -1.90000000\n-0.30000000 0.60000000 1.20000000\n-0.30000000 0.60000000 1.25000000\n-0.30000000 0.60000000 1.30000000\n-0.30000000 0.60000000 1.35000000\n-0.30000000 0.60000000 1.40000000\n-0.30000000 0.60000000 1.55000000\n-0.30000000 0.60000000 1.60000000\n-0.30000000 0.60000000 1.65000000\n-0.30000000 0.60000000 1.90000000\n-0.30000000 0.60000000 1.95000000\n-0.30000000 0.65000000 -1.90000000\n-0.30000000 0.65000000 1.00000000\n-0.30000000 0.65000000 1.05000000\n-0.30000000 0.65000000 1.10000000\n-0.30000000 0.65000000 1.15000000\n-0.30000000 0.65000000 1.20000000\n-0.30000000 0.65000000 1.70000000\n-0.30000000 0.65000000 1.75000000\n-0.30000000 0.65000000 1.80000000\n-0.30000000 0.65000000 1.85000000\n-0.30000000 0.70000000 -1.90000000\n-0.30000000 0.70000000 0.60000000\n-0.30000000 0.70000000 0.65000000\n-0.30000000 0.70000000 0.70000000\n-0.30000000 0.70000000 0.75000000\n-0.30000000 0.70000000 0.80000000\n-0.30000000 0.70000000 0.85000000\n-0.30000000 0.70000000 0.90000000\n-0.30000000 0.70000000 0.95000000\n-0.30000000 0.75000000 -1.90000000\n-0.30000000 0.75000000 0.15000000\n-0.30000000 0.75000000 0.20000000\n-0.30000000 0.75000000 0.25000000\n-0.30000000 0.75000000 0.30000000\n-0.30000000 0.75000000 0.35000000\n-0.30000000 0.75000000 0.40000000\n-0.30000000 0.75000000 0.45000000\n-0.30000000 0.75000000 0.50000000\n-0.30000000 0.75000000 0.55000000\n-0.30000000 0.80000000 -1.85000000\n-0.30000000 0.80000000 0.05000000\n-0.30000000 0.80000000 0.10000000\n-0.30000000 0.85000000 -1.85000000\n-0.30000000 0.85000000 0.00000000\n-0.30000000 0.90000000 -1.80000000\n-0.30000000 0.90000000 -0.05000000\n-0.30000000 0.95000000 -1.75000000\n-0.30000000 0.95000000 -0.15000000\n-0.30000000 0.95000000 -0.10000000\n-0.30000000 1.00000000 -1.70000000\n-0.30000000 1.00000000 -1.65000000\n-0.30000000 1.00000000 -0.25000000\n-0.30000000 1.00000000 -0.20000000\n-0.30000000 1.05000000 -1.60000000\n-0.30000000 1.05000000 -1.55000000\n-0.30000000 1.05000000 -1.50000000\n-0.30000000 1.05000000 -0.40000000\n-0.30000000 1.05000000 -0.35000000\n-0.30000000 1.05000000 -0.30000000\n-0.30000000 1.10000000 -1.45000000\n-0.30000000 1.10000000 -1.40000000\n-0.30000000 1.10000000 -1.35000000\n-0.30000000 1.10000000 -1.30000000\n-0.30000000 1.10000000 -0.60000000\n-0.30000000 1.10000000 -0.55000000\n-0.30000000 1.10000000 -0.50000000\n-0.30000000 1.10000000 -0.45000000\n-0.30000000 1.15000000 -1.25000000\n-0.30000000 1.15000000 -1.20000000\n-0.30000000 1.15000000 -1.15000000\n-0.30000000 1.15000000 -1.10000000\n-0.30000000 1.15000000 -1.05000000\n-0.30000000 1.15000000 -1.00000000\n-0.30000000 1.15000000 -0.95000000\n-0.30000000 1.15000000 -0.90000000\n-0.30000000 1.15000000 -0.85000000\n-0.30000000 1.15000000 -0.80000000\n-0.30000000 1.15000000 -0.75000000\n-0.30000000 1.15000000 -0.70000000\n-0.30000000 1.15000000 -0.65000000\n-0.25000000 0.10000000 -0.60000000\n-0.25000000 0.10000000 -0.55000000\n-0.25000000 0.10000000 -0.50000000\n-0.25000000 0.10000000 -0.45000000\n-0.25000000 0.10000000 -0.40000000\n-0.25000000 0.10000000 -0.35000000\n-0.25000000 0.10000000 -0.30000000\n-0.25000000 0.10000000 -0.25000000\n-0.25000000 0.10000000 -0.20000000\n-0.25000000 0.10000000 -0.15000000\n-0.25000000 0.10000000 -0.10000000\n-0.25000000 0.10000000 -0.05000000\n-0.25000000 0.10000000 0.00000000\n-0.25000000 0.10000000 0.05000000\n-0.25000000 0.10000000 0.10000000\n-0.25000000 0.10000000 0.15000000\n-0.25000000 0.10000000 0.20000000\n-0.25000000 0.10000000 0.25000000\n-0.25000000 0.10000000 0.30000000\n-0.25000000 0.10000000 0.35000000\n-0.25000000 0.10000000 0.40000000\n-0.25000000 0.10000000 0.45000000\n-0.25000000 0.10000000 0.50000000\n-0.25000000 0.10000000 0.55000000\n-0.25000000 0.10000000 0.60000000\n-0.25000000 0.10000000 0.65000000\n-0.25000000 0.10000000 0.70000000\n-0.25000000 0.10000000 0.75000000\n-0.25000000 0.10000000 1.60000000\n-0.25000000 0.10000000 1.65000000\n-0.25000000 0.10000000 1.70000000\n-0.25000000 0.10000000 1.75000000\n-0.25000000 0.10000000 1.80000000\n-0.25000000 0.10000000 1.85000000\n-0.25000000 0.10000000 1.90000000\n-0.25000000 0.10000000 1.95000000\n-0.25000000 0.15000000 -1.15000000\n-0.25000000 0.15000000 -1.10000000\n-0.25000000 0.15000000 -1.05000000\n-0.25000000 0.15000000 -1.00000000\n-0.25000000 0.15000000 -0.95000000\n-0.25000000 0.15000000 -0.90000000\n-0.25000000 0.15000000 -0.85000000\n-0.25000000 0.15000000 -0.80000000\n-0.25000000 0.15000000 -0.75000000\n-0.25000000 0.15000000 -0.70000000\n-0.25000000 0.15000000 -0.65000000\n-0.25000000 0.15000000 0.80000000\n-0.25000000 0.15000000 0.85000000\n-0.25000000 0.15000000 0.90000000\n-0.25000000 0.15000000 0.95000000\n-0.25000000 0.15000000 1.00000000\n-0.25000000 0.15000000 1.05000000\n-0.25000000 0.15000000 1.10000000\n-0.25000000 0.15000000 1.15000000\n-0.25000000 0.15000000 1.20000000\n-0.25000000 0.15000000 1.25000000\n-0.25000000 0.15000000 1.50000000\n-0.25000000 0.15000000 1.55000000\n-0.25000000 0.15000000 2.00000000\n-0.25000000 0.20000000 -1.35000000\n-0.25000000 0.20000000 -1.30000000\n-0.25000000 0.20000000 -1.25000000\n-0.25000000 0.20000000 -1.20000000\n-0.25000000 0.20000000 1.30000000\n-0.25000000 0.20000000 1.35000000\n-0.25000000 0.20000000 1.40000000\n-0.25000000 0.20000000 1.45000000\n-0.25000000 0.20000000 2.05000000\n-0.25000000 0.25000000 -1.50000000\n-0.25000000 0.25000000 -1.45000000\n-0.25000000 0.25000000 -1.40000000\n-0.25000000 0.25000000 2.10000000\n-0.25000000 0.30000000 -1.60000000\n-0.25000000 0.30000000 -1.55000000\n-0.25000000 0.30000000 2.10000000\n-0.25000000 0.35000000 -1.70000000\n-0.25000000 0.35000000 -1.65000000\n-0.25000000 0.35000000 2.10000000\n-0.25000000 0.40000000 -1.80000000\n-0.25000000 0.40000000 -1.75000000\n-0.25000000 0.40000000 2.10000000\n-0.25000000 0.45000000 -1.80000000\n-0.25000000 0.45000000 2.10000000\n-0.25000000 0.50000000 -1.85000000\n-0.25000000 0.50000000 2.10000000\n-0.25000000 0.55000000 -1.85000000\n-0.25000000 0.55000000 2.05000000\n-0.25000000 0.60000000 -1.90000000\n-0.25000000 0.60000000 1.40000000\n-0.25000000 0.60000000 1.45000000\n-0.25000000 0.60000000 1.50000000\n-0.25000000 0.60000000 1.55000000\n-0.25000000 0.60000000 1.60000000\n-0.25000000 0.60000000 1.90000000\n-0.25000000 0.60000000 1.95000000\n-0.25000000 0.60000000 2.00000000\n-0.25000000 0.65000000 -1.90000000\n-0.25000000 0.65000000 1.15000000\n-0.25000000 0.65000000 1.20000000\n-0.25000000 0.65000000 1.25000000\n-0.25000000 0.65000000 1.30000000\n-0.25000000 0.65000000 1.35000000\n-0.25000000 0.65000000 1.65000000\n-0.25000000 0.65000000 1.70000000\n-0.25000000 0.65000000 1.75000000\n-0.25000000 0.65000000 1.80000000\n-0.25000000 0.65000000 1.85000000\n-0.25000000 0.70000000 -1.90000000\n-0.25000000 0.70000000 0.85000000\n-0.25000000 0.70000000 0.90000000\n-0.25000000 0.70000000 0.95000000\n-0.25000000 0.70000000 1.00000000\n-0.25000000 0.70000000 1.05000000\n-0.25000000 0.70000000 1.10000000\n-0.25000000 0.75000000 -1.90000000\n-0.25000000 0.75000000 0.35000000\n-0.25000000 0.75000000 0.40000000\n-0.25000000 0.75000000 0.45000000\n-0.25000000 0.75000000 0.50000000\n-0.25000000 0.75000000 0.55000000\n-0.25000000 0.75000000 0.60000000\n-0.25000000 0.75000000 0.65000000\n-0.25000000 0.75000000 0.70000000\n-0.25000000 0.75000000 0.75000000\n-0.25000000 0.75000000 0.80000000\n-0.25000000 0.80000000 -1.90000000\n-0.25000000 0.80000000 0.05000000\n-0.25000000 0.80000000 0.10000000\n-0.25000000 0.80000000 0.15000000\n-0.25000000 0.80000000 0.20000000\n-0.25000000 0.80000000 0.25000000\n-0.25000000 0.80000000 0.30000000\n-0.25000000 0.85000000 -1.85000000\n-0.25000000 0.85000000 0.00000000\n-0.25000000 0.90000000 -1.80000000\n-0.25000000 0.90000000 -0.05000000\n-0.25000000 0.95000000 -1.80000000\n-0.25000000 0.95000000 -1.75000000\n-0.25000000 0.95000000 -0.15000000\n-0.25000000 0.95000000 -0.10000000\n-0.25000000 1.00000000 -1.70000000\n-0.25000000 1.00000000 -1.65000000\n-0.25000000 1.00000000 -0.25000000\n-0.25000000 1.00000000 -0.20000000\n-0.25000000 1.05000000 -1.60000000\n-0.25000000 1.05000000 -1.55000000\n-0.25000000 1.05000000 -0.35000000\n-0.25000000 1.05000000 -0.30000000\n-0.25000000 1.10000000 -1.50000000\n-0.25000000 1.10000000 -1.45000000\n-0.25000000 1.10000000 -1.40000000\n-0.25000000 1.10000000 -1.35000000\n-0.25000000 1.10000000 -0.60000000\n-0.25000000 1.10000000 -0.55000000\n-0.25000000 1.10000000 -0.50000000\n-0.25000000 1.10000000 -0.45000000\n-0.25000000 1.10000000 -0.40000000\n-0.25000000 1.15000000 -1.30000000\n-0.25000000 1.15000000 -1.25000000\n-0.25000000 1.15000000 -1.20000000\n-0.25000000 1.15000000 -1.15000000\n-0.25000000 1.15000000 -1.10000000\n-0.25000000 1.15000000 -1.05000000\n-0.25000000 1.15000000 -1.00000000\n-0.25000000 1.15000000 -0.95000000\n-0.25000000 1.15000000 -0.90000000\n-0.25000000 1.15000000 -0.85000000\n-0.25000000 1.15000000 -0.80000000\n-0.25000000 1.15000000 -0.75000000\n-0.25000000 1.15000000 -0.70000000\n-0.25000000 1.15000000 -0.65000000\n-0.20000000 0.10000000 -0.65000000\n-0.20000000 0.10000000 -0.60000000\n-0.20000000 0.10000000 -0.55000000\n-0.20000000 0.10000000 -0.50000000\n-0.20000000 0.10000000 -0.45000000\n-0.20000000 0.10000000 -0.40000000\n-0.20000000 0.10000000 -0.35000000\n-0.20000000 0.10000000 -0.30000000\n-0.20000000 0.10000000 -0.25000000\n-0.20000000 0.10000000 -0.20000000\n-0.20000000 0.10000000 -0.15000000\n-0.20000000 0.10000000 -0.10000000\n-0.20000000 0.10000000 -0.05000000\n-0.20000000 0.10000000 0.00000000\n-0.20000000 0.10000000 0.05000000\n-0.20000000 0.10000000 0.10000000\n-0.20000000 0.10000000 0.15000000\n-0.20000000 0.10000000 0.20000000\n-0.20000000 0.10000000 0.25000000\n-0.20000000 0.10000000 0.30000000\n-0.20000000 0.10000000 0.35000000\n-0.20000000 0.10000000 0.40000000\n-0.20000000 0.10000000 0.45000000\n-0.20000000 0.10000000 0.50000000\n-0.20000000 0.10000000 0.55000000\n-0.20000000 0.10000000 0.60000000\n-0.20000000 0.10000000 0.65000000\n-0.20000000 0.10000000 0.70000000\n-0.20000000 0.10000000 0.75000000\n-0.20000000 0.10000000 0.80000000\n-0.20000000 0.10000000 1.55000000\n-0.20000000 0.10000000 1.60000000\n-0.20000000 0.10000000 1.65000000\n-0.20000000 0.10000000 1.70000000\n-0.20000000 0.10000000 1.75000000\n-0.20000000 0.10000000 1.80000000\n-0.20000000 0.10000000 1.85000000\n-0.20000000 0.10000000 1.90000000\n-0.20000000 0.10000000 1.95000000\n-0.20000000 0.15000000 -1.15000000\n-0.20000000 0.15000000 -1.10000000\n-0.20000000 0.15000000 -1.05000000\n-0.20000000 0.15000000 -1.00000000\n-0.20000000 0.15000000 -0.95000000\n-0.20000000 0.15000000 -0.90000000\n-0.20000000 0.15000000 -0.85000000\n-0.20000000 0.15000000 -0.80000000\n-0.20000000 0.15000000 -0.75000000\n-0.20000000 0.15000000 -0.70000000\n-0.20000000 0.15000000 0.85000000\n-0.20000000 0.15000000 0.90000000\n-0.20000000 0.15000000 0.95000000\n-0.20000000 0.15000000 1.00000000\n-0.20000000 0.15000000 1.05000000\n-0.20000000 0.15000000 1.10000000\n-0.20000000 0.15000000 1.15000000\n-0.20000000 0.15000000 1.20000000\n-0.20000000 0.15000000 1.25000000\n-0.20000000 0.15000000 1.30000000\n-0.20000000 0.15000000 1.35000000\n-0.20000000 0.15000000 1.40000000\n-0.20000000 0.15000000 1.45000000\n-0.20000000 0.15000000 1.50000000\n-0.20000000 0.15000000 2.00000000\n-0.20000000 0.20000000 -1.40000000\n-0.20000000 0.20000000 -1.35000000\n-0.20000000 0.20000000 -1.30000000\n-0.20000000 0.20000000 -1.25000000\n-0.20000000 0.20000000 -1.20000000\n-0.20000000 0.20000000 2.05000000\n-0.20000000 0.20000000 2.10000000\n-0.20000000 0.25000000 -1.50000000\n-0.20000000 0.25000000 -1.45000000\n-0.20000000 0.25000000 2.10000000\n-0.20000000 0.30000000 -1.60000000\n-0.20000000 0.30000000 -1.55000000\n-0.20000000 0.30000000 2.10000000\n-0.20000000 0.35000000 -1.70000000\n-0.20000000 0.35000000 -1.65000000\n-0.20000000 0.35000000 2.15000000\n-0.20000000 0.40000000 -1.80000000\n-0.20000000 0.40000000 -1.75000000\n-0.20000000 0.40000000 2.15000000\n-0.20000000 0.45000000 -1.85000000\n-0.20000000 0.45000000 2.10000000\n-0.20000000 0.50000000 -1.85000000\n-0.20000000 0.50000000 2.10000000\n-0.20000000 0.55000000 -1.90000000\n-0.20000000 0.55000000 2.05000000\n-0.20000000 0.60000000 -1.90000000\n-0.20000000 0.60000000 1.55000000\n-0.20000000 0.60000000 1.60000000\n-0.20000000 0.60000000 1.90000000\n-0.20000000 0.60000000 1.95000000\n-0.20000000 0.60000000 2.00000000\n-0.20000000 0.65000000 -1.90000000\n-0.20000000 0.65000000 1.30000000\n-0.20000000 0.65000000 1.35000000\n-0.20000000 0.65000000 1.40000000\n-0.20000000 0.65000000 1.45000000\n-0.20000000 0.65000000 1.50000000\n-0.20000000 0.65000000 1.65000000\n-0.20000000 0.65000000 1.70000000\n-0.20000000 0.65000000 1.75000000\n-0.20000000 0.65000000 1.80000000\n-0.20000000 0.65000000 1.85000000\n-0.20000000 0.70000000 -1.90000000\n-0.20000000 0.70000000 1.05000000\n-0.20000000 0.70000000 1.10000000\n-0.20000000 0.70000000 1.15000000\n-0.20000000 0.70000000 1.20000000\n-0.20000000 0.70000000 1.25000000\n-0.20000000 0.75000000 -1.90000000\n-0.20000000 0.75000000 0.60000000\n-0.20000000 0.75000000 0.65000000\n-0.20000000 0.75000000 0.70000000\n-0.20000000 0.75000000 0.75000000\n-0.20000000 0.75000000 0.80000000\n-0.20000000 0.75000000 0.85000000\n-0.20000000 0.75000000 0.90000000\n-0.20000000 0.75000000 0.95000000\n-0.20000000 0.75000000 1.00000000\n-0.20000000 0.80000000 -1.90000000\n-0.20000000 0.80000000 0.10000000\n-0.20000000 0.80000000 0.15000000\n-0.20000000 0.80000000 0.20000000\n-0.20000000 0.80000000 0.25000000\n-0.20000000 0.80000000 0.30000000\n-0.20000000 0.80000000 0.35000000\n-0.20000000 0.80000000 0.40000000\n-0.20000000 0.80000000 0.45000000\n-0.20000000 0.80000000 0.50000000\n-0.20000000 0.80000000 0.55000000\n-0.20000000 0.85000000 -1.90000000\n-0.20000000 0.85000000 0.05000000\n-0.20000000 0.90000000 -1.85000000\n-0.20000000 0.90000000 -0.05000000\n-0.20000000 0.90000000 0.00000000\n-0.20000000 0.95000000 -1.80000000\n-0.20000000 0.95000000 -1.75000000\n-0.20000000 0.95000000 -0.10000000\n-0.20000000 1.00000000 -1.70000000\n-0.20000000 1.00000000 -0.20000000\n-0.20000000 1.00000000 -0.15000000\n-0.20000000 1.05000000 -1.65000000\n-0.20000000 1.05000000 -1.60000000\n-0.20000000 1.05000000 -1.55000000\n-0.20000000 1.05000000 -0.35000000\n-0.20000000 1.05000000 -0.30000000\n-0.20000000 1.05000000 -0.25000000\n-0.20000000 1.10000000 -1.50000000\n-0.20000000 1.10000000 -1.45000000\n-0.20000000 1.10000000 -1.40000000\n-0.20000000 1.10000000 -1.35000000\n-0.20000000 1.10000000 -0.55000000\n-0.20000000 1.10000000 -0.50000000\n-0.20000000 1.10000000 -0.45000000\n-0.20000000 1.10000000 -0.40000000\n-0.20000000 1.15000000 -1.30000000\n-0.20000000 1.15000000 -1.25000000\n-0.20000000 1.15000000 -1.20000000\n-0.20000000 1.15000000 -1.15000000\n-0.20000000 1.15000000 -1.10000000\n-0.20000000 1.15000000 -1.05000000\n-0.20000000 1.15000000 -1.00000000\n-0.20000000 1.15000000 -0.95000000\n-0.20000000 1.15000000 -0.90000000\n-0.20000000 1.15000000 -0.85000000\n-0.20000000 1.15000000 -0.80000000\n-0.20000000 1.15000000 -0.75000000\n-0.20000000 1.15000000 -0.70000000\n-0.20000000 1.15000000 -0.65000000\n-0.20000000 1.15000000 -0.60000000\n-0.15000000 0.10000000 -0.70000000\n-0.15000000 0.10000000 -0.65000000\n-0.15000000 0.10000000 -0.60000000\n-0.15000000 0.10000000 -0.55000000\n-0.15000000 0.10000000 -0.50000000\n-0.15000000 0.10000000 -0.45000000\n-0.15000000 0.10000000 -0.40000000\n-0.15000000 0.10000000 -0.35000000\n-0.15000000 0.10000000 -0.30000000\n-0.15000000 0.10000000 -0.25000000\n-0.15000000 0.10000000 -0.20000000\n-0.15000000 0.10000000 -0.15000000\n-0.15000000 0.10000000 -0.10000000\n-0.15000000 0.10000000 -0.05000000\n-0.15000000 0.10000000 0.00000000\n-0.15000000 0.10000000 0.05000000\n-0.15000000 0.10000000 0.10000000\n-0.15000000 0.10000000 0.15000000\n-0.15000000 0.10000000 0.20000000\n-0.15000000 0.10000000 0.25000000\n-0.15000000 0.10000000 0.30000000\n-0.15000000 0.10000000 0.35000000\n-0.15000000 0.10000000 0.40000000\n-0.15000000 0.10000000 0.45000000\n-0.15000000 0.10000000 0.50000000\n-0.15000000 0.10000000 0.55000000\n-0.15000000 0.10000000 0.60000000\n-0.15000000 0.10000000 0.65000000\n-0.15000000 0.10000000 0.70000000\n-0.15000000 0.10000000 0.75000000\n-0.15000000 0.10000000 0.80000000\n-0.15000000 0.10000000 0.85000000\n-0.15000000 0.10000000 0.90000000\n-0.15000000 0.10000000 0.95000000\n-0.15000000 0.10000000 1.00000000\n-0.15000000 0.10000000 1.05000000\n-0.15000000 0.10000000 1.10000000\n-0.15000000 0.10000000 1.15000000\n-0.15000000 0.10000000 1.20000000\n-0.15000000 0.10000000 1.55000000\n-0.15000000 0.10000000 1.60000000\n-0.15000000 0.10000000 1.65000000\n-0.15000000 0.10000000 1.70000000\n-0.15000000 0.10000000 1.75000000\n-0.15000000 0.10000000 1.80000000\n-0.15000000 0.10000000 1.85000000\n-0.15000000 0.10000000 1.90000000\n-0.15000000 0.10000000 1.95000000\n-0.15000000 0.15000000 -1.15000000\n-0.15000000 0.15000000 -1.10000000\n-0.15000000 0.15000000 -1.05000000\n-0.15000000 0.15000000 -1.00000000\n-0.15000000 0.15000000 -0.95000000\n-0.15000000 0.15000000 -0.90000000\n-0.15000000 0.15000000 -0.85000000\n-0.15000000 0.15000000 -0.80000000\n-0.15000000 0.15000000 -0.75000000\n-0.15000000 0.15000000 1.25000000\n-0.15000000 0.15000000 1.30000000\n-0.15000000 0.15000000 1.35000000\n-0.15000000 0.15000000 1.40000000\n-0.15000000 0.15000000 1.45000000\n-0.15000000 0.15000000 1.50000000\n-0.15000000 0.15000000 2.00000000\n-0.15000000 0.15000000 2.05000000\n-0.15000000 0.20000000 -1.40000000\n-0.15000000 0.20000000 -1.35000000\n-0.15000000 0.20000000 -1.30000000\n-0.15000000 0.20000000 -1.25000000\n-0.15000000 0.20000000 -1.20000000\n-0.15000000 0.20000000 2.10000000\n-0.15000000 0.25000000 -1.50000000\n-0.15000000 0.25000000 -1.45000000\n-0.15000000 0.25000000 2.10000000\n-0.15000000 0.30000000 -1.65000000\n-0.15000000 0.30000000 -1.60000000\n-0.15000000 0.30000000 -1.55000000\n-0.15000000 0.30000000 2.15000000\n-0.15000000 0.35000000 -1.75000000\n-0.15000000 0.35000000 -1.70000000\n-0.15000000 0.35000000 2.15000000\n-0.15000000 0.40000000 -1.80000000\n-0.15000000 0.40000000 2.15000000\n-0.15000000 0.45000000 -1.85000000\n-0.15000000 0.45000000 2.10000000\n-0.15000000 0.50000000 -1.85000000\n-0.15000000 0.50000000 2.10000000\n-0.15000000 0.55000000 -1.90000000\n-0.15000000 0.55000000 2.05000000\n-0.15000000 0.60000000 -1.90000000\n-0.15000000 0.60000000 1.95000000\n-0.15000000 0.60000000 2.00000000\n-0.15000000 0.65000000 -1.90000000\n-0.15000000 0.65000000 1.40000000\n-0.15000000 0.65000000 1.45000000\n-0.15000000 0.65000000 1.50000000\n-0.15000000 0.65000000 1.55000000\n-0.15000000 0.65000000 1.60000000\n-0.15000000 0.65000000 1.65000000\n-0.15000000 0.65000000 1.70000000\n-0.15000000 0.65000000 1.75000000\n-0.15000000 0.65000000 1.80000000\n-0.15000000 0.65000000 1.85000000\n-0.15000000 0.65000000 1.90000000\n-0.15000000 0.70000000 -1.95000000\n-0.15000000 0.70000000 1.15000000\n-0.15000000 0.70000000 1.20000000\n-0.15000000 0.70000000 1.25000000\n-0.15000000 0.70000000 1.30000000\n-0.15000000 0.70000000 1.35000000\n-0.15000000 0.75000000 -1.90000000\n-0.15000000 0.75000000 0.75000000\n-0.15000000 0.75000000 0.80000000\n-0.15000000 0.75000000 0.85000000\n-0.15000000 0.75000000 0.90000000\n-0.15000000 0.75000000 0.95000000\n-0.15000000 0.75000000 1.00000000\n-0.15000000 0.75000000 1.05000000\n-0.15000000 0.75000000 1.10000000\n-0.15000000 0.80000000 -1.90000000\n-0.15000000 0.80000000 0.10000000\n-0.15000000 0.80000000 0.15000000\n-0.15000000 0.80000000 0.20000000\n-0.15000000 0.80000000 0.25000000\n-0.15000000 0.80000000 0.30000000\n-0.15000000 0.80000000 0.35000000\n-0.15000000 0.80000000 0.40000000\n-0.15000000 0.80000000 0.45000000\n-0.15000000 0.80000000 0.50000000\n-0.15000000 0.80000000 0.55000000\n-0.15000000 0.80000000 0.60000000\n-0.15000000 0.80000000 0.65000000\n-0.15000000 0.80000000 0.70000000\n-0.15000000 0.85000000 -1.90000000\n-0.15000000 0.85000000 0.05000000\n-0.15000000 0.90000000 -1.85000000\n-0.15000000 0.90000000 -0.05000000\n-0.15000000 0.90000000 0.00000000\n-0.15000000 0.95000000 -1.80000000\n-0.15000000 0.95000000 -0.10000000\n-0.15000000 1.00000000 -1.75000000\n-0.15000000 1.00000000 -1.70000000\n-0.15000000 1.00000000 -0.20000000\n-0.15000000 1.00000000 -0.15000000\n-0.15000000 1.05000000 -1.65000000\n-0.15000000 1.05000000 -1.60000000\n-0.15000000 1.05000000 -0.35000000\n-0.15000000 1.05000000 -0.30000000\n-0.15000000 1.05000000 -0.25000000\n-0.15000000 1.10000000 -1.55000000\n-0.15000000 1.10000000 -1.50000000\n-0.15000000 1.10000000 -1.45000000\n-0.15000000 1.10000000 -1.40000000\n-0.15000000 1.10000000 -0.55000000\n-0.15000000 1.10000000 -0.50000000\n-0.15000000 1.10000000 -0.45000000\n-0.15000000 1.10000000 -0.40000000\n-0.15000000 1.15000000 -1.35000000\n-0.15000000 1.15000000 -1.30000000\n-0.15000000 1.15000000 -1.25000000\n-0.15000000 1.15000000 -1.20000000\n-0.15000000 1.15000000 -1.15000000\n-0.15000000 1.15000000 -1.10000000\n-0.15000000 1.15000000 -1.05000000\n-0.15000000 1.15000000 -1.00000000\n-0.15000000 1.15000000 -0.95000000\n-0.15000000 1.15000000 -0.90000000\n-0.15000000 1.15000000 -0.85000000\n-0.15000000 1.15000000 -0.80000000\n-0.15000000 1.15000000 -0.75000000\n-0.15000000 1.15000000 -0.70000000\n-0.15000000 1.15000000 -0.65000000\n-0.15000000 1.15000000 -0.60000000\n-0.10000000 0.10000000 -0.70000000\n-0.10000000 0.10000000 -0.65000000\n-0.10000000 0.10000000 -0.60000000\n-0.10000000 0.10000000 -0.55000000\n-0.10000000 0.10000000 -0.50000000\n-0.10000000 0.10000000 -0.45000000\n-0.10000000 0.10000000 -0.40000000\n-0.10000000 0.10000000 -0.35000000\n-0.10000000 0.10000000 -0.30000000\n-0.10000000 0.10000000 -0.25000000\n-0.10000000 0.10000000 -0.20000000\n-0.10000000 0.10000000 -0.15000000\n-0.10000000 0.10000000 -0.10000000\n-0.10000000 0.10000000 -0.05000000\n-0.10000000 0.10000000 0.00000000\n-0.10000000 0.10000000 0.05000000\n-0.10000000 0.10000000 0.10000000\n-0.10000000 0.10000000 0.15000000\n-0.10000000 0.10000000 0.20000000\n-0.10000000 0.10000000 0.25000000\n-0.10000000 0.10000000 0.30000000\n-0.10000000 0.10000000 0.35000000\n-0.10000000 0.10000000 0.40000000\n-0.10000000 0.10000000 0.45000000\n-0.10000000 0.10000000 0.50000000\n-0.10000000 0.10000000 0.55000000\n-0.10000000 0.10000000 0.60000000\n-0.10000000 0.10000000 0.65000000\n-0.10000000 0.10000000 0.70000000\n-0.10000000 0.10000000 0.75000000\n-0.10000000 0.10000000 0.80000000\n-0.10000000 0.10000000 0.85000000\n-0.10000000 0.10000000 0.90000000\n-0.10000000 0.10000000 0.95000000\n-0.10000000 0.10000000 1.00000000\n-0.10000000 0.10000000 1.05000000\n-0.10000000 0.10000000 1.10000000\n-0.10000000 0.10000000 1.15000000\n-0.10000000 0.10000000 1.20000000\n-0.10000000 0.10000000 1.25000000\n-0.10000000 0.10000000 1.30000000\n-0.10000000 0.10000000 1.35000000\n-0.10000000 0.10000000 1.55000000\n-0.10000000 0.10000000 1.60000000\n-0.10000000 0.10000000 1.65000000\n-0.10000000 0.10000000 1.70000000\n-0.10000000 0.10000000 1.75000000\n-0.10000000 0.10000000 1.80000000\n-0.10000000 0.10000000 1.85000000\n-0.10000000 0.10000000 1.90000000\n-0.10000000 0.10000000 1.95000000\n-0.10000000 0.15000000 -1.20000000\n-0.10000000 0.15000000 -1.15000000\n-0.10000000 0.15000000 -1.10000000\n-0.10000000 0.15000000 -1.05000000\n-0.10000000 0.15000000 -1.00000000\n-0.10000000 0.15000000 -0.95000000\n-0.10000000 0.15000000 -0.90000000\n-0.10000000 0.15000000 -0.85000000\n-0.10000000 0.15000000 -0.80000000\n-0.10000000 0.15000000 -0.75000000\n-0.10000000 0.15000000 1.40000000\n-0.10000000 0.15000000 1.45000000\n-0.10000000 0.15000000 1.50000000\n-0.10000000 0.15000000 2.00000000\n-0.10000000 0.15000000 2.05000000\n-0.10000000 0.20000000 -1.40000000\n-0.10000000 0.20000000 -1.35000000\n-0.10000000 0.20000000 -1.30000000\n-0.10000000 0.20000000 -1.25000000\n-0.10000000 0.20000000 2.10000000\n-0.10000000 0.25000000 -1.55000000\n-0.10000000 0.25000000 -1.50000000\n-0.10000000 0.25000000 -1.45000000\n-0.10000000 0.25000000 2.10000000\n-0.10000000 0.30000000 -1.65000000\n-0.10000000 0.30000000 -1.60000000\n-0.10000000 0.30000000 2.15000000\n-0.10000000 0.35000000 -1.75000000\n-0.10000000 0.35000000 -1.70000000\n-0.10000000 0.35000000 2.15000000\n-0.10000000 0.40000000 -1.80000000\n-0.10000000 0.40000000 2.15000000\n-0.10000000 0.45000000 -1.85000000\n-0.10000000 0.45000000 2.15000000\n-0.10000000 0.50000000 -1.90000000\n-0.10000000 0.50000000 2.10000000\n-0.10000000 0.55000000 -1.90000000\n-0.10000000 0.55000000 2.05000000\n-0.10000000 0.60000000 -1.90000000\n-0.10000000 0.60000000 1.95000000\n-0.10000000 0.60000000 2.00000000\n-0.10000000 0.65000000 -1.95000000\n-0.10000000 0.65000000 1.45000000\n-0.10000000 0.65000000 1.50000000\n-0.10000000 0.65000000 1.55000000\n-0.10000000 0.65000000 1.60000000\n-0.10000000 0.65000000 1.65000000\n-0.10000000 0.65000000 1.70000000\n-0.10000000 0.65000000 1.75000000\n-0.10000000 0.65000000 1.80000000\n-0.10000000 0.65000000 1.85000000\n-0.10000000 0.65000000 1.90000000\n-0.10000000 0.70000000 -1.95000000\n-0.10000000 0.70000000 1.20000000\n-0.10000000 0.70000000 1.25000000\n-0.10000000 0.70000000 1.30000000\n-0.10000000 0.70000000 1.35000000\n-0.10000000 0.70000000 1.40000000\n-0.10000000 0.75000000 -1.95000000\n-0.10000000 0.75000000 0.85000000\n-0.10000000 0.75000000 0.90000000\n-0.10000000 0.75000000 0.95000000\n-0.10000000 0.75000000 1.00000000\n-0.10000000 0.75000000 1.05000000\n-0.10000000 0.75000000 1.10000000\n-0.10000000 0.75000000 1.15000000\n-0.10000000 0.80000000 -1.90000000\n-0.10000000 0.80000000 0.30000000\n-0.10000000 0.80000000 0.35000000\n-0.10000000 0.80000000 0.40000000\n-0.10000000 0.80000000 0.45000000\n-0.10000000 0.80000000 0.50000000\n-0.10000000 0.80000000 0.55000000\n-0.10000000 0.80000000 0.60000000\n-0.10000000 0.80000000 0.65000000\n-0.10000000 0.80000000 0.70000000\n-0.10000000 0.80000000 0.75000000\n-0.10000000 0.80000000 0.80000000\n-0.10000000 0.85000000 -1.90000000\n-0.10000000 0.85000000 0.05000000\n-0.10000000 0.85000000 0.10000000\n-0.10000000 0.85000000 0.15000000\n-0.10000000 0.85000000 0.20000000\n-0.10000000 0.85000000 0.25000000\n-0.10000000 0.90000000 -1.85000000\n-0.10000000 0.90000000 0.00000000\n-0.10000000 0.95000000 -1.80000000\n-0.10000000 0.95000000 -0.10000000\n-0.10000000 0.95000000 -0.05000000\n-0.10000000 1.00000000 -1.75000000\n-0.10000000 1.00000000 -1.70000000\n-0.10000000 1.00000000 -0.20000000\n-0.10000000 1.00000000 -0.15000000\n-0.10000000 1.05000000 -1.65000000\n-0.10000000 1.05000000 -1.60000000\n-0.10000000 1.05000000 -0.35000000\n-0.10000000 1.05000000 -0.30000000\n-0.10000000 1.05000000 -0.25000000\n-0.10000000 1.10000000 -1.55000000\n-0.10000000 1.10000000 -1.50000000\n-0.10000000 1.10000000 -1.45000000\n-0.10000000 1.10000000 -1.40000000\n-0.10000000 1.10000000 -0.50000000\n-0.10000000 1.10000000 -0.45000000\n-0.10000000 1.10000000 -0.40000000\n-0.10000000 1.15000000 -1.35000000\n-0.10000000 1.15000000 -1.30000000\n-0.10000000 1.15000000 -1.25000000\n-0.10000000 1.15000000 -1.20000000\n-0.10000000 1.15000000 -1.15000000\n-0.10000000 1.15000000 -1.10000000\n-0.10000000 1.15000000 -1.05000000\n-0.10000000 1.15000000 -1.00000000\n-0.10000000 1.15000000 -0.95000000\n-0.10000000 1.15000000 -0.90000000\n-0.10000000 1.15000000 -0.85000000\n-0.10000000 1.15000000 -0.80000000\n-0.10000000 1.15000000 -0.75000000\n-0.10000000 1.15000000 -0.70000000\n-0.10000000 1.15000000 -0.65000000\n-0.10000000 1.15000000 -0.60000000\n-0.10000000 1.15000000 -0.55000000\n-0.05000000 0.10000000 -0.70000000\n-0.05000000 0.10000000 -0.65000000\n-0.05000000 0.10000000 -0.60000000\n-0.05000000 0.10000000 -0.55000000\n-0.05000000 0.10000000 -0.50000000\n-0.05000000 0.10000000 -0.45000000\n-0.05000000 0.10000000 -0.40000000\n-0.05000000 0.10000000 -0.35000000\n-0.05000000 0.10000000 -0.30000000\n-0.05000000 0.10000000 -0.25000000\n-0.05000000 0.10000000 -0.20000000\n-0.05000000 0.10000000 -0.15000000\n-0.05000000 0.10000000 -0.10000000\n-0.05000000 0.10000000 -0.05000000\n-0.05000000 0.10000000 0.00000000\n-0.05000000 0.10000000 0.05000000\n-0.05000000 0.10000000 0.10000000\n-0.05000000 0.10000000 0.15000000\n-0.05000000 0.10000000 0.20000000\n-0.05000000 0.10000000 0.25000000\n-0.05000000 0.10000000 0.30000000\n-0.05000000 0.10000000 0.35000000\n-0.05000000 0.10000000 0.40000000\n-0.05000000 0.10000000 0.45000000\n-0.05000000 0.10000000 0.50000000\n-0.05000000 0.10000000 0.55000000\n-0.05000000 0.10000000 0.60000000\n-0.05000000 0.10000000 0.65000000\n-0.05000000 0.10000000 0.70000000\n-0.05000000 0.10000000 0.75000000\n-0.05000000 0.10000000 0.80000000\n-0.05000000 0.10000000 0.85000000\n-0.05000000 0.10000000 0.90000000\n-0.05000000 0.10000000 0.95000000\n-0.05000000 0.10000000 1.00000000\n-0.05000000 0.10000000 1.05000000\n-0.05000000 0.10000000 1.10000000\n-0.05000000 0.10000000 1.15000000\n-0.05000000 0.10000000 1.20000000\n-0.05000000 0.10000000 1.25000000\n-0.05000000 0.10000000 1.30000000\n-0.05000000 0.10000000 1.35000000\n-0.05000000 0.10000000 1.40000000\n-0.05000000 0.10000000 1.45000000\n-0.05000000 0.10000000 1.55000000\n-0.05000000 0.10000000 1.60000000\n-0.05000000 0.10000000 1.65000000\n-0.05000000 0.10000000 1.70000000\n-0.05000000 0.10000000 1.75000000\n-0.05000000 0.10000000 1.80000000\n-0.05000000 0.10000000 1.85000000\n-0.05000000 0.10000000 1.90000000\n-0.05000000 0.10000000 1.95000000\n-0.05000000 0.15000000 -1.20000000\n-0.05000000 0.15000000 -1.15000000\n-0.05000000 0.15000000 -1.10000000\n-0.05000000 0.15000000 -1.05000000\n-0.05000000 0.15000000 -1.00000000\n-0.05000000 0.15000000 -0.95000000\n-0.05000000 0.15000000 -0.90000000\n-0.05000000 0.15000000 -0.85000000\n-0.05000000 0.15000000 -0.80000000\n-0.05000000 0.15000000 -0.75000000\n-0.05000000 0.15000000 1.50000000\n-0.05000000 0.15000000 2.00000000\n-0.05000000 0.15000000 2.05000000\n-0.05000000 0.20000000 -1.40000000\n-0.05000000 0.20000000 -1.35000000\n-0.05000000 0.20000000 -1.30000000\n-0.05000000 0.20000000 -1.25000000\n-0.05000000 0.20000000 2.10000000\n-0.05000000 0.25000000 -1.55000000\n-0.05000000 0.25000000 -1.50000000\n-0.05000000 0.25000000 -1.45000000\n-0.05000000 0.25000000 2.10000000\n-0.05000000 0.30000000 -1.65000000\n-0.05000000 0.30000000 -1.60000000\n-0.05000000 0.30000000 2.15000000\n-0.05000000 0.35000000 -1.75000000\n-0.05000000 0.35000000 -1.70000000\n-0.05000000 0.35000000 2.15000000\n-0.05000000 0.40000000 -1.85000000\n-0.05000000 0.40000000 -1.80000000\n-0.05000000 0.40000000 2.15000000\n-0.05000000 0.45000000 -1.85000000\n-0.05000000 0.45000000 2.15000000\n-0.05000000 0.50000000 -1.90000000\n-0.05000000 0.50000000 2.10000000\n-0.05000000 0.55000000 -1.90000000\n-0.05000000 0.55000000 2.05000000\n-0.05000000 0.60000000 -1.90000000\n-0.05000000 0.60000000 1.95000000\n-0.05000000 0.60000000 2.00000000\n-0.05000000 0.65000000 -1.95000000\n-0.05000000 0.65000000 1.50000000\n-0.05000000 0.65000000 1.55000000\n-0.05000000 0.65000000 1.60000000\n-0.05000000 0.65000000 1.65000000\n-0.05000000 0.65000000 1.70000000\n-0.05000000 0.65000000 1.75000000\n-0.05000000 0.65000000 1.80000000\n-0.05000000 0.65000000 1.85000000\n-0.05000000 0.65000000 1.90000000\n-0.05000000 0.70000000 -1.95000000\n-0.05000000 0.70000000 1.25000000\n-0.05000000 0.70000000 1.30000000\n-0.05000000 0.70000000 1.35000000\n-0.05000000 0.70000000 1.40000000\n-0.05000000 0.70000000 1.45000000\n-0.05000000 0.75000000 -1.95000000\n-0.05000000 0.75000000 0.90000000\n-0.05000000 0.75000000 0.95000000\n-0.05000000 0.75000000 1.00000000\n-0.05000000 0.75000000 1.05000000\n-0.05000000 0.75000000 1.10000000\n-0.05000000 0.75000000 1.15000000\n-0.05000000 0.75000000 1.20000000\n-0.05000000 0.80000000 -1.90000000\n-0.05000000 0.80000000 0.40000000\n-0.05000000 0.80000000 0.45000000\n-0.05000000 0.80000000 0.50000000\n-0.05000000 0.80000000 0.55000000\n-0.05000000 0.80000000 0.60000000\n-0.05000000 0.80000000 0.65000000\n-0.05000000 0.80000000 0.70000000\n-0.05000000 0.80000000 0.75000000\n-0.05000000 0.80000000 0.80000000\n-0.05000000 0.80000000 0.85000000\n-0.05000000 0.85000000 -1.90000000\n-0.05000000 0.85000000 0.05000000\n-0.05000000 0.85000000 0.10000000\n-0.05000000 0.85000000 0.15000000\n-0.05000000 0.85000000 0.20000000\n-0.05000000 0.85000000 0.25000000\n-0.05000000 0.85000000 0.30000000\n-0.05000000 0.85000000 0.35000000\n-0.05000000 0.90000000 -1.85000000\n-0.05000000 0.90000000 0.00000000\n-0.05000000 0.95000000 -1.80000000\n-0.05000000 0.95000000 -0.10000000\n-0.05000000 0.95000000 -0.05000000\n-0.05000000 1.00000000 -1.75000000\n-0.05000000 1.00000000 -1.70000000\n-0.05000000 1.00000000 -0.20000000\n-0.05000000 1.00000000 -0.15000000\n-0.05000000 1.05000000 -1.65000000\n-0.05000000 1.05000000 -1.60000000\n-0.05000000 1.05000000 -0.30000000\n-0.05000000 1.05000000 -0.25000000\n-0.05000000 1.10000000 -1.55000000\n-0.05000000 1.10000000 -1.50000000\n-0.05000000 1.10000000 -1.45000000\n-0.05000000 1.10000000 -1.40000000\n-0.05000000 1.10000000 -0.50000000\n-0.05000000 1.10000000 -0.45000000\n-0.05000000 1.10000000 -0.40000000\n-0.05000000 1.10000000 -0.35000000\n-0.05000000 1.15000000 -1.35000000\n-0.05000000 1.15000000 -1.30000000\n-0.05000000 1.15000000 -1.25000000\n-0.05000000 1.15000000 -1.20000000\n-0.05000000 1.15000000 -1.15000000\n-0.05000000 1.15000000 -1.10000000\n-0.05000000 1.15000000 -1.05000000\n-0.05000000 1.15000000 -1.00000000\n-0.05000000 1.15000000 -0.95000000\n-0.05000000 1.15000000 -0.90000000\n-0.05000000 1.15000000 -0.85000000\n-0.05000000 1.15000000 -0.80000000\n-0.05000000 1.15000000 -0.75000000\n-0.05000000 1.15000000 -0.70000000\n-0.05000000 1.15000000 -0.65000000\n-0.05000000 1.15000000 -0.60000000\n-0.05000000 1.15000000 -0.55000000\n0.00000000 0.10000000 -0.70000000\n0.00000000 0.10000000 -0.65000000\n0.00000000 0.10000000 -0.60000000\n0.00000000 0.10000000 -0.55000000\n0.00000000 0.10000000 -0.50000000\n0.00000000 0.10000000 -0.45000000\n0.00000000 0.10000000 -0.40000000\n0.00000000 0.10000000 -0.35000000\n0.00000000 0.10000000 -0.30000000\n0.00000000 0.10000000 -0.25000000\n0.00000000 0.10000000 -0.20000000\n0.00000000 0.10000000 -0.15000000\n0.00000000 0.10000000 -0.10000000\n0.00000000 0.10000000 -0.05000000\n0.00000000 0.10000000 0.00000000\n0.00000000 0.10000000 0.05000000\n0.00000000 0.10000000 0.10000000\n0.00000000 0.10000000 0.15000000\n0.00000000 0.10000000 0.20000000\n0.00000000 0.10000000 0.25000000\n0.00000000 0.10000000 0.30000000\n0.00000000 0.10000000 0.35000000\n0.00000000 0.10000000 0.40000000\n0.00000000 0.10000000 0.45000000\n0.00000000 0.10000000 0.50000000\n0.00000000 0.10000000 0.55000000\n0.00000000 0.10000000 0.60000000\n0.00000000 0.10000000 0.65000000\n0.00000000 0.10000000 0.70000000\n0.00000000 0.10000000 0.75000000\n0.00000000 0.10000000 0.80000000\n0.00000000 0.10000000 0.85000000\n0.00000000 0.10000000 0.90000000\n0.00000000 0.10000000 0.95000000\n0.00000000 0.10000000 1.00000000\n0.00000000 0.10000000 1.05000000\n0.00000000 0.10000000 1.10000000\n0.00000000 0.10000000 1.15000000\n0.00000000 0.10000000 1.20000000\n0.00000000 0.10000000 1.25000000\n0.00000000 0.10000000 1.30000000\n0.00000000 0.10000000 1.35000000\n0.00000000 0.10000000 1.40000000\n0.00000000 0.10000000 1.45000000\n0.00000000 0.10000000 1.55000000\n0.00000000 0.10000000 1.60000000\n0.00000000 0.10000000 1.65000000\n0.00000000 0.10000000 1.70000000\n0.00000000 0.10000000 1.75000000\n0.00000000 0.10000000 1.80000000\n0.00000000 0.10000000 1.85000000\n0.00000000 0.10000000 1.90000000\n0.00000000 0.10000000 1.95000000\n0.00000000 0.15000000 -1.20000000\n0.00000000 0.15000000 -1.15000000\n0.00000000 0.15000000 -1.10000000\n0.00000000 0.15000000 -1.05000000\n0.00000000 0.15000000 -1.00000000\n0.00000000 0.15000000 -0.95000000\n0.00000000 0.15000000 -0.90000000\n0.00000000 0.15000000 -0.85000000\n0.00000000 0.15000000 -0.80000000\n0.00000000 0.15000000 -0.75000000\n0.00000000 0.15000000 1.50000000\n0.00000000 0.15000000 2.00000000\n0.00000000 0.15000000 2.05000000\n0.00000000 0.20000000 -1.40000000\n0.00000000 0.20000000 -1.35000000\n0.00000000 0.20000000 -1.30000000\n0.00000000 0.20000000 -1.25000000\n0.00000000 0.20000000 2.10000000\n0.00000000 0.25000000 -1.55000000\n0.00000000 0.25000000 -1.50000000\n0.00000000 0.25000000 -1.45000000\n0.00000000 0.25000000 2.10000000\n0.00000000 0.30000000 -1.65000000\n0.00000000 0.30000000 -1.60000000\n0.00000000 0.30000000 2.15000000\n0.00000000 0.35000000 -1.75000000\n0.00000000 0.35000000 -1.70000000\n0.00000000 0.35000000 2.15000000\n0.00000000 0.40000000 -1.85000000\n0.00000000 0.40000000 -1.80000000\n0.00000000 0.40000000 2.15000000\n0.00000000 0.45000000 -1.85000000\n0.00000000 0.45000000 2.15000000\n0.00000000 0.50000000 -1.90000000\n0.00000000 0.50000000 2.10000000\n0.00000000 0.55000000 -1.90000000\n0.00000000 0.55000000 2.05000000\n0.00000000 0.60000000 -1.95000000\n0.00000000 0.60000000 1.95000000\n0.00000000 0.60000000 2.00000000\n0.00000000 0.65000000 -1.95000000\n0.00000000 0.65000000 1.50000000\n0.00000000 0.65000000 1.55000000\n0.00000000 0.65000000 1.60000000\n0.00000000 0.65000000 1.65000000\n0.00000000 0.65000000 1.70000000\n0.00000000 0.65000000 1.75000000\n0.00000000 0.65000000 1.80000000\n0.00000000 0.65000000 1.85000000\n0.00000000 0.65000000 1.90000000\n0.00000000 0.70000000 -1.95000000\n0.00000000 0.70000000 1.25000000\n0.00000000 0.70000000 1.30000000\n0.00000000 0.70000000 1.35000000\n0.00000000 0.70000000 1.40000000\n0.00000000 0.70000000 1.45000000\n0.00000000 0.75000000 -1.95000000\n0.00000000 0.75000000 0.90000000\n0.00000000 0.75000000 0.95000000\n0.00000000 0.75000000 1.00000000\n0.00000000 0.75000000 1.05000000\n0.00000000 0.75000000 1.10000000\n0.00000000 0.75000000 1.15000000\n0.00000000 0.75000000 1.20000000\n0.00000000 0.80000000 -1.90000000\n0.00000000 0.80000000 0.40000000\n0.00000000 0.80000000 0.45000000\n0.00000000 0.80000000 0.50000000\n0.00000000 0.80000000 0.55000000\n0.00000000 0.80000000 0.60000000\n0.00000000 0.80000000 0.65000000\n0.00000000 0.80000000 0.70000000\n0.00000000 0.80000000 0.75000000\n0.00000000 0.80000000 0.80000000\n0.00000000 0.80000000 0.85000000\n0.00000000 0.85000000 -1.90000000\n0.00000000 0.85000000 0.05000000\n0.00000000 0.85000000 0.10000000\n0.00000000 0.85000000 0.15000000\n0.00000000 0.85000000 0.20000000\n0.00000000 0.85000000 0.25000000\n0.00000000 0.85000000 0.30000000\n0.00000000 0.85000000 0.35000000\n0.00000000 0.90000000 -1.85000000\n0.00000000 0.90000000 0.00000000\n0.00000000 0.95000000 -1.80000000\n0.00000000 0.95000000 -0.10000000\n0.00000000 0.95000000 -0.05000000\n0.00000000 1.00000000 -1.75000000\n0.00000000 1.00000000 -1.70000000\n0.00000000 1.00000000 -0.20000000\n0.00000000 1.00000000 -0.15000000\n0.00000000 1.05000000 -1.65000000\n0.00000000 1.05000000 -1.60000000\n0.00000000 1.05000000 -0.30000000\n0.00000000 1.05000000 -0.25000000\n0.00000000 1.10000000 -1.55000000\n0.00000000 1.10000000 -1.50000000\n0.00000000 1.10000000 -1.45000000\n0.00000000 1.10000000 -1.40000000\n0.00000000 1.10000000 -0.50000000\n0.00000000 1.10000000 -0.45000000\n0.00000000 1.10000000 -0.40000000\n0.00000000 1.10000000 -0.35000000\n0.00000000 1.15000000 -1.35000000\n0.00000000 1.15000000 -1.30000000\n0.00000000 1.15000000 -1.25000000\n0.00000000 1.15000000 -1.20000000\n0.00000000 1.15000000 -1.15000000\n0.00000000 1.15000000 -1.10000000\n0.00000000 1.15000000 -1.05000000\n0.00000000 1.15000000 -1.00000000\n0.00000000 1.15000000 -0.95000000\n0.00000000 1.15000000 -0.90000000\n0.00000000 1.15000000 -0.85000000\n0.00000000 1.15000000 -0.80000000\n0.00000000 1.15000000 -0.75000000\n0.00000000 1.15000000 -0.70000000\n0.00000000 1.15000000 -0.65000000\n0.00000000 1.15000000 -0.60000000\n0.00000000 1.15000000 -0.55000000\n0.05000000 0.10000000 -0.70000000\n0.05000000 0.10000000 -0.65000000\n0.05000000 0.10000000 -0.60000000\n0.05000000 0.10000000 -0.55000000\n0.05000000 0.10000000 -0.50000000\n0.05000000 0.10000000 -0.45000000\n0.05000000 0.10000000 -0.40000000\n0.05000000 0.10000000 -0.35000000\n0.05000000 0.10000000 -0.30000000\n0.05000000 0.10000000 -0.25000000\n0.05000000 0.10000000 -0.20000000\n0.05000000 0.10000000 -0.15000000\n0.05000000 0.10000000 -0.10000000\n0.05000000 0.10000000 -0.05000000\n0.05000000 0.10000000 0.00000000\n0.05000000 0.10000000 0.05000000\n0.05000000 0.10000000 0.10000000\n0.05000000 0.10000000 0.15000000\n0.05000000 0.10000000 0.20000000\n0.05000000 0.10000000 0.25000000\n0.05000000 0.10000000 0.30000000\n0.05000000 0.10000000 0.35000000\n0.05000000 0.10000000 0.40000000\n0.05000000 0.10000000 0.45000000\n0.05000000 0.10000000 0.50000000\n0.05000000 0.10000000 0.55000000\n0.05000000 0.10000000 0.60000000\n0.05000000 0.10000000 0.65000000\n0.05000000 0.10000000 0.70000000\n0.05000000 0.10000000 0.75000000\n0.05000000 0.10000000 0.80000000\n0.05000000 0.10000000 0.85000000\n0.05000000 0.10000000 0.90000000\n0.05000000 0.10000000 0.95000000\n0.05000000 0.10000000 1.00000000\n0.05000000 0.10000000 1.05000000\n0.05000000 0.10000000 1.10000000\n0.05000000 0.10000000 1.15000000\n0.05000000 0.10000000 1.20000000\n0.05000000 0.10000000 1.25000000\n0.05000000 0.10000000 1.30000000\n0.05000000 0.10000000 1.35000000\n0.05000000 0.10000000 1.40000000\n0.05000000 0.10000000 1.45000000\n0.05000000 0.10000000 1.55000000\n0.05000000 0.10000000 1.60000000\n0.05000000 0.10000000 1.65000000\n0.05000000 0.10000000 1.70000000\n0.05000000 0.10000000 1.75000000\n0.05000000 0.10000000 1.80000000\n0.05000000 0.10000000 1.85000000\n0.05000000 0.10000000 1.90000000\n0.05000000 0.10000000 1.95000000\n0.05000000 0.15000000 -1.20000000\n0.05000000 0.15000000 -1.15000000\n0.05000000 0.15000000 -1.10000000\n0.05000000 0.15000000 -1.05000000\n0.05000000 0.15000000 -1.00000000\n0.05000000 0.15000000 -0.95000000\n0.05000000 0.15000000 -0.90000000\n0.05000000 0.15000000 -0.85000000\n0.05000000 0.15000000 -0.80000000\n0.05000000 0.15000000 -0.75000000\n0.05000000 0.15000000 1.50000000\n0.05000000 0.15000000 2.00000000\n0.05000000 0.15000000 2.05000000\n0.05000000 0.20000000 -1.40000000\n0.05000000 0.20000000 -1.35000000\n0.05000000 0.20000000 -1.30000000\n0.05000000 0.20000000 -1.25000000\n0.05000000 0.20000000 2.10000000\n0.05000000 0.25000000 -1.55000000\n0.05000000 0.25000000 -1.50000000\n0.05000000 0.25000000 -1.45000000\n0.05000000 0.25000000 2.10000000\n0.05000000 0.30000000 -1.65000000\n0.05000000 0.30000000 -1.60000000\n0.05000000 0.30000000 2.15000000\n0.05000000 0.35000000 -1.75000000\n0.05000000 0.35000000 -1.70000000\n0.05000000 0.35000000 2.15000000\n0.05000000 0.40000000 -1.85000000\n0.05000000 0.40000000 -1.80000000\n0.05000000 0.40000000 2.15000000\n0.05000000 0.45000000 -1.85000000\n0.05000000 0.45000000 2.15000000\n0.05000000 0.50000000 -1.90000000\n0.05000000 0.50000000 2.10000000\n0.05000000 0.55000000 -1.90000000\n0.05000000 0.55000000 2.05000000\n0.05000000 0.60000000 -1.90000000\n0.05000000 0.60000000 1.95000000\n0.05000000 0.60000000 2.00000000\n0.05000000 0.65000000 -1.95000000\n0.05000000 0.65000000 1.50000000\n0.05000000 0.65000000 1.55000000\n0.05000000 0.65000000 1.60000000\n0.05000000 0.65000000 1.65000000\n0.05000000 0.65000000 1.70000000\n0.05000000 0.65000000 1.75000000\n0.05000000 0.65000000 1.80000000\n0.05000000 0.65000000 1.85000000\n0.05000000 0.65000000 1.90000000\n0.05000000 0.70000000 -1.95000000\n0.05000000 0.70000000 1.25000000\n0.05000000 0.70000000 1.30000000\n0.05000000 0.70000000 1.35000000\n0.05000000 0.70000000 1.40000000\n0.05000000 0.70000000 1.45000000\n0.05000000 0.75000000 -1.95000000\n0.05000000 0.75000000 0.90000000\n0.05000000 0.75000000 0.95000000\n0.05000000 0.75000000 1.00000000\n0.05000000 0.75000000 1.05000000\n0.05000000 0.75000000 1.10000000\n0.05000000 0.75000000 1.15000000\n0.05000000 0.75000000 1.20000000\n0.05000000 0.80000000 -1.90000000\n0.05000000 0.80000000 0.40000000\n0.05000000 0.80000000 0.45000000\n0.05000000 0.80000000 0.50000000\n0.05000000 0.80000000 0.55000000\n0.05000000 0.80000000 0.60000000\n0.05000000 0.80000000 0.65000000\n0.05000000 0.80000000 0.70000000\n0.05000000 0.80000000 0.75000000\n0.05000000 0.80000000 0.80000000\n0.05000000 0.80000000 0.85000000\n0.05000000 0.85000000 -1.90000000\n0.05000000 0.85000000 0.05000000\n0.05000000 0.85000000 0.10000000\n0.05000000 0.85000000 0.15000000\n0.05000000 0.85000000 0.20000000\n0.05000000 0.85000000 0.25000000\n0.05000000 0.85000000 0.30000000\n0.05000000 0.85000000 0.35000000\n0.05000000 0.90000000 -1.85000000\n0.05000000 0.90000000 0.00000000\n0.05000000 0.95000000 -1.80000000\n0.05000000 0.95000000 -0.10000000\n0.05000000 0.95000000 -0.05000000\n0.05000000 1.00000000 -1.75000000\n0.05000000 1.00000000 -1.70000000\n0.05000000 1.00000000 -0.20000000\n0.05000000 1.00000000 -0.15000000\n0.05000000 1.05000000 -1.65000000\n0.05000000 1.05000000 -1.60000000\n0.05000000 1.05000000 -0.30000000\n0.05000000 1.05000000 -0.25000000\n0.05000000 1.10000000 -1.55000000\n0.05000000 1.10000000 -1.50000000\n0.05000000 1.10000000 -1.45000000\n0.05000000 1.10000000 -1.40000000\n0.05000000 1.10000000 -0.50000000\n0.05000000 1.10000000 -0.45000000\n0.05000000 1.10000000 -0.40000000\n0.05000000 1.10000000 -0.35000000\n0.05000000 1.15000000 -1.35000000\n0.05000000 1.15000000 -1.30000000\n0.05000000 1.15000000 -1.25000000\n0.05000000 1.15000000 -1.20000000\n0.05000000 1.15000000 -1.15000000\n0.05000000 1.15000000 -1.10000000\n0.05000000 1.15000000 -1.05000000\n0.05000000 1.15000000 -1.00000000\n0.05000000 1.15000000 -0.95000000\n0.05000000 1.15000000 -0.90000000\n0.05000000 1.15000000 -0.85000000\n0.05000000 1.15000000 -0.80000000\n0.05000000 1.15000000 -0.75000000\n0.05000000 1.15000000 -0.70000000\n0.05000000 1.15000000 -0.65000000\n0.05000000 1.15000000 -0.60000000\n0.05000000 1.15000000 -0.55000000\n0.10000000 0.10000000 -0.70000000\n0.10000000 0.10000000 -0.65000000\n0.10000000 0.10000000 -0.60000000\n0.10000000 0.10000000 -0.55000000\n0.10000000 0.10000000 -0.50000000\n0.10000000 0.10000000 -0.45000000\n0.10000000 0.10000000 -0.40000000\n0.10000000 0.10000000 -0.35000000\n0.10000000 0.10000000 -0.30000000\n0.10000000 0.10000000 -0.25000000\n0.10000000 0.10000000 -0.20000000\n0.10000000 0.10000000 -0.15000000\n0.10000000 0.10000000 -0.10000000\n0.10000000 0.10000000 -0.05000000\n0.10000000 0.10000000 0.00000000\n0.10000000 0.10000000 0.05000000\n0.10000000 0.10000000 0.10000000\n0.10000000 0.10000000 0.15000000\n0.10000000 0.10000000 0.20000000\n0.10000000 0.10000000 0.25000000\n0.10000000 0.10000000 0.30000000\n0.10000000 0.10000000 0.35000000\n0.10000000 0.10000000 0.40000000\n0.10000000 0.10000000 0.45000000\n0.10000000 0.10000000 0.50000000\n0.10000000 0.10000000 0.55000000\n0.10000000 0.10000000 0.60000000\n0.10000000 0.10000000 0.65000000\n0.10000000 0.10000000 0.70000000\n0.10000000 0.10000000 0.75000000\n0.10000000 0.10000000 0.80000000\n0.10000000 0.10000000 0.85000000\n0.10000000 0.10000000 0.90000000\n0.10000000 0.10000000 0.95000000\n0.10000000 0.10000000 1.00000000\n0.10000000 0.10000000 1.05000000\n0.10000000 0.10000000 1.10000000\n0.10000000 0.10000000 1.15000000\n0.10000000 0.10000000 1.20000000\n0.10000000 0.10000000 1.25000000\n0.10000000 0.10000000 1.30000000\n0.10000000 0.10000000 1.35000000\n0.10000000 0.10000000 1.55000000\n0.10000000 0.10000000 1.60000000\n0.10000000 0.10000000 1.65000000\n0.10000000 0.10000000 1.70000000\n0.10000000 0.10000000 1.75000000\n0.10000000 0.10000000 1.80000000\n0.10000000 0.10000000 1.85000000\n0.10000000 0.10000000 1.90000000\n0.10000000 0.10000000 1.95000000\n0.10000000 0.15000000 -1.20000000\n0.10000000 0.15000000 -1.15000000\n0.10000000 0.15000000 -1.10000000\n0.10000000 0.15000000 -1.05000000\n0.10000000 0.15000000 -1.00000000\n0.10000000 0.15000000 -0.95000000\n0.10000000 0.15000000 -0.90000000\n0.10000000 0.15000000 -0.85000000\n0.10000000 0.15000000 -0.80000000\n0.10000000 0.15000000 -0.75000000\n0.10000000 0.15000000 1.40000000\n0.10000000 0.15000000 1.45000000\n0.10000000 0.15000000 1.50000000\n0.10000000 0.15000000 2.00000000\n0.10000000 0.15000000 2.05000000\n0.10000000 0.20000000 -1.40000000\n0.10000000 0.20000000 -1.35000000\n0.10000000 0.20000000 -1.30000000\n0.10000000 0.20000000 -1.25000000\n0.10000000 0.20000000 2.10000000\n0.10000000 0.25000000 -1.55000000\n0.10000000 0.25000000 -1.50000000\n0.10000000 0.25000000 -1.45000000\n0.10000000 0.25000000 2.10000000\n0.10000000 0.30000000 -1.65000000\n0.10000000 0.30000000 -1.60000000\n0.10000000 0.30000000 2.15000000\n0.10000000 0.35000000 -1.75000000\n0.10000000 0.35000000 -1.70000000\n0.10000000 0.35000000 2.15000000\n0.10000000 0.40000000 -1.80000000\n0.10000000 0.40000000 2.15000000\n0.10000000 0.45000000 -1.85000000\n0.10000000 0.45000000 2.15000000\n0.10000000 0.50000000 -1.90000000\n0.10000000 0.50000000 2.10000000\n0.10000000 0.55000000 -1.90000000\n0.10000000 0.55000000 2.05000000\n0.10000000 0.60000000 -1.90000000\n0.10000000 0.60000000 1.95000000\n0.10000000 0.60000000 2.00000000\n0.10000000 0.65000000 -1.95000000\n0.10000000 0.65000000 1.45000000\n0.10000000 0.65000000 1.50000000\n0.10000000 0.65000000 1.55000000\n0.10000000 0.65000000 1.60000000\n0.10000000 0.65000000 1.65000000\n0.10000000 0.65000000 1.70000000\n0.10000000 0.65000000 1.75000000\n0.10000000 0.65000000 1.80000000\n0.10000000 0.65000000 1.85000000\n0.10000000 0.65000000 1.90000000\n0.10000000 0.70000000 -1.95000000\n0.10000000 0.70000000 1.20000000\n0.10000000 0.70000000 1.25000000\n0.10000000 0.70000000 1.30000000\n0.10000000 0.70000000 1.35000000\n0.10000000 0.70000000 1.40000000\n0.10000000 0.75000000 -1.95000000\n0.10000000 0.75000000 0.85000000\n0.10000000 0.75000000 0.90000000\n0.10000000 0.75000000 0.95000000\n0.10000000 0.75000000 1.00000000\n0.10000000 0.75000000 1.05000000\n0.10000000 0.75000000 1.10000000\n0.10000000 0.75000000 1.15000000\n0.10000000 0.80000000 -1.90000000\n0.10000000 0.80000000 0.30000000\n0.10000000 0.80000000 0.35000000\n0.10000000 0.80000000 0.40000000\n0.10000000 0.80000000 0.45000000\n0.10000000 0.80000000 0.50000000\n0.10000000 0.80000000 0.55000000\n0.10000000 0.80000000 0.60000000\n0.10000000 0.80000000 0.65000000\n0.10000000 0.80000000 0.70000000\n0.10000000 0.80000000 0.75000000\n0.10000000 0.80000000 0.80000000\n0.10000000 0.85000000 -1.90000000\n0.10000000 0.85000000 0.05000000\n0.10000000 0.85000000 0.10000000\n0.10000000 0.85000000 0.15000000\n0.10000000 0.85000000 0.20000000\n0.10000000 0.85000000 0.25000000\n0.10000000 0.90000000 -1.85000000\n0.10000000 0.90000000 0.00000000\n0.10000000 0.95000000 -1.80000000\n0.10000000 0.95000000 -0.10000000\n0.10000000 0.95000000 -0.05000000\n0.10000000 1.00000000 -1.75000000\n0.10000000 1.00000000 -1.70000000\n0.10000000 1.00000000 -0.20000000\n0.10000000 1.00000000 -0.15000000\n0.10000000 1.05000000 -1.65000000\n0.10000000 1.05000000 -1.60000000\n0.10000000 1.05000000 -0.35000000\n0.10000000 1.05000000 -0.30000000\n0.10000000 1.05000000 -0.25000000\n0.10000000 1.10000000 -1.55000000\n0.10000000 1.10000000 -1.50000000\n0.10000000 1.10000000 -1.45000000\n0.10000000 1.10000000 -1.40000000\n0.10000000 1.10000000 -0.50000000\n0.10000000 1.10000000 -0.45000000\n0.10000000 1.10000000 -0.40000000\n0.10000000 1.15000000 -1.35000000\n0.10000000 1.15000000 -1.30000000\n0.10000000 1.15000000 -1.25000000\n0.10000000 1.15000000 -1.20000000\n0.10000000 1.15000000 -1.15000000\n0.10000000 1.15000000 -1.10000000\n0.10000000 1.15000000 -1.05000000\n0.10000000 1.15000000 -1.00000000\n0.10000000 1.15000000 -0.95000000\n0.10000000 1.15000000 -0.90000000\n0.10000000 1.15000000 -0.85000000\n0.10000000 1.15000000 -0.80000000\n0.10000000 1.15000000 -0.75000000\n0.10000000 1.15000000 -0.70000000\n0.10000000 1.15000000 -0.65000000\n0.10000000 1.15000000 -0.60000000\n0.10000000 1.15000000 -0.55000000\n0.15000000 0.10000000 -0.70000000\n0.15000000 0.10000000 -0.65000000\n0.15000000 0.10000000 -0.60000000\n0.15000000 0.10000000 -0.55000000\n0.15000000 0.10000000 -0.50000000\n0.15000000 0.10000000 -0.45000000\n0.15000000 0.10000000 -0.40000000\n0.15000000 0.10000000 -0.35000000\n0.15000000 0.10000000 -0.30000000\n0.15000000 0.10000000 -0.25000000\n0.15000000 0.10000000 -0.20000000\n0.15000000 0.10000000 -0.15000000\n0.15000000 0.10000000 -0.10000000\n0.15000000 0.10000000 -0.05000000\n0.15000000 0.10000000 0.00000000\n0.15000000 0.10000000 0.05000000\n0.15000000 0.10000000 0.10000000\n0.15000000 0.10000000 0.15000000\n0.15000000 0.10000000 0.20000000\n0.15000000 0.10000000 0.25000000\n0.15000000 0.10000000 0.30000000\n0.15000000 0.10000000 0.35000000\n0.15000000 0.10000000 0.40000000\n0.15000000 0.10000000 0.45000000\n0.15000000 0.10000000 0.50000000\n0.15000000 0.10000000 0.55000000\n0.15000000 0.10000000 0.60000000\n0.15000000 0.10000000 0.65000000\n0.15000000 0.10000000 0.70000000\n0.15000000 0.10000000 0.75000000\n0.15000000 0.10000000 0.80000000\n0.15000000 0.10000000 0.85000000\n0.15000000 0.10000000 0.90000000\n0.15000000 0.10000000 0.95000000\n0.15000000 0.10000000 1.00000000\n0.15000000 0.10000000 1.05000000\n0.15000000 0.10000000 1.10000000\n0.15000000 0.10000000 1.15000000\n0.15000000 0.10000000 1.20000000\n0.15000000 0.10000000 1.55000000\n0.15000000 0.10000000 1.60000000\n0.15000000 0.10000000 1.65000000\n0.15000000 0.10000000 1.70000000\n0.15000000 0.10000000 1.75000000\n0.15000000 0.10000000 1.80000000\n0.15000000 0.10000000 1.85000000\n0.15000000 0.10000000 1.90000000\n0.15000000 0.10000000 1.95000000\n0.15000000 0.15000000 -1.15000000\n0.15000000 0.15000000 -1.10000000\n0.15000000 0.15000000 -1.05000000\n0.15000000 0.15000000 -1.00000000\n0.15000000 0.15000000 -0.95000000\n0.15000000 0.15000000 -0.90000000\n0.15000000 0.15000000 -0.85000000\n0.15000000 0.15000000 -0.80000000\n0.15000000 0.15000000 -0.75000000\n0.15000000 0.15000000 1.25000000\n0.15000000 0.15000000 1.30000000\n0.15000000 0.15000000 1.35000000\n0.15000000 0.15000000 1.40000000\n0.15000000 0.15000000 1.45000000\n0.15000000 0.15000000 1.50000000\n0.15000000 0.15000000 2.00000000\n0.15000000 0.15000000 2.05000000\n0.15000000 0.20000000 -1.40000000\n0.15000000 0.20000000 -1.35000000\n0.15000000 0.20000000 -1.30000000\n0.15000000 0.20000000 -1.25000000\n0.15000000 0.20000000 -1.20000000\n0.15000000 0.20000000 2.10000000\n0.15000000 0.25000000 -1.50000000\n0.15000000 0.25000000 -1.45000000\n0.15000000 0.25000000 2.10000000\n0.15000000 0.30000000 -1.65000000\n0.15000000 0.30000000 -1.60000000\n0.15000000 0.30000000 -1.55000000\n0.15000000 0.30000000 2.15000000\n0.15000000 0.35000000 -1.75000000\n0.15000000 0.35000000 -1.70000000\n0.15000000 0.35000000 2.15000000\n0.15000000 0.40000000 -1.80000000\n0.15000000 0.40000000 2.15000000\n0.15000000 0.45000000 -1.85000000\n0.15000000 0.45000000 2.10000000\n0.15000000 0.50000000 -1.85000000\n0.15000000 0.50000000 2.10000000\n0.15000000 0.55000000 -1.90000000\n0.15000000 0.55000000 2.05000000\n0.15000000 0.60000000 -1.90000000\n0.15000000 0.60000000 1.95000000\n0.15000000 0.60000000 2.00000000\n0.15000000 0.65000000 -1.90000000\n0.15000000 0.65000000 1.40000000\n0.15000000 0.65000000 1.45000000\n0.15000000 0.65000000 1.50000000\n0.15000000 0.65000000 1.55000000\n0.15000000 0.65000000 1.60000000\n0.15000000 0.65000000 1.65000000\n0.15000000 0.65000000 1.70000000\n0.15000000 0.65000000 1.75000000\n0.15000000 0.65000000 1.80000000\n0.15000000 0.65000000 1.85000000\n0.15000000 0.65000000 1.90000000\n0.15000000 0.70000000 -1.95000000\n0.15000000 0.70000000 1.15000000\n0.15000000 0.70000000 1.20000000\n0.15000000 0.70000000 1.25000000\n0.15000000 0.70000000 1.30000000\n0.15000000 0.70000000 1.35000000\n0.15000000 0.75000000 -1.90000000\n0.15000000 0.75000000 0.75000000\n0.15000000 0.75000000 0.80000000\n0.15000000 0.75000000 0.85000000\n0.15000000 0.75000000 0.90000000\n0.15000000 0.75000000 0.95000000\n0.15000000 0.75000000 1.00000000\n0.15000000 0.75000000 1.05000000\n0.15000000 0.75000000 1.10000000\n0.15000000 0.80000000 -1.90000000\n0.15000000 0.80000000 0.10000000\n0.15000000 0.80000000 0.15000000\n0.15000000 0.80000000 0.20000000\n0.15000000 0.80000000 0.25000000\n0.15000000 0.80000000 0.30000000\n0.15000000 0.80000000 0.35000000\n0.15000000 0.80000000 0.40000000\n0.15000000 0.80000000 0.45000000\n0.15000000 0.80000000 0.50000000\n0.15000000 0.80000000 0.55000000\n0.15000000 0.80000000 0.60000000\n0.15000000 0.80000000 0.65000000\n0.15000000 0.80000000 0.70000000\n0.15000000 0.85000000 -1.90000000\n0.15000000 0.85000000 0.05000000\n0.15000000 0.90000000 -1.85000000\n0.15000000 0.90000000 -0.05000000\n0.15000000 0.90000000 0.00000000\n0.15000000 0.95000000 -1.80000000\n0.15000000 0.95000000 -0.10000000\n0.15000000 1.00000000 -1.75000000\n0.15000000 1.00000000 -1.70000000\n0.15000000 1.00000000 -0.20000000\n0.15000000 1.00000000 -0.15000000\n0.15000000 1.05000000 -1.65000000\n0.15000000 1.05000000 -1.60000000\n0.15000000 1.05000000 -0.35000000\n0.15000000 1.05000000 -0.30000000\n0.15000000 1.05000000 -0.25000000\n0.15000000 1.10000000 -1.55000000\n0.15000000 1.10000000 -1.50000000\n0.15000000 1.10000000 -1.45000000\n0.15000000 1.10000000 -1.40000000\n0.15000000 1.10000000 -0.55000000\n0.15000000 1.10000000 -0.50000000\n0.15000000 1.10000000 -0.45000000\n0.15000000 1.10000000 -0.40000000\n0.15000000 1.15000000 -1.35000000\n0.15000000 1.15000000 -1.30000000\n0.15000000 1.15000000 -1.25000000\n0.15000000 1.15000000 -1.20000000\n0.15000000 1.15000000 -1.15000000\n0.15000000 1.15000000 -1.10000000\n0.15000000 1.15000000 -1.05000000\n0.15000000 1.15000000 -1.00000000\n0.15000000 1.15000000 -0.95000000\n0.15000000 1.15000000 -0.90000000\n0.15000000 1.15000000 -0.85000000\n0.15000000 1.15000000 -0.80000000\n0.15000000 1.15000000 -0.75000000\n0.15000000 1.15000000 -0.70000000\n0.15000000 1.15000000 -0.65000000\n0.15000000 1.15000000 -0.60000000\n0.20000000 0.10000000 -0.65000000\n0.20000000 0.10000000 -0.60000000\n0.20000000 0.10000000 -0.55000000\n0.20000000 0.10000000 -0.50000000\n0.20000000 0.10000000 -0.45000000\n0.20000000 0.10000000 -0.40000000\n0.20000000 0.10000000 -0.35000000\n0.20000000 0.10000000 -0.30000000\n0.20000000 0.10000000 -0.25000000\n0.20000000 0.10000000 -0.20000000\n0.20000000 0.10000000 -0.15000000\n0.20000000 0.10000000 -0.10000000\n0.20000000 0.10000000 -0.05000000\n0.20000000 0.10000000 0.00000000\n0.20000000 0.10000000 0.05000000\n0.20000000 0.10000000 0.10000000\n0.20000000 0.10000000 0.15000000\n0.20000000 0.10000000 0.20000000\n0.20000000 0.10000000 0.25000000\n0.20000000 0.10000000 0.30000000\n0.20000000 0.10000000 0.35000000\n0.20000000 0.10000000 0.40000000\n0.20000000 0.10000000 0.45000000\n0.20000000 0.10000000 0.50000000\n0.20000000 0.10000000 0.55000000\n0.20000000 0.10000000 0.60000000\n0.20000000 0.10000000 0.65000000\n0.20000000 0.10000000 0.70000000\n0.20000000 0.10000000 0.75000000\n0.20000000 0.10000000 0.80000000\n0.20000000 0.10000000 1.55000000\n0.20000000 0.10000000 1.60000000\n0.20000000 0.10000000 1.65000000\n0.20000000 0.10000000 1.70000000\n0.20000000 0.10000000 1.75000000\n0.20000000 0.10000000 1.80000000\n0.20000000 0.10000000 1.85000000\n0.20000000 0.10000000 1.90000000\n0.20000000 0.10000000 1.95000000\n0.20000000 0.15000000 -1.15000000\n0.20000000 0.15000000 -1.10000000\n0.20000000 0.15000000 -1.05000000\n0.20000000 0.15000000 -1.00000000\n0.20000000 0.15000000 -0.95000000\n0.20000000 0.15000000 -0.90000000\n0.20000000 0.15000000 -0.85000000\n0.20000000 0.15000000 -0.80000000\n0.20000000 0.15000000 -0.75000000\n0.20000000 0.15000000 -0.70000000\n0.20000000 0.15000000 0.85000000\n0.20000000 0.15000000 0.90000000\n0.20000000 0.15000000 0.95000000\n0.20000000 0.15000000 1.00000000\n0.20000000 0.15000000 1.05000000\n0.20000000 0.15000000 1.10000000\n0.20000000 0.15000000 1.15000000\n0.20000000 0.15000000 1.20000000\n0.20000000 0.15000000 1.25000000\n0.20000000 0.15000000 1.30000000\n0.20000000 0.15000000 1.35000000\n0.20000000 0.15000000 1.40000000\n0.20000000 0.15000000 1.45000000\n0.20000000 0.15000000 1.50000000\n0.20000000 0.15000000 2.00000000\n0.20000000 0.15000000 2.05000000\n0.20000000 0.20000000 -1.40000000\n0.20000000 0.20000000 -1.35000000\n0.20000000 0.20000000 -1.30000000\n0.20000000 0.20000000 -1.25000000\n0.20000000 0.20000000 -1.20000000\n0.20000000 0.20000000 2.10000000\n0.20000000 0.25000000 -1.50000000\n0.20000000 0.25000000 -1.45000000\n0.20000000 0.25000000 2.10000000\n0.20000000 0.30000000 -1.60000000\n0.20000000 0.30000000 -1.55000000\n0.20000000 0.30000000 2.15000000\n0.20000000 0.35000000 -1.70000000\n0.20000000 0.35000000 -1.65000000\n0.20000000 0.35000000 2.15000000\n0.20000000 0.40000000 -1.80000000\n0.20000000 0.40000000 -1.75000000\n0.20000000 0.40000000 2.15000000\n0.20000000 0.45000000 -1.85000000\n0.20000000 0.45000000 2.10000000\n0.20000000 0.50000000 -1.85000000\n0.20000000 0.50000000 2.10000000\n0.20000000 0.55000000 -1.90000000\n0.20000000 0.55000000 2.05000000\n0.20000000 0.60000000 -1.90000000\n0.20000000 0.60000000 1.55000000\n0.20000000 0.60000000 1.60000000\n0.20000000 0.60000000 1.95000000\n0.20000000 0.60000000 2.00000000\n0.20000000 0.65000000 -1.90000000\n0.20000000 0.65000000 1.30000000\n0.20000000 0.65000000 1.35000000\n0.20000000 0.65000000 1.40000000\n0.20000000 0.65000000 1.45000000\n0.20000000 0.65000000 1.50000000\n0.20000000 0.65000000 1.65000000\n0.20000000 0.65000000 1.70000000\n0.20000000 0.65000000 1.75000000\n0.20000000 0.65000000 1.80000000\n0.20000000 0.65000000 1.85000000\n0.20000000 0.65000000 1.90000000\n0.20000000 0.70000000 -1.90000000\n0.20000000 0.70000000 1.05000000\n0.20000000 0.70000000 1.10000000\n0.20000000 0.70000000 1.15000000\n0.20000000 0.70000000 1.20000000\n0.20000000 0.70000000 1.25000000\n0.20000000 0.75000000 -1.90000000\n0.20000000 0.75000000 0.60000000\n0.20000000 0.75000000 0.65000000\n0.20000000 0.75000000 0.70000000\n0.20000000 0.75000000 0.75000000\n0.20000000 0.75000000 0.80000000\n0.20000000 0.75000000 0.85000000\n0.20000000 0.75000000 0.90000000\n0.20000000 0.75000000 0.95000000\n0.20000000 0.75000000 1.00000000\n0.20000000 0.80000000 -1.90000000\n0.20000000 0.80000000 0.10000000\n0.20000000 0.80000000 0.15000000\n0.20000000 0.80000000 0.20000000\n0.20000000 0.80000000 0.25000000\n0.20000000 0.80000000 0.30000000\n0.20000000 0.80000000 0.35000000\n0.20000000 0.80000000 0.40000000\n0.20000000 0.80000000 0.45000000\n0.20000000 0.80000000 0.50000000\n0.20000000 0.80000000 0.55000000\n0.20000000 0.85000000 -1.90000000\n0.20000000 0.85000000 0.05000000\n0.20000000 0.90000000 -1.85000000\n0.20000000 0.90000000 -0.05000000\n0.20000000 0.90000000 0.00000000\n0.20000000 0.95000000 -1.80000000\n0.20000000 0.95000000 -1.75000000\n0.20000000 0.95000000 -0.10000000\n0.20000000 1.00000000 -1.70000000\n0.20000000 1.00000000 -0.20000000\n0.20000000 1.00000000 -0.15000000\n0.20000000 1.05000000 -1.65000000\n0.20000000 1.05000000 -1.60000000\n0.20000000 1.05000000 -1.55000000\n0.20000000 1.05000000 -0.35000000\n0.20000000 1.05000000 -0.30000000\n0.20000000 1.05000000 -0.25000000\n0.20000000 1.10000000 -1.50000000\n0.20000000 1.10000000 -1.45000000\n0.20000000 1.10000000 -1.40000000\n0.20000000 1.10000000 -1.35000000\n0.20000000 1.10000000 -0.55000000\n0.20000000 1.10000000 -0.50000000\n0.20000000 1.10000000 -0.45000000\n0.20000000 1.10000000 -0.40000000\n0.20000000 1.15000000 -1.30000000\n0.20000000 1.15000000 -1.25000000\n0.20000000 1.15000000 -1.20000000\n0.20000000 1.15000000 -1.15000000\n0.20000000 1.15000000 -1.10000000\n0.20000000 1.15000000 -1.05000000\n0.20000000 1.15000000 -1.00000000\n0.20000000 1.15000000 -0.95000000\n0.20000000 1.15000000 -0.90000000\n0.20000000 1.15000000 -0.85000000\n0.20000000 1.15000000 -0.80000000\n0.20000000 1.15000000 -0.75000000\n0.20000000 1.15000000 -0.70000000\n0.20000000 1.15000000 -0.65000000\n0.20000000 1.15000000 -0.60000000\n0.25000000 0.10000000 -0.60000000\n0.25000000 0.10000000 -0.55000000\n0.25000000 0.10000000 -0.50000000\n0.25000000 0.10000000 -0.45000000\n0.25000000 0.10000000 -0.40000000\n0.25000000 0.10000000 -0.35000000\n0.25000000 0.10000000 -0.30000000\n0.25000000 0.10000000 -0.25000000\n0.25000000 0.10000000 -0.20000000\n0.25000000 0.10000000 -0.15000000\n0.25000000 0.10000000 -0.10000000\n0.25000000 0.10000000 -0.05000000\n0.25000000 0.10000000 0.00000000\n0.25000000 0.10000000 0.05000000\n0.25000000 0.10000000 0.10000000\n0.25000000 0.10000000 0.15000000\n0.25000000 0.10000000 0.20000000\n0.25000000 0.10000000 0.25000000\n0.25000000 0.10000000 0.30000000\n0.25000000 0.10000000 0.35000000\n0.25000000 0.10000000 0.40000000\n0.25000000 0.10000000 0.45000000\n0.25000000 0.10000000 0.50000000\n0.25000000 0.10000000 0.55000000\n0.25000000 0.10000000 0.60000000\n0.25000000 0.10000000 0.65000000\n0.25000000 0.10000000 0.70000000\n0.25000000 0.10000000 0.75000000\n0.25000000 0.10000000 1.55000000\n0.25000000 0.10000000 1.60000000\n0.25000000 0.10000000 1.65000000\n0.25000000 0.10000000 1.70000000\n0.25000000 0.10000000 1.75000000\n0.25000000 0.10000000 1.80000000\n0.25000000 0.10000000 1.85000000\n0.25000000 0.10000000 1.90000000\n0.25000000 0.10000000 1.95000000\n0.25000000 0.15000000 -1.15000000\n0.25000000 0.15000000 -1.10000000\n0.25000000 0.15000000 -1.05000000\n0.25000000 0.15000000 -1.00000000\n0.25000000 0.15000000 -0.95000000\n0.25000000 0.15000000 -0.90000000\n0.25000000 0.15000000 -0.85000000\n0.25000000 0.15000000 -0.80000000\n0.25000000 0.15000000 -0.75000000\n0.25000000 0.15000000 -0.70000000\n0.25000000 0.15000000 -0.65000000\n0.25000000 0.15000000 0.80000000\n0.25000000 0.15000000 0.85000000\n0.25000000 0.15000000 0.90000000\n0.25000000 0.15000000 0.95000000\n0.25000000 0.15000000 1.00000000\n0.25000000 0.15000000 1.05000000\n0.25000000 0.15000000 1.10000000\n0.25000000 0.15000000 1.15000000\n0.25000000 0.15000000 1.20000000\n0.25000000 0.15000000 1.25000000\n0.25000000 0.15000000 1.50000000\n0.25000000 0.15000000 2.00000000\n0.25000000 0.20000000 -1.35000000\n0.25000000 0.20000000 -1.30000000\n0.25000000 0.20000000 -1.25000000\n0.25000000 0.20000000 -1.20000000\n0.25000000 0.20000000 1.30000000\n0.25000000 0.20000000 1.35000000\n0.25000000 0.20000000 1.40000000\n0.25000000 0.20000000 1.45000000\n0.25000000 0.20000000 2.05000000\n0.25000000 0.25000000 -1.50000000\n0.25000000 0.25000000 -1.45000000\n0.25000000 0.25000000 -1.40000000\n0.25000000 0.25000000 2.10000000\n0.25000000 0.30000000 -1.60000000\n0.25000000 0.30000000 -1.55000000\n0.25000000 0.30000000 2.10000000\n0.25000000 0.35000000 -1.70000000\n0.25000000 0.35000000 -1.65000000\n0.25000000 0.35000000 2.15000000\n0.25000000 0.40000000 -1.80000000\n0.25000000 0.40000000 -1.75000000\n0.25000000 0.40000000 2.15000000\n0.25000000 0.45000000 -1.80000000\n0.25000000 0.45000000 2.10000000\n0.25000000 0.50000000 -1.85000000\n0.25000000 0.50000000 2.10000000\n0.25000000 0.55000000 -1.85000000\n0.25000000 0.55000000 2.05000000\n0.25000000 0.60000000 -1.90000000\n0.25000000 0.60000000 1.40000000\n0.25000000 0.60000000 1.45000000\n0.25000000 0.60000000 1.50000000\n0.25000000 0.60000000 1.55000000\n0.25000000 0.60000000 1.60000000\n0.25000000 0.60000000 1.90000000\n0.25000000 0.60000000 1.95000000\n0.25000000 0.60000000 2.00000000\n0.25000000 0.65000000 -1.90000000\n0.25000000 0.65000000 1.15000000\n0.25000000 0.65000000 1.20000000\n0.25000000 0.65000000 1.25000000\n0.25000000 0.65000000 1.30000000\n0.25000000 0.65000000 1.35000000\n0.25000000 0.65000000 1.65000000\n0.25000000 0.65000000 1.70000000\n0.25000000 0.65000000 1.75000000\n0.25000000 0.65000000 1.80000000\n0.25000000 0.65000000 1.85000000\n0.25000000 0.70000000 -1.90000000\n0.25000000 0.70000000 0.85000000\n0.25000000 0.70000000 0.90000000\n0.25000000 0.70000000 0.95000000\n0.25000000 0.70000000 1.00000000\n0.25000000 0.70000000 1.05000000\n0.25000000 0.70000000 1.10000000\n0.25000000 0.75000000 -1.90000000\n0.25000000 0.75000000 0.35000000\n0.25000000 0.75000000 0.40000000\n0.25000000 0.75000000 0.45000000\n0.25000000 0.75000000 0.50000000\n0.25000000 0.75000000 0.55000000\n0.25000000 0.75000000 0.60000000\n0.25000000 0.75000000 0.65000000\n0.25000000 0.75000000 0.70000000\n0.25000000 0.75000000 0.75000000\n0.25000000 0.75000000 0.80000000\n0.25000000 0.80000000 -1.90000000\n0.25000000 0.80000000 0.05000000\n0.25000000 0.80000000 0.10000000\n0.25000000 0.80000000 0.15000000\n0.25000000 0.80000000 0.20000000\n0.25000000 0.80000000 0.25000000\n0.25000000 0.80000000 0.30000000\n0.25000000 0.85000000 -1.85000000\n0.25000000 0.85000000 0.00000000\n0.25000000 0.90000000 -1.80000000\n0.25000000 0.90000000 -0.05000000\n0.25000000 0.95000000 -1.80000000\n0.25000000 0.95000000 -1.75000000\n0.25000000 0.95000000 -0.15000000\n0.25000000 0.95000000 -0.10000000\n0.25000000 1.00000000 -1.70000000\n0.25000000 1.00000000 -1.65000000\n0.25000000 1.00000000 -0.25000000\n0.25000000 1.00000000 -0.20000000\n0.25000000 1.05000000 -1.60000000\n0.25000000 1.05000000 -1.55000000\n0.25000000 1.05000000 -0.35000000\n0.25000000 1.05000000 -0.30000000\n0.25000000 1.10000000 -1.50000000\n0.25000000 1.10000000 -1.45000000\n0.25000000 1.10000000 -1.40000000\n0.25000000 1.10000000 -1.35000000\n0.25000000 1.10000000 -0.60000000\n0.25000000 1.10000000 -0.55000000\n0.25000000 1.10000000 -0.50000000\n0.25000000 1.10000000 -0.45000000\n0.25000000 1.10000000 -0.40000000\n0.25000000 1.15000000 -1.30000000\n0.25000000 1.15000000 -1.25000000\n0.25000000 1.15000000 -1.20000000\n0.25000000 1.15000000 -1.15000000\n0.25000000 1.15000000 -1.10000000\n0.25000000 1.15000000 -1.05000000\n0.25000000 1.15000000 -1.00000000\n0.25000000 1.15000000 -0.95000000\n0.25000000 1.15000000 -0.90000000\n0.25000000 1.15000000 -0.85000000\n0.25000000 1.15000000 -0.80000000\n0.25000000 1.15000000 -0.75000000\n0.25000000 1.15000000 -0.70000000\n0.25000000 1.15000000 -0.65000000\n0.30000000 0.10000000 -0.55000000\n0.30000000 0.10000000 -0.50000000\n0.30000000 0.10000000 -0.45000000\n0.30000000 0.10000000 -0.40000000\n0.30000000 0.10000000 -0.35000000\n0.30000000 0.10000000 -0.30000000\n0.30000000 0.10000000 -0.25000000\n0.30000000 0.10000000 -0.20000000\n0.30000000 0.10000000 -0.15000000\n0.30000000 0.10000000 -0.10000000\n0.30000000 0.10000000 -0.05000000\n0.30000000 0.10000000 0.00000000\n0.30000000 0.10000000 0.05000000\n0.30000000 0.10000000 0.10000000\n0.30000000 0.10000000 0.15000000\n0.30000000 0.10000000 0.20000000\n0.30000000 0.10000000 0.25000000\n0.30000000 0.10000000 0.30000000\n0.30000000 0.10000000 0.35000000\n0.30000000 0.10000000 0.40000000\n0.30000000 0.10000000 0.45000000\n0.30000000 0.10000000 0.50000000\n0.30000000 0.10000000 0.55000000\n0.30000000 0.10000000 0.60000000\n0.30000000 0.10000000 0.65000000\n0.30000000 0.10000000 0.70000000\n0.30000000 0.10000000 1.60000000\n0.30000000 0.10000000 1.65000000\n0.30000000 0.10000000 1.70000000\n0.30000000 0.10000000 1.75000000\n0.30000000 0.10000000 1.80000000\n0.30000000 0.10000000 1.85000000\n0.30000000 0.10000000 1.90000000\n0.30000000 0.10000000 1.95000000\n0.30000000 0.15000000 -1.10000000\n0.30000000 0.15000000 -1.05000000\n0.30000000 0.15000000 -1.00000000\n0.30000000 0.15000000 -0.95000000\n0.30000000 0.15000000 -0.90000000\n0.30000000 0.15000000 -0.85000000\n0.30000000 0.15000000 -0.80000000\n0.30000000 0.15000000 -0.75000000\n0.30000000 0.15000000 -0.70000000\n0.30000000 0.15000000 -0.65000000\n0.30000000 0.15000000 -0.60000000\n0.30000000 0.15000000 0.75000000\n0.30000000 0.15000000 0.80000000\n0.30000000 0.15000000 0.85000000\n0.30000000 0.15000000 0.90000000\n0.30000000 0.15000000 0.95000000\n0.30000000 0.15000000 1.00000000\n0.30000000 0.15000000 1.50000000\n0.30000000 0.15000000 1.55000000\n0.30000000 0.15000000 2.00000000\n0.30000000 0.20000000 -1.35000000\n0.30000000 0.20000000 -1.30000000\n0.30000000 0.20000000 -1.25000000\n0.30000000 0.20000000 -1.20000000\n0.30000000 0.20000000 -1.15000000\n0.30000000 0.20000000 1.05000000\n0.30000000 0.20000000 1.10000000\n0.30000000 0.20000000 1.15000000\n0.30000000 0.20000000 1.20000000\n0.30000000 0.20000000 1.25000000\n0.30000000 0.20000000 1.30000000\n0.30000000 0.20000000 1.35000000\n0.30000000 0.20000000 1.45000000\n0.30000000 0.20000000 2.05000000\n0.30000000 0.25000000 -1.45000000\n0.30000000 0.25000000 -1.40000000\n0.30000000 0.25000000 1.35000000\n0.30000000 0.25000000 1.40000000\n0.30000000 0.25000000 2.10000000\n0.30000000 0.30000000 -1.60000000\n0.30000000 0.30000000 -1.55000000\n0.30000000 0.30000000 -1.50000000\n0.30000000 0.30000000 2.10000000\n0.30000000 0.35000000 -1.70000000\n0.30000000 0.35000000 -1.65000000\n0.30000000 0.35000000 2.10000000\n0.30000000 0.40000000 -1.75000000\n0.30000000 0.40000000 2.10000000\n0.30000000 0.45000000 -1.80000000\n0.30000000 0.45000000 2.10000000\n0.30000000 0.50000000 -1.85000000\n0.30000000 0.50000000 2.10000000\n0.30000000 0.55000000 -1.85000000\n0.30000000 0.55000000 1.40000000\n0.30000000 0.55000000 1.45000000\n0.30000000 0.55000000 1.50000000\n0.30000000 0.55000000 2.05000000\n0.30000000 0.60000000 -1.90000000\n0.30000000 0.60000000 1.20000000\n0.30000000 0.60000000 1.25000000\n0.30000000 0.60000000 1.30000000\n0.30000000 0.60000000 1.35000000\n0.30000000 0.60000000 1.40000000\n0.30000000 0.60000000 1.55000000\n0.30000000 0.60000000 1.60000000\n0.30000000 0.60000000 1.90000000\n0.30000000 0.60000000 1.95000000\n0.30000000 0.60000000 2.00000000\n0.30000000 0.65000000 -1.90000000\n0.30000000 0.65000000 1.00000000\n0.30000000 0.65000000 1.05000000\n0.30000000 0.65000000 1.10000000\n0.30000000 0.65000000 1.15000000\n0.30000000 0.65000000 1.20000000\n0.30000000 0.65000000 1.65000000\n0.30000000 0.65000000 1.70000000\n0.30000000 0.65000000 1.75000000\n0.30000000 0.65000000 1.80000000\n0.30000000 0.65000000 1.85000000\n0.30000000 0.70000000 -1.90000000\n0.30000000 0.70000000 0.60000000\n0.30000000 0.70000000 0.65000000\n0.30000000 0.70000000 0.70000000\n0.30000000 0.70000000 0.75000000\n0.30000000 0.70000000 0.80000000\n0.30000000 0.70000000 0.85000000\n0.30000000 0.70000000 0.90000000\n0.30000000 0.70000000 0.95000000\n0.30000000 0.75000000 -1.90000000\n0.30000000 0.75000000 0.15000000\n0.30000000 0.75000000 0.20000000\n0.30000000 0.75000000 0.25000000\n0.30000000 0.75000000 0.30000000\n0.30000000 0.75000000 0.35000000\n0.30000000 0.75000000 0.40000000\n0.30000000 0.75000000 0.45000000\n0.30000000 0.75000000 0.50000000\n0.30000000 0.75000000 0.55000000\n0.30000000 0.80000000 -1.85000000\n0.30000000 0.80000000 0.05000000\n0.30000000 0.80000000 0.10000000\n0.30000000 0.85000000 -1.85000000\n0.30000000 0.85000000 0.00000000\n0.30000000 0.90000000 -1.80000000\n0.30000000 0.90000000 -0.05000000\n0.30000000 0.95000000 -1.75000000\n0.30000000 0.95000000 -0.15000000\n0.30000000 0.95000000 -0.10000000\n0.30000000 1.00000000 -1.70000000\n0.30000000 1.00000000 -1.65000000\n0.30000000 1.00000000 -0.25000000\n0.30000000 1.00000000 -0.20000000\n0.30000000 1.05000000 -1.60000000\n0.30000000 1.05000000 -1.55000000\n0.30000000 1.05000000 -1.50000000\n0.30000000 1.05000000 -0.40000000\n0.30000000 1.05000000 -0.35000000\n0.30000000 1.05000000 -0.30000000\n0.30000000 1.10000000 -1.45000000\n0.30000000 1.10000000 -1.40000000\n0.30000000 1.10000000 -1.35000000\n0.30000000 1.10000000 -1.30000000\n0.30000000 1.10000000 -0.60000000\n0.30000000 1.10000000 -0.55000000\n0.30000000 1.10000000 -0.50000000\n0.30000000 1.10000000 -0.45000000\n0.30000000 1.15000000 -1.25000000\n0.30000000 1.15000000 -1.20000000\n0.30000000 1.15000000 -1.15000000\n0.30000000 1.15000000 -1.10000000\n0.30000000 1.15000000 -1.05000000\n0.30000000 1.15000000 -1.00000000\n0.30000000 1.15000000 -0.95000000\n0.30000000 1.15000000 -0.90000000\n0.30000000 1.15000000 -0.85000000\n0.30000000 1.15000000 -0.80000000\n0.30000000 1.15000000 -0.75000000\n0.30000000 1.15000000 -0.70000000\n0.30000000 1.15000000 -0.65000000\n0.35000000 0.10000000 -0.50000000\n0.35000000 0.10000000 -0.45000000\n0.35000000 0.10000000 -0.40000000\n0.35000000 0.10000000 -0.35000000\n0.35000000 0.10000000 -0.30000000\n0.35000000 0.10000000 -0.25000000\n0.35000000 0.10000000 -0.20000000\n0.35000000 0.10000000 -0.15000000\n0.35000000 0.10000000 -0.10000000\n0.35000000 0.10000000 -0.05000000\n0.35000000 0.10000000 0.00000000\n0.35000000 0.10000000 0.05000000\n0.35000000 0.10000000 0.10000000\n0.35000000 0.10000000 0.15000000\n0.35000000 0.10000000 0.20000000\n0.35000000 0.10000000 0.25000000\n0.35000000 0.10000000 0.30000000\n0.35000000 0.10000000 0.35000000\n0.35000000 0.10000000 0.40000000\n0.35000000 0.10000000 0.45000000\n0.35000000 0.10000000 0.50000000\n0.35000000 0.10000000 0.55000000\n0.35000000 0.10000000 0.60000000\n0.35000000 0.10000000 0.65000000\n0.35000000 0.10000000 1.60000000\n0.35000000 0.10000000 1.65000000\n0.35000000 0.10000000 1.70000000\n0.35000000 0.10000000 1.75000000\n0.35000000 0.10000000 1.80000000\n0.35000000 0.10000000 1.85000000\n0.35000000 0.10000000 1.90000000\n0.35000000 0.15000000 -1.05000000\n0.35000000 0.15000000 -1.00000000\n0.35000000 0.15000000 -0.95000000\n0.35000000 0.15000000 -0.90000000\n0.35000000 0.15000000 -0.85000000\n0.35000000 0.15000000 -0.80000000\n0.35000000 0.15000000 -0.75000000\n0.35000000 0.15000000 -0.70000000\n0.35000000 0.15000000 -0.65000000\n0.35000000 0.15000000 -0.60000000\n0.35000000 0.15000000 -0.55000000\n0.35000000 0.15000000 0.70000000\n0.35000000 0.15000000 0.75000000\n0.35000000 0.15000000 0.80000000\n0.35000000 0.15000000 0.85000000\n0.35000000 0.15000000 0.90000000\n0.35000000 0.15000000 0.95000000\n0.35000000 0.15000000 1.00000000\n0.35000000 0.15000000 1.50000000\n0.35000000 0.15000000 1.55000000\n0.35000000 0.15000000 1.95000000\n0.35000000 0.15000000 2.00000000\n0.35000000 0.20000000 -1.30000000\n0.35000000 0.20000000 -1.25000000\n0.35000000 0.20000000 -1.20000000\n0.35000000 0.20000000 -1.15000000\n0.35000000 0.20000000 -1.10000000\n0.35000000 0.20000000 1.05000000\n0.35000000 0.20000000 1.10000000\n0.35000000 0.20000000 1.15000000\n0.35000000 0.20000000 1.45000000\n0.35000000 0.20000000 2.05000000\n0.35000000 0.25000000 -1.45000000\n0.35000000 0.25000000 -1.40000000\n0.35000000 0.25000000 -1.35000000\n0.35000000 0.25000000 1.20000000\n0.35000000 0.25000000 1.25000000\n0.35000000 0.25000000 1.30000000\n0.35000000 0.25000000 1.40000000\n0.35000000 0.25000000 2.10000000\n0.35000000 0.30000000 -1.55000000\n0.35000000 0.30000000 -1.50000000\n0.35000000 0.30000000 1.35000000\n0.35000000 0.30000000 2.10000000\n0.35000000 0.35000000 -1.65000000\n0.35000000 0.35000000 -1.60000000\n0.35000000 0.35000000 2.10000000\n0.35000000 0.40000000 -1.75000000\n0.35000000 0.40000000 -1.70000000\n0.35000000 0.40000000 2.10000000\n0.35000000 0.45000000 -1.80000000\n0.35000000 0.45000000 1.35000000\n0.35000000 0.45000000 2.10000000\n0.35000000 0.50000000 -1.80000000\n0.35000000 0.50000000 1.35000000\n0.35000000 0.50000000 1.40000000\n0.35000000 0.50000000 2.10000000\n0.35000000 0.55000000 -1.85000000\n0.35000000 0.55000000 1.20000000\n0.35000000 0.55000000 1.25000000\n0.35000000 0.55000000 1.30000000\n0.35000000 0.55000000 1.35000000\n0.35000000 0.55000000 1.45000000\n0.35000000 0.55000000 1.50000000\n0.35000000 0.55000000 2.00000000\n0.35000000 0.55000000 2.05000000\n0.35000000 0.60000000 -1.85000000\n0.35000000 0.60000000 1.00000000\n0.35000000 0.60000000 1.05000000\n0.35000000 0.60000000 1.10000000\n0.35000000 0.60000000 1.15000000\n0.35000000 0.60000000 1.55000000\n0.35000000 0.60000000 1.60000000\n0.35000000 0.60000000 1.65000000\n0.35000000 0.60000000 1.85000000\n0.35000000 0.60000000 1.90000000\n0.35000000 0.60000000 1.95000000\n0.35000000 0.65000000 -1.90000000\n0.35000000 0.65000000 0.80000000\n0.35000000 0.65000000 0.85000000\n0.35000000 0.65000000 0.90000000\n0.35000000 0.65000000 0.95000000\n0.35000000 0.65000000 1.70000000\n0.35000000 0.65000000 1.75000000\n0.35000000 0.65000000 1.80000000\n0.35000000 0.70000000 -1.90000000\n0.35000000 0.70000000 0.50000000\n0.35000000 0.70000000 0.55000000\n0.35000000 0.70000000 0.60000000\n0.35000000 0.70000000 0.65000000\n0.35000000 0.70000000 0.70000000\n0.35000000 0.70000000 0.75000000\n0.35000000 0.75000000 -1.85000000\n0.35000000 0.75000000 0.10000000\n0.35000000 0.75000000 0.15000000\n0.35000000 0.75000000 0.20000000\n0.35000000 0.75000000 0.25000000\n0.35000000 0.75000000 0.30000000\n0.35000000 0.75000000 0.35000000\n0.35000000 0.75000000 0.40000000\n0.35000000 0.75000000 0.45000000\n0.35000000 0.80000000 -1.85000000\n0.35000000 0.80000000 0.05000000\n0.35000000 0.85000000 -1.85000000\n0.35000000 0.85000000 0.00000000\n0.35000000 0.90000000 -1.80000000\n0.35000000 0.90000000 -0.10000000\n0.35000000 0.90000000 -0.05000000\n0.35000000 0.95000000 -1.75000000\n0.35000000 0.95000000 -1.70000000\n0.35000000 0.95000000 -0.15000000\n0.35000000 1.00000000 -1.65000000\n0.35000000 1.00000000 -1.60000000\n0.35000000 1.00000000 -0.30000000\n0.35000000 1.00000000 -0.25000000\n0.35000000 1.00000000 -0.20000000\n0.35000000 1.05000000 -1.55000000\n0.35000000 1.05000000 -1.50000000\n0.35000000 1.05000000 -0.45000000\n0.35000000 1.05000000 -0.40000000\n0.35000000 1.05000000 -0.35000000\n0.35000000 1.10000000 -1.45000000\n0.35000000 1.10000000 -1.40000000\n0.35000000 1.10000000 -1.35000000\n0.35000000 1.10000000 -1.30000000\n0.35000000 1.10000000 -1.25000000\n0.35000000 1.10000000 -0.70000000\n0.35000000 1.10000000 -0.65000000\n0.35000000 1.10000000 -0.60000000\n0.35000000 1.10000000 -0.55000000\n0.35000000 1.10000000 -0.50000000\n0.35000000 1.15000000 -1.20000000\n0.35000000 1.15000000 -1.15000000\n0.35000000 1.15000000 -1.10000000\n0.35000000 1.15000000 -1.05000000\n0.35000000 1.15000000 -1.00000000\n0.35000000 1.15000000 -0.95000000\n0.35000000 1.15000000 -0.90000000\n0.35000000 1.15000000 -0.85000000\n0.35000000 1.15000000 -0.80000000\n0.35000000 1.15000000 -0.75000000\n0.40000000 0.10000000 -0.40000000\n0.40000000 0.10000000 -0.35000000\n0.40000000 0.10000000 -0.30000000\n0.40000000 0.10000000 -0.25000000\n0.40000000 0.10000000 -0.20000000\n0.40000000 0.10000000 -0.15000000\n0.40000000 0.10000000 -0.10000000\n0.40000000 0.10000000 -0.05000000\n0.40000000 0.10000000 0.00000000\n0.40000000 0.10000000 0.05000000\n0.40000000 0.10000000 0.10000000\n0.40000000 0.10000000 0.15000000\n0.40000000 0.10000000 0.20000000\n0.40000000 0.10000000 0.25000000\n0.40000000 0.10000000 0.30000000\n0.40000000 0.10000000 0.35000000\n0.40000000 0.10000000 0.40000000\n0.40000000 0.10000000 0.45000000\n0.40000000 0.10000000 0.50000000\n0.40000000 0.10000000 0.55000000\n0.40000000 0.10000000 1.60000000\n0.40000000 0.10000000 1.65000000\n0.40000000 0.10000000 1.70000000\n0.40000000 0.10000000 1.75000000\n0.40000000 0.10000000 1.80000000\n0.40000000 0.10000000 1.85000000\n0.40000000 0.10000000 1.90000000\n0.40000000 0.15000000 -0.90000000\n0.40000000 0.15000000 -0.85000000\n0.40000000 0.15000000 -0.80000000\n0.40000000 0.15000000 -0.75000000\n0.40000000 0.15000000 -0.70000000\n0.40000000 0.15000000 -0.65000000\n0.40000000 0.15000000 -0.60000000\n0.40000000 0.15000000 -0.55000000\n0.40000000 0.15000000 -0.50000000\n0.40000000 0.15000000 -0.45000000\n0.40000000 0.15000000 0.60000000\n0.40000000 0.15000000 0.65000000\n0.40000000 0.15000000 0.70000000\n0.40000000 0.15000000 0.75000000\n0.40000000 0.15000000 0.80000000\n0.40000000 0.15000000 0.85000000\n0.40000000 0.15000000 0.90000000\n0.40000000 0.15000000 0.95000000\n0.40000000 0.15000000 1.50000000\n0.40000000 0.15000000 1.55000000\n0.40000000 0.15000000 1.95000000\n0.40000000 0.15000000 2.00000000\n0.40000000 0.20000000 -1.25000000\n0.40000000 0.20000000 -1.20000000\n0.40000000 0.20000000 -1.15000000\n0.40000000 0.20000000 -1.10000000\n0.40000000 0.20000000 -1.05000000\n0.40000000 0.20000000 -1.00000000\n0.40000000 0.20000000 -0.95000000\n0.40000000 0.20000000 1.00000000\n0.40000000 0.20000000 1.05000000\n0.40000000 0.20000000 1.10000000\n0.40000000 0.20000000 1.45000000\n0.40000000 0.20000000 2.05000000\n0.40000000 0.25000000 -1.40000000\n0.40000000 0.25000000 -1.35000000\n0.40000000 0.25000000 -1.30000000\n0.40000000 0.25000000 1.15000000\n0.40000000 0.25000000 1.20000000\n0.40000000 0.25000000 1.25000000\n0.40000000 0.25000000 1.45000000\n0.40000000 0.25000000 2.10000000\n0.40000000 0.30000000 -1.55000000\n0.40000000 0.30000000 -1.50000000\n0.40000000 0.30000000 -1.45000000\n0.40000000 0.30000000 1.30000000\n0.40000000 0.30000000 1.40000000\n0.40000000 0.30000000 2.10000000\n0.40000000 0.35000000 -1.60000000\n0.40000000 0.35000000 1.35000000\n0.40000000 0.35000000 2.10000000\n0.40000000 0.40000000 -1.70000000\n0.40000000 0.40000000 -1.65000000\n0.40000000 0.40000000 1.35000000\n0.40000000 0.40000000 2.10000000\n0.40000000 0.45000000 -1.75000000\n0.40000000 0.45000000 1.30000000\n0.40000000 0.45000000 1.40000000\n0.40000000 0.45000000 2.10000000\n0.40000000 0.50000000 -1.80000000\n0.40000000 0.50000000 1.25000000\n0.40000000 0.50000000 1.30000000\n0.40000000 0.50000000 1.45000000\n0.40000000 0.50000000 2.05000000\n0.40000000 0.55000000 -1.85000000\n0.40000000 0.55000000 1.10000000\n0.40000000 0.55000000 1.15000000\n0.40000000 0.55000000 1.20000000\n0.40000000 0.55000000 1.50000000\n0.40000000 0.55000000 2.00000000\n0.40000000 0.55000000 2.05000000\n0.40000000 0.60000000 -1.85000000\n0.40000000 0.60000000 0.95000000\n0.40000000 0.60000000 1.00000000\n0.40000000 0.60000000 1.05000000\n0.40000000 0.60000000 1.55000000\n0.40000000 0.60000000 1.60000000\n0.40000000 0.60000000 1.65000000\n0.40000000 0.60000000 1.70000000\n0.40000000 0.60000000 1.75000000\n0.40000000 0.60000000 1.80000000\n0.40000000 0.60000000 1.85000000\n0.40000000 0.60000000 1.90000000\n0.40000000 0.60000000 1.95000000\n0.40000000 0.65000000 -1.85000000\n0.40000000 0.65000000 0.75000000\n0.40000000 0.65000000 0.80000000\n0.40000000 0.65000000 0.85000000\n0.40000000 0.65000000 0.90000000\n0.40000000 0.70000000 -1.85000000\n0.40000000 0.70000000 0.45000000\n0.40000000 0.70000000 0.50000000\n0.40000000 0.70000000 0.55000000\n0.40000000 0.70000000 0.60000000\n0.40000000 0.70000000 0.65000000\n0.40000000 0.70000000 0.70000000\n0.40000000 0.75000000 -1.85000000\n0.40000000 0.75000000 0.05000000\n0.40000000 0.75000000 0.10000000\n0.40000000 0.75000000 0.15000000\n0.40000000 0.75000000 0.20000000\n0.40000000 0.75000000 0.25000000\n0.40000000 0.75000000 0.30000000\n0.40000000 0.75000000 0.35000000\n0.40000000 0.75000000 0.40000000\n0.40000000 0.80000000 -1.85000000\n0.40000000 0.80000000 0.00000000\n0.40000000 0.85000000 -1.80000000\n0.40000000 0.85000000 -0.05000000\n0.40000000 0.90000000 -1.75000000\n0.40000000 0.90000000 -0.10000000\n0.40000000 0.95000000 -1.70000000\n0.40000000 0.95000000 -0.20000000\n0.40000000 0.95000000 -0.15000000\n0.40000000 1.00000000 -1.65000000\n0.40000000 1.00000000 -1.60000000\n0.40000000 1.00000000 -0.30000000\n0.40000000 1.00000000 -0.25000000\n0.40000000 1.05000000 -1.55000000\n0.40000000 1.05000000 -1.50000000\n0.40000000 1.05000000 -1.45000000\n0.40000000 1.05000000 -0.45000000\n0.40000000 1.05000000 -0.40000000\n0.40000000 1.05000000 -0.35000000\n0.40000000 1.10000000 -1.40000000\n0.40000000 1.10000000 -1.35000000\n0.40000000 1.10000000 -1.30000000\n0.40000000 1.10000000 -1.25000000\n0.40000000 1.10000000 -1.20000000\n0.40000000 1.10000000 -0.80000000\n0.40000000 1.10000000 -0.75000000\n0.40000000 1.10000000 -0.70000000\n0.40000000 1.10000000 -0.65000000\n0.40000000 1.10000000 -0.60000000\n0.40000000 1.10000000 -0.55000000\n0.40000000 1.10000000 -0.50000000\n0.40000000 1.15000000 -1.15000000\n0.40000000 1.15000000 -1.10000000\n0.40000000 1.15000000 -1.05000000\n0.40000000 1.15000000 -1.00000000\n0.40000000 1.15000000 -0.95000000\n0.40000000 1.15000000 -0.90000000\n0.40000000 1.15000000 -0.85000000\n0.45000000 0.10000000 -0.20000000\n0.45000000 0.10000000 -0.15000000\n0.45000000 0.10000000 -0.10000000\n0.45000000 0.10000000 -0.05000000\n0.45000000 0.10000000 0.00000000\n0.45000000 0.10000000 0.05000000\n0.45000000 0.10000000 0.10000000\n0.45000000 0.10000000 0.15000000\n0.45000000 0.10000000 0.20000000\n0.45000000 0.10000000 0.25000000\n0.45000000 0.10000000 0.30000000\n0.45000000 0.10000000 0.35000000\n0.45000000 0.10000000 0.40000000\n0.45000000 0.10000000 1.65000000\n0.45000000 0.10000000 1.70000000\n0.45000000 0.10000000 1.75000000\n0.45000000 0.10000000 1.80000000\n0.45000000 0.10000000 1.85000000\n0.45000000 0.15000000 -0.80000000\n0.45000000 0.15000000 -0.75000000\n0.45000000 0.15000000 -0.70000000\n0.45000000 0.15000000 -0.65000000\n0.45000000 0.15000000 -0.60000000\n0.45000000 0.15000000 -0.55000000\n0.45000000 0.15000000 -0.50000000\n0.45000000 0.15000000 -0.45000000\n0.45000000 0.15000000 -0.40000000\n0.45000000 0.15000000 -0.35000000\n0.45000000 0.15000000 -0.30000000\n0.45000000 0.15000000 -0.25000000\n0.45000000 0.15000000 0.45000000\n0.45000000 0.15000000 0.50000000\n0.45000000 0.15000000 0.55000000\n0.45000000 0.15000000 0.60000000\n0.45000000 0.15000000 0.65000000\n0.45000000 0.15000000 0.70000000\n0.45000000 0.15000000 0.75000000\n0.45000000 0.15000000 0.80000000\n0.45000000 0.15000000 0.85000000\n0.45000000 0.15000000 1.55000000\n0.45000000 0.15000000 1.60000000\n0.45000000 0.15000000 1.90000000\n0.45000000 0.15000000 1.95000000\n0.45000000 0.15000000 2.00000000\n0.45000000 0.20000000 -1.20000000\n0.45000000 0.20000000 -1.15000000\n0.45000000 0.20000000 -1.10000000\n0.45000000 0.20000000 -1.05000000\n0.45000000 0.20000000 -1.00000000\n0.45000000 0.20000000 -0.95000000\n0.45000000 0.20000000 -0.90000000\n0.45000000 0.20000000 -0.85000000\n0.45000000 0.20000000 0.90000000\n0.45000000 0.20000000 0.95000000\n0.45000000 0.20000000 1.00000000\n0.45000000 0.20000000 1.05000000\n0.45000000 0.20000000 1.10000000\n0.45000000 0.20000000 1.45000000\n0.45000000 0.20000000 1.50000000\n0.45000000 0.20000000 2.05000000\n0.45000000 0.25000000 -1.40000000\n0.45000000 0.25000000 -1.35000000\n0.45000000 0.25000000 -1.30000000\n0.45000000 0.25000000 -1.25000000\n0.45000000 0.25000000 1.15000000\n0.45000000 0.25000000 1.20000000\n0.45000000 0.25000000 1.45000000\n0.45000000 0.25000000 2.05000000\n0.45000000 0.30000000 -1.50000000\n0.45000000 0.30000000 -1.45000000\n0.45000000 0.30000000 1.25000000\n0.45000000 0.30000000 1.40000000\n0.45000000 0.30000000 2.10000000\n0.45000000 0.35000000 -1.60000000\n0.45000000 0.35000000 -1.55000000\n0.45000000 0.35000000 1.30000000\n0.45000000 0.35000000 1.40000000\n0.45000000 0.35000000 2.10000000\n0.45000000 0.40000000 -1.65000000\n0.45000000 0.40000000 1.30000000\n0.45000000 0.40000000 1.40000000\n0.45000000 0.40000000 2.10000000\n0.45000000 0.45000000 -1.75000000\n0.45000000 0.45000000 -1.70000000\n0.45000000 0.45000000 1.30000000\n0.45000000 0.45000000 1.40000000\n0.45000000 0.45000000 2.10000000\n0.45000000 0.50000000 -1.80000000\n0.45000000 0.50000000 1.20000000\n0.45000000 0.50000000 1.25000000\n0.45000000 0.50000000 1.45000000\n0.45000000 0.50000000 2.05000000\n0.45000000 0.55000000 -1.80000000\n0.45000000 0.55000000 1.10000000\n0.45000000 0.55000000 1.15000000\n0.45000000 0.55000000 1.50000000\n0.45000000 0.55000000 2.00000000\n0.45000000 0.60000000 -1.80000000\n0.45000000 0.60000000 0.90000000\n0.45000000 0.60000000 0.95000000\n0.45000000 0.60000000 1.00000000\n0.45000000 0.60000000 1.05000000\n0.45000000 0.60000000 1.55000000\n0.45000000 0.60000000 1.60000000\n0.45000000 0.60000000 1.65000000\n0.45000000 0.60000000 1.70000000\n0.45000000 0.60000000 1.75000000\n0.45000000 0.60000000 1.80000000\n0.45000000 0.60000000 1.85000000\n0.45000000 0.60000000 1.90000000\n0.45000000 0.60000000 1.95000000\n0.45000000 0.65000000 -1.85000000\n0.45000000 0.65000000 0.70000000\n0.45000000 0.65000000 0.75000000\n0.45000000 0.65000000 0.80000000\n0.45000000 0.65000000 0.85000000\n0.45000000 0.70000000 -1.85000000\n0.45000000 0.70000000 0.40000000\n0.45000000 0.70000000 0.45000000\n0.45000000 0.70000000 0.50000000\n0.45000000 0.70000000 0.55000000\n0.45000000 0.70000000 0.60000000\n0.45000000 0.70000000 0.65000000\n0.45000000 0.75000000 -1.85000000\n0.45000000 0.75000000 0.05000000\n0.45000000 0.75000000 0.10000000\n0.45000000 0.75000000 0.15000000\n0.45000000 0.75000000 0.20000000\n0.45000000 0.75000000 0.25000000\n0.45000000 0.75000000 0.30000000\n0.45000000 0.75000000 0.35000000\n0.45000000 0.80000000 -1.80000000\n0.45000000 0.80000000 0.00000000\n0.45000000 0.85000000 -1.80000000\n0.45000000 0.85000000 -0.05000000\n0.45000000 0.90000000 -1.75000000\n0.45000000 0.90000000 -0.15000000\n0.45000000 0.90000000 -0.10000000\n0.45000000 0.95000000 -1.70000000\n0.45000000 0.95000000 -0.20000000\n0.45000000 1.00000000 -1.65000000\n0.45000000 1.00000000 -1.60000000\n0.45000000 1.00000000 -1.55000000\n0.45000000 1.00000000 -0.35000000\n0.45000000 1.00000000 -0.30000000\n0.45000000 1.00000000 -0.25000000\n0.45000000 1.05000000 -1.50000000\n0.45000000 1.05000000 -1.45000000\n0.45000000 1.05000000 -1.40000000\n0.45000000 1.05000000 -0.50000000\n0.45000000 1.05000000 -0.45000000\n0.45000000 1.05000000 -0.40000000\n0.45000000 1.10000000 -1.35000000\n0.45000000 1.10000000 -1.30000000\n0.45000000 1.10000000 -1.25000000\n0.45000000 1.10000000 -1.20000000\n0.45000000 1.10000000 -1.15000000\n0.45000000 1.10000000 -1.10000000\n0.45000000 1.10000000 -1.05000000\n0.45000000 1.10000000 -1.00000000\n0.45000000 1.10000000 -0.95000000\n0.45000000 1.10000000 -0.90000000\n0.45000000 1.10000000 -0.85000000\n0.45000000 1.10000000 -0.80000000\n0.45000000 1.10000000 -0.75000000\n0.45000000 1.10000000 -0.70000000\n0.45000000 1.10000000 -0.65000000\n0.45000000 1.10000000 -0.60000000\n0.45000000 1.10000000 -0.55000000\n0.50000000 0.10000000 1.70000000\n0.50000000 0.10000000 1.75000000\n0.50000000 0.10000000 1.80000000\n0.50000000 0.15000000 -0.70000000\n0.50000000 0.15000000 -0.65000000\n0.50000000 0.15000000 -0.60000000\n0.50000000 0.15000000 -0.55000000\n0.50000000 0.15000000 -0.50000000\n0.50000000 0.15000000 -0.45000000\n0.50000000 0.15000000 -0.40000000\n0.50000000 0.15000000 -0.35000000\n0.50000000 0.15000000 -0.30000000\n0.50000000 0.15000000 -0.25000000\n0.50000000 0.15000000 -0.20000000\n0.50000000 0.15000000 -0.15000000\n0.50000000 0.15000000 -0.10000000\n0.50000000 0.15000000 -0.05000000\n0.50000000 0.15000000 0.00000000\n0.50000000 0.15000000 0.05000000\n0.50000000 0.15000000 0.10000000\n0.50000000 0.15000000 0.15000000\n0.50000000 0.15000000 0.20000000\n0.50000000 0.15000000 0.25000000\n0.50000000 0.15000000 0.30000000\n0.50000000 0.15000000 0.35000000\n0.50000000 0.15000000 0.40000000\n0.50000000 0.15000000 0.45000000\n0.50000000 0.15000000 0.50000000\n0.50000000 0.15000000 0.55000000\n0.50000000 0.15000000 0.60000000\n0.50000000 0.15000000 0.65000000\n0.50000000 0.15000000 0.70000000\n0.50000000 0.15000000 0.75000000\n0.50000000 0.15000000 0.80000000\n0.50000000 0.15000000 1.55000000\n0.50000000 0.15000000 1.60000000\n0.50000000 0.15000000 1.65000000\n0.50000000 0.15000000 1.85000000\n0.50000000 0.15000000 1.90000000\n0.50000000 0.15000000 1.95000000\n0.50000000 0.20000000 -1.15000000\n0.50000000 0.20000000 -1.10000000\n0.50000000 0.20000000 -1.05000000\n0.50000000 0.20000000 -1.00000000\n0.50000000 0.20000000 -0.95000000\n0.50000000 0.20000000 -0.90000000\n0.50000000 0.20000000 -0.85000000\n0.50000000 0.20000000 -0.80000000\n0.50000000 0.20000000 -0.75000000\n0.50000000 0.20000000 0.85000000\n0.50000000 0.20000000 0.90000000\n0.50000000 0.20000000 0.95000000\n0.50000000 0.20000000 1.00000000\n0.50000000 0.20000000 1.50000000\n0.50000000 0.20000000 2.00000000\n0.50000000 0.25000000 -1.35000000\n0.50000000 0.25000000 -1.30000000\n0.50000000 0.25000000 -1.25000000\n0.50000000 0.25000000 -1.20000000\n0.50000000 0.25000000 1.05000000\n0.50000000 0.25000000 1.10000000\n0.50000000 0.25000000 1.15000000\n0.50000000 0.25000000 1.45000000\n0.50000000 0.25000000 2.05000000\n0.50000000 0.30000000 -1.50000000\n0.50000000 0.30000000 -1.45000000\n0.50000000 0.30000000 -1.40000000\n0.50000000 0.30000000 1.20000000\n0.50000000 0.30000000 1.45000000\n0.50000000 0.30000000 2.10000000\n0.50000000 0.35000000 -1.55000000\n0.50000000 0.35000000 1.25000000\n0.50000000 0.35000000 1.40000000\n0.50000000 0.35000000 2.10000000\n0.50000000 0.40000000 -1.65000000\n0.50000000 0.40000000 -1.60000000\n0.50000000 0.40000000 1.25000000\n0.50000000 0.40000000 1.40000000\n0.50000000 0.40000000 2.10000000\n0.50000000 0.45000000 -1.70000000\n0.50000000 0.45000000 1.25000000\n0.50000000 0.45000000 1.45000000\n0.50000000 0.45000000 2.05000000\n0.50000000 0.50000000 -1.75000000\n0.50000000 0.50000000 1.15000000\n0.50000000 0.50000000 1.20000000\n0.50000000 0.50000000 1.45000000\n0.50000000 0.50000000 2.05000000\n0.50000000 0.55000000 -1.80000000\n0.50000000 0.55000000 1.05000000\n0.50000000 0.55000000 1.10000000\n0.50000000 0.55000000 1.50000000\n0.50000000 0.55000000 1.55000000\n0.50000000 0.55000000 1.95000000\n0.50000000 0.55000000 2.00000000\n0.50000000 0.60000000 -1.80000000\n0.50000000 0.60000000 0.85000000\n0.50000000 0.60000000 0.90000000\n0.50000000 0.60000000 0.95000000\n0.50000000 0.60000000 1.00000000\n0.50000000 0.60000000 1.60000000\n0.50000000 0.60000000 1.65000000\n0.50000000 0.60000000 1.70000000\n0.50000000 0.60000000 1.75000000\n0.50000000 0.60000000 1.80000000\n0.50000000 0.60000000 1.85000000\n0.50000000 0.60000000 1.90000000\n0.50000000 0.65000000 -1.80000000\n0.50000000 0.65000000 0.65000000\n0.50000000 0.65000000 0.70000000\n0.50000000 0.65000000 0.75000000\n0.50000000 0.65000000 0.80000000\n0.50000000 0.70000000 -1.80000000\n0.50000000 0.70000000 0.30000000\n0.50000000 0.70000000 0.35000000\n0.50000000 0.70000000 0.40000000\n0.50000000 0.70000000 0.45000000\n0.50000000 0.70000000 0.50000000\n0.50000000 0.70000000 0.55000000\n0.50000000 0.70000000 0.60000000\n0.50000000 0.75000000 -1.80000000\n0.50000000 0.75000000 0.00000000\n0.50000000 0.75000000 0.05000000\n0.50000000 0.75000000 0.10000000\n0.50000000 0.75000000 0.15000000\n0.50000000 0.75000000 0.20000000\n0.50000000 0.75000000 0.25000000\n0.50000000 0.80000000 -1.80000000\n0.50000000 0.80000000 -0.05000000\n0.50000000 0.85000000 -1.75000000\n0.50000000 0.85000000 -0.10000000\n0.50000000 0.90000000 -1.70000000\n0.50000000 0.90000000 -0.15000000\n0.50000000 0.95000000 -1.65000000\n0.50000000 0.95000000 -0.25000000\n0.50000000 0.95000000 -0.20000000\n0.50000000 1.00000000 -1.60000000\n0.50000000 1.00000000 -1.55000000\n0.50000000 1.00000000 -1.50000000\n0.50000000 1.00000000 -0.40000000\n0.50000000 1.00000000 -0.35000000\n0.50000000 1.00000000 -0.30000000\n0.50000000 1.05000000 -1.45000000\n0.50000000 1.05000000 -1.40000000\n0.50000000 1.05000000 -1.35000000\n0.50000000 1.05000000 -0.55000000\n0.50000000 1.05000000 -0.50000000\n0.50000000 1.05000000 -0.45000000\n0.50000000 1.10000000 -1.30000000\n0.50000000 1.10000000 -1.25000000\n0.50000000 1.10000000 -1.20000000\n0.50000000 1.10000000 -1.15000000\n0.50000000 1.10000000 -1.10000000\n0.50000000 1.10000000 -1.05000000\n0.50000000 1.10000000 -1.00000000\n0.50000000 1.10000000 -0.95000000\n0.50000000 1.10000000 -0.90000000\n0.50000000 1.10000000 -0.85000000\n0.50000000 1.10000000 -0.80000000\n0.50000000 1.10000000 -0.75000000\n0.50000000 1.10000000 -0.70000000\n0.50000000 1.10000000 -0.65000000\n0.50000000 1.10000000 -0.60000000\n0.55000000 0.15000000 -0.60000000\n0.55000000 0.15000000 -0.55000000\n0.55000000 0.15000000 -0.50000000\n0.55000000 0.15000000 -0.45000000\n0.55000000 0.15000000 -0.40000000\n0.55000000 0.15000000 -0.35000000\n0.55000000 0.15000000 -0.30000000\n0.55000000 0.15000000 -0.25000000\n0.55000000 0.15000000 -0.20000000\n0.55000000 0.15000000 -0.15000000\n0.55000000 0.15000000 -0.10000000\n0.55000000 0.15000000 -0.05000000\n0.55000000 0.15000000 0.00000000\n0.55000000 0.15000000 0.05000000\n0.55000000 0.15000000 0.10000000\n0.55000000 0.15000000 0.15000000\n0.55000000 0.15000000 0.20000000\n0.55000000 0.15000000 0.25000000\n0.55000000 0.15000000 0.30000000\n0.55000000 0.15000000 0.35000000\n0.55000000 0.15000000 0.40000000\n0.55000000 0.15000000 0.45000000\n0.55000000 0.15000000 0.50000000\n0.55000000 0.15000000 0.55000000\n0.55000000 0.15000000 0.60000000\n0.55000000 0.15000000 0.65000000\n0.55000000 0.15000000 1.55000000\n0.55000000 0.15000000 1.60000000\n0.55000000 0.15000000 1.65000000\n0.55000000 0.15000000 1.70000000\n0.55000000 0.15000000 1.75000000\n0.55000000 0.15000000 1.80000000\n0.55000000 0.15000000 1.85000000\n0.55000000 0.15000000 1.90000000\n0.55000000 0.15000000 1.95000000\n0.55000000 0.20000000 -1.05000000\n0.55000000 0.20000000 -1.00000000\n0.55000000 0.20000000 -0.95000000\n0.55000000 0.20000000 -0.90000000\n0.55000000 0.20000000 -0.85000000\n0.55000000 0.20000000 -0.80000000\n0.55000000 0.20000000 -0.75000000\n0.55000000 0.20000000 -0.70000000\n0.55000000 0.20000000 -0.65000000\n0.55000000 0.20000000 0.70000000\n0.55000000 0.20000000 0.75000000\n0.55000000 0.20000000 0.80000000\n0.55000000 0.20000000 0.85000000\n0.55000000 0.20000000 0.90000000\n0.55000000 0.20000000 0.95000000\n0.55000000 0.20000000 1.50000000\n0.55000000 0.20000000 2.00000000\n0.55000000 0.25000000 -1.30000000\n0.55000000 0.25000000 -1.25000000\n0.55000000 0.25000000 -1.20000000\n0.55000000 0.25000000 -1.15000000\n0.55000000 0.25000000 -1.10000000\n0.55000000 0.25000000 1.00000000\n0.55000000 0.25000000 1.05000000\n0.55000000 0.25000000 1.10000000\n0.55000000 0.25000000 1.45000000\n0.55000000 0.25000000 2.05000000\n0.55000000 0.30000000 -1.45000000\n0.55000000 0.30000000 -1.40000000\n0.55000000 0.30000000 -1.35000000\n0.55000000 0.30000000 1.15000000\n0.55000000 0.30000000 1.45000000\n0.55000000 0.30000000 2.05000000\n0.55000000 0.35000000 -1.55000000\n0.55000000 0.35000000 -1.50000000\n0.55000000 0.35000000 1.20000000\n0.55000000 0.35000000 1.45000000\n0.55000000 0.35000000 2.05000000\n0.55000000 0.40000000 -1.60000000\n0.55000000 0.40000000 1.20000000\n0.55000000 0.40000000 1.45000000\n0.55000000 0.40000000 2.05000000\n0.55000000 0.45000000 -1.65000000\n0.55000000 0.45000000 1.15000000\n0.55000000 0.45000000 1.20000000\n0.55000000 0.45000000 1.45000000\n0.55000000 0.45000000 2.05000000\n0.55000000 0.50000000 -1.70000000\n0.55000000 0.50000000 1.10000000\n0.55000000 0.50000000 1.15000000\n0.55000000 0.50000000 1.50000000\n0.55000000 0.50000000 2.05000000\n0.55000000 0.55000000 -1.75000000\n0.55000000 0.55000000 0.95000000\n0.55000000 0.55000000 1.00000000\n0.55000000 0.55000000 1.05000000\n0.55000000 0.55000000 1.55000000\n0.55000000 0.55000000 1.60000000\n0.55000000 0.55000000 1.95000000\n0.55000000 0.55000000 2.00000000\n0.55000000 0.60000000 -1.75000000\n0.55000000 0.60000000 0.80000000\n0.55000000 0.60000000 0.85000000\n0.55000000 0.60000000 0.90000000\n0.55000000 0.60000000 1.65000000\n0.55000000 0.60000000 1.70000000\n0.55000000 0.60000000 1.75000000\n0.55000000 0.60000000 1.80000000\n0.55000000 0.60000000 1.85000000\n0.55000000 0.60000000 1.90000000\n0.55000000 0.65000000 -1.80000000\n0.55000000 0.65000000 0.55000000\n0.55000000 0.65000000 0.60000000\n0.55000000 0.65000000 0.65000000\n0.55000000 0.65000000 0.70000000\n0.55000000 0.65000000 0.75000000\n0.55000000 0.70000000 -1.80000000\n0.55000000 0.70000000 0.20000000\n0.55000000 0.70000000 0.25000000\n0.55000000 0.70000000 0.30000000\n0.55000000 0.70000000 0.35000000\n0.55000000 0.70000000 0.40000000\n0.55000000 0.70000000 0.45000000\n0.55000000 0.70000000 0.50000000\n0.55000000 0.75000000 -1.80000000\n0.55000000 0.75000000 0.00000000\n0.55000000 0.75000000 0.05000000\n0.55000000 0.75000000 0.10000000\n0.55000000 0.75000000 0.15000000\n0.55000000 0.80000000 -1.75000000\n0.55000000 0.80000000 -0.05000000\n0.55000000 0.85000000 -1.75000000\n0.55000000 0.85000000 -0.10000000\n0.55000000 0.90000000 -1.70000000\n0.55000000 0.90000000 -1.65000000\n0.55000000 0.90000000 -0.20000000\n0.55000000 0.90000000 -0.15000000\n0.55000000 0.95000000 -1.60000000\n0.55000000 0.95000000 -0.30000000\n0.55000000 0.95000000 -0.25000000\n0.55000000 1.00000000 -1.55000000\n0.55000000 1.00000000 -1.50000000\n0.55000000 1.00000000 -1.45000000\n0.55000000 1.00000000 -0.45000000\n0.55000000 1.00000000 -0.40000000\n0.55000000 1.00000000 -0.35000000\n0.55000000 1.05000000 -1.40000000\n0.55000000 1.05000000 -1.35000000\n0.55000000 1.05000000 -1.30000000\n0.55000000 1.05000000 -1.25000000\n0.55000000 1.05000000 -0.65000000\n0.55000000 1.05000000 -0.60000000\n0.55000000 1.05000000 -0.55000000\n0.55000000 1.05000000 -0.50000000\n0.55000000 1.10000000 -1.20000000\n0.55000000 1.10000000 -1.15000000\n0.55000000 1.10000000 -1.10000000\n0.55000000 1.10000000 -1.05000000\n0.55000000 1.10000000 -1.00000000\n0.55000000 1.10000000 -0.95000000\n0.55000000 1.10000000 -0.90000000\n0.55000000 1.10000000 -0.85000000\n0.55000000 1.10000000 -0.80000000\n0.55000000 1.10000000 -0.75000000\n0.55000000 1.10000000 -0.70000000\n0.60000000 0.15000000 -0.45000000\n0.60000000 0.15000000 -0.40000000\n0.60000000 0.15000000 -0.35000000\n0.60000000 0.15000000 -0.30000000\n0.60000000 0.15000000 -0.25000000\n0.60000000 0.15000000 -0.20000000\n0.60000000 0.15000000 -0.15000000\n0.60000000 0.15000000 -0.10000000\n0.60000000 0.15000000 -0.05000000\n0.60000000 0.15000000 0.00000000\n0.60000000 0.15000000 0.05000000\n0.60000000 0.15000000 0.10000000\n0.60000000 0.15000000 0.15000000\n0.60000000 0.15000000 0.20000000\n0.60000000 0.15000000 0.25000000\n0.60000000 0.15000000 0.30000000\n0.60000000 0.15000000 0.35000000\n0.60000000 0.15000000 0.40000000\n0.60000000 0.15000000 0.45000000\n0.60000000 0.15000000 0.50000000\n0.60000000 0.15000000 0.55000000\n0.60000000 0.15000000 1.60000000\n0.60000000 0.15000000 1.65000000\n0.60000000 0.15000000 1.70000000\n0.60000000 0.15000000 1.75000000\n0.60000000 0.15000000 1.80000000\n0.60000000 0.15000000 1.85000000\n0.60000000 0.15000000 1.90000000\n0.60000000 0.20000000 -0.85000000\n0.60000000 0.20000000 -0.80000000\n0.60000000 0.20000000 -0.75000000\n0.60000000 0.20000000 -0.70000000\n0.60000000 0.20000000 -0.65000000\n0.60000000 0.20000000 -0.60000000\n0.60000000 0.20000000 -0.55000000\n0.60000000 0.20000000 -0.50000000\n0.60000000 0.20000000 0.60000000\n0.60000000 0.20000000 0.65000000\n0.60000000 0.20000000 0.70000000\n0.60000000 0.20000000 0.75000000\n0.60000000 0.20000000 0.80000000\n0.60000000 0.20000000 0.85000000\n0.60000000 0.20000000 1.50000000\n0.60000000 0.20000000 1.55000000\n0.60000000 0.20000000 1.95000000\n0.60000000 0.20000000 2.00000000\n0.60000000 0.25000000 -1.20000000\n0.60000000 0.25000000 -1.15000000\n0.60000000 0.25000000 -1.10000000\n0.60000000 0.25000000 -1.05000000\n0.60000000 0.25000000 -1.00000000\n0.60000000 0.25000000 -0.95000000\n0.60000000 0.25000000 -0.90000000\n0.60000000 0.25000000 0.90000000\n0.60000000 0.25000000 0.95000000\n0.60000000 0.25000000 1.00000000\n0.60000000 0.25000000 1.50000000\n0.60000000 0.25000000 2.05000000\n0.60000000 0.30000000 -1.40000000\n0.60000000 0.30000000 -1.35000000\n0.60000000 0.30000000 -1.30000000\n0.60000000 0.30000000 -1.25000000\n0.60000000 0.30000000 1.05000000\n0.60000000 0.30000000 1.10000000\n0.60000000 0.30000000 1.45000000\n0.60000000 0.30000000 2.05000000\n0.60000000 0.35000000 -1.50000000\n0.60000000 0.35000000 -1.45000000\n0.60000000 0.35000000 1.10000000\n0.60000000 0.35000000 1.15000000\n0.60000000 0.35000000 1.45000000\n0.60000000 0.35000000 2.05000000\n0.60000000 0.40000000 -1.60000000\n0.60000000 0.40000000 -1.55000000\n0.60000000 0.40000000 1.10000000\n0.60000000 0.40000000 1.15000000\n0.60000000 0.40000000 1.45000000\n0.60000000 0.40000000 2.05000000\n0.60000000 0.45000000 -1.65000000\n0.60000000 0.45000000 1.10000000\n0.60000000 0.45000000 1.45000000\n0.60000000 0.45000000 2.05000000\n0.60000000 0.50000000 -1.70000000\n0.60000000 0.50000000 1.05000000\n0.60000000 0.50000000 1.10000000\n0.60000000 0.50000000 1.50000000\n0.60000000 0.50000000 2.00000000\n0.60000000 0.55000000 -1.70000000\n0.60000000 0.55000000 0.90000000\n0.60000000 0.55000000 0.95000000\n0.60000000 0.55000000 1.00000000\n0.60000000 0.55000000 1.55000000\n0.60000000 0.55000000 1.60000000\n0.60000000 0.55000000 1.65000000\n0.60000000 0.55000000 1.90000000\n0.60000000 0.55000000 1.95000000\n0.60000000 0.60000000 -1.75000000\n0.60000000 0.60000000 0.75000000\n0.60000000 0.60000000 0.80000000\n0.60000000 0.60000000 0.85000000\n0.60000000 0.60000000 1.70000000\n0.60000000 0.60000000 1.75000000\n0.60000000 0.60000000 1.80000000\n0.60000000 0.60000000 1.85000000\n0.60000000 0.65000000 -1.75000000\n0.60000000 0.65000000 0.50000000\n0.60000000 0.65000000 0.55000000\n0.60000000 0.65000000 0.60000000\n0.60000000 0.65000000 0.65000000\n0.60000000 0.65000000 0.70000000\n0.60000000 0.70000000 -1.75000000\n0.60000000 0.70000000 0.05000000\n0.60000000 0.70000000 0.10000000\n0.60000000 0.70000000 0.15000000\n0.60000000 0.70000000 0.20000000\n0.60000000 0.70000000 0.25000000\n0.60000000 0.70000000 0.30000000\n0.60000000 0.70000000 0.35000000\n0.60000000 0.70000000 0.40000000\n0.60000000 0.70000000 0.45000000\n0.60000000 0.75000000 -1.75000000\n0.60000000 0.75000000 -0.05000000\n0.60000000 0.75000000 0.00000000\n0.60000000 0.80000000 -1.75000000\n0.60000000 0.80000000 -0.10000000\n0.60000000 0.85000000 -1.70000000\n0.60000000 0.85000000 -0.15000000\n0.60000000 0.90000000 -1.65000000\n0.60000000 0.90000000 -0.25000000\n0.60000000 0.90000000 -0.20000000\n0.60000000 0.95000000 -1.60000000\n0.60000000 0.95000000 -1.55000000\n0.60000000 0.95000000 -0.35000000\n0.60000000 0.95000000 -0.30000000\n0.60000000 1.00000000 -1.50000000\n0.60000000 1.00000000 -1.45000000\n0.60000000 1.00000000 -1.40000000\n0.60000000 1.00000000 -0.50000000\n0.60000000 1.00000000 -0.45000000\n0.60000000 1.00000000 -0.40000000\n0.60000000 1.05000000 -1.35000000\n0.60000000 1.05000000 -1.30000000\n0.60000000 1.05000000 -1.25000000\n0.60000000 1.05000000 -1.20000000\n0.60000000 1.05000000 -1.15000000\n0.60000000 1.05000000 -1.10000000\n0.60000000 1.05000000 -0.85000000\n0.60000000 1.05000000 -0.80000000\n0.60000000 1.05000000 -0.75000000\n0.60000000 1.05000000 -0.70000000\n0.60000000 1.05000000 -0.65000000\n0.60000000 1.05000000 -0.60000000\n0.60000000 1.05000000 -0.55000000\n0.60000000 1.10000000 -1.05000000\n0.60000000 1.10000000 -1.00000000\n0.60000000 1.10000000 -0.95000000\n0.60000000 1.10000000 -0.90000000\n0.65000000 0.15000000 -0.25000000\n0.65000000 0.15000000 -0.20000000\n0.65000000 0.15000000 -0.15000000\n0.65000000 0.15000000 -0.10000000\n0.65000000 0.15000000 -0.05000000\n0.65000000 0.15000000 0.00000000\n0.65000000 0.15000000 0.05000000\n0.65000000 0.15000000 0.10000000\n0.65000000 0.15000000 0.15000000\n0.65000000 0.15000000 0.20000000\n0.65000000 0.15000000 0.25000000\n0.65000000 0.15000000 0.30000000\n0.65000000 0.15000000 0.35000000\n0.65000000 0.15000000 1.65000000\n0.65000000 0.15000000 1.70000000\n0.65000000 0.15000000 1.75000000\n0.65000000 0.15000000 1.80000000\n0.65000000 0.15000000 1.85000000\n0.65000000 0.20000000 -0.75000000\n0.65000000 0.20000000 -0.70000000\n0.65000000 0.20000000 -0.65000000\n0.65000000 0.20000000 -0.60000000\n0.65000000 0.20000000 -0.55000000\n0.65000000 0.20000000 -0.50000000\n0.65000000 0.20000000 -0.45000000\n0.65000000 0.20000000 -0.40000000\n0.65000000 0.20000000 -0.35000000\n0.65000000 0.20000000 -0.30000000\n0.65000000 0.20000000 0.40000000\n0.65000000 0.20000000 0.45000000\n0.65000000 0.20000000 0.50000000\n0.65000000 0.20000000 0.55000000\n0.65000000 0.20000000 0.60000000\n0.65000000 0.20000000 0.65000000\n0.65000000 0.20000000 0.70000000\n0.65000000 0.20000000 0.75000000\n0.65000000 0.20000000 1.55000000\n0.65000000 0.20000000 1.60000000\n0.65000000 0.20000000 1.90000000\n0.65000000 0.20000000 1.95000000\n0.65000000 0.25000000 -1.10000000\n0.65000000 0.25000000 -1.05000000\n0.65000000 0.25000000 -1.00000000\n0.65000000 0.25000000 -0.95000000\n0.65000000 0.25000000 -0.90000000\n0.65000000 0.25000000 -0.85000000\n0.65000000 0.25000000 -0.80000000\n0.65000000 0.25000000 0.80000000\n0.65000000 0.25000000 0.85000000\n0.65000000 0.25000000 0.90000000\n0.65000000 0.25000000 1.50000000\n0.65000000 0.25000000 2.00000000\n0.65000000 0.30000000 -1.35000000\n0.65000000 0.30000000 -1.30000000\n0.65000000 0.30000000 -1.25000000\n0.65000000 0.30000000 -1.20000000\n0.65000000 0.30000000 -1.15000000\n0.65000000 0.30000000 0.95000000\n0.65000000 0.30000000 1.00000000\n0.65000000 0.30000000 1.05000000\n0.65000000 0.30000000 1.50000000\n0.65000000 0.30000000 2.05000000\n0.65000000 0.35000000 -1.45000000\n0.65000000 0.35000000 -1.40000000\n0.65000000 0.35000000 1.05000000\n0.65000000 0.35000000 1.45000000\n0.65000000 0.35000000 2.05000000\n0.65000000 0.40000000 -1.55000000\n0.65000000 0.40000000 -1.50000000\n0.65000000 0.40000000 1.05000000\n0.65000000 0.40000000 1.45000000\n0.65000000 0.40000000 2.05000000\n0.65000000 0.45000000 -1.60000000\n0.65000000 0.45000000 1.05000000\n0.65000000 0.45000000 1.50000000\n0.65000000 0.45000000 2.00000000\n0.65000000 0.50000000 -1.65000000\n0.65000000 0.50000000 0.95000000\n0.65000000 0.50000000 1.00000000\n0.65000000 0.50000000 1.55000000\n0.65000000 0.50000000 1.95000000\n0.65000000 0.50000000 2.00000000\n0.65000000 0.55000000 -1.70000000\n0.65000000 0.55000000 0.85000000\n0.65000000 0.55000000 0.90000000\n0.65000000 0.55000000 1.60000000\n0.65000000 0.55000000 1.65000000\n0.65000000 0.55000000 1.70000000\n0.65000000 0.55000000 1.75000000\n0.65000000 0.55000000 1.80000000\n0.65000000 0.55000000 1.85000000\n0.65000000 0.55000000 1.90000000\n0.65000000 0.60000000 -1.70000000\n0.65000000 0.60000000 0.65000000\n0.65000000 0.60000000 0.70000000\n0.65000000 0.60000000 0.75000000\n0.65000000 0.60000000 0.80000000\n0.65000000 0.65000000 -1.70000000\n0.65000000 0.65000000 0.40000000\n0.65000000 0.65000000 0.45000000\n0.65000000 0.65000000 0.50000000\n0.65000000 0.65000000 0.55000000\n0.65000000 0.65000000 0.60000000\n0.65000000 0.70000000 -1.70000000\n0.65000000 0.70000000 -0.05000000\n0.65000000 0.70000000 0.00000000\n0.65000000 0.70000000 0.05000000\n0.65000000 0.70000000 0.10000000\n0.65000000 0.70000000 0.15000000\n0.65000000 0.70000000 0.20000000\n0.65000000 0.70000000 0.25000000\n0.65000000 0.70000000 0.30000000\n0.65000000 0.70000000 0.35000000\n0.65000000 0.75000000 -1.70000000\n0.65000000 0.75000000 -0.10000000\n0.65000000 0.80000000 -1.70000000\n0.65000000 0.80000000 -0.15000000\n0.65000000 0.85000000 -1.65000000\n0.65000000 0.85000000 -0.20000000\n0.65000000 0.90000000 -1.60000000\n0.65000000 0.90000000 -0.30000000\n0.65000000 0.90000000 -0.25000000\n0.65000000 0.95000000 -1.55000000\n0.65000000 0.95000000 -1.50000000\n0.65000000 0.95000000 -1.45000000\n0.65000000 0.95000000 -0.40000000\n0.65000000 0.95000000 -0.35000000\n0.65000000 1.00000000 -1.40000000\n0.65000000 1.00000000 -1.35000000\n0.65000000 1.00000000 -1.30000000\n0.65000000 1.00000000 -0.60000000\n0.65000000 1.00000000 -0.55000000\n0.65000000 1.00000000 -0.50000000\n0.65000000 1.00000000 -0.45000000\n0.65000000 1.05000000 -1.25000000\n0.65000000 1.05000000 -1.20000000\n0.65000000 1.05000000 -1.15000000\n0.65000000 1.05000000 -1.10000000\n0.65000000 1.05000000 -1.05000000\n0.65000000 1.05000000 -1.00000000\n0.65000000 1.05000000 -0.95000000\n0.65000000 1.05000000 -0.90000000\n0.65000000 1.05000000 -0.85000000\n0.65000000 1.05000000 -0.80000000\n0.65000000 1.05000000 -0.75000000\n0.65000000 1.05000000 -0.70000000\n0.65000000 1.05000000 -0.65000000\n0.70000000 0.10000000 1.75000000\n0.70000000 0.10000000 1.80000000\n0.70000000 0.15000000 1.65000000\n0.70000000 0.15000000 1.70000000\n0.70000000 0.15000000 1.85000000\n0.70000000 0.15000000 1.90000000\n0.70000000 0.20000000 -1.30000000\n0.70000000 0.20000000 -1.25000000\n0.70000000 0.20000000 -1.20000000\n0.70000000 0.20000000 -1.15000000\n0.70000000 0.20000000 -1.10000000\n0.70000000 0.20000000 -0.60000000\n0.70000000 0.20000000 -0.55000000\n0.70000000 0.20000000 -0.50000000\n0.70000000 0.20000000 -0.45000000\n0.70000000 0.20000000 -0.40000000\n0.70000000 0.20000000 -0.35000000\n0.70000000 0.20000000 -0.30000000\n0.70000000 0.20000000 -0.25000000\n0.70000000 0.20000000 -0.20000000\n0.70000000 0.20000000 -0.15000000\n0.70000000 0.20000000 -0.10000000\n0.70000000 0.20000000 -0.05000000\n0.70000000 0.20000000 0.00000000\n0.70000000 0.20000000 0.05000000\n0.70000000 0.20000000 0.10000000\n0.70000000 0.20000000 0.15000000\n0.70000000 0.20000000 0.20000000\n0.70000000 0.20000000 0.25000000\n0.70000000 0.20000000 0.30000000\n0.70000000 0.20000000 0.35000000\n0.70000000 0.20000000 0.40000000\n0.70000000 0.20000000 0.45000000\n0.70000000 0.20000000 0.50000000\n0.70000000 0.20000000 0.55000000\n0.70000000 0.20000000 0.60000000\n0.70000000 0.20000000 1.60000000\n0.70000000 0.20000000 1.95000000\n0.70000000 0.25000000 -1.35000000\n0.70000000 0.25000000 -1.30000000\n0.70000000 0.25000000 -1.25000000\n0.70000000 0.25000000 -1.20000000\n0.70000000 0.25000000 -1.15000000\n0.70000000 0.25000000 -1.05000000\n0.70000000 0.25000000 -1.00000000\n0.70000000 0.25000000 -0.95000000\n0.70000000 0.25000000 -0.90000000\n0.70000000 0.25000000 -0.85000000\n0.70000000 0.25000000 -0.80000000\n0.70000000 0.25000000 -0.75000000\n0.70000000 0.25000000 -0.70000000\n0.70000000 0.25000000 -0.65000000\n0.70000000 0.25000000 0.65000000\n0.70000000 0.25000000 0.70000000\n0.70000000 0.25000000 0.75000000\n0.70000000 0.25000000 0.80000000\n0.70000000 0.25000000 0.85000000\n0.70000000 0.25000000 1.55000000\n0.70000000 0.25000000 2.00000000\n0.70000000 0.30000000 -1.35000000\n0.70000000 0.30000000 0.90000000\n0.70000000 0.30000000 0.95000000\n0.70000000 0.30000000 1.50000000\n0.70000000 0.30000000 2.00000000\n0.70000000 0.35000000 -1.35000000\n0.70000000 0.35000000 0.95000000\n0.70000000 0.35000000 1.00000000\n0.70000000 0.35000000 1.50000000\n0.70000000 0.35000000 2.00000000\n0.70000000 0.40000000 -1.50000000\n0.70000000 0.40000000 -1.45000000\n0.70000000 0.40000000 -1.40000000\n0.70000000 0.40000000 0.95000000\n0.70000000 0.40000000 1.00000000\n0.70000000 0.40000000 1.50000000\n0.70000000 0.40000000 2.00000000\n0.70000000 0.45000000 -1.55000000\n0.70000000 0.45000000 0.95000000\n0.70000000 0.45000000 1.00000000\n0.70000000 0.45000000 1.50000000\n0.70000000 0.45000000 2.00000000\n0.70000000 0.50000000 -1.60000000\n0.70000000 0.50000000 0.90000000\n0.70000000 0.50000000 1.55000000\n0.70000000 0.50000000 1.60000000\n0.70000000 0.50000000 1.95000000\n0.70000000 0.55000000 -1.65000000\n0.70000000 0.55000000 0.75000000\n0.70000000 0.55000000 0.80000000\n0.70000000 0.55000000 0.85000000\n0.70000000 0.55000000 1.65000000\n0.70000000 0.55000000 1.70000000\n0.70000000 0.55000000 1.85000000\n0.70000000 0.55000000 1.90000000\n0.70000000 0.60000000 -1.65000000\n0.70000000 0.60000000 0.55000000\n0.70000000 0.60000000 0.60000000\n0.70000000 0.60000000 0.65000000\n0.70000000 0.60000000 0.70000000\n0.70000000 0.60000000 1.75000000\n0.70000000 0.60000000 1.80000000\n0.70000000 0.65000000 -1.65000000\n0.70000000 0.65000000 0.25000000\n0.70000000 0.65000000 0.30000000\n0.70000000 0.65000000 0.35000000\n0.70000000 0.65000000 0.40000000\n0.70000000 0.65000000 0.45000000\n0.70000000 0.65000000 0.50000000\n0.70000000 0.70000000 -1.65000000\n0.70000000 0.70000000 -0.10000000\n0.70000000 0.70000000 -0.05000000\n0.70000000 0.70000000 0.00000000\n0.70000000 0.70000000 0.05000000\n0.70000000 0.70000000 0.10000000\n0.70000000 0.70000000 0.15000000\n0.70000000 0.70000000 0.20000000\n0.70000000 0.75000000 -1.65000000\n0.70000000 0.75000000 -0.15000000\n0.70000000 0.80000000 -1.65000000\n0.70000000 0.80000000 -0.20000000\n0.70000000 0.85000000 -1.60000000\n0.70000000 0.85000000 -0.25000000\n0.70000000 0.90000000 -1.55000000\n0.70000000 0.90000000 -1.50000000\n0.70000000 0.90000000 -0.35000000\n0.70000000 0.90000000 -0.30000000\n0.70000000 0.95000000 -1.45000000\n0.70000000 0.95000000 -1.40000000\n0.70000000 0.95000000 -0.50000000\n0.70000000 0.95000000 -0.45000000\n0.70000000 0.95000000 -0.40000000\n0.70000000 1.00000000 -1.35000000\n0.70000000 1.00000000 -1.30000000\n0.70000000 1.00000000 -1.25000000\n0.70000000 1.00000000 -1.20000000\n0.70000000 1.00000000 -0.75000000\n0.70000000 1.00000000 -0.70000000\n0.70000000 1.00000000 -0.65000000\n0.70000000 1.00000000 -0.60000000\n0.70000000 1.00000000 -0.55000000\n0.70000000 1.05000000 -1.15000000\n0.70000000 1.05000000 -1.10000000\n0.70000000 1.05000000 -1.05000000\n0.70000000 1.05000000 -1.00000000\n0.70000000 1.05000000 -0.95000000\n0.70000000 1.05000000 -0.90000000\n0.70000000 1.05000000 -0.85000000\n0.70000000 1.05000000 -0.80000000\n0.75000000 0.05000000 -1.30000000\n0.75000000 0.05000000 -1.25000000\n0.75000000 0.05000000 -1.20000000\n0.75000000 0.05000000 -1.15000000\n0.75000000 0.05000000 1.65000000\n0.75000000 0.05000000 1.70000000\n0.75000000 0.05000000 1.75000000\n0.75000000 0.05000000 1.80000000\n0.75000000 0.05000000 1.85000000\n0.75000000 0.05000000 1.90000000\n0.75000000 0.10000000 -1.35000000\n0.75000000 0.10000000 -1.30000000\n0.75000000 0.10000000 -1.25000000\n0.75000000 0.10000000 -1.20000000\n0.75000000 0.10000000 -1.15000000\n0.75000000 0.10000000 -1.10000000\n0.75000000 0.10000000 -1.05000000\n0.75000000 0.10000000 1.55000000\n0.75000000 0.10000000 1.60000000\n0.75000000 0.10000000 1.65000000\n0.75000000 0.10000000 1.70000000\n0.75000000 0.10000000 1.85000000\n0.75000000 0.10000000 1.90000000\n0.75000000 0.10000000 1.95000000\n0.75000000 0.10000000 2.00000000\n0.75000000 0.15000000 -1.40000000\n0.75000000 0.15000000 -1.35000000\n0.75000000 0.15000000 -1.30000000\n0.75000000 0.15000000 -1.25000000\n0.75000000 0.15000000 -1.20000000\n0.75000000 0.15000000 -1.15000000\n0.75000000 0.15000000 -1.10000000\n0.75000000 0.15000000 -1.05000000\n0.75000000 0.15000000 -1.00000000\n0.75000000 0.15000000 1.55000000\n0.75000000 0.15000000 1.60000000\n0.75000000 0.15000000 1.95000000\n0.75000000 0.15000000 2.00000000\n0.75000000 0.15000000 2.05000000\n0.75000000 0.20000000 -1.45000000\n0.75000000 0.20000000 -1.40000000\n0.75000000 0.20000000 -1.35000000\n0.75000000 0.20000000 -1.05000000\n0.75000000 0.20000000 -1.00000000\n0.75000000 0.20000000 -0.95000000\n0.75000000 0.20000000 -0.45000000\n0.75000000 0.20000000 -0.40000000\n0.75000000 0.20000000 -0.35000000\n0.75000000 0.20000000 -0.30000000\n0.75000000 0.20000000 -0.25000000\n0.75000000 0.20000000 -0.20000000\n0.75000000 0.20000000 -0.15000000\n0.75000000 0.20000000 -0.10000000\n0.75000000 0.20000000 -0.05000000\n0.75000000 0.20000000 0.00000000\n0.75000000 0.20000000 0.05000000\n0.75000000 0.20000000 0.10000000\n0.75000000 0.20000000 0.15000000\n0.75000000 0.20000000 0.20000000\n0.75000000 0.20000000 0.25000000\n0.75000000 0.20000000 0.30000000\n0.75000000 0.20000000 0.35000000\n0.75000000 0.20000000 0.40000000\n0.75000000 0.20000000 0.45000000\n0.75000000 0.20000000 1.50000000\n0.75000000 0.20000000 1.55000000\n0.75000000 0.20000000 2.00000000\n0.75000000 0.20000000 2.05000000\n0.75000000 0.25000000 -1.50000000\n0.75000000 0.25000000 -1.45000000\n0.75000000 0.25000000 -1.40000000\n0.75000000 0.25000000 -0.95000000\n0.75000000 0.25000000 -0.80000000\n0.75000000 0.25000000 -0.75000000\n0.75000000 0.25000000 -0.70000000\n0.75000000 0.25000000 -0.65000000\n0.75000000 0.25000000 -0.60000000\n0.75000000 0.25000000 -0.55000000\n0.75000000 0.25000000 -0.50000000\n0.75000000 0.25000000 0.50000000\n0.75000000 0.25000000 0.55000000\n0.75000000 0.25000000 0.60000000\n0.75000000 0.25000000 0.65000000\n0.75000000 0.25000000 0.70000000\n0.75000000 0.25000000 1.50000000\n0.75000000 0.25000000 2.05000000\n0.75000000 0.25000000 2.10000000\n0.75000000 0.30000000 -1.50000000\n0.75000000 0.30000000 -1.45000000\n0.75000000 0.30000000 -1.40000000\n0.75000000 0.30000000 -0.90000000\n0.75000000 0.30000000 -0.85000000\n0.75000000 0.30000000 0.75000000\n0.75000000 0.30000000 0.80000000\n0.75000000 0.30000000 0.85000000\n0.75000000 0.30000000 1.45000000\n0.75000000 0.30000000 2.05000000\n0.75000000 0.30000000 2.10000000\n0.75000000 0.35000000 -1.50000000\n0.75000000 0.35000000 -1.45000000\n0.75000000 0.35000000 -1.40000000\n0.75000000 0.35000000 0.85000000\n0.75000000 0.35000000 0.90000000\n0.75000000 0.35000000 1.45000000\n0.75000000 0.35000000 2.05000000\n0.75000000 0.35000000 2.10000000\n0.75000000 0.40000000 -1.50000000\n0.75000000 0.40000000 0.85000000\n0.75000000 0.40000000 0.90000000\n0.75000000 0.40000000 1.45000000\n0.75000000 0.40000000 2.05000000\n0.75000000 0.40000000 2.10000000\n0.75000000 0.45000000 -1.50000000\n0.75000000 0.45000000 0.85000000\n0.75000000 0.45000000 0.90000000\n0.75000000 0.45000000 1.50000000\n0.75000000 0.45000000 2.05000000\n0.75000000 0.45000000 2.10000000\n0.75000000 0.50000000 -1.55000000\n0.75000000 0.50000000 0.80000000\n0.75000000 0.50000000 0.85000000\n0.75000000 0.50000000 1.50000000\n0.75000000 0.50000000 2.00000000\n0.75000000 0.50000000 2.05000000\n0.75000000 0.55000000 -1.60000000\n0.75000000 0.55000000 0.65000000\n0.75000000 0.55000000 0.70000000\n0.75000000 0.55000000 0.75000000\n0.75000000 0.55000000 1.50000000\n0.75000000 0.55000000 1.55000000\n0.75000000 0.55000000 1.60000000\n0.75000000 0.55000000 1.95000000\n0.75000000 0.55000000 2.00000000\n0.75000000 0.55000000 2.05000000\n0.75000000 0.60000000 -1.60000000\n0.75000000 0.60000000 0.45000000\n0.75000000 0.60000000 0.50000000\n0.75000000 0.60000000 0.55000000\n0.75000000 0.60000000 0.60000000\n0.75000000 0.60000000 1.55000000\n0.75000000 0.60000000 1.60000000\n0.75000000 0.60000000 1.65000000\n0.75000000 0.60000000 1.70000000\n0.75000000 0.60000000 1.85000000\n0.75000000 0.60000000 1.90000000\n0.75000000 0.60000000 1.95000000\n0.75000000 0.60000000 2.00000000\n0.75000000 0.65000000 -1.60000000\n0.75000000 0.65000000 0.05000000\n0.75000000 0.65000000 0.10000000\n0.75000000 0.65000000 0.15000000\n0.75000000 0.65000000 0.20000000\n0.75000000 0.65000000 0.25000000\n0.75000000 0.65000000 0.30000000\n0.75000000 0.65000000 0.35000000\n0.75000000 0.65000000 0.40000000\n0.75000000 0.65000000 1.65000000\n0.75000000 0.65000000 1.70000000\n0.75000000 0.65000000 1.75000000\n0.75000000 0.65000000 1.80000000\n0.75000000 0.65000000 1.85000000\n0.75000000 0.65000000 1.90000000\n0.75000000 0.65000000 1.95000000\n0.75000000 0.70000000 -1.60000000\n0.75000000 0.70000000 -0.20000000\n0.75000000 0.70000000 -0.15000000\n0.75000000 0.70000000 -0.10000000\n0.75000000 0.70000000 -0.05000000\n0.75000000 0.70000000 0.00000000\n0.75000000 0.75000000 -1.60000000\n0.75000000 0.75000000 -0.20000000\n0.75000000 0.80000000 -1.60000000\n0.75000000 0.80000000 -0.25000000\n0.75000000 0.85000000 -1.55000000\n0.75000000 0.85000000 -0.35000000\n0.75000000 0.85000000 -0.30000000\n0.75000000 0.90000000 -1.50000000\n0.75000000 0.90000000 -1.45000000\n0.75000000 0.90000000 -0.45000000\n0.75000000 0.90000000 -0.40000000\n0.75000000 0.95000000 -1.40000000\n0.75000000 0.95000000 -1.35000000\n0.75000000 0.95000000 -1.30000000\n0.75000000 0.95000000 -0.60000000\n0.75000000 0.95000000 -0.55000000\n0.75000000 0.95000000 -0.50000000\n0.75000000 1.00000000 -1.25000000\n0.75000000 1.00000000 -1.20000000\n0.75000000 1.00000000 -1.15000000\n0.75000000 1.00000000 -1.10000000\n0.75000000 1.00000000 -1.05000000\n0.75000000 1.00000000 -1.00000000\n0.75000000 1.00000000 -0.95000000\n0.75000000 1.00000000 -0.90000000\n0.75000000 1.00000000 -0.85000000\n0.75000000 1.00000000 -0.80000000\n0.75000000 1.00000000 -0.75000000\n0.75000000 1.00000000 -0.70000000\n0.75000000 1.00000000 -0.65000000\n0.80000000 0.00000000 -1.30000000\n0.80000000 0.00000000 -1.25000000\n0.80000000 0.00000000 -1.20000000\n0.80000000 0.00000000 -1.15000000\n0.80000000 0.00000000 1.65000000\n0.80000000 0.00000000 1.70000000\n0.80000000 0.00000000 1.75000000\n0.80000000 0.00000000 1.80000000\n0.80000000 0.00000000 1.85000000\n0.80000000 0.00000000 1.90000000\n0.80000000 0.05000000 -1.40000000\n0.80000000 0.05000000 -1.35000000\n0.80000000 0.05000000 -1.10000000\n0.80000000 0.05000000 -1.05000000\n0.80000000 0.05000000 -1.00000000\n0.80000000 0.05000000 1.55000000\n0.80000000 0.05000000 1.60000000\n0.80000000 0.05000000 1.95000000\n0.80000000 0.05000000 2.00000000\n0.80000000 0.10000000 -1.45000000\n0.80000000 0.10000000 -1.40000000\n0.80000000 0.10000000 -1.00000000\n0.80000000 0.10000000 -0.95000000\n0.80000000 0.10000000 1.50000000\n0.80000000 0.10000000 2.05000000\n0.80000000 0.15000000 -1.50000000\n0.80000000 0.15000000 -1.45000000\n0.80000000 0.15000000 -0.95000000\n0.80000000 0.15000000 -0.90000000\n0.80000000 0.15000000 1.50000000\n0.80000000 0.15000000 2.10000000\n0.80000000 0.20000000 -1.50000000\n0.80000000 0.20000000 -0.90000000\n0.80000000 0.20000000 1.45000000\n0.80000000 0.20000000 2.10000000\n0.80000000 0.25000000 -1.55000000\n0.80000000 0.25000000 -0.90000000\n0.80000000 0.25000000 -0.65000000\n0.80000000 0.25000000 -0.60000000\n0.80000000 0.25000000 -0.55000000\n0.80000000 0.25000000 -0.50000000\n0.80000000 0.25000000 -0.45000000\n0.80000000 0.25000000 -0.40000000\n0.80000000 0.25000000 -0.35000000\n0.80000000 0.25000000 -0.30000000\n0.80000000 0.25000000 -0.25000000\n0.80000000 0.25000000 -0.20000000\n0.80000000 0.25000000 -0.15000000\n0.80000000 0.25000000 -0.10000000\n0.80000000 0.25000000 -0.05000000\n0.80000000 0.25000000 0.00000000\n0.80000000 0.25000000 0.05000000\n0.80000000 0.25000000 0.10000000\n0.80000000 0.25000000 0.15000000\n0.80000000 0.25000000 0.20000000\n0.80000000 0.25000000 0.25000000\n0.80000000 0.25000000 0.30000000\n0.80000000 0.25000000 0.35000000\n0.80000000 0.25000000 0.40000000\n0.80000000 0.25000000 0.45000000\n0.80000000 0.25000000 0.50000000\n0.80000000 0.25000000 0.55000000\n0.80000000 0.25000000 1.45000000\n0.80000000 0.25000000 2.15000000\n0.80000000 0.30000000 -1.55000000\n0.80000000 0.30000000 -0.85000000\n0.80000000 0.30000000 -0.80000000\n0.80000000 0.30000000 -0.75000000\n0.80000000 0.30000000 -0.70000000\n0.80000000 0.30000000 0.60000000\n0.80000000 0.30000000 0.65000000\n0.80000000 0.30000000 0.70000000\n0.80000000 0.30000000 1.45000000\n0.80000000 0.30000000 2.15000000\n0.80000000 0.35000000 -1.55000000\n0.80000000 0.35000000 0.70000000\n0.80000000 0.35000000 0.75000000\n0.80000000 0.35000000 0.80000000\n0.80000000 0.35000000 1.45000000\n0.80000000 0.35000000 2.15000000\n0.80000000 0.40000000 -1.55000000\n0.80000000 0.40000000 0.70000000\n0.80000000 0.40000000 0.75000000\n0.80000000 0.40000000 0.80000000\n0.80000000 0.40000000 1.45000000\n0.80000000 0.40000000 2.15000000\n0.80000000 0.45000000 -1.55000000\n0.80000000 0.45000000 0.70000000\n0.80000000 0.45000000 0.75000000\n0.80000000 0.45000000 0.80000000\n0.80000000 0.45000000 1.45000000\n0.80000000 0.45000000 2.15000000\n0.80000000 0.50000000 -1.50000000\n0.80000000 0.50000000 0.65000000\n0.80000000 0.50000000 0.70000000\n0.80000000 0.50000000 0.75000000\n0.80000000 0.50000000 1.45000000\n0.80000000 0.50000000 2.10000000\n0.80000000 0.55000000 -1.55000000\n0.80000000 0.55000000 0.55000000\n0.80000000 0.55000000 0.60000000\n0.80000000 0.55000000 0.65000000\n0.80000000 0.55000000 1.45000000\n0.80000000 0.55000000 2.10000000\n0.80000000 0.60000000 -1.55000000\n0.80000000 0.60000000 0.25000000\n0.80000000 0.60000000 0.30000000\n0.80000000 0.60000000 0.35000000\n0.80000000 0.60000000 0.40000000\n0.80000000 0.60000000 0.45000000\n0.80000000 0.60000000 0.50000000\n0.80000000 0.60000000 1.50000000\n0.80000000 0.60000000 2.05000000\n0.80000000 0.65000000 -1.55000000\n0.80000000 0.65000000 -0.20000000\n0.80000000 0.65000000 -0.15000000\n0.80000000 0.65000000 -0.10000000\n0.80000000 0.65000000 -0.05000000\n0.80000000 0.65000000 0.00000000\n0.80000000 0.65000000 0.05000000\n0.80000000 0.65000000 0.10000000\n0.80000000 0.65000000 0.15000000\n0.80000000 0.65000000 0.20000000\n0.80000000 0.65000000 1.55000000\n0.80000000 0.65000000 1.60000000\n0.80000000 0.65000000 1.95000000\n0.80000000 0.65000000 2.00000000\n0.80000000 0.70000000 -1.55000000\n0.80000000 0.70000000 -0.25000000\n0.80000000 0.70000000 1.65000000\n0.80000000 0.70000000 1.70000000\n0.80000000 0.70000000 1.75000000\n0.80000000 0.70000000 1.80000000\n0.80000000 0.70000000 1.85000000\n0.80000000 0.70000000 1.90000000\n0.80000000 0.75000000 -1.55000000\n0.80000000 0.75000000 -0.25000000\n0.80000000 0.80000000 -1.55000000\n0.80000000 0.80000000 -1.50000000\n0.80000000 0.80000000 -0.35000000\n0.80000000 0.80000000 -0.30000000\n0.80000000 0.85000000 -1.50000000\n0.80000000 0.85000000 -1.45000000\n0.80000000 0.85000000 -0.40000000\n0.80000000 0.85000000 -0.35000000\n0.80000000 0.90000000 -1.40000000\n0.80000000 0.90000000 -1.35000000\n0.80000000 0.90000000 -0.50000000\n0.80000000 0.90000000 -0.45000000\n0.80000000 0.95000000 -1.30000000\n0.80000000 0.95000000 -1.25000000\n0.80000000 0.95000000 -1.20000000\n0.80000000 0.95000000 -1.15000000\n0.80000000 0.95000000 -1.10000000\n0.80000000 0.95000000 -0.75000000\n0.80000000 0.95000000 -0.70000000\n0.80000000 0.95000000 -0.65000000\n0.80000000 0.95000000 -0.60000000\n0.80000000 0.95000000 -0.55000000\n0.80000000 1.00000000 -1.05000000\n0.80000000 1.00000000 -1.00000000\n0.80000000 1.00000000 -0.95000000\n0.80000000 1.00000000 -0.90000000\n0.80000000 1.00000000 -0.85000000\n0.80000000 1.00000000 -0.80000000\n0.85000000 0.00000000 -1.35000000\n0.85000000 0.00000000 -1.30000000\n0.85000000 0.00000000 -1.25000000\n0.85000000 0.00000000 -1.20000000\n0.85000000 0.00000000 -1.15000000\n0.85000000 0.00000000 -1.10000000\n0.85000000 0.00000000 -1.05000000\n0.85000000 0.00000000 1.65000000\n0.85000000 0.00000000 1.70000000\n0.85000000 0.00000000 1.75000000\n0.85000000 0.00000000 1.80000000\n0.85000000 0.00000000 1.85000000\n0.85000000 0.00000000 1.90000000\n0.85000000 0.00000000 1.95000000\n0.85000000 0.05000000 -1.45000000\n0.85000000 0.05000000 -1.40000000\n0.85000000 0.05000000 -1.00000000\n0.85000000 0.05000000 1.55000000\n0.85000000 0.05000000 1.60000000\n0.85000000 0.05000000 2.00000000\n0.85000000 0.10000000 -1.50000000\n0.85000000 0.10000000 -0.95000000\n0.85000000 0.10000000 1.50000000\n0.85000000 0.10000000 2.05000000\n0.85000000 0.15000000 -1.50000000\n0.85000000 0.15000000 -0.90000000\n0.85000000 0.15000000 1.45000000\n0.85000000 0.15000000 2.10000000\n0.85000000 0.20000000 -1.55000000\n0.85000000 0.20000000 -0.85000000\n0.85000000 0.20000000 1.45000000\n0.85000000 0.20000000 2.10000000\n0.85000000 0.25000000 -1.55000000\n0.85000000 0.25000000 -0.85000000\n0.85000000 0.25000000 -0.40000000\n0.85000000 0.25000000 -0.35000000\n0.85000000 0.25000000 -0.30000000\n0.85000000 0.25000000 -0.25000000\n0.85000000 0.25000000 -0.20000000\n0.85000000 0.25000000 -0.15000000\n0.85000000 0.25000000 -0.10000000\n0.85000000 0.25000000 -0.05000000\n0.85000000 0.25000000 0.00000000\n0.85000000 0.25000000 0.05000000\n0.85000000 0.25000000 0.10000000\n0.85000000 0.25000000 0.15000000\n0.85000000 0.25000000 0.20000000\n0.85000000 0.25000000 0.25000000\n0.85000000 0.25000000 0.30000000\n0.85000000 0.25000000 1.45000000\n0.85000000 0.25000000 2.15000000\n0.85000000 0.30000000 -1.55000000\n0.85000000 0.30000000 -0.85000000\n0.85000000 0.30000000 -0.75000000\n0.85000000 0.30000000 -0.70000000\n0.85000000 0.30000000 -0.65000000\n0.85000000 0.30000000 -0.60000000\n0.85000000 0.30000000 -0.55000000\n0.85000000 0.30000000 -0.50000000\n0.85000000 0.30000000 -0.45000000\n0.85000000 0.30000000 0.35000000\n0.85000000 0.30000000 0.40000000\n0.85000000 0.30000000 0.45000000\n0.85000000 0.30000000 0.50000000\n0.85000000 0.30000000 0.55000000\n0.85000000 0.30000000 1.40000000\n0.85000000 0.30000000 2.15000000\n0.85000000 0.35000000 -1.55000000\n0.85000000 0.35000000 -0.80000000\n0.85000000 0.35000000 0.50000000\n0.85000000 0.35000000 0.55000000\n0.85000000 0.35000000 0.60000000\n0.85000000 0.35000000 0.65000000\n0.85000000 0.35000000 1.40000000\n0.85000000 0.35000000 2.15000000\n0.85000000 0.40000000 -1.55000000\n0.85000000 0.40000000 0.55000000\n0.85000000 0.40000000 0.60000000\n0.85000000 0.40000000 0.65000000\n0.85000000 0.40000000 1.40000000\n0.85000000 0.40000000 2.15000000\n0.85000000 0.45000000 -1.55000000\n0.85000000 0.45000000 0.55000000\n0.85000000 0.45000000 0.60000000\n0.85000000 0.45000000 0.65000000\n0.85000000 0.45000000 1.45000000\n0.85000000 0.45000000 2.15000000\n0.85000000 0.50000000 -1.55000000\n0.85000000 0.50000000 0.50000000\n0.85000000 0.50000000 0.55000000\n0.85000000 0.50000000 0.60000000\n0.85000000 0.50000000 1.45000000\n0.85000000 0.50000000 2.10000000\n0.85000000 0.55000000 -1.50000000\n0.85000000 0.55000000 0.35000000\n0.85000000 0.55000000 0.40000000\n0.85000000 0.55000000 0.45000000\n0.85000000 0.55000000 0.50000000\n0.85000000 0.55000000 1.45000000\n0.85000000 0.55000000 2.10000000\n0.85000000 0.60000000 -1.50000000\n0.85000000 0.60000000 0.00000000\n0.85000000 0.60000000 0.05000000\n0.85000000 0.60000000 0.10000000\n0.85000000 0.60000000 0.15000000\n0.85000000 0.60000000 0.20000000\n0.85000000 0.60000000 0.25000000\n0.85000000 0.60000000 0.30000000\n0.85000000 0.60000000 1.50000000\n0.85000000 0.60000000 2.05000000\n0.85000000 0.65000000 -1.50000000\n0.85000000 0.65000000 -0.30000000\n0.85000000 0.65000000 -0.25000000\n0.85000000 0.65000000 -0.20000000\n0.85000000 0.65000000 -0.15000000\n0.85000000 0.65000000 -0.10000000\n0.85000000 0.65000000 -0.05000000\n0.85000000 0.65000000 1.55000000\n0.85000000 0.65000000 2.00000000\n0.85000000 0.70000000 -1.50000000\n0.85000000 0.70000000 -0.35000000\n0.85000000 0.70000000 -0.30000000\n0.85000000 0.70000000 1.60000000\n0.85000000 0.70000000 1.65000000\n0.85000000 0.70000000 1.70000000\n0.85000000 0.70000000 1.75000000\n0.85000000 0.70000000 1.80000000\n0.85000000 0.70000000 1.85000000\n0.85000000 0.70000000 1.90000000\n0.85000000 0.70000000 1.95000000\n0.85000000 0.75000000 -1.50000000\n0.85000000 0.75000000 -1.45000000\n0.85000000 0.75000000 -0.35000000\n0.85000000 0.75000000 -0.30000000\n0.85000000 0.80000000 -1.45000000\n0.85000000 0.80000000 -1.40000000\n0.85000000 0.80000000 -0.40000000\n0.85000000 0.85000000 -1.40000000\n0.85000000 0.85000000 -1.35000000\n0.85000000 0.85000000 -0.50000000\n0.85000000 0.85000000 -0.45000000\n0.85000000 0.90000000 -1.30000000\n0.85000000 0.90000000 -1.25000000\n0.85000000 0.90000000 -0.65000000\n0.85000000 0.90000000 -0.60000000\n0.85000000 0.90000000 -0.55000000\n0.85000000 0.95000000 -1.20000000\n0.85000000 0.95000000 -1.15000000\n0.85000000 0.95000000 -1.10000000\n0.85000000 0.95000000 -1.05000000\n0.85000000 0.95000000 -1.00000000\n0.85000000 0.95000000 -0.95000000\n0.85000000 0.95000000 -0.90000000\n0.85000000 0.95000000 -0.85000000\n0.85000000 0.95000000 -0.80000000\n0.85000000 0.95000000 -0.75000000\n0.85000000 0.95000000 -0.70000000\n0.90000000 0.00000000 -1.35000000\n0.90000000 0.00000000 -1.30000000\n0.90000000 0.00000000 -1.25000000\n0.90000000 0.00000000 -1.20000000\n0.90000000 0.00000000 -1.15000000\n0.90000000 0.00000000 -1.10000000\n0.90000000 0.00000000 -1.05000000\n0.90000000 0.00000000 1.65000000\n0.90000000 0.00000000 1.70000000\n0.90000000 0.00000000 1.75000000\n0.90000000 0.00000000 1.80000000\n0.90000000 0.00000000 1.85000000\n0.90000000 0.00000000 1.90000000\n0.90000000 0.00000000 1.95000000\n0.90000000 0.05000000 -1.45000000\n0.90000000 0.05000000 -1.40000000\n0.90000000 0.05000000 -1.00000000\n0.90000000 0.05000000 1.55000000\n0.90000000 0.05000000 1.60000000\n0.90000000 0.05000000 2.00000000\n0.90000000 0.10000000 -1.50000000\n0.90000000 0.10000000 -0.95000000\n0.90000000 0.10000000 1.50000000\n0.90000000 0.10000000 2.05000000\n0.90000000 0.15000000 -1.50000000\n0.90000000 0.15000000 -0.90000000\n0.90000000 0.15000000 1.45000000\n0.90000000 0.15000000 2.10000000\n0.90000000 0.20000000 -1.55000000\n0.90000000 0.20000000 -0.85000000\n0.90000000 0.20000000 1.45000000\n0.90000000 0.20000000 2.10000000\n0.90000000 0.25000000 -1.55000000\n0.90000000 0.25000000 -0.85000000\n0.90000000 0.25000000 1.45000000\n0.90000000 0.25000000 2.15000000\n0.90000000 0.30000000 -1.55000000\n0.90000000 0.30000000 -0.85000000\n0.90000000 0.30000000 -0.50000000\n0.90000000 0.30000000 -0.45000000\n0.90000000 0.30000000 -0.40000000\n0.90000000 0.30000000 -0.35000000\n0.90000000 0.30000000 -0.30000000\n0.90000000 0.30000000 -0.25000000\n0.90000000 0.30000000 -0.20000000\n0.90000000 0.30000000 -0.15000000\n0.90000000 0.30000000 -0.10000000\n0.90000000 0.30000000 -0.05000000\n0.90000000 0.30000000 0.00000000\n0.90000000 0.30000000 0.05000000\n0.90000000 0.30000000 0.10000000\n0.90000000 0.30000000 0.15000000\n0.90000000 0.30000000 0.20000000\n0.90000000 0.30000000 0.25000000\n0.90000000 0.30000000 0.30000000\n0.90000000 0.30000000 0.35000000\n0.90000000 0.30000000 1.40000000\n0.90000000 0.30000000 2.15000000\n0.90000000 0.35000000 -1.55000000\n0.90000000 0.35000000 -0.85000000\n0.90000000 0.35000000 -0.75000000\n0.90000000 0.35000000 -0.70000000\n0.90000000 0.35000000 -0.65000000\n0.90000000 0.35000000 -0.60000000\n0.90000000 0.35000000 -0.55000000\n0.90000000 0.35000000 0.25000000\n0.90000000 0.35000000 0.30000000\n0.90000000 0.35000000 0.35000000\n0.90000000 0.35000000 0.40000000\n0.90000000 0.35000000 0.45000000\n0.90000000 0.35000000 1.40000000\n0.90000000 0.35000000 2.15000000\n0.90000000 0.40000000 -1.55000000\n0.90000000 0.40000000 -0.80000000\n0.90000000 0.40000000 -0.75000000\n0.90000000 0.40000000 -0.70000000\n0.90000000 0.40000000 0.35000000\n0.90000000 0.40000000 0.40000000\n0.90000000 0.40000000 0.45000000\n0.90000000 0.40000000 0.50000000\n0.90000000 0.40000000 1.40000000\n0.90000000 0.40000000 2.15000000\n0.90000000 0.45000000 -1.55000000\n0.90000000 0.45000000 0.35000000\n0.90000000 0.45000000 0.40000000\n0.90000000 0.45000000 0.45000000\n0.90000000 0.45000000 0.50000000\n0.90000000 0.45000000 1.45000000\n0.90000000 0.45000000 2.15000000\n0.90000000 0.50000000 -1.55000000\n0.90000000 0.50000000 0.30000000\n0.90000000 0.50000000 0.35000000\n0.90000000 0.50000000 0.40000000\n0.90000000 0.50000000 0.45000000\n0.90000000 0.50000000 1.45000000\n0.90000000 0.50000000 2.10000000\n0.90000000 0.55000000 -1.50000000\n0.90000000 0.55000000 0.10000000\n0.90000000 0.55000000 0.15000000\n0.90000000 0.55000000 0.20000000\n0.90000000 0.55000000 0.25000000\n0.90000000 0.55000000 0.30000000\n0.90000000 0.55000000 0.35000000\n0.90000000 0.55000000 1.45000000\n0.90000000 0.55000000 2.10000000\n0.90000000 0.60000000 -1.50000000\n0.90000000 0.60000000 -0.40000000\n0.90000000 0.60000000 -0.35000000\n0.90000000 0.60000000 -0.30000000\n0.90000000 0.60000000 -0.25000000\n0.90000000 0.60000000 -0.20000000\n0.90000000 0.60000000 -0.15000000\n0.90000000 0.60000000 -0.10000000\n0.90000000 0.60000000 -0.05000000\n0.90000000 0.60000000 0.00000000\n0.90000000 0.60000000 0.05000000\n0.90000000 0.60000000 0.10000000\n0.90000000 0.60000000 1.50000000\n0.90000000 0.60000000 2.05000000\n0.90000000 0.65000000 -1.45000000\n0.90000000 0.65000000 -0.40000000\n0.90000000 0.65000000 -0.35000000\n0.90000000 0.65000000 1.55000000\n0.90000000 0.65000000 1.60000000\n0.90000000 0.65000000 2.00000000\n0.90000000 0.70000000 -1.45000000\n0.90000000 0.70000000 -1.40000000\n0.90000000 0.70000000 -0.45000000\n0.90000000 0.70000000 -0.40000000\n0.90000000 0.70000000 1.65000000\n0.90000000 0.70000000 1.70000000\n0.90000000 0.70000000 1.75000000\n0.90000000 0.70000000 1.80000000\n0.90000000 0.70000000 1.85000000\n0.90000000 0.70000000 1.90000000\n0.90000000 0.70000000 1.95000000\n0.90000000 0.75000000 -1.40000000\n0.90000000 0.75000000 -1.35000000\n0.90000000 0.75000000 -0.45000000\n0.90000000 0.75000000 -0.40000000\n0.90000000 0.80000000 -1.35000000\n0.90000000 0.80000000 -1.30000000\n0.90000000 0.80000000 -0.55000000\n0.90000000 0.80000000 -0.50000000\n0.90000000 0.80000000 -0.45000000\n0.90000000 0.85000000 -1.30000000\n0.90000000 0.85000000 -1.25000000\n0.90000000 0.85000000 -0.65000000\n0.90000000 0.85000000 -0.60000000\n0.90000000 0.85000000 -0.55000000\n0.90000000 0.90000000 -1.20000000\n0.90000000 0.90000000 -1.15000000\n0.90000000 0.90000000 -1.10000000\n0.90000000 0.90000000 -1.05000000\n0.90000000 0.90000000 -1.00000000\n0.90000000 0.90000000 -0.95000000\n0.90000000 0.90000000 -0.90000000\n0.90000000 0.90000000 -0.85000000\n0.90000000 0.90000000 -0.80000000\n0.90000000 0.90000000 -0.75000000\n0.90000000 0.90000000 -0.70000000\n0.90000000 0.90000000 -0.65000000\n0.95000000 0.00000000 -1.35000000\n0.95000000 0.00000000 -1.30000000\n0.95000000 0.00000000 -1.25000000\n0.95000000 0.00000000 -1.20000000\n0.95000000 0.00000000 -1.15000000\n0.95000000 0.00000000 -1.10000000\n0.95000000 0.00000000 1.70000000\n0.95000000 0.00000000 1.75000000\n0.95000000 0.00000000 1.80000000\n0.95000000 0.00000000 1.85000000\n0.95000000 0.05000000 -1.40000000\n0.95000000 0.05000000 -1.05000000\n0.95000000 0.05000000 -1.00000000\n0.95000000 0.05000000 1.60000000\n0.95000000 0.05000000 1.65000000\n0.95000000 0.05000000 1.70000000\n0.95000000 0.05000000 1.85000000\n0.95000000 0.05000000 1.90000000\n0.95000000 0.05000000 1.95000000\n0.95000000 0.10000000 -1.45000000\n0.95000000 0.10000000 -0.95000000\n0.95000000 0.10000000 1.55000000\n0.95000000 0.10000000 2.00000000\n0.95000000 0.10000000 2.05000000\n0.95000000 0.15000000 -1.50000000\n0.95000000 0.15000000 -0.90000000\n0.95000000 0.15000000 1.50000000\n0.95000000 0.15000000 2.05000000\n0.95000000 0.20000000 -1.55000000\n0.95000000 0.20000000 -0.90000000\n0.95000000 0.20000000 1.45000000\n0.95000000 0.20000000 1.50000000\n0.95000000 0.20000000 2.10000000\n0.95000000 0.25000000 -1.55000000\n0.95000000 0.25000000 -0.85000000\n0.95000000 0.25000000 1.45000000\n0.95000000 0.25000000 2.10000000\n0.95000000 0.30000000 -1.55000000\n0.95000000 0.30000000 -0.85000000\n0.95000000 0.30000000 1.45000000\n0.95000000 0.30000000 2.10000000\n0.95000000 0.35000000 -1.55000000\n0.95000000 0.35000000 -0.85000000\n0.95000000 0.35000000 -0.50000000\n0.95000000 0.35000000 -0.45000000\n0.95000000 0.35000000 -0.40000000\n0.95000000 0.35000000 -0.35000000\n0.95000000 0.35000000 -0.30000000\n0.95000000 0.35000000 -0.25000000\n0.95000000 0.35000000 -0.20000000\n0.95000000 0.35000000 -0.15000000\n0.95000000 0.35000000 -0.10000000\n0.95000000 0.35000000 -0.05000000\n0.95000000 0.35000000 0.00000000\n0.95000000 0.35000000 0.05000000\n0.95000000 0.35000000 0.10000000\n0.95000000 0.35000000 0.15000000\n0.95000000 0.35000000 0.20000000\n0.95000000 0.35000000 1.45000000\n0.95000000 0.35000000 2.10000000\n0.95000000 0.40000000 -1.55000000\n0.95000000 0.40000000 -0.85000000\n0.95000000 0.40000000 -0.65000000\n0.95000000 0.40000000 -0.60000000\n0.95000000 0.40000000 -0.55000000\n0.95000000 0.40000000 -0.50000000\n0.95000000 0.40000000 -0.45000000\n0.95000000 0.40000000 -0.40000000\n0.95000000 0.40000000 -0.35000000\n0.95000000 0.40000000 -0.30000000\n0.95000000 0.40000000 -0.25000000\n0.95000000 0.40000000 -0.20000000\n0.95000000 0.40000000 -0.15000000\n0.95000000 0.40000000 -0.10000000\n0.95000000 0.40000000 -0.05000000\n0.95000000 0.40000000 0.00000000\n0.95000000 0.40000000 0.05000000\n0.95000000 0.40000000 0.10000000\n0.95000000 0.40000000 0.15000000\n0.95000000 0.40000000 0.20000000\n0.95000000 0.40000000 0.25000000\n0.95000000 0.40000000 0.30000000\n0.95000000 0.40000000 1.45000000\n0.95000000 0.40000000 2.10000000\n0.95000000 0.45000000 -1.55000000\n0.95000000 0.45000000 -0.85000000\n0.95000000 0.45000000 -0.80000000\n0.95000000 0.45000000 -0.75000000\n0.95000000 0.45000000 -0.70000000\n0.95000000 0.45000000 -0.65000000\n0.95000000 0.45000000 -0.60000000\n0.95000000 0.45000000 -0.55000000\n0.95000000 0.45000000 -0.50000000\n0.95000000 0.45000000 -0.45000000\n0.95000000 0.45000000 -0.40000000\n0.95000000 0.45000000 -0.35000000\n0.95000000 0.45000000 -0.30000000\n0.95000000 0.45000000 -0.25000000\n0.95000000 0.45000000 -0.20000000\n0.95000000 0.45000000 -0.15000000\n0.95000000 0.45000000 -0.10000000\n0.95000000 0.45000000 -0.05000000\n0.95000000 0.45000000 0.00000000\n0.95000000 0.45000000 0.05000000\n0.95000000 0.45000000 0.10000000\n0.95000000 0.45000000 0.15000000\n0.95000000 0.45000000 0.20000000\n0.95000000 0.45000000 0.25000000\n0.95000000 0.45000000 0.30000000\n0.95000000 0.45000000 1.45000000\n0.95000000 0.45000000 2.10000000\n0.95000000 0.50000000 -1.55000000\n0.95000000 0.50000000 -0.70000000\n0.95000000 0.50000000 -0.65000000\n0.95000000 0.50000000 -0.60000000\n0.95000000 0.50000000 -0.55000000\n0.95000000 0.50000000 -0.50000000\n0.95000000 0.50000000 -0.45000000\n0.95000000 0.50000000 -0.40000000\n0.95000000 0.50000000 -0.35000000\n0.95000000 0.50000000 -0.30000000\n0.95000000 0.50000000 -0.25000000\n0.95000000 0.50000000 -0.20000000\n0.95000000 0.50000000 -0.15000000\n0.95000000 0.50000000 -0.10000000\n0.95000000 0.50000000 -0.05000000\n0.95000000 0.50000000 0.00000000\n0.95000000 0.50000000 0.05000000\n0.95000000 0.50000000 0.10000000\n0.95000000 0.50000000 0.15000000\n0.95000000 0.50000000 0.20000000\n0.95000000 0.50000000 0.25000000\n0.95000000 0.50000000 1.45000000\n0.95000000 0.50000000 1.50000000\n0.95000000 0.50000000 2.10000000\n0.95000000 0.55000000 -1.50000000\n0.95000000 0.55000000 -0.60000000\n0.95000000 0.55000000 -0.55000000\n0.95000000 0.55000000 -0.50000000\n0.95000000 0.55000000 -0.45000000\n0.95000000 0.55000000 -0.40000000\n0.95000000 0.55000000 -0.35000000\n0.95000000 0.55000000 -0.30000000\n0.95000000 0.55000000 -0.25000000\n0.95000000 0.55000000 -0.20000000\n0.95000000 0.55000000 -0.15000000\n0.95000000 0.55000000 -0.10000000\n0.95000000 0.55000000 -0.05000000\n0.95000000 0.55000000 0.00000000\n0.95000000 0.55000000 0.05000000\n0.95000000 0.55000000 1.50000000\n0.95000000 0.55000000 2.05000000\n0.95000000 0.60000000 -1.45000000\n0.95000000 0.60000000 -0.55000000\n0.95000000 0.60000000 -0.50000000\n0.95000000 0.60000000 -0.45000000\n0.95000000 0.60000000 1.55000000\n0.95000000 0.60000000 2.00000000\n0.95000000 0.60000000 2.05000000\n0.95000000 0.65000000 -1.40000000\n0.95000000 0.65000000 -0.55000000\n0.95000000 0.65000000 -0.50000000\n0.95000000 0.65000000 -0.45000000\n0.95000000 0.65000000 1.60000000\n0.95000000 0.65000000 1.65000000\n0.95000000 0.65000000 1.90000000\n0.95000000 0.65000000 1.95000000\n0.95000000 0.65000000 2.00000000\n0.95000000 0.70000000 -1.35000000\n0.95000000 0.70000000 -1.30000000\n0.95000000 0.70000000 -1.25000000\n0.95000000 0.70000000 -0.55000000\n0.95000000 0.70000000 -0.50000000\n0.95000000 0.70000000 1.70000000\n0.95000000 0.70000000 1.75000000\n0.95000000 0.70000000 1.80000000\n0.95000000 0.70000000 1.85000000\n0.95000000 0.70000000 1.90000000\n0.95000000 0.75000000 -1.30000000\n0.95000000 0.75000000 -1.25000000\n0.95000000 0.75000000 -1.20000000\n0.95000000 0.75000000 -0.60000000\n0.95000000 0.75000000 -0.55000000\n0.95000000 0.75000000 -0.50000000\n0.95000000 0.80000000 -1.25000000\n0.95000000 0.80000000 -1.20000000\n0.95000000 0.80000000 -1.15000000\n0.95000000 0.80000000 -0.70000000\n0.95000000 0.80000000 -0.65000000\n0.95000000 0.80000000 -0.60000000\n0.95000000 0.85000000 -1.20000000\n0.95000000 0.85000000 -1.15000000\n0.95000000 0.85000000 -1.10000000\n0.95000000 0.85000000 -1.05000000\n0.95000000 0.85000000 -1.00000000\n0.95000000 0.85000000 -0.95000000\n0.95000000 0.85000000 -0.90000000\n0.95000000 0.85000000 -0.85000000\n0.95000000 0.85000000 -0.80000000\n0.95000000 0.85000000 -0.75000000\n0.95000000 0.85000000 -0.70000000\n1.00000000 0.05000000 -1.35000000\n1.00000000 0.05000000 -1.30000000\n1.00000000 0.05000000 -1.25000000\n1.00000000 0.05000000 -1.20000000\n1.00000000 0.05000000 -1.15000000\n1.00000000 0.05000000 -1.10000000\n1.00000000 0.05000000 -1.05000000\n1.00000000 0.05000000 1.75000000\n1.00000000 0.05000000 1.80000000\n1.00000000 0.10000000 -1.40000000\n1.00000000 0.10000000 -1.35000000\n1.00000000 0.10000000 -1.30000000\n1.00000000 0.10000000 -1.25000000\n1.00000000 0.10000000 -1.20000000\n1.00000000 0.10000000 -1.15000000\n1.00000000 0.10000000 -1.10000000\n1.00000000 0.10000000 -1.05000000\n1.00000000 0.10000000 -1.00000000\n1.00000000 0.10000000 1.60000000\n1.00000000 0.10000000 1.65000000\n1.00000000 0.10000000 1.70000000\n1.00000000 0.10000000 1.75000000\n1.00000000 0.10000000 1.80000000\n1.00000000 0.10000000 1.85000000\n1.00000000 0.10000000 1.90000000\n1.00000000 0.10000000 1.95000000\n1.00000000 0.15000000 -1.45000000\n1.00000000 0.15000000 -1.40000000\n1.00000000 0.15000000 -1.05000000\n1.00000000 0.15000000 -1.00000000\n1.00000000 0.15000000 -0.95000000\n1.00000000 0.15000000 1.55000000\n1.00000000 0.15000000 1.60000000\n1.00000000 0.15000000 1.65000000\n1.00000000 0.15000000 1.70000000\n1.00000000 0.15000000 1.75000000\n1.00000000 0.15000000 1.80000000\n1.00000000 0.15000000 1.85000000\n1.00000000 0.15000000 1.90000000\n1.00000000 0.15000000 1.95000000\n1.00000000 0.15000000 2.00000000\n1.00000000 0.20000000 -1.50000000\n1.00000000 0.20000000 -1.45000000\n1.00000000 0.20000000 -0.95000000\n1.00000000 0.20000000 1.55000000\n1.00000000 0.20000000 1.60000000\n1.00000000 0.20000000 1.65000000\n1.00000000 0.20000000 1.90000000\n1.00000000 0.20000000 1.95000000\n1.00000000 0.20000000 2.00000000\n1.00000000 0.20000000 2.05000000\n1.00000000 0.25000000 -1.50000000\n1.00000000 0.25000000 -1.45000000\n1.00000000 0.25000000 -0.95000000\n1.00000000 0.25000000 -0.90000000\n1.00000000 0.25000000 1.50000000\n1.00000000 0.25000000 1.55000000\n1.00000000 0.25000000 1.60000000\n1.00000000 0.25000000 1.95000000\n1.00000000 0.25000000 2.00000000\n1.00000000 0.25000000 2.05000000\n1.00000000 0.30000000 -1.50000000\n1.00000000 0.30000000 -0.95000000\n1.00000000 0.30000000 -0.90000000\n1.00000000 0.30000000 1.50000000\n1.00000000 0.30000000 1.55000000\n1.00000000 0.30000000 1.60000000\n1.00000000 0.30000000 2.00000000\n1.00000000 0.30000000 2.05000000\n1.00000000 0.35000000 -1.50000000\n1.00000000 0.35000000 -0.95000000\n1.00000000 0.35000000 -0.90000000\n1.00000000 0.35000000 1.50000000\n1.00000000 0.35000000 1.55000000\n1.00000000 0.35000000 2.00000000\n1.00000000 0.35000000 2.05000000\n1.00000000 0.40000000 -1.50000000\n1.00000000 0.40000000 -0.95000000\n1.00000000 0.40000000 -0.90000000\n1.00000000 0.40000000 1.50000000\n1.00000000 0.40000000 1.55000000\n1.00000000 0.40000000 1.60000000\n1.00000000 0.40000000 2.00000000\n1.00000000 0.40000000 2.05000000\n1.00000000 0.45000000 -1.50000000\n1.00000000 0.45000000 -1.45000000\n1.00000000 0.45000000 -0.95000000\n1.00000000 0.45000000 -0.90000000\n1.00000000 0.45000000 1.50000000\n1.00000000 0.45000000 1.55000000\n1.00000000 0.45000000 1.60000000\n1.00000000 0.45000000 1.95000000\n1.00000000 0.45000000 2.00000000\n1.00000000 0.45000000 2.05000000\n1.00000000 0.50000000 -1.50000000\n1.00000000 0.50000000 -1.45000000\n1.00000000 0.50000000 -0.95000000\n1.00000000 0.50000000 -0.90000000\n1.00000000 0.50000000 -0.85000000\n1.00000000 0.50000000 -0.80000000\n1.00000000 0.50000000 -0.75000000\n1.00000000 0.50000000 1.55000000\n1.00000000 0.50000000 1.60000000\n1.00000000 0.50000000 1.65000000\n1.00000000 0.50000000 1.90000000\n1.00000000 0.50000000 1.95000000\n1.00000000 0.50000000 2.00000000\n1.00000000 0.50000000 2.05000000\n1.00000000 0.55000000 -1.45000000\n1.00000000 0.55000000 -1.40000000\n1.00000000 0.55000000 -1.00000000\n1.00000000 0.55000000 -0.95000000\n1.00000000 0.55000000 -0.90000000\n1.00000000 0.55000000 -0.85000000\n1.00000000 0.55000000 -0.80000000\n1.00000000 0.55000000 -0.75000000\n1.00000000 0.55000000 -0.70000000\n1.00000000 0.55000000 -0.65000000\n1.00000000 0.55000000 1.55000000\n1.00000000 0.55000000 1.60000000\n1.00000000 0.55000000 1.65000000\n1.00000000 0.55000000 1.70000000\n1.00000000 0.55000000 1.75000000\n1.00000000 0.55000000 1.80000000\n1.00000000 0.55000000 1.85000000\n1.00000000 0.55000000 1.90000000\n1.00000000 0.55000000 1.95000000\n1.00000000 0.55000000 2.00000000\n1.00000000 0.60000000 -1.40000000\n1.00000000 0.60000000 -1.35000000\n1.00000000 0.60000000 -1.30000000\n1.00000000 0.60000000 -1.10000000\n1.00000000 0.60000000 -1.05000000\n1.00000000 0.60000000 -1.00000000\n1.00000000 0.60000000 -0.95000000\n1.00000000 0.60000000 -0.90000000\n1.00000000 0.60000000 -0.85000000\n1.00000000 0.60000000 -0.80000000\n1.00000000 0.60000000 -0.75000000\n1.00000000 0.60000000 -0.70000000\n1.00000000 0.60000000 -0.65000000\n1.00000000 0.60000000 -0.60000000\n1.00000000 0.60000000 1.60000000\n1.00000000 0.60000000 1.65000000\n1.00000000 0.60000000 1.70000000\n1.00000000 0.60000000 1.75000000\n1.00000000 0.60000000 1.80000000\n1.00000000 0.60000000 1.85000000\n1.00000000 0.60000000 1.90000000\n1.00000000 0.60000000 1.95000000\n1.00000000 0.65000000 -1.35000000\n1.00000000 0.65000000 -1.30000000\n1.00000000 0.65000000 -1.25000000\n1.00000000 0.65000000 -1.20000000\n1.00000000 0.65000000 -1.15000000\n1.00000000 0.65000000 -1.10000000\n1.00000000 0.65000000 -1.05000000\n1.00000000 0.65000000 -1.00000000\n1.00000000 0.65000000 -0.95000000\n1.00000000 0.65000000 -0.90000000\n1.00000000 0.65000000 -0.85000000\n1.00000000 0.65000000 -0.80000000\n1.00000000 0.65000000 -0.75000000\n1.00000000 0.65000000 -0.70000000\n1.00000000 0.65000000 -0.65000000\n1.00000000 0.65000000 -0.60000000\n1.00000000 0.65000000 1.70000000\n1.00000000 0.65000000 1.75000000\n1.00000000 0.65000000 1.80000000\n1.00000000 0.65000000 1.85000000\n1.00000000 0.70000000 -1.20000000\n1.00000000 0.70000000 -1.15000000\n1.00000000 0.70000000 -1.10000000\n1.00000000 0.70000000 -1.05000000\n1.00000000 0.70000000 -1.00000000\n1.00000000 0.70000000 -0.95000000\n1.00000000 0.70000000 -0.90000000\n1.00000000 0.70000000 -0.85000000\n1.00000000 0.70000000 -0.80000000\n1.00000000 0.70000000 -0.75000000\n1.00000000 0.70000000 -0.70000000\n1.00000000 0.70000000 -0.65000000\n1.00000000 0.70000000 -0.60000000\n1.00000000 0.75000000 -1.15000000\n1.00000000 0.75000000 -1.10000000\n1.00000000 0.75000000 -1.05000000\n1.00000000 0.75000000 -1.00000000\n1.00000000 0.75000000 -0.95000000\n1.00000000 0.75000000 -0.90000000\n1.00000000 0.75000000 -0.85000000\n1.00000000 0.75000000 -0.80000000\n1.00000000 0.75000000 -0.75000000\n1.00000000 0.75000000 -0.70000000\n1.00000000 0.75000000 -0.65000000\n1.00000000 0.80000000 -1.10000000\n1.00000000 0.80000000 -1.05000000\n1.00000000 0.80000000 -1.00000000\n1.00000000 0.80000000 -0.95000000\n1.00000000 0.80000000 -0.90000000\n1.00000000 0.80000000 -0.85000000\n1.00000000 0.80000000 -0.80000000\n1.00000000 0.80000000 -0.75000000\n1.05000000 0.15000000 -1.35000000\n1.05000000 0.15000000 -1.30000000\n1.05000000 0.15000000 -1.25000000\n1.05000000 0.15000000 -1.20000000\n1.05000000 0.15000000 -1.15000000\n1.05000000 0.15000000 -1.10000000\n1.05000000 0.20000000 -1.40000000\n1.05000000 0.20000000 -1.35000000\n1.05000000 0.20000000 -1.30000000\n1.05000000 0.20000000 -1.25000000\n1.05000000 0.20000000 -1.20000000\n1.05000000 0.20000000 -1.15000000\n1.05000000 0.20000000 -1.10000000\n1.05000000 0.20000000 -1.05000000\n1.05000000 0.20000000 -1.00000000\n1.05000000 0.20000000 1.70000000\n1.05000000 0.20000000 1.75000000\n1.05000000 0.20000000 1.80000000\n1.05000000 0.20000000 1.85000000\n1.05000000 0.25000000 -1.40000000\n1.05000000 0.25000000 -1.35000000\n1.05000000 0.25000000 -1.30000000\n1.05000000 0.25000000 -1.25000000\n1.05000000 0.25000000 -1.20000000\n1.05000000 0.25000000 -1.15000000\n1.05000000 0.25000000 -1.10000000\n1.05000000 0.25000000 -1.05000000\n1.05000000 0.25000000 -1.00000000\n1.05000000 0.25000000 1.65000000\n1.05000000 0.25000000 1.70000000\n1.05000000 0.25000000 1.75000000\n1.05000000 0.25000000 1.80000000\n1.05000000 0.25000000 1.85000000\n1.05000000 0.25000000 1.90000000\n1.05000000 0.30000000 -1.45000000\n1.05000000 0.30000000 -1.40000000\n1.05000000 0.30000000 -1.35000000\n1.05000000 0.30000000 -1.30000000\n1.05000000 0.30000000 -1.25000000\n1.05000000 0.30000000 -1.20000000\n1.05000000 0.30000000 -1.15000000\n1.05000000 0.30000000 -1.10000000\n1.05000000 0.30000000 -1.05000000\n1.05000000 0.30000000 -1.00000000\n1.05000000 0.30000000 1.65000000\n1.05000000 0.30000000 1.70000000\n1.05000000 0.30000000 1.75000000\n1.05000000 0.30000000 1.80000000\n1.05000000 0.30000000 1.85000000\n1.05000000 0.30000000 1.90000000\n1.05000000 0.30000000 1.95000000\n1.05000000 0.35000000 -1.45000000\n1.05000000 0.35000000 -1.40000000\n1.05000000 0.35000000 -1.35000000\n1.05000000 0.35000000 -1.30000000\n1.05000000 0.35000000 -1.25000000\n1.05000000 0.35000000 -1.20000000\n1.05000000 0.35000000 -1.15000000\n1.05000000 0.35000000 -1.10000000\n1.05000000 0.35000000 -1.05000000\n1.05000000 0.35000000 -1.00000000\n1.05000000 0.35000000 1.60000000\n1.05000000 0.35000000 1.65000000\n1.05000000 0.35000000 1.70000000\n1.05000000 0.35000000 1.75000000\n1.05000000 0.35000000 1.80000000\n1.05000000 0.35000000 1.85000000\n1.05000000 0.35000000 1.90000000\n1.05000000 0.35000000 1.95000000\n1.05000000 0.40000000 -1.45000000\n1.05000000 0.40000000 -1.40000000\n1.05000000 0.40000000 -1.35000000\n1.05000000 0.40000000 -1.30000000\n1.05000000 0.40000000 -1.25000000\n1.05000000 0.40000000 -1.20000000\n1.05000000 0.40000000 -1.15000000\n1.05000000 0.40000000 -1.10000000\n1.05000000 0.40000000 -1.05000000\n1.05000000 0.40000000 -1.00000000\n1.05000000 0.40000000 1.65000000\n1.05000000 0.40000000 1.70000000\n1.05000000 0.40000000 1.75000000\n1.05000000 0.40000000 1.80000000\n1.05000000 0.40000000 1.85000000\n1.05000000 0.40000000 1.90000000\n1.05000000 0.40000000 1.95000000\n1.05000000 0.45000000 -1.40000000\n1.05000000 0.45000000 -1.35000000\n1.05000000 0.45000000 -1.30000000\n1.05000000 0.45000000 -1.25000000\n1.05000000 0.45000000 -1.20000000\n1.05000000 0.45000000 -1.15000000\n1.05000000 0.45000000 -1.10000000\n1.05000000 0.45000000 -1.05000000\n1.05000000 0.45000000 -1.00000000\n1.05000000 0.45000000 1.65000000\n1.05000000 0.45000000 1.70000000\n1.05000000 0.45000000 1.75000000\n1.05000000 0.45000000 1.80000000\n1.05000000 0.45000000 1.85000000\n1.05000000 0.45000000 1.90000000\n1.05000000 0.50000000 -1.40000000\n1.05000000 0.50000000 -1.35000000\n1.05000000 0.50000000 -1.30000000\n1.05000000 0.50000000 -1.25000000\n1.05000000 0.50000000 -1.20000000\n1.05000000 0.50000000 -1.15000000\n1.05000000 0.50000000 -1.10000000\n1.05000000 0.50000000 -1.05000000\n1.05000000 0.50000000 -1.00000000\n1.05000000 0.50000000 1.70000000\n1.05000000 0.50000000 1.75000000\n1.05000000 0.50000000 1.80000000\n1.05000000 0.50000000 1.85000000\n1.05000000 0.55000000 -1.35000000\n1.05000000 0.55000000 -1.30000000\n1.05000000 0.55000000 -1.25000000\n1.05000000 0.55000000 -1.20000000\n1.05000000 0.55000000 -1.15000000\n1.05000000 0.55000000 -1.10000000\n1.05000000 0.55000000 -1.05000000\n1.05000000 0.60000000 -1.25000000\n1.05000000 0.60000000 -1.20000000\n1.05000000 0.60000000 -1.15000000"};
    array<float> voxelSizes = {
        0.175f,
        0.1f,
        0.05f,
        0.015f
    };
    int preset = 0;
    int refreshRate = 30;
    int lastPreset = -1;
    bool aborted = false;
    class iso4q {
        vec3 Position;
        quat Rotation;
    }
    iso4q prevTarget();
    uint RENDER_INTERVAL_MS = 1000;
    vec3 Cross(const vec3 &in a, const vec3 &in b) {
        return vec3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        );
    }
    vec3 QuatMultVec3(const quat &in q, const vec3 &in v) {
        vec3 u = vec3(q.x, q.y, q.z);
        float s = q.w;
        return u * 2.0f * Math::Dot(u, v)
            + v * (s*s - Math::Dot(u, u)) 
            + Cross(u, v) * 2.0f * s;
    }
    void CarVisualSettingsPage() {
        UI::CheckboxVar("Enable Car Visual", id+"_car_visual_enabled");
        if(!GetVariableBool(id+"_car_visual_enabled")){
            return;
        }
        preset = UI::SliderIntVar("Model Quality", id+"_car_render_quality", 0, voxels.Length);
        if(aborted){
            UI::TextWrapped("MODEL QUALITY TOO HIGH, RENDERING CANNOT BE COMPLETED IN TIME. MAY CAUSE ISSUES.");
            UI::TextWrapped("Please consider using a lower quality setting.");
        }
        refreshRate = UI::SliderIntVar("Update rate", id+"_car_render_rate", 1, 100);
        UI::TextDimmed("The update rate is the amount of times per second that the car's visual is updated when values change. Lower values may be less responsive but also cause less lag. This setting does not affect performance for a static visual.");
        RENDER_INTERVAL_MS = int(1000 / refreshRate);
    }
    bool vec3Equal(const vec3&in a, const vec3&in b) {
        return a.x == b.x && a.y == b.y && a.z == b.z;
    }
    bool iso4qEqual(const iso4q&in a, const iso4q&in b) {
        if(!vec3Equal(a.Position, b.Position)) {
            return false;
        }
        if(a.Rotation.x != b.Rotation.x ||
        a.Rotation.y != b.Rotation.y ||
        a.Rotation.z != b.Rotation.z ||
        a.Rotation.w != b.Rotation.w) {
            return false;
        }
        return true;
    }
    uint64 startTime = 0;
    void Render(){
        if(GetCurrentGameState() == TM::GameState::StartUp){
            startTime = Time::get_Now();
            return;
        }
        if(Time::get_Now() - startTime < 2000){
            return;
        }
        string cachedIdsStr = GetVariableString(id+"_bf_trigger_cache");
        if (cachedIdsStr != "" && g_ellipsoidVisualTriggerIds.Length == 0) {
            array<string> ids = cachedIdsStr.Split(",");
            array<int> triggerIds = GetTriggerIds();
            for(uint i = 0; i < ids.Length; ++i) {
                if(triggerIds.Find(Text::ParseInt(ids[i]))==-1) {
                    continue;
                }
                if(!RemoveTrigger(Text::ParseInt(ids[i]))){
                    continue;
                }
            }
            SetVariable(id+"_bf_trigger_cache", "");
        }
        SimulationManager@ simManager = GetSimulationManager();
        uint64 currentTime = Time::get_Now();
        if (currentTime - g_lastTriggerUpdateTime > RENDER_INTERVAL_MS) {
            g_lastTriggerUpdateTime = currentTime;
            vec3 pos = Text::ParseVec3(GetVariableString(id+"_bf_target_position"));
            float actual_pitch_deg = GetVariableDouble(id+"_bf_target_rotation_pitch");
            float actual_yaw_deg = GetVariableDouble(id+"_bf_target_rotation_yaw");
            float actual_roll_deg = GetVariableDouble(id+"_bf_target_rotation_roll");
            quat rotation;
            rotation.SetYawPitchRoll(Math::ToRad(actual_yaw_deg), Math::ToRad(actual_pitch_deg), Math::ToRad(actual_roll_deg));
            iso4q location;
            location.Position = pos;
            location.Rotation = rotation;
            RenderCar(location);
        }
    }
    void RenderCar(iso4q target) {
        if (!GetVariableBool(id + "_car_visual_enabled")) {
            if (g_ellipsoidVisualTriggerIds.Length > 0) {
                for (uint i = 0; i < g_ellipsoidVisualTriggerIds.Length; ++i) {
                    if (g_ellipsoidVisualTriggerIds[i] != -1) {
                        RemoveTrigger(g_ellipsoidVisualTriggerIds[i]);
                    }
                }
                g_ellipsoidVisualTriggerIds.Clear();
                SetVariable(id + "_bf_trigger_cache", "");
                lastPreset = -1;
                prevTarget = iso4q();
            }
            return;
        }
        if (iso4qEqual(prevTarget, target) && lastPreset == preset) {
            return;
        }
        prevTarget = target;
        if (GetVariableString(id+"_bf_trigger_cache") != "" && g_ellipsoidVisualTriggerIds.Length == 0){
            array<string> ids = GetVariableString(id+"_bf_trigger_cache").Split(",");
            g_ellipsoidVisualTriggerIds.Resize(ids.Length);
            for(uint i = 0; i < ids.Length; ++i) {
                g_ellipsoidVisualTriggerIds[i] = Text::ParseInt(ids[i]);
            }
            SetVariable(id+"_bf_trigger_cache", "");
        }
        if(lastPreset != preset) {
            int newSize = (preset == 0) ? 4 : voxels[preset - 1].Length;
            int oldSize = g_ellipsoidVisualTriggerIds.Length;
            if (newSize < oldSize) {
                for(int i = newSize; i < oldSize; i++) {
                    if (g_ellipsoidVisualTriggerIds[i] != -1) {
                        RemoveTrigger(g_ellipsoidVisualTriggerIds[i]);
                    }
                }
            }
            g_ellipsoidVisualTriggerIds.Resize(newSize);
            if (newSize > oldSize) {
                for(int i = oldSize; i < newSize; i++) {
                    g_ellipsoidVisualTriggerIds[i] = -1;
                }
            }
            lastPreset = preset;
        }
        auto simManager = GetSimulationManager();
        if (simManager is null || !simManager.InRace) { return; }
        uint64 startTime = Time::get_Now();
        bool currAborted = false;
        if(preset == 0){
            SimulationWheels@ wheels = simManager.Wheels;
            float maxWheelRadius = 0.364f;
            string cache = "";
            for(uint i = 0; i < 4; ++i) {
                vec3 worldPos = GetCarEllipsoidLocationByIndex(simManager, target, i).Position;
                vec3 ellipsoidSize = vec3(maxWheelRadius * 2.0f, maxWheelRadius * 2.0f, maxWheelRadius * 2.0f);
                Trigger3D trig = Trigger3D(worldPos - maxWheelRadius, ellipsoidSize);
                int triggerId = SetTrigger(trig, g_ellipsoidVisualTriggerIds[i]);
                g_ellipsoidVisualTriggerIds[i] = triggerId;
                cache += Text::FormatInt(triggerId) + ",";
            }
            if (cache.Length > 0) {
                cache = cache.Substr(0, cache.Length - 1);
                SetVariable(id+"_bf_trigger_cache", cache);
            }
        } else {
            float s = voxelSizes[preset - 1];
            const vec3 ellipsoidSize = vec3(s, s, s);
            const array<vec3>@ currentVoxels = voxels[preset - 1];
            string cache = "";
            for(uint i = 0; i < currentVoxels.Length; ++i) {
                if(i % 100 == 0 && Time::get_Now() - startTime > RENDER_INTERVAL_MS) {
                    currAborted = true;
                    break;
                }
                vec3 v = currentVoxels[i];
                vec3 worldPos = QuatMultVec3(target.Rotation, v) + target.Position;
                Trigger3D trig = Trigger3D(worldPos - (ellipsoidSize / 2.0f), ellipsoidSize);
                int triggerId = SetTrigger(trig, g_ellipsoidVisualTriggerIds[i]);
                g_ellipsoidVisualTriggerIds[i] = triggerId;
                cache += Text::FormatInt(triggerId) + ",";
            }
            if (cache.Length > 0) {
                cache = cache.Substr(0, cache.Length - 1);
                SetVariable(id+"_bf_trigger_cache", cache);
            }
        }
        aborted = currAborted;
    }
    iso4q GetCarEllipsoidLocationByIndex(SimulationManager@ simM, const iso4q&in carLocation, uint index) {
        auto simManager = GetSimulationManager();
        iso4q worldTransform;
        vec3 wheelSurfaceLocalPos;
        switch(index) {
            case 0: wheelSurfaceLocalPos = simManager.Wheels.FrontLeft.SurfaceHandler.Location.Position; break;
            case 1: wheelSurfaceLocalPos = simManager.Wheels.FrontRight.SurfaceHandler.Location.Position; break;
            case 2: wheelSurfaceLocalPos = simManager.Wheels.BackLeft.SurfaceHandler.Location.Position; break;
            case 3: wheelSurfaceLocalPos = simManager.Wheels.BackRight.SurfaceHandler.Location.Position; break;
            default:
                print("Error: Unexpected index in wheel section: " + index, Severity::Error);
                return iso4q();
        }
        worldTransform.Rotation = carLocation.Rotation;
        worldTransform.Position = carLocation.Position + QuatMultVec3(worldTransform.Rotation, wheelSurfaceLocalPos);
        return worldTransform;
    }
    void RenderEvalSettings(){
        SimulationManager@ simManager = GetSimulationManager();
        UI::Dummy(vec2(0, 17));
        UI::Text("Target position:");
        UI::SameLine();
        UI::DragFloat3Var("##azea", id+"_bf_target_position", 0.01f, -100000.0f, 100000.0f, "%.3f");
        if(simManager.InRace){
            UI::Dummy(vec2(0, 2));
            UI::Dummy(vec2(102, 0));
            UI::SameLine();
            if(GetCurrentCamera().NameId!=""){
                if(UI::Button("Copy from Vehicle")){
                    SetVariable(id+"_bf_target_position", simManager.Dyna.CurrentState.Location.Position.ToString());
                }
            }else{
                if(UI::Button("Copy from Camera")){
                    SetVariable(id+"_bf_target_position", GetCurrentCamera().Location.Position.ToString());
                }
            }
        }
        UI::Dummy(vec2(0, 19));
        UI::Text("Yaw");
        UI::SameLine();
        UI::Dummy(vec2(12, 0));
        UI::SameLine();
        UI::SliderFloatVar("##eaa2aa", id+"_bf_target_rotation_yaw", -180, 180 , "%.2f");
        UI::Text("Pitch");
        UI::SameLine();
        UI::Dummy(vec2(6, 0));
        UI::SameLine();
        UI::SliderFloatVar("##ea2a2", id+"_bf_target_rotation_pitch", -180, 180 , "%.2f");
        UI::Text("Roll");
        UI::SameLine();
        UI::Dummy(vec2(14, 0));
        UI::SameLine();
        UI::SliderFloatVar("##eaaaaaaa2", id+"_bf_target_rotation_roll", -180, 180 , "%.2f");
        UI::Dummy(vec2(0, 2));
        UI::Dummy(vec2(47, 0));
        UI::SameLine();
        if(UI::Button("Copy from Vehicle##1")){
            mat3 vehicleMat = simManager.Dyna.CurrentState.Location.Rotation;
            quat vehicleQuat = quat(vehicleMat);
            float vehicleYaw, vehiclePitch, vehicleRoll;
            vehicleQuat.GetYawPitchRoll(vehicleYaw, vehiclePitch, vehicleRoll); 
            SetVariable(id+"_bf_target_rotation_yaw", Math::ToDeg(vehicleYaw));
            SetVariable(id+"_bf_target_rotation_pitch", Math::ToDeg(vehiclePitch));
            SetVariable(id+"_bf_target_rotation_roll", Math::ToDeg(vehicleRoll));
        }
        UI::SameLine();
        UI::Dummy(vec2(45, 0));
        UI::SameLine();
        if(UI::Button("Reset Rotation")){
            SetVariable(id+"_bf_target_rotation_yaw", 0.0);
            SetVariable(id+"_bf_target_rotation_pitch", 0.0);
            SetVariable(id+"_bf_target_rotation_roll", 0.0);
        }
        UI::Dummy(vec2(0, 19));
        UI::PushItemWidth(300);
        UI::Text("Weight");
        UI::SameLine();
        int bal = int(GetVariableDouble(id+"_bf_weight"));
        string balText = Text::FormatInt(100 - bal) + "%% Position, " + Text::FormatInt(bal) + "%% Rotation";
        UI::SliderIntVar("##injsdqf", id+"_bf_weight", 0, 100, balText);
        UI::Dummy(vec2(0, 0));
        UI::TextDimmed("This parameter is used to weight the rotation difference against the distance. A higher value will make the bruteforcing process more sensitive to rotation differences.");
        UI::Dummy(vec2(0, 17));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(17, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##Nosdfthinqefgg1", id+"_bf_eval_min_time");
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(36, 0));
        UI::SameLine();
        UI::PushItemWidth(200);
        UI::InputTimeVar("##Nothggrtzetgrz2", id+"_bf_eval_max_time");
        UI::Dummy(vec2(0, 0));
        UI::TextDimmed("Reducing the maximum evaluation time will make the bruteforcing process faster.");
        UI::Dummy(vec2(0, 12));
    }
    float bestDist = 0;
    float bestRot = 0;
    int bestTime = 0;
    int minTime = 0;
    int maxTime = 0;
    bool base = false;
    bool improvedYet = false;
    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        bool isEvalTime = raceTime >= minTime && raceTime <= maxTime;
        bool isPastEvalTime = raceTime > maxTime;
        if (info.Phase == BFPhase::Initial) {
            if (isEvalTime) {
                float d = dist();
                float r = rotDiff();
                float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();
                int cps = simManager.PlayerInfo.CurCheckpointCount;
                if(isBetter(d, speed, cps, r)){
                    bestDist = d;
                    bestRot = r;
                    bestTime = raceTime;
                }
            }
            if(isPastEvalTime) {
                resp.Decision = BFEvaluationDecision::Accept;
                string text="";
                if(base){
                    base = false;
                    if(bestTime == 0){
                        text = "Base run: -1.000000000 m, -1.000000000 rad at invalid";
                    }else{
                        text = "Base run: " + Text::FormatFloat(bestDist,"", 0, 9) + " m, " + Text::FormatFloat(Math::ToDeg(bestRot), "", 0, 9) + " deg at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2);
                    }
                    print(text);
                }else{
                    float score = Math::Sqrt(bestDist * bestDist * balance * balance + bestRot * bestRot * (1.0f - balance) * (1.0f - balance));
                    text = "Found better result: " + Text::FormatFloat(bestDist, "", 0, 9) + " m, " + Text::FormatFloat(Math::ToDeg(bestRot), "", 0, 9) + " deg (score: " + Text::FormatFloat(score, "", 0, 9) + ") at " + Text::FormatFloat(bestTime/1000.0, "", 0, 2)+ ", iterations: " + info.Iterations;
                    print(text, Severity::Success);
                }
                resp.ResultFileStartContent = text;
            }
        } else {
            if(isEvalTime){
                float d = dist();
                float r = rotDiff();
                float speed = simManager.Dyna.CurrentState.LinearSpeed.Length();
                int cps = simManager.PlayerInfo.CurCheckpointCount;
                if(isBetter(d, speed, cps, r)){
                    resp.Decision = BFEvaluationDecision::Accept;
                    improvedYet = false;
                }
            }
            if(isPastEvalTime){
                resp.Decision = BFEvaluationDecision::Reject;
            }
        }
        return resp;
    }
    vec3 targetP();
    quat targetR();
    float balance = 0;
    float dist(){
        return Math::Distance(pos(), targetP);
    }
    float Dot(const quat &in a, const quat &in b) {
        return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    }
    float rotDiff(){
        float dot = Math::Abs(Dot(rot(), targetR));
        if(dot > 1.0f) {
            dot = 1.0f;
        }
        return Math::Acos(dot);
    }
    quat rot(){
        return GetSimulationManager().Dyna.CurrentState.Quat;
    }
    vec3 pos() {
        return GetSimulationManager().Dyna.CurrentState.Location.Position;
    }
    void OnSimulationBegin(SimulationManager@ simManager) {
        if (!(GetVariableString("bf_target") == id && GetVariableString("controller") == "bfv2")) {
            return;
        }
        bestDist = -1.0f;
        bestRot = -1.0f;
        bestTime = 0;
        improvedYet = false;
        minTime = int(GetVariableDouble(id + "_bf_eval_min_time"));
        maxTime = int(GetVariableDouble(id + "_bf_eval_max_time"));
        maxTime = ResolveMaxTime(maxTime, int(simManager.EventsDuration));
        targetP = Text::ParseVec3(GetVariableString(id + "_bf_target_position"));
        targetR.SetYawPitchRoll(
            Math::ToRad(GetVariableDouble(id + "_bf_target_rotation_yaw")),
            Math::ToRad(GetVariableDouble(id + "_bf_target_rotation_pitch")),
            Math::ToRad(GetVariableDouble(id + "_bf_target_rotation_roll"))
        );
        base = true;
        speedCondition = GetVariableDouble("bf_condition_speed");
        distCondition = GetVariableDouble("bf_condition_distance") > 0.0f ? GetVariableDouble("bf_condition_distance") : 1e18f;
        cpsCondition = int(GetVariableDouble("bf_condition_cps"));
        balance = (100 - int(GetVariableDouble(id + "_bf_weight"))) / 100.0f;
    }
    float speedCondition = 0.0f;
    float distCondition = 0.0f;
    int cpsCondition = 0;
    bool meetsConditions(float dist, float speed, int cps = 0) {
        return dist < distCondition && speed > speedCondition/3.6f && cps >= cpsCondition && GlobalConditionsMet(GetSimulationManager());
    }
    bool isBetter(float dist, float speed, int cps, float rotDiff) {
        if(meetsConditions(dist, speed, cps)){
            if(!improvedYet){
                improvedYet = true;
                return true;
            }
            return dist * dist * balance * balance + rotDiff * rotDiff * (1.0f - balance) * (1.0f - balance) < bestDist * bestDist * balance * balance + bestRot * bestRot * (1.0f - balance) * (1.0f - balance);
        }
        return false;
    }
    void Main() {
        g_ellipsoidVisualTriggerIds.Clear();
        for(uint i = 0; i < data.Length; ++i) {
            CommandList list();
            list.Content = data[i];
            array<string> lines = list.Content.Split("\n");
            voxels.Add(array<vec3>());
            for (uint j = 0; j < lines.Length; j++) {
                auto line = lines[j];
                if(line.Substr(0, 1) == "#") {
                    continue;
                }
                array<string> coords = line.Split(" ");
                if(coords.Length < 3) {
                    continue;
                }
                try {
                    float x = Text::ParseFloat(coords[0]);
                    float y = Text::ParseFloat(coords[1]);
                    float z = Text::ParseFloat(coords[2]);
                    voxels[i].Add(vec3(x, y, z));
                } catch {
                    print("Error parsing coordinates in line: " + line + " in preset " + i, Severity::Error);
                }
            }
        }
        RegisterVariable(id+"_car_render_quality", 0);
        RegisterVariable(id+"_car_render_rate", 30);
        RegisterVariable(id+"_bf_target_position", "0.0,0.0,0.0");
        RegisterVariable(id+"_bf_target_rotation_yaw", 0.0);
        RegisterVariable(id+"_bf_target_rotation_pitch", 0.0);
        RegisterVariable(id+"_bf_target_rotation_roll", 0.0);
        RegisterVariable(id+"_bf_eval_min_time", 0.0);
        RegisterVariable(id+"_bf_eval_max_time", 0.0);
        RegisterVariable(id+"_bf_trigger_cache", "");
        RegisterVariable(id+"_car_visual_enabled", true);
        RegisterVariable(id + "_bf_weight", 0);
        RegisterVariable("bf_condition_distance", 0.0f);
        RegisterVariable("bf_ignore_same_speed", false);
        RegisterVariable("bf_condition_cps", 0);
        RegisterSettingsPage("Car Visual", CarVisualSettingsPage);
        preset = int(GetVariableDouble(id+"_car_render_quality"));
        RENDER_INTERVAL_MS = int(1000/GetVariableDouble(id+"_car_render_rate"));
        auto eval = RegisterBruteforceEval(id, "Car Location", OnEvaluate, RenderEvalSettings);
        @eval.onSimBegin = @OnSimulationBegin;
    }
}
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

// --- New API handlers ---

void EnsureSlotVariablesRegistered(int slotCount)
{
    for (int s = 1; s < slotCount; s++)
    {
        string vs = GetInputModVarSuffix(uint(s));
        RegisterVariable("bf_modify_count" + vs, 0);
        RegisterVariable("bf_inputs_min_time" + vs, 0);
        RegisterVariable("bf_inputs_max_time" + vs, 0);
        RegisterVariable("bf_max_steer_diff" + vs, 0);
        RegisterVariable("bf_max_time_diff" + vs, 0);
        RegisterVariable("bf_inputs_fill_steer" + vs, false);
        RegisterVariable("bf_input_mod_enabled" + vs, true);
        RegisterVariable("bf_input_mod_algorithm" + vs, "basic");
        RegisterVariable("bf_range_min_input_count" + vs, 1);
        RegisterVariable("bf_range_max_input_count" + vs, 1);
        RegisterVariable("bf_range_min_steer" + vs, -65536);
        RegisterVariable("bf_range_max_steer" + vs, 65536);
        RegisterVariable("bf_range_min_time_diff" + vs, 0);
        RegisterVariable("bf_range_max_time_diff" + vs, 0);
        RegisterVariable("bf_range_fill_steer" + vs, false);
        RegisterVariable("bf_adv_steer_modify_count" + vs, 0);
        RegisterVariable("bf_adv_steer_min_time" + vs, 0);
        RegisterVariable("bf_adv_steer_max_time" + vs, 0);
        RegisterVariable("bf_adv_steer_max_diff" + vs, 0);
        RegisterVariable("bf_adv_steer_max_time_diff" + vs, 0);
        RegisterVariable("bf_adv_steer_fill" + vs, false);
        RegisterVariable("bf_adv_accel_modify_count" + vs, 0);
        RegisterVariable("bf_adv_accel_min_time" + vs, 0);
        RegisterVariable("bf_adv_accel_max_time" + vs, 0);
        RegisterVariable("bf_adv_accel_max_time_diff" + vs, 0);
        RegisterVariable("bf_adv_brake_modify_count" + vs, 0);
        RegisterVariable("bf_adv_brake_min_time" + vs, 0);
        RegisterVariable("bf_adv_brake_max_time" + vs, 0);
        RegisterVariable("bf_adv_brake_max_time_diff" + vs, 0);
        RegisterVariable("bf_advr_steer_min_input_count" + vs, 1);
        RegisterVariable("bf_advr_steer_max_input_count" + vs, 1);
        RegisterVariable("bf_advr_steer_min_time" + vs, 0);
        RegisterVariable("bf_advr_steer_max_time" + vs, 0);
        RegisterVariable("bf_advr_steer_min_steer" + vs, -65536);
        RegisterVariable("bf_advr_steer_max_steer" + vs, 65536);
        RegisterVariable("bf_advr_steer_min_time_diff" + vs, 0);
        RegisterVariable("bf_advr_steer_max_time_diff" + vs, 0);
        RegisterVariable("bf_advr_steer_fill" + vs, false);
        RegisterVariable("bf_advr_accel_min_input_count" + vs, 1);
        RegisterVariable("bf_advr_accel_max_input_count" + vs, 1);
        RegisterVariable("bf_advr_accel_min_time" + vs, 0);
        RegisterVariable("bf_advr_accel_max_time" + vs, 0);
        RegisterVariable("bf_advr_accel_min_time_diff" + vs, 0);
        RegisterVariable("bf_advr_accel_max_time_diff" + vs, 0);
        RegisterVariable("bf_advr_brake_min_input_count" + vs, 1);
        RegisterVariable("bf_advr_brake_max_input_count" + vs, 1);
        RegisterVariable("bf_advr_brake_min_time" + vs, 0);
        RegisterVariable("bf_advr_brake_max_time" + vs, 0);
        RegisterVariable("bf_advr_brake_min_time_diff" + vs, 0);
        RegisterVariable("bf_advr_brake_max_time_diff" + vs, 0);
    }
}

string HandleGetAllSettings(const string &in body)
{
    int slotCount = int(GetVariableDouble("bf_input_mod_count"));
    if (slotCount < 1) slotCount = 1;
    EnsureSlotVariablesRegistered(slotCount);

    string json = "{";

    // Controller active: check if the bfv2 controller is selected
    bool controllerActive = GetVariableString("controller") == "bfv2";
    json += JsonBool("controllerActive", controllerActive);

    // Target
    string targetId = GetVariableString("bf_target");
    json += "," + JsonString("target", targetId);
    json += "," + JsonString("targetTitle", GetBfTargetTitle());

    // Behavior
    json += ",\"behavior\":{";
    json += JsonString("resultFilename", GetVariableString("bf_result_filename"));
    json += "," + JsonInt("iterationsBeforeRestart", int(GetVariableDouble("bf_iterations_before_restart")));
    json += "," + JsonString("resultFolder", GetVariableString("bf_result_folder"));
    json += "," + JsonString("restartConditionScript", GetVariableString("bf_restart_condition_script"));
    json += "}";

    // Conditions
    json += ",\"conditions\":{";
    json += JsonFloat("speed", float(GetVariableDouble("bf_condition_speed")));
    json += "," + JsonInt("cps", int(GetVariableDouble("bf_condition_cps")));
    json += "," + JsonInt("trigger", int(GetVariableDouble("bf_condition_trigger")));
    json += "," + JsonString("conditionScript", GetVariableString("bf_condition_script"));
    json += "}";

    // Slots (slotCount already set above)
    json += "," + JsonInt("slotCount", slotCount);

    string slots = "[";
    for (int s = 0; s < slotCount; s++)
    {
        if (s > 0) slots += ",";
        string vs = GetInputModVarSuffix(uint(s));
        string algoId = GetVariableString("bf_input_mod_algorithm" + vs);
        bool enabled = (s == 0) ? true : GetVariableBool("bf_input_mod_enabled" + vs);

        slots += "{";
        slots += JsonBool("enabled", enabled);
        slots += "," + JsonString("algorithm", algoId);

        // Basic settings
        slots += ",\"basic\":{";
        slots += JsonInt("modifyCount", int(GetVariableDouble("bf_modify_count" + vs)));
        slots += "," + JsonInt("minTime", int(GetVariableDouble("bf_inputs_min_time" + vs)));
        slots += "," + JsonInt("maxTime", int(GetVariableDouble("bf_inputs_max_time" + vs)));
        slots += "," + JsonInt("maxSteerDiff", int(GetVariableDouble("bf_max_steer_diff" + vs)));
        slots += "," + JsonInt("maxTimeDiff", int(GetVariableDouble("bf_max_time_diff" + vs)));
        slots += "," + JsonBool("fillSteer", GetVariableBool("bf_inputs_fill_steer" + vs));
        slots += "}";

        // Range settings
        slots += ",\"range\":{";
        slots += JsonInt("minInputCount", int(GetVariableDouble("bf_range_min_input_count" + vs)));
        slots += "," + JsonInt("maxInputCount", int(GetVariableDouble("bf_range_max_input_count" + vs)));
        slots += "," + JsonInt("minTime", int(GetVariableDouble("bf_inputs_min_time" + vs)));
        slots += "," + JsonInt("maxTime", int(GetVariableDouble("bf_inputs_max_time" + vs)));
        slots += "," + JsonInt("minSteer", int(GetVariableDouble("bf_range_min_steer" + vs)));
        slots += "," + JsonInt("maxSteer", int(GetVariableDouble("bf_range_max_steer" + vs)));
        slots += "," + JsonInt("minTimeDiff", int(GetVariableDouble("bf_range_min_time_diff" + vs)));
        slots += "," + JsonInt("maxTimeDiff", int(GetVariableDouble("bf_range_max_time_diff" + vs)));
        slots += "," + JsonBool("fillSteer", GetVariableBool("bf_range_fill_steer" + vs));
        slots += "}";

        // Advanced Basic settings
        slots += ",\"advanced_basic\":{";
        slots += JsonInt("steerModifyCount", int(GetVariableDouble("bf_adv_steer_modify_count" + vs)));
        slots += "," + JsonInt("steerMinTime", int(GetVariableDouble("bf_adv_steer_min_time" + vs)));
        slots += "," + JsonInt("steerMaxTime", int(GetVariableDouble("bf_adv_steer_max_time" + vs)));
        slots += "," + JsonInt("steerMaxDiff", int(GetVariableDouble("bf_adv_steer_max_diff" + vs)));
        slots += "," + JsonInt("steerMaxTimeDiff", int(GetVariableDouble("bf_adv_steer_max_time_diff" + vs)));
        slots += "," + JsonBool("steerFill", GetVariableBool("bf_adv_steer_fill" + vs));
        slots += "," + JsonInt("accelModifyCount", int(GetVariableDouble("bf_adv_accel_modify_count" + vs)));
        slots += "," + JsonInt("accelMinTime", int(GetVariableDouble("bf_adv_accel_min_time" + vs)));
        slots += "," + JsonInt("accelMaxTime", int(GetVariableDouble("bf_adv_accel_max_time" + vs)));
        slots += "," + JsonInt("accelMaxTimeDiff", int(GetVariableDouble("bf_adv_accel_max_time_diff" + vs)));
        slots += "," + JsonInt("brakeModifyCount", int(GetVariableDouble("bf_adv_brake_modify_count" + vs)));
        slots += "," + JsonInt("brakeMinTime", int(GetVariableDouble("bf_adv_brake_min_time" + vs)));
        slots += "," + JsonInt("brakeMaxTime", int(GetVariableDouble("bf_adv_brake_max_time" + vs)));
        slots += "," + JsonInt("brakeMaxTimeDiff", int(GetVariableDouble("bf_adv_brake_max_time_diff" + vs)));
        slots += "}";

        // Advanced Range settings
        slots += ",\"advanced_range\":{";
        slots += JsonInt("steerMinInputCount", int(GetVariableDouble("bf_advr_steer_min_input_count" + vs)));
        slots += "," + JsonInt("steerMaxInputCount", int(GetVariableDouble("bf_advr_steer_max_input_count" + vs)));
        slots += "," + JsonInt("steerMinTime", int(GetVariableDouble("bf_advr_steer_min_time" + vs)));
        slots += "," + JsonInt("steerMaxTime", int(GetVariableDouble("bf_advr_steer_max_time" + vs)));
        slots += "," + JsonInt("steerMinSteer", int(GetVariableDouble("bf_advr_steer_min_steer" + vs)));
        slots += "," + JsonInt("steerMaxSteer", int(GetVariableDouble("bf_advr_steer_max_steer" + vs)));
        slots += "," + JsonInt("steerMinTimeDiff", int(GetVariableDouble("bf_advr_steer_min_time_diff" + vs)));
        slots += "," + JsonInt("steerMaxTimeDiff", int(GetVariableDouble("bf_advr_steer_max_time_diff" + vs)));
        slots += "," + JsonBool("steerFill", GetVariableBool("bf_advr_steer_fill" + vs));
        slots += "," + JsonInt("accelMinInputCount", int(GetVariableDouble("bf_advr_accel_min_input_count" + vs)));
        slots += "," + JsonInt("accelMaxInputCount", int(GetVariableDouble("bf_advr_accel_max_input_count" + vs)));
        slots += "," + JsonInt("accelMinTime", int(GetVariableDouble("bf_advr_accel_min_time" + vs)));
        slots += "," + JsonInt("accelMaxTime", int(GetVariableDouble("bf_advr_accel_max_time" + vs)));
        slots += "," + JsonInt("accelMinTimeDiff", int(GetVariableDouble("bf_advr_accel_min_time_diff" + vs)));
        slots += "," + JsonInt("accelMaxTimeDiff", int(GetVariableDouble("bf_advr_accel_max_time_diff" + vs)));
        slots += "," + JsonInt("brakeMinInputCount", int(GetVariableDouble("bf_advr_brake_min_input_count" + vs)));
        slots += "," + JsonInt("brakeMaxInputCount", int(GetVariableDouble("bf_advr_brake_max_input_count" + vs)));
        slots += "," + JsonInt("brakeMinTime", int(GetVariableDouble("bf_advr_brake_min_time" + vs)));
        slots += "," + JsonInt("brakeMaxTime", int(GetVariableDouble("bf_advr_brake_max_time" + vs)));
        slots += "," + JsonInt("brakeMinTimeDiff", int(GetVariableDouble("bf_advr_brake_min_time_diff" + vs)));
        slots += "," + JsonInt("brakeMaxTimeDiff", int(GetVariableDouble("bf_advr_brake_max_time_diff" + vs)));
        slots += "}";

        slots += "}";
    }
    slots += "]";
    json += ",\"slots\":" + slots;

    // Eval settings based on current target
    json += ",\"evalSettings\":{";
    if (targetId == "precisefinish")
    {
        // No extra settings
    }
    else if (targetId == "precisecheckpoint")
    {
        json += JsonInt("bf_target_cp", int(GetVariableDouble("bf_target_cp")));
    }
    else if (targetId == "precisetrigger")
    {
        json += JsonInt("bf_target_trigger", int(GetVariableDouble("bf_target_trigger")));
    }
    else if (targetId == "standardtrigger")
    {
        json += JsonInt("bf_stdtrigger_trigger", int(GetVariableDouble("bf_stdtrigger_trigger")));
        json += "," + JsonInt("bf_stdtrigger_weight", int(GetVariableDouble("bf_stdtrigger_weight")));
    }
    else if (targetId == "betterpoint")
    {
        json += JsonInt("bf_weight", int(GetVariableDouble("bf_weight")));
        vec3 tp = Text::ParseVec3(GetVariableString("bf_target_point"));
        json += "," + JsonVec3("bf_target_point", tp);
        json += "," + JsonInt("bf_eval_min_time", int(GetVariableDouble("bf_eval_min_time")));
        json += "," + JsonInt("bf_eval_max_time", int(GetVariableDouble("bf_eval_max_time")));
        json += "," + JsonFloat("bf_singlepoint_shift_threshold", float(GetVariableDouble("bf_singlepoint_shift_threshold")));
        json += "," + JsonFloat("bf_condition_distance", float(GetVariableDouble("bf_condition_distance")));
        json += "," + JsonBool("bf_ignore_same_speed", GetVariableBool("bf_ignore_same_speed"));
    }
    else if (targetId == "velocity")
    {
        json += JsonString("bf_velocity_type", GetVariableString("bf_velocity_type"));
        vec3 vFrom = Text::ParseVec3(GetVariableString("bf_velocity_from"));
        json += "," + JsonVec3("bf_velocity_from", vFrom);
        vec3 vTo = Text::ParseVec3(GetVariableString("bf_velocity_to"));
        json += "," + JsonVec3("bf_velocity_to", vTo);
        json += "," + JsonFloat("bf_velocity_min_percent", float(GetVariableDouble("bf_velocity_min_percent")));
        json += "," + JsonInt("bf_eval_min_time", int(GetVariableDouble("bf_eval_min_time")));
        json += "," + JsonInt("bf_eval_max_time", int(GetVariableDouble("bf_eval_max_time")));
    }
    else if (targetId == "distance_target")
    {
        json += JsonInt("dist_bf_target_type", int(GetVariableDouble("dist_bf_target_type")));
        json += "," + JsonInt("dist_bf_target_cp_index", int(GetVariableDouble("dist_bf_target_cp_index")));
        json += "," + JsonBool("dist_bf_show_cp_numbers", GetVariableBool("dist_bf_show_cp_numbers"));
        json += "," + JsonBool("dist_bf_shift_cp_eval", GetVariableBool("dist_bf_shift_cp_eval"));
        json += "," + JsonBool("dist_bf_shift_finish_eval", GetVariableBool("dist_bf_shift_finish_eval"));
        json += "," + JsonInt("dist_bf_bf_time_from", int(GetVariableDouble("dist_bf_bf_time_from")));
        json += "," + JsonInt("dist_bf_bf_time_to", int(GetVariableDouble("dist_bf_bf_time_to")));
        json += "," + JsonInt("dist_bf_constraint_trigger_index", int(GetVariableDouble("dist_bf_constraint_trigger_index")));
    }
    else if (targetId == "uberbug_target")
    {
        json += JsonString("uber_bf_uberbug_mode", GetVariableString("uber_bf_uberbug_mode"));
        json += "," + JsonString("uber_bf_uberbug_find_mode", GetVariableString("uber_bf_uberbug_find_mode"));
        json += "," + JsonInt("uber_bf_uberbug_amount", int(GetVariableDouble("uber_bf_uberbug_amount")));
        json += "," + JsonString("uber_bf_uberbug_result_file", GetVariableString("uber_bf_uberbug_result_file"));
        vec3 up1 = Text::ParseVec3(GetVariableString("uber_bf_uberbug_point1"));
        json += "," + JsonVec3("uber_bf_uberbug_point1", up1);
        vec3 up2 = Text::ParseVec3(GetVariableString("uber_bf_uberbug_point2"));
        json += "," + JsonVec3("uber_bf_uberbug_point2", up2);
        json += "," + JsonFloat("uber_bf_uberbug_threshold", float(GetVariableDouble("uber_bf_uberbug_threshold")));
        json += "," + JsonInt("uber_bf_bf_time_from", int(GetVariableDouble("uber_bf_bf_time_from")));
        json += "," + JsonInt("uber_bf_bf_time_to", int(GetVariableDouble("uber_bf_bf_time_to")));
        json += "," + JsonFloat("uber_bf_uberbug_min_speed", float(GetVariableDouble("uber_bf_uberbug_min_speed")));
    }
    else if (targetId == "clbf")
    {
        vec3 clPos = Text::ParseVec3(GetVariableString("clbf_bf_target_position"));
        json += JsonVec3("clbf_bf_target_position", clPos);
        json += "," + JsonFloat("clbf_bf_target_rotation_yaw", float(GetVariableDouble("clbf_bf_target_rotation_yaw")));
        json += "," + JsonFloat("clbf_bf_target_rotation_pitch", float(GetVariableDouble("clbf_bf_target_rotation_pitch")));
        json += "," + JsonFloat("clbf_bf_target_rotation_roll", float(GetVariableDouble("clbf_bf_target_rotation_roll")));
        json += "," + JsonInt("clbf_bf_weight", int(GetVariableDouble("clbf_bf_weight")));
        json += "," + JsonInt("clbf_bf_eval_min_time", int(GetVariableDouble("clbf_bf_eval_min_time")));
        json += "," + JsonInt("clbf_bf_eval_max_time", int(GetVariableDouble("clbf_bf_eval_max_time")));
    }
    else if (targetId == "time")
    {
        json += JsonInt("timebf_min_time", int(GetVariableDouble("timebf_min_time")));
    }
    else if (targetId == "customtarget")
    {
        json += JsonString("bf_customtarget_script", GetVariableString("bf_customtarget_script"));
        json += "," + JsonInt("bf_customtarget_eval_min_time", int(GetVariableDouble("bf_customtarget_eval_min_time")));
        json += "," + JsonInt("bf_customtarget_eval_max_time", int(GetVariableDouble("bf_customtarget_eval_max_time")));
    }
    json += "}";

    // Available evaluations
    string evals = "[";
    for (uint i = 0; i < evaluations.Length; i++)
    {
        if (i > 0) evals += ",";
        evals += "{" + JsonString("id", evaluations[i].identifier);
        evals += "," + JsonString("title", evaluations[i].title) + "}";
    }
    evals += "]";
    json += ",\"evaluations\":" + evals;

    // Available algorithms
    string algos = "[";
    for (uint i = 0; i < g_inputModAlgorithms.Length; i++)
    {
        if (i > 0) algos += ",";
        algos += "{" + JsonString("id", g_inputModAlgorithms[i].identifier);
        algos += "," + JsonString("name", g_inputModAlgorithms[i].name) + "}";
    }
    algos += "]";
    json += ",\"algorithms\":" + algos;

    // Triggers
    string trigs = "[";
    array<int>@ triggerIds = GetTriggerIds();
    if (triggerIds !is null)
    {
        for (uint i = 0; i < triggerIds.Length; i++)
        {
            if (i > 0) trigs += ",";
            Trigger3D t = GetTrigger(triggerIds[i]);
            trigs += "{" + JsonInt("index", triggerIds[i]);
            trigs += "," + JsonVec3("position", t.Position) + "}";
        }
    }
    trigs += "]";
    json += ",\"triggers\":" + trigs;

    json += "}";
    return json;
}

string HandlePostSetVar(const string &in body)
{
    string name = GetFormValue(body, "name");
    string value = GetFormValue(body, "value");

    if (name.Length == 0)
        return "{\"ok\":false,\"error\":\"missing name\"}";

    // Look up variable type
    array<VariableInfo>@ vars = ListVariables();
    VariableType varType = VariableType::Double;
    bool found = false;
    for (uint i = 0; i < vars.Length; i++)
    {
        if (vars[i].Name == name)
        {
            varType = vars[i].Type;
            found = true;
            break;
        }
    }

    bool ok = false;
    if (!found)
    {
        ok = SetVariable(name, value);
    }
    else if (varType == VariableType::Double)
    {
        double dval = Text::ParseFloat(value);
        ok = SetVariable(name, dval);
    }
    else if (varType == VariableType::String)
    {
        ok = SetVariable(name, value);
    }
    else if (varType == VariableType::Boolean)
    {
        bool bval = (value == "true" || value == "1");
        ok = SetVariable(name, bval);
    }

    if (ok)
        return "{\"ok\":true}";
    else
        return "{\"ok\":false,\"error\":\"SetVariable failed\"}";
}

string HandlePostAddSlot(const string &in body)
{
    int newCount = int(GetVariableDouble("bf_input_mod_count")) + 1;
    EnsureSlotVariablesRegistered(newCount);
    AddInputModificationSettings();
    return "{\"ok\":true}";
}

string HandlePostRemoveSlot(const string &in body)
{
    string indexStr = GetFormValue(body, "index");
    if (indexStr.Length == 0)
        return "{\"ok\":false,\"error\":\"missing index\"}";

    int idx = int(Text::ParseInt(indexStr));
    if (idx <= 0)
        return "{\"ok\":false,\"error\":\"index must be > 0\"}";

    RemoveInputModificationSettings(uint(idx));
    return "{\"ok\":true}";
}

string HandleCopyPosition(const string &in body)
{
    SimulationManager@ sim = GetSimulationManager();
    if (sim is null)
        return "{\"error\":\"no simulation manager\"}";

    TM::HmsDyna@ dyna = sim.Dyna;
    if (dyna is null)
        return "{\"error\":\"no dyna state\"}";

    vec3 vPos = dyna.CurrentState.Location.Position;

    string json = "{";
    json += JsonVec3("vehiclePosition", vPos);
    json += ",\"cameraPosition\":null";
    json += "}";
    return json;
}

string HandleDeleteSession(const string &in body)
{
    string id = GetFormValue(body, "id");
    if (id.Length == 0)
        return "{\"ok\":false,\"error\":\"missing id\"}";

    int idNum = int(Text::ParseInt(id));
    if (idNum <= 0)
        return "{\"ok\":false,\"error\":\"invalid id\"}";

    if (idNum == currentSessionId)
        return "{\"ok\":false,\"error\":\"cannot delete active session\"}";

    string content = FileRead(DATA_FOLDER + "/sessions.txt");
    if (content.Length == 0)
        return "{\"ok\":false,\"error\":\"no sessions\"}";

    array<string>@ lines = content.Split("\n");
    string newContent = "";
    bool found = false;
    for (uint i = 0; i < lines.Length; i++)
    {
        if (lines[i].Length == 0) continue;
        array<string>@ parts = lines[i].Split("|");
        if (parts.Length >= 1 && parts[0] == id)
        {
            found = true;
            continue;
        }
        if (newContent.Length > 0) newContent += "\n";
        newContent += lines[i];
    }

    if (!found)
        return "{\"ok\":false,\"error\":\"not found\"}";

    if (newContent.Length > 0) newContent += "\n";
    FileWrite(DATA_FOLDER + "/sessions.txt", newContent);

    FileWrite(DATA_FOLDER + "/sessions/" + id + "/log.txt", "");
    FileWrite(DATA_FOLDER + "/sessions/" + id + "/improvements.txt", "");

    return "{\"ok\":true}";
}

string HandlePostSetBatch(const string &in body)
{
    array<VariableInfo>@ vars = ListVariables();
    array<string>@ lines = body.Split("\n");
    int setCount = 0;
    for (uint i = 0; i < lines.Length; i++)
    {
        string line = lines[i];
        if (line.Length == 0) continue;
        int eq = line.FindFirst("=");
        if (eq <= 0) continue;
        string name = line.Substr(0, eq);
        string value = line.Substr(uint(eq + 1));

        VariableType varType = VariableType::String;
        bool found = false;
        if (vars !is null)
        {
            for (uint v = 0; v < vars.Length; v++)
            {
                if (vars[v].Name == name)
                {
                    varType = vars[v].Type;
                    found = true;
                    break;
                }
            }
        }
        if (found)
        {
            if (varType == VariableType::Double)
                SetVariable(name, double(Text::ParseFloat(value)));
            else if (varType == VariableType::Boolean)
                SetVariable(name, value == "true" || value == "1");
            else
                SetVariable(name, value);
        }
        else
        {
            SetVariable(name, value);
        }
        setCount++;
    }
    return "{\"ok\":true,\"count\":" + Text::FormatInt(setCount) + "}";
}
string HandleBfDashboard(const string &in body)
{
    string h = "<!DOCTYPE html><html lang='en'><head>";
    h += "<meta charset='utf-8'>";
    h += "<meta name='viewport' content='width=device-width,initial-scale=1'>";
    h += "<title>BfV2 Dashboard</title>";
    h += "<style>" + BfDashCSS() + "</style>";
    h += "</head><body>";
    h += "<header><h1>BfV2 Dashboard</h1><span id='conn' class='badge'>Connecting...</span></header>";
    h += "<main>";

    // Status panel
    h += "<section class='panel' id='status'>";
    h += "<h2>Status</h2>";
    h += "<div class='grid2'>";
    h += "<div class='stat'><label>State</label><span id='bfState' class='badge'>-</span></div>";
    h += "<div class='stat'><label>Phase</label><span id='bfPhase' class='badge'>-</span></div>";
    h += "<div class='stat'><label>Target</label><span id='bfTarget'>-</span></div>";
    h += "<div class='stat'><label>Elapsed</label><span id='bfElapsed'>-</span></div>";
    h += "<div class='stat'><label>Iterations</label><span id='bfIter' class='big'>0</span></div>";
    h += "<div class='stat'><label>Iter/sec</label><span id='bfIterSec' class='big'>0</span></div>";
    h += "<div class='stat'><label>Restarts</label><span id='bfRestarts'>0</span></div>";
    h += "<div class='stat'><label>Improvements</label><span id='bfImpCount'>0</span></div>";
    h += "</div>";
    h += "</section>";

    // Map panel
    h += "<section class='panel' id='mapinfo'>";
    h += "<h2>Map</h2>";
    h += "<div class='stat'><label>Name</label><span id='mapName'>-</span></div>";
    h += "<div class='stat'><label>Author</label><span id='mapAuthor'>-</span></div>";
    h += "<div class='stat'><label>UID</label><span id='mapUid' class='mono'>-</span></div>";
    h += "</section>";

    // Settings panel (wide, full collapsible)
    h += "<section class='panel wide' id='settings'>";
    h += "<h2>Settings</h2>";
    h += "<div id='ctrlBadge'></div>";
    h += "<div id='applyBar' class='apply-bar' style='display:none'>";
    h += "<span class='desynced-badge'>Desynchronized</span>";
    h += "<span id='dirtyCount' class='dirty-count'>No pending changes</span>";
    h += "<button id='btnDiscard' class='btn-action' disabled>Discard</button>";
    h += "<button id='btnApply' class='btn-action btn-apply' disabled>Apply All</button>";
    h += "</div>";

    // Optimization section
    h += "<details id='secOptimization' open>";
    h += "<summary>Optimization</summary>";
    h += "<div class='sec-body'>";
    h += "<div class='field-row'><label>Target</label><select id='optTarget' data-var='bf_target'></select></div>";
    h += "<div id='evalFields'></div>";
    h += "</div></details>";

    // Behavior section
    h += "<details id='secBehavior'>";
    h += "<summary>Behavior</summary>";
    h += "<div class='sec-body'>";
    h += "<div class='field-row'><label>Result Filename</label><input type='text' id='behFile' data-var='bf_result_filename'></div>";
    h += "<div class='field-row'><label>Iterations Before Restart</label><input type='number' id='behIter' data-var='bf_iterations_before_restart' min='0' step='1'></div>";
    h += "<div class='field-row'><label>Result Folder</label><input type='text' id='behFolder' data-var='bf_result_folder'></div>";
    h += "<div class='field-row full'><label>Restart Condition Script</label><textarea id='behRestartScript' data-var='bf_restart_condition_script' rows='3'></textarea></div>";
    h += "</div></details>";

    // Conditions section
    h += "<details id='secConditions'>";
    h += "<summary>Conditions</summary>";
    h += "<div class='sec-body'>";
    h += "<div class='field-row'><label>Min Speed</label><input type='number' id='condSpeed' data-var='bf_condition_speed' min='0' step='0.1'></div>";
    h += "<div class='field-row'><label>Min CPs</label><input type='number' id='condCps' data-var='bf_condition_cps' min='0' step='1'></div>";
    h += "<div class='field-row'><label>Trigger</label><select id='condTrigger' data-var='bf_condition_trigger'></select></div>";
    h += "<div class='field-row full'><label>Condition Script</label><textarea id='condScript' data-var='bf_condition_script' rows='3'></textarea></div>";
    h += "</div></details>";

    // Input Modification section
    h += "<details id='secInputMod'>";
    h += "<summary>Input Modification</summary>";
    h += "<div class='sec-body'>";
    h += "<div id='slotsContainer'></div>";
    h += "<button id='btnAddSlot' class='btn-action'>+ Add Slot</button>";
    h += "</div></details>";

    h += "</section>";

    // Session history panel (wide)
    h += "<section class='panel wide' id='history'>";
    h += "<div class='tab-bar' id='sessionTabs'></div>";
    h += "<div class='sub-tabs'>";
    h += "<button class='sub-tab active' id='tabImp'>Improvements</button>";
    h += "<button class='sub-tab' id='tabLog'>Log</button>";
    h += "</div>";
    h += "<div id='historyContent' class='history-content'></div>";
    h += "</section>";

    h += "</main>";
    h += "<script>";
    h += BfDashJS_Helpers();
    h += BfDashJS_Status();
    h += BfDashJS_Settings();
    h += BfDashJS_Sessions();
    h += "</script>";
    h += "</body></html>";
    return h;
}

// ============================================================
// CSS
// ============================================================

string BfDashCSS()
{
    string c = "*{box-sizing:border-box;margin:0;padding:0}";
    c += "body{font-family:system-ui,-apple-system,sans-serif;background:#0d1117;color:#c9d1d9;min-height:100vh}";
    c += "header{background:#161b22;padding:1rem 2rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #30363d}";
    c += "header h1{font-size:1.2rem;color:#f0883e}";
    c += "main{display:grid;grid-template-columns:1fr 1fr;gap:1rem;padding:1rem 2rem;max-width:1400px;margin:0 auto}";
    c += ".panel{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:1.2rem}";
    c += ".panel.wide{grid-column:1/-1}";
    c += ".panel h2{color:#f0883e;font-size:1rem;margin-bottom:0.8rem;padding-bottom:0.4rem;border-bottom:1px solid #21262d}";
    c += ".panel h3{color:#8b949e;font-size:0.8rem;text-transform:uppercase;margin:0.8rem 0 0.3rem}";
    c += ".grid2{display:grid;grid-template-columns:1fr 1fr;gap:0.5rem}";
    c += ".stat{display:flex;flex-direction:column;gap:0.15rem}";
    c += ".stat label{color:#8b949e;font-size:0.75rem;text-transform:uppercase}";
    c += ".stat span{font-size:1rem}";
    c += ".big{font-size:1.6rem !important;font-weight:700;color:#fff}";
    c += ".badge{background:#21262d;padding:0.15rem 0.5rem;border-radius:4px;font-size:0.8rem;display:inline-block}";
    c += ".badge.running{background:#3fb95030;color:#3fb950}";
    c += ".badge.idle{background:#21262d;color:#8b949e}";
    c += ".badge.initial{background:#58a6ff30;color:#58a6ff}";
    c += ".badge.search{background:#d2992230;color:#d29922}";
    c += ".badge.warn{background:#d2992230;color:#d29922;margin-bottom:0.6rem}";
    c += ".mono{font-family:monospace;font-size:0.8rem !important;word-break:break-all}";

    // Collapsible sections
    c += "details{border:1px solid #21262d;border-radius:6px;margin-bottom:0.6rem}";
    c += "details[open]{border-color:#30363d}";
    c += "summary{cursor:pointer;padding:0.5rem 0.7rem;font-size:0.85rem;font-weight:600;color:#f0883e;background:#0d1117;border-radius:5px;user-select:none;list-style:none}";
    c += "summary::-webkit-details-marker{display:none}";
    c += "summary::before{content:'\\25B6';display:inline-block;margin-right:0.5rem;font-size:0.65rem;transition:transform 0.15s}";
    c += "details[open]>summary::before{transform:rotate(90deg)}";
    c += "summary:hover{background:#161b22}";
    c += ".sec-body{padding:0.7rem;display:grid;grid-template-columns:1fr 1fr;gap:0.5rem 1rem;overflow:hidden}";

    // Field rows
    c += ".field-row{display:flex;flex-direction:column;gap:0.15rem;min-width:0}";
    c += ".field-row.full{grid-column:1/-1}";
    c += ".field-row label{color:#8b949e;font-size:0.7rem;text-transform:uppercase}";
    c += ".field-row input,.field-row select,.field-row textarea{background:#0d1117;border:1px solid #30363d;border-radius:4px;color:#c9d1d9;padding:0.3rem 0.5rem;font-size:0.8rem;font-family:inherit;width:100%;max-width:100%;min-width:0}";
    c += ".field-row input:focus,.field-row select:focus,.field-row textarea:focus{outline:none;border-color:#f0883e}";
    c += ".field-row textarea{font-family:monospace;resize:vertical;min-height:2.5rem}";
    c += ".field-row input[type=number]{-moz-appearance:textfield}";
    c += ".field-row input[type=range]{padding:0;height:1.2rem}";

    // Vec3 row
    c += ".vec3-row{display:flex;gap:0.3rem;align-items:center}";
    c += ".vec3-row input{flex:1;min-width:0}";
    c += ".vec3-row .btn-sm{flex:0 0 auto}";

    // Inline row
    c += ".inline-row{display:flex;gap:0.4rem;align-items:center}";
    c += ".inline-row label{white-space:nowrap}";

    // Checkbox wrapper
    c += ".chk-row{display:flex;align-items:center;gap:0.4rem;padding:0.15rem 0}";
    c += ".chk-row input[type=checkbox]{width:1rem;height:1rem;accent-color:#f0883e}";
    c += ".chk-row label{color:#c9d1d9;font-size:0.8rem}";

    // Slot card
    c += ".slot-card{background:#0d1117;border:1px solid #30363d;border-radius:6px;margin-bottom:0.5rem;overflow:hidden}";
    c += ".slot-hdr{display:flex;align-items:center;gap:0.5rem;padding:0.4rem 0.6rem;background:#161b22;border-bottom:1px solid #21262d}";
    c += ".slot-hdr .slot-title{font-size:0.85rem;font-weight:600;color:#c9d1d9;flex:1}";
    c += ".slot-body{padding:0.6rem;display:grid;grid-template-columns:1fr 1fr;gap:0.5rem 1rem}";

    // Sub-section within a slot (for advanced algorithm sub-types)
    c += ".sub-sec{grid-column:1/-1;border:1px solid #21262d;border-radius:4px;padding:0.5rem;margin-top:0.2rem}";
    c += ".sub-sec-title{font-size:0.75rem;font-weight:600;color:#8b949e;text-transform:uppercase;margin-bottom:0.4rem}";
    c += ".sub-sec-grid{display:grid;grid-template-columns:1fr 1fr;gap:0.4rem 1rem}";

    // Buttons
    c += ".btn-action{background:#21262d;color:#c9d1d9;border:1px solid #30363d;border-radius:4px;padding:0.3rem 0.8rem;cursor:pointer;font-size:0.8rem}";
    c += ".btn-action:hover{background:#30363d}";
    c += ".btn-danger{background:#f8514920;color:#f85149;border:1px solid #f8514940}";
    c += ".btn-danger:hover{background:#f8514940}";
    c += ".btn-sm{background:#21262d;color:#c9d1d9;border:1px solid #30363d;border-radius:4px;padding:0.2rem 0.5rem;cursor:pointer;font-size:0.7rem}";
    c += ".btn-sm:hover{background:#30363d}";

    // Range display
    c += ".range-wrap{display:flex;align-items:center;gap:0.4rem;min-width:0}";
    c += ".range-wrap input[type=range]{flex:1;min-width:0}";
    c += ".range-wrap .range-val{font-size:0.8rem;color:#c9d1d9;min-width:3rem;text-align:right;font-family:monospace}";

    // Session tabs
    c += ".tab-bar{display:flex;gap:0.3rem;margin-bottom:0.5rem;flex-wrap:wrap}";
    c += ".tab-btn{background:#21262d;color:#8b949e;border:1px solid #30363d;padding:0.3rem 0.8rem;border-radius:6px 6px 0 0;cursor:pointer;font-size:0.8rem}";
    c += ".tab-btn:hover{background:#30363d}";
    c += ".tab-btn.active{background:#161b22;color:#f0883e;border-bottom-color:#161b22}";
    c += ".sub-tabs{display:flex;gap:0.3rem;margin-bottom:0.5rem}";
    c += ".sub-tab{background:none;color:#8b949e;border:none;padding:0.3rem 0.8rem;cursor:pointer;font-size:0.8rem;border-bottom:2px solid transparent}";
    c += ".sub-tab:hover{color:#c9d1d9}";
    c += ".sub-tab.active{color:#f0883e;border-bottom-color:#f0883e}";

    // History
    c += ".history-content{max-height:400px;overflow-y:auto}";
    c += ".imp-row{display:grid;grid-template-columns:2.5rem 4rem 1fr 4rem 3rem;gap:0.5rem;padding:0.3rem 0;border-bottom:1px solid #21262d;font-size:0.8rem;align-items:center}";
    c += ".imp-row.hdr{color:#8b949e;font-weight:600;border-bottom:2px solid #30363d}";
    c += ".log-entry{padding:0.15rem 0;font-family:monospace;font-size:0.8rem;line-height:1.5}";
    c += ".log-entry .lt{color:#8b949e;margin-right:0.5rem}";
    c += ".log-entry .lm{color:#c9d1d9}";

    c += ".dirty { border-left: 3px solid #d29922 !important; padding-left: 0.3rem; }";
    c += ".apply-bar { display:flex; align-items:center; gap:0.6rem; padding:0.5rem 0.7rem; margin-bottom:0.6rem; background:#d2992215; border:1px solid #d2992240; border-radius:6px; }";
    c += ".desynced-badge { background:#d2992230; color:#d29922; padding:0.15rem 0.5rem; border-radius:4px; font-size:0.8rem; font-weight:600; }";
    c += ".dirty-count { color:#8b949e; font-size:0.8rem; flex:1; }";
    c += ".btn-apply { background:#d2992230; color:#d29922; border-color:#d2992240; }";
    c += ".btn-apply:hover:not(:disabled) { background:#d2992250; }";
    c += ".btn-action:disabled { opacity:0.4; cursor:default; }";
    c += ".toast { position:fixed; bottom:1.5rem; left:50%; transform:translateX(-50%) translateY(20px); background:#21262d; color:#c9d1d9; border:1px solid #30363d; border-radius:6px; padding:0.5rem 1rem; font-size:0.85rem; opacity:0; transition:opacity 0.3s,transform 0.3s; z-index:1000; pointer-events:none; }";
    c += ".toast.show { opacity:1; transform:translateX(-50%) translateY(0); }";
    c += ".tab-del { background:none; border:none; color:#8b949e; font-size:0.7rem; cursor:pointer; margin-left:0.3rem; padding:0 0.2rem; line-height:1; }";
    c += ".tab-del:hover { color:#f85149; }";

    c += "@media(max-width:700px){main{grid-template-columns:1fr}.sec-body{grid-template-columns:1fr}.slot-body{grid-template-columns:1fr}.sub-sec-grid{grid-template-columns:1fr}.grid2{grid-template-columns:1fr}}";

    return c;
}

// ============================================================
// JS: Helper functions (format, parse, API send)
// ============================================================

string BfDashJS_Helpers()
{
    string j = "";

    // State variables for buffered mode
    j += "var bfIsRunning = null;";
    j += "var dirtyVars = {};";
    j += "var serverSnapshot = {};";

    // Format milliseconds to m:ss.cc
    j += "function fmtTime(ms){";
    j += "if(ms===0||ms===null||ms===undefined)return '0:00.00';";
    j += "var neg=ms<0;if(neg)ms=-ms;";
    j += "var totalCs=Math.floor(ms/10);";
    j += "var cs=totalCs%100;var totalSec=Math.floor(totalCs/100);";
    j += "var sec=totalSec%60;var min=Math.floor(totalSec/60);";
    j += "var r=min+':'+(sec<10?'0':'')+sec+'.'+(cs<10?'0':'')+cs;";
    j += "return neg?'-'+r:r;}";

    // Parse m:ss.cc or plain number to ms
    j += "function parseTime(s){";
    j += "s=s.trim();if(s==='')return 0;";
    j += "if(/^-?\\d+$/.test(s))return parseInt(s,10);";
    j += "var neg=false;if(s[0]==='-'){neg=true;s=s.substring(1);}";
    j += "var parts=s.split(':');var min=0;var rest=s;";
    j += "if(parts.length===2){min=parseInt(parts[0],10)||0;rest=parts[1];}";
    j += "var secParts=rest.split('.');var sec=parseInt(secParts[0],10)||0;";
    j += "var cs=0;if(secParts.length>1){var f=secParts[1];if(f.length===1)f+='0';cs=parseInt(f.substring(0,2),10)||0;}";
    j += "var ms=(min*60+sec)*1000+cs*10;return neg?-ms:ms;}";

    // Duration formatter (for elapsed time)
    j += "function fmtDur(ms){if(ms<1000)return ms+'ms';var s=ms/1000;var sr=Math.round(s*10)/10;if(sr<60)return sr.toFixed(1)+'s';var m=Math.floor(s/60);var sec=Math.floor(s%60);return m+'m '+sec+'s';}";

    // Number formatter
    j += "function fmtNum(n){return n.toLocaleString();}";

    // Seconds formatter (for log timestamps)
    j += "function fmtSec(s){if(s<60)return s.toFixed(1)+'s';var m=Math.floor(s/60);return m+'m '+((s%60).toFixed(1))+'s';}";

    // Script text conversions (colon <-> newline)
    j += "function scriptToDisplay(s){if(!s)return '';return s.split(':').join('\\n');}";
    j += "function displayToScript(s){if(!s)return '';return s.split('\\n').join(':');}";

    // POST /api/bf/set helper (mode-aware: buffers during BF, immediate otherwise)
    j += "function setVar(name, value) {";
    j += "var sv = String(value);";
    j += "if (bfIsRunning === null) return;";
    j += "if (!bfIsRunning) {";
    j += "fetch('/api/bf/set', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},";
    j += "body:'name='+encodeURIComponent(name)+'&value='+encodeURIComponent(sv)});";
    j += "return;}";
    j += "if (serverSnapshot[name] !== undefined && serverSnapshot[name] === sv) {";
    j += "delete dirtyVars[name];";
    j += "} else {";
    j += "dirtyVars[name] = sv;}";
    j += "markFieldDirty(name, name in dirtyVars);";
    j += "updateApplyBar();}";

    // POST helper for add-slot / remove-slot (clears slot-related dirty vars on structural changes)
    j += "function postAction(url, bodyStr) {";
    j += "fetch(url, {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:bodyStr||''});";
    j += "if (bfIsRunning && (url.indexOf('add-slot') !== -1 || url.indexOf('remove-slot') !== -1)) {";
    j += "var keys = Object.keys(dirtyVars);";
    j += "for (var i=0; i<keys.length; i++) {";
    j += "if (keys[i].indexOf('bf_modify') === 0 || keys[i].indexOf('bf_inputs') === 0 ||";
    j += "keys[i].indexOf('bf_max_') === 0 || keys[i].indexOf('bf_range') === 0 ||";
    j += "keys[i].indexOf('bf_adv') === 0 || keys[i].indexOf('bf_input_mod') === 0) {";
    j += "var row = document.querySelector('[data-var=\"'+keys[i]+'\"]');";
    j += "if (row) { var r2 = row.closest('.field-row')||row.closest('.chk-row'); if(r2) r2.classList.remove('dirty'); }";
    j += "delete dirtyVars[keys[i]];}}";
    j += "updateApplyBar();";
    j += "showToast('Slot changed. Slot-related pending edits cleared.');}}";

    // Safe set textContent
    j += "function setText(id,txt){var el=document.getElementById(id);if(el)el.textContent=txt;}";

    // Check if element is focused
    j += "function isFocused(el){return document.activeElement===el;}";

    // Set field value only if not focused (dirty-aware: skips fields with local dirty edits during BF)
    j += "function setField(el, val) {";
    j += "if (!el || isFocused(el)) return;";
    j += "var vn = el.getAttribute('data-var');";
    j += "if (bfIsRunning && vn && (vn in dirtyVars)) return;";
    j += "if (el.tagName === 'SELECT') el.value = String(val);";
    j += "else if (el.type === 'checkbox') el.checked = !!val;";
    j += "else {";
    j += "el.value = String(val);";
    j += "if (el.type === 'range') {";
    j += "var ev = el.closest('.range-wrap');";
    j += "if (ev) { var sp = ev.querySelector('.range-val'); if (sp) sp.textContent = String(val); }}}}";

    // Dirty field marking helpers
    j += "function markFieldDirty(varName, isDirty) {";
    j += "var els = document.querySelectorAll('[data-var=\"'+varName+'\"]');";
    j += "for (var i=0; i<els.length; i++) {";
    j += "var row = els[i].closest('.field-row') || els[i].closest('.chk-row') || els[i].closest('.vec3-row') || els[i].closest('.range-wrap');";
    j += "if (row) { if (isDirty) row.classList.add('dirty'); else row.classList.remove('dirty'); }}}";

    j += "function markAllClean() {";
    j += "var els = document.querySelectorAll('.dirty');";
    j += "for (var i=0; i<els.length; i++) els[i].classList.remove('dirty');}";

    j += "function updateApplyBar() {";
    j += "var bar = document.getElementById('applyBar');";
    j += "if (!bar) return;";
    j += "var count = Object.keys(dirtyVars).length;";
    j += "if (!bfIsRunning) { bar.style.display = 'none'; return; }";
    j += "bar.style.display = 'flex';";
    j += "document.getElementById('dirtyCount').textContent = count > 0 ? count + ' pending change' + (count > 1 ? 's' : '') : 'No pending changes';";
    j += "document.getElementById('btnApply').disabled = (count === 0);";
    j += "document.getElementById('btnDiscard').disabled = (count === 0);}";

    j += "function showToast(msg) {";
    j += "var t = document.createElement('div');";
    j += "t.className = 'toast';";
    j += "t.textContent = msg;";
    j += "document.body.appendChild(t);";
    j += "setTimeout(function(){ t.classList.add('show'); }, 10);";
    j += "setTimeout(function(){ t.classList.remove('show'); setTimeout(function(){ t.remove(); }, 300); }, 3000);}";

    // Create a field-row div
    j += "function mkFieldRow(labelText,inputEl,full){";
    j += "var d=document.createElement('div');d.className='field-row'+(full?' full':'');";
    j += "var lb=document.createElement('label');lb.textContent=labelText;";
    j += "d.appendChild(lb);d.appendChild(inputEl);return d;}";

    // Create a number input
    j += "function mkNum(varName,min,max,step){";
    j += "var inp=document.createElement('input');inp.type='number';inp.setAttribute('data-var',varName);";
    j += "if(min!==undefined&&min!==null)inp.min=min;if(max!==undefined&&max!==null)inp.max=max;";
    j += "inp.step=step||'1';";
    j += "inp.addEventListener('blur',function(){setVar(varName,this.value);});return inp;}";

    // Create a time input (displays m:ss.cc, stores ms integer)
    j += "function mkTime(varName){";
    j += "var inp=document.createElement('input');inp.type='text';inp.setAttribute('data-var',varName);";
    j += "inp.setAttribute('data-time','1');inp.placeholder='0:00.00';";
    j += "inp.addEventListener('blur',function(){var ms=parseTime(this.value);this.value=fmtTime(ms);setVar(varName,ms);});return inp;}";

    // Create a text input
    j += "function mkText(varName){";
    j += "var inp=document.createElement('input');inp.type='text';inp.setAttribute('data-var',varName);";
    j += "inp.addEventListener('blur',function(){setVar(varName,this.value);});return inp;}";

    // Create a textarea (for scripts)
    j += "function mkScript(varName){";
    j += "var ta=document.createElement('textarea');ta.setAttribute('data-var',varName);ta.rows=3;";
    j += "ta.setAttribute('data-script','1');";
    j += "ta.addEventListener('blur',function(){setVar(varName,displayToScript(this.value));});return ta;}";

    // Create a checkbox
    j += "function mkCheck(varName,labelText){";
    j += "var wrap=document.createElement('div');wrap.className='chk-row';";
    j += "var cb=document.createElement('input');cb.type='checkbox';cb.setAttribute('data-var',varName);cb.id='chk_'+varName;";
    j += "cb.addEventListener('change',function(){setVar(varName,this.checked?'true':'false');});";
    j += "var lb=document.createElement('label');lb.setAttribute('for','chk_'+varName);lb.textContent=labelText;";
    j += "wrap.appendChild(cb);wrap.appendChild(lb);return wrap;}";

    // Create a select
    j += "function mkSelect(varName,options){";
    j += "var sel=document.createElement('select');sel.setAttribute('data-var',varName);";
    j += "for(var i=0;i<options.length;i++){var o=document.createElement('option');o.value=options[i].value;o.textContent=options[i].text;sel.appendChild(o);}";
    j += "sel.addEventListener('change',function(){setVar(varName,this.value);});return sel;}";

    // Create a range input
    j += "function mkRange(varName,min,max,step){";
    j += "var wrap=document.createElement('div');wrap.className='range-wrap';";
    j += "var inp=document.createElement('input');inp.type='range';inp.setAttribute('data-var',varName);";
    j += "inp.min=min;inp.max=max;inp.step=step||'1';inp.value=min;";
    j += "var sp=document.createElement('span');sp.className='range-val';sp.textContent=String(min);";
    j += "inp.addEventListener('input',function(){sp.textContent=this.value;});";
    j += "inp.addEventListener('change',function(){setVar(varName,this.value);});";
    j += "wrap.appendChild(inp);wrap.appendChild(sp);return wrap;}";

    // Create vec3 inputs (3 numbers + optional copy button)
    j += "function mkVec3(varName,withCopy){";
    j += "var wrap=document.createElement('div');wrap.className='vec3-row';";
    j += "var labels=['X','Y','Z'];";
    j += "for(var i=0;i<3;i++){";
    j += "var inp=document.createElement('input');inp.type='number';inp.step='0.001';";
    j += "inp.setAttribute('data-var',varName);inp.setAttribute('data-vec3-idx',i);";
    j += "inp.placeholder=labels[i];";
    j += "inp.addEventListener('blur',function(){";
    j += "var inps=this.parentNode.querySelectorAll('input[type=number]');";
    j += "var v=inps[0].value+' '+inps[1].value+' '+inps[2].value;";
    j += "setVar(varName,v);});";
    j += "wrap.appendChild(inp);}";
    j += "if(withCopy){var btn=document.createElement('button');btn.className='btn-sm';btn.textContent='Copy Vehicle';";
    j += "btn.addEventListener('click',function(){";
    j += "fetch('/api/bf/copy-position',{method:'POST'}).then(function(r){return r.json();}).then(function(d){";
    j += "if(d.vehiclePosition){var inps=wrap.querySelectorAll('input[type=number]');";
    j += "inps[0].value=d.vehiclePosition.x.toFixed(3);inps[1].value=d.vehiclePosition.y.toFixed(3);inps[2].value=d.vehiclePosition.z.toFixed(3);";
    j += "setVar(varName,d.vehiclePosition.x+' '+d.vehiclePosition.y+' '+d.vehiclePosition.z);}});});";
    j += "wrap.appendChild(btn);}";
    j += "return wrap;}";

    return j;
}

// ============================================================
// JS: Status polling + Map loading
// ============================================================

string BfDashJS_Status()
{
    string j = "";

    j += "var pollOk=false;";

    // Status polling
    j += "function pollStatus(){";
    j += "fetch('/api/bf/status').then(function(r){return r.json();}).then(function(d){pollOk=true;";
    j += "var cn=document.getElementById('conn');cn.textContent='Connected';cn.style.background='#3fb95030';cn.style.color='#3fb950';";
    j += "var st=document.getElementById('bfState');st.textContent=d.running?'Running':'Idle';st.className='badge '+(d.running?'running':'idle');";
    j += "var ph=document.getElementById('bfPhase');ph.textContent=d.phase;ph.className='badge '+(d.phase==='Initial'?'initial':d.phase==='Search'?'search':'idle');";
    j += "setText('bfTarget',d.target||'-');";
    j += "setText('bfElapsed',fmtDur(d.elapsedMs||0));";
    j += "setText('bfIter',fmtNum(d.iterations||0));";
    j += "setText('bfIterSec',(d.iterationsPerSec||0).toFixed(1));";
    j += "setText('bfRestarts',d.restarts||0);";
    // Track bfIsRunning transitions
    j += "var wasRunning = bfIsRunning;";
    j += "bfIsRunning = d.running;";
    j += "if (wasRunning === null) { updateApplyBar(); }";
    j += "if (wasRunning && !bfIsRunning) {";
    j += "var count = Object.keys(dirtyVars).length;";
    j += "if (count > 0) {";
    j += "applyAllDirty();";
    j += "showToast('BF ended. ' + count + ' pending change(s) applied.');}";
    j += "updateApplyBar();}";
    j += "if (!wasRunning && bfIsRunning) {";
    j += "dirtyVars = {};";
    j += "markAllClean();";
    j += "updateApplyBar();}";
    j += "}).catch(function(){";
    j += "if(pollOk){pollOk=false;var cn=document.getElementById('conn');cn.textContent='Disconnected';cn.style.background='#f8514930';cn.style.color='#f85149';}";
    j += "});}";
    j += "setInterval(pollStatus,500);pollStatus();";

    // Map
    j += "function loadMap(){";
    j += "fetch('/api/map').then(function(r){return r.json();}).then(function(d){";
    j += "setText('mapName',d.loaded?d.name:'No map');";
    j += "setText('mapAuthor',d.loaded?d.author:'-');";
    j += "setText('mapUid',d.loaded?d.uid:'-');";
    j += "}).catch(function(){});}";
    j += "loadMap();setInterval(loadMap,10000);";

    return j;
}

// ============================================================
// JS: Settings polling + rendering
// ============================================================

string BfDashJS_Settings()
{
    string j = "";

    j += "var allCfg=null;var lastSlotCount=-1;";

    // Build the eval-specific fields based on target
    j += "function buildEvalFields(cfg){";
    j += "var c=document.getElementById('evalFields');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "var t=cfg.target;var es=cfg.evalSettings;var trigs=cfg.triggers||[];";

    // Helper to make trigger select options
    j += "function trigOpts(includeNone){var opts=[];if(includeNone)opts.push({value:'0',text:'None'});";
    j += "for(var i=0;i<trigs.length;i++){var ti=trigs[i];var p=ti.position;";
    j += "opts.push({value:String(ti.index),text:'#'+ti.index+' ('+p.x.toFixed(1)+', '+p.y.toFixed(1)+', '+p.z.toFixed(1)+')'});}return opts;}";

    // precisefinish
    j += "if(t==='precisefinish'){return;}";

    // precisecheckpoint
    j += "if(t==='precisecheckpoint'){";
    j += "c.appendChild(mkFieldRow('Target CP',mkNum('bf_target_cp',0)));return;}";

    // precisetrigger
    j += "if(t==='precisetrigger'){";
    j += "c.appendChild(mkFieldRow('Trigger',mkSelect('bf_target_trigger',trigOpts(false))));return;}";

    // standardtrigger
    j += "if(t==='standardtrigger'){";
    j += "c.appendChild(mkFieldRow('Trigger',mkSelect('bf_stdtrigger_trigger',trigOpts(false))));";
    j += "c.appendChild(mkFieldRow('Ratio',mkRange('bf_stdtrigger_weight',0,100)));return;}";

    // betterpoint
    j += "if(t==='betterpoint'){";
    j += "c.appendChild(mkFieldRow('Ratio',mkRange('bf_weight',0,100)));";
    j += "c.appendChild(mkFieldRow('Target Position',mkVec3('bf_target_point',true),true));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('bf_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('bf_eval_max_time')));";
    j += "c.appendChild(mkFieldRow('Shift Threshold',mkNum('bf_singlepoint_shift_threshold',null,null,'0.001')));";
    j += "c.appendChild(mkFieldRow('Max Distance',mkNum('bf_condition_distance',null,null,'0.001')));";
    j += "var chk=mkCheck('bf_ignore_same_speed','Ignore Same Speed');chk.className+=' full';c.appendChild(chk);return;}";

    // velocity
    j += "if(t==='velocity'){";
    j += "var vTypeOpts=[{value:'Global',text:'Global'},{value:'Trajectory',text:'Trajectory'}];";
    j += "c.appendChild(mkFieldRow('Type',mkSelect('bf_velocity_type',vTypeOpts)));";
    j += "c.appendChild(mkFieldRow('From Direction',mkVec3('bf_velocity_from',false),true));";
    j += "c.appendChild(mkFieldRow('To Direction',mkVec3('bf_velocity_to',false),true));";
    j += "c.appendChild(mkFieldRow('Min Matching Velocity',mkRange('bf_velocity_min_percent',-1.0,1.0,0.01)));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('bf_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('bf_eval_max_time')));return;}";

    // distance_target
    j += "if(t==='distance_target'){";
    j += "var dtOpts=[{value:'0',text:'CP'},{value:'1',text:'Finish'}];";
    j += "c.appendChild(mkFieldRow('Target Type',mkSelect('dist_bf_target_type',dtOpts)));";
    j += "c.appendChild(mkFieldRow('CP Index',mkNum('dist_bf_target_cp_index',0)));";
    j += "var chk1=mkCheck('dist_bf_show_cp_numbers','Show CP Numbers');c.appendChild(chk1);";
    j += "var chk2=mkCheck('dist_bf_shift_cp_eval','Shift CP Eval');c.appendChild(chk2);";
    j += "var chk3=mkCheck('dist_bf_shift_finish_eval','Shift Finish Eval');c.appendChild(chk3);";
    j += "c.appendChild(mkFieldRow('Time From',mkTime('dist_bf_bf_time_from')));";
    j += "c.appendChild(mkFieldRow('Time To',mkTime('dist_bf_bf_time_to')));";
    j += "c.appendChild(mkFieldRow('Trigger Constraint',mkNum('dist_bf_constraint_trigger_index',0)));return;}";

    // uberbug_target
    j += "if(t==='uberbug_target'){";
    j += "var modeOpts=[{value:'Find',text:'Find'},{value:'Optimize',text:'Optimize'}];";
    j += "c.appendChild(mkFieldRow('Mode',mkSelect('uber_bf_uberbug_mode',modeOpts)));";
    j += "var findOpts=[{value:'Single',text:'Single'},{value:'Collect many',text:'Collect many'},{value:'Keep best',text:'Keep best'}];";
    j += "c.appendChild(mkFieldRow('Find Mode',mkSelect('uber_bf_uberbug_find_mode',findOpts)));";
    j += "c.appendChild(mkFieldRow('Amount',mkNum('uber_bf_uberbug_amount',1)));";
    j += "c.appendChild(mkFieldRow('Result File',mkText('uber_bf_uberbug_result_file')));";
    j += "c.appendChild(mkFieldRow('Point1',mkVec3('uber_bf_uberbug_point1',false),true));";
    j += "c.appendChild(mkFieldRow('Point2',mkVec3('uber_bf_uberbug_point2',false),true));";
    j += "c.appendChild(mkFieldRow('Threshold',mkNum('uber_bf_uberbug_threshold',null,null,'0.001')));";
    j += "c.appendChild(mkFieldRow('Time From',mkTime('uber_bf_bf_time_from')));";
    j += "c.appendChild(mkFieldRow('Time To',mkTime('uber_bf_bf_time_to')));";
    j += "c.appendChild(mkFieldRow('Min Speed',mkNum('uber_bf_uberbug_min_speed',null,null,'0.1')));return;}";

    // clbf
    j += "if(t==='clbf'){";
    j += "c.appendChild(mkFieldRow('Target Position',mkVec3('clbf_bf_target_position',true),true));";
    j += "c.appendChild(mkFieldRow('Yaw',mkRange('clbf_bf_target_rotation_yaw',-180,180)));";
    j += "c.appendChild(mkFieldRow('Pitch',mkRange('clbf_bf_target_rotation_pitch',-180,180)));";
    j += "c.appendChild(mkFieldRow('Roll',mkRange('clbf_bf_target_rotation_roll',-180,180)));";
    j += "c.appendChild(mkFieldRow('Weight',mkRange('clbf_bf_weight',0,100)));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('clbf_bf_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('clbf_bf_eval_max_time')));return;}";

    // time
    j += "if(t==='time'){";
    j += "c.appendChild(mkFieldRow('Minimum Time',mkTime('timebf_min_time')));return;}";

    // customtarget
    j += "if(t==='customtarget'){";
    j += "c.appendChild(mkFieldRow('Script',mkScript('bf_customtarget_script'),true));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('bf_customtarget_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('bf_customtarget_eval_max_time')));return;}";

    j += "}";

    // Update eval fields with values from cfg
    j += "function updateEvalValues(cfg){";
    j += "var es=cfg.evalSettings;if(!es)return;";
    j += "var keys=Object.keys(es);";
    j += "for(var i=0;i<keys.length;i++){";
    j += "var k=keys[i];var val=es[k];";
    // Handle vec3 objects
    j += "if(val!==null&&typeof val==='object'&&'x' in val){";
    j += "var inps=document.querySelectorAll('input[data-var=\"'+k+'\"][data-vec3-idx]');";
    j += "if(inps.length===3){setField(inps[0],val.x.toFixed(3));setField(inps[1],val.y.toFixed(3));setField(inps[2],val.z.toFixed(3));}";
    j += "continue;}";
    // Handle time fields
    j += "var tEl=document.querySelector('[data-var=\"'+k+'\"][data-time]');";
    j += "if(tEl){setField(tEl,fmtTime(val));continue;}";
    // Handle script fields
    j += "var sEl=document.querySelector('[data-var=\"'+k+'\"][data-script]');";
    j += "if(sEl){if(!isFocused(sEl))sEl.value=scriptToDisplay(val);continue;}";
    // Handle regular fields
    j += "var el=document.querySelector('[data-var=\"'+k+'\"]');";
    j += "if(el){setField(el,val);}";
    j += "}}";

    // Build slot UI
    j += "function buildSlots(cfg){";
    j += "var c=document.getElementById('slotsContainer');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "var slots=cfg.slots||[];var algos=cfg.algorithms||[];";
    j += "for(var si=0;si<slots.length;si++){";
    j += "(function(si){";
    j += "var s=slots[si];var card=document.createElement('div');card.className='slot-card';";

    // Slot header
    j += "var hdr=document.createElement('div');hdr.className='slot-hdr';";
    j += "var title=document.createElement('span');title.className='slot-title';title.textContent='Slot #'+(si+1);hdr.appendChild(title);";
    // Enabled checkbox for non-first slots
    j += "if(si>0){";
    j += "var vs=si===0?'':'_'+si;";
    j += "var enChk=document.createElement('input');enChk.type='checkbox';enChk.checked=s.enabled;";
    j += "enChk.title='Enabled';enChk.setAttribute('data-var','bf_input_mod_enabled'+vs);";
    j += "enChk.addEventListener('change',function(){setVar('bf_input_mod_enabled'+vs,this.checked?'true':'false');});";
    j += "hdr.appendChild(enChk);}";
    // Algorithm select
    j += "var vs=si===0?'':'_'+si;";
    j += "var algoOpts=[];for(var ai=0;ai<algos.length;ai++){algoOpts.push({value:algos[ai].id,text:algos[ai].name});}";
    j += "var algoSel=mkSelect('bf_input_mod_algorithm'+vs,algoOpts);algoSel.value=s.algorithm;";
    j += "algoSel.style.maxWidth='140px';hdr.appendChild(algoSel);";
    // Remove button for non-first slots
    j += "if(si>0){var rmBtn=document.createElement('button');rmBtn.className='btn-sm btn-danger';rmBtn.textContent='Remove';";
    j += "rmBtn.addEventListener('click',function(){postAction('/api/bf/remove-slot','index='+si);});hdr.appendChild(rmBtn);}";

    j += "card.appendChild(hdr);";

    // Slot body
    j += "var body=document.createElement('div');body.className='slot-body';body.setAttribute('data-slot',si);";
    j += "buildAlgoFields(body,s,si,s.algorithm);";
    j += "card.appendChild(body);c.appendChild(card);";
    j += "})(si);}";
    j += "}";

    // Build algorithm-specific fields inside a slot body
    j += "function buildAlgoFields(body,s,si,algoId){";
    j += "var vs=si===0?'':'_'+si;";

    // basic
    j += "if(algoId==='basic'){";
    j += "body.appendChild(mkFieldRow('Modify Count',mkNum('bf_modify_count'+vs,0)));";
    j += "body.appendChild(mkFieldRow('Time From',mkTime('bf_inputs_min_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Time To',mkTime('bf_inputs_max_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Max Steer Diff',mkRange('bf_max_steer_diff'+vs,0,131072)));";
    j += "body.appendChild(mkFieldRow('Max Time Diff',mkNum('bf_max_time_diff'+vs,0)));";
    j += "var chk=mkCheck('bf_inputs_fill_steer'+vs,'Fill Steer');chk.className+=' full';body.appendChild(chk);return;}";

    // range
    j += "if(algoId==='range'){";
    j += "body.appendChild(mkFieldRow('Min Input Count',mkNum('bf_range_min_input_count'+vs,1)));";
    j += "body.appendChild(mkFieldRow('Max Input Count',mkNum('bf_range_max_input_count'+vs,1)));";
    j += "body.appendChild(mkFieldRow('Time From',mkTime('bf_inputs_min_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Time To',mkTime('bf_inputs_max_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Steer Range Min',mkNum('bf_range_min_steer'+vs,-65536,65536)));";
    j += "body.appendChild(mkFieldRow('Steer Range Max',mkNum('bf_range_max_steer'+vs,-65536,65536)));";
    j += "body.appendChild(mkFieldRow('Time Diff Range Min',mkNum('bf_range_min_time_diff'+vs)));";
    j += "body.appendChild(mkFieldRow('Time Diff Range Max',mkNum('bf_range_max_time_diff'+vs)));";
    j += "var chk=mkCheck('bf_range_fill_steer'+vs,'Fill Steer');chk.className+=' full';body.appendChild(chk);return;}";

    // advanced_basic
    j += "if(algoId==='advanced_basic'){";
    j += "var types=[{name:'Steer',pre:'bf_adv_steer_',fields:['modify_count','min_time','max_time','max_diff','max_time_diff','fill']},";
    j += "{name:'Accel',pre:'bf_adv_accel_',fields:['modify_count','min_time','max_time','max_time_diff']},";
    j += "{name:'Brake',pre:'bf_adv_brake_',fields:['modify_count','min_time','max_time','max_time_diff']}];";
    j += "for(var ti=0;ti<types.length;ti++){";
    j += "var sec=document.createElement('div');sec.className='sub-sec';";
    j += "var st=document.createElement('div');st.className='sub-sec-title';st.textContent=types[ti].name;sec.appendChild(st);";
    j += "var sg=document.createElement('div');sg.className='sub-sec-grid';";
    j += "var pre=types[ti].pre;var ff=types[ti].fields;";
    j += "for(var fi=0;fi<ff.length;fi++){var fn=ff[fi];var vn=pre+fn+vs;";
    j += "if(fn==='fill'){var chk=mkCheck(vn,'Fill Steer');chk.className+=' full';sg.appendChild(chk);}";
    j += "else if(fn==='min_time'||fn==='max_time'){sg.appendChild(mkFieldRow(fn==='min_time'?'Time From':'Time To',mkTime(vn)));}";
    j += "else if(fn==='max_diff'){sg.appendChild(mkFieldRow('Max Steer Diff',mkRange(vn,0,131072)));}";
    j += "else{var label=fn.replace(/_/g,' ');label=label.charAt(0).toUpperCase()+label.slice(1);sg.appendChild(mkFieldRow(label,mkNum(vn,0)));}}";
    j += "sec.appendChild(sg);body.appendChild(sec);}return;}";

    // advanced_range
    j += "if(algoId==='advanced_range'){";
    j += "var types=[{name:'Steer',pre:'bf_advr_steer_',fields:['min_input_count','max_input_count','min_time','max_time','min_steer','max_steer','min_time_diff','max_time_diff','fill']},";
    j += "{name:'Accel',pre:'bf_advr_accel_',fields:['min_input_count','max_input_count','min_time','max_time','min_time_diff','max_time_diff']},";
    j += "{name:'Brake',pre:'bf_advr_brake_',fields:['min_input_count','max_input_count','min_time','max_time','min_time_diff','max_time_diff']}];";
    j += "for(var ti=0;ti<types.length;ti++){";
    j += "var sec=document.createElement('div');sec.className='sub-sec';";
    j += "var st=document.createElement('div');st.className='sub-sec-title';st.textContent=types[ti].name;sec.appendChild(st);";
    j += "var sg=document.createElement('div');sg.className='sub-sec-grid';";
    j += "var pre=types[ti].pre;var ff=types[ti].fields;";
    j += "for(var fi=0;fi<ff.length;fi++){var fn=ff[fi];var vn=pre+fn+vs;";
    j += "if(fn==='fill'){var chk=mkCheck(vn,'Fill Steer');chk.className+=' full';sg.appendChild(chk);}";
    j += "else if(fn==='min_time'||fn==='max_time'){sg.appendChild(mkFieldRow(fn==='min_time'?'Time From':'Time To',mkTime(vn)));}";
    j += "else if(fn==='min_steer'||fn==='max_steer'){sg.appendChild(mkFieldRow(fn==='min_steer'?'Steer Min':'Steer Max',mkNum(vn,-65536,65536)));}";
    j += "else{var label=fn.replace(/_/g,' ');label=label.charAt(0).toUpperCase()+label.slice(1);sg.appendChild(mkFieldRow(label,mkNum(vn,0)));}}";
    j += "sec.appendChild(sg);body.appendChild(sec);}return;}";

    j += "}";

    // Update all slot field values from config
    j += "function updateSlotValues(cfg){";
    j += "var slots=cfg.slots||[];";
    j += "for(var si=0;si<slots.length;si++){";
    j += "var s=slots[si];var vs=si===0?'':'_'+si;";
    j += "var algoKey=s.algorithm;var data=s[algoKey];";
    // Also grab basic/range/advanced_basic/advanced_range sub-objects
    j += "var allSubs=['basic','range','advanced_basic','advanced_range'];";
    j += "for(var sbi=0;sbi<allSubs.length;sbi++){";
    j += "var sub=s[allSubs[sbi]];if(!sub)continue;";
    j += "var keys=Object.keys(sub);";
    j += "for(var ki=0;ki<keys.length;ki++){";
    j += "var k=keys[ki];var val=sub[k];";
    // Map JSON key to variable name
    j += "var varMap={";
    // basic
    j += "'modifyCount':'bf_modify_count','minTime':'bf_inputs_min_time','maxTime':'bf_inputs_max_time',";
    j += "'maxSteerDiff':'bf_max_steer_diff','maxTimeDiff':'bf_max_time_diff','fillSteer':'bf_inputs_fill_steer',";
    // range
    j += "'minInputCount':'bf_range_min_input_count','maxInputCount':'bf_range_max_input_count',";
    j += "'minSteer':'bf_range_min_steer','maxSteer':'bf_range_max_steer',";
    j += "'minTimeDiff':'bf_range_min_time_diff','maxTimeDiff2':'bf_range_max_time_diff'};";
    // We need a different approach - use data-var attribute directly
    j += "}}";

    // Actually, update by iterating all data-var elements in the slot body
    j += "var body=document.querySelector('[data-slot=\"'+si+'\"]');if(!body)continue;";
    j += "var els=body.querySelectorAll('[data-var]');";
    j += "for(var ei=0;ei<els.length;ei++){";
    j += "var el=els[ei];var vn=el.getAttribute('data-var');";
    // Find matching value from the slot's algorithm data
    j += "var val=findSlotValue(s,vn,vs);";
    j += "if(val===undefined)continue;";
    j += "if(el.getAttribute('data-time')){setField(el,fmtTime(val));}";
    j += "else if(el.type==='checkbox'){if(!isFocused(el))el.checked=!!val;}";
    j += "else{setField(el,val);}";
    j += "}";

    // Update enabled checkbox and algo select in header
    j += "if(si>0){var enEl=document.querySelector('.slot-hdr input[data-var=\"bf_input_mod_enabled'+vs+'\"]');";
    j += "if(enEl&&!isFocused(enEl))enEl.checked=s.enabled;}";
    j += "var algoEl=document.querySelector('.slot-hdr select[data-var=\"bf_input_mod_algorithm'+vs+'\"]');";
    j += "if(algoEl&&!isFocused(algoEl))algoEl.value=s.algorithm;";

    j += "}}";

    // Lookup a value from the slot data by variable name
    j += "function findSlotValue(s,vn,vs){";
    // Strip the suffix to get the base name
    j += "var base=vn;if(vs&&vn.endsWith(vs))base=vn.substring(0,vn.length-vs.length);";
    j += "var maps={";
    // basic keys
    j += "'bf_modify_count':['basic','modifyCount'],";
    j += "'bf_inputs_min_time':['basic','minTime'],";
    j += "'bf_inputs_max_time':['basic','maxTime'],";
    j += "'bf_max_steer_diff':['basic','maxSteerDiff'],";
    j += "'bf_max_time_diff':['basic','maxTimeDiff'],";
    j += "'bf_inputs_fill_steer':['basic','fillSteer'],";
    // range keys
    j += "'bf_range_min_input_count':['range','minInputCount'],";
    j += "'bf_range_max_input_count':['range','maxInputCount'],";
    j += "'bf_range_min_steer':['range','minSteer'],";
    j += "'bf_range_max_steer':['range','maxSteer'],";
    j += "'bf_range_min_time_diff':['range','minTimeDiff'],";
    j += "'bf_range_max_time_diff':['range','maxTimeDiff'],";
    j += "'bf_range_fill_steer':['range','fillSteer'],";
    // advanced_basic keys
    j += "'bf_adv_steer_modify_count':['advanced_basic','steerModifyCount'],";
    j += "'bf_adv_steer_min_time':['advanced_basic','steerMinTime'],";
    j += "'bf_adv_steer_max_time':['advanced_basic','steerMaxTime'],";
    j += "'bf_adv_steer_max_diff':['advanced_basic','steerMaxDiff'],";
    j += "'bf_adv_steer_max_time_diff':['advanced_basic','steerMaxTimeDiff'],";
    j += "'bf_adv_steer_fill':['advanced_basic','steerFill'],";
    j += "'bf_adv_accel_modify_count':['advanced_basic','accelModifyCount'],";
    j += "'bf_adv_accel_min_time':['advanced_basic','accelMinTime'],";
    j += "'bf_adv_accel_max_time':['advanced_basic','accelMaxTime'],";
    j += "'bf_adv_accel_max_time_diff':['advanced_basic','accelMaxTimeDiff'],";
    j += "'bf_adv_brake_modify_count':['advanced_basic','brakeModifyCount'],";
    j += "'bf_adv_brake_min_time':['advanced_basic','brakeMinTime'],";
    j += "'bf_adv_brake_max_time':['advanced_basic','brakeMaxTime'],";
    j += "'bf_adv_brake_max_time_diff':['advanced_basic','brakeMaxTimeDiff'],";
    // advanced_range keys
    j += "'bf_advr_steer_min_input_count':['advanced_range','steerMinInputCount'],";
    j += "'bf_advr_steer_max_input_count':['advanced_range','steerMaxInputCount'],";
    j += "'bf_advr_steer_min_time':['advanced_range','steerMinTime'],";
    j += "'bf_advr_steer_max_time':['advanced_range','steerMaxTime'],";
    j += "'bf_advr_steer_min_steer':['advanced_range','steerMinSteer'],";
    j += "'bf_advr_steer_max_steer':['advanced_range','steerMaxSteer'],";
    j += "'bf_advr_steer_min_time_diff':['advanced_range','steerMinTimeDiff'],";
    j += "'bf_advr_steer_max_time_diff':['advanced_range','steerMaxTimeDiff'],";
    j += "'bf_advr_steer_fill':['advanced_range','steerFill'],";
    j += "'bf_advr_accel_min_input_count':['advanced_range','accelMinInputCount'],";
    j += "'bf_advr_accel_max_input_count':['advanced_range','accelMaxInputCount'],";
    j += "'bf_advr_accel_min_time':['advanced_range','accelMinTime'],";
    j += "'bf_advr_accel_max_time':['advanced_range','accelMaxTime'],";
    j += "'bf_advr_accel_min_time_diff':['advanced_range','accelMinTimeDiff'],";
    j += "'bf_advr_accel_max_time_diff':['advanced_range','accelMaxTimeDiff'],";
    j += "'bf_advr_brake_min_input_count':['advanced_range','brakeMinInputCount'],";
    j += "'bf_advr_brake_max_input_count':['advanced_range','brakeMaxInputCount'],";
    j += "'bf_advr_brake_min_time':['advanced_range','brakeMinTime'],";
    j += "'bf_advr_brake_max_time':['advanced_range','brakeMaxTime'],";
    j += "'bf_advr_brake_min_time_diff':['advanced_range','brakeMinTimeDiff'],";
    j += "'bf_advr_brake_max_time_diff':['advanced_range','brakeMaxTimeDiff']";
    j += "};";
    j += "var m=maps[base];if(!m)return undefined;";
    j += "var sub=s[m[0]];if(!sub)return undefined;";
    j += "return sub[m[1]];}";

    // Track previous target for rebuild detection
    j += "var prevTarget='';var prevSlotAlgos='';";

    // Main settings poll
    j += "function pollSettings(){";
    j += "fetch('/api/bf/all-settings').then(function(r){return r.json();}).then(function(cfg){";
    j += "allCfg=cfg;";

    // Build serverSnapshot from polled config
    j += "serverSnapshot={};";
    j += "serverSnapshot['bf_target']=String(cfg.target);";
    j += "if(cfg.behavior){";
    j += "serverSnapshot['bf_result_filename']=String(cfg.behavior.resultFilename);";
    j += "serverSnapshot['bf_iterations_before_restart']=String(cfg.behavior.iterationsBeforeRestart);";
    j += "serverSnapshot['bf_result_folder']=String(cfg.behavior.resultFolder);";
    j += "serverSnapshot['bf_restart_condition_script']=String(cfg.behavior.restartConditionScript);}";
    j += "if(cfg.conditions){";
    j += "serverSnapshot['bf_condition_speed']=String(cfg.conditions.speed);";
    j += "serverSnapshot['bf_condition_cps']=String(cfg.conditions.cps);";
    j += "serverSnapshot['bf_condition_trigger']=String(cfg.conditions.trigger);";
    j += "serverSnapshot['bf_condition_script']=String(cfg.conditions.conditionScript);}";
    j += "if(cfg.evalSettings){var ek=Object.keys(cfg.evalSettings);for(var ei=0;ei<ek.length;ei++){";
    j += "var ev=cfg.evalSettings[ek[ei]];";
    j += "if(ev!==null&&typeof ev==='object'&&'x' in ev)serverSnapshot[ek[ei]]=ev.x.toFixed(3)+' '+ev.y.toFixed(3)+' '+ev.z.toFixed(3);";
    j += "else serverSnapshot[ek[ei]]=String(ev);}}";
    j += "if(cfg.slots){for(var si=0;si<cfg.slots.length;si++){var sl=cfg.slots[si];var vs=si===0?'':'_'+si;";
    j += "serverSnapshot['bf_input_mod_algorithm'+vs]=sl.algorithm;";
    j += "if(si>0)serverSnapshot['bf_input_mod_enabled'+vs]=String(sl.enabled);";
    j += "var algos=['basic','range','advanced_basic','advanced_range'];";
    j += "for(var ai=0;ai<algos.length;ai++){var ao=sl[algos[ai]];if(!ao)continue;var ak=Object.keys(ao);";
    j += "for(var aki=0;aki<ak.length;aki++){var varN=findVarName(algos[ai],ak[aki],vs);if(varN)serverSnapshot[varN]=String(ao[ak[aki]]);}}}}";

    // Helper to map JSON key back to variable name
    j += "function findVarName(algo,key,vs){";
    j += "var m={'basic':{'modifyCount':'bf_modify_count','minTime':'bf_inputs_min_time','maxTime':'bf_inputs_max_time','maxSteerDiff':'bf_max_steer_diff','maxTimeDiff':'bf_max_time_diff','fillSteer':'bf_inputs_fill_steer'},";
    j += "'range':{'minInputCount':'bf_range_min_input_count','maxInputCount':'bf_range_max_input_count','minTime':'bf_inputs_min_time','maxTime':'bf_inputs_max_time','minSteer':'bf_range_min_steer','maxSteer':'bf_range_max_steer','minTimeDiff':'bf_range_min_time_diff','maxTimeDiff':'bf_range_max_time_diff','fillSteer':'bf_range_fill_steer'},";
    j += "'advanced_basic':{'steerModifyCount':'bf_adv_steer_modify_count','steerMinTime':'bf_adv_steer_min_time','steerMaxTime':'bf_adv_steer_max_time','steerMaxDiff':'bf_adv_steer_max_diff','steerMaxTimeDiff':'bf_adv_steer_max_time_diff','steerFill':'bf_adv_steer_fill','accelModifyCount':'bf_adv_accel_modify_count','accelMinTime':'bf_adv_accel_min_time','accelMaxTime':'bf_adv_accel_max_time','accelMaxTimeDiff':'bf_adv_accel_max_time_diff','brakeModifyCount':'bf_adv_brake_modify_count','brakeMinTime':'bf_adv_brake_min_time','brakeMaxTime':'bf_adv_brake_max_time','brakeMaxTimeDiff':'bf_adv_brake_max_time_diff'},";
    j += "'advanced_range':{'steerMinInputCount':'bf_advr_steer_min_input_count','steerMaxInputCount':'bf_advr_steer_max_input_count','steerMinTime':'bf_advr_steer_min_time','steerMaxTime':'bf_advr_steer_max_time','steerMinSteer':'bf_advr_steer_min_steer','steerMaxSteer':'bf_advr_steer_max_steer','steerMinTimeDiff':'bf_advr_steer_min_time_diff','steerMaxTimeDiff':'bf_advr_steer_max_time_diff','steerFill':'bf_advr_steer_fill','accelMinInputCount':'bf_advr_accel_min_input_count','accelMaxInputCount':'bf_advr_accel_max_input_count','accelMinTime':'bf_advr_accel_min_time','accelMaxTime':'bf_advr_accel_max_time','accelMinTimeDiff':'bf_advr_accel_min_time_diff','accelMaxTimeDiff':'bf_advr_accel_max_time_diff','brakeMinInputCount':'bf_advr_brake_min_input_count','brakeMaxInputCount':'bf_advr_brake_max_input_count','brakeMinTime':'bf_advr_brake_min_time','brakeMaxTime':'bf_advr_brake_max_time','brakeMinTimeDiff':'bf_advr_brake_min_time_diff','brakeMaxTimeDiff':'bf_advr_brake_max_time_diff'}};";
    j += "var map=m[algo];if(!map||!map[key])return null;return map[key]+vs;}";

    // Controller badge
    j += "var cb=document.getElementById('ctrlBadge');";
    j += "if(!cfg.controllerActive){";
    j += "if(!cb.firstChild){var b=document.createElement('span');b.className='badge warn';b.textContent='BfV2 not active';cb.appendChild(b);}";
    j += "}else{while(cb.firstChild)cb.removeChild(cb.firstChild);}";

    // Populate target select
    j += "var tSel=document.getElementById('optTarget');";
    j += "if(tSel.options.length!==cfg.evaluations.length){";
    j += "while(tSel.firstChild)tSel.removeChild(tSel.firstChild);";
    j += "for(var i=0;i<cfg.evaluations.length;i++){var o=document.createElement('option');o.value=cfg.evaluations[i].id;o.textContent=cfg.evaluations[i].title;tSel.appendChild(o);}}";
    j += "setField(tSel,cfg.target);";

    // Rebuild eval fields if target changed
    j += "var displayTarget=('bf_target' in dirtyVars)?dirtyVars['bf_target']:cfg.target;";
    j += "if(displayTarget!==prevTarget){prevTarget=displayTarget;buildEvalFields({target:displayTarget,evalSettings:cfg.evalSettings,triggers:cfg.triggers});}";
    j += "updateEvalValues(cfg);";

    // Update behavior fields
    j += "setField(document.getElementById('behFile'),cfg.behavior.resultFilename);";
    j += "setField(document.getElementById('behIter'),cfg.behavior.iterationsBeforeRestart);";
    j += "setField(document.getElementById('behFolder'),cfg.behavior.resultFolder);";
    j += "var behScript=document.getElementById('behRestartScript');";
    j += "if(!isFocused(behScript))behScript.value=scriptToDisplay(cfg.behavior.restartConditionScript);";

    // Update condition fields
    j += "setField(document.getElementById('condSpeed'),cfg.conditions.speed);";
    j += "setField(document.getElementById('condCps'),cfg.conditions.cps);";

    // Populate condition trigger select
    j += "var ctSel=document.getElementById('condTrigger');";
    j += "var trigs=cfg.triggers||[];var neededOpts=trigs.length+1;";
    j += "if(ctSel.options.length!==neededOpts){";
    j += "while(ctSel.firstChild)ctSel.removeChild(ctSel.firstChild);";
    j += "var none=document.createElement('option');none.value='0';none.textContent='None';ctSel.appendChild(none);";
    j += "for(var i=0;i<trigs.length;i++){var o=document.createElement('option');o.value=String(trigs[i].index);";
    j += "var p=trigs[i].position;o.textContent='#'+trigs[i].index+' ('+p.x.toFixed(1)+', '+p.y.toFixed(1)+', '+p.z.toFixed(1)+')';ctSel.appendChild(o);}}";
    j += "setField(ctSel,cfg.conditions.trigger);";

    j += "var condScript=document.getElementById('condScript');";
    j += "if(!isFocused(condScript))condScript.value=scriptToDisplay(cfg.conditions.conditionScript);";

    // Build/rebuild slots if count or algorithms changed
    j += "var slotAlgos='';for(var i=0;i<cfg.slots.length;i++)slotAlgos+=cfg.slots[i].algorithm+',';";
    j += "if(cfg.slots.length!==lastSlotCount||slotAlgos!==prevSlotAlgos){lastSlotCount=cfg.slots.length;prevSlotAlgos=slotAlgos;buildSlots(cfg);}";
    j += "updateSlotValues(cfg);";

    j += "}).catch(function(){});}";
    j += "setInterval(pollSettings,500);pollSettings();";

    // Wire up static settings change events
    j += "document.getElementById('optTarget').addEventListener('change',function(){setVar('bf_target',this.value);prevTarget='';});";
    j += "document.getElementById('behFile').addEventListener('blur',function(){setVar('bf_result_filename',this.value);});";
    j += "document.getElementById('behIter').addEventListener('blur',function(){setVar('bf_iterations_before_restart',this.value);});";
    j += "document.getElementById('behFolder').addEventListener('blur',function(){setVar('bf_result_folder',this.value);});";
    j += "document.getElementById('behRestartScript').addEventListener('blur',function(){setVar('bf_restart_condition_script',displayToScript(this.value));});";
    j += "document.getElementById('condSpeed').addEventListener('blur',function(){setVar('bf_condition_speed',this.value);});";
    j += "document.getElementById('condCps').addEventListener('blur',function(){setVar('bf_condition_cps',this.value);});";
    j += "document.getElementById('condTrigger').addEventListener('change',function(){setVar('bf_condition_trigger',this.value);});";
    j += "document.getElementById('condScript').addEventListener('blur',function(){setVar('bf_condition_script',displayToScript(this.value));});";

    // Add Slot button
    j += "document.getElementById('btnAddSlot').addEventListener('click',function(){postAction('/api/bf/add-slot','');});";

    // Apply/Discard button handlers
    j += "function applyAllDirty() {";
    j += "var keys = Object.keys(dirtyVars);";
    j += "if (keys.length === 0) return;";
    j += "var body = '';";
    j += "for (var i=0; i<keys.length; i++) {";
    j += "if (i > 0) body += '\\n';";
    j += "body += keys[i] + '=' + dirtyVars[keys[i]];}";
    j += "fetch('/api/bf/set-batch', {method:'POST', body:body}).then(function(r){return r.json();}).then(function(d){";
    j += "if (d.ok) { dirtyVars = {}; markAllClean(); updateApplyBar(); }";
    j += "}).catch(function(){});}";

    j += "document.getElementById('btnApply').addEventListener('click', function() { applyAllDirty(); });";
    j += "document.getElementById('btnDiscard').addEventListener('click', function() {";
    j += "dirtyVars = {};";
    j += "markAllClean();";
    j += "updateApplyBar();";
    j += "pollSettings();});";

    return j;
}

// ============================================================
// JS: Session history (log, improvements, session tabs)
// ============================================================

string BfDashJS_Sessions()
{
    string j = "";

    j += "var activeSession='current',activeSubTab='imp',sessions=[];";

    // Current session log/improvements polling
    j += "var lastLogLen=0,lastImpLen=0;";
    j += "function pollCurrentLog(){";
    j += "if(activeSession!=='current'||activeSubTab!=='log')return;";
    j += "fetch('/api/bf/log').then(function(r){return r.json();}).then(function(arr){";
    j += "if(arr.length!==lastLogLen){lastLogLen=arr.length;renderLog(arr);}";
    j += "}).catch(function(){});}";

    j += "function pollCurrentImp(){";
    j += "if(activeSession!=='current'||activeSubTab!=='imp')return;";
    j += "fetch('/api/bf/improvements').then(function(r){return r.json();}).then(function(arr){";
    j += "if(arr.length!==lastImpLen){lastImpLen=arr.length;renderImp(arr);setText('bfImpCount',arr.length);}";
    j += "}).catch(function(){});}";

    j += "setInterval(pollCurrentLog,1000);setInterval(pollCurrentImp,2000);";

    // Sessions polling
    j += "function pollSessions(){";
    j += "fetch('/api/bf/sessions').then(function(r){return r.json();}).then(function(arr){sessions=arr;renderSessionTabs();}).catch(function(){});}";
    j += "setInterval(pollSessions,5000);pollSessions();";

    // Render session tabs (with X delete buttons on past sessions)
    j += "function renderSessionTabs(){";
    j += "var bar=document.getElementById('sessionTabs');while(bar.firstChild)bar.removeChild(bar.firstChild);";
    j += "var cur=document.createElement('button');cur.className='tab-btn'+(activeSession==='current'?' active':'');cur.textContent='Current';";
    j += "cur.addEventListener('click',function(){activeSession='current';renderSessionTabs();loadSessionData();});bar.appendChild(cur);";
    j += "for(var i=sessions.length-1;i>=0;i--){";
    j += "(function(s){";
    j += "var btn=document.createElement('button');btn.className='tab-btn'+(activeSession===s.id?' active':'');";
    j += "btn.title=s.map||'';";
    j += "var lbl=document.createElement('span');";
    j += "lbl.textContent='#'+s.id+': '+(s.target||'?').substring(0,15);";
    j += "btn.appendChild(lbl);";
    j += "var del=document.createElement('span');";
    j += "del.className='tab-del';";
    j += "del.textContent='\\u00D7';";
    j += "del.title='Delete session #'+s.id;";
    j += "del.addEventListener('click',function(e){";
    j += "e.stopPropagation();";
    j += "if(!e.shiftKey&&!confirm('Delete session #'+s.id+'?\\n(Hold Shift to bypass this confirmation)'))return;";
    j += "fetch('/api/bf/delete-session',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'id='+encodeURIComponent(s.id)}).then(function(r){return r.json();}).then(function(d){";
    j += "if(d.ok){";
    j += "if(activeSession===s.id)activeSession='current';";
    j += "for(var j2=0;j2<sessions.length;j2++){if(sessions[j2].id===s.id){sessions.splice(j2,1);break;}}";
    j += "renderSessionTabs();";
    j += "loadSessionData();}});});";
    j += "btn.appendChild(del);";
    j += "btn.addEventListener('click',function(){activeSession=s.id;renderSessionTabs();loadSessionData();});";
    j += "bar.appendChild(btn);";
    j += "})(sessions[i]);}";
    j += "}";

    // Sub-tab switching
    j += "document.getElementById('tabImp').addEventListener('click',function(){activeSubTab='imp';";
    j += "document.getElementById('tabImp').className='sub-tab active';document.getElementById('tabLog').className='sub-tab';loadSessionData();});";
    j += "document.getElementById('tabLog').addEventListener('click',function(){activeSubTab='log';";
    j += "document.getElementById('tabLog').className='sub-tab active';document.getElementById('tabImp').className='sub-tab';loadSessionData();});";

    // Load data for selected session+tab
    j += "function loadSessionData(){";
    j += "lastLogLen=-1;lastImpLen=-1;";
    j += "var hc=document.getElementById('historyContent');while(hc&&hc.firstChild)hc.removeChild(hc.firstChild);";
    j += "if(activeSession==='current'){";
    j += "if(activeSubTab==='log'){pollCurrentLog();}else{pollCurrentImp();}return;}";
    j += "var type=activeSubTab==='log'?'session-log':'session-imp';";
    j += "fetch('/api/bf/'+type+'?id='+encodeURIComponent(activeSession)).then(function(r){return r.json();}).then(function(arr){";
    j += "if(activeSubTab==='log'){renderLog(arr);}else{renderImp(arr);}";
    j += "}).catch(function(){});}";

    // Render log entries
    j += "function renderLog(arr){";
    j += "var c=document.getElementById('historyContent');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "for(var i=0;i<arr.length;i++){var e=arr[i];var div=document.createElement('div');div.className='log-entry';";
    j += "var ts=document.createElement('span');ts.className='lt';ts.textContent='['+fmtSec(e.t)+']';";
    j += "var msg=document.createElement('span');msg.className='lm';msg.textContent=e.msg;";
    j += "div.appendChild(ts);div.appendChild(msg);c.appendChild(div);}c.scrollTop=c.scrollHeight;}";

    // Render improvements
    j += "function renderImp(arr){";
    j += "var c=document.getElementById('historyContent');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "var hdr=document.createElement('div');hdr.className='imp-row hdr';";
    j += "var cols=['#','Time','Details','Iter','Rst'];";
    j += "for(var ci=0;ci<cols.length;ci++){var s=document.createElement('span');s.textContent=cols[ci];hdr.appendChild(s);}c.appendChild(hdr);";
    j += "for(var i=arr.length-1;i>=0;i--){var e=arr[i];";
    j += "var row=document.createElement('div');row.className='imp-row';";
    j += "var ns=document.createElement('span');ns.textContent=i+1;";
    j += "var ts=document.createElement('span');ts.textContent=fmtSec(e.t);";
    j += "var ds=document.createElement('span');ds.textContent=((e.eval||'')+' '+(e.details||'')).substring(0,100);ds.title=e.details||'';";
    j += "var is2=document.createElement('span');is2.textContent=fmtNum(e.iteration||0);";
    j += "var rs=document.createElement('span');rs.textContent=e.restart||0;";
    j += "row.appendChild(ns);row.appendChild(ts);row.appendChild(ds);row.appendChild(is2);row.appendChild(rs);c.appendChild(row);}";
    j += "if(activeSession==='current')setText('bfImpCount',arr.length);}";

    // Initial load
    j += "setTimeout(loadSessionData,500);";

    return j;
}
string FileRead(const string &in path)
{
    CommandList list(path);
    if (list is null) return "";
    return list.Content;
}

bool FileWrite(const string &in path, const string &in content)
{
    CommandList list;
    list.Content = content;
    return list.Save(path);
}

bool FileAppendLine(const string &in path, const string &in line)
{
    string existing = FileRead(path);
    if (existing.Length > 0 && existing[existing.Length - 1] != 0x0A)
        existing += "\n";
    existing += line + "\n";
    return FileWrite(path, existing);
}
const uint MAX_BUFFER_SIZE = 8192;
const int MAX_WAIT_FRAMES = 30;

Net::Socket@ listenSock = null;
Net::Socket@ clientSock = null;

string requestBuffer = "";
int readWaitFrames = 0;
string lastRequestPath = "";
string serverStatus = "Starting...";
uint requestCount = 0;

// --- Routing ---

funcdef string RouteHandler(const string &in body);

class Route
{
    string method;
    string path;
    RouteHandler@ handler;
}

array<Route@> routes;

void RegisterRoute(const string &in method, const string &in path, RouteHandler@ handler)
{
    Route@ r = Route();
    r.method = method;
    r.path = path;
    @r.handler = handler;
    routes.Add(r);
}

// --- Request parsing ---

string requestMethod = "";
string requestPath = "";
string requestQuery = "";
string requestBody = "";

void ParseRequest(const string &in raw)
{
    int sp1 = raw.FindFirst(" ");
    if (sp1 < 0)
    {
        requestMethod = "GET";
        requestPath = "/";
        requestBody = "";
        return;
    }
    requestMethod = raw.Substr(0, sp1);

    string afterMethod = raw.Substr(uint(sp1 + 1));
    int sp2 = afterMethod.FindFirst(" ");
    int lineEnd = afterMethod.FindFirst("\r");

    int pathEnd = -1;
    if (sp2 >= 0 && lineEnd >= 0)
        pathEnd = (sp2 < lineEnd) ? sp2 : lineEnd;
    else if (sp2 >= 0)
        pathEnd = sp2;
    else if (lineEnd >= 0)
        pathEnd = lineEnd;

    requestPath = (pathEnd <= 0) ? "/" : afterMethod.Substr(0, pathEnd);

    int qmark = requestPath.FindFirst("?");
    if (qmark >= 0)
    {
        requestQuery = requestPath.Substr(uint(qmark + 1));
        requestPath = requestPath.Substr(0, qmark);
    }
    else
    {
        requestQuery = "";
    }

    int headerEnd = raw.FindFirst("\r\n\r\n");
    if (headerEnd >= 0)
        requestBody = raw.Substr(uint(headerEnd + 4));
    else
        requestBody = "";
}

int ParseContentLength(const string &in raw)
{
    int idx = raw.FindFirst("Content-Length: ");
    if (idx < 0)
    {
        idx = raw.FindFirst("content-length: ");
        if (idx < 0) return 0;
    }
    string after = raw.Substr(uint(idx + 16));
    int lineEnd = after.FindFirst("\r");
    if (lineEnd <= 0) return 0;
    string numStr = after.Substr(0, lineEnd);
    int val = int(Text::ParseInt(numStr));
    if (val < 0) return 0;
    return val;
}

string ExtractMethod(const string &in raw)
{
    int sp = raw.FindFirst(" ");
    if (sp < 0) return "GET";
    return raw.Substr(0, sp);
}

// --- Server lifecycle ---

void StartServer(const string &in host, uint16 port)
{
    @clientSock = null;
    @listenSock = null;
    requestBuffer = "";
    readWaitFrames = 0;

    @listenSock = Net::Socket();
    if (listenSock.Listen(host, port))
    {
        serverStatus = "Listening on " + host + ":" + Text::FormatUInt(port);
        log("HTTP Server: " + serverStatus);
    }
    else
    {
        serverStatus = "FAILED to listen on " + host + ":" + Text::FormatUInt(port);
        log("HTTP Server: " + serverStatus);
        @listenSock = null;
    }
}

void StopServer()
{
    @clientSock = null;
    @listenSock = null;
    routes.Resize(0);
    log("HTTP Server: Shut down");
}

void PollServer()
{
    if (@listenSock is null) return;

    if (@clientSock is null)
    {
        Net::Socket@ newSock = listenSock.Accept(0);
        if (@newSock !is null)
        {
            @clientSock = @newSock;
            requestBuffer = "";
            readWaitFrames = 0;
        }
        return;
    }

    uint avail = clientSock.Available;
    if (avail > 0)
    {
        uint toRead = avail;
        if (requestBuffer.Length + avail > MAX_BUFFER_SIZE)
            toRead = MAX_BUFFER_SIZE - requestBuffer.Length;
        if (toRead > 0)
        {
            requestBuffer += clientSock.ReadString(toRead);
            readWaitFrames = 0;
        }
    }
    else
    {
        readWaitFrames++;
    }

    if (requestBuffer.Length >= MAX_BUFFER_SIZE)
    {
        log("HTTP Server: Request too large, dropping connection");
        @clientSock = null;
        requestBuffer = "";
        return;
    }

    int headerEnd = requestBuffer.FindFirst("\r\n\r\n");
    if (headerEnd >= 0)
    {
        string method = ExtractMethod(requestBuffer);
        if (method == "POST")
        {
            int contentLength = ParseContentLength(requestBuffer);
            uint expectedTotal = uint(headerEnd + 4) + uint(contentLength);
            if (requestBuffer.Length < expectedTotal)
                return;
        }

        ParseRequest(requestBuffer);
        requestCount++;
        DispatchRoute();
        @clientSock = null;
        requestBuffer = "";
    }
    else if (readWaitFrames > MAX_WAIT_FRAMES)
    {
        @clientSock = null;
        requestBuffer = "";
    }
}

void DispatchRoute()
{
    if (requestMethod == "OPTIONS")
    {
        string resp = "HTTP/1.1 204 No Content\r\n";
        resp += "Access-Control-Allow-Origin: *\r\n";
        resp += "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n";
        resp += "Access-Control-Allow-Headers: Content-Type\r\n";
        resp += "Content-Length: 0\r\n";
        resp += "Connection: close\r\n\r\n";
        clientSock.Write(resp);
        return;
    }

    for (uint i = 0; i < routes.Length; i++)
    {
        if (routes[i].method == requestMethod && routes[i].path == requestPath)
        {
            lastRequestPath = requestPath;
            string body = routes[i].handler(requestBody);
            string contentType = "text/html";
            if (requestPath.FindFirst("/api/") == 0)
                contentType = "application/json";
            string response = BuildHttpResponse(200, "OK", contentType, body);
            clientSock.Write(response);
            return;
        }
    }

    lastRequestPath = requestPath;
    string body = "{\"error\":\"not found\",\"path\":\"" + EscapeJson(requestPath) + "\"}";
    string response = BuildHttpResponse(404, "Not Found", "application/json", body);
    clientSock.Write(response);
}

// --- HTTP response ---

string BuildHttpResponse(int statusCode, const string &in statusText, const string &in contentType, const string &in body)
{
    string crlf = "\r\n";
    string resp = "HTTP/1.1 " + Text::FormatInt(statusCode) + " " + statusText + crlf;
    resp += "Content-Type: " + contentType + "; charset=utf-8" + crlf;
    resp += "Content-Length: " + Text::FormatUInt(body.Length) + crlf;
    resp += "Connection: close" + crlf;
    resp += "Access-Control-Allow-Origin: *" + crlf;
    resp += crlf;
    resp += body;
    return resp;
}

// --- String utilities ---

string ReplaceAll(const string &in str, const string &in from, const string &in to)
{
    if (from.Length == 0) return str;

    string result = "";
    int start = 0;
    int idx = str.FindFirst(from, uint(start));
    while (idx >= 0)
    {
        result += str.Substr(uint(start), idx - start);
        result += to;
        start = idx + int(from.Length);
        idx = str.FindFirst(from, uint(start));
    }
    result += str.Substr(uint(start));
    return result;
}

string StripNonAscii(const string &in input)
{
    string result = "";
    for (uint i = 0; i < input.Length; i++)
    {
        uint8 c = input[i];
        if (c >= 0x20 && c < 0x7F)
            result += input.Substr(i, 1);
    }
    return result;
}

string StripControlChars(const string &in input)
{
    string result = "";
    for (uint i = 0; i < input.Length; i++)
    {
        uint8 c = input[i];
        if (c >= 0x20)
            result += input.Substr(i, 1);
    }
    return result;
}

// --- HTML escaping ---

string EscapeHtml(const string &in input)
{
    string result = StripNonAscii(input);
    result = ReplaceAll(result, "&", "&amp;");
    result = ReplaceAll(result, "<", "&lt;");
    result = ReplaceAll(result, ">", "&gt;");
    result = ReplaceAll(result, "\"", "&quot;");
    return result;
}

// --- JSON escaping ---

string EscapeJsonDisplay(const string &in input)
{
    string result = StripNonAscii(input);
    result = ReplaceAll(result, "\\", "\\\\");
    result = ReplaceAll(result, "\"", "\\\"");
    return result;
}

string EscapeJson(const string &in input)
{
    string result = StripControlChars(input);
    result = ReplaceAll(result, "\\", "\\\\");
    result = ReplaceAll(result, "\"", "\\\"");
    return result;
}

// --- JSON helpers ---

string JsonString(const string &in key, const string &in value)
{
    return "\"" + EscapeJson(key) + "\":\"" + EscapeJson(value) + "\"";
}

string JsonStringDisplay(const string &in key, const string &in value)
{
    return "\"" + EscapeJson(key) + "\":\"" + EscapeJsonDisplay(value) + "\"";
}

string JsonInt(const string &in key, int value)
{
    return "\"" + EscapeJson(key) + "\":" + Text::FormatInt(value);
}

string JsonUInt(const string &in key, uint value)
{
    return "\"" + EscapeJson(key) + "\":" + Text::FormatUInt(value);
}

string JsonFloat(const string &in key, float value)
{
    return "\"" + EscapeJson(key) + "\":" + Text::FormatFloat(value, "", 0, 3);
}

string JsonBool(const string &in key, bool value)
{
    return "\"" + EscapeJson(key) + "\":" + (value ? "true" : "false");
}

string JsonVec3(const string &in key, vec3 v)
{
    string obj = "{";
    obj += "\"x\":" + Text::FormatFloat(v.x, "", 0, 3);
    obj += ",\"y\":" + Text::FormatFloat(v.y, "", 0, 3);
    obj += ",\"z\":" + Text::FormatFloat(v.z, "", 0, 3);
    obj += "}";
    return "\"" + EscapeJson(key) + "\":" + obj;
}

// --- URL decoding ---

string CharFromByte(uint8 b)
{
    string s = " ";
    s[0] = b;
    return s;
}

string UrlDecode(const string &in input)
{
    string result = "";
    for (uint i = 0; i < input.Length; i++)
    {
        uint8 c = input[i];
        if (c == 0x2B)
        {
            result += " ";
        }
        else if (c == 0x25 && i + 2 < input.Length)
        {
            string hex = input.Substr(i + 1, 2);
            uint8 val = uint8(Text::ParseUInt(hex, 16));
            result += CharFromByte(val);
            i += 2;
        }
        else
        {
            result += input.Substr(i, 1);
        }
    }
    return result;
}

// --- Form parsing ---

string GetFormValue(const string &in body, const string &in key)
{
    string search = key + "=";
    int idx = body.FindFirst(search);
    while (idx >= 0)
    {
        if (idx == 0 || body[uint(idx - 1)] == 0x26)
        {
            string after = body.Substr(uint(idx) + search.Length);
            int ampIdx = after.FindFirst("&");
            string raw = (ampIdx >= 0) ? after.Substr(0, ampIdx) : after;
            return UrlDecode(raw);
        }
        idx = body.FindFirst(search, uint(idx + 1));
    }
    return "";
}

// --- GameState to string ---

string GameStateToString(TM::GameState state)
{
    if (state == TM::GameState::None) return "None";
    if (state == TM::GameState::GameNetMenus) return "GameNetMenus";
    if (state == TM::GameState::GameNetRoundPrepare) return "GameNetRoundPrepare";
    if (state == TM::GameState::GameNetRoundPlay) return "GameNetRoundPlay";
    if (state == TM::GameState::GameNetRoundExit) return "GameNetRoundExit";
    if (state == TM::GameState::StartUp) return "StartUp";
    if (state == TM::GameState::Menus) return "Menus";
    if (state == TM::GameState::Quit) return "Quit";
    if (state == TM::GameState::LocalInit) return "LocalInit";
    if (state == TM::GameState::LocalEditor) return "LocalEditor";
    if (state == TM::GameState::LocalRace) return "LocalRace";
    if (state == TM::GameState::LocalRaceEndDialog) return "LocalRaceEndDialog";
    if (state == TM::GameState::LocalReplayEditor) return "LocalReplayEditor";
    if (state == TM::GameState::LocalReplay) return "LocalReplay";
    if (state == TM::GameState::LocalEnd) return "LocalEnd";
    if (state == TM::GameState::NetSync) return "NetSync";
    if (state == TM::GameState::NetPlaying) return "NetPlaying";
    if (state == TM::GameState::NetExitRound) return "NetExitRound";
    if (state == TM::GameState::Unknown1) return "Unknown1";
    if (state == TM::GameState::Unknown2) return "Unknown2";
    if (state == TM::GameState::Unknown3) return "Unknown3";
    if (state == TM::GameState::Unknown4) return "Unknown4";
    if (state == TM::GameState::Unknown5) return "Unknown5";
    if (state == TM::GameState::Unknown6) return "Unknown6";
    return "Unknown";
}
namespace InputModification
{
    int cachedStartIndex = -1;
    int cachedMinTime = -1;
    int g_earliestMutationTime = 2147483647;
    void SortBufferManual(TM::InputEventBuffer @buffer, int startIndex = -1)
    {
        if (buffer is null || buffer.Length < 2)
            return;
        uint startCopy = 0;
        if (startIndex != -1)
        {
            startCopy = startIndex + 1;
        }
        if (startCopy >= buffer.Length)
            return;
        array<TM::InputEvent> events;
        for (uint i = startCopy; i < buffer.Length; i++)
        {
            events.Add(buffer[i]);
        }
        for (uint i = 1; i < events.Length; i++)
        {
            TM::InputEvent key = events[i];
            int j = i - 1;
            while (j >= 0 && events[j].Time > key.Time)
            {
                events[j + 1] = events[j];
                j--;
            }
            events[j + 1] = key;
        }
        for (uint i = 0; i < events.Length; i++)
        {
            buffer[startCopy + i] = events[i];
        }
    }
    void MutateInputs(TM::InputEventBuffer @buffer, int inputCount, int minTime, int maxTime, int maxSteerDiff, int maxTimeDiff, bool fillInputs)
    { 
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs)
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        int actualInputCount = Math::Rand(1, inputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                cachedStartIndex = i;
                continue;
            }
            indices.Add(i);
            if (int(evt.Time) - 100010 > maxTime)
                break;
        }
        if (indices.Length == 0)
        {
            print("No inputs found in the specified time frame to modify.", Severity::Warning);
            return;
        }
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(-maxTimeDiff / 10, maxTimeDiff / 10) * 10;
            int steerOffset = Math::Rand(-maxSteerDiff, maxSteerDiff);
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (evt.Value.EventIndex == buffer.EventIndices.SteerId)
            {
                evt.Value.Analog = evt.Value.Analog + steerOffset;
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
    void MutateInputsRange(TM::InputEventBuffer @buffer, int minInputCount, int maxInputCount, int minTime, int maxTime, int minSteer, int maxSteer, int minTimeDiff, int maxTimeDiff, bool fillInputs)
    { 
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs)
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        if (minInputCount > maxInputCount)
        {
            int tmp = minInputCount;
            minInputCount = maxInputCount;
            maxInputCount = tmp;
        }
        if (minInputCount < 1) minInputCount = 1;
        int actualInputCount = Math::Rand(minInputCount, maxInputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                cachedStartIndex = i;
                continue;
            }
            indices.Add(i);
            if (int(evt.Time) - 100010 > maxTime)
                break;
        }
        if (indices.Length == 0)
        {
            print("No inputs found in the specified time frame to modify.", Severity::Warning);
            return;
        }
        if (minTimeDiff > maxTimeDiff)
        {
            int tmp = minTimeDiff;
            minTimeDiff = maxTimeDiff;
            maxTimeDiff = tmp;
        }
        if (minSteer > maxSteer)
        {
            int tmp = minSteer;
            minSteer = maxSteer;
            maxSteer = tmp;
        }
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(minTimeDiff / 10, maxTimeDiff / 10) * 10;
            int newSteerValue = Math::Rand(minSteer, maxSteer);
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (evt.Value.EventIndex == buffer.EventIndices.SteerId)
            {
                evt.Value.Analog = newSteerValue;
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
    void FillInputs(TM::InputEventBuffer @buffer, int maxTime, int minIndex)
    {
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        const int OFFSET = 100010;
        int absMaxTime = OFFSET + maxTime;
        auto indices = buffer.EventIndices;
        array<TM::InputEvent> steer;
        int startIndex = 0;
        int prevSteerState = 0;
        int prevSteerTime = -1;
        bool hasPrevSteer = true;
        if (minIndex > 0 && minIndex < int(buffer.Length))
        {
            startIndex = minIndex;
            for (int i = minIndex - 1; i >= 0; i--)
            {
                if (buffer[i].Value.EventIndex == indices.SteerId)
                {
                    prevSteerState = int(buffer[i].Value.Analog);
                    prevSteerTime = int(buffer[i].Time);
                    break;
                }
            }
        }
        for (uint i = startIndex; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) > absMaxTime)
                break;
            if (evt.Value.EventIndex == indices.SteerId)
            {
                steer.Add(evt);
            }
        }
        uint k = 0;
        const uint steerLen = steer.Length;
        int loopStartTime = 0;
        if (startIndex > 0 && startIndex < int(buffer.Length))
        {
            loopStartTime = int(buffer[startIndex].Time) - OFFSET;
            loopStartTime = (loopStartTime / 10) * 10;
            if (loopStartTime < 0)
                loopStartTime = 0;
        }
        for (int t = loopStartTime; t <= maxTime; t += 10)
        {
            int absT = t + OFFSET;
            bool hadSteerAtT = false;
            while (k < steerLen && int(steer[k].Time) <= absT)
            {
                if (int(steer[k].Time) == absT)
                {
                    hadSteerAtT = true;
                }
                prevSteerState = int(steer[k].Value.Analog);
                prevSteerTime = int(steer[k].Time);
                hasPrevSteer = true;
                k++;
            }
            if (!hadSteerAtT && hasPrevSteer && absT > prevSteerTime)
            {
                buffer.Add(t, InputType::Steer, prevSteerState);
            }
        }
    }
    void MutateInputsByType(TM::InputEventBuffer @buffer, int eventTypeId, int inputCount, int minTime, int maxTime, int maxSteerDiff, int maxTimeDiff, bool fillInputs, bool isBinaryInput)
    {
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs && eventTypeId == int(buffer.EventIndices.SteerId))
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        int actualInputCount = Math::Rand(1, inputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                if (cachedStartIndex < int(i))
                    cachedStartIndex = int(i);
                continue;
            }
            if (int(evt.Time) - 100010 > maxTime)
                break;
            if (int(evt.Value.EventIndex) == eventTypeId)
            {
                indices.Add(i);
            }
        }
        if (indices.Length == 0)
            return;
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(-maxTimeDiff / 10, maxTimeDiff / 10) * 10;
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (isBinaryInput)
            {
                evt.Value.Analog = (evt.Value.Analog == 0) ? 1 : 0;
            }
            else
            {
                int steerOffset = Math::Rand(-maxSteerDiff, maxSteerDiff);
                evt.Value.Analog = evt.Value.Analog + steerOffset;
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
    void MutateInputsRangeByType(TM::InputEventBuffer @buffer, int eventTypeId, int minInputCount, int maxInputCount, int minTime, int maxTime, int minSteer, int maxSteer, int minTimeDiff, int maxTimeDiff, bool fillInputs, bool isBinaryInput)
    {
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs && eventTypeId == int(buffer.EventIndices.SteerId))
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        if (minInputCount > maxInputCount)
        {
            int tmp = minInputCount;
            minInputCount = maxInputCount;
            maxInputCount = tmp;
        }
        if (minInputCount < 1) minInputCount = 1;
        int actualInputCount = Math::Rand(minInputCount, maxInputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                if (cachedStartIndex < int(i))
                    cachedStartIndex = int(i);
                continue;
            }
            if (int(evt.Time) - 100010 > maxTime)
                break;
            if (int(evt.Value.EventIndex) == eventTypeId)
            {
                indices.Add(i);
            }
        }
        if (indices.Length == 0)
            return;
        if (minTimeDiff > maxTimeDiff)
        {
            int tmp = minTimeDiff;
            minTimeDiff = maxTimeDiff;
            maxTimeDiff = tmp;
        }
        if (minSteer > maxSteer)
        {
            int tmp = minSteer;
            minSteer = maxSteer;
            maxSteer = tmp;
        }
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(minTimeDiff / 10, maxTimeDiff / 10) * 10;
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (isBinaryInput)
            {
                evt.Value.Analog = (evt.Value.Analog == 0) ? 1 : 0;
            }
            else
            {
                evt.Value.Analog = Math::Rand(minSteer, maxSteer);
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
}
PluginInfo @GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Bruteforce V2 + Dashboard";
    info.Author = "Skycrafter";
    info.Version = "2.0-dashboard-1";
    info.Description = "Next generation bruteforce with web dashboard";
    return info;
}
void Main()
{
    InitializeInputModAlgorithms();
    RegisterValidationHandler("bfv2", "Bruteforce V2", BruteforceV2Settings);
    RegisterVariable("bf_iterations_before_restart", 0);
    RegisterVariable("bf_result_folder", "");
    RegisterVariable("bf_condition_script", "");
    RegisterVariable("bf_condition_script_height", 26);
    RegisterVariable("bf_restart_condition_script", "");
    RegisterVariable("bf_restart_condition_script_height", 26);
    RegisterVariable("bf_condition_trigger", 0);
    RegisterVariable("bf_input_mod_count", 1);
    RegisterVariable("bf_input_mod_algorithm", "basic");
    RegisterVariable("bf_range_min_input_count", 1);
    RegisterVariable("bf_range_max_input_count", 1);
    RegisterVariable("bf_range_min_steer", -65536);
    RegisterVariable("bf_range_max_steer", 65536);
    RegisterVariable("bf_range_min_time_diff", 0);
    RegisterVariable("bf_range_max_time_diff", 0);
    RegisterVariable("bf_range_fill_steer", false);
    RegisterVariable("bf_adv_steer_modify_count", 0);
    RegisterVariable("bf_adv_steer_min_time", 0);
    RegisterVariable("bf_adv_steer_max_time", 0);
    RegisterVariable("bf_adv_steer_max_diff", 0);
    RegisterVariable("bf_adv_steer_max_time_diff", 0);
    RegisterVariable("bf_adv_steer_fill", false);
    RegisterVariable("bf_adv_accel_modify_count", 0);
    RegisterVariable("bf_adv_accel_min_time", 0);
    RegisterVariable("bf_adv_accel_max_time", 0);
    RegisterVariable("bf_adv_accel_max_time_diff", 0);
    RegisterVariable("bf_adv_brake_modify_count", 0);
    RegisterVariable("bf_adv_brake_min_time", 0);
    RegisterVariable("bf_adv_brake_max_time", 0);
    RegisterVariable("bf_adv_brake_max_time_diff", 0);
    RegisterVariable("bf_advr_steer_min_input_count", 1);
    RegisterVariable("bf_advr_steer_max_input_count", 1);
    RegisterVariable("bf_advr_steer_min_time", 0);
    RegisterVariable("bf_advr_steer_max_time", 0);
    RegisterVariable("bf_advr_steer_min_steer", -65536);
    RegisterVariable("bf_advr_steer_max_steer", 65536);
    RegisterVariable("bf_advr_steer_min_time_diff", 0);
    RegisterVariable("bf_advr_steer_max_time_diff", 0);
    RegisterVariable("bf_advr_steer_fill", false);
    RegisterVariable("bf_advr_accel_min_input_count", 1);
    RegisterVariable("bf_advr_accel_max_input_count", 1);
    RegisterVariable("bf_advr_accel_min_time", 0);
    RegisterVariable("bf_advr_accel_max_time", 0);
    RegisterVariable("bf_advr_accel_min_time_diff", 0);
    RegisterVariable("bf_advr_accel_max_time_diff", 0);
    RegisterVariable("bf_advr_brake_min_input_count", 1);
    RegisterVariable("bf_advr_brake_max_input_count", 1);
    RegisterVariable("bf_advr_brake_min_time", 0);
    RegisterVariable("bf_advr_brake_max_time", 0);
    RegisterVariable("bf_advr_brake_min_time_diff", 0);
    RegisterVariable("bf_advr_brake_max_time_diff", 0);
    PreciseFinishBf::Main();
    PreciseCheckpointBf::Main();
    PreciseTriggerBf::Main();
    StandardTriggerBf::Main();
    SinglePointBf::Main();
    VelocityBf::Main();
    SkyBf::Main();
    CarLocationBf::Main();
    TimeBf::Main();
    CustomTargetBf::Main();
    RegisterSettingsPage("Scripting Docs", ScriptingReference::Render);

    RegisterRoute("GET", "/api/bf/status", HandleGetBfStatus);
    RegisterRoute("GET", "/api/bf/log", HandleGetBfLog);
    RegisterRoute("GET", "/api/bf/improvements", HandleGetBfImprovements);
    RegisterRoute("GET", "/api/bf/settings", HandleGetBfSettings);
    RegisterRoute("GET", "/api/bf/all-settings", HandleGetAllSettings);
    RegisterRoute("GET", "/api/bf/sessions", HandleGetBfSessions);
    RegisterRoute("GET", "/api/bf/session-log", HandleGetSessionLog);
    RegisterRoute("GET", "/api/bf/session-imp", HandleGetSessionImp);
    RegisterRoute("POST", "/api/bf/set", HandlePostSetVar);
    RegisterRoute("POST", "/api/bf/add-slot", HandlePostAddSlot);
    RegisterRoute("POST", "/api/bf/remove-slot", HandlePostRemoveSlot);
    RegisterRoute("POST", "/api/bf/copy-position", HandleCopyPosition);
    RegisterRoute("POST", "/api/bf/delete-session", HandleDeleteSession);
    RegisterRoute("POST", "/api/bf/set-batch", HandlePostSetBatch);
    RegisterRoute("GET", "/api/map", HandleGetMap);
    RegisterRoute("GET", "/", HandleBfDashboard);
    StartServer("127.0.0.1", 8081);
}
void Render()
{
    PollServer();
    if (current !is null && current.onRender !is null)
        current.onRender();
}
void OnDisabled()
{
    StopServer();
}
namespace PreciseCheckpointBf
{
    int targetCp;
    double bestTime = -1;
    int bestTimeMsImprecise = -1;
    bool conditionsMetBeforeCompute = false;
    void RenderEvalSettings()
    {
        targetCp = UI::InputIntVar("Target Checkpoint Index", "bf_target_cp");
    }
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        int raceTime = simManager.RaceTime;
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        bool hasCp = int(simManager.PlayerInfo.CurCheckpointCount) >= targetCp;
        if (info.Phase == BFPhase::Search && !PreciseFinish::IsEstimating && bestTimeMsImprecise != -1)
        {
            if (hasCp && raceTime < bestTimeMsImprecise)
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
        if (hasCp && !PreciseFinish::IsEstimating)
        {
            conditionsMetBeforeCompute = GlobalConditionsMet(simManager);
        }
        bool calculationDone = PreciseFinish::Compute(simManager, hasCp, preciseTime);
        if (!calculationDone)
        {
            return resp;
        }
        if (!conditionsMetBeforeCompute)
        {
            if (info.Phase == BFPhase::Initial)
            {
                print("Base run hit checkpoint but conditions not met. Search will require meeting these conditions.", Severity::Warning);
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
                print("Precise checkpoint time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            else
                print("Base run checkpoint time: " + Text::FormatFloat(preciseTime, "", 0, 9));
            bestTime = preciseTime;
            bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
            resp.Decision = BFEvaluationDecision::Accept;
            resp.ResultFileStartContent = "# Precise Checkpoint Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
        }
        else
        {
            if (preciseTime < bestTime)
            {
                bestTime = preciseTime;
                bestTimeMsImprecise = PreciseFinish::StateBeforeHitTime;
                resp.Decision = BFEvaluationDecision::Accept;
                resp.ResultFileStartContent = "# Precise Checkpoint Time: " + Text::FormatFloat(bestTime, "", 0, 9) + " s";
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
        targetCp = int(GetVariableDouble("bf_target_cp"));
    }
    void Main()
    {
        auto bfEval = RegisterBruteforceEval("precisecheckpoint", "Checkpoint", OnEvaluate, RenderEvalSettings);
        @bfEval.onSimBegin = @OnSimulationBegin;
    }
}
namespace PreciseFinish
{
    bool IsEstimating = false;
    uint64 CoeffMin = 0;
    uint64 CoeffMax = 18446744073709551615;
    SimulationState @StateBeforeHit;
    SimulationState @StateAtHit;
    int StateBeforeHitTime = -1;
    int StateAtHitTime = -1;
    bool done = false;
    double localResult = -1;
    uint Precision = 1;
    void Reset()
    {
        IsEstimating = false;
        CoeffMin = 0;
        CoeffMax = 18446744073709551615;
        @StateBeforeHit = null;
        @StateAtHit = null;
        StateAtHitTime = -1;
        StateBeforeHitTime = -1;
        localResult = -1;
        done = false;
    }
    bool Compute(SimulationManager @sim, bool targetReached, double &out result)
    {
        if (done)
        {
            result = localResult;
            return true;
        }
        if (!IsEstimating)
        {
            if (targetReached)
            {
                IsEstimating = true;
                @StateAtHit = sim.SaveState();
                StateAtHitTime = sim.RaceTime;
                CoeffMin = 0;
                CoeffMax = 18446744073709551615;
                if (StateBeforeHit is null)
                {
                    result = double(sim.RaceTime) / 1000.0;
                    return true;
                }
            }
            else
            {
                @StateBeforeHit = sim.SaveState();
                StateBeforeHitTime = sim.RaceTime;
                return false;
            }
        }
        else
        {
            if (targetReached)
            {
                CoeffMax = CoeffMin + (CoeffMax - CoeffMin) / 2;
            }
            else
            {
                CoeffMin = CoeffMin + (CoeffMax - CoeffMin) / 2;
            }
        }
        if (CoeffMax - CoeffMin <= Precision)
        {
            IsEstimating = false;
            uint64 currentCoeff = CoeffMin + (CoeffMax - CoeffMin) / 2;
            double currentCoeffPercentage = double(currentCoeff) / 18446744073709551615.0;
            result = (double(StateBeforeHitTime) / 1000.0) + (currentCoeffPercentage * 0.01);
            if (StateAtHit !is null)
            {
                sim.RewindToState(StateAtHit);
            }
            else if (StateBeforeHit !is null)
            {
                sim.RewindToState(StateBeforeHit);
            }
            localResult = result;
            @StateBeforeHit = null;
            @StateAtHit = null;
            done = true;
            return true;
        }
        sim.RewindToState(StateBeforeHit);
        uint64 currentCoeff = CoeffMin + (CoeffMax - CoeffMin) / 2;
        double currentCoeffPercentage = double(currentCoeff) / 18446744073709551615.0;
        sim.Dyna.CurrentState.LinearSpeed = sim.Dyna.CurrentState.LinearSpeed * currentCoeffPercentage;
        sim.Dyna.CurrentState.AngularSpeed = sim.Dyna.CurrentState.AngularSpeed * currentCoeffPercentage;
        return false;
    }
}
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
namespace Scripting
{
    bool StartsWith(const string &in str, const string &in prefix)
    {
        if (str.Length < prefix.Length)
            return false;
        return str.Substr(0, prefix.Length) == prefix;
    }
    bool EndsWith(const string &in str, const string &in suffix)
    {
        if (str.Length < suffix.Length)
            return false;
        return str.Substr(str.Length - suffix.Length) == suffix;
    }
    string ToLower(const string &in input)
    {
        string output = input;
        for (uint i = 0; i < output.Length; i++)
        {
            uint8 c = output[i];
            if (c >= 65 && c <= 90)
                output[i] = c + 32;
        }
        return output;
    }
    funcdef bool ConditionCallback(SimulationManager @sim);
    funcdef float FloatGetter(SimulationManager @sim);
    funcdef vec3 Vec3Getter(SimulationManager @sim);
    float GetCarX(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position.x; }
    float GetCarY(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position.y; }
    float GetCarZ(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position.z; }
    float GetCarVelX(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.x; }
    float GetCarVelY(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.y; }
    float GetCarVelZ(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.z; }
    float GetCarLocalVelX(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.x; }
    float GetCarLocalVelY(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.y; }
    float GetCarLocalVelZ(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.z; }
    float GetCarLocalSpeed(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.Length(); }
    float GetCarPitch(SimulationManager @sim)
    {
        float x, y, z;
        sim.Dyna.CurrentState.Quat.GetYawPitchRoll(x, y, z);
        return y;
    }
    float GetCarYaw(SimulationManager @sim)
    {
        float x, y, z;
        sim.Dyna.CurrentState.Quat.GetYawPitchRoll(x, y, z);
        return x;
    }
    float GetCarRoll(SimulationManager @sim)
    {
        float x, y, z;
        sim.Dyna.CurrentState.Quat.GetYawPitchRoll(x, y, z);
        return z;
    }
    float GetCarSpeed(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.Length(); }
    float GetCarFreewheel(SimulationManager @sim) { return sim.SceneVehicleCar.IsFreeWheeling ? 1.0f : 0.0f; }
    float GetCarLateralContact(SimulationManager @sim) { return sim.SceneVehicleCar.HasAnyLateralContact ? 1.0f : 0.0f; }
    float GetCarSliding(SimulationManager @sim) { return sim.SceneVehicleCar.IsSliding ? 1.0f : 0.0f; }
    float GetCarGear(SimulationManager @sim) { return sim.SceneVehicleCar.CarEngine.RearGear==1 ? -1.0f : float(sim.SceneVehicleCar.CarEngine.Gear); }
    float GetWheelFLGroundContact(SimulationManager @sim) { return sim.Wheels.FrontLeft.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelFRGroundContact(SimulationManager @sim) { return sim.Wheels.FrontRight.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelBLGroundContact(SimulationManager @sim) { return sim.Wheels.BackLeft.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelBRGroundContact(SimulationManager @sim) { return sim.Wheels.BackRight.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelFLSurface(SimulationManager @sim) { return float(sim.Wheels.FrontLeft.RTState.ContactMaterialId); }
    float GetWheelFRSurface(SimulationManager @sim) { return float(sim.Wheels.FrontRight.RTState.ContactMaterialId); }
    float GetWheelBLSurface(SimulationManager @sim) { return float(sim.Wheels.BackLeft.RTState.ContactMaterialId); }
    float GetWheelBRSurface(SimulationManager @sim) { return float(sim.Wheels.BackRight.RTState.ContactMaterialId); }
    vec3 GetCarPos(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position; }
    vec3 GetCarVel(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed; }
    vec3 GetCarLocalVel(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed; }
    float GetIterationCount(SimulationManager @sim)
    {
        return float(info.Iterations);
    }
    float GetTimeLastImprovement(SimulationManager @sim)
    {
        return float(lastImprovementTime / 1000.0);
    }
    float GetTimeLastRestart(SimulationManager @sim)
    {
        return float(lastRestartTime / 1000.0);
    }
    class ConstantFloat
    {
        float val;
        ConstantFloat(float v) { val = v; }
        float Get(SimulationManager @sim) { return val; }
    }
    class ConstantVec3
    {
        vec3 val;
        ConstantVec3(vec3 v) { val = v; }
        vec3 Get(SimulationManager @sim) { return val; }
    }
    class VarFloat
    {
        string name;
        VarFloat(const string &in n) { name = n; }
        float Get(SimulationManager @sim) { return float(GetVariableDouble(name)); }
    }
    class VarVec3
    {
        string name;
        VarVec3(const string &in n) { name = n; }
        vec3 Get(SimulationManager @sim) { return Text::ParseVec3(GetVariableString(name)); }
    }
    class MathOp
    {
        FloatGetter @left;
        FloatGetter @right;
        string op;
        MathOp(FloatGetter @l, FloatGetter @r, const string &in o)
        {
            @left = l;
            @right = r;
            op = o;
        }
        float Get(SimulationManager @sim)
        {
            float l = left(sim);
            float r = right(sim);
            if (op == "+")
                return l + r;
            if (op == "-")
                return l - r;
            if (op == "*")
                return l * r;
            if (op == "/")
                return r != 0.0f ? l / r : 0.0f;
            return 0.0f;
        }
    }
    class FunctionKmh
    {
        FloatGetter @arg;
        FunctionKmh(FloatGetter @a) { @arg = a; }
        float Get(SimulationManager @sim) { return arg(sim) * 3.6f; }
    }
    class FunctionDeg
    {
        FloatGetter @arg;
        FunctionDeg(FloatGetter @a) { @arg = a; }
        float Get(SimulationManager @sim) { return arg(sim) * 180.0f / 3.14159265358979323846f; }
    }
    class FunctionDistance
    {
        Vec3Getter @p1;
        Vec3Getter @p2;
        FunctionDistance(Vec3Getter @a, Vec3Getter @b)
        {
            @p1 = a;
            @p2 = b;
        }
        float Get(SimulationManager @sim) { return Math::Distance(p1(sim), p2(sim)); }
    }
    class FunctionTimeSince
    {
        FloatGetter @arg;
        FunctionTimeSince(FloatGetter @a) { @arg = a; }
        float Get(SimulationManager @sim)
        {
            return (float(Time::Now) / 1000.0f) - arg(sim);
        }
    }
    enum CmpOp { Gt,
                 Lt,
                 GtEq,
                 LtEq,
                 Eq }
    class Comparison
    {
        FloatGetter @left;
        FloatGetter @right;
        CmpOp op;
        Comparison(FloatGetter @l, FloatGetter @r, CmpOp o)
        {
            @left = l;
            @right = r;
            op = o;
        }
        bool Evaluate(SimulationManager @sim)
        {
            float l = left(sim);
            float r = right(sim);
            switch (op)
            {
            case CmpOp::Gt:
                return l > r;
            case CmpOp::Lt:
                return l < r;
            case CmpOp::GtEq:
                return l >= r;
            case CmpOp::LtEq:
                return l <= r;
            case CmpOp::Eq:
                return l == r;
            }
            return false;
        }
    }
    string CleanSource(const string &in input)
    {
        string output = "";
        string temp = " ";
        bool insideQuote = false;
        for (uint i = 0; i < input.Length; i++)
        {
            uint8 c = input[i];
            if (c == 34)
                insideQuote = !insideQuote;
            if (insideQuote || c != 32)
            {
                temp[0] = c;
                output += temp;
            }
        }
        return output;
    }
    int FindTopLevel(const string &in code, const string &in target, int start = 0)
    {
        int depth = 0;
        int targetLen = target.Length;
        for (uint i = start; i < code.Length; i++)
        {
            uint8 c = code[i];
            if (c == 40)
                depth++;
            else if (c == 41)
                depth--;
            else if (depth == 0)
            {
                if (code.Substr(i, targetLen) == target)
                    return i;
            }
        }
        return -1;
    }
    ConditionCallback @Compile(const string &in source)
    {
        string code = CleanSource(source);
        if (code == "")
            return null;
        CmpOp op;
        int idx = -1;
        int len = 1;
        if ((idx = FindTopLevel(code, ">=")) != -1)
        {
            op = CmpOp::GtEq;
            len = 2;
        }
        else if ((idx = FindTopLevel(code, "<=")) != -1)
        {
            op = CmpOp::LtEq;
            len = 2;
        }
        else if ((idx = FindTopLevel(code, ">")) != -1)
        {
            op = CmpOp::Gt;
        }
        else if ((idx = FindTopLevel(code, "<")) != -1)
        {
            op = CmpOp::Lt;
        }
        else if ((idx = FindTopLevel(code, "=")) != -1)
        {
            op = CmpOp::Eq;
        }
        if (idx == -1)
        {
            return null;
        }
        string lhs = code.Substr(0, idx);
        string rhs = code.Substr(idx + len);
        FloatGetter @leftGetter = ParseExpression(lhs);
        FloatGetter @rightGetter = ParseExpression(rhs);
        if (leftGetter is null || rightGetter is null)
            return null;
        Comparison @comp = Comparison(leftGetter, rightGetter, op);
        return ConditionCallback(comp.Evaluate);
    }
    class MultiCondition
    {
        array<ConditionCallback @> conditions;
        void Add(ConditionCallback @cb)
        {
            conditions.Add(cb);
        }
        bool Evaluate(SimulationManager @sim)
        {
            for (uint i = 0; i < conditions.Length; i++)
            {
                if (!conditions[i](sim))
                    return false;
            }
            return true;
        }
    }
    ConditionCallback @CompileMulti(const array<string> &in sources)
    {
        MultiCondition @multi = MultiCondition();
        for (uint i = 0; i < sources.Length; i++)
        {
            string s = sources[i];
            if (CleanSource(s) == "")
                continue;
            ConditionCallback @cb = Compile(s);
            if (cb is null)
                return null;
            multi.Add(cb);
        }
        if (multi.conditions.Length == 0)
            return null;
        return ConditionCallback(multi.Evaluate);
    }
    FloatGetter @ParseExpression(const string &in code)
    {
        int idx = -1;
        string opStr = "";
        int depth = 0;
        for (int i = int(code.Length) - 1; i >= 0; i--)
        {
            if (code[i] == 41)
                depth++;
            else if (code[i] == 40)
                depth--;
            else if (depth == 0)
            {
                if (code[i] == 43)
                {
                    idx = i;
                    opStr = "+";
                    break;
                }
                if (code[i] == 45 && i > 0)
                {
                    idx = i;
                    opStr = "-";
                    break;
                }
            }
        }
        if (idx != -1)
        {
            FloatGetter @left = ParseExpression(code.Substr(0, idx));
            FloatGetter @right = ParseTerm(code.Substr(idx + 1));
            if (left is null || right is null)
                return null;
            MathOp @math = MathOp(left, right, opStr);
            return FloatGetter(math.Get);
        }
        return ParseTerm(code);
    }
    FloatGetter @ParseTerm(const string &in code)
    {
        int idx = -1;
        string opStr = "";
        int depth = 0;
        for (int i = int(code.Length) - 1; i >= 0; i--)
        {
            if (code[i] == 41)
                depth++;
            else if (code[i] == 40)
                depth--;
            else if (depth == 0)
            {
                if (code[i] == 42)
                {
                    idx = i;
                    opStr = "*";
                    break;
                }
                if (code[i] == 47)
                {
                    idx = i;
                    opStr = "/";
                    break;
                }
            }
        }
        if (idx != -1)
        {
            FloatGetter @left = ParseTerm(code.Substr(0, idx));
            FloatGetter @right = ParseFactor(code.Substr(idx + 1));
            if (left is null || right is null)
                return null;
            MathOp @math = MathOp(left, right, opStr);
            return FloatGetter(math.Get);
        }
        return ParseFactor(code);
    }
    FloatGetter @ParseFactor(const string &in input)
    {
        string t = input;
        string lower = ToLower(t);
        if (StartsWith(t, "(") && EndsWith(t, ")"))
        {
            return ParseExpression(t.Substr(1, t.Length - 2));
        }
        if (StartsWith(lower, "kmh(") && EndsWith(t, ")"))
        {
            string argStr = t.Substr(4, t.Length - 5);
            FloatGetter @arg = ParseExpression(argStr);
            if (arg is null)
                return null;
            FunctionKmh @fn = FunctionKmh(arg);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "deg(") && EndsWith(t, ")"))
        {
            string argStr = t.Substr(4, t.Length - 5);
            FloatGetter @arg = ParseExpression(argStr);
            if (arg is null)
                return null;
            FunctionDeg @fn = FunctionDeg(arg);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "distance(") && EndsWith(t, ")"))
        {
            string content = t.Substr(9, t.Length - 10);
            int commaIdx = FindTopLevel(content, ",");
            if (commaIdx == -1)
                return null;
            string arg1 = content.Substr(0, commaIdx);
            string arg2 = content.Substr(commaIdx + 1);
            Vec3Getter @v1 = ParseVec3(arg1);
            Vec3Getter @v2 = ParseVec3(arg2);
            if (v1 is null || v2 is null)
                return null;
            FunctionDistance @fn = FunctionDistance(v1, v2);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "time_since(") && EndsWith(t, ")"))
        {
            string content = t.Substr(11, t.Length - 12);
            FloatGetter @arg = ParseExpression(content);
            if (arg is null)
                return null;
            FunctionTimeSince @fn = FunctionTimeSince(arg);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "variable(") && EndsWith(t, ")"))
        {
            string content = t.Substr(9, t.Length - 10);
            if (StartsWith(content, "\"") && EndsWith(content, "\""))
            {
                content = content.Substr(1, content.Length - 2);
            }
            VarFloat @v = VarFloat(content);
            return FloatGetter(v.Get);
        }
        if (lower == "car.position.x" || lower == "car.x")
            return GetCarX;
        if (lower == "car.position.y" || lower == "car.y")
            return GetCarY;
        if (lower == "car.position.z" || lower == "car.z")
            return GetCarZ;
        if (lower == "car.velocity.x" || lower == "car.vel.x")
            return GetCarVelX;
        if (lower == "car.velocity.y" || lower == "car.vel.y")
            return GetCarVelY;
        if (lower == "car.velocity.z" || lower == "car.vel.z")
            return GetCarVelZ;
        if (lower == "car.localvelocity.x" || lower == "car.localvel.x")
            return GetCarLocalVelX;
        if (lower == "car.localvelocity.y" || lower == "car.localvel.y")
            return GetCarLocalVelY;
        if (lower == "car.localvelocity.z" || lower == "car.localvel.z")
            return GetCarLocalVelZ;
        if (lower == "car.localspeed")
            return GetCarLocalSpeed;
        if (lower == "car.rotation.pitch" || lower == "car.pitch")
            return GetCarPitch;
        if (lower == "car.rotation.yaw" || lower == "car.yaw")
            return GetCarYaw;
        if (lower == "car.rotation.roll" || lower == "car.roll")
            return GetCarRoll;
        if (lower == "car.speed")
            return GetCarSpeed;
        if (lower == "car.freewheel")
            return GetCarFreewheel;
        if (lower == "car.lateralcontact")
            return GetCarLateralContact;
        if (lower == "car.sliding")
            return GetCarSliding;
        if (lower == "car.gear")
            return GetCarGear;
        if (lower == "car.wheels.frontleft.groundcontact")
            return GetWheelFLGroundContact;
        if (lower == "car.wheels.frontright.groundcontact")
            return GetWheelFRGroundContact;
        if (lower == "car.wheels.backleft.groundcontact")
            return GetWheelBLGroundContact;
        if (lower == "car.wheels.backright.groundcontact")
            return GetWheelBRGroundContact;
        if (lower == "car.wheels.frontleft.surface")
            return GetWheelFLSurface;
        if (lower == "car.wheels.frontright.surface")
            return GetWheelFRSurface;
        if (lower == "car.wheels.backleft.surface")
            return GetWheelBLSurface;
        if (lower == "car.wheels.backright.surface")
            return GetWheelBRSurface;
        if (lower == "last_improvement.time")
            return GetTimeLastImprovement;
        if (lower == "last_restart.time")
            return GetTimeLastRestart;
        if (lower == "iterations")
            return GetIterationCount;
        if (lower.Length > 0 && lower.FindFirstNotOf("0123456789.-") == -1)
        {
            ConstantFloat @c = ConstantFloat(Text::ParseFloat(lower));
            return FloatGetter(c.Get);
        }
        return null;
    }
    Vec3Getter @ParseVec3(const string &in input)
    {
        string t = input;
        string lower = ToLower(t);
        if (StartsWith(t, "(") && EndsWith(t, ")"))
        {
            string content = t.Substr(1, t.Length - 2);
            array<string> parts = content.Split(",");
            if (parts.Length == 3)
            {
                vec3 v(Text::ParseFloat(parts[0]), Text::ParseFloat(parts[1]), Text::ParseFloat(parts[2]));
                ConstantVec3 @c = ConstantVec3(v);
                return Vec3Getter(c.Get);
            }
        }
        if (StartsWith(lower, "variable(") && EndsWith(t, ")"))
        {
            string content = t.Substr(9, t.Length - 10);
            if (StartsWith(content, "\"") && EndsWith(content, "\""))
            {
                content = content.Substr(1, content.Length - 2);
            }
            VarVec3 @v = VarVec3(content);
            return Vec3Getter(v.Get);
        }
        if (lower == "car.position" || lower == "car.pos")
            return GetCarPos;
        if (lower == "car.velocity" || lower == "car.vel")
            return GetCarVel;
        if (lower == "car.localvelocity" || lower == "car.localvel")
            return GetCarLocalVel;
        return null;
    }
}
namespace ScriptingReference
{
    void SectionHeader(const string &in title)
    {
        UI::Dummy(vec2(0, 6));
        UI::PushStyleColor(UI::Col::Text, vec4(1.0, 0.85, 0.3, 1.0));
        UI::Text(title);
        UI::PopStyleColor();
        UI::Separator();
        UI::Dummy(vec2(0, 2));
    }
    void SubHeader(const string &in title)
    {
        UI::Dummy(vec2(0, 3));
        UI::PushStyleColor(UI::Col::Text, vec4(0.5, 0.85, 1.0, 1.0));
        UI::Text(title);
        UI::PopStyleColor();
        UI::Dummy(vec2(0, 1));
    }
    uint copyId = 0;
    void Code(const string &in code)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + code);
        UI::PopStyleColor();
        UI::SameLine();
        if (UI::Button("Copy##c" + copyId++))
            IO::SetClipboard(code);
    }
    void CodeNoCopy(const string &in code)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + code);
        UI::PopStyleColor();
    }
    void CodeBlock(const string &in line1, const string &in line2)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + line1);
        UI::Text("  " + line2);
        UI::PopStyleColor();
        UI::SameLine();
        if (UI::Button("Copy##c" + copyId++))
            IO::SetClipboard(line1 + "\n" + line2);
    }
    void CodeBlock3(const string &in l1, const string &in l2, const string &in l3)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + l1);
        UI::Text("  " + l2);
        UI::Text("  " + l3);
        UI::PopStyleColor();
        UI::SameLine();
        if (UI::Button("Copy##c" + copyId++))
            IO::SetClipboard(l1 + "\n" + l2 + "\n" + l3);
    }
    void Desc(const string &in text)
    {
        UI::TextDimmed("    " + text);
    }
    void VarRow(const string &in name, const string &in desc)
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text(name);
        UI::PopStyleColor();
        UI::SameLine();
        string copyName = name;
        int slashPos = copyName.FindFirst(" /");
        if (slashPos != -1)
            copyName = copyName.Substr(0, slashPos);
        while (copyName.Length > 0 && copyName[copyName.Length - 1] == 32)
            copyName = copyName.Substr(0, copyName.Length - 1);
        if (UI::Button("Copy##v" + copyId++))
            IO::SetClipboard(copyName);
        UI::TableSetColumnIndex(1);
        UI::TextDimmed(desc);
    }
    void SurfaceRow(const string &in id, const string &in name, const string &in id2, const string &in name2)
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text(id);
        UI::TableSetColumnIndex(1);
        UI::TextDimmed(name);
        UI::TableSetColumnIndex(2);
        UI::Text(id2);
        UI::TableSetColumnIndex(3);
        UI::TextDimmed(name2);
    }
    void Render()
    {
        copyId = 0;
        UI::PushStyleColor(UI::Col::Text, vec4(1, 1, 1, 0.95));
        UI::TextWrapped("This page documents the scripting language used in Condition Scripts, Restart Condition Scripts, and Custom Target Scripts. All three share the same expression language.");
        UI::PopStyleColor();
        UI::Dummy(vec2(0, 4));
        if (UI::CollapsingHeader("Condition Script"))
        {
            UI::Dummy(vec2(0, 2));
            UI::TextWrapped("Used in the Conditions and Restart Condition fields. Each line is a boolean comparison. All lines must be true (AND logic).");
            SubHeader("Format");
            CodeNoCopy("EXPRESSION  OPERATOR  EXPRESSION");
            UI::Dummy(vec2(0, 2));
            UI::TextDimmed("  Operators:  >  <  >=  <=  =");
            SubHeader("Examples");
            Code("kmh(car.speed) > 500");
            Desc("Speed must exceed 500 km/h");
            UI::Dummy(vec2(0, 1));
            Code("car.z < 10.5");
            Desc("Z position must be below 10.5");
            UI::Dummy(vec2(0, 1));
            CodeBlock("deg(car.pitch) > 80", "car.wheels.frontleft.groundcontact = 1");
            Desc("Nose up and front-left wheel touching ground");
            UI::Dummy(vec2(0, 1));
            Code("distance(car.pos, (105.5, 20.0, 300.0)) < 5.0");
            Desc("Car within 5m of a fixed point");
            UI::Dummy(vec2(0, 1));
            Code("distance(car.pos, variable(\"bf_target_point\")) < 3.0");
            Desc("Car within 3m of the single point BF target");
            UI::Dummy(vec2(0, 1));
            Code("car.wheels.frontleft.surface = 2");
            Desc("Front-left wheel is on Grass (ID 2)");
            UI::Dummy(vec2(0, 1));
            Code("time_since(last_improvement.time) > 60");
            Desc("Restart if no improvement for 60 seconds");
            UI::Dummy(vec2(0, 1));
            Code("time_since(last_restart.time) > 60*5");
            Desc("Restart every 5 minutes");
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Custom Target Script"))
        {
            UI::Dummy(vec2(0, 2));
            UI::TextWrapped("Used in the Custom Target bruteforce evaluation. Each line defines an optimization objective instead of a boolean condition.");
            SubHeader("Directives");
            if (UI::BeginTable("##directives_table", 2))
            {
                UI::TableSetupColumn("Directive");
                UI::TableSetupColumn("Meaning");
                VarRow("min EXPR", "Minimize the expression (lower is better)");
                VarRow("max EXPR", "Maximize the expression (higher is better)");
                VarRow("target VALUE EXPR", "Get expression as close to VALUE as possible");
                UI::EndTable();
            }
            UI::Dummy(vec2(0, 2));
            UI::TextDimmed("  Lines starting with # are comments. Blank lines are ignored.");
            SubHeader("Multi-Objective (Pareto)");
            UI::TextWrapped("  When multiple directives are used, a run is accepted only if it improves at least one objective without worsening any other.");
            SubHeader("Examples");
            Code("max car.speed");
            Desc("Maximize raw speed");
            UI::Dummy(vec2(0, 1));
            Code("target 500 car.x");
            Desc("Get car.x as close to 500 as possible");
            UI::Dummy(vec2(0, 1));
            Code("min distance(car.pos, (105.5, 20.0, 300.0))");
            Desc("Minimize distance to a point");
            UI::Dummy(vec2(0, 1));
            CodeBlock("max kmh(car.speed)", "target 200 car.x");
            Desc("Maximize speed while keeping car.x near 200");
            UI::Dummy(vec2(0, 1));
            CodeBlock("# Optimize for altitude", "max car.y");
            Desc("Comments are allowed with #");
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Variables Reference"))
        {
            UI::Dummy(vec2(0, 2));
            SubHeader("Position");
            if (UI::BeginTable("##vars_pos", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.x  /  car.position.x", "X position");
                VarRow("car.y  /  car.position.y", "Y position (height)");
                VarRow("car.z  /  car.position.z", "Z position");
                UI::EndTable();
            }
            SubHeader("Velocity");
            if (UI::BeginTable("##vars_vel", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.vel.x  /  car.velocity.x", "X velocity, world (m/s)");
                VarRow("car.vel.y  /  car.velocity.y", "Y velocity, world (m/s)");
                VarRow("car.vel.z  /  car.velocity.z", "Z velocity, world (m/s)");
                VarRow("car.speed", "Total speed (m/s)");
                VarRow("car.localvel.x", "X velocity, car-relative (m/s)");
                VarRow("car.localvel.y", "Y velocity, car-relative (m/s)");
                VarRow("car.localvel.z", "Z velocity, car-relative (m/s)");
                VarRow("car.localspeed", "Total local speed (m/s)");
                UI::EndTable();
            }
            SubHeader("Rotation");
            if (UI::BeginTable("##vars_rot", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.yaw  /  car.rotation.yaw", "Yaw angle (radians)");
                VarRow("car.pitch  /  car.rotation.pitch", "Pitch angle (radians)");
                VarRow("car.roll  /  car.rotation.roll", "Roll angle (radians)");
                UI::EndTable();
            }
            SubHeader("Vehicle State");
            if (UI::BeginTable("##vars_state", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.freewheel", "1 if freewheeling, 0 otherwise");
                VarRow("car.lateralcontact", "1 if lateral contact, 0 otherwise");
                VarRow("car.sliding", "1 if sliding, 0 otherwise");
                VarRow("car.gear", "Current gear (-1 = reverse)");
                UI::EndTable();
            }
            SubHeader("Wheels - Ground Contact");
            if (UI::BeginTable("##vars_gc", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Value");
                VarRow("car.wheels.frontleft.groundcontact", "0 or 1");
                VarRow("car.wheels.frontright.groundcontact", "0 or 1");
                VarRow("car.wheels.backleft.groundcontact", "0 or 1");
                VarRow("car.wheels.backright.groundcontact", "0 or 1");
                UI::EndTable();
            }
            SubHeader("Wheels - Surface Material");
            if (UI::BeginTable("##vars_surf", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Value");
                VarRow("car.wheels.frontleft.surface", "Material ID (see table)");
                VarRow("car.wheels.frontright.surface", "Material ID (see table)");
                VarRow("car.wheels.backleft.surface", "Material ID (see table)");
                VarRow("car.wheels.backright.surface", "Material ID (see table)");
                UI::EndTable();
            }
            SubHeader("Vectors (for distance() function)");
            if (UI::BeginTable("##vars_vec", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.pos  /  car.position", "Position as vec3");
                VarRow("car.vel  /  car.velocity", "Velocity as vec3 (world)");
                VarRow("car.localvel  /  car.localvelocity", "Velocity as vec3 (car-relative)");
                VarRow("(x, y, z)", "Constant vec3 literal");
                UI::EndTable();
            }
            SubHeader("Bruteforce State");
            if (UI::BeginTable("##vars_bf", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("iterations", "Current iteration count");
                VarRow("last_improvement.time", "Timestamp of last improvement (s)");
                VarRow("last_restart.time", "Timestamp of last restart (s)");
                UI::EndTable();
            }
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Functions Reference"))
        {
            UI::Dummy(vec2(0, 2));
            if (UI::BeginTable("##funcs_table", 2))
            {
                UI::TableSetupColumn("Function");
                UI::TableSetupColumn("Description");
                VarRow("kmh(value)", "Converts m/s to km/h (x 3.6)");
                VarRow("deg(value)", "Converts radians to degrees");
                VarRow("distance(vec1, vec2)", "Euclidean distance between two vec3s");
                VarRow("time_since(timestamp)", "Seconds elapsed since timestamp");
                VarRow("variable(\"name\")", "Read a TMInterface variable as float or vec3");
                UI::EndTable();
            }
            SubHeader("Operators");
            UI::TextDimmed("  Arithmetic:   +   -   *   /");
            UI::TextDimmed("  Comparison:   >   <   >=   <=   =");
            UI::TextDimmed("  Grouping:     ( ... )");
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Surface Material IDs"))
        {
            UI::Dummy(vec2(0, 2));
            UI::TextDimmed("  Use with car.wheels.*.surface variables in conditions.");
            UI::Dummy(vec2(0, 2));
            if (UI::BeginTable("##surface_ids", 4))
            {
                UI::TableSetupColumn("ID");
                UI::TableSetupColumn("Surface");
                UI::TableSetupColumn("ID");
                UI::TableSetupColumn("Surface");
                UI::TableHeadersRow();
                SurfaceRow("0", "Concrete", "15", "Rubber");
                SurfaceRow("1", "Pavement", "16", "SlidingRubber");
                SurfaceRow("2", "Grass", "17", "Test");
                SurfaceRow("3", "Ice", "18", "Rock");
                SurfaceRow("4", "Metal", "19", "Water");
                SurfaceRow("5", "Sand", "20", "Wood");
                SurfaceRow("6", "Dirt", "21", "Danger");
                SurfaceRow("7", "DirtRoad", "22", "Asphalt");
                SurfaceRow("8", "Plastic", "23", "WetDirtRoad");
                SurfaceRow("9", "Green", "24", "WetAsphalt");
                SurfaceRow("10", "Snow", "25", "WetPavement");
                SurfaceRow("11", "MetalTrans", "26", "WetGrass");
                SurfaceRow("12", "GrassGreen", "27", "Snow2");
                SurfaceRow("13", "GrassBrown", "28", "TurboRoulette");
                SurfaceRow("14", "NotCollidable", "29", "FreeWheeling");
                UI::EndTable();
            }
            UI::Dummy(vec2(0, 4));
        }
    }
}
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
namespace SkyBf
{
    Polyhedron g_finishPoly;
    Polyhedron g_roadCheckpointPoly;
    Polyhedron g_roadCheckpointUpPoly;
    Polyhedron g_roadCheckpointDownPoly;
    Polyhedron g_roadCheckpointLeftPoly;
    Polyhedron g_roadCheckpointRightPoly;
    Polyhedron g_platformCheckpointPoly;
    Polyhedron g_platformCheckpointUpPoly;
    Polyhedron g_platformCheckpointDownPoly;
    Polyhedron g_platformCheckpointLeftPoly;
    Polyhedron g_platformCheckpointRightPoly;
    Polyhedron g_roadDirtHighCheckpointPoly;
    Polyhedron g_roadDirtCheckpointPoly;
    Polyhedron g_grassCheckpointPoly;
    Polyhedron g_ringHCheckpointPoly;
    Polyhedron g_ringVCheckpointPoly;
    dictionary g_triggerPolyhedrons;
    void InitializeTriggerData()
    {
        g_finishPoly = Polyhedron(
            {vec3(3.0, 1.0, 12.205891), vec3(3.0, 1.0, 11.79281), vec3(30.0, 1.0, 11.79281), vec3(30.0, 1.0, 12.205891), vec3(30.0, 1.9485588, 12.205891), vec3(26.664326, 5.083612, 12.205891), vec3(19.401665, 7.814228, 12.205891), vec3(12.598329, 7.814228, 12.205891), vec3(5.325968, 5.0799665, 12.205891), vec3(3.0, 2.889081, 12.205891), vec3(30.0, 1.9485588, 11.79281), vec3(3.0, 2.889081, 11.792811), vec3(5.325968, 5.0799665, 11.79281), vec3(12.598328, 7.814228, 11.79281), vec3(19.401665, 7.814228, 11.79281), vec3(26.664326, 5.083612, 11.79281)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_roadCheckpointPoly = Polyhedron(
            {vec3(3.0, 1.0, 16.20654), vec3(3.0, 1.0, 15.793459), vec3(30.0, 1.0, 15.793459), vec3(30.0, 1.0, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(3.0, 2.8890808, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(3.0, 2.8890808, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_roadCheckpointUpPoly = Polyhedron(
            {vec3(3.0, 5.305454, 16.20654), vec3(3.0, 5.205257, 15.79346), vec3(30.0, 5.205257, 15.793459), vec3(30.0, 5.305454, 16.20654), vec3(30.0, 6.0024333, 16.20654), vec3(26.664326, 9.137486, 16.20654), vec3(19.401665, 11.868102, 16.20654), vec3(12.598328, 11.868102, 16.20654), vec3(5.325968, 9.133841, 16.20654), vec3(3.0, 6.942955, 16.20654), vec3(30.0, 5.9022365, 15.793459), vec3(3.0, 6.842759, 15.79346), vec3(5.325968, 9.033645, 15.79346), vec3(12.598328, 11.767906, 15.79346), vec3(19.401665, 11.767906, 15.793459), vec3(26.664326, 9.03729, 15.793459)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_roadCheckpointDownPoly = Polyhedron(
            {vec3(29.133787, 5.305454, 15.793457), vec3(29.133787, 5.205257, 16.206537), vec3(2.1337872, 5.205257, 16.206541), vec3(2.1337872, 5.305454, 15.793461), vec3(2.1337872, 6.0024333, 15.793461), vec3(5.4694614, 9.137486, 15.793461), vec3(12.732122, 11.868102, 15.793459), vec3(19.53546, 11.868102, 15.793458), vec3(26.80782, 9.133841, 15.793457), vec3(29.133787, 6.942955, 15.793457), vec3(2.1337872, 5.9022365, 16.206541), vec3(29.133787, 6.842759, 16.206537), vec3(26.80782, 9.033645, 16.206537), vec3(19.53546, 11.767906, 16.206537), vec3(12.732122, 11.767906, 16.20654), vec3(5.4694605, 9.03729, 16.206541)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_roadCheckpointLeftPoly = Polyhedron(
            {vec3(3.0, 8.565392, 16.20654), vec3(3.0, 8.565392, 15.793459), vec3(30.0, 1.7613418, 15.793459), vec3(30.0, 1.7613418, 16.20654), vec3(30.0, 2.7099004, 16.20654), vec3(26.664326, 6.6855497, 16.20654), vec3(19.401665, 11.24637, 16.20654), vec3(12.598328, 12.960824, 16.20654), vec3(5.325968, 12.05921, 16.20654), vec3(3.0, 10.454473, 16.20654), vec3(30.0, 2.7099004, 15.793459), vec3(3.0, 10.454473, 15.793459), vec3(5.325968, 12.05921, 15.793459), vec3(12.598328, 12.960824, 15.793459), vec3(19.401665, 11.24637, 15.793459), vec3(26.664326, 6.6855497, 15.793459)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_roadCheckpointRightPoly = Polyhedron(
            {vec3(29.0, 8.512752, 16.20654), vec3(2.0, 1.7087021, 16.20654), vec3(2.0, 1.7087021, 15.793459), vec3(29.0, 8.512752, 15.793458), vec3(26.674032, 12.00657, 16.206537), vec3(19.401672, 12.908184, 16.206537), vec3(12.598335, 11.19373, 16.206537), vec3(29.0, 10.401833, 16.20654), vec3(5.3356743, 6.6329103, 16.20654), vec3(2.0, 2.657261, 16.20654), vec3(2.0, 2.657261, 15.793459), vec3(5.3356743, 6.6329103, 15.793458), vec3(12.598335, 11.19373, 15.793458), vec3(19.401672, 12.908184, 15.793458), vec3(26.674032, 12.00657, 15.793458), vec3(29.0, 10.401833, 15.793458)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {7, 4, 6}, {6, 8, 9}, {6, 9, 1}, {7, 6, 1}, {0, 7, 1}, {2, 1, 9}, {9, 10, 2}, {10, 11, 12}, {12, 13, 14}, {14, 15, 3}, {12, 14, 3}, {10, 12, 3}, {2, 10, 3}, {0, 3, 15}, {15, 7, 0}, {6, 5, 13}, {13, 12, 6}, {8, 6, 12}, {12, 11, 8}, {14, 13, 5}, {5, 4, 14}, {15, 14, 4}, {4, 7, 15}, {9, 8, 11}, {11, 10, 9}});
        g_platformCheckpointPoly = Polyhedron(
            {vec3(30.179214, 7.9320526, 16.09842), vec3(28.640587, 9.741932, 16.09842), vec3(26.304703, 11.035336, 16.09842), vec3(22.725918, 12.514831, 16.09842), vec3(18.33589, 13.464806, 16.09842), vec3(13.664118, 13.464806, 16.09842), vec3(9.274088, 12.514832, 16.09842), vec3(5.695303, 11.035337, 16.09842), vec3(3.359416, 9.741935, 16.09842), vec3(1.8207855, 7.9320536, 16.09842), vec3(3.359416, 9.741935, 15.658419), vec3(1.8207855, 7.9320545, 15.658419), vec3(5.695303, 11.035337, 15.658419), vec3(9.274088, 12.514832, 15.658419), vec3(13.664118, 13.464806, 15.658419), vec3(18.33589, 13.464806, 15.658419), vec3(22.725918, 12.51483, 15.658419), vec3(26.304703, 11.035336, 15.658419), vec3(28.640587, 9.741932, 15.658419), vec3(30.179214, 7.9320536, 15.658419)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {6, 7, 8}, {4, 6, 8}, {2, 4, 8}, {0, 2, 8}, {9, 0, 8}, {9, 8, 10}, {10, 11, 9}, {8, 7, 12}, {12, 10, 8}, {7, 6, 13}, {13, 12, 7}, {6, 5, 14}, {14, 13, 6}, {5, 4, 15}, {15, 14, 5}, {4, 3, 16}, {16, 15, 4}, {3, 2, 17}, {17, 16, 3}, {2, 1, 18}, {18, 17, 2}, {1, 0, 19}, {19, 18, 1}, {11, 19, 0}, {9, 11, 0}, {10, 12, 13}, {13, 14, 15}, {15, 16, 17}, {17, 18, 19}, {15, 17, 19}, {13, 15, 19}, {10, 13, 19}, {11, 10, 19}});
        g_platformCheckpointUpPoly = Polyhedron(
            {vec3(30.179218, 15.981263, 16.09842), vec3(28.64059, 17.791142, 16.09842), vec3(26.304707, 19.084545, 16.09842), vec3(22.725922, 20.56404, 16.09842), vec3(18.33589, 21.514013, 16.098421), vec3(13.664118, 21.514013, 16.098421), vec3(9.274088, 20.564041, 16.098421), vec3(5.695304, 19.084547, 16.09842), vec3(3.359417, 17.791147, 16.09842), vec3(1.8207862, 15.981263, 16.09842), vec3(3.3594167, 17.571144, 15.658419), vec3(1.8207862, 15.761264, 15.658419), vec3(5.695303, 18.864546, 15.658415), vec3(9.274088, 20.34404, 15.658419), vec3(13.664118, 21.294012, 15.658419), vec3(18.33589, 21.294014, 15.658419), vec3(22.725918, 20.344038, 15.658417), vec3(26.304703, 18.864544, 15.658417), vec3(28.640587, 17.571142, 15.658417), vec3(30.179214, 15.761261, 15.658419)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {6, 7, 8}, {4, 6, 8}, {2, 4, 8}, {0, 2, 8}, {9, 0, 8}, {9, 8, 10}, {10, 11, 9}, {8, 7, 12}, {12, 10, 8}, {7, 6, 13}, {13, 12, 7}, {6, 5, 14}, {14, 13, 6}, {5, 4, 15}, {15, 14, 5}, {4, 3, 16}, {16, 15, 4}, {3, 2, 17}, {17, 16, 3}, {2, 1, 18}, {18, 17, 2}, {1, 0, 19}, {19, 18, 1}, {11, 19, 0}, {9, 11, 0}, {10, 12, 13}, {13, 14, 15}, {15, 16, 17}, {17, 18, 19}, {15, 17, 19}, {13, 15, 19}, {10, 13, 19}, {11, 10, 19}});
        g_platformCheckpointDownPoly = Polyhedron(
            {vec3(30.179218, 15.882843, 16.09842), vec3(28.64059, 17.692722, 16.09842), vec3(26.304707, 18.986124, 16.09842), vec3(22.725922, 20.465622, 16.09842), vec3(18.33589, 21.415592, 16.098421), vec3(13.664118, 21.415594, 16.098421), vec3(9.274087, 20.465622, 16.098421), vec3(5.6953034, 18.986126, 16.09842), vec3(3.3594165, 17.692722, 16.09842), vec3(1.8207858, 15.882844, 16.09842), vec3(3.3594162, 17.912724, 15.658421), vec3(1.8207858, 16.102846, 15.658419), vec3(5.695303, 19.206125, 15.658421), vec3(9.274087, 20.68562, 15.658421), vec3(13.664118, 21.635593, 15.658421), vec3(18.33589, 21.635593, 15.658421), vec3(22.725918, 20.68562, 15.658421), vec3(26.304703, 19.206125, 15.658421), vec3(28.640587, 17.912722, 15.658421), vec3(30.179214, 16.102844, 15.658422)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {6, 7, 8}, {4, 6, 8}, {2, 4, 8}, {0, 2, 8}, {9, 0, 8}, {9, 8, 10}, {10, 11, 9}, {8, 7, 12}, {12, 10, 8}, {7, 6, 13}, {13, 12, 7}, {6, 5, 14}, {14, 13, 6}, {5, 4, 15}, {15, 14, 5}, {4, 3, 16}, {16, 15, 4}, {3, 2, 17}, {17, 16, 3}, {2, 1, 18}, {18, 17, 2}, {1, 0, 19}, {19, 18, 1}, {11, 19, 0}, {9, 11, 0}, {10, 12, 13}, {13, 14, 15}, {15, 16, 17}, {17, 18, 19}, {15, 17, 19}, {13, 15, 19}, {10, 13, 19}, {11, 10, 19}});
        g_platformCheckpointLeftPoly = Polyhedron(
            {vec3(30.179218, 8.842444, 16.09842), vec3(28.64059, 11.421638, 16.09842), vec3(26.304707, 13.882984, 16.09842), vec3(22.725922, 17.15187, 16.09842), vec3(18.33589, 20.29686, 16.098423), vec3(13.664118, 22.632746, 16.098423), vec3(9.274087, 23.877789, 16.098421), vec3(5.6953034, 24.187687, 16.098421), vec3(3.3594165, 24.062225, 16.09842), vec3(1.8207858, 23.02166, 16.09842), vec3(3.3594162, 24.062225, 15.658421), vec3(1.8207858, 23.021664, 15.658422), vec3(5.695303, 24.187685, 15.658421), vec3(9.274087, 23.877785, 15.658422), vec3(13.664118, 22.632746, 15.658422), vec3(18.33589, 20.29686, 15.658422), vec3(22.725918, 17.151869, 15.658421), vec3(26.304703, 13.882983, 15.658421), vec3(28.640587, 11.421638, 15.658421), vec3(30.179214, 8.842445, 15.658422)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {6, 7, 8}, {4, 6, 8}, {2, 4, 8}, {0, 2, 8}, {9, 0, 8}, {9, 8, 10}, {10, 11, 9}, {8, 7, 12}, {12, 10, 8}, {7, 6, 13}, {13, 12, 7}, {6, 5, 14}, {14, 13, 6}, {5, 4, 15}, {15, 14, 5}, {4, 3, 16}, {16, 15, 4}, {3, 2, 17}, {17, 16, 3}, {2, 1, 18}, {18, 17, 2}, {1, 0, 19}, {19, 18, 1}, {11, 19, 0}, {9, 11, 0}, {10, 12, 13}, {13, 14, 15}, {15, 16, 17}, {17, 18, 19}, {15, 17, 19}, {13, 15, 19}, {10, 13, 19}, {11, 10, 19}});
        g_platformCheckpointRightPoly = Polyhedron(
            {vec3(30.179218, 23.02166, 16.09842), vec3(28.64059, 24.062227, 16.09842), vec3(26.304707, 24.187685, 16.09842), vec3(22.725922, 23.877789, 16.09842), vec3(18.33589, 22.632751, 16.098421), vec3(13.664118, 20.296865, 16.098421), vec3(9.274087, 17.151875, 16.098421), vec3(5.6953034, 13.882988, 16.09842), vec3(3.3594165, 11.421643, 16.09842), vec3(1.8207858, 8.842446, 16.09842), vec3(3.3594162, 11.421643, 15.658421), vec3(1.8207858, 8.842446, 15.658419), vec3(5.695303, 13.882988, 15.658421), vec3(9.274087, 17.151875, 15.658421), vec3(13.664118, 20.296864, 15.658421), vec3(18.33589, 22.63275, 15.658421), vec3(22.725918, 23.877785, 15.658421), vec3(26.304703, 24.187685, 15.658421), vec3(28.640587, 24.062225, 15.658421), vec3(30.179214, 23.02166, 15.658422)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {6, 7, 8}, {4, 6, 8}, {2, 4, 8}, {0, 2, 8}, {9, 0, 8}, {9, 8, 10}, {10, 11, 9}, {8, 7, 12}, {12, 10, 8}, {7, 6, 13}, {13, 12, 7}, {6, 5, 14}, {14, 13, 6}, {5, 4, 15}, {15, 14, 5}, {4, 3, 16}, {16, 15, 4}, {3, 2, 17}, {17, 16, 3}, {2, 1, 18}, {18, 17, 2}, {1, 0, 19}, {19, 18, 1}, {11, 19, 0}, {9, 11, 0}, {10, 12, 13}, {13, 14, 15}, {15, 16, 17}, {17, 18, 19}, {15, 17, 19}, {13, 15, 19}, {10, 13, 19}, {11, 10, 19}});
        g_roadDirtHighCheckpointPoly = Polyhedron(
            {vec3(3.7928343, -0.09202623, 16.20654), vec3(3.7928343, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 16.20654), vec3(28.268883, 1.1523709, 16.20654), vec3(25.85778, 3.959106, 16.20654), vec3(19.401665, 7.2270656, 16.20654), vec3(12.598328, 7.2270656, 16.20654), vec3(6.1362143, 3.8242507, 16.20654), vec3(3.7928343, 1.1458168, 16.20654), vec3(28.268883, 1.1523709, 15.793459), vec3(3.7928343, 1.1458168, 15.793459), vec3(6.1362143, 3.8242507, 15.793459), vec3(12.598328, 7.2270656, 15.793459), vec3(19.401665, 7.2270656, 15.793459), vec3(25.85778, 3.959106, 15.793459)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_roadDirtCheckpointPoly = Polyhedron(
            {vec3(2.063568, -1.1490858, 16.20654), vec3(2.063568, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 16.20654), vec3(30.0, 3.4846723, 16.20654), vec3(26.664326, 6.291407, 16.20654), vec3(19.401665, 8.890814, 16.20654), vec3(12.598328, 8.890814, 16.20654), vec3(5.325968, 6.156552, 16.20654), vec3(2.063568, 3.478118, 16.20654), vec3(30.0, 3.4846723, 15.793459), vec3(2.063568, 3.478118, 15.793459), vec3(5.325968, 6.156552, 15.793459), vec3(12.598328, 8.890814, 15.793459), vec3(19.401665, 8.890814, 15.793459), vec3(26.664326, 6.291407, 15.793459)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_grassCheckpointPoly = Polyhedron(
            {vec3(3.0, -0.32810664, 16.20654), vec3(3.0, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(2.2881927, 1.4034786, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(2.2881927, 1.4034786, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)},
            {{0, 1, 2}, {2, 3, 0}, {4, 5, 6}, {3, 4, 6}, {6, 7, 8}, {6, 8, 9}, {3, 6, 9}, {0, 3, 9}, {2, 10, 4}, {4, 3, 2}, {1, 11, 12}, {12, 13, 14}, {1, 12, 14}, {14, 15, 10}, {1, 14, 10}, {2, 1, 10}, {0, 9, 11}, {11, 1, 0}, {6, 14, 13}, {13, 7, 6}, {5, 15, 14}, {14, 6, 5}, {12, 8, 7}, {7, 13, 12}, {11, 9, 8}, {8, 12, 11}, {4, 10, 15}, {15, 5, 4}});
        g_ringHCheckpointPoly = Polyhedron(
            {vec3(26.156471, 3.7799995, 24.192066), vec3(22.629168, 3.7799993, 27.151827), vec3(18.302288, 3.779999, 28.726685), vec3(13.69772, 3.779999, 28.726685), vec3(9.370839, 3.7799993, 27.15183), vec3(5.843534, 3.7799995, 24.192072), vec3(3.541249, 3.7799997, 20.2044), vec3(2.7416735, 3.7800002, 15.669784), vec3(3.5412476, 3.7800007, 11.135169), vec3(5.843531, 3.780001, 7.147495), vec3(9.370835, 3.7800012, 4.187733), vec3(13.697715, 3.7800014, 2.6128778), vec3(18.302284, 3.7800014, 2.6128778), vec3(22.629164, 3.7800012, 4.187733), vec3(26.156467, 3.780001, 7.147493), vec3(28.458754, 3.7800007, 11.135166), vec3(29.258327, 3.7800002, 15.669782), vec3(28.458754, 3.7799997, 20.204391), vec3(28.458754, 4.2200007, 11.135166), vec3(29.258327, 4.2200003, 15.669782), vec3(26.156467, 4.2200007, 7.147493), vec3(22.629164, 4.220001, 4.187733), vec3(18.302284, 4.220001, 2.612878), vec3(13.697715, 4.220001, 2.6128778), vec3(9.370835, 4.220001, 4.187733), vec3(5.843531, 4.2200007, 7.147495), vec3(3.5412476, 4.2200007, 11.135169), vec3(2.7416735, 4.2200003, 15.669784), vec3(3.541249, 4.22, 20.2044), vec3(5.843534, 4.2199993, 24.192074), vec3(9.370839, 4.2199993, 27.151833), vec3(13.69772, 4.219999, 28.726686), vec3(18.302288, 4.219999, 28.726685), vec3(22.629168, 4.2199993, 27.151829), vec3(26.156471, 4.2199993, 24.192068), vec3(28.458754, 4.22, 20.204393)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {2, 4, 6}, {6, 7, 8}, {8, 9, 10}, {6, 8, 10}, {10, 11, 12}, {12, 13, 14}, {10, 12, 14}, {6, 10, 14}, {2, 6, 14}, {14, 15, 16}, {2, 14, 16}, {0, 2, 16}, {17, 0, 16}, {16, 15, 18}, {18, 19, 16}, {15, 14, 20}, {20, 18, 15}, {14, 13, 21}, {21, 20, 14}, {13, 12, 22}, {22, 21, 13}, {12, 11, 23}, {23, 22, 12}, {11, 10, 24}, {24, 23, 11}, {10, 9, 25}, {25, 24, 10}, {9, 8, 26}, {26, 25, 9}, {8, 7, 27}, {27, 26, 8}, {7, 6, 28}, {28, 27, 7}, {6, 5, 29}, {29, 28, 6}, {5, 4, 30}, {30, 29, 5}, {4, 3, 31}, {31, 30, 4}, {3, 2, 32}, {32, 31, 3}, {2, 1, 33}, {33, 32, 2}, {1, 0, 34}, {34, 33, 1}, {0, 17, 35}, {35, 34, 0}, {17, 16, 19}, {19, 35, 17}, {19, 18, 20}, {20, 21, 22}, {22, 23, 24}, {20, 22, 24}, {24, 25, 26}, {26, 27, 28}, {24, 26, 28}, {28, 29, 30}, {30, 31, 32}, {28, 30, 32}, {24, 28, 32}, {20, 24, 32}, {32, 33, 34}, {20, 32, 34}, {19, 20, 34}, {35, 19, 34}});
        g_ringVCheckpointPoly = Polyhedron(
            {vec3(26.156471, 24.522285, 16.09842), vec3(22.629168, 27.482046, 16.09842), vec3(18.302288, 29.056904, 16.09842), vec3(13.697719, 29.056904, 16.09842), vec3(9.370839, 27.48205, 16.09842), vec3(5.8435335, 24.522291, 16.09842), vec3(3.5412483, 20.534618, 16.09842), vec3(2.7416725, 16.000002, 16.09842), vec3(3.5412464, 11.465387, 16.09842), vec3(5.8435307, 7.4777126, 16.09842), vec3(9.370834, 4.517952, 16.09842), vec3(13.697714, 2.9430962, 16.09842), vec3(18.302284, 2.9430962, 16.09842), vec3(22.629164, 4.517951, 16.09842), vec3(26.156467, 7.4777107, 16.09842), vec3(28.458752, 11.4653845, 16.09842), vec3(29.258327, 16.0, 16.09842), vec3(28.458754, 20.53461, 16.09842), vec3(28.458752, 11.4653845, 15.658419), vec3(29.258327, 16.0, 15.658419), vec3(26.156467, 7.4777107, 15.658419), vec3(22.629164, 4.517951, 15.658419), vec3(18.302284, 2.9430962, 15.658419), vec3(13.697714, 2.9430962, 15.658419), vec3(9.370834, 4.517952, 15.658419), vec3(5.8435307, 7.4777126, 15.658419), vec3(3.5412464, 11.465387, 15.658419), vec3(2.7416725, 16.000002, 15.658419), vec3(3.5412483, 20.534618, 15.65842), vec3(5.8435335, 24.522291, 15.65842), vec3(9.370839, 27.48205, 15.65842), vec3(13.697719, 29.056904, 15.65842), vec3(18.302288, 29.056904, 15.65842), vec3(22.629168, 27.482046, 15.65842), vec3(26.156471, 24.522285, 15.65842), vec3(28.458754, 20.53461, 15.65842)},
            {{0, 1, 2}, {2, 3, 4}, {4, 5, 6}, {2, 4, 6}, {6, 7, 8}, {8, 9, 10}, {6, 8, 10}, {10, 11, 12}, {12, 13, 14}, {10, 12, 14}, {6, 10, 14}, {2, 6, 14}, {14, 15, 16}, {2, 14, 16}, {0, 2, 16}, {17, 0, 16}, {16, 15, 18}, {18, 19, 16}, {15, 14, 20}, {20, 18, 15}, {14, 13, 21}, {21, 20, 14}, {13, 12, 22}, {22, 21, 13}, {12, 11, 23}, {23, 22, 12}, {11, 10, 24}, {24, 23, 11}, {10, 9, 25}, {25, 24, 10}, {9, 8, 26}, {26, 25, 9}, {8, 7, 27}, {27, 26, 8}, {7, 6, 28}, {28, 27, 7}, {6, 5, 29}, {29, 28, 6}, {5, 4, 30}, {30, 29, 5}, {4, 3, 31}, {31, 30, 4}, {3, 2, 32}, {32, 31, 3}, {2, 1, 33}, {33, 32, 2}, {1, 0, 34}, {34, 33, 1}, {0, 17, 35}, {35, 34, 0}, {17, 16, 19}, {19, 35, 17}, {19, 18, 20}, {20, 21, 22}, {22, 23, 24}, {20, 22, 24}, {24, 25, 26}, {26, 27, 28}, {24, 26, 28}, {28, 29, 30}, {30, 31, 32}, {28, 30, 32}, {24, 28, 32}, {20, 24, 32}, {32, 33, 34}, {20, 32, 34}, {19, 20, 34}, {35, 19, 34}});
        g_triggerPolyhedrons["StadiumRoadMainCheckpoint"] = @g_roadCheckpointPoly;
        g_triggerPolyhedrons["StadiumGrassCheckpoint"] = @g_grassCheckpointPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointUp"] = @g_roadCheckpointUpPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointDown"] = @g_roadCheckpointDownPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointLeft"] = @g_roadCheckpointLeftPoly;
        g_triggerPolyhedrons["StadiumRoadMainCheckpointRight"] = @g_roadCheckpointRightPoly;
        g_triggerPolyhedrons["StadiumCheckpointRingV"] = @g_ringVCheckpointPoly;
        g_triggerPolyhedrons["StadiumCheckpointRingHRoad"] = @g_ringHCheckpointPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpoint"] = @g_platformCheckpointPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointUp"] = @g_platformCheckpointUpPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointDown"] = @g_platformCheckpointDownPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointLeft"] = @g_platformCheckpointLeftPoly;
        g_triggerPolyhedrons["StadiumPlatformCheckpointRight"] = @g_platformCheckpointRightPoly;
        g_triggerPolyhedrons["StadiumRoadDirtHighCheckpoint"] = @g_roadDirtHighCheckpointPoly;
        g_triggerPolyhedrons["StadiumRoadDirtCheckpoint"] = @g_roadDirtCheckpointPoly;
        g_triggerPolyhedrons["StadiumRoadMainFinishLine"] = @g_finishPoly;
    }
    array<Ellipsoid> g_carEllipsoids;
    array<Polyhedron @> g_worldCheckpointPolys;
    array<AABB> g_worldCheckpointAABBs;
    array<string> g_worldCheckpointNames;
    array<Polyhedron @> g_worldFinishPolys;
    array<AABB> g_worldFinishAABBs;
    uint64 g_totalOnEvaluateTime = 0;
    uint64 g_totalCalcMinCarDistTime = 0;
    uint64 g_totalVertexTransformTime = 0;
    uint64 g_totalClosestPointPolyTime = 0;
    uint64 g_onEvaluateCallCount = 0;
    const string g_distPluginPrefix = "dist_bf";
    const string g_uberPluginPrefix = "uber_bf";
    int g_bfTargetType = -1;
    int g_bfTargetCpIndex = -1;
    float g_bestBfDistance = 1e18f;
    string g_cachedChallengeUid = "";
    void CacheCheckpointData()
    {
        TM::GameCtnChallenge @challenge = GetCurrentChallenge();
        if (challenge is null)
        {
            print("Error: Could not get current challenge for caching.", Severity::Error);
            g_cachedChallengeUid = "";
            g_worldCheckpointPolys.Clear();
            g_worldCheckpointAABBs.Clear();
            g_worldCheckpointNames.Clear();
            g_worldFinishPolys.Clear();
            g_worldFinishAABBs.Clear();
            return;
        }
        if (challenge.Uid == g_cachedChallengeUid)
        {
            return;
        }
        g_cachedChallengeUid = challenge.Uid;
        g_worldCheckpointPolys.Clear();
        g_worldCheckpointAABBs.Clear();
        g_worldCheckpointNames.Clear();
        g_worldFinishPolys.Clear();
        g_worldFinishAABBs.Clear();
        array<TM::GameCtnBlock @> blocks = challenge.Blocks;
        if (blocks is null)
        {
            print("Error: Could not get challenge blocks.", Severity::Error);
            return;
        }
        for (uint i = 0; i < blocks.Length; i++)
        {
            TM::GameCtnBlock @block = blocks[i];
            if (block !is null && block.WayPointType == TM::WayPointType::Checkpoint)
            {
                Polyhedron @basePoly = Polyhedron();
                if (g_triggerPolyhedrons.Get(block.Name, basePoly))
                {
                    if (basePoly !is null)
                    {
                        Polyhedron worldPoly = TransformPolyhedronToWorld(basePoly, block);
                        AABB worldAABB = CalculatePolyhedronAABB(worldPoly);
                        g_worldCheckpointPolys.Add(worldPoly);
                        g_worldCheckpointAABBs.Add(worldAABB);
                        g_worldCheckpointNames.Add(block.Name);
                    }
                    else
                    {
                        print("Warning: Null polyhedron found in dictionary for block: " + block.Name, Severity::Warning);
                    }
                }
                else
                {
                    print("Warning: No trigger polyhedron defined for checkpoint block: " + block.Name, Severity::Warning);
                }
            }
            else if (block.WayPointType == TM::WayPointType::Finish)
            {
                Polyhedron @basePoly = Polyhedron();
                if (g_triggerPolyhedrons.Get(block.Name, basePoly))
                {
                    if (basePoly !is null)
                    {
                        Polyhedron worldPoly = TransformPolyhedronToWorld(basePoly, block);
                        AABB worldAABB = CalculatePolyhedronAABB(worldPoly);
                        g_worldFinishPolys.Add(worldPoly);
                        g_worldFinishAABBs.Add(worldAABB);
                    }
                    else
                    {
                        print("Warning: Null polyhedron found in dictionary for block: " + block.Name, Severity::Warning);
                    }
                }
                else
                {
                    print("Warning: No trigger polyhedron defined for finish block: " + block.Name, Severity::Warning);
                }
            }
        }
    }
    namespace Drawing
    {
        int counter = 0;
        const vec2 padFix = vec2(-8, -8);
        bool dimensionsInitialized = false;
        const array<string> NUMBER_PATTERNS = {
            "111101101101111", 
            "010110010010111", 
            "111001111100111", 
            "111001111001111", 
            "101101111001001", 
            "111100111001111", 
            "111100111101111", 
            "111001010010010", 
            "111101111101111", 
            "111101111001111"  
        };
        void square(int x, int y, uint dimension)
        {
            string title = "##Window for pixel" + counter++;
            UI::SetNextWindowPos(vec2(x - dimension / 2, y - dimension / 2) + padFix);
            UI::SetNextWindowSize(vec2(dimension + 12, dimension + 12));
            UI::Begin(title,
                      UI::WindowFlags::NoBackground | UI::WindowFlags::NoDecoration | UI::WindowFlags::NoInputs | UI::WindowFlags::NoMouseInputs | UI::WindowFlags::NoNavInputs | UI::WindowFlags::NoFocusOnAppearing | UI::WindowFlags::NoBringToFrontOnFocus | UI::WindowFlags::NoNavFocus);
            UI::Button(title, vec2(float(dimension), float(dimension)));
            UI::End();
        }
        void number(int x, int y, uint dimension, uint numberValue)
        {
            if (dimension == 0)
                return;
            string digits = "" + numberValue;
            if (digits.Length == 0)
                digits = "0";
            uint cellSize = dimension;
            int digitWidth = int(cellSize) * 3;
            int digitSpacing = int(cellSize);
            int totalWidth = int(digits.Length) * digitWidth;
            if (digits.Length > 1)
            {
                totalWidth += (int(digits.Length) - 1) * digitSpacing;
            }
            int totalHeight = int(cellSize) * 5;
            int startX = x - totalWidth / 2;
            int startY = y - totalHeight / 2;
            for (uint i = 0; i < digits.Length; ++i)
            {
                int digitIndex = digits[i] - '0';
                if (digitIndex < 0 || digitIndex >= int(NUMBER_PATTERNS.Length))
                    continue;
                string pattern = NUMBER_PATTERNS[digitIndex];
                int digitX = startX + int(i) * (digitWidth + digitSpacing);
                for (uint row = 0; row < 5; ++row)
                {
                    for (uint col = 0; col < 3; ++col)
                    {
                        uint patternIndex = row * 3 + col;
                        if (patternIndex >= pattern.Length)
                            continue;
                        if (pattern[patternIndex] != '1')
                            continue;
                        float centerX = float(digitX) + (float(col) + 0.5f) * float(cellSize);
                        float centerY = float(startY) + (float(row) + 0.5f) * float(cellSize);
                        square(int(Math::Round(centerX)), int(Math::Round(centerY)), cellSize);
                    }
                }
            }
        }
        dictionary dimensionsMapping;
        void InitializeDimensions()
        {
            if (dimensionsInitialized)
                return;
            dimensionsMapping = dictionary();
            dimensionsMapping.Set("1228800", vec2(640, 480));
            dimensionsMapping.Set("1920000", vec2(800, 600));
            dimensionsMapping.Set("4915200", vec2(1280, 960));
            dimensionsMapping.Set("8294400", vec2(1920, 1080));
            dimensionsMapping.Set("14745600", vec2(2560, 1440));
            dimensionsMapping.Set("33177600", vec2(3840, 2160));
            dimensionsInitialized = true;
        }
        int screenWidth = 1920;
        int screenHeight = 1080;
        uint64 timeOfLastCapture = 0;
        uint64 captureInterval = 2000;
        vec3 lastCamPos = vec3(0, 0, 0);
        mat3 lastCamRot = mat3();
        vec2 lastScreenPos = vec2(0, 0);
        void UpdateScreenSize()
        {
            InitializeDimensions();
            uint64 currentTime = Time::Now;
            if (currentTime - timeOfLastCapture <= captureInterval)
            {
                return;
            }
            timeOfLastCapture = currentTime;
            array<uint8> @screenshot = Graphics::CaptureScreenshot(vec2(0, 0));
            string key = screenshot.Length + "";
            if (!dimensionsMapping.Exists(key))
            {
                return;
            }
            vec2 dim;
            dimensionsMapping.Get(key, dim);
            screenWidth = int(dim.x);
            screenHeight = int(dim.y);
        }
        void BeginFrame()
        {
            counter = 0;
            UpdateScreenSize();
        }
        vec2 GetScreenSize()
        {
            return vec2(float(screenWidth), float(screenHeight));
        }
        void Draw(SimulationManager @simManager)
        {
            BeginFrame();
            TM::GameCamera @gameCamera = GetCurrentCamera();
            vec3 camPos = gameCamera.Location.Position;
            mat3 camRot = gameCamera.Location.Rotation;
            float camFov = gameCamera.Fov; 
            UpdateScreenSize();
            vec2 screenPos;
            if (camPos == lastCamPos && camRot.x == lastCamRot.x && camRot.y == lastCamRot.y && camRot.z == lastCamRot.z)
            {
                screenPos = lastScreenPos;
            }
            else
            {
                screenPos = WorldToScreen(vec3(0, 0, 0), camPos, camRot, camFov, vec2(screenWidth, screenHeight));
                lastScreenPos = screenPos;
            }
            lastCamPos = camPos;
            lastCamRot = camRot;
            lastScreenPos = screenPos;
            vec3 rgb = HSVToRGB(GetRainbowHue(), 1.0f, 1.0f);
            vec4 rainbowColor = vec4(rgb.x, rgb.y, rgb.z, 1.0f);
            UI::PushStyleColor(UI::Col::Button, rainbowColor);
            number(int(screenPos.x), int(screenPos.y), 30, int(Math::Round(camFov)));
            UI::PopStyleColor(1);
        }
        vec2 WorldToScreen(vec3 worldPos, vec3 camPos, mat3 camRot, float camFov, vec2 screenSize)
        {
            vec3 dir = worldPos - camPos;
            camRot.Transpose();
            vec3 localDir = matTimesVec(camRot, dir);
            if (localDir.z <= 0)
                return vec2(-1, -1);
            float fovRad = camFov * (3.14159265 / 180.0);
            float aspectRatio = screenSize.x / screenSize.y;
            float tanHalfFov = Math::Tan(fovRad * 0.5);
            float ndcX = -(localDir.x / localDir.z) / (tanHalfFov * aspectRatio);
            float ndcY = (localDir.y / localDir.z) / tanHalfFov;
            float screenX = (ndcX * 0.5 + 0.5) * screenSize.x;
            float screenY = (-ndcY * 0.5 + 0.5) * screenSize.y;
            return vec2(screenX, screenY);
        }
        vec3 matTimesVec(mat3 m, vec3 v)
        {
            return vec3(
                m.x.x * v.x + m.x.y * v.y + m.x.z * v.z,
                m.y.x * v.x + m.y.y * v.y + m.y.z * v.z,
                m.z.x * v.x + m.z.y * v.y + m.z.z * v.z);
        }
        float GetRainbowHue()
        {
            float t = float(Time::Now % 6000) / 6000.0f;
            return t * 360.0f;
        }
        vec3 HSVToRGB(float h, float s, float v)
        {
            while (h < 0.0f)
                h += 360.0f;
            while (h >= 360.0f)
                h -= 360.0f;
            float hPrime = h / 60.0f;
            float hFloor = Math::Floor(hPrime);
            int segment = int(hFloor) % 6;
            if (segment < 0)
                segment += 6;
            float f = hPrime - hFloor;
            float p = v * (1.0f - s);
            float q = v * (1.0f - f * s);
            float t = v * (1.0f - (1.0f - f) * s);
            if (segment == 0)
                return vec3(v, t, p);
            if (segment == 1)
                return vec3(q, v, p);
            if (segment == 2)
                return vec3(p, v, t);
            if (segment == 3)
                return vec3(p, q, v);
            if (segment == 4)
                return vec3(t, p, v);
            return vec3(v, p, q);
        }
    }
    void RenderBruteforceEvaluationSettingssss()
    {
        g_bfTargetType = int(GetVariableDouble(g_distPluginPrefix + "_target_type"));
        g_bfTargetCpIndex = int(GetVariableDouble(g_distPluginPrefix + "_target_cp_index"));
        bool typeChanged = false;
        UI::Text("Optimize for minimum distance to:");
        bool isCpSelected = (g_bfTargetType == 0);
        UI::BeginDisabled(isCpSelected);
        if (UI::Button("Checkpoint Index##TargetBtn"))
        {
            g_bfTargetType = 0;
            typeChanged = true;
        }
        UI::EndDisabled();
        bool isFinishSelected = (g_bfTargetType == 1);
        UI::BeginDisabled(isFinishSelected);
        if (UI::Button("Finish Line##TargetBtn"))
        {
            g_bfTargetType = 1;
            typeChanged = true;
        }
        UI::EndDisabled();
        UI::Separator();
        if (g_bfTargetType == 0)
        {
            UI::Text("Target Checkpoint Settings:");
            UI::Dummy(vec2(0, 5));
            UI::CheckboxVar("Show Checkpoint Numbers", g_distPluginPrefix + "_show_cp_numbers");
            UI::CheckboxVar("Shift checkpoint eval after reached", g_distPluginPrefix + "_shift_cp_eval");
            UI::PushItemWidth(120);
            UI::InputIntVar("Target Index##CPIndex", g_distPluginPrefix + "_target_cp_index", 1);
            UI::PopItemWidth();
            int potentiallyUpdatedIndex = int(GetVariableDouble(g_distPluginPrefix + "_target_cp_index"));
            int clampedIndex = Math::Max(0, potentiallyUpdatedIndex);
            if (clampedIndex != g_bfTargetCpIndex || clampedIndex != potentiallyUpdatedIndex)
            {
                g_bfTargetCpIndex = clampedIndex;
                SetVariable(g_distPluginPrefix + "_target_cp_index", g_bfTargetCpIndex);
            }
            else
            {
                g_bfTargetCpIndex = clampedIndex;
            }
            string rangeText = "Valid range: 0 to " + (g_worldCheckpointPolys.Length > 0 ? g_worldCheckpointPolys.Length - 1 : 0);
            UI::TextDimmed(rangeText);
            if (g_bfTargetCpIndex >= 0 && g_bfTargetCpIndex < int(g_worldCheckpointNames.Length))
            {
                UI::Text("Selected: ");
                UI::SameLine();
                UI::BeginDisabled();
                UI::Text(g_worldCheckpointNames[g_bfTargetCpIndex]);
                UI::EndDisabled();
            }
            else if (g_worldCheckpointPolys.Length > 0)
            {
                UI::TextDimmed("Error: Index is out of bounds!");
            }
            else
            {
                UI::TextDimmed("No checkpoint data cached.");
            }
        }
        else
        {
            UI::Text("Target Finish Settings:");
            UI::Dummy(vec2(0, 5));
            UI::CheckboxVar("Shift finish eval after reached", g_distPluginPrefix + "_shift_finish_eval");
            UI::Dummy(vec2(0, 5));
            UI::BeginDisabled();
            UI::TextWrapped("The bruteforce will optimize towards the closest point on any finish line block surface.");
            UI::EndDisabled();
        }
        if (typeChanged)
        {
            SetVariable(g_distPluginPrefix + "_target_type", g_bfTargetType);
        }
        UI::Separator();
        string bestDistText = "Current Best Distance Found: ";
        if (g_bestBfDistance > 1e17f)
        {
            bestDistText += "N/A";
        }
        else
        {
            bestDistText += Text::FormatFloat(g_bestBfDistance, "", 0, 4) + " m";
        }
        UI::Text(bestDistText);
        UI::Dummy(vec2(0, 5));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(30, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing1", g_distPluginPrefix + "_bf_time_from");
        UI::PopItemWidth();
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(49, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing2", g_distPluginPrefix + "_bf_time_to");
        UI::PopItemWidth();
        UI::Text("Trigger constraint");
        UI::SameLine();
        UI::Dummy(vec2(-11, 0));
        UI::SameLine();
        UI::PushItemWidth(110);
        int triggerId = UI::InputIntVar("##Nothing3", g_distPluginPrefix + "_constraint_trigger_index", 1);
        UI::PopItemWidth();
        UI::TextDimmed("0 to disable, 1 or more for the trigger index (see Triggers tab)");
        if (triggerId < 0)
        {
            triggerId = 0;
            SetVariable(g_distPluginPrefix + "_constraint_trigger_index", triggerId);
        }
    }
    vec3 ProjectPointOnPlane(const vec3 &in point, const vec3 &in planeNormal, const vec3 &in planePoint)
    {
        float distance = Math::Dot(point - planePoint, planeNormal);
        return point - planeNormal * distance;
    }
    float PointToSegmentDistanceSq(const vec3 &in p, const vec3 &in a, const vec3 &in b, vec3 &out projection)
    {
        vec3 ab = b - a;
        vec3 ap = p - a;
        float abLenSq = Math::Dot(ab, ab);
        if (abLenSq < 1e-6f)
        {
            projection = a;
            return DistanceSq(p, a);
        }
        float t = Math::Dot(ap, ab) / abLenSq;
        t = Math::Clamp(t, 0.0f, 1.0f);
        projection = a + ab * t;
        return DistanceSq(p, projection);
    }
    float DistanceSq(const vec3 &in p1, const vec3 &in p2)
    {
        vec3 diff = p1 - p2;
        return Math::Dot(diff, diff);
    }
    bool IsPointInsideTriangle(const vec3 &in point, const vec3 &in v0, const vec3 &in v1, const vec3 &in v2, const vec3 &in planeNormal)
    {
        vec3 edge0 = v1 - v0;
        vec3 edge1 = v2 - v1;
        vec3 edge2 = v0 - v2;
        vec3 p0 = point - v0;
        vec3 p1 = point - v1;
        vec3 p2 = point - v2;
        vec3 edgePlaneNormal0 = Cross(edge0, planeNormal);
        if (Math::Dot(p0, edgePlaneNormal0) > 1e-6f)
            return false;
        vec3 edgePlaneNormal1 = Cross(edge1, planeNormal);
        if (Math::Dot(p1, edgePlaneNormal1) > 1e-6f)
            return false;
        vec3 edgePlaneNormal2 = Cross(edge2, planeNormal);
        if (Math::Dot(p2, edgePlaneNormal2) > 1e-6f)
            return false;
        return true;
    }
    AABB CalculatePolyhedronAABB(const Polyhedron &in poly)
    {
        AABB box;
        if (poly.vertices.Length == 0)
            return box;
        for (uint i = 0; i < poly.vertices.Length; ++i)
        {
            box.Add(poly.vertices[i]);
        }
        return box;
    }
    Polyhedron CreateAABBPolyhedron(const vec3 &in center, const vec3 &in size)
    {
        vec3 halfSize = size * 0.5f;
        vec3 min = center - halfSize;
        vec3 max = center + halfSize;
        array<vec3> vertices = {
            vec3(min.x, min.y, min.z),
            vec3(max.x, min.y, min.z),
            vec3(max.x, max.y, min.z),
            vec3(min.x, max.y, min.z),
            vec3(min.x, min.y, max.z),
            vec3(max.x, min.y, max.z),
            vec3(max.x, max.y, max.z),
            vec3(min.x, max.y, max.z)};
        array<array<int>> faces = {
            {0, 3, 2, 1},
            {4, 5, 6, 7},
            {0, 1, 5, 4},
            {0, 4, 7, 3},
            {1, 2, 6, 5},
            {0, 1, 2, 3},
            {4, 5, 6, 7},
            {0, 1, 5, 4},
            {3, 7, 6, 2}};
        faces = {
            {0, 3, 2, 1},
            {4, 5, 6, 7},
            {0, 4, 7, 3},
            {1, 2, 6, 5},
            {0, 1, 5, 4},
            {3, 7, 6, 2}};
        return Polyhedron(vertices, faces);
    }
    Polyhedron TransformPolyhedronToWorld(const Polyhedron &in basePoly, const TM::GameCtnBlock @block)
    {
        Polyhedron worldPoly;
        vec3 blockOriginWorld = vec3(block.Coord.x * 32.0f, block.Coord.y * 8.0f, block.Coord.z * 32.0f);
        GmVec3 centerOffsetLocal = GmVec3(16.0f, 4.0f, 16.0f);
        GmVec3 blockCenterWorld = GmVec3(blockOriginWorld) + centerOffsetLocal;
        GmMat3 blockRotationMat;
        float angleRad = 0.0f;
        if (block.Dir == TM::CardinalDir::East)
        {
            angleRad = Math::ToRad(-90.0f);
        }
        else if (block.Dir == TM::CardinalDir::South)
        {
            angleRad = Math::ToRad(180.0f);
        }
        else if (block.Dir == TM::CardinalDir::West)
        {
            angleRad = Math::ToRad(90.0f);
        }
        if (angleRad != 0.0f)
        {
            blockRotationMat.RotateY(angleRad);
        }
        worldPoly.vertices.Resize(basePoly.vertices.Length);
        for (uint i = 0; i < basePoly.vertices.Length; ++i)
        {
            GmVec3 baseVertexLocal = GmVec3(basePoly.vertices[i]);
            GmVec3 vertexRelativeToCenterLocal = baseVertexLocal - centerOffsetLocal;
            GmVec3 rotatedRelativeVertex = blockRotationMat.Transform(vertexRelativeToCenterLocal);
            GmVec3 finalWorldVertex = rotatedRelativeVertex + blockCenterWorld;
            worldPoly.vertices[i] = finalWorldVertex.ToVec3();
        }
        worldPoly.faces = basePoly.faces;
        worldPoly.uniqueEdges = basePoly.uniqueEdges;
        worldPoly.precomputedFaces.Resize(basePoly.precomputedFaces.Length);
        for (uint i = 0; i < basePoly.precomputedFaces.Length; ++i)
        {
            const PrecomputedFace @basePface = basePoly.precomputedFaces[i];
            PrecomputedFace @worldPface = worldPoly.precomputedFaces[i];
            worldPface.vertexIndices = basePface.vertexIndices;
            GmVec3 localPlanePoint = basePface.planePoint;
            GmVec3 pointRelativeToCenter = localPlanePoint - centerOffsetLocal;
            GmVec3 rotatedRelativePoint = blockRotationMat.Transform(pointRelativeToCenter);
            worldPface.planePoint = rotatedRelativePoint + blockCenterWorld;
            worldPface.normal = blockRotationMat.Transform(basePface.normal);
        }
        return worldPoly;
    }
    float g_currentWindowMinDistance = 1e18f;
    bool g_conditionsMetAtMinDistance = false;
    bool g_windowResultProcessed = false;
    int g_lastProcessedRaceTime = -1;
    int bfTimeFrom = 0;
    int bfTimeTo = 0;
    AABB triggerIdToAABB(int id)
    {
        int index = id - 1;
        if (index < 0)
        {
            return AABB(vec3(-1e18f, -1e18f, -1e18f), vec3(1e18f, 1e18f, 1e18f));
        }
        array<int> triggerIds = GetTriggerIds();
        bool canExist = index <= int(triggerIds.Length);
        if (!canExist)
        {
            print("BF Evaluate: Trigger index " + index + " not found.", Severity::Error);
            return AABB(vec3(1e18f, 1e18f, 1e18f), vec3(-1e18f, -1e18f, -1e18f));
        }
        Trigger3D trigger = GetTriggerByIndex(index);
        return AABB(trigger.Position, trigger.Position + trigger.Size);
        ;
    }
    Polyhedron g_targetCpPoly;
    AABB g_targetCpAABB;
    bool g_bfConfigIsValid = false;
    string g_bfTargetDescription = "Invalid Target";
    Polyhedron g_clippedtargetCpPoly;
    AABB @g_clippedtargetCpAABB;
    array<Polyhedron @> g_worldClippedFinishPolys;
    array<AABB> g_worldClippedFinishAABBs;
    void OnDistSimulationBegin(SimulationManager @simManager)
    {
        if (!(GetVariableString("controller") == "bfv2"))
        {
            g_bfConfigIsValid = false;
            return;
        }
        g_isNewBFEvaluationRun = true;
        g_simEndProcessed = false;
        g_isEarlyStop = false;
        g_forceAccept = false;
        g_bfPhase = BFPhase::Initial;
        TM::GameCtnChallenge @challenge = GetCurrentChallenge();
        if (challenge !is null && challenge.Uid != g_cachedChallengeUid)
        {
            CacheCheckpointData();
        }
        g_bfConfigIsValid = false;
        bfTimeFrom = int(GetVariableDouble(g_distPluginPrefix + "_bf_time_from"));
        bfTimeTo = int(GetVariableDouble(g_distPluginPrefix + "_bf_time_to"));
        g_bfTargetType = int(GetVariableDouble(g_distPluginPrefix + "_target_type"));
        if (g_bfTargetType == 0)
        {
            g_bfTargetCpIndex = int(GetVariableDouble(g_distPluginPrefix + "_target_cp_index"));
            if (g_bfTargetCpIndex < 0 || g_bfTargetCpIndex >= int(g_worldCheckpointPolys.Length))
            {
                print("BF Init Error: Target CP index " + g_bfTargetCpIndex + " is out of bounds (0-" + (g_worldCheckpointPolys.Length) + ").", Severity::Error);
            }
            else
            {
                g_targetCpPoly = g_worldCheckpointPolys[g_bfTargetCpIndex];
                if (g_targetCpPoly is null)
                {
                    print("BF Init Error: Target CP polyhedron at index " + g_bfTargetCpIndex + " is null.", Severity::Error);
                }
                else
                {
                    g_targetCpAABB = g_worldCheckpointAABBs[g_bfTargetCpIndex];
                    g_bfTargetDescription = "CP Index " + g_bfTargetCpIndex;
                    if (g_bfTargetCpIndex >= 0 && g_bfTargetCpIndex < int(g_worldCheckpointNames.Length))
                    {
                        g_bfTargetDescription += " (" + g_worldCheckpointNames[g_bfTargetCpIndex] + ")";
                    }
                    g_bfConfigIsValid = true;
                }
            }
        }
        else if (g_bfTargetType == 1)
        {
            if (g_worldFinishPolys.IsEmpty())
            {
                print("BF Init Error: No finish blocks cached for this map. Cannot evaluate distance.", Severity::Error);
            }
            else
            {
                g_bfTargetDescription = "Finish Line";
                if (g_worldFinishPolys.Length > 1)
                {
                    g_bfTargetDescription += " (Closest of " + g_worldFinishPolys.Length + ")";
                }
                g_bfConfigIsValid = true;
            }
        }
        else
        {
            print("BF Init Error: Invalid target type specified: " + g_bfTargetType, Severity::Error);
        }
        if (g_bfConfigIsValid)
        {
            g_bestBfDistance = 1e18f;
            g_currentWindowMinDistance = 1e18f;
            g_conditionsMetAtMinDistance = false;
            g_windowResultProcessed = true;
            g_lastProcessedRaceTime = -1;
            g_totalOnEvaluateTime = 0;
            g_totalCalcMinCarDistTime = 0;
            g_totalVertexTransformTime = 0;
            g_totalClosestPointPolyTime = 0;
            g_onEvaluateCallCount = 0;
            AABB triggerAABB = triggerIdToAABB(int(GetVariableDouble(g_distPluginPrefix + "_constraint_trigger_index")));
            if (g_bfTargetType == 0)
            {
                g_clippedtargetCpPoly = ClipPolyhedronByAABB(g_targetCpPoly, triggerAABB);
                g_targetCpAABB = triggerAABB;
            }
            else if (g_bfTargetType == 1)
            {
                g_worldClippedFinishPolys.Resize(0);
                g_worldClippedFinishAABBs.Resize(0);
                for (uint i = 0; i < g_worldFinishPolys.Length; ++i)
                {
                    const Polyhedron @targetPoly = g_worldFinishPolys[i];
                    if (targetPoly is null)
                        continue;
                    const AABB targetAABB = g_worldFinishAABBs[i];
                    Polyhedron clippedPoly = ClipPolyhedronByAABB(targetPoly, triggerAABB);
                    g_worldClippedFinishPolys.Add(clippedPoly);
                    g_worldClippedFinishAABBs.Add(targetAABB);
                }
            }
        }
        else
        {
            print("BF Initialization failed. Evaluation will be stopped.");
        }
    }
    void OnSimulationBegin(SimulationManager @simManager)
    {
        if (GetVariableString("bf_target") == g_bruteforceDistanceTargetIdentifier)
        {
            OnDistSimulationBegin(simManager);
        }
        else if (GetVariableString("bf_target") == g_uberbugTargetIdentifier)
        {
            OnUberSimulationBegin(simManager);
        }
    }
    bool g_simEndProcessed = false;
    void OnSimulationEnd(SimulationManager @simManager, SimulationResult result)
    {
        if (GetVariableString("bf_target") != g_bruteforceDistanceTargetIdentifier || GetVariableString("controller") != "bfv2")
        {
            return;
        }
        if (!g_simEndProcessed)
        {
            g_simEndProcessed = true;
            if (g_bfConfigIsValid && g_isEarlyStop)
            {
                g_earlyStopCommandList.Save(GetVariableString("bf_result_filename"));
            }
            print("\n--- Bruteforce Performance Report ---");
            if (g_onEvaluateCallCount == 0)
            {
                print("No evaluations were run.");
                print("-------------------------------------\n");
                return;
            }
            print("Total evaluations: " + g_onEvaluateCallCount);
            print("Total time in OnEvaluate: " + g_totalOnEvaluateTime + " ms");
            float avgOnEvaluate = float(g_totalOnEvaluateTime) / g_onEvaluateCallCount;
            print("  -> Average per evaluation: " + Text::FormatFloat(avgOnEvaluate, "", 0, 4) + " ms");
            if (g_totalOnEvaluateTime > 0)
            {
                print("\nBreakdown of OnEvaluate time:");
                uint64 totalMeasuredInside = g_totalCalcMinCarDistTime;
                uint64 overhead = g_totalOnEvaluateTime > totalMeasuredInside ? g_totalOnEvaluateTime - totalMeasuredInside : 0;
                print("  - CalculateMinCarDistanceToPoly: " + g_totalCalcMinCarDistTime + " ms (" + Text::FormatFloat(100.0f * g_totalCalcMinCarDistTime / g_totalOnEvaluateTime, "", 0, 1) + "%)");
                print("  - OnEvaluate Overhead: " + overhead + " ms (" + Text::FormatFloat(100.0f * overhead / g_totalOnEvaluateTime, "", 0, 1) + "%)");
                if (g_totalCalcMinCarDistTime > 0)
                {
                    print("\nBreakdown of CalculateMinCarDistanceToPoly time:");
                    uint64 totalCalcDistBreakdown = g_totalVertexTransformTime + g_totalClosestPointPolyTime;
                    uint64 calcDistOverhead = g_totalCalcMinCarDistTime > totalCalcDistBreakdown ? g_totalCalcMinCarDistTime - totalCalcDistBreakdown : 0;
                    print("    - Vertex Transformations: " + g_totalVertexTransformTime + " ms (" + Text::FormatFloat(100.0f * g_totalVertexTransformTime / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                    print("    - Polygon Closest Point Checks: " + g_totalClosestPointPolyTime + " ms (" + Text::FormatFloat(100.0f * g_totalClosestPointPolyTime / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                    print("    - Other (internal logic): " + calcDistOverhead + " ms (" + Text::FormatFloat(100.0f * calcDistOverhead / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                }
            }
            print("-------------------------------------\n");
        }
    }
    class BFResultPrinter
    {
        int COL_ITER = 10;
        int COL_PHASE = 12;
        int COL_TARGET = 30;
        int COL_WINDOW = 18;
        int COL_DIST = 18;
        int COL_IMPROVE = 18;
        int precision = 8;
        bool headerPrinted = false;
    private
        string PadString(const string &in str, int width, bool alignRight = false)
        {
            int len = str.Length;
            if (len >= width)
            {
                return str.Substr(0, width);
            }
            int padding = width - len;
            string padStr = "";
            for (int i = 0; i < padding; ++i)
            {
                padStr += " ";
            }
            if (alignRight)
            {
                return padStr + str;
            }
            else
            {
                return str + padStr;
            }
        }
        void PrintHeader(const string &in targetDesc, int timeFrom, int timeTo)
        {
            string title = "Bruteforce Evaluation Results";
            string targetInfo = "Target: " + targetDesc + " | Window: [" + timeFrom + "-" + timeTo + "] ms";
            string header = PadString("Iteration", COL_ITER) + " | " +
                            PadString("Phase", COL_PHASE) + " | " +
                            PadString("Min Distance", COL_DIST, true) + " | " +
                            PadString("Improvement", COL_IMPROVE, true);
            int totalWidth = header.Length;
            string separator = "";
            for (int i = 0; i < totalWidth; ++i)
            {
                separator += "-";
            }
            print("");
            print(title);
            print(targetInfo);
            print(separator);
            print(header);
            print(separator);
            headerPrinted = true;
        }
        void PrintRow(int iteration, const string &in phase, float distance, float improvement = -1.0f)
        {
            string iterStr = Text::FormatInt(iteration);
            string phaseStr = phase;
            string distStr = Text::FormatFloat(distance, "", 0, precision) + " m";
            string improveStr = (improvement >= 0.0f) ? (Text::FormatFloat(improvement, "", 0, precision) + " m") : "N/A";
            string row = PadString(iterStr, COL_ITER, true) + " | " +
                         PadString(phaseStr, COL_PHASE) + " | " +
                         PadString(distStr, COL_DIST, true) + " | " +
                         PadString(improveStr, COL_IMPROVE, true);
            print(row);
        }
        void PrintInitialResult(int iteration, const string &in targetDesc, int timeFrom, int timeTo, float distance)
        {
            if (!headerPrinted)
            {
                PrintHeader(targetDesc, timeFrom, timeTo);
            }
            PrintRow(iteration, "Initial", distance, -1.0f);
        }
        void PrintImprovedResult(int iteration, float newDistance, float improvement)
        {
            if (!headerPrinted)
            {
                print("BFResultPrinter Warning: Header not printed before improved result!", Severity::Warning);
            }
            PrintRow(iteration, "Improvement", newDistance, improvement);
        }
        void PrintTargetAchieved()
        {
            if (!headerPrinted)
            {
                print("BFResultPrinter Warning: Header not printed before target achievement!", Severity::Warning);
            }
            array<string> celebration = {
                "|------------------------------------------------------|",
                "|                                                      |",
                "|                   CONGRATULATIONS!                   |",
                "|                                                      |",
                "|   /$$$$$$  /$$   /$$ /$$     /$$ /$$$$$$$  /$$$$$$$$ |",
                "|  /$$__  $$| $$  /$$/|  $$   /$$/| $$__  $$| $$_____/ |",
                "| | $$  \\__/| $$ /$$/  \\  $$ /$$/ | $$  \\ $$| $$       |",
                "| |  $$$$$$ | $$$$$/    \\  $$$$/  | $$$$$$$ | $$$$$    |",
                "|  \\____  $$| $$  $$     \\  $$/   | $$__  $$| $$__/    |",
                "|  /$$  \\ $$| $$\\  $$     | $$    | $$  \\ $$| $$       |",
                "| |  $$$$$$/| $$ \\  $$    | $$    | $$$$$$$/| $$       |",
                "|  \\______/ |__/  \\__/    |__/    |_______/ |__/       |",
                "|                                                      |",
                "|                Mission accomplished!                 |",
                "|                                                      |",
                "|------------------------------------------------------|"};
            print("\n");
            for (uint i = 0; i < celebration.Length; ++i)
            {
                string leftPadding = "     ";
                string text = leftPadding + celebration[i];
                print(text, Severity::Success);
            }
            print("\n");
        }
        void Reset()
        {
            headerPrinted = false;
        }
    }
    BFResultPrinter g_bfPrinter;
    bool g_isNewBFEvaluationRun = false;
    CommandList g_earlyStopCommandList;
    bool g_isEarlyStop = false;
    bool g_forceAccept = false;
    BFPhase g_bfPhase = BFPhase::Initial;
    void OnCheckpointCountChanged(SimulationManager @simManager, int current, int target)
    {
        int raceTime = simManager.RaceTime;
        if (!(GetVariableString("bf_target") == g_bruteforceDistanceTargetIdentifier && GetVariableString("controller") == "bfv2"))
        {
            return;
        }
        if (current == target && raceTime <= bfTimeTo && g_bfPhase == BFPhase::Search)
        {
            if (GetVariableBool(g_distPluginPrefix + "_shift_finish_eval"))
            {
                CommandList finish();
                finish.Content = simManager.InputEvents.ToCommandsText();
                g_bfPrinter.PrintTargetAchieved();
                print("");
                print("Finish reached at " + (raceTime) + "ms (or before), shifting finish evaluation earlier...", Severity::Warning);
                print("File saved: " + finish.Save(GetVariableString("bf_result_filename").Split(".")[0] + "_restart" + restartCount + "_bestfin.txt"));
                bfTimeTo = raceTime - 10;
                if (bfTimeFrom > bfTimeTo)
                {
                    bfTimeFrom = bfTimeTo;
                }
                g_bestBfDistance = 1e18f;
                g_currentWindowMinDistance = 1e18f;
                g_conditionsMetAtMinDistance = false;
                g_windowResultProcessed = false;
                g_forceAccept = true;
            }
            else
            {
                g_isEarlyStop = true;
                g_forceAccept = true;
            }
        }
        if (g_bfTargetType == 0 && g_bfTargetCpIndex >= 0 && raceTime <= bfTimeTo && g_bfPhase == BFPhase::Search)
        {
            array<int> cpStates = simManager.PlayerInfo.CheckpointStates;
            if (g_bfTargetCpIndex < int(cpStates.Length) && cpStates[g_bfTargetCpIndex] == 1)
            {
                if (GetVariableBool(g_distPluginPrefix + "_shift_cp_eval"))
                {
                    CommandList cpReached();
                    cpReached.Content = simManager.InputEvents.ToCommandsText();
                    g_bfPrinter.PrintTargetAchieved();
                    print("");
                    print("Checkpoint " + g_bfTargetCpIndex + " reached at " + (raceTime) + "ms (or before), shifting checkpoint evaluation earlier...", Severity::Warning);
                    print("File saved: " + cpReached.Save(GetVariableString("bf_result_filename").Split(".")[0] + "_restart" + restartCount + "_bestcp.txt"));
                    bfTimeTo = raceTime - 10;
                    if (bfTimeFrom > bfTimeTo)
                    {
                        bfTimeFrom = bfTimeTo;
                    }
                    g_bestBfDistance = 1e18f;
                    g_currentWindowMinDistance = 1e18f;
                    g_conditionsMetAtMinDistance = false;
                    g_windowResultProcessed = false;
                    g_forceAccept = true;
                }
                else
                {
                    g_isEarlyStop = true;
                    g_forceAccept = true;
                }
            }
        }
        if (raceTime < bfTimeFrom || raceTime >= bfTimeTo)
        {
            return;
        }
    }
    BFEvaluationResponse @OnEvaluate(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        uint64 onEvaluateStartTime = Time::get_Now();
        BFEvaluationResponse @resp = OnEvaluate_Inner(simManager, info);
        g_onEvaluateCallCount++;
        g_totalOnEvaluateTime += (Time::get_Now() - onEvaluateStartTime);
        return resp;
    }
    BFEvaluationResponse @OnEvaluate_Inner(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;
        if (!g_bfConfigIsValid)
        {
            resp.Decision = BFEvaluationDecision::Stop;
            return resp;
        }
        int raceTime = simManager.RaceTime;
        g_bfPhase = info.Phase;
        if (raceTime < g_lastProcessedRaceTime)
        {
            g_currentWindowMinDistance = 1e18f;
            g_conditionsMetAtMinDistance = false;
            g_windowResultProcessed = false;
        }
        g_lastProcessedRaceTime = raceTime;
        TM::PlayerInfo @playerInfo = simManager.PlayerInfo;
        bool isInWindow = (raceTime >= bfTimeFrom && raceTime < bfTimeTo);
        bool isDecisionTime = (raceTime == bfTimeTo);
        bool shouldCalculateDistance = isInWindow || (isDecisionTime && !g_windowResultProcessed);
        float currentTickDistance = 1e18f;
        if (shouldCalculateDistance)
        {
            g_windowResultProcessed = false;
            GmIso4 carWorldTransform = GmIso4(simManager.Dyna.CurrentState.Location);
            vec3 carPosition = carWorldTransform.m_Position.ToVec3();
            if (g_bfTargetType == 0)
            {
                const Polyhedron @targetPoly;
                const AABB targetAABB = g_targetCpAABB;
                int constraintTriggerIndex = int(GetVariableDouble(g_distPluginPrefix + "_constraint_trigger_index"));
                bool constraintIsActive = (constraintTriggerIndex > 0);
                if (constraintIsActive)
                {
                    @targetPoly = g_clippedtargetCpPoly;
                }
                else
                {
                    @targetPoly = g_targetCpPoly;
                }
                bool needsAccurateDistance = targetAABB.Contains(carPosition, 15);
                if (needsAccurateDistance)
                {
                    currentTickDistance = CalculateMinCarDistanceToPoly(carWorldTransform, targetPoly);
                }
                else
                {
                    currentTickDistance = Math::Max(0.0f, targetAABB.DistanceToPoint(carPosition));
                }
            }
            else
            {
                float minDistToAnyFinish = 1e18f;
                for (uint i = 0; i < g_worldClippedFinishPolys.Length; ++i)
                {
                    const Polyhedron @targetPoly = g_worldClippedFinishPolys[i];
                    if (targetPoly is null || targetPoly.faces.Length == 0)
                        continue;
                    const AABB targetAABB = g_worldClippedFinishAABBs[i];
                    bool needsAccurateDistance = targetAABB.Contains(carPosition, 15);
                    float distToThisFinish = 1e18f;
                    if (needsAccurateDistance)
                    {
                        distToThisFinish = CalculateMinCarDistanceToPoly(carWorldTransform, targetPoly);
                    }
                    else
                    {
                        distToThisFinish = Math::Max(0.0f, targetAABB.DistanceToPoint(carPosition));
                    }
                    minDistToAnyFinish = Math::Min(minDistToAnyFinish, distToThisFinish);
                }
                currentTickDistance = minDistToAnyFinish;
            }
            if (currentTickDistance < g_currentWindowMinDistance)
            {
                g_conditionsMetAtMinDistance = GlobalConditionsMet(simManager);
            }
            g_currentWindowMinDistance = Math::Min(g_currentWindowMinDistance, currentTickDistance);
        }
        if (isDecisionTime && !g_windowResultProcessed)
        {
            g_windowResultProcessed = true;
            if (g_bfTargetType == 1 && playerInfo.RaceFinished && !GetVariableBool(g_distPluginPrefix + "_shift_finish_eval"))
            {
                g_isEarlyStop = true;
            }
            if (g_isEarlyStop)
            {
                g_earlyStopCommandList.Content = simManager.InputEvents.ToCommandsText();
                resp.Decision = BFEvaluationDecision::Stop;
                g_bfPrinter.PrintTargetAchieved();
                return resp;
            }
            float finalMinDistance = g_currentWindowMinDistance;
            if (finalMinDistance == 1e18f)
            {
                if (shouldCalculateDistance)
                {
                    finalMinDistance = currentTickDistance;
                }
                else
                {
                    print("BF Evaluate: Warning - Could not determine minimum distance at decision time " + raceTime + "ms.", Severity::Warning);
                }
            }
            string targetDesc = g_bfTargetDescription;
            if (info.Phase == BFPhase::Initial)
            {
                g_bestBfDistance = finalMinDistance;
                resp.Decision = BFEvaluationDecision::Accept;
                if (g_isNewBFEvaluationRun)
                {
                    g_bfPrinter.Reset();
                    g_isNewBFEvaluationRun = false;
                    g_bfPrinter.PrintInitialResult(info.Iterations, targetDesc, bfTimeFrom, bfTimeTo, g_bestBfDistance);
                    resp.ResultFileStartContent = "# Baseline min distance to " + targetDesc + " [" + bfTimeFrom + "-" + bfTimeTo + "ms]: " + Text::FormatFloat(g_bestBfDistance, "", 0, 6) + " m";
                }
            }
            else
            {
                if (finalMinDistance == 0.0f)
                {
                    resp.Decision = BFEvaluationDecision::DoNothing;
                    return resp;
                }
                if (finalMinDistance < g_bestBfDistance && g_conditionsMetAtMinDistance)
                {
                    float oldBest = g_bestBfDistance;
                    g_bestBfDistance = finalMinDistance;
                    resp.Decision = BFEvaluationDecision::Accept;
                    g_bfPrinter.PrintImprovedResult(info.Iterations, g_bestBfDistance, oldBest - g_bestBfDistance);
                    resp.ResultFileStartContent = "# Distance to " + targetDesc + " [" + Text::FormatFloat(bfTimeFrom/1000.0, "", 0, 2) + "-" + Text::FormatFloat(bfTimeTo/1000.0, "", 0, 2) + "]: " + Text::FormatFloat(g_bestBfDistance, "", 0, 6) + " m at iteration " + info.Iterations;
                }
                else
                {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
            }
            g_currentWindowMinDistance = 1e18f;
            g_conditionsMetAtMinDistance = false;
            return resp;
        }
        if (g_forceAccept && info.Phase == BFPhase::Search)
        {
            if (GetVariableBool(g_distPluginPrefix + "_shift_finish_eval"))
            {
                g_isNewBFEvaluationRun = true;
            }
            g_forceAccept = false;
            resp.Decision = BFEvaluationDecision::Accept;
        }
        if (raceTime > bfTimeTo + 10)
        {
            resp.Decision = BFEvaluationDecision::Reject;
        }
        return resp;
    }
    string g_bruteforceDistanceTargetIdentifier = "distance_target";
    string g_uberbugTargetIdentifier = "uberbug_target";
    void Main()
    {
        InitializeTriggerData();
        InitializeCarEllipsoids();
        RegisterVariable(g_distPluginPrefix + "_target_type", 0);
        RegisterVariable(g_distPluginPrefix + "_target_cp_index", 0);
        RegisterVariable(g_distPluginPrefix + "_show_cp_numbers", false);
        RegisterVariable(g_distPluginPrefix + "_bf_time_from", 0);
        RegisterVariable(g_distPluginPrefix + "_bf_time_to", 0);
        RegisterVariable(g_distPluginPrefix + "_constraint_trigger_index", -1);
        RegisterVariable(g_distPluginPrefix + "_shift_finish_eval", true);
        RegisterVariable(g_distPluginPrefix + "_shift_cp_eval", true);
        auto eval1 = RegisterBruteforceEval(
            g_bruteforceDistanceTargetIdentifier,
            "Distance to Target (CP/Finish)",
            OnEvaluate,
            RenderBruteforceEvaluationSettingssss);
        @eval1.onSimBegin = @OnSimulationBegin;
        @eval1.onSimEnd = @OnSimulationEnd;
        @eval1.onCheckpointCountChanged = @OnCheckpointCountChanged;
        @eval1.onRunStep = @OnRunStep;
        @eval1.onRender = @Render;
        RegisterVariable(g_uberPluginPrefix + "_uberbug_threshold", 0.8);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_mode", "Find");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_show_visualization", false);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_amount", 10);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_result_file", "uber{i}.txt");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_min_speed", 300.0f);
        RegisterVariable(g_uberPluginPrefix + "_bf_time_from", 0);
        RegisterVariable(g_uberPluginPrefix + "_bf_time_to", 0);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_viz_follow_race", false);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_point1", "0,0,0");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_point2", "0,0,0");
        RegisterVariable(g_uberPluginPrefix + "_uberbug_show_trajectory", false);
        RegisterVariable(g_uberPluginPrefix + "_uberbug_find_mode", "Single");
        RegisterVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        RegisterVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        RegisterVariable(g_uberPluginPrefix + "_replaysaving_filename_format", "uberbug{i}.txt");
        RegisterVariable(g_uberPluginPrefix + "_replaysaving_time_limit", 20000);
        currentUberMode = GetVariableString(g_uberPluginPrefix + "_uberbug_mode");
        currentFindMode = GetVariableString(g_uberPluginPrefix + "_uberbug_find_mode");
        auto eval2 = RegisterBruteforceEval(
            g_uberbugTargetIdentifier,
            "Uberbug",
            OnEvaluateUberbug,
            RenderBruteforceEvaluationSettingsUberbug);
        @eval2.onSimBegin = @OnSimulationBegin;
        @eval2.onSimEnd = @OnSimulationEnd;
        @eval2.onCheckpointCountChanged = @OnCheckpointCountChanged;
        @eval2.onRunStep = @OnRunStep;
        @eval2.onRender = @Render;
        RegisterSettingsPage("Uberbug BF", UberbugPageSettings);
        RegisterCustomCommand("clear_uberbugs", "Clear all stored uberbugs", OnClearUberbugs);
        string trajectoryTriggerCache = GetVariableString(g_uberPluginPrefix + "_trajectory_trigger_cache");
        string cachedTriggers = GetVariableString(g_uberPluginPrefix + "_uberbugs_trigger_cache");
    }
    void DistRender()
    {
        if (!GetVariableBool(g_distPluginPrefix + "_show_cp_numbers"))
        {
            return;
        }
        SimulationManager @simManager = GetSimulationManager();
        if (simManager is null || !simManager.InRace)
        {
            return;
        }
        TM::GameCamera @gameCamera = GetCurrentCamera();
        if (gameCamera is null)
        {
            return;
        }
        Drawing::BeginFrame();
        vec3 camPos = gameCamera.Location.Position;
        mat3 camRot = gameCamera.Location.Rotation;
        float camFov = gameCamera.Fov;
        vec2 screenSize = Drawing::GetScreenSize();
        vec3 rainbow = Drawing::HSVToRGB(Drawing::GetRainbowHue(), 1.0f, 1.0f);
        UI::PushStyleColor(UI::Col::Button, vec4(rainbow.x, rainbow.y, rainbow.z, 1.0f));
        for (uint i = 0; i < g_worldCheckpointAABBs.Length; i++)
        {
            vec3 center = g_worldCheckpointAABBs[i].Center();
            vec2 screenPos = Drawing::WorldToScreen(center, camPos, camRot, camFov, screenSize);
            Drawing::number(int(Math::Round(screenPos.x)), int(Math::Round(screenPos.y)), 14, i);
        }
        UI::PopStyleColor(1);
    }
    void Render()
    {
        DistRender();
        UberRender();
    }
    class GmVec3
    {
        float x = 0.0f;
        float y = 0.0f;
        float z = 0.0f;
        GmVec3() {}
        GmVec3(float num)
        {
            this.x = num;
            this.y = num;
            this.z = num;
        }
        GmVec3(float x, float y, float z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
        }
        GmVec3(const GmVec3 &in other)
        {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
        }
        GmVec3(const vec3 &in other)
        {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
        }
        vec3 ToVec3() const
        {
            return vec3(x, y, z);
        }
        void Mult(const GmMat3 &in M)
        {
            float _x = x * M.x.x + y * M.x.y + z * M.x.z;
            float _y = x * M.y.x + y * M.y.y + z * M.y.z;
            float _z = x * M.z.x + y * M.z.y + z * M.z.z;
            x = _x;
            y = _y;
            z = _z;
        }
        void Mult(const GmIso4 &in T)
        {
            Mult(T.m_Rotation);
            x += T.m_Position.x;
            y += T.m_Position.y;
            z += T.m_Position.z;
        }
        void MultTranspose(const GmMat3 &in M)
        {
            float _x = x * M.x.x + y * M.y.x + z * M.z.x;
            float _y = x * M.x.y + y * M.y.y + z * M.z.y;
            float _z = x * M.x.z + y * M.y.z + z * M.z.z;
            x = _x;
            y = _y;
            z = _z;
        }
        float LengthSquared() const
        {
            return x * x + y * y + z * z;
        }
        float Length() const
        {
            return Math::Sqrt(LengthSquared());
        }
        void Normalize()
        {
            float len = Length();
            if (len > 1e-6f)
            {
                x /= len;
                y /= len;
                z /= len;
            }
        }
        GmVec3 Normalized() const
        {
            GmVec3 result = this;
            result.Normalize();
            return result;
        }
        GmVec3 opAdd(const GmVec3 &in other) const
        {
            return GmVec3(x + other.x, y + other.y, z + other.z);
        }
        GmVec3 opSub(const GmVec3 &in other) const
        {
            return GmVec3(x - other.x, y - other.y, z - other.z);
        }
        GmVec3 opMul(float scalar) const
        {
            return GmVec3(x * scalar, y * scalar, z * scalar);
        }
        GmVec3 opDiv(float scalar) const
        {
            return GmVec3(x / scalar, y / scalar, z / scalar);
        }
        GmVec3 opNeg() const
        {
            return GmVec3(-x, -y, -z);
        }
        void opAddAssign(const GmVec3 &in other)
        {
            x += other.x;
            y += other.y;
            z += other.z;
        }
        void opSubAssign(const GmVec3 &in other)
        {
            x -= other.x;
            y -= other.y;
            z -= other.z;
        }
        void opMulAssign(float scalar)
        {
            x *= scalar;
            y *= scalar;
            z *= scalar;
        }
        void opDivAssign(float scalar)
        {
            x /= scalar;
            y /= scalar;
            z /= scalar;
        }
        GmVec3 opMul_Elementwise(const GmVec3 &in other) const
        {
            return GmVec3(x * other.x, y * other.y, z * other.z);
        }
        GmVec3 opDiv_Elementwise(const GmVec3 &in other) const
        {
            return GmVec3(x / other.x, y / other.y, z / other.z);
        }
    } class GmMat3
    {
        GmVec3 x;
        GmVec3 y;
        GmVec3 z;
        GmMat3() { SetIdentity(); }
        GmMat3(const GmMat3 &in other)
        {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
        }
        GmMat3(const GmVec3 &in x, const GmVec3 &in y, const GmVec3 &in z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
        }
        GmMat3(const mat3 &in other)
        {
            this.x.x = other.x.x;
            this.x.y = other.y.x;
            this.x.z = other.z.x;
            this.y.x = other.x.y;
            this.y.y = other.y.y;
            this.y.z = other.z.y;
            this.z.x = other.x.z;
            this.z.y = other.y.z;
            this.z.z = other.z.z;
        }
        mat3 ToMat3() const
        {
            mat3 m;
            m.x.x = this.x.x;
            m.x.y = this.y.x;
            m.x.z = this.z.x;
            m.y.x = this.x.y;
            m.y.y = this.y.y;
            m.y.z = this.z.y;
            m.z.x = this.x.z;
            m.z.y = this.y.z;
            m.z.z = this.z.z;
            return m;
        }
        void SetIdentity()
        {
            x = GmVec3(1.0f, 0.0f, 0.0f);
            y = GmVec3(0.0f, 1.0f, 0.0f);
            z = GmVec3(0.0f, 0.0f, 1.0f);
        }
        void Mult(const GmMat3 &in other)
        {
            GmMat3 result;
            result.x.x = x.x * other.x.x + y.x * other.x.y + z.x * other.x.z;
            result.x.y = x.y * other.x.x + y.y * other.x.y + z.y * other.x.z;
            result.x.z = x.z * other.x.x + y.z * other.x.y + z.z * other.x.z;
            result.y.x = x.x * other.y.x + y.x * other.y.y + z.x * other.y.z;
            result.y.y = x.y * other.y.x + y.y * other.y.y + z.y * other.y.z;
            result.y.z = x.z * other.y.x + y.z * other.y.y + z.z * other.y.z;
            result.z.x = x.x * other.z.x + y.x * other.z.y + z.x * other.z.z;
            result.z.y = x.y * other.z.x + y.y * other.z.y + z.y * other.z.z;
            result.z.z = x.z * other.z.x + y.z * other.z.y + z.z * other.z.z;
            this = result;
        }
        GmMat3 opMul(const GmMat3 &in other) const
        {
            GmMat3 result = this;
            result.Mult(other);
            return result;
        }
        GmVec3 Transform(const GmVec3 &in v) const
        {
            return GmVec3(
                x.x * v.x + y.x * v.y + z.x * v.z,
                x.y * v.x + y.y * v.y + z.y * v.z,
                x.z * v.x + y.z * v.y + z.z * v.z);
        }
        GmVec3 opMul(const GmVec3 &in v) const
        {
            return Transform(v);
        }
        GmVec3 TransformTranspose(const GmVec3 &in v) const
        {
            return GmVec3(
                x.x * v.x + x.y * v.y + x.z * v.z,
                y.x * v.x + y.y * v.y + y.z * v.z,
                z.x * v.x + z.y * v.y + z.z * v.z);
        }
        void RotateX(float rad)
        {
            float s = Math::Sin(rad);
            float c = Math::Cos(rad);
            GmMat3 rotMat(
                GmVec3(1, 0, 0),
                GmVec3(0, c, s),
                GmVec3(0, -s, c));
            Mult(rotMat);
        }
        void RotateY(float rad)
        {
            float s = Math::Sin(rad);
            float c = Math::Cos(rad);
            GmMat3 rotMat(
                GmVec3(c, 0, -s),
                GmVec3(0, 1, 0),
                GmVec3(s, 0, c));
            Mult(rotMat);
        }
        void RotateZ(float rad)
        {
            float s = Math::Sin(rad);
            float c = Math::Cos(rad);
            GmMat3 rotMat(
                GmVec3(c, s, 0),
                GmVec3(-s, c, 0),
                GmVec3(0, 0, 1));
            Mult(rotMat);
        }
        float Determinant() const
        {
            return x.x * (y.y * z.z - y.z * z.y) - y.x * (x.y * z.z - x.z * z.y) + z.x * (x.y * y.z - x.z * y.y);
        }
        GmMat3 Inverse() const
        {
            GmMat3 inv;
            float det = Determinant();
            if (Math::Abs(det) < 1e-6f)
            {
                print("Warning: GmMat3::Inverse() called on singular matrix. Returning identity.", Severity::Warning);
                return inv;
            }
            float invDet = 1.0f / det;
            inv.x.x = (y.y * z.z - y.z * z.y) * invDet;
            inv.y.x = (y.z * z.x - y.x * z.z) * invDet;
            inv.z.x = (y.x * z.y - y.y * z.x) * invDet;
            inv.x.y = (x.z * z.y - x.y * z.z) * invDet;
            inv.y.y = (x.x * z.z - x.z * z.x) * invDet;
            inv.z.y = (x.y * z.x - x.x * z.y) * invDet;
            inv.x.z = (x.y * y.z - x.z * y.y) * invDet;
            inv.y.z = (x.z * y.x - x.x * y.z) * invDet;
            inv.z.z = (x.x * y.y - x.y * y.x) * invDet;
            return inv;
        }
        GmMat3 Transposed() const
        {
            GmMat3 result;
            result.x.x = x.x;
            result.y.x = x.y;
            result.z.x = x.z;
            result.x.y = y.x;
            result.y.y = y.y;
            result.z.y = y.z;
            result.x.z = z.x;
            result.y.z = z.y;
            result.z.z = z.z;
            return result;
        }
    } class GmIso4
    {
        GmMat3 m_Rotation;
        GmVec3 m_Position;
        GmIso4() {}
        GmIso4(const GmIso4 &in other)
        {
            this.m_Rotation = other.m_Rotation;
            this.m_Position = other.m_Position;
        }
        GmIso4(const GmMat3 &in rotation, const GmVec3 &in position)
        {
            this.m_Rotation = rotation;
            this.m_Position = position;
        }
        GmIso4(const iso4 &in other)
        {
            this.m_Rotation = GmMat3(other.Rotation);
            this.m_Position = GmVec3(other.Position);
        }
        iso4 ToIso4() const
        {
            iso4 result;
            result.Rotation = m_Rotation.ToMat3();
            result.Position = m_Position.ToVec3();
            return result;
        }
        void Mult(const GmIso4 &in other)
        {
            m_Position = m_Rotation.Transform(other.m_Position) + m_Position;
            m_Rotation.Mult(other.m_Rotation);
        }
        GmIso4 opMul(const GmIso4 &in other) const
        {
            GmIso4 result = this;
            result.Mult(other);
            return result;
        }
        GmVec3 Transform(const GmVec3 &in p) const
        {
            return m_Rotation.Transform(p) + m_Position;
        }
        GmVec3 opMul(const GmVec3 &in p) const
        {
            return Transform(p);
        }
        GmVec3 TransformDirection(const GmVec3 &in d) const
        {
            return m_Rotation.Transform(d);
        }
        GmIso4 Inverse() const
        {
            GmMat3 invRot = m_Rotation.Inverse();
            GmVec3 invPos = invRot.Transform(-m_Position);
            return GmIso4(invRot, invPos);
        }
    } class AABB
    {
        vec3 min = vec3(1e9, 1e9, 1e9);
        vec3 max = vec3(-1e9, -1e9, -1e9);
        AABB() {}
        AABB(const vec3 &in min, const vec3 &in max)
        {
            this.min = min;
            this.max = max;
        }
        void Add(const vec3 &in p)
        {
            min.x = Math::Min(min.x, p.x);
            min.y = Math::Min(min.y, p.y);
            min.z = Math::Min(min.z, p.z);
            max.x = Math::Max(max.x, p.x);
            max.y = Math::Max(max.y, p.y);
            max.z = Math::Max(max.z, p.z);
        }
        void Add(const AABB &in other)
        {
            Add(other.min);
            Add(other.max);
        }
        vec3 Center() const
        {
            return (min + max) * 0.5f;
        }
        vec3 Size() const
        {
            return max - min;
        }
        bool Contains(const vec3 &in p, float margin = 1e-6f) const
        {
            return (p.x >= min.x - margin && p.x <= max.x + margin &&
                    p.y >= min.y - margin && p.y <= max.y + margin &&
                    p.z >= min.z - margin && p.z <= max.z + margin);
        }
        float DistanceToPoint(const vec3 &in p) const
        {
            float dx = Math::Max(min.x - p.x, 0.0f) + Math::Max(p.x - max.x, 0.0f);
            float dy = Math::Max(min.y - p.y, 0.0f) + Math::Max(p.y - max.y, 0.0f);
            float dz = Math::Max(min.z - p.z, 0.0f) + Math::Max(p.z - max.z, 0.0f);
            return Math::Sqrt(dx * dx + dy * dy + dz * dz);
        }
        AABB Intersect(const AABB &other) const
        {
            vec3 intersectMin = vec3(
                Math::Max(min.x, other.min.x),
                Math::Max(min.y, other.min.y),
                Math::Max(min.z, other.min.z));
            vec3 intersectMax = vec3(
                Math::Min(max.x, other.max.x),
                Math::Min(max.y, other.max.y),
                Math::Min(max.z, other.max.z));
            return AABB(intersectMin, intersectMax);
        }
        bool IsValid() const
        {
            return min.x <= max.x && min.y <= max.y && min.z <= max.z;
        }
        bool intersectsSegment(const vec3 &in p0, const vec3 &in p1) const
        {
            vec3 d = p1 - p0;
            float tmin = 0.0f;
            float tmax = 1.0f;
            for (int i = 0; i < 3; ++i)
            {
                if (Math::Abs(d[i]) < 1e-6f)
                {
                    if (p0[i] < min[i] || p0[i] > max[i])
                        return false;
                }
                else
                {
                    float ood = 1.0f / d[i];
                    float t1 = (min[i] - p0[i]) * ood;
                    float t2 = (max[i] - p0[i]) * ood;
                    if (t1 > t2)
                    {
                        float temp = t1;
                        t1 = t2;
                        t2 = temp;
                    }
                    tmin = Math::Max(tmin, t1);
                    tmax = Math::Min(tmax, t2);
                    if (tmin > tmax)
                        return false;
                }
            }
            return true;
        }
        bool testAxis(const vec3 &in v0, const vec3 &in v1, const vec3 &in v2, const vec3 &in edge, const vec3 &in boxHalf, const int axis)
        {
            float p, minTri, maxTri, rad;
            if (axis == 0)
            {
                p = v0.z * edge.y - v0.y * edge.z;
                minTri = p;
                maxTri = p;
                p = v1.z * edge.y - v1.y * edge.z;
                minTri = Math::Min(minTri, p);
                maxTri = Math::Max(maxTri, p);
                p = v2.z * edge.y - v2.y * edge.z;
                minTri = Math::Min(minTri, p);
                maxTri = Math::Max(maxTri, p);
                rad = Math::Abs(edge.y) * boxHalf.z + Math::Abs(edge.z) * boxHalf.y;
            }
            else if (axis == 1)
            {
                p = v0.x * edge.z - v0.z * edge.x;
                minTri = p;
                maxTri = p;
                p = v1.x * edge.z - v1.z * edge.x;
                minTri = Math::Min(minTri, p);
                maxTri = Math::Max(maxTri, p);
                p = v2.x * edge.z - v2.z * edge.x;
                minTri = Math::Min(minTri, p);
                maxTri = Math::Max(maxTri, p);
                rad = Math::Abs(edge.x) * boxHalf.z + Math::Abs(edge.z) * boxHalf.x;
            }
            else
            {
                p = v0.y * edge.x - v0.x * edge.y;
                minTri = p;
                maxTri = p;
                p = v1.y * edge.x - v1.x * edge.y;
                minTri = Math::Min(minTri, p);
                maxTri = Math::Max(maxTri, p);
                p = v2.y * edge.x - v2.x * edge.y;
                minTri = Math::Min(minTri, p);
                maxTri = Math::Max(maxTri, p);
                rad = Math::Abs(edge.x) * boxHalf.y + Math::Abs(edge.y) * boxHalf.x;
            }
            return !(minTri > rad || maxTri < -rad);
        }
        bool intersectsTriangle(const vec3 &in p0, const vec3 &in p1, const vec3 &in p2) const
        {
            vec3 boxCenter = (min + max) * 0.5f;
            vec3 boxHalf = (max - min) * 0.5f;
            vec3 v0 = p0 - boxCenter;
            vec3 v1 = p1 - boxCenter;
            vec3 v2 = p2 - boxCenter;
            vec3 e0 = v1 - v0;
            vec3 e1 = v2 - v1;
            vec3 e2 = v0 - v2;
            if (!testAxis(v0, v1, v2, e0, boxHalf, 0))
                return false;
            if (!testAxis(v0, v1, v2, e0, boxHalf, 1))
                return false;
            if (!testAxis(v0, v1, v2, e0, boxHalf, 2))
                return false;
            if (!testAxis(v0, v1, v2, e1, boxHalf, 0))
                return false;
            if (!testAxis(v0, v1, v2, e1, boxHalf, 1))
                return false;
            if (!testAxis(v0, v1, v2, e1, boxHalf, 2))
                return false;
            if (!testAxis(v0, v1, v2, e2, boxHalf, 0))
                return false;
            if (!testAxis(v0, v1, v2, e2, boxHalf, 1))
                return false;
            if (!testAxis(v0, v1, v2, e2, boxHalf, 2))
                return false;
            for (int i = 0; i < 3; i++)
            {
                float triMin = Math::Min(v0[i], Math::Min(v1[i], v2[i]));
                float triMax = Math::Max(v0[i], Math::Max(v1[i], v2[i]));
                if (triMin > boxHalf[i] || triMax < -boxHalf[i])
                    return false;
            }
            vec3 normal = Cross(e0, e1);
            float rad = boxHalf.x * Math::Abs(normal.x) + boxHalf.y * Math::Abs(normal.y) + boxHalf.z * Math::Abs(normal.z);
            float triProj0 = Math::Dot(normal, v0);
            float triProj1 = Math::Dot(normal, v1);
            float triProj2 = Math::Dot(normal, v2);
            float triMin = Math::Min(triProj0, Math::Min(triProj1, triProj2));
            float triMax = Math::Max(triProj0, Math::Max(triProj1, triProj2));
            if (triMin > rad || triMax < -rad)
                return false;
            return true;
        }
        string ToString()
        {
            return "AABB(min: " + min.x + ", " + min.y + ", " + min.z +
                   ", max: " + max.x + ", " + max.y + ", " + max.z + ")";
        }
    }
    class Edge
    {
        int v0;
        int v1;
        Edge()
        {
            v0 = -1;
            v1 = -1;
        }
        Edge(int i0 = -1, int i1 = -1)
        {
            if (i0 < i1)
            {
                v0 = i0;
                v1 = i1;
            }
            else
            {
                v0 = i1;
                v1 = i0;
            }
        }
        bool opEquals(const Edge &in other) const
        {
            return v0 == other.v0 && v1 == other.v1;
        }
        bool opLess(const Edge &in other) const
        {
            if (v0 < other.v0)
                return true;
            if (v0 > other.v0)
                return false;
            return v1 < other.v1;
        }
    }
    class SortableVertex
    {
        float angle;
        int index;
        int opCmp(const SortableVertex &in other) const
        {
            if (angle < other.angle)
                return -1;
            if (angle > other.angle)
                return 1;
            return 0;
        }
    };
    class PrecomputedFace
    {
        array<int> vertexIndices;
        GmVec3 normal;
        GmVec3 planePoint;
    }
    class Polyhedron
    {
        array<vec3> vertices;
        array<array<int>> faces;
        array<PrecomputedFace> precomputedFaces;
        array<Edge> uniqueEdges;
        vec3 BoundingSphereCenter;
        float BoundingSphereRadius;
        Polyhedron()
        {
            BoundingSphereRadius = 0.0f;
        }
        Polyhedron(const array<vec3> &in in_vertices, const array<array<int>> &in triangleFaces)
        {
            this.vertices = in_vertices;
            if (vertices.IsEmpty() || triangleFaces.IsEmpty())
            {
                return;
            }
            uint numTriangles = triangleFaces.Length;
            array<array<int>> newFaceIndices;
            array<PrecomputedFace> newPrecomputedFaces;
            dictionary edgeToGlobalFaces;
            array<vec3> faceNormals(numTriangles);
            for (uint i = 0; i < numTriangles; ++i)
            {
                const array<int> @face_idxs = triangleFaces[i];
                if (face_idxs.Length != 3)
                {
                    print("Error: Input face " + i + " is not a triangle. Simplification requires a triangle mesh.", Severity::Error);
                    return;
                }
                vec3 edge1 = vertices[face_idxs[1]] - vertices[face_idxs[0]];
                vec3 edge2 = vertices[face_idxs[2]] - vertices[face_idxs[0]];
                faceNormals[i] = Cross(edge1, edge2).Normalized();
                for (uint j = 0; j < 3; ++j)
                {
                    Edge e(face_idxs[j], face_idxs[(j + 1) % 3]);
                    string edgeKey = e.v0 + "_" + e.v1;
                    array<int> @faceList;
                    if (!edgeToGlobalFaces.Get(edgeKey, @faceList))
                    {
                        edgeToGlobalFaces.Set(edgeKey, array<int> = {int(i)});
                    }
                    else
                    {
                        faceList.Add(i);
                    }
                }
            }
            array<bool> processedFaces(numTriangles);
            const float COPLANAR_TOLERANCE = 0.9999f;
            for (uint i = 0; i < numTriangles; ++i)
            {
                if (processedFaces[i])
                    continue;
                array<int> componentQueue = {int(i)};
                array<int> componentFaces = {int(i)};
                processedFaces[i] = true;
                uint head = 0;
                const vec3 referenceNormal = faceNormals[i];
                while (head < componentQueue.Length)
                {
                    int currentIdx = componentQueue[head++];
                    const array<int> @currentFace = triangleFaces[currentIdx];
                    for (uint j = 0; j < 3; ++j)
                    {
                        Edge e(currentFace[j], currentFace[(j + 1) % 3]);
                        string edgeKey = e.v0 + "_" + e.v1;
                        array<int> @neighborFaces;
                        if (edgeToGlobalFaces.Get(edgeKey, @neighborFaces))
                        {
                            for (uint k = 0; k < neighborFaces.Length; ++k)
                            {
                                int neighborIdx = neighborFaces[k];
                                if (!processedFaces[neighborIdx] && Math::Dot(referenceNormal, faceNormals[neighborIdx]) > COPLANAR_TOLERANCE)
                                {
                                    processedFaces[neighborIdx] = true;
                                    componentFaces.Add(neighborIdx);
                                    componentQueue.Add(neighborIdx);
                                }
                            }
                        }
                    }
                }
                dictionary boundaryEdges;
                dictionary vertToBoundaryEdges;
                for (uint c_idx = 0; c_idx < componentFaces.Length; ++c_idx)
                {
                    int triFaceIdx = componentFaces[c_idx];
                    const array<int> @triVerts = triangleFaces[triFaceIdx];
                    for (uint v_idx = 0; v_idx < 3; ++v_idx)
                    {
                        Edge e(triVerts[v_idx], triVerts[(v_idx + 1) % 3]);
                        string edgeKey = e.v0 + "_" + e.v1;
                        array<int> @globalFaces;
                        edgeToGlobalFaces.Get(edgeKey, @globalFaces);
                        int sharedCoplanarFaces = 0;
                        for (uint g_idx = 0; g_idx < globalFaces.Length; ++g_idx)
                        {
                            if (componentFaces.Find(globalFaces[g_idx]) != -1)
                            {
                                sharedCoplanarFaces++;
                            }
                        }
                        if (sharedCoplanarFaces == 1)
                        {
                            if (!boundaryEdges.Exists(edgeKey))
                            {
                                boundaryEdges.Set(edgeKey, e);
                                array<Edge> @v0_edges;
                                if (!vertToBoundaryEdges.Get("" + e.v0, @v0_edges))
                                {
                                    @v0_edges = array<Edge>();
                                    vertToBoundaryEdges.Set("" + e.v0, @v0_edges);
                                }
                                v0_edges.Add(e);
                                array<Edge> @v1_edges;
                                if (!vertToBoundaryEdges.Get("" + e.v1, @v1_edges))
                                {
                                    @v1_edges = array<Edge>();
                                    vertToBoundaryEdges.Set("" + e.v1, @v1_edges);
                                }
                                v1_edges.Add(e);
                            }
                        }
                    }
                }
                array<string> @boundaryEdgeKeys = boundaryEdges.GetKeys();
                if (boundaryEdgeKeys.Length < 3)
                    continue;
                array<int> sortedIndices;
                Edge startEdge;
                boundaryEdges.Get(boundaryEdgeKeys[0], startEdge);
                sortedIndices.Add(startEdge.v0);
                sortedIndices.Add(startEdge.v1);
                dictionary usedEdgeKeys;
                usedEdgeKeys.Set(boundaryEdgeKeys[0], true);
                int currentVert = startEdge.v1;
                int startVert = startEdge.v0;
                while (currentVert != startVert && sortedIndices.Length <= boundaryEdgeKeys.Length)
                {
                    array<Edge> @connectedEdges;
                    vertToBoundaryEdges.Get("" + currentVert, @connectedEdges);
                    bool foundNext = false;
                    for (uint edge_idx = 0; edge_idx < connectedEdges.Length; ++edge_idx)
                    {
                        Edge nextEdge = connectedEdges[edge_idx];
                        string nextEdgeKey = nextEdge.v0 + "_" + nextEdge.v1;
                        if (!usedEdgeKeys.Exists(nextEdgeKey))
                        {
                            usedEdgeKeys.Set(nextEdgeKey, true);
                            currentVert = (nextEdge.v0 == currentVert) ? nextEdge.v1 : nextEdge.v0;
                            sortedIndices.Add(currentVert);
                            foundNext = true;
                            break;
                        }
                    }
                    if (!foundNext)
                    {
                        print("Error: Could not find next edge in chain for merged face.", Severity::Error);
                        break;
                    }
                }
                if (sortedIndices.Length > 0 && sortedIndices[sortedIndices.Length - 1] == startVert)
                {
                    sortedIndices.RemoveAt(sortedIndices.Length - 1);
                }
                if (sortedIndices.Length < 3)
                    continue;
                newFaceIndices.Add(sortedIndices);
                PrecomputedFace pface;
                pface.vertexIndices = sortedIndices;
                pface.normal = GmVec3(referenceNormal);
                pface.planePoint = GmVec3(vertices[sortedIndices[0]]);
                newPrecomputedFaces.Add(pface);
            }
            this.faces = newFaceIndices;
            this.precomputedFaces = newPrecomputedFaces;
            if (this.precomputedFaces.IsEmpty())
            {
            }
            else
            {
                GmVec3 centroid(0, 0, 0);
                for (uint i = 0; i < this.vertices.Length; ++i)
                {
                    centroid += GmVec3(this.vertices[i]);
                }
                if (this.vertices.Length > 0)
                {
                    centroid /= float(this.vertices.Length);
                }
                for (uint i = 0; i < this.precomputedFaces.Length; ++i)
                {
                    PrecomputedFace @pface = this.precomputedFaces[i];
                    if (pface.vertexIndices.Length < 3)
                        continue;
                    GmVec3 v0 = GmVec3(this.vertices[pface.vertexIndices[0]]);
                    GmVec3 v1 = GmVec3(this.vertices[pface.vertexIndices[1]]);
                    GmVec3 v2 = GmVec3(this.vertices[pface.vertexIndices[2]]);
                    GmVec3 correct_normal = Cross(v1 - v0, v2 - v0).Normalized();
                    GmVec3 face_to_center = centroid - v0;
                    if (GmDot(correct_normal, face_to_center) > 0.0f)
                    {
                        correct_normal = -correct_normal;
                    }
                    pface.normal = correct_normal;
                    pface.planePoint = v0;
                }
            }
            if (vertices.IsEmpty() || this.faces.IsEmpty())
                return;
            uint numFaces = this.faces.Length;
            array<Edge> allEdgesTemp;
            for (uint i = 0; i < numFaces; ++i)
            {
                const array<int> @faceIndices = this.faces[i];
                uint faceVertCount = faceIndices.Length;
                if (faceVertCount < 2)
                    continue;
                for (uint v_idx = 0; v_idx < faceVertCount; ++v_idx)
                {
                    int i0 = faceIndices[v_idx];
                    int i1 = faceIndices[(v_idx + 1) % faceVertCount];
                    allEdgesTemp.Add(Edge(i0, i1));
                }
            }
            if (!allEdgesTemp.IsEmpty())
            {
                allEdgesTemp.SortAsc();
                uniqueEdges.Add(allEdgesTemp[0]);
                for (uint i = 1; i < allEdgesTemp.Length; ++i)
                {
                    if (!(allEdgesTemp[i] == uniqueEdges[uniqueEdges.Length - 1]))
                    {
                        uniqueEdges.Add(allEdgesTemp[i]);
                    }
                }
            }
            if (!this.vertices.IsEmpty())
            {
                vec3 center(0, 0, 0);
                for (uint i = 0; i < this.vertices.Length; ++i)
                {
                    center += this.vertices[i];
                }
                center /= float(this.vertices.Length);
                this.BoundingSphereCenter = center;
                float maxRadiusSq = 0.0f;
                for (uint i = 0; i < this.vertices.Length; ++i)
                {
                    float distSq = (this.vertices[i] - this.BoundingSphereCenter).LengthSquared();
                    if (distSq > maxRadiusSq)
                    {
                        maxRadiusSq = distSq;
                    }
                }
                this.BoundingSphereRadius = Math::Sqrt(maxRadiusSq);
            }
            else
            {
                this.BoundingSphereCenter = vec3(0, 0, 0);
                this.BoundingSphereRadius = 0.0f;
            }
        }
        bool GetFaceVertices(uint faceIndex, array<vec3> &out faceVerts) const
        {
            if (faceIndex >= faces.Length)
                return false;
            const array<int> @indices = faces[faceIndex];
            faceVerts.Resize(indices.Length);
            for (uint i = 0; i < indices.Length; ++i)
            {
                int vertexIndex = indices[i];
                if (vertexIndex < 0 || vertexIndex >= int(vertices.Length))
                    return false;
                faceVerts[i] = vertices[vertexIndex];
            }
            return true;
        }
        GmVec3 GetClosestPoint(const GmVec3 &in p) const
        {
            if (precomputedFaces.IsEmpty())
            {
                if (vertices.IsEmpty())
                    return p;
                GmVec3 closest_v(vertices[0].x, vertices[0].y, vertices[0].z);
                float min_dist_sq = (p - closest_v).LengthSquared();
                for (uint i = 1; i < vertices.Length; ++i)
                {
                    GmVec3 current_v(vertices[i].x, vertices[i].y, vertices[i].z);
                    float dist_sq = (p - current_v).LengthSquared();
                    if (dist_sq < min_dist_sq)
                    {
                        min_dist_sq = dist_sq;
                        closest_v = current_v;
                    }
                }
                return closest_v;
            }
            GmVec3 closest_point_overall;
            float min_dist_sq = 1e18f;
            bool first_face = true;
            for (uint i = 0; i < precomputedFaces.Length; ++i)
            {
                const PrecomputedFace @face = precomputedFaces[i];
                GmVec3 projectedPoint = p - face.normal * GmDot(p - face.planePoint, face.normal);
                bool isInside = true;
                for (uint j = 0; j < face.vertexIndices.Length; ++j)
                {
                    GmVec3 v_start = GmVec3(vertices[face.vertexIndices[j]]);
                    GmVec3 v_end = GmVec3(vertices[face.vertexIndices[(j + 1) % face.vertexIndices.Length]]);
                    GmVec3 edge = v_end - v_start;
                    GmVec3 to_point = projectedPoint - v_start;
                    if (GmDot(Cross(edge, to_point), face.normal) < -EPSILON)
                    {
                        isInside = false;
                        break;
                    }
                }
                GmVec3 point_on_face;
                if (isInside)
                {
                    point_on_face = projectedPoint;
                }
                else
                {
                    GmVec3 v_last = GmVec3(vertices[face.vertexIndices[face.vertexIndices.Length - 1]]);
                    GmVec3 v_first = GmVec3(vertices[face.vertexIndices[0]]);
                    point_on_face = closest_point_on_segment(p, v_last, v_first);
                    float min_edge_dist_sq = (p - point_on_face).LengthSquared();
                    for (uint j = 0; j < face.vertexIndices.Length - 1; ++j)
                    {
                        GmVec3 v_start = GmVec3(vertices[face.vertexIndices[j]]);
                        GmVec3 v_end = GmVec3(vertices[face.vertexIndices[j + 1]]);
                        GmVec3 edge_point = closest_point_on_segment(p, v_start, v_end);
                        float dist_sq = (p - edge_point).LengthSquared();
                        if (dist_sq < min_edge_dist_sq)
                        {
                            min_edge_dist_sq = dist_sq;
                            point_on_face = edge_point;
                        }
                    }
                }
                float dist_sq = (p - point_on_face).LengthSquared();
                if (first_face || dist_sq < min_dist_sq)
                {
                    min_dist_sq = dist_sq;
                    closest_point_overall = point_on_face;
                    first_face = false;
                }
            }
            return closest_point_overall;
        }
        bool GetFaceNormal(uint faceIndex, GmVec3 &out normal) const
        {
            if (faceIndex >= precomputedFaces.Length)
                return false;
            normal = precomputedFaces[faceIndex].normal;
            return true;
        }
    };
    class Ellipsoid
    {
        GmVec3 center;
        GmVec3 radii;
        GmMat3 rotation;
        Ellipsoid()
        {
            center = GmVec3(0, 0, 0);
            radii = GmVec3(1, 1, 1);
        }
        Ellipsoid(const GmVec3 &in center, const GmVec3 &in radii, const GmMat3 &in rotation)
        {
            this.center = center;
            this.radii = radii;
            this.rotation = rotation;
        }
        Ellipsoid(const vec3 &in center, const vec3 &in radii, const mat3 &in rotation)
        {
            this.center = GmVec3(center);
            this.radii = GmVec3(radii);
            this.rotation = GmMat3(rotation);
        }
    } array<iso4> currentRunStates;
    array<string> runStatesResultFiles;
    array<iso4> initialRunStates;
    int maxDur = 0;
    float viztime = 0;
    bool runAccepted = false;
    bool stop = false;
    float bestProj = 0.0f;
    BFEvaluationResponse @OnEvaluateUberbug(SimulationManager @simManager, const BFEvaluationInfo &in info)
    {
        BFEvaluationResponse @resp = BFEvaluationResponse();
        auto phase = info.Phase;
        int raceTime = simManager.RaceTime;
        bool isEvalTime = raceTime >= GetVariableDouble(g_uberPluginPrefix + "_bf_time_from") &&
                          raceTime <= GetVariableDouble(g_uberPluginPrefix + "_bf_time_to");
        bool isLastTick = raceTime == GetVariableDouble(g_uberPluginPrefix + "_bf_time_to");
        bool isPastEvalTime = raceTime > GetVariableDouble(g_uberPluginPrefix + "_bf_time_to");
        if (currentUberMode != "Find")
        {
            resp.Decision == BFEvaluationDecision::Stop;
            print("Uberbug evaluation is not implemented for mode: " + currentUberMode);
            return resp;
        }
        if (phase == BFPhase::Initial)
        {
            if (raceTime >= 0)
            {
                initialRunStates.InsertAt(raceTime / 10, simManager.Dyna.CurrentState.Location);
            }
            if (isEvalTime && isUberbug(simManager) && GlobalConditionsMet(simManager))
            {
                if (currentFindMode == "Single")
                {
                    print("Base run already contained a uberbug at time " + Text::FormatInt(raceTime) + ".");
                    resp.Decision == BFEvaluationDecision::Stop;
                }
            }
            if (isPastEvalTime)
            {
                currentRunStates = initialRunStates;
            }
        }
        else
        {
            if (raceTime >= 0 && currentFindMode == "Collect many")
            {
                currentRunStates.RemoveAt(raceTime / 10);
                currentRunStates.InsertAt(raceTime / 10, simManager.Dyna.CurrentState.Location);
            }
            if (isEvalTime && isUberbug(simManager) && !runAccepted && GlobalConditionsMet(simManager))
            {
                if (currentFindMode == "Collect many")
                {
                    totalAmountCollected++;
                    runStatesResultFiles.Add(SaveCurrentInputs(simManager));
                    runAccepted = true;
                    print("Collected uberbug at time " + Text::FormatInt(raceTime) + ".", Severity::Success);
                    if (totalAmountCollected >= GetVariableDouble(g_uberPluginPrefix + "_uberbug_amount"))
                    {
                        stop = true;
                    }
                }
                else if (currentFindMode == "Single")
                {
                    print("Found a uberbug at time " + Text::FormatInt(raceTime) + ". Stopping evaluation.", Severity::Success);
                    SaveCurrentInputs(simManager);
                    resp.Decision = BFEvaluationDecision::Stop;
                    return resp;
                }
                else if (currentFindMode == "Keep best")
                {
                    vec3 desiredTraj = Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point2")) -
                                       Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point1"));
                    vec3 uberTraj = simManager.Dyna.CurrentState.LinearSpeed;
                    float length = uberTraj.Length();
                    if (length > 1000.0f)
                    {
                        uberTraj = uberTraj.Normalized() * 1000.0f;
                    }
                    float k = Math::Acos(Math::Dot(uberTraj.Normalized(), desiredTraj.Normalized())) / 3.14159f * 180.0f;
                    if (k < bestProj)
                    {
                        bestProj = k;
                        SaveCurrentInputs(simManager);
                        print("Found a better uberbug at time " + Text::FormatInt(raceTime) + ". " + Text::FormatFloat(bestProj, "", 0, 9) + " degrees away from trajectory", Severity::Success);
                        resp.Decision = BFEvaluationDecision::Reject;
                    }
                }
            }
            if (isPastEvalTime && !runAccepted)
            {
                resp.Decision = BFEvaluationDecision::Reject;
                currentRunStates = initialRunStates;
            }
        }
        if (raceTime >= int(simManager.EventsDuration) && runAccepted)
        {
            uberbugStates.Add(currentRunStates);
            currentRunStates = initialRunStates;
            runAccepted = false;
            resp.Decision = BFEvaluationDecision::Reject;
            if (stop)
            {
                resp.Decision = BFEvaluationDecision::Stop;
                print("Collected enough uberbugs, stopping evaluation.", Severity::Warning);
            }
        }
        return resp;
    }
    string SaveCurrentInputs(SimulationManager @simManager)
    {
        string filename = currentFindMode == "Collect many" ? GetVariableString(g_uberPluginPrefix + "_uberbug_result_file")
                                                            : GetVariableString("bf_result_filename");
        int i = totalAmountCollected;
        int indexPos = filename.FindLast("{i}");
        CommandList inputs();
        inputs.Content = simManager.InputEvents.ToCommandsText();
        if (indexPos != -1)
        {
            filename.Erase(indexPos, 3);
            filename.Insert(indexPos, Text::FormatInt(i));
        }
        if (inputs.Save(filename))
        {
            print("Saved inputs to " + filename, Severity::Success);
        }
        else
        {
            print("Failed to save inputs to " + filename, Severity::Error);
        }
        return filename;
    }
    bool isUberbug(SimulationManager @simManager)
    {
        vec3 speed = simManager.Dyna.CurrentState.LinearSpeed;
        vec3 previousSpeed = simManager.Dyna.PreviousState.LinearSpeed;
        return Math::Dot(speed.Normalized(), previousSpeed.Normalized()) <= GetVariableDouble(g_uberPluginPrefix + "_uberbug_threshold") && speed.Length() * 3.6f >= GetVariableDouble(g_uberPluginPrefix + "_uberbug_min_speed");
    }
    vec3 GetUberbugTrajectory(SimulationManager @simManager)
    {
        vec3 pos = simManager.Dyna.CurrentState.Location.Position;
        vec3 prevPos = simManager.Dyna.PreviousState.Location.Position;
        return (pos - prevPos);
    }
    int totalAmountCollected = 0;
    void OnUberSimulationBegin(SimulationManager @simManager)
    {
        if (GetVariableString("controller") != "bfv2")
        {
            return;
        }
        string cachedTriggerIds = GetVariableString(g_uberPluginPrefix + "_uberbugs_trigger_cache");
        if (g_uberbugDrawTriggerIds.Length == 0 && cachedTriggerIds != "")
        {
            array<string> ids = cachedTriggerIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i)
            {
                g_uberbugDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        }
        for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i)
        {
            RemoveTrigger(g_uberbugDrawTriggerIds[i]);
        }
        string cachedTrajIds = GetVariableString(g_uberPluginPrefix + "_trajectory_trigger_cache");
        if (g_trajectoryDrawTriggerIds.Length == 0 && cachedTrajIds != "")
        {
            array<string> ids = cachedTrajIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i)
            {
                g_trajectoryDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        }
        for (uint i = 0; i < g_trajectoryDrawTriggerIds.Length; ++i)
        {
            RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
        }
        totalAmountCollected = 0;
        uberbugStates = array<array<iso4>>();
        currentRunStates.Clear();
        initialRunStates.Clear();
        runStatesResultFiles.Clear();
        runAccepted = false;
        maxDur = int(simManager.EventsDuration);
        stop = false;
        closestInputFile = "";
        bestProj = 1e18f;
        g_uberbugDrawTriggerIds.Clear();
        SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
    }
    string currentUberMode = "Find";
    string currentFindMode = "Single";
    array<array<iso4>> uberbugStates;
    void RenderBruteforceEvaluationSettingsUberbug()
    {
        SimulationManager @simManager = GetSimulationManager();
        TM::GameCamera @cam = GetCurrentCamera();
        UI::Dummy(vec2(0, 5));
        UI::PushItemWidth(231);
        if (UI::BeginCombo("Mode", currentUberMode))
        {
            if (UI::Selectable("Find", currentUberMode == "Find"))
            {
                currentUberMode = "Find";
                SetVariable(g_uberPluginPrefix + "_uberbug_mode", currentUberMode);
            }
            if (UI::Selectable("Optimize", currentUberMode == "Optimize"))
            {
                currentUberMode = "Optimize";
                SetVariable(g_uberPluginPrefix + "_uberbug_mode", currentUberMode);
            }
            UI::EndCombo();
        }
        UI::Dummy(vec2(0, 1));
        if (currentUberMode == "Find")
        {
            UI::Dummy(vec2(0, 1));
            if (UI::BeginCombo("Find mode", currentFindMode))
            {
                if (UI::Selectable("Single", currentFindMode == "Single"))
                {
                    currentFindMode = "Single";
                    SetVariable(g_uberPluginPrefix + "_uberbug_find_mode", currentFindMode);
                }
                if (UI::Selectable("Collect many", currentFindMode == "Collect many"))
                {
                    currentFindMode = "Collect many";
                    SetVariable(g_uberPluginPrefix + "_uberbug_find_mode", currentFindMode);
                }
                if (UI::Selectable("Keep best", currentFindMode == "Keep best"))
                {
                    currentFindMode = "Keep best";
                    SetVariable(g_uberPluginPrefix + "_uberbug_find_mode", currentFindMode);
                }
                UI::EndCombo();
            }
            UI::Dummy(vec2(0, 1));
            if (currentFindMode == "Collect many")
            {
                UI::InputIntVar("Amount", g_uberPluginPrefix + "_uberbug_amount", 10);
                UI::Dummy(vec2(0, 1));
                UI::InputTextVar("Result file", g_uberPluginPrefix + "_uberbug_result_file");
                UI::TextDimmed("This is the file where the uberbugs will be saved. {i} will be replaced with the uberbug number, starting from 1.");
                UI::Dummy(vec2(0, 1));
            }
            if (currentFindMode == "Keep best")
            {
                UI::Dummy(vec2(0, 1));
                UI::DragFloat3Var("Point 1", g_uberPluginPrefix + "_uberbug_point1", 0.1f, 0.0f, 0.0f, "%.3f");
                if (simManager.InRace)
                {
                    UI::SameLine();
                    if (UI::Button("Copy cam position"))
                    {
                        SetVariable(g_uberPluginPrefix + "_uberbug_point1", cam.Location.Position.ToString());
                    }
                }
                UI::Dummy(vec2(0, 1));
                UI::DragFloat3Var("Point 2", g_uberPluginPrefix + "_uberbug_point2", 0.1f, 0.0f, 0.0f, "%.3f");
                if (simManager.InRace)
                {
                    UI::SameLine();
                    if (UI::Button("Copy cam position##"))
                    {
                        SetVariable(g_uberPluginPrefix + "_uberbug_point2", cam.Location.Position.ToString());
                    }
                }
                UI::Dummy(vec2(0, 1));
            }
        }
        if (currentUberMode == "Optimize")
        {
            UI::Text("THIS MODE IS NOT IMPLEMENTED YET");
            UI::Dummy(vec2(0, 1));
        }
        UI::Separator();
        UI::Dummy(vec2(0, 5));
        UI::InputFloatVar("Threshold", g_uberPluginPrefix + "_uberbug_threshold", 0.05f);
        UI::PopItemWidth();
        UI::TextDimmed("This is the maximum value for which a dot product is considered valid for a uberbug. If you have no idea what this means, leave it at default (0.8). Decrease slightly if you are getting false positives.");
        UI::Dummy(vec2(0, 5));
        UI::Text("From");
        UI::SameLine();
        UI::Dummy(vec2(30, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing1", g_uberPluginPrefix + "_bf_time_from");
        UI::PopItemWidth();
        UI::Text("To");
        UI::SameLine();
        UI::Dummy(vec2(49, 0));
        UI::SameLine();
        UI::PushItemWidth(150);
        UI::InputTimeVar("##Nothing2", g_uberPluginPrefix + "_bf_time_to");
        UI::Dummy(vec2(0, 5));
        UI::PushItemWidth(231);
        UI::InputFloatVar("Min. speed", g_uberPluginPrefix + "_uberbug_min_speed", 10.0f);
        UI::PopItemWidth();
    }
    string replaySavingFilenameFormat = "";
    int record = 0;
    int currentReplay = 1;
    int replaySavingTime = 0;
    SimulationState baseState;
    void OnRunStep(SimulationManager @simManager)
    {
        CacheCheckpointData();
        if(record==1){
            simManager.GiveUp();
            record=2;
        }else if(record==2){
            simManager.SimulationOnly = true;
            baseState = simManager.SaveState();
            record = 3;
        }else if(record==3){
            string filename = ReplaceI(replaySavingFilenameFormat, currentReplay);
            CommandList list(filename);
            if(list is null) {
                record=0;
                currentReplay=1;
                simManager.SimulationOnly = false;
                print("No more input files found, stopping recording.", Severity::Info);
            }else{
                simManager.RewindToState(baseState);
                list.Process(CommandListProcessOption::OnlyParse);
                SetCurrentCommandList(list);
                record=4;
            }
        }else if(record==4){
            if(simManager.RaceTime >= int(Math::Ceil(replaySavingTime/1000.0))*1000+currentReplay*10){
                SaveReplay(ReplaceI(replaySavingFilenameFormat, currentReplay));
                print("Saved replay " + (currentReplay-1), Severity::Success);
                currentReplay += 1;
                record=3;
            }
        }
    }
    uint64 last_ubertriggers_update = 0;
    array<int> g_uberbugDrawTriggerIds;
    array<int> g_trajectoryDrawTriggerIds;
    int prevTime = -1;
    vec3 prev1();
    vec3 prev2();
    void drawTrajectory(vec3 p1, vec3 p2)
    {
        TM::GameState gameState = GetCurrentGameState();
        string cachedTriggerIds = GetVariableString(g_uberPluginPrefix + "_trajectory_trigger_cache");
        if (g_trajectoryDrawTriggerIds.Length == 0 && cachedTriggerIds != "")
        {
            array<string> ids = cachedTriggerIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i)
            {
                g_trajectoryDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        }
        if (!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_trajectory") || gameState != TM::GameState::LocalRace)
        {
            for (uint i = 0; i < g_trajectoryDrawTriggerIds.Length; i++)
            {
                RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
            }
            g_trajectoryDrawTriggerIds.Clear();
            return;
        }
        vec3 diff = p2 - p1;
        if (diff.LengthSquared() < 1e-6f)
        {
            for (uint i = 0; i < g_trajectoryDrawTriggerIds.Length; i++)
            {
                RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
            }
            g_trajectoryDrawTriggerIds.Clear();
            return;
        }
        if (p1 == prev1 && p2 == prev2)
        {
            if (g_trajectoryDrawTriggerIds.Length != 0)
            {
                return;
            }
        }
        prev1 = p1;
        prev2 = p2;
        for (uint i = 0; i < g_trajectoryDrawTriggerIds.Length; i++)
        {
            RemoveTrigger(g_trajectoryDrawTriggerIds[i]);
        }
        g_trajectoryDrawTriggerIds.Clear();
        SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", "");
        vec3 dir = diff.Normalized();
        float s = 0.4f;
        float spacing = 5.0f;
        vec3 size = vec3(s, s, s);
        vec3 max();
        vec3 min();
        max = p2;
        min = p1;
        string cache = "";
        while (Math::Dot(max - min, dir) > 0)
        {
            int id = SetTrigger(Trigger3D(min - size, size));
            g_trajectoryDrawTriggerIds.Add(id);
            min += dir * s * spacing;
            cache += Text::FormatInt(id) + ",";
        }
        if (cache.Length > 0)
        {
            cache.Erase(cache.Length - 1, 1);
            SetVariable(g_uberPluginPrefix + "_trajectory_trigger_cache", cache);
        }
    }
    uint64 startTime = 0;
    void UberRender()
    {
        if (GetCurrentGameState() == TM::GameState::StartUp)
        {
            startTime = Time::get_Now();
            return;
        }
        if (Time::get_Now() - startTime < 2000)
        {
            return;
        }
        SimulationManager @simManager = GetSimulationManager();
        int raceTime = simManager.RaceTime;
        if (GetVariableBool(g_uberPluginPrefix + "_uberbug_viz_follow_race"))
        {
            drawUberTriggers(raceTime);
        }
        else
        {
            drawUberTriggers(int(viztime * 1000));
        }
        drawTrajectory(
            Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point1")),
            Text::ParseVec3(GetVariableString(g_uberPluginPrefix + "_uberbug_point2")));
    }
    void drawUberTriggers(int time)
    {
        TM::GameState gameState = GetCurrentGameState();
        string cachedTriggerIds = GetVariableString(g_uberPluginPrefix + "_uberbugs_trigger_cache");
        if (g_uberbugDrawTriggerIds.Length == 0 && cachedTriggerIds != "")
        {
            array<string> ids = cachedTriggerIds.Split(",");
            for (uint i = 0; i < ids.Length; ++i)
            {
                g_uberbugDrawTriggerIds.Add(Text::ParseInt(ids[i]));
            }
            SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        }
        if (!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_visualization") || gameState != TM::GameState::LocalRace)
        {
            for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; i++)
            {
                RemoveTrigger(g_uberbugDrawTriggerIds[i]);
            }
            g_uberbugDrawTriggerIds.Clear();
            return;
        }
        if (time == prevTime)
        {
            if (!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_visualization"))
            {
                for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i)
                {
                    RemoveTrigger(g_uberbugDrawTriggerIds[i]);
                }
                g_uberbugDrawTriggerIds.Clear();
            }
            else if (g_uberbugDrawTriggerIds.Length != 0)
            {
                return;
            }
        }
        prevTime = time;
        if (!GetVariableBool(g_uberPluginPrefix + "_uberbug_show_visualization"))
        {
            for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i)
            {
                RemoveTrigger(g_uberbugDrawTriggerIds[i]);
            }
            g_uberbugDrawTriggerIds.Clear();
            return;
        }
        for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i)
        {
            RemoveTrigger(g_uberbugDrawTriggerIds[i]);
        }
        g_uberbugDrawTriggerIds.Clear();
        auto simManager = GetSimulationManager();
        if (simManager is null || !simManager.InRace)
        {
            return;
        }
        if (time < 0)
        {
            return;
        }
        if (uberbugStates.Length == 0)
        {
            return;
        }
        for (uint i = 0; i < uberbugStates.Length; ++i)
        {
            try
            {
                iso4 carTransform = uberbugStates[i][time / 10];
                vec3 carWorldPos = carTransform.Position;
                mat3 carWorldRot = carTransform.Rotation;
                vec3 aabbMin, aabbSize;
                int id;
                vec3 mainBodyLocalHalfExtents(1.5f / 2.0f, 0.45 / 2.0f, 3.0f / 2.0f);
                vec3 mainBodyLocalOffset(0.0f, 0.0f, 0.0f);
                CalculateRotatedAABB(mainBodyLocalOffset, mainBodyLocalHalfExtents, carWorldPos, carWorldRot, aabbMin, aabbSize);
                id = SetTrigger(Trigger3D(aabbMin, aabbSize));
                g_uberbugDrawTriggerIds.Add(id);
                vec3 backPartLocalHalfExtents(0.6f / 2.0f, 0.5f / 2.0f, 0.6f / 2.0f);
                vec3 backPartLocalOffset(0.0f, 0.4f, -0.8f);
                CalculateRotatedAABB(backPartLocalOffset, backPartLocalHalfExtents, carWorldPos, carWorldRot, aabbMin, aabbSize);
                id = SetTrigger(Trigger3D(aabbMin, aabbSize));
                g_uberbugDrawTriggerIds.Add(id);
                vec3 topPartLocalHalfExtents(0.3f / 2.0f, 0.35f / 2.0f, 0.7f / 2.0f);
                vec3 topPartLocalOffset(0.0f, 0.4f, 0.0f);
                CalculateRotatedAABB(topPartLocalOffset, topPartLocalHalfExtents, carWorldPos, carWorldRot, aabbMin, aabbSize);
                id = SetTrigger(Trigger3D(aabbMin, aabbSize));
                g_uberbugDrawTriggerIds.Add(id);
            }
            catch
            {
                continue;
            }
        }
        string cache = "";
        for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i)
        {
            cache += Text::FormatInt(g_uberbugDrawTriggerIds[i]) + ",";
        }
        if (cache.Length > 0)
        {
            cache.Erase(cache.Length - 1, 1);
        }
        SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", cache);
    }
    string closestInputFile = "";
    void UberbugPageSettings()
    {
        UI::CheckboxVar("Show uberbugs visualization", g_uberPluginPrefix + "_uberbug_show_visualization");
        UI::Dummy(vec2(0, 1));
        if (!UI::CheckboxVar("Follow race", g_uberPluginPrefix + "_uberbug_viz_follow_race"))
        {
            viztime = UI::SliderFloat("Time", viztime, 0, maxDur / 1000.0f, "%.2f");
        }
        if (GetSimulationManager().InRace && uberbugStates.Length > 0 && UI::Button("Get inputs from closest car"))
        {
            TM::GameCamera @cam = GetCurrentCamera();
            vec3 position = cam.Location.Position;
            closestInputFile = "";
            float bestDist = 1e18f;
            int time = 0;
            if (GetVariableBool(g_uberPluginPrefix + "_uberbug_viz_follow_race"))
            {
                time = GetSimulationManager().RaceTime;
            }
            else
            {
                time = int(viztime * 1000);
            }
            for (uint i = 0; i < uberbugStates.Length; i++)
            {
                float d = Math::Distance(uberbugStates[i][time / 10].Position, position);
                if (d < bestDist)
                {
                    bestDist = d;
                    closestInputFile = runStatesResultFiles[i];
                }
            }
        }
        if (closestInputFile != "")
        {
            UI::Dummy(vec2(0, 1));
            UI::Text("Closest inputs found: " + closestInputFile);
            UI::Dummy(vec2(0, 1));
            if (UI::Button("Load inputs"))
            {
                CommandList list(closestInputFile);
                list.Process();
                SetCurrentCommandList(list);
            }
            try
            {
                array<VariableInfo> @vars = ListVariables();
                bool hasLoa = false;
                for (uint i = 0; i < vars.Length; ++i)
                {
                    if (vars[i].Name == "plugin_inputsloa_enabled")
                    {
                        hasLoa = GetVariableBool("plugin_inputsloa_enabled");
                        break;
                    }
                }
                if (hasLoa)
                {
                    if (UI::Button("Loa inputs"))
                    {
                        ExecuteCommand("loa " + closestInputFile);
                    }
                }
            }
            catch
            {
            }
        }
        UI::Dummy(vec2(0, 3));
        UI::Separator();
        UI::Dummy(vec2(0, 3));
        UI::TextWrapped("Replay generation from input files");
        UI::Dummy(vec2(0, 1));
        if(GetSimulationManager().InRace){
            replaySavingFilenameFormat = UI::InputTextVar("Filename format", g_uberPluginPrefix + "_replaysaving_filename_format");
            replaySavingTime = UI::InputTimeVar("Time limit", g_uberPluginPrefix + "_replaysaving_time_limit");
            if(replaySavingFilenameFormat.FindFirst("{i}") == -1){
                UI::TextDimmed("Filename format should contain {i} to match the uberbug bruteforce result files.");
            }else if(UI::Button("Generate replays")){
                record = 1;
            }
            UI::TextDimmed("This will go through every input file with a name matching the pattern. Every replay will be saved with a different time, so that they can be differentiated in mediatracker.");
            float root = Math::Ceil(replaySavingTime/1000.0);
            UI::TextDimmed("Given the current time limit, replays will start from: " + root + ".01 s for the first replay, " + root + ".02 s for the second, and so on.");
            UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
            UI::TextWrapped("Make sure to have the Uberbug selected as bruteforce target, otherwise it won't work.");
            UI::PopStyleColor();
        }else{
            UI::TextDimmed("You need to be in a race to generate replays from input files.");
        }
        UI::Dummy(vec2(0, 3));
        UI::Separator();
        UI::Dummy(vec2(0, 3));
        UI::CheckboxVar("Show trajectory preview", g_uberPluginPrefix + "_uberbug_show_trajectory");
    }
    void OnClearUberbugs(int fromTime, int toTime, const string &in commandLine, const array<string> &in args)
    {
        for (uint i = 0; i < g_uberbugDrawTriggerIds.Length; ++i)
        {
            RemoveTrigger(g_uberbugDrawTriggerIds[i]);
        }
        g_uberbugDrawTriggerIds.Clear();
        SetVariable(g_uberPluginPrefix + "_uberbugs_trigger_cache", "");
        uberbugStates.Clear();
    }
    vec3 Mat3MultVec3(const mat3 &in M, const vec3 &in v)
    {
        return vec3(
            M.x.x * v.x + M.x.y * v.y + M.x.z * v.z,
            M.y.x * v.x + M.y.y * v.y + M.y.z * v.z,
            M.z.x * v.x + M.z.y * v.y + M.z.z * v.z);
    }
    void CalculateRotatedAABB(
        const vec3 &in localCenterOffset,
        const vec3 &in localHalfExtents,
        const vec3 &in carWorldPosition,
        const mat3 &in carWorldRotation,
        vec3 &out out_aabbMin,
        vec3 &out out_aabbSize)
    {
        vec3 worldBoxCenter = carWorldPosition + Mat3MultVec3(carWorldRotation, localCenterOffset);
        vec3 newGlobalHalfExtents;
        newGlobalHalfExtents.x = Math::Abs(carWorldRotation.x.x * localHalfExtents.x) +
                                 Math::Abs(carWorldRotation.y.x * localHalfExtents.y) +
                                 Math::Abs(carWorldRotation.z.x * localHalfExtents.z);
        newGlobalHalfExtents.y = Math::Abs(carWorldRotation.x.y * localHalfExtents.x) +
                                 Math::Abs(carWorldRotation.y.y * localHalfExtents.y) +
                                 Math::Abs(carWorldRotation.z.y * localHalfExtents.z);
        newGlobalHalfExtents.z = Math::Abs(carWorldRotation.x.z * localHalfExtents.x) +
                                 Math::Abs(carWorldRotation.y.z * localHalfExtents.y) +
                                 Math::Abs(carWorldRotation.z.z * localHalfExtents.z);
        out_aabbMin = worldBoxCenter - newGlobalHalfExtents;
        out_aabbSize = newGlobalHalfExtents * 2.0f;
    }
    array<vec3> g_polyVertsInCarSpace;
    array<vec3> g_transformedVertices;
    vec3 Normalize(vec3 v)
    {
        float magnitude = v.Length();
        if (magnitude > 1e-6f)
        {
            return v / magnitude;
        }
        return vec3(0, 0, 0);
    }
    vec3 Cross(vec3 a, vec3 b)
    {
        return vec3(a.y * b.z - a.z * b.y,
                    a.z * b.x - a.x * b.z,
                    a.x * b.y - a.y * b.x);
    }
    GmVec3 Cross(const GmVec3 &in a, const GmVec3 &in b)
    {
        return GmVec3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x);
    }
    const float EPSILON = 1e-6f;
    GmIso4 GetCarEllipsoidLocationByIndex(SimulationManager @simM, const GmIso4 &in carLocation, uint index)
    {
        if (index >= 8)
        {
            print("Error: Invalid ellipsoid index requested: " + index + ". Must be 0-7.", Severity::Error);
            return GmIso4();
        }
        if (index >= 4 && g_carEllipsoids.Length <= index)
        {
            print("Error: g_carEllipsoids array not initialized correctly for index " + index, Severity::Error);
            return GmIso4();
        }
        auto simManager = GetSimulationManager();
        GmIso4 worldTransform;
        if (index <= 3)
        {
            GmVec3 wheelSurfaceLocalPos;
            switch (index)
            {
            case 0:
                wheelSurfaceLocalPos = GmVec3(simManager.Wheels.FrontLeft.SurfaceHandler.Location.Position);
                break;
            case 1:
                wheelSurfaceLocalPos = GmVec3(simManager.Wheels.FrontRight.SurfaceHandler.Location.Position);
                break;
            case 2:
                wheelSurfaceLocalPos = GmVec3(simManager.Wheels.BackLeft.SurfaceHandler.Location.Position);
                break;
            case 3:
                wheelSurfaceLocalPos = GmVec3(simManager.Wheels.BackRight.SurfaceHandler.Location.Position);
                break;
            default:
                print("Error: Unexpected index in wheel section: " + index, Severity::Error);
                return GmIso4();
            }
            worldTransform.m_Rotation = carLocation.m_Rotation;
            GmVec3 worldSpaceOffset = carLocation.m_Rotation.Transform(wheelSurfaceLocalPos);
            worldTransform.m_Position = carLocation.m_Position + worldSpaceOffset;
        }
        else
        {
            const GmVec3 @localPositionOffset = g_carEllipsoids[index].center;
            const GmMat3 @localRotation = g_carEllipsoids[index].rotation;
            worldTransform.m_Rotation = carLocation.m_Rotation * localRotation;
            GmVec3 worldSpaceOffset = carLocation.m_Rotation.Transform(localPositionOffset);
            worldTransform.m_Position = carLocation.m_Position + worldSpaceOffset;
        }
        return worldTransform;
    }
    void InitializeCarEllipsoids()
    {
        g_carEllipsoids.Clear();
        const array<GmVec3> radii = {
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.182f, 0.364f, 0.364f),
            GmVec3(0.439118f, 0.362f, 1.901528f),
            GmVec3(0.968297f, 0.362741f, 1.682276f),
            GmVec3(1.020922f, 0.515218f, 1.038007f),
            GmVec3(0.384841f, 0.905323f, 0.283418f)};
        const array<GmVec3> localPositions = {
            GmVec3(0.863012f, 0.3525f, 1.782089f),
            GmVec3(-0.863012f, 0.3525f, 1.782089f),
            GmVec3(0.885002f, 0.352504f, -1.205502f),
            GmVec3(-0.885002f, 0.352504f, -1.205502f),
            GmVec3(0.0f, 0.471253f, 0.219106f),
            GmVec3(0.0f, 0.448782f, -0.20792f),
            GmVec3(0.0f, 0.652812f, -0.89763f),
            GmVec3(-0.015532f, 0.363252f, 1.75357f)};
        array<GmMat3> localRotations;
        localRotations.Resize(8);
        localRotations[4].RotateX(Math::ToRad(3.4160502f));
        localRotations[5].RotateX(Math::ToRad(2.6202483f));
        localRotations[6].RotateX(Math::ToRad(2.6874702f));
        localRotations[7].RotateY(Math::ToRad(90.0f));
        localRotations[7].RotateX(Math::ToRad(90.0f));
        localRotations[7].RotateZ(Math::ToRad(-180.0f));
        for (uint i = 0; i < 8; ++i)
        {
            g_carEllipsoids.Add(Ellipsoid(localPositions[i], radii[i], localRotations[i]));
        }
    }
    float GmDot(const GmVec3 &in a, const GmVec3 &in b)
    {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    GmVec3 GmScale(const GmVec3 &in a, const GmVec3 &in b)
    {
        return GmVec3(a.x * b.x, a.y * b.y, a.z * b.z);
    }
    vec3 FindClosestPointOnPolyToOrigin_Native(const array<vec3> &in transformedVertices, const Polyhedron &in originalPoly)
    {
        if (transformedVertices.IsEmpty())
            return vec3(0, 0, 0);
        vec3 centroid(0, 0, 0);
        for (uint i = 0; i < transformedVertices.Length; ++i)
        {
            centroid += transformedVertices[i];
        }
        if (!transformedVertices.IsEmpty())
        {
            centroid /= float(transformedVertices.Length);
        }
        float max_dist = -1e18f;
        int best_face_index = -1;
        for (uint i = 0; i < originalPoly.precomputedFaces.Length; ++i)
        {
            const PrecomputedFace @face_info = originalPoly.precomputedFaces[i];
            if (face_info.vertexIndices.Length < 3)
                continue;
            const vec3 v0 = transformedVertices[face_info.vertexIndices[0]];
            const vec3 v1 = transformedVertices[face_info.vertexIndices[1]];
            const vec3 v2 = transformedVertices[face_info.vertexIndices[2]];
            vec3 face_normal = Cross(v1 - v0, v2 - v0).Normalized();
            if (Math::Dot(face_normal, centroid - v0) > 0.0f)
            {
                face_normal = face_normal * -1.0f;
            }
            float dist = -Math::Dot(v0, face_normal);
            if (dist > max_dist)
            {
                max_dist = dist;
                best_face_index = i;
            }
        }
        if (best_face_index == -1)
        {
            float min_dist_sq = 1e18f;
            vec3 closest_point;
            for (uint i = 0; i < transformedVertices.Length; i++)
            {
                float dist_sq = transformedVertices[i].LengthSquared();
                if (dist_sq < min_dist_sq)
                {
                    min_dist_sq = dist_sq;
                    closest_point = transformedVertices[i];
                }
            }
            return closest_point;
        }
        const PrecomputedFace @best_face = originalPoly.precomputedFaces[best_face_index];
        const array<int> @vertexIndices = best_face.vertexIndices;
        const vec3 v0 = transformedVertices[vertexIndices[0]];
        const vec3 v1 = transformedVertices[vertexIndices[1]];
        const vec3 v2 = transformedVertices[vertexIndices[2]];
        vec3 best_face_normal = Cross(v1 - v0, v2 - v0).Normalized();
        if (Math::Dot(best_face_normal, centroid - v0) > 0.0f)
        {
            best_face_normal = best_face_normal * -1.0f;
        }
        vec3 projectedPoint = best_face_normal * -Math::Dot(v0, best_face_normal);
        bool isInside = true;
        for (uint j = 0; j < vertexIndices.Length; ++j)
        {
            const vec3 v_start = transformedVertices[vertexIndices[j]];
            const vec3 v_end = transformedVertices[vertexIndices[(j + 1) % vertexIndices.Length]];
            vec3 edge = v_end - v_start;
            vec3 to_point = projectedPoint - v_start;
            if (Math::Dot(Cross(edge, to_point), best_face_normal) < -EPSILON)
            {
                isInside = false;
                break;
            }
        }
        if (isInside)
        {
            return projectedPoint;
        }
        else
        {
            float min_dist_sq = 1e18f;
            vec3 closest_point_on_edge;
            for (uint j = 0; j < vertexIndices.Length; j++)
            {
                const vec3 vA = transformedVertices[vertexIndices[j]];
                const vec3 vB = transformedVertices[vertexIndices[(j + 1) % vertexIndices.Length]];
                vec3 point_on_edge = closest_point_on_segment_from_origin_native(vA, vB);
                float dist_sq = point_on_edge.LengthSquared();
                if (dist_sq < min_dist_sq)
                {
                    min_dist_sq = dist_sq;
                    closest_point_on_edge = point_on_edge;
                }
            }
            return closest_point_on_edge;
        }
    }
    vec3 GetClosestPointOnTransformedPolyhedron(const array<vec3> &in transformedVertices, const Polyhedron &in originalPoly)
    {
        uint64 polyCheckStartTime = Time::get_Now();
        vec3 closestPoint = FindClosestPointOnPolyToOrigin_Native(transformedVertices, originalPoly);
        g_totalClosestPointPolyTime += (Time::get_Now() - polyCheckStartTime);
        return closestPoint;
    }
    float CalculateMinCarDistanceToPoly_Inner(const GmIso4 &in carWorldTransformGm, const Polyhedron @targetPoly)
    {
        if (targetPoly is null || targetPoly.vertices.IsEmpty())
        {
            return 1e18f;
        }
        auto simManager = GetSimulationManager();
        float minDistanceSqOverall = 1e18f;
        iso4 carWorldTransform = carWorldTransformGm.ToIso4();
        mat3 carInvRotation = carWorldTransform.Rotation;
        g_polyVertsInCarSpace.Resize(targetPoly.vertices.Length);
        for (uint i = 0; i < targetPoly.vertices.Length; ++i)
        {
            vec3 v_rel_world = targetPoly.vertices[i] - carWorldTransform.Position;
            g_polyVertsInCarSpace[i] = vec3(
                carInvRotation.x.x * v_rel_world.x + carInvRotation.y.x * v_rel_world.y + carInvRotation.z.x * v_rel_world.z,
                carInvRotation.x.y * v_rel_world.x + carInvRotation.y.y * v_rel_world.y + carInvRotation.z.y * v_rel_world.z,
                carInvRotation.x.z * v_rel_world.x + carInvRotation.y.z * v_rel_world.y + carInvRotation.z.z * v_rel_world.z);
        }
        g_transformedVertices.Resize(targetPoly.vertices.Length);
        for (uint ellipsoidIndex = 0; ellipsoidIndex < g_carEllipsoids.Length; ++ellipsoidIndex)
        {
            const Ellipsoid @baseEllipsoid = g_carEllipsoids[ellipsoidIndex];
            vec3 localPosition = baseEllipsoid.center.ToVec3();
            vec3 invRadii(1.0f / baseEllipsoid.radii.x, 1.0f / baseEllipsoid.radii.y, 1.0f / baseEllipsoid.radii.z);
            if (ellipsoidIndex <= 3)
            {
                iso4 wheelSurfaceLocation;
                switch (ellipsoidIndex)
                {
                case 0:
                    wheelSurfaceLocation = simManager.Wheels.FrontLeft.SurfaceHandler.Location;
                    break;
                case 1:
                    wheelSurfaceLocation = simManager.Wheels.FrontRight.SurfaceHandler.Location;
                    break;
                case 2:
                    wheelSurfaceLocation = simManager.Wheels.BackLeft.SurfaceHandler.Location;
                    break;
                case 3:
                    wheelSurfaceLocation = simManager.Wheels.BackRight.SurfaceHandler.Location;
                    break;
                }
                localPosition = wheelSurfaceLocation.Position;
                for (uint i = 0; i < g_polyVertsInCarSpace.Length; ++i)
                {
                    g_transformedVertices[i] = Scale(g_polyVertsInCarSpace[i] - localPosition, invRadii);
                }
            }
            else
            {
                mat3 localInvRotation = baseEllipsoid.rotation.ToMat3();
                for (uint i = 0; i < g_polyVertsInCarSpace.Length; ++i)
                {
                    vec3 v_relative_to_ellipsoid = g_polyVertsInCarSpace[i] - localPosition;
                    vec3 v_rotated = vec3(
                        localInvRotation.x.x * v_relative_to_ellipsoid.x + localInvRotation.y.x * v_relative_to_ellipsoid.y + localInvRotation.z.x * v_relative_to_ellipsoid.z,
                        localInvRotation.x.y * v_relative_to_ellipsoid.x + localInvRotation.y.y * v_relative_to_ellipsoid.y + localInvRotation.z.y * v_relative_to_ellipsoid.z,
                        localInvRotation.x.z * v_relative_to_ellipsoid.x + localInvRotation.y.z * v_relative_to_ellipsoid.y + localInvRotation.z.z * v_relative_to_ellipsoid.z);
                    g_transformedVertices[i] = Scale(v_rotated, invRadii);
                }
            }
            vec3 p_poly_transformed = GetClosestPointOnTransformedPolyhedron(g_transformedVertices, targetPoly);
            if (p_poly_transformed.LengthSquared() < 1.0f - EPSILON)
            {
                return 0.0f;
            }
            vec3 p_sphere_transformed = p_poly_transformed.Normalized();
            vec3 p_poly_carspace, p_sphere_carspace;
            vec3 p_poly_unscaled = Scale(p_poly_transformed, baseEllipsoid.radii.ToVec3());
            vec3 p_sphere_unscaled = Scale(p_sphere_transformed, baseEllipsoid.radii.ToVec3());
            if (ellipsoidIndex <= 3)
            {
                p_poly_carspace = p_poly_unscaled + localPosition;
                p_sphere_carspace = p_sphere_unscaled + localPosition;
            }
            else
            {
                mat3 localForwardRotation = baseEllipsoid.rotation.ToMat3();
                localForwardRotation.Transpose();
                p_poly_carspace = vec3(
                                      localForwardRotation.x.x * p_poly_unscaled.x + localForwardRotation.y.x * p_poly_unscaled.y + localForwardRotation.z.x * p_poly_unscaled.z,
                                      localForwardRotation.x.y * p_poly_unscaled.x + localForwardRotation.y.y * p_poly_unscaled.y + localForwardRotation.z.y * p_poly_unscaled.z,
                                      localForwardRotation.x.z * p_poly_unscaled.x + localForwardRotation.y.z * p_poly_unscaled.y + localForwardRotation.z.z * p_poly_unscaled.z) +
                                  localPosition;
                p_sphere_carspace = vec3(
                                        localForwardRotation.x.x * p_sphere_unscaled.x + localForwardRotation.y.x * p_sphere_unscaled.y + localForwardRotation.z.x * p_sphere_unscaled.z,
                                        localForwardRotation.x.y * p_sphere_unscaled.x + localForwardRotation.y.y * p_sphere_unscaled.y + localForwardRotation.z.y * p_sphere_unscaled.z,
                                        localForwardRotation.x.z * p_sphere_unscaled.x + localForwardRotation.y.z * p_sphere_unscaled.y + localForwardRotation.z.z * p_sphere_unscaled.z) +
                                    localPosition;
            }
            float distanceSq = (p_poly_carspace - p_sphere_carspace).LengthSquared();
            if (distanceSq < minDistanceSqOverall)
            {
                minDistanceSqOverall = distanceSq;
            }
        }
        return Math::Sqrt(minDistanceSqOverall);
    }
    float CalculateMinCarDistanceToPoly(const GmIso4 &in carWorldTransform, const Polyhedron @targetPoly)
    {
        uint64 funcStartTime = Time::get_Now();
        float result = CalculateMinCarDistanceToPoly_Inner(carWorldTransform, targetPoly);
        g_totalCalcMinCarDistTime += (Time::get_Now() - funcStartTime);
        return result;
    }
    Polyhedron ClipPolyhedronByPlane(const Polyhedron &in poly, const vec3 &in clipPlaneNormal, const vec3 &in clipPlanePoint)
    {
        if (poly.vertices.IsEmpty())
            return poly;
        array<vec3> newVertices;
        array<array<int>> newFaces;
        dictionary vertexMap;
        array<float> vertexDists(poly.vertices.Length);
        for (uint i = 0; i < poly.vertices.Length; i++)
        {
            vertexDists[i] = Math::Dot(poly.vertices[i] - clipPlanePoint, clipPlaneNormal);
        }
        for (uint faceIdx = 0; faceIdx < poly.faces.Length; faceIdx++)
        {
            const array<int> @face = poly.faces[faceIdx];
            if (face.Length < 3)
                continue;
            array<int> newPolygonIndices;
            for (uint i = 0; i < face.Length; i++)
            {
                int currOriginalIdx = face[i];
                int nextOriginalIdx = face[(i + 1) % face.Length];
                float currDist = vertexDists[currOriginalIdx];
                float nextDist = vertexDists[nextOriginalIdx];
                if (currDist <= EPSILON)
                {
                    string key = "" + currOriginalIdx;
                    int newIdx;
                    if (!vertexMap.Get(key, newIdx))
                    {
                        newIdx = newVertices.Length;
                        vertexMap.Set(key, newIdx);
                        newVertices.Add(poly.vertices[currOriginalIdx]);
                    }
                    if (newPolygonIndices.IsEmpty() || newPolygonIndices[newPolygonIndices.Length - 1] != newIdx)
                    {
                        newPolygonIndices.Add(newIdx);
                    }
                }
                if ((currDist > 0 && nextDist < 0) || (currDist < 0 && nextDist > 0))
                {
                    float t = currDist / (currDist - nextDist);
                    vec3 intersectionPoint = poly.vertices[currOriginalIdx] + (poly.vertices[nextOriginalIdx] - poly.vertices[currOriginalIdx]) * t;
                    int newIdx = newVertices.Length;
                    newVertices.Add(intersectionPoint);
                    if (newPolygonIndices.IsEmpty() || newPolygonIndices[newPolygonIndices.Length - 1] != newIdx)
                    {
                        newPolygonIndices.Add(newIdx);
                    }
                }
            }
            if (newPolygonIndices.Length >= 3)
            {
                for (uint i = 1; i < newPolygonIndices.Length - 1; i++)
                {
                    array<int> newTriangle = {
                        newPolygonIndices[0],
                        newPolygonIndices[i],
                        newPolygonIndices[i + 1]};
                    newFaces.Add(newTriangle);
                }
            }
        }
        Polyhedron clippedPoly(newVertices, newFaces);
        return clippedPoly;
    }
    Polyhedron ClipPolyhedronByAABB(const Polyhedron &in poly, const AABB &in box)
    {
        Polyhedron clippedPoly = poly;
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(-1, 0, 0), box.min);
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(1, 0, 0), box.max);
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(0, -1, 0), box.min);
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(0, 1, 0), box.max);
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(0, 0, -1), box.min);
        clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(0, 0, 1), box.max);
        return clippedPoly;
    }
    vec3 Scale(const vec3 &in a, const vec3 &in b)
    {
        return vec3(a.x * b.x, a.y * b.y, a.z * b.z);
    }
    vec3 closest_point_on_segment_from_origin_native(const vec3 &in a, const vec3 &in b)
    {
        vec3 ab = b - a;
        float ab_len_sq = ab.LengthSquared();
        if (ab_len_sq < 1e-12f)
        {
            return a;
        }
        float t = -Math::Dot(a, ab) / ab_len_sq;
        t = Math::Clamp(t, 0.0f, 1.0f);
        return a + ab * t;
    }
    GmVec3 closest_point_on_segment(const GmVec3 &in p, const GmVec3 &in a, const GmVec3 &in b)
    {
        GmVec3 ab = b - a;
        float ab_len_sq = ab.LengthSquared();
        if (ab_len_sq < EPSILON * EPSILON)
        {
            return a;
        }
        float t = GmDot(p - a, ab) / ab_len_sq;
        t = Math::Max(0.0f, Math::Min(1.0f, t));
        return a + ab * t;
    }
    string vec3tostring(const vec3 &in v)
    {
        return "x: " + v.x + ", y: " + v.y + ", z: " + v.z;
    }
}
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
