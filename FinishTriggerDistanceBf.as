// Documentation available at https://donadigo.com/tminterface/plugins/api

array<vec3> fbc = array<vec3>(); // Fbc = finish block vertices
array<int> fbi = array<int>(); // Fbc = finish block indices
array<Ellipsoid> we = array<Ellipsoid>(); // We = wheels ellipsoids
array<array<vec3>> nfbc=array<array<vec3>>();

string info ="";
array<Ellipsoid> nwe = array<Ellipsoid>();
float bestDist = -1;
int bestDistTime = -1;


float bestExageratedDist = -1;
uint iterations = 0;
string uid="";
const float exageration = 2.5+15;//Car half diagonal + finish block half diagonal

void OnRunStep(SimulationManager@ simManager)
{
    calculateCenterToCenterDistanceToAnyFinish();
}

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    int raceTime = simManager.RaceTime;

    auto resp = BFEvaluationResponse();
    if (info.Phase == BFPhase::Initial) {
        if (simManager.PlayerInfo.RaceFinished) {
            print("Base run already finished, cancelling bruteforce.",Severity::Error);
            resp.Decision = BFEvaluationDecision::Stop;
            return resp;
        }
        if(GetCurrentChallenge().get_Uid()!=uid||info.Iterations<iterations){
            nfbc = findFBVertices();
            uid = GetCurrentChallenge().get_Uid();
            bestDist = -1;
            bestDistTime = -1;
            bestExageratedDist = -1;
        }
        iterations=info.Iterations;
        if (GetVariableBool("skycrafter_finishdist_eval_timeframe")) {
            if (raceTime >= GetVariableDouble("skycrafter_finishdist_eval_timemin") && raceTime <= GetVariableDouble("skycrafter_finishdist_eval_timemax")) {
                float currentDistWithExageration = calculateCenterToCenterDistanceToAnyFinish()+exageration;
                if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
                    return resp;
                }
                float dist = calculateShortestDistanceToAnyFinish();
                if (dist < bestDist || bestDist == -1) {
                    bestDist = dist;
                    bestDistTime = raceTime;
                    bestExageratedDist = currentDistWithExageration;
                }
            }else if(raceTime > GetVariableDouble("skycrafter_finishdist_eval_timemax")){
                resp.Decision=BFEvaluationDecision::Accept;
                print("Current best distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + bestDistTime,Severity::Success);
            }
        }else {
            TM::PlayerInfo@ playerInfo = simManager.get_PlayerInfo();
            array<int> checkpointStates = playerInfo.get_CheckpointStates();
            uint cpcount = playerInfo.CurCheckpointCount;
            if(cpcount == checkpointStates.Length-1){
                float currentDistWithExageration = calculateCenterToCenterDistanceToAnyFinish()+exageration;
                if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
                    return resp;
                }
                float dist = calculateShortestDistanceToAnyFinish();
                if (dist < bestDist || bestDist == -1) {
                    bestDist = dist;
                    bestDistTime = raceTime;
                    bestExageratedDist = currentDistWithExageration;
                }
            }
            if(raceTime>simManager.get_EventsDuration()){
                print("Current best distance: " + Text::FormatFloat(bestDist,"",0,5) + "m at time " + bestDistTime,Severity::Success);
            }
        }
        
            
    } else {
        if (simManager.PlayerInfo.RaceFinished) {
            print("Found a finish at time " + raceTime + ", congrats!",Severity::Success);
            print("Found a finish at time " + raceTime + ", congrats!",Severity::Warning);
            print("Found a finish at time " + raceTime + ", congrats!",Severity::Error);
            print("Found a finish at time " + raceTime + ", congrats!",Severity::Warning);
            print("Found a finish at time " + raceTime + ", congrats!",Severity::Success);
            resp.Decision = BFEvaluationDecision::Accept;
            return resp;
        }
        if (GetVariableBool("skycrafter_finishdist_eval_timeframe")) {
            if (raceTime >= GetVariableDouble("skycrafter_finishdist_eval_timemin") && raceTime <= GetVariableDouble("skycrafter_finishdist_eval_timemax")) {
                float currentDistWithExageration = calculateCenterToCenterDistanceToAnyFinish()+exageration;
                if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
                    return resp;
                }
                float dist = calculateShortestDistanceToAnyFinish();
                if (dist < bestDist || bestDist == -1) {
                    resp.Decision=BFEvaluationDecision::Accept;
                }
            }else if(raceTime > GetVariableDouble("skycrafter_finishdist_eval_timemax")){
                resp.Decision=BFEvaluationDecision::Reject;
            }
        }else {
            TM::PlayerInfo@ playerInfo = simManager.get_PlayerInfo();
            array<int> checkpointStates = playerInfo.get_CheckpointStates();
            uint cpcount = playerInfo.CurCheckpointCount;
            if(cpcount == checkpointStates.Length-1){
                float currentDistWithExageration = calculateCenterToCenterDistanceToAnyFinish()+exageration;
                if(bestExageratedDist!=-1&&currentDistWithExageration>bestExageratedDist){
                    return resp;
                }
                float dist = calculateShortestDistanceToAnyFinish();
                if (dist < bestDist || bestDist == -1) {
                    bestDist = dist;
                    bestDistTime = raceTime;
                    resp.Decision=BFEvaluationDecision::Accept;
                }
            }
            if(raceTime>simManager.get_EventsDuration()){
                resp.Decision=BFEvaluationDecision::Reject;
            }
        }
    }

    return resp;
}

void RenderEvalSettings()
{
    UI::TextWrapped("This plugin allows you to bruteforce the distance between the car's hitbox and the finish trigger.");
    UI::BeginDisabled();
    UI::Checkbox("Only wheels", true);
    UI::SameLine();
    UI::TextWrapped("(Unchangeable: Work In Progress)");
    UI::EndDisabled();
    UI::CheckboxVar("Custom Time frame", "skycrafter_finishdist_eval_timeframe");
    UI::TextDimmed("If not ticked, the evaluation will start after picking up the last checkpoint.");
    if(GetVariableBool("skycrafter_finishdist_eval_timeframe")){
        UI::InputTimeVar("Time min", "skycrafter_finishdist_eval_timemin", 1000, 0);
        if(GetVariableDouble("skycrafter_finishdist_eval_timemax") < GetVariableDouble("skycrafter_finishdist_eval_timemin")){
            SetVariable("skycrafter_finishdist_eval_timemax", GetVariableDouble("skycrafter_finishdist_eval_timemin"));
        }
        UI::InputTimeVar("Time max", "skycrafter_finishdist_eval_timemax", 1000, 0);
    }
}

void Main()
{
    log("Plugin started.");
    fbc.Add(vec3(3, 1, 12.205891));
    fbc.Add(vec3(3, 1, 11.79281));
    fbc.Add(vec3(30, 1, 11.79281));
    fbc.Add(vec3(30, 1, 12.205891));
    fbc.Add(vec3(30, 1.9485588, 12.205891));
    fbc.Add(vec3(26.664326, 5.083612, 12.205891));
    fbc.Add(vec3(19.401665, 7.814228, 12.205891));
    fbc.Add(vec3(12.598329, 7.814228, 12.205891));
    fbc.Add(vec3(5.325968, 5.0799665, 12.205891));
    fbc.Add(vec3(3, 2.889081, 12.205891));
    fbc.Add(vec3(30, 1.9485588, 11.79281));
    fbc.Add(vec3(3, 2.889081, 11.792811));
    fbc.Add(vec3(5.325968, 5.0799665, 11.79281));
    fbc.Add(vec3(12.598328, 7.814228, 11.79281));
    fbc.Add(vec3(19.401665, 7.814228, 11.79281));
    fbc.Add(vec3(26.664326, 5.083612, 11.79281));
    fbi.Add(0); fbi.Add(1); fbi.Add(2); fbi.Add(2); fbi.Add(3); fbi.Add(0); fbi.Add(4); fbi.Add(5); fbi.Add(6); fbi.Add(3); fbi.Add(4);
    fbi.Add(6); fbi.Add(6); fbi.Add(7); fbi.Add(8); fbi.Add(6); fbi.Add(8); fbi.Add(9); fbi.Add(3); fbi.Add(6); fbi.Add(9); fbi.Add(0);
    fbi.Add(3); fbi.Add(9); fbi.Add(2); fbi.Add(10); fbi.Add(4); fbi.Add(4); fbi.Add(3); fbi.Add(2); fbi.Add(1); fbi.Add(11); fbi.Add(12);
    fbi.Add(12); fbi.Add(13); fbi.Add(14); fbi.Add(1); fbi.Add(12); fbi.Add(14); fbi.Add(14); fbi.Add(15); fbi.Add(10); fbi.Add(1); fbi.Add(14);
    fbi.Add(10); fbi.Add(2); fbi.Add(1); fbi.Add(10); fbi.Add(0); fbi.Add(9); fbi.Add(11); fbi.Add(11); fbi.Add(1); fbi.Add(0); fbi.Add(6);
    fbi.Add(14); fbi.Add(13); fbi.Add(13); fbi.Add(7); fbi.Add(6); fbi.Add(5); fbi.Add(15); fbi.Add(14); fbi.Add(14); fbi.Add(6); fbi.Add(5);
    fbi.Add(12); fbi.Add(8); fbi.Add(7); fbi.Add(7); fbi.Add(13); fbi.Add(12); fbi.Add(11); fbi.Add(9); fbi.Add(8); fbi.Add(8); fbi.Add(12);
    fbi.Add(11); fbi.Add(4); fbi.Add(10); fbi.Add(15); fbi.Add(15); fbi.Add(5); fbi.Add(4);



    we.Add(Ellipsoid(vec3(0.863012, 0.3525, 1.782089),vec3(0.182, 0.364, 0.364))); //Front left wheel
    we.Add(Ellipsoid(vec3(-0.863012, 0.3525, 1.782089),vec3(0.182, 0.364, 0.364))); //Front right wheel
    we.Add(Ellipsoid(vec3(0.885002, 0.352504, -1.205502),vec3(0.182, 0.364, 0.364))); //Back left wheel
    we.Add(Ellipsoid(vec3(-0.885002, 0.352504, -1.205502),vec3(0.182, 0.364, 0.364))); //Back right wheel

    RegisterBruteforceEvaluation("distancetofintrigger", "Distance to finish trigger", OnEvaluate, RenderEvalSettings);
    RegisterVariable("skycrafter_finishdist_eval_timeframe", true);
    RegisterVariable("skycrafter_finishdist_eval_timemin", 0.0);
    RegisterVariable("skycrafter_finishdist_eval_timemax", 0.0);

}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Hitbox Distance Bruteforce";
    info.Author = "Skycrafter";
    info.Version = "v0.1.0";
    info.Description = "Allows bruteforcing the distance between the car's hitbox and the finish trigger.";
    return info;
}


array<array<vec3>> findFBVertices(){ //Find finish block vertices
    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
    array<array<vec3>> finishesVertices=array<array<vec3>>();
    if(challenge is null){
        return finishesVertices;
    }
    array<TM::GameCtnBlock@> blocks = challenge.get_Blocks();
    for(uint i = 0; i < blocks.Length; i++){
        TM::GameCtnBlock@ block = blocks[i];
        if(block.get_Name().FindFirst("Finish")==-1){
            continue;
        }
        array<vec3> vertices = array<vec3>();
        vec3 location = vec3(block.Coord.x*32,block.Coord.y*8,block.Coord.z*32);
        for(uint j = 0; j < fbc.Length; j++){
            vec3 v = fbc[j]-vec3(16,4,16);
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
        finishesVertices.Add(vertices);
    }
    return finishesVertices;
}

float calculateCenterToCenterDistanceToAnyFinish(){
    SimulationManager@ simManager = GetSimulationManager();
    float calculated_distance = 1e9;
    const vec3 carLocation = simManager.Dyna.CurrentState.Location.Position;
    array<TM::GameCtnBlock@> blocks = GetCurrentChallenge().get_Blocks();
    vec3 relativeCenter;
    const vec3 offset=vec3(16,4,16);
    array<int> triggerIds = GetTriggerIds();
    for(uint i = 0; i<triggerIds.Length;i++){
        RemoveTrigger(triggerIds[i]);
    }
    for(uint i = 0; i < blocks.Length; i++){
        TM::GameCtnBlock@ block = blocks[i];
        if(block.get_Name().FindFirst("Finish")==-1){
            continue;
        }
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
        float dist = mag(carLocation-centerLocation);
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

    //Precompute polyhedron faces since they are the same for all
    Polyhedron dummy = Polyhedron(fbc,fbi);
    dummy.computeFaces();

    for (uint ellipsoidId = 0; ellipsoidId < 4; ellipsoidId++) {
        GetCarEllipsoidLocationByIndex(simManager, carLocation, ellipsoidId, ellipsoidLocation);
        Ellipsoid ellipsoid = Ellipsoid(vec3(ellipsoidLocation.m_Position.x,ellipsoidLocation.m_Position.y,ellipsoidLocation.m_Position.z),we[ellipsoidId].size);

        for(uint i = 0; i < nfbc.Length;i++){
            
            Polyhedron polyhedron = Polyhedron(nfbc[i],fbi);
            polyhedron.faces=dummy.faces;
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
    array<int> indices;
    array<array<int>> faces;
    Polyhedron(array<vec3> vertices, array<int> indices){
        this.vertices = vertices;
        this.indices=indices;
    }
    Polyhedron(){
        this.vertices = array<vec3>();
        this.indices= array<int>();
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
    void computeFaces() {
        // Assuming indices are provided in sets of three for triangles
        for (uint i = 0; i < indices.Length; i += 3) {
            array<int> face = array<int>();
            face.Add(indices[i]);
            face.Add(indices[i+1]);
            face.Add(indices[i+2]);
            faces.Add(face);
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

vec3 mult2(vec3 v1,vec3 v2){
    return vec3(v1[0]*v2[0],v1[1]*v2[1],v1[2]*v2[2]);
}
vec3 mult(float v1,vec3 v2){
    return vec3(v1*v2[0],v1*v2[1],v1*v2[2]);
}

float pointToSegmentDistance(vec3 p, vec3 a, vec3 b) {
    vec3 ab = b - a;
    vec3 ap = p - a;
    float t = dot(ap, ab) / dot(ab, ab);
    t = Math::Clamp(t, 0.0f, 1.0f);
    vec3 projection = a + mult(t, ab);
    return mag(p - projection);
}

vec3 projectPointOnPlane(vec3 point, vec3 planeNormal, vec3 planePoint) {
    float distance = dot(point - planePoint, planeNormal);
    return point - mult(distance, planeNormal);
}

bool isPointInsideFace(vec3 point, array<vec3>@ faceVertices, vec3 planeNormal) {
    for (uint i = 0; i < faceVertices.Length; ++i) {
        vec3 edge = faceVertices[(i + 1) % faceVertices.Length] - faceVertices[i];
        vec3 edgeNormal = cross(edge, planeNormal);
        if (dot(point - faceVertices[i], edgeNormal) > 0) {
            return false;
        }
    }
    return true;
}


float findDist(Ellipsoid ellipsoid, Polyhedron polyhedron) {
    info = "";
    
    int size=1  ;
    
    // Simplify the problem by turning the ellipsoid into a sphere
    vec3 coeff = ellipsoid.size;
    ellipsoid.divide(coeff);
    // print(ellipsoid.size[0] + " " + ellipsoid.size[1] + " " + ellipsoid.size[2]);
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
            float distance = mag(projectedPoint - sphere.center);
            if (distance < minDistance) {
                minDistance = distance;
                closestPolyPoint = projectedPoint;
            }
        } else {
            // Check the closest point on the edges of the face
            for (uint j = 0; j < faceVertices.Length; ++j) {
                vec3 a = faceVertices[j];
                vec3 b = faceVertices[(j + 1) % faceVertices.Length];
                float distance = pointToSegmentDistance(sphere.center, a, b);
                if (distance < minDistance) {
                    minDistance = distance;
                    // Calculate the closest point on the edge
                    vec3 ab = b - a;
                    vec3 ap = sphere.center - a;
                    float t = dot(ap, ab) / dot(ab, ab);
                    t = Math::Clamp(t, 0.0f, 1.0f);
                    closestPolyPoint = a + mult(t, ab);
                }
            }
        }
    }

    

    //Find the point closest on the sphere's surface
    vec3 vect = closestPolyPoint-sphere.center;
    vec3 closestCirclePoint = sphere.center + normalize(vect);

    vec3 realClosestCirclePoint = mult2(closestCirclePoint, coeff);
    vec3 realClosestPolyPoint = mult2(closestPolyPoint, coeff);
    float realDistance = mag(realClosestPolyPoint-realClosestCirclePoint);
    return realDistance;
}
vec3 normalize(vec3 v) {
    float magnitude = mag(v);
    if (magnitude != 0) {
        return vec3(v.x / magnitude, v.y / magnitude, v.z / magnitude);
    }
    return v;
}

vec3 cross(vec3 a,vec3 b){
    return vec3(a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]);
}

vec3 neg(vec3 v){
    return vec3(-v.x,-v.y,-v.z);
}


float mag(vec3 v){
    return Math::Sqrt(v.x*v.x+v.y*v.y+v.z*v.z);
}

float dot(vec3 a,vec3 b){
    return a.x*b.x+a.y*b.y+a.z*b.z;
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