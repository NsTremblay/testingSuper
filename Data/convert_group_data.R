##########################################
## NAME: convert_group_data.R
##
## USAGE: Rscript convert_group_data.R
##
## DESCRIPTION:
##   Retrieves SNP and pangenome presence/absence data from
##   Superphy Postgres DB, converts to large data.frame and
##   saves it in Rbinary data format.
##
##  AUTHOR: Matthew Whiteside (matthew.whiteside@phac-aspc.gc.ca)
##
##  DATE: Sept 9, 2014
##
##########################################

## Globals ##
config_file = "../../config/genodo.cfg";

## Libraries ##
library(RPostgreSQL);



## Functions ##

# Open a connection to db
connectDb <- function(drv, configFile) {

	# Config
	if(!file.exists(configFile)) {
		stop(cat("Config file ", configFile, " not found. Verify in correct work directory (i.e. .../Data/).", sep=""));
	}
	cfg <- read.config(configFile);
	if(any(is.null(cfg$db$port), is.null(cfg$db$host), is.null(cfg$db$user), is.null(cfg$db$pass))) {
		stop(cat("Invalid config file ", configFile, ". Missing DB connection parameters.", sep=""));
	}

	# Connect
	con <- dbConnect(drv, dbname="genodo", host=cfg$db$host, port=cfg$db$port, user=cfg$db$user, password=cfg$db$pass);

	return(con);
}

# Parse a config file
read.config <- function(INI.filename) {

	connection <- file(INI.filename) 
	Lines  <- readLines(connection) 
	close(connection) 

	Lines <- chartr("[]", "==", Lines)  # change section headers 

	connection <- textConnection(Lines) 
	d <- read.table(connection, as.is = TRUE, sep = "=", fill = TRUE, strip.white=TRUE) 
	close(connection) 

	L <- d$V1 == ""                    # location of section breaks 
	d <- subset(transform(d, V3 = V2[which(L)[cumsum(L)]])[1:3], 
                           V1 != "") 

	ToParse  <- paste("INI.list$", d$V3, "$",  d$V1, " <- '", 
                    d$V2, "'", sep="") 

	INI.list <- list() 
	eval(parse(text=ToParse)) 

	return(INI.list)
}

## Main ##

# Connect to db
drv <- dbDriver("PostgreSQL");
con <- connectDb(drv, config_file);
stopifnot(!is.null(con));


# Disconnect to db
dbDisconnect(con)
dbUnloadDriver(drv)






