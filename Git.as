const string ROOT = "git/";

PluginInfo@ GetPluginInfo() {
    PluginInfo@ info = PluginInfo();
    info.Author = "Skycrafter";
    info.Name = "Git-like Helper";
    info.Description = "Helper to handle inputs easier.";
    info.Version = "1.0";
    return info;
}

string Full(const string &in rel) { return ROOT + rel; }

bool Write(const string &in rel, const string &in text) {
    CommandList f;
    f.Content = text;
    return f.Save(Full(rel));
}

string Read(const string &in rel) {
    try {
        CommandList@ f = CommandList(Full(rel)); 
        return f.Content;
    } catch {
        return "";
    }
}

bool Append(const string &in rel, const string &in text) {
    string prev = Read(rel);
    CommandList f;
    f.Content = prev + text;
    return f.Save(Full(rel));
}

void Main() {
    Git::Init();

}

void OnDisabled() {}

namespace Git {

    const string CURRENT = "current.txt";   
    const string BACKUPS = "backups/";      
    const string BRANCH_FILE = "branch.txt";
    const string BRANCHES_INDEX = "branches/index.txt";

    CommandList@ current = null;       
    bool dirty = false;                
    int lastLoadedId = 0;              
    string lastLoadedMsg = "";         
    bool internalLoading = false;      
    string currentBranch = "main";  

    string uiCommitMsg = "";
    int uiLogCount = 10;
    string uiNewBranchName = "";

    int uiSelectedCommitId = 0;
    string uiSelectedCommitLabel = "";

    const float kInputWidth = 260.0f;

    void CollectBranches(array<string> &out outBranches) {
        outBranches.Resize(0);

        if (!Exists(BRANCHES_INDEX)) {
            Write(BRANCHES_INDEX, "");
            AddBranchToIndexIfMissing(currentBranch);
        }

        string cur = Read(BRANCHES_INDEX);
        if (cur.Length == 0) {
            outBranches.Add(currentBranch);
            return;
        }

        uint start = 0;
        for (uint i = 0; i <= cur.Length; i++) {
            bool eol = (i == cur.Length) || (cur[i] == '\n');
            if (!eol) continue;

            string name = "";
            for (uint j = start; j < i; j++) {
                string ch = "";
                ch.Resize(1);
                ch[0] = cur[j];
                name += ch;
            }
            start = i + 1;

            name = Trim(name);
            if (name.Length == 0) continue;
            outBranches.Add(name);
        }

        bool foundCurrent = false;
        for (uint i = 0; i < outBranches.Length; i++) {
            if (outBranches[i] == currentBranch) {
                foundCurrent = true;
                break;
            }
        }
        if (!foundCurrent) outBranches.Add(currentBranch);
    }

    void CollectCommits(array<int> &out outIds, array<string> &out outLabels) {
        outIds.Resize(0);
        outLabels.Resize(0);

        string idx = Read(BranchDir() + "index.txt");
        if (idx.Length == 0) return;

        array<uint> starts;
        starts.Add(0);
        for (uint i = 0; i < idx.Length; i++) {
            if (idx[i] == '\n')
                starts.Add(i + 1);
        }

        for (uint si = 0; si < starts.Length; si++) {
            uint start = starts[si];
            if (start >= idx.Length) continue;

            string line = "";
            for (uint j = start; j < idx.Length && idx[j] != '\n'; j++) {
                string ch = "";
                ch.Resize(1);
                ch[0] = idx[j];
                line += ch;
            }
            if (line.Length == 0) continue;

            int bar = -1;
            for (uint k = 0; k < line.Length; k++) {
                if (line[k] == '|') {
                    bar = int(k);
                    break;
                }
            }
            if (bar < 0) continue;

            string idStr = "";
            for (int k = 0; k < bar; k++) {
                string ch = "";
                ch.Resize(1);
                ch[0] = line[k];
                idStr += ch;
            }

            string msg = "";
            for (uint k = uint(bar + 1); k < line.Length; k++) {
                string ch = "";
                ch.Resize(1);
                ch[0] = line[k];
                msg += ch;
            }

            int id = Text::ParseInt(idStr);
            if (id <= 0 || msg.Length == 0) continue;

            outIds.Add(id);
            outLabels.Add(Text::FormatInt(id) + " | " + msg);
        }
    }

    string BranchDirFor(const string &in name) { return "branches/" + name + "/"; }
    string BranchDir() { return BranchDirFor(currentBranch); }

    bool Exists(const string &in relPath) {
        try { CommandList@ _ = CommandList(ROOT + relPath); return true; }
        catch { return false; }
    }

    void SaveBranch() { Write(BRANCH_FILE, currentBranch); }
    void LoadBranch() {
        string s = Read(BRANCH_FILE);
        if (s.Length > 0) currentBranch = s;
        else { currentBranch = "main"; SaveBranch(); }
        EnsureBranchExists(currentBranch);
    }

    void EnsureBranchExists(const string &in name) {

        string dir = BranchDirFor(name);
        if (!Exists(dir + "index.txt")) { Write(dir + "index.txt", ""); }
        if (!Exists(dir + "next.txt"))  { Write(dir + "next.txt", "1"); }

        if (!Exists(BRANCHES_INDEX)) { Write(BRANCHES_INDEX, ""); }
        AddBranchToIndexIfMissing(name);
    }

    bool BranchExists(const string &in name) {
        return Exists(BranchDirFor(name) + "index.txt");
    }

    void AddBranchToIndexIfMissing(const string &in name) {
        string cur = Read(BRANCHES_INDEX);
        bool found = false;

        uint start = 0;
        for (uint i = 0; i <= cur.Length; i++) {
            bool eol = (i == cur.Length) || (cur[i] == '\n');
            if (eol) {

                string line = "";
                for (uint j = start; j < i; j++) { string ch=""; ch.Resize(1); ch[0]=cur[j]; line += ch; }
                if (line == name) { found = true; break; }
                start = i + 1;
            }
        }

        if (!found) {
            Append(BRANCHES_INDEX, (cur.Length > 0 && cur[cur.Length-1] != '\n' ? "\n" : "") + name + "\n");
        }
    }

    int ReadNextId() {
        string t = Read(BranchDir() + "next.txt");
        if (t.Length == 0) return 1;
        int n = Text::ParseInt(t);
        return n <= 0 ? 1 : n;
    }
    void WriteNextId(int nextId) {
        Write(BranchDir() + "next.txt", Text::FormatInt(nextId));
    }

    string GetMessageById(int id) {
        string idx = Read(BranchDir() + "index.txt");
        if (idx.Length == 0) return "";

        array<uint> starts; starts.Add(0);
        for (uint i = 0; i < idx.Length; i++) if (idx[i] == '\n') starts.Add(i + 1);

        for (uint si = 0; si < starts.Length; si++) {
            uint start = starts[si];
            if (start >= idx.Length) continue;

            string line = "";
            for (uint j = start; j < idx.Length && idx[j] != '\n'; j++) { string ch=""; ch.Resize(1); ch[0]=idx[j]; line += ch; }
            if (line.Length == 0) continue;

            int bar = -1;
            for (uint k = 0; k < line.Length; k++) { if (line[k] == '|') { bar = int(k); break; } }
            if (bar < 0) continue;

            string idStr = "";
            for (int k = 0; k < bar; k++) { string ch=""; ch.Resize(1); ch[0]=line[k]; idStr += ch; }
            if (Text::ParseInt(idStr) == id) {
                string msg = "";
                for (uint k = uint(bar + 1); k < line.Length; k++) { string ch=""; ch.Resize(1); ch[0]=line[k]; msg += ch; }
                return msg;
            }
        }
        return "";
    }

    bool BackupCurrentIfDirty() {
        if (!dirty) return true;

        string body = Read(CURRENT);
        string base = (lastLoadedMsg.Length > 0) ? lastLoadedMsg : "current";

        int i = 1;
        while (true) {
            string candidate = BACKUPS + base + "-edited(" + Text::FormatInt(i) + ").txt";
            if (!Exists(candidate)) {
                if (!Write(candidate, body)) {
                    log("[git] failed to write backup: " + candidate, Severity::Error);
                    return false;
                }
                log("[git] backup saved: " + candidate, Severity::Info);
                break;
            }
            i++;
        }
        return true;
    }

    string SubFrom(const string &in s, uint start) {
        string r = ""; for (uint i = start; i < s.Length; i++) { string ch=""; ch.Resize(1); ch[0]=s[i]; r += ch; } return r;
    }
    string Trim(const string &in s) {
        uint a=0,b=s.Length; while(a<b&&(s[a]==' '||s[a]=='\t'))a++; while(b>a&&(s[b-1]==' '||s[b-1]=='\t'))b--;
        string r=""; for(uint i=a;i<b;i++){ string ch=""; ch.Resize(1); ch[0]=s[i]; r+=ch; } return r;
    }
    string Unquote(const string &in s) {
        if (s.Length>=2 && s[0]=='"' && s[s.Length-1]=='"'){ string r=""; for(uint i=1;i+1<s.Length;i++){ string ch=""; ch.Resize(1); ch[0]=s[i]; r+=ch;} return r; }
        return s;
    }
    string JoinArgs(const array<string> &in args, uint start) {
        string r=""; for(uint i=start;i<args.Length;i++){ if(i>start) r+=" "; r+=args[i]; } return r;
    }

    bool Commit(const string &in message) {
        EnsureBranchExists(currentBranch);

        int id = ReadNextId();
        string body = (current !is null) ? current.Content : "";

        string dir = BranchDir();
        if (!Write(dir + Text::FormatInt(id) + ".txt", body)) return false;

        Append(dir + "index.txt", Text::FormatInt(id) + "|" + message + "\n");
        WriteNextId(id + 1);

        log("[git] [" + currentBranch + "] commit " + Text::FormatInt(id) + ": " + message, Severity::Info);
        return true;
    }

    int FindLastIdByMessage(const string &in message) {
        string idx = Read(BranchDir() + "index.txt");
        if (idx.Length == 0) return 0;

        array<uint> starts; starts.Add(0);
        for (uint i = 0; i < idx.Length; i++) if (idx[i] == '\n') starts.Add(i + 1);

        for (int si = int(starts.Length) - 1; si >= 0; si--) {
            uint start = starts[si];
            if (start >= idx.Length) continue;

            string line=""; for(uint j=start; j<idx.Length && idx[j] != '\n'; j++){ string ch=""; ch.Resize(1); ch[0]=idx[j]; line+=ch; }
            if (line.Length == 0) continue;

            int bar=-1; for(uint k=0;k<line.Length;k++){ if(line[k]=='|'){ bar=int(k); break; } }
            if (bar < 0) continue;

            string idStr=""; for(int k=0;k<bar;k++){ string ch=""; ch.Resize(1); ch[0]=line[k]; idStr+=ch; }
            string msg=""; for(uint k=uint(bar+1); k<line.Length; k++){ string ch=""; ch.Resize(1); ch[0]=line[k]; msg+=ch; }

            if (msg == message) {
                int id = Text::ParseInt(idStr);
                if (id > 0) return id;
            }
        }
        return 0;
    }

    bool LoadById(int id) {
        if (id <= 0) return false;

        string dir = BranchDir();
        string commitPath = dir + Text::FormatInt(id) + ".txt";
        string body = Read(commitPath);
        if (body.Length == 0) {
            log("[git] [" + currentBranch + "] commit " + Text::FormatInt(id) + " is empty or missing", Severity::Error);
            return false;
        }

        if (!BackupCurrentIfDirty()) return false;

        if (!Write(CURRENT, body)) {
            log("[git] failed to update " + CURRENT, Severity::Error);
            return false;
        }

        string msg = GetMessageById(id);
        try {
            CommandList@ list = CommandList(ROOT + CURRENT);
            internalLoading = true;
            SetCurrentCommandList(list);
            lastLoadedId = id;
            lastLoadedMsg = msg;
            log("[git] [" + currentBranch + "] loaded " + Text::FormatInt(id) + " into " + CURRENT, Severity::Info);
            return true;
        } catch {
            internalLoading = false;
            log("[git] failed to load " + CURRENT, Severity::Error);
            return false;
        }
    }

    bool Load(const string &in key) {

        bool numeric = key.Length > 0;
        for (uint i = 0; i < key.Length; i++) { uint8 c = key[i]; if (c < '0' || c > '9') { numeric = false; break; } }
        if (numeric) return LoadById(Text::ParseInt(key));

        int id = FindLastIdByMessage(key);
        if (id <= 0) {
            log("[git] [" + currentBranch + "] no commit with message: " + key, Severity::Error);
            return false;
        }
        return LoadById(id);
    }

    void LogLast(int count) {
        if (count <= 0) count = 10;

        string idx = Read(BranchDir() + "index.txt");
        if (idx.Length == 0) {
            log("[git] [" + currentBranch + "] (no commits)", Severity::Info);
            return;
        }

        array<uint> starts; starts.Add(0);
        for (uint i = 0; i < idx.Length; i++) if (idx[i] == '\n') starts.Add(i + 1);

        int shown = 0;
        for (int si = int(starts.Length) - 1; si >= 0 && shown < count; si--) {
            uint start = starts[si];
            if (start >= idx.Length) continue;

            string line=""; for(uint j=start; j<idx.Length && idx[j] != '\n'; j++){ string ch=""; ch.Resize(1); ch[0]=idx[j]; line+=ch; }
            if (line.Length == 0) continue;

            int bar=-1; for(uint k=0;k<line.Length;k++){ if(line[k]=='|'){ bar=int(k); break; } }
            if (bar < 0) continue;

            string idStr=""; for(int k=0;k<bar;k++){ string ch=""; ch.Resize(1); ch[0]=line[k]; idStr+=ch; }
            string msg=""; for(uint k=uint(bar+1); k<line.Length; k++){ string ch=""; ch.Resize(1); ch[0]=line[k]; msg+=ch; }

            int id = Text::ParseInt(idStr);
            if (id > 0) {
                log("[git] [" + currentBranch + "] " + Text::FormatInt(id) + "  " + msg, Severity::Info);
                shown++;
            }
        }

        if (shown == 0) {
            log("[git] [" + currentBranch + "] (no commits)", Severity::Info);
        }
    }

    string AbsPathFor(const string &in rel) {
        string base = GetVariableString("scripts_folder"); 
        bool needSep = true;
        if (base.Length > 0) { uint8 last = base[base.Length - 1]; if (last == '\\' || last == '/') needSep = false; }
        string combined = base; if (needSep) combined += "\\";
        for (uint i = 0; i < rel.Length; i++) { string ch=""; ch.Resize(1); ch[0] = (rel[i] == '/') ? '\\' : rel[i]; combined += ch; }
        return combined;
    }

    void OnGitCmd(int fromTime, int toTime, const string &in commandLine, const array<string> &in args) {
        if (args.Length == 0) {
            log("[git] usage: git commit -m \"msg\" | git load <id|message> | git log [n] | git branch [name] | git checkout <name> | git branches", Severity::Info);
            return;
        }

        string sub = args[0];

        if (sub == "commit") {
            int mIndex = -1;
            for (uint i = 1; i < args.Length; i++) { if (args[i] == "-m") { mIndex = int(i); break; } }
            if (mIndex < 0 || uint(mIndex + 1) >= args.Length) { log("[git] usage: git commit -m \"message\"", Severity::Error); return; }
            string msg = JoinArgs(args, uint(mIndex + 1));
            if (msg.Length >= 2 && msg[0] == '"' && msg[msg.Length - 1] == '"') {
                string unq=""; for(uint i=1;i+1<msg.Length;i++){ string ch=""; ch.Resize(1); ch[0]=msg[i]; unq+=ch; } msg=unq;
            }
            if (msg.Length == 0) { log("[git] empty commit message", Severity::Error); return; }
            Commit(msg);
            return;
        }

        if (sub == "load") {
            if (args.Length < 2) { log("[git] usage: git load <id|\"message\">", Severity::Error); return; }
            string key = JoinArgs(args, 1);
            if (key.Length >= 2 && key[0] == '"' && key[key.Length - 1] == '"') {
                string unq=""; for(uint i=1;i+1<key.Length;i++){ string ch=""; ch.Resize(1); ch[0]=key[i]; unq+=ch; } key=unq;
            }
            Load(key);
            return;
        }

        if (sub == "log") {
            int n = 10;
            if (args.Length >= 2) { n = Text::ParseInt(args[1]); if (n <= 0) n = 10; }
            LogLast(n);
            return;
        }

        if (sub == "branch") {
            if (args.Length == 1) {
                log("[git] current branch: " + currentBranch, Severity::Info);
                return;
            }
            string name = args[1];
            if (BranchExists(name)) {
                log("[git] branch '" + name + "' already exists", Severity::Info);
                return;
            }
            EnsureBranchExists(name);
            log("[git] created branch '" + name + "'", Severity::Info);
            return;
        }

        if (sub == "checkout") {
            if (args.Length < 2) { log("[git] usage: git checkout <name>", Severity::Error); return; }
            string name = args[1];
            if (!BranchExists(name)) { log("[git] no such branch '" + name + "'", Severity::Error); return; }
            currentBranch = name;
            SaveBranch();
            log("[git] switched to branch '" + currentBranch + "'", Severity::Info);
            return;
        }

        if (sub == "branches") {

            if (!Exists(BRANCHES_INDEX)) { Write(BRANCHES_INDEX, ""); AddBranchToIndexIfMissing(currentBranch); }
            string cur = Read(BRANCHES_INDEX);
            if (cur.Length == 0) {
                log("[git] branches: * " + currentBranch, Severity::Info);
                return;
            }

            uint start = 0;
            bool any = false;
            for (uint i = 0; i <= cur.Length; i++) {
                bool eol = (i == cur.Length) || (cur[i] == '\n');
                if (!eol) continue;

                string name = "";
                for (uint j = start; j < i; j++) { string ch=""; ch.Resize(1); ch[0]=cur[j]; name += ch; }
                start = i + 1;

                if (name.Length == 0) continue;
                any = true;
                string mark = (name == currentBranch) ? "* " : "  ";
                log("[git] " + mark + name, Severity::Info);
            }

            if (!any) {

                log("[git] * " + currentBranch, Severity::Info);
            }
            return;
        }

        log("[git] unknown subcommand. use: commit | load | log | branch | checkout", Severity::Error);
    }

    void RenderSettings() {
        UI::Text("Mini Git Helpers");
        UI::Text("Current branch: " + currentBranch);
        UI::Separator();

        if (UI::CollapsingHeader("Commits")) {
            UI::PushItemWidth(kInputWidth);
            uiCommitMsg = UI::InputText("Commit message", uiCommitMsg);
            UI::PopItemWidth();

            if (UI::Button("Commit")) {
                if (uiCommitMsg.Length == 0) {
                    log("[git] empty commit message", Severity::Error);
                } else {
                    Commit(uiCommitMsg);
                }
            }
        }

        UI::Separator();

        if (UI::CollapsingHeader("Load & Log")) {

            array<int> commitIds;
            array<string> commitLabels;
            CollectCommits(commitIds, commitLabels);

            if (commitIds.Length == 0) {
                UI::Text("No commits available on this branch.");
            } else {

                bool foundSelected = false;
                for (uint i = 0; i < commitIds.Length; i++) {
                    if (commitIds[i] == uiSelectedCommitId) {
                        uiSelectedCommitLabel = commitLabels[i];
                        foundSelected = true;
                        break;
                    }
                }
                if (!foundSelected) {
                    uiSelectedCommitId = commitIds[commitIds.Length - 1];
                    uiSelectedCommitLabel = commitLabels[commitLabels.Length - 1];
                }

                UI::PushItemWidth(kInputWidth);
                if (UI::BeginCombo("Commit to load", uiSelectedCommitLabel)) {
                    for (uint i = 0; i < commitIds.Length; i++) {
                        bool isSelected = (commitIds[i] == uiSelectedCommitId);
                        if (UI::Selectable(commitLabels[i], isSelected)) {
                            uiSelectedCommitId = commitIds[i];
                            uiSelectedCommitLabel = commitLabels[i];
                        }
                    }
                    UI::EndCombo();
                }
                UI::PopItemWidth();

                if (UI::Button("Load selected commit")) {
                    if (uiSelectedCommitId > 0) {

                        Load(Text::FormatInt(uiSelectedCommitId));
                    } else {
                        log("[git] no commit selected", Severity::Error);
                    }
                }
            }

            UI::Dummy(vec2(0, 5));

            UI::PushItemWidth(kInputWidth);
            uiLogCount = UI::InputInt("Log entries", uiLogCount, 1);
            UI::PopItemWidth();

            if (uiLogCount <= 0) uiLogCount = 10;

            if (UI::Button("Show log in console")) {
                LogLast(uiLogCount);
            }
        }

        UI::Separator();

        if (UI::CollapsingHeader("Branches")) {
            array<string> branches;
            CollectBranches(branches);

            UI::PushItemWidth(kInputWidth);
            if (UI::BeginCombo("Active branch", currentBranch)) {
                for (uint i = 0; i < branches.Length; i++) {
                    bool isSelected = branches[i] == currentBranch;
                    if (UI::Selectable(branches[i], isSelected)) {
                        if (branches[i] != currentBranch) {
                            if (!BranchExists(branches[i])) {
                                log("[git] no such branch '" + branches[i] + "'", Severity::Error);
                            } else {
                                currentBranch = branches[i];
                                SaveBranch();
                                log("[git] switched to branch '" + currentBranch + "'", Severity::Info);
                            }
                        }
                    }
                }
                UI::EndCombo();
            }
            UI::PopItemWidth();

            UI::Dummy(vec2(0, 5));

            UI::PushItemWidth(kInputWidth);
            uiNewBranchName = UI::InputText("New branch name", uiNewBranchName);
            UI::PopItemWidth();

            if (UI::Button("Create branch")) {
                string name = Trim(uiNewBranchName);
                if (name.Length == 0) {
                    log("[git] branch name cannot be empty", Severity::Error);
                } else if (BranchExists(name)) {
                    log("[git] branch '" + name + "' already exists", Severity::Info);
                } else {
                    EnsureBranchExists(name);
                    log("[git] created branch '" + name + "'", Severity::Info);
                    uiNewBranchName = "";
                }
            }

            UI::Dummy(vec2(0, 5));

            if (UI::Button("List branches in console")) {
                array<string> args;
                args.Add("branches");
                OnGitCmd(0, 0, "git branches", args);
            }
        }
    }

    void Init() {
        LoadBranch(); 
        RegisterCustomCommand("git", "Save/load input snapshots (with branches)", OnGitCmd);
        RegisterSettingsPage("Git", RenderSettings);
    }
}

void OnCommandListChanged(CommandList@ prev, CommandList@ curr, CommandListChangeReason reason) {
    @Git::current = @curr;

    if(reason==CommandListChangeReason::Unload) return;

    string expected = Git::AbsPathFor(ROOT + Git::CURRENT);

    bool isCurrentTxt = (curr !is null) && (curr.Filename == expected);

    if (Git::internalLoading && isCurrentTxt) {

        Git::internalLoading = false;
        Git::dirty = false;
        return;
    }

    if (isCurrentTxt) {
        Git::dirty = true;
    }

}