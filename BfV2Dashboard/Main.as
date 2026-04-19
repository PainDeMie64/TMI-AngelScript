const uint16 MASTER_PORT = 8489;
const uint16 WORKER_PORT_START = 8490;
const uint16 WORKER_PORT_END = 8520;

bool isMaster = false;
uint16 localPort = 0;
uint instancePid = 0;
uint64 lastHeartbeatTime = 0;
const uint HEARTBEAT_INTERVAL_MS = 3000;

PluginInfo @GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Bruteforce V2 + Dashboard";
    info.Author = "Skycrafter";
    info.Version = "2.0-dashboard-1";
    info.Description = "Next generation bruteforce with web dashboard";
    return info;
}

void RegisterCommonRoutes()
{
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
}

void RegisterMasterRoutes()
{
    RegisterRoute("GET", "/api/instances", HandleGetInstances);
    RegisterRoute("GET", "/", HandleBfDashboard);
}

uint64 lastDiscoverTime = 0;
const uint DISCOVER_INTERVAL_MS = 2000;

void RegisterWorkerRoutes()
{
    RegisterRoute("GET", "/", HandleWorkerRedirect);
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

    instancePid = IO::GetCurrentProcessId();

    SetupAsRole();
}

void SetupAsRole()
{
    routes.Resize(0);
    isMaster = false;

    // Try master
    RegisterCommonRoutes();
    RegisterMasterRoutes();
    StartServer("127.0.0.1", MASTER_PORT);
    if (@listenSock !is null)
    {
        isMaster = true;
        localPort = MASTER_PORT;
        RegisterInstance(instancePid, MASTER_PORT);
        log("BfV2Dashboard: MASTER on port " + Text::FormatUInt(MASTER_PORT) + " (PID " + Text::FormatUInt(instancePid) + ")");
        return;
    }

    // Worker
    routes.Resize(0);
    RegisterCommonRoutes();
    RegisterWorkerRoutes();
    for (uint16 p = WORKER_PORT_START; p <= WORKER_PORT_END; p++)
    {
        StartServer("127.0.0.1", p);
        if (@listenSock !is null)
        {
            localPort = p;
            log("BfV2Dashboard: Worker on port " + Text::FormatUInt(localPort) + " (PID " + Text::FormatUInt(instancePid) + ")");
            return;
        }
    }
    log("BfV2Dashboard: No free port found (8489-" + Text::FormatUInt(WORKER_PORT_END) + " all taken)");
}

uint heartbeatCounter = 0;

void WriteHeartbeatFile()
{
    heartbeatCounter++;
    string path = DATA_FOLDER + "/heartbeats/" + Text::FormatUInt(localPort) + ".txt";
    string content = Text::FormatUInt(instancePid) + "|" + Text::FormatUInt(localPort) + "|" + Text::FormatUInt(heartbeatCounter);
    FileWrite(path, content);
}

void Render()
{
    PollServer();

    // All instances write heartbeat files periodically
    if (localPort > 0)
    {
        uint64 now = Time::Now;
        if (now - lastHeartbeatTime >= HEARTBEAT_INTERVAL_MS)
        {
            lastHeartbeatTime = now;
            WriteHeartbeatFile();
        }
    }

    // Master: discover instances from heartbeat files periodically
    if (isMaster)
    {
        uint64 discNow = Time::Now;
        if (discNow - lastDiscoverTime >= DISCOVER_INTERVAL_MS)
        {
            lastDiscoverTime = discNow;
            DiscoverInstances();
        }
    }

    if (current !is null && current.onRender !is null)
        current.onRender();
}

void OnDisabled()
{
    StopServer();
}
