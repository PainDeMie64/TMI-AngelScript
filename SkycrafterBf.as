// Documentation available at https://donadigo.com/tminterface/plugins/api

BlockTrigger@ finishTrigger = BlockTrigger();
BlockTrigger@ roadCheckpointTrigger = BlockTrigger();
BlockTrigger@ roadCheckpointUpTrigger = BlockTrigger();
BlockTrigger@ roadCheckpointDownTrigger = BlockTrigger();
BlockTrigger@ roadCheckpointLeftTrigger = BlockTrigger();
BlockTrigger@ roadCheckpointRightTrigger = BlockTrigger();


BlockTrigger@ platformCheckpointTrigger = BlockTrigger();
BlockTrigger@ platformCheckpointUpTrigger = BlockTrigger();
BlockTrigger@ platformCheckpointDownTrigger = BlockTrigger();
BlockTrigger@ platformCheckpointLeftTrigger = BlockTrigger();
BlockTrigger@ platformCheckpointRightTrigger = BlockTrigger();
BlockTrigger@ roadDirtHighCheckpointTrigger = BlockTrigger();
BlockTrigger@ roadDirtCheckpointTrigger = BlockTrigger();
BlockTrigger@ grassCheckpointTrigger = BlockTrigger();
BlockTrigger@ ringHCheckpointTrigger = BlockTrigger();
BlockTrigger@ ringVCheckpointTrigger = BlockTrigger();

dictionary blocksTriggers = dictionary();

array<Ellipsoid> we = array<Ellipsoid>(); // We = wheels ellipsoids

array<GameBlock@> finishBlocks = array<GameBlock@>();
array<GameBlock@> checkpointBlocks = array<GameBlock@>();
array<GameBlock@> checkpointNotTakenBlocks = array<GameBlock@>();
uint checkpointCount = 0;
uint targetCpCount = 0;

string current = "Finish Distance";

string info ="";
array<Ellipsoid> nwe = array<Ellipsoid>();
float bestDist = -1;
int bestDistTime = -1;
BFPhase phase = BFPhase::Initial;
bool bruting = false;
int raceTime = 0;

SimulationStateFile f;


float bestExageratedDist = -1;
const float exageration = 2.5+15; //Car half diagonal + trigger half diagonal

bool eval_timeframe = true;
float eval_timemin = 0.0;
float eval_timemax = 0.0;

int64 startTime = 0;

void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target){
    if(phase==BFPhase::Initial&&bruting){
        if(targetCpCount==0){
            f.CaptureCurrentState(simManager, true);
        }
        auto lowest=1e9;
        auto lowestId=-1;
        for(uint i = 0; i < checkpointNotTakenBlocks.Length; i++){
            GameBlock@ block = checkpointNotTakenBlocks[i];
            vec3 center=vec3(block.Coord.x*32,block.Coord.y*8,block.Coord.z*32)+vec3(16,4,16);
            float dist = Math::Distance(simManager.Dyna.CurrentState.Location.Position,center);
            if(dist<lowest){
                lowest=dist;
                lowestId=i;
            }
        }
        if(lowestId!=-1){
            checkpointNotTakenBlocks.RemoveAt(lowestId);
        }
    }
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result){
    phase=BFPhase::Search;
    bruting=false;
}

dictionary temp=dictionary();

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    raceTime = simManager.RaceTime;
    phase=info.Phase;

    auto resp = BFEvaluationResponse();
    if (info.Phase == BFPhase::Initial) {
        bruting = true;
        if(raceTime==10){
            checkpointNotTakenBlocks = checkpointBlocks;
            f.CaptureCurrentState(simManager, true);
        }
        if (targetCpCount!=0&&simManager.PlayerInfo.CurCheckpointCount==targetCpCount) {
            print("Base run already reached target, cancelling bruteforce.",Severity::Error);
            resp.Decision = BFEvaluationDecision::Stop;
            return resp;
        }
        if (GetVariableBool("skycrafter_bf_eval_timeframe")) {
            if (raceTime >= GetVariableDouble("skycrafter_bf_eval_timemin") && raceTime <= GetVariableDouble("skycrafter_bf_eval_timemax")&&simManager.PlayerInfo.CurCheckpointCount == targetCpCount-1) {
                initial(simManager);
            }else if(raceTime > GetVariableDouble("skycrafter_bf_eval_timemax")){
                if(targetCpCount==0){
                    targetCpCount = current=="Finish Distance" ? checkpointCount+1 : simManager.PlayerInfo.CurCheckpointCount+1;
                    simManager.RewindToState(f);
                }else{
                    print("Current best distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s, iteration " + info.Iterations + " (Run time: " + (Time::get_Now()-startTime)/1000 + "s)",Severity::Success);
                    resp.Decision=BFEvaluationDecision::Accept;
                }
            }
        }else {
            if(simManager.PlayerInfo.CurCheckpointCount == targetCpCount-1){
                initial(simManager);
            }
            if(raceTime>int(simManager.get_EventsDuration())){
                if(targetCpCount==0){
                    targetCpCount = current=="Finish Distance" ? checkpointCount+1 : simManager.PlayerInfo.CurCheckpointCount+1;
                    simManager.RewindToState(f);
                }else{
                    print("Current best distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s, iteration " + info.Iterations + " (Run time: " + (Time::get_Now()-startTime)/1000 + "s)",Severity::Success);
                }
            }
        }
            
    } else {
        
        if (GetVariableBool("skycrafter_bf_eval_timeframe")) {
            if (raceTime >= GetVariableDouble("skycrafter_bf_eval_timemin") && raceTime <= GetVariableDouble("skycrafter_bf_eval_timemax") && simManager.PlayerInfo.CurCheckpointCount >= targetCpCount-1) {
                if (simManager.PlayerInfo.CurCheckpointCount==targetCpCount) {
                    print("Reached the target at time " + raceTime + ", congrats!",Severity::Success);
                    print("Reached the target at time " + raceTime + ", congrats!",Severity::Warning);
                    print("Reached the target at time " + raceTime + ", congrats!",Severity::Error);
                    print("Reached the target at time " + raceTime + ", congrats!",Severity::Warning);
                    print("Reached the target at time " + raceTime + ", congrats!",Severity::Success);
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                }
                eval(simManager, resp);
                
            }else if(raceTime > GetVariableDouble("skycrafter_bf_eval_timemax")){
                resp.Decision=BFEvaluationDecision::Reject;
            }
        }else {
            if (simManager.PlayerInfo.CurCheckpointCount==targetCpCount) {
                print("Reached the target at time " + raceTime + ", congrats!",Severity::Success);
                print("Reached the target at time " + raceTime + ", congrats!",Severity::Warning);
                print("Reached the target at time " + raceTime + ", congrats!",Severity::Error);
                print("Reached the target at time " + raceTime + ", congrats!",Severity::Warning);
                print("Reached the target at time " + raceTime + ", congrats!",Severity::Success);
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            }
            TM::PlayerInfo@ playerInfo = simManager.get_PlayerInfo();
            if(simManager.PlayerInfo.CurCheckpointCount == targetCpCount-1){
                eval(simManager, resp);
            }
            if(raceTime>int(simManager.get_EventsDuration())){
                resp.Decision=BFEvaluationDecision::Reject;
            }
        }
    }

    return resp;
}

void initial(SimulationManager@ simManager){
    if(current=="Finish Distance"){    
        float currentDistWithExageration = calculateCenterToCenterDistanceToAnyFinish()+exageration;
        if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
            return;
        }
        float dist = calculateShortestDistanceToAnyFinish();
        if (dist < bestDist || bestDist == -1) {
            bestDist = dist;
            bestDistTime = raceTime;
            bestExageratedDist = currentDistWithExageration;
        }
    }else if(current=="Checkpoint Distance"){
        float currentDistWithExageration = calculateCenterToCenterDistanceToAnyUnreachedCheckpoint()+exageration;
        if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
            return;
        }
        float dist = calculateShortestDistanceToAnyUnreachedCheckpoint();
        if (dist < bestDist || bestDist == -1) {
            bestDist = dist;
            bestDistTime = raceTime;
            bestExageratedDist = currentDistWithExageration;
        }
    }

    
}


void eval(SimulationManager@ simManager, BFEvaluationResponse&out resp){
    if(current=="Finish Distance"){    
        float currentDistWithExageration = calculateCenterToCenterDistanceToAnyFinish()+exageration;
        if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
            return;
        }
        float dist = calculateShortestDistanceToAnyFinish();
        if (dist < bestDist || bestDist == -1) {
            bestDist = dist;
            bestDistTime = raceTime;
            resp.Decision=BFEvaluationDecision::Accept;
        }
    }else if(current=="Checkpoint Distance"){
        float currentDistWithExageration = calculateCenterToCenterDistanceToAnyUnreachedCheckpoint()+exageration;
        if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
            return;
        }
        float dist = calculateShortestDistanceToAnyUnreachedCheckpoint();
        if (dist < bestDist || bestDist == -1) {
            bestDist = dist;
            bestDistTime = raceTime;
            resp.Decision=BFEvaluationDecision::Accept;
        }
    }
}

float calculateCenterToCenterDistanceToAnyUnreachedCheckpoint(){
    SimulationManager@ simManager = GetSimulationManager();
    float calculated_distance = 1e9;
    const vec3 carLocation = simManager.Dyna.CurrentState.Location.Position;
    vec3 relativeCenter;
    const vec3 offset=vec3(16,4,16);
    for(uint i = 0; i < checkpointBlocks.Length; i++){
        GameBlock@ block = checkpointBlocks[i];
        vec3 centerLocation = vec3(block.Coord.x*32,block.Coord.y*8,block.Coord.z*32)+offset;//+relativeCenter;
        if(block.Name.Substr(0,block.Name.FindFirst("Checkpoint")).Length!=block.Name.Length-10){
            centerLocation+=vec3(0,4,0);
        }
        vec3 size=vec3(1,1,1);
        float dist = Math::Distance(carLocation,centerLocation);
        if(dist<calculated_distance){
            calculated_distance = dist;
        }
    }
    return calculated_distance;
}

float calculateShortestDistanceToAnyUnreachedCheckpoint(){
    SimulationManager@ simManager = GetSimulationManager();
    float calculated_distance = 1e9;
    const GmIso4@ carLocation = simManager.Dyna.CurrentState.Location;
    GmIso4 ellipsoidLocation;


    for (uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++) {
        GetCarEllipsoidLocationByIndex(simManager, carLocation, ellipsoidId, ellipsoidLocation);
        Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),we[ellipsoidId].size);

        for(uint i = 0; i < checkpointNotTakenBlocks.Length;i++){
            bool rightCp = checkpointNotTakenBlocks[i].Name.FindFirst("Right")!=-1;
            Polyhedron polyhedron = Polyhedron(checkpointNotTakenBlocks[i].trigger.vertices,checkpointNotTakenBlocks[i].trigger.faceIndices);
            float dist = findDist(ellipsoid,polyhedron);
            if(dist<calculated_distance){
                calculated_distance = dist;
            }
        }
    }
    return calculated_distance;
}

void RenderEvalSettings()
{
    UI::TextWrapped("This plugin allows you to bruteforce different targets implemented by Skycrafter.");
    if(UI::BeginCombo("Label", current)){
        if(UI::Selectable("Finish Distance", false)){
            current="Finish Distance";
        }
        if(UI::Selectable("Checkpoint Distance", false)){
            current="Checkpoint Distance";
        }
        SetVariable("skycrafter_bf_mode", current);
        UI::EndCombo();
    }

    if(current=="Finish Distance"||current=="Checkpoint Distance"){
        UI::BeginDisabled();
        UI::Checkbox("Only wheels", true);
        UI::SameLine();
        UI::TextWrapped("(Unchangeable: Work In Progress)");
        UI::EndDisabled();
        eval_timeframe=UI::CheckboxVar("Custom Time frame", "skycrafter_bf_eval_timeframe");
        UI::TextDimmed("If not ticked, the evaluation will start after picking up the last checkpoint.");
        if(eval_timeframe){
            eval_timemin=UI::InputTimeVar("Time min", "skycrafter_bf_eval_timemin", 100, 0);
            if(GetVariableDouble("skycrafter_bf_eval_timemax") < GetVariableDouble("skycrafter_bf_eval_timemin")){
                SetVariable("skycrafter_bf_eval_timemax", GetVariableDouble("skycrafter_bf_eval_timemin"));
            }
            eval_timemax=UI::InputTimeVar("Time max", "skycrafter_bf_eval_timemax", 100, 0);
        }
    }

}

void Main()
{
    finishTrigger.vertices={vec3(3.0, 1.0, 12.205891), vec3(3.0, 1.0, 11.79281), vec3(30.0, 1.0, 11.79281), vec3(30.0, 1.0, 12.205891), vec3(30.0, 1.9485588, 12.205891), vec3(26.664326, 5.083612, 12.205891), vec3(19.401665, 7.814228, 12.205891), vec3(12.598329, 7.814228, 12.205891), vec3(5.325968, 5.0799665, 12.205891), vec3(3.0, 2.889081, 12.205891), vec3(30.0, 1.9485588, 11.79281), vec3(3.0, 2.889081, 11.792811), vec3(5.325968, 5.0799665, 11.79281), vec3(12.598328, 7.814228, 11.79281), vec3(19.401665, 7.814228, 11.79281), vec3(26.664326, 5.083612, 11.79281)};
    finishTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};

    roadCheckpointTrigger.vertices={vec3(3.0, 1.0, 16.20654), vec3(3.0, 1.0, 15.793459), vec3(30.0, 1.0, 15.793459), vec3(30.0, 1.0, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(3.0, 2.8890808, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(3.0, 2.8890808, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)};
    roadCheckpointTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};
    
    roadCheckpointUpTrigger.vertices={vec3(3.0, 5.305454, 16.20654), vec3(3.0, 5.205257, 15.79346), vec3(30.0, 5.205257, 15.793459), vec3(30.0, 5.305454, 16.20654), vec3(30.0, 6.0024333, 16.20654), vec3(26.664326, 9.137486, 16.20654), vec3(19.401665, 11.868102, 16.20654), vec3(12.598328, 11.868102, 16.20654), vec3(5.325968, 9.133841, 16.20654), vec3(3.0, 6.942955, 16.20654), vec3(30.0, 5.9022365, 15.793459), vec3(3.0, 6.842759, 15.79346), vec3(5.325968, 9.033645, 15.79346), vec3(12.598328, 11.767906, 15.79346), vec3(19.401665, 11.767906, 15.793459), vec3(26.664326, 9.03729, 15.793459)};
    roadCheckpointUpTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};
    
    roadCheckpointDownTrigger.vertices={vec3(29.133787, 5.305454, 15.793457), vec3(29.133787, 5.205257, 16.206537), vec3(2.1337872, 5.205257, 16.206541), vec3(2.1337872, 5.305454, 15.793461), vec3(2.1337872, 6.0024333, 15.793461), vec3(5.4694614, 9.137486, 15.793461), vec3(12.732122, 11.868102, 15.793459), vec3(19.53546, 11.868102, 15.793458), vec3(26.80782, 9.133841, 15.793457), vec3(29.133787, 6.942955, 15.793457), vec3(2.1337872, 5.9022365, 16.206541), vec3(29.133787, 6.842759, 16.206537), vec3(26.80782, 9.033645, 16.206537), vec3(19.53546, 11.767906, 16.206537), vec3(12.732122, 11.767906, 16.20654), vec3(5.4694605, 9.03729, 16.206541)};
    roadCheckpointDownTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};
    
    roadCheckpointLeftTrigger.vertices={vec3(3.0, 8.565392, 16.20654), vec3(3.0, 8.565392, 15.793459), vec3(30.0, 1.7613418, 15.793459), vec3(30.0, 1.7613418, 16.20654), vec3(30.0, 2.7099004, 16.20654), vec3(26.664326, 6.6855497, 16.20654), vec3(19.401665, 11.24637, 16.20654), vec3(12.598328, 12.960824, 16.20654), vec3(5.325968, 12.05921, 16.20654), vec3(3.0, 10.454473, 16.20654), vec3(30.0, 2.7099004, 15.793459), vec3(3.0, 10.454473, 15.793459), vec3(5.325968, 12.05921, 15.793459), vec3(12.598328, 12.960824, 15.793459), vec3(19.401665, 11.24637, 15.793459), vec3(26.664326, 6.6855497, 15.793459)};
    roadCheckpointLeftTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};
    
    roadCheckpointRightTrigger.vertices={vec3(29.0, 8.512752, 16.20654), vec3(2.0, 1.7087021, 16.20654), vec3(2.0, 1.7087021, 15.793459), vec3(29.0, 8.512752, 15.793458), vec3(26.674032, 12.00657, 16.206537), vec3(19.401672, 12.908184, 16.206537), vec3(12.598335, 11.19373, 16.206537), vec3(29.0, 10.401833, 16.20654), vec3(5.3356743, 6.6329103, 16.20654), vec3(2.0, 2.657261, 16.20654), vec3(2.0, 2.657261, 15.793459), vec3(5.3356743, 6.6329103, 15.793458), vec3(12.598335, 11.19373, 15.793458), vec3(19.401672, 12.908184, 15.793458), vec3(26.674032, 12.00657, 15.793458), vec3(29.0, 10.401833, 15.793458)};
    roadCheckpointRightTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {7,4,6}, {6,8,9}, {6,9,1}, {7,6,1}, {0,7,1}, {2,1,9}, {9,10,2}, {10,11,12}, {12,13,14}, {14,15,3}, {12,14,3}, {10,12,3}, {2,10,3}, {0,3,15}, {15,7,0}, {6,5,13}, {13,12,6}, {8,6,12}, {12,11,8}, {14,13,5}, {5,4,14}, {15,14,4}, {4,7,15}, {9,8,11}, {11,10,9}};

    //StadiumRoadMainCheckpoint, StadiumGrassCheckpoint, StadiumRoadMainCheckpointUp, StadiumRoadMainCheckpointDown, StadiumRoadMainCheckpointLeft, StadiumRoadMainCheckpointRight, StadiumCheckpointRingV, StadiumCheckpointRingHRoad, StadiumPlatformCheckpoint, StadiumPlatformCheckpointUp, StadiumPlatformCheckpointDown, StadiumPlatformCheckpointLeft, StadiumPlatformCheckpointRight, StadiumRoadDirtHighCheckpoint, StadiumRoadDirtCheckpoint, StadiumRoadMainFinishLine

    blocksTriggers["StadiumRoadMainCheckpoint"]=@roadCheckpointTrigger;
    blocksTriggers["StadiumGrassCheckpoint"]=@grassCheckpointTrigger;
    blocksTriggers["StadiumRoadMainCheckpointUp"]=@roadCheckpointUpTrigger;
    blocksTriggers["StadiumRoadMainCheckpointDown"]=@roadCheckpointDownTrigger;
    blocksTriggers["StadiumRoadMainCheckpointLeft"]=@roadCheckpointLeftTrigger;
    blocksTriggers["StadiumRoadMainCheckpointRight"]=@roadCheckpointRightTrigger;
    blocksTriggers["StadiumCheckpointRingV"]=@ringVCheckpointTrigger;
    blocksTriggers["StadiumCheckpointRingHRoad"]=@ringHCheckpointTrigger;
    blocksTriggers["StadiumPlatformCheckpoint"]=@platformCheckpointTrigger;
    blocksTriggers["StadiumPlatformCheckpointUp"]=@platformCheckpointUpTrigger;
    blocksTriggers["StadiumPlatformCheckpointDown"]=@platformCheckpointDownTrigger;
    blocksTriggers["StadiumPlatformCheckpointLeft"]=@platformCheckpointLeftTrigger;
    blocksTriggers["StadiumPlatformCheckpointRight"]=@platformCheckpointRightTrigger;
    blocksTriggers["StadiumRoadDirtHighCheckpoint"]=@roadDirtHighCheckpointTrigger;
    blocksTriggers["StadiumRoadDirtCheckpoint"]=@roadDirtCheckpointTrigger;
    blocksTriggers["StadiumRoadMainFinishLine"]=@finishTrigger;


    we.Add(Ellipsoid(vec3(0.863012, 0.3525, 1.782089),vec3(0.182, 0.364, 0.364))); //Front left wheel
    we.Add(Ellipsoid(vec3(-0.863012, 0.3525, 1.782089),vec3(0.182, 0.364, 0.364))); //Front right wheel
    we.Add(Ellipsoid(vec3(0.885002, 0.352504, -1.205502),vec3(0.182, 0.364, 0.364))); //Back left wheel
    we.Add(Ellipsoid(vec3(-0.885002, 0.352504, -1.205502),vec3(0.182, 0.364, 0.364))); //Back right wheel

    RegisterBruteforceEvaluation("distancetofintrigger", "Skycrafter's targets", OnEvaluate, RenderEvalSettings);
    RegisterVariable("skycrafter_bf_eval_timeframe", true);
    RegisterVariable("skycrafter_bf_eval_timemin", 0.0);
    RegisterVariable("skycrafter_bf_eval_timemax", 0.0);
    RegisterVariable("skycrafter_bf_mode", "Finish Distance");
    current=GetVariableString("skycrafter_bf_mode");
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Skycrafter's Bruteforce Targets";
    info.Author = "Skycrafter";
    info.Version = "v0.3.0";
    info.Description = "Allows bruteforcing different custom targets.";
    return info;
}


void findFBVertices(){ //Find finish block vertices
    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
    array<GameBlock@> blocks=array<GameBlock@>();
    array<TM::GameCtnBlock@> blocks2 = challenge.Blocks;
    for(uint i = 0; i < blocks2.Length; i++){
        if(blocks2[i].WayPointType!=TM::WayPointType::None){
            blocks.Add(blocks2[i]);
        }
    }
    finishBlocks.Clear();
    checkpointBlocks.Clear();
    for(uint i = 0; i < blocks.Length; i++){
        GameBlock block = blocks[i];
        if(block.WayPointType==1){
            block.trigger = finishTrigger;
            array<vec3>@ vertices = block.trigger.vertices;
            array<vec3>@ finishTriggerVertices=finishTrigger.vertices;
            vertices.Clear();
            vec3 location = vec3(block.Coord.x*32,block.Coord.y*8,block.Coord.z*32);
            for(uint j = 0; j < finishTriggerVertices.Length; j++){
                vec3 v = finishTriggerVertices[j]-vec3(16,4,16);
                vec3 newv;
                if(block.Dir == 0){
                    newv = vec3(v.x+location.x,v.y+location.y,v.z+location.z);
                }else if(block.Dir == 1){
                    newv = vec3(-v.z+location.x,v.y+location.y,v.x+location.z);
                }else if(block.Dir == 2){
                    newv = vec3(-v.x+location.x,v.y+location.y,-v.z+location.z);
                }else{
                    newv = vec3(v.z+location.x,v.y+location.y,-v.x+location.z);
                }
                vertices.Add(newv+vec3(16,4,16));
            }
            finishBlocks.Add(block);
        }else if(block.WayPointType==2){
            BlockTrigger@ correctTrigger=cast<BlockTrigger@>(blocksTriggers[block.Name]);
            block.trigger = correctTrigger;
            array<vec3>@ vertices = block.trigger.vertices;
            array<vec3>@ cpTriggerVertices=correctTrigger.vertices;
            vertices.Clear();
            vec3 location = vec3(block.Coord.x*32,block.Coord.y*8,block.Coord.z*32);
            for(uint j = 0; j < cpTriggerVertices.Length; j++){
                vec3 v = cpTriggerVertices[j]-vec3(16,4,16);
                vec3 newv;
                if(block.Dir == 0){
                    newv = vec3(v.x+location.x,v.y+location.y,v.z+location.z);
                }else if(block.Dir == 1){
                    newv = vec3(-v.z+location.x,v.y+location.y,v.x+location.z);
                }else if(block.Dir == 2){
                    newv = vec3(-v.x+location.x,v.y+location.y,-v.z+location.z);
                }else{
                    newv = vec3(v.z+location.x,v.y+location.y,-v.x+location.z);
                }
                vertices.Add(newv+vec3(16,4,16));
            }
            checkpointBlocks.Add(block);
        }
    }
    return;
}

float calculateCenterToCenterDistanceToAnyFinish(){
    SimulationManager@ simManager = GetSimulationManager();
    float calculated_distance = 1e9;
    const vec3 carLocation = simManager.Dyna.CurrentState.Location.Position;
    vec3 relativeCenter;
    const vec3 offset=vec3(16,4,16);
    for(uint i = 0; i < finishBlocks.Length; i++){
        GameBlock@ block = finishBlocks[i];
        if(block.Dir == 0){
            relativeCenter=vec3(0,0.5,-4)+offset;
        }else if(block.Dir == 1){
            relativeCenter=vec3(4,0.5,0)+offset;
        }else if(block.Dir == 2){
            relativeCenter=vec3(0,0.5,4)+offset;
        }else{
            relativeCenter=vec3(-4,0.5,0)+offset;
        }
        vec3 centerLocation = vec3(block.Coord.x*32,block.Coord.y*8,block.Coord.z*32)+relativeCenter;
        float dist = Math::Distance(carLocation,centerLocation);
        if(dist<calculated_distance){
            calculated_distance = dist;
        }
    }
    return calculated_distance;
}

float calculateShortestDistanceToAnyFinish(){
    SimulationManager@ simManager = GetSimulationManager();
    float calculated_distance = 1e9;
    const GmIso4@ carLocation = simManager.Dyna.CurrentState.Location;
    GmIso4 ellipsoidLocation;

    for (uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++) {
        GetCarEllipsoidLocationByIndex(simManager, carLocation, ellipsoidId, ellipsoidLocation);
        Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),we[ellipsoidId].size);

        for(uint i = 0; i < finishBlocks.Length;i++){
            
            Polyhedron polyhedron = Polyhedron(finishBlocks[i].trigger.vertices,finishBlocks[i].trigger.faceIndices);
            float dist = findDist(ellipsoid,polyhedron);
            if(dist<calculated_distance){
                calculated_distance = dist;
            }
        }
    }
    return calculated_distance;
}

class Polyhedron{
    array<vec3> vertices;
    array<array<int>> faces;
    Polyhedron(array<vec3> vertices, array<array<int>> faces){
        this.vertices = vertices;
        this.faces=faces;
    }
    Polyhedron(){
        this.vertices = array<vec3>();
    }
    void mult(vec3 v){
        for(uint i = 0; i < vertices.Length; i++){
            vertices[i] = vec3(vertices[i][0]*v[0],vertices[i][1]*v[1],vertices[i][2]*v[2]);
        }
    }

    void divide(vec3 v){
        for(uint i = 0; i < vertices.Length; i++){
            vertices[i] = vec3(vertices[i][0]/v[0],vertices[i][1]/v[1],vertices[i][2]/v[2]);
        }
    }
}


class Ellipsoid{
    vec3 center;
    vec3 size;
    Ellipsoid(vec3 center,vec3 size){
        this.center = center;
        this.size = size;
    }
    Ellipsoid(){
        this.center = vec3(0,0,0);
        this.size = vec3(0,0,0);
    }
    void mult(vec3 v){
        center = vec3(center[0]*v[0],center[1]*v[1],center[2]*v[2]);
        size = vec3(size[0]*v[0],size[1]*v[1],size[2]*v[2]);
    }
    void divide(vec3 v){
        center = vec3(center[0]/v[0],center[1]/v[1],center[2]/v[2]);
        size = vec3(size[0]/v[0],size[1]/v[1],size[2]/v[2]);
    }
}

class Sphere{
    vec3 center;
    float radius;
    Sphere(vec3 center,float radius){
        this.center = center;
        this.radius = radius;
    }
    Sphere(){
        this.center = vec3(0,0,0);
        this.radius = 0;
    }
    void mult(vec3 v){
        center = vec3(center[0]*v[0],center[1]*v[1],center[2]*v[2]);
        radius = radius*v[0];
    }
    void divide(vec3 v){
        center = vec3(center[0]/v[0],center[1]/v[1],center[2]/v[2]);
        radius = radius/v[0];
    }
}

float pointToSegmentDistance(vec3 p, vec3 a, vec3 b, vec3&out projection) {
    vec3 ab = b - a;
    vec3 ap = p - a;
    float t = Math::Dot(ap, ab) / Math::Dot(ab, ab);
    t = Math::Clamp(t, 0.0f, 1.0f);
    projection = a + ab*t;
    return Math::Distance(p,projection);
}

vec3 projectPointOnPlane(vec3 point, vec3 planeNormal, vec3 planePoint) {
    float distance = Math::Dot(point - planePoint, planeNormal);
    return point - planeNormal*distance;
}

bool isPointInsideFace(vec3 point, array<vec3>@ faceVertices, vec3 planeNormal) {
    for (uint i = 0; i < faceVertices.Length; ++i) {
        vec3 edge = faceVertices[(i + 1) % faceVertices.Length] - faceVertices[i];
        vec3 edgeNormal = cross(edge, planeNormal);
        if (Math::Dot(point - faceVertices[i], edgeNormal) > 0) {
            return false;
        }
    }
    return true;
}


float findDist(Ellipsoid ellipsoid, Polyhedron polyhedron) {
    // Simplify the problem by turning the ellipsoid into a sphere
    vec3 coeff = ellipsoid.size;
    ellipsoid.divide(coeff);
    Sphere sphere = Sphere(ellipsoid.center, 1);
    polyhedron.divide(coeff);

    // Find the closest point on the polyhedron to the sphere
    vec3 closestPolyPoint = vec3(0, 0, 0);
    float minDistance = 1e9;

    for (uint i = 0; i < polyhedron.faces.Length; ++i) {
        array<int>@ faceIndices = polyhedron.faces[i];
        array<vec3> faceVertices;
        for (uint j = 0; j < faceIndices.Length; ++j) {
            faceVertices.Add(polyhedron.vertices[faceIndices[j]]);
        }

        vec3 planeNormal = normalize(cross(faceVertices[1] - faceVertices[0], faceVertices[2] - faceVertices[0]));
        vec3 projectedPoint = projectPointOnPlane(sphere.center, planeNormal, faceVertices[0]);

        // Check if the projected point is inside the face
        if (isPointInsideFace(projectedPoint, faceVertices, planeNormal)) {
            float distance = Math::Distance(projectedPoint, sphere.center);
            if (distance < minDistance) {
                minDistance = distance;
                closestPolyPoint = projectedPoint;
            }
        } else {
            // Check the closest point on the edges of the face
            for (uint j = 0; j < faceVertices.Length; ++j) {
                vec3 a = faceVertices[j];
                vec3 b = faceVertices[(j + 1) % faceVertices.Length];
                float distance = pointToSegmentDistance(sphere.center, a, b, projectedPoint);
                if (distance < minDistance) {
                    minDistance = distance;
                    closestPolyPoint = projectedPoint;
                }
            }
        }
    }

    //Find the point closest on the sphere's surface
    vec3 vect = closestPolyPoint-sphere.center;
    vec3 closestCirclePoint = sphere.center + normalize(vect);

    vec3 realClosestCirclePoint = closestCirclePoint*coeff;
    vec3 realClosestPolyPoint = closestPolyPoint*coeff;
    float realDistance = Math::Distance(realClosestPolyPoint,realClosestCirclePoint);
    return realDistance;
}
vec3 normalize(vec3 v) {
    float magnitude = v.Length();
    if (magnitude != 0) {
        return vec3(v.x / magnitude, v.y / magnitude, v.z / magnitude);
    }
    return v;
}

vec3 cross(vec3 a,vec3 b){
    return vec3(a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]);
}

vec3 neg(vec3 v){
    return v-v-v;
}

void OnSimulationBegin(SimulationManager@ simManager){
    findFBVertices();
    bestDist = -1;
    bestDistTime = -1;
    bestExageratedDist = -1;
    checkpointCount = GetSimulationManager().PlayerInfo.CheckpointStates.Length-1;
    targetCpCount = 0;
    startTime = Time::get_Now();
}

void GetCarEllipsoidLocationByIndex(SimulationManager@ simManager, const GmIso4&in carLocation, uint index, GmIso4&out location) {
    switch(index) {
        case 0:
        {
            location.m_Position = simManager.Wheels.FrontLeft.SurfaceHandler.Location.Position;
            location.Mult(carLocation);
            break;
        }
        case 1:
        {
            location.m_Position = simManager.Wheels.FrontRight.SurfaceHandler.Location.Position;
            location.Mult(carLocation);
            break;
        }
        case 2:
        {
            location.m_Position = simManager.Wheels.BackLeft.SurfaceHandler.Location.Position;
            location.Mult(carLocation);
            break;
        }
        case 3:
        {
            location.m_Position = simManager.Wheels.BackRight.SurfaceHandler.Location.Position;
            location.Mult(carLocation);
            break;
        }
        case 4:
        {
            // bodysurf1
            GmVec3 translationFromCar(0.0f, 0.471253f, 0.219106f);
            // in the data this pitch was negative, somehow i had to make it positive to get the correct result
            float pitch = 3.4160502f;
            // Math::ToRad(3.4160502f); -> 0.0596213234033 (pitch)
            location.m_Rotation.RotateX(0.0596213234033f);
            location.Mult(carLocation);
            translationFromCar.Mult(carLocation.m_Rotation);
            location.m_Position += translationFromCar;
            break;
        }
        case 5:
        {
            // bodysurf2
            GmVec3 translationFromCar(0.0f, 0.448782f, -0.20792f);
            // in the data this pitch was negative, somehow i had to make it positive to get the correct result
            // float pitch = 2.6202483f -> 0.0457319600547 (pitch)
            location.m_Rotation.RotateX(0.0457319600547f);
            location.Mult(carLocation);
            translationFromCar.Mult(carLocation.m_Rotation);
            location.m_Position += translationFromCar;
            break;
        }
        case 6:
        {
            // bodysurf3
            GmVec3 translationFromCar(0.0f, 0.652812f, -0.89763f);
            // in the data this pitch was negative, somehow i had to make it positive to get the correct result
            // float pitch = 2.6874702f;
            // Math::ToRad(2.6874702f); -> 0.0469052035391 (pitch)
            location.m_Rotation.RotateX(0.0469052035391f);
            location.Mult(carLocation);
            translationFromCar.Mult(carLocation.m_Rotation);
            location.m_Position += translationFromCar;
            break;
        }
        case 7:
        {
            // bodysurf4
            GmVec3 translationFromCar(-0.015532f, 0.363252f, 1.75357f);
            // float pitch = 0.0f;
            // float yaw = 90.0f;
            //float roll = -180.0f;
            // for some reason, the data said pitch 0 but i ended up having to use 90, and roll doesnt really seem to matter? this needs to be looked into
            // Math::ToRad(90.0f); -> 1.5708 (pitch, despite above / data saying 0.0)
            location.m_Rotation.RotateX(1.5708f);
            // Math::ToRad(90.0); -> 1.5708 (yaw)
            location.m_Rotation.RotateY(1.5708f);
            // not used?
            //location.m_Rotation.RotateZ(Math::ToRad(roll));
            location.Mult(carLocation);
            translationFromCar.Mult(carLocation.m_Rotation);
            location.m_Position += translationFromCar;
            break;
        }
    }
}

class GmVec3 {
    float x;
    float y;
    float z;
    
    GmVec3() {}
    GmVec3(float num) {
        this.x = num;
        this.y = num;
        this.z = num;
    }
    GmVec3(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    GmVec3(const GmVec3&in other) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }
    GmVec3(const vec3&in other) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }

    void Mult(const GmMat3&in other) {
        float _x = x * other.x.x + y * other.x.y + z * other.x.z;
        float _y = x * other.y.x + y * other.y.y + z * other.y.z;
        z = x * other.z.x + y * other.z.y + z * other.z.z;
        x = _x;
        y = _y;
    }

    void Mult(const GmIso4&in other) {
        float _x = x * other.m_Rotation.x.x + y * other.m_Rotation.x.y + z * other.m_Rotation.x.z + other.m_Position.x;
        float _y = x * other.m_Rotation.y.x + y * other.m_Rotation.y.y + z * other.m_Rotation.y.z + other.m_Position.y;
        z = x * other.m_Rotation.z.x + y * other.m_Rotation.z.y + z * other.m_Rotation.z.z + other.m_Position.z;
        x = _x;
        y = _y;
    }

    void MultTranspose(const GmMat3&in other) {
        float _x = x * other.x.x + y * other.y.x + z * other.z.x;
        float _y = x * other.x.y + y * other.y.y + z * other.z.y;
        z = x * other.x.z + y * other.y.z + z * other.z.z;
        x = _x;
        y = _y;
    }


    GmVec3 opAdd(const GmVec3&in other) {
        GmVec3 result;
        result.x = x + other.x;
        result.y = y + other.y;
        result.z = z + other.z;
        return result;
    }

    GmVec3 opSub(const GmVec3&in other) {
        GmVec3 result;
        result.x = x - other.x;
        result.y = y - other.y;
        result.z = z - other.z;
        return result;
    }

    GmVec3 opMul(const float&in other) {
        GmVec3 result;
        result.x = x * other;
        result.y = y * other;
        result.z = z * other;
        return result;
    }

    void opAddAssign(const GmVec3&in other) {
        x += other.x;
        y += other.y;
        z += other.z;
    }

    void opSubAssign(const GmVec3&in other) {
        x -= other.x;
        y -= other.y;
        z -= other.z;
    }

    void opMulAssign(const GmVec3&in other) {
        x *= other.x;
        y *= other.y;
        z *= other.z;
    }

    void opDivAssign(const GmVec3&in other) {
        x /= other.x;
        y /= other.y;
        z /= other.z;
    }
}

class GmMat3 {
    GmVec3 x(1.0f, 0.0f, 0.0f);
    GmVec3 y(0.0f, 1.0f, 0.0f);
    GmVec3 z(0.0f, 0.0f, 1.0f);

    GmMat3() {}
    GmMat3(const GmMat3&in other) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }
    GmMat3(const GmVec3&in x, const GmVec3&in y, const GmVec3&in z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    GmMat3(const mat3&in other) {
        this.x = GmVec3(other.x);
        this.y = GmVec3(other.y);
        this.z = GmVec3(other.z);
    }

    void SetIdentity() {
        this.x.x = 1.0f;
        this.x.y = 0.0f;
        this.x.z = 0.0f;
        this.y.x = 0.0f;
        this.y.y = 1.0f;
        this.y.z = 0.0f;
        this.z.x = 0.0f;
        this.z.y = 0.0f;
        this.z.z = 1.0f;
    }

    void Mult(const GmMat3&in other) {
        float _xx = x.x * other.x.x + y.x * other.x.y + z.x * other.x.z;
        float _xy = x.y * other.x.x + y.y * other.x.y + z.y * other.x.z;
        float _xz = x.z * other.x.x + y.z * other.x.y + z.z * other.x.z;
        float _yx = x.x * other.y.x + y.x * other.y.y + z.x * other.y.z;
        float _yy = x.y * other.y.x + y.y * other.y.y + z.y * other.y.z;
        float _yz = x.z * other.y.x + y.z * other.y.y + z.z * other.y.z;
        z.x = x.x * other.z.x + y.x * other.z.y + z.x * other.z.z;
        z.y = x.y * other.z.x + y.y * other.z.y + z.y * other.z.z;
        z.z = x.z * other.z.x + y.z * other.z.y + z.z * other.z.z;
        x.x = _xx;
        x.y = _xy;
        x.z = _xz;
        y.x = _yx;
        y.y = _yy;
        y.z = _yz;
    }

    void MultTranspose(const GmMat3&in other) {
        float _xx = x.x * other.x.x + y.x * other.y.x + z.x * other.z.x;
        float _xy = x.y * other.x.x + y.y * other.y.x + z.y * other.z.x;
        float _xz = x.z * other.x.x + y.z * other.y.x + z.z * other.z.x;
        float _yx = x.x * other.x.y + y.x * other.y.y + z.x * other.z.y;
        float _yy = x.y * other.x.y + y.y * other.y.y + z.y * other.z.y;
        float _yz = x.z * other.x.y + y.z * other.y.y + z.z * other.z.y;
        z.x = x.x * other.x.z + y.x * other.y.z + z.x * other.z.z;
        z.y = x.y * other.x.z + y.y * other.y.z + z.y * other.z.z;
        z.z = x.z * other.x.z + y.z * other.y.z + z.z * other.z.z;
        x.x = _xx;
        x.y = _xy;
        x.z = _xz;
        y.x = _yx;
        y.y = _yy;
        y.z = _yz;
    }

    void RotateX(float rad) {
        float sin_pos = Math::Sin(rad);
        float sin_neg = -sin_pos;
        float cos_pos = Math::Cos(rad);

        GmVec3 y_temp(y);

        y.x = y.x * cos_pos + z.x * sin_neg;
        y.y = y.y * cos_pos + z.y * sin_neg;
        y.z = y.z * cos_pos + z.z * sin_neg;
        z.x = z.x * cos_pos + y_temp.x * sin_pos;
        z.y = z.y * cos_pos + y_temp.y * sin_pos;
        z.z = z.z * cos_pos + y_temp.z * sin_pos;
    }

    void RotateY(float rad) {
        float sin_pos = Math::Sin(rad);
        float sin_neg = -sin_pos;
        float cos_pos = Math::Cos(rad);

        GmVec3 x_temp(x);

        x.x = x.x * cos_pos + z.x * sin_pos;
        x.y = x.y * cos_pos + z.y * sin_pos;
        x.z = x.z * cos_pos + z.z * sin_pos;
        z.x = z.x * cos_pos + x_temp.x * sin_neg;
        z.y = z.y * cos_pos + x_temp.y * sin_neg;
        z.z = z.z * cos_pos + x_temp.z * sin_neg;
    }

    void RotateZ(float rad) {
        float sin_pos = Math::Sin(rad);
        float sin_neg = -sin_pos;
        float cos_pos = Math::Cos(rad);

        GmVec3 x_temp(x);

        x.x = x.x * cos_pos + y.x * sin_neg;
        x.y = x.y * cos_pos + y.y * sin_neg;
        x.z = x.z * cos_pos + y.z * sin_neg;
        y.x = y.x * cos_pos + x_temp.x * sin_pos;
        y.y = y.y * cos_pos + x_temp.y * sin_pos;
        y.z = y.z * cos_pos + x_temp.z * sin_pos;
    }
}

class GmIso4 {
    GmMat3 m_Rotation;
    GmVec3 m_Position;

    GmIso4() {}
    GmIso4(const GmIso4&in other) {
        this.m_Rotation = other.m_Rotation;
        this.m_Position = other.m_Position;
    }
    GmIso4(const GmMat3&in rotation, const GmVec3&in position) {
        this.m_Rotation = rotation;
        this.m_Position = position;
    }
    GmIso4(const iso4&in other) {
        this.m_Rotation = GmMat3(other.Rotation);
        this.m_Position = GmVec3(other.Position);
    }
    GmIso4(const mat3&in rotation, const vec3&in position) {
        this.m_Rotation = GmMat3(rotation);
        this.m_Position = GmVec3(position);
    }

    void Mult(const GmIso4&in other) {
        m_Rotation.Mult(other.m_Rotation);
        m_Position.Mult(other);
    }
}

enum EGmSurfType {
    GmSurfType_Sphere,
    GmSurfType_Ellipsoid,
    GmSurfType_Plane,
    GmSurfType_QuadHeight,
    GmSurfType_TriangleHeight,
    GmSurfType_Polygon,
    GmSurfType_Box,
    GmSurfType_Mesh,
    GmSurfType_Cylinder,
    GmSurfType_Count
};

class GmSurf {
    TM::PlugSurfaceMaterialId m_MaterialId;
    EGmSurfType m_GmSurfType;
}

class STriangle {
    STriangle() {
        m_VertexIndices.Resize(3);
    }
    GmVec3 m_Normal;
    float m_Distance;
    array<uint> m_VertexIndices;
    TM::PlugSurfaceMaterialId m_MaterialId;
}

class GameBlock {
    string Name;
    TM::WayPointType WayPointType;
    nat3 Coord;
    TM::CardinalDir Dir;
    BlockTrigger trigger;

    GameBlock(){
        this.Name = "";
        this.WayPointType = TM::WayPointType::None;
        this.Coord = nat3();
        this.Dir = TM::CardinalDir::North;
    }

    GameBlock(string Name, TM::WayPointType WayPointType, const nat3 Coord, TM::CardinalDir Dir) {
        this.Name = Name;
        this.WayPointType = WayPointType;
        this.Coord = Coord;
        this.Dir = Dir;
    }
    GameBlock(TM::GameCtnBlock@&in block) {
        this.Name = block.Name;
        this.WayPointType = block.WayPointType;
        this.Coord = block.Coord;
        this.Dir = block.Dir;
    }
}

class BlockTrigger {
    array<vec3> vertices;
    array<array<int>> faceIndices;
    BlockTrigger() {
        vertices = array<vec3>();
        faceIndices = array<array<int>>();
    }
    BlockTrigger(array<vec3> vertices, array<array<int>> faceIndices) {
        this.vertices = vertices;
        this.faceIndices = faceIndices;
    }
    Polyhedron toPoly() {
        return Polyhedron(vertices, faceIndices);
    }
    void addV(vec3 v) {
        vertices.Add(v);
    }
    void addF(array<int> f) {
        faceIndices.Add(f);
    }
}