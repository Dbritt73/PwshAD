Function Remove-ADShadowGroupMembership {
  <#
    .SYNOPSIS
    Describe purpose of "Resolve-ShadowGroup" in 1-2 sentences.

    .DESCRIPTION
    Add a more complete description of what the function does.

    .PARAMETER OU
    Describe parameter -OU.

    .PARAMETER ShadowGroup
    Describe parameter -ShadowGroup.

    .EXAMPLE
    Resolve-ShadowGroup -OU Value -ShadowGroup Value
    Describe what this call does

    .NOTES
    Place additional notes here.

    .LINK
    URLs to related sites
    The first link is opened by Get-Help -Online Resolve-ShadowGroup
    https://ravingroo.com/458/active-directory-shadow-group-automatically-add-ou-users-membership/

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
  #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user')]
        [String]$OU,

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user')]
        [String]$ShadowGroup

    )

    Begin {}

    Process {

        Try {

            $Splat = @{

                'Identity'    = $ShadowGroup
                'ErrorAction' = 'Stop'

            }

            $GroupMembership = Get-ADGroupMember @Splat | Where-Object {$_.distinguishedName -NotMatch $OU}

            foreach ($Member in $GroupMembership) {

                Remove-ADPrincipalGroupMembership -Identity $Member -MemberOf $ShadowGroup -Confirm:$false

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