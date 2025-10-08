# 


#elect-analysis-index.R

####Declare your desired working directory
#setwd("~/Desktop")
setwd("~/Google Drive/Teaching/Elections/ENP Analysis and do file/")


####Declare the country you wish to use
#country <- c("Italy, Canada, etc")
country <- "Germany"


####Read in the dataset and select only observations for your country
data <- read.csv("GlobalElections_all_global_elections.csv")
data <- data[data$cnty == country,]

#Change NA values to zero(may not be necessary)
for (i in 7:ncol(data)){
	data[i][is.na(data[i])] <- 0
}

####Separate vote and seat variables
votes <- data[,grep("p*[0-9]v", names(data), value=TRUE)]
seats <- data[,grep("p*[0-9]s", names(data), value=TRUE)]

####Declare empty vectors with length corresponding to the number of districts
hh_votes <- numeric(nrow(votes))
hh_seats <- numeric(nrow(seats))

####Transform and sum the vote data over the parties, looping over the districts

#####VECTORIZE THIS#######

for (i in 1:nrow(data)){
		tmp <- ((votes[i,]/data["dtv"][i,])^2)
		tmp <- sum(tmp)
		hh_votes[i] <- tmp  
		tmp2 <- ((seats[i,]/data["dm"][i,])^2)
		tmp2 <- sum(tmp2)
		hh_seats[i] <- tmp2
		rm(tmp)
		rm(tmp2)
}


####Create dataset with only variables used for plotting
attach(data)
data2 <- data.frame(cnty, year, district, hh_votes, hh_seats)
detach(data)


###Get rid of zeroes
#row_sub <- apply(data2, 1, function(row) all(row !=0 ))
#data2 <- data2[row_sub,]

####Add inverse variables
data2$enp_votes <- 1/data2$hh_votes
data2$enp_seats <- 1/data2$hh_seats

####Remove non-inverted vars
#data2$hh_seats <- NULL
#data2$hh_votes <- NULL

####Check for and remove districts with undefined values for enp_votes or enp_seats
is.na(data2) <- sapply(data2, is.infinite)
data2 <- na.omit(data2)

####Write out our new dataset to the CWD
write.csv(data2, paste(country,"index_dat.csv", sep="_"), row.names=FALSE)


