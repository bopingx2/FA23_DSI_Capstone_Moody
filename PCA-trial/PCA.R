## This file is for the PCA-trial
library(lubridate)
library(dplyr)
library(tidyverse)
library(ggplot2)


## Read Data 
## Romania
Rom_BET_mo24mma <- read.csv("data/stock prices/BET_mo24mma_change.csv")
Rom_BET_mo24mma$Date <- format(as.Date(Rom_BET_mo24mma$Date), "%Y-%m")
Rom_BET_mo24mma = Rom_BET_mo24mma %>% select("Date", "mo24mma.change")
colnames(Rom_BET_mo24mma)[2] <- "BET_mo24mma_change"

Rom_BET_mom <- read.csv("data/stock prices/BET_mom%change.csv")
Rom_BET_mom$Date <- format(as.Date(Rom_BET_mom$Date), "%Y-%m")
Rom_BET_mom = Rom_BET_mom %>% select("Date", "mom.change")
colnames(Rom_BET_mom)[2] <- "BET_mom_change"

Rom_BET_volatility <- read.csv("data/stock prices/BETmonthly_Volatility.csv")
Rom_BET_volatility$Date <- format(ym(Rom_BET_volatility$Date), "%Y-%m")
Rom_BET_volatility = Rom_BET_volatility %>% select("Date", "Volatility")
colnames(Rom_BET_volatility)[2] <- "BET_volatility"

Rom_REER <- read.csv('data/REER/REER Romania.csv', skip = 26)
colnames(Rom_REER)[1] <- "Date"
colnames(Rom_REER)[2] <- "REER"
Rom_REER$Date <- format(my(Rom_REER$Date), "%Y-%m")

Rom_Bank_Lending <- read.csv('data/Bank Lending Rate/Bank Lending Rate mo12m change Romania.csv')
Rom_Bank_Lending$Date <- format(ym(Rom_Bank_Lending$Date), "%Y-%m")
Rom_Bank_Lending <- Rom_Bank_Lending %>% select("Date", "mo12m_change")
colnames(Rom_Bank_Lending)[2] <- "Bank_Lending_mo12m_change"


Rom_Foreign_exchange_reserve_change <- read.csv("data/Foreign exchange reserve year over yr new/Romania_monthly.csv", skip = 2)
Rom_Foreign_exchange_reserve_change = Rom_Foreign_exchange_reserve_change %>% select("Date", "Annual_Percent_Change")
Rom_Foreign_exchange_reserve_change$Date <- format(mdy(Rom_Foreign_exchange_reserve_change$Date), "%Y-%m")
colnames(Rom_Foreign_exchange_reserve_change)[2] <- "FER_change"


Rom_Term_Premium <- read.csv("data/Term Premium/Romania_termpremium.csv") %>% select("Date", "TermPremium")
Rom_Term_Premium$Date <- format(ymd(Rom_Term_Premium$Date), "%Y-%m")

Rom_Risk_Premium <- read.csv("data/Risk Premium new/Romania_riskpremium.csv") %>% select("Date", "RiskPremium")
Rom_Risk_Premium$Date <- format(ymd(Rom_Risk_Premium$Date), "%Y-%m")

## Merge Data

Rom_merged <- list(Rom_BET_mo24mma, Rom_BET_mom, Rom_BET_volatility, Rom_REER, 
                    Rom_Bank_Lending, Rom_Foreign_exchange_reserve_change, Rom_Term_Premium, Rom_Risk_Premium) %>% 
              reduce(full_join, by='Date')

Rom_PCA = princomp(~ BET_mo24mma_change + BET_mom_change + BET_volatility + REER + Bank_Lending_mo12m_change + 
           FER_change + TermPremium + RiskPremium, data = Rom_merged, na.action = na.omit, cor = TRUE)
summary(Rom_PCA)
Rom_PCA$loadings
Rom_plot = cbind(na.omit(Rom_merged)["Date"], Rom_PCA$scores[,1])
colnames(Rom_plot)[2] = "Comp1"
Rom_plot$Date = ym(Rom_plot$Date)
ggplot(data = Rom_plot, mapping = aes(x = Date, y = Comp1))+geom_line() + 
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")


