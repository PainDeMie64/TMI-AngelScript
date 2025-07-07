PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "Skycrafter";
    info.Name = "Auto Start Trick";
    info.Description = "Automatically detects and optimizes start trick inputs for different booster configurations";
    info.Version = "1.0";
    return info;
}

enum Phase
{
    None,
    Error,
    SimPrologue,
    SimInit,
    SimSearch,
    SimEnd
}

auto mainPhase = Phase::None;

array<InputCommand> sstInputs; 
array<InputCommand> leftBoosterInputs; 
array<InputCommand> rightBoosterInputs; 
array<InputCommand> downhillInputs; 
array<InputCommand> platformInputs; 

array<InputCommand> currentInputs; 
array<InputCommand> bestInputs; 
float targetSpeedKmh = 0.0f; 
int evaluationTime = 0; 
float minSpeed = 0.0;

uint64 searchStartTime = 0; 
uint64 searchTimeoutMs = 15000; 

float bestSpeed = 0.0f; 

SimulationStateFile f;
bool isInitialized = false;

void OnRunStep(SimulationManager@ simManager){
    int raceTime = simManager.TickTime;

    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();

    switch (mainPhase) {
        case Phase::None:
            break;
        case Phase::SimPrologue:
            if (raceTime < 0){
                f.CaptureCurrentState(simManager, false);
                isInitialized = true;
            }
            if(raceTime >= 0 && isInitialized) {
                mainPhase = Phase::SimInit;
                simManager.SimulationOnly = true;
                simManager.RewindToState(f.ToState());
            }
            break;
        case Phase::SimInit:
            for(uint i = 0; i < currentInputs.Length; i++) {
                if(currentInputs[i].Timestamp == raceTime) {
                    simManager.SetInputState(currentInputs[i].Type, currentInputs[i].State);

                }
            }
            if(raceTime >= evaluationTime) {
                mainPhase = Phase::SimSearch;
                bestSpeed = simManager.Dyna.CurrentState.LinearSpeed.Length()*3.6;

                bestInputs = currentInputs; 
                searchStartTime = Time::get_Now(); 
                searchTimeoutMs = uint64(Math::Round(GetVariableDouble("sto_bf_timeout_seconds"))*1000);

                MutateInputs();
                simManager.RewindToState(f.ToState());
            }
            break;
        case Phase::SimSearch:
            for(uint i = 0; i < currentInputs.Length; i++) {
                if(currentInputs[i].Timestamp == raceTime) {
                    simManager.SetInputState(currentInputs[i].Type, currentInputs[i].State);
                }
            }
            if(raceTime >= evaluationTime) {
                float currentSpeed = simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6;
                if (currentSpeed > bestSpeed && currentSpeed > minSpeed) {
                    bestSpeed = currentSpeed;
                    bestInputs = currentInputs;
                    print("New best speed: " + bestSpeed + " km/h");
                }
                CommandList bestList;
                bestList.Content = simManager.InputEvents.ToCommandsText();
                bestList.Process(CommandListProcessOption::OnlyParse);
                bestList.Save(GetVariableString("bf_result_filename"));

                if(bestSpeed >= targetSpeedKmh) {
                    mainPhase = Phase::SimEnd;
                    print("Target speed of " + targetSpeedKmh + " km/h reached");
                    break;
                }

                simManager.RewindToState(f.ToState());
                currentInputs = bestInputs; 
                MutateInputs();
            }

            if (Time::get_Now() - searchStartTime > searchTimeoutMs) {
                mainPhase = Phase::SimEnd;
                print("Search timed out");
            }
            break;
        case Phase::SimEnd:
            simManager.SimulationOnly = false;
            print("Optimization complete! Final speed: " + bestSpeed + " km/h", Severity::Success);
            if(GetVariableBool("sto_bf_auto_load_inputs")) {
                CommandList list(GetVariableString("bf_result_filename"));
                list.Process();
                SetCurrentCommandList(list);
            }
            mainPhase = Phase::None; 
            break;
        default:
        break;
    }
}

int state = -4;
uint64 lastUpdate = 0;
uint interval = 15;

void Renderr(){

    if(mainPhase == Phase::None) {
        UI::Text("Waiting to start optimization...");
    } else if(mainPhase == Phase::Error){
        UI::Text("Unkown start trick configuration.");
    } else if(mainPhase == Phase::SimEnd) {
        UI::Text("Optimization complete! Final speed: " + bestSpeed + " km/h");
    }

    UI::InputTextVar("Result file", "bf_result_filename");

    if (UI::Button("Detect & Optimize Start Trick")) {
        mainPhase = Phase::SimPrologue;
        SetCurrentCommandList(null);
        GetSimulationManager().GiveUp();
        isInitialized = false;
        StartTrickAnalysis::TrickInfo@ info = StartTrickAnalysis::AnalyzeStartConfiguration();

        if(info.Type == StartTrickAnalysis::TrickType::None) {
            mainPhase = Phase::Error;
            return;
        }else{
            print("\n\n\n\n\n\n===============================\n");
        }

        string sidePreference = GetVariableString("sto_bf_side_straight");
        bool useRightSide = sidePreference == "right";

        if(info.Type == StartTrickAnalysis::TrickType::ForwardBooster){

            if(useRightSide) {
                currentInputs = FlipSteeringInputs(sstInputs);
                print("Forward Booster detected (RIGHT side)! Target speed: " + info.TargetSpeedKmh + " km/h");
            } else {
                currentInputs = sstInputs;
                print("Forward Booster detected (LEFT side)! Target speed: " + info.TargetSpeedKmh + " km/h");
            }
            targetSpeedKmh = info.TargetSpeedKmh;
            evaluationTime = info.EvaluationTick*10; 
            minSpeed = 208.0;

        } 
        else if(info.Type == StartTrickAnalysis::TrickType::LeftBooster){
            currentInputs = leftBoosterInputs;
            targetSpeedKmh = info.TargetSpeedKmh;
            print("Left Booster detected! Target speed: " + targetSpeedKmh + " km/h");
            evaluationTime = info.EvaluationTick*10; 
            minSpeed = 0;

        }
        else if(info.Type == StartTrickAnalysis::TrickType::RightBooster){
            currentInputs = rightBoosterInputs;
            targetSpeedKmh = info.TargetSpeedKmh;
            print("Right Booster detected! Target speed: " + targetSpeedKmh + " km/h");
            evaluationTime = info.EvaluationTick*10; 
            minSpeed = 0;

        }
        else if(info.Type == StartTrickAnalysis::TrickType::DownhillBooster){

            if(useRightSide) {
                currentInputs = FlipSteeringInputs(downhillInputs);
                print("Downhill Booster detected (RIGHT side)! Target speed: " + info.TargetSpeedKmh + " km/h");
            } else {
                currentInputs = downhillInputs;
                print("Downhill Booster detected (LEFT side)! Target speed: " + info.TargetSpeedKmh + " km/h");
            }
            targetSpeedKmh = info.TargetSpeedKmh;
            evaluationTime = info.EvaluationTick*10; 
            minSpeed = 216.0;

        }
        else if(info.Type == StartTrickAnalysis::TrickType::PlatformBooster){

            if(useRightSide) {
                currentInputs = FlipSteeringInputs(platformInputs);
                print("Platform Booster detected (RIGHT side)! Target speed: " + info.TargetSpeedKmh + " km/h");
            } else {
                currentInputs = platformInputs;
                print("Platform Booster detected (LEFT side)! Target speed: " + info.TargetSpeedKmh + " km/h");
            }
            targetSpeedKmh = info.TargetSpeedKmh;
            evaluationTime = info.EvaluationTick*10; 
            minSpeed = 224;

        }
    }

    if(GetVariableString("sto_bf_side_straight")!="left" && GetVariableString("sto_bf_side_straight")!="right"){
        SetVariable("sto_bf_side_straight", "left");
    }

    if(GetVariableString("sto_bf_side_straight") == "left" && state != -4 && Time::get_Now() - lastUpdate > interval){
        state-=1;
        lastUpdate = Time::get_Now();
    }
    if(GetVariableString("sto_bf_side_straight") == "right" && state != 4 && Time::get_Now() - lastUpdate > interval){
        state+=1;
        lastUpdate = Time::get_Now();
    }

    UI::Dummy(vec2(0, 5));
    UI::Separator();
    UI::Dummy(vec2(0, 2));

    UI::TextWrapped("Choose the side for tricks where both sides are possible:");

    string currentSide = GetVariableString("sto_bf_side_straight");
    UI::Dummy(vec2(0, 3));

    string buttonText = "[";
    for(int i = -4; i <= 4; i++) {
        if(i == state) {
            buttonText += "●";
        } else {
            buttonText += "–";
        }
    }
    buttonText += "]";
    if(state!=-4 && state!=4) UI::BeginDisabled();
    if(UI::Button(buttonText)){
        if(GetVariableString("sto_bf_side_straight") == "left"){
            SetVariable("sto_bf_side_straight", "right");
        }
        else{
            SetVariable("sto_bf_side_straight", "left");
        }
    }

    if(state!=-4 && state!=4) UI::EndDisabled();

    UI::TextDimmed((currentSide == "right" ? "          RIGHT" : "           LEFT"));
    UI::Dummy(vec2(0, 3));

    UI::Dummy(vec2(0, 3));
    UI::CheckboxVar("Load inputs after optimization", "sto_bf_auto_load_inputs");

    UI::Text("Search timeout: ");
    UI::SameLine();
    UI::PushItemWidth(120);
    UI::InputFloatVar("seconds", "sto_bf_timeout_seconds", 0.1);

    UI::Dummy(vec2(0, 15));
    UI::TextDimmed("Credits to the Kackiest Kacky TAS server for the inputs and bruteforce settings");

}

void Main()
{
    CommandList list;
    list.Content="0.00 press up;0.04 steer 2564;0.05 steer 0;0.06 steer -142;0.07 steer 0;0.13 steer -65536;0.14 steer 22576;0.15 steer 0;0.16 steer -65536;0.17 steer 33645;0.18 steer 0;0.23 steer -10437;0.24 steer 0;0.45 steer 2457;0.46 steer 0;0.50 steer -65536;0.51 steer -50022;0.52 steer -65536;0.53 steer 0;0.54 steer -43494;0.55 steer -65536;0.56 steer 38480;0.57 steer 0;0.58 steer 9955;0.59 steer 0;0.64 steer -65536;0.66 steer 65536;0.69 steer 0;0.74 steer 41974;0.75 steer 1388;0.76 steer 0;0.81 steer -65536;0.83 steer 0;0.84 steer 17110;0.85 steer 63;0.86 steer 0;0.95 steer 12685;0.96 steer 459;0.97 steer 0;1.00 steer 316;1.01 steer 0;1.04 steer 65536;1.05 steer 0;1.09 steer -48988;1.10 steer 21940;1.11 steer 0;1.25 steer 3181;1.26 steer 0;1.27 steer -48510;1.28 steer 65536;1.29 steer 0;1.35 steer 28758;1.36 steer 65536;1.37 steer -51067;1.38 steer -59671;1.39 steer 0;1.40 steer 25844;1.41 steer -216;1.42 steer 0;1.43 steer 35633;1.44 steer 4509;1.45 steer 8234;1.46 steer 29920;1.47 steer 10712;1.48 steer -48584;1.49 steer 0;1.50 steer 2077;1.51 steer 58498;1.52 steer 25606;1.53 steer 0;1.54 steer 58398;1.55 steer -62893;1.56 steer 50268;1.57 steer 20570;1.58 steer -38649;1.59 steer 4777;1.60 steer 15290;1.61 steer -46558;1.62 steer -30729;1.63 steer 56028;1.64 steer -1497;1.65 steer 1966;1.66 steer -17678;1.67 steer -4939;1.68 steer 5191;1.69 steer 0;1.70 steer -52980;1.71 steer 61561;1.72 steer -30914;1.73 steer 4762;1.74 steer -26530;1.75 steer 53707;1.76 steer 0";
    list.Process(CommandListProcessOption::OnlyParse);
    sstInputs = list.InputCommands;

    list.Content="0.00 steer -9214;0.00 press up;0.02 steer -10352;0.03 steer -11489;0.04 steer -12058;0.05 steer -12627;0.07 steer -13196;0.13 steer -13765;0.14 steer -14334;0.16 steer -16610;0.17 steer -17178;0.18 steer -16610;0.19 steer -17178;0.20 steer -17747;0.22 steer -18316;0.24 steer -18885;0.25 steer -20023;0.26 steer -20592;0.27 steer -21730;0.28 steer -22299;0.29 steer -22868;0.31 steer -23436;0.37 steer -24005;0.38 steer -23436;0.39 steer -24005;0.40 steer -23436;0.46 steer -22868;0.47 steer -23436;0.50 steer -24005;0.52 steer -23436;0.53 steer -24005;0.55 steer -23436;0.70 steer -24005;0.72 steer -25712;0.73 steer -27419;0.74 steer -28557;0.75 steer -29126;0.76 steer -29694;0.77 steer -31970;0.78 steer -33108;0.79 steer -32539;0.80 steer -31970;0.81 steer -32539;0.82 steer -31970;1.08 steer -32539;1.10 steer -30263;1.11 steer -29126;1.12 steer -29694;1.14 steer -29126;1.15 steer -27419;1.16 steer -26850;1.17 steer -24005;1.19 steer -23436;1.20 steer -22868;1.22 steer -21730;1.23 steer -20592;1.25 steer -19454;1.27 steer -18316;1.28 steer -16610;1.30 steer -14334;1.32 steer -12627;1.33 steer -13196;1.34 steer -12627;1.35 steer -12058;1.36 steer -10352;1.37 steer -9214;1.38 steer -6938;1.40 steer -6369;1.41 steer -5800;1.42 steer -6938;1.44 steer -7507;1.45 steer -6938;1.48 steer -6369;1.49 steer -10352;1.50 steer -13196;1.51 steer -21161;1.52 steer -24574;1.53 steer -29694;1.54 steer -37659;1.55 steer -42210;1.56 steer -47899;1.57 steer -53020;1.58 steer -56433;1.59 steer -64398;1.60 steer -65536;2.08 steer -50744;2.09 steer -33108;2.10 steer -21730;2.11 steer -9214;2.12 steer 0";
    list.Process(CommandListProcessOption::OnlyParse);
    leftBoosterInputs = list.InputCommands;

    list.Content="0.00 steer 9214;0.00 press up;0.02 steer 10352;0.03 steer 11489;0.04 steer 12058;0.05 steer 12627;0.07 steer 13196;0.13 steer 13765;0.14 steer 14334;0.16 steer 16610;0.17 steer 17178;0.18 steer 16610;0.19 steer 17178;0.20 steer 17747;0.22 steer 18316;0.24 steer 18885;0.25 steer 20023;0.26 steer 20592;0.27 steer 21730;0.28 steer 22299;0.29 steer 22868;0.31 steer 23436;0.37 steer 24005;0.38 steer 23436;0.39 steer 24005;0.40 steer 23436;0.46 steer 22868;0.47 steer 23436;0.50 steer 24005;0.52 steer 23436;0.53 steer 24005;0.55 steer 23436;0.70 steer 24005;0.72 steer 25712;0.73 steer 27419;0.74 steer 28557;0.75 steer 29126;0.76 steer 29694;0.77 steer 31970;0.78 steer 33108;0.79 steer 32539;0.80 steer 31970;0.81 steer 32539;0.82 steer 31970;1.08 steer 32539;1.10 steer 30263;1.11 steer 29126;1.12 steer 29694;1.14 steer 29126;1.15 steer 27419;1.16 steer 26850;1.17 steer 24005;1.19 steer 23436;1.20 steer 22868;1.22 steer 21730;1.23 steer 20592;1.25 steer 19454;1.27 steer 18316;1.28 steer 16610;1.30 steer 14334;1.32 steer 12627;1.33 steer 13196;1.34 steer 12627;1.35 steer 12058;1.36 steer 10352;1.37 steer 9214;1.38 steer 6938;1.40 steer 6369;1.41 steer 5800;1.42 steer 6938;1.44 steer 7507;1.45 steer 6938;1.48 steer 6369;1.49 steer 10352;1.50 steer 13196;1.51 steer 21161;1.52 steer 24574;1.53 steer 29694;1.54 steer 37659;1.55 steer 42210;1.56 steer 47899;1.57 steer 53020;1.58 steer 56433;1.59 steer 64398;1.60 steer 65536;2.08 steer 50744;2.09 steer 33108;2.10 steer 21730;2.11 steer 9214;2.12 steer 0";
    list.Process(CommandListProcessOption::OnlyParse);
    rightBoosterInputs = list.InputCommands;

    list.Content="0.00-1.43 press up;0.01 steer 3336;0.02 steer 4705;0.03 steer 0;0.28 steer -43540;0.29 steer 64128;0.30 steer 0;0.51 steer 2589;0.52 steer -41956;0.53 steer -43630;0.54 steer -65536;0.55 steer -57466;0.56 steer -63893;0.57 steer -63576;0.58 steer 20861;0.59 steer 25978;0.60 steer -65536;0.61 steer 65536;0.62 steer -65536;0.63 steer 60795;0.64 steer 43664;0.65 steer 35052;0.66 steer -928;0.67 steer -65536;0.68 steer 15403;0.69 steer -825;0.70 steer -6191;0.71 steer -928;0.72 steer 2128;0.73 steer -47314;0.74 steer -29023;0.75 steer -30062;0.76 steer -65536;0.77 steer 62830;0.78 steer 59307;0.79 steer 9081;0.80 steer 0;0.81 steer 571;0.82 steer -47585;0.83 steer 52873;0.84 steer 0;0.87 steer 880;0.88 steer 0;0.91 steer 23354;0.92 steer 0;0.93 steer -2205;0.94 steer 0;0.96 steer -65536;0.97 steer 27236;0.98 steer -65536;0.99 steer 65536;1.00 steer 0;1.03 steer -27258;1.04 steer 35534;1.05 steer 0;1.07 steer 21930;1.08 steer 3814;1.09 steer 36710;1.10 steer 65536;1.11 steer -34025;1.12 steer -60223;1.13 steer -48034;1.14 steer -50241;1.15 steer -38343;1.16 steer 38690;1.17 steer -65536;1.19 steer -64675;1.20 steer -40783;1.21 steer 50157;1.22 steer -37974;1.23 steer -46231;1.24 steer -65536;1.25 steer -23514;1.26 steer -65536;1.29 steer 21752;1.30 steer -61053;1.31 steer -65536;1.32 steer 12185;1.33 steer -65536;1.34 steer 40610;1.35 steer -65536;1.36 steer 65536;1.38 steer 30608;1.39 steer 65536;1.39-1.68 press down;1.40 steer 52051;1.41 steer 28676;1.42 steer 56277;1.43 steer 65536;1.44 steer 63920;1.45 steer 65536;1.52 steer 57098;1.53 steer 44716;1.54 steer -65536;1.55 steer 30811;1.56 steer -12075;1.57 steer 21309;1.58 steer 4856;1.59 steer -4428;1.60 steer 65536;1.61 steer -59950;1.61 press up;1.62 steer -43630;1.63 steer 65536;1.64 steer -43581;1.65 steer 36716;1.66 steer -47602;1.67 steer -24607;1.68 steer 51625;1.69 steer 64897;1.70 steer 31609;1.71 steer 58389;1.72 steer 57352;1.73 steer 32947;1.74 steer -65536;1.75 steer 36440;1.76 steer 41354;1.77 steer 28858;1.78 steer -59105;1.79 steer 52537;1.80 steer 34992;1.81 steer 1258;1.82 steer 29313;1.83 steer 31624;1.84 steer 46020;1.85 steer 46982;1.86 steer 65536;1.87 steer 4510;1.88 steer 50734;1.89 steer 49084;1.90 steer 61811;1.91 steer -59496;1.92 steer 40450;1.93 steer -221;1.94 steer -47073;1.95 steer -19256;1.96 steer -923;1.97 steer -18694;1.98 steer -52996;1.99 steer -43557;2.00 steer 56117;2.01 steer -45047;2.02 steer -65536;2.03 steer 50080;2.04 steer 23828;2.05 steer -47239;2.06 steer -24864;2.07 steer 65536;2.08 steer 46757;2.09 steer -20759;2.10 steer 0";
    list.Process(CommandListProcessOption::OnlyParse);
    downhillInputs = list.InputCommands;

    list.Content="0.00 press up;0.39 steer -13527;0.41 steer -16591;0.42 steer -14683;0.43 steer -15261;0.46 steer -15475;0.47 steer -15261;0.48 steer -17475;0.49 steer -14683;0.50 steer -15261;0.54 steer -15838;0.55 steer -15261;0.58 steer -15838;0.60 steer -15261;0.63 steer -14683;0.64 steer -15261;0.68 steer -15838;0.69 steer -15261;0.71 steer -15838;0.73 steer -15261;0.74 steer -12981;0.75 steer -15261;0.76 steer -10741;0.77 steer -15261;0.79 steer -14683;0.81 steer -10636;0.82 steer -7747;0.83 steer -1969;0.84 steer 606;0.85 steer 0;0.88 steer 4185;0.89 steer 0;0.91 steer -2547;0.92 steer -4858;0.93 steer -7747;0.94 steer -39512;0.95 steer -9480;0.97 steer -54555;0.98 steer 36111;0.99 steer -10636;1.00 steer -10058;1.03 steer 45315;1.04 steer -7747;1.05 steer -5436;1.06 steer 0;1.10 steer 15299;1.11 steer -35313;1.12 steer 0;1.18 steer -4349;1.19 steer 5883;1.20 steer -981;1.21 steer -186;1.22 steer 0;1.25 steer 1249;1.26 steer 3525;1.27 steer 13765;1.28 steer 40047;1.29 steer 29694;1.30 steer 36521;1.31 steer -17161;1.32 steer 4057;1.33 steer 65536;1.36 steer 57638;1.37 steer 65536;1.38 steer 27483;1.39 steer 65536;1.40 steer -33436;1.41 steer -32206;1.42 steer 37659;1.43 steer -28895;1.44 steer 0;1.45 steer -12729;1.46 steer 0;1.47 steer -847;1.48 steer -3454;1.49 steer 0;1.50 steer 6228;1.51 steer 0;1.52 steer -27250;1.53 steer -7584;1.54 steer -65095;1.55 steer 8619;1.56 steer 0;1.57 steer 42588;1.58 steer -37365;1.59 steer 0;1.61 steer -10812;1.62 steer -51133;1.63 steer 56515;1.64 steer 8646;1.65 steer 25471;1.66 steer -31345;1.67 steer 0;1.68 steer 58164;1.69 steer 17086;1.70 steer 369;1.71 steer -24597;1.72 steer 19410;1.73 steer 35831;1.74 steer -38131;1.75 steer 31439;1.76 steer 0;1.79 steer 24073;1.80 steer 0;1.82 steer 10865;1.83 steer 36158;1.84 steer 4046;1.85 steer 0;1.87 steer 7422;1.88 steer -26615;1.89 steer -56434;1.90 steer -13648;1.91 steer -39436;1.92 steer 31429;1.93 steer -11794;1.94 steer -220;1.95 steer -27974;1.96 steer 49192;1.97 steer -16427;1.98 steer -36644;1.99 steer 8895;2.00 steer -39189;2.01 steer -50887;2.02 steer 41793;2.03 steer 49817;2.04 steer 5098;2.05 steer 0;2.06 steer -10949;2.07 steer 0;2.08 steer 40256;2.09 steer 0;2.10 steer 20182;2.11 steer 40774;2.12 steer -12659;2.13 steer -5222;2.14 steer -11867;2.15 steer 0;2.16 steer 53221;2.17 steer 47855;2.18 steer 1443;2.19 steer 40299;2.20 steer 8235;2.21 steer 0;2.22 steer -57281;2.23 steer -27216;2.24 steer -9309;2.25 steer 54324;2.26 steer 1511;2.27 steer 4233;2.28 steer -24482;2.29 steer 17311;2.30 steer 36063;2.31 steer 3409;2.32 steer -45596;2.33 steer 15969;2.34 steer 0;2.36 steer 60799;2.37 steer -51523;2.38 steer 49404;2.39 steer -48023;2.40 steer -1978;2.41 steer -5179;2.42 steer 15232;2.43 steer -65482;2.44 steer 7103;2.45 steer -34241;2.46 steer 3258;2.47 steer -38684;2.48 steer 45118;2.49 steer 0";
    list.Process(CommandListProcessOption::OnlyParse);
    platformInputs = list.InputCommands;

    RegisterSettingsPage("Start trick", Renderr);

    RegisterVariable("sto_bf_side_straight","left");
    RegisterVariable("sto_bf_auto_load_inputs", true);
    RegisterVariable("sto_bf_timeout_seconds", 15);

    if(GetVariableString("sto_bf_side_straight") == "left"){
        state=-4;
    }else{
        state=4;
    }
}

namespace StartTrickAnalysis {

    enum TrickType {
        None,
        LeftBooster,
        RightBooster,
        ForwardBooster,
        DownhillBooster,
        PlatformBooster
    }

    class TrickInfo {
        TrickType Type = TrickType::None;
        uint EvaluationTick = 0;
        float TargetSpeedKmh = 0.0f;
        string BaseInputFile = "";
        string Description = "No recognized start configuration found.";
    }

     TM::GameCtnBlock@ FindStartBlock(const array<TM::GameCtnBlock@>@ blocks) {
        if (@blocks == null) return null;
        for (uint i = 0; i < blocks.Length; i++) {
            if (blocks[i].WayPointType == TM::WayPointType::Start) {
                return blocks[i];
            }
        }
        return null;
    }

     vec3 GetBlockPosition(TM::GameCtnBlock@ block) {
        return vec3(block.Coord.x * 32, block.Coord.y * 8, block.Coord.z * 32);
    }

     bool IsPositionMatch(vec3 pos1, vec3 pos2, float tolerance = 1.0f) {
        return Math::Abs(pos1.x - pos2.x) < tolerance &&
               Math::Abs(pos1.y - pos2.y) < tolerance &&
               Math::Abs(pos1.z - pos2.z) < tolerance;
    }

     vec3 GetDirectionVector(TM::CardinalDir dir) {
        switch (dir) {
            case TM::CardinalDir::North: return vec3(0, 0, 1);   
            case TM::CardinalDir::East:  return vec3(-1, 0, 0);  
            case TM::CardinalDir::South: return vec3(0, 0, -1);  
            case TM::CardinalDir::West:  return vec3(1, 0, 0);   
        }
        return vec3(); 
    }

     vec3 GetPositionInDirection(vec3 pos, TM::CardinalDir dir, float distance = 32.0f) {
        return pos + GetDirectionVector(dir) * distance;
    }

     TM::GameCtnBlock@ FindBlockAtPosition(const array<TM::GameCtnBlock@>@ blocks, vec3 position, const string &in blockName = "") {
        if (@blocks == null) return null;
        for (uint i = 0; i < blocks.Length; i++) {
            TM::GameCtnBlock@ block = blocks[i];
            if (IsPositionMatch(GetBlockPosition(block), position)) {
                if (blockName.IsEmpty() || block.Name == blockName) {
                    return block;
                }
            }
        }
        return null;
    }

     TM::CardinalDir GetOppositeCardinalDir(TM::CardinalDir dir) {
        switch (dir) {
            case TM::CardinalDir::North: return TM::CardinalDir::South;
            case TM::CardinalDir::East:  return TM::CardinalDir::West;
            case TM::CardinalDir::South: return TM::CardinalDir::North;
            case TM::CardinalDir::West:  return TM::CardinalDir::East;
        }
        return dir;
    }

    class BoosterInfo {
        TM::GameCtnBlock@ Block = null;
        bool IsLeftBooster = false;
        bool IsRightBooster = false;

        TM::GameCtnBlock@ LeftBlock = null;
        TM::GameCtnBlock@ RightBlock = null;
        bool BothBoostersPresent = false;
    }

     BoosterInfo FindValidSideBooster(const array<TM::GameCtnBlock@>@ blocks, TM::GameCtnBlock@ roadBlock, TM::GameCtnBlock@ startBlock) {
        BoosterInfo result;
        vec3 roadPos = GetBlockPosition(roadBlock);
        vec3 startPos = GetBlockPosition(startBlock);

        vec3 forwardVec = roadPos - startPos;

        float length = forwardVec.Length();
        if (length > 0) {
            forwardVec = forwardVec / length;
        } else {

            forwardVec = GetDirectionVector(roadBlock.Dir);
        }

        vec3 leftOffsetDir = vec3(-forwardVec.z, 0, forwardVec.x);
        vec3 rightOffsetDir = vec3(forwardVec.z, 0, -forwardVec.x);

        vec3 rightBoosterPos = roadPos + leftOffsetDir * 32.0f;
        vec3 leftBoosterPos = roadPos + rightOffsetDir * 32.0f;

        TM::CardinalDir expectedLeftBoosterDir = GetOppositeCardinalDir(GetDirectionFromVector(leftOffsetDir));
        TM::CardinalDir expectedRightBoosterDir = GetOppositeCardinalDir(GetDirectionFromVector(rightOffsetDir));

        TM::GameCtnBlock@ leftBooster = null;
        TM::GameCtnBlock@ rightBooster = null;

        for (uint i = 0; i < blocks.Length; i++) {
            TM::GameCtnBlock@ block = blocks[i];
            if (block.Name == "StadiumRoadMainTurbo") {
                vec3 blockPos = GetBlockPosition(block);
                if (IsPositionMatch(blockPos, leftBoosterPos) && block.Dir == expectedLeftBoosterDir) {
                    @leftBooster = block;
                }
                if (IsPositionMatch(blockPos, rightBoosterPos) && block.Dir == expectedRightBoosterDir) {
                    @rightBooster = block;
                }
            }
        }

        @result.LeftBlock = leftBooster;
        @result.RightBlock = rightBooster;

        if (@leftBooster != null && @rightBooster != null) {
            result.BothBoostersPresent = true;

            string sidePreference = GetVariableString("sto_bf_side_straight");
            if (sidePreference == "right") {
                @result.Block = rightBooster;
                result.IsRightBooster = true;
            } else {

                @result.Block = leftBooster;
                result.IsLeftBooster = true;
            }
        } else if (@leftBooster != null) {

            @result.Block = leftBooster;
            result.IsLeftBooster = true;
        } else if (@rightBooster != null) {

            @result.Block = rightBooster;
            result.IsRightBooster = true;
        }

        return result;
    }

    TM::CardinalDir GetDirectionFromVector(vec3 vec) {
        if (Math::Abs(vec.x) > Math::Abs(vec.z)) {
            return vec.x > 0 ? TM::CardinalDir::West : TM::CardinalDir::East;  
        } else {
            return vec.z > 0 ? TM::CardinalDir::North : TM::CardinalDir::South; 
        }
    }

    TrickInfo@ AnalyzeStartConfiguration() {
        TrickInfo@ result = TrickInfo();
        TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
        if (@challenge == null) {
            result.Description = "Error: Could not get current challenge.";
            return result;
        }

        array<TM::GameCtnBlock@> blocks = challenge.Blocks;
        TM::GameCtnBlock@ startBlock = FindStartBlock(blocks);
        if (@startBlock == null) {
            result.Description = "Error: Could not find a start block on the map.";
            return result;
        }

        vec3 startPos = GetBlockPosition(startBlock);
        vec3 posInFront = GetPositionInDirection(startPos, startBlock.Dir);

        vec3 posInFrontDown = vec3(posInFront.x, posInFront.y - 8.0f, posInFront.z);

        TM::GameCtnBlock@ boosterBlock = FindBlockAtPosition(blocks, posInFront, "StadiumRoadMainTurbo");

        if (@boosterBlock != null && boosterBlock.Dir == startBlock.Dir) {
            result.Type = TrickType::ForwardBooster;
            result.Description = "Detected a Forward Booster start.";
            result.EvaluationTick = 210; 
            result.TargetSpeedKmh = 208.7f;
            result.BaseInputFile = "straight_start_trick.txt";
            return result;
        }

        TM::GameCtnBlock@ downhillBlock = FindBlockAtPosition(blocks, posInFrontDown, "StadiumRoadMainTurboDown");
        if (@downhillBlock != null && downhillBlock.Dir == startBlock.Dir) {
            result.Type = TrickType::DownhillBooster;
            result.Description = "Detected a Downhill Booster start.";
            result.EvaluationTick = 230; 
            result.TargetSpeedKmh = 217.0f;
            result.BaseInputFile = "downhill_booster_trick.txt";
            return result;
        }

        TM::GameCtnBlock@ platformBlock = FindBlockAtPosition(blocks, posInFrontDown, "StadiumCircuitTurbo");

        vec3 posInFront2 = GetPositionInDirection(startPos, startBlock.Dir, 64.0f); 
        vec3 posInFront2Down = vec3(posInFront2.x, posInFront2.y - 8.0f, posInFront2.z); 
        TM::GameCtnBlock@ platformBlock2 = FindBlockAtPosition(blocks, posInFront2Down, "StadiumCircuitTurbo");

        if (@platformBlock != null && platformBlock.Dir == startBlock.Dir && 
            @platformBlock2 != null && platformBlock2.Dir == startBlock.Dir) {
            result.Type = TrickType::PlatformBooster;
            result.Description = "Detected a Platform Booster start.";
            result.EvaluationTick = 250; 
            result.TargetSpeedKmh = 224.0f;
            result.BaseInputFile = "platform_booster_trick.txt";
            return result;
        }

        TM::GameCtnBlock@ roadBlock = FindBlockAtPosition(blocks, posInFront, "StadiumRoadMain");
        if (@roadBlock != null) {
            BoosterInfo boosterInfo = FindValidSideBooster(blocks, roadBlock, startBlock);
            if (@boosterInfo.Block != null) {
                if (boosterInfo.BothBoostersPresent) {
                    string sidePreference = GetVariableString("sto_bf_side_straight");
                    if (boosterInfo.IsLeftBooster) {
                        result.Type = TrickType::LeftBooster;
                        result.Description = "Detected both Left and Right Booster options. Using Left based on preference setting.";
                    } else {
                        result.Type = TrickType::RightBooster;
                        result.Description = "Detected both Left and Right Booster options. Using Right based on preference setting.";
                    }
                    print("Both left and right boosters are available. Using " + sidePreference + " side based on preference.");
                } else if (boosterInfo.IsLeftBooster) {
                    result.Type = TrickType::LeftBooster;
                    result.Description = "Detected a Left Booster start.";
                } else if (boosterInfo.IsRightBooster) {
                    result.Type = TrickType::RightBooster;
                    result.Description = "Detected a Right Booster start.";
                }

                result.EvaluationTick = 230; 
                result.TargetSpeedKmh = 169.4f;
                result.BaseInputFile = boosterInfo.IsLeftBooster ? "left_booster_trick.txt" : "right_booster_trick.txt";
                return result;
            }
        }

        return result;
    }
}

array<InputCommand> FlipSteeringInputs(const array<InputCommand> &in inputs) {
    array<InputCommand> flippedInputs = {};

    for(uint i = 0; i < inputs.Length; i++) {
        InputCommand cmd = inputs[i];

        if(cmd.Type == 4) {

            cmd.State = -cmd.State;
        }
        flippedInputs.Add(cmd);
    }

    return flippedInputs;
}

void MutateInputs() {

    if (currentInputs.Length == 0) return;

    int numInputsToMutate = Math::Rand(1, 5);
    numInputsToMutate = Math::Min(numInputsToMutate, int(currentInputs.Length));

    for (int i = 0; i < numInputsToMutate; i++) {

        int inputIndex = Math::Rand(0, int(currentInputs.Length - 1));

        int timestampOffset = Math::Rand(-20, 20);
        currentInputs[inputIndex].Timestamp = Math::Max(0, currentInputs[inputIndex].Timestamp + timestampOffset);

        if (currentInputs[inputIndex].Type == 4) {
            int steerOffset = Math::Rand(-131072, 131072);
            int newSteerValue = currentInputs[inputIndex].State + steerOffset;

            newSteerValue = Math::Max(-65536, Math::Min(65536, newSteerValue));
            currentInputs[inputIndex].State = newSteerValue;
        }
    }
}
