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

    h += "<section class='panel' id='settings'>";
    h += "<h2>Settings</h2>";
    h += "<div class='stat'><label>Target</label><span id='sTarget'>-</span></div>";
    h += "<div class='stat'><label>Restart after</label><span id='sRestart'>-</span></div>";
    h += "<div class='stat'><label>Result file</label><span id='sFile' class='mono'>-</span></div>";
    h += "<div class='stat'><label>Result folder</label><span id='sFolder' class='mono'>-</span></div>";
    h += "<h3>Input Modification Slots</h3>";
    h += "<div id='sSlots' class='slot-list'></div>";
    h += "</section>";

    h += "<section class='panel' id='mapinfo'>";
    h += "<h2>Map</h2>";
    h += "<div class='stat'><label>Name</label><span id='mapName'>-</span></div>";
    h += "<div class='stat'><label>Author</label><span id='mapAuthor'>-</span></div>";
    h += "<div class='stat'><label>UID</label><span id='mapUid' class='mono'>-</span></div>";
    h += "</section>";

    h += "<section class='panel wide' id='history'>";
    h += "<div class='tab-bar' id='sessionTabs'></div>";
    h += "<div class='sub-tabs'>";
    h += "<button class='sub-tab active' id='tabImp'>Improvements</button>";
    h += "<button class='sub-tab' id='tabLog'>Log</button>";
    h += "</div>";
    h += "<div id='historyContent' class='history-content'></div>";
    h += "</section>";

    h += "</main>";
    h += "<script>" + BfDashJS() + "</script>";
    h += "</body></html>";
    return h;
}

string BfDashCSS()
{
    string c = "*{box-sizing:border-box;margin:0;padding:0}";
    c += "body{font-family:system-ui,-apple-system,sans-serif;background:#0d1117;color:#c9d1d9;min-height:100vh}";
    c += "header{background:#161b22;padding:1rem 2rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #30363d}";
    c += "header h1{font-size:1.2rem;color:#f0883e}";
    c += "main{display:grid;grid-template-columns:1fr 1fr 1fr;gap:1rem;padding:1rem 2rem;max-width:1400px;margin:0 auto}";
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
    c += ".mono{font-family:monospace;font-size:0.8rem !important;word-break:break-all}";

    c += ".slot-list{display:flex;flex-direction:column;gap:0.3rem}";
    c += ".slot-item{background:#0d1117;padding:0.4rem 0.6rem;border-radius:4px;font-size:0.8rem;font-family:monospace;border-left:3px solid #30363d}";
    c += ".slot-item.enabled{border-left-color:#3fb950}";
    c += ".slot-item.disabled{border-left-color:#f85149;opacity:0.5}";

    c += ".tab-bar{display:flex;gap:0.3rem;margin-bottom:0.5rem;flex-wrap:wrap}";
    c += ".tab-btn{background:#21262d;color:#8b949e;border:1px solid #30363d;padding:0.3rem 0.8rem;border-radius:6px 6px 0 0;cursor:pointer;font-size:0.8rem}";
    c += ".tab-btn:hover{background:#30363d}";
    c += ".tab-btn.active{background:#161b22;color:#f0883e;border-bottom-color:#161b22}";
    c += ".sub-tabs{display:flex;gap:0.3rem;margin-bottom:0.5rem}";
    c += ".sub-tab{background:none;color:#8b949e;border:none;padding:0.3rem 0.8rem;cursor:pointer;font-size:0.8rem;border-bottom:2px solid transparent}";
    c += ".sub-tab:hover{color:#c9d1d9}";
    c += ".sub-tab.active{color:#f0883e;border-bottom-color:#f0883e}";

    c += ".history-content{max-height:400px;overflow-y:auto}";
    c += ".imp-row{display:grid;grid-template-columns:2.5rem 4rem 1fr 4rem 3rem;gap:0.5rem;padding:0.3rem 0;border-bottom:1px solid #21262d;font-size:0.8rem;align-items:center}";
    c += ".imp-row.hdr{color:#8b949e;font-weight:600;border-bottom:2px solid #30363d}";
    c += ".log-entry{padding:0.15rem 0;font-family:monospace;font-size:0.8rem;line-height:1.5}";
    c += ".log-entry .lt{color:#8b949e;margin-right:0.5rem}";
    c += ".log-entry .lm{color:#c9d1d9}";
    return c;
}

string BfDashJS()
{
    string j = "";

    j += "let pollOk=false,activeSession='current',activeSubTab='imp',sessions=[];";

    // Status polling
    j += "async function pollStatus(){";
    j += "try{const r=await fetch('/api/bf/status');const d=await r.json();pollOk=true;";
    j += "const cn=document.getElementById('conn');cn.textContent='Connected';cn.style.background='#3fb95030';cn.style.color='#3fb950';";
    j += "const st=document.getElementById('bfState');st.textContent=d.running?'Running':'Idle';st.className='badge '+(d.running?'running':'idle');";
    j += "const ph=document.getElementById('bfPhase');ph.textContent=d.phase;ph.className='badge '+(d.phase==='Initial'?'initial':d.phase==='Search'?'search':'idle');";
    j += "document.getElementById('bfTarget').textContent=d.target||'-';";
    j += "document.getElementById('bfElapsed').textContent=fmtDur(d.elapsedMs||0);";
    j += "document.getElementById('bfIter').textContent=fmtNum(d.iterations||0);";
    j += "document.getElementById('bfIterSec').textContent=(d.iterationsPerSec||0).toFixed(1);";
    j += "document.getElementById('bfRestarts').textContent=d.restarts||0;";
    j += "}catch(e){";
    j += "if(pollOk){pollOk=false;const cn=document.getElementById('conn');cn.textContent='Disconnected';cn.style.background='#f8514930';cn.style.color='#f85149';}";
    j += "}}";
    j += "setInterval(pollStatus,500);pollStatus();";

    // Current session log/improvements polling
    j += "let lastLogLen=0,lastImpLen=0;";
    j += "async function pollCurrentLog(){";
    j += "if(activeSession!=='current'||activeSubTab!=='log')return;";
    j += "try{const r=await fetch('/api/bf/log');const arr=await r.json();";
    j += "if(arr.length!==lastLogLen){lastLogLen=arr.length;renderLog(arr);}";
    j += "}catch(e){}}";

    j += "async function pollCurrentImp(){";
    j += "if(activeSession!=='current'||activeSubTab!=='imp')return;";
    j += "try{const r=await fetch('/api/bf/improvements');const arr=await r.json();";
    j += "if(arr.length!==lastImpLen){lastImpLen=arr.length;renderImp(arr);document.getElementById('bfImpCount').textContent=arr.length;}";
    j += "}catch(e){}}";

    j += "setInterval(pollCurrentLog,1000);setInterval(pollCurrentImp,2000);";

    // Settings polling
    j += "async function pollSettings(){";
    j += "try{const r=await fetch('/api/bf/settings');const d=await r.json();";
    j += "document.getElementById('sTarget').textContent=d.target||'-';";
    j += "document.getElementById('sRestart').textContent=d.restartAfter>0?fmtNum(d.restartAfter)+' iterations':'Disabled';";
    j += "document.getElementById('sFile').textContent=d.resultFilename||'-';";
    j += "document.getElementById('sFolder').textContent=d.resultFolder||'(root)';";
    j += "const sl=document.getElementById('sSlots');while(sl.firstChild)sl.removeChild(sl.firstChild);";
    j += "if(d.slots){d.slots.forEach((s,i)=>{";
    j += "const div=document.createElement('div');div.className='slot-item '+(s.enabled?'enabled':'disabled');";
    j += "div.textContent='#'+(i+1)+': '+s.algorithm+(s.enabled?'':' (off)')+' - '+s.modifyCount+' mods, '+s.minTime+'-'+s.maxTime+'ms';";
    j += "sl.appendChild(div);});}";
    j += "}catch(e){}}";
    j += "setInterval(pollSettings,5000);pollSettings();";

    // Sessions polling
    j += "async function pollSessions(){";
    j += "try{const r=await fetch('/api/bf/sessions');sessions=await r.json();renderSessionTabs();}catch(e){}}";
    j += "setInterval(pollSessions,5000);pollSessions();";

    // Map
    j += "async function loadMap(){";
    j += "try{const r=await fetch('/api/map');const d=await r.json();";
    j += "document.getElementById('mapName').textContent=d.loaded?d.name:'No map';";
    j += "document.getElementById('mapAuthor').textContent=d.loaded?d.author:'-';";
    j += "document.getElementById('mapUid').textContent=d.loaded?d.uid:'-';";
    j += "}catch(e){}}";
    j += "loadMap();setInterval(loadMap,10000);";

    // Render session tabs
    j += "function renderSessionTabs(){";
    j += "const bar=document.getElementById('sessionTabs');while(bar.firstChild)bar.removeChild(bar.firstChild);";
    j += "const cur=document.createElement('button');cur.className='tab-btn'+(activeSession==='current'?' active':'');cur.textContent='Current';";
    j += "cur.addEventListener('click',()=>{activeSession='current';renderSessionTabs();loadSessionData();});bar.appendChild(cur);";
    j += "for(let i=sessions.length-1;i>=0;i--){const s=sessions[i];";
    j += "const btn=document.createElement('button');btn.className='tab-btn'+(activeSession===s.id?' active':'');";
    j += "btn.textContent='#'+s.id+': '+(s.target||'?').substring(0,15);btn.title=s.map||'';";
    j += "const sid=s.id;btn.addEventListener('click',()=>{activeSession=sid;renderSessionTabs();loadSessionData();});bar.appendChild(btn);}";
    j += "}";

    // Sub-tab switching
    j += "document.getElementById('tabImp').addEventListener('click',()=>{activeSubTab='imp';";
    j += "document.getElementById('tabImp').className='sub-tab active';document.getElementById('tabLog').className='sub-tab';loadSessionData();});";
    j += "document.getElementById('tabLog').addEventListener('click',()=>{activeSubTab='log';";
    j += "document.getElementById('tabLog').className='sub-tab active';document.getElementById('tabImp').className='sub-tab';loadSessionData();});";

    // Load data for selected session+tab
    j += "async function loadSessionData(){";
    j += "lastLogLen=0;lastImpLen=0;";
    j += "if(activeSession==='current'){";
    j += "if(activeSubTab==='log'){pollCurrentLog();}else{pollCurrentImp();}return;}";
    j += "try{";
    j += "const type=activeSubTab==='log'?'session-log':'session-imp';";
    j += "const r=await fetch('/api/bf/'+type+'?id='+encodeURIComponent(activeSession));const arr=await r.json();";
    j += "if(activeSubTab==='log'){renderLog(arr);}else{renderImp(arr);}";
    j += "}catch(e){}}";

    // Render functions
    j += "function renderLog(arr){";
    j += "const c=document.getElementById('historyContent');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "arr.forEach(e=>{const div=document.createElement('div');div.className='log-entry';";
    j += "const ts=document.createElement('span');ts.className='lt';ts.textContent='['+fmtSec(e.t)+']';";
    j += "const msg=document.createElement('span');msg.className='lm';msg.textContent=e.msg;";
    j += "div.appendChild(ts);div.appendChild(msg);c.appendChild(div);});c.scrollTop=c.scrollHeight;}";

    j += "function renderImp(arr){";
    j += "const c=document.getElementById('historyContent');while(c.firstChild)c.removeChild(c.firstChild);";
    j += "const hdr=document.createElement('div');hdr.className='imp-row hdr';";
    j += "['#','Time','Details','Iter','Rst'].forEach(t=>{const s=document.createElement('span');s.textContent=t;hdr.appendChild(s);});c.appendChild(hdr);";
    j += "for(let i=arr.length-1;i>=0;i--){const e=arr[i];";
    j += "const row=document.createElement('div');row.className='imp-row';";
    j += "const ns=document.createElement('span');ns.textContent=i+1;";
    j += "const ts=document.createElement('span');ts.textContent=fmtSec(e.t);";
    j += "const ds=document.createElement('span');ds.textContent=((e.eval||'')+' '+(e.details||'')).substring(0,100);ds.title=e.details||'';";
    j += "const is2=document.createElement('span');is2.textContent=fmtNum(e.iteration||0);";
    j += "const rs=document.createElement('span');rs.textContent=e.restart||0;";
    j += "row.appendChild(ns);row.appendChild(ts);row.appendChild(ds);row.appendChild(is2);row.appendChild(rs);c.appendChild(row);}";
    j += "if(activeSession==='current')document.getElementById('bfImpCount').textContent=arr.length;}";

    // Initial load
    j += "setTimeout(loadSessionData,500);";

    // Format helpers
    j += "function fmtSec(s){if(s<60)return s.toFixed(1)+'s';const m=Math.floor(s/60);return m+'m '+((s%60).toFixed(1))+'s';}";
    j += "function fmtDur(ms){if(ms<1000)return ms+'ms';const s=ms/1000;const sr=Math.round(s*10)/10;if(sr<60)return sr.toFixed(1)+'s';const m=Math.floor(s/60);const sec=Math.floor(s%60);return m+'m '+sec+'s';}";
    j += "function fmtNum(n){return n.toLocaleString();}";

    return j;
}
