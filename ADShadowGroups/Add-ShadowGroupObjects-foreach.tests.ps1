Describe Add-ADShadowGroupMember {

    Context 'Error Handling' {

        Mock Add-ADGroupMember {Throw}

        Mock Get-ADObject {Throw}

        It "Should throw if we're unable to modify group membership" {

            {Add-ADShadowGroupMember -GroupName 'test' -OrgUnit 'testorg'} | Should -Throw

        }

    }

    Context 'Parameters are being passed to helper functions' {

        Mock Add-ADGroupMember {

            Param ()
            $Script:Credential = $Credential
            $Global:Searchbase = $orgunit

        } -Verifiable

        Mock Get-ADObject {

            Param ($SearchBase)
            $Script:Credential = $Credential
            $Global:Searchbase = $orgunit

        } -Verifiable

        It 'When -Credential is provided, Credentials should be passed to both Add-ADGroupMember and Get-ADObject' {

            $PW = ConvertTo-SecureString 'Password' -AsPlainText -Force
            $Cred = New-Object System.Management.Automation.PSCredential('SomeUser', $PW)
            Add-ADShadowGroupMember -orgunit 'OU=Test,DC=Com' -Groupname 'testgroup' -Credential $cred
            $Credential | Should -Not be $Null

        }

    }

}