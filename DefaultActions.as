bool newrun=true;
void OnMenuCommand(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    SetVariable("skycrafter_defaultactions_display", true);
}

void Main()
{
    log("Plugin started.");
    RegisterCustomCommand("open_defaultactions_menu", "Well, open the default actions menu", OnMenuCommand);
    RegisterVariable("skycrafter_defaultactions_endtime", 0);
    RegisterVariable("skycrafter_defaultactions_fastforwardspeed", 10);
    RegisterVariable("skycrafter_defaultactions_normalspeed", 1);
    RegisterVariable("skycrafter_defaultactions_enabled", true);
    RegisterVariable("skycrafter_defaultactions_display", true);
    RegisterVariable("skycrafter_defaultactions_graphics", true);
}

void OnRunStep(SimulationManager@ simManager)
{
    if(GetVariableBool("skycrafter_defaultactions_enabled")){
        int time = simManager.get_RaceTime();
        if(time==0){
            newrun=true;
            simManager.SetSpeed(GetVariableDouble("skycrafter_defaultactions_fastforwardspeed"));
            if(!GetVariableBool("skycrafter_defaultactions_graphics")){
                SetVariable("draw_game", false);
            }
        }else if(newrun and time >= GetVariableDouble("skycrafter_defaultactions_endtime")){
            newrun=false;
            simManager.SetSpeed(GetVariableDouble("skycrafter_defaultactions_normalspeed"));
            SetVariable("draw_game", true);
        }
    }
}

void Render()
{
    if(GetVariableBool("skycrafter_defaultactions_display")){
        if (UI::Begin("Default actions")) {
            UI::CheckboxVar("Enable fast forward", "skycrafter_defaultactions_enabled");
            UI::CheckboxVar("Enable graphics", "skycrafter_defaultactions_graphics");
            UI::Text("Set a time below to automatically speed up the race to that point.");
            UI::InputTimeVar("End time", "skycrafter_defaultactions_endtime");
            UI::InputFloatVar("Fast Forward Speed", "skycrafter_defaultactions_fastforwardspeed");
            UI::InputFloatVar("Normal Speed", "skycrafter_defaultactions_normalspeed");
            UI::Dummy(8);
            if(UI::Button("Hide menu")){
                log("You can always reopen the menu with the command 'open_defaultactions_menu'");
                SetVariable("skycrafter_defaultactions_display",false);
            }
            UI::TextDimmed("Reopen the menu with the command 'open_defaultactions_menu'");
        }
        UI::End();
    }
}


PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Default Actions";
    info.Author = "Skycrafter";
    info.Version = "v1.0.0";
    info.Description = "Default actions at the start of each run!";
    return info;
}