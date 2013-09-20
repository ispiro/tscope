<?php

function timesort($a, $b) {
	return $a[1] < $b[1];
}


function getDirectoryList ($directory) 
  {

    // create an array to hold directory list
    $results = array();

    // create a handler for the directory
    $handler = opendir($directory);

    // open directory and walk through the filenames
    while ($file = readdir($handler)) {

      // if file isn't this directory or its parent, add it to the results
     if(substr($file,0,1) != ".") {
     
      	if (substr($file,0,1) != ".") {
      	
      	
      	 $testfile = "cache/" . $file . "/" . "31.jpg";
      	 if (file_exists($testfile)) {
      	 
          	$results[] = array($file, filemtime("cache/" . $file));
          }
      	}
      }
    }

    // tidy up: close the handler
    closedir($handler);

    // done!
    return $results;

  }


	$l = getDirectoryList("cache");
	
	usort($l, timesort);
	for ($i = 0; $i < count($l); $i++) {
		print $l[$i][0] . "\n";
	}
?>