Net::Socket@ sock = null;
Net::Socket@ clientSock = null;

enum MessageType {
    CPluginsList = 0,
    CShutdown = 1,
    CInstall = 2,
    CUninstall = 3,
    CDebug = 4
}

const string HOST = "127.0.0.1";
const uint16 PORT = 8477;


int HandleMessage()
{
    if (clientSock.Available == 0) {
        return -1;
    }

    auto type = clientSock.ReadInt32();
    switch(type) {

        case MessageType::CPluginsList: {
            return 0;
        }

        case MessageType::CShutdown: {
            log("Client disconnected");
            @clientSock = null;
            break;
        }
    }
    return -1;
}

void SendInstall(string link){
    clientSock.Write(MessageType::CInstall);
    clientSock.Write(link.get_Length());
    clientSock.Write(link);
}

void SendUninstall(string registryname){
    clientSock.Write(MessageType::CUninstall);
    clientSock.Write(registryname.get_Length());
    clientSock.Write(registryname);
}

void SendDebug(string msg){
    clientSock.Write(MessageType::CDebug);
    clientSock.Write(msg.get_Length());
    clientSock.Write(msg);
}

void Main()
{
    if (@sock is null) {
        @sock = Net::Socket();
        sock.Listen(HOST, PORT);
    }
}

array<array<string>> listoflists;
array<string> uninstalled;

bool isPreviouslyUninstalled(string e){
    for(uint i = 0; i<uninstalled.Length;++i){
        if(uninstalled[i]==e) return true;
    }
    return false;
}

void remove(string e){
    array<int> a;
    for(uint i = 0; i<uninstalled.Length;++i){
        if(uninstalled[i]==e) a.Add(i);
    }
    for(uint i = 0;i<a.Length;++i){
        uninstalled.RemoveAt(a[i]);
    }
}

// void Render()
// {   
//     auto @newSock = sock.Accept(0);
//     if (@newSock !is null) {
//         @clientSock = @newSock;
//         log("Client connected (IP: " + clientSock.RemoteIP + ")");
//     }
//     if(not UI::Begin("Plugin Browser")){
//         return;
//     }
//     UI::Text("List of available plugins and downloads (Make sure to have the python script opened)");
//     UI::BeginTable("Available Plugins", 3);
//     UI::TableNextRow();
//     UI::TableSetColumnIndex(0);
//     for (uint i = 0; i < listoflists.Length; ++i)
//     {
//         array<string> plugin = listoflists[i];
//         string title = plugin[0];
//         string description = plugin[1];
//         string download = plugin[2];
//         string registeryval = plugin[3];
//         string registery = "plugin_"+registeryval+"_enabled";
//         bool exists=false;
//         if(isPreviouslyUninstalled(registery)){
//             exists=false;
//         }else{
//             try{
//                 GetVariableString(registery);
//                 exists=true;
//             }catch{
//                 try{
//                     GetVariableBool(registery);
//                         exists=true;
//                 }catch{
//                     try{
//                         GetVariableDouble(registery);
//                         exists=true;
//                     }catch{}
//                 }
//             }
//         }
//         UI::TextWrapped(title);
//         UI::TextWrapped("\n"+description);
//         if(exists){
//             if(UI::Button("Uninstall "+ title)){
//                 SetVariable(registery,false);
//                 uninstalled.Add(registery);
//                 SendUninstall(registeryval);
//             }
//         }else {
//             if(UI::Button("Install "+ title)){
//                 if(isPreviouslyUninstalled(registery)){
//                     remove(registery);
//                 }
//                 SendInstall(download);
//             }
//         }
//         UI::TableNextColumn();
//     }

//     UI::EndTable();
//     UI::End();

//     if(@clientSock !is null){
//         if (clientSock.Available != 0) {
//             auto type = clientSock.ReadInt32();
//             switch(type) {

//                 case MessageType::CPluginsList: {
//                     auto stringLength = clientSock.ReadInt32();
//                     auto pluginsList = clientSock.ReadString(stringLength);

//                     string input = pluginsList;
//                     input.Erase(0,2);
//                     input.Erase(input.Length-2,2);
//                     array<string> lists = input.Split("], [");
//                     listoflists.Clear();
//                     for(uint i = 0; i < lists.Length ; ++i){
//                         array<string> items=lists[i].Split(", ");
//                         for(uint j = 0; j < items.Length ; ++j){
//                             items[j].Erase(0,1);
//                             items[j].Erase(items[j].Length-1,1);
//                         }
//                         listoflists.Add(items);
//                     }
//                     break;
//                 }

//                 case MessageType::CShutdown: {
//                     log("Python client disconnected");
//                     @clientSock = null;
//                     break;
//                 }
//             }
//         }
//     }
// }

void Render()
{   
    auto @newSock = sock.Accept(0);
    if (@newSock !is null) {
        @clientSock = @newSock;
        log("Client connected (IP: " + clientSock.RemoteIP + ")");
    }
    if(not UI::Begin("Plugin Browser")){
        return;
    }
    UI::Text("List of available plugins and downloads (Make sure to have the python script opened)");
    for (uint i = 0; i < listoflists.Length; ++i)
    {
        array<string> plugin = listoflists[i];
        string title = plugin[0];
        string description = plugin[1];
        string download = plugin[2];
        string registeryval = plugin[3];
        string registery = "plugin_"+registeryval+"_enabled";
        bool exists=false;
        if(isPreviouslyUninstalled(registery)){
            exists=false;
        }else{
            try{
                GetVariableString(registery);
                exists=true;
            }catch{
                try{
                    GetVariableBool(registery);
                        exists=true;
                }catch{
                    try{
                        GetVariableDouble(registery);
                        exists=true;
                    }catch{}
                }
            }
        }
        // SendDebug("e1:" + i);
        if(i%3==0) {
            UI::BeginTable("a"+Text::FormatInt(i), 3);
            UI::TableNextRow();
        }
        UI::TableSetColumnIndex(i%3);
        // SendDebug("e2:" + i);
        UI::TextWrapped(title);
        UI::TextWrapped("\n"+description);
        // SendDebug("e3:" + i);
        if(exists){
            if(UI::Button("Uninstall "+ title)){
                SetVariable(registery,false);
                uninstalled.Add(registery);
                SendUninstall(registeryval);
            }
        }else {
            if(UI::Button("Install "+ title)){
                if(isPreviouslyUninstalled(registery)){
                    remove(registery);
                }
                SendInstall(download);
            }
        }
        // SendDebug("e4:" + i);
        UI::TableNextColumn();
        // SendDebug("e5:" + i);
        if(i%3==0) {
            UI::EndTable();
        }
        // SendDebug("e6:" + i);
    }
    UI::End();

    if(@clientSock !is null){
        if (clientSock.Available != 0) {
            auto type = clientSock.ReadInt32();
            switch(type) {

                case MessageType::CPluginsList: {
                    auto stringLength = clientSock.ReadInt32();
                    auto pluginsList = clientSock.ReadString(stringLength);

                    string input = pluginsList;
                    input.Erase(0,2);
                    input.Erase(input.Length-2,2);
                    array<string> lists = input.Split("], [");
                    listoflists.Clear();
                    for(uint i = 0; i < lists.Length ; ++i){
                        array<string> items=lists[i].Split(", ");
                        for(uint j = 0; j < items.Length ; ++j){
                            items[j].Erase(0,1);
                            items[j].Erase(items[j].Length-1,1);
                        }
                        listoflists.Add(items);
                    }
                    SendDebug("e1");
                    break;
                }

                case MessageType::CShutdown: {
                    log("Python client disconnected");
                    @clientSock = null;
                    break;
                }
            }
        }
    }
}

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "Skycrafter";
    info.Name = "Plugin Browser";
    info.Description = "Browse avaiable plugins made by the community";
    info.Version = "1.0.0";
    return info;
}