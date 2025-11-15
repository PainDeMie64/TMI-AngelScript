bool enabled = false;

int counter=0;
const vec2 padFix = vec2(-8, -8);

void square(int x, int y, uint dimension){

    UI::SetNextWindowPos(vec2(x-dimension/2, y-dimension/2) + padFix);
    UI::SetNextWindowSize(vec2(dimension+12, dimension+12));

    UI::Begin("##Window for pixel" + counter,
        UI::WindowFlags::NoBackground
        | UI::WindowFlags::NoDecoration
        | UI::WindowFlags::NoInputs
        | UI::WindowFlags::NoMouseInputs
        | UI::WindowFlags::NoNavInputs
    );

    UI::Button("##pixel" + counter++, vec2(float(dimension), float(dimension)));

    UI::End();
}

dictionary dimensionsMapping;

uint64 timeOfLastCapture=0;
uint64 captureInterval=2000;
int screenWidth=1920;
int screenHeight=1080;

vec3 lastCarPos=vec3(0,0,0);
vec2 lastScreenPos=vec2(0,0);

void Render(){
    if(!enabled)return;
    SimulationManager@ simManager = GetSimulationManager();
    if(!simManager.InRace)return;
    counter=0;
    vec3 carPos = simManager.Dyna.CurrentState.Location.Position;
    mat3 carRot = simManager.Dyna.CurrentState.Location.Rotation;
    quat carQuat = simManager.Dyna.CurrentState.Quat; // Alternative rotation representation

    TM::GameCamera@ gameCamera = GetCurrentCamera();
    vec3 camPos = gameCamera.Location.Position;
    mat3 camRot = gameCamera.Location.Rotation;
    float camFov = gameCamera.Fov; // Varies between 70 and 90 degrees
    uint64 currentTime = Time::Now;
    if(currentTime - timeOfLastCapture > captureInterval){
        timeOfLastCapture = currentTime;
        array<uint8>@ screenshot = Graphics::CaptureScreenshot(vec2(0,0));
        
        if(dimensionsMapping.GetKeys().Find(screenshot.Length+"")!=-1){
            vec2 dim;
            dimensionsMapping.Get(screenshot.Length+"",dim);
            screenWidth=int(dim.x);
            screenHeight=int(dim.y);
        }
    }

    vec2 screenPos;
    if(carPos == lastCarPos){
        screenPos = lastScreenPos;
    } else {
        screenPos = WorldToScreen(carPos, camPos, camRot, camFov, vec2(screenWidth,screenHeight));
        lastScreenPos = screenPos;
    }
    lastCarPos = carPos;

    vec3 rgb=HSVToRGB(GetRainbowHue(), 1.0f, 1.0f);
    vec4 rainbowColor = vec4(rgb.x, rgb.y, rgb.z, 1.0f);
    UI::PushStyleColor(UI::Col::Button, rainbowColor);
    square(int(screenPos.x),int(screenPos.y),30);
    UI::PopStyleColor(1);
    
}

vec2 WorldToScreen(vec3 worldPos, vec3 camPos, mat3 camRot, float camFov, vec2 screenSize){
    vec3 dir = worldPos - camPos;

    camRot.Transpose();
    vec3 localDir = matTimesVec(camRot, dir);

    if (localDir.z <= 0) return vec2(-1, -1);

    float fovRad      = camFov * (3.14159265 / 180.0);
    float aspectRatio = screenSize.x / screenSize.y;
    float tanHalfFov  = Math::Tan(fovRad * 0.5);

    float ndcX = -(localDir.x / localDir.z) / (tanHalfFov * aspectRatio);
    float ndcY =  (localDir.y / localDir.z) /  tanHalfFov;

    float screenX = (ndcX * 0.5 + 0.5) * screenSize.x;
    float screenY = (-ndcY * 0.5 + 0.5) * screenSize.y;

    return vec2(screenX, screenY);
}


vec3 matTimesVec(mat3 m, vec3 v){
    return vec3(
        m.x.x*v.x + m.x.y*v.y + m.x.z*v.z,
        m.y.x*v.x + m.y.y*v.y + m.y.z*v.z,
        m.z.x*v.x + m.z.y*v.y + m.z.z*v.z
    );
}

float GetRainbowHue() {
    float t = float(Time::Now % 6000) / 6000.0f;
    return t * 360.0f;
}

vec3 HSVToRGB(float h, float s, float v) {
    while (h < 0.0f) h += 360.0f;
    while (h >= 360.0f) h -= 360.0f;

    float hPrime = h / 60.0f;
    float hFloor = Math::Floor(hPrime);
    int segment = int(hFloor) % 6;
    if (segment < 0) segment += 6;
    float f = hPrime - hFloor;

    float p = v * (1.0f - s);
    float q = v * (1.0f - f * s);
    float t = v * (1.0f - (1.0f - f) * s);

    if (segment == 0) return vec3(v, t, p);
    if (segment == 1) return vec3(q, v, p);
    if (segment == 2) return vec3(p, v, t);
    if (segment == 3) return vec3(p, q, v);
    if (segment == 4) return vec3(t, p, v);
    return vec3(v, p, q);
}

void TogglePlugin(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    enabled = !enabled;
    if (enabled) {
        log("[Find My Car] Tracking enabled. Type again to disable.");
    } else {
        log("[Find My Car] Tracking disabled. Type again to enable.");
    }
}

void Main() {
    dimensionsMapping=  dictionary();
    dimensionsMapping.Set("1228800",vec2(640,480));
    dimensionsMapping.Set("1920000",vec2(800,600));
    dimensionsMapping.Set("4915200",vec2(1280,960));
    dimensionsMapping.Set("8294400",vec2(1920,1080));
    RegisterCustomCommand("findmycar", "Toggle Find My Car plugin", TogglePlugin);
}
PluginInfo@ GetPluginInfo() {
    auto info = PluginInfo();
    info.Name = "Find my car";
    info.Author = "Skycrafter";
    info.Version = "1.0.0";
    info.Description = "If you lost the car, this plugin will help you find it. Type \"findmycar\" in the console to toggle.";
    return info;
}
