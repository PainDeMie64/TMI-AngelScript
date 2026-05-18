PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Input editor crash fix";
    info.Author = "Skycrafter";
    info.Version = "v1.0.0";
    info.Description = "Prevent a specific crash that happens when making use of \"Preview race at current cursor\" during race end dialog then driving and finishing a new run.";
    return info;
}

void OnGameStateChanged(TM::GameState state) { 
    SetVariable("run_editor_cursor_preview", state == TM::GameState::LocalRace);
}