# ACS Teams Phone Extensibility Resource Account Authorization Manager

A PowerShell script to manage authorization of Teams Phone Resource Accounts to interact with Azure Communication Services (ACS) resources.

## Overview

- This tool provides a simple way to authorize, check, and remove authorization for Teams Phone Resource Accounts to work with Azure Communication Services through signed HTTP requests using HMAC-SHA256 authentication.
- The script has been created to perform the operations described in section "Configure your Communication Services resource to accept calls for the Teams resource account" of the following page [Answer Teams Phone calls from Call Automation](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/tpe/teams-phone-extensibility-answer-teams-calls#configure-your-communication-services-resource-to-accept-calls-for-the-teams-resource-account).
- It implements the pseudocode described in the section "Access Key Authentication" on the page [Azure Communication Service Authentication](https://learn.microsoft.com/en-us/rest/api/communication/authentication).

## Features

- **Authorize Resource Accounts**: Grant a Teams Phone Resource Account permission to interact with an ACS resource (PUT request)
- **Check Authorization Status**: Verify if a Resource Account is authorized (GET request)
- **Remove Authorization**: Revoke a Resource Account's access to an ACS resource (DELETE request)

## Prerequisites

- PowerShell 5.1 or later
- Access to Azure Communication Services resource
- Teams Phone Resource Account Object ID
- Microsoft Entra Tenant ID

## Required Information

Before running the script, you'll need to gather the following information:

1. **ACS Endpoint**: The URL of your Azure Communication Services resource (without trailing slash)
   - Example: `https://your-acs-resource.europe.communication.azure.com`

2. **Access Key**: Your ACS resource's access key (Base64 encoded)
   - Found in Azure Portal → Your ACS Resource → Keys
   - Note: the access key you find on the page mentioned above is already in Base64 format, so it is sufficient to copy/paste it.

3. **Resource Account Object ID**: The Object ID of your Teams Phone Resource Account
   - Found in Microsoft Entra → Enterprise Applications → Your Resource Account

4. **Tenant ID**: Your Microsoft Entra Tenant ID (required only for PUT and DELETE operations)
   - Found in Azure Portal → Azure Active Directory → Overview

## Usage

### 1. Configure Variables

Import the module

```powershell
Import-Module ./ResourceAccountAuthorizationToACS.psm1
```

### 2. Choose Operation

#### Authorize a Resource Account (PUT)

```powershell
New-AcsResourceAccountAssignment -acsEndpoint <ACSEndPoint_Value> -accessKey <ACSAccessKey> -tenantID <TenantID> -resourceAccountObjectID <ResourceAccountObjectID>
```

Expected response: `201 Created` on success

#### Check Authorization Status (GET)

```powershell
Get-AcsResourceAccountAssignment -acsEndpoint <ACSEndPoint_Value> -accessKey <ACSAccessKey> -tenantID <TenantID> -resourceAccountObjectID <ResourceAccountObjectID>
```

Expected responses:
- `200 OK` - Resource Account is authorized
- `404 Not Found` - Resource Account is not authorized

#### Remove Authorization (DELETE)

```powershell
Remove-AcsResourceAccountAssignment -acsEndpoint <ACSEndPoint_Value> -accessKey <ACSAccessKey> -tenantID <TenantID> -resourceAccountObjectID <ResourceAccountObjectID>
```

Expected response: `204 No Content` on success

## Functions

### Sign-HttpRequest

Signs an HTTP request using HMAC-SHA256 according to ACS Endpoint specification.

**Parameters:**
- `Method` - HTTP method (GET, POST, PUT, DELETE)
- `Uri` - Complete URI of the request
- `AccessKey` - Access key in Base64 format
- `RequestBody` - Request body (optional)

**Returns:** Hashtable of signed headers

### Invoke-SignedHttpRequest

Executes a signed HTTP request to the ACS endpoint.

**Parameters:**
- `Method` - HTTP method
- `Uri` - Complete URI of the request
- `AccessKey` - Access key in Base64 format
- `RequestBody` - Request body (optional)

**Returns:** HTTP response object

## API Version

This script uses the ACS Teams Extension API version `2025-06-30`.

## Security Considerations

⚠️ **Important Security Notes:**

- Never commit your access keys to version control
- Store access keys securely (e.g., Azure Key Vault, environment variables)
- Rotate access keys regularly
- Use appropriate access controls for the script file

## Troubleshooting

### Common Issues

**401 Unauthorized**
- Verify your access key is correct
- Ensure the access key hasn't been regenerated in Azure Portal

**404 Not Found**
- Check that the Resource Account Object ID is correct
- Verify the Tenant ID matches your Microsoft Entra tenant

**400 Bad Request**
- Ensure the ACS endpoint URL is correct
- Verify the API version is supported

## Response Status Codes

| Code | Operation | Meaning |
|------|-----------|---------|
| 200 OK | GET | Resource Account is authorized |
| 201 Created | PUT | Authorization created successfully |
| 204 No Content | DELETE | Authorization removed successfully |
| 400 Bad Request | All | Invalid request format |
| 401 Unauthorized | All | Invalid or expired access key |
| 404 Not Found | GET | Resource Account not authorized |

## Example Workflow

1. **Initial Setup**: Configure variables with your ACS and Resource Account details
2. **Authorize**: Uncomment PUT section and run script
3. **Verify**: Uncomment GET section and run script to confirm authorization
4. **Remove (if needed)**: Uncomment DELETE section and run script


## Disclaimer

**USE AT YOUR OWN RISK**

This script is provided "AS IS" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability, fitness for a particular purpose, or non-infringement.

The author shall not be held liable for any damages, including but not limited to:
- Direct, indirect, incidental, special, consequential, or exemplary damages
- Loss of data, business interruption, or loss of profits
- Hardware or software failures or malfunctions
- Any other damages arising from the use or inability to use this script

By using this script, you acknowledge that:
- You are solely responsible for determining the appropriateness of using or redistributing the script
- You assume all risks associated with its use
- You will comply with all applicable laws and regulations
- You have adequate backups and security measures in place

**SECURITY NOTICE**: This script handles sensitive authentication credentials. Ensure you follow security best practices when storing and managing access keys.

## License

MIT License

Copyright (c) 2025 Davide Rasoli

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
