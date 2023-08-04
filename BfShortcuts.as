dictionary points;
bool newstuff = false;
int timeminsuggestion = 0;
int timemaxsuggestion = 0;
string previousChallenge="";


Point lastBfPoint;
class Point {
    float x, y, z;
    
    Point() {}

    Point(vec3 pos) {
        x = pos.x;
        y = pos.y;
        z = pos.z;
    }

    bool equals(Point p){
        return p.x==x && p.y==y && p.z==z;
    }
}

void SetPoint(SimulationManager@ simManager) {
    vec3 pos = simManager.Dyna.CurrentState.Location.Position;
    Point p(pos);
    points[""+simManager.get_RaceTime()]=p;
}

Point StringToPoint(string s){
    Point p();
    array<string> split = s.Split(" ");
    p.x=Text::ParseFloat(split[0]);
    p.y=Text::ParseFloat(split[1]);
    p.z=Text::ParseFloat(split[2]);
    return p;
}

float distanceSquared(Point &in p1, Point &in p2) {
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    float dz = p2.z - p1.z;
    return dx*dx + dy*dy + dz*dz;
}

string findClosestPointTime(dictionary &in dict, Point &in refPoint) {
    float minDistance = Math::INT_MAX;
    string closestKey;
    array<string>@ keys = dict.GetKeys();

    for(uint i = 0; i < keys.Length; i++) {
        Point@ p;
        dict.Get(keys[i], @p);
        float dist = distanceSquared(refPoint, p);
        if(dist < minDistance) {
            minDistance = dist;
            closestKey = keys[i];
        }
    }

    return closestKey;
}



void OnRunStep(SimulationManager@ simManager)
{
    int time = simManager.get_RaceTime();
    if(time==0){
        string curr=GetCurrentChallenge().get_Uid();
        if(curr!=previousChallenge){
            previousChallenge=curr;
            points.DeleteAll();
        }  
    }
    if(time>=0 && time%100==0){
        SetPoint(simManager);
        if(time%1000==0){
            newstuff=true;
        }
    }
    
}



void Render()
{
    if(UI::Begin("Bf settings shortcut")){
        UI::BeginTabBar("Tabs");
        if(UI::BeginTabItem("Time setters")){
            UI::TextWrapped("Click any of these buttons to set the corresponding bruteforce setting to the current race time");
            SimulationManager@ simManager = GetSimulationManager();
            bool works = simManager.get_InRace();
            if(works){
                int time = simManager.get_RaceTime();
                if(UI::Button("Point min")){
                    SetVariable("bf_eval_min_time",time);
                }
                UI::SameLine();
                if(UI::Button("Point max")){
                    SetVariable("bf_eval_max_time",time);
                }
                UI::SameLine();
                if(UI::Button("Reset point")){
                    SetVariable("bf_eval_min_time",0);
                    SetVariable("bf_eval_max_time",0);
                }
                if(UI::Button("Input min")){
                    SetVariable("bf_inputs_min_time",time);
                }
                UI::SameLine();
                if(UI::Button("Input max")){
                    SetVariable("bf_inputs_max_time",time);
                }
                UI::SameLine();
                if(UI::Button("Reset input")){
                    SetVariable("bf_inputs_min_time",0);
                    SetVariable("bf_inputs_max_time",0);
                }
                if(UI::Button("Custom stop time")){
                    SetVariable("bf_override_stop_time",time);
                }
                UI::SameLine();
                if(UI::Button("Reset stop time")){
                    SetVariable("bf_override_stop_time",0);
                }

            }else{
                UI::Text("You must be in a race for this.");
            }
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Auto time frame")){
            if(GetVariableString("bf_target")!="point"){
                UI::TextDimmed("Make sure to select point bruteforce first");
            }
            UI::CheckboxVar("Make calculation automatically","skycrafter_bfsettingsshortcut_auto");
            Point currentPoint = StringToPoint(GetVariableString("bf_target_point"));
            bool calculation = UI::Button("Make calculation");
            if((GetVariableBool("skycrafter_bfsettingsshortcut_auto")||calculation)&&(!currentPoint.equals(lastBfPoint) || newstuff)){
                lastBfPoint=currentPoint;
                newstuff=false;
                int timeMid = Text::ParseInt(findClosestPointTime(points, currentPoint));
                timeminsuggestion=timeMid-500;
                timemaxsuggestion=timeMid+500;
            }
            int timemin = UI::InputTime("Time min", timeminsuggestion);
            int timemax = UI::InputTime("Time max", timemaxsuggestion);
            bool btn = UI::Button("Set time frame");
            if(btn){
                SetVariable("bf_eval_min_time", timeminsuggestion);
                SetVariable("bf_eval_max_time", timemaxsuggestion);
            }
            UI::EndTabItem();
        }
        if(UI::BeginTabItem("Commands list")){
            UI::TextWrapped("Type help to get a detailed description of every command listed here:\n\napply_pointframe_suggestion\nmake_point_frame_calculation\nset_bfpointmin_current\nset_bfpointmax_current\nset_inputmin_current\nset_inputmax_current\nset_stoptime_current");
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }
    UI::End();
}

void OnApply(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    SetVariable("bf_eval_min_time", timeminsuggestion);
    SetVariable("bf_eval_max_time", timemaxsuggestion);
}

void OnPointFrameCalculation(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    Point currentPoint = StringToPoint(GetVariableString("bf_target_point"));
    lastBfPoint=currentPoint;
    newstuff=false;
    int timeMid = Text::ParseInt(findClosestPointTime(points, currentPoint));
    timeminsuggestion=timeMid-500;
    timemaxsuggestion=timeMid+500;
}

void setVariableToCurrentRaceTime(const string&in varName) {
    SimulationManager@ simManager = GetSimulationManager();
    if(simManager.get_InRace()){
        SetVariable(varName, simManager.get_RaceTime());
    }else{
        log("You must be in a race for this command", Severity::Error);
    }
}

void OnBfPointMin(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    setVariableToCurrentRaceTime("bf_eval_min_time");
}

void OnBfPointMax(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    setVariableToCurrentRaceTime("bf_eval_max_time");
}

void OnBfInputMin(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    setVariableToCurrentRaceTime("bf_inputs_min_time");
}

void OnBfInputMax(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    setVariableToCurrentRaceTime("bf_inputs_max_time");
}

void OnBfStopTime(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    setVariableToCurrentRaceTime("bf_override_stop_time");
}


void Main()
{
    log("Plugin started.");
    RegisterVariable("skycrafter_bfsettingsshortcut_auto",false);
    RegisterCustomCommand("apply_pointframe_suggestion", "Apply the suggested time frame to the bruteforce settings", OnApply);
    RegisterCustomCommand("make_point_frame_calculation", "Make the calculation for the time frame for the point bruteforce", OnPointFrameCalculation);
    RegisterCustomCommand("set_bfpointmin_current", "Set the bruteforce point min time to the current race time", OnBfPointMin);
    RegisterCustomCommand("set_bfpointmax_current", "Set the bruteforce point max time to the current race time", OnBfPointMax);
    RegisterCustomCommand("set_inputmin_current", "Set the bruteforce input min time to the current race time", OnBfInputMin);
    RegisterCustomCommand("set_inputmax_current", "Set the bruteforce input max time to the current race time", OnBfInputMax);
    RegisterCustomCommand("set_stoptime_current", "Set the bruteforce custom stop time to the current race time", OnBfStopTime);
}


PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Bf settings shortcuts";
    info.Author = "Skycrafter";
    info.Version = "v1.1.0";
    info.Description = "A faster way of setting bruteforce settings";
    return info;
}