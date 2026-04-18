namespace ScriptingReference
{
    void SectionHeader(const string &in title)
    {
        UI::Dummy(vec2(0, 6));
        UI::PushStyleColor(UI::Col::Text, vec4(1.0, 0.85, 0.3, 1.0));
        UI::Text(title);
        UI::PopStyleColor();
        UI::Separator();
        UI::Dummy(vec2(0, 2));
    }
    void SubHeader(const string &in title)
    {
        UI::Dummy(vec2(0, 3));
        UI::PushStyleColor(UI::Col::Text, vec4(0.5, 0.85, 1.0, 1.0));
        UI::Text(title);
        UI::PopStyleColor();
        UI::Dummy(vec2(0, 1));
    }
    uint copyId = 0;
    void Code(const string &in code)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + code);
        UI::PopStyleColor();
        UI::SameLine();
        if (UI::Button("Copy##c" + copyId++))
            IO::SetClipboard(code);
    }
    void CodeNoCopy(const string &in code)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + code);
        UI::PopStyleColor();
    }
    void CodeBlock(const string &in line1, const string &in line2)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + line1);
        UI::Text("  " + line2);
        UI::PopStyleColor();
        UI::SameLine();
        if (UI::Button("Copy##c" + copyId++))
            IO::SetClipboard(line1 + "\n" + line2);
    }
    void CodeBlock3(const string &in l1, const string &in l2, const string &in l3)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text("  " + l1);
        UI::Text("  " + l2);
        UI::Text("  " + l3);
        UI::PopStyleColor();
        UI::SameLine();
        if (UI::Button("Copy##c" + copyId++))
            IO::SetClipboard(l1 + "\n" + l2 + "\n" + l3);
    }
    void Desc(const string &in text)
    {
        UI::TextDimmed("    " + text);
    }
    void VarRow(const string &in name, const string &in desc)
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::PushStyleColor(UI::Col::Text, vec4(0.6, 1.0, 0.6, 1.0));
        UI::Text(name);
        UI::PopStyleColor();
        UI::SameLine();
        string copyName = name;
        int slashPos = copyName.FindFirst(" /");
        if (slashPos != -1)
            copyName = copyName.Substr(0, slashPos);
        while (copyName.Length > 0 && copyName[copyName.Length - 1] == 32)
            copyName = copyName.Substr(0, copyName.Length - 1);
        if (UI::Button("Copy##v" + copyId++))
            IO::SetClipboard(copyName);
        UI::TableSetColumnIndex(1);
        UI::TextDimmed(desc);
    }
    void SurfaceRow(const string &in id, const string &in name, const string &in id2, const string &in name2)
    {
        UI::TableNextRow();
        UI::TableSetColumnIndex(0);
        UI::Text(id);
        UI::TableSetColumnIndex(1);
        UI::TextDimmed(name);
        UI::TableSetColumnIndex(2);
        UI::Text(id2);
        UI::TableSetColumnIndex(3);
        UI::TextDimmed(name2);
    }
    void Render()
    {
        copyId = 0;
        UI::PushStyleColor(UI::Col::Text, vec4(1, 1, 1, 0.95));
        UI::TextWrapped("This page documents the scripting language used in Condition Scripts, Restart Condition Scripts, and Custom Target Scripts. All three share the same expression language.");
        UI::PopStyleColor();
        UI::Dummy(vec2(0, 4));
        if (UI::CollapsingHeader("Condition Script"))
        {
            UI::Dummy(vec2(0, 2));
            UI::TextWrapped("Used in the Conditions and Restart Condition fields. Each line is a boolean comparison. All lines must be true (AND logic).");
            SubHeader("Format");
            CodeNoCopy("EXPRESSION  OPERATOR  EXPRESSION");
            UI::Dummy(vec2(0, 2));
            UI::TextDimmed("  Operators:  >  <  >=  <=  =");
            SubHeader("Examples");
            Code("kmh(car.speed) > 500");
            Desc("Speed must exceed 500 km/h");
            UI::Dummy(vec2(0, 1));
            Code("car.z < 10.5");
            Desc("Z position must be below 10.5");
            UI::Dummy(vec2(0, 1));
            CodeBlock("deg(car.pitch) > 80", "car.wheels.frontleft.groundcontact = 1");
            Desc("Nose up and front-left wheel touching ground");
            UI::Dummy(vec2(0, 1));
            Code("distance(car.pos, (105.5, 20.0, 300.0)) < 5.0");
            Desc("Car within 5m of a fixed point");
            UI::Dummy(vec2(0, 1));
            Code("distance(car.pos, variable(\"bf_target_point\")) < 3.0");
            Desc("Car within 3m of the single point BF target");
            UI::Dummy(vec2(0, 1));
            Code("car.wheels.frontleft.surface = 2");
            Desc("Front-left wheel is on Grass (ID 2)");
            UI::Dummy(vec2(0, 1));
            Code("time_since(last_improvement.time) > 60");
            Desc("Restart if no improvement for 60 seconds");
            UI::Dummy(vec2(0, 1));
            Code("time_since(last_restart.time) > 60*5");
            Desc("Restart every 5 minutes");
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Custom Target Script"))
        {
            UI::Dummy(vec2(0, 2));
            UI::TextWrapped("Used in the Custom Target bruteforce evaluation. Each line defines an optimization objective instead of a boolean condition.");
            SubHeader("Directives");
            if (UI::BeginTable("##directives_table", 2))
            {
                UI::TableSetupColumn("Directive");
                UI::TableSetupColumn("Meaning");
                VarRow("min EXPR", "Minimize the expression (lower is better)");
                VarRow("max EXPR", "Maximize the expression (higher is better)");
                VarRow("target VALUE EXPR", "Get expression as close to VALUE as possible");
                UI::EndTable();
            }
            UI::Dummy(vec2(0, 2));
            UI::TextDimmed("  Lines starting with # are comments. Blank lines are ignored.");
            SubHeader("Multi-Objective (Pareto)");
            UI::TextWrapped("  When multiple directives are used, a run is accepted only if it improves at least one objective without worsening any other.");
            SubHeader("Examples");
            Code("max car.speed");
            Desc("Maximize raw speed");
            UI::Dummy(vec2(0, 1));
            Code("target 500 car.x");
            Desc("Get car.x as close to 500 as possible");
            UI::Dummy(vec2(0, 1));
            Code("min distance(car.pos, (105.5, 20.0, 300.0))");
            Desc("Minimize distance to a point");
            UI::Dummy(vec2(0, 1));
            CodeBlock("max kmh(car.speed)", "target 200 car.x");
            Desc("Maximize speed while keeping car.x near 200");
            UI::Dummy(vec2(0, 1));
            CodeBlock("# Optimize for altitude", "max car.y");
            Desc("Comments are allowed with #");
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Variables Reference"))
        {
            UI::Dummy(vec2(0, 2));
            SubHeader("Position");
            if (UI::BeginTable("##vars_pos", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.x  /  car.position.x", "X position");
                VarRow("car.y  /  car.position.y", "Y position (height)");
                VarRow("car.z  /  car.position.z", "Z position");
                UI::EndTable();
            }
            SubHeader("Velocity");
            if (UI::BeginTable("##vars_vel", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.vel.x  /  car.velocity.x", "X velocity, world (m/s)");
                VarRow("car.vel.y  /  car.velocity.y", "Y velocity, world (m/s)");
                VarRow("car.vel.z  /  car.velocity.z", "Z velocity, world (m/s)");
                VarRow("car.speed", "Total speed (m/s)");
                VarRow("car.localvel.x", "X velocity, car-relative (m/s)");
                VarRow("car.localvel.y", "Y velocity, car-relative (m/s)");
                VarRow("car.localvel.z", "Z velocity, car-relative (m/s)");
                VarRow("car.localspeed", "Total local speed (m/s)");
                UI::EndTable();
            }
            SubHeader("Rotation");
            if (UI::BeginTable("##vars_rot", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.yaw  /  car.rotation.yaw", "Yaw angle (radians)");
                VarRow("car.pitch  /  car.rotation.pitch", "Pitch angle (radians)");
                VarRow("car.roll  /  car.rotation.roll", "Roll angle (radians)");
                UI::EndTable();
            }
            SubHeader("Vehicle State");
            if (UI::BeginTable("##vars_state", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.freewheel", "1 if freewheeling, 0 otherwise");
                VarRow("car.lateralcontact", "1 if lateral contact, 0 otherwise");
                VarRow("car.sliding", "1 if sliding, 0 otherwise");
                VarRow("car.gear", "Current gear (-1 = reverse)");
                UI::EndTable();
            }
            SubHeader("Wheels - Ground Contact");
            if (UI::BeginTable("##vars_gc", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Value");
                VarRow("car.wheels.frontleft.groundcontact", "0 or 1");
                VarRow("car.wheels.frontright.groundcontact", "0 or 1");
                VarRow("car.wheels.backleft.groundcontact", "0 or 1");
                VarRow("car.wheels.backright.groundcontact", "0 or 1");
                UI::EndTable();
            }
            SubHeader("Wheels - Surface Material");
            if (UI::BeginTable("##vars_surf", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Value");
                VarRow("car.wheels.frontleft.surface", "Material ID (see table)");
                VarRow("car.wheels.frontright.surface", "Material ID (see table)");
                VarRow("car.wheels.backleft.surface", "Material ID (see table)");
                VarRow("car.wheels.backright.surface", "Material ID (see table)");
                UI::EndTable();
            }
            SubHeader("Vectors (for distance() function)");
            if (UI::BeginTable("##vars_vec", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("car.pos  /  car.position", "Position as vec3");
                VarRow("car.vel  /  car.velocity", "Velocity as vec3 (world)");
                VarRow("car.localvel  /  car.localvelocity", "Velocity as vec3 (car-relative)");
                VarRow("(x, y, z)", "Constant vec3 literal");
                UI::EndTable();
            }
            SubHeader("Bruteforce State");
            if (UI::BeginTable("##vars_bf", 2))
            {
                UI::TableSetupColumn("Variable");
                UI::TableSetupColumn("Description");
                VarRow("iterations", "Current iteration count");
                VarRow("last_improvement.time", "Timestamp of last improvement (s)");
                VarRow("last_restart.time", "Timestamp of last restart (s)");
                UI::EndTable();
            }
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Functions Reference"))
        {
            UI::Dummy(vec2(0, 2));
            if (UI::BeginTable("##funcs_table", 2))
            {
                UI::TableSetupColumn("Function");
                UI::TableSetupColumn("Description");
                VarRow("kmh(value)", "Converts m/s to km/h (x 3.6)");
                VarRow("deg(value)", "Converts radians to degrees");
                VarRow("distance(vec1, vec2)", "Euclidean distance between two vec3s");
                VarRow("time_since(timestamp)", "Seconds elapsed since timestamp");
                VarRow("variable(\"name\")", "Read a TMInterface variable as float or vec3");
                UI::EndTable();
            }
            SubHeader("Operators");
            UI::TextDimmed("  Arithmetic:   +   -   *   /");
            UI::TextDimmed("  Comparison:   >   <   >=   <=   =");
            UI::TextDimmed("  Grouping:     ( ... )");
            UI::Dummy(vec2(0, 4));
        }
        if (UI::CollapsingHeader("Surface Material IDs"))
        {
            UI::Dummy(vec2(0, 2));
            UI::TextDimmed("  Use with car.wheels.*.surface variables in conditions.");
            UI::Dummy(vec2(0, 2));
            if (UI::BeginTable("##surface_ids", 4))
            {
                UI::TableSetupColumn("ID");
                UI::TableSetupColumn("Surface");
                UI::TableSetupColumn("ID");
                UI::TableSetupColumn("Surface");
                UI::TableHeadersRow();
                SurfaceRow("0", "Concrete", "15", "Rubber");
                SurfaceRow("1", "Pavement", "16", "SlidingRubber");
                SurfaceRow("2", "Grass", "17", "Test");
                SurfaceRow("3", "Ice", "18", "Rock");
                SurfaceRow("4", "Metal", "19", "Water");
                SurfaceRow("5", "Sand", "20", "Wood");
                SurfaceRow("6", "Dirt", "21", "Danger");
                SurfaceRow("7", "DirtRoad", "22", "Asphalt");
                SurfaceRow("8", "Plastic", "23", "WetDirtRoad");
                SurfaceRow("9", "Green", "24", "WetAsphalt");
                SurfaceRow("10", "Snow", "25", "WetPavement");
                SurfaceRow("11", "MetalTrans", "26", "WetGrass");
                SurfaceRow("12", "GrassGreen", "27", "Snow2");
                SurfaceRow("13", "GrassBrown", "28", "TurboRoulette");
                SurfaceRow("14", "NotCollidable", "29", "FreeWheeling");
                UI::EndTable();
            }
            UI::Dummy(vec2(0, 4));
        }
    }
}
