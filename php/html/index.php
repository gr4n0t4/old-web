<?php 
echo "Test from php\n";
$conn = mysql_connect();

if (!$conn) {
    die("Connection failed: " . $conn->connect_error);
} 
echo "Connected to MySQL successfully!";
mysql_close($conn);

?>