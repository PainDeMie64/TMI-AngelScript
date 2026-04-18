string FileRead(const string &in path)
{
    CommandList list(path);
    if (list is null) return "";
    return list.Content;
}

bool FileWrite(const string &in path, const string &in content)
{
    CommandList list;
    list.Content = content;
    return list.Save(path);
}

bool FileAppendLine(const string &in path, const string &in line)
{
    string existing = FileRead(path);
    if (existing.Length > 0 && existing[existing.Length - 1] != 0x0A)
        existing += "\n";
    existing += line + "\n";
    return FileWrite(path, existing);
}
