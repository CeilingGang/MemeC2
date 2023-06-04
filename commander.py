import os
import time
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
from base64 import b64encode, b64decode

# Pre-shared Key for AES Encryption
key_hex_str = '966b926de08c6c0bfd3811809cba8da1'
key = bytes.fromhex(key_hex_str)

# This dictionary will save the last modification time of each file
file_mod_times = {}

# The directory that the script will watch
directory = os.getcwd()

while True:
    # Always get a command input
    command = input('Enter command: ')
    with open('command.txt', 'w') as file:
        file.write(command)

    # Watch for file changes after input
    has_changed = False
    while not has_changed:
        for filename in os.listdir(directory):
            if filename.endswith('_data.txt'):
                # Get the current modification time of the file
                curr_mod_time = os.stat(filename).st_mtime

                # If the file is not in the dictionary, add it
                if filename not in file_mod_times:
                    file_mod_times[filename] = curr_mod_time
                    has_changed = True

                    # Decrypt and print new file content
                    with open(filename, 'r') as file:
                        content = file.read()
                        hostname = filename.split("_")[0]
                        print(f"┌──({hostname})-[~] {command}\n└─$ {content}")

                # If the file is in the dictionary, check if it has been modified
                elif file_mod_times[filename] < curr_mod_time:
                    file_mod_times[filename] = curr_mod_time
                    has_changed = True

                    # Decrypt and print modified file content
                    with open(filename, 'r') as file:
                        content = file.read()
                        hostname = filename.split("_")[0]
                        print(f"┌──({hostname})-[~] {command}\n└─$ {content}")

        if not has_changed:
            # Check every second
            time.sleep(1)
