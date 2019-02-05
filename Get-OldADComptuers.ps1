function Get-OldADComputers {
    <#
    .Synopsis
    Gets a list of computers in AD that have not logged in for the past number of months

    .DESCRIPTION
    Get-OldADComputers uses the existing Get-ADcomputer cmdlet to query a specified Organizational Unit and produces 
    computer objects that have not loggedin the past uyser specified months

    .EXAMPLE
    Get-OldADComputers -SearchBase 'Computers.department' -MonthsOld '6'

    Gets all computers in the OU Computers.Department that havent been logged into for 6 months or longer

    #>
    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user',
                    ValueFromPipelineByPropertyName = $true)]
        [String]$SearchBase,

        [string]$MonthsOld = 6,

        [System.Management.Automation.Credential()][pscredential]$Credential

    )

    Begin {}

    Process {

        Try {

            $LastLoginDeadline = (Get-Date).AddMonths(-$MonthsOld)

            $ADC = @{

                'SearchBase' = $SearchBase

                'Filter'     = {(OperatingSystem -notlike '*Mac*') -And (OperatingSystem -notlike '*Ubuntu*') -And (LastLogonDate -lt $LastLoginDeadline)}

                'Properties' = '*'

                'ErrorAction' = 'Stop'

                'Credential' = $Credential

            }

            if ($PSBoundParameters.ContainsKey(('Credential'))) {

                $OldComputers = Get-ADComputer @ADC

            } else {

                $ADC.Remove('Credential')
                $OldComputers = Get-ADComputer @ADC

            }

            Foreach ($computer in $OldComputers) {

                $Bitlocker = Get-BitLockerInformation -ComputerName $Computer.Name

                $Props = [ordered]@{

                    'Name'            = $Computer.Name

                    'Description'     = $computer.Description

                    'LastLogon'       = $computer.LastLogonDate

                    'GUID'            = $computer.ObjectGUID

                    'OrgUnit'      = $computer.DistinguishedName.Split(',', 2)[1]

                    'OperatingSystem' = $Computer.OperatingSystem

                    'Enabled'         = $computer.Enabled

                    'Bitlocker'       = if ($Bitlocker) {Write-Output -InputObject 'True'} Else {Write-Output -InputObject 'False'}

                    'DateRecorded'    = (Get-Date)

                }

                $Object = New-Object -TypeName PSObject -Property $props
                $object.PSObject.typenames.insert(0, 'Report.DatedComputers')
                Write-Output -InputObject $Object

            }

        } Catch {

            # get error record
            [Management.Automation.ErrorRecord]$e = $_

            # retrieve information about runtime error
            $info = [PSCustomObject]@{

                Exception = $e.Exception.Message
                Reason    = $e.CategoryInfo.Reason
                Target    = $e.CategoryInfo.TargetName
                Script    = $e.InvocationInfo.ScriptName
                Line      = $e.InvocationInfo.ScriptLineNumber
                Column    = $e.InvocationInfo.OffsetInLine

            }

            # output information. Post-process collected info, and log info (optional)
            Write-output -InputObject $info

        }

    }

    End {}

}