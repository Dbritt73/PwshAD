#Controller - AD Manager
[CmdletBinding()]
Param (

    [String]$SourceOU,

    [String]$DestinationOU,

    [String]$BitLockerOU,

    [String]$MonthsOld,

    [String]$CollectionID,

    [System.Management.Automation.Credential()][pscredential]$ADcred = (Get-Credential -Message "This prompt is for your administrative account for Active Directory"),

    [System.Management.Automation.Credential()][pscredential]$SCCMCred = (Get-Credential -Message "This prompt is for your administrative account for SCCM")

)

Begin {

    Try {

        #Import SCCM PowerShell Module
        $splat = @{

            'Name' = "$ENV:ProgramFiles(x86)\Microsoft Configuration Manager\bin\ConfigurationManager.psd1"

            'Force' = $true

            'ErrorAction' = 'Stop'

        }

        Import-Module @splat

    } Catch {

        throw "System Center Configuration Manager Admin Console required to execute this script"

    }

    #Source Bitlocker function into memory
    . $PSScriptRoot\Get-BitLockerInformation.ps1

    #Source AD Function into memory
    . $PSScriptRoot\Get-OldADComputers.ps1

}

Process {

    #Move AD Computers to specified delete OU
    $ComputerObject = Get-OldADComputers -SearchBase $SourceOU -MonthsOld '6'

    Foreach ($Computer in $ComputerObject) {

        If ($Computer.Bitlocker -eq 'True') {

            Write-Verbose -Message "Moving $Computer from $SourceOU to $BitLockerOU"

            $Splat = @{

                'Identity' = $Computer.GUID

                'TargetPath' = $BitLockerOU

                'Credential' = $ADcred

                'ErrorAction' = 'Stop'

            }

            Move-ADObject @Splat

        } Else {

            Write-Verbose -Message "Moving $Computer from $SourceOU to $DestinationOU"

            $Splat = @{

                'Identity' = $Computer.GUID

                'TargetPath' = $DestinationOU

                'Credential' = $ADcred

                'ErrorAction' = 'Stop'

            }

            Move-ADObject @Splat

            $Splat = @{

                'Identity'    = $Computer.DistinguishedName

                'Description' = "$($Computer.Description) - Disabled $(Get-Date) - PSScript"

                'Credential'  = $ADcred

                'ErrorAction' = 'Stop'

            }

            Write-Verbose -Message "Updating AD Description for $($Computer.Name)"
            Set-ADComputer @Splat

            Write-Verbose -Message "Disabling computer object $($Computer.Name)"
            Disable-ADAccount -Identity $Computer.DistinguishedName

        }

    }

    $ComputerObject | Export-Csv -Path "$PSScriptRoot\MoveLog.csv" -NoTypeInformation -Append

    #Delete objects from zDelete that are 10 months old or older.
    $ComputerObject = Get-OldADComputers -SearchBase $DestinationOU -MonthsOld '10'

    Foreach ($Computer in $ComputerObject) {

        Write-Verbose -Message "Removing Computer Object : $($Computer.Name) : from Active Directory"
        Remove-ADObject -Identity $Computer.GUID -Credential $ADcred

    }

    $ComputerObject | Export-Csv -Path "$PSScriptRoot\DeleteLog.csv" -NoTypeInformation -Append

    #Remove deleted objects from SCCM
    Write-Verbose -Message "Setting location to SCCM site PSDrive"
    Set-Location -Path WWU:

    Foreach ($Computer in $ComputerObject) {

        Write-Verbose -Message "Removing computer object : $($Computer.Name) : from System Center ConfigMgr Database"

        $splat = @{

            'CollectionID' = $CollectionID

            'Name'           = $Computer.Name

            'Credential'     = $SCCMCred

            'ErrorAction'    = 'Stop'

        }

        Get-CMDevice @splat | Remove-CMDevice -Credential $SCCMCred -Force

    }

}

End {

    Write-Verbose -Message "Set location to $ENV:HOMEDRIVE"
    Set-Location -Path C:

}