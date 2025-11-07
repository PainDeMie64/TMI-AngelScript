int framesToAdvance = 0;
void OnRunStep(SimulationManager@ simManager)
{
    if(framesToAdvance>1){
        framesToAdvance-=1;
    }else if(framesToAdvance==1){
        simManager.SetSpeed(0);
        framesToAdvance=0;
    }
}
void OnFrameAdvance(int fromTime, int toTime, const string&in commandLine, const array<string>&in args){
    GetSimulationManager().SetSpeed(0.2);
    if(args.Length>=1){
        framesToAdvance=Text::ParseInt(args[0]);
    }else{
        framesToAdvance=1;
    }
}


void Main()
{
    log("Plugin started.");
    RegisterCustomCommand("advance_frames", "Well, advance one frame", OnFrameAdvance);
}

void Render()
{
    if(!UI::IsMainDockVisible()) return;
    if (UI::Begin("Advance a frame")) {
        if(UI::Button("Advance")){
            GetSimulationManager().SetSpeed(0.2);
            framesToAdvance=1;
        }
    }
    UI::End();
}


PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Frame Advance";
    info.Author = "Skycrafter&Lukalyc";
    info.Version = "v1.2.0";
    info.Description = "Advance one frame with a command and button";
    return info;
}
