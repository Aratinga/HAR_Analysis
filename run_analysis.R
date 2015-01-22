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

library(dplyr)
library(plyr)
setwd(DataDirectory)       ## you will end up in this directory and will be able to examine the objects
## If you are going to do this again, remove the stash file dataFile
if (!file.exists(dataFile)) {                ## Put labels into vectors
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
    names(trainSubjects) = "Subject"
    trainSubjects$subject = as.factor(trainSubjects$Subject)
    train = cbind(Xtrain, trainSubjects, Ytrain)

    Xtest = read.table("test/X_test.txt", sep = "")
    names(Xtest) = attNames
    Ytest = read.table("test/y_test.txt", sep = "")
    names(Ytest) = "Activity"
    Ytest$Activity = as.factor(Ytest$Activity)
    levels(Ytest$Activity) = activityLabels
    testSubjects = read.table("test/subject_test.txt", sep = "")   ### These are different people
    names(testSubjects) = "Subject"
    testSubjects$subject = as.factor(testSubjects$Subject)
    test = cbind(Xtest, testSubjects, Ytest)
   print("ready with data") 
    ## The two data frames should look the same at this point
  hold <- rbind_list(train, test)

    save(hold, file = dataFile)
}
 ## now there is one big file named hold with 563 columns
 ## select just the columns that are means and/or standard deviations, based on their names, also the keys! 
 ## Omit frequency domain domain data and the gravity and angle data
    hold2 <- hold %>% select(Subject,Activity, contains("mean",ignore.case=TRUE), contains("std", ignore.case=TRUE), -starts_with("angle"), -starts_with("f"), -contains("Gravity",ignore.case=TRUE), ignore.case = TRUE)

## TIME TO MESS WITH HEADERNAMES
wnames <- names(hold2)
wnames <-sub("^t","",wnames)              ## we are using only time domain so get rid of the t
wnames <- sub("BodyBody","Body",wnames)   ## this was an error but I think it was in frequency anyway
wnames <- sub("\\.{3}","\\.",wnames)      ## reduce the number of periods to 1
wnames <- sub("\\.{2}","\\.",wnames)      ## reduce the number of periods to 1
wnames <- sub("\\.$","",wnames)           ## trailing periods
wnames <- sub("Body","",wnames)            ## they are all body so get rid of it
wnames <- sub("AccJerk","Acc.Jerk", wnames)     ## trust me, we are adding these periods to help the data
wnames <- sub("GyroJerk","Gyro.Jerk", wnames)   ## trust me, we are adding these periods to help the data
wnames <- sub("GyroMag","Gyro.Mag", wnames)     ## trust me, we are adding these periods to help the data
wnames <- sub("AccMag","Acc.Mag", wnames)       ## trust me, we are adding these periods to help the data
wnames <- sub("JerkMag","Jerk.Mag", wnames)     ## trust me, we are adding these periods to help the data

## LET'S PUT THE REVISED HEADER NAMES ON hold2
names(hold2) <- wnames
## Add a column to distinguish Accelerometer and Gyro measurements
xnames <- wnames[3:34]                           ## all the column names that are not keys
## select the accelerometer names so they end up in the order we want them
##namelist <- c("Subject", "Activity", grep("Acc.[a-z]", xnames, value = TRUE) , grep("Acc.Mag", xnames, value = TRUE), grep("Acc.Jerk.[a-z]", xnames, value = TRUE),grep("Acc.Jerk.Mag", xnames, value = TRUE),grep("Gyro.[a-z]", xnames, value = TRUE) , grep("Gyro.Mag", xnames, value = TRUE),grep("Gyro.Jerk.[a-z]", xnames, value = TRUE),grep("Gyro.Jerk.Mag", xnames, value = TRUE))
accList <- c("Subject", "Activity", grep("Acc.[a-z]", xnames, value = TRUE) , grep("Acc.Mag", xnames, value = TRUE), grep("Acc.Jerk.[a-z]", xnames, value = TRUE),grep("Acc.Jerk.Mag", xnames, value = TRUE))
hold4 <- select(hold2, one_of(accList))              ## put the accelerometer columns in a data frame
hold4 <- mutate(hold4, Measurement_Type = "Accelerometer")  ## stick the identifier out there
## Now do the same for the gyroscope measurements
gyroList <- c("Subject", "Activity", grep("Gyro.[a-z]", xnames, value = TRUE) , grep("Gyro.Mag", xnames, value = TRUE),grep("Gyro.Jerk.[a-z]", xnames, value = TRUE),grep("Gyro.Jerk.Mag", xnames, value = TRUE))
hold5 <- select(hold2, one_of(gyroList))
hold5 <- mutate(hold5, Measurement_Type = "Gyroscope")
##Now stick them back together for grouping
#First get rid of the Acc. and Gyro. fragments on the names so they can be in the same column
names(hold4) <- sub("Acc.","", names(hold4))
names(hold5) <- sub("Gyro.","", names(hold5))
nicedata <- rbind_list(hold4, hold5)
## Now we have only 16 variables and 3 keys
## GROUP by Subject, Activity, and Measurement_Type
aggdata <- group_by(nicedata, Subject, Activity, Measurement_Type)
## Get the summary data (means of all the data columns)
summdata <- aggdata %>%
  summarise_each(funs(mean))
write.table(summdata,file="tidyHAR.txt", row.names=FALSE)