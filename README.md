### HAR_Analysis
For Course Project getdata-010 2015

My script will download the data and put it into the appropriate subfolder, if you have not done that already.

Execute the script from your working directory. You will then be placed in the data directory "./UCI HAR Dataset/". The directories are pretty much in named objects, so you can change them if necessary.

The script is thoroughly documented. I did not use very sophisticated libraries, just mostly dplyr and the basic ones. I also used a lot of intermediate objects, which can be examined in the data directory at the end of the script.

After staring at the data, and actually creating a reasonable but very wide data frame, I realised that most of the data was highly dubious.

* Columns starting with f, Frequency Domain, were derived via Fast Fourier Transform and probably not useful to most users. Skipped.
* Columns starting with Gravity were subtractions from the original observations, leaving Body as the ones of interest. Skipped.
* Columns that were neither mean nor std were also skipped, and columns starting with "angle".

So the remaining columns described Time Domain Body Accelerometer and Gyroscope means and standard deviations. I put this in hold2.

Accelerometer and Gyroscope measurements looked as if they could be taken out of the column names and set up as indicators (keys).
This is a huge pain.

First a set of sub statements were executed on a copy of the names() to get the punctuation right and remove extraneous characters. They are commented in the script.

The resulting names were applied to the working dataset hold2. The columns in hold2 are not in a reasonable order, so I had to build two lists of names, one each for Accelerometer and Gyroscope, for selection. I used grep for this. 

Then I made two separate data frames by using select .. one_of:  hold4 <- select(hold2, one_of(accList)) . The Accelerometer data ended up in hold4 and the Gyroscope in hold5. I added a column Measurement_Type using mutate to each set, and set the values to Accelerometer and Gyroscope respectively.

At this point one would like to rbind the two sets, but you can't do that because the column heads are still different. The last thing to be done to them is to get rid of the Acc. and Gyro. particles, now that there is a column of Measurement_Type. So I used sub(). It was then possible to rbind_list.

This thing, which I called nicedata, was now ready to have itself grouped by the three keys. Of course I put it into another object. I wouldn't have to keep doing that except that it makes things much clearer. This grouped object, aggdata, only has one more step to go: summarise, as follows: summdata <- aggdata %>%
  summarise_each(funs(mean))

Oh, that summarise_each! It takes a long time to find the correct variant (like one_of above).

Anyway, it turned out to be a very simple table indeed, which you can see by reading it back in with datatemp <-read.table("tidyHAR.txt", header=TRUE)

