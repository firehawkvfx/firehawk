#Requires -Version 7.0

param (
    [parameter(mandatory)][string]$resourcetier,
    [parameter(mandatory)][string]$deadline_user_name,
    [parameter(mandatory)][string]$aws_region,
    [parameter(mandatory)][string]$aws_access_key,
    [parameter(mandatory)][string]$aws_secret_key
)

$ErrorActionPreference = "Stop"

# aws ssm get-parameters --with-decryption --names /firehawk/resourcetier/dev/sqs_remote_in_deadline_cert_url

function SSM-Get-Parm {
    param (
        [string]$parm_name
    )
    # $env:AWS_DEFAULT_REGION = $aws_region
    # $env:AWS_ACCESS_KEY_ID = $aws_access_key
    # $env:AWS_SECRET_ACCESS_KEY = $aws_secret_key
    # Write-Host ""
    # Write-Host "Curent user: $env:UserName"
    Write-Host "...Get ssm parameter:"
    Write-Host "$parm_name"
    Write-Host "running:`naws ssm get-parameters --with-decryption --output json --names `"$parm_name`""
    $output = $($env:AWS_DEFAULT_REGION = $aws_region; $env:AWS_ACCESS_KEY_ID = $aws_access_key; `
            $env:AWS_SECRET_ACCESS_KEY = $aws_secret_key; & 'C:\Program Files\Amazon\AWSCLIV2\aws' `
            ssm get-parameters --with-decryption --output json --names "$parm_name")
    # $output = $(aws ssm get-parameters --with-decryption --output json --names "$parm_name")
    if (-not $LASTEXITCODE -eq 0) {
        Write-Warning "...Failed retrieving: $parm_name"
        Write-Warning "LASTEXITCODE: $LASTEXITCODE"
        Write-Warning "Result: $output"
        Write-Warning "Message: $_"
        exit(1)
    }
    $output = $($output | ConvertFrom-Json)
    $invalid = $($output.InvalidParameters.Length)
    if (-not $invalid -eq 0) {
        Write-Warning "...Failed retrieving: $parm_name"
        Write-Warning "invalid parameters: $invalid"
        Write-Warning "Result: $output"
        exit(1)
    }
    $value = $($output.Parameters.Value)
    Write-Host "Retrieved value: $value"
    return $value
}

function Poll-Sqs-Queue {
    <#
    .SYNOPSIS
    Poll an AWS SQS queue for a message
    .DESCRIPTION
    Gets a value from an SQS queue, optionally draining the message.
    .PARAMETER resourcetier
    Specifies the environment.
    .PARAMETER parm_name
    Specifies the parameter name to aquire
    .INPUTS
    None. You cannot pipe objects to Poll-Sqs-Queue.
    .OUTPUTS
    System.String. Poll-Sqs-Queue returns nothing.
    .EXAMPLE
    PS> Poll-Sqs-Queue -resourcetier 'dev'
    .LINK
    http://www.firehawkvfx.com
    #>
    param (
        [parameter(mandatory)][string]$resourcetier,
        [string]$parm_name = "/firehawk/resourcetier/$resourcetier/sqs_remote_in_deadline_cert_url",
        [string]$sqs_queue_url = $(SSM-Get-Parm $parm_name),
        [string]$drain_queue = $false,
        [float]$default_poll_duration = 5,
        [float]$max_count = 1
    )

    Write-Host "...Polling SQS queue"
    $count = 0
    $poll = $true

    while ($poll) {
        $count += 1
        Write-Host "aws sqs receive-message --queue-url $sqs_queue_url --output json"
        $msg = $(aws sqs receive-message --queue-url $sqs_queue_url --output json)
        Write-Host "msg: $msg"
        if ($msg) {
            $poll = $false
            # check for error in request
            if (-not $LASTEXITCODE -eq 0) {
                Write-Error "Error getting msg: $msg"
                exit(1)
            }
            # convert msg from json
            $msg = $($msg | ConvertFrom-Json)

            # get the message count
            $count = $($msg.Messages.Count)
            if ($count -eq 0) {
                Write-Error "No messages in queue."
                exit(1)
            }
            if ($count -gt 1) {
                Write-Error "Too many messages in queue. Count: $count"
                exit(1)
            }
            if (-not $count -eq 1) {
                Write-Error "Message count invalid. Count: $count"
                exit(1)
            }
            
            # get msg body
            $body = $($msg.Messages[0].Body)
            if (-not "$body") {
                Write-Error "Message body invalid. body: $body"
                exit(1)
            }
            $body = $($body | ConvertFrom-Json)

            if ($drain_queue) {
                # receipt handle is required to drain queue
                $receipt_handle = $($msg.Messages[0].ReceiptHandle)
                if (-not $LASTEXITCODE -eq 0 -or -not $receipt_handle) {
                    Write-Error "Couldn't get receipt_handle: $receipt_handle"
                    exit(1)
                }
                
                Write-Host "aws sqs delete-message --queue-url $sqs_queue_url --receipt-handle $receipt_handle"
                aws sqs delete-message --queue-url $sqs_queue_url --receipt-handle $receipt_handle
                if (-not $LASTEXITCODE -eq 0) {
                    return $body
                }
                else {
                    Write-Host "Error during aws sqs delete-message"
                }
            }
            else {
                return $body
            }

        }

        if ($poll) {
            if ($max_count -gt 0 -and $count -ge $max_count) {
                $poll = $false
                Write-Host "Max count reached."
            }
            else {
                Write-Host "...Waiting $default_poll_duration seconds before retry."
                Start-Sleep -Seconds $default_poll_duration
            }
        }
    }
}

function Get-Cert-Fingerprint {
    param (
        [parameter(mandatory = $true)][string]$file_path,
        [parameter(mandatory = $false)][string]$cert_password = ""
    )
    # current_fingerprint="$(openssl pkcs12 -in $file_path -nodes -passin pass: |openssl x509 -noout -fingerprint)"
    $thumbprint = $(New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($file_path, $cert_password)).Thumbprint
    return $thumbprint
}

function Test-Service-Up {
    param (
        [parameter(mandatory)][string]$deadline_client_cert_fingerprint,
        [parameter(mandatory)][string]$deadline_user_name
    )
    Write-Host "...Try to get fingerprint from local certificate"
    $source_file_path = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx" # the original file path that was stored in vault
    $windows_home = "C:\Users\$deadline_user_name"
    $target_path = "$windows_home\.ssh\$($source_file_path | Split-Path -Leaf)"
    if (Test-Path $target_path) {
        Write-Host "Local certificate exists: $target_path"
        $local_fingerprint = $(Get-Cert-Fingerprint -file_path $target_path)
        if ($deadline_client_cert_fingerprint -eq $local_fingerprint) {
            return $true
        }
        else {
            Write-Host "Local cert fingerprint doesn't match."
            Write-Host "deadline_client_cert_fingerprint: $deadline_client_cert_fingerprint"
            Write-Host "local: $local_fingerprint"
            return $false
        }
    }
    else {
        Write-Host "No local certificate exists yet."
    }
}

function Get-Cert-From-Secrets-Manager {
    param (
        [parameter(mandatory)][string]$resourcetier,
        [parameter(mandatory)][string]$host1,
        [parameter(mandatory)][string]$host2,
        [parameter(mandatory)][string]$vault_token,
        [parameter(mandatory)][string]$deadline_user_name
    )
    Write-Host "Request the deadline client certificate from proxy."
    $source_file_path = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx" # the original file path that was stored in vault
    # $source_vault_path = "$resourcetier/data/deadline/client_cert_files$source_file_path" # the full namespace / path to the file in vault.
    # $bash_home="/home/$deadline_user_name"
    # $bash_windows_home="/mnt/c/users/$deadline_user_name"
    $windows_home = "C:\Users\$deadline_user_name"
    $tmp_target_path = "$windows_home\.ssh\_$($source_file_path | Split-Path -Leaf)"
    $target_path = "$windows_home\.ssh\$($source_file_path | Split-Path -Leaf)"
    if (Test-Path -Path $tmp_target_path) {
        Remove-Item -Path $tmp_target_path
    }
    Write-Host "Run: Get-Secrets-Manager-File"
    Get-Secrets-Manager-File -tmp_target_path "$tmp_target_path" -target_path "$target_path"
    # Move-Item -Path $tmp_target_path -Destination $target_path
}

function Test-Path-With-Timeout {
    Write-Host "`nChecking if NFS mount exists: Test-Path `"X:\`" -PathType Container"
    $ps = [powershell]::Create().AddScript("Test-Path 'X:\' -PathType Container")
        
    # execute it asynchronously
    $handle = $ps.BeginInvoke()
    
    # Wait 2500 milliseconds for it to finish
    if(-not $handle.AsyncWaitHandle.WaitOne(2500)){
        throw "timed out"
        return
    }
    
    # WaitOne() returned $true, let's fetch the result
    $result = $ps.EndInvoke($handle)
    
    return $result
}

function Mount-NFS {
    param (
        [parameter(mandatory)][string]$resourcetier
    )
    
    try {
        
        $mounts = $(Test-Path-With-Timeout)
        Write-Host "mounts: $mounts"
        if ($mounts) {
            Write-Host "X: is already mounted"
            $dir_content = $(ls X:\)
            Write-Host "dir_content: $dir_content"
            return
        }
        else {
            throw "No mount exists.  Will attempt to mount"
        }
    }
    catch {
        Write-Host "Msg: $_"
        Write-Host "Mount not yet present.  Will mount..."
        # if ($mounts -and $mounts.count -gt 0) {
        #     Write-Host "X: is already mounted"
        #     return
        # }
        # Ensure NFS parm exists
        Write-Host "Get NFS volume export path."
        $cloud_nfs_filegateway_export = $(SSM-Get-Parm "/firehawk/resourcetier/$resourcetier/cloud_nfs_filegateway_export")
        if (-not $LASTEXITCODE -eq 0) {
            $message = $_
            Write-Warning "...Failed."
            Write-Warning "LASTEXITCODE: $LASTEXITCODE"
            Write-Warning "output: $cloud_nfs_filegateway_export"
            Write-Warning "message: $message"
            exit(1)
        }
        # Write-Host "Ensure mount exists: $cloud_nfs_filegateway_export"
        # mount.exe -o anon,nolock,hard $cloud_nfs_filegateway_export X:
        $cloud_nfs_filegateway_export = $($cloud_nfs_filegateway_export).Replace(":/", "\")
        $cloud_nfs_filegateway_export = $($cloud_nfs_filegateway_export).Replace("/", "\")
        Write-Host "Mount Volume with: `
New-PSDrive X -PsProvider FileSystem -Root \\$cloud_nfs_filegateway_export -Persist -Scope Global"
        # New-PSDrive X -PsProvider FileSystem -Root \\10.40.1.1\export\isos -Persist
        New-PSDrive X -PsProvider FileSystem -Root \\$cloud_nfs_filegateway_export -Persist -Scope Global

        # Invoke-Command -FilePath "New-PSDrive X -PsProvider FileSystem -Root \\$cloud_nfs_filegateway_export -Persist -Scope Global" -Credential Get-Credential
        if (-not $LASTEXITCODE -eq 0) {
            $message = $_
            Write-Warning "...Failed."
            Write-Warning "LASTEXITCODE: $LASTEXITCODE"
            # Write-Warning "output: $cloud_nfs_filegateway_export"
            Write-Warning "message: $message"
            exit(1)
        }
        # ensure we were succesfull
        try {
            $mounts = $(Test-Path-With-Timeout)
            Write-Host "mounts: $mounts"
            if ($mounts) {
                Write-Host "X: is already mounted"
                $dir_content = $(ls X:\)
                Write-Host "dir_content: $dir_content"
                return
            }
            else {
                throw "No mount exists."
            }
        } catch {
            throw "Failed to mount at path X:\"
        }
    }
}

function Get-Secrets-Manager-File {
    param (
        [parameter(mandatory)][string]$tmp_target_path,
        [parameter(mandatory)][string]$target_path
    )

    $cert_password = ""

    Write-Host "Aquiring file from aws secrets manager"

    
    # log "Request the deadline client certificate from proxy."
    # source_file_path="/opt/Thinkbox/certs/Deadline10RemoteClient.pfx" # the original file path that was stored in vault
    # source_vault_path="$resourcetier/data/deadline/client_cert_files$source_file_path" # the full namespace / path to the file in vault.
    # tmp_target_path="$HOME/.ssh/_$(basename $source_file_path)"
    # target_path="$HOME/.ssh/$(basename $source_file_path)"

    # rm -f $tmp_target_path
    # $win_script_path = "$PSScriptRoot\get-vault-file"
    # $bash_script_path = $(wsl wslpath -a "'$win_script_path'") # this is broken?
    # $bash_script_path = "/mnt/c/AppData/get-vault-file" # TODO dont do this!

    # Write-Host "`$win_script_path = `"$win_script_path`""
    # Write-Host "`$bash_script_path = `"$bash_script_path`""
    # Write-Host "`$host1 = `"$host1`""
    # Write-Host "`$host2 = `"$host2`""
    # Write-Host "`$source_vault_path = `"$source_vault_path`""
    Write-Host "`$tmp_target_path = `"$tmp_target_path`""
    # Write-Host "`$vault_token = `"$vault_token`""

    # TODO if winodws supports ssh certificates, get this working
    # Get-File-Stdout-Proxy -host1 "$host1" -host2 "$host2" -vault_token "$vault_token" -source_vault_path "$source_vault_path" -target_path "$target_path"
    
    Write-Host "Running: aws secretsmanager get-secret-value --secret-id"
    # $output = $(bash -c "echo 'test'")
    # $output = $(bash "$bash_script_path" --host1 $host1 --host2 $host2 --source-vault-path $source_vault_path --target-path $tmp_target_path --vault-token $vault_token)
    
    $output = $($env:AWS_DEFAULT_REGION = $aws_region; $env:AWS_ACCESS_KEY_ID = $aws_access_key; $env:AWS_SECRET_ACCESS_KEY = $aws_secret_key; & 'C:\Program Files\Amazon\AWSCLIV2\aws' secretsmanager get-secret-value --secret-id "/firehawk/resourcetier/$resourcetier/file_deadline_cert" --output json)

    # $message = $_
    # mv $tmp_target_path $target_path 
    if (-not $LASTEXITCODE -eq 0) {
        $message = $_
        Write-Warning "...Failed running: $bash_script_path"
        Write-Warning "LASTEXITCODE: $LASTEXITCODE"
        Write-Warning "output: $output"
        Write-Warning "message: $message"
        exit(1)
    }
    Write-Host "Parsing SecretString"
    $output = $($output | ConvertFrom-Json)
    $output = $($output.SecretString | ConvertFrom-Json).file
    Write-Host = "`$output = `"$output`""
    Write-Host "Base64 decode"

    # $converted = $(bash -c "echo $output | base64 --decode")
    # $output=$([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($output)))

    $bytes = [Convert]::FromBase64String($output)

    Write-Host "Remove existing files: $tmp_target_path"
    if (Test-Path -Path $tmp_target_path) {
        Remove-Item -Path $tmp_target_path
    }
    Write-Host "Output to disk: $tmp_target_path"
    # $output | Out-File -FilePath $tmp_target_path

    [IO.File]::WriteAllBytes($tmp_target_path, $bytes)

    # validate a fingerprint
    Write-Host "Validate a fingerprint is possible..."
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tmp_target_path, $cert_password)

    Write-Host "Move cert from temp $tmp_target_path to $target_path"
    Move-Item -Path $tmp_target_path -Destination $target_path -Force

    if (Test-Path -Path $target_path) {
        Write-Host "File acquired!"
    }
    else {
        Write-Warning "Could not aquire data. Aborting. Output:"
        Write-Warning "$_"
        exit(1)
    }
}

function Get-File-Stdout-Local {
    param (
        [parameter(mandatory)][string]$vault_token,
        [parameter(mandatory)][string]$source_vault_path,
        [parameter(mandatory)][string]$target_path
    )
    Write-Host "Local Vault request"
    Write-Host "Retrieve: $source_vault_path"

    $bash_script_path = $(wsl wslpath -a "'$PSScriptRoot\request_stdout.sh'")
    # bash "$bash_script_path" "$source_vault_path/file" "$vault_token"
    # if (-not $LASTEXITCODE -eq 0) {
    #     Write-Warning "...Failed test running: $bash_script_path"
    #     Write-Warning "LASTEXITCODE: $LASTEXITCODE"
    #     exit(1)
    # }
    Write-Host "bash `"$bash_script_path`" `"$source_vault_path/file`" `"$vault_token`""

    response=$(bash "$bash_script_path" "$source_vault_path/file" "$vault_token")
    if (-not $LASTEXITCODE -eq 0) {
        Write-Warning "...Failed running: $bash_script_path"
        Write-Warning "LASTEXITCODE: $LASTEXITCODE"
        exit(1)
    }
    Stdout-To-File -response "$response" -target_path "$target_path"
}

function Get-File-Stdout-Proxy {
    param (
        [parameter(mandatory)][string]$host1,
        [parameter(mandatory)][string]$host2,
        [parameter(mandatory)][string]$vault_token,
        [parameter(mandatory)][string]$source_vault_path,
        [parameter(mandatory)][string]$target_path
        # [parameter()][string]$local_request = $false
    )
    if ($IsWindows) {
        # For windows the system wide ssh known_hosts is not known.
        # $ssh_known_hosts_path="$HOME/.ssh/known_hosts"
        # windows will use bash for ssh functions, so this is the bash path.
        $ssh_known_hosts_path = "/etc/ssh/ssh_known_hosts"
    }
    elseif ($IsMacOs) {
        $ssh_known_hosts_path = "/usr/local/etc/ssh/ssh_known_hosts"
    }
    elseif ($IsLinux) {
        $ssh_known_hosts_path = "/etc/ssh/ssh_known_hosts"
    }
    else {
        throw "Something has gone wrong because the os could not be determined"
    }
    Write-Host "`$ssh_known_hosts_path = $ssh_known_hosts_path"
    Write-Host "`$host1 = $host1"
    Write-Host "`$host2 = $host2"
    Write-Host "`$source_vault_path = $source_vault_path"
    Write-Host "`$vault_token = $vault_token"
    Set-PSDebug -Trace 1
    response=$(ssh -i "$HOME\.ssh\id_rsa-cert.pub" -i "$HOME\.ssh\id_rsa" -o UserKnownHostsFile="$ssh_known_hosts_path" -o ProxyCommand="ssh -i \"$HOME/.ssh/id_rsa-cert.pub\" -i \"$HOME/.ssh/id_rsa\" -o UserKnownHostsFile=\"$ssh_known_hosts_path\" $host1 -W %h:%p" $host2 "bash -s" `< $PSScriptRoot/request_stdout.sh "$source_vault_path/file" "$vault_token")

    Stdout-To-File -response $response -target_path $target_path






}
function Stdout-To-File {
    param (
        [parameter(mandatory)][string]$response,
        [parameter(mandatory)][string]$target_path
    )
    $errors = $(response.errors.Length)
    if (-not $errors -eq 0) {
        Write-Warning "Vault request failed. response: $response"
        exit(1)
    }
    Write-Host "stdout_to_file mkdir: $(Split-Path -parent $target_path)"
    New-Item $(Split-Path -parent $target_path) -ItemType Directory -ea 0
    Write-Host "Write file content from stdout..."
    $response.data.data.value | Out-File -FilePath $target_path
    $content = $(Get-Content -Path $target_path)
    if (-not $(Test-Path -Path $target_path)) {
        Write-Warning "Error: no file at $target_path"
        exit(1)
    }
    elseif (-not $content) {
        Write-Warning "Error: no content in $target_path"
        exit(1)
    }
    Write-Host "Request Complete."
}

function Main {
    param (
        [parameter(mandatory)][string]$resourcetier
    )
    Write-Host "Poll SQS Queue for certificate."
    $result = $(Poll-Sqs-Queue -resourcetier $resourcetier)
    if (-not $result) {
        Write-Host "No SQS message available to validate with yet. May already `
be current, have already be drained or expired."
    }
    else {
        Write-Host "...Get fingerprint from SQS Message: $result"
        $deadline_client_cert_fingerprint = $($result.deadline_client_cert_fingerprint).Replace(":", "")
        Write-Host "deadline_client_cert_fingerprint: $deadline_client_cert_fingerprint"
        if ($deadline_client_cert_fingerprint -eq "null") {
            Write-Warning "No fingerprint in message.  The invalid message should not have been sent: fingerprint: $deadline_client_cert_fingerprint"
            exit(1)
        }
        elseif (-not $deadline_client_cert_fingerprint) {
            Write-Host "No deadline_client_cert_fingerprint available to validate with yet."
            exit(0)
        }
        elseif (-not $(Test-Service-Up $deadline_client_cert_fingerprint $deadline_user_name)) {
            Write-Host "Deadline cert fingerprint is not current (No Match).  Will update. Fingerprint: $deadline_client_cert_fingerprint"
            Write-Host "...Getting SQS endpoint from SSM Parameter and await SQS message for VPN credentials."

            if ($result) {
                $host1 = $result.host1
                $host2 = $result.host2
                $vault_token = $result.token
                Get-Cert-From-Secrets-Manager "$resourcetier" "$host1" "$host2" "$vault_token" "$deadline_user_name"
                Mount-NFS "$resourcetier"
            }
            else {
                Write-Host "No payload aquired"
            }
            if (-not $(Test-Service-Up $deadline_client_cert_fingerprint $deadline_user_name)) {
                Write-Warning "Fingerprint doesn't match after attempted aquisition"
                exit(1)
            }
        }
        else {
            Write-Host "Deadline certificate matches current remote certificate."
            
        }
    }
    Mount-NFS "$resourcetier"
}

try {
    Main -resourcetier $resourcetier
}
catch {
    $message = $_
    Write-Warning "Error running Main in: $PSCommandPath. $message"
    Write-Warning "Get-Error"
    Get-Error
    exit(1)
}
