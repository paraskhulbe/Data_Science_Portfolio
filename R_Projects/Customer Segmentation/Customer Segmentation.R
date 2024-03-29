## Importing the dataset
library(lubridate)
Online.Retail <- read.csv("Online Retail.csv", stringsAsFactors=FALSE)

## NA value treatment

order_wise <- na.omit(Online.Retail)

## Making RFM data

Amount <- order_wise$Quantity * order_wise$UnitPrice
order_wise <- cbind(order_wise,Amount)

order_wise <- order_wise[order(order_wise$CustomerID),]

monetary <- aggregate(Amount~CustomerID, order_wise, sum)

frequency <- order_wise[,c(7,1)]
frequency  
k<-table(as.factor(frequency$CustomerID))

k<-data.frame(k)
k
colnames(k)[1]<-c("CustomerID")

master <-merge(monetary,k,by="CustomerID")

recency <- order_wise[,c(7,5)]

recency$InvoiceDate<-parse_date_time(recency$InvoiceDate,orders = c("mdy_HM"))

maximum<-max(recency$InvoiceDate)

maximum<-maximum+1

maximum$diff <-round(difftime(maximum, recency$InvoiceDate, units = c("days")),0)

recency$diff<-maximum$diff

df<-aggregate(recency$diff,by=list(recency$CustomerID),FUN="min")

colnames(df)[1]<- "CustomerID"

colnames(df)[2]<- "Recency"

RFM <- merge(monetary, k, by = ("CustomerID"))

RFM <- merge(RFM, df, by = ("CustomerID"))

RFM$Recency <- as.numeric(RFM$Recency)
summary(RFM)
## Outlier treatment

box <- boxplot.stats(RFM$Amount)
box
out <- box$out

RFM1 <- RFM[ !RFM$Amount %in% out, ]

RFM <- RFM1

box <- boxplot.stats(RFM$Freq)
out <- box$out

RFM1 <- RFM[ !RFM$Freq %in% out, ]

RFM <- RFM1

box <- boxplot.stats(RFM$Recency)
out <- box$out

RFM1 <- RFM[ !RFM$Recency %in% out, ]

RFM <- RFM1
summary(RFM)
## Standardisation of data

RFM_norm1<- RFM[,-1]

RFM_norm1$Amount <- scale(RFM_norm1$Amount)
RFM_norm1$Freq <- scale(RFM_norm1$Freq)
RFM_norm1$Recency <- scale(RFM_norm1$Recency)

## Implementing K-Means algorithm 

clus3 <- kmeans(RFM_norm1, centers = 3, iter.max = 50, nstart = 50)
str(clus3)
## Finding the optimal value of K

r_sq<- rnorm(20)

for (number in 1:20){clus <- kmeans(RFM_norm1, centers = number, iter.max = 50, nstart = 50)
r_sq[number]<- clus$betweenss/clus$totss
}

plot(r_sq)

## Running the K-Means algorithm for K =4,5,6

clus4 <- kmeans(RFM_norm1, centers = 4, iter.max = 50, nstart = 50)

clus5 <- kmeans(RFM_norm1, centers = 5, iter.max = 50, nstart = 50)

clus6 <- kmeans(RFM_norm1, centers = 6, iter.max = 50, nstart = 50)

## Appending the ClusterIDs to RFM data

RFM_km <-cbind(RFM,clus5$cluster)

colnames(RFM_km)[5]<- "ClusterID"

## Cluster Analysis

library(dplyr)

km_clusters<- group_by(RFM_km, ClusterID)

tab1<- summarise(km_clusters, Mean_amount=mean(Amount), Mean_freq=mean(Freq), Mean_recency=mean(Recency))
library(ggplot2)
ggplot(tab1, aes(x= factor(ClusterID), y=Mean_amount)) + geom_bar(stat = "identity")
ggplot(tab1, aes(x= factor(ClusterID), y=Mean_freq)) + geom_bar(stat = "identity")
ggplot(tab1, aes(x= factor(ClusterID), y=Mean_recency)) + geom_bar(stat = "identity")

# With cluster value 4
RFM_km_4 <-cbind(RFM,clus4$cluster)

colnames(RFM_km_4)[5]<- "ClusterID"

# Analyse the clusters 
km_clusters_4 <- group_by(RFM_km_4, ClusterID)
tab2 <- summarise(km_clusters_4, MeanAmount = mean(Amount), MeanFrequency = mean(Freq), 
                  MeanRecency = mean(Recency))
library(ggthemes)
p1 <- ggplot(tab2, aes(x = factor(ClusterID), y = MeanAmount, fill = as.factor(ClusterID))) + 
  geom_col() + scale_fill_discrete(name = "ClusterID") + theme_solarized()
p2 <- ggplot(tab2, aes(x = factor(ClusterID), y = MeanFrequency)) + geom_col(fill = "medium turquoise")
p3 <- ggplot(tab2, aes(x = factor(ClusterID), y = MeanRecency)) + geom_col(fill = "yellow")
library(gridExtra)
grid.arrange(p1,p2,p3)
# Cluster 3 is again the best

## Hierarchical clustering

## Calcualting the distance matrix

RFM_dist<- dist(RFM_norm1)
typeof(RFM_dist)
## Constructing the dendrogram using single linkage

RFM_hclust1<- hclust(RFM_dist, method="single") # Type of Linkage
plot(RFM_hclust1, labels = rownames(RFM_hclust1))

## Constructing the dendrogram using complete linkage

RFM_hclust2<- hclust(RFM_dist, method="complete")
plot(RFM_hclust2)

## Visualising the cut in the dendrogram

rect.hclust(RFM_hclust2, k=5, border="red")

## Making the cut in the dendrogram

clusterCut <- cutree(RFM_hclust2, k=5)
clusterCut
## Appending the ClusterIDs to RFM data

RFM_hc <-cbind(RFM,clusterCut)

colnames(RFM_hc)[5]<- "ClusterID"

## Cluster Analysis

hc_clusters<- group_by(RFM_hc, ClusterID)
library(ggplot2)
tab2<- summarise(hc_clusters, Mean_amount=mean(Amount), Mean_freq=mean(Freq), Mean_recency=mean(Recency))
ggplot(tab2, aes(x= factor(ClusterID), y=Mean_recency)) + geom_bar(stat = "identity")
ggplot(tab2, aes(x= factor(ClusterID), y=Mean_amount)) + geom_bar(stat = "identity")
ggplot(tab2, aes(x= factor(ClusterID), y=Mean_freq)) + geom_bar(stat = "identity")
