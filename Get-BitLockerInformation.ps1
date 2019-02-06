Function Get-BitLockerInformation {
  <#
    .SYNOPSIS
    Retrieve BitLocker information from Active Directory for 1 or more computer objects

    .DESCRIPTION
    Get-BitLockerInformation utilizes existing ActiveDirectory Cmdlets to query the specified AD objects for information
    on their BitLocker status. If no object is returned, then the named comouter object does not have any BitLocker
    information stored in Active Directory.

    .PARAMETER ComputerName
    Name of computer object(s) to query for BitLocker information

    .PARAMETER Credential
    Optionj to provide alternative credentials when querying Active Directory

    .EXAMPLE
    Get-BitLockerInformation -ComputerName Server01 -Credential (Get-Credential)

    ComputerName     : Server01
    Date             : 9/6/2017 10:03:01 AM
    PasswordID       : 5A6ABC83-3D64-4760-BDAC-BCE2D768CF9C
    RecoveryPassword : 511325-009603-4423175-507353-289749-537053-004543-286789

    .NOTES
    '(?<={)(.*?)(?=})' - RegEx to get all text between a '{' and '}'

    .LINK
    https://social.technet.microsoft.com/Forums/lync/en-US/eea348c4-05ab-4b3c-a61f-1c23b77a691b/issues-with-getadcomputer-bitlocker-msfverecoverypassword?forum=winserverpowershell

    http://technet.microsoft.com/en-us/library/dd875529.aspx

    https://gist.github.com/morisy/5b99e763d6b72f9b3e7c1747b6d0a1ee

    .INPUTS
    [String[]]$ComputerName,

    [pscredential]$Credential

    .OUTPUTS
    Report.BitLocker
  #>


    [CmdletBinding()]
    Param (

        [Parameter( ValueFromPipeline = $True,
                    ValueFromPipelineByPropertyName = $True,
                    Mandatory = $True,
                    HelpMessage='Name of computer object to query in AD',
                    Position = 0)]
        [String[]]$ComputerName,

        [System.Management.Automation.Credential()][pscredential]$Credential

    )

    Begin {}

    Process {

        foreach ($computer in $ComputerName) {

            Try {

                $ADcomp = @{

                    'Identity' = $computer

                    'Credential' = $Credential

                    'ErrorAction' = 'Stop'

                }

                if ($PSBoundParameters.ContainsKey(('Credential'))) {

                    $ADComputer = Get-ADComputer @ADcomp

                    $ADObj = @{

                        'Filter' = {objectclass -eq 'msFVE-RecoveryInformation'}

                        'SearchBase' =  $ADComputer.DistinguishedName

                        'Properties' = '*'

                        'Credential' = $Credential

                        'ErrorAction' = 'Stop'

                    }

                    $BitLocker = Get-ADObject @ADObj

                } else {

                    $ADcomp.Remove('Credential')

                    $ADComputer = Get-ADComputer @ADcomp

                    $ADObj = @{

                        'Filter' = {objectclass -eq 'msFVE-RecoveryInformation'}

                        'SearchBase' =  $ADComputer.DistinguishedName

                        'Properties' = '*'

                        'ErrorAction' = 'Stop'

                    }

                    $BitLocker = Get-ADObject @ADObj

                }

                foreach ($BLObj in $BitLocker) {

                    $props = [Ordered]@{

                        'ComputerName' = $computer

                        'Date' = $BLObj.Created

                        'PasswordID' = [Regex]::Match($($BLObj.CN), '(?<={)(.*?)(?=})') | Select-Object -ExpandProperty 'Value'

                        'RecoveryPassword' = $BLObj | Select-Object -ExpandProperty 'msFVE-RecoveryPassword'

                    }

                    $Obj = New-Object -TypeName 'PSObject' -Property "$Props"
                    $Obj.PSObject.TypeNames.Insert(0,'Report.BitLocker')
                    Write-Output -InputObject $Obj

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
                Write-Output -InputObject $info

            }

        }

    }

    End {}

}