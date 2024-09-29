# Copyright: (c) 2024, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Test-Tls {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $HostName,

        [Parameter()]
        [int]
        $Port = 443,

        [Parameter()]
        [System.Security.Authentication.SslProtocols]
        $TlsVersion = 'None',
        
        [Parameter()]
        [string]
        $SNIName
    )

    $tcp = [System.Net.Sockets.TcpClient]::new()
    $ssl = $null
    try {
        $tcp.Connect($HostName, $port)
        $validationState = @{}
        $ssl = [System.Net.Security.SslStream]::new($tcp.GetStream(), $false, {
            param($SslSender, $Certificate, $Chain, $SslPolicyErrors)

            $validationState.PolicyErrors = $SslPolicyErrors

            $true
        })
        
        $sslHost = $HostName
        if ($SNIName) {
            $sslHost = $SNIName
        }
        $ssl.AuthenticateAsClient($sslHost, $null, $TlsVersion, $true)

        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)

        [PSCustomObject]@{
            SslProtocol = $ssl.SslProtocol
            NegotiatedCipherSuite = $ssl.NegotiatedCipherSuite  # Only works with pwsh 7+
            Certificate = $cert
            ValidationErrors = $validationState.PolicyErrors
        }
    }
    finally {
        if ($ssl) { $ssl.Dispose() }
        $tcp.Dispose()
    }
}