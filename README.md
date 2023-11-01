# FA23_DSI_Capstone_Moody

This repository is the Capstone Project for Fall 2023 MS in Data Science at Columbia University.

Group Member:
Boping Xia (bx2210)
Xinhao Dai (xd2285)
Mingkang Yuan (my2705)
Shumin Song (ss6606)
Margaret Reed (mr4251)

## Data Gathering
### Data Gathering Checklist


|                           |                                                   | Egypt     | Hungary   | Nigeria | Poland | Romania |
|---------------------------|---------------------------------------------------|-----------|-----------|---------|--------|---------|
| Bond Markets              | Term Premium                                      | ✓ GFD</br>***2013.5-2022.9*** | ✓ GFD</br>1999.1-2023.9 | ✓ Investing</br>Use 2 Yr</br>2008.2-2023.9 | ✓ GFD</br>2003.12-**2023.3** | ✓ GFD</br>2008.1-***2022.9*** |
|                           | Risk Premium                                      | ✓ CEIC</br>**2013.5-2023.9** | ✓ CEIC</br>1999.1-2023.9 | ✓ CEIC</br>2007.12-2023.9 | ✓ CEIC</br>1999.5-***2023.3*** | ✓ CEIC</br>2001.12-**2023.6** |
| Equity Markets            | Stock Prices, mom% change                         | ✓ Bloomberg</br>2001.1-2023.9 | ✓ Bloomberg</br>2001.1-2023.9 | ✓ Bloomberg</br>2001.2-2023.9| ✓ Bloomberg</br>2001.1-2023.9 | ✓ Bloomberg</br>2003.2-2023.9|
|                           | Stock Prices, mom24mma% change                    | ✓ Bloomberg</br>2002.12-2023.9 | ✓ Bloomberg</br>2002.12-2023.9 | ✓ Bloomberg</br>2003.1-2023.9 | ✓ Bloomberg</br>2002.12-2023.9 | ✓ Bloomberg</br>2005.1-2023.9 |
|                           | Stock Market Volatility                           | ✓ Bloomberg</br>2001.2-2023.9 | ✓ Bloomberg</br>2001.2-2023.9 | ✓ Bloomberg</br>2001.2-2023.9| ✓ Bloomberg</br>2001.2-2023.9 | ✓ Bloomberg</br>2003.3-2023.9 |
| Macero Fundamentals       | REER                                              |  | ✓ IMF</br>1990.10-**2023.8** | ✓ IMF</br>1979.12-**2023.8** | ✓ IMF</br>1990.10-**2023.8** | ✓ IMF</br>1990.10-**2023.8** |
|                           | Current Account Balance (change % year over year) | ✓ CEIC</br>1994.12-**2023.6** | ✓</br>CEIC 1990.12-**2023.6** | ✓ CEIC</br>2009.3-***2022.12*** | ✓ CEIC</br>2001.3-2023.6 | ✓ CEIC</br>2003.9-*2023.6* |
|                           | Current Account Balance (mil USD) / GDP           | ✓ CEIC</br>2001.9-***2023.4*** | ✓ CEIC</br> 1995.3-**2023.6** | ✓ CEIC </br>2010.3-***2022.12*** | ✓ CEIC </br>2022.3-2023.6 | ✓ CEIC </br>2003.9-**2023.6** |
|                           | Policy (One-Day Repo) Rate %AVG                   | ✓ CEIC</br>2005.10-2023.9 | ✓ BIS</br>1995.1-2023.9 | ✓ CEIC</br>2006.12-2023.9 | ✓ BIS</br>1995.1-2023.9 | ✓ BIS</br>2003.1-2023.9 |
|                           | Policy (One-Day Repo) Rate %EOP                   | ✓ CEIC</br>2005.10-2023.9 | ✓ CEIC</br>1995.1-2023.9 | ✓ CEIC</br>2006.12-2023.9 | ✓ BIS</br>1995.1-2023.9 | ✓ CEIC</br>2003.1-2023.9 |
|                           | Policy Rate & Fed Funds Rate Differential %AVP    | ✓ CEIC</br>2005.10-2023.9 | ✓ BIS</br>1995.1-2023.9 | ✓ CEIC</br>2006.12-2023.9 | ✓ BIS</br>1995.1-2023.9 | ✓ BIS</br>2003.1-2023.9 |
|                           | Policy Rate & Fed Funds Rate Differential %EOP    | ✓ CEIC</br>2005.10-2023.9 | ✓ CEIC</br>1995.1-2023.9 | ✓ CEIC</br>2006.12-2023.9 | ✓ CEIC</br>1995.1-2023.9 | ✓ CEIC</br>2003.1-2023.9 |
| Money and Portfolio Flows | Broad Money, mo12m%change                         | ✓ WDI</br>2004.1-**2023.7** |  | ✓ WDI</br>2001.12-***2023.4*** | ✓ IMF</br>2004.3-**2023.7** | ✓ IMF</br>2001.12-**2023.8** |
|                           | Velocity of Money, mo12m change                   | ✓ CBE</br>2002.1-***2023.4*** |  | ✓ </br>2010.3-***2023.4*** | ✓ </br>2004.3-**2023.6** | ✓ </br>2001.12-**2023.6** |
|                           | Portfolio Flows                                   | ✓ IFF</br>2000.3-**2023.6** | ✓ IFF</br>2014.4-**2023.7** | ✓ IFF</br>2005.3-2024.12 | ✓</br>IFF 2000.1-**2023.7** | ✓</br>IFF 2005.1-**2023.7** |
|                           | Foreign Exchange Reserve (change % year over year)| ✓ CEIC</br>2005.12-2023.9 | ✓ CEIC</br>1999.1-2023.9 | ✓ CEIC</br>1961.1-**2023.6** | ✓ CEIC</br>1999.1-2023.9 | ✓ CEIC</br>2006.4-2023.9 |
|                           | Foreign Exchange Reserve (Mil USD) / GDP          | ✓ CEIC</br>2004.12-***2023.4*** | ✓ GFD</br>1998.1-**2023.6** | ✓ GFD</br>2010.3-**2023.6** | ✓ GFD</br>2002.3-**2023.6** | ✓ GFD</br>2005.4-**2023.6** |
|                           | Bank Lending, mo12m% change (total bank lending)  | ✓ CEIC</br>1980.06-**2023.8** | ✓ CEIC</br>2001.01-2023.9 | ✓ CEIC</br>2007.01-**2023.8** | ✓ CEIC</br>2006.01-**2023.8** | ✓ CEIC</br>2006.12-**2023.8** |
    




Currently under construction.

Select one from block component</br>
Term pre different options select one</br>
Repurchase avg, eop use one.</br>
same sign</br>
Comparing FCI: correlation and alignment</br>
Send csv by **11/03**
