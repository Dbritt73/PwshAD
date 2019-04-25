Function Set-KerberosConstrainedDelegation {
  <#
    .SYNOPSIS
    Add delegate computer account to another active directory computer object

    .DESCRIPTION
    Set-KerberosConstrainedDelegation can add or remove delegate entries in the msDS-AllowedToActOnBehalfOfOtherIdentity
    property of an Active Directory computer. Intended as part of a solution to double hop issue when PSRemoting.

    .PARAMETER ComputerName
    Name of computer to add the delegate entry to

    .PARAMETER Delegate
    Name of principal object to add as a delegate

    .PARAMETER Credential
    Valid username and password for Active Directory

    .PARAMETER Allow
    When called in conjunction with the Delegate parameter, adds specified computer as a delegate to the target

    .PARAMETER Revoke
    Remove all delegate entries on specified AD object

    .EXAMPLE
    Set-KerberosConstrainedDelegation -ComputerName SERVER01 -Delegate SERVER02 -Credential $Cred -Allow

    Example showing SERVER02 being granted delegate access to SERVER01

    .EXAMPLE
    Set-KerberosConstrainedDelegation -ComputerName SERVER01 -Credential $Cred -Revoke

    Example showing removal of all delegate permitted entries for SERVER01

    .NOTES
    Written to help with double hop issue when PSRemoting

    .LINK
    URLs to related sites
    https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/

    .INPUTS
    [String]ComputerName
    [string]Delegate
    [pscredential]Credential
    [String]Action

    .OUTPUTS
    none
  #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    Param (

        [Parameter( Mandatory = $true,
                    HelpMessage='Computer to add or remove delegation')]
        [String]$ComputerName,

        [Parameter(ParameterSetName = 'Allow')]
        [String]$Delegate,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'Allow')]
        [Switch]$Allow,

        [Parameter(ParameterSetName = 'Revoke')]
        [Switch]$Revoke

    )

    Begin {}

    Process {

        Try {

            $Target = Get-ADComputer -Identity $ComputerName -ErrorAction 'Stop'

            if ($Allow) {

                $Member = Get-ADComputer -Identity $Delegate -ErrorAction 'Stop'

                $splat = @{

                    'Identity'                             = $Target
                    'PrincipalsAllowedToDelegateToAccount' = $Member
                    'Credential'                           = $Credential
                    'ErrorAction'                          = 'Stop'

                }

                Set-ADComputer @splat

                #KLIST to purge existing Kerberos tickets cached on target computer
                $Splat = @{

                    'ComputerName' = $ComputerName
                    'ScriptBlock'  = {

                        if (Test-Path -Path "$env:ProgramFiles(x86)\windows resource kits\tools\klist.exe") {

                            $Splat = @{

                                'FilePath'     = "$env:windir\System32\klist.exe"
                                'ArgumentList' = @('PURGE', '-LI', '0x3e7')
                                'Wait'         = $true
                                'NoNewWindow'  = $true

                            }

                            Start-Process @Splat

                        }

                    }
                    'ErrorAction'  = 'Stop'

                }

                Invoke-Command @Splat

            }

            if ($Revoke) {

                $splat = @{

                    'Identity'                             = $Target
                    'PrincipalsAllowedToDelegateToAccount' = $null
                    'Credential'                           = $Credential
                    'ErrorAction'                          = 'Stop'

                }

                Set-ADComputer @splat

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

    End {}

}