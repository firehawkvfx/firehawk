#Requires -Version 7.0

Write-Host "Start Service"

# $ErrorActionPreference = "Stop"

function Main {
    $Timer = New-Object Timers.Timer
    $Timer.Interval = 10000
    $Timer.Enabled = $True
    $Timer.AutoReset = $True
    $objectEventArgs = @{
        InputObject      = $Timer
        EventName        = 'Elapsed'
        SourceIdentifier = 'myservicejob'
        Action           = {
            try {
                $resourcetier = "dev"
                Write-Host "Run aws-auth-deadline-cert`nCurent user: $env:UserName"
                Set-strictmode -version latest
                if (Test-Path -Path C:\AppData\myservice-config.ps1) {
                    . C:\AppData\myservice-config.ps1
                    C:\AppData\aws-auth-deadline-pwsh-cert.ps1 -resourcetier $resourcetier -deadline_user_name $deadline_user_name -aws_region $aws_region -aws_access_key $aws_access_key -aws_secret_key $aws_secret_key
                }
                else {
                    Write-Warning "C:\AppData\myservice-config.ps1 does not exist.  Install the service again and do not use the -skip_configure_aws argument"
                }
                Write-Host "Finished running aws-auth-deadline-cert"
            }
            catch {
                Write-Warning "Error in service Action{} block"
                Write-Warning "Message: $_"
                exit(1)
            }
        }
    }
    $Job = Register-ObjectEvent @objectEventArgs

    Wait-Event
}

try {
    Main
}
catch {
    Write-Warning "Error running Main in: $PSCommandPath"
    exit(1)
}
