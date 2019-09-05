Function Add-ADShadowGroupMember {
  <#
    .SYNOPSIS
    Add members to AD group based off Organizational Unit

    .DESCRIPTION
    Add-ADShadowGroupMember uses existing AD Cmdlets to query an existing Organizational Unit and adds objects in that
    unit to the specified AD Group

    .PARAMETER OrgUnit
    The Organizational Unit to query for group membership

    .PARAMETER GroupName
    The Active Directory group to add objects found in the Organizational Unit specified by the OrgUnit parameter

    .EXAMPLE
    Add-ADShadowGroupMember -OrgUnit 'HumanResources' -GroupName 'grp.hr.work'

    Queries the HumanResources OU and adds all objects (users,computers, other groups, etc.) to the AD group grp.hr.wrk

    .NOTES
    Original use case for software management through AD groups and SCCM

    .LINK
    https://ravingroo.com/458/active-directory-shadow-group-automatically-add-ou-users-membership/

    .INPUTS
    [String[]]OrgUnit
    [String]ShadowGroup
    [pscredential]Credential

    .OUTPUTS
    List of output types produced by this function.
  #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user')]
        [String[]]$OrgUnit,

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Add help message for user')]
        [String]$GroupName,

        [Parameter()]
        [System.Management.Automation.Credential()][pscredential]$Credential

    )

    Begin {}

    Process {

        Try {

            $splat = @{

                'SearchBase'  = $OrgUnit
                'SearchScope' = 'OneLevel'
                'LDAPFilter'  = "(!memberOf=$GroupName)"
                'ErrorAction' = 'Stop'

            }

            if ($PSBoundParameters.ContainsKey('Credential')) {

                $splat.Add('Credential', $Credential)

            }

            if ($PSCmdlet.ShouldProcess($GroupName, 'Adding members')) {

                $OrgMembership = Get-ADObject @splat

                Write-Verbose -Message "$orgmembership"

                $splat = @{

                    'Identity'    = $GroupName
                    'members'     = $OrgMembership
                    'ErrorAction' = 'Stop'

                }

                if ($PSBoundParameters.ContainsKey('Credential')) {

                    $splat.Add('Credential', $Credential)

                }

                Add-ADGroupMember @splat

                <#foreach ($Member in $OrgMembership) {

                    Add-ADGroupMember -Identity $GroupName -Members $Member

                }#>

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