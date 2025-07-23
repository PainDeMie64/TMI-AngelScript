void OnSimulationBegin(SimulationManager@ s){
    print("[BugHelper] Using random_seed: "+int(GetVariableDouble("random_seed"))+" in simulation/bruteforce.");
}
void OnSimulationEnd(SimulationManager@ s,SimulationResult result){
    print("[BugHelper] Simulation/bruteforce used random_seed: "+int(GetVariableDouble("random_seed"))+".");
}
void OnGameStateChanged(TM::GameState state){
    if(state==TM::GameState::LocalReplay){
        uint64 time=Time::get_Now()%4294967295;
        SetVariable("random_seed",time);
        log("[BugHelper] Random seed set to: "+time);
    }
}
PluginInfo@ GetPluginInfo(){
    auto info=PluginInfo();
    info.Name="Bug Helper";
    info.Author="Skycrafter";
    info.Version="1.0.0";
    info.Description="Make bugs easily reproducible by setting and printing the random_seed.";
    return info;
}
