bool newrun=true;
void OnThingCommand(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    SetVariable("skycrafter_defaultactions_endtime", GetSimulationManager().RaceTime);
}

string loaded = "XItIfNDOrK4UjgV";
string defaultVal = "XItIfNDOrK4UjgV";

void Main()
{
    log("Plugin started.");
    RegisterCustomCommand("set_defaultactions_time", "Define current race time as fast forward end time", OnThingCommand);
    RegisterVariable("skycrafter_defaultactions_endtime", 0);
    RegisterVariable("skycrafter_defaultactions_fastforwardspeed", 10);
    RegisterVariable("skycrafter_defaultactions_normalspeed", 1);
    RegisterVariable("skycrafter_defaultactions_enabled", false);
    RegisterVariable("skycrafter_defaultactions_stateenabled", false);
    RegisterVariable("skycrafter_defaultactions_graphics", true);
    RegisterVariable("skycrafter_defaultactions_statename","state.bin");
    RegisterSettingsPage("Default Actions", RenderSettingsPagee);
}

void OnRunStep(SimulationManager@ simManager)
{   
    int time = simManager.get_RaceTime();
    if(time==0){
        newrun=true;
        if(GetVariableBool("skycrafter_defaultactions_enabled")){
            simManager.SetSpeed(GetVariableDouble("skycrafter_defaultactions_fastforwardspeed"));
            SetVariable("draw_game", GetVariableBool("skycrafter_defaultactions_graphics"));
        }
        if(GetVariableBool("skycrafter_defaultactions_stateenabled")){
            string error;
            SimulationStateFile f;
            if(f.Load(GetVariableString("skycrafter_defaultactions_statename"), error)){
                simManager.RewindToState(f);
            }else{
                log("Could not rewind to state, make sure the name is correct");
            }
        }
        
    }else if(GetVariableBool("skycrafter_defaultactions_enabled") and newrun and time >= GetVariableDouble("skycrafter_defaultactions_endtime")){
        newrun=false;
        simManager.SetSpeed(GetVariableDouble("skycrafter_defaultactions_normalspeed"));
        SetVariable("draw_game", true);
    }
}


void RenderSettingsPagee()
{
    if(UI::BeginTabBar("Default actions")){
        if(UI::BeginTabItem("Fast Forward")){
            UI::CheckboxVar("Enable fast forward", "skycrafter_defaultactions_enabled");
            UI::CheckboxVar("Enable graphics", "skycrafter_defaultactions_graphics");
            UI::Text("Set a time below to automatically speed up the race to that point.");
            UI::InputTimeVar("End time", "skycrafter_defaultactions_endtime");
            UI::InputFloatVar("Fast Forward Speed", "skycrafter_defaultactions_fastforwardspeed");
            UI::InputFloatVar("Normal Speed", "skycrafter_defaultactions_normalspeed");
            UI::EndTabItem();
        }
        if(UI::BeginTabItem("State load")){
            UI::CheckboxVar("Enable state load", "skycrafter_defaultactions_stateenabled");
            UI::InputTextVar("Base state","skycrafter_defaultactions_statename");
            string curr = GetVariableString("skycrafter_defaultactions_statename");
            if(curr!=loaded){
                string error;
                SimulationStateFile f;
                if (!f.Load(curr, error)) {
                    for(uint i = 0 ; i<20 ; i++){
                        UI::Text("STATE FILE "+ curr + " DOESN'T EXIST AND WON'T BE LOADED");
                    }
                }else{
                    loaded=curr;
                }
            }
            UI::EndTabItem();
        }
    UI::EndTabBar();
    
    }
}


PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Default Actions";
    info.Author = "Skycrafter";
    info.Version = "v1.2.0";
    info.Description = "Default actions at the start of each run!";
    return info;
}
