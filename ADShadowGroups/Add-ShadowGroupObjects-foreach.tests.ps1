Describe Add-ADShadowGroupMember {

    Context 'Error Handling' {

        It "Should error if we're unable to modify group membership" {

            {Add-ADShadowGroupMember -GroupName 'test' -SearchBase 'testorg'} | Should -BeOfType [PSCustomObject]

        }

    }

    Context 'Parameters are being passed to helper functions' {

        Mock Add-ADGroupMember {

            Param (

                $SearchBase,

                $GroupName

            )
            $Global:Credential = $Credential
            $script:Searchbase = $SearchBase
            $script:GroupName = $GroupName

        } -Verifiable

        Mock Get-ADObject {

            Param (

                $SearchBase,

                $GroupName

            )
            $Global:Credential = $Credential
            $script:Searchbase = $SearchBase
            $script:GroupName = $GroupName

        } -Verifiable

        It 'When -Credential is provided, Credentials should be passed to both Add-ADGroupMember and Get-ADObject' {

            $PW = ConvertTo-SecureString 'Password' -AsPlainText -Force
            $Cred = New-Object System.Management.Automation.PSCredential('SomeUser', $PW)
            Add-ADShadowGroupMember -SearchBase 'OU=Test,DC=Com' -Groupname 'testgroup' -Credential $cred
            $Credential | Should -Not -Be $null

        }

    }

}