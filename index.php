<?php

function downloadImage($url, $num, $dir) {

	if (!is_dir("cache/" . $dir)) {
		mkdir("cache/" . $dir);
		echo "Created " . $dir . "/" . " ";
	}
	$fname = "cache/" . $dir . "/" . $num . ".jpg";

	if (!is_file($fname)) {

	$ch = curl_init($url);
	$fp = fopen("cache/" . $dir . "/" . $num . ".jpg", 'wb');
  echo $num . " ";

	curl_setopt($ch, CURLOPT_FILE, $fp);
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_exec($ch);
	curl_close($ch);
	
	fclose($fp);
  $cmd = "/usr/bin/mogrify -verbose -resize 960x960 /Users/ispiro/Code/tscope/cache/" . $dir . "/" . $num . ".jpg";
	 $out = shell_exec ( $cmd );
	}
}



$query = $_GET['query'];
$query = strtolower($query);
if ($query != null) {

//print($query);

$dir = str_replace(" ","_",$query);
$squery = str_replace(" ","+",$query);

$start = 0;
$count = 0;

$try = 0;
while(1) {

$url = "https://ajax.googleapis.com/ajax/services/search/images?" .
       "v=1.0&q=$squery&key=ABQIAAAAPlZEid6-O0NEIVcEBLsUjxTd3NmChiMRhJXoiUEBOAhuZa3gwhTDE_OilBnlXXoXq4V3GZ-8-9UOuQ&userip=is.cs.nyu.edu&start=$start&imgtype=photo&imgc=color";



//print $url;

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
		
		downloadImage($res[$i]->url, $count, $dir );
		$count++;
		
		//echo "Try " . $try . "<br>";
    $try++;
    if ($try > 100) break;
		
		if ($count >= 40) break;
}

if ($count >= 32) break;
if ($try > 40) break;

$start+=4;



}

}

?>


<html>
<head>
</head>

<script language=Javascript>

	function submit() {
	
		
		 document.getElementById("myForm").submit();
		 //window.location = "http://192.168.1.57/~ispiro?status=1";
		 }

</script>
<style TYPE="text/css">
       
       body {
       	    background: #CCCCCC;
	    		font-family: arial;
			}
			
			#submitDiv {

				   border: 1px solid red;
				   	    background: #EEEEFF;
					    		 cursor: pointer; 
							   border: 1px solid #EEEEEE; 
							    -moz-box-shadow: 5px 5px 5px #888;
							     -webkit-box-shadow: 5px 5px 5px #888;
							      box-shadow: 5px 5px 5px #888;
							       padding: 20px;
							        height: 120px;
								 margin-top: 50px;
								  	     font-size: 100px;
									     color: gray;
									     	    line-height: 110px;
										    		 overflow: hidden;
												 }
												 
												 #submitButton {
												  cursor: pointer; 
												   border: 1px solid #EEEEEE; 
												   -moz-box-shadow: 5px 5px 5px #888;
												   -webkit-box-shadow: 5px 5px 5px #888;
												   box-shadow: 5px 5px 5px #888;
												   padding: 0px;
												   background: white;
												   margin: 0px;
												   width: 99%
												   
												   }
												   
												   #formText {
												   	     position: relative;
													     	       width: 100%; 
														       	      height: 160px; 
															      	      font-size: 50px; 
																      		 text-align: center;
																		 }
																		 
																		 #status {
																		 	 height: 100px;
																			 	 font-size: 50px;
																				 }

																				 #status b {
																				 	 color: red;
																					 	font-weight: normal;
																						}
																						
																						#main {
																						      margin: 50px;
																						      }


</style>

<body style="padding: 0px; margin: 0px; border: none;">
<center>
<div id=main>
<div style="width: 100%; border: none; padding:-50px;">
<form action=index.php method=GET id=myForm>
<input type=text name=query id=formText autocorrect = "off">
<br>
<div id=submitDiv onClick="javascript:submit()">enqueue</div>
</form>
</div>
 
</div>

