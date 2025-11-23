vec3 position1;
vec3 position2;

void OnTriggerWindowCommand(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    SetVariable("skycrafter_triggerplacing_display", true);
}

vec3 Size(const vec3 &point1, const vec3 &point2)
{
    return vec3(Math::Abs(point1.x - point2.x), Math::Abs(point1.y - point2.y), Math::Abs(point1.z - point2.z));
}

vec3 LowerCorner(const vec3 &point1, const vec3 &point2)
{
    return vec3(Math::Min(point1.x, point2.x), Math::Min(point1.y, point2.y), Math::Min(point1.z, point2.z));
}

void PlacePoint1(){
    TM::GameCamera@ cam = GetCurrentCamera();
    if(!(cam is null)){
        position1=cam.Location.Position;
        log("Placed point 1 at coordinates: " + position1.x + " " + position1.y + " " + position1.z);
        if(!(position2.x == 0 && position2.y == 0 && position2.z == 0)){
            vec3 size = Size(position1, position2);
            vec3 lowerCorner = LowerCorner(position1, position2);
            Trigger3D trig(lowerCorner, size);
            SetTrigger(trig);
            position1=vec3(0, 0, 0);
            position2=vec3(0, 0, 0);
            log("Successfully created trigger", Severity::Success);
        }
    }
}

void PlacePoint2(){
    TM::GameCamera@ cam = GetCurrentCamera();
    if(!(cam is null)){
        position2=cam.Location.Position;
        log("Placed point 2 at coordinates: " + position2.x + " " + position2.y + " " + position2.z);
        if(!(position1.x == 0 && position1.y == 0 && position1.z == 0)){
            vec3 size = Size(position1, position2);
            vec3 lowerCorner = LowerCorner(position1, position2);
            Trigger3D trig(lowerCorner, size);
            SetTrigger(trig);
            position1=vec3(0, 0, 0);
            position2=vec3(0, 0, 0);
            log("Successfully created trigger", Severity::Success);
        }
    }
}

void OnPos1(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    PlacePoint1();
}

void OnPos2(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    PlacePoint2();
}

void Render()
{    
    if(!UI::IsMainDockVisible()) return;
    if(GetVariableBool("skycrafter_triggerplacing_display")){
        if (UI::Begin("Trigger placing")) {
            if(UI::Button("Place point 1")){
                PlacePoint1();
            }
            if(UI::Button("Place point 2")){
                PlacePoint2();
            }
            UI::Dummy(8);
            if(UI::Button("Hide Menu")){
                SetVariable("skycrafter_triggerplacing_display", false);
                log("You can always reopen the menu with the command 'open_triggerplacing_menu'");
            }
        }
        UI::End();
    }
}



void Main()
{
    log("Plugin started.");
    RegisterCustomCommand("pos1", "Register position 1", OnPos1);
    RegisterCustomCommand("pos2", "Register position 2", OnPos2);
    RegisterCustomCommand("open_triggerplacing_menu", "Open the trigger placing menu", OnTriggerWindowCommand);
    RegisterVariable("skycrafter_triggerplacing_display", true);

}

void OnDisabled()
{
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Trigger Placing";
    info.Author = "Skycrafter";
    info.Version = "v1.0.0";
    info.Description = "Easiest way to accurately place triggers";
    return info;
}
