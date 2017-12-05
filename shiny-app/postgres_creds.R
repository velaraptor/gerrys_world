##database
library(RPostgreSQL)
library(DBI)

drv = dbDriver("PostgreSQL")
connection_creds = function(){dbConnect(
					drv,
					port="5432",
					host="safeatxx.cnj4vinpaowc.us-west-2.rds.amazonaws.com",
					user="superuser",
					dbname="christophvel",
					password="Tygafe4*"
				)}