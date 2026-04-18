namespace InputModification
{
    int cachedStartIndex = -1;
    int cachedMinTime = -1;
    int g_earliestMutationTime = 2147483647;
    void SortBufferManual(TM::InputEventBuffer @buffer, int startIndex = -1)
    {
        if (buffer is null || buffer.Length < 2)
            return;
        uint startCopy = 0;
        if (startIndex != -1)
        {
            startCopy = startIndex + 1;
        }
        if (startCopy >= buffer.Length)
            return;
        array<TM::InputEvent> events;
        for (uint i = startCopy; i < buffer.Length; i++)
        {
            events.Add(buffer[i]);
        }
        for (uint i = 1; i < events.Length; i++)
        {
            TM::InputEvent key = events[i];
            int j = i - 1;
            while (j >= 0 && events[j].Time > key.Time)
            {
                events[j + 1] = events[j];
                j--;
            }
            events[j + 1] = key;
        }
        for (uint i = 0; i < events.Length; i++)
        {
            buffer[startCopy + i] = events[i];
        }
    }
    void MutateInputs(TM::InputEventBuffer @buffer, int inputCount, int minTime, int maxTime, int maxSteerDiff, int maxTimeDiff, bool fillInputs)
    { 
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs)
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        int actualInputCount = Math::Rand(1, inputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                cachedStartIndex = i;
                continue;
            }
            indices.Add(i);
            if (int(evt.Time) - 100010 > maxTime)
                break;
        }
        if (indices.Length == 0)
        {
            print("No inputs found in the specified time frame to modify.", Severity::Warning);
            return;
        }
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(-maxTimeDiff / 10, maxTimeDiff / 10) * 10;
            int steerOffset = Math::Rand(-maxSteerDiff, maxSteerDiff);
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (evt.Value.EventIndex == buffer.EventIndices.SteerId)
            {
                evt.Value.Analog = evt.Value.Analog + steerOffset;
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
    void MutateInputsRange(TM::InputEventBuffer @buffer, int minInputCount, int maxInputCount, int minTime, int maxTime, int minSteer, int maxSteer, int minTimeDiff, int maxTimeDiff, bool fillInputs)
    { 
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs)
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        if (minInputCount > maxInputCount)
        {
            int tmp = minInputCount;
            minInputCount = maxInputCount;
            maxInputCount = tmp;
        }
        if (minInputCount < 1) minInputCount = 1;
        int actualInputCount = Math::Rand(minInputCount, maxInputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                cachedStartIndex = i;
                continue;
            }
            indices.Add(i);
            if (int(evt.Time) - 100010 > maxTime)
                break;
        }
        if (indices.Length == 0)
        {
            print("No inputs found in the specified time frame to modify.", Severity::Warning);
            return;
        }
        if (minTimeDiff > maxTimeDiff)
        {
            int tmp = minTimeDiff;
            minTimeDiff = maxTimeDiff;
            maxTimeDiff = tmp;
        }
        if (minSteer > maxSteer)
        {
            int tmp = minSteer;
            minSteer = maxSteer;
            maxSteer = tmp;
        }
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(minTimeDiff / 10, maxTimeDiff / 10) * 10;
            int newSteerValue = Math::Rand(minSteer, maxSteer);
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (evt.Value.EventIndex == buffer.EventIndices.SteerId)
            {
                evt.Value.Analog = newSteerValue;
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
    void FillInputs(TM::InputEventBuffer @buffer, int maxTime, int minIndex)
    {
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        const int OFFSET = 100010;
        int absMaxTime = OFFSET + maxTime;
        auto indices = buffer.EventIndices;
        array<TM::InputEvent> steer;
        int startIndex = 0;
        int prevSteerState = 0;
        int prevSteerTime = -1;
        bool hasPrevSteer = true;
        if (minIndex > 0 && minIndex < int(buffer.Length))
        {
            startIndex = minIndex;
            for (int i = minIndex - 1; i >= 0; i--)
            {
                if (buffer[i].Value.EventIndex == indices.SteerId)
                {
                    prevSteerState = int(buffer[i].Value.Analog);
                    prevSteerTime = int(buffer[i].Time);
                    break;
                }
            }
        }
        for (uint i = startIndex; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) > absMaxTime)
                break;
            if (evt.Value.EventIndex == indices.SteerId)
            {
                steer.Add(evt);
            }
        }
        uint k = 0;
        const uint steerLen = steer.Length;
        int loopStartTime = 0;
        if (startIndex > 0 && startIndex < int(buffer.Length))
        {
            loopStartTime = int(buffer[startIndex].Time) - OFFSET;
            loopStartTime = (loopStartTime / 10) * 10;
            if (loopStartTime < 0)
                loopStartTime = 0;
        }
        for (int t = loopStartTime; t <= maxTime; t += 10)
        {
            int absT = t + OFFSET;
            bool hadSteerAtT = false;
            while (k < steerLen && int(steer[k].Time) <= absT)
            {
                if (int(steer[k].Time) == absT)
                {
                    hadSteerAtT = true;
                }
                prevSteerState = int(steer[k].Value.Analog);
                prevSteerTime = int(steer[k].Time);
                hasPrevSteer = true;
                k++;
            }
            if (!hadSteerAtT && hasPrevSteer && absT > prevSteerTime)
            {
                buffer.Add(t, InputType::Steer, prevSteerState);
            }
        }
    }
    void MutateInputsByType(TM::InputEventBuffer @buffer, int eventTypeId, int inputCount, int minTime, int maxTime, int maxSteerDiff, int maxTimeDiff, bool fillInputs, bool isBinaryInput)
    {
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs && eventTypeId == int(buffer.EventIndices.SteerId))
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        int actualInputCount = Math::Rand(1, inputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                if (cachedStartIndex < int(i))
                    cachedStartIndex = int(i);
                continue;
            }
            if (int(evt.Time) - 100010 > maxTime)
                break;
            if (int(evt.Value.EventIndex) == eventTypeId)
            {
                indices.Add(i);
            }
        }
        if (indices.Length == 0)
            return;
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(-maxTimeDiff / 10, maxTimeDiff / 10) * 10;
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (isBinaryInput)
            {
                evt.Value.Analog = (evt.Value.Analog == 0) ? 1 : 0;
            }
            else
            {
                int steerOffset = Math::Rand(-maxSteerDiff, maxSteerDiff);
                evt.Value.Analog = evt.Value.Analog + steerOffset;
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
    void MutateInputsRangeByType(TM::InputEventBuffer @buffer, int eventTypeId, int minInputCount, int maxInputCount, int minTime, int maxTime, int minSteer, int maxSteer, int minTimeDiff, int maxTimeDiff, bool fillInputs, bool isBinaryInput)
    {
        if (buffer is null)
            return;
        if (maxTime <= 0)
            return;
        if (fillInputs && eventTypeId == int(buffer.EventIndices.SteerId))
        {
            uint lenBefore = buffer.Length;
            FillInputs(buffer, maxTime, cachedStartIndex);
            if (buffer.Length != lenBefore)
                cachedStartIndex = -1;
        }
        if (minTime != cachedMinTime)
        {
            cachedMinTime = minTime;
            cachedStartIndex = -1;
        }
        if (minInputCount > maxInputCount)
        {
            int tmp = minInputCount;
            minInputCount = maxInputCount;
            maxInputCount = tmp;
        }
        if (minInputCount < 1) minInputCount = 1;
        int actualInputCount = Math::Rand(minInputCount, maxInputCount);
        array<int> indices;
        uint start = 0;
        if (cachedStartIndex != -1 && cachedStartIndex < int(buffer.Length))
        {
            start = cachedStartIndex;
        }
        for (uint i = start; i < buffer.Length; i++)
        {
            auto evt = buffer[i];
            if (int(evt.Time) - 100010 < minTime)
            {
                if (cachedStartIndex < int(i))
                    cachedStartIndex = int(i);
                continue;
            }
            if (int(evt.Time) - 100010 > maxTime)
                break;
            if (int(evt.Value.EventIndex) == eventTypeId)
            {
                indices.Add(i);
            }
        }
        if (indices.Length == 0)
            return;
        if (minTimeDiff > maxTimeDiff)
        {
            int tmp = minTimeDiff;
            minTimeDiff = maxTimeDiff;
            maxTimeDiff = tmp;
        }
        if (minSteer > maxSteer)
        {
            int tmp = minSteer;
            minSteer = maxSteer;
            maxSteer = tmp;
        }
        for (int i = 0; i < actualInputCount; i++)
        {
            int timeOffset = Math::Rand(minTimeDiff / 10, maxTimeDiff / 10) * 10;
            int inputIdx = indices[Math::Rand(0, indices.Length - 1)];
            auto evt = buffer[inputIdx];
            evt.Time += timeOffset;
            if (evt.Time < 100010)
            {
                evt.Time = 100010;
            }
            if (int(evt.Time) - 100010 < minTime)
            {
                evt.Time = 100010 + minTime;
            }
            if (int(evt.Time) - 100010 > maxTime)
            {
                evt.Time = 100010 + maxTime;
            }
            if (isBinaryInput)
            {
                evt.Value.Analog = (evt.Value.Analog == 0) ? 1 : 0;
            }
            else
            {
                evt.Value.Analog = Math::Rand(minSteer, maxSteer);
                if (evt.Value.Analog < -65536)
                {
                    evt.Value.Analog = -65536;
                }
                if (evt.Value.Analog > 65536)
                {
                    evt.Value.Analog = 65536;
                }
            }
            int origRaceTime = int(buffer[inputIdx].Time) - 100010;
            int newRaceTime = int(evt.Time) - 100010;
            g_earliestMutationTime = Math::Min(g_earliestMutationTime, Math::Min(origRaceTime, newRaceTime));
            buffer[inputIdx] = evt;
        }
        SortBufferManual(buffer, cachedStartIndex);
    }
}
