# Set variables
$jellyfinServerURL = "https://mydomain.tld/jellyfin"
$jellyfinAPIKey = "my-jellyfin-api-key"
$libraryId = ""  # Replace with your library ID
$collectionName = "- Top movies of the week"
$minRating = 2
$minYear = 2022

# Fetch the JSON from the URL
$jsonURL = "https://mdblist.com/lists/titooo7/top-10-pirated-of-the-week"
$json = Invoke-RestMethod -Uri $jsonURL

# Extract movie titles from the JSON
$movieTitles = $json | ForEach-Object { $_.title }

# Loop through libraries and create collections
# Assume you have one library with ID $libraryId
# You can modify the loop for multiple libraries if needed
Write-Host "Creating collection: $($collectionName)"

# Get list of items in library
$itemsURL = "$jellyfinServerURL/items?ParentId=$libraryId&IncludeItemTypes=Movie&api_key=$jellyfinAPIKey&Recursive=true"
$itemsResponse = Invoke-RestMethod -Uri $itemsURL -Method Get
$items = $itemsResponse.Items | Where-Object { $movieTitles -contains $_.Name -and $_.PremiereDate.Year -ge $minYear -and $_.CommunityRating -ge $minRating }

# Create collection
if ($items.Count -gt 0) {
    $itemIDs = $items.Id -join ","
    $collectionURL = "$jellyfinServerURL/Collections?Name=$collectionName&Ids=$itemIDs&api_key=$jellyfinAPIKey"
    $collectionResponse = Invoke-RestMethod -Uri $collectionURL -Method Post
    Write-Host "Collection created with $($items.Count) movies."
} else {
    Write-Host "No matching movies found in the library."
}
