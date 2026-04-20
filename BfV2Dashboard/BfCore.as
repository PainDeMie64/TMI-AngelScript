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
        UI::CheckboxVar("Persist dashboard logs to file", "bf_dashboard_persist_logs");
        toolTip(300, {"When enabled, dashboard improvements and log entries are written to files in the Scripts/BfV2Dashboard/ folder, allowing them to persist across game restarts and appear in Past Sessions."});
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
            RegisterVariable("don_bf_modify_steering_min_time" + varSuffix, 0);
            RegisterVariable("don_bf_modify_steering_max_time" + varSuffix, 5);
            RegisterVariable("don_bf_modify_steering_min_amount" + varSuffix, 1);
            RegisterVariable("don_bf_modify_steering_max_amount" + varSuffix, 5);
            RegisterVariable("don_bf_steering_modification_radius" + varSuffix, 0);
            RegisterVariable("don_bf_modify_steering_min_diff" + varSuffix, 1);
            RegisterVariable("don_bf_modify_steering_max_diff" + varSuffix, 10000);
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
