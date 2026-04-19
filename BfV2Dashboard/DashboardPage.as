string HandleBfDashboard(const string &in body)
{
    string h = "<!DOCTYPE html><html lang='en'><head>";
    h += "<meta charset='utf-8'>";
    h += "<meta name='viewport' content='width=device-width,initial-scale=1'>";
    h += "<title>BfV2 Dashboard</title>";
    h += "<style>" + BfDashCSS() + "</style>";
    h += "</head><body>";
    h += "<header><h1>BfV2 Dashboard</h1><span id='conn' class='badge'>Connecting...</span></header>";
    h += "<main>";

    // Live Bruteforce panel (wide, always visible, at the very top)
    h += "<section class='panel wide' id='liveBf'>";
    h += "<h2>Live Bruteforce</h2>";
    h += "<div id='liveCards' class='live-cards'></div>";
    h += "<p id='liveEmpty' class='hint' style='color:#8b949e;padding:0.5rem 0;'>No instances currently running bruteforce.</p>";
    h += "</section>";

    // Instance switcher
    h += "<div class='instance-switcher'>";
    h += "<span class='instance-label'>Viewing instance:</span>";
    h += "<div id='instanceBar' class='instance-bar'></div>";
    h += "<p class='instance-hint'>Switching changes all panels below (Status, Settings, Sessions, etc.)</p>";
    h += "</div>";

    // Status panel
    h += "<section class='panel' id='status'>";
    h += "<h2>Status</h2>";
    h += "<div class='grid2'>";
    h += "<div class='stat'><label>State</label><span id='bfState' class='badge'>-</span></div>";
    h += "<div class='stat'><label>Phase</label><span id='bfPhase' class='badge'>-</span></div>";
    h += "<div class='stat'><label>Target</label><span id='bfTarget'>-</span></div>";
    h += "<div class='stat'><label>Elapsed</label><span id='bfElapsed'>-</span></div>";
    h += "<div class='stat'><label>Iterations</label><span id='bfIter' class='big'>0</span></div>";
    h += "<div class='stat'><label>Iter/sec</label><span id='bfIterSec' class='big'>0</span></div>";
    h += "<div class='stat'><label>Restarts</label><span id='bfRestarts'>0</span></div>";
    h += "<div class='stat'><label>Improvements</label><span id='bfImpCount'>0</span></div>";
    h += "</div>";
    h += "</section>";

    // Map panel
    h += "<section class='panel' id='mapinfo'>";
    h += "<h2>Map</h2>";
    h += "<div class='stat'><label>Name</label><span id='mapName'>-</span></div>";
    h += "<div class='stat'><label>Author</label><span id='mapAuthor'>-</span></div>";
    h += "<div class='stat'><label>UID</label><span id='mapUid' class='mono'>-</span></div>";
    h += "</section>";

    // Settings panel (wide, full collapsible)
    h += "<section class='panel wide' id='settings'>";
    h += "<h2>Settings</h2>";
    h += "<div id='ctrlBadge'></div>";
    h += "<div id='applyBar' class='apply-bar' style='display:none'>";
    h += "<span class='desynced-badge'>Desynchronized</span>";
    h += "<span id='dirtyCount' class='dirty-count'>No pending changes</span>";
    h += "<button id='btnDiscard' class='btn-action' disabled>Discard</button>";
    h += "<button id='btnApply' class='btn-action btn-apply' disabled>Apply All</button>";
    h += "</div>";

    // Behavior section
    h += "<details id='secBehavior' open>";
    h += "<summary>Behavior <button class='propagate-btn' data-section='secBehavior' onclick='event.stopPropagation();propagateSection(this.dataset.section)'>Propagate to all</button></summary>";
    h += "<div class='sec-body'>";
    h += "<div class='field-row'><label>Result Filename</label><input type='text' id='behFile' data-var='bf_result_filename'></div>";
    h += "<div class='field-row'><label>Iterations Before Restart</label><input type='number' id='behIter' data-var='bf_iterations_before_restart' min='0' step='1'></div>";
    h += "<div class='field-row'><label>Result Folder</label><input type='text' id='behFolder' data-var='bf_result_folder'></div>";
    h += "<div class='chk-row'><input type='checkbox' id='behPersist' data-var='bf_dashboard_persist_logs'><label for='behPersist'>Persist dashboard logs to file</label></div>";
    h += "<div class='field-row full'><label>Restart Condition Script</label><textarea id='behRestartScript' data-var='bf_restart_condition_script' data-script='1' rows='3'></textarea></div>";
    h += "</div></details>";

    // Optimization section
    h += "<details id='secOptimization'>";
    h += "<summary>Optimization <button class='propagate-btn' data-section='secOptimization' onclick='event.stopPropagation();propagateSection(this.dataset.section)'>Propagate to all</button></summary>";
    h += "<div class='sec-body'>";
    h += "<div class='field-row full'><label>Target</label><select id='optTarget' data-var='bf_target'></select></div>";
    h += "<div id='evalFields'></div>";
    h += "</div></details>";

    // Conditions section
    h += "<details id='secConditions'>";
    h += "<summary>Conditions <button class='propagate-btn' data-section='secConditions' onclick='event.stopPropagation();propagateSection(this.dataset.section)'>Propagate to all</button></summary>";
    h += "<div class='sec-body'>";
    h += "<div class='field-row'><label>Min Speed</label><input type='number' id='condSpeed' data-var='bf_condition_speed' min='0' step='0.1'></div>";
    h += "<div class='field-row'><label>Min CPs</label><input type='number' id='condCps' data-var='bf_condition_cps' min='0' step='1'></div>";
    h += "<div class='field-row'><label>Trigger</label><select id='condTrigger' data-var='bf_condition_trigger'></select></div>";
    h += "<div class='field-row full'><label>Condition Script</label><textarea id='condScript' data-var='bf_condition_script' data-script='1' rows='3'></textarea></div>";
    h += "</div></details>";

    // Input Modification section
    h += "<details id='secInputMod'>";
    h += "<summary>Input Modification <button class='propagate-btn' data-section='secInputMod' onclick='event.stopPropagation();propagateSection(this.dataset.section)'>Propagate to all</button></summary>";
    h += "<div class='sec-body'>";
    h += "<div id='slotsContainer'></div>";
    h += "<button id='btnAddSlot' class='btn-action'>+ Add Slot</button>";
    h += "</div></details>";

    h += "</section>";

    // Past Sessions panel (wide)
    h += "<section class='panel wide' id='pastSessions'>";
    h += "<h2>Past Sessions</h2>";
    h += "<div class='tab-bar' id='sessionTabs'></div>";
    h += "<div class='sub-tabs'>";
    h += "<button class='sub-tab active' id='tabImp'>Improvements</button>";
    h += "<button class='sub-tab' id='tabLog'>Log</button>";
    h += "</div>";
    h += "<div id='historyContent' class='history-content'></div>";
    h += "</section>";

    // Base Run Inputs panel (wide, disabled overlay when BF not running)
    h += "<section class='panel wide' id='baseInputs'>";
    h += "<h2>Base Run Inputs</h2>";
    h += "<div id='baseDisabledOverlay' class='disabled-overlay'>";
    h += "<span>Bruteforce must be running to use this feature</span>";
    h += "</div>";
    h += "<div id='baseContent'>";
    h += "<p class='hint'>Paste input commands to replace the current base run and restart bruteforce with these inputs.</p>";
    h += "<textarea id='inputScript' rows='8' class='code-input' placeholder='0 press up&#10;0.1 steer 13107&#10;0.5 steer -65536&#10;5 press down&#10;...'></textarea>";
    h += "<div class='base-actions'>";
    h += "<button id='btnApplyInputs' class='btn-action btn-apply'>Apply &amp; Restart Bruteforce</button>";
    h += "<button id='btnApplyAll' class='btn-action btn-apply'>Apply to All &amp; Restart All Bruteforces</button>";
    h += "<span id='inputResult' class='input-result'></span>";
    h += "</div>";
    h += "</div>";
    h += "</section>";

    h += "</main>";
    h += "<script>";
    h += BfDashJS_Helpers();
    h += BfDashJS_Status();
    h += BfDashJS_Settings();
    h += BfDashJS_Sessions();
    h += "</script>";
    h += "</body></html>";
    return h;
}

// ============================================================
// CSS
// ============================================================

string BfDashCSS()
{
    string c = "*{box-sizing:border-box;margin:0;padding:0}";
    c += "body{font-family:system-ui,-apple-system,sans-serif;background:#0d1117;color:#c9d1d9;min-height:100vh}";
    c += "header{background:#161b22;padding:1rem 2rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #30363d}";
    c += "header h1{font-size:1.2rem;color:#f0883e}";
    c += "main{display:grid;grid-template-columns:1fr 1fr;gap:1rem;padding:1rem 2rem;max-width:1400px;margin:0 auto}";
    c += ".panel{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:1.2rem}";
    c += ".panel.wide{grid-column:1/-1}";
    c += ".panel h2{color:#f0883e;font-size:1rem;margin-bottom:0.8rem;padding-bottom:0.4rem;border-bottom:1px solid #21262d}";
    c += ".panel h3{color:#8b949e;font-size:0.8rem;text-transform:uppercase;margin:0.8rem 0 0.3rem}";
    c += ".grid2{display:grid;grid-template-columns:1fr 1fr;gap:0.5rem}";
    c += ".stat{display:flex;flex-direction:column;gap:0.15rem}";
    c += ".stat label{color:#8b949e;font-size:0.75rem;text-transform:uppercase}";
    c += ".stat span{font-size:1rem}";
    c += ".big{font-size:1.6rem !important;font-weight:700;color:#fff}";
    c += ".badge{background:#21262d;padding:0.15rem 0.5rem;border-radius:4px;font-size:0.8rem;display:inline-block}";
    c += ".badge.running{background:#3fb95030;color:#3fb950}";
    c += ".badge.idle{background:#21262d;color:#8b949e}";
    c += ".badge.initial{background:#58a6ff30;color:#58a6ff}";
    c += ".badge.search{background:#d2992230;color:#d29922}";
    c += ".badge.warn{background:#d2992230;color:#d29922;margin-bottom:0.6rem}";
    c += ".mono{font-family:monospace;font-size:0.8rem !important;word-break:break-all}";

    // Collapsible sections
    c += "details{border:1px solid #21262d;border-radius:6px;margin-bottom:0.6rem}";
    c += "details[open]{border-color:#30363d}";
    c += "summary{cursor:pointer;padding:0.5rem 0.7rem;font-size:0.85rem;font-weight:600;color:#f0883e;background:#0d1117;border-radius:5px;user-select:none;list-style:none}";
    c += "summary::-webkit-details-marker{display:none}";
    c += "summary::before{content:'\\25B6';display:inline-block;margin-right:0.5rem;font-size:0.65rem;transition:transform 0.15s}";
    c += "details[open]>summary::before{transform:rotate(90deg)}";
    c += "summary:hover{background:#161b22}";
    c += ".propagate-btn{float:right;background:#21262d;color:#8b949e;border:1px solid #30363d;border-radius:4px;padding:0.15rem 0.5rem;font-size:0.7rem;cursor:pointer}";
    c += ".propagate-btn:hover{background:#58a6ff30;color:#58a6ff;border-color:#58a6ff40}";
    c += ".sec-body{padding:0.7rem;display:grid;grid-template-columns:1fr 1fr;gap:0.5rem 1rem;overflow:hidden}";

    // Field rows
    c += ".field-row{display:flex;flex-direction:column;gap:0.15rem;min-width:0}";
    c += ".field-row.full{grid-column:1/-1}";
    c += ".field-row label{color:#8b949e;font-size:0.7rem;text-transform:uppercase}";
    c += ".field-row input,.field-row select,.field-row textarea{background:#0d1117;border:1px solid #30363d;border-radius:4px;color:#c9d1d9;padding:0.3rem 0.5rem;font-size:0.8rem;font-family:inherit;width:100%;max-width:100%;min-width:0}";
    c += ".field-row input:focus,.field-row select:focus,.field-row textarea:focus{outline:none;border-color:#f0883e}";
    c += ".field-row textarea{font-family:monospace;resize:vertical;min-height:2.5rem}";
    c += ".field-row input[type=number]{-moz-appearance:textfield}";
    c += ".field-row input[type=range]{padding:0;height:1.2rem}";

    // Vec3 row
    c += ".vec3-row{display:flex;gap:0.3rem;align-items:center}";
    c += ".vec3-row input{flex:1;min-width:0}";
    c += ".vec3-row .btn-sm{flex:0 0 auto}";

    // Inline row
    c += ".inline-row{display:flex;gap:0.4rem;align-items:center}";
    c += ".inline-row label{white-space:nowrap}";

    // Checkbox wrapper
    c += ".chk-row{display:flex;align-items:center;gap:0.4rem;padding:0.15rem 0}";
    c += ".chk-row input[type=checkbox]{width:1rem;height:1rem;accent-color:#f0883e}";
    c += ".chk-row label{color:#c9d1d9;font-size:0.8rem}";

    // Slot card
    c += ".slot-card{background:#0d1117;border:1px solid #30363d;border-radius:6px;margin-bottom:0.5rem;overflow:hidden}";
    c += ".slot-hdr{display:flex;align-items:center;gap:0.5rem;padding:0.4rem 0.6rem;background:#161b22;border-bottom:1px solid #21262d}";
    c += ".slot-hdr .slot-title{font-size:0.85rem;font-weight:600;color:#c9d1d9;flex:1}";
    c += ".slot-body{padding:0.6rem;display:grid;grid-template-columns:1fr 1fr;gap:0.5rem 1rem}";

    // Sub-section within a slot (for advanced algorithm sub-types)
    c += ".sub-sec{grid-column:1/-1;border:1px solid #21262d;border-radius:4px;padding:0.5rem;margin-top:0.2rem}";
    c += ".sub-sec-title{font-size:0.75rem;font-weight:600;color:#8b949e;text-transform:uppercase;margin-bottom:0.4rem}";
    c += ".sub-sec-grid{display:grid;grid-template-columns:1fr 1fr;gap:0.4rem 1rem}";

    // Buttons
    c += ".btn-action{background:#21262d;color:#c9d1d9;border:1px solid #30363d;border-radius:4px;padding:0.3rem 0.8rem;cursor:pointer;font-size:0.8rem}";
    c += ".btn-action:hover{background:#30363d}";
    c += ".btn-danger{background:#f8514920;color:#f85149;border:1px solid #f8514940}";
    c += ".btn-danger:hover{background:#f8514940}";
    c += ".btn-sm{background:#21262d;color:#c9d1d9;border:1px solid #30363d;border-radius:4px;padding:0.2rem 0.5rem;cursor:pointer;font-size:0.7rem}";
    c += ".btn-sm:hover{background:#30363d}";

    // Range display
    c += ".range-wrap{display:flex;align-items:center;gap:0.4rem;min-width:0}";
    c += ".range-wrap input[type=range]{flex:1;min-width:0}";
    c += ".range-wrap .range-val{font-size:0.8rem;color:#c9d1d9;min-width:3rem;text-align:right;font-family:monospace}";

    // Session tabs
    c += ".tab-bar{display:flex;gap:0.3rem;margin-bottom:0.5rem;flex-wrap:wrap}";
    c += ".tab-btn{background:#21262d;color:#8b949e;border:1px solid #30363d;padding:0.3rem 0.8rem;border-radius:6px 6px 0 0;cursor:pointer;font-size:0.8rem}";
    c += ".tab-btn:hover{background:#30363d}";
    c += ".tab-btn.active{background:#161b22;color:#f0883e;border-bottom-color:#161b22}";
    c += ".sub-tabs{display:flex;gap:0.3rem;margin-bottom:0.5rem}";
    c += ".sub-tab{background:none;color:#8b949e;border:none;padding:0.3rem 0.8rem;cursor:pointer;font-size:0.8rem;border-bottom:2px solid transparent}";
    c += ".sub-tab:hover{color:#c9d1d9}";
    c += ".sub-tab.active{color:#f0883e;border-bottom-color:#f0883e}";

    // History
    c += ".history-content{max-height:400px;overflow-y:auto}";
    c += ".imp-row{display:grid;grid-template-columns:2.5rem 4rem 1fr 4rem 3rem;gap:0.5rem;padding:0.3rem 0;border-bottom:1px solid #21262d;font-size:0.8rem;align-items:center}";
    c += ".imp-row.hdr{color:#8b949e;font-weight:600;border-bottom:2px solid #30363d}";
    c += ".log-entry{padding:0.15rem 0;font-family:monospace;font-size:0.8rem;line-height:1.5}";
    c += ".log-entry .lt{color:#8b949e;margin-right:0.5rem}";
    c += ".log-entry .lm{color:#c9d1d9}";

    c += ".dirty { border-left: 3px solid #d29922 !important; padding-left: 0.3rem; }";
    c += ".apply-bar { display:flex; align-items:center; gap:0.6rem; padding:0.5rem 0.7rem; margin-bottom:0.6rem; background:#d2992215; border:1px solid #d2992240; border-radius:6px; }";
    c += ".desynced-badge { background:#d2992230; color:#d29922; padding:0.15rem 0.5rem; border-radius:4px; font-size:0.8rem; font-weight:600; }";
    c += ".dirty-count { color:#8b949e; font-size:0.8rem; flex:1; }";
    c += ".btn-apply { background:#d2992230; color:#d29922; border-color:#d2992240; }";
    c += ".btn-apply:hover:not(:disabled) { background:#d2992250; }";
    c += ".btn-action:disabled { opacity:0.4; cursor:default; }";
    c += ".toast { position:fixed; bottom:1.5rem; left:50%; transform:translateX(-50%) translateY(20px); background:#21262d; color:#c9d1d9; border:1px solid #30363d; border-radius:6px; padding:0.5rem 1rem; font-size:0.85rem; opacity:0; transition:opacity 0.3s,transform 0.3s; z-index:1000; pointer-events:none; }";
    c += ".toast.show { opacity:1; transform:translateX(-50%) translateY(0); }";
    c += ".tab-del { background:none; border:none; color:#8b949e; font-size:0.7rem; cursor:pointer; margin-left:0.3rem; padding:0 0.2rem; line-height:1; }";
    c += ".tab-del:hover { color:#f85149; }";

    c += ".instance-switcher{grid-column:1/-1;background:#161b22;border:1px solid #30363d;border-radius:8px;padding:0.8rem 1.2rem;margin-bottom:0}";
    c += ".instance-label{color:#f0883e;font-weight:600;font-size:0.85rem;display:block;margin-bottom:0.4rem}";
    c += ".instance-hint{color:#8b949e;font-size:0.7rem;margin-top:0.3rem;font-style:italic}";
    c += ".instance-bar{display:flex;gap:0.3rem;flex-wrap:wrap}";
    c += ".inst-btn { background:#21262d; color:#8b949e; border:1px solid #30363d; padding:0.4rem 1rem; border-radius:6px; cursor:pointer; font-size:0.85rem; }";
    c += ".inst-btn:hover { background:#30363d; }";
    c += ".inst-btn.active { background:#f0883e20; color:#f0883e; border-color:#f0883e40; }";

    // Live BF cards
    c += ".live-cards { display:flex; flex-wrap:wrap; gap:0.5rem; }";
    c += ".live-card { flex:0 0 calc(25% - 0.375rem); background:#0d1117; border:1px solid #30363d; border-radius:6px; overflow:hidden; min-width:200px; }";
    c += ".live-card-hdr { padding:0.4rem 0.6rem; background:#161b22; border-bottom:1px solid #21262d; font-size:0.8rem; }";
    c += ".live-card-hdr .port { color:#f0883e; font-weight:600; }";
    c += ".live-card-hdr .target { color:#8b949e; margin-left:0.3rem; }";
    c += ".live-card-tabs { display:flex; border-bottom:1px solid #21262d; }";
    c += ".live-card-tab { flex:1; text-align:center; padding:0.25rem; font-size:0.7rem; cursor:pointer; color:#8b949e; background:none; border:none; border-bottom:2px solid transparent; }";
    c += ".live-card-tab.active { color:#f0883e; border-bottom-color:#f0883e; }";
    c += ".live-card-body { max-height:200px; overflow-y:auto; padding:0.3rem; font-size:0.75rem; font-family:monospace; }";

    // Base Run Inputs
    c += ".code-input { width:100%; background:#0d1117; color:#c9d1d9; border:1px solid #30363d; border-radius:4px; padding:0.5rem; font-family:monospace; font-size:0.8rem; resize:vertical; }";
    c += ".hint { color:#8b949e; font-size:0.75rem; margin-bottom:0.5rem; }";
    c += ".base-actions { display:flex; align-items:center; gap:0.5rem; margin-top:0.5rem; flex-wrap:wrap; }";
    c += "#baseInputs{position:relative}";
    c += ".disabled-overlay{position:absolute;top:0;left:0;right:0;bottom:0;background:rgba(13,17,23,0.85);z-index:10;display:flex;align-items:center;justify-content:center;border-radius:8px}";
    c += ".disabled-overlay span{color:#8b949e;font-size:0.9rem;padding:1rem;text-align:center}";
    c += ".input-result { font-size:0.8rem; font-family:monospace; }";

    // Group Editor
    c += ".ge-wrap{grid-column:1/-1;border:1px solid #30363d;border-radius:6px;margin-top:0.4rem;background:#0d1117}";
    c += ".ge-title{font-size:0.85rem;font-weight:600;color:#f0883e;padding:0.5rem 0.7rem;border-bottom:1px solid #21262d}";
    c += ".ge-body{padding:0.5rem 0.7rem}";
    c += ".ge-row{display:flex;align-items:center;gap:0.5rem;margin-bottom:0.35rem;flex-wrap:wrap}";
    c += ".ge-row label{color:#8b949e;font-size:0.75rem;text-transform:uppercase;min-width:5rem}";
    c += ".ge-row select,.ge-row input[type=number]{background:#161b22;border:1px solid #30363d;border-radius:4px;color:#c9d1d9;padding:0.25rem 0.4rem;font-size:0.8rem}";
    c += ".ge-row select{min-width:10rem}";
    c += ".ge-row input[type=number]{width:6rem}";
    c += ".ge-row input[type=checkbox]{width:1rem;height:1rem;accent-color:#f0883e}";
    c += ".ge-scalar{border:1px solid #21262d;border-radius:4px;padding:0.4rem 0.6rem;margin-top:0.3rem}";
    c += ".ge-scalar-name{font-size:0.8rem;font-weight:600;color:#c9d1d9;margin-bottom:0.3rem}";
    c += ".ge-bound{display:flex;align-items:center;gap:0.4rem;margin-bottom:0.2rem}";
    c += ".ge-bound label{color:#8b949e;font-size:0.7rem;min-width:4rem}";
    c += ".ge-hint{color:#8b949e;font-size:0.7rem;font-style:italic;padding:0.3rem 0}";

    // Condition Editor
    c += ".ce-wrap{grid-column:1/-1;border:1px solid #30363d;border-radius:6px;margin-top:0.4rem;background:#0d1117}";
    c += ".ce-title{font-size:0.85rem;font-weight:600;color:#f0883e;padding:0.5rem 0.7rem;border-bottom:1px solid #21262d}";
    c += ".ce-body{padding:0.5rem 0.7rem}";
    c += ".ce-row{display:flex;align-items:center;gap:0.5rem;margin-bottom:0.35rem;flex-wrap:wrap}";
    c += ".ce-row label{color:#8b949e;font-size:0.75rem;text-transform:uppercase;min-width:5rem}";
    c += ".ce-row select,.ce-row input[type=number]{background:#161b22;border:1px solid #30363d;border-radius:4px;color:#c9d1d9;padding:0.25rem 0.4rem;font-size:0.8rem}";
    c += ".ce-row select{min-width:10rem}";
    c += ".ce-row input[type=number]{width:6rem}";
    c += ".ce-row input[type=checkbox]{width:1rem;height:1rem;accent-color:#f0883e}";
    c += ".ce-fields{border:1px solid #21262d;border-radius:4px;padding:0.4rem 0.6rem;margin-top:0.3rem}";
    c += ".ce-hint{color:#8b949e;font-size:0.7rem;font-style:italic;padding:0.3rem 0}";
    c += ".ce-range-row{display:flex;align-items:center;gap:0.4rem;margin-bottom:0.2rem}";
    c += ".ce-range-row label{color:#8b949e;font-size:0.7rem;min-width:3rem}";
    c += ".ce-range-row input[type=range]{flex:1;min-width:4rem}";
    c += ".ce-range-row .ce-range-val{font-size:0.8rem;color:#c9d1d9;min-width:2rem;text-align:right;font-family:monospace}";
    c += ".ce-reset{background:#21262d;color:#8b949e;border:1px solid #30363d;border-radius:4px;padding:0.15rem 0.5rem;font-size:0.7rem;cursor:pointer;margin-left:auto}";
    c += ".ce-reset:hover{background:#f8514920;color:#f85149;border-color:#f8514940}";

    c += "@media(max-width:700px){main{grid-template-columns:1fr}.sec-body{grid-template-columns:1fr}.slot-body{grid-template-columns:1fr}.sub-sec-grid{grid-template-columns:1fr}.grid2{grid-template-columns:1fr}}";

    return c;
}

// ============================================================
// JS: Helper functions (format, parse, API send)
// ============================================================

string BfDashJS_Helpers()
{
    string j = "";

    // Multi-instance state
    j += "var apiBase = '';";
    j += "var activeInstancePort = 0;";
    j += "var instances = [];";
    j += "var perInstanceState = {};";

    // State variables for buffered mode
    j += "var bfIsRunning = null;";
    j += "var dirtyVars = {};";
    j += "var serverSnapshot = {};";

    // Format milliseconds to m:ss.cc
    j += "function fmtTime(ms){";
    j += "if(ms===0||ms===null||ms===undefined)return '0:00.00';";
    j += "var neg=ms<0;if(neg)ms=-ms;";
    j += "var totalCs=Math.floor(ms/10);";
    j += "var cs=totalCs%100;var totalSec=Math.floor(totalCs/100);";
    j += "var sec=totalSec%60;var min=Math.floor(totalSec/60);";
    j += "var r=min+':'+(sec<10?'0':'')+sec+'.'+(cs<10?'0':'')+cs;";
    j += "return neg?'-'+r:r;}";

    // Parse m:ss.cc or plain number to ms
    j += "function parseTime(s){";
    j += "s=s.trim();if(s==='')return 0;";
    j += "if(/^-?\\d+$/.test(s))return parseInt(s,10);";
    j += "var neg=false;if(s[0]==='-'){neg=true;s=s.substring(1);}";
    j += "var parts=s.split(':');var min=0;var rest=s;";
    j += "if(parts.length===2){min=parseInt(parts[0],10)||0;rest=parts[1];}";
    j += "var secParts=rest.split('.');var sec=parseInt(secParts[0],10)||0;";
    j += "var cs=0;if(secParts.length>1){var f=secParts[1];if(f.length===1)f+='0';cs=parseInt(f.substring(0,2),10)||0;}";
    j += "var ms=(min*60+sec)*1000+cs*10;return neg?-ms:ms;}";

    // Duration formatter (for elapsed time)
    j += "function fmtDur(ms){if(ms<1000)return ms+'ms';var s=ms/1000;var sr=Math.round(s*10)/10;if(sr<60)return sr.toFixed(1)+'s';var m=Math.floor(s/60);var sec=Math.floor(s%60);return m+'m '+sec+'s';}";

    // Number formatter
    j += "function fmtNum(n){return n.toLocaleString();}";

    // Seconds formatter (for log timestamps)
    j += "function fmtSec(s){if(s<60)return s.toFixed(1)+'s';var m=Math.floor(s/60);return m+'m '+((s%60).toFixed(1))+'s';}";

    // Script text conversions (colon <-> newline)
    j += "function scriptToDisplay(s){if(!s)return '';return s.split(':').join('\\n');}";
    j += "function displayToScript(s){if(!s)return '';return s.split('\\n').join(':');}";

    // POST /api/bf/set helper (mode-aware: buffers during BF, immediate otherwise)
    j += "function setVar(name, value) {";
    j += "var sv = String(value);";
    j += "if (bfIsRunning === null) return;";
    j += "if (!bfIsRunning) {";
    j += "fetch(apiBase+'/api/bf/set', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},";
    j += "body:'name='+encodeURIComponent(name)+'&value='+encodeURIComponent(sv)});";
    j += "return;}";
    j += "if (serverSnapshot[name] !== undefined && serverSnapshot[name] === sv) {";
    j += "delete dirtyVars[name];";
    j += "} else {";
    j += "dirtyVars[name] = sv;}";
    j += "markFieldDirty(name, name in dirtyVars);";
    j += "updateApplyBar();}";

    // POST helper for add-slot / remove-slot (clears slot-related dirty vars on structural changes)
    j += "function postAction(url, bodyStr) {";
    j += "fetch(apiBase+url, {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:bodyStr||''});";
    j += "if (bfIsRunning && (url.indexOf('add-slot') !== -1 || url.indexOf('remove-slot') !== -1)) {";
    j += "var keys = Object.keys(dirtyVars);";
    j += "for (var i=0; i<keys.length; i++) {";
    j += "if (keys[i].indexOf('bf_modify') === 0 || keys[i].indexOf('bf_inputs') === 0 ||";
    j += "keys[i].indexOf('bf_max_') === 0 || keys[i].indexOf('bf_range') === 0 ||";
    j += "keys[i].indexOf('bf_adv') === 0 || keys[i].indexOf('bf_input_mod') === 0) {";
    j += "var row = document.querySelector('[data-var=\"'+keys[i]+'\"]');";
    j += "if (row) { var r2 = row.closest('.field-row')||row.closest('.chk-row'); if(r2) r2.classList.remove('dirty'); }";
    j += "delete dirtyVars[keys[i]];}}";
    j += "updateApplyBar();";
    j += "showToast('Slot changed. Slot-related pending edits cleared.');}}";

    // Safe set textContent
    j += "function setText(id,txt){var el=document.getElementById(id);if(el)el.textContent=txt;}";

    // Check if element is focused
    j += "function isFocused(el){return document.activeElement===el;}";

    // Set field value only if not focused (dirty-aware: skips fields with local dirty edits during BF)
    j += "function setField(el, val) {";
    j += "if (!el || isFocused(el)) return;";
    j += "var vn = el.getAttribute('data-var');";
    j += "if (bfIsRunning && vn && (vn in dirtyVars)) return;";
    j += "if (el.tagName === 'SELECT') el.value = String(val);";
    j += "else if (el.type === 'checkbox') el.checked = !!val;";
    j += "else {";
    j += "el.value = String(val);";
    j += "if (el.type === 'range') {";
    j += "var ev = el.closest('.range-wrap');";
    j += "if (ev) { var sp = ev.querySelector('.range-val'); if (sp) sp.textContent = String(val); }}}}";

    // Dirty field marking helpers
    j += "function markFieldDirty(varName, isDirty) {";
    j += "var els = document.querySelectorAll('[data-var=\"'+varName+'\"]');";
    j += "for (var i=0; i<els.length; i++) {";
    j += "var row = els[i].closest('.field-row') || els[i].closest('.chk-row') || els[i].closest('.vec3-row') || els[i].closest('.range-wrap');";
    j += "if (row) { if (isDirty) row.classList.add('dirty'); else row.classList.remove('dirty'); }}}";

    j += "function markAllClean() {";
    j += "var els = document.querySelectorAll('.dirty');";
    j += "for (var i=0; i<els.length; i++) els[i].classList.remove('dirty');}";

    j += "function updateApplyBar() {";
    j += "var bar = document.getElementById('applyBar');";
    j += "if (!bar) return;";
    j += "var count = Object.keys(dirtyVars).length;";
    j += "if (!bfIsRunning) { bar.style.display = 'none'; return; }";
    j += "bar.style.display = 'flex';";
    j += "document.getElementById('dirtyCount').textContent = count > 0 ? count + ' pending change' + (count > 1 ? 's' : '') : 'No pending changes';";
    j += "document.getElementById('btnApply').disabled = (count === 0);";
    j += "document.getElementById('btnDiscard').disabled = (count === 0);}";

    j += "function showToast(msg) {";
    j += "var t = document.createElement('div');";
    j += "t.className = 'toast';";
    j += "t.textContent = msg;";
    j += "document.body.appendChild(t);";
    j += "setTimeout(function(){ t.classList.add('show'); }, 10);";
    j += "setTimeout(function(){ t.classList.remove('show'); setTimeout(function(){ t.remove(); }, 300); }, 3000);}";

    // Propagate a section's settings to all other instances
    j += "function propagateSection(sectionId){";
    j += "var sec=document.getElementById(sectionId);if(!sec)return;";
    j += "var els=sec.querySelectorAll('[data-var]');";
    j += "var pairs={};";
    j += "for(var i=0;i<els.length;i++){";
    j += "var vn=els[i].getAttribute('data-var');if(!vn)continue;";
    j += "var val;";
    j += "if(els[i].type==='checkbox')val=els[i].checked?'true':'false';";
    j += "else if(els[i].getAttribute('data-script'))val=displayToScript(els[i].value);";
    j += "else if(els[i].getAttribute('data-time'))val=String(parseTime(els[i].value));";
    j += "else if(els[i].getAttribute('data-vec3-idx')){";
    j += "var vidx=els[i].getAttribute('data-vec3-idx');";
    j += "if(vidx!=='0')continue;";
    j += "var row=els[i].closest('.vec3-row');if(!row)continue;";
    j += "var inps=row.querySelectorAll('input[type=number]');";
    j += "val=inps[0].value+' '+inps[1].value+' '+inps[2].value;";
    j += "}else val=els[i].value;";
    j += "pairs[vn]=val;}";
    j += "var body='';var keys=Object.keys(pairs);";
    j += "for(var k=0;k<keys.length;k++){if(k>0)body+='\\n';body+=keys[k]+'='+pairs[keys[k]];}";
    j += "var sent=0;";
    j += "for(var ii=0;ii<instances.length;ii++){";
    j += "if(instances[ii].port===activeInstancePort)continue;";
    j += "sent++;";
    j += "fetch('http://localhost:'+instances[ii].port+'/api/bf/set-batch',{method:'POST',body:body}).catch(function(){});}";
    j += "showToast('Propagated '+keys.length+' settings to '+sent+' instance'+(sent!==1?'s':''));}";

    // Create a field-row div
    j += "function mkFieldRow(labelText,inputEl,full){";
    j += "var d=document.createElement('div');d.className='field-row'+(full?' full':'');";
    j += "var lb=document.createElement('label');lb.textContent=labelText;";
    j += "d.appendChild(lb);d.appendChild(inputEl);return d;}";

    // Create a number input
    j += "function mkNum(varName,min,max,step){";
    j += "var inp=document.createElement('input');inp.type='number';inp.setAttribute('data-var',varName);";
    j += "if(min!==undefined&&min!==null)inp.min=min;if(max!==undefined&&max!==null)inp.max=max;";
    j += "inp.step=step||'1';";
    j += "inp.addEventListener('blur',function(){setVar(varName,this.value);});return inp;}";

    // Create a time input (displays m:ss.cc, stores ms integer)
    j += "function mkTime(varName){";
    j += "var inp=document.createElement('input');inp.type='text';inp.setAttribute('data-var',varName);";
    j += "inp.setAttribute('data-time','1');inp.placeholder='0:00.00';";
    j += "inp.addEventListener('blur',function(){var ms=parseTime(this.value);this.value=fmtTime(ms);setVar(varName,ms);});return inp;}";

    // Create a text input
    j += "function mkText(varName){";
    j += "var inp=document.createElement('input');inp.type='text';inp.setAttribute('data-var',varName);";
    j += "inp.addEventListener('blur',function(){setVar(varName,this.value);});return inp;}";

    // Create a textarea (for scripts)
    j += "function mkScript(varName){";
    j += "var ta=document.createElement('textarea');ta.setAttribute('data-var',varName);ta.rows=3;";
    j += "ta.setAttribute('data-script','1');";
    j += "ta.addEventListener('blur',function(){setVar(varName,displayToScript(this.value));});return ta;}";

    // Create a checkbox
    j += "function mkCheck(varName,labelText){";
    j += "var wrap=document.createElement('div');wrap.className='chk-row';";
    j += "var cb=document.createElement('input');cb.type='checkbox';cb.setAttribute('data-var',varName);cb.id='chk_'+varName;";
    j += "cb.addEventListener('change',function(){setVar(varName,this.checked?'true':'false');});";
    j += "var lb=document.createElement('label');lb.setAttribute('for','chk_'+varName);lb.textContent=labelText;";
    j += "wrap.appendChild(cb);wrap.appendChild(lb);return wrap;}";

    // Create a select
    j += "function mkSelect(varName,options){";
    j += "var sel=document.createElement('select');sel.setAttribute('data-var',varName);";
    j += "for(var i=0;i<options.length;i++){var o=document.createElement('option');o.value=options[i].value;o.textContent=options[i].text;sel.appendChild(o);}";
    j += "sel.addEventListener('change',function(){setVar(varName,this.value);});return sel;}";

    // Create a range input
    j += "function mkRange(varName,min,max,step){";
    j += "var wrap=document.createElement('div');wrap.className='range-wrap';";
    j += "var inp=document.createElement('input');inp.type='range';inp.setAttribute('data-var',varName);";
    j += "inp.min=min;inp.max=max;inp.step=step||'1';inp.value=min;";
    j += "var sp=document.createElement('span');sp.className='range-val';sp.textContent=String(min);";
    j += "inp.addEventListener('input',function(){sp.textContent=this.value;});";
    j += "inp.addEventListener('change',function(){setVar(varName,this.value);});";
    j += "wrap.appendChild(inp);wrap.appendChild(sp);return wrap;}";

    // Create vec3 inputs (3 numbers + optional copy button)
    j += "function mkVec3(varName,withCopy){";
    j += "var wrap=document.createElement('div');wrap.className='vec3-row';";
    j += "var labels=['X','Y','Z'];";
    j += "for(var i=0;i<3;i++){";
    j += "var inp=document.createElement('input');inp.type='number';inp.step='0.001';";
    j += "inp.setAttribute('data-var',varName);inp.setAttribute('data-vec3-idx',i);";
    j += "inp.placeholder=labels[i];";
    j += "inp.addEventListener('blur',function(){";
    j += "var inps=this.parentNode.querySelectorAll('input[type=number]');";
    j += "var v=inps[0].value+' '+inps[1].value+' '+inps[2].value;";
    j += "setVar(varName,v);});";
    j += "wrap.appendChild(inp);}";
    j += "if(withCopy){var btn=document.createElement('button');btn.className='btn-sm';btn.textContent='Copy Vehicle';";
    j += "btn.addEventListener('click',function(){";
    j += "fetch(apiBase+'/api/bf/copy-position',{method:'POST'}).then(function(r){return r.json();}).then(function(d){";
    j += "if(d.vehiclePosition){var inps=wrap.querySelectorAll('input[type=number]');";
    j += "inps[0].value=d.vehiclePosition.x.toFixed(3);inps[1].value=d.vehiclePosition.y.toFixed(3);inps[2].value=d.vehiclePosition.z.toFixed(3);";
    j += "setVar(varName,d.vehiclePosition.x+' '+d.vehiclePosition.y+' '+d.vehiclePosition.z);}});});";
    j += "wrap.appendChild(btn);}";
    j += "return wrap;}";

    // ---- Group Editor globals ----
    // Constants: group and scalar names (must match FinetunerBf.as exactly)
    j += "var GE_GROUPS=['Position','Rotation','Global Speed','Local Speed',";
    j += "'Front Left Wheel','Front Right Wheel','Back Right Wheel','Back Left Wheel'];";
    j += "var GE_SCALARS=['X Position','Y Position','Z Position',";
    j += "'Yaw','Pitch','Roll',";
    j += "'Global X Speed','Global Y Speed','Global Z Speed',";
    j += "'Local X Speed (Sideways)','Local Y Speed (Upwards)','Local Z Speed (Forwards)',";
    j += "'X Front Left Wheel','Y Front Left Wheel','Z Front Left Wheel',";
    j += "'X Front Right Wheel','Y Front Right Wheel','Z Front Right Wheel',";
    j += "'X Back Right Wheel','Y Back Right Wheel','Z Back Right Wheel',";
    j += "'X Back Left Wheel','Y Back Left Wheel','Z Back Left Wheel'];";

    // Parse groups: "v2.0.0|Name:0;Name:1;..." -> [{name,active}]
    j += "function geParseGroups(s){";
    j += "var result=[];for(var i=0;i<GE_GROUPS.length;i++)result.push({name:GE_GROUPS[i],active:false});";
    j += "if(!s||s.indexOf('|')===-1)return result;";
    j += "var parts=s.split('|');if(parts.length!==2)return result;";
    j += "var entries=parts[1].split(';');";
    j += "for(var i=0;i<entries.length;i++){";
    j += "var kv=entries[i].split(':');if(kv.length!==2)continue;";
    j += "var idx=GE_GROUPS.indexOf(kv[0]);if(idx===-1)continue;";
    j += "result[idx].active=kv[1]==='1';}";
    j += "return result;}";

    // Serialize groups: [{name,active}] -> "v2.0.0|Name:0;Name:1;..."
    j += "function geSerializeGroups(groups){";
    j += "var parts=[];for(var i=0;i<groups.length;i++){";
    j += "parts.push(groups[i].name+':'+(groups[i].active?'1':'0'));}";
    j += "return 'v2.0.0|'+parts.join(';');}";

    // Parse scalars: "v2.0.0|Name:lower,upper,valLow,valUp,dispLow,dispUp;..."
    j += "function geParseScalars(s){";
    j += "var result=[];for(var i=0;i<GE_SCALARS.length;i++)result.push({name:GE_SCALARS[i],lower:false,upper:false,valueLower:0,valueUpper:0,displayLower:0,displayUpper:0});";
    j += "if(!s||s.indexOf('|')===-1)return result;";
    j += "var parts=s.split('|');if(parts.length!==2)return result;";
    j += "var entries=parts[1].split(';');";
    j += "for(var i=0;i<entries.length;i++){";
    j += "var kv=entries[i].split(':');if(kv.length!==2)continue;";
    j += "var idx=GE_SCALARS.indexOf(kv[0]);if(idx===-1)continue;";
    j += "var vals=kv[1].split(',');if(vals.length!==6)continue;";
    j += "result[idx].lower=vals[0]==='1';";
    j += "result[idx].upper=vals[1]==='1';";
    j += "result[idx].valueLower=parseFloat(vals[2])||0;";
    j += "result[idx].valueUpper=parseFloat(vals[3])||0;";
    j += "result[idx].displayLower=parseFloat(vals[4])||0;";
    j += "result[idx].displayUpper=parseFloat(vals[5])||0;}";
    j += "return result;}";

    // Serialize scalars
    j += "function geSerializeScalars(scalars){";
    j += "var parts=[];for(var i=0;i<scalars.length;i++){var sc=scalars[i];";
    j += "parts.push(sc.name+':'+(sc.lower?'1':'0')+','+(sc.upper?'1':'0')+','+sc.valueLower+','+sc.valueUpper+','+sc.displayLower+','+sc.displayUpper);}";
    j += "return 'v2.0.0|'+parts.join(';');}";

    // Render the group editor detail panel for the selected group
    j += "function renderGroupEditor(es){";
    j += "var detail=document.getElementById('geDetail');if(!detail)return;";
    j += "while(detail.firstChild)detail.removeChild(detail.firstChild);";
    j += "var sel=document.getElementById('geGroupSel');if(!sel)return;";
    j += "var gi=parseInt(sel.value,10);if(gi<0)return;";
    j += "var grpStr=es.finetuner_common_groups||'';";
    j += "var sclStr=es.finetuner_common_scalars||'';";
    j += "var groups=geParseGroups(grpStr);";
    j += "var scalars=geParseScalars(sclStr);";
    j += "var grp=groups[gi];";

    // Group active checkbox
    j += "var gaRow=document.createElement('div');gaRow.className='ge-row';";
    j += "var gaLabel=document.createElement('label');gaLabel.textContent='Active';gaRow.appendChild(gaLabel);";
    j += "var gaCb=document.createElement('input');gaCb.type='checkbox';gaCb.checked=grp.active;";
    j += "gaCb.addEventListener('change',function(){";
    j += "var gs=geParseGroups(es.finetuner_common_groups||'');";
    j += "gs[gi].active=this.checked;";
    j += "var ser=geSerializeGroups(gs);";
    j += "es.finetuner_common_groups=ser;";
    j += "setVar('finetuner_common_groups',ser);});";
    j += "gaRow.appendChild(gaCb);detail.appendChild(gaRow);";

    // Scalars for this group (3 per group, at indices gi*3 .. gi*3+2)
    j += "for(var si=0;si<3;si++){";
    j += "(function(si){";
    j += "var scIdx=gi*3+si;";
    j += "var sc=scalars[scIdx];";
    j += "var scDiv=document.createElement('div');scDiv.className='ge-scalar';";
    j += "var scName=document.createElement('div');scName.className='ge-scalar-name';scName.textContent=GE_SCALARS[scIdx];";
    j += "scDiv.appendChild(scName);";

    // Lower bound row
    j += "var lbRow=document.createElement('div');lbRow.className='ge-bound';";
    j += "var lbCb=document.createElement('input');lbCb.type='checkbox';lbCb.checked=sc.lower;";
    j += "var lbLabel=document.createElement('label');lbLabel.textContent='Lower';";
    j += "var lbInp=document.createElement('input');lbInp.type='number';lbInp.step='0.001';lbInp.value=sc.displayLower;";
    j += "lbInp.disabled=!sc.lower;";
    j += "lbCb.addEventListener('change',function(){";
    j += "lbInp.disabled=!this.checked;";
    j += "var ss=geParseScalars(es.finetuner_common_scalars||'');";
    j += "ss[scIdx].lower=this.checked;";
    j += "var ser=geSerializeScalars(ss);";
    j += "es.finetuner_common_scalars=ser;";
    j += "setVar('finetuner_common_scalars',ser);});";
    j += "lbInp.addEventListener('blur',function(){";
    j += "var ss=geParseScalars(es.finetuner_common_scalars||'');";
    j += "ss[scIdx].displayLower=parseFloat(this.value)||0;";
    j += "var grpIdx=Math.floor(scIdx/3);";
    j += "if(grpIdx===1)ss[scIdx].valueLower=ss[scIdx].displayLower*Math.PI/180;";
    j += "else if(grpIdx===2||grpIdx===3)ss[scIdx].valueLower=ss[scIdx].displayLower/3.6;";
    j += "else ss[scIdx].valueLower=ss[scIdx].displayLower;";
    j += "var ser=geSerializeScalars(ss);";
    j += "es.finetuner_common_scalars=ser;";
    j += "setVar('finetuner_common_scalars',ser);});";
    j += "lbRow.appendChild(lbCb);lbRow.appendChild(lbLabel);lbRow.appendChild(lbInp);";
    j += "scDiv.appendChild(lbRow);";

    // Upper bound row
    j += "var ubRow=document.createElement('div');ubRow.className='ge-bound';";
    j += "var ubCb=document.createElement('input');ubCb.type='checkbox';ubCb.checked=sc.upper;";
    j += "var ubLabel=document.createElement('label');ubLabel.textContent='Upper';";
    j += "var ubInp=document.createElement('input');ubInp.type='number';ubInp.step='0.001';ubInp.value=sc.displayUpper;";
    j += "ubInp.disabled=!sc.upper;";
    j += "ubCb.addEventListener('change',function(){";
    j += "ubInp.disabled=!this.checked;";
    j += "var ss=geParseScalars(es.finetuner_common_scalars||'');";
    j += "ss[scIdx].upper=this.checked;";
    j += "var ser=geSerializeScalars(ss);";
    j += "es.finetuner_common_scalars=ser;";
    j += "setVar('finetuner_common_scalars',ser);});";
    j += "ubInp.addEventListener('blur',function(){";
    j += "var ss=geParseScalars(es.finetuner_common_scalars||'');";
    j += "ss[scIdx].displayUpper=parseFloat(this.value)||0;";
    j += "var grpIdx2=Math.floor(scIdx/3);";
    j += "if(grpIdx2===1)ss[scIdx].valueUpper=ss[scIdx].displayUpper*Math.PI/180;";
    j += "else if(grpIdx2===2||grpIdx2===3)ss[scIdx].valueUpper=ss[scIdx].displayUpper/3.6;";
    j += "else ss[scIdx].valueUpper=ss[scIdx].displayUpper;";
    j += "var ser=geSerializeScalars(ss);";
    j += "es.finetuner_common_scalars=ser;";
    j += "setVar('finetuner_common_scalars',ser);});";
    j += "ubRow.appendChild(ubCb);ubRow.appendChild(ubLabel);ubRow.appendChild(ubInp);";
    j += "scDiv.appendChild(ubRow);";

    j += "detail.appendChild(scDiv);";
    j += "})(si);}";
    j += "}";

    // Store the latest evalSettings ref for group/condition editor refresh from updateEvalValues
    j += "var geLastEs=null;";
    j += "var ceLastEs=null;";

    // ---- Condition Editor globals ----
    // Constants: condition names (must match FinetunerBf.as ConditionKind enum exactly)
    j += "var CE_CONDS=['Minimum Real Speed','Freewheeling','Sliding','Wheel Touching Wall','Wheel Contacts',";
    j += "'Checkpoints','RPM','Gear','Rear Gear','Glitching'];";

    // Parse conditions string: "v2.0.0|Name:active,value,valueMin,valueMax,display,displayMin,displayMax;..."
    j += "function ceParseConditions(s){";
    j += "var result=[];for(var i=0;i<CE_CONDS.length;i++)result.push({name:CE_CONDS[i],active:false,value:0,valueMin:0,valueMax:0,display:0,displayMin:0,displayMax:0});";
    j += "if(!s||s.indexOf('|')===-1)return result;";
    j += "var parts=s.split('|');if(parts.length!==2)return result;";
    j += "var entries=parts[1].split(';');";
    j += "for(var i=0;i<entries.length;i++){";
    j += "var kv=entries[i].split(':');if(kv.length!==2)continue;";
    j += "var idx=CE_CONDS.indexOf(kv[0]);if(idx===-1)continue;";
    j += "var vals=kv[1].split(',');if(vals.length!==7)continue;";
    j += "result[idx].active=vals[0]==='1';";
    j += "result[idx].value=parseFloat(vals[1])||0;";
    j += "result[idx].valueMin=parseFloat(vals[2])||0;";
    j += "result[idx].valueMax=parseFloat(vals[3])||0;";
    j += "result[idx].display=parseFloat(vals[4])||0;";
    j += "result[idx].displayMin=parseFloat(vals[5])||0;";
    j += "result[idx].displayMax=parseFloat(vals[6])||0;}";
    j += "return result;}";

    // Serialize conditions back: "v2.0.0|Name:active,value,valueMin,valueMax,display,displayMin,displayMax;..."
    j += "function ceSerializeConditions(conds){";
    j += "var parts=[];for(var i=0;i<conds.length;i++){var cd=conds[i];";
    j += "parts.push(cd.name+':'+(cd.active?'1':'0')+','+cd.value+','+cd.valueMin+','+cd.valueMax+','+cd.display+','+cd.displayMin+','+cd.displayMax);}";
    j += "return 'v2.0.0|'+parts.join(';');}";

    // Helper: re-parse conditions, apply a mutation, serialize and send
    j += "function ceSave(es,ci,mutate){";
    j += "var conds=ceParseConditions(es.finetuner_common_conditions||'');";
    j += "mutate(conds[ci]);";
    j += "var ser=ceSerializeConditions(conds);";
    j += "es.finetuner_common_conditions=ser;";
    j += "setVar('finetuner_common_conditions',ser);}";

    // Helper: create a labeled range slider row for condition editor
    j += "function ceMkRange(labelText,min,max,step,initVal,onChange){";
    j += "var row=document.createElement('div');row.className='ce-range-row';";
    j += "var lb=document.createElement('label');lb.textContent=labelText;row.appendChild(lb);";
    j += "var inp=document.createElement('input');inp.type='range';inp.min=min;inp.max=max;inp.step=step||'1';inp.value=initVal;";
    j += "var sp=document.createElement('span');sp.className='ce-range-val';sp.textContent=String(initVal);";
    j += "inp.addEventListener('input',function(){sp.textContent=this.value;});";
    j += "inp.addEventListener('change',function(){onChange(parseInt(this.value,10));});";
    j += "row.appendChild(inp);row.appendChild(sp);return row;}";

    // Render the condition editor detail panel for the selected condition
    j += "function renderConditionEditor(es){";
    j += "var detail=document.getElementById('ceDetail');if(!detail)return;";
    j += "while(detail.firstChild)detail.removeChild(detail.firstChild);";
    j += "var sel=document.getElementById('ceCondSel');if(!sel)return;";
    j += "var ci=parseInt(sel.value,10);if(ci<0)return;";
    j += "var condStr=es.finetuner_common_conditions||'';";
    j += "var conds=ceParseConditions(condStr);";
    j += "var cond=conds[ci];";

    // Active checkbox + Reset button row
    j += "var actRow=document.createElement('div');actRow.className='ce-row';";
    j += "var actLabel=document.createElement('label');actLabel.textContent='Active';actRow.appendChild(actLabel);";
    j += "var actCb=document.createElement('input');actCb.type='checkbox';actCb.checked=cond.active;";
    j += "actCb.addEventListener('change',function(){var chk=this.checked;ceSave(es,ci,function(cd){cd.active=chk;});});";
    j += "actRow.appendChild(actCb);";
    j += "var rstBtn=document.createElement('button');rstBtn.className='ce-reset';rstBtn.textContent='Reset';";
    j += "rstBtn.addEventListener('click',function(){ceSave(es,ci,function(cd){cd.active=false;cd.value=0;cd.valueMin=0;cd.valueMax=0;cd.display=0;cd.displayMin=0;cd.displayMax=0;});renderConditionEditor(es);});";
    j += "actRow.appendChild(rstBtn);";
    j += "detail.appendChild(actRow);";

    // Condition-specific fields container
    j += "var fields=document.createElement('div');fields.className='ce-fields';";

    // Kind 0: MIN_REAL_SPEED - float input (display km/h, value = display / 3.6)
    j += "if(ci===0){";
    j += "var fr=document.createElement('div');fr.className='ce-row';";
    j += "var fl=document.createElement('label');fl.textContent='Min Speed (km/h)';fr.appendChild(fl);";
    j += "var fi=document.createElement('input');fi.type='number';fi.step='0.1';fi.value=cond.display;";
    j += "fi.addEventListener('blur',function(){var v=parseFloat(this.value)||0;ceSave(es,ci,function(cd){cd.display=v;cd.value=v/3.6;});});";
    j += "fr.appendChild(fi);fields.appendChild(fr);";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "ht.textContent='The car MUST have a real speed of at least '+cond.display+' km/h in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    // Kinds 1,2,3,9: checkbox (FREEWHEELING, SLIDING, WHEEL_TOUCHING, GLITCHING)
    j += "if(ci===1||ci===2||ci===3||ci===9){";
    j += "var whatMap={1:'be free-wheeled',2:'be sliding',3:'have wheel(s) crashing into a wall',9:'be glitching'};";
    j += "var cr=document.createElement('div');cr.className='ce-row';";
    j += "var cl=document.createElement('label');cl.textContent='Required';cr.appendChild(cl);";
    j += "var ccb=document.createElement('input');ccb.type='checkbox';ccb.checked=cond.display!==0;";
    j += "ccb.addEventListener('change',function(){var v=this.checked?1:0;ceSave(es,ci,function(cd){cd.display=v;cd.value=v;});";
    j += "var htEl=fields.querySelector('.ce-hint');if(htEl)htEl.textContent='The car MUST'+(v?' ':' NOT ')+whatMap[ci]+' in the eval timeframe.';});";
    j += "cr.appendChild(ccb);fields.appendChild(cr);";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "ht.textContent='The car MUST'+(cond.display!==0?' ':' NOT ')+whatMap[ci]+' in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    // Kind 4: WHEEL_CONTACTS - two range sliders (int 0-4)
    j += "if(ci===4){";
    j += "fields.appendChild(ceMkRange('Min',0,4,'1',Math.round(cond.displayMin),function(v){ceSave(es,ci,function(cd){";
    j += "var mx=Math.round(cd.displayMax);if(v>mx){cd.displayMin=mx;cd.displayMax=v;}else{cd.displayMin=v;}";
    j += "cd.valueMin=cd.displayMin;cd.valueMax=cd.displayMax;});renderConditionEditor(es);}));";
    j += "fields.appendChild(ceMkRange('Max',0,4,'1',Math.round(cond.displayMax),function(v){ceSave(es,ci,function(cd){";
    j += "var mn=Math.round(cd.displayMin);if(v<mn){cd.displayMax=mn;cd.displayMin=v;}else{cd.displayMax=v;}";
    j += "cd.valueMin=cd.displayMin;cd.valueMax=cd.displayMax;});renderConditionEditor(es);}));";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "var mn=Math.round(cond.displayMin);var mx=Math.round(cond.displayMax);";
    j += "ht.textContent='The car MUST have '+(mn===mx?'exactly '+mn:'between '+mn+' and '+mx)+' wheels contacting the ground in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    // Kind 5: CHECKPOINTS - int input (value = display)
    j += "if(ci===5){";
    j += "var fr=document.createElement('div');fr.className='ce-row';";
    j += "var fl=document.createElement('label');fl.textContent='Checkpoints';fr.appendChild(fl);";
    j += "var fi=document.createElement('input');fi.type='number';fi.step='1';fi.min='0';fi.value=Math.round(cond.display);";
    j += "fi.addEventListener('blur',function(){var v=parseInt(this.value,10)||0;ceSave(es,ci,function(cd){cd.display=v;cd.value=v;});});";
    j += "fr.appendChild(fi);fields.appendChild(fr);";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "ht.textContent='The car MUST have exactly '+Math.round(cond.display)+' checkpoints in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    // Kind 6: RPM - two float inputs (min/max)
    j += "if(ci===6){";
    j += "var mrMin=document.createElement('div');mrMin.className='ce-row';";
    j += "var mlMin=document.createElement('label');mlMin.textContent='Min RPM';mrMin.appendChild(mlMin);";
    j += "var miMin=document.createElement('input');miMin.type='number';miMin.step='1';miMin.value=cond.displayMin;";
    j += "mrMin.appendChild(miMin);fields.appendChild(mrMin);";
    j += "var mrMax=document.createElement('div');mrMax.className='ce-row';";
    j += "var mlMax=document.createElement('label');mlMax.textContent='Max RPM';mrMax.appendChild(mlMax);";
    j += "var miMax=document.createElement('input');miMax.type='number';miMax.step='1';miMax.value=cond.displayMax;";
    j += "mrMax.appendChild(miMax);fields.appendChild(mrMax);";
    j += "miMin.addEventListener('blur',function(){var vn=parseFloat(miMin.value)||0;var vx=parseFloat(miMax.value)||0;";
    j += "var lo=Math.min(vn,vx);var hi=Math.max(vn,vx);miMin.value=lo;miMax.value=hi;";
    j += "ceSave(es,ci,function(cd){cd.displayMin=lo;cd.displayMax=hi;cd.valueMin=lo;cd.valueMax=hi;});});";
    j += "miMax.addEventListener('blur',function(){var vn=parseFloat(miMin.value)||0;var vx=parseFloat(miMax.value)||0;";
    j += "var lo=Math.min(vn,vx);var hi=Math.max(vn,vx);miMin.value=lo;miMax.value=hi;";
    j += "ceSave(es,ci,function(cd){cd.displayMin=lo;cd.displayMax=hi;cd.valueMin=lo;cd.valueMax=hi;});});";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "var mn=cond.displayMin;var mx=cond.displayMax;";
    j += "ht.textContent='The car MUST have '+(mn===mx?'exactly '+mn:'between '+mn+' and '+mx)+' RPM in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    // Kind 7: GEAR - two range sliders (int 0-5)
    j += "if(ci===7){";
    j += "fields.appendChild(ceMkRange('Min',0,5,'1',Math.round(cond.displayMin),function(v){ceSave(es,ci,function(cd){";
    j += "var mx=Math.round(cd.displayMax);if(v>mx){cd.displayMin=mx;cd.displayMax=v;}else{cd.displayMin=v;}";
    j += "cd.valueMin=cd.displayMin;cd.valueMax=cd.displayMax;});renderConditionEditor(es);}));";
    j += "fields.appendChild(ceMkRange('Max',0,5,'1',Math.round(cond.displayMax),function(v){ceSave(es,ci,function(cd){";
    j += "var mn=Math.round(cd.displayMin);if(v<mn){cd.displayMax=mn;cd.displayMin=v;}else{cd.displayMax=v;}";
    j += "cd.valueMin=cd.displayMin;cd.valueMax=cd.displayMax;});renderConditionEditor(es);}));";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "var mn=Math.round(cond.displayMin);var mx=Math.round(cond.displayMax);";
    j += "ht.textContent='The car MUST have '+(mn===mx?'exactly '+mn:'between '+mn+' and '+mx)+' gears in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    // Kind 8: REAR_GEAR - two range sliders (int 0-1)
    j += "if(ci===8){";
    j += "fields.appendChild(ceMkRange('Min',0,1,'1',Math.round(cond.displayMin),function(v){ceSave(es,ci,function(cd){";
    j += "var mx=Math.round(cd.displayMax);if(v>mx){cd.displayMin=mx;cd.displayMax=v;}else{cd.displayMin=v;}";
    j += "cd.valueMin=cd.displayMin;cd.valueMax=cd.displayMax;});renderConditionEditor(es);}));";
    j += "fields.appendChild(ceMkRange('Max',0,1,'1',Math.round(cond.displayMax),function(v){ceSave(es,ci,function(cd){";
    j += "var mn=Math.round(cd.displayMin);if(v<mn){cd.displayMax=mn;cd.displayMin=v;}else{cd.displayMax=v;}";
    j += "cd.valueMin=cd.displayMin;cd.valueMax=cd.displayMax;});renderConditionEditor(es);}));";
    j += "var ht=document.createElement('div');ht.className='ce-hint';";
    j += "var mn=Math.round(cond.displayMin);var mx=Math.round(cond.displayMax);";
    j += "ht.textContent='The car MUST have '+(mn===mx?'exactly '+mn:'between '+mn+' and '+mx)+' rear gears in the eval timeframe.';";
    j += "fields.appendChild(ht);}";

    j += "detail.appendChild(fields);";
    j += "}"; // end renderConditionEditor

    return j;
}

// ============================================================
// JS: Status polling + Map loading
// ============================================================

string BfDashJS_Status()
{
    string j = "";

    j += "var pollOk=false;";

    // Status polling
    j += "function pollStatus(){";
    j += "fetch(apiBase+'/api/bf/status').then(function(r){return r.json();}).then(function(d){pollOk=true;";
    j += "var cn=document.getElementById('conn');cn.textContent='Connected';cn.style.background='#3fb95030';cn.style.color='#3fb950';";
    j += "var st=document.getElementById('bfState');st.textContent=d.running?'Running':'Idle';st.className='badge '+(d.running?'running':'idle');";
    j += "var ph=document.getElementById('bfPhase');ph.textContent=d.phase;ph.className='badge '+(d.phase==='Initial'?'initial':d.phase==='Search'?'search':'idle');";
    j += "setText('bfTarget',d.target||'-');";
    j += "setText('bfElapsed',fmtDur(d.elapsedMs||0));";
    j += "setText('bfIter',fmtNum(d.iterations||0));";
    j += "setText('bfIterSec',(d.iterationsPerSec||0).toFixed(1));";
    j += "setText('bfRestarts',d.restarts||0);";
    j += "setText('bfImpCount',d.improvements||0);";
    // Track bfIsRunning transitions
    j += "var wasRunning = bfIsRunning;";
    j += "bfIsRunning = d.running;";
    j += "if (wasRunning === null) { updateApplyBar(); }";
    j += "if (wasRunning && !bfIsRunning) {";
    j += "var count = Object.keys(dirtyVars).length;";
    j += "if (count > 0) {";
    j += "applyAllDirty();";
    j += "showToast('BF ended. ' + count + ' pending change(s) applied.');}";
    j += "updateApplyBar();}";
    j += "if (!wasRunning && bfIsRunning) {";
    j += "dirtyVars = {};";
    j += "markAllClean();";
    j += "updateApplyBar();}";
    j += "}).catch(function(){";
    j += "if(pollOk){pollOk=false;var cn=document.getElementById('conn');cn.textContent='Disconnected';cn.style.background='#f8514930';cn.style.color='#f85149';}";
    j += "});}";
    j += "setInterval(pollStatus,1000);pollStatus();";

    // Map
    j += "function loadMap(){";
    j += "fetch(apiBase+'/api/map').then(function(r){return r.json();}).then(function(d){";
    j += "setText('mapName',d.loaded?d.name:'No map');";
    j += "setText('mapAuthor',d.loaded?d.author:'-');";
    j += "setText('mapUid',d.loaded?d.uid:'-');";
    j += "}).catch(function(){});}";
    j += "loadMap();setInterval(loadMap,10000);";

    // Multi-instance: resilient scanning with last-seen tracking
    j += "var SCAN_START=8489,SCAN_END=8520;";
    j += "var SCAN_TIMEOUT=2000;";  // 2s timeout for BF-busy servers
    j += "var MISS_THRESHOLD=3;";   // remove after 3 consecutive misses (~9s)
    j += "var DISCOVERY_INTERVAL=15000;";  // full port scan every 15s
    j += "var KNOWN_INTERVAL=3000;";       // probe known instances every 3s
    j += "var instanceLastSeen={};";  // port -> {data, missCount, lastSuccess}
    j += "var lastFullScanTime=0;";

    // Probe a single port, returns a Promise
    j += "function probePort(port){";
    j += "return new Promise(function(resolve){";
    j += "var ctrl=new AbortController();var t=setTimeout(function(){ctrl.abort();},SCAN_TIMEOUT);";
    j += "fetch('http://localhost:'+port+'/api/bf/status',{signal:ctrl.signal})";
    j += ".then(function(r){clearTimeout(t);return r.json();})";
    j += ".then(function(d){resolve({port:port,target:d.target||'-',running:d.running,ok:true});})";
    j += ".catch(function(){clearTimeout(t);resolve({port:port,ok:false});});";
    j += "});}";

    // Scan known instances (fast, every 3s)
    j += "function scanKnownInstances(){";
    j += "var knownPorts=Object.keys(instanceLastSeen);";
    j += "if(knownPorts.length===0)return Promise.resolve();";
    j += "var probes=[];";
    j += "for(var i=0;i<knownPorts.length;i++){probes.push(probePort(parseInt(knownPorts[i])));}";
    j += "return Promise.all(probes).then(function(results){";
    j += "for(var i=0;i<results.length;i++){var r=results[i];var pk=String(r.port);";
    j += "if(r.ok){instanceLastSeen[pk]={data:{port:r.port,target:r.target,running:r.running},missCount:0,lastSuccess:Date.now()};}";
    j += "else{if(instanceLastSeen[pk]){instanceLastSeen[pk].missCount++;";
    j += "if(instanceLastSeen[pk].missCount>=MISS_THRESHOLD){delete instanceLastSeen[pk];}}}}";
    j += "onScanDone();});}";

    // Full discovery scan (slow, every 15s) - probes all ports
    j += "function scanDiscovery(){";
    j += "lastFullScanTime=Date.now();";
    j += "var probes=[];";
    j += "for(var p=SCAN_START;p<=SCAN_END;p++){probes.push(probePort(p));}";
    j += "return Promise.all(probes).then(function(results){";
    j += "for(var i=0;i<results.length;i++){var r=results[i];var pk=String(r.port);";
    j += "if(r.ok){instanceLastSeen[pk]={data:{port:r.port,target:r.target,running:r.running},missCount:0,lastSuccess:Date.now()};}";
    j += "else{if(instanceLastSeen[pk]){instanceLastSeen[pk].missCount++;";
    j += "if(instanceLastSeen[pk].missCount>=MISS_THRESHOLD){delete instanceLastSeen[pk];}}}}";
    j += "onScanDone();});}";

    // Main scan dispatcher
    j += "function scanInstances(){";
    j += "var now=Date.now();";
    j += "if(now-lastFullScanTime>=DISCOVERY_INTERVAL||Object.keys(instanceLastSeen).length===0){scanDiscovery();}";
    j += "else{scanKnownInstances();}}";

    j += "function onScanDone(){";
    j += "var found=[];var keys=Object.keys(instanceLastSeen);";
    j += "for(var i=0;i<keys.length;i++){found.push(instanceLastSeen[keys[i]].data);}";
    j += "found.sort(function(a,b){return a.port-b.port;});";
    j += "instances=found;";
    j += "if(found.length>0){";
    j += "var stillExists=false;for(var si=0;si<found.length;si++){if(found[si].port===activeInstancePort)stillExists=true;}";
    j += "if(!stillExists||activeInstancePort===0){activeInstancePort=found[0].port;apiBase='http://localhost:'+found[0].port;}}";
    j += "renderInstances();";
    j += "updateLiveCards(found);}";

    j += "var lastInstKey='';";
    j += "function renderInstances(){";
    j += "var bar=document.getElementById('instanceBar');";
    j += "if(instances.length===0){while(bar.firstChild)bar.removeChild(bar.firstChild);lastInstKey='';return;}";
    j += "bar.className='instance-bar';";
    j += "var key=instances.map(function(i){return i.port;}).join(',');";
    j += "if(key!==lastInstKey){";
    j += "lastInstKey=key;";
    j += "while(bar.firstChild)bar.removeChild(bar.firstChild);";
    j += "for(var i=0;i<instances.length;i++){";
    j += "(function(inst,idx){";
    j += "var btn=document.createElement('button');btn.id='instBtn'+inst.port;";
    j += "btn.addEventListener('click',function(){switchInstance(inst.port);});";
    j += "bar.appendChild(btn);";
    j += "})(instances[i],i);}}";
    j += "for(var i=0;i<instances.length;i++){";
    j += "var btn=document.getElementById('instBtn'+instances[i].port);if(!btn)continue;";
    j += "btn.className='inst-btn'+(activeInstancePort===instances[i].port?' active':'');";
    j += "var lbl=instances[i].running?'BF: '+instances[i].target:'Idle';";
    j += "btn.textContent='Instance '+(i+1)+' :'+instances[i].port+' ('+lbl+')';}}";

    j += "function switchInstance(port){";
    j += "if(activeInstancePort>0){";
    j += "perInstanceState[activeInstancePort]={";
    j += "dirtyVars:dirtyVars,";
    j += "serverSnapshot:serverSnapshot,";
    j += "bfIsRunning:bfIsRunning,";
    j += "lastLogLen:lastLogLen,";
    j += "lastImpLen:lastImpLen,";
    j += "activeSession:activeSession,";
    j += "activeSubTab:activeSubTab,";
    j += "prevTarget:prevTarget,";
    j += "prevSlotAlgos:prevSlotAlgos,";
    j += "lastSlotCount:lastSlotCount};}";
    j += "activeInstancePort=port;";
    j += "apiBase='http://localhost:'+port;";
    j += "var saved=perInstanceState[port];";
    j += "if(saved){";
    j += "dirtyVars=saved.dirtyVars;";
    j += "serverSnapshot=saved.serverSnapshot;";
    j += "bfIsRunning=saved.bfIsRunning;";
    j += "lastLogLen=saved.lastLogLen;";
    j += "lastImpLen=saved.lastImpLen;";
    j += "activeSession=saved.activeSession;";
    j += "activeSubTab=saved.activeSubTab;";
    j += "prevTarget=saved.prevTarget;";
    j += "prevSlotAlgos=saved.prevSlotAlgos;";
    j += "lastSlotCount=saved.lastSlotCount;";
    j += "}else{";
    j += "dirtyVars={};";
    j += "serverSnapshot={};";
    j += "bfIsRunning=null;";
    j += "lastLogLen=-1;";
    j += "lastImpLen=-1;";
    j += "activeSession=null;";
    j += "activeSubTab='imp';";
    j += "prevTarget='';";
    j += "prevSlotAlgos='';";
    j += "lastSlotCount=-1;}";
    j += "markAllClean();";
    j += "updateApplyBar();";
    j += "renderInstances();";
    j += "pollStatus();";
    j += "pollSettings();";
    j += "pollSessions();";
    j += "loadSessionData();";
    j += "loadMap();}";

    j += "setInterval(scanInstances,KNOWN_INTERVAL);scanInstances();";

    return j;
}

// ============================================================
// JS: Settings polling + rendering
// ============================================================

string BfDashJS_Settings()
{
    string j = "";

    j += "var allCfg=null;var lastSlotCount=-1;";

    // Build the eval-specific fields based on target
    j += "function buildEvalFields(cfg){";
    j += "var c=document.getElementById('evalFields');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "var t=cfg.target;var es=cfg.evalSettings;var trigs=cfg.triggers||[];";

    // Helper to make trigger select options
    j += "function trigOpts(includeNone){var opts=[];if(includeNone)opts.push({value:'0',text:'None'});";
    j += "for(var i=0;i<trigs.length;i++){var ti=trigs[i];var p=ti.position;";
    j += "opts.push({value:String(ti.index),text:'#'+ti.index+' ('+p.x.toFixed(1)+', '+p.y.toFixed(1)+', '+p.z.toFixed(1)+')'});}return opts;}";

    // precisefinish
    j += "if(t==='precisefinish'){return;}";

    // precisecheckpoint
    j += "if(t==='precisecheckpoint'){";
    j += "c.appendChild(mkFieldRow('Target CP',mkNum('bf_target_cp',0)));return;}";

    // precisetrigger
    j += "if(t==='precisetrigger'){";
    j += "c.appendChild(mkFieldRow('Trigger',mkSelect('bf_target_trigger',trigOpts(false))));return;}";

    // standardtrigger
    j += "if(t==='standardtrigger'){";
    j += "c.appendChild(mkFieldRow('Trigger',mkSelect('bf_stdtrigger_trigger',trigOpts(false))));";
    j += "c.appendChild(mkFieldRow('Ratio',mkRange('bf_stdtrigger_weight',0,100)));return;}";

    // betterpoint
    j += "if(t==='betterpoint'){";
    j += "c.appendChild(mkFieldRow('Ratio',mkRange('bf_weight',0,100)));";
    j += "c.appendChild(mkFieldRow('Target Position',mkVec3('bf_target_point',true),true));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('bf_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('bf_eval_max_time')));";
    j += "c.appendChild(mkFieldRow('Shift Threshold',mkNum('bf_singlepoint_shift_threshold',null,null,'0.001')));";
    j += "c.appendChild(mkFieldRow('Max Distance',mkNum('bf_condition_distance',null,null,'0.001')));";
    j += "var chk=mkCheck('bf_ignore_same_speed','Ignore Same Speed');chk.className+=' full';c.appendChild(chk);return;}";

    // velocity
    j += "if(t==='velocity'){";
    j += "var vTypeOpts=[{value:'Global',text:'Global'},{value:'Trajectory',text:'Trajectory'}];";
    j += "c.appendChild(mkFieldRow('Type',mkSelect('bf_velocity_type',vTypeOpts)));";
    j += "c.appendChild(mkFieldRow('From Direction',mkVec3('bf_velocity_from',false),true));";
    j += "c.appendChild(mkFieldRow('To Direction',mkVec3('bf_velocity_to',false),true));";
    j += "c.appendChild(mkFieldRow('Min Matching Velocity',mkRange('bf_velocity_min_percent',-1.0,1.0,0.01)));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('bf_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('bf_eval_max_time')));return;}";

    // distance_target
    j += "if(t==='distance_target'){";
    j += "var dtOpts=[{value:'0',text:'CP'},{value:'1',text:'Finish'}];";
    j += "c.appendChild(mkFieldRow('Target Type',mkSelect('dist_bf_target_type',dtOpts)));";
    j += "c.appendChild(mkFieldRow('CP Index',mkNum('dist_bf_target_cp_index',0)));";
    j += "var chk1=mkCheck('dist_bf_show_cp_numbers','Show CP Numbers');c.appendChild(chk1);";
    j += "var chk2=mkCheck('dist_bf_shift_cp_eval','Shift CP Eval');c.appendChild(chk2);";
    j += "var chk3=mkCheck('dist_bf_shift_finish_eval','Shift Finish Eval');c.appendChild(chk3);";
    j += "c.appendChild(mkFieldRow('Time From',mkTime('dist_bf_bf_time_from')));";
    j += "c.appendChild(mkFieldRow('Time To',mkTime('dist_bf_bf_time_to')));";
    j += "c.appendChild(mkFieldRow('Trigger Constraint',mkNum('dist_bf_constraint_trigger_index',0)));return;}";

    // uberbug_target
    j += "if(t==='uberbug_target'){";
    j += "var modeOpts=[{value:'Find',text:'Find'},{value:'Optimize',text:'Optimize'}];";
    j += "c.appendChild(mkFieldRow('Mode',mkSelect('uber_bf_uberbug_mode',modeOpts)));";
    j += "var findOpts=[{value:'Single',text:'Single'},{value:'Collect many',text:'Collect many'},{value:'Keep best',text:'Keep best'}];";
    j += "c.appendChild(mkFieldRow('Find Mode',mkSelect('uber_bf_uberbug_find_mode',findOpts)));";
    j += "c.appendChild(mkFieldRow('Amount',mkNum('uber_bf_uberbug_amount',1)));";
    j += "c.appendChild(mkFieldRow('Result File',mkText('uber_bf_uberbug_result_file')));";
    j += "c.appendChild(mkFieldRow('Point1',mkVec3('uber_bf_uberbug_point1',false),true));";
    j += "c.appendChild(mkFieldRow('Point2',mkVec3('uber_bf_uberbug_point2',false),true));";
    j += "c.appendChild(mkFieldRow('Threshold',mkNum('uber_bf_uberbug_threshold',null,null,'0.001')));";
    j += "c.appendChild(mkFieldRow('Time From',mkTime('uber_bf_bf_time_from')));";
    j += "c.appendChild(mkFieldRow('Time To',mkTime('uber_bf_bf_time_to')));";
    j += "c.appendChild(mkFieldRow('Min Speed',mkNum('uber_bf_uberbug_min_speed',null,null,'0.1')));return;}";

    // clbf
    j += "if(t==='clbf'){";
    j += "c.appendChild(mkFieldRow('Target Position',mkVec3('clbf_bf_target_position',true),true));";
    j += "c.appendChild(mkFieldRow('Yaw',mkRange('clbf_bf_target_rotation_yaw',-180,180)));";
    j += "c.appendChild(mkFieldRow('Pitch',mkRange('clbf_bf_target_rotation_pitch',-180,180)));";
    j += "c.appendChild(mkFieldRow('Roll',mkRange('clbf_bf_target_rotation_roll',-180,180)));";
    j += "c.appendChild(mkFieldRow('Weight',mkRange('clbf_bf_weight',0,100)));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('clbf_bf_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('clbf_bf_eval_max_time')));return;}";

    // time
    j += "if(t==='time'){";
    j += "c.appendChild(mkFieldRow('Minimum Time',mkTime('timebf_min_time')));return;}";

    // customtarget
    j += "if(t==='customtarget'){";
    j += "c.appendChild(mkFieldRow('Script',mkScript('bf_customtarget_script'),true));";
    j += "c.appendChild(mkFieldRow('Eval Time From',mkTime('bf_customtarget_eval_min_time')));";
    j += "c.appendChild(mkFieldRow('Eval Time To',mkTime('bf_customtarget_eval_max_time')));return;}";

    // finetuner
    j += "if(t==='finetuner'){";
    j += "c.appendChild(mkFieldRow('Evaluate From',mkTime('finetuner_eval_from')));";
    j += "c.appendChild(mkFieldRow('Evaluate To',mkTime('finetuner_eval_to')));";
    j += "var chkGrp=mkCheck('finetuner_target_grouped');c.appendChild(mkFieldRow('Grouped Target?',chkGrp));";
    j += "var grpOpts=[{value:'0',text:'Position'},{value:'1',text:'Rotation'},{value:'2',text:'Global Speed'},{value:'3',text:'Local Speed'},{value:'4',text:'Front Left Wheel'},{value:'5',text:'Front Right Wheel'},{value:'6',text:'Back Right Wheel'},{value:'7',text:'Back Left Wheel'}];";
    j += "c.appendChild(mkFieldRow('Target (Group)',mkSelect('finetuner_target_group',grpOpts)));";
    j += "var sclOpts=[{value:'0',text:'X Position'},{value:'1',text:'Y Position'},{value:'2',text:'Z Position'},{value:'3',text:'Yaw'},{value:'4',text:'Pitch'},{value:'5',text:'Roll'},{value:'6',text:'Global X Speed'},{value:'7',text:'Global Y Speed'},{value:'8',text:'Global Z Speed'},{value:'9',text:'Local X Speed (Sideways)'},{value:'10',text:'Local Y Speed (Upwards)'},{value:'11',text:'Local Z Speed (Forwards)'},{value:'12',text:'X Front Left Wheel'},{value:'13',text:'Y Front Left Wheel'},{value:'14',text:'Z Front Left Wheel'},{value:'15',text:'X Front Right Wheel'},{value:'16',text:'Y Front Right Wheel'},{value:'17',text:'Z Front Right Wheel'},{value:'18',text:'X Back Right Wheel'},{value:'19',text:'Y Back Right Wheel'},{value:'20',text:'Z Back Right Wheel'},{value:'21',text:'X Back Left Wheel'},{value:'22',text:'Y Back Left Wheel'},{value:'23',text:'Z Back Left Wheel'}];";
    j += "c.appendChild(mkFieldRow('Target (Scalar)',mkSelect('finetuner_target_scalar',sclOpts)));";
    j += "c.appendChild(mkFieldRow('Target Towards',mkRange('finetuner_target_towards',-1,1,1)));";
    j += "c.appendChild(mkFieldRow('Target Value',mkNum('finetuner_target_value_display',null,null,0.1)));";
    j += "c.appendChild(mkFieldRow('Target Values',mkVec3('finetuner_target_vec3_display',true),true));";
    j += "var chkPrint=mkCheck('finetuner_print_by_component');c.appendChild(mkFieldRow('Print Group values by component?',chkPrint));";

    // ---- Group Editor DOM ----
    j += "var geWrap=document.createElement('div');geWrap.className='ge-wrap';";
    j += "var geTitle=document.createElement('div');geTitle.className='ge-title';geTitle.textContent='Group Editor';";
    j += "geWrap.appendChild(geTitle);";
    j += "var geBody=document.createElement('div');geBody.className='ge-body';";
    j += "geWrap.appendChild(geBody);";
    j += "c.appendChild(geWrap);";

    // Group selector row
    j += "var geSelRow=document.createElement('div');geSelRow.className='ge-row';";
    j += "var geSelLabel=document.createElement('label');geSelLabel.textContent='Group';geSelRow.appendChild(geSelLabel);";
    j += "var geSel=document.createElement('select');geSel.id='geGroupSel';";
    j += "var geHideOpt=document.createElement('option');geHideOpt.value='-1';geHideOpt.textContent='<Hide>';geSel.appendChild(geHideOpt);";
    j += "for(var gi=0;gi<GE_GROUPS.length;gi++){var go=document.createElement('option');go.value=String(gi);go.textContent=GE_GROUPS[gi];geSel.appendChild(go);}";
    j += "geSelRow.appendChild(geSel);";
    j += "geBody.appendChild(geSelRow);";

    // Detail container
    j += "var geDetail=document.createElement('div');geDetail.id='geDetail';geBody.appendChild(geDetail);";

    // Wire up select change and store es ref for polling refresh
    j += "geLastEs=es;";
    j += "geSel.addEventListener('change',function(){renderGroupEditor(geLastEs);});";

    // Initial render
    j += "renderGroupEditor(es);";

    // ---- Condition Editor DOM ----
    j += "var ceWrap=document.createElement('div');ceWrap.className='ce-wrap';";
    j += "var ceTitle=document.createElement('div');ceTitle.className='ce-title';ceTitle.textContent='Condition Editor';";
    j += "ceWrap.appendChild(ceTitle);";
    j += "var ceBody=document.createElement('div');ceBody.className='ce-body';";
    j += "ceWrap.appendChild(ceBody);";
    j += "c.appendChild(ceWrap);";

    // Condition selector row
    j += "var ceSelRow=document.createElement('div');ceSelRow.className='ce-row';";
    j += "var ceSelLabel=document.createElement('label');ceSelLabel.textContent='Condition';ceSelRow.appendChild(ceSelLabel);";
    j += "var ceSel=document.createElement('select');ceSel.id='ceCondSel';";
    j += "var ceHideOpt=document.createElement('option');ceHideOpt.value='-1';ceHideOpt.textContent='<Hide>';ceSel.appendChild(ceHideOpt);";
    j += "for(var ci=0;ci<CE_CONDS.length;ci++){var co=document.createElement('option');co.value=String(ci);co.textContent=CE_CONDS[ci];ceSel.appendChild(co);}";
    j += "ceSelRow.appendChild(ceSel);";
    j += "ceBody.appendChild(ceSelRow);";

    // Detail container for selected condition
    j += "var ceDetail=document.createElement('div');ceDetail.id='ceDetail';ceBody.appendChild(ceDetail);";

    // Wire up condition select change and store es ref for polling refresh
    j += "ceLastEs=es;";
    j += "ceSel.addEventListener('change',function(){renderConditionEditor(ceLastEs);});";

    // Initial render
    j += "renderConditionEditor(es);";

    j += "return;}";

    // nosepos_plus
    j += "if(t==='nosepos_plus'){";
    j += "c.appendChild(mkFieldRow('Eval time min',mkTime('shweetz_eval_time_min')));";
    j += "c.appendChild(mkFieldRow('Eval time max',mkTime('shweetz_eval_time_max')));";
    j += "c.appendChild(mkFieldRow('Target yaw (\\u00b0) (90 for left gs and uber, -90 for right)',mkNum('shweetz_yaw_deg',null,null,1)));";
    j += "c.appendChild(mkFieldRow('Target pitch (\\u00b0) (85 to 90 for nosepos, 0 for gs, -25 for uber)',mkNum('shweetz_pitch_deg',null,null,1)));";
    j += "c.appendChild(mkFieldRow('Target roll (\\u00b0) (usually 0)',mkNum('shweetz_roll_deg',null,null,1)));";
    j += "var chkYaw=mkCheck('shweetz_allow_yaw_180');c.appendChild(mkFieldRow('Accept any yaw for nosepos (uncheck for yaw bruteforce)',chkYaw));";
    j += "var chkNext=mkCheck('shweetz_next_eval_check');c.appendChild(mkFieldRow('Change eval after nosepos is good enough',chkNext));";
    // Conditional block: only shown when next_eval_check is true (matching in-game order: angle first, then combo + point)
    j += "var npCondDiv=document.createElement('div');npCondDiv.id='npCondBlock';c.appendChild(npCondDiv);";
    j += "c.appendChild(mkFieldRow('Min speed (km/h)',mkRange('shweetz_condition_speed',0,1000,0.1)));";
    j += "c.appendChild(mkFieldRow('Min CP collected',mkNum('shweetz_min_cp',0,null,1)));";
    j += "c.appendChild(mkFieldRow('Min wheels on ground',mkRange('shweetz_min_wheels_on_ground',0,4,1)));";
    j += "c.appendChild(mkFieldRow('Gear (0 to disable)',mkRange('shweetz_gear',-1,6,1)));";
    j += "c.appendChild(mkFieldRow('Trigger index (0 to disable)',mkNum('shweetz_trigger_index',0,null,1)));";
    j += "c.appendChild(mkFieldRow('Anti-Trigger index (0 to disable)',mkNum('shweetz_antitrigger_index',0,null,1)));";
    j += "c.appendChild(mkFieldRow('Tick to print if conditions are met (0 to disable)',mkTime('shweetz_debug')));";
    j += "return;}";

    // NoseposPlus conditional block updater (called from updateEvalValues)
    j += "function updateNpCondBlock(es){";
    j += "var blk=document.getElementById('npCondBlock');if(!blk)return;";
    j += "while(blk.firstChild)blk.removeChild(blk.firstChild);";
    j += "var nextCheck=es['shweetz_next_eval_check'];";
    j += "if(!nextCheck)return;";
    j += "blk.appendChild(mkFieldRow('Max angle from ideal (\\u00b0)',mkNum('shweetz_angle_min_deg',0,null,1)));";
    j += "var nextOpts=[{value:'Point',text:'Point'},{value:'Speed',text:'Speed'},{value:'Time',text:'Time'},{value:'Hold',text:'Hold'}];";
    j += "blk.appendChild(mkFieldRow('Next eval',mkSelect('shweetz_next_eval',nextOpts)));";
    j += "var nextMode=es['shweetz_next_eval']||'Point';";
    j += "var nSel=blk.querySelector('[data-var=\"shweetz_next_eval\"]');if(nSel)nSel.value=nextMode;";
    j += "if(nextMode==='Point'){";
    j += "blk.appendChild(mkFieldRow('Point',mkVec3('shweetz_point',true),true));}";
    j += "var angleEl=blk.querySelector('[data-var=\"shweetz_angle_min_deg\"]');if(angleEl&&es['shweetz_angle_min_deg']!==undefined)angleEl.value=es['shweetz_angle_min_deg'];";
    j += "}";

    j += "}";

    // Update eval fields with values from cfg
    j += "function updateEvalValues(cfg){";
    j += "var es=cfg.evalSettings;if(!es)return;";
    j += "var keys=Object.keys(es);";
    j += "for(var i=0;i<keys.length;i++){";
    j += "var k=keys[i];var val=es[k];";
    // Handle vec3 objects
    j += "if(val!==null&&typeof val==='object'&&'x' in val){";
    j += "var inps=document.querySelectorAll('input[data-var=\"'+k+'\"][data-vec3-idx]');";
    j += "if(inps.length===3){setField(inps[0],val.x.toFixed(3));setField(inps[1],val.y.toFixed(3));setField(inps[2],val.z.toFixed(3));}";
    j += "continue;}";
    // Handle time fields
    j += "var tEl=document.querySelector('[data-var=\"'+k+'\"][data-time]');";
    j += "if(tEl){setField(tEl,fmtTime(val));continue;}";
    // Handle script fields
    j += "var sEl=document.querySelector('[data-var=\"'+k+'\"][data-script]');";
    j += "if(sEl){if(!isFocused(sEl))sEl.value=scriptToDisplay(val);continue;}";
    // Handle regular fields
    j += "var el=document.querySelector('[data-var=\"'+k+'\"]');";
    j += "if(el){setField(el,val);}";
    j += "}";
    // Refresh group editor if present and no group editor element is focused
    j += "if(document.getElementById('geDetail')){geLastEs=es;if(!document.getElementById('geDetail').contains(document.activeElement)){renderGroupEditor(es);}}";
    // Refresh condition editor if present and no condition editor element is focused
    j += "if(document.getElementById('ceDetail')){ceLastEs=es;if(!document.getElementById('ceDetail').contains(document.activeElement)){renderConditionEditor(es);}}";
    // Refresh NoseposPlus conditional block
    j += "if(document.getElementById('npCondBlock')){updateNpCondBlock(es);}";
    j += "}";

    // Build slot UI
    j += "function buildSlots(cfg){";
    j += "var c=document.getElementById('slotsContainer');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "var slots=cfg.slots||[];var algos=cfg.algorithms||[];";
    j += "for(var si=0;si<slots.length;si++){";
    j += "(function(si){";
    j += "var s=slots[si];var card=document.createElement('div');card.className='slot-card';";

    // Slot header
    j += "var hdr=document.createElement('div');hdr.className='slot-hdr';";
    j += "var title=document.createElement('span');title.className='slot-title';title.textContent='Slot #'+(si+1);hdr.appendChild(title);";
    // Enabled checkbox for non-first slots
    j += "if(si>0){";
    j += "var vs=si===0?'':'_'+si;";
    j += "var enChk=document.createElement('input');enChk.type='checkbox';enChk.checked=s.enabled;";
    j += "enChk.title='Enabled';enChk.setAttribute('data-var','bf_input_mod_enabled'+vs);";
    j += "enChk.addEventListener('change',function(){setVar('bf_input_mod_enabled'+vs,this.checked?'true':'false');});";
    j += "hdr.appendChild(enChk);}";
    // Algorithm select
    j += "var vs=si===0?'':'_'+si;";
    j += "var algoOpts=[];for(var ai=0;ai<algos.length;ai++){algoOpts.push({value:algos[ai].id,text:algos[ai].name});}";
    j += "var algoSel=mkSelect('bf_input_mod_algorithm'+vs,algoOpts);algoSel.value=s.algorithm;";
    j += "algoSel.style.maxWidth='140px';hdr.appendChild(algoSel);";
    // Remove button for non-first slots
    j += "if(si>0){var rmBtn=document.createElement('button');rmBtn.className='btn-sm btn-danger';rmBtn.textContent='Remove';";
    j += "rmBtn.addEventListener('click',function(){postAction('/api/bf/remove-slot','index='+si);});hdr.appendChild(rmBtn);}";

    j += "card.appendChild(hdr);";

    // Slot body
    j += "var body=document.createElement('div');body.className='slot-body';body.setAttribute('data-slot',si);";
    j += "buildAlgoFields(body,s,si,s.algorithm);";
    j += "card.appendChild(body);c.appendChild(card);";
    j += "})(si);}";
    j += "}";

    // Build algorithm-specific fields inside a slot body
    j += "function buildAlgoFields(body,s,si,algoId){";
    j += "var vs=si===0?'':'_'+si;";

    // basic
    j += "if(algoId==='basic'){";
    j += "body.appendChild(mkFieldRow('Modify Count',mkNum('bf_modify_count'+vs,0)));";
    j += "body.appendChild(mkFieldRow('Time From',mkTime('bf_inputs_min_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Time To',mkTime('bf_inputs_max_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Max Steer Diff',mkRange('bf_max_steer_diff'+vs,0,131072)));";
    j += "body.appendChild(mkFieldRow('Max Time Diff',mkNum('bf_max_time_diff'+vs,0)));";
    j += "var chk=mkCheck('bf_inputs_fill_steer'+vs,'Fill Steer');chk.className+=' full';body.appendChild(chk);return;}";

    // range
    j += "if(algoId==='range'){";
    j += "body.appendChild(mkFieldRow('Min Input Count',mkNum('bf_range_min_input_count'+vs,1)));";
    j += "body.appendChild(mkFieldRow('Max Input Count',mkNum('bf_range_max_input_count'+vs,1)));";
    j += "body.appendChild(mkFieldRow('Time From',mkTime('bf_inputs_min_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Time To',mkTime('bf_inputs_max_time'+vs)));";
    j += "body.appendChild(mkFieldRow('Steer Range Min',mkNum('bf_range_min_steer'+vs,-65536,65536)));";
    j += "body.appendChild(mkFieldRow('Steer Range Max',mkNum('bf_range_max_steer'+vs,-65536,65536)));";
    j += "body.appendChild(mkFieldRow('Time Diff Range Min',mkNum('bf_range_min_time_diff'+vs)));";
    j += "body.appendChild(mkFieldRow('Time Diff Range Max',mkNum('bf_range_max_time_diff'+vs)));";
    j += "var chk=mkCheck('bf_range_fill_steer'+vs,'Fill Steer');chk.className+=' full';body.appendChild(chk);return;}";

    // advanced_basic
    j += "if(algoId==='advanced_basic'){";
    j += "var types=[{name:'Steer',pre:'bf_adv_steer_',fields:['modify_count','min_time','max_time','max_diff','max_time_diff','fill']},";
    j += "{name:'Accel',pre:'bf_adv_accel_',fields:['modify_count','min_time','max_time','max_time_diff']},";
    j += "{name:'Brake',pre:'bf_adv_brake_',fields:['modify_count','min_time','max_time','max_time_diff']}];";
    j += "for(var ti=0;ti<types.length;ti++){";
    j += "var sec=document.createElement('div');sec.className='sub-sec';";
    j += "var st=document.createElement('div');st.className='sub-sec-title';st.textContent=types[ti].name;sec.appendChild(st);";
    j += "var sg=document.createElement('div');sg.className='sub-sec-grid';";
    j += "var pre=types[ti].pre;var ff=types[ti].fields;";
    j += "for(var fi=0;fi<ff.length;fi++){var fn=ff[fi];var vn=pre+fn+vs;";
    j += "if(fn==='fill'){var chk=mkCheck(vn,'Fill Steer');chk.className+=' full';sg.appendChild(chk);}";
    j += "else if(fn==='min_time'||fn==='max_time'){sg.appendChild(mkFieldRow(fn==='min_time'?'Time From':'Time To',mkTime(vn)));}";
    j += "else if(fn==='max_diff'){sg.appendChild(mkFieldRow('Max Steer Diff',mkRange(vn,0,131072)));}";
    j += "else{var label=fn.replace(/_/g,' ');label=label.charAt(0).toUpperCase()+label.slice(1);sg.appendChild(mkFieldRow(label,mkNum(vn,0)));}}";
    j += "sec.appendChild(sg);body.appendChild(sec);}return;}";

    // advanced_range
    j += "if(algoId==='advanced_range'){";
    j += "var types=[{name:'Steer',pre:'bf_advr_steer_',fields:['min_input_count','max_input_count','min_time','max_time','min_steer','max_steer','min_time_diff','max_time_diff','fill']},";
    j += "{name:'Accel',pre:'bf_advr_accel_',fields:['min_input_count','max_input_count','min_time','max_time','min_time_diff','max_time_diff']},";
    j += "{name:'Brake',pre:'bf_advr_brake_',fields:['min_input_count','max_input_count','min_time','max_time','min_time_diff','max_time_diff']}];";
    j += "for(var ti=0;ti<types.length;ti++){";
    j += "var sec=document.createElement('div');sec.className='sub-sec';";
    j += "var st=document.createElement('div');st.className='sub-sec-title';st.textContent=types[ti].name;sec.appendChild(st);";
    j += "var sg=document.createElement('div');sg.className='sub-sec-grid';";
    j += "var pre=types[ti].pre;var ff=types[ti].fields;";
    j += "for(var fi=0;fi<ff.length;fi++){var fn=ff[fi];var vn=pre+fn+vs;";
    j += "if(fn==='fill'){var chk=mkCheck(vn,'Fill Steer');chk.className+=' full';sg.appendChild(chk);}";
    j += "else if(fn==='min_time'||fn==='max_time'){sg.appendChild(mkFieldRow(fn==='min_time'?'Time From':'Time To',mkTime(vn)));}";
    j += "else if(fn==='min_steer'||fn==='max_steer'){sg.appendChild(mkFieldRow(fn==='min_steer'?'Steer Min':'Steer Max',mkNum(vn,-65536,65536)));}";
    j += "else{var label=fn.replace(/_/g,' ');label=label.charAt(0).toUpperCase()+label.slice(1);sg.appendChild(mkFieldRow(label,mkNum(vn,0)));}}";
    j += "sec.appendChild(sg);body.appendChild(sec);}return;}";

    j += "}";

    // Update all slot field values from config
    j += "function updateSlotValues(cfg){";
    j += "var slots=cfg.slots||[];";
    j += "for(var si=0;si<slots.length;si++){";
    j += "var s=slots[si];var vs=si===0?'':'_'+si;";
    j += "var algoKey=s.algorithm;var data=s[algoKey];";
    // Also grab basic/range/advanced_basic/advanced_range sub-objects
    j += "var allSubs=['basic','range','advanced_basic','advanced_range'];";
    j += "for(var sbi=0;sbi<allSubs.length;sbi++){";
    j += "var sub=s[allSubs[sbi]];if(!sub)continue;";
    j += "var keys=Object.keys(sub);";
    j += "for(var ki=0;ki<keys.length;ki++){";
    j += "var k=keys[ki];var val=sub[k];";
    // Map JSON key to variable name
    j += "var varMap={";
    // basic
    j += "'modifyCount':'bf_modify_count','minTime':'bf_inputs_min_time','maxTime':'bf_inputs_max_time',";
    j += "'maxSteerDiff':'bf_max_steer_diff','maxTimeDiff':'bf_max_time_diff','fillSteer':'bf_inputs_fill_steer',";
    // range
    j += "'minInputCount':'bf_range_min_input_count','maxInputCount':'bf_range_max_input_count',";
    j += "'minSteer':'bf_range_min_steer','maxSteer':'bf_range_max_steer',";
    j += "'minTimeDiff':'bf_range_min_time_diff','maxTimeDiff2':'bf_range_max_time_diff'};";
    // We need a different approach - use data-var attribute directly
    j += "}}";

    // Actually, update by iterating all data-var elements in the slot body
    j += "var body=document.querySelector('[data-slot=\"'+si+'\"]');if(!body)continue;";
    j += "var els=body.querySelectorAll('[data-var]');";
    j += "for(var ei=0;ei<els.length;ei++){";
    j += "var el=els[ei];var vn=el.getAttribute('data-var');";
    // Find matching value from the slot's algorithm data
    j += "var val=findSlotValue(s,vn,vs);";
    j += "if(val===undefined)continue;";
    j += "if(el.getAttribute('data-time')){setField(el,fmtTime(val));}";
    j += "else if(el.type==='checkbox'){if(!isFocused(el))el.checked=!!val;}";
    j += "else{setField(el,val);}";
    j += "}";

    // Update enabled checkbox and algo select in header
    j += "if(si>0){var enEl=document.querySelector('.slot-hdr input[data-var=\"bf_input_mod_enabled'+vs+'\"]');";
    j += "if(enEl&&!isFocused(enEl))enEl.checked=s.enabled;}";
    j += "var algoEl=document.querySelector('.slot-hdr select[data-var=\"bf_input_mod_algorithm'+vs+'\"]');";
    j += "if(algoEl&&!isFocused(algoEl))algoEl.value=s.algorithm;";

    j += "}}";

    // Lookup a value from the slot data by variable name
    j += "function findSlotValue(s,vn,vs){";
    // Strip the suffix to get the base name
    j += "var base=vn;if(vs&&vn.endsWith(vs))base=vn.substring(0,vn.length-vs.length);";
    j += "var maps={";
    // basic keys
    j += "'bf_modify_count':['basic','modifyCount'],";
    j += "'bf_inputs_min_time':['basic','minTime'],";
    j += "'bf_inputs_max_time':['basic','maxTime'],";
    j += "'bf_max_steer_diff':['basic','maxSteerDiff'],";
    j += "'bf_max_time_diff':['basic','maxTimeDiff'],";
    j += "'bf_inputs_fill_steer':['basic','fillSteer'],";
    // range keys
    j += "'bf_range_min_input_count':['range','minInputCount'],";
    j += "'bf_range_max_input_count':['range','maxInputCount'],";
    j += "'bf_range_min_steer':['range','minSteer'],";
    j += "'bf_range_max_steer':['range','maxSteer'],";
    j += "'bf_range_min_time_diff':['range','minTimeDiff'],";
    j += "'bf_range_max_time_diff':['range','maxTimeDiff'],";
    j += "'bf_range_fill_steer':['range','fillSteer'],";
    // advanced_basic keys
    j += "'bf_adv_steer_modify_count':['advanced_basic','steerModifyCount'],";
    j += "'bf_adv_steer_min_time':['advanced_basic','steerMinTime'],";
    j += "'bf_adv_steer_max_time':['advanced_basic','steerMaxTime'],";
    j += "'bf_adv_steer_max_diff':['advanced_basic','steerMaxDiff'],";
    j += "'bf_adv_steer_max_time_diff':['advanced_basic','steerMaxTimeDiff'],";
    j += "'bf_adv_steer_fill':['advanced_basic','steerFill'],";
    j += "'bf_adv_accel_modify_count':['advanced_basic','accelModifyCount'],";
    j += "'bf_adv_accel_min_time':['advanced_basic','accelMinTime'],";
    j += "'bf_adv_accel_max_time':['advanced_basic','accelMaxTime'],";
    j += "'bf_adv_accel_max_time_diff':['advanced_basic','accelMaxTimeDiff'],";
    j += "'bf_adv_brake_modify_count':['advanced_basic','brakeModifyCount'],";
    j += "'bf_adv_brake_min_time':['advanced_basic','brakeMinTime'],";
    j += "'bf_adv_brake_max_time':['advanced_basic','brakeMaxTime'],";
    j += "'bf_adv_brake_max_time_diff':['advanced_basic','brakeMaxTimeDiff'],";
    // advanced_range keys
    j += "'bf_advr_steer_min_input_count':['advanced_range','steerMinInputCount'],";
    j += "'bf_advr_steer_max_input_count':['advanced_range','steerMaxInputCount'],";
    j += "'bf_advr_steer_min_time':['advanced_range','steerMinTime'],";
    j += "'bf_advr_steer_max_time':['advanced_range','steerMaxTime'],";
    j += "'bf_advr_steer_min_steer':['advanced_range','steerMinSteer'],";
    j += "'bf_advr_steer_max_steer':['advanced_range','steerMaxSteer'],";
    j += "'bf_advr_steer_min_time_diff':['advanced_range','steerMinTimeDiff'],";
    j += "'bf_advr_steer_max_time_diff':['advanced_range','steerMaxTimeDiff'],";
    j += "'bf_advr_steer_fill':['advanced_range','steerFill'],";
    j += "'bf_advr_accel_min_input_count':['advanced_range','accelMinInputCount'],";
    j += "'bf_advr_accel_max_input_count':['advanced_range','accelMaxInputCount'],";
    j += "'bf_advr_accel_min_time':['advanced_range','accelMinTime'],";
    j += "'bf_advr_accel_max_time':['advanced_range','accelMaxTime'],";
    j += "'bf_advr_accel_min_time_diff':['advanced_range','accelMinTimeDiff'],";
    j += "'bf_advr_accel_max_time_diff':['advanced_range','accelMaxTimeDiff'],";
    j += "'bf_advr_brake_min_input_count':['advanced_range','brakeMinInputCount'],";
    j += "'bf_advr_brake_max_input_count':['advanced_range','brakeMaxInputCount'],";
    j += "'bf_advr_brake_min_time':['advanced_range','brakeMinTime'],";
    j += "'bf_advr_brake_max_time':['advanced_range','brakeMaxTime'],";
    j += "'bf_advr_brake_min_time_diff':['advanced_range','brakeMinTimeDiff'],";
    j += "'bf_advr_brake_max_time_diff':['advanced_range','brakeMaxTimeDiff']";
    j += "};";
    j += "var m=maps[base];if(!m)return undefined;";
    j += "var sub=s[m[0]];if(!sub)return undefined;";
    j += "return sub[m[1]];}";

    // Track previous target for rebuild detection
    j += "var prevTarget='';var prevSlotAlgos='';";

    // Main settings poll
    j += "function pollSettings(){";
    j += "fetch(apiBase+'/api/bf/all-settings').then(function(r){return r.json();}).then(function(cfg){";
    j += "allCfg=cfg;";

    // Build serverSnapshot from polled config
    j += "serverSnapshot={};";
    j += "serverSnapshot['bf_target']=String(cfg.target);";
    j += "if(cfg.behavior){";
    j += "serverSnapshot['bf_result_filename']=String(cfg.behavior.resultFilename);";
    j += "serverSnapshot['bf_iterations_before_restart']=String(cfg.behavior.iterationsBeforeRestart);";
    j += "serverSnapshot['bf_result_folder']=String(cfg.behavior.resultFolder);";
    j += "serverSnapshot['bf_restart_condition_script']=String(cfg.behavior.restartConditionScript);";
    j += "serverSnapshot['bf_dashboard_persist_logs']=String(cfg.behavior.persistLogs);}";
    j += "if(cfg.conditions){";
    j += "serverSnapshot['bf_condition_speed']=String(cfg.conditions.speed);";
    j += "serverSnapshot['bf_condition_cps']=String(cfg.conditions.cps);";
    j += "serverSnapshot['bf_condition_trigger']=String(cfg.conditions.trigger);";
    j += "serverSnapshot['bf_condition_script']=String(cfg.conditions.conditionScript);}";
    j += "if(cfg.evalSettings){var ek=Object.keys(cfg.evalSettings);for(var ei=0;ei<ek.length;ei++){";
    j += "var ev=cfg.evalSettings[ek[ei]];";
    j += "if(ev!==null&&typeof ev==='object'&&'x' in ev)serverSnapshot[ek[ei]]=ev.x.toFixed(3)+' '+ev.y.toFixed(3)+' '+ev.z.toFixed(3);";
    j += "else serverSnapshot[ek[ei]]=String(ev);}}";
    j += "if(cfg.slots){for(var si=0;si<cfg.slots.length;si++){var sl=cfg.slots[si];var vs=si===0?'':'_'+si;";
    j += "serverSnapshot['bf_input_mod_algorithm'+vs]=sl.algorithm;";
    j += "if(si>0)serverSnapshot['bf_input_mod_enabled'+vs]=String(sl.enabled);";
    j += "var algos=['basic','range','advanced_basic','advanced_range'];";
    j += "for(var ai=0;ai<algos.length;ai++){var ao=sl[algos[ai]];if(!ao)continue;var ak=Object.keys(ao);";
    j += "for(var aki=0;aki<ak.length;aki++){var varN=findVarName(algos[ai],ak[aki],vs);if(varN)serverSnapshot[varN]=String(ao[ak[aki]]);}}}}";

    // Helper to map JSON key back to variable name
    j += "function findVarName(algo,key,vs){";
    j += "var m={'basic':{'modifyCount':'bf_modify_count','minTime':'bf_inputs_min_time','maxTime':'bf_inputs_max_time','maxSteerDiff':'bf_max_steer_diff','maxTimeDiff':'bf_max_time_diff','fillSteer':'bf_inputs_fill_steer'},";
    j += "'range':{'minInputCount':'bf_range_min_input_count','maxInputCount':'bf_range_max_input_count','minTime':'bf_inputs_min_time','maxTime':'bf_inputs_max_time','minSteer':'bf_range_min_steer','maxSteer':'bf_range_max_steer','minTimeDiff':'bf_range_min_time_diff','maxTimeDiff':'bf_range_max_time_diff','fillSteer':'bf_range_fill_steer'},";
    j += "'advanced_basic':{'steerModifyCount':'bf_adv_steer_modify_count','steerMinTime':'bf_adv_steer_min_time','steerMaxTime':'bf_adv_steer_max_time','steerMaxDiff':'bf_adv_steer_max_diff','steerMaxTimeDiff':'bf_adv_steer_max_time_diff','steerFill':'bf_adv_steer_fill','accelModifyCount':'bf_adv_accel_modify_count','accelMinTime':'bf_adv_accel_min_time','accelMaxTime':'bf_adv_accel_max_time','accelMaxTimeDiff':'bf_adv_accel_max_time_diff','brakeModifyCount':'bf_adv_brake_modify_count','brakeMinTime':'bf_adv_brake_min_time','brakeMaxTime':'bf_adv_brake_max_time','brakeMaxTimeDiff':'bf_adv_brake_max_time_diff'},";
    j += "'advanced_range':{'steerMinInputCount':'bf_advr_steer_min_input_count','steerMaxInputCount':'bf_advr_steer_max_input_count','steerMinTime':'bf_advr_steer_min_time','steerMaxTime':'bf_advr_steer_max_time','steerMinSteer':'bf_advr_steer_min_steer','steerMaxSteer':'bf_advr_steer_max_steer','steerMinTimeDiff':'bf_advr_steer_min_time_diff','steerMaxTimeDiff':'bf_advr_steer_max_time_diff','steerFill':'bf_advr_steer_fill','accelMinInputCount':'bf_advr_accel_min_input_count','accelMaxInputCount':'bf_advr_accel_max_input_count','accelMinTime':'bf_advr_accel_min_time','accelMaxTime':'bf_advr_accel_max_time','accelMinTimeDiff':'bf_advr_accel_min_time_diff','accelMaxTimeDiff':'bf_advr_accel_max_time_diff','brakeMinInputCount':'bf_advr_brake_min_input_count','brakeMaxInputCount':'bf_advr_brake_max_input_count','brakeMinTime':'bf_advr_brake_min_time','brakeMaxTime':'bf_advr_brake_max_time','brakeMinTimeDiff':'bf_advr_brake_min_time_diff','brakeMaxTimeDiff':'bf_advr_brake_max_time_diff'}};";
    j += "var map=m[algo];if(!map||!map[key])return null;return map[key]+vs;}";

    // Controller badge
    j += "var cb=document.getElementById('ctrlBadge');";
    j += "if(!cfg.controllerActive){";
    j += "if(!cb.firstChild){var b=document.createElement('span');b.className='badge warn';b.textContent='BfV2 not active';cb.appendChild(b);}";
    j += "}else{while(cb.firstChild)cb.removeChild(cb.firstChild);}";

    // Populate target select
    j += "var tSel=document.getElementById('optTarget');";
    j += "if(tSel.options.length!==cfg.evaluations.length){";
    j += "while(tSel.firstChild)tSel.removeChild(tSel.firstChild);";
    j += "for(var i=0;i<cfg.evaluations.length;i++){var o=document.createElement('option');o.value=cfg.evaluations[i].id;o.textContent=cfg.evaluations[i].title;tSel.appendChild(o);}}";
    j += "setField(tSel,cfg.target);";

    // Rebuild eval fields if target changed
    j += "var displayTarget=('bf_target' in dirtyVars)?dirtyVars['bf_target']:cfg.target;";
    j += "if(displayTarget!==prevTarget){prevTarget=displayTarget;buildEvalFields({target:displayTarget,evalSettings:cfg.evalSettings,triggers:cfg.triggers});}";
    j += "updateEvalValues(cfg);";

    // Update behavior fields
    j += "setField(document.getElementById('behFile'),cfg.behavior.resultFilename);";
    j += "setField(document.getElementById('behIter'),cfg.behavior.iterationsBeforeRestart);";
    j += "setField(document.getElementById('behFolder'),cfg.behavior.resultFolder);";
    j += "setField(document.getElementById('behPersist'),cfg.behavior.persistLogs);";
    j += "var behScript=document.getElementById('behRestartScript');";
    j += "if(!isFocused(behScript))behScript.value=scriptToDisplay(cfg.behavior.restartConditionScript);";

    // Update condition fields
    j += "setField(document.getElementById('condSpeed'),cfg.conditions.speed);";
    j += "setField(document.getElementById('condCps'),cfg.conditions.cps);";

    // Populate condition trigger select
    j += "var ctSel=document.getElementById('condTrigger');";
    j += "var trigs=cfg.triggers||[];var neededOpts=trigs.length+1;";
    j += "if(ctSel.options.length!==neededOpts){";
    j += "while(ctSel.firstChild)ctSel.removeChild(ctSel.firstChild);";
    j += "var none=document.createElement('option');none.value='0';none.textContent='None';ctSel.appendChild(none);";
    j += "for(var i=0;i<trigs.length;i++){var o=document.createElement('option');o.value=String(trigs[i].index);";
    j += "var p=trigs[i].position;o.textContent='#'+trigs[i].index+' ('+p.x.toFixed(1)+', '+p.y.toFixed(1)+', '+p.z.toFixed(1)+')';ctSel.appendChild(o);}}";
    j += "setField(ctSel,cfg.conditions.trigger);";

    j += "var condScript=document.getElementById('condScript');";
    j += "if(!isFocused(condScript))condScript.value=scriptToDisplay(cfg.conditions.conditionScript);";

    // Build/rebuild slots if count or algorithms changed
    j += "var slotAlgos='';for(var i=0;i<cfg.slots.length;i++)slotAlgos+=cfg.slots[i].algorithm+',';";
    j += "if(cfg.slots.length!==lastSlotCount||slotAlgos!==prevSlotAlgos){lastSlotCount=cfg.slots.length;prevSlotAlgos=slotAlgos;buildSlots(cfg);}";
    j += "updateSlotValues(cfg);";

    j += "}).catch(function(){});}";
    j += "setInterval(pollSettings,2000);pollSettings();";

    // Wire up static settings change events
    j += "document.getElementById('optTarget').addEventListener('change',function(){setVar('bf_target',this.value);prevTarget='';});";
    j += "document.getElementById('behFile').addEventListener('blur',function(){setVar('bf_result_filename',this.value);});";
    j += "document.getElementById('behIter').addEventListener('blur',function(){setVar('bf_iterations_before_restart',this.value);});";
    j += "document.getElementById('behFolder').addEventListener('blur',function(){setVar('bf_result_folder',this.value);});";
    j += "document.getElementById('behPersist').addEventListener('change',function(){setVar('bf_dashboard_persist_logs',this.checked?'true':'false');});";
    j += "document.getElementById('behRestartScript').addEventListener('blur',function(){setVar('bf_restart_condition_script',displayToScript(this.value));});";
    j += "document.getElementById('condSpeed').addEventListener('blur',function(){setVar('bf_condition_speed',this.value);});";
    j += "document.getElementById('condCps').addEventListener('blur',function(){setVar('bf_condition_cps',this.value);});";
    j += "document.getElementById('condTrigger').addEventListener('change',function(){setVar('bf_condition_trigger',this.value);});";
    j += "document.getElementById('condScript').addEventListener('blur',function(){setVar('bf_condition_script',displayToScript(this.value));});";

    // Add Slot button
    j += "document.getElementById('btnAddSlot').addEventListener('click',function(){postAction('/api/bf/add-slot','');});";

    // Apply/Discard button handlers
    j += "function applyAllDirty() {";
    j += "var keys = Object.keys(dirtyVars);";
    j += "if (keys.length === 0) return;";
    j += "var body = '';";
    j += "for (var i=0; i<keys.length; i++) {";
    j += "if (i > 0) body += '\\n';";
    j += "body += keys[i] + '=' + dirtyVars[keys[i]];}";
    j += "fetch(apiBase+'/api/bf/set-batch', {method:'POST', body:body}).then(function(r){return r.json();}).then(function(d){";
    j += "if (d.ok) { dirtyVars = {}; markAllClean(); updateApplyBar(); }";
    j += "}).catch(function(){});}";

    j += "document.getElementById('btnApply').addEventListener('click', function() { applyAllDirty(); });";
    j += "document.getElementById('btnDiscard').addEventListener('click', function() {";
    j += "dirtyVars = {};";
    j += "markAllClean();";
    j += "updateApplyBar();";
    j += "pollSettings();});";

    return j;
}

// ============================================================
// JS: Session history (log, improvements, session tabs) + Live BF cards
// ============================================================

string BfDashJS_Sessions()
{
    string j = "";

    j += "var activeSession=null,activeSubTab='imp',sessions=[];";
    j += "var lastLogLen=-1,lastImpLen=-1;";

    // Live cards state
    j += "var liveCards={};";

    // Sessions polling
    j += "function pollSessions(){";
    j += "fetch(apiBase+'/api/bf/sessions').then(function(r){return r.json();}).then(function(arr){sessions=arr;renderSessionTabs();}).catch(function(){});}";
    j += "setInterval(pollSessions,5000);pollSessions();";

    // Render session tabs (past sessions only, no "Current" tab)
    j += "function renderSessionTabs(){";
    j += "var bar=document.getElementById('sessionTabs');while(bar.firstChild)bar.removeChild(bar.firstChild);";
    j += "if(sessions.length===0){var em=document.createElement('span');em.textContent='No past sessions';em.style.color='#8b949e';em.style.fontSize='0.8rem';bar.appendChild(em);return;}";
    j += "if(activeSession===null&&sessions.length>0)activeSession=sessions[sessions.length-1].id;";
    j += "for(var i=sessions.length-1;i>=0;i--){";
    j += "(function(s){";
    j += "var btn=document.createElement('button');btn.className='tab-btn'+(activeSession===s.id?' active':'');";
    j += "btn.title=s.map||'';";
    j += "var lbl=document.createElement('span');";
    j += "lbl.textContent='#'+s.id+': '+(s.target||'?').substring(0,15);";
    j += "btn.appendChild(lbl);";
    j += "var del=document.createElement('span');";
    j += "del.className='tab-del';";
    j += "del.textContent='\\u00D7';";
    j += "del.title='Delete session #'+s.id;";
    j += "del.addEventListener('click',function(e){";
    j += "e.stopPropagation();";
    j += "if(!e.shiftKey&&!confirm('Delete session #'+s.id+'?\\n(Hold Shift to bypass this confirmation)'))return;";
    j += "fetch(apiBase+'/api/bf/delete-session',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'id='+encodeURIComponent(s.id)}).then(function(r){return r.json();}).then(function(d){";
    j += "if(d.ok){";
    j += "if(activeSession===s.id){activeSession=null;}";
    j += "for(var j2=0;j2<sessions.length;j2++){if(sessions[j2].id===s.id){sessions.splice(j2,1);break;}}";
    j += "renderSessionTabs();";
    j += "loadSessionData();}});});";
    j += "btn.appendChild(del);";
    j += "btn.addEventListener('click',function(){activeSession=s.id;renderSessionTabs();loadSessionData();});";
    j += "bar.appendChild(btn);";
    j += "})(sessions[i]);}";
    j += "}";

    // Sub-tab switching
    j += "document.getElementById('tabImp').addEventListener('click',function(){activeSubTab='imp';";
    j += "document.getElementById('tabImp').className='sub-tab active';document.getElementById('tabLog').className='sub-tab';loadSessionData();});";
    j += "document.getElementById('tabLog').addEventListener('click',function(){activeSubTab='log';";
    j += "document.getElementById('tabLog').className='sub-tab active';document.getElementById('tabImp').className='sub-tab';loadSessionData();});";

    // Load data for selected session+tab (past sessions only)
    j += "function loadSessionData(){";
    j += "lastLogLen=-1;lastImpLen=-1;";
    j += "var hc=document.getElementById('historyContent');while(hc&&hc.firstChild)hc.removeChild(hc.firstChild);";
    j += "if(activeSession===null)return;";
    j += "var type=activeSubTab==='log'?'session-log':'session-imp';";
    j += "fetch(apiBase+'/api/bf/'+type+'?id='+encodeURIComponent(activeSession)).then(function(r){return r.json();}).then(function(arr){";
    j += "if(activeSubTab==='log'){renderLog(arr);}else{renderImp(arr);}";
    j += "}).catch(function(){});}";

    // Render log entries
    j += "function renderLog(arr){";
    j += "var c=document.getElementById('historyContent');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "for(var i=0;i<arr.length;i++){var e=arr[i];var div=document.createElement('div');div.className='log-entry';";
    j += "var ts=document.createElement('span');ts.className='lt';ts.textContent='['+fmtSec(e.t)+']';";
    j += "var msg=document.createElement('span');msg.className='lm';msg.textContent=e.msg;";
    j += "div.appendChild(ts);div.appendChild(msg);c.appendChild(div);}c.scrollTop=c.scrollHeight;}";

    // Render improvements
    j += "function renderImp(arr){";
    j += "var c=document.getElementById('historyContent');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "var hdr=document.createElement('div');hdr.className='imp-row hdr';";
    j += "var cols=['#','Time','Details','Iter','Rst'];";
    j += "for(var ci=0;ci<cols.length;ci++){var s=document.createElement('span');s.textContent=cols[ci];hdr.appendChild(s);}c.appendChild(hdr);";
    j += "for(var i=arr.length-1;i>=0;i--){var e=arr[i];";
    j += "var row=document.createElement('div');row.className='imp-row';";
    j += "var ns=document.createElement('span');ns.textContent=i+1;";
    j += "var ts=document.createElement('span');ts.textContent=fmtSec(e.t);";
    j += "var ds=document.createElement('span');ds.textContent=((e.eval||'')+' '+(e.details||'')).substring(0,100);ds.title=e.details||'';";
    j += "var is2=document.createElement('span');is2.textContent=fmtNum(e.iteration||0);";
    j += "var rs=document.createElement('span');rs.textContent=e.restart||0;";
    j += "row.appendChild(ns);row.appendChild(ts);row.appendChild(ds);row.appendChild(is2);row.appendChild(rs);c.appendChild(row);}";
    j += "}";

    // ---- Live BF Cards ----

    j += "function updateLiveCards(found){";
    j += "var running=found.filter(function(i){return i.running;});";
    j += "var emptyMsg=document.getElementById('liveEmpty');";
    j += "if(running.length===0){";
    j += "if(emptyMsg)emptyMsg.style.display='';";
    j += "var keys=Object.keys(liveCards);for(var k=0;k<keys.length;k++){clearInterval(liveCards[keys[k]].logTimer);clearInterval(liveCards[keys[k]].impTimer);var cardEl=liveCards[keys[k]].contentEl.parentNode;if(cardEl&&cardEl.parentNode)cardEl.parentNode.removeChild(cardEl);}";
    j += "liveCards={};return;}";
    j += "if(emptyMsg)emptyMsg.style.display='none';";

    // Remove cards for instances no longer running
    j += "var existingPorts=Object.keys(liveCards);";
    j += "for(var ep=0;ep<existingPorts.length;ep++){";
    j += "var still=false;for(var ri=0;ri<running.length;ri++){if(String(running[ri].port)===existingPorts[ep]){still=true;break;}}";
    j += "if(!still){clearInterval(liveCards[existingPorts[ep]].logTimer);clearInterval(liveCards[existingPorts[ep]].impTimer);";
    j += "var cardEl=liveCards[existingPorts[ep]].contentEl.parentNode;cardEl.parentNode.removeChild(cardEl);";
    j += "delete liveCards[existingPorts[ep]];}}";

    // Add cards for newly running instances
    j += "var container=document.getElementById('liveCards');";
    j += "for(var ri=0;ri<running.length;ri++){";
    j += "(function(inst){";
    j += "var portKey=String(inst.port);";
    j += "if(liveCards[portKey])return;";

    // Build card element
    j += "var card=document.createElement('div');card.className='live-card';";

    // Header
    j += "var hdr=document.createElement('div');hdr.className='live-card-hdr';";
    j += "var portSpan=document.createElement('span');portSpan.className='port';portSpan.textContent=':'+inst.port;hdr.appendChild(portSpan);";
    j += "var targetSpan=document.createElement('span');targetSpan.className='target';targetSpan.textContent=inst.target||'-';hdr.appendChild(targetSpan);";
    j += "card.appendChild(hdr);";

    // Sub-tabs
    j += "var tabs=document.createElement('div');tabs.className='live-card-tabs';";
    j += "var tabImp=document.createElement('button');tabImp.className='live-card-tab active';tabImp.textContent='Imp';";
    j += "var tabLog=document.createElement('button');tabLog.className='live-card-tab';tabLog.textContent='Log';";
    j += "tabs.appendChild(tabImp);tabs.appendChild(tabLog);card.appendChild(tabs);";

    // Body
    j += "var body=document.createElement('div');body.className='live-card-body';";
    j += "card.appendChild(body);container.appendChild(card);";

    // State object
    j += "var state={lastLogLen:-1,lastImpLen:-1,subTab:'imp',logTimer:null,impTimer:null,contentEl:body};";
    j += "liveCards[portKey]=state;";

    // Tab switching
    j += "tabImp.addEventListener('click',function(){state.subTab='imp';tabImp.className='live-card-tab active';tabLog.className='live-card-tab';pollCardImp();});";
    j += "tabLog.addEventListener('click',function(){state.subTab='log';tabLog.className='live-card-tab active';tabImp.className='live-card-tab';pollCardLog();});";

    // Poll functions
    j += "function pollCardLog(){";
    j += "if(state.subTab!=='log')return;";
    j += "fetch('http://localhost:'+inst.port+'/api/bf/log').then(function(r){return r.json();}).then(function(arr){";
    j += "if(arr.length!==state.lastLogLen){state.lastLogLen=arr.length;renderCardLog(body,arr);}";
    j += "}).catch(function(){});}";

    j += "function pollCardImp(){";
    j += "if(state.subTab!=='imp')return;";
    j += "fetch('http://localhost:'+inst.port+'/api/bf/improvements').then(function(r){return r.json();}).then(function(arr){";
    j += "if(arr.length!==state.lastImpLen){state.lastImpLen=arr.length;renderCardImp(body,arr);}";
    j += "}).catch(function(){});}";

    // Start timers
    j += "state.logTimer=setInterval(pollCardLog,2000);";
    j += "state.impTimer=setInterval(pollCardImp,2000);";
    j += "pollCardImp();";

    j += "})(running[ri]);}";
    j += "}";

    // Render helpers for live cards
    j += "function renderCardLog(el,arr){";
    j += "while(el.firstChild)el.removeChild(el.firstChild);";
    j += "for(var i=0;i<arr.length;i++){var e=arr[i];var div=document.createElement('div');div.className='log-entry';";
    j += "var ts=document.createElement('span');ts.className='lt';ts.textContent='['+fmtSec(e.t)+']';";
    j += "var msg=document.createElement('span');msg.className='lm';msg.textContent=e.msg;";
    j += "div.appendChild(ts);div.appendChild(msg);el.appendChild(div);}el.scrollTop=el.scrollHeight;}";

    j += "function renderCardImp(el,arr){";
    j += "while(el.firstChild)el.removeChild(el.firstChild);";
    j += "for(var i=arr.length-1;i>=0;i--){var e=arr[i];var div=document.createElement('div');div.className='log-entry';";
    j += "var txt=document.createElement('span');txt.className='lm';txt.textContent='#'+(i+1)+' '+fmtSec(e.t)+' '+(e.eval||'')+' '+(e.details||'');";
    j += "div.appendChild(txt);el.appendChild(div);}}";

    // ---- Base Run Inputs ----

    j += "document.getElementById('btnApplyInputs').addEventListener('click', function() {";
    j += "var script = document.getElementById('inputScript').value;";
    j += "if (!script.trim()) return;";
    j += "var res = document.getElementById('inputResult');";
    j += "res.textContent = 'Sending...';";
    j += "res.style.color = '#8b949e';";
    j += "fetch(apiBase + '/api/bf/apply-inputs', {method:'POST', body:script})";
    j += ".then(function(r) { return r.json(); })";
    j += ".then(function(d) {";
    j += "if (d.ok) {";
    j += "res.textContent = 'Applied ' + d.commands + ' commands';";
    j += "res.style.color = '#3fb950';";
    j += "} else {";
    j += "res.textContent = 'Error: ' + (d.error || 'unknown');";
    j += "res.style.color = '#f85149';";
    j += "}";
    j += "})";
    j += ".catch(function() {";
    j += "res.textContent = 'Request failed';";
    j += "res.style.color = '#f85149';";
    j += "});";
    j += "});";

    // Apply to All instances
    j += "document.getElementById('btnApplyAll').addEventListener('click',function(){";
    j += "var script=document.getElementById('inputScript').value;";
    j += "if(!script.trim())return;";
    j += "var res=document.getElementById('inputResult');";
    j += "if(instances.length===0){res.textContent='No instances found';res.style.color='#f85149';return;}";
    j += "res.textContent='Sending to all instances...';res.style.color='#8b949e';";
    j += "var sent=0,ok=0,fail=0;";
    j += "for(var i=0;i<instances.length;i++){";
    j += "(function(port){";
    j += "sent++;";
    j += "fetch('http://localhost:'+port+'/api/bf/apply-inputs',{method:'POST',body:script})";
    j += ".then(function(r){return r.json();})";
    j += ".then(function(d){if(d.ok)ok++;else fail++;})";
    j += ".catch(function(){fail++;})";
    j += ".finally(function(){if(ok+fail===sent){";
    j += "res.textContent='Applied to '+ok+'/'+sent+' instances'+(fail>0?' ('+fail+' failed)':'');";
    j += "res.style.color=fail===0?'#3fb950':'#d29922';}});";
    j += "})(instances[i].port);}";
    j += "});";

    // Toggle base inputs overlay based on BF running state
    j += "function updateBaseOverlay(){";
    j += "var overlay=document.getElementById('baseDisabledOverlay');";
    j += "if(!overlay)return;";
    j += "overlay.style.display=bfIsRunning?'none':'flex';}";
    j += "setInterval(updateBaseOverlay,500);updateBaseOverlay();";

    // Initial load
    j += "setTimeout(loadSessionData,500);";

    return j;
}
