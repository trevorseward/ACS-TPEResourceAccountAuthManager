# This script helps you authorizing Teams Phone Resource Accounts to interact with an Azure Communication service resource.
# You can:
## Authorize the specified Teams Phone Resource Account (PUT request) to interact with the specified Azure Communication Service resource.
## Check if the specified Teams Phone Resource Account is authorzied to interact with the specified Azure Communication Service resource.
## Remove the specified Teams Phone Resource Account authorization to interact with the specified Azure Communication Services resource.

param(
    [Parameter(Mandatory)]
    [string]$acsEndpoint,

    [Parameter(Mandatory)]
    [string]$accessKey,

    [Parameter(Mandatory)]
    [string]$resourceAccountObjectID,

    [Parameter(Mandatory)]
    [string]$tenantID
)

function Sign-HttpRequest {
    <#
    .SYNOPSIS
        Signs an HTTP request using HMAC-SHA256 according to ACS Endpoint specification
    
    .PARAMETER Method
        The HTTP method (GET, POST, PUT, DELETE, etc.)
    
    .PARAMETER Uri
        The complete URI of the request
    
    .PARAMETER AccessKey
        The access key in Base64 format
    
    .PARAMETER RequestBody
        The request body (optional, default empty string)
    
    .EXAMPLE
        $headers = Sign-HttpRequest -Method "GET" -Uri "Complete URI of the request" -AccessKey "Base64 encoded ACS's access key"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$true)]
        [string]$AccessKey,
        
        [Parameter(Mandatory=$false)]
        [string]$RequestBody = ""
    )
    
    # Parse the URI
    $parsedUri = [System.Uri]$Uri
    
    # 1. HTTP request method
    $Verb = $Method.ToUpper()
    
    # 2. UTC timestamp in RFC1123 format
    $Timestamp = [DateTime]::UtcNow.ToString("r")
    
    # 3. HTTP request host (authority component)
    $DestUri = $parsedUri.Authority
    
    # 4. SHA256 hash of the request body
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($RequestBody)
    $hashBytes = $sha256.ComputeHash($bodyBytes)
    $ContentHash = [Convert]::ToBase64String($hashBytes)
    
    # 5. URI path and query
    $URIPathAndQuery = $parsedUri.PathAndQuery
    
    # Build the string to sign
    $StringToSign = $Verb + "`n" + 
                    $URIPathAndQuery + "`n" + 
                    $Timestamp + ";" + $DestUri + ";" + $ContentHash
    
    Write-Verbose "String to sign: $StringToSign"
    
    # Decode the access key from Base64
    $decodedKey = [Convert]::FromBase64String($AccessKey)
    
    # Generate the HMAC-SHA256 signature
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = $decodedKey
    $stringBytes = [System.Text.Encoding]::UTF8.GetBytes($StringToSign)
    $signatureBytes = $hmac.ComputeHash($stringBytes)
    $Signature = [Convert]::ToBase64String($signatureBytes)
    
    Write-Verbose "Signature: $Signature"
    
    # Create the required headers
    $headers = @{
        "x-ms-date" = $Timestamp
        "x-ms-content-sha256" = $ContentHash
        "host" = $DestUri
        "Authorization" = "HMAC-SHA256 SignedHeaders=x-ms-date;host;x-ms-content-sha256&Signature=$Signature"
    }
    
    return $headers
}

function Invoke-SignedHttpRequest {
    <#
    .SYNOPSIS
        Executes a signed HTTP request
    
    .PARAMETER Method
        The HTTP method (GET, POST, PUT, DELETE, etc.)
    
    .PARAMETER Uri
        The complete URI of the request
    
    .PARAMETER AccessKey
        The access key in Base64 format
    
    .PARAMETER RequestBody
        The request body (optional, default empty string)
    
    .EXAMPLE
        $response = Invoke-SignedHttpRequest -Method "GET" -Uri "Complete URI of the request" -AccessKey "Base64 encoded ACS's access key"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$true)]
        [string]$AccessKey,
        
        [Parameter(Mandatory=$false)]
        [string]$RequestBody = ""
    )
    
    # Generate the signed headers
    $headers = Sign-HttpRequest -Method $Method -Uri $Uri -AccessKey $AccessKey -RequestBody $RequestBody -Verbose

    
    # Execute the HTTP request
    try {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = $headers
        }
        

        if ($RequestBody -ne "") {
            $params.Body = $RequestBody
            $params.ContentType = "application/json"
        }

        ConvertTo-Json $params | Write-Host
        
        $response = Invoke-WebRequest @params
        return $response
    }
    catch {
        Write-Error "Error during HTTP request: $_"
        throw
    }
}

### PUT SECTION ###

function New-AcsResourceAccountAssignment {
    param($acsEndpoint, $accessKey, $resourceAccountObjectID, $tenantID)

    try {
        $putUri = "${acsEndpoint}/access/teamsExtension/tenants/${tenantID}/assignments/${resourceAccountObjectID}?api-version=2025-06-30"
        $body = '{"principalType" : "teamsResourceAccount"}'
        $response = Invoke-SignedHttpRequest -Method "PUT" -Uri $putUri -AccessKey $accessKey -RequestBody $body

    # Check HTTP Status code
    if ($response.StatusCode -eq 201) {
        Write-Host "`nResource Account successfully authorized (201 Created)" -ForegroundColor Green
        Write-Host "Response Body: $($response.Content)"
        }
    else {
        Write-Host "`nWarning: received unexptected Status Code: $($response.StatusCode)" -ForegroundColor Yellow
        Write-Host "Response Body: $($response.Content)"
        }
    }
    catch {
        Write-Host "`nError while authorizing the Resource Account" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

### DELETE SECTION ###

function Remove-AcsResourceAccountAssignment {
    param($acsEndpoint, $accessKey, $resourceAccountObjectID, $tenantID)

    try {
        $deleteUri = "${acsEndpoint}/access/teamsExtension/tenants/${tenantID}/assignments/${resourceAccountObjectID}?api-version=2025-06-30"
        $response = Invoke-SignedHttpRequest -Method "DELETE" -Uri $deleteUri -AccessKey $accessKey

        # Check HTTP Status code
        if ($response.StatusCode -eq 204) {
            Write-Host "`nResource Account's authorization removed successfully (204 No Content)" -ForegroundColor Green
        }
        else {
            Write-Host "`nWarning: Received Status Code: $($response.StatusCode)" -ForegroundColor Yellow
            Write-Host "Response Body: $($response.Content)"
            }
        }
        catch {
            Write-Host "`nError while removing Resource Account's authorization" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
}

### GET SECTION ###

function Get-AcsResourceAccountAssignment{
    param($acsEndpoint, $accessKey, $resourceAccountObjectID, $tenantID)

    try {
    $getUri = "${acsEndpoint}/access/teamsExtension/tenants/${tenantID}/assignments/${resourceAccountObjectID}?api-version=2025-06-30"
    $response = Invoke-SignedHttpRequest -Method "GET" -Uri $getUri -AccessKey $accessKey

    # Check HTTP Status code
    if ($response.StatusCode -eq 200) {
        Write-Host "`nResource account correctly authorized (200 OK)" -ForegroundColor Green
        Write-Host "Response Body: $($response.Content)"
    }
    else {
        Write-Host "`nWarning: Received unexpected Status Code: $($response.StatusCode)" -ForegroundColor Yellow
        Write-Host "Response Body: $($response.Content)"
        }
    }
    catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "`nResource account not found in the authorization list (404 Not Found)" -ForegroundColor Yellow
        Write-Host "Response Body: $($_.Exception.Response | ConvertTo-Json)"
    }
        Write-Host "`nError while checking Resource Account's authorization" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
