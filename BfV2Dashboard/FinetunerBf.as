namespace FinetunerBf
{

// ============================================================================
// smn_utils - Time
// ============================================================================

typedef int32 ms;

const ms TICK = 10;

ms TickToMs(const int tick)
{
    return tick * TICK;
}

int MsToTick(const ms time)
{
    return time / TICK;
}

bool ParseTime(const string &in raceTime, int &out value)
{
    value = Time::Parse(raceTime);
    return value != -1;
}


// ============================================================================
// smn_utils - String (PadRight, Repeat, StringBuilder)
// ============================================================================

string PadRight(const string &in str, const uint targetLength, const uint8 char = ' ')
{
    const uint len = str.Length;
    if (len >= targetLength)
        return str;

    string s = str;
    s.Resize(targetLength);

    for (uint i = len; i < targetLength; i++)
        s[i] = char;

    return s;
}

string Repeat(const uint times, const uint8 char = ' ')
{
    string builder;
    builder.Resize(times);
    for (uint i = 0; i < times; i++)
        builder[i] = char;
    return builder;
}

class StringWrapper
{
    string str;

    StringWrapper()
    {}

    StringWrapper(const string &in s)
    {
        str = s;
    }
}

class StringBuilder
{
    protected string buffer;

    StringBuilder@ Append(const bool value)   { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const uint value)   { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const uint64 value) { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const int value)    { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const int64 value)  { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const float value)  { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const double value) { const string s = value; AppendOne(s); return this; }

    StringBuilder@ Append(const string &in value) { AppendOne(value); return this; }
    StringBuilder@ Append(const array<string>@ strings) { AppendMany(strings); return this; }

    StringBuilder@ AppendLine() { AppendOne("\n"); return this; }

    StringBuilder@ AppendLine(const bool value)   { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const uint value)   { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const uint64 value) { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const int value)    { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const int64 value)  { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const float value)  { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const double value) { AppendMany({value, "\n"}); return this; }

    StringBuilder@ AppendLine(const string &in value) { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const array<string>@ strings)
    {
        AppendMany(strings, 1);
        buffer[buffer.Length - 1] = '\n';
        return this;
    }

    protected void AppendOne(const string &in s)
    {
        const uint offset = buffer.Length;
        buffer.Resize(offset + s.Length);
        for (uint i = 0; i < s.Length; i++)
            buffer[offset + i] = s[i];
    }

    protected void AppendMany(const array<string>@ strings, const uint extraLength = 0)
    {
        uint totalLength = extraLength;
        for (uint i = 0; i < strings.Length; i++)
            totalLength += strings[i].Length;

        const uint offset = buffer.Length;
        buffer.Resize(offset + totalLength);
        uint bufferIndex = offset;
        for (uint i = 0; i < strings.Length; i++)
        {
            for (uint j = 0; j < strings[i].Length; j++)
                buffer[bufferIndex++] = strings[i][j];
        }
    }

    void Clear()
    {
        buffer.Resize(0);
    }

    const string& ToString() const
    {
        return buffer;
    }

    StringWrapper@ ToStringWrapper() const
    {
        return StringWrapper(buffer);
    }

    uint GetLastLineLength() const
    {
        int right = buffer.Length - 1;
        while (right != -1)
        {
            if (buffer[right--] == '\n')
                break;
        }

        int left = right;
        while (left != -1)
        {
            if (buffer[left] == '\n')
                break;

            left--;
        }

        return right - left;
    }
}


// ============================================================================
// smn_utils - Text (FormatPrecise)
// ============================================================================

string FormatPrecise(const double value, const uint precision = 12)
{
    return Text::FormatFloat(value, " ", 0, precision);
}

string FormatPrecise(const vec2 &in value, const uint precision = 12)
{
    const string x = FormatPrecise(value.x, precision);
    const string y = FormatPrecise(value.y, precision);

    string s;
    s.Resize(x.Length + 1 + y.Length);

    uint i = 0;
    for (uint j = 0; j < x.Length; j++)
        s[i++] = x[j];
    s[i++] = ' ';
    for (uint j = 0; j < y.Length; j++)
        s[i++] = y[j];

    return s;
}

string FormatPrecise(const vec3 &in value, const uint precision = 12)
{
    const string x = FormatPrecise(value.x, precision);
    const string y = FormatPrecise(value.y, precision);
    const string z = FormatPrecise(value.z, precision);

    string s;
    s.Resize(x.Length + 1 + y.Length + 1 + z.Length);

    uint i = 0;
    for (uint j = 0; j < x.Length; j++)
        s[i++] = x[j];
    s[i++] = ' ';
    for (uint j = 0; j < y.Length; j++)
        s[i++] = y[j];
    s[i++] = ' ';
    for (uint j = 0; j < z.Length; j++)
        s[i++] = z[j];

    return s;
}


// ============================================================================
// smn_utils - Global (Var wrappers, SetVariable vec3 overload)
// ============================================================================

bool GetConVarBool(const string &in name)
{
    return GetVariableBool(name);
}

int GetConVarInt(const string &in name)
{
    return int(GetVariableDouble(name));
}

ms GetConVarTime(const string &in name)
{
    return ms(GetVariableDouble(name));
}

double GetConVarDouble(const string &in name)
{
    return GetVariableDouble(name);
}

string GetConVarString(const string &in name)
{
    return GetVariableString(name);
}

vec3 GetConVarVec3(const string &in name)
{
    return Text::ParseVec3(GetVariableString(name));
}

void SetVarVec3(const string &in name, const vec3 value)
{
    ::SetVariable(name, value.ToString());
}


// ============================================================================
// smn_utils - UI (TooltipOnHover, ComboHelper with OnSelectIndex)
// ============================================================================

void TooltipOnHover(const string &in text)
{
    UI::SameLine();
    UI::TextDimmed("(i)");
    if (UI::IsItemHovered())
    {
        if (UI::BeginTooltip())
        {
            UI::Text(text);
            UI::EndTooltip();
        }
    }
}

funcdef void OnSelectIndex(const uint index);

bool ComboHelper(const string &in label, const array<string>@ names, const uint currentIndex, OnSelectIndex@ onSelect)
{
    const bool isOpen = UI::BeginCombo(label, names[currentIndex]);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, i == currentIndex))
                onSelect(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}


// ============================================================================
// common.as - Separators and LogIfWrongCount
// ============================================================================

const string ITEM_SEP = ",";
const string PAIR_SEP = ":";
const string KIND_SEP = ";";
const string VERSION_SEP = "|";

void LogIfWrongCount()
{
    if (groupNames.Length != GroupKind::COUNT)         log("groupNames has wrong Length!",     Severity::Error);
    if (scalarNames.Length != ScalarKind::COUNT)       log("scalarNames has wrong Length!",    Severity::Error);
    if (conditionNames.Length != ConditionKind::COUNT) log("conditionNames has wrong Length!", Severity::Error);
}


// ============================================================================
// common.as - Groups
// ============================================================================

enum GroupKind
{
    NONE = -1,

    POSITION,
    ROTATION,

    SPEED_GLOBAL,
    SPEED_LOCAL,

    WHEEL_FRONT_LEFT,
    WHEEL_FRONT_RIGHT,
    WHEEL_BACK_RIGHT,
    WHEEL_BACK_LEFT,

    COUNT // amount of group kinds
}

const array<string> groupNames =
{
    "Position",
    "Rotation",

    "Global Speed",
    "Local Speed",

    "Front Left Wheel",
    "Front Right Wheel",
    "Back Right Wheel",
    "Back Left Wheel"
};

class Group
{
    bool active;
}

array<Group> groups(GroupKind::COUNT);

string SerializeGroups()
{
    array<string> kinds(GroupKind::COUNT);
    for (uint i = 0; i < GroupKind::COUNT; i++)
    {
        const GroupKind groupKind = GroupKind(i);
        kinds[i] = groupNames[groupKind] + PAIR_SEP + SerializeBool(groups[groupKind].active);
    }
    return Text::Join({ "v2.0.0", Text::Join(kinds, KIND_SEP) }, VERSION_SEP);
}

void DeserializeGroups(const string &in s)
{
    array<string>@ const versioned = s.Split(VERSION_SEP);
    {
        string error;
        if (versioned.Length != 2)
        {
            error = "No version field detected";
        }
        else
        {
            const string version = versioned[0];
            if (version.IsEmpty() || version[0] != 'v')
            {
                error = "No version detected";
            }
            else
            {
                if (version != "v2.0.0")
                    error = "Unsupported version detected: " + version;
            }
        }

        if (!error.IsEmpty())
        {
            log(error + ", generating groups...");
            SaveGroups();
            return;
        }
    }

    array<string>@ const kinds = versioned[1].Split(KIND_SEP);
    for (uint i = 0; i < kinds.Length; i++)
    {
        array<string>@ const kv = kinds[i].Split(PAIR_SEP);
        if (kv.Length != 2)
        {
            log("Failed to deserialize group! Index: " + i, Severity::Error);
            continue;
        }

        const string keyString = kv[0];
        const GroupKind kind = GroupKind(groupNames.Find(keyString));
        if (kind == GroupKind::NONE)
        {
            log("Could not find this group: " + keyString, Severity::Warning);
            continue;
        }

        const string valueString = kv[1];
        bool value;
        if (!DeserializeBool(valueString, value))
        {
            log("Could not deserialize this group's value! String: " + valueString, Severity::Error);
            continue;
        }

        groups[kind].active = value;
    }
}


// ============================================================================
// common.as - Scalars
// ============================================================================

enum ScalarKind
{
    NONE = -1,

    POSITION_X, POSITION_Y, POSITION_Z,
    ROTATION_YAW, ROTATION_PITCH, ROTATION_ROLL,

    SPEED_GLOBAL_X, SPEED_GLOBAL_Y, SPEED_GLOBAL_Z,
    SPEED_LOCAL_X, SPEED_LOCAL_Y, SPEED_LOCAL_Z,

    WHEEL_FL_X, WHEEL_FL_Y, WHEEL_FL_Z,
    WHEEL_FR_X, WHEEL_FR_Y, WHEEL_FR_Z,
    WHEEL_BR_X, WHEEL_BR_Y, WHEEL_BR_Z,
    WHEEL_BL_X, WHEEL_BL_Y, WHEEL_BL_Z,

    COUNT // amount of scalar kinds
}

const array<string> scalarNames =
{
    "X Position", "Y Position", "Z Position",
    "Yaw", "Pitch", "Roll",

    "Global X Speed", "Global Y Speed", "Global Z Speed",
    "Local X Speed (Sideways)", "Local Y Speed (Upwards)", "Local Z Speed (Forwards)",

    "X Front Left Wheel", "Y Front Left Wheel", "Z Front Left Wheel",
    "X Front Right Wheel", "Y Front Right Wheel", "Z Front Right Wheel",
    "X Back Right Wheel", "Y Back Right Wheel", "Z Back Right Wheel",
    "X Back Left Wheel", "Y Back Left Wheel", "Z Back Left Wheel"
};

class Scalar
{
    bool lower, upper;
    double valueLower, valueUpper;
    float displayLower, displayUpper;

    void Reset()
    {
        lower = false;
        upper = false;
        valueLower = 0;
        valueUpper = 0;
        displayLower = 0;
        displayUpper = 0;
    }
}

array<Scalar> scalars(ScalarKind::COUNT);

string SerializeScalars()
{
    array<string> kinds(ScalarKind::COUNT);
    for (uint i = 0; i < ScalarKind::COUNT; i++)
    {
        const ScalarKind scalarKind = ScalarKind(i);
        const Scalar@ const scalar = scalars[scalarKind];
        const array<string> kind =
        {
            SerializeBool(scalar.lower),
            SerializeBool(scalar.upper),
            scalar.valueLower,
            scalar.valueUpper,
            scalar.displayLower,
            scalar.displayUpper
        };
        kinds[i] = scalarNames[scalarKind] + PAIR_SEP + Text::Join(kind, ITEM_SEP);
    }
    return Text::Join({ "v2.0.0", Text::Join(kinds, KIND_SEP) }, VERSION_SEP);
}

void DeserializeScalars(const string &in s)
{
    array<string>@ const versioned = s.Split(VERSION_SEP);
    {
        string error;
        if (versioned.Length != 2)
        {
            error = "No version field detected";
        }
        else
        {
            const string version = versioned[0];
            if (version.IsEmpty() || version[0] != 'v')
            {
                error = "No version detected";
            }
            else
            {
                if (version != "v2.0.0")
                    error = "Unsupported version detected: " + version;
            }
        }

        if (!error.IsEmpty())
        {
            log(error + ", generating scalars...");
            SaveScalars();
            return;
        }
    }

    array<string>@ const kinds = versioned[1].Split(KIND_SEP);
    for (uint i = 0; i < kinds.Length; i++)
    {
        array<string>@ const kv = kinds[i].Split(PAIR_SEP);
        if (kv.Length != 2)
        {
            log("Failed to deserialize scalar! Index: " + i, Severity::Error);
            continue;
        }

        const string keyString = kv[0];
        const ScalarKind kind = ScalarKind(scalarNames.Find(keyString));
        if (kind == ScalarKind::NONE)
        {
            log("Could not find this scalar: " + keyString, Severity::Warning);
            continue;
        }

        const string valueString = kv[1];
        array<string>@ const values = valueString.Split(ITEM_SEP);
        if (values.Length != 6)
        {
            log("Could not deserialize this scalar's values! String: " + valueString, Severity::Error);
            continue;
        }

        bool lower;
        bool upper;
        if (!(DeserializeBool(values[0], lower) && DeserializeBool(values[1], upper)))
        {
            log("Could not deserialize this scalar's flags!", Severity::Error);
            continue;
        }

        const double valueLower = Text::ParseFloat(values[2]);
        const double valueUpper = Text::ParseFloat(values[3]);

        const double displayLower = Text::ParseFloat(values[4]);
        const double displayUpper = Text::ParseFloat(values[5]);

        Scalar@ const scalar = scalars[kind];
        scalar.lower = lower;
        scalar.upper = upper;
        scalar.valueLower = valueLower;
        scalar.valueUpper = valueUpper;
        scalar.displayLower = displayLower;
        scalar.displayUpper = displayUpper;
    }
}


// ============================================================================
// common.as - Conditions
// ============================================================================

enum ConditionKind
{
    NONE = -1,

    MIN_REAL_SPEED,
    FREEWHEELING,
    SLIDING,
    WHEEL_TOUCHING,
    WHEEL_CONTACTS,

    CHECKPOINTS,

    RPM,
    GEAR,
    REAR_GEAR,

    GLITCHING,

    COUNT // amount of condition kinds
}

const array<string> conditionNames =
{
    "Minimum Real Speed",
    "Freewheeling",
    "Sliding",
    "Wheel Touching Wall",
    "Wheel Contacts",

    "Checkpoints",

    "RPM",
    "Gear",
    "Rear Gear",

    "Glitching"
};

class Condition
{
    bool active;
    double value, valueMin, valueMax;
    float display, displayMin, displayMax;

    bool MatchBool(const bool otherValue) const
    {
        return otherValue == (value != 0);
    }

    bool MatchUInt(const uint otherValue) const
    {
        return otherValue == uint(value);
    }

    bool CompareInt(const int otherValue) const
    {
        return otherValue >= int(valueMin) && otherValue <= int(valueMax);
    }

    bool CompareDouble(const double otherValue) const
    {
        return otherValue >= valueMin && otherValue <= valueMax;
    }

    void Transfer()
    {
        value = display;
    }

    void TransferRange()
    {
        valueMin = displayMin;
        valueMax = displayMax;
    }

    void Reset()
    {
        value = 0;
        valueMin = 0;
        valueMax = 0;

        display = 0;
        displayMin = 0;
        displayMax = 0;
    }
}

array<Condition> conditions(ConditionKind::COUNT);

string SerializeConditions()
{
    array<string> kinds(ConditionKind::COUNT);
    for (uint i = 0; i < ConditionKind::COUNT; i++)
    {
        const ConditionKind conditionKind = ConditionKind(i);
        const Condition@ const condition = conditions[conditionKind];
        const array<string> kind =
        {
            SerializeBool(condition.active),

            condition.value,
            condition.valueMin,
            condition.valueMax,

            condition.display,
            condition.displayMin,
            condition.displayMax
        };
        kinds[i] = conditionNames[conditionKind] + PAIR_SEP + Text::Join(kind, ITEM_SEP);
    }
    return Text::Join({ "v2.0.0", Text::Join(kinds, KIND_SEP) }, VERSION_SEP);
}

void DeserializeConditions(const string &in s)
{
    array<string>@ const versioned = s.Split(VERSION_SEP);
    {
        string error;
        if (versioned.Length != 2)
        {
            error = "No version field detected";
        }
        else
        {
            const string version = versioned[0];
            if (version.IsEmpty() || version[0] != 'v')
            {
                error = "No version detected";
            }
            else
            {
                if (version != "v2.0.0")
                    error = "Unsupported version detected: " + version;
            }
        }

        if (!error.IsEmpty())
        {
            log(error + ", generating conditions...");
            SaveConditions();
            return;
        }
    }

    array<string>@ const kinds = versioned[1].Split(KIND_SEP);
    for (uint i = 0; i < kinds.Length; i++)
    {
        array<string>@ const kv = kinds[i].Split(PAIR_SEP);
        if (kv.Length != 2)
        {
            log("Failed to deserialize condition! Index: " + i, Severity::Error);
            continue;
        }

        const string keyString = kv[0];
        const ConditionKind kind = ConditionKind(conditionNames.Find(keyString));
        if (kind == ConditionKind::NONE)
        {
            log("Could not find this condition: " + keyString, Severity::Warning);
            continue;
        }

        const string valueString = kv[1];
        array<string>@ const values = valueString.Split(ITEM_SEP);
        if (values.Length != 7)
        {
            log("Could not deserialize this condition's values! String: " + valueString, Severity::Error);
            continue;
        }

        bool active;
        if (!DeserializeBool(values[0], active))
        {
            log("Could not deserialize this condition's active field! String: " + valueString, Severity::Error);
            continue;
        }

        const double value = Text::ParseFloat(values[1]);
        const double valueMin = Text::ParseFloat(values[2]);
        const double valueMax = Text::ParseFloat(values[3]);

        const float display = Text::ParseFloat(values[4]);
        const float displayMin = Text::ParseFloat(values[5]);
        const float displayMax = Text::ParseFloat(values[6]);

        Condition@ const condition = conditions[kind];
        condition.active = active;

        condition.value = value;
        condition.valueMin = valueMin;
        condition.valueMax = valueMax;

        condition.display = display;
        condition.displayMin = displayMin;
        condition.displayMax = displayMax;
    }
}


// ============================================================================
// common.as - Misc (serialization, conversion, formatting, mapping)
// ============================================================================

string SerializeBool(const bool b)
{
    return b ? "1" : "0";
}

bool DeserializeBool(const string &in s, bool &out b)
{
    bool ok;
    if (s == "0")
    {
        b = false;
        ok = true;
    }
    else if (s == "1")
    {
        b = true;
        ok = true;
    }
    else
    {
        b = false;
        ok = false;
    }
    return ok;
}

double ConvertDisplayToValue(const ScalarKind kind, const float display)
{
    return ConvertDisplayToValue(ScalarKindToGroupKind(kind), display);
}

double ConvertDisplayToValue(const GroupKind kind, const float display)
{
    double value;
    switch (kind)
    {
    case GroupKind::ROTATION:
        value = Math::ToRad(display);
        break;
    case GroupKind::SPEED_GLOBAL:
    case GroupKind::SPEED_LOCAL:
        value = display / 3.6;
        break;
    default:
        value = display;
        break;
    }
    return value;
}

vec3 ConvertDisplayToValue3(const ScalarKind kind, const vec3 &in display)
{
    return ConvertDisplayToValue3(ScalarKindToGroupKind(kind), display);
}

vec3 ConvertDisplayToValue3(const GroupKind kind, const vec3 &in display)
{
    vec3 value;
    value.x = ConvertDisplayToValue(kind, display.x);
    value.y = ConvertDisplayToValue(kind, display.y);
    value.z = ConvertDisplayToValue(kind, display.z);
    return value;
}

float ConvertValueToDisplay(const ScalarKind kind, const double value)
{
    return ConvertValueToDisplay(ScalarKindToGroupKind(kind), value);
}

float ConvertValueToDisplay(const GroupKind kind, const double value)
{
    float display;
    switch (kind)
    {
    case GroupKind::ROTATION:
        display = Math::ToDeg(value);
        break;
    case GroupKind::SPEED_GLOBAL:
    case GroupKind::SPEED_LOCAL:
        display = value * 3.6;
        break;
    default:
        display = value;
        break;
    }
    return display;
}

vec3 ConvertValueToDisplay3(const ScalarKind kind, const vec3 &in value)
{
    return ConvertValueToDisplay3(ScalarKindToGroupKind(kind), value);
}

vec3 ConvertValueToDisplay3(const GroupKind kind, const vec3 &in value)
{
    vec3 display;
    display.x = ConvertValueToDisplay(kind, value.x);
    display.y = ConvertValueToDisplay(kind, value.y);
    display.z = ConvertValueToDisplay(kind, value.z);
    return display;
}

string FormatVec3ByTargetGroup(const vec3 &in value, const uint precision = 12)
{
    string formatted;
    if (printByComponent)
    {
        const vec3 display = ConvertValueToDisplay3(targetGroup, value);
        formatted = FormatPrecise(display, precision);
    }
    else
    {
        formatted = FormatValueByGroup(targetGroup, value.Length(), precision);
    }
    return formatted;
}

string FormatValueByTarget(const double value, const uint precision = 12)
{
    const GroupKind groupKind = isTargetGrouped ? targetGroup : ScalarKindToGroupKind(targetScalar);
    return FormatValueByGroup(groupKind, value, precision);
}

string FormatValueByGroup(const GroupKind groupKind, const double value, const uint precision = 12)
{
    return FormatPrecise(ConvertValueToDisplay(groupKind, value), precision);
}

string FormatValueByScalar(const ScalarKind scalarKind, const double value, const uint precision = 12)
{
    return FormatPrecise(ConvertValueToDisplay(scalarKind, value), precision);
}

array<ScalarKind>@ GroupKindToScalarKinds(const GroupKind groupKind)
{
    array<ScalarKind> scalarKinds;
    switch (groupKind)
    {
    case POSITION:
        scalarKinds =
        {
            ScalarKind::POSITION_X,
            ScalarKind::POSITION_Y,
            ScalarKind::POSITION_Z
        };
        break;
    case ROTATION:
        scalarKinds =
        {
            ScalarKind::ROTATION_YAW,
            ScalarKind::ROTATION_PITCH,
            ScalarKind::ROTATION_ROLL
        };
        break;
    case SPEED_GLOBAL:
        scalarKinds =
        {
            ScalarKind::SPEED_GLOBAL_X,
            ScalarKind::SPEED_GLOBAL_Y,
            ScalarKind::SPEED_GLOBAL_Z
        };
        break;
    case SPEED_LOCAL:
        scalarKinds =
        {
            ScalarKind::SPEED_LOCAL_X,
            ScalarKind::SPEED_LOCAL_Y,
            ScalarKind::SPEED_LOCAL_Z
        };
        break;
    case WHEEL_FRONT_LEFT:
        scalarKinds =
        {
            ScalarKind::WHEEL_FL_X,
            ScalarKind::WHEEL_FL_Y,
            ScalarKind::WHEEL_FL_Z
        };
        break;
    case WHEEL_FRONT_RIGHT:
        scalarKinds =
        {
            ScalarKind::WHEEL_FR_X,
            ScalarKind::WHEEL_FR_Y,
            ScalarKind::WHEEL_FR_Z
        };
        break;
    case WHEEL_BACK_RIGHT:
        scalarKinds =
        {
            ScalarKind::WHEEL_BR_X,
            ScalarKind::WHEEL_BR_Y,
            ScalarKind::WHEEL_BR_Z
        };
        break;
    case WHEEL_BACK_LEFT:
        scalarKinds =
        {
            ScalarKind::WHEEL_BL_X,
            ScalarKind::WHEEL_BL_Y,
            ScalarKind::WHEEL_BL_Z
        };
        break;
    }
    return scalarKinds;
}

GroupKind ScalarKindToGroupKind(const ScalarKind scalarKind)
{
    GroupKind groupKind;
    switch (scalarKind)
    {
    case POSITION_X:
    case POSITION_Y:
    case POSITION_Z:
        groupKind = GroupKind::POSITION;
        break;
    case ROTATION_YAW:
    case ROTATION_PITCH:
    case ROTATION_ROLL:
        groupKind = GroupKind::ROTATION;
        break;
    case SPEED_GLOBAL_X:
    case SPEED_GLOBAL_Y:
    case SPEED_GLOBAL_Z:
        groupKind = GroupKind::SPEED_GLOBAL;
        break;
    case SPEED_LOCAL_X:
    case SPEED_LOCAL_Y:
    case SPEED_LOCAL_Z:
        groupKind = GroupKind::SPEED_LOCAL;
        break;
    case WHEEL_FL_X:
    case WHEEL_FL_Y:
    case WHEEL_FL_Z:
        groupKind = GroupKind::WHEEL_FRONT_LEFT;
        break;
    case WHEEL_FR_X:
    case WHEEL_FR_Y:
    case WHEEL_FR_Z:
        groupKind = GroupKind::WHEEL_FRONT_RIGHT;
        break;
    case WHEEL_BR_X:
    case WHEEL_BR_Y:
    case WHEEL_BR_Z:
        groupKind = GroupKind::WHEEL_BACK_RIGHT;
        break;
    case WHEEL_BL_X:
    case WHEEL_BL_Y:
    case WHEEL_BL_Z:
        groupKind = GroupKind::WHEEL_BACK_LEFT;
        break;
    default:
        groupKind = GroupKind::NONE;
        break;
    }
    return groupKind;
}


// ============================================================================
// settings.as - Variables and Registration
// ============================================================================

const string ID = "finetuner";
const string VAR = ID + "_";

const string VAR_EVAL_FROM = VAR + "eval_from";
const string VAR_EVAL_TO   = VAR + "eval_to";

const string VAR_TARGET_GROUPED = VAR + "target_grouped";
const string VAR_TARGET_SCALAR  = VAR + "target_scalar";
const string VAR_TARGET_GROUP   = VAR + "target_group";
const string VAR_TARGET_TOWARDS = VAR + "target_towards";

const string VAR_TARGET_VALUE         = VAR + "target_value";
const string VAR_TARGET_VALUE_DISPLAY = VAR + "target_value_display";

const string VAR_TARGET_VEC3         = VAR + "target_vec3";
const string VAR_TARGET_VEC3_DISPLAY = VAR + "target_vec3_display";

const string VAR_PRINT_BY_COMPONENT = VAR + "print_by_component";

const string VAR_COMMON_GROUPS     = VAR + "common_groups";
const string VAR_COMMON_SCALARS    = VAR + "common_scalars";
const string VAR_COMMON_CONDITIONS = VAR + "common_conditions";

ms evalFrom;
ms evalTo;

bool isTargetGrouped;
GroupKind targetGroup;
ScalarKind targetScalar;
int targetTowards;

double targetValue;
float targetValueDisplay;

vec3 targetVec3;
vec3 targetVec3Display;

bool printByComponent;

void RegisterSettings()
{
    RegisterVariable(VAR_EVAL_FROM, 0);
    RegisterVariable(VAR_EVAL_TO,   0);

    RegisterVariable(VAR_TARGET_GROUPED, true);
    RegisterVariable(VAR_TARGET_SCALAR,  0);
    RegisterVariable(VAR_TARGET_GROUP,   0);
    RegisterVariable(VAR_TARGET_TOWARDS, 0);

    RegisterVariable(VAR_TARGET_VALUE,           0);
    RegisterVariable(VAR_TARGET_VALUE_DISPLAY,   0);

    RegisterVariable(VAR_TARGET_VEC3,         vec3().ToString());
    RegisterVariable(VAR_TARGET_VEC3_DISPLAY, vec3().ToString());

    RegisterVariable(VAR_PRINT_BY_COMPONENT, false);

    RegisterVariable(VAR_COMMON_GROUPS,     "");
    RegisterVariable(VAR_COMMON_SCALARS,    "");
    RegisterVariable(VAR_COMMON_CONDITIONS, "");

    evalFrom = GetConVarTime(VAR_EVAL_FROM);
    evalTo   = GetConVarTime(VAR_EVAL_TO);

    isTargetGrouped = GetConVarBool(VAR_TARGET_GROUPED);
    targetScalar    = ScalarKind(GetVariableDouble(VAR_TARGET_SCALAR));
    targetGroup     = GroupKind(GetVariableDouble(VAR_TARGET_GROUP));
    targetTowards   = GetConVarInt(VAR_TARGET_TOWARDS);

    targetValue        = GetConVarDouble(VAR_TARGET_VALUE);
    targetValueDisplay = GetConVarDouble(VAR_TARGET_VALUE_DISPLAY);

    targetVec3        = GetConVarVec3(VAR_TARGET_VEC3);
    targetVec3Display = GetConVarVec3(VAR_TARGET_VEC3_DISPLAY);

    printByComponent = GetConVarBool(VAR_PRINT_BY_COMPONENT);

    DeserializeGroups(    GetConVarString(VAR_COMMON_GROUPS));
    DeserializeScalars(   GetConVarString(VAR_COMMON_SCALARS));
    DeserializeConditions(GetConVarString(VAR_COMMON_CONDITIONS));
}

void SaveSettings()
{
    SaveGroups();
    SaveScalars();
    SaveConditions();
}

void SaveGroups()
{
    SetVariable(VAR_COMMON_GROUPS, SerializeGroups());
}

void SaveScalars()
{
    SetVariable(VAR_COMMON_SCALARS, SerializeScalars());
}

void SaveConditions()
{
    SetVariable(VAR_COMMON_CONDITIONS, SerializeConditions());
}


// ============================================================================
// settings.as - RenderSettings (UI)
// ============================================================================

const string HIDDEN_EDITOR_LABEL = "<Hide>";

int triggerPosEditorID = -1;
int triggerPosEditorIndex = -1;

GroupKind groupInEditor = GroupKind::NONE;
ConditionKind conditionInEditor = ConditionKind::NONE;

void RenderSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From", VAR_EVAL_FROM);
    evalTo   = UI::InputTimeVar("Evaluate To",   VAR_EVAL_TO);
    if (evalTo < evalFrom)
        SetVariable(VAR_EVAL_TO, evalTo = evalFrom);

    isTargetGrouped = UI::CheckboxVar("Grouped Target?", VAR_TARGET_GROUPED);
    if (isTargetGrouped)
    {
        ComboHelper("Target (Group):", groupNames, targetGroup,
            function(index)
            {
                targetGroup = GroupKind(index);
                SetVariable(VAR_TARGET_GROUP, targetGroup);
            }
        );

        if (targetGroup == GroupKind::ROTATION)
            UI::TextDimmed("WARNING: using grouped rotation is not recommended.");
    }
    else
    {
        ComboHelper("Target (Scalar):", scalarNames, targetScalar,
            function(index)
            {
                targetScalar = ScalarKind(index);
                SetVariable(VAR_TARGET_SCALAR, targetScalar);
            }
        );
    }

    targetTowards = UI::SliderIntVar("Target Towards", VAR_TARGET_TOWARDS, -1, 1);

    {
        bool disableTarget;
        string targetTowardsMessage;
        switch (targetTowards)
        {
        case -1:
            disableTarget = true;
            targetTowardsMessage = "Lower value is better.";
            break;
        case 1:
            disableTarget = true;
            targetTowardsMessage = "Higher value is better.";
            break;
        default:
            disableTarget = false;
            targetTowardsMessage = "Custom:";
            break;
        }
        UI::TextDimmed(targetTowardsMessage);

        UI::BeginDisabled(disableTarget);
        if (isTargetGrouped)
        {
            if (UI::DragFloat3Var("Target Values", VAR_TARGET_VEC3_DISPLAY))
            {
                targetVec3Display = GetConVarVec3(VAR_TARGET_VEC3_DISPLAY);
                targetVec3 = ConvertDisplayToValue3(targetGroup, targetVec3Display);
                SetVarVec3(VAR_TARGET_VEC3, targetVec3);
            }
        }
        else
        {
            targetValueDisplay = UI::InputFloatVar("Target Value", VAR_TARGET_VALUE_DISPLAY);
            targetValue = ConvertDisplayToValue(targetScalar, targetValueDisplay);
            SetVariable(VAR_TARGET_VALUE, targetValue);
        }
        UI::EndDisabled();
    }

    if (isTargetGrouped)
    {
        printByComponent = UI::CheckboxVar("Print Group values by component?", VAR_PRINT_BY_COMPONENT);
        TooltipOnHover("Whether the values of the target group are to be printed by component (e.g. x y z), or as one value.");

        if (targetGroup == GroupKind::POSITION)
        {
            vec3 cameraPosition;
            if (CameraPosOnClick("Use Cam Position", cameraPosition))
                SetTargetVec3(cameraPosition);
            UI::SameLine();
            vec3 carPosition;
            if (CarPosOnClick("Use Car Position", carPosition))
                SetTargetVec3(carPosition);
        }
    }

    UI::Separator();
    UI::Separator();

    {
        const bool isHiddenGroupInEditor = groupInEditor == GroupKind::NONE;
        const string currentGroup =
            isHiddenGroupInEditor ? HIDDEN_EDITOR_LABEL : groupNames[groupInEditor];
        if (UI::BeginCombo("Group Editor", currentGroup))
        {
            UI::PushID("group_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenGroupInEditor))
                groupInEditor = GroupKind::NONE;

            for (uint i = 0; i < GroupKind::COUNT; i++)
            {
                const GroupKind kind = GroupKind(i);
                UI::PushID("" + i);

                Group@ const group = groups[kind];
                group.active = UI::Checkbox("##active", group.active);
                UI::SameLine();
                if (UI::Selectable(groupNames[kind], groupInEditor == kind))
                    groupInEditor = kind;

                UI::PopID();
            }

            UI::PopID();
            UI::EndCombo();
        }
    }

    if (groupInEditor != GroupKind::NONE)
    {
        UI::PushID("group_in_editor_" + groupInEditor);

        Group@ const group = groups[groupInEditor];
        group.active = UI::Checkbox("Active", group.active);

        const bool resetAll = UI::Button("Reset All");
        UI::SameLine();
        const bool toggleAll = UI::Button("Toggle All");
        UI::SameLine();
        const bool activateAll = UI::Button("Activate All");

        const auto@ const scalarsToRender = GroupKindToScalarKinds(groupInEditor);
        if (groupInEditor == GroupKind::POSITION)
        {
            TriggerCombo(triggerPosEditorID, triggerPosEditorIndex);

            Trigger3D trigger;
            if (GetTriggerOrReset(triggerPosEditorID, triggerPosEditorIndex, trigger))
            {
                const vec3 position = trigger.Position;
                const vec3 size = trigger.Size;
                for (uint i = 0; i < 3; i++)
                {
                    Scalar@ const scalar = scalars[scalarsToRender[i]];
                    scalar.valueLower = position[i];
                    scalar.valueUpper = position[i] + size[i];
                    scalar.displayLower = scalar.valueLower;
                    scalar.displayUpper = scalar.valueUpper;
                }
            }

            vec3 cameraPosition;
            if (CameraPosOnClick("Use Cam Position", cameraPosition))
            {
                ResetTriggerID(triggerPosEditorID, triggerPosEditorIndex);
                BoundScalarsByVec3(scalarsToRender, cameraPosition);
            }
            UI::SameLine();
            vec3 carPosition;
            if (CarPosOnClick("Use Car Position", carPosition))
            {
                ResetTriggerID(triggerPosEditorID, triggerPosEditorIndex);
                BoundScalarsByVec3(scalarsToRender, carPosition);
            }
        }

        for (uint i = 0; i < scalarsToRender.Length; i++)
        {
            const ScalarKind scalarKind = scalarsToRender[i];
            UI::PushID("" + i);

            UI::Separator();

            Scalar@ const scalar = scalars[scalarKind];
            if (UI::Button("Reset") || resetAll)
                scalar.Reset();
            UI::SameLine();
            UI::TextWrapped("Scalar: " + scalarNames[scalarKind]);

            scalar.lower = UI::Checkbox("Lower Bound", scalar.lower) || activateAll;
            UI::SameLine();
            scalar.upper = UI::Checkbox("Upper Bound", scalar.upper) || activateAll;

            if (toggleAll)
            {
                scalar.lower = !scalar.lower;
                scalar.upper = !scalar.upper;
            }

            UI::PushItemWidth(192);
            UI::BeginDisabled(!scalar.lower);

            scalar.displayLower = UI::InputFloat("##lower", scalar.displayLower);
            if (scalar.lower)
                scalar.valueLower = ConvertDisplayToValue(groupInEditor, scalar.displayLower);

            UI::EndDisabled();
            UI::SameLine();
            UI::BeginDisabled(!scalar.upper);

            scalar.displayUpper = UI::InputFloat("##upper", scalar.displayUpper);
            if (scalar.upper)
                scalar.valueUpper = ConvertDisplayToValue(groupInEditor, scalar.displayUpper);

            UI::EndDisabled();
            UI::PopItemWidth();

            UI::PopID();
        }

        UI::PopID();
    }

    UI::Separator();
    UI::Separator();

    {
        const bool isHiddenConditionInEditor = conditionInEditor == ConditionKind::NONE;
        const string currentCondition =
            isHiddenConditionInEditor ? HIDDEN_EDITOR_LABEL : conditionNames[conditionInEditor];
        if (UI::BeginCombo("Condition Editor", currentCondition))
        {
            UI::PushID("condition_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenConditionInEditor))
                conditionInEditor = ConditionKind::NONE;

            for (uint i = 0; i < ConditionKind::COUNT; i++)
            {
                const ConditionKind kind = ConditionKind(i);
                UI::PushID("" + i);

                Condition@ const condition = conditions[kind];
                condition.active = UI::Checkbox("##active", condition.active);
                UI::SameLine();
                if (UI::Selectable(conditionNames[kind], conditionInEditor == kind))
                    conditionInEditor = kind;

                UI::PopID();
            }

            UI::PopID();
            UI::EndCombo();
        }
    }

    if (conditionInEditor != ConditionKind::NONE)
    {
        UI::PushID("condition_in_editor_" + conditionInEditor);

        Condition@ const condition = conditions[conditionInEditor];
        condition.active = UI::Checkbox("Active", condition.active);

        if (UI::Button("Reset"))
            condition.Reset();

        switch (conditionInEditor)
        {
        case ConditionKind::MIN_REAL_SPEED:
            condition.display = UI::InputFloat("##min_real_speed", condition.display);
            {
                StringBuilder builder;
                builder.Append("The car MUST have a real speed of at least ");
                builder.Append(condition.display);
                builder.Append(" km/h in the eval timeframe.");
                UI::TextDimmed(builder.ToString());
            }
            condition.value = condition.display / 3.6;
            break;
        case ConditionKind::FREEWHEELING:
            RenderConditionCheckbox(condition, "##freewheeling", "be free-wheeled");
            break;
        case ConditionKind::SLIDING:
            RenderConditionCheckbox(condition, "##sliding", "be sliding");
            break;
        case ConditionKind::WHEEL_TOUCHING:
            RenderConditionCheckbox(condition, "##wheel_touching", "have wheel(s) crashing into a wall");
            break;
        case ConditionKind::WHEEL_CONTACTS:
            RenderConditionSliderInts(condition, "##wheel_contacts", 0, 4, "wheels contacting the ground");
            break;
        case ConditionKind::CHECKPOINTS:
            RenderConditionInputInt(condition, "##checkpoints", "checkpoints");
            break;
        case ConditionKind::RPM:
            RenderConditionInputFloats(condition, "##rpm", "RPM");
            break;
        case ConditionKind::GEAR:
            RenderConditionSliderInts(condition, "##gear", 0, 5, "gears");
            break;
        case ConditionKind::REAR_GEAR:
            RenderConditionSliderInts(condition, "##rear_gear", 0, 1, "rear gears");
            break;
        case ConditionKind::GLITCHING:
            RenderConditionCheckbox(condition, "##glitching", "be glitching");
            break;
        default:
            UI::TextWrapped("Corrupted condition index: " + conditionInEditor);
            break;
        }

        UI::PopID();
    }

    SaveSettings();
}

bool CameraPosOnClick(const string &in label, vec3 &out position)
{
    if (UI::Button(label))
    {
        const auto@ const camera = GetCurrentCamera();
        if (camera !is null)
        {
            position = camera.Location.Position;
            return true;
        }
    }

    position = vec3();
    return false;
}

bool CarPosOnClick(const string &in label, vec3 &out position)
{
    if (UI::Button(label))
    {
        const auto@ const dyna = GetSimulationManager().Dyna;
        if (dyna !is null)
        {
            position = dyna.RefStateCurrent.Location.Position;
            return true;
        }
    }

    position = vec3();
    return false;
}

void SetTargetVec3(const vec3 &in value)
{
    targetVec3 = value;
    SetVarVec3(VAR_TARGET_VEC3, targetVec3);
    targetVec3Display = value;
    SetVarVec3(VAR_TARGET_VEC3_DISPLAY, targetVec3Display);
}

void TriggerCombo(int& id, int& index)
{
    if (UI::BeginCombo("Triggers", (index + 1) + "."))
    {
        if (UI::Selectable("0.", id == -1))
            ResetTriggerID(id, index);

        const auto@ const ids = GetTriggerIds();
        for (uint i = 0; i < ids.Length; i++)
        {
            const int triggerID = ids[i];
            const Trigger3D trigger = GetTrigger(triggerID);
            if (UI::Selectable((i + 1) + ". " + TriggerToString(trigger), id == triggerID))
            {
                id = triggerID;
                index = i;
            }
        }

        UI::EndCombo();
    }
}

string TriggerToString(const Trigger3D &in trigger)
{
    return "[ " + trigger.Position.ToString() + " | " + trigger.Size.ToString() + " ]";
}

bool GetTriggerOrReset(int& id, int& index, Trigger3D &out trigger)
{
    trigger = GetTrigger(id);
    if (trigger)
        return true;

    ResetTriggerID(id, index);
    return false;
}

void ResetTriggerID(int& id, int& index)
{
    id = -1;
    index = -1;
}

void BoundScalarsByVec3(const array<ScalarKind>@ scalarKinds, const vec3 &in v, const double offset = 2)
{
    if (scalarKinds.Length != 3)
    {
        UI::TextWrapped("ERROR: cannot bound scalars by vec3.");
        return;
    }

    for (uint i = 0; i < 3; i++)
    {
        const ScalarKind kind = scalarKinds[i];
        Scalar@ const scalar = scalars[kind];
        scalar.lower = true;
        scalar.upper = true;
        scalar.valueLower = v[i] - offset;
        scalar.valueUpper = v[i] + offset;
        scalar.displayLower = ConvertValueToDisplay(kind, scalar.valueLower);
        scalar.displayUpper = ConvertValueToDisplay(kind, scalar.valueUpper);
    }
}

void RenderConditionCheckbox(Condition@ condition, const string &in id, const string &in what)
{
    const bool tempValue = UI::Checkbox(id, condition.display != 0);
    condition.display = tempValue ? 1 : 0;

    StringBuilder builder;
    builder.Append("The car MUST");
    builder.Append(tempValue ? " " : " NOT ");
    builder.Append(what);
    builder.Append(" in the eval timeframe.");
    UI::TextDimmed(builder.ToString());

    condition.Transfer();
}

void RenderConditionInputInt(Condition@ condition, const string &in id, const string &in what)
{
    condition.display = UI::InputInt(id, int(condition.display));

    StringBuilder builder;
    builder.Append("The car MUST have exactly ");
    builder.Append(condition.display);
    builder.Append(" ");
    builder.Append(what);
    builder.Append(" in the eval timeframe.");
    UI::TextDimmed(builder.ToString());

    condition.Transfer();
}

void RenderConditionInputFloats(Condition@ condition, const string &in id, const string &in what)
{
    const float inputMin = UI::InputFloat(id + "_min", condition.displayMin);
    const float inputMax = UI::InputFloat(id + "_max", condition.displayMax);
    condition.displayMin = Math::Min(inputMin, inputMax);
    condition.displayMax = Math::Max(inputMin, inputMax);

    StringBuilder builder;
    BuildRangeText(builder, condition, what);
    UI::TextDimmed(builder.ToString());

    condition.TransferRange();
}

void RenderConditionSliderInts(Condition@ condition, const string &in id, const int min, const int max, const string &in what)
{
    const int sliderMin = UI::SliderInt(id + "_min", int(condition.displayMin), min, max);
    const int sliderMax = UI::SliderInt(id + "_max", int(condition.displayMax), min, max);
    condition.displayMin = Math::Min(sliderMin, sliderMax);
    condition.displayMax = Math::Max(sliderMin, sliderMax);

    StringBuilder builder;
    BuildRangeText(builder, condition, what);
    UI::TextDimmed(builder.ToString());

    condition.TransferRange();
}

void BuildRangeText(StringBuilder@ builder, const Condition@ condition, const string &in what)
{
    const bool inexact = condition.displayMin != condition.displayMax;
    builder.Append("The car MUST have ");
    builder.Append(inexact ? "between " : "exactly ");
    builder.Append(condition.displayMin);
    if (inexact)
    {
        builder.Append(" and ");
        builder.Append(condition.displayMax);
    }
    builder.Append(" ");
    builder.Append(what);
    builder.Append(" in the eval timeframe.");
}


// ============================================================================
// main.as - State variables
// ============================================================================

bool customTargetTowards;

bool valid;
ms impTime;

double diffCurrent;
double diffBest;

double current;
vec3   current3;
double best;
vec3   best3;

funcdef bool IsBetterTargeted(SimulationManager@ simManager);
const IsBetterTargeted@ isBetter;

funcdef bool IsBetterTargetedTowards();
const IsBetterTargetedTowards@ isBetterTowards;

bool met;

array<ScalarKind> scalarIndices;
array<ScalarKind> unmetScalarIndices;
array<ms>         unmetScalarTimes;

array<ConditionKind> conditionIndices;
array<ConditionKind> unmetConditionIndices;
array<ms>            unmetConditionTimes;


// ============================================================================
// Main - BfV2 entry point
// ============================================================================

void Main()
{
    LogIfWrongCount();
    RegisterSettings();
    auto eval = RegisterBruteforceEval("finetuner", "Finetuner", OnEvaluate, RenderSettings);
    @eval.onSimBegin = @OnSimBegin;
    @eval.onSimEnd = @OnSimEnd;
}


// ============================================================================
// OnSimBegin - extracted from OnSimulationBegin (guard removed)
// ============================================================================

void OnSimBegin(SimulationManager@)
{
    customTargetTowards = targetTowards == 0;
    if (isTargetGrouped)
    {
        switch (targetTowards)
        {
        case -1:
            @isBetterTowards =
                function()
                {
                    return current3.Length() < best3.Length();
                };
            break;
        case 0:
            @isBetterTowards =
                function()
                {
                    diffCurrent = Math::Distance(current3, targetVec3);
                    return diffCurrent < diffBest;
                };
            break;
        case 1:
            @isBetterTowards =
                function()
                {
                    return current3.Length() > best3.Length();
                };
            break;
        default:
            @isBetterTowards = function() { return false; };
            print("Bug with targetTowards...", Severity::Error);
            break;
        }

        @isBetter =
            function(simManager)
            {
                current3 = GetGroupValue(simManager, targetGroup);
                return isBetterTowards();
            };
    }
    else
    {
        switch (targetTowards)
        {
        case -1:
            @isBetterTowards =
                function()
                {
                    return current < best;
                };
            break;
        case 0:
            @isBetterTowards =
                function()
                {
                    const double diff = current - targetValue;
                    switch (targetScalar)
                    {
                    case ScalarKind::ROTATION_YAW:
                    case ScalarKind::ROTATION_PITCH:
                    case ScalarKind::ROTATION_ROLL:
                        diffCurrent = Math::Min(Math::Abs(diff), Math::Abs(diff + Math::PI * 2));
                        break;
                    default:
                        diffCurrent = Math::Abs(diff);
                        break;
                    }
                    return diffCurrent < diffBest;
                };
            break;
        case 1:
            @isBetterTowards =
                function()
                {
                    return current > best;
                };
            break;
        default:
            @isBetterTowards = function() { return false; };
            print("Bug with targetTowards...", Severity::Error);
            break;
        }

        @isBetter =
            function(simManager)
            {
                current = GetScalarValue(simManager, targetScalar);
                return isBetterTowards();
            };
    }

    for (uint g = 0; g < GroupKind::COUNT; g++)
    {
        const GroupKind groupKind = GroupKind(g);
        if (!groups[groupKind].active)
            continue;

        const auto@ const tempScalarKinds = GroupKindToScalarKinds(groupKind);
        for (uint k = 0; k < tempScalarKinds.Length; k++)
        {
            const ScalarKind scalarKind = tempScalarKinds[k];
            const Scalar@ const scalar = scalars[scalarKind];
            if (scalar.lower || scalar.upper)
                scalarIndices.Add(scalarKind);
        }
    }

    for (uint c = 0; c < ConditionKind::COUNT; c++)
    {
        const ConditionKind kind = ConditionKind(c);
        if (conditions[kind].active)
            conditionIndices.Add(kind);
    }

    StringBuilder builder;
    builder
        .AppendLine()
        .AppendLine("=========")
        .AppendLine("Finetuner")
        .AppendLine("=========")
        .AppendLine();

    {
        builder.AppendLine("Target:");
        if (isTargetGrouped)
        {
            builder.AppendLine({ "Group = ", groupNames[targetGroup] });
            if (customTargetTowards)
                builder.AppendLine({ "Values = ", FormatPrecise(targetVec3) });
        }
        else
        {
            builder.AppendLine({ "Scalar = ", scalarNames[targetScalar] });
            if (customTargetTowards)
                builder.AppendLine({ "Value = ", FormatPrecise(targetValue) });
        }

        builder.Append("Towards = ");
        switch (targetTowards)
        {
        case -1:
            builder.AppendLine("Lower value is better.");
            break;
        case 0:
            builder.AppendLine("Custom.");
            break;
        case 1:
            builder.AppendLine("Higher value is better.");
            break;
        default:
            builder.AppendLine(targetTowards);
            break;
        }

        builder
            .AppendLine(Repeat(builder.GetLastLineLength(), '-'))
            .AppendLine();
    }

    {
        builder.AppendLine("Bounds: (actual values, so angles in radians and speeds in m/s)");
        uint maxScalarNameLength = 0;
        if (scalarIndices.IsEmpty())
        {
            const string NO_SCALARS = "None.";
            builder.AppendLine(NO_SCALARS);
            maxScalarNameLength = NO_SCALARS.Length;
        }
        else
        {
            for (uint i = 0; i < scalarIndices.Length; i++)
            {
                const uint len = scalarNames[scalarIndices[i]].Length;
                if (maxScalarNameLength < len)
                    maxScalarNameLength = len;
            }

            for (uint i = 0; i < scalarIndices.Length; i++)
            {
                const ScalarKind kind = scalarIndices[i];
                const Scalar@ const scalar = scalars[kind];
                builder.Append({ PadRight(scalarNames[kind], maxScalarNameLength), " => " });

                if (scalar.lower)
                    builder.Append({ "Lower: ", FormatPrecise(scalar.valueLower) });

                if (scalar.lower && scalar.upper)
                    builder.Append(", ");

                if (scalar.upper)
                    builder.Append({ "Upper: ", FormatPrecise(scalar.valueUpper) });

                builder.AppendLine();
            }
        }

        builder
            .AppendLine(Repeat(maxScalarNameLength, '-'))
            .AppendLine();
    }

    {
        builder.AppendLine("Conditions: (actual values)");
        uint maxConditionNameLength = 0;
        if (conditionIndices.IsEmpty())
        {
            const string NO_CONDITIONS = "None.";
            builder.AppendLine(NO_CONDITIONS);
            maxConditionNameLength = NO_CONDITIONS.Length;
        }
        else
        {
            for (uint i = 0; i < conditionIndices.Length; i++)
            {
                const uint len = conditionNames[conditionIndices[i]].Length;
                if (maxConditionNameLength < len)
                    maxConditionNameLength = len;
            }

            for (uint i = 0; i < conditionIndices.Length; i++)
            {
                const ConditionKind kind = conditionIndices[i];
                const Condition@ const condition = conditions[kind];
                builder.Append({ PadRight(conditionNames[kind], maxConditionNameLength), " => " });
                switch (kind)
                {
                case ConditionKind::WHEEL_CONTACTS:
                case ConditionKind::GEAR:
                case ConditionKind::REAR_GEAR:
                    if (condition.valueMin == condition.valueMax)
                        builder.AppendLine(condition.valueMin);
                    else
                        builder.AppendLine({ "[", condition.valueMin, ", ", condition.valueMax, "]" });
                    break;
                default:
                    builder.AppendLine(condition.value);
                    break;
                }
            }
        }

        builder
            .AppendLine(Repeat(maxConditionNameLength, '-'))
            .AppendLine();
    }

    print(builder.ToString());
}


// ============================================================================
// OnSimEnd - extracted from OnSimulationEnd (guard removed)
// ============================================================================

void OnSimEnd(SimulationManager@, SimulationResult)
{
    valid = false;
    met = false;

    scalarIndices.Clear();
    unmetScalarIndices.Clear();
    unmetScalarTimes.Clear();

    conditionIndices.Clear();
    unmetConditionIndices.Clear();
    unmetConditionTimes.Clear();
}


// ============================================================================
// main.as - OnEvaluate (evaluation logic, kept exactly as-is)
// ============================================================================

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    auto response = BFEvaluationResponse();

    const ms time = simManager.RaceTime;
    switch (info.Phase)
    {
    case BFPhase::Initial:
        if (IsEvalTime(time))
        {
            if (IsBetter(simManager))
            {
                valid = true;
                impTime = time;

                best = current;
                best3 = current3;
                diffBest = diffCurrent;
            }
        }
        else if (IsPastEvalTime(time))
        {
            met = true; // prevent memory leak in unmet* arrays

            StringBuilder builder;
            Severity severity;
            if (valid)
            {
                if (isTargetGrouped)
                    builder.Append({ groupNames[targetGroup], " | ", FormatVec3ByTargetGroup(best3, 6) });
                else
                    builder.Append({ scalarNames[targetScalar], " | ", FormatValueByScalar(targetScalar, best, 6) });

                builder.Append({ " | Time: ", Time::Format(impTime) });

                if (customTargetTowards)
                    builder.Append({ " | Diff: ", FormatValueByTarget(diffBest) });

                const uint iterations = info.Iterations;
                if (iterations == 0)
                {
                    severity = Severity::Info;
                }
                else
                {
                    builder.Append({ " | Iterations: ", iterations });
                    severity = Severity::Success;
                }
            }
            else
            {
                builder.AppendLine("Base Run did not suffice...");

                const uint unmetConditionLength = unmetConditionIndices.Length;
                if (unmetConditionLength != 0)
                {
                    builder.AppendLine().AppendLine("Unmet conditions:");
                    for (uint i = 0; i < unmetConditionLength; i++)
                        builder.AppendLine({ unmetConditionTimes[i], " ", conditionNames[unmetConditionIndices[i]] });
                }

                const uint unmetScalarLength = unmetScalarIndices.Length;
                if (unmetScalarLength != 0)
                {
                    builder.AppendLine().AppendLine("Unmet scalars:");
                    for (uint i = 0; i < unmetScalarLength; i++)
                        builder.AppendLine({ unmetScalarTimes[i], " ", scalarNames[unmetScalarIndices[i]] });
                }

                severity = Severity::Warning;
            }

            print(builder.ToString(), severity);
            response.Decision = BFEvaluationDecision::Accept;
        }
        break;
    case BFPhase::Search:
        if (IsEvalTime(time))
        {
            if (IsBetter(simManager))
                response.Decision = BFEvaluationDecision::Accept;
        }
        else if (IsPastEvalTime(time))
        {
            response.Decision = BFEvaluationDecision::Reject;
        }
        break;
    }

    return response;
}


// ============================================================================
// main.as - Evaluation helpers (kept exactly as-is)
// ============================================================================

bool IsEvalTime(const ms time)
{
    return time >= evalFrom && time <= evalTo;
}

bool IsPastEvalTime(const ms time)
{
    return time > evalTo;
}

bool IsBetter(SimulationManager@ simManager)
{
    const auto@ const dyna = simManager.Dyna;
    const auto@ const currentState = dyna.RefStateCurrent;
    const auto@ const previousState = dyna.RefStatePrevious;
    const double velocity = currentState.LinearSpeed.Length();

    const auto@ const svc = simManager.SceneVehicleCar;
    const auto@ const engine = svc.CarEngine;

    const auto@ const playerInfo = simManager.PlayerInfo;

    const ms time = simManager.RaceTime;
    for (uint i = 0; i < conditionIndices.Length; i++)
    {
        const ConditionKind kind = conditionIndices[i];
        const Condition@ const condition = conditions[kind];
        bool ok;
        switch (kind)
        {
        case ConditionKind::MIN_REAL_SPEED:
            ok = velocity >= condition.value;
            break;
        case ConditionKind::FREEWHEELING:
            ok = condition.MatchBool(svc.IsFreeWheeling);
            break;
        case ConditionKind::SLIDING:
            ok = condition.MatchBool(svc.IsSliding);
            break;
        case ConditionKind::WHEEL_TOUCHING:
            ok = condition.MatchBool(svc.HasAnyLateralContact);
            break;
        case ConditionKind::WHEEL_CONTACTS:
            {
                int contacts = 0;
                const auto@ const wheels = simManager.Wheels;
                for (uint w = 0; w < 4; w++)
                {
                    if (wheels[w].RTState.HasGroundContact)
                        contacts++;
                }

                ok = condition.CompareInt(contacts);
            }
            break;
        case ConditionKind::CHECKPOINTS:
            ok = condition.MatchUInt(playerInfo.CurCheckpointCount);
            break;
        case ConditionKind::RPM:
            ok = condition.CompareDouble(engine.ActualRPM);
            break;
        case ConditionKind::GEAR:
            ok = condition.CompareInt(engine.Gear);
            break;
        case ConditionKind::REAR_GEAR:
            ok = condition.CompareInt(engine.RearGear);
            break;
        case ConditionKind::GLITCHING:
            {
                const double positionalDifference = Math::Distance(
                    previousState.Location.Position,
                    currentState.Location.Position);
                const bool isGlitching = positionalDifference > 0.1 && velocity / positionalDifference < 50.0;
                ok = condition.MatchBool(isGlitching);
            }
            break;
        default:
            print("Corrupted condition index: " + kind, Severity::Error);
            ok = false;
            break;
        }

        if (!ok)
        {
            if (!met)
            {
                unmetConditionIndices.Add(kind);
                unmetConditionTimes.Add(time);
            }
            return false;
        }
    }

    for (uint i = 0; i < scalarIndices.Length; i++)
    {
        const ScalarKind kind = scalarIndices[i];
        const double value = GetScalarValue(simManager, kind);

        const Scalar@ const scalar = scalars[kind];
        if (scalar.lower && value < scalar.valueLower || scalar.upper && value > scalar.valueUpper)
        {
            if (!met)
            {
                unmetScalarIndices.Add(kind);
                unmetScalarTimes.Add(time);
            }
            return false;
        }
    }

    return isBetter(simManager) || !valid;
}


// ============================================================================
// main.as - GetGroupValue, GetScalarValue, AddOffsetToLocation (kept exactly as-is)
// ============================================================================

vec3 GetGroupValue(SimulationManager@ simManager, const GroupKind kind)
{
    vec3 value;

    const auto@ const dyna = simManager.Dyna.RefStateCurrent;
    const iso4 location = dyna.Location;
    mat3 rotation = location.Rotation;

    const auto@ const svc = simManager.SceneVehicleCar;

    const auto@ const wheels = simManager.Wheels;

    switch (kind)
    {
    case GroupKind::POSITION:
        value = location.Position;
        break;
    case GroupKind::ROTATION:
        rotation.GetYawPitchRoll(value.x, value.y, value.z);
        break;
    case GroupKind::SPEED_GLOBAL:
        value = dyna.LinearSpeed;
        break;
    case GroupKind::SPEED_LOCAL:
        value = svc.CurrentLocalSpeed;
        break;
    case GroupKind::WHEEL_FRONT_LEFT:
        value = AddOffsetToLocation(wheels.FrontLeft,  location);
        break;
    case GroupKind::WHEEL_FRONT_RIGHT:
        value = AddOffsetToLocation(wheels.FrontRight, location);
        break;
    case GroupKind::WHEEL_BACK_RIGHT:
        value = AddOffsetToLocation(wheels.BackRight,  location);
        break;
    case GroupKind::WHEEL_BACK_LEFT:
        value = AddOffsetToLocation(wheels.BackLeft,   location);
        break;
    default:
        print("Corrupted group index: " + kind, Severity::Error);
        break;
    }

    return value;
}

double GetScalarValue(SimulationManager@ simManager, const ScalarKind kind)
{
    double value = 0;

    const auto@ const dyna = simManager.Dyna.RefStateCurrent;
    const iso4 location = dyna.Location;
    const vec3 position = location.Position;
    mat3 rotation = location.Rotation;
    const vec3 globalSpeed = dyna.LinearSpeed;

    const auto@ const svc = simManager.SceneVehicleCar;
    const vec3 localSpeed = svc.CurrentLocalSpeed;

    const auto@ const wheels = simManager.Wheels;

    switch (kind)
    {
    case ScalarKind::POSITION_X:
        value = position.x;
        break;
    case ScalarKind::POSITION_Y:
        value = position.y;
        break;
    case ScalarKind::POSITION_Z:
        value = position.z;
        break;
    case ScalarKind::ROTATION_YAW:
        { float y, _p, _r; rotation.GetYawPitchRoll(y, _p, _r); value = y; }
        break;
    case ScalarKind::ROTATION_PITCH:
        { float _y, p, _r; rotation.GetYawPitchRoll(_y, p, _r); value = p; }
        break;
    case ScalarKind::ROTATION_ROLL:
        { float _y, _p, r; rotation.GetYawPitchRoll(_y, _p, r); value = r; }
        break;
    case ScalarKind::SPEED_GLOBAL_X:
        value = globalSpeed.x;
        break;
    case ScalarKind::SPEED_GLOBAL_Y:
        value = globalSpeed.y;
        break;
    case ScalarKind::SPEED_GLOBAL_Z:
        value = globalSpeed.z;
        break;
    case ScalarKind::SPEED_LOCAL_X:
        value = localSpeed.x;
        break;
    case ScalarKind::SPEED_LOCAL_Y:
        value = localSpeed.y;
        break;
    case ScalarKind::SPEED_LOCAL_Z:
        value = localSpeed.z;
        break;
    case ScalarKind::WHEEL_FL_X:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).x;
        break;
    case ScalarKind::WHEEL_FL_Y:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).y;
        break;
    case ScalarKind::WHEEL_FL_Z:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).z;
        break;
    case ScalarKind::WHEEL_FR_X:
        value = AddOffsetToLocation(wheels.FrontRight, location).x;
        break;
    case ScalarKind::WHEEL_FR_Y:
        value = AddOffsetToLocation(wheels.FrontRight, location).y;
        break;
    case ScalarKind::WHEEL_FR_Z:
        value = AddOffsetToLocation(wheels.FrontRight, location).z;
        break;
    case ScalarKind::WHEEL_BR_X:
        value = AddOffsetToLocation(wheels.BackRight,  location).x;
        break;
    case ScalarKind::WHEEL_BR_Y:
        value = AddOffsetToLocation(wheels.BackRight,  location).y;
        break;
    case ScalarKind::WHEEL_BR_Z:
        value = AddOffsetToLocation(wheels.BackRight,  location).z;
        break;
    case ScalarKind::WHEEL_BL_X:
        value = AddOffsetToLocation(wheels.BackLeft,   location).x;
        break;
    case ScalarKind::WHEEL_BL_Y:
        value = AddOffsetToLocation(wheels.BackLeft,   location).y;
        break;
    case ScalarKind::WHEEL_BL_Z:
        value = AddOffsetToLocation(wheels.BackLeft,   location).z;
        break;
    default:
        print("Corrupted scalar index: " + kind, Severity::Error);
        break;
    }

    return value;
}

vec3 AddOffsetToLocation(TM::SceneVehicleCar::SimulationWheel@ wheel, const iso4 &in location)
{
    const vec3 offset = wheel.SurfaceHandler.Location.Position;
    const mat3 rot = location.Rotation;
    const vec3 global = vec3(Math::Dot(offset, rot.x), Math::Dot(offset, rot.y), Math::Dot(offset, rot.z));
    return location.Position + global;
}

} // namespace FinetunerBf
