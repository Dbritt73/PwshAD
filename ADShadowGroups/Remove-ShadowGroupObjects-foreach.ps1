Function Remove-ADShadowGroupMember {
  <#
    .SYNOPSIS
    Remove AD objects from AD group is no longer a member of a specified organizational unit

    .DESCRIPTION
    Remove-ADShadowGroupMember uses existing AD Cmdlets to query an existing Organizational Unit and removes objects
    from a specified AD group based on membership of the specified Organizationl Unit

    .PARAMETER OrgUnit
    The Organizational Unit to query for group membership

    .PARAMETER GroupName
    The Active Directory group to remove objects not found in the Organizational Unit specified by the OrgUnit parameter

    .EXAMPLE
    Remove-ADShadowGroupMember -OrgUnit 'HumanResources' -GroupName 'grp.hr.work'
    Describe what this call does

    .NOTES
    Place additional notes here.

    .LINK
    https://ravingroo.com/458/active-directory-shadow-group-automatically-add-ou-users-membership/

    .INPUTS
    [String[]]OrgUnit
    [String]GroupName

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

            $Splat = @{

                'Identity'    = $GroupName
                'ErrorAction' = 'Stop'

            }

            if ($PSBoundParameters.ContainsKey('Credential')) {

                $splat.Add('Credential', $Credential)

            }

            $GroupMembership = Get-ADGroupMember @Splat | Where-Object {$_.distinguishedName -NotMatch $OrgUnit}

            if ($PSCmdlet.ShouldProcess($GroupName, 'Removing members')) {

                $splat = @{

                    'Identity'    = $GroupName
                    'members'     = $GroupMembership
                    'ErrorAction' = 'Stop'

                }

                if ($PSBoundParameters.ContainsKey('Credential')) {

                    $splat.Add('Credential', $Credential)

                }

                Remove-ADGroupMember @splat

                <#foreach ($Member in $GroupMembership) {

                    Remove-ADPrincipalGroupMembership -Identity $Member -MemberOf $GroupName -Confirm:$false

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