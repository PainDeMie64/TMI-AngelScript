// Documentation available at https://donadigo.com/tminterface/plugins/api
// Huge thanks to bigbang1112 for providing a lot of the missing triggers I needed

array<BruteforceEval@> bruteforceEvals = array<BruteforceEval@>();

interface BruteforceEval{
    string get_Name();
    string get_Prefix();
    string toLocalVarName(string var);
    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info);
    void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target);
    void OnSimulationBegin(SimulationManager@ simManager);
    void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result);
    void RenderAdditionalSettings();
}

const string PLUGIN_PREFIX="skycrafter_bf_";



class HitboxDistanceBF : BruteforceEval{
    string Name="Hitbox Based Distance";
    string prefix="hitboxdistancebf";
    string target="Finish Distance";
    
    array<GameBlock@> finishBlocks = array<GameBlock@>();
    array<GameBlock@> checkpointBlocks = array<GameBlock@>();
    array<GameBlock@> checkpointNotTakenBlocks = array<GameBlock@>();
    array<array<int>> triggerFaceIndices = array<array<int>>();
    array<vec3> triggerVertices = array<vec3>();
    float triggerHalfDiagonal = 0;
    vec3 triggerCenter = vec3(0,0,0);

    uint checkpointCount = 0;
    uint targetCpCount = 0;

    string info ="";
    float bestDist = -1;
    int bestDistTime = -1;
    BFPhase phase = BFPhase::Initial;
    bool bruting = false;
    int raceTime = 0;

    float bestExageratedDist = -1;
    float exageration = 2.5+15; //Car half diagonal + trigger half diagonal

    
    bool eval_timeframe = true;
    float eval_timemin = 0.0;
    float eval_timemax = 0.0;
    float threshold=0.01;

    array<GmIso4> initialData = array<GmIso4>();
    array<int> initialDataTimes = array<int>();
    int lastCpTaken=0;

    HitboxDistanceBF(){
        RegisterVariable(toLocalVarName("eval_timeframe"), false);
        RegisterVariable(toLocalVarName("eval_timemin"), 0.0);
        RegisterVariable(toLocalVarName("eval_timemax"), 0.0);
        RegisterVariable(toLocalVarName("trigger_id"), 1);
        RegisterVariable(toLocalVarName("target"), target);
        RegisterVariable(toLocalVarName("threshold"), 0.01);
        target=GetVariableString(toLocalVarName("target"));
    }
    
    string get_Name(){
        return Name;
    }
    string get_Prefix(){
        return prefix;
    }

    string toLocalVarName(string var){
        return PLUGIN_PREFIX+prefix+"_"+var;
    }
    
    void OnSimulationBegin(SimulationManager@ simManager){
        if(target!="Trigger Distance") findFBVertices();
        bruting=false;
        bestDist = -1;
        bestDistTime = -1;
        bestExageratedDist = -1;
        checkpointCount = GetSimulationManager().PlayerInfo.CheckpointStates.Length-1;
        targetCpCount = 0;
        startTime = Time::get_Now();
        // Trigger3D trigger = GetTriggerByIndex(int(GetVariableDouble(toLocalVarName("trigger_id")))-1);
        // vec3 pos=trigger.Position;
        // print("Trigger position: "+pos.x+" "+pos.y+" "+pos.z);
        // vec3 size=trigger.Size;
        // triggerHalfDiagonal=Math::Sqrt(size.x*size.x+size.y*size.y+size.z*size.z)/2;
        // triggerCenter=vec3(pos.x+size.x/2,pos.y+size.y/2,pos.z+size.z/2);

        // triggerVertices.Clear();
        // triggerFaceIndices.Clear();
        // triggerVertices.Add(vec3(pos.x, pos.y, pos.z));                   // V1
        // triggerVertices.Add(vec3(pos.x + size.x, pos.y, pos.z));          // V2
        // triggerVertices.Add(vec3(pos.x + size.x, pos.y + size.y, pos.z)); // V3
        // triggerVertices.Add(vec3(pos.x, pos.y + size.y, pos.z));          // V4
        // triggerVertices.Add(vec3(pos.x, pos.y, pos.z + size.z));          // V5
        // triggerVertices.Add(vec3(pos.x + size.x, pos.y, pos.z + size.z)); // V6
        // triggerVertices.Add(vec3(pos.x + size.x, pos.y + size.y, pos.z + size.z)); // V7
        // triggerVertices.Add(vec3(pos.x, pos.y + size.y, pos.z + size.z)); // V8

        // // Front face (z = pos.z)
        // triggerFaceIndices.Add({0, 1, 2});
        // triggerFaceIndices.Add({0, 2, 3});

        // // Back face (z = pos.z + size.z)
        // triggerFaceIndices.Add({4, 5, 6});
        // triggerFaceIndices.Add({4, 6, 7});

        // // Left face (x = pos.x)
        // triggerFaceIndices.Add({0, 3, 7});
        // triggerFaceIndices.Add({0, 7, 4});

        // // Right face (x = pos.x + size.x)
        // triggerFaceIndices.Add({1, 5, 6});
        // triggerFaceIndices.Add({1, 6, 2});

        // // Top face (y = pos.y + size.y)
        // triggerFaceIndices.Add({3, 2, 6});
        // triggerFaceIndices.Add({3, 6, 7});

        // // Bottom face (y = pos.y)
        // triggerFaceIndices.Add({0, 1, 5});
        // triggerFaceIndices.Add({0, 5, 4});

    }
    void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result){
        phase=BFPhase::Search;
        bruting=false;
    }

    
    void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target){
        if(phase==BFPhase::Initial&&bruting){
            if(targetCpCount==0){
                lastCpTaken=simManager.RaceTime;
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
    }

    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info){
        raceTime = simManager.RaceTime;
        phase=info.Phase;
        auto resp = BFEvaluationResponse();

        if (info.Phase == BFPhase::Initial) {
            bruting = true;
            if(targetCpCount==0){
                if(raceTime==0){
                    checkpointNotTakenBlocks = checkpointBlocks;
                }
                GmIso4 state = simManager.Dyna.CurrentState.Location;
                initialData.Add(state);
                initialDataTimes.Add(raceTime);
            }
            if (targetCpCount!=0&&((simManager.PlayerInfo.CurCheckpointCount==targetCpCount))) {
                if(bestDist==-1){
                    print("Base run already reached target, cancelling bruteforce.",Severity::Error);
                }else{
                    print("Reached at " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s, congrats!",Severity::Info);
                    print("Reached at " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s, congrats!",Severity::Success);
                    print("Reached at " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s, congrats!",Severity::Info);
                }
                resp.Decision = BFEvaluationDecision::Stop;
                CommandList list;
                list.Content = simManager.InputEvents.ToCommandsText();
                string newfile = GetVariableString("bf_result_filename").Substr(0,GetVariableString("bf_result_filename").FindLast(".txt"))+"_alt.txt";
                print("In case something went wrong, inputs have been saved to " + newfile,Severity::Warning);
                list.Save(newfile);
                return resp;
            }
            if (GetVariableBool(toLocalVarName("eval_timeframe"))) {
                if (raceTime >= GetVariableDouble(toLocalVarName("eval_timemin")) && raceTime <= GetVariableDouble(toLocalVarName("eval_timemax"))&&simManager.PlayerInfo.CurCheckpointCount == targetCpCount-1) {
                    initial(simManager);
                }else if(raceTime > GetVariableDouble(toLocalVarName("eval_timemax"))){
                    if(targetCpCount==0){
                        bestDist=1e9;
                        if(target=="Finish Distance"){
                            targetCpCount = checkpointCount+1;
                            for(uint i = 0; i < initialData.Length; i++){
                                int time=initialDataTimes[i];
                                if(time<lastCpTaken||time>GetVariableDouble(toLocalVarName("eval_timemax"))||time<GetVariableDouble(toLocalVarName("eval_timemin"))) continue;
                                GmIso4 state=initialData[i];
                                for(uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++){
                                    vec3 size=we[ellipsoidId].size;
                                    GmIso4 ellipsoidLocation;
                                    GetCarEllipsoidLocationByIndex(simManager, state, ellipsoidId, ellipsoidLocation);
                                    Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),size);
                                    ellipsoid.rotation = state.m_Rotation;
                                    for(uint j = 0; j < finishBlocks.Length; j++){
                                        Polyhedron polyhedron = Polyhedron(finishBlocks[j].trigger.vertices,finishBlocks[j].trigger.faceIndices);
                                        float d = findDist(ellipsoid,polyhedron);
                                        if(d<bestDist){
                                            bestDist=d;
                                            bestDistTime=time;
                                            bestExageratedDist=calculateCenterToCenterDistanceToAnyFinish()+exageration;
                                        }
                                    }
                                }
                            }
                        }else if(target=="Checkpoint Distance"){
                            targetCpCount = simManager.PlayerInfo.CurCheckpointCount+1;
                            for(uint i = 0; i < initialData.Length; i++){
                                int time=initialDataTimes[i];
                                if(time<lastCpTaken||time>GetVariableDouble(toLocalVarName("eval_timemax"))||time<GetVariableDouble(toLocalVarName("eval_timemin"))) continue;
                                GmIso4 state=initialData[i];
                                for(uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++){
                                    vec3 size=we[ellipsoidId].size;
                                    GmIso4 ellipsoidLocation;
                                    GetCarEllipsoidLocationByIndex(simManager, state, ellipsoidId, ellipsoidLocation);
                                    Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),size);
                                    ellipsoid.rotation = state.m_Rotation;
                                    for(uint j = 0; j < checkpointNotTakenBlocks.Length; j++){
                                        Polyhedron polyhedron = Polyhedron(checkpointNotTakenBlocks[j].trigger.vertices,checkpointNotTakenBlocks[j].trigger.faceIndices);
                                        float d = findDist(ellipsoid,polyhedron);
                                        if(d<bestDist){
                                            bestDist=d;
                                            bestDistTime=time;
                                            bestExageratedDist=calculateCenterToCenterDistanceToAnyUnreachedCheckpoint()+exageration;
                                        }
                                    }
                                }
                            }
                        }
                        print("Base distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s",Severity::Success);
                        resp.Decision=BFEvaluationDecision::Accept;
                        initialData.Clear();
                        initialDataTimes.Clear();
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
                        bestDist=1e9;
                        if(target=="Finish Distance"){
                            targetCpCount = checkpointCount+1;
                            for(uint i = 0; i < initialData.Length; i++){
                                int time=initialDataTimes[i];
                                if(time<lastCpTaken||time>GetVariableDouble(toLocalVarName("eval_timemax"))) continue;
                                GmIso4 state=initialData[i];
                                for(uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++){
                                    vec3 size=we[ellipsoidId].size;
                                    GmIso4 ellipsoidLocation;
                                    GetCarEllipsoidLocationByIndex(simManager, state, ellipsoidId, ellipsoidLocation);
                                    Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),size);
                                    ellipsoid.rotation = state.m_Rotation;
                                    for(uint j = 0; j < finishBlocks.Length; j++){
                                        Polyhedron polyhedron = Polyhedron(finishBlocks[j].trigger.vertices,finishBlocks[j].trigger.faceIndices);
                                        float d = findDist(ellipsoid,polyhedron);
                                        if(d<bestDist){
                                            bestDist=d;
                                            bestDistTime=time;
                                            bestExageratedDist=calculateCenterToCenterDistanceToAnyFinish()+exageration;
                                        }
                                    }
                                }
                            }
                        }else if(target=="Checkpoint Distance"){
                            targetCpCount = simManager.PlayerInfo.CurCheckpointCount+1;
                            for(uint i = 0; i < initialData.Length; i++){
                                int time=initialDataTimes[i];
                                if(time<lastCpTaken||time>GetVariableDouble(toLocalVarName("eval_timemax"))) continue;
                                GmIso4 state=initialData[i];
                                for(uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++){
                                    vec3 size=we[ellipsoidId].size;
                                    GmIso4 ellipsoidLocation;
                                    GetCarEllipsoidLocationByIndex(simManager, state, ellipsoidId, ellipsoidLocation);
                                    Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),size);
                                    ellipsoid.rotation = state.m_Rotation;
                                    for(uint j = 0; j < checkpointNotTakenBlocks.Length; j++){
                                        Polyhedron polyhedron = Polyhedron(checkpointNotTakenBlocks[j].trigger.vertices,checkpointNotTakenBlocks[j].trigger.faceIndices);
                                        float d = findDist(ellipsoid,polyhedron);
                                        if(d<bestDist){
                                            bestDist=d;
                                            bestDistTime=time;
                                            bestExageratedDist=calculateCenterToCenterDistanceToAnyUnreachedCheckpoint()+exageration;
                                        }
                                    }
                                }
                            }
                        }
                        print("Base distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s",Severity::Success);
                        resp.Decision=BFEvaluationDecision::Accept;
                        initialData.Clear();
                        initialDataTimes.Clear();
                    }else{
                        print("Current best distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + Text::FormatFloat(bestDistTime/1000.0,"",0,2) + "s, iteration " + info.Iterations + " (Run time: " + (Time::get_Now()-startTime)/1000 + "s)",Severity::Success);
                        resp.Decision=BFEvaluationDecision::Accept;
                    }
                }
            }
                
        } else {
            if (GetVariableBool(toLocalVarName("eval_timeframe"))) {
                if (raceTime >= GetVariableDouble(toLocalVarName("eval_timemin")) && raceTime <= GetVariableDouble(toLocalVarName("eval_timemax")) && simManager.PlayerInfo.CurCheckpointCount >= targetCpCount-1) {
                    
                    eval(simManager, resp);
                    
                }else if(raceTime > GetVariableDouble(toLocalVarName("eval_timemax"))){
                    resp.Decision=BFEvaluationDecision::Reject;
                }
            }else {
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
        if(target=="Finish Distance"){
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
        }else if(target=="Checkpoint Distance"){
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
        if(target=="Finish Distance"){    
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
        }else if(target=="Checkpoint Distance"){
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
        for(uint i = 0; i < checkpointNotTakenBlocks.Length; i++){
            GameBlock@ block = checkpointNotTakenBlocks[i];
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
            vec3 size=we[ellipsoidId].size;
            GetCarEllipsoidLocationByIndex(simManager, carLocation, ellipsoidId, ellipsoidLocation);
            Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),size);
            ellipsoid.rotation = carLocation.m_Rotation;
            for(uint i = 0; i < checkpointNotTakenBlocks.Length;i++){
                Polyhedron polyhedron = Polyhedron(checkpointNotTakenBlocks[i].trigger.vertices,checkpointNotTakenBlocks[i].trigger.faceIndices);
                float dist = findDist(ellipsoid,polyhedron);
                if(dist<calculated_distance){
                    calculated_distance = dist;
                }
            }
        }
        return calculated_distance;
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
            vec3 size=we[ellipsoidId].size;
            GetCarEllipsoidLocationByIndex(simManager, carLocation, ellipsoidId, ellipsoidLocation);
            Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),size);
            ellipsoid.rotation = carLocation.m_Rotation;
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


    void RenderAdditionalSettings(){
        if(UI::BeginCombo("Target", target)){
            if(UI::Selectable("Finish Distance", false)){
                target="Finish Distance";
            }
            if(UI::Selectable("Checkpoint Distance", false)){
                target="Checkpoint Distance";
            }
            UI::BeginDisabled();
            if(UI::Selectable("Trigger Distance", false)){
                target="Trigger Distance";
            }
            UI::EndDisabled();
            
            SetVariable(toLocalVarName("target"), target);
            UI::EndCombo();
        }
        if(target=="Trigger Distance"){
            UI::InputIntVar("Trigger id: ", toLocalVarName("trigger_id"), 1);
            threshold=UI::InputFloatVar("Threshold: ", toLocalVarName("threshold"), 0.1);
        }
        UI::BeginDisabled();
        UI::Checkbox("Only wheels", true);
        UI::SameLine();
        UI::TextWrapped("(Unchangeable: Work In Progress)");
        UI::EndDisabled();
        eval_timeframe=UI::CheckboxVar("Custom Time frame", toLocalVarName("eval_timeframe"));
        UI::TextDimmed("If not ticked, the evaluation will start after picking up the last checkpoint.");
        if(eval_timeframe){
            eval_timemin=UI::InputTimeVar("Time min", toLocalVarName("eval_timemin"), 100, 0);
            if(GetVariableDouble(toLocalVarName("eval_timemax")) < GetVariableDouble(toLocalVarName("eval_timemin"))){
                SetVariable(toLocalVarName("eval_timemax"), GetVariableDouble(toLocalVarName("eval_timemin")));
            }
            eval_timemax=UI::InputTimeVar("Time max", toLocalVarName("eval_timemax"), 100, 0);
        }
    }

}

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


array<Ellipsoid> we = array<Ellipsoid>(); //Wheels ellipsoids


string current = "Hitbox Based Distance";
int currentId = 0;
int subcurrentId = 0;

int64 startTime = 0;

void OnSimulationBegin(SimulationManager@ simManager){
    bruteforceEvals[subcurrentId].OnSimulationBegin(simManager);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result){
    bruteforceEvals[subcurrentId].OnSimulationEnd(simManager,result);
}

void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target){
    bruteforceEvals[subcurrentId].OnCheckpointCountChanged(simManager,current,target);
}

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    return bruteforceEvals[subcurrentId].OnEvaluate(simManager,info);
}

void RenderEvalSettings()
{
    UI::TextWrapped("This plugin allows you to bruteforce different targets implemented by Skycrafter.");
    if(UI::BeginCombo("Mode", current)){
        for(uint i = 0; i<bruteforceEvals.Length; i++){
            if(UI::Selectable(bruteforceEvals[i].get_Name(), false)){
                current=bruteforceEvals[i].get_Name();
                currentId=i;
                subcurrentId=i;
            }
        }
        SetVariable("skycrafter_bf_mode", current);
        UI::EndCombo();
    }
    
    bruteforceEvals[currentId].RenderAdditionalSettings();

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

    platformCheckpointTrigger.vertices={vec3(30.179214, 7.9320526, 16.09842), vec3(28.640587, 9.741932, 16.09842), vec3(26.304703, 11.035336, 16.09842), vec3(22.725918, 12.514831, 16.09842), vec3(18.33589, 13.464806, 16.09842), vec3(13.664118, 13.464806, 16.09842), vec3(9.274088, 12.514832, 16.09842), vec3(5.695303, 11.035337, 16.09842), vec3(3.359416, 9.741935, 16.09842), vec3(1.8207855, 7.9320536, 16.09842), vec3(3.359416, 9.741935, 15.658419), vec3(1.8207855, 7.9320545, 15.658419), vec3(5.695303, 11.035337, 15.658419), vec3(9.274088, 12.514832, 15.658419), vec3(13.664118, 13.464806, 15.658419), vec3(18.33589, 13.464806, 15.658419), vec3(22.725918, 12.51483, 15.658419), vec3(26.304703, 11.035336, 15.658419), vec3(28.640587, 9.741932, 15.658419), vec3(30.179214, 7.9320536, 15.658419)};
    platformCheckpointTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}};

    platformCheckpointUpTrigger.vertices={vec3(30.179218, 15.981263, 16.09842), vec3(28.64059, 17.791142, 16.09842), vec3(26.304707, 19.084545, 16.09842), vec3(22.725922, 20.56404, 16.09842), vec3(18.33589, 21.514013, 16.098421), vec3(13.664118, 21.514013, 16.098421), vec3(9.274088, 20.564041, 16.098421), vec3(5.695304, 19.084547, 16.09842), vec3(3.359417, 17.791147, 16.09842), vec3(1.8207862, 15.981263, 16.09842), vec3(3.3594167, 17.571144, 15.658419), vec3(1.8207862, 15.761264, 15.658419), vec3(5.695303, 18.864546, 15.658415), vec3(9.274088, 20.34404, 15.658419), vec3(13.664118, 21.294012, 15.658419), vec3(18.33589, 21.294014, 15.658419), vec3(22.725918, 20.344038, 15.658417), vec3(26.304703, 18.864544, 15.658417), vec3(28.640587, 17.571142, 15.658417), vec3(30.179214, 15.761261, 15.658419)};
    platformCheckpointUpTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}};

    platformCheckpointDownTrigger.vertices={vec3(30.179218, 15.882843, 16.09842), vec3(28.64059, 17.692722, 16.09842), vec3(26.304707, 18.986124, 16.09842), vec3(22.725922, 20.465622, 16.09842), vec3(18.33589, 21.415592, 16.098421), vec3(13.664118, 21.415594, 16.098421), vec3(9.274087, 20.465622, 16.098421), vec3(5.6953034, 18.986126, 16.09842), vec3(3.3594165, 17.692722, 16.09842), vec3(1.8207858, 15.882844, 16.09842), vec3(3.3594162, 17.912724, 15.658421), vec3(1.8207858, 16.102846, 15.658419), vec3(5.695303, 19.206125, 15.658421), vec3(9.274087, 20.68562, 15.658421), vec3(13.664118, 21.635593, 15.658421), vec3(18.33589, 21.635593, 15.658421), vec3(22.725918, 20.68562, 15.658421), vec3(26.304703, 19.206125, 15.658421), vec3(28.640587, 17.912722, 15.658421), vec3(30.179214, 16.102844, 15.658422)};
    platformCheckpointDownTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}};

    platformCheckpointLeftTrigger.vertices={vec3(30.179218, 8.842444, 16.09842), vec3(28.64059, 11.421638, 16.09842), vec3(26.304707, 13.882984, 16.09842), vec3(22.725922, 17.15187, 16.09842), vec3(18.33589, 20.29686, 16.098423), vec3(13.664118, 22.632746, 16.098423), vec3(9.274087, 23.877789, 16.098421), vec3(5.6953034, 24.187687, 16.098421), vec3(3.3594165, 24.062225, 16.09842), vec3(1.8207858, 23.02166, 16.09842), vec3(3.3594162, 24.062225, 15.658421), vec3(1.8207858, 23.021664, 15.658422), vec3(5.695303, 24.187685, 15.658421), vec3(9.274087, 23.877785, 15.658422), vec3(13.664118, 22.632746, 15.658422), vec3(18.33589, 20.29686, 15.658422), vec3(22.725918, 17.151869, 15.658421), vec3(26.304703, 13.882983, 15.658421), vec3(28.640587, 11.421638, 15.658421), vec3(30.179214, 8.842445, 15.658422)};
    platformCheckpointLeftTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}};

    platformCheckpointRightTrigger.vertices={vec3(30.179218, 23.02166, 16.09842), vec3(28.64059, 24.062227, 16.09842), vec3(26.304707, 24.187685, 16.09842), vec3(22.725922, 23.877789, 16.09842), vec3(18.33589, 22.632751, 16.098421), vec3(13.664118, 20.296865, 16.098421), vec3(9.274087, 17.151875, 16.098421), vec3(5.6953034, 13.882988, 16.09842), vec3(3.3594165, 11.421643, 16.09842), vec3(1.8207858, 8.842446, 16.09842), vec3(3.3594162, 11.421643, 15.658421), vec3(1.8207858, 8.842446, 15.658419), vec3(5.695303, 13.882988, 15.658421), vec3(9.274087, 17.151875, 15.658421), vec3(13.664118, 20.296864, 15.658421), vec3(18.33589, 22.63275, 15.658421), vec3(22.725918, 23.877785, 15.658421), vec3(26.304703, 24.187685, 15.658421), vec3(28.640587, 24.062225, 15.658421), vec3(30.179214, 23.02166, 15.658422)};
    platformCheckpointRightTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}};

    roadDirtHighCheckpointTrigger.vertices={vec3(3.7928343, -0.09202623, 16.20654), vec3(3.7928343, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 16.20654), vec3(28.268883, 1.1523709, 16.20654), vec3(25.85778, 3.959106, 16.20654), vec3(19.401665, 7.2270656, 16.20654), vec3(12.598328, 7.2270656, 16.20654), vec3(6.1362143, 3.8242507, 16.20654), vec3(3.7928343, 1.1458168, 16.20654), vec3(28.268883, 1.1523709, 15.793459), vec3(3.7928343, 1.1458168, 15.793459), vec3(6.1362143, 3.8242507, 15.793459), vec3(12.598328, 7.2270656, 15.793459), vec3(19.401665, 7.2270656, 15.793459), vec3(25.85778, 3.959106, 15.793459)};
    roadDirtHighCheckpointTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};

    roadDirtCheckpointTrigger.vertices={vec3(2.063568, -1.1490858, 16.20654), vec3(2.063568, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 16.20654), vec3(30.0, 3.4846723, 16.20654), vec3(26.664326, 6.291407, 16.20654), vec3(19.401665, 8.890814, 16.20654), vec3(12.598328, 8.890814, 16.20654), vec3(5.325968, 6.156552, 16.20654), vec3(2.063568, 3.478118, 16.20654), vec3(30.0, 3.4846723, 15.793459), vec3(2.063568, 3.478118, 15.793459), vec3(5.325968, 6.156552, 15.793459), vec3(12.598328, 8.890814, 15.793459), vec3(19.401665, 8.890814, 15.793459), vec3(26.664326, 6.291407, 15.793459)};
    roadDirtCheckpointTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};

    grassCheckpointTrigger.vertices={vec3(3.0, -0.32810664, 16.20654), vec3(3.0, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(2.2881927, 1.4034786, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(2.2881927, 1.4034786, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)};
    grassCheckpointTrigger.faceIndices={{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}};

    ringHCheckpointTrigger.vertices={vec3(26.156471, 3.7799995, 24.192066), vec3(22.629168, 3.7799993, 27.151827), vec3(18.302288, 3.779999, 28.726685), vec3(13.69772, 3.779999, 28.726685), vec3(9.370839, 3.7799993, 27.15183), vec3(5.843534, 3.7799995, 24.192072), vec3(3.541249, 3.7799997, 20.2044), vec3(2.7416735, 3.7800002, 15.669784), vec3(3.5412476, 3.7800007, 11.135169), vec3(5.843531, 3.780001, 7.147495), vec3(9.370835, 3.7800012, 4.187733), vec3(13.697715, 3.7800014, 2.6128778), vec3(18.302284, 3.7800014, 2.6128778), vec3(22.629164, 3.7800012, 4.187733), vec3(26.156467, 3.780001, 7.147493), vec3(28.458754, 3.7800007, 11.135166), vec3(29.258327, 3.7800002, 15.669782), vec3(28.458754, 3.7799997, 20.204391), vec3(28.458754, 4.2200007, 11.135166), vec3(29.258327, 4.2200003, 15.669782), vec3(26.156467, 4.2200007, 7.147493), vec3(22.629164, 4.220001, 4.187733), vec3(18.302284, 4.220001, 2.612878), vec3(13.697715, 4.220001, 2.6128778), vec3(9.370835, 4.220001, 4.187733), vec3(5.843531, 4.2200007, 7.147495), vec3(3.5412476, 4.2200007, 11.135169), vec3(2.7416735, 4.2200003, 15.669784), vec3(3.541249, 4.22, 20.2044), vec3(5.843534, 4.2199993, 24.192074), vec3(9.370839, 4.2199993, 27.151833), vec3(13.69772, 4.219999, 28.726686), vec3(18.302288, 4.219999, 28.726685), vec3(22.629168, 4.2199993, 27.151829), vec3(26.156471, 4.2199993, 24.192068), vec3(28.458754, 4.22, 20.204393)};
    ringHCheckpointTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {2,4,6}, {6,7,8}, {8,9,10}, {6,8,10}, {10,11,12}, {12,13,14}, {10,12,14}, {6,10,14}, {2,6,14}, {14,15,16}, {2,14,16}, {0,2,16}, {17,0,16}, {16,15,18}, {18,19,16}, {15,14,20}, {20,18,15}, {14,13,21}, {21,20,14}, {13,12,22}, {22,21,13}, {12,11,23}, {23,22,12}, {11,10,24}, {24,23,11}, {10,9,25}, {25,24,10}, {9,8,26}, {26,25,9}, {8,7,27}, {27,26,8}, {7,6,28}, {28,27,7}, {6,5,29}, {29,28,6}, {5,4,30}, {30,29,5}, {4,3,31}, {31,30,4}, {3,2,32}, {32,31,3}, {2,1,33}, {33,32,2}, {1,0,34}, {34,33,1}, {0,17,35}, {35,34,0}, {17,16,19}, {19,35,17}, {19,18,20}, {20,21,22}, {22,23,24}, {20,22,24}, {24,25,26}, {26,27,28}, {24,26,28}, {28,29,30}, {30,31,32}, {28,30,32}, {24,28,32}, {20,24,32}, {32,33,34}, {20,32,34}, {19,20,34}, {35,19,34}};

    ringVCheckpointTrigger.vertices={vec3(26.156471, 24.522285, 16.09842), vec3(22.629168, 27.482046, 16.09842), vec3(18.302288, 29.056904, 16.09842), vec3(13.697719, 29.056904, 16.09842), vec3(9.370839, 27.48205, 16.09842), vec3(5.8435335, 24.522291, 16.09842), vec3(3.5412483, 20.534618, 16.09842), vec3(2.7416725, 16.000002, 16.09842), vec3(3.5412464, 11.465387, 16.09842), vec3(5.8435307, 7.4777126, 16.09842), vec3(9.370834, 4.517952, 16.09842), vec3(13.697714, 2.9430962, 16.09842), vec3(18.302284, 2.9430962, 16.09842), vec3(22.629164, 4.517951, 16.09842), vec3(26.156467, 7.4777107, 16.09842), vec3(28.458752, 11.4653845, 16.09842), vec3(29.258327, 16.0, 16.09842), vec3(28.458754, 20.53461, 16.09842), vec3(28.458752, 11.4653845, 15.658419), vec3(29.258327, 16.0, 15.658419), vec3(26.156467, 7.4777107, 15.658419), vec3(22.629164, 4.517951, 15.658419), vec3(18.302284, 2.9430962, 15.658419), vec3(13.697714, 2.9430962, 15.658419), vec3(9.370834, 4.517952, 15.658419), vec3(5.8435307, 7.4777126, 15.658419), vec3(3.5412464, 11.465387, 15.658419), vec3(2.7416725, 16.000002, 15.658419), vec3(3.5412483, 20.534618, 15.65842), vec3(5.8435335, 24.522291, 15.65842), vec3(9.370839, 27.48205, 15.65842), vec3(13.697719, 29.056904, 15.65842), vec3(18.302288, 29.056904, 15.65842), vec3(22.629168, 27.482046, 15.65842), vec3(26.156471, 24.522285, 15.65842), vec3(28.458754, 20.53461, 15.65842)};
    ringVCheckpointTrigger.faceIndices={{0,1,2}, {2,3,4}, {4,5,6}, {2,4,6}, {6,7,8}, {8,9,10}, {6,8,10}, {10,11,12}, {12,13,14}, {10,12,14}, {6,10,14}, {2,6,14}, {14,15,16}, {2,14,16}, {0,2,16}, {17,0,16}, {16,15,18}, {18,19,16}, {15,14,20}, {20,18,15}, {14,13,21}, {21,20,14}, {13,12,22}, {22,21,13}, {12,11,23}, {23,22,12}, {11,10,24}, {24,23,11}, {10,9,25}, {25,24,10}, {9,8,26}, {26,25,9}, {8,7,27}, {27,26,8}, {7,6,28}, {28,27,7}, {6,5,29}, {29,28,6}, {5,4,30}, {30,29,5}, {4,3,31}, {31,30,4}, {3,2,32}, {32,31,3}, {2,1,33}, {33,32,2}, {1,0,34}, {34,33,1}, {0,17,35}, {35,34,0}, {17,16,19}, {19,35,17}, {19,18,20}, {20,21,22}, {22,23,24}, {20,22,24}, {24,25,26}, {26,27,28}, {24,26,28}, {28,29,30}, {30,31,32}, {28,30,32}, {24,28,32}, {20,24,32}, {32,33,34}, {20,32,34}, {19,20,34}, {35,19,34}};

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

    
    HitboxDistanceBF@ hitboxDistanceBF = HitboxDistanceBF();
    bruteforceEvals.Add(hitboxDistanceBF);
    

    RegisterBruteforceEvaluation("skycraftertargets", "Skycrafter's targets", OnEvaluate, RenderEvalSettings);
    RegisterVariable("skycrafter_bf_mode", bruteforceEvals[0].get_Name());
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
}


class Ellipsoid{
    vec3 center;
    vec3 size;
    GmMat3 rotation;
    Ellipsoid(vec3 center,vec3 size, GmMat3 rotation){
        this.center = center;
        this.size = size;
        this.rotation = rotation;
    }
    Ellipsoid(vec3 center,vec3 size){
        this.center = center;
        this.size = size;
        this.rotation = GmMat3();
        rotation.SetIdentity();
    }
    Ellipsoid(){
        this.center = vec3(0,0,0);
        this.size = vec3(0,0,0);
        this.rotation = GmMat3();
        rotation.SetIdentity();
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
    GmMat3 rotation = ellipsoid.rotation;
    GmMat3 invRotation = rotation.Inverse();

    Polyhedron transformedPolyhedron = polyhedron;

    // Transform the polyhedron vertices into the ellipsoid's coordinate frame
    for (uint i = 0; i < transformedPolyhedron.vertices.Length; ++i) {
        vec3 v = transformedPolyhedron.vertices[i];
        v = v - ellipsoid.center;    // Translate
        v = invRotation * v;         // Rotate
        v = v / coeff;               // Scale
        transformedPolyhedron.vertices[i] = v;
    }

    // In the transformed space, the ellipsoid becomes a unit sphere at the origin
    vec3 sphereCenter = vec3(0, 0, 0);
    float sphereRadius = 1;

    // Initialize variables to find the closest point
    vec3 closestPolyPoint = vec3(0, 0, 0);
    float minDistance = 1e9;

    // Iterate over each face of the transformed polyhedron
    for (uint i = 0; i < transformedPolyhedron.faces.Length; ++i) {
        array<int>@ faceIndices = transformedPolyhedron.faces[i];
        array<vec3> faceVertices;
        for (uint j = 0; j < faceIndices.Length; ++j) {
            faceVertices.Add(transformedPolyhedron.vertices[faceIndices[j]]);
        }

        // Compute the plane normal
        vec3 planeNormal = normalize(cross(faceVertices[1] - faceVertices[0], faceVertices[2] - faceVertices[0]));

        // Project the sphere center onto the plane of the face
        vec3 projectedPoint = projectPointOnPlane(sphereCenter, planeNormal, faceVertices[0]);

        // Check if the projected point is inside the face
        if (isPointInsideFace(projectedPoint, faceVertices, planeNormal)) {
            float distance = Math::Distance(projectedPoint, sphereCenter);
            if (distance < minDistance) {
                minDistance = distance;
                closestPolyPoint = projectedPoint;
            }
        } else {
            // Check the closest point on the edges of the face
            for (uint j = 0; j < faceVertices.Length; ++j) {
                vec3 a = faceVertices[j];
                vec3 b = faceVertices[(j + 1) % faceVertices.Length];
                float distance = pointToSegmentDistance(sphereCenter, a, b, projectedPoint);
                if (distance < minDistance) {
                    minDistance = distance;
                    closestPolyPoint = projectedPoint;
                }
            }
        }
    }

    //Find the point closest on the sphere's surface
    vec3 vect = closestPolyPoint-sphereCenter;
    vec3 closestSpherePoint = sphereCenter + normalize(vect) * sphereRadius;

    // Transform the closest points back to the original coordinate frame
    vec3 transformedClosestPolyPoint = closestPolyPoint * coeff; // Scale
    transformedClosestPolyPoint = rotation * transformedClosestPolyPoint; // Rotate
    transformedClosestPolyPoint += ellipsoid.center; // Translate

    vec3 transformedClosestSpherePoint = closestSpherePoint * coeff; // Scale
    transformedClosestSpherePoint = rotation * transformedClosestSpherePoint; // Rotate
    transformedClosestSpherePoint += ellipsoid.center; // Translate

    // Calculate the real distance between the closest points
    float realDistance = Math::Distance(transformedClosestPolyPoint, transformedClosestSpherePoint);

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

    vec3 Mult(vec3 v) {
        return vec3(x.x * v.x + y.x * v.y + z.x * v.z, x.y * v.x + y.y * v.y + z.y * v.z, x.z * v.x + y.z * v.y + z.z * v.z);
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

    float Determinant() {
        return x.x * (y.y * z.z - y.z * z.y) - y.x * (x.y * z.z - x.z * z.y) + z.x * (x.y * y.z - x.z * y.y);
    }

    GmMat3 Inverse(){
        GmMat3 inv;
        float det = Determinant();
        if (det == 0) {
            return inv; // Return identity matrix if singular
        }
        inv.x.x = (y.y * z.z - y.z * z.y) / det;
        inv.x.y = (x.z * z.y - x.y * z.z) / det;
        inv.x.z = (x.y * y.z - x.z * y.y) / det;
        inv.y.x = (y.z * z.x - y.x * z.z) / det;
        inv.y.y = (x.x * z.z - x.z * z.x) / det;
        inv.y.z = (x.z * y.x - x.x * y.z) / det;
        inv.z.x = (y.x * z.y - y.y * z.x) / det;
        inv.z.y = (x.y * z.x - x.x * z.y) / det;
        inv.z.z = (x.x * y.y - x.y * y.x) / det;
        return inv;
    }

    vec3 Transform(vec3 v) {
        return vec3(x.x * v.x + x.y * v.y + x.z * v.z, y.x * v.x + y.y * v.y + y.z * v.z, z.x * v.x + z.y * v.y + z.z * v.z);
    }

    vec3 opMul(const vec3&in v) {
        return Transform(v);
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