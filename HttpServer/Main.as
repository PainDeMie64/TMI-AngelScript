const string HOST = "127.0.0.1";
const uint16 PORT = 8080;

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "HTTP Server";
    info.Author = "PainDeMie64";
    info.Description = "Web dashboard for TMInterface on localhost:8080";
    info.Version = "2.0.0";
    return info;
}

void Main()
{
    RegisterRoute("GET", "/api/state", HandleGetState);
    RegisterRoute("GET", "/api/map", HandleGetMap);
    RegisterRoute("GET", "/api/variables", HandleGetVariables);
    RegisterRoute("POST", "/api/command", HandlePostCommand);
    RegisterRoute("POST", "/api/setvar", HandlePostSetVar);
    RegisterRoute("POST", "/api/respawn", HandlePostRespawn);
    RegisterRoute("POST", "/api/giveup", HandlePostGiveUp);
    RegisterRoute("GET", "/", HandleDashboard);
    StartServer(HOST, PORT);
}

void OnDisabled()
{
    StopServer();
}

void Render()
{
    PollServer();

    if (UI::Begin("HTTP Server"))
    {
        UI::Text("Status: " + serverStatus);
        UI::Text("Requests: " + Text::FormatUInt(requestCount));
        UI::Text("Last: " + lastRequestPath);
        UI::Text("URL: http://" + HOST + ":" + Text::FormatUInt(PORT));
    }
    UI::End();
}

string HandleDashboard(const string &in body)
{
    string h = "<!DOCTYPE html><html lang='en'><head>";
    h += "<meta charset='utf-8'>";
    h += "<meta name='viewport' content='width=device-width,initial-scale=1'>";
    h += "<title>TMInterface Dashboard</title>";
    h += "<style>";
    h += DashboardCSS();
    h += "</style></head><body>";
    h += "<header><h1>TMInterface Dashboard</h1><span id='conn' class='badge'>Connecting...</span></header>";
    h += "<main>";

    h += "<section class='panel' id='telemetry'>";
    h += "<h2>Telemetry</h2>";
    h += "<div class='grid2'>";
    h += "<div class='stat'><label>Game State</label><span id='gameState' class='badge'>-</span></div>";
    h += "<div class='stat'><label>Race Time</label><span id='raceTime'>-</span></div>";
    h += "<div class='stat'><label>Speed</label><span id='speed' class='big'>-</span></div>";
    h += "<div class='stat'><label>Best Time</label><span id='bestTime'>-</span></div>";
    h += "<div class='stat'><label>Checkpoints</label><span id='checkpoints'>-</span></div>";
    h += "<div class='stat'><label>Lap</label><span id='curLap'>-</span></div>";
    h += "<div class='stat'><label>Finished</label><span id='finished'>-</span></div>";
    h += "<div class='stat'><label>Turbo</label><span id='turbo'>-</span></div>";
    h += "</div>";
    h += "<h3>Position</h3><div class='vec3' id='position'>-</div>";
    h += "<h3>Velocity</h3><div class='vec3' id='velocity'>-</div>";
    h += "<h3>Local Speed</h3><div class='vec3' id='localSpeed'>-</div>";
    h += "<h3>Inputs</h3>";
    h += "<div class='input-bars'>";
    h += "<div class='bar-row'><label>Gas</label><div class='bar-bg'><div class='bar gas' id='barGas'></div></div><span id='valGas'>0</span></div>";
    h += "<div class='bar-row'><label>Brake</label><div class='bar-bg'><div class='bar brake' id='barBrake'></div></div><span id='valBrake'>0</span></div>";
    h += "<div class='bar-row'><label>Steer</label><div class='bar-bg steer-bg'><div class='bar steer' id='barSteer'></div></div><span id='valSteer'>0</span></div>";
    h += "</div>";
    h += "</section>";

    h += "<section class='panel' id='mapinfo'>";
    h += "<h2>Map</h2>";
    h += "<div class='stat'><label>Name</label><span id='mapName'>-</span></div>";
    h += "<div class='stat'><label>Author</label><span id='mapAuthor'>-</span></div>";
    h += "<div class='stat'><label>UID</label><span id='mapUid' class='mono'>-</span></div>";
    h += "</section>";

    h += "<section class='panel' id='actions'>";
    h += "<h2>Actions</h2>";
    h += "<div class='btn-group'>";
    h += "<button id='btnGiveUp' class='btn btn-danger'>Give Up</button>";
    h += "<button id='btnRespawn' class='btn btn-warn'>Respawn</button>";
    h += "</div>";
    h += "<div class='cmd-row'>";
    h += "<input type='text' id='cmdInput' placeholder='TMI console command...'>";
    h += "<button id='btnCmd' class='btn'>Execute</button>";
    h += "</div>";
    h += "<div id='cmdResult' class='cmd-result'></div>";
    h += "</section>";

    h += "<section class='panel wide' id='variables'>";
    h += "<h2>Variables <button id='btnRefreshVars' class='btn btn-sm'>Refresh</button></h2>";
    h += "<input type='text' id='varFilter' placeholder='Filter variables...'>";
    h += "<div id='varList' class='var-list'></div>";
    h += "</section>";

    h += "</main>";
    h += "<script>";
    h += DashboardJS();
    h += "</script></body></html>";
    return h;
}

string DashboardCSS()
{
    string c = "*{box-sizing:border-box;margin:0;padding:0}";
    c += "body{font-family:system-ui,-apple-system,sans-serif;background:#0d1117;color:#c9d1d9;min-height:100vh}";
    c += "header{background:#161b22;padding:1rem 2rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #30363d}";
    c += "header h1{font-size:1.2rem;color:#58a6ff}";
    c += "main{display:grid;grid-template-columns:1fr 1fr;gap:1rem;padding:1rem 2rem;max-width:1200px;margin:0 auto}";
    c += ".panel{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:1.2rem}";
    c += ".panel.wide{grid-column:1/-1}";
    c += ".panel h2{color:#58a6ff;font-size:1rem;margin-bottom:0.8rem;padding-bottom:0.4rem;border-bottom:1px solid #21262d}";
    c += ".panel h3{color:#8b949e;font-size:0.8rem;text-transform:uppercase;margin:0.8rem 0 0.3rem}";
    c += ".grid2{display:grid;grid-template-columns:1fr 1fr;gap:0.5rem}";
    c += ".stat{display:flex;flex-direction:column;gap:0.15rem}";
    c += ".stat label{color:#8b949e;font-size:0.75rem;text-transform:uppercase}";
    c += ".stat span{font-size:1rem}";
    c += ".big{font-size:1.8rem !important;font-weight:700;color:#fff}";
    c += ".badge{background:#21262d;padding:0.15rem 0.5rem;border-radius:4px;font-size:0.8rem;display:inline-block}";
    c += ".mono{font-family:monospace;font-size:0.8rem !important;word-break:break-all}";
    c += ".vec3{font-family:monospace;font-size:0.85rem;color:#8b949e}";
    c += ".input-bars{display:flex;flex-direction:column;gap:0.4rem;margin-top:0.3rem}";
    c += ".bar-row{display:grid;grid-template-columns:3rem 1fr 2.5rem;align-items:center;gap:0.5rem}";
    c += ".bar-row label{font-size:0.75rem;color:#8b949e;text-transform:uppercase}";
    c += ".bar-row span{font-size:0.8rem;text-align:right;font-family:monospace}";
    c += ".bar-bg{height:12px;background:#21262d;border-radius:6px;overflow:hidden;position:relative}";
    c += ".bar{height:100%;border-radius:6px;transition:width 0.1s}";
    c += ".bar.gas{background:#3fb950}";
    c += ".bar.brake{background:#f85149}";
    c += ".steer-bg{position:relative}";
    c += ".bar.steer{background:#58a6ff;position:absolute;top:0;height:100%}";
    c += ".btn-group{display:flex;gap:0.5rem;margin-bottom:0.8rem}";
    c += ".btn{background:#21262d;color:#c9d1d9;border:1px solid #30363d;padding:0.4rem 1rem;border-radius:6px;cursor:pointer;font-size:0.85rem;transition:all 0.15s}";
    c += ".btn:hover{background:#30363d}";
    c += ".btn-danger{border-color:#f8514950;color:#f85149}.btn-danger:hover{background:#f8514930}";
    c += ".btn-warn{border-color:#d2992250;color:#d29922}.btn-warn:hover{background:#d2992230}";
    c += ".btn-sm{font-size:0.7rem;padding:0.2rem 0.5rem}";
    c += ".btn.ok{background:#3fb95030;border-color:#3fb950}";
    c += ".btn.fail{background:#f8514930;border-color:#f85149}";
    c += ".cmd-row{display:flex;gap:0.5rem}";
    c += ".cmd-row input{flex:1;background:#0d1117;color:#c9d1d9;border:1px solid #30363d;padding:0.4rem 0.6rem;border-radius:6px;font-size:0.85rem;font-family:monospace}";
    c += ".cmd-result{margin-top:0.5rem;font-size:0.8rem;font-family:monospace;color:#8b949e;min-height:1.2rem}";
    c += "#varFilter{width:100%;background:#0d1117;color:#c9d1d9;border:1px solid #30363d;padding:0.4rem 0.6rem;border-radius:6px;font-size:0.85rem;margin-bottom:0.5rem}";
    c += ".var-list{max-height:300px;overflow-y:auto}";
    c += ".var-item{display:grid;grid-template-columns:1fr auto auto;gap:0.5rem;align-items:center;padding:0.3rem 0;border-bottom:1px solid #21262d;font-size:0.8rem}";
    c += ".var-item .vname{font-family:monospace;color:#c9d1d9}";
    c += ".var-item .vval{font-family:monospace;color:#58a6ff;cursor:pointer;padding:0.1rem 0.3rem;border-radius:3px}";
    c += ".var-item .vval:hover{background:#21262d}";
    c += ".var-item .vtype{color:#8b949e;font-size:0.7rem}";
    return c;
}

string DashboardJS()
{
    string j = "";

    j += "let pollOk=false;";
    j += "async function pollState(){";
    j += "try{";
    j += "const r=await fetch('/api/state');const d=await r.json();pollOk=true;";
    j += "const cn=document.getElementById('conn');cn.textContent='Connected';cn.style.background='#3fb95030';cn.style.color='#3fb950';";
    j += "document.getElementById('gameState').textContent=d.gameState||'-';";
    j += "document.getElementById('raceTime').textContent=d.raceTimeFormatted||'-';";
    j += "document.getElementById('speed').textContent=d.speed!=null?d.speed+'km/h':'-';";
    j += "document.getElementById('bestTime').textContent=d.bestTime!=null&&d.bestTime>0?fmtTime(d.bestTime):'-';";
    j += "document.getElementById('checkpoints').textContent=d.checkpoints!=null?d.checkpoints:'-';";
    j += "document.getElementById('curLap').textContent=d.curLap!=null?d.curLap:'-';";
    j += "document.getElementById('finished').textContent=d.finished!=null?(d.finished?'Yes':'No'):'-';";
    j += "document.getElementById('turbo').textContent=d.turboBoostFactor!=null?d.turboBoostFactor.toFixed(2)+'x':'-';";
    j += "document.getElementById('position').textContent=fmtV3(d.position);";
    j += "document.getElementById('velocity').textContent=fmtV3(d.velocity);";
    j += "document.getElementById('localSpeed').textContent=fmtV3(d.localSpeed);";

    j += "const gas=d.inputGas||0,brake=d.inputBrake||0,steer=d.inputSteer||0;";
    j += "document.getElementById('barGas').style.width=(gas*100)+'%';";
    j += "document.getElementById('valGas').textContent=gas.toFixed(2);";
    j += "document.getElementById('barBrake').style.width=(brake*100)+'%';";
    j += "document.getElementById('valBrake').textContent=brake.toFixed(2);";
    j += "const sp=Math.abs(steer)*50;const sl=steer<0?50-sp:50;";
    j += "document.getElementById('barSteer').style.width=sp+'%';";
    j += "document.getElementById('barSteer').style.left=sl+'%';";
    j += "document.getElementById('valSteer').textContent=steer.toFixed(3);";

    j += "}catch(e){";
    j += "if(pollOk){pollOk=false;const cn=document.getElementById('conn');cn.textContent='Disconnected';cn.style.background='#f8514930';cn.style.color='#f85149';}";
    j += "}}";
    j += "setInterval(pollState,200);pollState();";

    j += "let lastGS='';";
    j += "async function loadMap(){";
    j += "try{const r=await fetch('/api/map');const d=await r.json();";
    j += "document.getElementById('mapName').textContent=d.loaded?d.name:'No map loaded';";
    j += "document.getElementById('mapAuthor').textContent=d.loaded?d.author:'-';";
    j += "document.getElementById('mapUid').textContent=d.loaded?d.uid:'-';";
    j += "}catch(e){}}";
    j += "loadMap();";
    j += "setInterval(()=>{const gs=document.getElementById('gameState').textContent;if(gs!==lastGS){lastGS=gs;loadMap();}},1000);";

    j += "function fmtV3(v){if(!v)return'-';return'X: '+v.x.toFixed(2)+'  Y: '+v.y.toFixed(2)+'  Z: '+v.z.toFixed(2);}";
    j += "function fmtTime(ms){const m=Math.floor(ms/60000);const s=Math.floor((ms%60000)/1000);const cs=Math.floor((ms%1000)/10);return m+':'+String(s).padStart(2,'0')+'.'+String(cs).padStart(2,'0');}";

    j += "function flashBtn(btn,ok){btn.classList.add(ok?'ok':'fail');setTimeout(()=>btn.classList.remove('ok','fail'),500);}";
    j += "async function doAction(url,btn){";
    j += "try{const r=await fetch(url,{method:'POST'});const d=await r.json();flashBtn(btn,d.ok);";
    j += "}catch(e){flashBtn(btn,false);}}";

    j += "document.getElementById('btnGiveUp').addEventListener('click',function(){doAction('/api/giveup',this);});";
    j += "document.getElementById('btnRespawn').addEventListener('click',function(){doAction('/api/respawn',this);});";

    j += "async function runCmd(){";
    j += "const inp=document.getElementById('cmdInput');const cmd=inp.value.trim();if(!cmd)return;";
    j += "try{const r=await fetch('/api/command',{method:'POST',body:cmd});const d=await r.json();";
    j += "const res=document.getElementById('cmdResult');res.textContent=d.ok?'> '+d.command:'Error: '+(d.error||'unknown');";
    j += "res.style.color=d.ok?'#3fb950':'#f85149';if(d.ok)inp.value='';";
    j += "}catch(e){const res=document.getElementById('cmdResult');res.textContent='Request failed';res.style.color='#f85149';}}";

    j += "document.getElementById('btnCmd').addEventListener('click',runCmd);";
    j += "document.getElementById('cmdInput').addEventListener('keydown',function(e){if(e.key==='Enter')runCmd();});";

    j += "let allVars=[];";
    j += "async function loadVars(){";
    j += "try{const r=await fetch('/api/variables');allVars=await r.json();renderVars();}catch(e){}}";

    j += "function renderVars(){";
    j += "const filter=document.getElementById('varFilter').value.toLowerCase();";
    j += "const list=document.getElementById('varList');";
    j += "while(list.firstChild)list.removeChild(list.firstChild);";
    j += "const filtered=allVars.filter(v=>v.name.toLowerCase().includes(filter));";
    j += "filtered.slice(0,100).forEach(v=>{";
    j += "const row=document.createElement('div');row.className='var-item';";
    j += "const ns=document.createElement('span');ns.className='vname';ns.textContent=v.name;";
    j += "const vs=document.createElement('span');vs.className='vval';vs.textContent=v.value!=null?String(v.value):'-';vs.title='Click to edit';";
    j += "vs.addEventListener('click',()=>{const nv=prompt('Set '+v.name+' to:',String(v.value||''));if(nv!==null)setVar(v.name,nv);});";
    j += "const ts=document.createElement('span');ts.className='vtype';ts.textContent=v.type;";
    j += "row.appendChild(ns);row.appendChild(vs);row.appendChild(ts);list.appendChild(row);";
    j += "});";
    j += "if(filtered.length>100){const m=document.createElement('div');m.className='var-item';m.textContent='... '+(filtered.length-100)+' more';list.appendChild(m);}";
    j += "}";

    j += "document.getElementById('varFilter').addEventListener('input',renderVars);";
    j += "document.getElementById('btnRefreshVars').addEventListener('click',loadVars);";

    j += "async function setVar(name,value){";
    j += "try{await fetch('/api/setvar',{method:'POST',body:'name='+encodeURIComponent(name)+'&value='+encodeURIComponent(value)});";
    j += "setTimeout(loadVars,100);}catch(e){}}";
    j += "loadVars();";

    return j;
}
