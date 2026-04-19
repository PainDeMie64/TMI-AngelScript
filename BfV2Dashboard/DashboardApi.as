string HandleWorkerRedirect(const string &in body)
{
    return "<html><head><meta http-equiv='refresh' content='0;url=http://localhost:" + Text::FormatUInt(MASTER_PORT) + "/'></head>"
        + "<body>Redirecting to <a href='http://localhost:" + Text::FormatUInt(MASTER_PORT) + "/'>master dashboard</a>...</body></html>";
}

// --- BfV2 API ---

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
    json += "," + JsonUInt("improvements", uint(improvementLog.Length));
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
    json += "," + JsonBool("persistLogs", GetVariableBool("bf_dashboard_persist_logs"));
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
    else if (targetId == "finetuner")
    {
        json += JsonInt("finetuner_eval_from", int(GetVariableDouble("finetuner_eval_from")));
        json += "," + JsonInt("finetuner_eval_to", int(GetVariableDouble("finetuner_eval_to")));
        json += "," + JsonBool("finetuner_target_grouped", GetVariableBool("finetuner_target_grouped"));
        json += "," + JsonInt("finetuner_target_scalar", int(GetVariableDouble("finetuner_target_scalar")));
        json += "," + JsonInt("finetuner_target_group", int(GetVariableDouble("finetuner_target_group")));
        json += "," + JsonInt("finetuner_target_towards", int(GetVariableDouble("finetuner_target_towards")));
        json += "," + JsonFloat("finetuner_target_value", float(GetVariableDouble("finetuner_target_value")));
        json += "," + JsonFloat("finetuner_target_value_display", float(GetVariableDouble("finetuner_target_value_display")));
        vec3 ftVec = Text::ParseVec3(GetVariableString("finetuner_target_vec3"));
        json += "," + JsonVec3("finetuner_target_vec3", ftVec);
        vec3 ftVecDisp = Text::ParseVec3(GetVariableString("finetuner_target_vec3_display"));
        json += "," + JsonVec3("finetuner_target_vec3_display", ftVecDisp);
        json += "," + JsonBool("finetuner_print_by_component", GetVariableBool("finetuner_print_by_component"));
        json += "," + JsonString("finetuner_common_groups", GetVariableString("finetuner_common_groups"));
        json += "," + JsonString("finetuner_common_scalars", GetVariableString("finetuner_common_scalars"));
        json += "," + JsonString("finetuner_common_conditions", GetVariableString("finetuner_common_conditions"));
    }
    else if (targetId == "nosepos_plus")
    {
        json += JsonInt("shweetz_eval_time_min", int(GetVariableDouble("shweetz_eval_time_min")));
        json += "," + JsonInt("shweetz_eval_time_max", int(GetVariableDouble("shweetz_eval_time_max")));
        json += "," + JsonInt("shweetz_yaw_deg", int(GetVariableDouble("shweetz_yaw_deg")));
        json += "," + JsonInt("shweetz_pitch_deg", int(GetVariableDouble("shweetz_pitch_deg")));
        json += "," + JsonInt("shweetz_roll_deg", int(GetVariableDouble("shweetz_roll_deg")));
        json += "," + JsonBool("shweetz_allow_yaw_180", GetVariableBool("shweetz_allow_yaw_180"));
        json += "," + JsonBool("shweetz_next_eval_check", GetVariableBool("shweetz_next_eval_check"));
        json += "," + JsonString("shweetz_next_eval", GetVariableString("shweetz_next_eval"));
        vec3 spPoint = Text::ParseVec3(GetVariableString("shweetz_point"));
        json += "," + JsonVec3("shweetz_point", spPoint);
        json += "," + JsonInt("shweetz_angle_min_deg", int(GetVariableDouble("shweetz_angle_min_deg")));
        json += "," + JsonFloat("shweetz_condition_speed", float(GetVariableDouble("shweetz_condition_speed")));
        json += "," + JsonInt("shweetz_min_cp", int(GetVariableDouble("shweetz_min_cp")));
        json += "," + JsonInt("shweetz_min_wheels_on_ground", int(GetVariableDouble("shweetz_min_wheels_on_ground")));
        json += "," + JsonInt("shweetz_gear", int(GetVariableDouble("shweetz_gear")));
        json += "," + JsonInt("shweetz_trigger_index", int(GetVariableDouble("shweetz_trigger_index")));
        json += "," + JsonInt("shweetz_antitrigger_index", int(GetVariableDouble("shweetz_antitrigger_index")));
        json += "," + JsonInt("shweetz_debug", int(GetVariableDouble("shweetz_debug")));
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

string HandleApplyInputs(const string &in body)
{
    if (!IsBfV2Active)
        return "{\"ok\":false,\"error\":\"BfV2 not active\"}";
    if (!rewindStateAssigned)
        return "{\"ok\":false,\"error\":\"BF not initialized (no rewind state yet)\"}";

    SimulationManager@ sim = GetSimulationManager();
    if (sim is null)
        return "{\"ok\":false,\"error\":\"no simulation manager\"}";

    CommandList list;
    list.Content = body;
    list.Process(CommandListProcessOption::OnlyParse);
    const array<InputCommand>@ cmds = list.InputCommands;
    if (cmds is null || cmds.Length == 0)
        return "{\"ok\":false,\"error\":\"no valid inputs parsed\"}";

    sim.InputEvents.Clear();
    for (uint i = 0; i < cmds.Length; i++)
        sim.InputEvents.Add(cmds[i].Timestamp, cmds[i].Type, cmds[i].State);

    SaveBaseInputs(sim);
    SaveBestInputs(sim);

    RefreshInputModSettings(sim);

    info.Iterations = 0;
    info.Phase = BFPhase::Initial;
    info.Rewinded = false;
    currentIterations = 0;
    currentPhase = "Initial";
    restartCount = 0;
    currentRestarts = 0;
    uint64 nowApply = Time::Now;
    lastImprovementTime = nowApply;
    lastRestartTime = nowApply;
    simStateCache.Clear();
    simStateTimes.Clear();

    if (current !is null && current.onSimBegin !is null)
        current.onSimBegin(sim);

    sim.RewindToState(rewindState);
    RestoreBestInputs(sim);

    // Start a fresh session (old log/improvements go to past)
    StartSession();
    DashboardLog("Base inputs replaced (" + Text::FormatUInt(cmds.Length) + " commands), BF restarted");
    return "{\"ok\":true,\"commands\":" + Text::FormatUInt(cmds.Length) + "}";
}
