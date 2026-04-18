namespace Scripting
{
    bool StartsWith(const string &in str, const string &in prefix)
    {
        if (str.Length < prefix.Length)
            return false;
        return str.Substr(0, prefix.Length) == prefix;
    }
    bool EndsWith(const string &in str, const string &in suffix)
    {
        if (str.Length < suffix.Length)
            return false;
        return str.Substr(str.Length - suffix.Length) == suffix;
    }
    string ToLower(const string &in input)
    {
        string output = input;
        for (uint i = 0; i < output.Length; i++)
        {
            uint8 c = output[i];
            if (c >= 65 && c <= 90)
                output[i] = c + 32;
        }
        return output;
    }
    funcdef bool ConditionCallback(SimulationManager @sim);
    funcdef float FloatGetter(SimulationManager @sim);
    funcdef vec3 Vec3Getter(SimulationManager @sim);
    float GetCarX(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position.x; }
    float GetCarY(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position.y; }
    float GetCarZ(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position.z; }
    float GetCarVelX(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.x; }
    float GetCarVelY(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.y; }
    float GetCarVelZ(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.z; }
    float GetCarLocalVelX(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.x; }
    float GetCarLocalVelY(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.y; }
    float GetCarLocalVelZ(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.z; }
    float GetCarLocalSpeed(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed.Length(); }
    float GetCarPitch(SimulationManager @sim)
    {
        float x, y, z;
        sim.Dyna.CurrentState.Quat.GetYawPitchRoll(x, y, z);
        return y;
    }
    float GetCarYaw(SimulationManager @sim)
    {
        float x, y, z;
        sim.Dyna.CurrentState.Quat.GetYawPitchRoll(x, y, z);
        return x;
    }
    float GetCarRoll(SimulationManager @sim)
    {
        float x, y, z;
        sim.Dyna.CurrentState.Quat.GetYawPitchRoll(x, y, z);
        return z;
    }
    float GetCarSpeed(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed.Length(); }
    float GetCarFreewheel(SimulationManager @sim) { return sim.SceneVehicleCar.IsFreeWheeling ? 1.0f : 0.0f; }
    float GetCarLateralContact(SimulationManager @sim) { return sim.SceneVehicleCar.HasAnyLateralContact ? 1.0f : 0.0f; }
    float GetCarSliding(SimulationManager @sim) { return sim.SceneVehicleCar.IsSliding ? 1.0f : 0.0f; }
    float GetCarGear(SimulationManager @sim) { return sim.SceneVehicleCar.CarEngine.RearGear==1 ? -1.0f : float(sim.SceneVehicleCar.CarEngine.Gear); }
    float GetWheelFLGroundContact(SimulationManager @sim) { return sim.Wheels.FrontLeft.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelFRGroundContact(SimulationManager @sim) { return sim.Wheels.FrontRight.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelBLGroundContact(SimulationManager @sim) { return sim.Wheels.BackLeft.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelBRGroundContact(SimulationManager @sim) { return sim.Wheels.BackRight.RTState.HasGroundContact ? 1.0f : 0.0f; }
    float GetWheelFLSurface(SimulationManager @sim) { return float(sim.Wheels.FrontLeft.RTState.ContactMaterialId); }
    float GetWheelFRSurface(SimulationManager @sim) { return float(sim.Wheels.FrontRight.RTState.ContactMaterialId); }
    float GetWheelBLSurface(SimulationManager @sim) { return float(sim.Wheels.BackLeft.RTState.ContactMaterialId); }
    float GetWheelBRSurface(SimulationManager @sim) { return float(sim.Wheels.BackRight.RTState.ContactMaterialId); }
    vec3 GetCarPos(SimulationManager @sim) { return sim.Dyna.CurrentState.Location.Position; }
    vec3 GetCarVel(SimulationManager @sim) { return sim.Dyna.CurrentState.LinearSpeed; }
    vec3 GetCarLocalVel(SimulationManager @sim) { return sim.SceneVehicleCar.CurrentLocalSpeed; }
    float GetIterationCount(SimulationManager @sim)
    {
        return float(info.Iterations);
    }
    float GetTimeLastImprovement(SimulationManager @sim)
    {
        return float(lastImprovementTime / 1000.0);
    }
    float GetTimeLastRestart(SimulationManager @sim)
    {
        return float(lastRestartTime / 1000.0);
    }
    class ConstantFloat
    {
        float val;
        ConstantFloat(float v) { val = v; }
        float Get(SimulationManager @sim) { return val; }
    }
    class ConstantVec3
    {
        vec3 val;
        ConstantVec3(vec3 v) { val = v; }
        vec3 Get(SimulationManager @sim) { return val; }
    }
    class VarFloat
    {
        string name;
        VarFloat(const string &in n) { name = n; }
        float Get(SimulationManager @sim) { return float(GetVariableDouble(name)); }
    }
    class VarVec3
    {
        string name;
        VarVec3(const string &in n) { name = n; }
        vec3 Get(SimulationManager @sim) { return Text::ParseVec3(GetVariableString(name)); }
    }
    class MathOp
    {
        FloatGetter @left;
        FloatGetter @right;
        string op;
        MathOp(FloatGetter @l, FloatGetter @r, const string &in o)
        {
            @left = l;
            @right = r;
            op = o;
        }
        float Get(SimulationManager @sim)
        {
            float l = left(sim);
            float r = right(sim);
            if (op == "+")
                return l + r;
            if (op == "-")
                return l - r;
            if (op == "*")
                return l * r;
            if (op == "/")
                return r != 0.0f ? l / r : 0.0f;
            return 0.0f;
        }
    }
    class FunctionKmh
    {
        FloatGetter @arg;
        FunctionKmh(FloatGetter @a) { @arg = a; }
        float Get(SimulationManager @sim) { return arg(sim) * 3.6f; }
    }
    class FunctionDeg
    {
        FloatGetter @arg;
        FunctionDeg(FloatGetter @a) { @arg = a; }
        float Get(SimulationManager @sim) { return arg(sim) * 180.0f / 3.14159265358979323846f; }
    }
    class FunctionDistance
    {
        Vec3Getter @p1;
        Vec3Getter @p2;
        FunctionDistance(Vec3Getter @a, Vec3Getter @b)
        {
            @p1 = a;
            @p2 = b;
        }
        float Get(SimulationManager @sim) { return Math::Distance(p1(sim), p2(sim)); }
    }
    class FunctionTimeSince
    {
        FloatGetter @arg;
        FunctionTimeSince(FloatGetter @a) { @arg = a; }
        float Get(SimulationManager @sim)
        {
            return (float(Time::Now) / 1000.0f) - arg(sim);
        }
    }
    enum CmpOp { Gt,
                 Lt,
                 GtEq,
                 LtEq,
                 Eq }
    class Comparison
    {
        FloatGetter @left;
        FloatGetter @right;
        CmpOp op;
        Comparison(FloatGetter @l, FloatGetter @r, CmpOp o)
        {
            @left = l;
            @right = r;
            op = o;
        }
        bool Evaluate(SimulationManager @sim)
        {
            float l = left(sim);
            float r = right(sim);
            switch (op)
            {
            case CmpOp::Gt:
                return l > r;
            case CmpOp::Lt:
                return l < r;
            case CmpOp::GtEq:
                return l >= r;
            case CmpOp::LtEq:
                return l <= r;
            case CmpOp::Eq:
                return l == r;
            }
            return false;
        }
    }
    string CleanSource(const string &in input)
    {
        string output = "";
        string temp = " ";
        bool insideQuote = false;
        for (uint i = 0; i < input.Length; i++)
        {
            uint8 c = input[i];
            if (c == 34)
                insideQuote = !insideQuote;
            if (insideQuote || c != 32)
            {
                temp[0] = c;
                output += temp;
            }
        }
        return output;
    }
    int FindTopLevel(const string &in code, const string &in target, int start = 0)
    {
        int depth = 0;
        int targetLen = target.Length;
        for (uint i = start; i < code.Length; i++)
        {
            uint8 c = code[i];
            if (c == 40)
                depth++;
            else if (c == 41)
                depth--;
            else if (depth == 0)
            {
                if (code.Substr(i, targetLen) == target)
                    return i;
            }
        }
        return -1;
    }
    ConditionCallback @Compile(const string &in source)
    {
        string code = CleanSource(source);
        if (code == "")
            return null;
        CmpOp op;
        int idx = -1;
        int len = 1;
        if ((idx = FindTopLevel(code, ">=")) != -1)
        {
            op = CmpOp::GtEq;
            len = 2;
        }
        else if ((idx = FindTopLevel(code, "<=")) != -1)
        {
            op = CmpOp::LtEq;
            len = 2;
        }
        else if ((idx = FindTopLevel(code, ">")) != -1)
        {
            op = CmpOp::Gt;
        }
        else if ((idx = FindTopLevel(code, "<")) != -1)
        {
            op = CmpOp::Lt;
        }
        else if ((idx = FindTopLevel(code, "=")) != -1)
        {
            op = CmpOp::Eq;
        }
        if (idx == -1)
        {
            return null;
        }
        string lhs = code.Substr(0, idx);
        string rhs = code.Substr(idx + len);
        FloatGetter @leftGetter = ParseExpression(lhs);
        FloatGetter @rightGetter = ParseExpression(rhs);
        if (leftGetter is null || rightGetter is null)
            return null;
        Comparison @comp = Comparison(leftGetter, rightGetter, op);
        return ConditionCallback(comp.Evaluate);
    }
    class MultiCondition
    {
        array<ConditionCallback @> conditions;
        void Add(ConditionCallback @cb)
        {
            conditions.Add(cb);
        }
        bool Evaluate(SimulationManager @sim)
        {
            for (uint i = 0; i < conditions.Length; i++)
            {
                if (!conditions[i](sim))
                    return false;
            }
            return true;
        }
    }
    ConditionCallback @CompileMulti(const array<string> &in sources)
    {
        MultiCondition @multi = MultiCondition();
        for (uint i = 0; i < sources.Length; i++)
        {
            string s = sources[i];
            if (CleanSource(s) == "")
                continue;
            ConditionCallback @cb = Compile(s);
            if (cb is null)
                return null;
            multi.Add(cb);
        }
        if (multi.conditions.Length == 0)
            return null;
        return ConditionCallback(multi.Evaluate);
    }
    FloatGetter @ParseExpression(const string &in code)
    {
        int idx = -1;
        string opStr = "";
        int depth = 0;
        for (int i = int(code.Length) - 1; i >= 0; i--)
        {
            if (code[i] == 41)
                depth++;
            else if (code[i] == 40)
                depth--;
            else if (depth == 0)
            {
                if (code[i] == 43)
                {
                    idx = i;
                    opStr = "+";
                    break;
                }
                if (code[i] == 45 && i > 0)
                {
                    idx = i;
                    opStr = "-";
                    break;
                }
            }
        }
        if (idx != -1)
        {
            FloatGetter @left = ParseExpression(code.Substr(0, idx));
            FloatGetter @right = ParseTerm(code.Substr(idx + 1));
            if (left is null || right is null)
                return null;
            MathOp @math = MathOp(left, right, opStr);
            return FloatGetter(math.Get);
        }
        return ParseTerm(code);
    }
    FloatGetter @ParseTerm(const string &in code)
    {
        int idx = -1;
        string opStr = "";
        int depth = 0;
        for (int i = int(code.Length) - 1; i >= 0; i--)
        {
            if (code[i] == 41)
                depth++;
            else if (code[i] == 40)
                depth--;
            else if (depth == 0)
            {
                if (code[i] == 42)
                {
                    idx = i;
                    opStr = "*";
                    break;
                }
                if (code[i] == 47)
                {
                    idx = i;
                    opStr = "/";
                    break;
                }
            }
        }
        if (idx != -1)
        {
            FloatGetter @left = ParseTerm(code.Substr(0, idx));
            FloatGetter @right = ParseFactor(code.Substr(idx + 1));
            if (left is null || right is null)
                return null;
            MathOp @math = MathOp(left, right, opStr);
            return FloatGetter(math.Get);
        }
        return ParseFactor(code);
    }
    FloatGetter @ParseFactor(const string &in input)
    {
        string t = input;
        string lower = ToLower(t);
        if (StartsWith(t, "(") && EndsWith(t, ")"))
        {
            return ParseExpression(t.Substr(1, t.Length - 2));
        }
        if (StartsWith(lower, "kmh(") && EndsWith(t, ")"))
        {
            string argStr = t.Substr(4, t.Length - 5);
            FloatGetter @arg = ParseExpression(argStr);
            if (arg is null)
                return null;
            FunctionKmh @fn = FunctionKmh(arg);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "deg(") && EndsWith(t, ")"))
        {
            string argStr = t.Substr(4, t.Length - 5);
            FloatGetter @arg = ParseExpression(argStr);
            if (arg is null)
                return null;
            FunctionDeg @fn = FunctionDeg(arg);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "distance(") && EndsWith(t, ")"))
        {
            string content = t.Substr(9, t.Length - 10);
            int commaIdx = FindTopLevel(content, ",");
            if (commaIdx == -1)
                return null;
            string arg1 = content.Substr(0, commaIdx);
            string arg2 = content.Substr(commaIdx + 1);
            Vec3Getter @v1 = ParseVec3(arg1);
            Vec3Getter @v2 = ParseVec3(arg2);
            if (v1 is null || v2 is null)
                return null;
            FunctionDistance @fn = FunctionDistance(v1, v2);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "time_since(") && EndsWith(t, ")"))
        {
            string content = t.Substr(11, t.Length - 12);
            FloatGetter @arg = ParseExpression(content);
            if (arg is null)
                return null;
            FunctionTimeSince @fn = FunctionTimeSince(arg);
            return FloatGetter(fn.Get);
        }
        if (StartsWith(lower, "variable(") && EndsWith(t, ")"))
        {
            string content = t.Substr(9, t.Length - 10);
            if (StartsWith(content, "\"") && EndsWith(content, "\""))
            {
                content = content.Substr(1, content.Length - 2);
            }
            VarFloat @v = VarFloat(content);
            return FloatGetter(v.Get);
        }
        if (lower == "car.position.x" || lower == "car.x")
            return GetCarX;
        if (lower == "car.position.y" || lower == "car.y")
            return GetCarY;
        if (lower == "car.position.z" || lower == "car.z")
            return GetCarZ;
        if (lower == "car.velocity.x" || lower == "car.vel.x")
            return GetCarVelX;
        if (lower == "car.velocity.y" || lower == "car.vel.y")
            return GetCarVelY;
        if (lower == "car.velocity.z" || lower == "car.vel.z")
            return GetCarVelZ;
        if (lower == "car.localvelocity.x" || lower == "car.localvel.x")
            return GetCarLocalVelX;
        if (lower == "car.localvelocity.y" || lower == "car.localvel.y")
            return GetCarLocalVelY;
        if (lower == "car.localvelocity.z" || lower == "car.localvel.z")
            return GetCarLocalVelZ;
        if (lower == "car.localspeed")
            return GetCarLocalSpeed;
        if (lower == "car.rotation.pitch" || lower == "car.pitch")
            return GetCarPitch;
        if (lower == "car.rotation.yaw" || lower == "car.yaw")
            return GetCarYaw;
        if (lower == "car.rotation.roll" || lower == "car.roll")
            return GetCarRoll;
        if (lower == "car.speed")
            return GetCarSpeed;
        if (lower == "car.freewheel")
            return GetCarFreewheel;
        if (lower == "car.lateralcontact")
            return GetCarLateralContact;
        if (lower == "car.sliding")
            return GetCarSliding;
        if (lower == "car.gear")
            return GetCarGear;
        if (lower == "car.wheels.frontleft.groundcontact")
            return GetWheelFLGroundContact;
        if (lower == "car.wheels.frontright.groundcontact")
            return GetWheelFRGroundContact;
        if (lower == "car.wheels.backleft.groundcontact")
            return GetWheelBLGroundContact;
        if (lower == "car.wheels.backright.groundcontact")
            return GetWheelBRGroundContact;
        if (lower == "car.wheels.frontleft.surface")
            return GetWheelFLSurface;
        if (lower == "car.wheels.frontright.surface")
            return GetWheelFRSurface;
        if (lower == "car.wheels.backleft.surface")
            return GetWheelBLSurface;
        if (lower == "car.wheels.backright.surface")
            return GetWheelBRSurface;
        if (lower == "last_improvement.time")
            return GetTimeLastImprovement;
        if (lower == "last_restart.time")
            return GetTimeLastRestart;
        if (lower == "iterations")
            return GetIterationCount;
        if (lower.Length > 0 && lower.FindFirstNotOf("0123456789.-") == -1)
        {
            ConstantFloat @c = ConstantFloat(Text::ParseFloat(lower));
            return FloatGetter(c.Get);
        }
        return null;
    }
    Vec3Getter @ParseVec3(const string &in input)
    {
        string t = input;
        string lower = ToLower(t);
        if (StartsWith(t, "(") && EndsWith(t, ")"))
        {
            string content = t.Substr(1, t.Length - 2);
            array<string> parts = content.Split(",");
            if (parts.Length == 3)
            {
                vec3 v(Text::ParseFloat(parts[0]), Text::ParseFloat(parts[1]), Text::ParseFloat(parts[2]));
                ConstantVec3 @c = ConstantVec3(v);
                return Vec3Getter(c.Get);
            }
        }
        if (StartsWith(lower, "variable(") && EndsWith(t, ")"))
        {
            string content = t.Substr(9, t.Length - 10);
            if (StartsWith(content, "\"") && EndsWith(content, "\""))
            {
                content = content.Substr(1, content.Length - 2);
            }
            VarVec3 @v = VarVec3(content);
            return Vec3Getter(v.Get);
        }
        if (lower == "car.position" || lower == "car.pos")
            return GetCarPos;
        if (lower == "car.velocity" || lower == "car.vel")
            return GetCarVel;
        if (lower == "car.localvelocity" || lower == "car.localvel")
            return GetCarLocalVel;
        return null;
    }
}
