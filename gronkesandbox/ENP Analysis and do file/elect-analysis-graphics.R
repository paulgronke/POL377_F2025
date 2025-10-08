#elect-analysis-graphics.R

#setwd("~/Desktop")
setwd("~/Google Drive/Teaching/Elections/ENP Analysis and do file/")
# data2 <- read.csv("index_dat.csv")

attach(data2)

#Graphs write out to CWD

#Total Graph
jpeg(paste(country, "_ENP-votes_ENP_seats.jpg", sep = ""))
title <- paste(country, "ENP Votes against ENP Seats")
plot(enp_votes, enp_seats, main = title)
#Add best-fit line
abline(lm(enp_seats~enp_votes), col='blue', lwd=1)
#Add line with slope 1
abline(0,1, col='red', lwd=1)
dev.off()

#Loop through the yars we have data for, creating a separate plot for each
year_list <- unique(year)

for (i in 1:length(year_list)) {
	jpeg(paste(country, "_ENP-votes_ENP_seats_",year_list[i],".jpeg", sep = ""))
	title <- paste(country, year_list[i], "ENP Votes against ENP Seats")
	plot(enp_votes[year == year_list[i]], enp_seats[year == year_list[i]], main = title)
	abline(lm(enp_seats[year == year_list[i]]~enp_votes[year == year_list[i]]), col='blue',lwd=1)
	abline(0,1, col='red')
	dev.off()
}

