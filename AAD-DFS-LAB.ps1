$Dcpasswd = ConvertTo-SecureString -String 'Skills39' -AsPlainText -Force
$Dfspasswd = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
$username = "username"
$password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force

$credentials = New-Object System.Management.Automation.PSCredential($username, $password)

# Login to Tenant
Connect-AzureRmAccount -Verbose -Credential $credentials

# Creating the KeyVault
New-AzureRmKeyVault -VaultName "AAD-DFS-KV" `
        -Location 'East US' `
        -ResourceGroupName "AAD-LAB" `
        -EnabledForDiskEncryption `
        -Confirm `
        -Verbose


#Create Secrets for Key Vault
Set-AzureKeyVaultSecret -VaultName "AAD-DFS-KV" `
        -Name "DC-Admin-psswd" `
        -SecretValue $Dcpasswd `
        -ContentType 'txt' `
        -Confirm `
        -Verbose

Set-AzureKeyVaultSecret -VaultName "AAD-DFS-KV" `
        -Name "ADFS-Admin-psswd" `
        -SecretValue $Dfspasswd `
        -ContentType 'txt' `
        -Confirm `
        -Verbose

#Creating Networks and Subnets
New-AzureRmVirtualNetwork -ResourceGroupName AAD-LAB `
        -Location 'East US' `
        -Name AAD-LAB-NETWORK `
        -AddressPrefix 10.0.0.0/16

$vnet = Get-AzureRmVirtualNetwork `
        -ResourceGroupName AAD-LAB `
        -Name AAD-LAB-NETWORK

Add-AzureRmVirtualNetworkSubnetConfig -Name INTERNO-LAB-ADD `
        -AddressPrefix 10.0.0.0/24 `
        -VirtualNetwork $vnet

$subnet = Get-AzureRmVirtualNetworkSubnetConfig `
        -Name 'INTERNO-LAB-ADD' `
        -VirtualNetwork $vnet

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
$vnet
$subnet



#Create Public IP
$pip = New-AzureRmPublicIpAddress -Name AAD-LAB-PUBLIC-IP `
        -ResourceGroupName AAD-LAB `
        -Location 'East US' `
        -Sku Basic `
        -AllocationMethod Static `
        -DomainNameLabel cloudsecbox

#Creating a NetworkInterface
#===========DFS================#
$NCDFS = New-AzureRmNetworkInterface `
        -Name NIC-DFS-AAD-LAB `
        -ResourceGroupName AAD-LAB `
        -Location 'East US' `
        -SubnetId $vnet.Subnets[0].Id `
        -PublicIpAddressId $pip.Id

$nicDFS = Get-AzureRmNetworkInterface `
        -Name NIC-DFS-AAD-LAB `
        -ResourceGroupName AAD-LAB

$ipconfigDFS = New-AzureRmNetworkInterfaceIpConfig `
        -Name 'AAD-IP-CONFIG-LAB' `
        -Subnet $subnet `
        -PublicIpAddress $pip

$nicDFS | Add-AzureRmNetworkInterfaceIpConfig `
        -Name $ipconfigDFS `
        -Subnet $subnet `
        -PublicIpAddress $pip

Set-AzureRmNetworkInterface `
        -NetworkInterface $nicDFS

#==========DC=======#
$NCDC = New-AzureRmNetworkInterface -Name NIC-AAD-LAB `
        -ResourceGroupName AAD-LAB `
        -Location 'East US' `
        -SubnetId $vnet.Subnets[0].Id


$nicDC = Get-AzureRmNetworkInterface `
        -Name NIC-AAD-LAB `
        -ResourceGroupName AAD-LAB

$ipconfigDC = New-AzureRmNetworkInterfaceIpConfig `
        -Name 'AAD-IP-CONFIG-LAB' `
        -Subnet $subnet

$nicDC | Add-AzureRmNetworkInterfaceIpConfig `
        -Name $ipconfigDC `
        -Subnet $subnet

Set-AzureRmNetworkInterface `
        -NetworkInterface $nicDC