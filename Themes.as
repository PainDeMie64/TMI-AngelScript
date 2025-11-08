string current = "";

void Render()
{
    current = GetVariableString("skycrafter_themes_currenttheme");

    if (current == "Openplanet")
    {
        SetupOpenplanetImGuiStyle();
    }
    else if (current == "Twinkie")
    {
        SetupTwinkieImGuiStyle();
    }
    else if (current == "Default")
    {
        SetupTMInterfaceImGuiStyle();
    }

    string AlreadyUsedColor = GetVariableString("ui_color_window_bg");
    int AlphaIdx = AlreadyUsedColor.FindLastOf(",");
    string NoAlpha = AlreadyUsedColor.Substr(0, AlphaIdx);
    
    SetVariable("ui_color_window_bg", NoAlpha + "," + int((GetVariableDouble("skycrafter_themes_transparent_opacity") / 100) * 255));
}

void cOption(string option)
{
    if (UI::Selectable(option, false)) SetVariable("skycrafter_themes_currenttheme", option);
}

void RenderThemesSettings()
{
    if (current == "")
    {
        SetVariable("skycrafter_themes_currenttheme", "Default");
    }
    if (UI::BeginCombo("Current theme", current)) 
    {
        cOption("Default");
        cOption("Openplanet");
        cOption("Twinkie");
        UI::EndCombo();
    }

    UI::SliderFloatVar("Opacity", "skycrafter_themes_transparent_opacity", 0.0, 100.0, "%.1f");

    UI::TextDimmed("More to come later!");
}

void Main()
{
    RegisterSettingsPage("Themes", RenderThemesSettings);
    RegisterVariable("skycrafter_themes_currenttheme", "");
    RegisterVariable("skycrafter_themes_transparent_opacity", 50.0);
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Themes";
    info.Author = "Skycrafter & jailman.";
    info.Version = "v1.0.0";
    info.Description = "Bank of themes";
    return info;
}

void SetupTwinkieImGuiStyle()
{
    SetVariable("ui_color_text", "219,237,226,255");
    SetVariable("ui_color_text_disabled", "133,140,136,255");
    SetVariable("ui_color_window_bg", "33,35,43,204");
    SetVariable("ui_color_child_bg", "38,40,48,0");
    SetVariable("ui_color_popup_bg", "51,56,68,255");
    SetVariable("ui_color_border", "35,29,34,255");
    SetVariable("ui_color_border_shadow", "0,0,0,255");
    SetVariable("ui_color_frame_bg", "43,47,59,255");
    SetVariable("ui_color_frame_bg_hovered", "116,50,76,255");
    SetVariable("ui_color_frame_bg_active", "116,50,76,255");
    SetVariable("ui_color_title_bg", "59,51,69,255");
    SetVariable("ui_color_title_bg_active", "128,19,65,255");
    SetVariable("ui_color_title_bg_collapsed", "51,56,68,255");
    SetVariable("ui_color_menu_bar_bg", "51,56,68,255");
    SetVariable("ui_color_scrollbar_bg", "61,61,56,255");
    SetVariable("ui_color_scrollbar_grab", "99,99,95,255");
    SetVariable("ui_color_scrollbar_grab_hovered", "177,177,175,255");
    SetVariable("ui_color_scrollbar_grab_active", "177,177,175,255");
    SetVariable("ui_color_check_mark", "168,35,45,255");
    SetVariable("ui_color_slider_grab", "166,38,88,255");
    SetVariable("ui_color_slider_grab_active", "181,56,68,255");
    SetVariable("ui_color_button", "166,38,88,255");
    SetVariable("ui_color_button_hovered", "116,50,76,255");
    SetVariable("ui_color_button_active", "116,50,76,255");
    SetVariable("ui_color_header", "116,50,76,255");
    SetVariable("ui_color_header_hovered", "166,38,88,255");
    SetVariable("ui_color_header_active", "128,19,65,255");
    SetVariable("ui_color_separator", "109,109,127,255");
    SetVariable("ui_color_separator_hovered", "25,102,191,255");
    SetVariable("ui_color_separator_active", "25,102,191,255");
    SetVariable("ui_color_resize_grip", "166,38,88,255");
    SetVariable("ui_color_resize_grip_hovered", "116,50,76,255");
    SetVariable("ui_color_resize_grip_active", "116,50,76,255");
    SetVariable("ui_color_tab", "45,89,147,255");
    SetVariable("ui_color_tab_hovered", "66,150,249,255");
    SetVariable("ui_color_tab_active", "50,104,173,255");
    SetVariable("ui_color_tab_unfocused", "17,26,37,255");
    SetVariable("ui_color_tab_unfocused_active", "34,66,108,255");
    SetVariable("ui_color_plot_lines", "219,237,226,255");
    SetVariable("ui_color_plot_lines_hovered", "116,50,76,255");
    SetVariable("ui_color_plot_histogram", "79,198,50,255");
    SetVariable("ui_color_plot_histogram_hovered", "116,50,76,255");
    SetVariable("ui_color_table_header_bg", "48,48,51,255");
    SetVariable("ui_color_table_border_strong", "79,79,89,255");
    SetVariable("ui_color_table_border_light", "58,58,63,255");
    SetVariable("ui_color_table_row_bg", "0,0,0,255");
    SetVariable("ui_color_table_row_bg_alt", "255,255,255,255");
    SetVariable("ui_color_text_selected_bg", "98,160,234,255");
    SetVariable("ui_color_drag_drop_target", "255,255,0,255");
    SetVariable("ui_color_nav_highlight", "66,150,249,255");
    SetVariable("ui_color_nav_windowing_highlight", "255,255,255,255");
    SetVariable("ui_color_nav_windowing_dim_bg", "204,204,204,255");
    SetVariable("ui_color_modal_window_dim_bg", "204,204,204,76");

    // inserted from ui_color_button
    SetVariable("ui_color_sidebar_button", "166,38,88,255");
}

void SetupOpenplanetImGuiStyle()
{
    SetVariable("ui_color_text", "255,255,255,255");
    SetVariable("ui_color_text_disabled", "127,127,127,255");
    SetVariable("ui_color_window_bg", "32,32,32,253");
    SetVariable("ui_color_child_bg", "255,255,255,0");
    SetVariable("ui_color_popup_bg", "28,28,28,253");
    SetVariable("ui_color_border", "202,202,202,0");
    SetVariable("ui_color_border_shadow", "15,15,15,25");
    SetVariable("ui_color_frame_bg", "15,15,15,239");
    SetVariable("ui_color_frame_bg_hovered", "86,106,255,102");
    SetVariable("ui_color_frame_bg_active", "86,106,255,170");
    SetVariable("ui_color_title_bg", "26,26,26,255");
    SetVariable("ui_color_title_bg_active", "40,40,40,255");
    SetVariable("ui_color_title_bg_collapsed", "15,15,15,130");
    SetVariable("ui_color_menu_bar_bg", "40,40,40,255");
    SetVariable("ui_color_scrollbar_bg", "21,21,21,135");
    SetVariable("ui_color_scrollbar_grab", "102,102,102,255");
    SetVariable("ui_color_scrollbar_grab_hovered", "130,130,130,255");
    SetVariable("ui_color_scrollbar_grab_active", "158,158,158,255");
    SetVariable("ui_color_check_mark", "86,106,255,255");
    SetVariable("ui_color_slider_grab", "87,103,255,255");
    SetVariable("ui_color_slider_grab_active", "86,106,255,255");
    SetVariable("ui_color_button", "86,106,255,102");
    SetVariable("ui_color_button_hovered", "86,106,255,255");
    SetVariable("ui_color_button_active", "57,76,171,255");
    SetVariable("ui_color_header", "86,106,255,79");
    SetVariable("ui_color_header_hovered", "86,106,255,204");
    SetVariable("ui_color_header_active", "86,106,255,255");
    SetVariable("ui_color_separator", "186,186,186,255");
    SetVariable("ui_color_separator_hovered", "86,106,255,198");
    SetVariable("ui_color_separator_active", "86,106,255,255");
    SetVariable("ui_color_resize_grip", "15,15,15,127");
    SetVariable("ui_color_resize_grip_hovered", "86,106,255,170");
    SetVariable("ui_color_resize_grip_active", "86,106,255,242");
    SetVariable("ui_color_tab", "66,76,177,219");
    SetVariable("ui_color_tab_hovered", "86,106,255,204");
    SetVariable("ui_color_plot_lines", "186,186,186,255");
    SetVariable("ui_color_plot_lines_hovered", "255,174,105,255");
    SetVariable("ui_color_plot_histogram", "86,106,255,255");
    SetVariable("ui_color_plot_histogram_hovered", "227,255,25,255");
    SetVariable("ui_color_table_header_bg", "15,15,15,165");
    SetVariable("ui_color_table_border_strong", "15,15,15,255");
    SetVariable("ui_color_table_border_light", "86,106,255,255");
    SetVariable("ui_color_table_row_bg", "43,43,43,160");
    SetVariable("ui_color_table_row_bg_alt", "36,36,36,160");
    SetVariable("ui_color_text_selected_bg", "86,106,255,89");
    SetVariable("ui_color_drag_drop_target", "176,255,25,229");
    SetVariable("ui_color_nav_highlight", "86,106,255,255");
    SetVariable("ui_color_nav_windowing_highlight", "15,15,15,178");
    SetVariable("ui_color_nav_windowing_dim_bg", "70,70,70,51");
    SetVariable("ui_color_modal_window_dim_bg", "15,15,15,229");

    // inserted from ui_color_button
    SetVariable("ui_color_sidebar_button", "86,106,255,102");
}

void SetupTMInterfaceImGuiStyle()
{
    // already exist
    SetVariable("ui_color_text", "255,255,255,255");
    SetVariable("ui_color_window_bg", "3,19,20,255");
    SetVariable("ui_color_child_bg", "255,255,255,0");
    SetVariable("ui_color_popup_bg", "20,20,20,239");
    SetVariable("ui_color_border", "109,109,127,127");
    SetVariable("ui_color_border_shadow", "0,0,0,0");
    SetVariable("ui_color_frame_bg", "51,53,56,137");
    SetVariable("ui_color_frame_bg_hovered", "102,102,102,102");
    SetVariable("ui_color_frame_bg_active", "45,45,45,170");
    SetVariable("ui_color_title_bg", "10,10,10,255");
    SetVariable("ui_color_title_bg_active", "0,143,145,255");
    SetVariable("ui_color_title_bg_collapsed", "0,0,0,130");
    SetVariable("ui_color_menu_bar_bg", "35,35,35,255");
    SetVariable("ui_color_scrollbar_bg", "5,5,5,135");
    SetVariable("ui_color_scrollbar_grab", "79,79,79,255");
    SetVariable("ui_color_scrollbar_grab_hovered", "104,104,104,255");
    SetVariable("ui_color_scrollbar_grab_active", "130,130,130,255");
    SetVariable("ui_color_check_mark", "239,239,239,255");
    SetVariable("ui_color_slider_grab", "130,130,130,255");
    SetVariable("ui_color_slider_grab_active", "219,219,219,255");
    SetVariable("ui_color_button", "0,143,145,255");
    SetVariable("ui_color_button_hovered", "15,153,130,255");
    SetVariable("ui_color_button_active", "0,99,83,255");
    SetVariable("ui_color_header", "0,78,79,255");
    SetVariable("ui_color_header_hovered", "76,130,145,198");
    SetVariable("ui_color_header_active", "76,130,145,198");
    SetVariable("ui_color_separator", "109,109,127,127");
    SetVariable("ui_color_separator_hovered", "183,183,183,198");
    SetVariable("ui_color_separator_active", "130,130,130,255");
    SetVariable("ui_color_resize_grip", "232,232,232,63");
    SetVariable("ui_color_resize_grip_hovered", "206,206,206,170");
    SetVariable("ui_color_resize_grip_active", "117,117,117,242");
    
    // inserted manually via screenshot
    SetVariable("ui_color_tab", "46,78,79,255");

    // already exist
    SetVariable("ui_color_tab_unfocused", "2,3,3,255");
    SetVariable("ui_color_tab_hovered", "76,130,145,198");
    SetVariable("ui_color_tab_active", "0,20,24,255");
    SetVariable("ui_color_plot_lines", "155,155,155,255");
    SetVariable("ui_color_plot_lines_hovered", "255,109,89,255");
    SetVariable("ui_color_plot_histogram", "186,153,38,255");
    SetVariable("ui_color_plot_histogram_hovered", "255,153,0,255");

    // inserted from imgui default theme
    SetVariable("ui_color_table_header_bg", "48,48,51,165");
    SetVariable("ui_color_table_border_strong", "79,79,89,255");
    SetVariable("ui_color_table_border_light", "59,59,64,255");
    SetVariable("ui_color_table_row_bg", "43,43,43,0");
    SetVariable("ui_color_table_row_bg_alt", "255,255,255,15");

    // already exist
    SetVariable("ui_color_text_selected_bg", "221,221,221,89");
    SetVariable("ui_color_drag_drop_target", "255,255,0,229");
    SetVariable("ui_color_nav_highlight", "153,153,153,255");
    SetVariable("ui_color_nav_windowing_highlight", "255,255,255,178");
    SetVariable("ui_color_modal_window_dim_bg", "0,0,0,127");
    SetVariable("ui_color_sidebar_button", "17,40,44,255");
}
