string current = "";

void Render()
{
    current = GetVariableString("skycrafter_themes_currenttheme");
    if(current == "Default")
    {
        UI::PopStyleColor(999);
    }
    else if (current == "Transparent")
    {
        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, GetVariableDouble("skycrafter_themes_transparent_opacity") / 100));
    }
    else if (current == "Openplanet")
    {
        SetupOpenplanetImGuiStyle();
    }
    else
    {
        SetupTwinkieImGuiStyle();
    }
}

void cOption(string option)
{
    if (UI::Selectable(option, false)) SetVariable("skycrafter_themes_currenttheme", option);
}

void RenderThemesSettings(){
    if(current == "")
    {
        SetVariable("skycrafter_themes_currenttheme","Default");
    }
    if (UI::BeginCombo("Current theme", current)) 
    {
        cOption("Default");
        cOption("Transparent");
        cOption("Openplanet");
        cOption("Twinkie");
        UI::EndCombo();
    }
    if (current == "Transparent")
    {
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
    info.Author = "Skycrafter & ";
    info.Version = "v1.0.0";
    info.Description = "Bank of themes";
    return info;
}

void SetupTwinkieImGuiStyle()
{
    UI::PushStyleColor(UI::Col::Text, vec4(0.8588235378265381f, 0.929411768913269f, 0.886274516582489f, 1.0f));
    UI::PushStyleColor(UI::Col::TextDisabled, vec4(0.5215686559677124f, 0.5490196347236633f, 0.5333333611488342f, 1.0f));
    UI::PushStyleColor(UI::Col::WindowBg, vec4(0.1294117718935013f, 0.1372549086809158f, 0.168627455830574f, 0.8f));
    UI::PushStyleColor(UI::Col::ChildBg, vec4(0.1490196138620377f, 0.1568627506494522f, 0.1882352977991104f, 0.8f));
    UI::PushStyleColor(UI::Col::PopupBg, vec4(0.2000000029802322f, 0.2196078449487686f, 0.2666666805744171f, 1.0f));
    UI::PushStyleColor(UI::Col::Border, vec4(0.1372549086809158f, 0.1137254908680916f, 0.1333333402872086f, 1.0f));
    UI::PushStyleColor(UI::Col::BorderShadow, vec4(0.0f, 0.0f, 0.0f, 1.0f));
    UI::PushStyleColor(UI::Col::FrameBg, vec4(0.168627455830574f, 0.1843137294054031f, 0.2313725501298904f, 1.0f));
    UI::PushStyleColor(UI::Col::FrameBgHovered, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::FrameBgActive, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::TitleBg, vec4(0.2313725501298904f, 0.2000000029802322f, 0.2705882489681244f, 1.0f));
    UI::PushStyleColor(UI::Col::TitleBgActive, vec4(0.501960813999176f, 0.07450980693101883f, 0.2549019753932953f, 1.0f));
    UI::PushStyleColor(UI::Col::TitleBgCollapsed, vec4(0.2000000029802322f, 0.2196078449487686f, 0.2666666805744171f, 1.0f));
    UI::PushStyleColor(UI::Col::MenuBarBg, vec4(0.2000000029802322f, 0.2196078449487686f, 0.2666666805744171f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarBg, vec4(0.239215686917305f, 0.239215686917305f, 0.2196078449487686f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarGrab, vec4(0.3882353007793427f, 0.3882353007793427f, 0.3725490272045135f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarGrabHovered, vec4(0.6941176652908325f, 0.6941176652908325f, 0.686274528503418f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarGrabActive, vec4(0.6941176652908325f, 0.6941176652908325f, 0.686274528503418f, 1.0f));
    UI::PushStyleColor(UI::Col::CheckMark, vec4(0.658823549747467f, 0.1372549086809158f, 0.1764705926179886f, 1.0f));
    UI::PushStyleColor(UI::Col::SliderGrab, vec4(0.6509804129600525f, 0.1490196138620377f, 0.3450980484485626f, 1.0f));
    UI::PushStyleColor(UI::Col::SliderGrabActive, vec4(0.7098039388656616f, 0.2196078449487686f, 0.2666666805744171f, 1.0f));
    UI::PushStyleColor(UI::Col::Button, vec4(0.6509804129600525f, 0.1490196138620377f, 0.3450980484485626f, 1.0f));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::Header, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.6509804129600525f, 0.1490196138620377f, 0.3450980484485626f, 1.0f));
    UI::PushStyleColor(UI::Col::HeaderActive, vec4(0.501960813999176f, 0.07450980693101883f, 0.2549019753932953f, 1.0f));
    UI::PushStyleColor(UI::Col::Separator, vec4(0.4274509847164154f, 0.4274509847164154f, 0.4980392158031464f, 1.0f));
    UI::PushStyleColor(UI::Col::SeparatorHovered, vec4(0.09803921729326248f, 0.4000000059604645f, 0.7490196228027344f, 1.0f));
    UI::PushStyleColor(UI::Col::SeparatorActive, vec4(0.09803921729326248f, 0.4000000059604645f, 0.7490196228027344f, 1.0f));
    UI::PushStyleColor(UI::Col::ResizeGrip, vec4(0.6509804129600525f, 0.1490196138620377f, 0.3450980484485626f, 1.0f));
    UI::PushStyleColor(UI::Col::ResizeGripHovered, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::ResizeGripActive, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::Tab, vec4(0.1764705926179886f, 0.3490196168422699f, 0.5764706134796143f, 1.0f));
    UI::PushStyleColor(UI::Col::TabHovered, vec4(0.2588235437870026f, 0.5882353186607361f, 0.9764705896377563f, 1.0f));
    UI::PushStyleColor(UI::Col::TabActive, vec4(0.196078434586525f, 0.407843142747879f, 0.6784313917160034f, 1.0f));
    UI::PushStyleColor(UI::Col::TabUnfocused, vec4(0.06666667014360428f, 0.1019607856869698f, 0.1450980454683304f, 1.0f));
    UI::PushStyleColor(UI::Col::TabUnfocusedActive, vec4(0.1333333402872086f, 0.2588235437870026f, 0.4235294163227081f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotLines, vec4(0.8588235378265381f, 0.929411768913269f, 0.886274516582489f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotLinesHovered, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotHistogram, vec4(0.3098039329051971f, 0.7764706015586853f, 0.196078434586525f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotHistogramHovered, vec4(0.4549019634723663f, 0.196078434586525f, 0.2980392277240753f, 1.0f));
    UI::PushStyleColor(UI::Col::TableHeaderBg, vec4(0.1882352977991104f, 0.1882352977991104f, 0.2000000029802322f, 1.0f));
    UI::PushStyleColor(UI::Col::TableBorderStrong, vec4(0.3098039329051971f, 0.3098039329051971f, 0.3490196168422699f, 1.0f));
    UI::PushStyleColor(UI::Col::TableBorderLight, vec4(0.2274509817361832f, 0.2274509817361832f, 0.2470588237047195f, 1.0f));
    UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.0f, 0.0f, 0.0f, 1.0f));
    UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(1.0f, 1.0f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::TextSelectedBg, vec4(0.3843137323856354f, 0.6274510025978088f, 0.9176470637321472f, 1.0f));
    UI::PushStyleColor(UI::Col::DragDropTarget, vec4(1.0f, 1.0f, 0.0f, 1.0f));
    UI::PushStyleColor(UI::Col::NavHighlight, vec4(0.2588235437870026f, 0.5882353186607361f, 0.9764705896377563f, 1.0f));
    UI::PushStyleColor(UI::Col::NavWindowingHighlight, vec4(1.0f, 1.0f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::NavWindowingDimBg, vec4(0.800000011920929f, 0.800000011920929f, 0.800000011920929f, 1.0f));
    UI::PushStyleColor(UI::Col::ModalWindowDimBg, vec4(0.800000011920929f, 0.800000011920929f, 0.800000011920929f, 0.300000011920929f));
}

void SetupOpenplanetImGuiStyle()
{
    UI::PushStyleColor(UI::Col::Text, vec4(1.0f, 1.0f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::TextDisabled, vec4(0.4980392156862745f, 0.4980392156862745f, 0.4980392156862745f, 1.0f));
    UI::PushStyleColor(UI::Col::WindowBg, vec4(0.12549019607843137f, 0.12549019607843137f, 0.12549019607843137f, 0.9921568627450981f));
    UI::PushStyleColor(UI::Col::ChildBg, vec4(1.0f, 1.0f, 1.0f, 0.0f));
    UI::PushStyleColor(UI::Col::PopupBg, vec4(0.10980392156862745f, 0.10980392156862745f, 0.10980392156862745f, 0.9921568627450981f));
    UI::PushStyleColor(UI::Col::Border, vec4(0.792156862745098f, 0.792156862745098f, 0.792156862745098f, 0.0f));
    UI::PushStyleColor(UI::Col::BorderShadow, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.09803921568627451f));
    UI::PushStyleColor(UI::Col::FrameBg, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.9372549019607843f));
    UI::PushStyleColor(UI::Col::FrameBgHovered, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.4f));
    UI::PushStyleColor(UI::Col::FrameBgActive, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.6666666666666666f));
    UI::PushStyleColor(UI::Col::TitleBg, vec4(0.10196078431372549f, 0.10196078431372549f, 0.10196078431372549f, 1.0f));
    UI::PushStyleColor(UI::Col::TitleBgActive, vec4(0.1568627450980392f, 0.1568627450980392f, 0.1568627450980392f, 1.0f));
    UI::PushStyleColor(UI::Col::TitleBgCollapsed, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.5098039215686274f));
    UI::PushStyleColor(UI::Col::MenuBarBg, vec4(0.1568627450980392f, 0.1568627450980392f, 0.1568627450980392f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarBg, vec4(0.08235294117647059f, 0.08235294117647059f, 0.08235294117647059f, 0.5294117647058824f));
    UI::PushStyleColor(UI::Col::ScrollbarGrab, vec4(0.4f, 0.4f, 0.4f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarGrabHovered, vec4(0.5098039215686274f, 0.5098039215686274f, 0.5098039215686274f, 1.0f));
    UI::PushStyleColor(UI::Col::ScrollbarGrabActive, vec4(0.6196078431372549f, 0.6196078431372549f, 0.6196078431372549f, 1.0f));
    UI::PushStyleColor(UI::Col::CheckMark, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::SliderGrab, vec4(0.3411764705882353f, 0.403921568627451f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::SliderGrabActive, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::Button, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.4f));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.2235294117647059f, 0.2980392156862745f, 0.6705882352941176f, 1.0f));
    UI::PushStyleColor(UI::Col::Header, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.30980392156862746f));
    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.8f));
    UI::PushStyleColor(UI::Col::HeaderActive, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::Separator, vec4(0.7294117647058823f, 0.7294117647058823f, 0.7294117647058823f, 1.0f));
    UI::PushStyleColor(UI::Col::SeparatorHovered, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.7764705882352941f));
    UI::PushStyleColor(UI::Col::SeparatorActive, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::ResizeGrip, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.4980392156862745f));
    UI::PushStyleColor(UI::Col::ResizeGripHovered, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.6666666666666666f));
    UI::PushStyleColor(UI::Col::ResizeGripActive, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.9490196078431372f));
    UI::PushStyleColor(UI::Col::Tab, vec4(0.25882352941176473f, 0.2980392156862745f, 0.6941176470588235f, 0.8588235294117647f));
    UI::PushStyleColor(UI::Col::TabHovered, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.8f));
    // UI::PushStyleColor(UI::Col::TabSelected, vec4(0.2901960784313726f, 0.3411764705882353f, 0.807843137254902f, 1.0f));
    // UI::PushStyleColor(UI::Col::TabSelectedOverline, vec4(0.2901960784313726f, 0.3411764705882353f, 0.807843137254902f, 1.0f));
    // UI::PushStyleColor(UI::Col::TabDimmed, vec4(0.11372549019607843f, 0.12549019607843137f, 0.2196078431372549f, 0.9686274509803922f));
    // UI::PushStyleColor(UI::Col::TabDimmedSelected, vec4(0.2f, 0.23137254901960785f, 0.5254901960784314f, 1.0f));
    // UI::PushStyleColor(UI::Col::TabDimmedSelectedOverline, vec4(0.2f, 0.23137254901960785f, 0.5254901960784314f, 1.0f));
    // UI::PushStyleColor(UI::Col::DockingPreview, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.6980392156862745f));
    // UI::PushStyleColor(UI::Col::DockingEmptyBg, vec4(0.9411764705882353f, 0.9411764705882353f, 0.9411764705882353f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotLines, vec4(0.7294117647058823f, 0.7294117647058823f, 0.7294117647058823f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotLinesHovered, vec4(1.0f, 0.6823529411764706f, 0.4117647058823529f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotHistogram, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::PlotHistogramHovered, vec4(0.8901960784313725f, 1.0f, 0.09803921568627451f, 1.0f));
    UI::PushStyleColor(UI::Col::TableHeaderBg, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.6470588235294118f));
    UI::PushStyleColor(UI::Col::TableBorderStrong, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 1.0f));
    UI::PushStyleColor(UI::Col::TableBorderLight, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.16862745098039217f, 0.16862745098039217f, 0.16862745098039217f, 0.6274509803921569f));
    UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.1411764705882353f, 0.1411764705882353f, 0.1411764705882353f, 0.6274509803921569f));
    // UI::PushStyleColor(UI::Col::TextLink, vec4(0.2f, 0.4f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::TextSelectedBg, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 0.34901960784313724f));
    UI::PushStyleColor(UI::Col::DragDropTarget, vec4(0.6901960784313725f, 1.0f, 0.09803921568627451f, 0.8980392156862745f));
    UI::PushStyleColor(UI::Col::NavHighlight, vec4(0.33725490196078434f, 0.41568627450980394f, 1.0f, 1.0f));
    UI::PushStyleColor(UI::Col::NavWindowingHighlight, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.6980392156862745f));
    UI::PushStyleColor(UI::Col::NavWindowingDimBg, vec4(0.27450980392156865f, 0.27450980392156865f, 0.27450980392156865f, 0.2f));
    UI::PushStyleColor(UI::Col::ModalWindowDimBg, vec4(0.058823529411764705f, 0.058823529411764705f, 0.058823529411764705f, 0.8980392156862745f));
}
