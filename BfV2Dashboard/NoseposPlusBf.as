namespace NoseposPlusBf
{
    // === Globals from Shweetz.as ===
    uint iterations = 0;
    bool debugPrint = false;

    // === Globals from Common.as ===
    array<string> modes = { "Point", "Speed", "Time", "Hold" };
    int prevTime = 0;
    auto best = CarState();
    auto curr = CarState();

    // === CarState class from Common.as ===
    class CarState
    {
        int time = -1;
        double angle = -1;
        double distance = -1;
        double speed = -1;
        int airTime = 0;
        int noseposUntil = 0;

        void ResetForNewTick()
        {
            time = -1;
            angle = -1;
            distance = -1;
            speed = -1;
        }
    }

    // === Point class from Common.as ===
    class Point
    {
        string pstr;
        vec3 pvec;

        Point()
        {
            str("0 0 0");
        }

        Point(const string &in s)
        {
            str(s);
        }

        void str(const string &in s)
        {
            pstr = s;
            array<string>@ splits = s.Split(" ");
            pvec = vec3(Text::ParseFloat(splits[0]), Text::ParseFloat(splits[1]), Text::ParseFloat(splits[2]));
            pvec.y = Text::ParseFloat(splits[1]);
            pvec.z = Text::ParseFloat(splits[2]);
        }

        void vec(const vec3 &in v)
        {
            pvec = v;
        }

        string toStr()
        {
            return "" + pvec.x + " " + pvec.y + " " + pvec.z;
        }

        vec3 toVec3()
        {
            return pvec;
        }
    }

    // === Utility functions from Common.as ===
    bool GetB(const string &in str)
    {
        return GetVariableBool(str);
    }

    double GetD(const string &in str)
    {
        return GetVariableDouble(str);
    }

    string GetS(const string &in str)
    {
        return GetVariableString(str);
    }

    void Print(string str)
    {
        if (debugPrint) {
            print(str);
        }
    }

    bool IsEvalTime(int raceTime)
    {
        return GetD("shweetz_eval_time_min") <= raceTime && raceTime <= GetD("shweetz_eval_time_max");
    }

    bool IsPastEvalTime(int raceTime)
    {
        return GetD("shweetz_eval_time_max") <= raceTime;
    }

    bool IsMaxTime(int raceTime)
    {
        return GetD("shweetz_eval_time_max") == raceTime;
    }

    double DistanceToPoint(const vec3 &in pos)
    {
        Point point(GetS("shweetz_point"));
        return Math::Distance(pos, point.pvec);
    }

    int CountWheelsOnGround(SimulationManager@ simManager)
    {
        int count = 0;
        auto@ state = simManager.SaveState();
        if (state.Wheels.FrontLeft.RTState.HasGroundContact) count++;
        if (state.Wheels.FrontRight.RTState.HasGroundContact) count++;
        if (state.Wheels.BackRight.RTState.HasGroundContact) count++;
        if (state.Wheels.BackLeft.RTState.HasGroundContact) count++;

        return count;
    }

    bool IsInTrigger(const vec3 &in pos, const string &in var)
    {
        auto trigger = GetTriggerVar(var);
        return trigger.ContainsPoint(pos);
    }

    bool IsInTrigger(const vec3 &in pos)
    {
        return IsInTrigger(pos, "shweetz_trigger_index");
    }

    Trigger3D GetTriggerVar(const string &in var)
    {
        uint triggerIndex = int(GetD(var));
        return GetTriggerByIndex(triggerIndex - 1);
    }

    // === Conditions from Conditions.as ===
    void UIConditions()
    {
        UI::SliderFloatVar("Min speed (km/h)", "shweetz_condition_speed", 0.0f, 1000.0f);
        UI::InputIntVar("Min CP collected", "shweetz_min_cp", 1);
        UI::SliderIntVar("Min wheels on ground", "shweetz_min_wheels_on_ground", 0, 4);
        UI::SliderIntVar("Gear (0 to disable)", "shweetz_gear", -1, 6);

        // Trigger
        UI::InputIntVar("Trigger index (0 to disable)", "shweetz_trigger_index", 1);
        Trigger3D trigger = GetTriggerVar("shweetz_trigger_index");
        if (trigger.Size.x != -1) {
            vec3 pos2 = trigger.Position + trigger.Size;
            UI::TextDimmed("The car must be in the trigger of coordinates: ");
            UI::TextDimmed("" + trigger.Position.ToString() + " " + pos2.ToString());
        }

        // Anti-Trigger
        UI::InputIntVar("Anti-Trigger index (0 to disable)", "shweetz_antitrigger_index", 1);
        trigger = GetTriggerVar("shweetz_antitrigger_index");
        if (trigger.Size.x != -1) {
            vec3 pos2 = trigger.Position + trigger.Size;
            UI::TextDimmed("The car must never hit the trigger of coordinates: ");
            UI::TextDimmed("" + trigger.Position.ToString() + " " + pos2.ToString());
        }

        UI::Dummy( vec2(0, 25) );

        UI::InputTimeVar("Tick to print if conditions are met (0 to disable)", "shweetz_debug");

        UI::Dummy( vec2(0, 25) );
    }

    bool AreConditionsMet(SimulationManager@ simManager)
    {
        // Choose a tick to print if a condition failed
        int debugTick = int(GetD("shweetz_debug"));

        float speedKmh = simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6;
        if (speedKmh < GetD("shweetz_condition_speed")) {
            if (simManager.TickTime == debugTick) { print("Condition speed too low: " + speedKmh + " < " + GetD("shweetz_condition_speed")); }
            return false;
        }

        int cpCount = int(simManager.PlayerInfo.CurCheckpointCount);
        if (cpCount < GetD("shweetz_min_cp")) {
            if (simManager.TickTime == debugTick) { print("Condition CPs not reached: " + cpCount + " < " + GetD("shweetz_min_cp")); }
            return false;
        }

        int wheelCount = CountWheelsOnGround(simManager);
        if (wheelCount < GetD("shweetz_min_wheels_on_ground")) {
            if (simManager.TickTime == debugTick) { print("Condition wheels not reached: " + wheelCount + " < " + GetD("shweetz_min_wheels_on_ground")); }
            return false;
        }

        int gear = simManager.SceneVehicleCar.CarEngine.Gear;
        if (GetD("shweetz_gear") > 0 && GetD("shweetz_gear") != gear) {
            if (simManager.TickTime == debugTick) { print("Condition gear not reached: " + gear + " != " + GetD("shweetz_gear")); }
            return false;
        }

        vec3 pos = simManager.Dyna.CurrentState.Location.Position;
        if (GetD("shweetz_trigger_index") > 0 && !IsInTrigger(pos, "shweetz_trigger_index")) {
            if (simManager.TickTime == debugTick) { print("Condition trigger not reached"); }
            return false;
        }

        if (simManager.TickTime == debugTick) { print("Conditions OK"); }

        return true;
    }

    bool IsForceReject(SimulationManager@ simManager)
    {
        int debugTick = int(GetD("shweetz_debug"));

        vec3 pos = simManager.Dyna.CurrentState.Location.Position;
        if (GetD("shweetz_antitrigger_index") > 0 && IsInTrigger(pos, "shweetz_antitrigger_index")) {
            if (debugTick > 0) { print("Antitrigger hit at " + curr.time + ", reject iteration " + iterations); }
            return true;
        }

        return false;
    }

    // === UI from BfNoseposPlus.as ===
    void UIBfNosePos()
    {
        UINosePos();
        UI::Separator();
        UIConditions();
    }

    void UINosePos()
    {
        // Eval time
        UI::InputTimeVar("Eval time min", "shweetz_eval_time_min");
        UI::InputTimeVar("Eval time max", "shweetz_eval_time_max");

        // eval max >= eval min
        SetVariable("shweetz_eval_time_max", Math::Max(GetD("shweetz_eval_time_min"), GetD("shweetz_eval_time_max")));

        if (GetD("bf_inputs_max_time") != 0) {
            // inputs max < eval max
            SetVariable("bf_inputs_max_time", Math::Min(GetD("bf_inputs_max_time"), GetD("shweetz_eval_time_max") - 10));

            // inputs max >= inputs min
            SetVariable("bf_inputs_max_time", Math::Max(GetD("bf_inputs_max_time"), GetD("bf_inputs_min_time")));
        }

        UI::Dummy( vec2(0, 25) );

        UI::InputIntVar("Target yaw (°) (90 for left gs and uber, -90 for right)", "shweetz_yaw_deg", 1);
        UI::InputIntVar("Target pitch (°) (85 to 90 for nosepos, 0 for gs, -25 for uber)", "shweetz_pitch_deg", 1);
        UI::InputIntVar("Target roll (°) (usually 0)", "shweetz_roll_deg", 1);
        UI::CheckboxVar("Accept any yaw for nosepos (uncheck for yaw bruteforce)", "shweetz_allow_yaw_180");

        // Change eval
        if (UI::CheckboxVar("Change eval after nosepos is good enough", "shweetz_next_eval_check"))
        {
            UI::TextDimmed("Good enough means angle can be some degrees off from ideal nosepos.");
            UI::InputIntVar("Max angle from ideal (°)", "shweetz_angle_min_deg", 1);

            UINextEval();
        }

        UI::Dummy( vec2(0, 25) );
    }

    void UINextEval()
    {
        string next_eval = GetS("shweetz_next_eval");
        if (UI::BeginCombo("Next eval", next_eval)) {
            for (uint i = 0; i < modes.Length; i++)
            {
                string currentMode = modes[i];
                if (UI::Selectable(currentMode, next_eval == currentMode))
                {
                    SetVariable("shweetz_next_eval", currentMode);
                }
            }

            UI::EndCombo();
        }

        if (next_eval == "Point") {
            UI::DragFloat3Var("Point", "shweetz_point");
            UI::SameLine();
            if (UI::Button("Copy coordinates")) {
                auto camera = GetCurrentCamera();
                if (@camera != null) {
                    SetVariable("shweetz_point", camera.Location.Position.ToString());
                }
            }
        }
    }

    // === Evaluation logic from BfNoseposPlus.as ===
    BFEvaluationResponse@ OnEvaluateNosePos(SimulationManager@ simManager, const BFEvaluationInfo&in info)
    {
        int raceTime = simManager.TickTime;
        prevTime = raceTime;

        if (info.Rewinded) {
            curr = CarState();
        } else {
            curr.ResetForNewTick();
        }
        curr.time = raceTime;

        iterations = info.Iterations;

        auto resp = BFEvaluationResponse();
        resp.Decision = BFEvaluationDecision::DoNothing;

        if (GetS("shweetz_next_eval") == "Hold") {
            if (info.Phase == BFPhase::Initial) {
                if (IsPastEvalTime(raceTime) && IsBetterNosePos(simManager, curr)) {
                    best = curr;
                    PrintGreenTextNosePos(best);
                }
            }
            else {
                if (IsPastEvalTime(raceTime)) {
                    if (IsBetterNosePos(simManager, curr)) {
                        resp.Decision = BFEvaluationDecision::Accept;
                        return resp;
                    }
                    if (!IsNosePos(simManager)) {
                        resp.Decision = BFEvaluationDecision::Reject;
                        return resp;
                    }
                }
            }
        }
        else {
            if (info.Phase == BFPhase::Initial) {
                if (IsEvalTime(raceTime) && IsBetterNosePos(simManager, curr)) {
                    best = curr;
                }

                if (IsMaxTime(raceTime)) {
                    PrintGreenTextNosePos(best);
                }
            }
            else {
                if (IsEvalTime(raceTime)) {
                    if (IsForceReject(simManager)) {
                        resp.Decision = BFEvaluationDecision::Reject;
                        return resp;
                    }
                    if (IsBetterNosePos(simManager, curr)) {
                        resp.Decision = BFEvaluationDecision::Accept;
                        return resp;
                    }
                }

                if (IsPastEvalTime(raceTime)) {
                    resp.Decision = BFEvaluationDecision::Reject;
                    return resp;
                }
            }
        }

        return resp;
    }

    /**
     * Project an angle in degrees in [-180; 180[
     */
    double AngleProject180To180Deg(double angle_deg)
    {
        while (angle_deg < -180) {
            angle_deg += 360;
        }
        while (angle_deg >= 180) {
            angle_deg -= 360;
        }
        return angle_deg;
    }

    double ComputeCarAngleToTarget(SimulationManager@ simManager)
    {
        // Get values
        vec3 speedVec = simManager.Dyna.CurrentState.LinearSpeed;
        float carYaw, carPit, carRol;
        simManager.Dyna.CurrentState.Location.Rotation.GetYawPitchRoll(carYaw, carPit, carRol);

        // Do calculations
        double targetYaw = GetD("shweetz_yaw_deg") + Math::ToDeg(Math::Atan2(speedVec.x, speedVec.z));
        double targetPit = GetD("shweetz_pitch_deg");
        double targetRol = GetD("shweetz_roll_deg");
        targetYaw = AngleProject180To180Deg(targetYaw);
        targetPit = AngleProject180To180Deg(targetPit);
        targetRol = AngleProject180To180Deg(targetRol);

        double diffYaw = Math::Abs(Math::ToDeg(carYaw) - targetYaw);
        double diffPit = Math::Abs(Math::ToDeg(carPit) - targetPit);
        double diffRol = Math::Abs(Math::ToDeg(carRol) - targetRol);
        diffYaw = diffYaw > 180 ? 360 - diffYaw : diffYaw;
        diffPit = diffPit > 180 ? 360 - diffPit : diffPit;
        diffRol = diffRol > 180 ? 360 - diffRol : diffRol;

        if (GetB("shweetz_allow_yaw_180")) {
            diffYaw = Math::Max(diffYaw - 90, 0.0);
        }

        return diffYaw + diffPit + diffRol;
    }

    bool IsNosePos(SimulationManager@ simManager)
    {
        // Conditions
        if (!AreConditionsMet(simManager)) {
            return false;
        }

        return ComputeCarAngleToTarget(simManager) < GetD("shweetz_angle_min_deg");
    }

    bool IsBetterNosePos(SimulationManager@ simManager, CarState& curr)
    {
        Print("IsBetterNosePos");

        // Conditions
        if (!AreConditionsMet(simManager)) {
            return false;
        }

        // Get values
        vec3 pos = simManager.Dyna.CurrentState.Location.Position;
        float speedKmh = simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6;

        curr.angle = ComputeCarAngleToTarget(simManager);
        curr.distance = DistanceToPoint(pos);
        curr.speed = Math::Min(speedKmh, 1000);
        if (IsNosePos(simManager)) {
            if (curr.noseposUntil == 0 || curr.noseposUntil == curr.time - 10) {
                curr.noseposUntil = curr.time;
            }
        }

        if (best.distance == -1) {
            // Base run (past conditions)
            return true;
        }

        if (GetB("shweetz_next_eval_check")) {
            if (best.angle < GetD("shweetz_angle_min_deg") && curr.angle < GetD("shweetz_angle_min_deg")) {
                // Best and current have a good angle, now check next eval
                if (GetS("shweetz_next_eval") == "Point") {
                    return curr.distance < best.distance;
                }
                if (GetS("shweetz_next_eval") == "Speed") {
                    return curr.speed > best.speed;
                }
                if (GetS("shweetz_next_eval") == "Time") {
                    return curr.time < best.time;
                }
            }
            if (GetS("shweetz_next_eval") == "Hold") {
                return curr.noseposUntil > best.noseposUntil;
            }
        }
        Print("" + curr.angle + " vs " + best.angle);
        return curr.angle < best.angle;
    }

    void PrintGreenTextNosePos(CarState best)
    {
        string greenText = "base at " + best.time + ": angle=" + best.angle;
        if (GetS("shweetz_next_eval") == "Point") greenText += ", Distance=" + best.distance;
        if (GetS("shweetz_next_eval") == "Speed") greenText += ", Speed=" + best.speed;
        greenText += ", Iteration=" + iterations;
        print(greenText);
    }

    // === OnSimBegin (BF-relevant reset only) ===
    void OnSimBegin(SimulationManager@ simManager)
    {
        prevTime = 0;
        best = CarState();
    }

    // === RegisterVariables (BF-relevant only) ===
    void RegisterVariables()
    {
        RegisterVariable("shweetz_eval_time_min", 0);
        RegisterVariable("shweetz_eval_time_max", 10000);
        RegisterVariable("shweetz_next_eval_check", false);
        RegisterVariable("shweetz_next_eval", modes[0]);
        RegisterVariable("shweetz_point", "0 0 0");
        RegisterVariable("shweetz_angle_min_deg", 10);
        RegisterVariable("shweetz_yaw_deg", 0);
        RegisterVariable("shweetz_pitch_deg", 85);
        RegisterVariable("shweetz_roll_deg", 0);
        RegisterVariable("shweetz_allow_yaw_180", true);

        // Conditions
        RegisterVariable("shweetz_condition_speed", 0);
        RegisterVariable("shweetz_min_cp", 0);
        RegisterVariable("shweetz_min_wheels_on_ground", 0);
        RegisterVariable("shweetz_gear", -1);
        RegisterVariable("shweetz_trigger_index", 0);
        RegisterVariable("shweetz_antitrigger_index", 0);
        RegisterVariable("shweetz_debug", 0);
    }

    // === Main (BfV2 pattern) ===
    void Main()
    {
        RegisterVariables();
        auto eval = RegisterBruteforceEval("nosepos_plus", "Nosepos+", OnEvaluateNosePos, UIBfNosePos);
        @eval.onSimBegin = @OnSimBegin;
    }
}
