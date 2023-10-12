import socket
import struct
import time
import requests
import json
import signal
from sys import stdout
from sys import exit
from tminterface.structs import SimStateData, CheckpointData
from multiprocessing import Process
import os
import zipfile
from pathlib import Path
import shutil

HOST = "127.0.0.1"
PORT = 8477
json_url = "http://skycrafter644.alwaysdata.net/plugins_list.json"
local_json = "plugins_list.json"

C_PLUGINS_LIST = 0
C_SHUTDOWN = 1
C_INSTALL = 2
C_UNINSTALL = 3
C_DEBUG = 4

sock = None

def fetch_json_data(url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching JSON data: {e}")
        return None

def load_local_data(file_path):
    try:
        with open(file_path, "r") as file:
            return json.load(file)
    except FileNotFoundError:
        return None

def save_local_data(data, file_path):
    with open(file_path, "w") as file:
        json.dump(data, file, indent=4)

def signal_handler(sig, frame):
    global sock

    print('Shutting down...')
    sock.sendall(struct.pack('i', C_SHUTDOWN))
    sock.close()
    exit()

def send_plugins_list(sock, pluginslist):
    sock.sendall(struct.pack('i', C_PLUGINS_LIST))
    sock.sendall(struct.pack('i', len(pluginslist)))
    sock.sendall(pluginslist.encode('utf-8'))

def respond(sock, type):
    sock.sendall(struct.pack('i', type))

def fetch_and_process_data(sock):
    first=True
    while True:
        remote_data = fetch_json_data(json_url)
        if not remote_data is None:
            local_data = load_local_data(local_json)

            if local_data is None or local_data != remote_data or first:
                first=False
                print("Data is different or local data doesn't exist. Updating...")

                save_local_data(remote_data, local_json)

                remote_data_str = json.dumps(remote_data).replace("\n", "")
                send_plugins_list(sock, remote_data_str)
        time.sleep(1)

def request_processs(sock):
    def delete_plugin_files_and_directories(root_dir):
        for root, dirs, files in os.walk(root_dir, topdown=False):
            for file_name in files:
                if file_name == "plugin":
                    file_path = os.path.join(root, file_name)
                    os.remove(file_path)
            for dir_name in dirs:
                if dir_name == "plugin":
                    dir_path = os.path.join(root, dir_name)
                    shutil.rmtree(dir_path)
    while True:
        message_type=-1
        try:
            message_type = struct.unpack('i', sock.recv(4))[0]
        except:
            pass
        if(message_type==C_UNINSTALL):
            length = struct.unpack('i', sock.recv(4))[0]
            name = sock.recv(length).decode()
            path=Path(os.getcwd())
            pluginsdir=path.parent.absolute()
            for entry in os.listdir(pluginsdir):
                entry_path = os.path.join(pluginsdir, entry)
                if os.path.isfile(entry_path) and os.path.splitext(entry)[0].lower() == name:
                    os.remove(entry_path)
                
                if os.path.isdir(entry_path) and entry.lower() == name:
                    shutil.rmtree(entry_path)
        elif(message_type==C_INSTALL):
            length = struct.unpack('i', sock.recv(4))[0]
            link = sock.recv(length).decode()
            print("found link to download: " + link)
            path=Path(os.getcwd())
            pluginsdir=path.parent.absolute()

            file_name = os.path.join(pluginsdir, link.split("/")[-1])

            try:
                response = requests.get(link)
                response.raise_for_status()

                with open(file_name, 'wb') as file:
                    file.write(response.content)

                if zipfile.is_zipfile(file_name):
                    with zipfile.ZipFile(file_name, 'r') as zip_ref:
                        zip_ref.extractall(pluginsdir)

                    os.remove(file_name)

                print(f"Download and extraction completed: {file_name}")
            except Exception as e:
                print(f"An error occurred: {str(e)}")
        elif(message_type==C_DEBUG):
            length = struct.unpack('i', sock.recv(4))[0]
            msg = sock.recv(length).decode()
            print("Debug message from client: " + msg)

            
            


def main():
    local_data = load_local_data(local_json)
    if local_data is None:
        save_local_data(fetch_json_data(json_url), local_json)
    global sock

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((HOST, PORT))
    print('Connected')


    request_process = Process(target=request_processs, args=(sock,))
    data_process = Process(target=fetch_and_process_data, args=(sock,))

    request_process.start()
    data_process.start()

    data_process.join()
    request_process.join()

if __name__ == "__main__":
    main()
