$ModulePath = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$ModuleName = 'PSJwt'
$ManifestPath = "$ModulePath\$ModuleName.psd1"
if (Get-Module -Name $ModuleName) {
    Remove-Module $ModuleName -Force
}
Import-Module $ManifestPath -Verbose:$false


# test the module manifest - exports the right functions, processes the right formats, and is generally correct
Describe -Name 'Manifest' -Fixture {
    $ManifestHash = Invoke-Expression -Command (Get-Content $ManifestPath -Raw)

    It -name 'has a valid manifest' -test {
        {
            $null = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop -WarningAction SilentlyContinue
        } | Should Not Throw
    }

    It -name 'has a valid root module' -test {
        $ManifestHash.RootModule | Should Be "$ModuleName.psm1"
    }

    It -name 'has a valid Description' -test {
        $ManifestHash.Description | Should Not BeNullOrEmpty
    }

    It -name 'has a valid guid' -test {
        $ManifestHash.Guid | Should Be '6934ef7a-f360-4d10-8e61-471823ec44c1'
    }

    It -name 'has a valid version' -test {
        $ManifestHash.ModuleVersion -as [Version] | Should Not BeNullOrEmpty
    }

    It -name 'has a valid copyright' -test {
        $ManifestHash.CopyRight | Should Not BeNullOrEmpty
    }

    It -name 'has a valid license Uri' -test {
        $ManifestHash.PrivateData.Values.LicenseUri | Should Be 'http://opensource.org/licenses/MIT'
    }

    It -name 'has a valid project Uri' -test {
        $ManifestHash.PrivateData.Values.ProjectUri | Should Be 'https://github.com/stefanstranger/PSJwt'
    }

    It -name "gallery tags don't contain spaces" -test {
        foreach ($Tag in $ManifestHash.PrivateData.Values.tags) {
            $Tag -notmatch '\s' | Should Be $true
        }
    }
}


Describe -Name 'Module PSJwt works' -Fixture {
    It -name 'Passed Module load' -test {
        Get-Module -Name 'PSJwt' | Should Not Be $null
    }
}


Describe -Name 'Test Functions in PSJwt Module' -Fixture {
    Context -Name 'Testing Public Functions' -Fixture {

        It -name 'Passes ConvertFrom-JWT Function for Payload' -test {
            $Token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJGaXJzdE5hbWUiOiJTdGVmYW4iLCJMYXN0TmFtZSI6IlN0cmFuZ2VyIiwiRGVtbyI6IkVuY29kZSBBY2Nlc3MgVG9rZW4iLCJleHAiOjEzOTMyODY4OTMsImlhdCI6MTM5MzI2ODg5M30.8-YqAPPth3o-C_xO9WFjW5RViAnDe2WrmVyqLRnNEV0'
            (ConvertFrom-JWT -Token $Token).PayLoad.Demo | Should Be 'Encode Access Token'
        }

        It -name 'Passes ConvertFrom-JWT Function for extra Header' -test {
            $Token = 'eyJFbnYiOiJEZW1vIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJpYXQiOiIxMzkzMjY4ODkzIiwiRGVtbyI6IkVuY29kZSBBY2Nlc3MgVG9rZW4iLCJGaXJzdE5hbWUiOiJTdGVmYW4iLCJleHAiOiIxMzkzMjg2ODkzIiwiTGFzdE5hbWUiOiJTdHJhbmdlciJ9.JFJVUaBIUJmHQUawkK1dH5Iie8tSTTXKFbZZka3_k7Y'
            (ConvertFrom-JWT -Token $Token).Header.Env | Should Be 'Demo'
        }

        It -name 'Passes ConvertTo-JWT Function without extra header' -test {
            $Secret = 'qwerty'
            $Result = ( @{'FirstName' = 'Stefan'; 'LastName' = 'Stranger'; 'Demo' = 'Encode Access Token'; 'exp' = '1393286893'; 'iat' = '1393268893'} | ConvertTo-Jwt -secret $secret)  
            $Result.Length | Should Be 229
        }

        It -name 'Passes ConvertTo-JWT Function with extra header' -test {
            $Secret = 'qwerty'
            $Header = @{'Env' = 'Demo'}
            $Result = ( @{'FirstName' = 'Stefan'; 'LastName' = 'Stranger'; 'Demo' = 'Encode Access Token'; 'exp' = '1393286893'; 'iat' = '1393268893'} | ConvertTo-Jwt -Header $Header -secret $secret)  
            $Result.Length | Should Be 247
        }
    }
}