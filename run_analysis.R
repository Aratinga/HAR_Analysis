## run_analysis.R

ProjectDirectory = getwd()
DataDirectory = "./UCI HAR Dataset/"
dataFile = "dataset.RData"    ### name of file to stash the slightly cooked data
## Download this just once! If you need it again, remove the DataDirectory
sourceFile = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
if (!file.exists(DataDirectory)) {
    download.file(sourceFile, 
        "data.zip", "curl", quiet = TRUE, mode = "wb")
    unzip("data.zip")
    file.remove("data.zip")
    whenDownloaded = date()
}
stopifnot(file.exists(DataDirectory))
## print("just starting")
## Now start munging the data from test and train into two data frames that can be combined and stored
## Do this only once
library(plyr)
library(dplyr)
setwd(DataDirectory)
if (!file.exists(dataFile)) {                ## Put labels into vectors
  print("reading data")
    temp = read.table("activity_labels.txt", sep = "")
    activityLabels = as.character(temp$V2)
    temp = read.table("features.txt", sep = "")
    attributeNames = temp$V2
    attNames <- make.names(attributeNames, unique=TRUE)   ### There are duplicate names on this file so munge
## Get the training data
    Xtrain = read.table("train/X_train.txt", sep = "")
    names(Xtrain) = attNames
    Ytrain = read.table("train/y_train.txt", sep = "")
    names(Ytrain) = "Activity"
    Ytrain$Activity = as.factor(Ytrain$Activity)
    levels(Ytrain$Activity) = activityLabels
    trainSubjects = read.table("train/subject_train.txt", sep = "")
    names(trainSubjects) = "subject"
    trainSubjects$subject = as.factor(trainSubjects$subject)
    train = cbind(Xtrain, trainSubjects, Ytrain)

    Xtest = read.table("test/X_test.txt", sep = "")
    names(Xtest) = attNames
    Ytest = read.table("test/y_test.txt", sep = "")
    names(Ytest) = "Activity"
    Ytest$Activity = as.factor(Ytest$Activity)
    levels(Ytest$Activity) = activityLabels
    testSubjects = read.table("test/subject_test.txt", sep = "")   ### These are different people
    names(testSubjects) = "subject"
    testSubjects$subject = as.factor(testSubjects$subject)
    test = cbind(Xtest, testSubjects, Ytest)
   print("ready with data") 
    ## The two data frames should look the same at this point
  hold <- rbind_list(train, test)

    save(hold, file = dataFile)
 ## select just the columns that are means and/or standard deviations, based on their names, also the keys!
    hold2 <- hold %>% select(subject,Activity, contains("mean"), contains("std"), -starts_with("angle"), ignore.case = TRUE)
 ##   rm(train, test, temp, Ytrain, Ytest, Xtrain, Xtest, trainSubjects, testSubjects, 
 ##       activityLabels, attributeNames, attNames)
}
## TIME TO MESS WITH HEADERNAMES
wnames <- names(hold2)
wnames <-sub("^f","FreqDomain",wnames)
wnames <-sub("^t","TimeDomain",wnames)
wnames <- sub("\\.{3}","\\.",wnames)
wnames <- sub("\\.{2}","\\.",wnames)
wnames <- sub("\\.$","",wnames)
## LET'S PUT THE REVISED HEADER NAMES ON hold2
names(hold2) <- wnames
## GROUP by Subject and Activity
aggdata <- group_by(hold2, subject, Activity)
## Get the summary data (means of all the data columns)
summdata <- aggdata %>%
  summarise_each(funs(mean))
write.table(summdata,file="tidyHAR.txt", row.names=FALSE)