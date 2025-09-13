BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    auto resp = BFEvaluationResponse();
    if (info.Phase!=BFPhase::Initial) resp.Decision = BFEvaluationDecision::Reject;
    return resp;
}
void Main() {
    RegisterBruteforceEvaluation("fastbf", "Fast BF (and nothing else)", OnEvaluate, null);
}
PluginInfo@ GetPluginInfo() {
    auto info = PluginInfo();
    info.Name = "Fast BF";
    info.Author = "Skycrafter";
    info.Version = "1.0.0";
    info.Description = "Vrooom.";
    return info;
}