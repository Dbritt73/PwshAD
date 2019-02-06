#Controller - AD Manager
[CmdletBinding()]
Param (

    [String]$SourceOU,

    [String]$DestinationOU,

    [String]$BitLockerOU,

    [String]$MonthsOld,

    [String]$CollectionID,

    [String]$SiteCode,

    [System.Management.Automation.Credential()][pscredential]$ADcred = (Get-Credential -Message "This prompt is for your administrative account for Active Directory"),

    [System.Management.Automation.Credential()][pscredential]$SCCMCred = (Get-Credential -Message "This prompt is for your administrative account for SCCM")

)

Begin {

    Try {

        #Import SCCM PowerShell Module
        $splat = @{

            'Name'        = "$ENV:ProgramFiles(x86)\Microsoft Configuration Manager\bin\ConfigurationManager.psd1"

            'Force'       = $true

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

        #Log computer objects being moved and disabled
        $Splat = @{

            'Path'            = "$PSScriptRoot\MoveLog.csv"

            NoTypeInformation = $true

            Append            = $true

        }

        $ComputerObject | Export-Csv @Splat

    Foreach ($Computer in $ComputerObject) {

        If ($Computer.Bitlocker -eq 'True') {

            Write-Verbose -Message "Moving $Computer from $SourceOU to $BitLockerOU"

            $Splat = @{

                'Identity'    = $Computer.GUID

                'TargetPath'  = $BitLockerOU

                'Credential'  = $ADcred

                'ErrorAction' = 'Stop'

            }

            Move-ADObject @Splat

        } Else {

            Write-Verbose -Message "Moving $Computer from $SourceOU to $DestinationOU"
            $Splat = @{

                'Identity'    = $Computer.GUID

                'TargetPath'  = $DestinationOU

                'Credential'  = $ADcred

                'ErrorAction' = 'Stop'

            }

            Move-ADObject @Splat

            Write-Verbose -Message "Updating AD Description for $($Computer.Name)"
            $Splat = @{

                'Identity'    = $Computer.DistinguishedName

                'Description' = "$($Computer.Description) - Disabled $(Get-Date) - PSScript"

                'Credential'  = $ADcred

                'ErrorAction' = 'Stop'

            }


            Set-ADComputer @Splat

            Write-Verbose -Message "Disabling computer object $($Computer.Name)"
            $Splat = @{

                'Identity'    = $Computer.DistinguishedName

                'Credential'  = $ADcred

                'ErrorAction' = 'Stop'

            }

            Disable-ADAccount @Splat

        }

    }

    #Delete objects from zDelete that are 10 months old or older.
    $Splat = @{

        'SearchBase' = $DestinationOU

        'MonthsOld'  = '10'

        'Credential' = $ADcred

    }

    $ComputerObject = Get-OldADComputers @Splat

        #Log computer objects being removed from AD and SCCM
        $Splat = @{

            'Path'            = "$PSScriptRoot\DeleteLog.csv"

            NoTypeInformation = $true

            Append            = $true

        }

        $ComputerObject | Export-Csv -Path @Splat

    Foreach ($Computer in $ComputerObject) {

        Write-Verbose -Message "Removing Computer Object : $($Computer.Name) : from Active Directory"
        $Splat = @{

            'Identity'    = $Computer.GUID

            'Credential'  = $ADcred

            'ErrorAction' = 'Stop'
        }

        Remove-ADObject @Splat

    }

    #Remove deleted objects from SCCM
    Write-Verbose -Message "Setting location to SCCM site PSDrive"
    Set-Location -Path $SiteCode

    Foreach ($Computer in $ComputerObject) {

        Write-Verbose -Message "Removing computer object : $($Computer.Name) : from System Center ConfigMgr Database"

        $splat = @{

            'CollectionID'   = $CollectionID

            'Name'           = $Computer.Name

            'Credential'     = $SCCMCred

            'ErrorAction'    = 'Stop'

        }

        Get-CMDevice @splat | Remove-CMDevice -Credential "$SCCMCred" -Force

    }

}

End {

    Write-Verbose -Message "Set location to $ENV:HOMEDRIVE"
    Set-Location -Path C:

}