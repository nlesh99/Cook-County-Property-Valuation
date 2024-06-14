
#Loading required libraries
library(boot)
library(glmnet)
library(ggplot2)
library(dplyr)
library(tidyr)
library(Matrix)


# Read data from CSV files
# Read cookbook, training, prediction data
train <- read.csv("historic_property_data.csv")
predict <- read.csv("predict_property_data.csv")
codebook <- read.csv("codebook.csv")


# Checking for nulls in the data
# We took the top missing values and found that all are character type
col_nulls <- colSums(is.na(train))
col_nulls <- col_nulls[order(col_nulls, decreasing = TRUE)]
print(head(col_nulls))

# We selected column to be handled
# Filling Unknown in such character type columns
columns_to_process <- c(
  "char_renovation", "meta_cdu", "char_apts", "char_porch", 
  "char_attic_fnsh", "char_tp_dsgn", "char_tp_plan", 
  "char_gar1_area", "char_gar1_att", "char_gar1_cnst", 
  "geo_fips", "geo_municipality"
)

for (col in columns_to_process) {
  train[[col]] <- ifelse(is.na(train[[col]]), "Unknown", train[[col]])
  predict[[col]] <- ifelse(is.na(predict[[col]]), "Unknown", predict[[col]])
}

# Dropping rows which have missing data in other columns
train_orig <- na.omit(train)
predict_orig <- na.omit(predict)

# Creating a static list of predictor columns using data from cookbook (using excel)
# We also create a list of numerical columns using data from cookbook (using excel)
# Sale price is not present in predict data, so creating 2 seaprate lists each 
all_cols <- c("sale_price",
              "meta_town_code",
              "meta_nbhd",
              "char_gar1_size",
              "char_hd_sf",
              "char_age",
              "char_type_resd",
              "ind_garage",
              "char_bsmt",
              "char_rooms",
              "char_beds",
              "char_bsmt_fin",
              "char_air",
              "char_frpl",
              "char_attic_type",
              "char_use",
              "char_ext_wall",
              "char_roof_cnst",
              "char_fbath",
              "char_hbath",
              "char_heat",
              "char_bldg_sf",
              "geo_ohare_noise",
              "geo_floodplain",
              "geo_fs_flood_factor",
              "geo_fs_flood_risk_direction",
              "geo_withinmr100",
              "geo_withinmr101300",
              "geo_school_elem_district",
              "geo_school_hs_district",
              "econ_midincome",
              "char_oheat",
              "char_gar1_cnst",
              "char_gar1_att",
              "char_gar1_area",
              "char_tp_plan",
              "char_tp_dsgn",
              "char_attic_fnsh",
              "char_porch",
              "char_apts",
              "econ_tax_rate")

all_cols_pred <- c("meta_town_code",
                   "meta_nbhd",
                   "char_gar1_size",
                   "char_hd_sf",
                   "char_age",
                   "char_type_resd",
                   "ind_garage",
                   "char_bsmt",
                   "char_rooms",
                   "char_beds",
                   "char_bsmt_fin",
                   "char_air",
                   "char_frpl",
                   "char_attic_type",
                   "char_use",
                   "char_ext_wall",
                   "char_roof_cnst",
                   "char_fbath",
                   "char_hbath",
                   "char_heat",
                   "char_bldg_sf",
                   "geo_ohare_noise",
                   "geo_floodplain",
                   "geo_fs_flood_factor",
                   "geo_fs_flood_risk_direction",
                   "geo_withinmr100",
                   "geo_withinmr101300",
                   "geo_school_elem_district",
                   "geo_school_hs_district",
                   "econ_midincome",
                   "char_oheat",
                   "char_gar1_cnst",
                   "char_gar1_att",
                   "char_gar1_area",
                   "char_tp_plan",
                   "char_tp_dsgn",
                   "char_attic_fnsh",
                   "char_porch",
                   "char_apts",
                   "econ_tax_rate")


# Added sale prices as we need to keep that column as a numeric col
# All logical columns can be converted into numerical as well
num_cols <- c("sale_price",
              "char_hd_sf",
              "char_age",
              "char_rooms",
              "char_beds",
              "char_frpl",
              "char_fbath",
              "char_hbath",
              "char_bldg_sf",
              "geo_fs_flood_factor",
              "geo_fs_flood_risk_direction",
              "econ_midincome",
              "econ_tax_rate",
              "ind_garage",
              "geo_ohare_noise",
              "geo_floodplain",
              "geo_withinmr100",
              "geo_withinmr101300")

# Added sale prices as we need to keep that column as a numeric col
num_cols_pred <- c("char_hd_sf",
                   "char_age",
                   "char_rooms",
                   "char_beds",
                   "char_frpl",
                   "char_fbath",
                   "char_hbath",
                   "char_bldg_sf",
                   "geo_fs_flood_factor",
                   "geo_fs_flood_risk_direction",
                   "econ_midincome",
                   "econ_tax_rate",
                   "ind_garage",
                   "geo_ohare_noise",
                   "geo_floodplain",
                   "geo_withinmr100",
                   "geo_withinmr101300")

# Create lists with non numerical columns
non_num_cols <- all_cols[!(all_cols %in% num_cols)]
non_num_cols_pred <- all_cols_pred[!(all_cols_pred %in% num_cols_pred)]

# Handle data properly
# [1] Typecast numeric columns as numeric (some columns are logical)
# Logical columns can be handled the same way as numeric ones
# [2] Typecast non-numeric columns as character
# [3] Convert non-numeric columns to as factor
# [4] Add sale price column as we will need to concatenate data
train <- subset(train_orig, select = all_cols)
train <- train %>% mutate(across(all_of(num_cols), as.numeric))
train <- train %>% mutate(across(all_of(non_num_cols), as.character))
train <- train %>% mutate_at(vars(all_of(non_num_cols)), as.factor)

predict <- subset(predict_orig, select = all_cols_pred)
predict <- predict %>% mutate(across(all_of(num_cols_pred), as.numeric))
predict <- predict %>% mutate(across(all_of(non_num_cols_pred), as.character))
predict <- predict %>% mutate_at(vars(all_of(non_num_cols_pred)), as.factor)
predict$sale_price <- -1 


# We are doing this so that when we do one hot encoding there
# is no mismatch between the number of columns in train and predict
# We take the super-set of all values to create one hot encoding
# Concatenate train and predict dataframe
df <- rbind(train, predict)

# Apply one-hot encoding only to factor columns using model.matrix
# Combine the encoded data with the original data (excluding the original factor columns)
# Remove the original factor columns
encoded <- model.matrix(~ . - 1, data = df[, non_num_cols])
df <- cbind(df, encoded)
df <- df[, !(names(df) %in% non_num_cols)]

# Split data into train and predict dataframe
split_index <- nrow(train)  
train <- df[1:split_index, ]
predict <- df[(split_index + 1):nrow(df), ]

# Randomly Split the training data into train and test
# We will use the test data to check accuracy of our model later
set.seed(0)
sample_indices <- sample(1:nrow(train), 0.8 * nrow(train))
test <- train[-sample_indices, ]
train <- train[sample_indices, ]

predict$sale_price <- NULL 


# Data is ready, We will run lasso regression now
# Prepare data
y <- train$sale_price
x <- as.matrix(train[, -which(names(train) %in% c("sale_price"))])
x <- as.matrix(Matrix(x, sparse = TRUE))

# Fit Lasso regression model with cross-validation
lasso_model <- cv.glmnet(x, y, alpha = 1, parallel=TRUE)

# Run MSE by making prediction on test dataset
ynew <- test$sale_price 
xnew <- as.matrix(test[, -which(names(test) %in% c("sale_price"))])

# Predict salaries and store in yhat
test$yhat <- predict(lasso_model, newx=xnew, s="lambda.min")

# Print MSE of predictions for test data
mse_value <- mean((test$yhat - test$sale_price)^2)
sum_value <- sum(test$sale_price)

cat("MSE for the Lasso model is:", mse_value, "\n")
cat("% MSE/Sum(sale price):", mse_value/sum_value, "\n")

# Create final predictions for data and write to csv file
xpred <- as.matrix(predict)

# Predict sale price
predict_orig$assessed_value <- predict(lasso_model, newx=xpred, s="lambda.min")
prediction <- subset(predict_orig, select = c("pid", "assessed_value"))

df <- data.frame(pid = c(1:10000))

# Ensure all pid from 1 to 10000 are present
all_pid <- 1:10000
pred_df <- df %>% left_join(prediction, by = "pid")

# Replace missing values with the mean of predictions
pred_df$assessed_value[is.na(pred_df$assessed_value)] <- mean(pred_df$assessed_value, na.rm = TRUE)

# Write final data data to csv
write.csv(pred_df, file = "prediction.csv", row.names = FALSE)
