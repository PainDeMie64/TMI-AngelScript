namespace TriggerPlacing{
    vec3 position1;
    vec3 position2;

    bool hasPosition1 = false;
    bool hasPosition2 = false;

 
    vec3 Size(const vec3 &in p1, const vec3 &in p2)
    {
        vec3 d = p1 - p2;
        return vec3(Math::Abs(d.x), Math::Abs(d.y), Math::Abs(d.z));
    }

    vec3 LowerCorner(const vec3 &point1, const vec3 &point2)
    {
        return vec3(Math::Min(point1.x, point2.x), Math::Min(point1.y, point2.y), Math::Min(point1.z, point2.z));
    }

    void ResetPoints()
    {
        hasPosition1 = false;
        hasPosition2 = false;
    }

    void CreateTrigger()
    {
        if (!hasPosition1 || !hasPosition2)
            return;

        Trigger3D trig(LowerCorner(position1, position2), Size(position1, position2));
        SetTrigger(trig);
        ResetPoints();

        log("Successfully created trigger", Severity::Success);
    }

    void PlacePoint1()
    {
        TM::GameCamera@ cam = GetCurrentCamera();
        if (cam is null) return;

        position1 = cam.Location.Position;
        hasPosition1 = true;

        CreateTrigger();
    }

    void PlacePoint2(){
        TM::GameCamera@ cam = GetCurrentCamera();
        if (cam is null) return;

        position2 = cam.Location.Position;
        hasPosition2 = true;

        CreateTrigger();
    }
}

void Render()
{
    if(!UI::IsMainDockVisible()) return;
    if(UI::Begin("BSS", UI::WindowFlags::NoScrollbar)){
        SimulationManager@ simManager = GetSimulationManager();
        bool works = simManager.InRace;
        if(works){
                int time = simManager.RaceTime;
                if(UI::Button("Pmin ##Pointmin")){
                    if(GetVariableString("bf_target")=="uberbug_target"){
                        SetVariable("uber_bf_bf_time_from", time);
                    }else if(GetVariableString("bf_target")=="distance_target"){
                        SetVariable("dist_bf_bf_time_from", time);
                    }else if(GetVariableString("bf_target")=="clbf"){
                        SetVariable("clbf_bf_eval_min_time", time);
                    }else {
                        SetVariable("bf_eval_min_time",time);
                    }
                }
                if(UI::Button("Pmax##Pointmax")){
                    if(GetVariableString("bf_target")=="uberbug_target"){
                        SetVariable("uber_bf_bf_time_to", time);
                    }else if(GetVariableString("bf_target")=="distance_target"){
                        SetVariable("dist_bf_bf_time_to", time);
                    }else if(GetVariableString("bf_target")=="clbf"){
                        SetVariable("clbf_bf_eval_max_time", time);
                    }else {
                        SetVariable("bf_eval_max_time",time);
                    }
                }
                
                if(UI::Button("Imin ##Inputmin")){
                    SetVariable("bf_inputs_min_time",time);
                }
                if(UI::Button("Imax##Inputmax")){
                    SetVariable("bf_inputs_max_time",time);
                }

                if(UI::Button("Pos1##Place point 1")){
                    TriggerPlacing::PlacePoint1();
                }
                if(UI::Button("Pos2##Place point 2")){
                    TriggerPlacing::PlacePoint2();
                }
        }else{
            UI::Text("Not in race.");
        }
    }
    UI::End();
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "UI Shortcuts - personal edition";
    info.Author = "Skycrafter";
    info.Version = "v1.0.0";
    info.Description = "A faster way of performing various actions. Personal edition means that it was tailored to my usage and not made to be user-friendly.";
    return info;
}
