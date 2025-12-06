array<TimedState> states;

bool hasCommandList = false;
bool se = false;              

uint lastIndex = 0;
int lastTime = -2540;
int time = 0;
uint lastInputEventsLength = 0;

void OnRunStep(SimulationManager@ simManager)
{
    lastTime = time;

    if (!hasCommandList || states.Length == 0) {
        return;
    }

    time = simManager.RaceTime;

    if (time <= lastTime) {
        lastIndex = 0;
        se = false;
        lastInputEventsLength = simManager.InputEvents.Length;
        SetVariable("execute_commands", true);
    }

    if (time < 10 || se || lastIndex + 1 >= states.Length) {
        return;
    }

    if (time - lastTime > 10) {
        for (uint i = lastIndex; i < states.Length - 1; i++) {
            if (states[i].time < time) {
                lastIndex = i;
            } else {
                break;
            }
        }
    }

    if (states[lastIndex + 1].time <= time - 10) {
        lastIndex++;
    }

    InputState inputState = simManager.GetInputState();

    uint respawnPressed = 0;
    auto@ events = simManager.InputEvents;
    auto indices = events.EventIndices;

    for (uint i = lastInputEventsLength; i < events.Length; i++) {
        auto evt = events[i];
        if (evt.Value.EventIndex == indices.RespawnId && evt.Value.Binary) {
            respawnPressed = 1;
            break;
        }
    }
    lastInputEventsLength = events.Length;

    TimedState currentState = TimedState(
        time,
        inputState.Up ? 1 : 0,
        inputState.Down ? 1 : 0,
        inputState.Steer,
        inputState.Left ? 1 : 0,
        inputState.Right ? 1 : 0,
        respawnPressed
    );

    if (states[lastIndex].equals(currentState)) {
        return;
    }

    SetVariable("execute_commands", false);
    se = true;
}

void OnCommandListChanged(CommandList@ prev, CommandList@ current, CommandListChangeReason reason)
{
    if (reason == CommandListChangeReason::Unload) {
        states.Clear();
        hasCommandList = false;
        se = false;
        lastIndex = 0;
        lastInputEventsLength = 0;

        SetVariable("execute_commands", true);
        return;
    }

    if (reason != CommandListChangeReason::Load &&
        reason != CommandListChangeReason::InternalReload &&
        reason != CommandListChangeReason::ExternalReload) {
        return;
    }

    if (current is null) {
        states.Clear();
        hasCommandList = false;
        se = false;
        lastIndex = 0;
        lastInputEventsLength = 0;
        SetVariable("execute_commands", true);
        return;
    }

    current.Process(CommandListProcessOption::OnlyParse);

    states.Clear();

    TimedState lastState = TimedState(0, 0, 0, 0, 0, 0, 0);
    auto@ cmds = current.InputCommands;

    if (cmds is null || cmds.Length == 0) {
        states.Add(lastState);
    } else {
        for (uint i = 0; i < cmds.Length; i++) {
            auto cmd = cmds[i];

            if (cmd.Timestamp != lastState.time) {
                states.Add(lastState);
                lastState = TimedState(
                    cmd.Timestamp,
                    lastState.accel,
                    lastState.brake,
                    lastState.steer,
                    lastState.left,
                    lastState.right,
                    lastState.respawn
                );
            }

            switch (cmd.Type) {
                case InputType::Up:
                    lastState.accel = cmd.State;
                    break;
                case InputType::Down:
                    lastState.brake = cmd.State;
                    break;
                case InputType::Left:
                    lastState.left = cmd.State;
                    break;
                case InputType::Right:
                    lastState.right = cmd.State;
                    break;
                case InputType::Steer:
                    lastState.steer = cmd.State;
                    break;
                case InputType::Respawn:
                    lastState.respawn = cmd.State;
                    break;
            }
        }

        states.Add(lastState);
    }

    hasCommandList = true;
    se = false;
    lastIndex = 0;
    lastTime = -2540;
    time = 0;

    SimulationManager@ sim = GetSimulationManager();
    if (sim !is null) {
        lastInputEventsLength = sim.InputEvents.Length;
    } else {
        lastInputEventsLength = 0;
    }

    SetVariable("execute_commands", true);
}

class TimedState {
    int time;
    uint accel;
    uint brake;
    int steer;
    uint left;
    uint right;
    uint respawn;

    TimedState(int time, uint accel, uint brake, int steer, uint left, uint right, uint respawn){
        this.time = time;
        this.accel = accel;
        this.brake = brake;
        this.steer = steer;
        this.left = left;
        this.right = right;
        this.respawn = respawn;
    }

    TimedState(){}

    bool equals(TimedState other){
        return this.accel == other.accel
            && this.brake == other.brake
            && this.steer == other.steer
            && this.left == other.left
            && this.right == other.right
            && this.respawn == other.respawn;
    }

    string opImplConv() const{
        return "Time: " + time
            + " Accel: " + accel
            + " Brake: " + brake
            + " Steer: " + steer
            + " Left: " + left
            + " Right: " + right
            + " Respawn: " + respawn;
    }
}

void Main()
{

    SetVariable("execute_commands", true);
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Race Control";
    info.Author = "Skycrafter";
    info.Version = "v1.2.0";
    info.Description = "As soon as a key is pressed during the race, stop executing input commands";
    return info;
}
void OnGameStateChanged(TM::GameState state)
{

    if ((int(state) & int(TM::GameState::LocalRace)) != 0)
    {
        SetVariable("execute_commands", true);
        se = false;

        SimulationManager@ sim = GetSimulationManager();
        if (sim !is null) {
            lastInputEventsLength = sim.InputEvents.Length;
        } else {
            lastInputEventsLength = 0;
        }
    }
}

