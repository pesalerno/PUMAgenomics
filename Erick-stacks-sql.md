### Getting mysql installed properly 
	sudo port install mysql5-server         ### you need MAcPorts installed for this https://www.macports.org

	sudo -u _mysql /opt/local/bin/mysql_install_db5
Start MySQL:

	sudo port load mysql5-server
Stop MySQL:

	sudo port unload mysql5-server
	
###to call mysql typ: 

	mysql5

#### Locally installing Stacks
If you need to install wget and already have home-brew, use command: 

	brew install wget
	wget -qO- https://get.haskellstack.org/ | sh   ### Or just click on the download button on website since you have GUI (easier so you know where the folder ends up -> can place it where you want and know path later)

###Then to setup you need homebrew 
	cd /bin
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew doctor  ## to check it 
	cd /to_where/you_have_stacks
	brew install haskell-stack
	./configure --prefix /Desktop/Genetic_programs/stacks-1.42 ###customize location

now type: 
	
	make 
	sudo make install 

Ok so now lets try to get the denovo_map output files into mysql 
Get the denovo .tsvoutput files from mt. moran to your local drive

	scp [username]@mtmoran.uwyo.edu:/path/to/denovo/output/folder/*.tsv /Path/to/	local/directory/where/you/want/files/to/go



#### Create a database in mysql
Helpful tutorial: https://www.ntu.edu.sg/home/ehchua/programming/sql/MySQL_HowTo.html#zz-3.5
In command line:

	mysql5 -u root #opens mysql

In mysql
NOTE: Could use root, but better to create user (root not meant for regular operations - could mess things up)
create user ‘username’@‘localhost’ identified by ‘newpassword’;
grant all on *.* to ‘username’@‘localhost’; #gives permission to user to access/edit/create all databases
quit; #quits sql to go back to command line (also can use exit)

In command line:

	mysql5 -u [username] -p #login to mysql using new username and password ##exclude [] in username


NOTE: must use this command every time you log into mysql 

In mysql> 
create database [database_name]; #Example: PH1_DenovoOut

####After creating database, populate database with tables that stacks will spit out


Go to folder where stacks.sql is (probably something/stacks-1.42/sql/
From within this folder, login in sql

	mysql5 -u [username] -p

In sql>

	use [database name];
	source stacks.sql;
	show tables; #to check that it worked

####Prep .cnf file for stacks to communicate with mysql
in terminal, go to:

	whatever/stacks-1.42/share/stacks/sql
	
open mysql.cnf.dist file in nano

	nano mysql.cnf.dist

copy code, close nano (no changes)
create mysql.cnf file in nano, using sudo to have permission (have to enter computer password)

	sudo nano mysql.cnf

paste code from .dist file, change username and password to match what you created earlier when you were setting up a user in sql
>sometime ch mod #lets you change permissions on file 


####When everything else is done, run load_radtags.pl in terminal

	/path/to/stacks-1.42/scripts/load_radtags.pl -D [database name] -p /path/to/denovo/output/folder/ -b 2 -c
-b = batch ID (I just used whatever batch ID I used for denovo map
-c = indicates to load the catalog into the database (don’t know whether to do this, so just included it)


####TROUBLESHOOTING if load_radtags.pl doesn’t work

	ERROR 1146: Table doesn’t exist
This means that either you did not import stacks.sql tables into your database, or something went wrong

	ERROR 2002 (HY000): Can't connect to local MySQL server through socket
There is something wrong with the path to your .sock file

	sudo find / -name ‘*.sock’ #to find mysqld.sock file

Found that mysql was looking for a folder mysql56/mysqld.sock, when my .sock file was actually in mysql5/mysqld.sock - solved this by creating a permanent link from the 5 folder to the 56 folder to make sql happy (not the cleanest fix, but it does the trick)

	ln -s /opt/local/var/run/mysql5/mysqld.sock /opt/local/var/run/mysql56/mysqld.sock

	Could not open required defaults file: /path/to/stacks-1.42/share/stacks/sql/mysql.cnf
This means that you did not create the .cnf file as instructed above, or something went wrong there
