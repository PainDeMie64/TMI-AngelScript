namespace PreciseFinish
{
    bool IsEstimating = false;
    uint64 CoeffMin = 0;
    uint64 CoeffMax = 18446744073709551615;
    SimulationState @StateBeforeHit;
    SimulationState @StateAtHit;
    int StateBeforeHitTime = -1;
    int StateAtHitTime = -1;
    bool done = false;
    double localResult = -1;
    uint Precision = 1;
    void Reset()
    {
        IsEstimating = false;
        CoeffMin = 0;
        CoeffMax = 18446744073709551615;
        @StateBeforeHit = null;
        @StateAtHit = null;
        StateAtHitTime = -1;
        StateBeforeHitTime = -1;
        localResult = -1;
        done = false;
    }
    bool Compute(SimulationManager @sim, bool targetReached, double &out result)
    {
        if (done)
        {
            result = localResult;
            return true;
        }
        if (!IsEstimating)
        {
            if (targetReached)
            {
                IsEstimating = true;
                @StateAtHit = sim.SaveState();
                StateAtHitTime = sim.RaceTime;
                CoeffMin = 0;
                CoeffMax = 18446744073709551615;
                if (StateBeforeHit is null)
                {
                    result = double(sim.RaceTime) / 1000.0;
                    return true;
                }
            }
            else
            {
                @StateBeforeHit = sim.SaveState();
                StateBeforeHitTime = sim.RaceTime;
                return false;
            }
        }
        else
        {
            if (targetReached)
            {
                CoeffMax = CoeffMin + (CoeffMax - CoeffMin) / 2;
            }
            else
            {
                CoeffMin = CoeffMin + (CoeffMax - CoeffMin) / 2;
            }
        }
        if (CoeffMax - CoeffMin <= Precision)
        {
            IsEstimating = false;
            uint64 currentCoeff = CoeffMin + (CoeffMax - CoeffMin) / 2;
            double currentCoeffPercentage = double(currentCoeff) / 18446744073709551615.0;
            result = (double(StateBeforeHitTime) / 1000.0) + (currentCoeffPercentage * 0.01);
            if (StateAtHit !is null)
            {
                sim.RewindToState(StateAtHit);
            }
            else if (StateBeforeHit !is null)
            {
                sim.RewindToState(StateBeforeHit);
            }
            localResult = result;
            @StateBeforeHit = null;
            @StateAtHit = null;
            done = true;
            return true;
        }
        sim.RewindToState(StateBeforeHit);
        uint64 currentCoeff = CoeffMin + (CoeffMax - CoeffMin) / 2;
        double currentCoeffPercentage = double(currentCoeff) / 18446744073709551615.0;
        sim.Dyna.CurrentState.LinearSpeed = sim.Dyna.CurrentState.LinearSpeed * currentCoeffPercentage;
        sim.Dyna.CurrentState.AngularSpeed = sim.Dyna.CurrentState.AngularSpeed * currentCoeffPercentage;
        return false;
    }
}
