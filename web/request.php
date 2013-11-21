<?php

function downloadImage($url, $num, $dir) {

	if (!is_dir("cache/" . $dir)) {
		mkdir("cache/" . $dir);
		echo "Created " . $dir . " " . $num;
	}
	$fname = "cache/" . $dir . "/" . $num . ".jpg";

	if (!is_file($fname)) {

	$ch = curl_init($url);
	$fp = fopen("cache/" . $dir . "/" . $num . ".jpg", 'wb');
	curl_setopt($ch, CURLOPT_FILE, $fp);
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_exec($ch);
	curl_close($ch);
	fclose($fp);
	
	}
}



$query = $_GET['query'];
$query = strtolower($query);
if ($query == null) return;

print($query);

$dir = str_replace(" ","_",$query);
$squery = str_replace(" ","+",$query);

$start = 0;
$count = 0;


while(1) {

$url = "https://ajax.googleapis.com/ajax/services/search/images?" .
       "v=1.0&q=$squery&key=ABQIAAAAPlZEid6-O0NEIVcEBLsUjxTd3NmChiMRhJXoiUEBOAhuZa3gwhTDE_OilBnlXXoXq4V3GZ-8-9UOuQ&userip=is.cs.nyu.edu&start=$start&imgtype=photo&imgc=color";



print $url;

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_REFERER, "http://is.cs.nyu.edu");
$body = curl_exec($ch);
curl_close($ch);

// now, process the JSON string
$json = json_decode($body);
// now have some fun with the results...

$res = $json->responseData->results;


for ($i = 0; $i < count($res); $i++) {
		
		print($res[$i]->url);
		downloadImage($res[$i]->url, $count, $dir );
		$count++;
		if ($count >= 32) break;
}

if ($count >= 32) break;
$start+=4;
}

?>