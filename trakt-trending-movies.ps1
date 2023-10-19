# Set variables
$jellyfinServerURL = "http://localhost:8096/"
$jellyfinAPIKey = "your-jf-api-key"
$libraryId = ""  # Replace with your library ID unless yoy want it to search on all your Movies libraries. I have an English Movie library and Spanish movie library so in my case I type there the one for which I want the collection to be created
$collectionName = "- Trending Movies"
$minRating = 2
$minYear = 2022

# Fetch the JSON from the URL
$jsonURL = "https://mdblist.com/lists/titooo7/top-10-trending-trakt/json/" # Created with mdblist, it picks the top 15 trending movies according to trakt.tv
$json = Invoke-RestMethod -Uri $jsonURL

# Extract movie titles from the JSON
$movieTitles = $json | ForEach-Object { $_.title }

# Create a hash table to track added movies
$addedMovies = @{}

# Loop through libraries and create collections
# Assume you have one library with ID $libraryId

# Get list of items in the specified library
$itemsURL = "$jellyfinServerURL/items?ParentId=$libraryId&IncludeItemTypes=Movie&ApiKey=$jellyfinAPIKey&Recursive=true" #if you arent entering any livrary id on line 4 then you might want to remove the ParentId=LibraryId part of this url. i didnt test if if would fail if not removed
$itemsResponse = Invoke-RestMethod -Uri $itemsURL -Method Get

# Loop through items and add unique movies to the collection
$items = $itemsResponse.Items | Where-Object {
    $movieTitle = $_.Name
    $movieYear = $_.PremiereDate.Year
    $movieRating = $_.CommunityRating

    # Check if the movie is in the list and hasn't been added to the collection
    if ($movieTitles -contains $movieTitle -and $movieYear -ge $minYear -and $movieRating -ge $minRating -and -not $addedMovies.ContainsKey($movieTitle)) {
        $addedMovies[$movieTitle] = $true  # Mark the movie as added
        $true  # Include the movie in the collection
    } else {
        $false  # Exclude the movie from the collection
    }
}

# Create collection
if ($addedMovies.Count -gt 0) {
    $itemIDs = ($items | Where-Object { $addedMovies.ContainsKey($_.Name) }).Id -join ","
    $collectionURL = "$jellyfinServerURL/Collections?Name=$collectionName&Ids=$itemIDs&ApiKey=$jellyfinAPIKey"

    # Print collectionURL for debugging
    Write-Host "Collection URL: $collectionURL"

    $collectionResponse = Invoke-RestMethod -Uri $collectionURL -Method Post
    Write-Host "Jellyfin Collection created with $($addedMovies.Count) unique movies."
} else {
    Write-Host "No matching movies found in the library."
}
