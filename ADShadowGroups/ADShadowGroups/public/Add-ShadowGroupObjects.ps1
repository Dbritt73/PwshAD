Function Add-ADShadowGroupMember {
  <#
    .SYNOPSIS
    Add members to AD group based off Organizational Unit

    .DESCRIPTION
    Add-ADShadowGroupMember uses existing AD Cmdlets to query an existing Organizational Unit and adds objects in that
    unit to the specified AD Group

    .PARAMETER OrgUnit
    The Organizational Unit to query for group membership

    .PARAMETER ShadowGroup
    The Active Directory group to add objects found in the Organizational Unit specified by the OrgUnit parameter

    .EXAMPLE
    Resolve-ShadowGroup -OrgUnit 'HumanResources' -ShadowGroup 'grp.hr.work'

    Queries the HumanResources OU and adds all objects (users,computers, other groups, etc.) to the AD group grp.hr.wrk

    .NOTES
    Place additional notes here.

    .LINK
    https://ravingroo.com/458/active-directory-shadow-group-automatically-add-ou-users-membership/

    .INPUTS
    [String]OrgUnit
    [String]ShadowGroup
    [pscredential]Credential

    .OUTPUTS
    List of output types produced by this function.
  #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user')]
        [String]$OrgUnit,

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user')]
        [String]$ShadowGroup,

        [Parameter()]
        [pscredential]$Credential

    )

    Begin {}

    Process {

        Try {

            $splat = @{

                'SearchBase'  = $OrgUnit
                'SearchScope' = 'OneLevel'
                'LDAPFilter'  = "(!memberOf=$ShadowGroup)"
                'ErrorAction' = 'Stop'

            }

            if ($PSBoundParameters.Contains('Credential')) {

                $splat.Add('Credential', $Credential)

            }

            Get-ADObject @splat | ForEach-Object {

                Add-ADGroupMember -Identity $ShadowGroup -Members $_ -Credential $Credential

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