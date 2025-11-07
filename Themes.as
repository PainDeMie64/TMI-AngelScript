string current="";

void Render(){
    current = GetVariableString("skycrafter_themes_currenttheme");
    if(current=="Default"){
        UI::PopStyleColor(999);
    }else{
        UI::PushStyleColor(UI::Col::WindowBg, vec4(0,0,0,GetVariableDouble("skycrafter_themes_transparent_opacity")/100));
    }
}

void cOption(string option){
    if(UI::Selectable(option, false)) SetVariable("skycrafter_themes_currenttheme",option);
}

void RenderThemesSettings(){
    if(current==""){
        SetVariable("skycrafter_themes_currenttheme","Default");
    }
    if(UI::BeginCombo("Current theme", current)){
        cOption("Default");
        cOption("Transparent");
        UI::EndCombo();
    }
    if(current=="Transparent"){
        UI::SliderFloatVar("Opacity", "skycrafter_themes_transparent_opacity", 0.0, 100.0, "%.1f");
    }
    UI::TextDimmed("More to come later!");
}

void Main()
{
    RegisterSettingsPage("Themes", RenderThemesSettings);
    RegisterVariable("skycrafter_themes_currenttheme","");
    RegisterVariable("skycrafter_themes_transparent_opacity",50.0);
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Themes";
    info.Author = "Skycrafter";
    info.Version = "v1.0.0";
    info.Description = "Bank of themes";
    return info;
}

