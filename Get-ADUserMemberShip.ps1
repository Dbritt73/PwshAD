Function Get-ADUserMemberShip {
  <#
    .SYNOPSIS
    Get all AD security groups the specified user is a member of.

    .DESCRIPTION
    Get-ADUserMembership utilizes Get-ADUser and Get-ADgroup with a LDAP filter to produce all the groups the user is a
    member of, including nested groups.

    .PARAMETER UserName
    User name of a user in actrive Directroy to query

    .EXAMPLE
    Get-ADUserMemberShip -UserName 'User1'

    Produces a collection of objects representing the groups 'User1' is a member of

    .NOTES
    1.2.840.113556.1.4.1941

    LDAP_MATCHING_RULE_IN_CHAIN

    This rule is limited to filters that apply to the DN. This is a special "extended" match operator that walks the
    chain of ancestry in objects all the way to the root until it finds a match.

    .LINK
    URLs to related sites
    http://powershell-guru.com/powershell-tip-72-list-the-nested-groups-of-a-user-in-active-directory/
    https://docs.microsoft.com/en-us/windows/desktop/adsi/search-filter-syntax

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
  #>


    [CmdletBinding()]
    Param (

        [Parameter( ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $True,
                    Mandatory = $True,
                    HelpMessage = 'Username to look up group membership for',
                    Position = 0)]
        [string[]]$UserName

    )

    Begin {}

    Process {

        foreach ($Id in $UserName) {

            Try {

                $DN = (Get-ADUser -Identity $Id -Properties DistinguishedName -ErrorAction 'Stop').DistinguishedName
                Get-ADGroup -LDAPFilter "(member:1.2.840.113556.1.4.1941:=$($DN))" -ErrorAction 'Stop'

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