# Gets the DirectoryEntry object for a specified computer
function Get-ComputerDirectoryEntry {
    [CmdletBinding()]
    param(

        [String]$Name

    )

    Begin {}

    Process {

        # Create and initialize DirectorySearcher object that finds computers
        $ComputerSearcher = [ADSISearcher]''
        $ComputerSearcher.Filter = "(&(objectClass=computer)(name=$name))"
        try {

            $searchResult = $ComputerSearcher.FindOne()

            if ( $searchResult ) {

                $searchResult.GetDirectoryEntry()

            }

        } catch [Management.Automation.MethodInvocationException] {

            Write-Error -Exception $_.Exception.InnerException

        }

    }

    End {}

}


# Gets a property from a ResultPropertyCollection; specify $propertyName
# in lowercase to remain compatible with PowerShell v2
function Get-SearchResultProperty {
    [CmdletBinding()]
    param(

        [DirectoryServices.ResultPropertyCollection]$properties,

        [String]$propertyName

    )

    Begin {}

    Process {

        if ( $properties[$propertyName] ) {

            $properties[$propertyName][0]

        }

    }

    End {}

}


Function Get-BitLockerRecovery {
    <#
    .SYNOPSIS
        Get BitLocker recovery information for one or more Active Directory computer objects.

    .DESCRIPTION
        Get BitLocker recovery information for one or more Active Directory computer objects.

    .PARAMETER ComputerName
        Specifies one or more computer names. Wildcards are not supported.

    .PARAMETER Domain
        Get BitLocker recovery information from computer objects in the specified domain.

    .PARAMETER Server
        Specifies a domain server.

    .PARAMETER Credential
        Specifies credentials that have sufficient permission to read BitLocker recovery information.

    .OUTPUTS
        Custom Object with the following properties:

            DistinguishedName - The distinguished name of the computer
            ComputerName - The computer name
            Date - The Date/time the BitLocker recovery information was stored
            PasswordID - The ID for the recovery password
            RecoveryPassword - The recovery password

    .LINK
        http://technet.microsoft.com/en-us/library/dd875529.aspx

        https://gist.github.com/morisy/5b99e763d6b72f9b3e7c1747b6d0a1ee

    .NOTES
        Original code from - Bill Stewart (bstewart@iname.com)

        Modified by - Darrin Britton (Darrin.Britton@Outlook.com)

        The TPMRecoveryInformation, Date, PasswordID, and RecoveryPassword properties will be "N/A" if BitLocker recovery
        information exists but the current user does not have sufficient permission to read it. If you do not have sufficient
        permission to read BitLocker recovery information, you can either:

        1) use the -Credential parameter to specifyan account with sufficient permissions

        2) start your PowerShell session using an account with sufficient permissions.

        Rabbit hole I went down before switching over to using the native PowerShell AD Cmdlets
    #>
    [CmdletBinding()]
    param(

        [parameter( Position = 0,
                    HelpMessage='Name of computer(s) in Active Directory to query',
                    Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
            [String[]]$ComputerName,

            [String]$Domain,

            [String]$Server,

            [System.Management.Automation.Credential()][Management.Automation.PSCredential]$Credential
    )

    Begin {

        # Create and initialize DirectorySearcher for finding
        # msFVE-RecoveryInformation objects
        $RecoverySearcher = [ADSISearcher]''
        $RecoverySearcher.PageSize = 100
        $RecoverySearcher.PropertiesToLoad.AddRange(@('distinguishedName','msFVE-RecoveryGuid','msFVE-RecoveryPassword','name'))

    }

    Process {

        $RecoverySearcher.Filter = '(objectClass=msFVE-RecoveryInformation)'

        foreach ( $Name in $ComputerName ) {

            $domainName = $ComputerSearcher.SearchRoot.dc
            $computerDirEntry = Get-ComputerDirectoryEntry -name $name

            if ( -not $computerDirEntry ) {

                Write-Error -Message "Unable to find computer $name in domain $domainName" -Category ObjectNotFound
                return

            }

            $RecoverySearcher.SearchRoot = $computerDirEntry
            $searchResults = $RecoverySearcher.FindAll()

            foreach ( $searchResult in $searchResults ) {

                $properties = $searchResult.Properties
                $recoveryPassword = Get-SearchResultProperty -properties $properties -propertyName 'msfve-recoverypassword'

                if ( $recoveryPassword ) {

                    $recoveryDate = ([DateTimeOffset] ((Get-SearchResultProperty -properties $properties -propertyName 'name') -split '{')[0]).DateTime
                    $passwordID = ([Guid] [Byte[]] (Get-SearchResultProperty -properties $properties -propertyName 'msfve-recoveryguid')).Guid

                } else {

                    $recoveryDate = $passwordID = $recoveryPassword = 'N/A'

                }

                $props = [Ordered]@{

                    'DistinguishedName'      = $computerDirEntry.Properties['distinguishedname'][0]

                    'ComputerName'           = $computerDirEntry.Properties['name'][0]

                    'Date'                   = $recoveryDate

                    'PasswordID'             = $passwordID.ToUpper()

                    'RecoveryPassword'       = $recoveryPassword.ToUpper()

                }

                $obj = New-Object -TypeName psobject -Property $props
                $obj.PsObject.Typenames.insert(0,'Report.BitLockerRecovery')
                Write-Output -InputObject $obj

            }

            $searchResults.Dispose()

        }

    }

    End {}

}