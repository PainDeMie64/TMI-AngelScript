const uint MAX_BUFFER_SIZE = 8192;
const int MAX_WAIT_FRAMES = 30;

Net::Socket@ listenSock = null;
Net::Socket@ clientSock = null;

string requestBuffer = "";
int readWaitFrames = 0;
string lastRequestPath = "";
string serverStatus = "Starting...";
uint requestCount = 0;

// --- Routing ---

funcdef string RouteHandler(const string &in body);

class Route
{
    string method;
    string path;
    RouteHandler@ handler;
}

array<Route@> routes;

void RegisterRoute(const string &in method, const string &in path, RouteHandler@ handler)
{
    Route@ r = Route();
    r.method = method;
    r.path = path;
    @r.handler = handler;
    routes.Add(r);
}

// --- Request parsing ---

string requestMethod = "";
string requestPath = "";
string requestQuery = "";
string requestBody = "";

void ParseRequest(const string &in raw)
{
    int sp1 = raw.FindFirst(" ");
    if (sp1 < 0)
    {
        requestMethod = "GET";
        requestPath = "/";
        requestBody = "";
        return;
    }
    requestMethod = raw.Substr(0, sp1);

    string afterMethod = raw.Substr(uint(sp1 + 1));
    int sp2 = afterMethod.FindFirst(" ");
    int lineEnd = afterMethod.FindFirst("\r");

    int pathEnd = -1;
    if (sp2 >= 0 && lineEnd >= 0)
        pathEnd = (sp2 < lineEnd) ? sp2 : lineEnd;
    else if (sp2 >= 0)
        pathEnd = sp2;
    else if (lineEnd >= 0)
        pathEnd = lineEnd;

    requestPath = (pathEnd <= 0) ? "/" : afterMethod.Substr(0, pathEnd);

    int qmark = requestPath.FindFirst("?");
    if (qmark >= 0)
    {
        requestQuery = requestPath.Substr(uint(qmark + 1));
        requestPath = requestPath.Substr(0, qmark);
    }
    else
    {
        requestQuery = "";
    }

    int headerEnd = raw.FindFirst("\r\n\r\n");
    if (headerEnd >= 0)
        requestBody = raw.Substr(uint(headerEnd + 4));
    else
        requestBody = "";
}

int ParseContentLength(const string &in raw)
{
    int idx = raw.FindFirst("Content-Length: ");
    if (idx < 0)
    {
        idx = raw.FindFirst("content-length: ");
        if (idx < 0) return 0;
    }
    string after = raw.Substr(uint(idx + 16));
    int lineEnd = after.FindFirst("\r");
    if (lineEnd <= 0) return 0;
    string numStr = after.Substr(0, lineEnd);
    int val = int(Text::ParseInt(numStr));
    if (val < 0) return 0;
    return val;
}

string ExtractMethod(const string &in raw)
{
    int sp = raw.FindFirst(" ");
    if (sp < 0) return "GET";
    return raw.Substr(0, sp);
}

// --- Server lifecycle ---

void StartServer(const string &in host, uint16 port, bool silent = false)
{
    @clientSock = null;
    @listenSock = null;
    requestBuffer = "";
    readWaitFrames = 0;

    @listenSock = Net::Socket();
    if (listenSock.Listen(host, port))
    {
        serverStatus = "Listening on " + host + ":" + Text::FormatUInt(port);
    }
    else
    {
        serverStatus = "FAILED to listen on " + host + ":" + Text::FormatUInt(port);
        if (!silent)
            log("HTTP Server: " + serverStatus);
        @listenSock = null;
    }
}

void StopServer()
{
    @clientSock = null;
    @listenSock = null;
    routes.Resize(0);
    log("HTTP Server: Shut down");
}

void PollServer()
{
    if (@listenSock is null) return;

    if (@clientSock is null)
    {
        Net::Socket@ newSock = listenSock.Accept(0);
        if (@newSock !is null)
        {
            @clientSock = @newSock;
            requestBuffer = "";
            readWaitFrames = 0;
        }
        return;
    }

    uint avail = clientSock.Available;
    if (avail > 0)
    {
        uint toRead = avail;
        if (requestBuffer.Length + avail > MAX_BUFFER_SIZE)
            toRead = MAX_BUFFER_SIZE - requestBuffer.Length;
        if (toRead > 0)
        {
            requestBuffer += clientSock.ReadString(toRead);
            readWaitFrames = 0;
        }
    }
    else
    {
        readWaitFrames++;
    }

    if (requestBuffer.Length >= MAX_BUFFER_SIZE)
    {
        log("HTTP Server: Request too large, dropping connection");
        @clientSock = null;
        requestBuffer = "";
        return;
    }

    int headerEnd = requestBuffer.FindFirst("\r\n\r\n");
    if (headerEnd >= 0)
    {
        string method = ExtractMethod(requestBuffer);
        if (method == "POST")
        {
            int contentLength = ParseContentLength(requestBuffer);
            uint expectedTotal = uint(headerEnd + 4) + uint(contentLength);
            if (requestBuffer.Length < expectedTotal)
                return;
        }

        ParseRequest(requestBuffer);
        requestCount++;
        DispatchRoute();
        @clientSock = null;
        requestBuffer = "";
    }
    else if (readWaitFrames > MAX_WAIT_FRAMES)
    {
        @clientSock = null;
        requestBuffer = "";
    }
}

void DispatchRoute()
{
    if (requestMethod == "OPTIONS")
    {
        string resp = "HTTP/1.1 204 No Content\r\n";
        resp += "Access-Control-Allow-Origin: *\r\n";
        resp += "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n";
        resp += "Access-Control-Allow-Headers: Content-Type\r\n";
        resp += "Content-Length: 0\r\n";
        resp += "Connection: close\r\n\r\n";
        clientSock.Write(resp);
        return;
    }

    for (uint i = 0; i < routes.Length; i++)
    {
        if (routes[i].method == requestMethod && routes[i].path == requestPath)
        {
            lastRequestPath = requestPath;
            string body = routes[i].handler(requestBody);
            string contentType = "text/html";
            if (requestPath.FindFirst("/api/") == 0)
                contentType = "application/json";
            string response = BuildHttpResponse(200, "OK", contentType, body);
            clientSock.Write(response);
            return;
        }
    }

    lastRequestPath = requestPath;
    string body = "{\"error\":\"not found\",\"path\":\"" + EscapeJson(requestPath) + "\"}";
    string response = BuildHttpResponse(404, "Not Found", "application/json", body);
    clientSock.Write(response);
}

// --- HTTP response ---

string BuildHttpResponse(int statusCode, const string &in statusText, const string &in contentType, const string &in body)
{
    string crlf = "\r\n";
    string resp = "HTTP/1.1 " + Text::FormatInt(statusCode) + " " + statusText + crlf;
    resp += "Content-Type: " + contentType + "; charset=utf-8" + crlf;
    resp += "Content-Length: " + Text::FormatUInt(body.Length) + crlf;
    resp += "Connection: close" + crlf;
    resp += "Access-Control-Allow-Origin: *" + crlf;
    resp += crlf;
    resp += body;
    return resp;
}

// --- String utilities ---

string ReplaceAll(const string &in str, const string &in from, const string &in to)
{
    if (from.Length == 0) return str;

    string result = "";
    int start = 0;
    int idx = str.FindFirst(from, uint(start));
    while (idx >= 0)
    {
        result += str.Substr(uint(start), idx - start);
        result += to;
        start = idx + int(from.Length);
        idx = str.FindFirst(from, uint(start));
    }
    result += str.Substr(uint(start));
    return result;
}

string StripNonAscii(const string &in input)
{
    string result = "";
    for (uint i = 0; i < input.Length; i++)
    {
        uint8 c = input[i];
        if (c >= 0x20 && c < 0x7F)
            result += input.Substr(i, 1);
    }
    return result;
}

string StripControlChars(const string &in input)
{
    string result = "";
    for (uint i = 0; i < input.Length; i++)
    {
        uint8 c = input[i];
        if (c >= 0x20)
            result += input.Substr(i, 1);
    }
    return result;
}

// --- HTML escaping ---

string EscapeHtml(const string &in input)
{
    string result = StripNonAscii(input);
    result = ReplaceAll(result, "&", "&amp;");
    result = ReplaceAll(result, "<", "&lt;");
    result = ReplaceAll(result, ">", "&gt;");
    result = ReplaceAll(result, "\"", "&quot;");
    return result;
}

// --- JSON escaping ---

string EscapeJsonDisplay(const string &in input)
{
    string result = StripNonAscii(input);
    result = ReplaceAll(result, "\\", "\\\\");
    result = ReplaceAll(result, "\"", "\\\"");
    return result;
}

string EscapeJson(const string &in input)
{
    string result = StripControlChars(input);
    result = ReplaceAll(result, "\\", "\\\\");
    result = ReplaceAll(result, "\"", "\\\"");
    return result;
}

// --- JSON helpers ---

string JsonString(const string &in key, const string &in value)
{
    return "\"" + EscapeJson(key) + "\":\"" + EscapeJson(value) + "\"";
}

string JsonStringDisplay(const string &in key, const string &in value)
{
    return "\"" + EscapeJson(key) + "\":\"" + EscapeJsonDisplay(value) + "\"";
}

string JsonInt(const string &in key, int value)
{
    return "\"" + EscapeJson(key) + "\":" + Text::FormatInt(value);
}

string JsonUInt(const string &in key, uint value)
{
    return "\"" + EscapeJson(key) + "\":" + Text::FormatUInt(value);
}

string JsonFloat(const string &in key, float value)
{
    return "\"" + EscapeJson(key) + "\":" + Text::FormatFloat(value, "", 0, 3);
}

string JsonBool(const string &in key, bool value)
{
    return "\"" + EscapeJson(key) + "\":" + (value ? "true" : "false");
}

string JsonVec3(const string &in key, vec3 v)
{
    string obj = "{";
    obj += "\"x\":" + Text::FormatFloat(v.x, "", 0, 3);
    obj += ",\"y\":" + Text::FormatFloat(v.y, "", 0, 3);
    obj += ",\"z\":" + Text::FormatFloat(v.z, "", 0, 3);
    obj += "}";
    return "\"" + EscapeJson(key) + "\":" + obj;
}

// --- URL decoding ---

string CharFromByte(uint8 b)
{
    string s = " ";
    s[0] = b;
    return s;
}

string UrlDecode(const string &in input)
{
    string result = "";
    for (uint i = 0; i < input.Length; i++)
    {
        uint8 c = input[i];
        if (c == 0x2B)
        {
            result += " ";
        }
        else if (c == 0x25 && i + 2 < input.Length)
        {
            string hex = input.Substr(i + 1, 2);
            uint8 val = uint8(Text::ParseUInt(hex, 16));
            result += CharFromByte(val);
            i += 2;
        }
        else
        {
            result += input.Substr(i, 1);
        }
    }
    return result;
}

// --- Form parsing ---

string GetFormValue(const string &in body, const string &in key)
{
    string search = key + "=";
    int idx = body.FindFirst(search);
    while (idx >= 0)
    {
        if (idx == 0 || body[uint(idx - 1)] == 0x26)
        {
            string after = body.Substr(uint(idx) + search.Length);
            int ampIdx = after.FindFirst("&");
            string raw = (ampIdx >= 0) ? after.Substr(0, ampIdx) : after;
            return UrlDecode(raw);
        }
        idx = body.FindFirst(search, uint(idx + 1));
    }
    return "";
}

// --- GameState to string ---

string GameStateToString(TM::GameState state)
{
    if (state == TM::GameState::None) return "None";
    if (state == TM::GameState::GameNetMenus) return "GameNetMenus";
    if (state == TM::GameState::GameNetRoundPrepare) return "GameNetRoundPrepare";
    if (state == TM::GameState::GameNetRoundPlay) return "GameNetRoundPlay";
    if (state == TM::GameState::GameNetRoundExit) return "GameNetRoundExit";
    if (state == TM::GameState::StartUp) return "StartUp";
    if (state == TM::GameState::Menus) return "Menus";
    if (state == TM::GameState::Quit) return "Quit";
    if (state == TM::GameState::LocalInit) return "LocalInit";
    if (state == TM::GameState::LocalEditor) return "LocalEditor";
    if (state == TM::GameState::LocalRace) return "LocalRace";
    if (state == TM::GameState::LocalRaceEndDialog) return "LocalRaceEndDialog";
    if (state == TM::GameState::LocalReplayEditor) return "LocalReplayEditor";
    if (state == TM::GameState::LocalReplay) return "LocalReplay";
    if (state == TM::GameState::LocalEnd) return "LocalEnd";
    if (state == TM::GameState::NetSync) return "NetSync";
    if (state == TM::GameState::NetPlaying) return "NetPlaying";
    if (state == TM::GameState::NetExitRound) return "NetExitRound";
    if (state == TM::GameState::Unknown1) return "Unknown1";
    if (state == TM::GameState::Unknown2) return "Unknown2";
    if (state == TM::GameState::Unknown3) return "Unknown3";
    if (state == TM::GameState::Unknown4) return "Unknown4";
    if (state == TM::GameState::Unknown5) return "Unknown5";
    if (state == TM::GameState::Unknown6) return "Unknown6";
    return "Unknown";
}
