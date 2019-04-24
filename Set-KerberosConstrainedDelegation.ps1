Function Set-KerberosConstrainedDelegation {
  <#
    .SYNOPSIS
    Describe purpose of "Set-KerberosConstrainedDelegation" in 1-2 sentences.

    .DESCRIPTION
    Add a more complete description of what the function does.

    .PARAMETER ComputerName
    Describe parameter -ComputerName.

    .PARAMETER Delegate
    Describe parameter -Delegate.

    .PARAMETER Credential
    Describe parameter -Credential.

    .PARAMETER Action
    Describe parameter -Action.

    .EXAMPLE
    Set-KerberosConstrainedDelegation -ComputerName Value -Delegate Value -Credential Value -Action Value
    Describe what this call does

    .NOTES
    Place additional notes here.

    .LINK
    URLs to related sites
    The first link is opened by Get-Help -Online Set-KerberosConstrainedDelegation

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
  #>


    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [String]$ComputerName,

        [string]$Delegate,

        [pscredential]$Credential,

        [ValidateSet('Allow', 'Revoke')]
        [String]$Action

    )

    Begin {

        $Target = Get-ADComputer -Identity $ComputerName


    }

    Process {

        Try {

            Switch ($Action) {

                'Allow' {

                    $Member = Get-ADComputer -Identity $Delegate
                    $splat = @{

                        'Identity'                             = $Target
                        'PrincipalsAllowedToDelegateToAccount' = $Member
                        'Credential'                           = $Credential

                    }

                    Set-ADComputer @splat

                    $Splat = @{

                        'ComputerName' = $ComputerName
                        'ScriptBlock' = {& "$env:ProgramFiles(x86)\windows resource kits\tools\klist.exe" PURGE -LI 0x3e7}

                    }

                    Invoke-Command @Splat

                }

                'Revoke' {

                    $splat = @{

                        'Identity'                             = $Target
                        'PrincipalsAllowedToDelegateToAccount' = $null
                        'Credential'                           = $Credential

                    }

                    Set-ADComputer @splat

                }

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
            $info

        }


    }

    End {}

}