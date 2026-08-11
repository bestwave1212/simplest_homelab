CREATE USER IF NOT EXISTS 'sync_in'@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD('MySQLRootPassword');
GRANT ALL PRIVILEGES ON sync_in.* TO 'sync_in'@'%';
FLUSH PRIVILEGES;
