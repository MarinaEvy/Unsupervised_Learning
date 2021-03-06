install.packages("caret") #Download te package for splitting the dataset into training and testing
install.packages("ggplot2") #Download this package in case I want to plot some features
install.packages("rattle") #Download this to plot the decision tree
install.packages("RColorBrewer") #Download this to make the tree look fancy
install.packages("lattice") #Care package requires it
install.packages("mice") # data imputation
install.packages("dummies") # binary transformation of categorical variables
install.packages("class") # KNN package
install.packages("e1071")
install.packages("nnet")
install.packages("neuralnet")
install.packages("grid")
install.packages("MASS")
install.packages("caret") #Download te package for splitting the dataset into training and testing
install.packages("ggplot2") #Download this package in case I want to plot some features
install.packages("rattle") #Download this to plot the decision tree
install.packages("RColorBrewer") #Download this to make the tree look fancy
install.packages("lattice") #Care package requires it
install.packages("mice") # data imputation
install.packages("dummies") # binary transformation of categorical variables
install.packages("class") # KNN package
install.packages("e1071")
install.packages("rpart")
install.packages("clusterGenomics")
install.packages("mclust")
install.packages("EMCluster")
install.packages("fastICA")
install.packages("devtools")
install_github("chappers/randomProjection")

library(randomProjection)
library(devtools)
library(caret)
library(ggplot2)
library(rattle)
library(RColorBrewer)
library(lattice)
library(mice)
library(dummies)
library(class)
library(e1071)
library(nnet)
library(neuralnet)
library(grid)
library(MASS)
library(caret)
library(ggplot2)
library(rattle)
library(RColorBrewer)
library(lattice)
library(mice)
library(dummies)
library(class)
library(e1071)
library(rpart)
library(clusterGenomics)
library(mclust)
library(EMCluster)
library(fastICA)

df=read.csv("C:/Users/mjohnson6/Desktop/Evy_Stuff/EVY_R_CODE/Credit.csv", 
            header = TRUE, dec=",", 
            na.strings = c(""," ","NA"))





#for some reason, R reads the variales below as factors. We have to convert them to numericals
numericVectors<-c("A2", "A3", "A8") 
for (n in 1:3){
  x=numericVectors[n]
  df[,x]<-as.numeric(levels(df[,x]))[df[,x]] #set some factor variables as numeric variables 
}

summary(df) # let's check the dataset
str(df) #let's see if all the variables are orrectly identified as factors and numbers.
classColumnID1<-dim(df)[2] #we will use the number of columns later on.


trainSet<-createDataPartition(y=df$class, p=0.7, list=FALSE) #create the testing training partitions
Train<-df[trainSet,] #subset the training set
Test<-df[-trainSet,] #subset the testing set

#let's check if the class labels are imbalanced. 
#According to the literature, if +/- ratio is above 0.5, the class os balanced.
balanceIndicatorTrain<-length(which(Train[, dim(Train)[2]]=="Yes"))/length(which(Train[, dim(Train)[2]]=="No"))
balanceIndicatorTest<-length(which(Test[, dim(Test)[2]]=="Yes"))/length(which(Test[, dim(Test)[2]]=="No"))
balanceIndicatorTrain=round(balanceIndicatorTrain, digits=3)
balanceIndicatorTest=round(balanceIndicatorTest, digits=3)
#parameter tuning for svm with a radial based function


#Let's do cross validation to get a better estimate of model accuracy
n<-nrow(Train)
K<-10 #number of folds - we do 10-fold cross validation
foldSize<-n%/%K
al<-runif(n) #we label eah row in the training set with random numebrs so we can assign them in one of the folds
ra<-rank(al) # we want to figure out which row in the training set the first random number is associated with
blocks<-(ra-1)%/%foldSize+1 # create the folds
blocks<-as.factor(blocks) #make them factors
print(summary(blocks))
errorCV <- vector(mode="numeric", length=K)
cp<-seq(0, 0.1, 0.01) # Learning rate values for tuning
minSplit<-seq(0,30,2) ## of hidden layers for tuning
meanError<-data.frame()
for(i in 1:length(cp)) {
  for(j in 1:length(minSplit)) {
    for(k in 1:K) {
      
      cvModel<-rpart(class ~. , method = "class", data=Train[blocks!=k,], 
                     control = rpart.control(minsplit=minSplit[j], cp = cp[i]))
      
      pred<-predict(cvModel, newdata=Train[blocks==k,], type="class")
      cmCV<-table(pred, Train[blocks==k,"class"])
      errorK<- 1- (cmCV[1,1] + cmCV[2,2])/sum(cmCV)
      errorCV[k]<-errorK
    }
    averageError<-mean(errorCV)
    meanError[i,j]<-averageError
  }
}
which(meanError==min(meanError)) #cp=0.03 and minsplit 6 gives the bes result

TreeModel<-rpart(class ~. , method = "class", data=Train, 
                 control = rpart.control(minsplit=0, cp = 0))

plot(TreeModel) #plots the tree
text(TreeModel, pretty=0) # brings teh text onto the plot
fancyRpartPlot(TreeModel, uniform=TRUE, sub="Classification Tree") # makes the plot look nicer

pTreeModel<-rpart(class ~. , method = "class", data=Train, 
                  control = rpart.control(minsplit=30, cp = 0.01))

pred<-predict(pTreeModel, newdata=Test, type="class")
cmCV<-table(pred, Test[,"class"])
Finalerror<- 1- (cmCV[1,1] + cmCV[2,2])/sum(cmCV)
plot(pTreeModel) #plots the tree
text(pTreeModel, pretty=0) # brings teh text onto the plot
fancyRpartPlot(pTreeModel, uniform=TRUE, sub="Pruned Classification Tree") # makes the plot look nicer

data1=data.frame(df$A9,df$A6, df$A10,df$class)

classColumnID1<-dim(data1)[2]

imputedDF<- mice(data1,m=1,maxit=50,meth='pmm',seed=500) #imputation with pmm
data1<-complete(imputedDF) #replacing the NA's
preObj <- preProcess(data1[, -classColumnID1], method=c("center", "scale")) #standardization
data2 <- predict(preObj, data1[, -classColumnID1]) #standardization
data2<-dummy.data.frame(data2, names = NULL, omit.constants=TRUE, dummy.classes = "factor") #categorical to binary variables
data2$class=data1$df.class #add the class to the df1
data1=data2 #save df1 to df
summary(data1) #get the summary of the dataframe to make sure things are ok!


pTreeModel<-rpart(class ~. , method = "class", data=data1, 
                  control = rpart.control(minsplit=30, cp = 0.01))
pred<-predict(pTreeModel, newdata=data1, type="class")
cmCV<-table(pred, data1[,"class"])
Finalerror<- 1- (cmCV[1,1] + cmCV[2,2])/sum(cmCV)
plot(pTreeModel) #plots the tree
text(pTreeModel, pretty=0) # brings teh text onto the plot
fancyRpartPlot(pTreeModel, uniform=TRUE, sub="Pruned Classification Tree")
data1=data1[, c("df.A9t", "df.A10f", "class")]
df=data1
a=ls()
a=a[a != "df"]
remove(list = a)


trainSet<-createDataPartition(y=df$class, p=0.7, list=FALSE) #create the testing training partitions
Train<-df[trainSet,] #subset he training set
Test<-df[-trainSet,] #subset the testing set
remove(trainSet)

#check if the class labels are imbalanced. 
#According to the literature, if +/- ratio is above 0.5, the class os balanced.
balanceIndicatorTrain<-length(which(Train[, dim(Train)[2]]=="Yes"))/length(which(Train[, dim(Train)[2]]=="No"))
balanceIndicatorTest<-length(which(Test[, dim(Test)[2]]=="Yes"))/length(which(Test[, dim(Test)[2]]=="No"))
balanceIndicatorTrain<-round(balanceIndicatorTrain, digits = 3)
balanceIndicatorTest<-round(balanceIndicatorTest, digits = 3)

Train2<-Train
Train2[,dim(Train)[2]]=as.numeric(Train[,dim(Train)[2]])-1
fmla <- as.formula(paste("class~ ", paste(names(Train2[,-dim(Train2)[2]]), collapse= "+")))

n<-nrow(Train2)
K<-10 #number of folds - do 10-fold cross validation
foldSize<-n%/%K
al<-runif(n) #label eah row in the training set with random numebrs so we can assign them in one of the folds
ra<-rank(al) # figure out which row in the training set the first random number is associated with
blocks<-(ra-1)%/%foldSize+1 # create the folds
blocks<-as.factor(blocks) #make them factors
print(summary(blocks))
errorCV <- vector(mode="numeric", length=K)
learningRate<-seq(0.005, 0.02, 0.005)
hiddenLayer<-c(2,3)
meanError<-data.frame()
for(i in 1:length(learningRate)) {
  for(j in 1:length(hiddenLayer)) {
    for(k in 1:K) {
      
      nn <- neuralnet(fmla,data=Train2[blocks!=k,], hidden=hiddenLayer[j], err.fct="ce",linear.output=FALSE, 
                      learningrate=learningRate[i], algorithm="backprop", 
                      act.fct = "logistic", threshold = 0.1, stepmax = 1e+06)
      
      predProb<-compute(nn, Train2[blocks==k, -dim(Train2)[2]])
      classLab <- vector(mode="character", length=dim(Train2[blocks==k, -dim(Train2)[2]])[1])
      pred=predProb$net.result
      for(ss in 1:dim(pred)[1]) {
        if(pred[ss]<0.5) {
          classLab[ss]="No"
        } else {
          classLab[ss]="Yes"
        }
      }
      cm<-table(classLab, Train[blocks==k, dim(Train)[2]])
      errorCV[k]<-1-(cm[1,1]+cm[2,2])/sum(cm)
    }
    
    meanError[i,j]<-mean(errorCV)
  }
}


nn <- neuralnet(fmla,data=Train2, hidden=1, err.fct="ce",linear.output=FALSE, 
                learningrate=0.015, algorithm="backprop", act.fct = "logistic", stepmax = 1e+06, threshold = 0.1)

predProb<-compute(nn, Test[, -dim(Test)[2]])
classLab <- vector(mode="character", length=dim(Test)[1])
pred=predProb$net.result
for(i in 1:dim(pred)[1]) {
  if(pred[i]<0.5) {
    classLab[i]="No"
  } else {
    classLab[i]="Yes"
  }
}
cm2<-table(classLab, Test[, dim(Test)[2]])
finalError<-1-(cm2[1,1]+cm2[2,2])/sum(cm2)
plot(nn)

mean(meanError[,1])

